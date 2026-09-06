import 'dart:convert';

enum OrbitMessageType {
  text('text'),
  media('media'),
  voice('voice');

  const OrbitMessageType(this.apiValue);
  final String apiValue;

  static OrbitMessageType parse(Object? value) {
    return switch (value) {
      'text' => OrbitMessageType.text,
      'media' => OrbitMessageType.media,
      'voice' => OrbitMessageType.voice,
      _ => throw FormatException('Unsupported Orbit message type: $value'),
    };
  }
}

enum LocalMessageDirection { incoming, outgoing }

enum LocalMessageStatus { sending, sent, delivered, failed }

class DevicePublicIdentity {
  const DevicePublicIdentity({
    required this.keyAgreementPublicKey,
    required this.signingPublicKey,
  });

  factory DevicePublicIdentity.fromServerValue(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Invalid device identity key bundle.');
    }
    final map = decoded.map((key, item) => MapEntry(key.toString(), item));
    if (map['v'] != 1 || map['kx'] is! String || map['sig'] is! String) {
      throw const FormatException('Unsupported device identity key bundle.');
    }
    return DevicePublicIdentity(
      keyAgreementPublicKey: base64Url.decode(map['kx']! as String),
      signingPublicKey: base64Url.decode(map['sig']! as String),
    );
  }

  final List<int> keyAgreementPublicKey;
  final List<int> signingPublicKey;

  String toServerValue() => jsonEncode(<String, Object>{
    'v': 1,
    'kx': base64Url.encode(keyAgreementPublicKey),
    'sig': base64Url.encode(signingPublicKey),
  });
}

class MessageDevice {
  const MessageDevice({
    required this.deviceId,
    required this.userId,
    required this.displayName,
    required this.platform,
    required this.identity,
    this.keyUpdatedAt,
  });

  final String deviceId;
  final int userId;
  final String displayName;
  final String platform;
  final DevicePublicIdentity identity;
  final DateTime? keyUpdatedAt;
}

class OutboundEnvelope {
  const OutboundEnvelope({
    required this.envelopeId,
    required this.recipientDeviceId,
    required this.ciphertext,
    this.encryptedPreview,
  });

  final String envelopeId;
  final String recipientDeviceId;
  final String ciphertext;
  final String? encryptedPreview;

  Map<String, Object?> toJson() => <String, Object?>{
    'envelope_id': envelopeId,
    'recipient_device_id': recipientDeviceId,
    'ciphertext': ciphertext,
    'encrypted_preview': encryptedPreview,
  };
}

class EncryptedInboundEnvelope {
  const EncryptedInboundEnvelope({
    required this.serverCursor,
    required this.envelopeId,
    required this.messageId,
    required this.circleId,
    required this.senderUserId,
    required this.senderDeviceId,
    required this.recipientDeviceId,
    required this.type,
    required this.ciphertext,
    required this.createdAt,
    required this.expiresAt,
  });

  factory EncryptedInboundEnvelope.fromJson(Map<String, Object?> json) {
    return EncryptedInboundEnvelope(
      serverCursor: _asInt(json['server_cursor'], 'server_cursor'),
      envelopeId: _asString(json['envelope_id'], 'envelope_id'),
      messageId: _asString(json['message_id'], 'message_id'),
      circleId: _asString(json['circle_id'], 'circle_id'),
      senderUserId: _asInt(json['sender_user_id'], 'sender_user_id'),
      senderDeviceId: _asString(json['sender_device_id'], 'sender_device_id'),
      recipientDeviceId: _asString(
        json['recipient_device_id'],
        'recipient_device_id',
      ),
      type: OrbitMessageType.parse(json['type']),
      ciphertext: _asString(json['ciphertext'], 'ciphertext'),
      createdAt: DateTime.parse(_asString(json['created_at'], 'created_at')),
      expiresAt: DateTime.parse(_asString(json['expires_at'], 'expires_at')),
    );
  }

  final int serverCursor;
  final String envelopeId;
  final String messageId;
  final String circleId;
  final int senderUserId;
  final String senderDeviceId;
  final String recipientDeviceId;
  final OrbitMessageType type;
  final String ciphertext;
  final DateTime createdAt;
  final DateTime expiresAt;
}

class MessageSyncPage {
  const MessageSyncPage({
    required this.envelopes,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<EncryptedInboundEnvelope> envelopes;
  final int nextCursor;
  final bool hasMore;
}

class LocalMessage {
  const LocalMessage({
    required this.messageId,
    required this.circleId,
    required this.senderUserId,
    required this.senderDeviceId,
    required this.direction,
    required this.type,
    required this.body,
    required this.createdAt,
    required this.status,
  });

  final String messageId;
  final String circleId;
  final int senderUserId;
  final String senderDeviceId;
  final LocalMessageDirection direction;
  final OrbitMessageType type;
  final String body;
  final DateTime createdAt;
  final LocalMessageStatus status;
}

class MessagingSettings {
  const MessagingSettings({required this.readReceiptsEnabled});

  factory MessagingSettings.fromJson(Map<String, Object?> json) {
    final enabled = json['read_receipts_enabled'];
    if (enabled is! bool) {
      throw const FormatException('Invalid messaging settings response.');
    }
    return MessagingSettings(readReceiptsEnabled: enabled);
  }

  final bool readReceiptsEnabled;
}

class ConversationSnapshot {
  const ConversationSnapshot({
    required this.messages,
    required this.identityFingerprint,
    required this.readReceiptsEnabled,
  });

  final List<LocalMessage> messages;
  final String identityFingerprint;
  final bool readReceiptsEnabled;
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
