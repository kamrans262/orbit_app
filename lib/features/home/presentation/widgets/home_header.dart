import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_avatar.dart';
import '../../domain/home_dashboard.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.user, super.key});

  final HomeUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const _OrbitWordmark(),
            const Spacer(),
            OrbitAvatar(
              initials: user.initials,
              size: 48,
              isOnline: true,
              backgroundColor: const Color(0xFF6A4B43),
            ),
          ],
        ),
        const SizedBox(height: OrbitSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Good evening, ${user.name}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: OrbitSpacing.xs),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: OrbitColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: OrbitSpacing.xs),
                      Flexible(
                        child: Text(
                          '${user.activeCircleCount} circles, all calm',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: OrbitColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: OrbitSpacing.md),
            const _MissionLine(),
          ],
        ),
      ],
    );
  }
}

class _OrbitWordmark extends StatelessWidget {
  const _OrbitWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 34,
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: OrbitColors.textPrimary,
                    width: 2.6,
                  ),
                ),
              ),
              Positioned(
                top: 1,
                right: 2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: OrbitColors.backgroundElevated,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: OrbitSpacing.xs),
        Text(
          'Orbit',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: 24),
        ),
      ],
    );
  }
}

class _MissionLine extends StatelessWidget {
  const _MissionLine();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 112),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              'Safer people\nbrighter tomorrows',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: OrbitColors.textMuted,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: OrbitSpacing.xs),
          const Icon(
            Icons.favorite_border_rounded,
            color: OrbitColors.danger,
            size: 18,
          ),
        ],
      ),
    );
  }
}
