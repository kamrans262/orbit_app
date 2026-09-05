enum PingStatus {
  pending,
  responded,
  dismissed,
  expired;

  static PingStatus parse(Object? value) {
    return switch (value) {
      'responded' => PingStatus.responded,
      'dismissed' => PingStatus.dismissed,
      'expired' => PingStatus.expired,
      _ => PingStatus.pending,
    };
  }
}

enum PingResponseType {
  hey,
  shareLocation;

  String get apiValue => switch (this) {
    PingResponseType.hey => 'hey',
    PingResponseType.shareLocation => 'share_location',
  };
}

class PingParty {
  const PingParty({
    required this.membershipId,
    required this.userId,
    required this.name,
  });

  final String membershipId;
  final int userId;
  final String name;
}

class PingItem {
  const PingItem({
    required this.id,
    required this.circleId,
    required this.circleName,
    required this.sender,
    required this.recipient,
    required this.status,
    required this.expiresAt,
    this.responseType,
    this.createdAt,
  });

  factory PingItem.fromJson(Map<String, Object?> json) {
    final circle = _stringMap(json['circle']);
    final sender = _stringMap(json['sender']);
    final recipient = _stringMap(json['recipient']);

    return PingItem(
      id: _requiredString(json, 'id'),
      circleId: _requiredString(circle, 'id'),
      circleName: _requiredString(circle, 'name'),
      sender: _party(sender),
      recipient: _party(recipient),
      status: PingStatus.parse(json['status']),
      responseType: _nullableString(json['response_type']),
      expiresAt: DateTime.parse(_requiredString(json, 'expires_at')),
      createdAt: _dateOrNull(json['created_at']),
    );
  }

  final String id;
  final String circleId;
  final String circleName;
  final PingParty sender;
  final PingParty recipient;
  final PingStatus status;
  final String? responseType;
  final DateTime expiresAt;
  final DateTime? createdAt;

  static PingParty _party(Map<String, Object?> json) {
    return PingParty(
      membershipId: _requiredString(json, 'membership_id'),
      userId: _requiredInt(json, 'user_id'),
      name: _nullableString(json['name']) ?? 'Orbit member',
    );
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid Ping response.');
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid Ping field: $key.');
    }
    return value;
  }

  static int _requiredInt(Map<String, Object?> json, String key) {
    final value = json[key];
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String text when int.tryParse(text) != null => int.parse(text),
      _ => throw FormatException('Invalid Ping field: $key.'),
    };
  }

  static String? _nullableString(Object? value) {
    return value is String && value.isNotEmpty ? value : null;
  }

  static DateTime? _dateOrNull(Object? value) {
    return value is String && value.isNotEmpty
        ? DateTime.tryParse(value)
        : null;
  }
}

class PingCircleOption {
  const PingCircleOption({
    required this.id,
    required this.name,
    required this.myMembershipId,
  });

  final String id;
  final String name;
  final String myMembershipId;
}

class PingTarget {
  const PingTarget({
    required this.membershipId,
    required this.name,
    required this.canPing,
  });

  final String membershipId;
  final String name;
  final bool canPing;
}
