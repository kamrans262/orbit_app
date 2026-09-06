import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../../../core/widgets/orbit_primary_button.dart';
import '../../domain/circle_permissions.dart';
import '../../domain/orbit_circle.dart';
import '../circle_providers.dart';
import '../widgets/circle_screen_scaffold.dart';

class CircleMemberSettingsPage extends ConsumerWidget {
  const CircleMemberSettingsPage({
    required this.circleId,
    required this.membershipId,
    super.key,
  });

  final String circleId;
  final String membershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = ref.watch(circleDetailProvider(circleId));
    final members = ref.watch(circleMembersProvider(circleId));

    return CircleScreenScaffold(
      title: 'Member access',
      body: circle.when(
        loading: () => const OrbitLoadingState(),
        error: (_, _) => OrbitErrorState(
          title: 'Circle could not be loaded',
          message: 'Try again before changing member access.',
          onRetry: () => ref.invalidate(circleDetailProvider(circleId)),
        ),
        data: (circleValue) => members.when(
          loading: () => const OrbitLoadingState(),
          error: (_, _) => OrbitErrorState(
            title: 'Member could not be loaded',
            message: 'Check your connection and try again.',
            onRetry: () => ref.invalidate(circleMembersProvider(circleId)),
          ),
          data: (items) {
            OrbitCircleMember? target;
            for (final member in items) {
              if (member.membershipId == membershipId) {
                target = member;
                break;
              }
            }
            if (target == null) {
              return OrbitErrorState(
                title: 'Member unavailable',
                message: 'This membership may have changed.',
                onRetry: () => ref.invalidate(circleMembersProvider(circleId)),
              );
            }
            return _MemberSettingsContent(circle: circleValue, member: target);
          },
        ),
      ),
    );
  }
}

class _MemberSettingsContent extends ConsumerWidget {
  const _MemberSettingsContent({required this.circle, required this.member});

  final OrbitCircle circle;
  final OrbitCircleMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutation = ref.watch(circleMutationControllerProvider);
    final assignable = CirclePermissions.assignableRoles(
      circle: circle,
      target: member,
    );
    final canRemove = CirclePermissions.canRemove(
      circle: circle,
      target: member,
    );

    return SingleChildScrollView(
      child: CircleContentPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            OrbitGlassCard(
              padding: const EdgeInsets.all(OrbitSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    member.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: OrbitSpacing.md),
                  Text(
                    'Current role: ${_roleLabel(member.role)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            if (assignable.isNotEmpty) ...<Widget>[
              const SizedBox(height: OrbitSpacing.lg),
              Text('Role', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: OrbitSpacing.xs),
              Text(
                'Role changes are enforced by the Laravel Circle authorization rules.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: OrbitSpacing.md),
              ...assignable.map(
                (role) => Padding(
                  padding: const EdgeInsets.only(bottom: OrbitSpacing.xs),
                  child: OrbitGlassCard(
                    onTap: mutation.isBusy || role == member.role
                        ? null
                        : () => _changeRole(context, ref, role),
                    padding: const EdgeInsets.all(OrbitSpacing.md),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          role == member.role
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: role == member.role
                              ? OrbitColors.primary
                              : OrbitColors.textMuted,
                        ),
                        const SizedBox(width: OrbitSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _roleLabel(role),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _roleDescription(role),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (mutation.hasErrorFor(const <CircleMutationKind>{
              CircleMutationKind.updateRole,
              CircleMutationKind.removeMember,
            })) ...<Widget>[
              const SizedBox(height: OrbitSpacing.md),
              Text(
                mutation.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (canRemove) ...<Widget>[
              const SizedBox(height: OrbitSpacing.xl),
              OrbitPrimaryButton(
                label: 'Remove from Circle',
                icon: Icons.person_remove_alt_1_rounded,
                isBusy: mutation.isBusy,
                backgroundColor: OrbitColors.danger,
                onPressed: () => _remove(context, ref),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    CircleRole role,
  ) async {
    final updated = await ref
        .read(circleMutationControllerProvider.notifier)
        .updateMemberRole(
          circleId: circle.id,
          membershipId: member.membershipId,
          role: role,
        );
    if (updated != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} is now ${_roleLabel(role)}.')),
      );
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
          '${member.name} will lose access to this Circle. This action should only be used when intended.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await ref
        .read(circleMutationControllerProvider.notifier)
        .removeMember(circleId: circle.id, membershipId: member.membershipId);
    if (success && context.mounted) {
      context.pop();
    }
  }

  static String _roleLabel(CircleRole role) {
    return switch (role) {
      CircleRole.owner => 'Owner',
      CircleRole.admin => 'Admin',
      CircleRole.member => 'Member',
      CircleRole.restricted => 'Restricted',
    };
  }

  static String _roleDescription(CircleRole role) {
    return switch (role) {
      CircleRole.owner => 'Owns the Circle.',
      CircleRole.admin =>
        'Can edit the Circle, invite, and manage eligible members.',
      CircleRole.member =>
        'Standard Circle access subject to personal privacy settings.',
      CircleRole.restricted =>
        'Limited Circle role controlled by server-side policy.',
    };
  }
}
