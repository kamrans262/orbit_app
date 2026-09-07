import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/push/application/orbit_push_bootstrap.dart';
import 'features/push/presentation/push_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pushSource = await OrbitPushBootstrap.createSource();
  runApp(
    ProviderScope(
      overrides: [pushTokenSourceProvider.overrideWithValue(pushSource)],
      child: const OrbitApp(),
    ),
  );
}
