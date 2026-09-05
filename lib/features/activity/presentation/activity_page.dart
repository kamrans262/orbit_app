import 'package:flutter/material.dart';

import '../../../core/widgets/orbit_feature_placeholder.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrbitFeaturePlaceholder(
      title: 'Activity',
      subtitle:
          'The activity timeline will be connected to the existing backend contracts later.',
      icon: Icons.notifications_none_rounded,
    );
  }
}
