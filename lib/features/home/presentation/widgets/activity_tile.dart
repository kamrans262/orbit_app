import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/home_dashboard.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({required this.activity, super.key});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      onTap: () {},
      padding: const EdgeInsets.symmetric(
        horizontal: OrbitSpacing.md,
        vertical: OrbitSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showCircle = constraints.maxWidth >= 300;

          return Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activity.accent.withValues(alpha: 0.22),
                ),
                child: Icon(activity.icon, color: activity.accent),
              ),
              const SizedBox(width: OrbitSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (showCircle) ...<Widget>[
                const SizedBox(width: OrbitSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.groups_2_rounded,
                        size: 17,
                        color: activity.accent,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          activity.circleName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: OrbitSpacing.xs),
              const Icon(
                Icons.chevron_right_rounded,
                color: OrbitColors.textMuted,
              ),
            ],
          );
        },
      ),
    );
  }
}
