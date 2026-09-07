import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_glass_card.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    required this.onPing,
    required this.onSos,
    required this.onAddMember,
    required this.onOpenMap,
    super.key,
  });

  final VoidCallback onPing;
  final VoidCallback onSos;
  final VoidCallback onAddMember;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickActionData>[
      _QuickActionData(
        title: 'Ping',
        subtitle: "Let them know\nyou're good",
        icon: Icons.near_me_rounded,
        accent: OrbitColors.primary,
        onTap: onPing,
      ),
      _QuickActionData(
        title: 'SOS',
        subtitle: 'Get help now',
        icon: Icons.emergency_rounded,
        accent: OrbitColors.danger,
        isDanger: true,
        onTap: onSos,
      ),
      _QuickActionData(
        title: 'Circle',
        subtitle: 'People & sharing',
        icon: Icons.groups_2_rounded,
        accent: OrbitColors.primary,
        onTap: onAddMember,
      ),
      _QuickActionData(
        title: 'Location',
        subtitle: 'Privacy-aware map',
        icon: Icons.location_on_outlined,
        accent: OrbitColors.teal,
        onTap: onOpenMap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const visibleCardCount = 3;
        final spacing = OrbitSpacing.sm;
        final visibleWidth = constraints.maxWidth;
        final cardWidth =
            (visibleWidth - (spacing * (visibleCardCount - 1))) /
            visibleCardCount;

        return SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, _) => SizedBox(width: spacing),
            itemBuilder: (context, index) => SizedBox(
              width: cardWidth,
              child: _QuickActionCard(data: actions[index]),
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: OrbitGlassCard(
        onTap: data.onTap,
        tint: data.isDanger
            ? OrbitColors.danger.withValues(alpha: 0.22)
            : data.accent.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(
          horizontal: OrbitSpacing.xs,
          vertical: OrbitSpacing.sm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(data.icon, color: data.accent, size: 32),
            const SizedBox(height: OrbitSpacing.sm),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: OrbitSpacing.xs),
            Text(
              data.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: OrbitColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.isDanger = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool isDanger;
}
