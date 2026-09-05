import 'package:flutter/material.dart';

import '../design_system/orbit_colors.dart';

class OrbitAvatar extends StatelessWidget {
  const OrbitAvatar({
    required this.initials,
    this.size = 40,
    this.isOnline = false,
    this.backgroundColor,
    super.key,
  });

  final String initials;
  final double size;
  final bool isOnline;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor ?? OrbitColors.surfaceElevated,
              border: Border.all(color: OrbitColors.borderStrong),
            ),
            child: Text(
              initials,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: size * 0.30,
                color: OrbitColors.textPrimary,
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.27,
                height: size * 0.27,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OrbitColors.success,
                  border: Border.all(
                    color: OrbitColors.backgroundElevated,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
