import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../core/widgets/orbit_feedback_state.dart';
import '../../../core/widgets/orbit_primary_button.dart';
import '../domain/ping_item.dart';
import 'ping_controller.dart';
import 'widgets/ping_card.dart';

class PingPage extends ConsumerWidget {
  const PingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pingControllerProvider);

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const OrbitAtmosphereBackground(),
          SafeArea(
            child: state.when(
              loading: () => const OrbitLoadingState(),
              error: (_, _) => OrbitErrorState(
                title: 'Pings could not be loaded',
                message: 'Check your connection and try again.',
                onRetry: () =>
                    ref.read(pingControllerProvider.notifier).refresh(),
              ),
              data: (value) => _PingContent(value: value),
            ),
          ),
        ],
      ),
    );
  }
}

class _PingContent extends ConsumerWidget {
  const _PingContent({required this.value});

  final PingViewState value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(pingControllerProvider.notifier);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OrbitSpacing.lg,
              OrbitSpacing.md,
              OrbitSpacing.lg,
              0,
            ),
            child: Row(
              children: <Widget>[
                IconButton.filledTonal(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: OrbitSpacing.sm),
                Expanded(
                  child: Text(
                    'Pings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: value.isBusy
                      ? null
                      : () => _showPingComposer(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New'),
                ),
              ],
            ),
          ),
          if (value.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OrbitSpacing.lg,
                OrbitSpacing.sm,
                OrbitSpacing.lg,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value.errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: OrbitColors.danger),
                ),
              ),
            ),
          const SizedBox(height: OrbitSpacing.sm),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: OrbitSpacing.lg),
            child: TabBar(
              tabs: <Widget>[
                Tab(text: 'Inbox'),
                Tab(text: 'Sent'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _PingList(
                  pings: value.inbox,
                  isIncoming: true,
                  isBusy: value.isBusy,
                  onRefresh: controller.refresh,
                  onHey: (ping) =>
                      controller.respond(ping, PingResponseType.hey),
                  onShareLocation: (ping) =>
                      controller.respond(ping, PingResponseType.shareLocation),
                  onDismiss: controller.dismiss,
                ),
                _PingList(
                  pings: value.sent,
                  isIncoming: false,
                  isBusy: value.isBusy,
                  onRefresh: controller.refresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPingComposer(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: OrbitColors.backgroundElevated,
      builder: (_) => const _PingComposerSheet(),
    );
  }
}

class _PingList extends StatelessWidget {
  const _PingList({
    required this.pings,
    required this.isIncoming,
    required this.isBusy,
    required this.onRefresh,
    this.onHey,
    this.onShareLocation,
    this.onDismiss,
  });

  final List<PingItem> pings;
  final bool isIncoming;
  final bool isBusy;
  final Future<void> Function() onRefresh;
  final ValueChanged<PingItem>? onHey;
  final ValueChanged<PingItem>? onShareLocation;
  final ValueChanged<PingItem>? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (pings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
            OrbitEmptyState(
              title: isIncoming ? 'No active Pings' : 'No sent Pings yet',
              message: isIncoming
                  ? 'When someone checks in with you, their Ping appears here.'
                  : 'Send a lightweight Ping without opening a full conversation.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(OrbitSpacing.lg),
        itemCount: pings.length,
        separatorBuilder: (_, _) => const SizedBox(height: OrbitSpacing.sm),
        itemBuilder: (context, index) {
          final ping = pings[index];
          return PingCard(
            ping: ping,
            isIncoming: isIncoming,
            isBusy: isBusy,
            onHey: onHey == null ? null : () => onHey!(ping),
            onShareLocation: onShareLocation == null
                ? null
                : () => onShareLocation!(ping),
            onDismiss: onDismiss == null ? null : () => onDismiss!(ping),
          );
        },
      ),
    );
  }
}

class _PingComposerSheet extends ConsumerStatefulWidget {
  const _PingComposerSheet();

  @override
  ConsumerState<_PingComposerSheet> createState() => _PingComposerSheetState();
}

class _PingComposerSheetState extends ConsumerState<_PingComposerSheet> {
  PingCircleOption? _selectedCircle;
  PingTarget? _selectedTarget;

  @override
  Widget build(BuildContext context) {
    final circlesAsync = ref.watch(pingCirclesProvider);
    final pingState = ref
        .watch(pingControllerProvider)
        .when(
          data: (value) => value,
          error: (_, _) =>
              const PingViewState(inbox: <PingItem>[], sent: <PingItem>[]),
          loading: () =>
              const PingViewState(inbox: <PingItem>[], sent: <PingItem>[]),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        OrbitSpacing.lg,
        OrbitSpacing.lg,
        OrbitSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + OrbitSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: circlesAsync.when(
          loading: () =>
              const SizedBox(height: 260, child: OrbitLoadingState()),
          error: (_, _) => OrbitErrorState(
            title: 'Circles could not be loaded',
            message: 'Check your connection and try again.',
            onRetry: () => ref.invalidate(pingCirclesProvider),
          ),
          data: (circles) {
            if (circles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: OrbitSpacing.xl),
                child: OrbitEmptyState(
                  title: 'No Circles yet',
                  message: 'Join or create a Circle before sending a Ping.',
                ),
              );
            }

            final selectedCircle = _selectedCircle ?? circles.first;
            final targetsAsync = ref.watch(pingTargetsProvider(selectedCircle));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Send a Ping',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: OrbitSpacing.xs),
                Text(
                  'A Ping is a short-lived check-in. Orbit enforces recipient privacy and cooldown rules server-side.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: OrbitSpacing.lg),
                DropdownButtonFormField<PingCircleOption>(
                  initialValue: selectedCircle,
                  decoration: const InputDecoration(labelText: 'Circle'),
                  items: circles
                      .map(
                        (circle) => DropdownMenuItem<PingCircleOption>(
                          value: circle,
                          child: Text(
                            circle.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: pingState.isBusy
                      ? null
                      : (circle) {
                          if (circle == null) {
                            return;
                          }
                          setState(() {
                            _selectedCircle = circle;
                            _selectedTarget = null;
                          });
                        },
                ),
                const SizedBox(height: OrbitSpacing.md),
                targetsAsync.when(
                  loading: () =>
                      const SizedBox(height: 96, child: OrbitLoadingState()),
                  error: (_, _) => Text(
                    'Orbit could not load members for this Circle.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: OrbitColors.danger),
                  ),
                  data: (targets) {
                    final enabledTargets = targets
                        .where((target) => target.canPing)
                        .toList(growable: false);
                    if (enabledTargets.isEmpty) {
                      return Text(
                        'No members in this Circle currently allow Pings.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }

                    final selectedTarget =
                        enabledTargets.contains(_selectedTarget)
                        ? _selectedTarget
                        : enabledTargets.first;

                    return DropdownButtonFormField<PingTarget>(
                      initialValue: selectedTarget,
                      decoration: const InputDecoration(labelText: 'Member'),
                      items: enabledTargets
                          .map(
                            (target) => DropdownMenuItem<PingTarget>(
                              value: target,
                              child: Text(
                                target.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: pingState.isBusy
                          ? null
                          : (target) =>
                                setState(() => _selectedTarget = target),
                    );
                  },
                ),
                if (pingState.errorMessage != null) ...<Widget>[
                  const SizedBox(height: OrbitSpacing.sm),
                  Text(
                    pingState.errorMessage!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: OrbitColors.danger),
                  ),
                ],
                const SizedBox(height: OrbitSpacing.lg),
                targetsAsync.maybeWhen(
                  data: (targets) {
                    final enabledTargets = targets
                        .where((target) => target.canPing)
                        .toList(growable: false);
                    final selectedTarget =
                        enabledTargets.contains(_selectedTarget)
                        ? _selectedTarget
                        : enabledTargets.isEmpty
                        ? null
                        : enabledTargets.first;

                    return OrbitPrimaryButton(
                      label: 'Send Ping',
                      icon: Icons.near_me_rounded,
                      isBusy: pingState.isBusy,
                      onPressed: selectedTarget == null
                          ? null
                          : () async {
                              final sent = await ref
                                  .read(pingControllerProvider.notifier)
                                  .send(
                                    circle: selectedCircle,
                                    target: selectedTarget,
                                  );
                              if (!context.mounted || !sent) {
                                return;
                              }
                              Navigator.of(context).pop();
                            },
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
