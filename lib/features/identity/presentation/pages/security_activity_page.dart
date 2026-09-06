import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/identity_models.dart';
import '../identity_providers.dart';

class SecurityActivityPage extends ConsumerWidget {
  const SecurityActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(securityAuditProvider);
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
                        'Security activity',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh security activity',
                      onPressed: () => ref.invalidate(securityAuditProvider),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: activity.when(
                  loading: () => const OrbitLoadingState(),
                  error: (_, _) => OrbitErrorState(
                    title: 'Security activity could not be loaded',
                    message: 'Check your connection and try again.',
                    onRetry: () => ref.invalidate(securityAuditProvider),
                  ),
                  data: (entries) => _ActivityBody(entries: entries),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityBody extends StatelessWidget {
  const _ActivityBody({required this.entries});

  final List<SecurityAuditEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const OrbitEmptyState(
        title: 'No security activity yet',
        message: 'Recent identity and security actions will appear here.',
      );
    }
    final maxWidth = MediaQuery.sizeOf(context).width >= 720
        ? 720.0
        : double.infinity;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        OrbitSpacing.lg,
        OrbitSpacing.md,
        OrbitSpacing.lg,
        OrbitSpacing.xxl,
      ),
      itemCount: entries.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: OrbitSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: OrbitGlassCard(
                padding: const EdgeInsets.all(OrbitSpacing.lg),
                tint: OrbitColors.surfaceSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.policy_outlined, color: OrbitColors.teal),
                    const SizedBox(width: OrbitSpacing.sm),
                    Expanded(
                      child: Text(
                        'This view intentionally shows only safe action summaries and timestamps. Server audit metadata is not rendered into the mobile UI.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final entry = entries[index - 1];
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _AuditCard(entry: entry),
          ),
        );
      },
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.entry});

  final SecurityAuditEntry entry;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.security_rounded, color: OrbitColors.primary),
          const SizedBox(width: OrbitSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _actionLabel(entry.action),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (entry.targetType != null) ...<Widget>[
                  const SizedBox(height: OrbitSpacing.xxs),
                  Text(
                    'Target: ${_humanize(entry.targetType!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (entry.occurredAt != null) ...<Widget>[
                  const SizedBox(height: OrbitSpacing.xxs),
                  Text(
                    _dateLabel(entry.occurredAt!),
                    style: Theme.of(context).textTheme.bodySmall,
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

String _actionLabel(String action) {
  final normalized = action.startsWith('identity.')
      ? action.substring('identity.'.length)
      : action;
  return _humanize(normalized.replaceAll('.', ' '));
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
