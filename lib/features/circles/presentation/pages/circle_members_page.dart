import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_avatar.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/circle_permissions.dart';
import '../../domain/orbit_circle.dart';
import '../circle_providers.dart';
import '../widgets/circle_list_card.dart';
import '../widgets/circle_screen_scaffold.dart';

class CircleMembersPage extends ConsumerWidget {
  const CircleMembersPage({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = ref.watch(circleDetailProvider(circleId));
    final members = ref.watch(circleMembersProvider(circleId));

    return CircleScreenScaffold(
      title: 'Members',
      subtitle: circle.asData?.value.name,
      actions: <Widget>[
        if (circle.asData?.value.canManageMembers == true)
          IconButton(
            tooltip: 'Create invite',
            onPressed: () => context.push('/circles/$circleId/invite'),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
      ],
      body: circle.when(
        loading: () => const OrbitLoadingState(),
        error: (_, _) => OrbitErrorState(
          title: 'Circle could not be loaded',
          message: 'Try again before managing members.',
          onRetry: () => ref.invalidate(circleDetailProvider(circleId)),
        ),
        data: (circleValue) => members.when(
          loading: () => const OrbitLoadingState(),
          error: (_, _) => OrbitErrorState(
            title: 'Members could not be loaded',
            message: 'Check your connection and try again.',
            onRetry: () => ref.invalidate(circleMembersProvider(circleId)),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(circleMembersProvider(circleId));
              ref.invalidate(circleDetailProvider(circleId));
              await ref.read(circleMembersProvider(circleId).future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                OrbitSpacing.md,
                OrbitSpacing.md,
                OrbitSpacing.md,
                OrbitSpacing.xxl,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: OrbitSpacing.sm),
              itemBuilder: (context, index) {
                final member = items[index];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: _MemberCard(
                      circle: circleValue,
                      member: member,
                      onTap:
                          CirclePermissions.canChangeRole(
                                circle: circleValue,
                                target: member,
                              ) ||
                              CirclePermissions.canRemove(
                                circle: circleValue,
                                target: member,
                              )
                          ? () => context.push(
                              '/circles/$circleId/members/${member.membershipId}',
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.circle,
    required this.member,
    required this.onTap,
  });

  final OrbitCircle circle;
  final OrbitCircleMember member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isMe = member.membershipId == circle.myMembershipId;

    return OrbitGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OrbitSpacing.md),
      child: Row(
        children: <Widget>[
          OrbitAvatar(initials: _initials(member.name), size: 48),
          const SizedBox(width: OrbitSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (isMe) ...<Widget>[
                      const SizedBox(width: OrbitSpacing.xs),
                      Text(
                        'You',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: OrbitColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: OrbitSpacing.xs),
                Wrap(
                  spacing: OrbitSpacing.xs,
                  runSpacing: OrbitSpacing.xs,
                  children: <Widget>[
                    CircleRolePill(role: member.role),
                    _PermissionPill(
                      icon: Icons.location_on_outlined,
                      label: member.locationMode,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              color: OrbitColors.textMuted,
            ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _PermissionPill extends StatelessWidget {
  const _PermissionPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: OrbitColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OrbitColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: OrbitColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
