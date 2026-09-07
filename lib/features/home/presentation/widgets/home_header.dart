import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_avatar.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.displayName,
    required this.circleCount,
    required this.activePingCount,
    super.key,
  });

  final String displayName;
  final int circleCount;
  final int activePingCount;

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
              initials: _initials(displayName),
              size: 48,
              isOnline: true,
              backgroundColor: const Color(0xFF6A4B43),
            ),
          ],
        ),
        const SizedBox(height: OrbitSpacing.lg),
        Text(
          'Good evening, $displayName',
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
              decoration: BoxDecoration(
                color: activePingCount > 0
                    ? OrbitColors.warning
                    : OrbitColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: OrbitSpacing.xs),
            Expanded(
              child: Text(
                _statusLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: OrbitColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _statusLabel() {
    if (activePingCount > 0) {
      final pingLabel = activePingCount == 1 ? 'Ping needs' : 'Pings need';
      return '$circleCount circles • $activePingCount $pingLabel you';
    }
    if (circleCount == 0) {
      return 'Your Orbit is ready';
    }
    return '$circleCount circles, all calm';
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
