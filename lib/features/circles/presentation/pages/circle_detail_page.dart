import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/orbit_circle.dart';
import '../circle_providers.dart';
import '../widgets/circle_list_card.dart';
import '../widgets/circle_screen_scaffold.dart';

class CircleDetailPage extends ConsumerWidget {
  const CircleDetailPage({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = ref.watch(circleDetailProvider(circleId));

    return CircleScreenScaffold(
      title: 'Circle',
      body: circle.when(
        loading: () => const OrbitLoadingState(),
        error: (_, _) => OrbitErrorState(
          title: 'Circle could not be loaded',
          message: 'It may be unavailable, or your connection was interrupted.',
          onRetry: () => ref.invalidate(circleDetailProvider(circleId)),
        ),
        data: (value) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(circleDetailProvider(circleId));
            ref.invalidate(circleMembersProvider(circleId));
            await ref.read(circleDetailProvider(circleId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              CircleContentPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _CircleHero(circle: value),
                    const SizedBox(height: OrbitSpacing.lg),
                    _ActionGrid(circle: value),
                    const SizedBox(height: OrbitSpacing.lg),
                    _AboutCard(circle: value),
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

class _CircleHero extends StatelessWidget {
  const _CircleHero({required this.circle});

  final OrbitCircle circle;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: OrbitColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_2_rounded,
                  color: OrbitColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: OrbitSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      circle.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        CircleRolePill(role: circle.myRole),
                        const SizedBox(width: OrbitSpacing.xs),
                        Flexible(
                          child: Text(
                            '${circle.memberCount} ${circle.memberCount == 1 ? 'member' : 'members'}',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (circle.description != null) ...<Widget>[
            const SizedBox(height: OrbitSpacing.md),
            Text(
              circle.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (!circle.isActive) ...<Widget>[
            const SizedBox(height: OrbitSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(OrbitSpacing.sm),
              decoration: BoxDecoration(
                color: OrbitColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: OrbitColors.warning.withValues(alpha: 0.30),
                ),
              ),
              child: Text(
                circle.isArchived
                    ? 'This Circle is archived. Member and Circle changes are disabled.'
                    : 'This temporary Circle has expired. Changes are disabled.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.circle});

  final OrbitCircle circle;

  @override
  Widget build(BuildContext context) {
    final actions = <_DetailAction>[
      _DetailAction(
        icon: Icons.people_outline_rounded,
        label: 'Members',
        onTap: () => context.push('/circles/${circle.id}/members'),
      ),
      if (circle.canManageMembers)
        _DetailAction(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Invite',
          onTap: () => context.push('/circles/${circle.id}/invite'),
        ),
      _DetailAction(
        icon: Icons.location_on_outlined,
        label: 'Privacy',
        onTap: () => context.push('/presence'),
      ),
      _DetailAction(
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: () => context.push('/circles/${circle.id}/settings'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 620 ? 4 : 2;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: OrbitSpacing.sm,
          crossAxisSpacing: OrbitSpacing.sm,
          childAspectRatio: constraints.maxWidth >= 620 ? 1.8 : 1.5,
          children: actions
              .map(
                (action) => OrbitGlassCard(
                  onTap: action.onTap,
                  padding: const EdgeInsets.all(OrbitSpacing.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(action.icon, color: OrbitColors.primary),
                      const SizedBox(height: OrbitSpacing.xs),
                      Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.circle});

  final OrbitCircle circle;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Circle details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: OrbitSpacing.md),
          _DetailRow(
            icon: Icons.category_outlined,
            label: 'Type',
            value: circle.type == CircleType.temporary
                ? 'Temporary'
                : 'Standard',
          ),
          if (circle.expiresAt != null)
            _DetailRow(
              icon: Icons.schedule_outlined,
              label: 'Expires',
              value: _formatDate(circle.expiresAt!),
            ),
          _DetailRow(
            icon: Icons.verified_user_outlined,
            label: 'Your role',
            value: circle.myRole.name,
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OrbitSpacing.sm),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: OrbitColors.textMuted),
          const SizedBox(width: OrbitSpacing.sm),
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DetailAction {
  const _DetailAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
