import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_radius.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_avatar.dart';
import '../../domain/home_dashboard.dart';

class MomentCard extends StatelessWidget {
  const MomentCard({required this.moment, required this.width, super.key});

  final HomeMoment moment;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 184,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OrbitRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: moment.palette,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Color(0x33000000),
                    Color(0xE6000000),
                  ],
                  stops: <double>[0.34, 0.58, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white.withValues(alpha: 0.65),
                size: 20,
              ),
            ),
            Positioned(
              left: OrbitSpacing.sm,
              right: OrbitSpacing.sm,
              bottom: OrbitSpacing.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      OrbitAvatar(
                        initials: moment.ownerInitials,
                        size: 32,
                        isOnline: true,
                      ),
                      const SizedBox(width: OrbitSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              moment.owner,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              moment.age,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: OrbitColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: OrbitSpacing.sm),
                  Row(
                    children: <Widget>[
                      Icon(moment.icon, size: 17, color: moment.accent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          moment.circleName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: OrbitColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
