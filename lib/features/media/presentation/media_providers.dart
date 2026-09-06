import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../messaging/presentation/messaging_providers.dart';
import '../../moments/presentation/moment_providers.dart';
import '../application/media_moment_service.dart';
import '../data/media_key_envelope_codec.dart';
import '../data/media_remote_repository.dart';
import '../data/orbit_media_file_cipher.dart';

final mediaRemoteRepositoryProvider = Provider<MediaRemoteRepository>((ref) {
  return HttpMediaRemoteRepository(
    apiClient: ref.watch(orbitApiClientProvider),
    binaryClient: ref.watch(orbitBinaryTransferClientProvider),
  );
});

final orbitMediaFileCipherProvider = Provider<OrbitMediaFileCipher>((ref) {
  return OrbitMediaFileCipher();
});

final mediaKeyEnvelopeCodecProvider = Provider<MediaKeyEnvelopeCodec>((ref) {
  return MediaKeyEnvelopeCodec();
});

final mediaMomentServiceProvider = Provider<MediaMomentService>((ref) {
  return MediaMomentService(
    mediaRemote: ref.watch(mediaRemoteRepositoryProvider),
    moments: ref.watch(momentsRepositoryProvider),
    messagingRemote: ref.watch(messagingRemoteRepositoryProvider),
    messagingService: ref.watch(messagingServiceProvider),
    identityStore: ref.watch(deviceIdentityStoreProvider),
    sessionStore: ref.watch(sessionStoreProvider),
    fileCipher: ref.watch(orbitMediaFileCipherProvider),
    keyEnvelopeCodec: ref.watch(mediaKeyEnvelopeCodecProvider),
  );
});
