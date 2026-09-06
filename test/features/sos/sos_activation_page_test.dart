import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/design_system/orbit_theme.dart';
import 'package:orbit_app/features/circles/data/circles_repository.dart';
import 'package:orbit_app/features/circles/domain/orbit_circle.dart';
import 'package:orbit_app/features/circles/presentation/circle_providers.dart';
import 'package:orbit_app/features/sos/presentation/pages/sos_activation_page.dart';
import 'package:orbit_app/features/sos/presentation/sos_providers.dart';

void main() {
  testWidgets('renders the hold-to-arm SOS flow on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          circlesRepositoryProvider.overrideWithValue(
            const _FakeCirclesRepository(),
          ),
          sosRecoveryProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          theme: OrbitTheme.dark(),
          home: const SosActivationPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Hold 3 seconds to activate SOS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeCirclesRepository implements CirclesRepository {
  const _FakeCirclesRepository();

  static const OrbitCircle circle = OrbitCircle(
    id: 'circle-1',
    name: 'Family',
    type: CircleType.standard,
    myRole: CircleRole.owner,
    myMembershipId: 'membership-me',
    memberCount: 3,
    isArchived: false,
    isExpired: false,
  );

  @override
  Future<List<OrbitCircle>> listCircles() async => const <OrbitCircle>[circle];

  @override
  Future<OrbitCircle> getCircle(String circleId) async => circle;

  @override
  Future<OrbitCircle> createCircle(CreateCircleInput input) =>
      throw UnimplementedError();

  @override
  Future<OrbitCircle> joinCircle(String code) => throw UnimplementedError();

  @override
  Future<OrbitCircle> updateCircle({
    required String circleId,
    required String name,
    String? description,
  }) => throw UnimplementedError();

  @override
  Future<void> archiveCircle(String circleId) => throw UnimplementedError();

  @override
  Future<OrbitCircleInvite> createInvite({
    required String circleId,
    required CreateCircleInviteInput input,
  }) => throw UnimplementedError();

  @override
  Future<List<OrbitCircleMember>> listMembers(String circleId) async =>
      const <OrbitCircleMember>[];

  @override
  Future<OrbitCircleMember> updateMemberRole({
    required String circleId,
    required String membershipId,
    required CircleRole role,
  }) => throw UnimplementedError();

  @override
  Future<void> removeMember({
    required String circleId,
    required String membershipId,
  }) => throw UnimplementedError();

  @override
  Future<void> leaveCircle(String circleId) => throw UnimplementedError();
}
