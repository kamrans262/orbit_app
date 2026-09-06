class OrbitPushToken {
  const OrbitPushToken({required this.value, required this.provider});

  final String value;
  final String provider;
}

abstract interface class PushTokenSource {
  bool get isAvailable;
  Future<OrbitPushToken?> currentToken();
  Stream<OrbitPushToken?> get tokenChanges;
  Stream<Uri> get openedUris;
}

/// Safe default until a concrete APNS/FCM provider adapter is configured.
/// The Laravel contract is provider-neutral, so Orbit must not fabricate a
/// token or pretend remote push is live when no sender/provider is installed.
class UnavailablePushTokenSource implements PushTokenSource {
  const UnavailablePushTokenSource();

  @override
  bool get isAvailable => false;

  @override
  Future<OrbitPushToken?> currentToken() async => null;

  @override
  Stream<OrbitPushToken?> get tokenChanges => const Stream.empty();

  @override
  Stream<Uri> get openedUris => const Stream.empty();
}
