import 'package:flutter/material.dart';

import '../design_system/orbit_colors.dart';
import '../design_system/orbit_radius.dart';
import '../design_system/orbit_spacing.dart';

class OrbitPrimaryButton extends StatelessWidget {
  const OrbitPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isBusy = false,
    this.backgroundColor,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isBusy;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isBusy ? null : onPressed;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? OrbitColors.primaryStrong,
          foregroundColor: Colors.white,
          disabledBackgroundColor: OrbitColors.surfaceElevated,
          disabledForegroundColor: OrbitColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OrbitRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.lg),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isBusy
              ? const SizedBox(
                  key: ValueKey<String>('busy'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : Row(
                  key: const ValueKey<String>('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 20),
                      const SizedBox(width: OrbitSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
