import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/design_system/orbit_theme.dart';
import 'package:orbit_app/core/providers/core_providers.dart';
import 'package:orbit_app/features/auth/presentation/pages/email_sign_in_page.dart';

import '../../../support/auth_test_fakes.dart';

void main() {
  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(SignedOutAuthRepository()),
      ],
      child: MaterialApp(
        theme: OrbitTheme.dark(),
        home: const EmailSignInPage(),
      ),
    );
  }

  testWidgets('renders passwordless email sign-in', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Stay close, privately.'), findsOneWidget);
    expect(find.text('Continue securely'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('email sign-in does not overflow on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Stay close, privately.'), findsOneWidget);
  });
}
