import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_radius.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_avatar.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/home_dashboard.dart';

class CircleSummaryCard extends StatelessWidget {
  const CircleSummaryCard({
    required this.circle,
    required this.width,
    super.key,
  });

  final HomeCircle circle;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: OrbitGlassCard(
        padding: const EdgeInsets.all(OrbitSpacing.md),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circle.accent.withValues(alpha: 0.20),
                  ),
                  child: Icon(circle.icon, color: circle.accent),
                ),
                const SizedBox(width: OrbitSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        circle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${circle.memberCount} members',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: OrbitColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: OrbitSpacing.sm),
            _MemberStrip(circle: circle),
            const SizedBox(height: OrbitSpacing.sm),
            _MiniMap(accent: circle.accent),
            const SizedBox(height: OrbitSpacing.sm),
            Row(
              children: <Widget>[
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: OrbitColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: OrbitSpacing.xs),
                Expanded(
                  child: Text(
                    circle.mapLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (circle.alertCount > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrbitSpacing.sm,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: OrbitColors.danger.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(OrbitRadius.pill),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: OrbitColors.danger.withValues(alpha: 0.26),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      '${circle.alertCount}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberStrip extends StatelessWidget {
  const _MemberStrip({required this.circle});

  final HomeCircle circle;

  @override
  Widget build(BuildContext context) {
    final visibleMembers = circle.members.take(3).toList(growable: false);
    final hiddenCount = circle.memberCount - visibleMembers.length;

    return Row(
      children: <Widget>[
        ...visibleMembers.map(
          (member) => Padding(
            padding: const EdgeInsets.only(right: OrbitSpacing.xs),
            child: OrbitAvatar(
              initials: member.initials,
              size: 38,
              isOnline: member.isOnline,
            ),
          ),
        ),
        if (hiddenCount > 0)
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OrbitColors.surfaceElevated,
              border: Border.all(color: OrbitColors.borderSubtle),
            ),
            child: Text(
              '+$hiddenCount',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: OrbitColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OrbitRadius.md),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF293648), Color(0xFF18202D)],
        ),
      ),
      child: CustomPaint(
        painter: _MiniMapPainter(accent),
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.22),
              border: Border.all(color: accent.withValues(alpha: 0.72)),
            ),
            child: Icon(Icons.home_rounded, size: 18, color: accent),
          ),
        ),
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  const _MiniMapPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final pathA = Path()
      ..moveTo(0, size.height * 0.24)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.05,
        size.width,
        size.height * 0.36,
      );
    final pathB = Path()
      ..moveTo(size.width * 0.08, size.height)
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * 0.55,
        size.width * 0.96,
        0,
      );
    final pathC = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(size.width, size.height * 0.78);

    canvas.drawPath(pathA, road);
    canvas.drawPath(pathB, road);
    canvas.drawPath(pathC, road);

    final glow = Paint()
      ..color = accent.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.30), 28, glow);
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
