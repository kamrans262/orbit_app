import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/design_system/orbit_theme.dart';
import 'package:orbit_app/features/home/presentation/home_page.dart';

void main() {
  Widget buildSubject() {
    return ProviderScope(
      child: MaterialApp(
        theme: OrbitTheme.dark(),
        home: const Scaffold(body: HomePage()),
      ),
    );
  }

  testWidgets('renders the reference home dashboard content', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Good evening, Maya'), findsOneWidget);
    expect(find.text('Family'), findsWidgets);
    expect(find.text('Recent Moments'), findsOneWidget);
    expect(find.text('Smart Activity'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('SOS'), findsWidgets);
  });

  testWidgets('does not overflow on a compact phone viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Good evening, Maya'), findsOneWidget);
  });
}
