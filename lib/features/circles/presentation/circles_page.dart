import 'package:flutter/material.dart';

import '../../../core/widgets/orbit_feature_placeholder.dart';

class CirclesPage extends StatelessWidget {
  const CirclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrbitFeaturePlaceholder(
      title: 'Circles',
      subtitle:
          'Circle management will be implemented in its dedicated milestone.',
      icon: Icons.groups_2_outlined,
    );
  }
}
