import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../domain/push_token_source.dart';

class FirebasePushTokenSource implements PushTokenSource {
  FirebasePushTokenSource({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  bool _prepared = false;

  @override
  bool get isAvailable => true;

  @override
  Future<bool> prepare() async {
    if (_prepared) {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus != AuthorizationStatus.denied;
    }
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
    );
    // Foreground FCM is a wake-up signal only. Orbit refreshes its durable
    // Laravel-backed inbox instead of showing a duplicate OS banner.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    }
    _prepared = true;
    return settings.authorizationStatus != AuthorizationStatus.denied;
  }

  @override
  Future<OrbitPushToken?> currentToken() async {
    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        await _messaging.getAPNSToken() == null) {
      // Apple requires the APNs token to exist before FCM token API calls.
      // Returning null here means "not ready yet"; the runtime retries later.
      return null;
    }
    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return OrbitPushToken(value: token.trim(), provider: 'fcm');
  }

  @override
  Stream<OrbitPushToken?> get tokenChanges =>
      _messaging.onTokenRefresh.map<OrbitPushToken?>((token) {
        final value = token.trim();
        return value.isEmpty
            ? null
            : OrbitPushToken(value: value, provider: 'fcm');
      });

  @override
  Stream<Uri> get openedUris async* {
    final initial = await _messaging.getInitialMessage();
    final initialUri = _deepLink(initial);
    if (initialUri != null) {
      yield initialUri;
    }

    await for (final message in FirebaseMessaging.onMessageOpenedApp) {
      final uri = _deepLink(message);
      if (uri != null) {
        yield uri;
      }
    }
  }

  @override
  Stream<OrbitPushWakeup> get wakeups => FirebaseMessaging.onMessage.map(
    (message) => OrbitPushWakeup(
      notificationId: _string(message.data['notification_id']),
      kind: _string(message.data['kind']),
      deepLink: _deepLink(message),
    ),
  );

  Uri? _deepLink(RemoteMessage? message) {
    if (message == null) {
      return null;
    }
    final value = _string(message.data['deep_link']);
    return value == null ? null : Uri.tryParse(value);
  }

  String? _string(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
