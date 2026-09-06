import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/orbit_api_exception.dart';
import '../../../core/security/session_store.dart';
import '../../messaging/application/messaging_service.dart';
import '../../messaging/data/device_identity_store.dart';
import '../../messaging/data/messaging_remote_repository.dart';
import '../../messaging/domain/messaging_models.dart';
import '../../moments/data/moments_repository.dart';
import '../../moments/domain/moment_models.dart';
import '../data/media_key_envelope_codec.dart';
import '../data/media_remote_repository.dart';
import '../data/orbit_media_file_cipher.dart';
import '../domain/media_models.dart';

class MediaMomentServiceException implements Exception {
  const MediaMomentServiceException(this.message);

  final String message;

  @override
  String toString() => 'MediaMomentServiceException($message)';
}

class MediaMomentService {
  MediaMomentService({
    required MediaRemoteRepository mediaRemote,
    required MomentsRepository moments,
    required MessagingRemoteRepository messagingRemote,
    required MessagingService messagingService,
    required DeviceIdentityStore identityStore,
    required SessionStore sessionStore,
    required OrbitMediaFileCipher fileCipher,
    required MediaKeyEnvelopeCodec keyEnvelopeCodec,
    Uuid uuid = const Uuid(),
  }) : this._(
         mediaRemote,
         moments,
         messagingRemote,
         messagingService,
         identityStore,
         sessionStore,
         fileCipher,
         keyEnvelopeCodec,
         uuid,
       );

  MediaMomentService._(
    this._mediaRemote,
    this._moments,
    this._messagingRemote,
    this._messagingService,
    this._identityStore,
    this._sessionStore,
    this._fileCipher,
    this._keyEnvelopeCodec,
    this._uuid,
  );

  final MediaRemoteRepository _mediaRemote;
  final MomentsRepository _moments;
  final MessagingRemoteRepository _messagingRemote;
  final MessagingService _messagingService;
  final DeviceIdentityStore _identityStore;
  final SessionStore _sessionStore;
  final OrbitMediaFileCipher _fileCipher;
  final MediaKeyEnvelopeCodec _keyEnvelopeCodec;
  final Uuid _uuid;

  Future<OrbitMoment> publishDraft({
    required MomentCaptureDraft draft,
    int ttlSeconds = 86400,
    void Function(double progress)? onProgress,
  }) async {
    final session = await _sessionStore.read();
    if (session == null) {
      throw const MediaMomentServiceException(
        'Your secure Orbit session is not available.',
      );
    }

    // Ensures this device has a published public identity before the backend
    // computes the server-authoritative media recipient device set.
    await _messagingService.identityFingerprint();

    final temp = await getTemporaryDirectory();
    final assetId = _uuid.v4();
    final momentId = _uuid.v4();
    final encryptedPath = p.join(temp.path, '$assetId.orbitcipher');
    OrbitMediaAsset? completedAsset;

    EncryptedMediaFile? encrypted;
    try {
      encrypted = await _fileCipher.encryptFile(
        sourcePath: draft.sourcePath,
        destinationPath: encryptedPath,
        onProgress: (value) => onProgress?.call(value * 0.25),
      );

      final recipients = await _messagingRemote.getCircleMessageDevices(
        draft.circleId,
      );
      await _messagingService.validatePeerDevices(recipients);
      if (recipients.isEmpty) {
        throw const MediaMomentServiceException(
          'No encryption-ready device is available for this Circle.',
        );
      }

      final ticket = await _mediaRemote.createUpload(
        circleId: draft.circleId,
        assetId: assetId,
        uploaderDeviceId: session.deviceId,
        kind: draft.kind,
        contentTypeHint: draft.contentTypeHint,
        sizeBytes: encrypted.sizeBytes,
        sha256Ciphertext: encrypted.sha256Ciphertext,
      );
      final expectedChunks =
          (encrypted.sizeBytes + ticket.chunkSizeBytes - 1) ~/
          ticket.chunkSizeBytes;
      if (ticket.assetId != assetId || ticket.totalChunks != expectedChunks) {
        throw const MediaMomentServiceException(
          'Orbit returned an inconsistent encrypted upload ticket.',
        );
      }

      await _uploadFile(
        encryptedPath: encrypted.path,
        ticket: ticket,
        onProgress: (value) => onProgress?.call(0.25 + (value * 0.55)),
      );

      completedAsset = await _completeWithCurrentRecipients(
        ticket: ticket,
        circleId: draft.circleId,
        mediaKeyBytes: encrypted.mediaKeyBytes,
        recipients: recipients,
      );
      if (completedAsset.assetId != assetId ||
          completedAsset.circleId != draft.circleId ||
          completedAsset.sizeBytes != encrypted.sizeBytes ||
          completedAsset.sha256Ciphertext.toLowerCase() !=
              encrypted.sha256Ciphertext.toLowerCase()) {
        throw const MediaMomentServiceException(
          'Orbit returned inconsistent encrypted media metadata.',
        );
      }
      onProgress?.call(0.9);

      final moment = await _moments.publishMoment(
        circleId: draft.circleId,
        momentId: momentId,
        mediaAssetId: completedAsset.assetId,
        ttlSeconds: ttlSeconds,
      );
      onProgress?.call(1);
      await _deleteIfExists(draft.sourcePath);
      return moment;
    } on Object {
      if (completedAsset != null) {
        try {
          await _mediaRemote.deleteAsset(completedAsset.assetId);
        } on Object {
          // Best-effort cleanup only. The backend's encrypted-media retention
          // lifecycle still guarantees eventual cleanup.
        }
      }
      rethrow;
    } finally {
      if (encrypted != null) {
        // Best-effort overwrite of the in-memory content key before releasing
        // the object. Dart does not guarantee physical memory erasure.
        encrypted.mediaKeyBytes.fillRange(0, encrypted.mediaKeyBytes.length, 0);
      }
      await _deleteIfExists(encryptedPath);
    }
  }

