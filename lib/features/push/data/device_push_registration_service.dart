// ignore_for_file: prefer_initializing_formals

import '../../../core/device/device_metadata_service.dart';
import '../../../core/network/orbit_api_client.dart';
import '../../../core/security/local_device_id_store.dart';
import '../../../core/security/session_store.dart';
import '../../messaging/data/device_identity_store.dart';
import '../domain/push_token_source.dart';
import 'push_token_store.dart';

class DevicePushRegistrationService {
  DevicePushRegistrationService({
    required OrbitApiClient apiClient,
    required SessionStore sessionStore,
    required ClientDeviceIdStore clientDeviceIdStore,
    required DeviceMetadataReader deviceMetadataReader,
    required DeviceIdentityStore identityStore,
    required PushTokenStore tokenStore,
  }) : _apiClient = apiClient,
       _sessionStore = sessionStore,
       _clientDeviceIdStore = clientDeviceIdStore,
       _deviceMetadataReader = deviceMetadataReader,
       _identityStore = identityStore,
       _tokenStore = tokenStore;

  final OrbitApiClient _apiClient;
  final SessionStore _sessionStore;
  final ClientDeviceIdStore _clientDeviceIdStore;
  final DeviceMetadataReader _deviceMetadataReader;
  final DeviceIdentityStore _identityStore;
  final PushTokenStore _tokenStore;

  /// Synchronizes provider token registration or rotation without ever
  /// dropping the existing E2EE public identity. Laravel's device upsert
  /// treats omitted fields as null, therefore this payload is complete.
  Future<void> synchronize(OrbitPushToken? token) async {
    final session = await _sessionStore.read();
    if (session == null) {
      return;
    }

    final identity = token == null
        ? await _identityStore.read(session.deviceId)
        : await _identityStore.getOrCreate(session.deviceId);
    if (identity == null) {
      // M10 never registers a token without first creating an E2EE identity.
      // If neither exists locally, there is no safe complete upsert to send.
      if (await _tokenStore.read() != null) {
        throw StateError(
          'Orbit cannot unregister push until the local device identity is available.',
        );
      }
      return;
    }

    final clientDeviceId = await _clientDeviceIdStore.getOrCreate();
    final metadata = await _deviceMetadataReader.read();

    await _apiClient.postDataMap(
      'v1/devices',
      data: <String, Object?>{
        'client_device_id': clientDeviceId,
        'platform': metadata.platform,
        'name': metadata.name,
        'app_version': metadata.appVersion,
        'os_version': metadata.osVersion,
        'public_identity_key': identity.publicIdentity.toServerValue(),
        'push_token': token?.value,
      },
      allowAuthRetry: true,
    );

    if (token == null) {
      await _tokenStore.clear();
    } else {
      await _tokenStore.write(token.value);
    }
  }

  Future<void> unregister() => synchronize(null);
}
