import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/orbit_notification.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    required this.announcement,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final OrbitAnnouncement announcement;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isSecurity = announcement.type.toLowerCase().contains('security');
    final accent = isSecurity ? OrbitColors.warning : OrbitColors.primary;
    return OrbitGlassCard(
      onTap: onTap,
      tint: accent.withValues(alpha: 0.08),
      padding: EdgeInsets.all(compact ? OrbitSpacing.sm : OrbitSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: compact ? 38 : 42,
            height: compact ? 38 : 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSecurity ? Icons.security_rounded : Icons.campaign_outlined,
              color: accent,
              size: compact ? 19 : 21,
            ),
          ),
          const SizedBox(width: OrbitSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  announcement.title,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (!compact && announcement.body.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    announcement.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: OrbitColors.textMuted),
        ],
      ),
    );
  }
}
