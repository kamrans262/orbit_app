import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_glass_card.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    const actions = <_QuickActionData>[
      _QuickActionData(
        title: 'Ping',
        subtitle: "Let them know\nyou're good",
        icon: Icons.near_me_rounded,
        accent: OrbitColors.primary,
      ),
      _QuickActionData(
        title: 'SOS',
        subtitle: 'Get help now',
        icon: Icons.sos_rounded,
        accent: OrbitColors.danger,
        isDanger: true,
      ),
      _QuickActionData(
        title: 'Add Member',
        subtitle: 'Grow your circle',
        icon: Icons.person_add_alt_1_rounded,
        accent: OrbitColors.primary,
      ),
      _QuickActionData(
        title: 'Open Map',
        subtitle: 'See everyone nearby',
        icon: Icons.map_outlined,
        accent: OrbitColors.teal,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth < 340 ? 2 : 4;
        final spacing = OrbitSpacing.sm;
        final itemWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions
              .map(
                (action) => SizedBox(
                  width: itemWidth,
                  child: _QuickActionCard(data: action),
                ),
              )
              .toList(growable: false),
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
    return SizedBox(
      height: 156,
      child: OrbitGlassCard(
        onTap: () {},
        tint: data.isDanger
            ? OrbitColors.danger.withValues(alpha: 0.22)
            : data.accent.withValues(alpha: 0.08),
        padding: const EdgeInsets.all(OrbitSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(data.icon, color: data.accent, size: 34),
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
    this.isDanger = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool isDanger;
}
