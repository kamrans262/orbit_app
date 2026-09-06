import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/moment_models.dart';

class MomentSummaryCard extends StatelessWidget {
  const MomentSummaryCard({
    required this.item,
    required this.onTap,
    this.width,
    super.key,
  });

  final RecentMomentItem item;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final moment = item.moment;
    final icon = moment.media.kind.name == 'video'
        ? Icons.videocam_rounded
        : Icons.photo_rounded;
    final age = _age(moment.createdAt);

    return SizedBox(
      width: width,
      child: OrbitGlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(OrbitSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 112,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    OrbitColors.primary.withValues(alpha: 0.35),
                    OrbitColors.purple.withValues(alpha: 0.18),
                    OrbitColors.surfaceSoft,
                  ],
                ),
              ),
              child: Center(child: Icon(icon, size: 38, color: Colors.white70)),
            ),
            const SizedBox(height: OrbitSpacing.sm),
            Text(
              moment.author.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              '${item.circleName} • $age',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  static String _age(DateTime createdAt) {
    final delta = DateTime.now().toUtc().difference(createdAt.toUtc());
    if (delta.inMinutes < 1) {
      return 'now';
    }
    if (delta.inHours < 1) {
      return '${delta.inMinutes}m';
    }
    if (delta.inDays < 1) {
      return '${delta.inHours}h';
    }
    return '${delta.inDays}d';
  }
}
