import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/design_system/orbit_theme.dart';
import 'package:orbit_app/features/sos/presentation/widgets/sos_hold_button.dart';

void main() {
  testWidgets('requires the full three-second hold before activating', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: OrbitTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SosHoldButton(onCompleted: () => activations += 1),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(SosHoldButton));
    final shortHold = await tester.startGesture(center);
    await tester.pump(const Duration(seconds: 2));
    await shortHold.up();
    await tester.pump();
    expect(activations, 0);

    final fullHold = await tester.startGesture(center);
    await tester.pump(const Duration(seconds: 3));
    expect(activations, 1);
    await fullHold.up();
    await tester.pump();
    expect(activations, 1);
  });
}
