import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../../../core/widgets/orbit_primary_button.dart';
import '../../domain/identity_models.dart';
import '../identity_providers.dart';

class PrivacyCenterPage extends ConsumerWidget {
  const PrivacyCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(privacySummaryProvider);
    final mutation = ref.watch(identityMutationControllerProvider);

    return Stack(
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
                  OrbitSpacing.sm,
                  OrbitSpacing.xs,
                ),
                child: Row(
                  children: <Widget>[
                    const BackButton(),
                    Expanded(
                      child: Text(
                        'Privacy center',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh privacy summary',
                      onPressed: mutation.hasBusyOperation
                          ? null
                          : () => ref.invalidate(privacySummaryProvider),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: summary.when(
                  loading: () => const OrbitLoadingState(),
                  error: (_, _) => OrbitErrorState(
                    title: 'Privacy information could not be loaded',
                    message: 'Check your connection and try again.',
                    onRetry: () => ref.invalidate(privacySummaryProvider),
                  ),
                  data: (value) =>
                      _PrivacyBody(summary: value, mutation: mutation),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyBody extends ConsumerWidget {
  const _PrivacyBody({required this.summary, required this.mutation});

  final PrivacySummary summary;
  final IdentityMutationState mutation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxWidth = MediaQuery.sizeOf(context).width >= 720
        ? 720.0
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Privacy snapshot',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: OrbitSpacing.md),
                    _SummaryRow(
                      label: 'Global Ghost Mode',
                      value: summary.globalGhostMode ? 'On' : 'Off',
                    ),
                    _SummaryRow(
                      label: 'Read receipts',
                      value: summary.readReceiptsEnabled == null
                          ? 'Not configured'
                          : summary.readReceiptsEnabled!
                          ? 'On'
                          : 'Off',
                    ),
                    _SummaryRow(
                      label: 'Circle privacy memberships',
                      value: summary.circleCount.toString(),
                    ),
                    if (summary.notificationPreferences != null)
                      _SummaryRow(
                        label: 'In-app notifications',
                        value: summary.notificationPreferences!.inAppEnabled
                            ? 'On'
                            : 'Off',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: OrbitSpacing.lg),
              Text(
                'Privacy controls',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: OrbitSpacing.sm),
              _PrivacyLink(
                icon: Icons.shield_moon_rounded,
                title: 'Presence & Circle privacy',
                subtitle:
                    'Ghost Mode, location visibility and Circle-specific controls.',
                onTap: () => context.push('/presence'),
              ),
              const SizedBox(height: OrbitSpacing.sm),
              _PrivacyLink(
                icon: Icons.lock_person_rounded,
                title: 'Messaging privacy',
                subtitle:
                    'Review E2EE device identity and read-receipt settings.',
                onTap: () => context.push('/security/messaging'),
              ),
              const SizedBox(height: OrbitSpacing.sm),
              _PrivacyLink(
                icon: Icons.notifications_active_outlined,
                title: 'Notification privacy',
                subtitle:
                    'Notification categories, quiet hours and delivery preferences.',
                onTap: () => context.push('/notifications/preferences'),
              ),
              const SizedBox(height: OrbitSpacing.lg),
              Text('Your data', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: OrbitSpacing.sm),
              _DataExportCard(summary: summary, mutation: mutation),
              const SizedBox(height: OrbitSpacing.lg),
              Text(
                'Account deletion',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: OrbitColors.danger),
              ),
              const SizedBox(height: OrbitSpacing.sm),
              _DeletionCard(summary: summary, mutation: mutation),
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
              OrbitGlassCard(
                padding: const EdgeInsets.all(OrbitSpacing.lg),
                tint: OrbitColors.surfaceSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: OrbitColors.teal,
                    ),
                    const SizedBox(width: OrbitSpacing.sm),
                    Expanded(
                      child: Text(
                        'Orbit private message and media plaintext is not present in server exports because private content remains encrypted. This screen also never renders raw identity audit metadata or session tokens.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataExportCard extends ConsumerWidget {
  const _DataExportCard({required this.summary, required this.mutation});

  final PrivacySummary summary;
  final IdentityMutationState mutation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final export = summary.dataExport;
    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.file_download_outlined,
                color: OrbitColors.primary,
              ),
              const SizedBox(width: OrbitSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Data export',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: OrbitSpacing.xxs),
                    Text(
                      export == null
                          ? 'Request a server-side export of the account data Orbit is permitted to hold.'
                          : 'Latest export: ${_humanize(export.status)}${export.expiresAt == null ? '' : ' • expires ${_dateLabel(export.expiresAt!)}'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OrbitSpacing.md),
          OrbitPrimaryButton(
            label: export == null
                ? 'Request data export'
                : 'Request or refresh export',
            icon: Icons.download_rounded,
            isBusy: mutation.isBusy('privacy:export'),
            onPressed: mutation.hasBusyOperation
                ? null
                : () => _requestExport(context, ref),
          ),
          if (export != null) ...<Widget>[
            const SizedBox(height: OrbitSpacing.sm),
            Text(
              'The current mobile contract exposes export status and expiry. It does not expose a dedicated download endpoint, so this UI does not invent one or display the raw export payload.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _requestExport(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(identityMutationControllerProvider.notifier)
        .requestDataExport();
    if (!context.mounted || result == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data export status: ${_humanize(result.status)}.'),
      ),
    );
  }
}

class _DeletionCard extends ConsumerWidget {
  const _DeletionCard({required this.summary, required this.mutation});

  final PrivacySummary summary;
  final IdentityMutationState mutation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletion = summary.accountDeletion;
    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.delete_forever_outlined,
                color: OrbitColors.danger,
              ),
              const SizedBox(width: OrbitSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      deletion == null
                          ? 'No deletion is scheduled'
                          : 'Deletion ${_humanize(deletion.status)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: OrbitSpacing.xxs),
                    Text(
                      deletion?.scheduledFor == null
                          ? 'Account deletion uses a 30-day reversible grace period enforced by Laravel.'
                          : 'Scheduled for ${_dateLabel(deletion!.scheduledFor!)}. You can cancel while the request is pending or blocked.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (deletion?.blockingReason != null) ...<Widget>[
                      const SizedBox(height: OrbitSpacing.xs),
                      Text(
                        'Blocked: ${deletion!.blockingReason}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: OrbitColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OrbitSpacing.md),
          if (deletion?.canCancel == true)
            OrbitPrimaryButton(
              label: 'Cancel account deletion',
              icon: Icons.undo_rounded,
              isBusy: mutation.isBusy('privacy:cancel-delete'),
              onPressed: mutation.hasBusyOperation
                  ? null
                  : () => _cancelDeletion(context, ref),
            )
          else
            OrbitPrimaryButton(
              label: 'Request account deletion',
              icon: Icons.delete_outline_rounded,
              backgroundColor: OrbitColors.danger,
              isBusy: mutation.isBusy('privacy:delete'),
              onPressed: mutation.hasBusyOperation
                  ? null
                  : () => _requestDeletion(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _requestDeletion(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final confirmationController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Schedule account deletion?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Laravel schedules deletion with a 30-day reversible grace period. Circle ownership or other server-side requirements may block completion.',
              ),
              const SizedBox(height: OrbitSpacing.md),
              TextField(
                controller: reasonController,
                maxLength: 255,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                ),
              ),
              const SizedBox(height: OrbitSpacing.sm),
              TextField(
                controller: confirmationController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to confirm',
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep account'),
          ),
          FilledButton(
            onPressed: () {
              final typed = confirmationController.text.trim().toUpperCase();
              Navigator.of(dialogContext).pop(typed == 'DELETE');
            },
            child: const Text('Schedule deletion'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    confirmationController.dispose();
    if (confirmed != true || !context.mounted) {
      return;
    }
    final result = await ref
        .read(identityMutationControllerProvider.notifier)
        .requestAccountDeletion(reason: reason.isEmpty ? null : reason);
    if (!context.mounted || result == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account deletion scheduled. The 30-day grace period has started.',
        ),
      ),
    );
  }

  Future<void> _cancelDeletion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel account deletion?'),
        content: const Text('Your pending deletion request will be cancelled.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep scheduled'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel deletion'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final ok = await ref
        .read(identityMutationControllerProvider.notifier)
        .cancelAccountDeletion();
    if (!context.mounted || !ok) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deletion cancelled.')),
    );
  }
}

class _PrivacyLink extends StatelessWidget {
  const _PrivacyLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: OrbitColors.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OrbitSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: OrbitSpacing.md),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
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
  return '${local.year}-$month-$day';
}
