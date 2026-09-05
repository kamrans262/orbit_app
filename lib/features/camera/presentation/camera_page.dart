import 'package:flutter/material.dart';

import '../../../core/widgets/orbit_feature_placeholder.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrbitFeaturePlaceholder(
      title: 'Camera',
      subtitle:
          'Camera and encrypted media flows will be added in their dedicated milestone.',
      icon: Icons.photo_camera_rounded,
    );
  }
}
