import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../circles/application/circle_change_signal.dart';
import '../data/api_home_overview_repository.dart';
import '../domain/home_overview.dart';

final homeOverviewRepositoryProvider = Provider<HomeOverviewRepository>((ref) {
  return ApiHomeOverviewRepository(
    apiClient: ref.watch(orbitApiClientProvider),
  );
});

final homeCirclesProvider = FutureProvider<List<HomeCircleSummary>>((ref) {
  ref.watch(circleChangeRevisionProvider);
  return ref.watch(homeOverviewRepositoryProvider).listCircles();
});

final homeCirclePresenceProvider =
    FutureProvider.family<List<HomePresenceMember>, String>((ref, circleId) {
      ref.watch(circleChangeRevisionProvider);
      return ref
          .watch(homeOverviewRepositoryProvider)
          .listCirclePresence(circleId);
    });
