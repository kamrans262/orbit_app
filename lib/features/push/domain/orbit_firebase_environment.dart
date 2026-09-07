import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class OrbitFirebaseEnvironment {
  const OrbitFirebaseEnvironment({
    required this.enabled,
    required this.projectId,
    required this.messagingSenderId,
    required this.androidApiKey,
    required this.androidAppId,
    required this.iosApiKey,
    required this.iosAppId,
    required this.iosBundleId,
  });

  factory OrbitFirebaseEnvironment.fromDartDefines() {
    return const OrbitFirebaseEnvironment(
      enabled: bool.fromEnvironment(
        'ORBIT_FIREBASE_ENABLED',
        defaultValue: false,
      ),
      projectId: String.fromEnvironment('ORBIT_FIREBASE_PROJECT_ID'),
      messagingSenderId: String.fromEnvironment(
        'ORBIT_FIREBASE_MESSAGING_SENDER_ID',
      ),
      androidApiKey: String.fromEnvironment('ORBIT_FIREBASE_ANDROID_API_KEY'),
      androidAppId: String.fromEnvironment('ORBIT_FIREBASE_ANDROID_APP_ID'),
      iosApiKey: String.fromEnvironment('ORBIT_FIREBASE_IOS_API_KEY'),
      iosAppId: String.fromEnvironment('ORBIT_FIREBASE_IOS_APP_ID'),
      iosBundleId: String.fromEnvironment('ORBIT_FIREBASE_IOS_BUNDLE_ID'),
    );
  }

  final bool enabled;
  final String projectId;
  final String messagingSenderId;
  final String androidApiKey;
  final String androidAppId;
  final String iosApiKey;
  final String iosAppId;
  final String iosBundleId;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  FirebaseOptions optionsForCurrentPlatform() {
    if (!enabled) {
      throw StateError('Orbit Firebase push is disabled for this build.');
    }
    if (!isSupportedPlatform) {
      throw UnsupportedError('Orbit Firebase push supports Android and iOS.');
    }
    _require(projectId, 'ORBIT_FIREBASE_PROJECT_ID');
    _require(messagingSenderId, 'ORBIT_FIREBASE_MESSAGING_SENDER_ID');

    if (defaultTargetPlatform == TargetPlatform.android) {
      _require(androidApiKey, 'ORBIT_FIREBASE_ANDROID_API_KEY');
      _require(androidAppId, 'ORBIT_FIREBASE_ANDROID_APP_ID');
      return FirebaseOptions(
        apiKey: androidApiKey,
        appId: androidAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
      );
    }

    _require(iosApiKey, 'ORBIT_FIREBASE_IOS_API_KEY');
    _require(iosAppId, 'ORBIT_FIREBASE_IOS_APP_ID');
    _require(iosBundleId, 'ORBIT_FIREBASE_IOS_BUNDLE_ID');
    return FirebaseOptions(
      apiKey: iosApiKey,
      appId: iosAppId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      iosBundleId: iosBundleId,
    );
  }

  void _require(String value, String name) {
    if (value.trim().isEmpty) {
      throw StateError('$name is required when ORBIT_FIREBASE_ENABLED=true.');
    }
  }
}
