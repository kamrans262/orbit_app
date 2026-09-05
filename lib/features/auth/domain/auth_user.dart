class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.emailVerifiedAt,
  });

  factory AuthUser.fromJson(Map<String, Object?> json) {
    final rawId = json['id'];
    final id = switch (rawId) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
    final email = json['email'];
    if (id == null || email is! String || email.isEmpty) {
      throw const FormatException('Invalid Orbit user response.');
    }

    final rawName = json['name'];
    final rawVerified = json['email_verified_at'];

    return AuthUser(
      id: id,
      email: email,
      name: rawName is String && rawName.trim().isNotEmpty
          ? rawName.trim()
          : null,
      emailVerifiedAt: rawVerified is String && rawVerified.isNotEmpty
          ? DateTime.tryParse(rawVerified)
          : null,
    );
  }

  final int id;
  final String email;
  final String? name;
  final DateTime? emailVerifiedAt;

  String get displayName => name ?? email.split('@').first;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'email': email,
    'name': name,
    'email_verified_at': emailVerifiedAt?.toUtc().toIso8601String(),
  };
}
