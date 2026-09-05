import 'dart:ui';

import 'package:flutter/material.dart';

import '../design_system/orbit_colors.dart';
import '../design_system/orbit_radius.dart';

class OrbitGlassCard extends StatelessWidget {
  const OrbitGlassCard({
    required this.child,
    this.padding,
    this.borderRadius = OrbitRadius.lg,
    this.onTap,
    this.tint,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint ?? OrbitColors.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: OrbitColors.borderSubtle),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      ),
    );
  }
}
