import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/sos_models.dart';

class SosStatusCard extends StatelessWidget {
  const SosStatusCard({required this.incident, super.key});

  final SosIncident incident;

  @override
  Widget build(BuildContext context) {
    final resolved = !incident.isActive;
    final accent = resolved ? OrbitColors.success : OrbitColors.danger;

    return OrbitGlassCard(
      tint: accent.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(OrbitSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                resolved ? Icons.verified_rounded : Icons.sos_rounded,
                color: accent,
                size: 32,
              ),
              const SizedBox(width: OrbitSpacing.sm),
              Expanded(
                child: Text(
                  resolved ? 'SOS resolved' : 'SOS is active',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OrbitSpacing.md),
          Text(
            resolved
                ? 'This emergency incident is no longer active.'
                : _stageMessage(incident.escalationStage),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (!resolved && incident.escalationStage >= 3) ...<Widget>[
            const SizedBox(height: OrbitSpacing.sm),
            Text(
              'If you are in immediate danger, contact your local emergency services. Orbit never auto-dials emergency services.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: OrbitColors.warning),
            ),
          ],
        ],
      ),
    );
  }

  static String _stageMessage(int stage) {
    return switch (stage) {
      <= 0 =>
        'Your Circle has been alerted. Keep this screen open for incident updates.',
      1 => 'Orbit is re-notifying Circle responders who have not engaged yet.',
      2 =>
        'Orbit recorded the external-contact fallback stage. Provider delivery is not assumed until confirmed by the backend provider integration.',
      _ =>
        'No responder has engaged yet. Orbit is showing the emergency-services guidance stage.',
    };
  }
}
