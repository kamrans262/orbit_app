import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/orbit_api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../circles/presentation/circle_providers.dart';
import '../data/moments_repository.dart';
import '../domain/moment_models.dart';

final momentsRepositoryProvider = Provider<MomentsRepository>((ref) {
  return HttpMomentsRepository(apiClient: ref.watch(orbitApiClientProvider));
});

final circleMomentsProvider = FutureProvider.autoDispose
    .family<List<OrbitMoment>, String>((ref, circleId) {
      return ref.watch(momentsRepositoryProvider).listCircleMoments(circleId);
    });

final momentProvider = FutureProvider.autoDispose.family<OrbitMoment, String>((
  ref,
  momentId,
) {
  return ref.watch(momentsRepositoryProvider).getMoment(momentId);
});

final momentViewersProvider = FutureProvider.autoDispose
    .family<MomentViewers, String>((ref, momentId) {
      return ref.watch(momentsRepositoryProvider).listViewers(momentId);
    });

final recentMomentsProvider =
    FutureProvider.autoDispose<List<RecentMomentItem>>((ref) async {
      final circles = await ref.watch(circlesProvider.future);
      final repository = ref.watch(momentsRepositoryProvider);
      final recent = <RecentMomentItem>[];

      for (final circle in circles.where((item) => item.isActive).take(6)) {
        try {
          final moments = await repository.listCircleMoments(circle.id);
          recent.addAll(
            moments.map(
              (moment) =>
                  RecentMomentItem(moment: moment, circleName: circle.name),
            ),
          );
        } on OrbitApiException catch (error) {
          if (error.code != 'MOMENT_VIEWING_DISABLED') {
            rethrow;
          }
        }
      }

      recent.sort((a, b) => b.moment.createdAt.compareTo(a.moment.createdAt));
      return recent.take(12).toList(growable: false);
    });
