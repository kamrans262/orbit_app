import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_radius.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_avatar.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../../presence/domain/presence_snapshot.dart';
import '../../domain/home_overview.dart';
import '../home_overview_providers.dart';

class CircleSummaryCard extends ConsumerWidget {
  const CircleSummaryCard({
    required this.circle,
    required this.width,
    this.alertCount = 0,
    this.onTap,
    super.key,
  });

  final HomeCircleSummary circle;
  final double width;
  final int alertCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presence = ref.watch(homeCirclePresenceProvider(circle.id));
    final accent = _accentFor(circle.id);

    return SizedBox(
      width: width,
      child: OrbitGlassCard(
        padding: const EdgeInsets.all(OrbitSpacing.md),
        onTap: onTap,
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
                    color: accent.withValues(alpha: 0.20),
                  ),
                  child: Icon(Icons.groups_2_rounded, color: accent),
                ),
                const SizedBox(width: OrbitSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        circle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${circle.memberCount} members',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: OrbitColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: OrbitSpacing.sm),
            presence.when(
              data: (members) => _MemberStrip(
                members: members,
                memberCount: circle.memberCount,
              ),
              loading: () => const _MemberStripLoading(),
              error: (_, _) => Text(
                'Presence unavailable',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: OrbitSpacing.sm),
            _PresencePreview(accent: accent, presence: presence),
            const SizedBox(height: OrbitSpacing.sm),
            Row(
              children: <Widget>[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _statusColor(presence),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: OrbitSpacing.xs),
                Expanded(
                  child: Text(
                    _summaryLabel(presence),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (alertCount > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrbitSpacing.sm,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: OrbitColors.danger.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(OrbitRadius.pill),
                    ),
                    child: Text(
                      '$alertCount',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _accentFor(String id) {
    const accents = <Color>[
      OrbitColors.primary,
      OrbitColors.purple,
      OrbitColors.teal,
      OrbitColors.warning,
    ];
    final hash = id.codeUnits.fold<int>(0, (sum, value) => sum + value);
    return accents[hash % accents.length];
  }

  static Color _statusColor(AsyncValue<List<HomePresenceMember>> presence) {
    return presence.when(
      data: (members) {
        if (members.any((member) => member.status == PresenceStatus.online)) {
          return OrbitColors.success;
        }
        if (members.any((member) => member.status == PresenceStatus.idle)) {
          return OrbitColors.warning;
        }
        if (members.isNotEmpty &&
            members.every((member) => member.status == PresenceStatus.ghost)) {
          return OrbitColors.purple;
        }
        return OrbitColors.textMuted;
      },
      loading: () => OrbitColors.textMuted,
      error: (_, _) => OrbitColors.textMuted,
    );
  }

  static String _summaryLabel(AsyncValue<List<HomePresenceMember>> presence) {
    return presence.when(
      loading: () => 'Checking presence…',
      error: (_, _) => 'Presence unavailable',
      data: (members) {
        if (members.isEmpty) {
          return 'No presence reported';
        }
        final online = members
            .where(
              (member) =>
                  member.status == PresenceStatus.online ||
                  member.status == PresenceStatus.idle,
            )
            .length;
        final ghost = members
            .where((member) => member.status == PresenceStatus.ghost)
            .length;
        if (online > 0 && ghost > 0) {
          return '$online online • $ghost private';
        }
        if (online > 0) {
          return '$online online';
        }
        if (ghost == members.length) {
          return 'Privacy protected';
        }
        return 'No recent presence';
      },
    );
  }
}

class _MemberStrip extends StatelessWidget {
  const _MemberStrip({required this.members, required this.memberCount});

  final List<HomePresenceMember> members;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final visibleMembers = members.take(3).toList(growable: false);
    final hiddenCount = (memberCount - visibleMembers.length).clamp(0, 999);

    return Row(
      children: <Widget>[
        ...visibleMembers.map(
          (member) => Padding(
            padding: const EdgeInsets.only(right: OrbitSpacing.xs),
            child: OrbitAvatar(
              initials: _initials(member.name),
              size: 38,
              isOnline:
                  member.status == PresenceStatus.online ||
                  member.status == PresenceStatus.idle,
            ),
          ),
        ),
        if (hiddenCount > 0)
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OrbitColors.surfaceElevated,
              border: Border.all(color: OrbitColors.borderSubtle),
            ),
            child: Text(
              '+$hiddenCount',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: OrbitColors.textSecondary),
            ),
          ),
      ],
    );
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'O';
    }
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _MemberStripLoading extends StatelessWidget {
  const _MemberStripLoading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        _LoadingAvatar(),
        SizedBox(width: OrbitSpacing.xs),
        _LoadingAvatar(),
        SizedBox(width: OrbitSpacing.xs),
        _LoadingAvatar(),
      ],
    );
  }
}

class _LoadingAvatar extends StatelessWidget {
  const _LoadingAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: OrbitColors.surfaceElevated,
      ),
    );
  }
}

class _PresencePreview extends StatelessWidget {
  const _PresencePreview({required this.accent, required this.presence});

  final Color accent;
  final AsyncValue<List<HomePresenceMember>> presence;

  @override
  Widget build(BuildContext context) {
    final icon = presence.when<IconData>(
      loading: () => Icons.radar_rounded,
      error: (_, _) => Icons.radar_rounded,
      data: (members) {
        if (members.isNotEmpty &&
            members.every(
              (member) => member.locationMode == PresenceLocationMode.ghost,
            )) {
          return Icons.visibility_off_rounded;
        }
        if (members.isNotEmpty &&
            members.every(
              (member) =>
                  member.locationMode == PresenceLocationMode.hidden ||
                  member.locationMode == PresenceLocationMode.ghost,
            )) {
          return Icons.location_off_rounded;
        }
        if (members.any(
          (member) => member.locationMode == PresenceLocationMode.precise,
        )) {
          return Icons.my_location_rounded;
        }
        if (members.any(
          (member) => member.locationMode == PresenceLocationMode.approximate,
        )) {
          return Icons.location_searching_rounded;
        }
        return Icons.radar_rounded;
      },
    );

    return Container(
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OrbitRadius.md),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF293648), Color(0xFF18202D)],
        ),
      ),
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.18),
            border: Border.all(color: accent.withValues(alpha: 0.65)),
          ),
          child: Icon(icon, size: 19, color: accent),
        ),
      ),
    );
  }
}
