import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_radius.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../domain/messaging_models.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, this.onRetry, super.key});

  final LocalMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final outgoing = message.direction == LocalMessageDirection.outgoing;
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.only(bottom: OrbitSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: OrbitSpacing.md,
            vertical: OrbitSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: outgoing
                ? OrbitColors.primaryStrong.withValues(alpha: 0.22)
                : OrbitColors.surfaceElevated,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(OrbitRadius.lg),
              topRight: const Radius.circular(OrbitRadius.lg),
              bottomLeft: Radius.circular(outgoing ? OrbitRadius.lg : 5),
              bottomRight: Radius.circular(outgoing ? 5 : OrbitRadius.lg),
            ),
            border: Border.all(
              color: outgoing
                  ? OrbitColors.primary.withValues(alpha: 0.25)
                  : OrbitColors.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                message.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: OrbitColors.textPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: OrbitSpacing.xxs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _time(message.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: OrbitColors.textMuted,
                    ),
                  ),
                  if (outgoing) ...<Widget>[
                    const SizedBox(width: OrbitSpacing.xs),
                    _StatusIcon(status: message.status),
                  ],
                  if (message.status == LocalMessageStatus.failed &&
                      onRetry != null) ...<Widget>[
                    const SizedBox(width: OrbitSpacing.xs),
                    InkWell(
                      onTap: onRetry,
                      borderRadius: BorderRadius.circular(OrbitRadius.pill),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Text(
                          'Retry',
                          style: TextStyle(color: OrbitColors.danger),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _time(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final LocalMessageStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      LocalMessageStatus.sending => const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      ),
      LocalMessageStatus.sent => const Icon(
        Icons.check_rounded,
        size: 15,
        color: OrbitColors.textMuted,
      ),
      LocalMessageStatus.delivered => const Icon(
        Icons.done_all_rounded,
        size: 15,
        color: OrbitColors.success,
      ),
      LocalMessageStatus.failed => const Icon(
        Icons.error_outline_rounded,
        size: 15,
        color: OrbitColors.danger,
      ),
    };
  }
}
