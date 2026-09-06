import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/orbit_notification.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.notification,
    required this.onTap,
    this.isBusy = false,
    super.key,
  });

  final OrbitNotification notification;
  final VoidCallback onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final presentation = _NotificationPresentation.from(notification);
    return OrbitGlassCard(
      onTap: isBusy ? null : onTap,
      padding: const EdgeInsets.all(OrbitSpacing.md),
      tint: notification.isRead
          ? null
          : OrbitColors.primary.withValues(alpha: 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: presentation.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(presentation.icon, color: presentation.color, size: 21),
          ),
          const SizedBox(width: OrbitSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        notification.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (!notification.isRead) ...<Widget>[
                      const SizedBox(width: OrbitSpacing.xs),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: OrbitColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _relativeTime(notification.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: OrbitColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OrbitSpacing.xs),
          if (isBusy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              notification.internalRoute == null
                  ? Icons.check_circle_outline_rounded
                  : Icons.chevron_right_rounded,
              color: OrbitColors.textMuted,
            ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }
}

class _NotificationPresentation {
  const _NotificationPresentation(this.icon, this.color);

  final IconData icon;
  final Color color;

  factory _NotificationPresentation.from(OrbitNotification notification) {
    if (notification.isHighestPriority ||
        notification.kind.startsWith('sos.')) {
      return const _NotificationPresentation(
        Icons.sos_rounded,
        OrbitColors.danger,
      );
    }
    if (notification.kind.startsWith('message.')) {
      return const _NotificationPresentation(
        Icons.chat_bubble_outline_rounded,
        OrbitColors.primary,
      );
    }
    if (notification.kind.startsWith('moment.')) {
      return const _NotificationPresentation(
        Icons.auto_awesome_rounded,
        OrbitColors.purple,
      );
    }
    if (notification.kind.startsWith('ping.')) {
      return const _NotificationPresentation(
        Icons.waving_hand_outlined,
        OrbitColors.warning,
      );
    }
    return const _NotificationPresentation(
      Icons.notifications_none_rounded,
      OrbitColors.teal,
    );
  }
}
