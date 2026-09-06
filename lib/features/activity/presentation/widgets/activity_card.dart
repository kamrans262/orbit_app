import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/activity_item.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.item,
    this.onHide,
    this.onReport,
    this.isBusy = false,
    this.compact = false,
    super.key,
  });

  final ActivityItem item;
  final VoidCallback? onHide;
  final VoidCallback? onReport;
  final bool isBusy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final presentation = _ActivityPresentation.from(item.kind);
    return OrbitGlassCard(
      padding: EdgeInsets.all(compact ? OrbitSpacing.sm : OrbitSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: compact ? 38 : 44,
            height: compact ? 38 : 44,
            decoration: BoxDecoration(
              color: presentation.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              presentation.icon,
              size: compact ? 19 : 22,
              color: presentation.color,
            ),
          ),
          const SizedBox(width: OrbitSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.primaryText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (item.secondaryText != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    item.secondaryText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _relativeTime(item.occurredAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: OrbitColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (!compact && (onHide != null || onReport != null))
            PopupMenuButton<_ActivityMenuAction>(
              enabled: !isBusy,
              tooltip: 'Activity options',
              onSelected: (value) {
                switch (value) {
                  case _ActivityMenuAction.hide:
                    onHide?.call();
                    break;
                  case _ActivityMenuAction.report:
                    onReport?.call();
                    break;
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<_ActivityMenuAction>>[
                if (onHide != null)
                  const PopupMenuItem<_ActivityMenuAction>(
                    value: _ActivityMenuAction.hide,
                    child: Text('Hide from my feed'),
                  ),
                if (onReport != null)
                  const PopupMenuItem<_ActivityMenuAction>(
                    value: _ActivityMenuAction.report,
                    child: Text('Report activity'),
                  ),
              ],
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.more_horiz_rounded),
            ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime occurredAt) {
    final difference = DateTime.now().difference(occurredAt);
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
    final local = occurredAt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

enum _ActivityMenuAction { hide, report }

class _ActivityPresentation {
  const _ActivityPresentation(this.icon, this.color);

  final IconData icon;
  final Color color;

  factory _ActivityPresentation.from(ActivityKind kind) {
    return switch (kind) {
      ActivityKind.momentPublished => const _ActivityPresentation(
        Icons.auto_awesome_rounded,
        OrbitColors.purple,
      ),
      ActivityKind.memberJoined => const _ActivityPresentation(
        Icons.person_add_alt_1_rounded,
        OrbitColors.success,
      ),
      ActivityKind.memberLeft => const _ActivityPresentation(
        Icons.person_remove_alt_1_rounded,
        OrbitColors.textMuted,
      ),
      ActivityKind.sosActivated => const _ActivityPresentation(
        Icons.sos_rounded,
        OrbitColors.danger,
      ),
      ActivityKind.sosEscalated => const _ActivityPresentation(
        Icons.sos_rounded,
        OrbitColors.danger,
      ),
      ActivityKind.sosResolved => const _ActivityPresentation(
        Icons.health_and_safety_rounded,
        OrbitColors.success,
      ),
      ActivityKind.other => const _ActivityPresentation(
        Icons.notifications_none_rounded,
        OrbitColors.primary,
      ),
    };
  }
}
