import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../core/widgets/orbit_feedback_state.dart';
import '../../notifications/presentation/widgets/notification_bell_button.dart';
import '../domain/activity_item.dart';
import 'activity_providers.dart';
import 'widgets/activity_card.dart';

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityControllerProvider);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  OrbitSpacing.lg,
                  OrbitSpacing.md,
                  OrbitSpacing.xs,
                  OrbitSpacing.xs,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Activity',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'What changed across your private Circles.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const NotificationBellButton(),
                  ],
                ),
              ),
              Expanded(
                child: activity.when(
                  loading: () => const OrbitLoadingState(),
                  error: (_, _) => OrbitErrorState(
                    title: 'Activity could not be loaded',
                    message: 'Check your connection and try again.',
                    onRetry: () =>
                        ref.read(activityControllerProvider.notifier).refresh(),
                  ),
                  data: (value) => _ActivityFeed(state: value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityFeed extends ConsumerWidget {
  const _ActivityFeed({required this.state});

  final ActivityViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(activityControllerProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 120),
            OrbitEmptyState(
              title: 'Your Orbit is quiet',
              message:
                  'New Moments, membership changes and safety events will appear here.',
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 700
            ? OrbitSpacing.xxl
            : OrbitSpacing.md;
        final maxWidth = constraints.maxWidth >= 900 ? 760.0 : double.infinity;

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(activityControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontal,
              OrbitSpacing.sm,
              horizontal,
              120,
            ),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: <Widget>[
                      if (state.errorMessage != null) ...<Widget>[
                        _InlineError(message: state.errorMessage!),
                        const SizedBox(height: OrbitSpacing.sm),
                      ],
                      for (final item in state.items) ...<Widget>[
                        ActivityCard(
                          item: item,
                          isBusy: state.busyActivityId == item.id,
                          onHide: () => _hide(context, ref, item),
                          onReport: () => _report(context, ref, item),
                        ),
                        const SizedBox(height: OrbitSpacing.sm),
                      ],
                      if (state.hasMore)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: state.isLoadingMore
                                ? null
                                : () => ref
                                      .read(activityControllerProvider.notifier)
                                      .loadMore(),
                            icon: state.isLoadingMore
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.expand_more_rounded),
                            label: Text(
                              state.isLoadingMore ? 'Loading…' : 'Load more',
                            ),
                          ),
                        ),
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

  Future<void> _hide(
    BuildContext context,
    WidgetRef ref,
    ActivityItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hide this activity?'),
        content: const Text(
          'This only removes the item from your own Activity feed.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hide'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final hidden = await ref
        .read(activityControllerProvider.notifier)
        .hide(item);
    if (hidden && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Activity hidden.')));
    }
  }

  Future<void> _report(
    BuildContext context,
    WidgetRef ref,
    ActivityItem item,
  ) async {
    final input = await showModalBottomSheet<_ActivityReportInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => const _ReportActivitySheet(),
    );
    if (input == null || !context.mounted) {
      return;
    }

    final reported = await ref
        .read(activityControllerProvider.notifier)
        .report(item: item, reason: input.reason, details: input.details);
    if (reported && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Activity sent for review.')),
        );
    }
  }
}

class _ReportActivitySheet extends StatefulWidget {
  const _ReportActivitySheet();

  @override
  State<_ReportActivitySheet> createState() => _ReportActivitySheetState();
}

class _ReportActivitySheetState extends State<_ReportActivitySheet> {
  ActivityReportReason _reason = ActivityReportReason.safety;
  final TextEditingController _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          OrbitSpacing.lg,
          0,
          OrbitSpacing.lg,
          OrbitSpacing.lg + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Report activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: OrbitSpacing.xs),
              Text(
                'Choose the reason that best matches your concern.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: OrbitSpacing.md),
              DropdownButtonFormField<ActivityReportReason>(
                initialValue: _reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: ActivityReportReason.values
                    .map(
                      (reason) => DropdownMenuItem<ActivityReportReason>(
                        value: reason,
                        child: Text(reason.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _reason = value);
                  }
                },
              ),
              const SizedBox(height: OrbitSpacing.md),
              TextField(
                controller: _detailsController,
                maxLength: 500,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  hintText: 'Add context for the review team.',
                ),
              ),
              const SizedBox(height: OrbitSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(
                    _ActivityReportInput(
                      reason: _reason,
                      details: _detailsController.text.trim(),
                    ),
                  ),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Send report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityReportInput {
  const _ActivityReportInput({required this.reason, required this.details});

  final ActivityReportReason reason;
  final String details;
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OrbitSpacing.sm),
      decoration: BoxDecoration(
        color: OrbitColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OrbitColors.danger.withValues(alpha: 0.22)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: OrbitColors.danger),
      ),
    );
  }
}
