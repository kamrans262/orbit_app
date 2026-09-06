import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/auth/data/auth_repository.dart';
import '../config/app_environment.dart';
import '../device/device_metadata_service.dart';
import '../logging/orbit_logger.dart';
import '../network/dio_orbit_api_client.dart';
import '../network/orbit_api_client.dart';
import '../network/orbit_api_command_client.dart';
import '../network/orbit_api_envelope_client.dart';
import '../network/orbit_binary_transfer_client.dart';
import '../security/local_device_id_store.dart';
import '../security/pending_bootstrap_store.dart';
import '../security/session_store.dart';

final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  return AppEnvironment.fromDartDefines();
});

final orbitLoggerProvider = Provider<OrbitLogger>((ref) {
  return const OrbitLogger();
});

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SecureSessionStore(ref.watch(flutterSecureStorageProvider));
});

final pendingBootstrapStoreProvider = Provider<PendingBootstrapStore>((ref) {
  return SecurePendingBootstrapStore(ref.watch(flutterSecureStorageProvider));
});

final clientDeviceIdStoreProvider = Provider<ClientDeviceIdStore>((ref) {
  return SecureClientDeviceIdStore(ref.watch(flutterSecureStorageProvider));
});

final deviceMetadataReaderProvider = Provider<DeviceMetadataReader>((ref) {
  return DeviceMetadataService(DeviceInfoPlugin(), PackageInfo.fromPlatform);
});

final dioOrbitApiClientProvider = Provider<DioOrbitApiClient>((ref) {
  final client = DioOrbitApiClient(
    environment: ref.watch(appEnvironmentProvider),
    sessionStore: ref.watch(sessionStoreProvider),
    logger: ref.watch(orbitLoggerProvider),
  );
  ref.onDispose(client.close);
  return client;
});

final orbitApiClientProvider = Provider<OrbitApiClient>((ref) {
  return ref.watch(dioOrbitApiClientProvider);
});

final orbitApiEnvelopeClientProvider = Provider<OrbitApiEnvelopeClient>((ref) {
  return ref.watch(dioOrbitApiClientProvider);
});

final orbitApiCommandClientProvider = Provider<OrbitApiCommandClient>((ref) {
  return ref.watch(dioOrbitApiClientProvider);
});

final orbitBinaryTransferClientProvider = Provider<OrbitBinaryTransferClient>((
  ref,
) {
  return ref.watch(dioOrbitApiClientProvider);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HttpAuthRepository(
    apiClient: ref.watch(orbitApiClientProvider),
    sessionStore: ref.watch(sessionStoreProvider),
    pendingStore: ref.watch(pendingBootstrapStoreProvider),
    clientDeviceIdStore: ref.watch(clientDeviceIdStoreProvider),
    deviceMetadataReader: ref.watch(deviceMetadataReaderProvider),
    logger: ref.watch(orbitLoggerProvider),
  );
});
