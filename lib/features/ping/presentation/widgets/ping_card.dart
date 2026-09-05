import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_radius.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/ping_item.dart';

class PingCard extends StatelessWidget {
  const PingCard({
    required this.ping,
    required this.isIncoming,
    this.isBusy = false,
    this.onHey,
    this.onShareLocation,
    this.onDismiss,
    super.key,
  });

  final PingItem ping;
  final bool isIncoming;
  final bool isBusy;
  final VoidCallback? onHey;
  final VoidCallback? onShareLocation;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final otherName = isIncoming ? ping.sender.name : ping.recipient.name;
    final statusColor = switch (ping.status) {
      PingStatus.pending => OrbitColors.primary,
      PingStatus.responded => OrbitColors.success,
      PingStatus.dismissed => OrbitColors.textMuted,
      PingStatus.expired => OrbitColors.warning,
    };

    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.12),
                  border: Border.all(color: OrbitColors.borderSubtle),
                ),
                child: const Icon(
                  Icons.near_me_rounded,
                  color: OrbitColors.primary,
                ),
              ),
              const SizedBox(width: OrbitSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isIncoming
                          ? '$otherName pinged you'
                          : 'Ping to $otherName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ping.circleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OrbitSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(OrbitRadius.pill),
                ),
                child: Text(
                  _statusLabel(ping),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          if (isIncoming && ping.status == PingStatus.pending) ...<Widget>[
            const SizedBox(height: OrbitSpacing.md),
            Wrap(
              spacing: OrbitSpacing.xs,
              runSpacing: OrbitSpacing.xs,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onHey,
                  icon: const Icon(Icons.waving_hand_rounded, size: 18),
                  label: const Text('Hey'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onShareLocation,
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text('Share location intent'),
                ),
                TextButton.icon(
                  onPressed: isBusy ? null : onDismiss,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(PingItem ping) {
    if (ping.status == PingStatus.pending) {
      final remaining = ping.expiresAt.toUtc().difference(
        DateTime.now().toUtc(),
      );
      if (remaining.inSeconds <= 0) {
        return 'Expired';
      }
      return '${remaining.inSeconds.clamp(1, 120)}s';
    }

    return switch (ping.status) {
      PingStatus.responded =>
        ping.responseType == 'share_location' ? 'Location intent' : 'Responded',
      PingStatus.dismissed => 'Dismissed',
      PingStatus.expired => 'Expired',
      PingStatus.pending => 'Pending',
    };
  }
}
