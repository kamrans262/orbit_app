import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_radius.dart';

class SosFloatingAction extends StatelessWidget {
  const SosFloatingAction({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Emergency SOS',
      hint: 'Opens the emergency SOS activation screen',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFFF6A65), Color(0xFFD92C35)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: OrbitColors.danger.withValues(alpha: 0.34),
                  blurRadius: OrbitRadius.xl,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(height: 2),
                Text(
                  'SOS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
