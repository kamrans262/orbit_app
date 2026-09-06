import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_radius.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/identity_models.dart';
import '../identity_providers.dart';

class SecuritySessionsPage extends ConsumerWidget {
  const SecuritySessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(identityDevicesProvider);
    final sessions = ref.watch(identitySessionsProvider);
    final currentSession = ref.watch(currentAuthSessionProvider).asData?.value;
    final mutation = ref.watch(identityMutationControllerProvider);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          child: Column(
            children: <Widget>[
              _Header(
                isBusy: mutation.hasBusyOperation,
                onRefresh: () {
                  ref.invalidate(identityDevicesProvider);
                  ref.invalidate(identitySessionsProvider);
                  ref.invalidate(currentAuthSessionProvider);
                },
              ),
              Expanded(
                child: devices.when(
                  loading: () => const OrbitLoadingState(),
                  error: (_, _) => OrbitErrorState(
                    title: 'Devices could not be loaded',
                    message: 'Check your connection and try again.',
                    onRetry: () => ref.invalidate(identityDevicesProvider),
                  ),
                  data: (deviceList) => sessions.when(
                    loading: () => const OrbitLoadingState(),
                    error: (_, _) => OrbitErrorState(
                      title: 'Sessions could not be loaded',
                      message: 'Check your connection and try again.',
                      onRetry: () => ref.invalidate(identitySessionsProvider),
                    ),
                    data: (sessionList) => _SecurityBody(
                      devices: deviceList,
                      sessions: sessionList,
                      currentSessionId: currentSession?.sessionId,
                      mutation: mutation,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isBusy, required this.onRefresh});

  final bool isBusy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OrbitSpacing.xs,
        OrbitSpacing.xs,
        OrbitSpacing.sm,
        OrbitSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          const BackButton(),
          Expanded(
            child: Text(
              'Security & devices',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            tooltip: 'Refresh devices and sessions',
            onPressed: isBusy ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _SecurityBody extends ConsumerWidget {
  const _SecurityBody({
    required this.devices,
    required this.sessions,
    required this.currentSessionId,
    required this.mutation,
  });

  final List<OrbitIdentityDevice> devices;
  final List<OrbitIdentitySessionSummary> sessions;
  final String? currentSessionId;
  final IdentityMutationState mutation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxWidth = MediaQuery.sizeOf(context).width >= 720
        ? 760.0
        : double.infinity;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        OrbitSpacing.lg,
        OrbitSpacing.md,
        OrbitSpacing.lg,
        OrbitSpacing.xxl,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              OrbitGlassCard(
                padding: const EdgeInsets.all(OrbitSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.phonelink_lock_rounded,
                      color: OrbitColors.primary,
                    ),
                    const SizedBox(width: OrbitSpacing.sm),
                    Expanded(
                      child: Text(
                        'Review devices and active identity sessions. Orbit never displays access or refresh tokens here.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if (mutation.errorMessage != null) ...<Widget>[
                const SizedBox(height: OrbitSpacing.sm),
                Text(
                  mutation.errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: OrbitColors.danger),
                ),
              ],
              const SizedBox(height: OrbitSpacing.lg),
              Text('Devices', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: OrbitSpacing.sm),
              if (devices.isEmpty)
                const OrbitEmptyState(
                  title: 'No devices found',
                  message: 'Orbit has no registered identity devices to show.',
                )
              else
                ...devices.map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: OrbitSpacing.sm),
                    child: _DeviceCard(
                      device: device,
                      isBusy: mutation.isBusy('device:${device.id}'),
                      onRename: () => _renameDevice(context, ref, device),
                    ),
                  ),
                ),
              const SizedBox(height: OrbitSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Sessions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: mutation.hasBusyOperation
                        ? null
                        : () => _revokeOtherSessions(context, ref),
                    icon: mutation.isBusy('sessions:others')
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Revoke others'),
                  ),
                ],
              ),
              const SizedBox(height: OrbitSpacing.sm),
              if (sessions.isEmpty)
                const OrbitEmptyState(
                  title: 'No sessions found',
                  message: 'Orbit has no identity sessions to show.',
                )
              else
                ...sessions.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: OrbitSpacing.sm),
                    child: _SessionCard(
                      session: session,
                      isCurrent: session.id == currentSessionId,
                      isBusy: mutation.isBusy('session:${session.id}'),
                      onRevoke:
                          session.id == currentSessionId || !session.isActive
                          ? null
                          : () => _revokeSession(context, ref, session),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _renameDevice(
    BuildContext context,
    WidgetRef ref,
    OrbitIdentityDevice device,
  ) async {
    final controller = TextEditingController(text: device.deviceName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename device'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Device name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    final cleanName = name?.trim();
    if (cleanName == null || cleanName.isEmpty || !context.mounted) {
      return;
    }
    final ok = await ref
        .read(identityMutationControllerProvider.notifier)
        .renameDevice(device.id, cleanName);
    if (!context.mounted || !ok) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Device name updated.')));
  }

  Future<void> _revokeSession(
    BuildContext context,
    WidgetRef ref,
    OrbitIdentitySessionSummary session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke this session?'),
        content: Text(
          '${session.displayName} will need to authenticate again. Your current session stays signed in.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final ok = await ref
        .read(identityMutationControllerProvider.notifier)
        .revokeSession(session.id);
    if (!context.mounted || !ok) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Session revoked.')));
  }

  Future<void> _revokeOtherSessions(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke other sessions?'),
        content: const Text(
          'All other active identity sessions will be revoked. This device will remain signed in.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Revoke others'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final count = await ref
        .read(identityMutationControllerProvider.notifier)
        .revokeOtherSessions();
    if (!context.mounted || count == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count other session${count == 1 ? '' : 's'} revoked.'),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.isBusy,
    required this.onRename,
  });

  final OrbitIdentityDevice device;
  final bool isBusy;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: OrbitColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(OrbitRadius.sm),
            ),
            child: Icon(
              _platformIcon(device.platform),
              color: OrbitColors.primary,
            ),
          ),
          title: Text(device.displayName),
          subtitle: Text(
            '${_humanize(device.trustStatus)}${device.lastSeenAt == null ? '' : ' • Last seen ${_dateLabel(device.lastSeenAt!)}'}',
          ),
          trailing: IconButton(
            tooltip: 'Rename device',
            onPressed: isBusy ? null : onRename,
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_outlined),
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isCurrent,
    required this.isBusy,
    required this.onRevoke,
  });

  final OrbitIdentitySessionSummary session;
  final bool isCurrent;
  final bool isBusy;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isCurrent
                ? Icons.verified_user_rounded
                : Icons.devices_other_rounded,
            color: isCurrent ? OrbitColors.success : OrbitColors.textSecondary,
          ),
          const SizedBox(width: OrbitSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        session.displayName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (isCurrent)
                      Text(
                        'Current session',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: OrbitColors.success,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: OrbitSpacing.xxs),
                Text(
                  '${_humanize(session.status)}${session.lastSeenAt == null ? '' : ' • Last seen ${_dateLabel(session.lastSeenAt!)}'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (session.refreshExpiresAt != null) ...<Widget>[
                  const SizedBox(height: OrbitSpacing.xxs),
                  Text(
                    'Refresh access expires ${_dateLabel(session.refreshExpiresAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (onRevoke != null) ...<Widget>[
                  const SizedBox(height: OrbitSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onRevoke,
                    icon: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Revoke session'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _platformIcon(String? platform) {
  return switch (platform?.toLowerCase()) {
    'android' => Icons.android_rounded,
    'ios' => Icons.phone_iphone_rounded,
    'web' => Icons.language_rounded,
    _ => Icons.devices_rounded,
  };
}

String _humanize(String value) {
  final words = value.replaceAll('_', ' ').trim();
  if (words.isEmpty) {
    return value;
  }
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
