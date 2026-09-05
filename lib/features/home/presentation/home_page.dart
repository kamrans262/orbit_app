import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../core/widgets/orbit_feedback_state.dart';
import '../../../core/widgets/orbit_section_header.dart';
import '../domain/home_dashboard.dart';
import 'home_providers.dart';
import 'widgets/activity_tile.dart';
import 'widgets/circle_summary_card.dart';
import 'widgets/home_header.dart';
import 'widgets/moment_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/sos_floating_action.dart';
import 'widgets/upcoming_tile.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          bottom: false,
          child: dashboard.when(
            data: (data) {
              if (data.isEmpty) {
                return const OrbitEmptyState(
                  title: 'Your Orbit is quiet',
                  message:
                      'Create or join a circle to start seeing activity here.',
                );
              }

              return _HomeDashboardContent(dashboard: data);
            },
            loading: () => const OrbitLoadingState(),
            error: (error, stackTrace) => OrbitErrorState(
              title: 'Home could not be loaded',
              message: 'Check your connection and try again.',
              onRetry: () => ref.invalidate(homeDashboardProvider),
            ),
          ),
        ),
        const Positioned(
          right: OrbitSpacing.md,
          bottom: OrbitSpacing.md,
          child: SosFloatingAction(),
        ),
      ],
    );
  }
}

class _HomeDashboardContent extends StatelessWidget {
  const _HomeDashboardContent({required this.dashboard});

  final HomeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 700
            ? OrbitSpacing.xxl
            : OrbitSpacing.md;
        final maxContentWidth = constraints.maxWidth >= 900
            ? 860.0
            : double.infinity;
        final circleWidth = constraints.maxWidth < 360
            ? 238.0
            : constraints.maxWidth < 500
            ? 258.0
            : 286.0;
        final momentWidth = constraints.maxWidth < 360 ? 132.0 : 146.0;

        return CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                OrbitSpacing.md,
                horizontalPadding,
                124,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        HomeHeader(user: dashboard.user),
                        const SizedBox(height: OrbitSpacing.lg),
                        _CircleRail(
                          circles: dashboard.circles,
                          cardWidth: circleWidth,
                        ),
                        const SizedBox(height: OrbitSpacing.lg),
                        const QuickActions(),
                        const SizedBox(height: OrbitSpacing.lg),
                        const OrbitSectionHeader(
                          title: 'Recent Moments',
                          actionLabel: 'See all',
                        ),
                        const SizedBox(height: OrbitSpacing.xs),
                        _MomentRail(
                          moments: dashboard.moments,
                          cardWidth: momentWidth,
                        ),
                        const SizedBox(height: OrbitSpacing.lg),
                        const OrbitSectionHeader(
                          title: 'Smart Activity',
                          actionLabel: 'See all',
                        ),
                        const SizedBox(height: OrbitSpacing.xs),
                        ...dashboard.activities.map(
                          (activity) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: OrbitSpacing.xs,
                            ),
                            child: ActivityTile(activity: activity),
                          ),
                        ),
                        const SizedBox(height: OrbitSpacing.md),
                        const OrbitSectionHeader(title: 'Upcoming'),
                        const SizedBox(height: OrbitSpacing.xs),
                        ...dashboard.upcoming.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: OrbitSpacing.xs,
                            ),
                            child: UpcomingTile(item: item),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CircleRail extends StatelessWidget {
  const _CircleRail({required this.circles, required this.cardWidth});

  final List<HomeCircle> circles;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 290,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: circles.length,
        separatorBuilder: (_, _) => const SizedBox(width: OrbitSpacing.sm),
        itemBuilder: (context, index) {
          return CircleSummaryCard(circle: circles[index], width: cardWidth);
        },
      ),
    );
  }
}

class _MomentRail extends StatelessWidget {
  const _MomentRail({required this.moments, required this.cardWidth});

  final List<HomeMoment> moments;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: moments.length,
        separatorBuilder: (_, _) => const SizedBox(width: OrbitSpacing.sm),
        itemBuilder: (context, index) {
          return MomentCard(moment: moments[index], width: cardWidth);
        },
      ),
    );
  }
}
