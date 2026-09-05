import 'package:flutter/material.dart';

import '../design_system/orbit_colors.dart';
import '../design_system/orbit_spacing.dart';
import 'orbit_atmosphere_background.dart';
import 'orbit_glass_card.dart';

class OrbitFeaturePlaceholder extends StatelessWidget {
  const OrbitFeaturePlaceholder({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(OrbitSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: OrbitGlassCard(
                  padding: const EdgeInsets.all(OrbitSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: OrbitColors.primary.withValues(alpha: 0.12),
                        ),
                        child: Icon(icon, size: 34, color: OrbitColors.primary),
                      ),
                      const SizedBox(height: OrbitSpacing.lg),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: OrbitSpacing.xs),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
