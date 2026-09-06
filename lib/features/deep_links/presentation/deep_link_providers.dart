import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../push/presentation/push_providers.dart';
import '../data/app_links_ingress.dart';
import '../domain/orbit_deep_link_resolver.dart';

final orbitDeepLinkResolverProvider = Provider<OrbitDeepLinkResolver>((ref) {
  return const OrbitDeepLinkResolver();
});

final deepLinkIngressProvider = Provider<DeepLinkIngress>((ref) {
  final pushSource = ref.watch(pushTokenSourceProvider);
  return CompositeDeepLinkIngress(
    appLinks: AppLinksDeepLinkIngress(),
    pushOpenedUris: pushSource.openedUris,
  );
});
