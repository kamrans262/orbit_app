import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../core/widgets/orbit_feedback_state.dart';
import '../../../core/widgets/orbit_section_header.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_view_state.dart';
import '../../ping/domain/ping_item.dart';
import '../../ping/presentation/ping_controller.dart';
import '../../ping/presentation/widgets/ping_card.dart';
import '../domain/home_overview.dart';
import 'home_overview_providers.dart';
import 'widgets/circle_summary_card.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_actions.dart';
import 'widgets/sos_floating_action.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(homeCirclesProvider);
    final pings = ref.watch(pingControllerProvider);
    final auth = ref
        .watch(authControllerProvider)
        .when(
          data: (value) => value,
          error: (_, _) => const AuthViewState.signedOut(),
          loading: () => const AuthViewState.signedOut(),
        );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          bottom: false,
          child: circles.when(
            loading: () => const OrbitLoadingState(),
            error: (_, _) => OrbitErrorState(
              title: 'Home could not be loaded',
              message: 'Check your connection and try again.',
              onRetry: () => ref.invalidate(homeCirclesProvider),
            ),
            data: (circleData) => _HomeDashboardContent(
              circles: circleData,
              pings: pings,
              displayName: auth.user?.displayName ?? 'there',
            ),
          ),
        ),
        Positioned(
          right: OrbitSpacing.md,
          bottom: OrbitSpacing.md,
          child: SosFloatingAction(
            onPressed: () => _showPlannedFeature(
              context,
              'SOS safety activation arrives in Flutter M8.',
            ),
          ),
        ),
      ],
    );
  }

  static void _showPlannedFeature(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HomeDashboardContent extends ConsumerWidget {
  const _HomeDashboardContent({
    required this.circles,
    required this.pings,
    required this.displayName,
  });

  final List<HomeCircleSummary> circles;
  final AsyncValue<PingViewState> pings;
  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePings = pings.when(
      data: (value) => value.inbox,
      error: (_, _) => const <PingItem>[],
      loading: () => const <PingItem>[],
    );

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

        return RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              OrbitSpacing.md,
              horizontalPadding,
              124,
            ),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      HomeHeader(
                        displayName: displayName,
                        circleCount: circles.length,
                        activePingCount: activePings.length,
                      ),
                      const SizedBox(height: OrbitSpacing.lg),
                      if (circles.isEmpty)
                        const _NoCirclesCard()
                      else
                        _CircleRail(
                          circles: circles,
                          activePings: activePings,
                          cardWidth: circleWidth,
                        ),
                      const SizedBox(height: OrbitSpacing.lg),
                      QuickActions(
                        onPing: () => context.push('/pings'),
                        onSos: () => _showPlannedFeature(
                          context,
                          'SOS safety flows arrive in Flutter M8.',
                        ),
                        onAddMember: () => context.go('/circles'),
                        onOpenMap: () => _showPlannedFeature(
                          context,
                          'The full privacy-aware map experience is not enabled yet.',
                        ),
                      ),
                      if (activePings.isNotEmpty) ...<Widget>[
                        const SizedBox(height: OrbitSpacing.lg),
                        OrbitSectionHeader(
                          title: 'Active Pings',
                          actionLabel: 'See all',
                          onAction: () => context.push('/pings'),
                        ),
                        const SizedBox(height: OrbitSpacing.xs),
                        ...activePings
                            .take(2)
                            .map(
                              (ping) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: OrbitSpacing.xs,
                                ),
                                child: PingCard(
                                  ping: ping,
                                  isIncoming: true,
                                  isBusy: pings.when(
                                    data: (value) => value.isBusy,
                                    error: (_, _) => false,
                                    loading: () => false,
                                  ),
                                  onHey: () => ref
                                      .read(pingControllerProvider.notifier)
                                      .respond(ping, PingResponseType.hey),
                                  onShareLocation: () => ref
                                      .read(pingControllerProvider.notifier)
                                      .respond(
                                        ping,
                                        PingResponseType.shareLocation,
                                      ),
                                  onDismiss: () => ref
                                      .read(pingControllerProvider.notifier)
                                      .dismiss(ping),
                                ),
                              ),
                            ),
                      ],
                      const SizedBox(height: OrbitSpacing.lg),
                      _PrivacyShortcut(onTap: () => context.push('/presence')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(homeCirclesProvider);
    ref.invalidate(homeCirclePresenceProvider);
    await ref.read(pingControllerProvider.notifier).refresh();
    await ref.read(homeCirclesProvider.future);
  }

  static void _showPlannedFeature(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CircleRail extends StatelessWidget {
  const _CircleRail({
    required this.circles,
    required this.activePings,
    required this.cardWidth,
  });

  final List<HomeCircleSummary> circles;
  final List<PingItem> activePings;
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
          final circle = circles[index];
          final alertCount = activePings
              .where((ping) => ping.circleId == circle.id)
              .length;
          return CircleSummaryCard(
            circle: circle,
            width: cardWidth,
            alertCount: alertCount,
            onTap: () => context.push('/circles/${circle.id}'),
          );
        },
      ),
    );
  }
}

class _NoCirclesCard extends StatelessWidget {
  const _NoCirclesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OrbitSpacing.lg),
      decoration: BoxDecoration(
        color: OrbitColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OrbitColors.borderSubtle),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.groups_2_outlined, color: OrbitColors.primary),
          const SizedBox(width: OrbitSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Your Orbit is quiet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  'Create or join a private Circle to start sharing presence.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyShortcut extends StatelessWidget {
  const _PrivacyShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(OrbitSpacing.md),
          decoration: BoxDecoration(
            color: OrbitColors.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OrbitColors.borderSubtle),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.shield_moon_rounded, color: OrbitColors.purple),
              const SizedBox(width: OrbitSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Presence & privacy',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Control Global Ghost Mode and per-Circle visibility.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: OrbitColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
