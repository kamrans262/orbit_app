import 'package:uuid/uuid.dart';

import '../../../core/network/orbit_api_exception.dart';
import '../../../core/security/auth_session.dart';
import '../../../core/security/session_store.dart';
import '../data/device_identity_store.dart';
import '../data/message_local_store.dart';
import '../data/messaging_remote_repository.dart';
import '../data/orbit_e2ee_codec.dart';
import '../domain/e2ee_identity.dart';
import '../domain/messaging_models.dart';

class MessagingServiceException implements Exception {
  const MessagingServiceException(this.message);

  final String message;

  @override
  String toString() => 'MessagingServiceException($message)';
}

class MessagingService {
  MessagingService({
    required MessagingRemoteRepository remote,
    required MessageLocalStore local,
    required DeviceIdentityStore identityStore,
    required OrbitE2eeCodec codec,
    required SessionStore sessionStore,
    Uuid uuid = const Uuid(),
  }) : this._(remote, local, identityStore, codec, sessionStore, uuid);

  MessagingService._(
    this._remote,
    this._local,
    this._identityStore,
    this._codec,
    this._sessionStore,
    this._uuid,
  );

  final MessagingRemoteRepository _remote;
  final MessageLocalStore _local;
  final DeviceIdentityStore _identityStore;
  final OrbitE2eeCodec _codec;
  final SessionStore _sessionStore;
  final Uuid _uuid;
  String? _publishedDeviceId;

  Future<ConversationSnapshot> loadConversation({
    required String circleId,
    required int currentUserId,
  }) async {
    final ready = await _ensureReady();
    final settings = await _remote.getSettings();
    await _syncCircle(
      circleId: circleId,
      currentUserId: currentUserId,
      session: ready.session,
      identity: ready.identity,
      readReceiptsEnabled: settings.readReceiptsEnabled,
    );
    return ConversationSnapshot(
      messages: await _local.listMessages(circleId),
      identityFingerprint: await _codec.fingerprint(
        ready.identity.publicIdentity,
      ),
      readReceiptsEnabled: settings.readReceiptsEnabled,
    );
  }

  Future<String> identityFingerprint() async {
    final ready = await _ensureReady();
    return _codec.fingerprint(ready.identity.publicIdentity);
  }

  Future<MessagingSettings> getSettings() async {
    await _ensureReady();
    return _remote.getSettings();
  }

  Future<MessagingSettings> updateReadReceipts(bool enabled) async {
    await _ensureReady();
    return _remote.updateSettings(enabled);
  }

  Future<void> sendText({
    required String circleId,
    required int senderUserId,
    required String plaintext,
  }) async {
    final body = plaintext.trim();
    if (body.isEmpty) {
      return;
    }
    if (body.length > 8000) {
      throw const MessagingServiceException(
        'Messages can contain up to 8,000 characters.',
      );
    }

    final ready = await _ensureReady();
    final messageId = _uuid.v4();
    final createdAt = DateTime.now().toUtc();
    await _local.saveMessage(
      LocalMessage(
        messageId: messageId,
        circleId: circleId,
        senderUserId: senderUserId,
        senderDeviceId: ready.session.deviceId,
        direction: LocalMessageDirection.outgoing,
        type: OrbitMessageType.text,
        body: body,
        createdAt: createdAt,
        status: LocalMessageStatus.sending,
      ),
    );

    try {
      await _sendWithCurrentRecipients(
        circleId: circleId,
        messageId: messageId,
        senderDeviceId: ready.session.deviceId,
        createdAt: createdAt,
        body: body,
        identity: ready.identity,
      );
      await _local.updateStatus(messageId, LocalMessageStatus.sent);
    } on OrbitApiException catch (error) {
      if (error.code == 'MESSAGING_RECIPIENT_DEVICES_CHANGED') {
        try {
          await _sendWithCurrentRecipients(
            circleId: circleId,
            messageId: messageId,
            senderDeviceId: ready.session.deviceId,
            createdAt: createdAt,
            body: body,
            identity: ready.identity,
          );
          await _local.updateStatus(messageId, LocalMessageStatus.sent);
          return;
        } on Object {
          await _local.updateStatus(messageId, LocalMessageStatus.failed);
          rethrow;
        }
      }
      await _local.updateStatus(messageId, LocalMessageStatus.failed);
      rethrow;
    } on Object {
      await _local.updateStatus(messageId, LocalMessageStatus.failed);
      rethrow;
    }
  }

  Future<void> retryMessage({required LocalMessage message}) async {
    if (message.direction != LocalMessageDirection.outgoing ||
        message.type != OrbitMessageType.text) {
      return;
    }
    final ready = await _ensureReady();
    await _local.updateStatus(message.messageId, LocalMessageStatus.sending);
    try {
      await _sendWithCurrentRecipients(
        circleId: message.circleId,
        messageId: message.messageId,
        senderDeviceId: ready.session.deviceId,
        createdAt: message.createdAt,
        body: message.body,
        identity: ready.identity,
      );
      await _local.updateStatus(message.messageId, LocalMessageStatus.sent);
    } on Object {
      await _local.updateStatus(message.messageId, LocalMessageStatus.failed);
      rethrow;
    }
  }

