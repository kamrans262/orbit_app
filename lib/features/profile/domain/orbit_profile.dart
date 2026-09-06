class OrbitProfile {
  const OrbitProfile({
    required this.id,
    required this.email,
    this.name,
    this.emailVerifiedAt,
    this.timezone,
    this.locale,
    this.createdAt,
    this.updatedAt,
  });

  factory OrbitProfile.fromJson(Map<String, Object?> json) {
    final id = _intValue(json['id']);
    final email = json['email'];
    if (id == null || email is! String || email.isEmpty) {
      throw const FormatException('Invalid Orbit profile response.');
    }

    return OrbitProfile(
      id: id,
      email: email,
      name: _nullableString(json['name']),
      emailVerifiedAt: _dateValue(json['email_verified_at']),
      timezone: _nullableString(json['timezone']),
      locale: _nullableString(json['locale']),
      createdAt: _dateValue(json['created_at']),
      updatedAt: _dateValue(json['updated_at']),
    );
  }

  final int id;
  final String email;
  final String? name;
  final DateTime? emailVerifiedAt;
  final String? timezone;
  final String? locale;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName {
    final value = name?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return email.split('@').first;
  }

  static int? _intValue(Object? value) {
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String text => int.tryParse(text),
      _ => null,
    };
  }

  static String? _nullableString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _dateValue(Object? value) {
    return value is String && value.isNotEmpty
        ? DateTime.tryParse(value)
        : null;
  }
}
