import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../circles/presentation/circle_providers.dart';
import '../../domain/moment_models.dart';
import '../moment_providers.dart';
import '../widgets/moment_summary_card.dart';

class CircleMomentsPage extends ConsumerWidget {
  const CircleMomentsPage({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = ref.watch(circleDetailProvider(circleId));
    final moments = ref.watch(circleMomentsProvider(circleId));

    return Scaffold(
      appBar: AppBar(
        title: Text(circle.asData?.value.name ?? 'Moments'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Capture Moment',
            onPressed: () => context.go('/camera?circleId=$circleId'),
            icon: const Icon(Icons.add_a_photo_rounded),
          ),
        ],
      ),
      body: moments.when(
        loading: () => const OrbitLoadingState(),
        error: (_, _) => OrbitErrorState(
          title: 'Moments could not be loaded',
          message: 'Check your connection or Circle Moment permissions.',
          onRetry: () => ref.invalidate(circleMomentsProvider(circleId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(OrbitSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const OrbitEmptyState(
                      title: 'No Moments yet',
                      message:
                          'Capture a private encrypted photo or video for this Circle.',
                    ),
                    const SizedBox(height: OrbitSpacing.md),
                    FilledButton.icon(
                      onPressed: () => context.go('/camera?circleId=$circleId'),
                      icon: const Icon(Icons.add_a_photo_rounded),
                      label: const Text('Open camera'),
                    ),
                  ],
                ),
              ),
            );
          }
          final circleName = circle.asData?.value.name ?? 'Circle';
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(circleMomentsProvider(circleId));
              await ref.read(circleMomentsProvider(circleId).future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                OrbitSpacing.md,
                OrbitSpacing.md,
                OrbitSpacing.md,
                96,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: OrbitSpacing.sm),
              itemBuilder: (context, index) {
                final moment = items[index];
                return MomentSummaryCard(
                  item: RecentMomentItem(
                    moment: moment,
                    circleName: circleName,
                  ),
                  onTap: () => context.push('/moments/${moment.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
