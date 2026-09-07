class OrbitPushToken {
  const OrbitPushToken({required this.value, required this.provider});

  final String value;
  final String provider;
}

class OrbitPushWakeup {
  const OrbitPushWakeup({
    required this.notificationId,
    required this.kind,
    this.deepLink,
  });

  final String? notificationId;
  final String? kind;
  final Uri? deepLink;
}

abstract interface class PushTokenSource {
  bool get isAvailable;
  Future<bool> prepare();
  Future<OrbitPushToken?> currentToken();
  Stream<OrbitPushToken?> get tokenChanges;
  Stream<Uri> get openedUris;
  Stream<OrbitPushWakeup> get wakeups;
}

/// Safe default when Firebase Cloud Messaging is not configured for this build.
/// Orbit must never fabricate a provider token or report remote push as live.
class UnavailablePushTokenSource implements PushTokenSource {
  const UnavailablePushTokenSource();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> prepare() async => false;

  @override
  Future<OrbitPushToken?> currentToken() async => null;

  @override
  Stream<OrbitPushToken?> get tokenChanges => const Stream.empty();

  @override
  Stream<Uri> get openedUris => const Stream.empty();

  @override
  Stream<OrbitPushWakeup> get wakeups => const Stream.empty();
}
