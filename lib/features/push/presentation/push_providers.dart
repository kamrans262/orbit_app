import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../messaging/presentation/device_identity_providers.dart';
import '../data/device_push_registration_service.dart';
import '../data/push_token_store.dart';
import '../domain/push_token_source.dart';

final pushTokenSourceProvider = Provider<PushTokenSource>((ref) {
  return const UnavailablePushTokenSource();
});

final devicePushRegistrationServiceProvider =
    Provider<DevicePushRegistrationService>((ref) {
      return DevicePushRegistrationService(
        apiClient: ref.watch(orbitApiClientProvider),
        sessionStore: ref.watch(sessionStoreProvider),
        clientDeviceIdStore: ref.watch(clientDeviceIdStoreProvider),
        deviceMetadataReader: ref.watch(deviceMetadataReaderProvider),
        identityStore: ref.watch(deviceIdentityStoreProvider),
        tokenStore: ref.watch(pushTokenStoreProvider),
      );
    });
