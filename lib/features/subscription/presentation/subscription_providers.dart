import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/subscription_repository.dart';
import '../domain/orbit_subscription.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return HttpSubscriptionRepository(
    apiClient: ref.watch(orbitApiClientProvider),
  );
});

final currentSubscriptionProvider = FutureProvider<OrbitSubscription>((ref) {
  return ref.watch(subscriptionRepositoryProvider).loadCurrentSubscription();
});
