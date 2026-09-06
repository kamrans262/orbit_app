import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_binary_transfer_client.dart';
import '../domain/media_models.dart';

abstract interface class MediaRemoteRepository {
  Future<MediaUploadTicket> createUpload({
    required String circleId,
    required String assetId,
    required String uploaderDeviceId,
    required OrbitMediaKind kind,
    required String contentTypeHint,
    required int sizeBytes,
    required String sha256Ciphertext,
  });

  Future<void> uploadChunk({
    required String uploadId,
    required int chunkIndex,
    required List<int> bytes,
  });

  Future<OrbitMediaAsset> completeUpload({
    required String uploadId,
    required List<OutboundMediaKeyEnvelope> keyEnvelopes,
  });

  Future<OrbitMediaAsset> getAsset(String assetId);

  Future<OrbitMediaKeyEnvelope> getKeyEnvelope({
    required String assetId,
    required String deviceId,
  });

  Future<void> downloadEncryptedAsset({
    required String assetId,
    required String deviceId,
    required String destinationPath,
  });

  Future<void> deleteAsset(String assetId);
}

class HttpMediaRemoteRepository implements MediaRemoteRepository {
  HttpMediaRemoteRepository({
    required OrbitApiClient apiClient,
    required OrbitBinaryTransferClient binaryClient,
  }) : this._(apiClient, binaryClient);

  HttpMediaRemoteRepository._(this._apiClient, this._binaryClient);

  final OrbitApiClient _apiClient;
  final OrbitBinaryTransferClient _binaryClient;

  @override
  Future<MediaUploadTicket> createUpload({
    required String circleId,
    required String assetId,
    required String uploaderDeviceId,
    required OrbitMediaKind kind,
    required String contentTypeHint,
    required int sizeBytes,
    required String sha256Ciphertext,
  }) async {
    final data = await _apiClient.postDataMap(
      'v1/circles/$circleId/media/uploads',
      data: <String, Object?>{
        'asset_id': assetId,
        'uploader_device_id': uploaderDeviceId,
        'kind': kind.apiValue,
        'content_type_hint': contentTypeHint,
        'size_bytes': sizeBytes,
        'sha256_ciphertext': sha256Ciphertext,
      },
      // Creating an upload is not server-idempotent; do not replay it after
      // an authentication refresh. The caller can retry explicitly.
      allowAuthRetry: false,
    );
    return MediaUploadTicket.fromJson(_stringMap(data));
  }

  @override
  Future<void> uploadChunk({
    required String uploadId,
    required int chunkIndex,
    required List<int> bytes,
  }) async {
    final digest = sha256.convert(bytes).toString();
    await _binaryClient.putBytes(
      'v1/media/uploads/$uploadId/chunks/$chunkIndex',
      bytes,
      headers: <String, String>{'X-Chunk-SHA256': digest},
      allowAuthRetry: true,
    );
  }

  @override
  Future<OrbitMediaAsset> completeUpload({
    required String uploadId,
    required List<OutboundMediaKeyEnvelope> keyEnvelopes,
  }) async {
    final data = await _apiClient.postDataMap(
      'v1/media/uploads/$uploadId/complete',
      data: <String, Object?>{
        'key_envelopes': keyEnvelopes
            .map((envelope) => envelope.toJson())
            .toList(growable: false),
      },
      // Completion is explicitly idempotent in Laravel: an already completed
      // upload returns its existing asset. A single auth replay is therefore safe.
      allowAuthRetry: true,
    );
    return OrbitMediaAsset.fromJson(_stringMap(data));
  }

  @override
  Future<OrbitMediaAsset> getAsset(String assetId) async {
    return OrbitMediaAsset.fromJson(
      _stringMap(await _apiClient.getDataMap('v1/media/$assetId')),
    );
  }

  @override
  Future<OrbitMediaKeyEnvelope> getKeyEnvelope({
    required String assetId,
    required String deviceId,
  }) async {
    return OrbitMediaKeyEnvelope.fromJson(
      _stringMap(
        await _apiClient.getDataMap(
          'v1/media/$assetId/key-envelope',
          queryParameters: <String, Object?>{'device_id': deviceId},
        ),
      ),
    );
  }

  @override
  Future<void> downloadEncryptedAsset({
    required String assetId,
    required String deviceId,
    required String destinationPath,
  }) {
    return _binaryClient.downloadToFile(
      'v1/media/$assetId/download',
      destinationPath,
      queryParameters: <String, Object?>{'device_id': deviceId},
    );
  }

  @override
  Future<void> deleteAsset(String assetId) {
    return _apiClient.delete(
      'v1/media/$assetId',
      // Laravel media deletion is not idempotent: a replay after a lost
      // response becomes MEDIA_ASSET_NOT_FOUND, so never replay automatically.
      allowAuthRetry: false,
    );
  }

  Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid Orbit media response.');
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}

Future<String> sha256File(String path) async {
  final file = File(path);
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}