  Future<void> sendTyping(String circleId, bool isTyping) async {
    await _ensureReady();
    await _remote.sendTyping(circleId, isTyping);
  }

  Future<void> applyDeliveryReceipt(String messageId) async {
    final normalized = messageId.trim();
    if (normalized.isEmpty) {
      return;
    }
    await _local.updateStatus(normalized, LocalMessageStatus.delivered);
  }

  /// Verifies that the current server device-key set still matches the
  /// identities already trusted by this installation. New devices are pinned
  /// on first sight; an unexpected key change for a known device fails closed.
  Future<void> validatePeerDevices(List<MessageDevice> devices) {
    return _cacheDeviceKeys(devices);
  }

  Future<void> _sendWithCurrentRecipients({
    required String circleId,
    required String messageId,
    required String senderDeviceId,
    required DateTime createdAt,
    required String body,
    required DevicePrivateIdentity identity,
  }) async {
    final devices = await _remote.getCircleMessageDevices(circleId);
    await _cacheDeviceKeys(devices);
    final recipients = devices
        .where((device) => device.deviceId != senderDeviceId)
        .toList(growable: false);
    if (recipients.isEmpty) {
      throw const MessagingServiceException(
        'No other encryption-ready device is available in this Circle yet.',
      );
    }

    final envelopes = <OutboundEnvelope>[];
    for (final recipient in recipients) {
      envelopes.add(
        await _codec.encryptText(
          envelopeId: _uuid.v4(),
          messageId: messageId,
          circleId: circleId,
          senderDeviceId: senderDeviceId,
          recipient: recipient,
          senderIdentity: identity,
          plaintext: body,
        ),
      );
    }

    await _remote.sendEncryptedMessage(
      circleId: circleId,
      messageId: messageId,
      senderDeviceId: senderDeviceId,
      clientSentAt: createdAt,
      envelopes: envelopes,
    );
  }

  Future<void> _syncCircle({
    required String circleId,
    required int currentUserId,
    required AuthSession session,
    required DevicePrivateIdentity identity,
    required bool readReceiptsEnabled,
  }) async {
    final devices = await _remote.getCircleMessageDevices(circleId);
    await _cacheDeviceKeys(devices);

    var cursor = await _local.readCursor(circleId, session.deviceId);
    var continueSync = true;
    while (continueSync) {
      final page = await _remote.syncCircle(
        circleId: circleId,
        deviceId: session.deviceId,
        afterId: cursor,
      );
      if (page.envelopes.isEmpty) {
        break;
      }

      for (final envelope in page.envelopes) {
        // M6 owns encrypted media/voice payloads. Do not acknowledge them here;
        // deleting their server envelope before M6 could destroy recoverability.
        if (envelope.type != OrbitMessageType.text) {
          continueSync = false;
          break;
        }
        final senderIdentity = await _local.readPeerIdentity(
          envelope.senderDeviceId,
        );
        if (senderIdentity == null) {
          throw const MessagingServiceException(
            'A sender encryption key is not available yet. Refresh the Circle and try again.',
          );
        }
        final clear = await _codec.decryptText(
          envelope: envelope,
          recipientIdentity: identity,
          senderIdentity: senderIdentity,
        );
        final isOwnUser = envelope.senderUserId == currentUserId;
        await _local.saveMessage(
          LocalMessage(
            messageId: envelope.messageId,
            circleId: envelope.circleId,
            senderUserId: envelope.senderUserId,
            senderDeviceId: envelope.senderDeviceId,
            direction: isOwnUser
                ? LocalMessageDirection.outgoing
                : LocalMessageDirection.incoming,
            type: envelope.type,
            body: clear.body,
            createdAt: envelope.createdAt,
            status: LocalMessageStatus.delivered,
          ),
        );

        // Delivery acknowledgement is intentionally after authenticated decrypt
        // and durable encrypted local persistence.
        await _remote.acknowledgeDelivery(envelope.envelopeId);
        if (!isOwnUser && readReceiptsEnabled) {
          await _remote.markRead(circleId, envelope.messageId);
        }
        cursor = envelope.serverCursor;
        await _local.writeCursor(circleId, session.deviceId, cursor);
      }
      continueSync = continueSync && page.hasMore;
    }
  }

  Future<void> _cacheDeviceKeys(List<MessageDevice> devices) async {
    for (final device in devices) {
      await _local.cachePeerIdentity(device.deviceId, device.identity);
    }
  }

  Future<_ReadyMessagingIdentity> _ensureReady() async {
    final session = await _sessionStore.read();
    if (session == null) {
      throw const MessagingServiceException(
        'Your secure Orbit session is not available.',
      );
    }
    final identity = await _identityStore.getOrCreate(session.deviceId);
    if (_publishedDeviceId != session.deviceId) {
      await _remote.publishDeviceIdentity(
        publicIdentityKey: identity.publicIdentity.toServerValue(),
      );
      _publishedDeviceId = session.deviceId;
    }
    return _ReadyMessagingIdentity(session: session, identity: identity);
  }
}

class _ReadyMessagingIdentity {
  const _ReadyMessagingIdentity({
    required this.session,
    required this.identity,
  });

  final AuthSession session;
  final DevicePrivateIdentity identity;
}
