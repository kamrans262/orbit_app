enum OrbitMediaKind {
  image('image'),
  video('video');

  const OrbitMediaKind(this.apiValue);
  final String apiValue;

  static OrbitMediaKind parse(Object? value) {
    return switch (value) {
      'image' => OrbitMediaKind.image,
      'video' => OrbitMediaKind.video,
      _ => throw FormatException('Unsupported Orbit media kind: $value'),
    };
  }
}

class MediaUploadTicket {
  const MediaUploadTicket({
    required this.uploadId,
    required this.assetId,
    required this.chunkSizeBytes,
    required this.totalChunks,
    required this.expiresAt,
  });

  factory MediaUploadTicket.fromJson(Map<String, Object?> json) {
    final chunkSizeBytes = _requiredInt(json, 'chunk_size_bytes');
    final totalChunks = _requiredInt(json, 'total_chunks');
    if (chunkSizeBytes <= 0 || totalChunks <= 0) {
      throw const FormatException('Invalid encrypted media upload ticket.');
    }
    return MediaUploadTicket(
      uploadId: _requiredString(json, 'upload_id'),
      assetId: _requiredString(json, 'asset_id'),
      chunkSizeBytes: chunkSizeBytes,
      totalChunks: totalChunks,
      expiresAt: DateTime.parse(_requiredString(json, 'expires_at')),
    );
  }

  final String uploadId;
  final String assetId;
  final int chunkSizeBytes;
  final int totalChunks;
  final DateTime expiresAt;
}

class OrbitMediaAsset {
  const OrbitMediaAsset({
    required this.assetId,
    required this.circleId,
    required this.kind,
    required this.sizeBytes,
    required this.sha256Ciphertext,
    this.contentTypeHint,
    this.expiresAt,
    this.createdAt,
  });

  factory OrbitMediaAsset.fromJson(Map<String, Object?> json) {
    final sizeBytes = _requiredInt(json, 'size_bytes');
    final sha256Ciphertext = _requiredString(json, 'sha256_ciphertext');
    if (sizeBytes <= 0 || !_isSha256Hex(sha256Ciphertext)) {
      throw const FormatException('Invalid encrypted media metadata.');
    }
    return OrbitMediaAsset(
      assetId: _requiredString(json, 'asset_id'),
      circleId: _requiredString(json, 'circle_id'),
      kind: OrbitMediaKind.parse(json['kind']),
      contentTypeHint: _nullableString(json['content_type_hint']),
      sizeBytes: sizeBytes,
      sha256Ciphertext: sha256Ciphertext.toLowerCase(),
      expiresAt: _nullableDate(json['expires_at']),
      createdAt: _nullableDate(json['created_at']),
    );
  }

  final String assetId;
  final String circleId;
  final OrbitMediaKind kind;
  final String? contentTypeHint;
  final int sizeBytes;
  final String sha256Ciphertext;
  final DateTime? expiresAt;
  final DateTime? createdAt;
}

class OrbitMediaKeyEnvelope {
  const OrbitMediaKeyEnvelope({
    required this.assetId,
    required this.recipientDeviceId,
    required this.algorithm,
    required this.encryptedKey,
  });

  factory OrbitMediaKeyEnvelope.fromJson(Map<String, Object?> json) {
    return OrbitMediaKeyEnvelope(
      assetId: _requiredString(json, 'asset_id'),
      recipientDeviceId: _requiredString(json, 'recipient_device_id'),
      algorithm: _requiredString(json, 'algorithm'),
      encryptedKey: _requiredString(json, 'encrypted_key'),
    );
  }

  final String assetId;
  final String recipientDeviceId;
  final String algorithm;
  final String encryptedKey;
}

class OutboundMediaKeyEnvelope {
  const OutboundMediaKeyEnvelope({
    required this.recipientDeviceId,
    required this.algorithm,
    required this.encryptedKey,
  });

  final String recipientDeviceId;
  final String algorithm;
  final String encryptedKey;

  Map<String, Object?> toJson() => <String, Object?>{
    'recipient_device_id': recipientDeviceId,
    'algorithm': algorithm,
    'encrypted_key': encryptedKey,
  };
}

class EncryptedMediaFile {
  const EncryptedMediaFile({
    required this.path,
    required this.sizeBytes,
    required this.sha256Ciphertext,
    required this.mediaKeyBytes,
  });

  final String path;
  final int sizeBytes;
  final String sha256Ciphertext;
  final List<int> mediaKeyBytes;
}

class PreparedMediaFile {
  const PreparedMediaFile({required this.path, required this.kind});

  final String path;
  final OrbitMediaKind kind;
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Invalid $key in media response.');
  }
  return value;
}

String? _nullableString(Object? value) {
  return value is String && value.isNotEmpty ? value : null;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  return switch (value) {
    int item => item,
    num item => item.toInt(),
    String item =>
      int.tryParse(item) ??
          (throw FormatException('Invalid $key in media response.')),
    _ => throw FormatException('Invalid $key in media response.'),
  };
}

bool _isSha256Hex(String value) {
  if (value.length != 64) {
    return false;
  }
  return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value);
}

DateTime? _nullableDate(Object? value) {
  return value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
}
