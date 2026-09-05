import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../../../core/design_system/orbit_radius.dart';
import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../core/widgets/orbit_feedback_state.dart';
import '../../../core/widgets/orbit_glass_card.dart';
import '../../../core/widgets/orbit_primary_button.dart';
import '../domain/presence_snapshot.dart';
import 'presence_controller.dart';

class PresencePage extends ConsumerWidget {
  const PresencePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(presenceControllerProvider);

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
                title: 'Presence could not be loaded',
                message: 'Check your connection and try again.',
                onRetry: () =>
                    ref.read(presenceControllerProvider.notifier).refresh(),
              ),
              data: (value) => _PresenceContent(value: value),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresenceContent extends ConsumerWidget {
  const _PresenceContent({required this.value});

  final PresenceViewState value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(presenceControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          OrbitSpacing.lg,
          OrbitSpacing.md,
          OrbitSpacing.lg,
          OrbitSpacing.xxl,
        ),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton.filledTonal(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: OrbitSpacing.sm),
              Expanded(
                child: Text(
                  'Presence & privacy',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: OrbitSpacing.lg),
          _OwnerPresenceCard(
            presence: value.presence,
            isBusy: value.isBusy,
            onGhostChanged: controller.setGlobalGhostMode,
          ),
          const SizedBox(height: OrbitSpacing.md),
          OrbitPrimaryButton(
            label: value.presence.globalGhostMode
                ? 'Location sharing paused by Ghost Mode'
                : 'Share current location now',
            icon: value.presence.globalGhostMode
                ? Icons.visibility_off_rounded
                : Icons.my_location_rounded,
            isBusy: value.isBusy,
            onPressed: value.presence.globalGhostMode
                ? null
                : controller.shareCurrentLocation,
          ),
          if (value.errorMessage != null) ...<Widget>[
            const SizedBox(height: OrbitSpacing.sm),
            Text(
              value.errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: OrbitColors.danger),
            ),
          ],
          const SizedBox(height: OrbitSpacing.xl),
          Text('Circle privacy', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: OrbitSpacing.xs),
          Text(
            'Each Circle has its own location visibility. Global Ghost Mode overrides every Circle without changing these saved choices.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: OrbitSpacing.md),
          if (value.circleSettings.isEmpty)
            const OrbitGlassCard(
              child: Padding(
                padding: EdgeInsets.all(OrbitSpacing.md),
                child: Text(
                  'Join or create a Circle to configure Circle-specific presence privacy.',
                ),
              ),
            )
          else
            ...value.circleSettings.map(
              (setting) => Padding(
                padding: const EdgeInsets.only(bottom: OrbitSpacing.sm),
                child: _CirclePrivacyCard(
                  setting: setting,
                  isBusy: value.isBusy,
                  onLocationModeChanged: (mode) =>
                      controller.updateCircleLocationMode(setting, mode),
                  onPingChanged: (canPing) =>
                      controller.updateCirclePingPermission(setting, canPing),
                ),
              ),
            ),
          const SizedBox(height: OrbitSpacing.md),
          Text(
            'Orbit requests foreground location only when you explicitly share your current location in this milestone. Background location tracking is not enabled.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _OwnerPresenceCard extends StatelessWidget {
  const _OwnerPresenceCard({
    required this.presence,
    required this.isBusy,
    required this.onGhostChanged,
  });

  final PresenceSnapshot presence;
  final bool isBusy;
  final ValueChanged<bool> onGhostChanged;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (presence.status) {
      PresenceStatus.online => OrbitColors.success,
      PresenceStatus.idle => OrbitColors.warning,
      PresenceStatus.ghost => OrbitColors.purple,
      PresenceStatus.offline => OrbitColors.textMuted,
    };

    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.12),
                ),
                child: Icon(
                  presence.globalGhostMode
                      ? Icons.visibility_off_rounded
                      : Icons.radar_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: OrbitSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _statusLabel(presence.status),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _presenceSubtitle(presence),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OrbitSpacing.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: OrbitColors.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(OrbitRadius.md),
              border: Border.all(color: OrbitColors.borderSubtle),
            ),
            child: SwitchListTile.adaptive(
              value: presence.globalGhostMode,
              onChanged: isBusy ? null : onGhostChanged,
              title: const Text('Global Ghost Mode'),
              subtitle: const Text(
                'Hide location, battery, movement, network and last-seen metadata from every Circle.',
              ),
              secondary: const Icon(
                Icons.shield_moon_rounded,
                color: OrbitColors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(PresenceStatus status) {
    return switch (status) {
      PresenceStatus.online => 'Presence online',
      PresenceStatus.idle => 'Presence idle',
      PresenceStatus.offline => 'Presence offline',
      PresenceStatus.ghost => 'Ghost Mode active',
    };
  }

  static String _presenceSubtitle(PresenceSnapshot presence) {
    if (presence.globalGhostMode) {
      return 'Server-side privacy override is active.';
    }
    if (presence.locationUpdatedAt == null) {
      return 'No location has been shared yet.';
    }
    return 'Last location shared ${_relativeAge(presence.locationUpdatedAt!)}.';
  }

  static String _relativeAge(DateTime timestamp) {
    final age = DateTime.now().toUtc().difference(timestamp.toUtc());
    if (age.isNegative || age.inMinutes < 1) {
      return 'just now';
    }
    if (age.inHours < 1) {
      return '${age.inMinutes}m ago';
    }
    if (age.inDays < 1) {
      return '${age.inHours}h ago';
    }
    return '${age.inDays}d ago';
  }
}

class _CirclePrivacyCard extends StatelessWidget {
  const _CirclePrivacyCard({
    required this.setting,
    required this.isBusy,
    required this.onLocationModeChanged,
    required this.onPingChanged,
  });

  final CirclePrivacySetting setting;
  final bool isBusy;
  final ValueChanged<PresenceLocationMode> onLocationModeChanged;
  final ValueChanged<bool> onPingChanged;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.groups_2_rounded, color: OrbitColors.primary),
              const SizedBox(width: OrbitSpacing.sm),
              Expanded(
                child: Text(
                  setting.circleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: OrbitSpacing.md),
          DropdownButtonFormField<PresenceLocationMode>(
            key: ValueKey<String>(
              '${setting.membershipId}:${setting.locationMode.name}',
            ),
            initialValue: setting.locationMode,
            decoration: const InputDecoration(labelText: 'Location visibility'),
            items: PresenceLocationMode.values
                .map(
                  (mode) => DropdownMenuItem<PresenceLocationMode>(
                    value: mode,
                    child: Text(_modeLabel(mode)),
                  ),
                )
                .toList(growable: false),
            onChanged: isBusy
                ? null
                : (mode) {
                    if (mode != null && mode != setting.locationMode) {
                      onLocationModeChanged(mode);
                    }
                  },
          ),
          const SizedBox(height: OrbitSpacing.sm),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: setting.canPing,
            onChanged: isBusy ? null : onPingChanged,
            title: const Text('Allow Pings'),
            subtitle: const Text(
              'Members of this Circle may send you lightweight Pings.',
            ),
          ),
        ],
      ),
    );
  }

  static String _modeLabel(PresenceLocationMode mode) {
    return switch (mode) {
      PresenceLocationMode.precise => 'Precise',
      PresenceLocationMode.approximate => 'Approximate',
      PresenceLocationMode.hidden => 'Hidden',
      PresenceLocationMode.ghost => 'Ghost',
    };
  }
}
