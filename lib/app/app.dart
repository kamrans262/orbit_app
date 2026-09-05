import 'package:flutter/material.dart';

import '../core/design_system/orbit_theme.dart';
import 'routing/app_router.dart';

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Orbit',
      debugShowCheckedModeBanner: false,
      theme: OrbitTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
