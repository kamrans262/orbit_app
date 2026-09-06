import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../push/data/push_token_store.dart';
import '../application/messaging_service.dart';
import '../data/message_local_store.dart';
import '../data/messaging_remote_repository.dart';
import '../data/orbit_e2ee_codec.dart';
import '../domain/messaging_models.dart';
import 'device_identity_providers.dart';

final messageLocalStoreProvider = Provider<MessageLocalStore>((ref) {
  final store = SqliteEncryptedMessageLocalStore(
    ref.watch(flutterSecureStorageProvider),
  );
  ref.onDispose(() {
    store.close();
  });
  return store;
});

final orbitE2eeCodecProvider = Provider<OrbitE2eeCodec>((ref) {
  return OrbitE2eeCodec();
});

final messagingRemoteRepositoryProvider = Provider<MessagingRemoteRepository>((
  ref,
) {
  return HttpMessagingRemoteRepository(
    apiClient: ref.watch(orbitApiClientProvider),
    clientDeviceIdStore: ref.watch(clientDeviceIdStoreProvider),
    deviceMetadataReader: ref.watch(deviceMetadataReaderProvider),
    pushTokenStore: ref.watch(pushTokenStoreProvider),
  );
});

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(
    remote: ref.watch(messagingRemoteRepositoryProvider),
    local: ref.watch(messageLocalStoreProvider),
    identityStore: ref.watch(deviceIdentityStoreProvider),
    codec: ref.watch(orbitE2eeCodecProvider),
    sessionStore: ref.watch(sessionStoreProvider),
  );
});

final circleConversationProvider = FutureProvider.autoDispose
    .family<ConversationSnapshot, String>((ref, circleId) async {
      final auth = await ref.watch(authControllerProvider.future);
      final user = auth.user;
      if (user == null) {
        throw const MessagingServiceException(
          'Sign in to open Circle messages.',
        );
      }
      return ref
          .watch(messagingServiceProvider)
          .loadConversation(circleId: circleId, currentUserId: user.id);
    });

final messagingIdentityFingerprintProvider = FutureProvider.autoDispose<String>(
  (ref) async {
    return ref.watch(messagingServiceProvider).identityFingerprint();
  },
);

final messagingSettingsProvider = FutureProvider.autoDispose<MessagingSettings>(
  (ref) async {
    return ref.watch(messagingServiceProvider).getSettings();
  },
);
