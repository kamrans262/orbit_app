import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../domain/sos_models.dart';

class SosResponderCard extends StatelessWidget {
  const SosResponderCard({required this.responder, super.key});

  final SosResponder responder;

  @override
  Widget build(BuildContext context) {
    final color = switch (responder.status) {
      SosResponderStatus.engaged => OrbitColors.success,
      SosResponderStatus.declined => OrbitColors.textMuted,
      SosResponderStatus.pending => OrbitColors.warning,
    };
    final label = switch (responder.status) {
      SosResponderStatus.engaged => 'Engaged',
      SosResponderStatus.declined => 'Declined',
      SosResponderStatus.pending => 'Awaiting response',
    };

    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.person_rounded, color: color),
          ),
          const SizedBox(width: OrbitSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Circle member ${responder.userId}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (responder.location != null)
            const Icon(Icons.my_location_rounded, color: OrbitColors.primary),
        ],
      ),
    );
  }
}
