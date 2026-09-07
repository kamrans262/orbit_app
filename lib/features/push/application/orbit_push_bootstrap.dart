import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../data/firebase_push_token_source.dart';
import '../domain/orbit_firebase_environment.dart';
import '../domain/push_token_source.dart';

@pragma('vm:entry-point')
Future<void> orbitFirebaseMessagingBackgroundHandler(RemoteMessage _) async {
  final environment = OrbitFirebaseEnvironment.fromDartDefines();
  if (!environment.enabled || !environment.isSupportedPlatform) {
    return;
  }
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: environment.optionsForCurrentPlatform(),
    );
  }
  // No notification payload is persisted or logged here. Background pushes
  // are wake-up signals; durable state is fetched from Laravel on resume/open.
}

class OrbitPushBootstrap {
  const OrbitPushBootstrap._();

  static Future<PushTokenSource> createSource() async {
    final environment = OrbitFirebaseEnvironment.fromDartDefines();
    if (!environment.enabled || !environment.isSupportedPlatform) {
      return const UnavailablePushTokenSource();
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: environment.optionsForCurrentPlatform(),
      );
    }
    FirebaseMessaging.onBackgroundMessage(
      orbitFirebaseMessagingBackgroundHandler,
    );
    return FirebasePushTokenSource();
  }
}