  Future<PreparedMediaFile> prepareMomentMedia(OrbitMoment moment) async {
    final session = await _sessionStore.read();
    if (session == null) {
      throw const MediaMomentServiceException(
        'Your secure Orbit session is not available.',
      );
    }
    await _messagingService.identityFingerprint();
    final identity = await _identityStore.getOrCreate(session.deviceId);
    final envelope = await _mediaRemote.getKeyEnvelope(
      assetId: moment.media.assetId,
      deviceId: session.deviceId,
    );
    final keyBytes = await _keyEnvelopeCodec.unwrap(
      envelope: envelope,
      circleId: moment.circleId,
      recipientIdentity: identity,
    );

    final temp = await getTemporaryDirectory();
    final localToken = _uuid.v4();
    final encryptedPath = p.join(temp.path, '$localToken.download.orbitcipher');
    final extension = moment.media.kind == OrbitMediaKind.image
        ? '.jpg'
        : '.mp4';
    final clearPath = p.join(temp.path, '$localToken.view$extension');

    try {
      await _mediaRemote.downloadEncryptedAsset(
        assetId: moment.media.assetId,
        deviceId: session.deviceId,
        destinationPath: encryptedPath,
      );

      final digest = await sha256File(encryptedPath);
      if (digest.toLowerCase() != moment.media.sha256Ciphertext.toLowerCase()) {
        throw const MediaMomentServiceException(
          'Encrypted Moment media failed its integrity check.',
        );
      }
      await _fileCipher.decryptFile(
        encryptedPath: encryptedPath,
        destinationPath: clearPath,
        mediaKeyBytes: keyBytes,
      );
      return PreparedMediaFile(path: clearPath, kind: moment.media.kind);
    } on Object {
      await _deleteIfExists(clearPath);
      rethrow;
    } finally {
      keyBytes.fillRange(0, keyBytes.length, 0);
      await _deleteIfExists(encryptedPath);
    }
  }

  Future<OrbitMediaAsset> _completeWithCurrentRecipients({
    required MediaUploadTicket ticket,
    required String circleId,
    required List<int> mediaKeyBytes,
    required List<MessageDevice> recipients,
  }) async {
    var currentRecipients = recipients;
    for (var attempt = 0; attempt < 2; attempt++) {
      final envelopes = await _wrapForRecipients(
        assetId: ticket.assetId,
        circleId: circleId,
        mediaKeyBytes: mediaKeyBytes,
        recipients: currentRecipients,
      );
      try {
        return await _mediaRemote.completeUpload(
          uploadId: ticket.uploadId,
          keyEnvelopes: envelopes,
        );
      } on OrbitApiException catch (error) {
        if (error.code != 'MEDIA_STALE_DEVICE_SET' || attempt == 1) {
          rethrow;
        }
        currentRecipients = await _messagingRemote.getCircleMessageDevices(
          circleId,
        );
        await _messagingService.validatePeerDevices(currentRecipients);
      }
    }
    throw const MediaMomentServiceException(
      'Orbit could not finalize encrypted media.',
    );
  }

  Future<List<OutboundMediaKeyEnvelope>> _wrapForRecipients({
    required String assetId,
    required String circleId,
    required List<int> mediaKeyBytes,
    required List<MessageDevice> recipients,
  }) async {
    if (recipients.isEmpty) {
      throw const MediaMomentServiceException(
        'No encryption-ready devices are available for this Circle.',
      );
    }
    final envelopes = <OutboundMediaKeyEnvelope>[];
    for (final recipient in recipients) {
      envelopes.add(
        await _keyEnvelopeCodec.wrap(
          assetId: assetId,
          circleId: circleId,
          recipient: recipient,
          mediaKeyBytes: mediaKeyBytes,
        ),
      );
    }
    return envelopes;
  }

  Future<void> _uploadFile({
    required String encryptedPath,
    required MediaUploadTicket ticket,
    void Function(double progress)? onProgress,
  }) async {
    final file = await File(encryptedPath).open();
    try {
      for (var index = 0; index < ticket.totalChunks; index++) {
        final bytes = await file.read(ticket.chunkSizeBytes);
        if (bytes.isEmpty) {
          throw const MediaMomentServiceException(
            'Encrypted media ended before all upload chunks were produced.',
          );
        }
        await _mediaRemote.uploadChunk(
          uploadId: ticket.uploadId,
          chunkIndex: index,
          bytes: bytes,
        );
        onProgress?.call((index + 1) / ticket.totalChunks);
      }
      final extra = await file.read(1);
      if (extra.isNotEmpty) {
        throw const MediaMomentServiceException(
          'Encrypted media exceeded the upload contract size.',
        );
      }
    } finally {
      await file.close();
    }
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      try {
        await file.delete();
      } on FileSystemException {
        // Temporary-file cleanup is best effort. OS cache cleanup remains a
        // final fallback and plaintext is never uploaded to Laravel.
      }
    }
  }
}
