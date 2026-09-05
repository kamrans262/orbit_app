import 'dart:ui';

import 'package:flutter/material.dart';

import '../design_system/orbit_colors.dart';

class OrbitAtmosphereBackground extends StatelessWidget {
  const OrbitAtmosphereBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF1B2233),
                  Color(0xFF101620),
                  OrbitColors.background,
                ],
                stops: <double>[0, 0.36, 0.78],
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: -70,
            child: _Glow(
              size: 250,
              color: const Color(0xFFD37A50).withValues(alpha: 0.24),
            ),
          ),
          Positioned(
            top: 125,
            left: -70,
            child: _Glow(
              size: 230,
              color: const Color(0xFF7B6EAC).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -110,
            child: _Glow(
              size: 300,
              color: const Color(0xFF2D5A7D).withValues(alpha: 0.16),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Color(0x66090D15),
                  OrbitColors.background,
                ],
                stops: <double>[0.12, 0.46, 0.9],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
