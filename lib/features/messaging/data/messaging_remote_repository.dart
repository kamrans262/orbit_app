import '../../../core/device/device_metadata_service.dart';
import '../../../core/network/orbit_api_client.dart';
import '../../../core/security/local_device_id_store.dart';
import '../domain/messaging_models.dart';

abstract interface class MessagingRemoteRepository {
  Future<void> publishDeviceIdentity({required String publicIdentityKey});

  Future<List<MessageDevice>> getCircleMessageDevices(String circleId);

  Future<void> sendEncryptedMessage({
    required String circleId,
    required String messageId,
    required String senderDeviceId,
    required DateTime clientSentAt,
    required List<OutboundEnvelope> envelopes,
  });

  Future<MessageSyncPage> syncCircle({
    required String circleId,
    required String deviceId,
    required int afterId,
    int limit = 200,
  });

  Future<void> acknowledgeDelivery(String envelopeId);
  Future<void> markRead(String circleId, String messageId);
  Future<void> sendTyping(String circleId, bool isTyping);
  Future<MessagingSettings> getSettings();
  Future<MessagingSettings> updateSettings(bool readReceiptsEnabled);
}

class HttpMessagingRemoteRepository implements MessagingRemoteRepository {
  HttpMessagingRemoteRepository({
    required OrbitApiClient apiClient,
    required ClientDeviceIdStore clientDeviceIdStore,
    required DeviceMetadataReader deviceMetadataReader,
  }) : this._(apiClient, clientDeviceIdStore, deviceMetadataReader);

  HttpMessagingRemoteRepository._(
    this._apiClient,
    this._clientDeviceIdStore,
    this._deviceMetadataReader,
  );

  final OrbitApiClient _apiClient;
  final ClientDeviceIdStore _clientDeviceIdStore;
  final DeviceMetadataReader _deviceMetadataReader;

  @override
  Future<void> publishDeviceIdentity({
    required String publicIdentityKey,
  }) async {
    final clientDeviceId = await _clientDeviceIdStore.getOrCreate();
    final metadata = await _deviceMetadataReader.read();
    await _apiClient.postDataMap(
      'v1/devices',
      data: <String, Object?>{
        'client_device_id': clientDeviceId,
        'platform': metadata.platform,
        'name': metadata.name,
        'app_version': metadata.appVersion,
        'os_version': metadata.osVersion,
        'public_identity_key': publicIdentityKey,
      },
      allowAuthRetry: true,
    );
  }

  @override
  Future<List<MessageDevice>> getCircleMessageDevices(String circleId) async {
    final data = await _apiClient.getDataList(
      'v1/circles/$circleId/message-devices',
    );
    final devices = <MessageDevice>[];
    for (final rawMembership in data) {
      final membership = _stringMap(rawMembership);
      final userId = _asInt(membership['user_id'], 'user_id');
      final rawName = membership['name'];
      final displayName = rawName is String && rawName.trim().isNotEmpty
          ? rawName.trim()
          : 'Orbit member';
      final rawDevices = membership['devices'];
      if (rawDevices is! List) {
        throw const FormatException('Invalid Circle message-device response.');
      }
      for (final rawDevice in rawDevices) {
        final device = _stringMap(rawDevice);
        final identityValue = _asString(
          device['public_identity_key'],
          'public_identity_key',
        );
        final updatedAt = device['key_updated_at'];
        devices.add(
          MessageDevice(
            deviceId: _asString(device['device_id'], 'device_id'),
            userId: userId,
            displayName: displayName,
            platform: _asString(device['platform'], 'platform'),
            identity: DevicePublicIdentity.fromServerValue(identityValue),
            keyUpdatedAt: updatedAt is String && updatedAt.isNotEmpty
                ? DateTime.tryParse(updatedAt)
                : null,
          ),
        );
      }
    }
    return devices;
  }

  @override
  Future<void> sendEncryptedMessage({
    required String circleId,
    required String messageId,
    required String senderDeviceId,
    required DateTime clientSentAt,
    required List<OutboundEnvelope> envelopes,
  }) async {
    await _apiClient.postDataMap(
      'v1/circles/$circleId/messages',
      data: <String, Object?>{
        'message_id': messageId,
        'sender_device_id': senderDeviceId,
        'type': OrbitMessageType.text.apiValue,
        'client_sent_at': clientSentAt.toUtc().toIso8601String(),
        'envelopes': envelopes
            .map((item) => item.toJson())
            .toList(growable: false),
      },
      // message_id is the backend idempotency key, so a single auth replay is safe.
      allowAuthRetry: true,
    );
  }

  @override
  Future<MessageSyncPage> syncCircle({
    required String circleId,
    required String deviceId,
    required int afterId,
    int limit = 200,
  }) async {
    final data = await _apiClient.getDataMap(
      'v1/circles/$circleId/messages',
      queryParameters: <String, Object?>{
        'device_id': deviceId,
        'after_id': afterId,
        'limit': limit,
      },
    );
    final rawEnvelopes = data['envelopes'];
    if (rawEnvelopes is! List) {
      throw const FormatException('Invalid encrypted message sync response.');
    }
    final envelopes = rawEnvelopes
        .map((raw) => EncryptedInboundEnvelope.fromJson(_stringMap(raw)))
        .toList(growable: false);
    return MessageSyncPage(
      envelopes: envelopes,
      nextCursor: _asInt(data['next_cursor'], 'next_cursor'),
      hasMore: data['has_more'] == true,
    );
  }

  @override
  Future<void> acknowledgeDelivery(String envelopeId) async {
    await _apiClient.postDataMap(
      'v1/message-envelopes/$envelopeId/delivered',
      allowAuthRetry: true,
    );
  }

  @override
  Future<void> markRead(String circleId, String messageId) async {
    await _apiClient.postDataMap(
      'v1/circles/$circleId/messages/$messageId/read',
      allowAuthRetry: true,
    );
  }

  @override
  Future<void> sendTyping(String circleId, bool isTyping) async {
    await _apiClient.postDataMap(
      'v1/circles/$circleId/typing',
      data: <String, Object?>{'is_typing': isTyping},
    );
  }

  @override
  Future<MessagingSettings> getSettings() async {
    return MessagingSettings.fromJson(
      await _apiClient.getDataMap('v1/messaging/settings'),
    );
  }

  @override
  Future<MessagingSettings> updateSettings(bool readReceiptsEnabled) async {
    return MessagingSettings.fromJson(
      await _apiClient.patchDataMap(
        'v1/messaging/settings',
        data: <String, Object?>{'read_receipts_enabled': readReceiptsEnabled},
        allowAuthRetry: true,
      ),
    );
  }

  Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid Orbit messaging response.');
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  int _asInt(Object? value, String field) {
    return switch (value) {
      int item => item,
      num item => item.toInt(),
      String item =>
        int.tryParse(item) ??
            (throw FormatException('Invalid $field in messaging response.')),
      _ => throw FormatException('Invalid $field in messaging response.'),
    };
  }

  String _asString(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid $field in messaging response.');
    }
    return value;
  }
}
