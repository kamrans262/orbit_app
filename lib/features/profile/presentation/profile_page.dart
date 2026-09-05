import 'package:flutter/material.dart';

import '../../../core/widgets/orbit_feature_placeholder.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrbitFeaturePlaceholder(
      title: 'Profile',
      subtitle:
          'Identity, settings, devices and privacy controls will be built against the existing API.',
      icon: Icons.person_outline_rounded,
    );
  }
}
