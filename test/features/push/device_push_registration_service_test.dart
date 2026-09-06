import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/device/device_metadata_service.dart';
import 'package:orbit_app/core/network/orbit_api_client.dart';
import 'package:orbit_app/core/security/auth_session.dart';
import 'package:orbit_app/core/security/local_device_id_store.dart';
import 'package:orbit_app/core/security/session_store.dart';
import 'package:orbit_app/features/messaging/data/device_identity_store.dart';
import 'package:orbit_app/features/messaging/domain/e2ee_identity.dart';
import 'package:orbit_app/features/messaging/domain/messaging_models.dart';
import 'package:orbit_app/features/push/data/device_push_registration_service.dart';
import 'package:orbit_app/features/push/data/push_token_store.dart';
import 'package:orbit_app/features/push/domain/push_token_source.dart';

void main() {
  test('push synchronization preserves the E2EE public identity', () async {
    final api = _RecordingApiClient();
    final service = DevicePushRegistrationService(
      apiClient: api,
      sessionStore: _SessionStore(),
      clientDeviceIdStore: _ClientDeviceIdStore(),
      deviceMetadataReader: _DeviceMetadataReader(),
      identityStore: _IdentityStore(),
      tokenStore: _PushTokenStore(),
    );

    await service.synchronize(
      const OrbitPushToken(value: 'secret-token', provider: 'fcm'),
    );

    expect(api.lastPath, 'v1/devices');
    expect(api.lastData?['client_device_id'], 'client-device');
    expect(api.lastData?['public_identity_key'], isNotNull);
    expect(api.lastData?['push_token'], 'secret-token');
  });

  test('push unregister sends null token while preserving identity', () async {
    final api = _RecordingApiClient();
    final tokenStore = _PushTokenStore()..value = 'registered-token';
    final service = DevicePushRegistrationService(
      apiClient: api,
      sessionStore: _SessionStore(),
      clientDeviceIdStore: _ClientDeviceIdStore(),
      deviceMetadataReader: _DeviceMetadataReader(),
      identityStore: _IdentityStore(),
      tokenStore: tokenStore,
    );

    await service.unregister();

    expect(api.lastData?.containsKey('push_token'), isTrue);
    expect(api.lastData?['push_token'], isNull);
    expect(api.lastData?['public_identity_key'], isNotNull);
    expect(tokenStore.value, isNull);
  });
}

class _SessionStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => AuthSession(
    accessToken: 'access',
    accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshToken: 'refresh',
    refreshExpiresAt: DateTime.now().add(const Duration(days: 1)),
    sessionId: 'session',
    deviceId: 'server-device',
  );

  @override
  Future<void> write(AuthSession session) async {}
}

class _ClientDeviceIdStore implements ClientDeviceIdStore {
  @override
  Future<String> getOrCreate() async => 'client-device';
}

class _DeviceMetadataReader implements DeviceMetadataReader {
  @override
  Future<DeviceMetadata> read() async => const DeviceMetadata(
    platform: 'android',
    name: 'Test device',
    appVersion: '1.0.0',
    osVersion: '15',
  );
}

class _IdentityStore implements DeviceIdentityStore {
  @override
  Future<DevicePrivateIdentity?> read(String serverDeviceId) async {
    return _identity();
  }

  @override
  Future<DevicePrivateIdentity> getOrCreate(String serverDeviceId) async {
    return _identity();
  }

  DevicePrivateIdentity _identity() {
    final agreement = SimpleKeyPairData(
      List<int>.filled(32, 1),
      publicKey: SimplePublicKey(
        List<int>.filled(32, 2),
        type: KeyPairType.x25519,
      ),
      type: KeyPairType.x25519,
    );
    final signing = SimpleKeyPairData(
      List<int>.filled(32, 3),
      publicKey: SimplePublicKey(
        List<int>.filled(32, 4),
        type: KeyPairType.ed25519,
      ),
      type: KeyPairType.ed25519,
    );
    return DevicePrivateIdentity(
      keyAgreementKeyPair: agreement,
      signingKeyPair: signing,
      publicIdentity: DevicePublicIdentity(
        keyAgreementPublicKey: List<int>.filled(32, 2),
        signingPublicKey: List<int>.filled(32, 4),
      ),
    );
  }
}

class _RecordingApiClient implements OrbitApiClient {
  String? lastPath;
  Map<String, Object?>? lastData;

  @override
  Future<Map<String, dynamic>> postDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    lastPath = path;
    lastData = Map<String, Object?>.from(data! as Map);
    return <String, dynamic>{};
  }

  @override
  Future<void> delete(
    String path, {
    bool authenticated = true,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {}
  @override
  Future<Map<String, dynamic>> getDataMap(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async => <String, dynamic>{};
  @override
  Future<List<dynamic>> getDataList(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async => <dynamic>[];
  @override
  Future<Map<String, dynamic>> patchDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async => <String, dynamic>{};
  @override
  Future<Map<String, dynamic>> putDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async => <String, dynamic>{};
  @override
  Future<bool> refreshIdentitySession() async => false;
  @override
  void close() {}
}

class _PushTokenStore implements PushTokenStore {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;
}
