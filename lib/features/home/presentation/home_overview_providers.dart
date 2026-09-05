import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/api_home_overview_repository.dart';
import '../domain/home_overview.dart';

final homeOverviewRepositoryProvider = Provider<HomeOverviewRepository>((ref) {
  return ApiHomeOverviewRepository(
    apiClient: ref.watch(orbitApiClientProvider),
  );
});

final homeCirclesProvider = FutureProvider<List<HomeCircleSummary>>((ref) {
  return ref.watch(homeOverviewRepositoryProvider).listCircles();
});

final homeCirclePresenceProvider =
    FutureProvider.family<List<HomePresenceMember>, String>((ref, circleId) {
      return ref
          .watch(homeOverviewRepositoryProvider)
          .listCirclePresence(circleId);
    });
