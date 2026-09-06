import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/orbit_circle.dart';

class CircleListCard extends StatelessWidget {
  const CircleListCard({required this.circle, required this.onTap, super.key});

  final OrbitCircle circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (circle.myRole) {
      CircleRole.owner => OrbitColors.primary,
      CircleRole.admin => OrbitColors.purple,
      CircleRole.member => OrbitColors.success,
      CircleRole.restricted => OrbitColors.warning,
    };

    return OrbitGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OrbitSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.34)),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.groups_2_rounded, color: accent),
          ),
          const SizedBox(width: OrbitSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        circle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    CircleRolePill(role: circle.myRole),
                  ],
                ),
                const SizedBox(height: OrbitSpacing.xs),
                Text(
                  _summary(circle),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: OrbitSpacing.xs),
          const Icon(Icons.chevron_right_rounded, color: OrbitColors.textMuted),
        ],
      ),
    );
  }

  static String _summary(OrbitCircle circle) {
    final members =
        '${circle.memberCount} ${circle.memberCount == 1 ? 'member' : 'members'}';
    if (circle.type == CircleType.temporary && circle.expiresAt != null) {
      return '$members • Temporary Circle';
    }
    return members;
  }
}

class CircleRolePill extends StatelessWidget {
  const CircleRolePill({required this.role, super.key});

  final CircleRole role;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      CircleRole.owner => 'Owner',
      CircleRole.admin => 'Admin',
      CircleRole.member => 'Member',
      CircleRole.restricted => 'Restricted',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: OrbitColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OrbitColors.borderSubtle),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
