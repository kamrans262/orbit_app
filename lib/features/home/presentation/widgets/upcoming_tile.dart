import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_avatar.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/home_dashboard.dart';

class UpcomingTile extends StatelessWidget {
  const UpcomingTile({required this.item, super.key});

  final HomeUpcomingItem item;

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
          final showMetadata = constraints.maxWidth >= 300;

          return Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OrbitColors.surfaceElevated,
                  border: Border.all(color: OrbitColors.borderSubtle),
                ),
                child: Icon(
                  item.icon,
                  color: OrbitColors.textSecondary,
                  size: 21,
                ),
              ),
              const SizedBox(width: OrbitSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (showMetadata) ...<Widget>[
                const SizedBox(width: OrbitSpacing.sm),
                _MiniAvatarStack(members: item.members),
                const SizedBox(width: OrbitSpacing.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.groups_2_rounded,
                        size: 16,
                        color: item.accent,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.circleName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MiniAvatarStack extends StatelessWidget {
  const _MiniAvatarStack({required this.members});

  final List<HomeMember> members;

  @override
  Widget build(BuildContext context) {
    final visible = members.take(3).toList(growable: false);
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    const avatarSize = 25.0;
    const overlap = 9.0;
    final width = avatarSize + (visible.length - 1) * (avatarSize - overlap);

    return SizedBox(
      width: width,
      height: avatarSize,
      child: Stack(
        children: <Widget>[
          for (var index = 0; index < visible.length; index++)
            Positioned(
              left: index * (avatarSize - overlap),
              child: OrbitAvatar(
                initials: visible[index].initials,
                size: avatarSize,
              ),
            ),
        ],
      ),
    );
  }
}
