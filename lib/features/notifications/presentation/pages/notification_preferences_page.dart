import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/orbit_notification.dart';
import '../notification_providers.dart';

class NotificationPreferencesPage extends ConsumerWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationPreferencesControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const OrbitAtmosphereBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    OrbitSpacing.xs,
                    OrbitSpacing.xs,
                    OrbitSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: <Widget>[
                      const BackButton(),
                      Expanded(
                        child: Text(
                          'Notification preferences',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.when(
                    loading: () => const OrbitLoadingState(),
                    error: (_, _) => OrbitErrorState(
                      title: 'Preferences could not be loaded',
                      message: 'Check your connection and try again.',
                      onRetry: () => ref.invalidate(
                        notificationPreferencesControllerProvider,
                      ),
                    ),
                    data: (value) => _PreferencesContent(state: value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesContent extends ConsumerWidget {
  const _PreferencesContent({required this.state});

  final NotificationPreferencesViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = state.preferences;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 700
            ? OrbitSpacing.xxl
            : OrbitSpacing.md;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            OrbitSpacing.md,
            horizontal,
            OrbitSpacing.xxl,
          ),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OrbitGlassCard(
                      padding: const EdgeInsets.all(OrbitSpacing.md),
                      child: Column(
                        children: <Widget>[
                          _PreferenceSwitch(
                            title: 'In-app notifications',
                            subtitle: 'Keep the private Orbit inbox enabled.',
                            value: preferences.inAppEnabled,
                            enabled: !state.isBusy,
                            onChanged: (value) => _save(
                              ref,
                              preferences.copyWith(inAppEnabled: value),
                            ),
                          ),
                          const Divider(height: 1),
                          _PreferenceSwitch(
                            title: 'Push notifications',
                            subtitle:
                                'Server preference for device push delivery.',
                            value: preferences.pushEnabled,
                            enabled: !state.isBusy,
                            onChanged: (value) => _save(
                              ref,
                              preferences.copyWith(pushEnabled: value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: OrbitSpacing.lg),
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: OrbitSpacing.sm),
                    OrbitGlassCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: OrbitSpacing.xxs,
                      ),
                      child: Column(
                        children: <Widget>[
                          _PreferenceSwitch(
                            title: 'Messages',
                            value: preferences.messagesEnabled,
                            enabled: !state.isBusy,
                            onChanged: (value) => _save(
                              ref,
                              preferences.copyWith(messagesEnabled: value),
                            ),
                          ),
                          const Divider(height: 1),
                          _PreferenceSwitch(
                            title: 'Moments',
                            value: preferences.momentsEnabled,
                            enabled: !state.isBusy,
                            onChanged: (value) => _save(
                              ref,
                              preferences.copyWith(momentsEnabled: value),
                            ),
                          ),
                          const Divider(height: 1),
                          _PreferenceSwitch(
                            title: 'Pings',
                            value: preferences.pingsEnabled,
                            enabled: !state.isBusy,
                            onChanged: (value) => _save(
                              ref,
                              preferences.copyWith(pingsEnabled: value),
                            ),
                          ),
                          const Divider(height: 1),
                          _PreferenceSwitch(
                            title: 'Activity',
                            value: preferences.activityEnabled,
                            enabled: !state.isBusy,
                            onChanged: (value) => _save(
                              ref,
                              preferences.copyWith(activityEnabled: value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: OrbitSpacing.lg),
                    Text(
                      'Quiet hours',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: OrbitSpacing.sm),
                    OrbitGlassCard(
                      padding: const EdgeInsets.all(OrbitSpacing.md),
                      child: Column(
                        children: <Widget>[
                          _PreferenceSwitch(
                            title: 'Enable quiet hours',
                            subtitle:
                                'Ordinary delivery follows this server-side preference. SOS remains safety-critical.',
                            value: preferences.quietHoursEnabled,
                            enabled: !state.isBusy,
                            onChanged: (value) => _save(
                              ref,
                              preferences.copyWith(quietHoursEnabled: value),
                            ),
                          ),
                          if (preferences.quietHoursEnabled) ...<Widget>[
                            const Divider(height: OrbitSpacing.lg),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _TimeButton(
                                    label: 'Starts',
                                    value: preferences.quietHoursStart,
                                    enabled: !state.isBusy,
                                    onTap: () => _pickTime(
                                      context,
                                      ref,
                                      preferences,
                                      isStart: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: OrbitSpacing.sm),
                                Expanded(
                                  child: _TimeButton(
                                    label: 'Ends',
                                    value: preferences.quietHoursEnd,
                                    enabled: !state.isBusy,
                                    onTap: () => _pickTime(
                                      context,
                                      ref,
                                      preferences,
                                      isStart: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: OrbitSpacing.sm),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Timezone: ${preferences.timezone}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (state.errorMessage != null) ...<Widget>[
                      const SizedBox(height: OrbitSpacing.md),
                      Text(
                        state.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: OrbitColors.danger,
                        ),
                      ),
                    ],
                    if (state.isBusy) ...<Widget>[
                      const SizedBox(height: OrbitSpacing.md),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences preferences, {
    required bool isStart,
  }) async {
    final current = _parseTime(
      isStart ? preferences.quietHoursStart : preferences.quietHoursEnd,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (picked == null || !context.mounted) {
      return;
    }
    final value = _formatTime(picked);
    await _save(
      ref,
      isStart
          ? preferences.copyWith(quietHoursStart: value)
          : preferences.copyWith(quietHoursEnd: value),
    );
  }

  Future<void> _save(WidgetRef ref, NotificationPreferences preferences) async {
    await ref
        .read(notificationPreferencesControllerProvider.notifier)
        .save(preferences);
  }

  static TimeOfDay? _parseTime(String? value) {
    if (value == null) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatTime(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.sm),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: OrbitSpacing.xs),
        child: Column(
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(value ?? 'Choose time'),
          ],
        ),
      ),
    );
  }
}
