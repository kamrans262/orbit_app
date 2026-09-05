class OtpChallenge {
  const OtpChallenge({required this.email, required this.expiresAt});

  final String email;
  final DateTime expiresAt;
}
