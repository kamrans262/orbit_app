import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/design_system/orbit_theme.dart';
import 'package:orbit_app/core/providers/core_providers.dart';
import 'package:orbit_app/features/home/data/api_home_overview_repository.dart';
import 'package:orbit_app/features/home/domain/home_overview.dart';
import 'package:orbit_app/features/home/presentation/home_overview_providers.dart';
import 'package:orbit_app/features/home/presentation/home_page.dart';
import 'package:orbit_app/features/ping/data/ping_repository.dart';
import 'package:orbit_app/features/ping/domain/ping_item.dart';
import 'package:orbit_app/features/ping/presentation/ping_controller.dart';
import 'package:orbit_app/features/presence/domain/presence_snapshot.dart';

import '../../support/auth_test_fakes.dart';

void main() {
  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(SignedOutAuthRepository()),
        homeOverviewRepositoryProvider.overrideWithValue(
          const _FakeHomeOverviewRepository(),
        ),
        pingRepositoryProvider.overrideWithValue(const _FakePingRepository()),
      ],
      child: MaterialApp(
        theme: OrbitTheme.dark(),
        home: const Scaffold(body: HomePage()),
      ),
    );
  }

  testWidgets('renders API-backed Home structure without preview sections', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Good evening, there'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('2 online'), findsOneWidget);
    expect(find.text('Ping'), findsWidgets);
    expect(find.text('Presence & privacy'), findsOneWidget);
    expect(find.text('Recent Moments'), findsNothing);
  });

  testWidgets('M3 Home does not overflow on a compact phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Good evening, there'), findsOneWidget);
  });
}

class _FakeHomeOverviewRepository implements HomeOverviewRepository {
  const _FakeHomeOverviewRepository();

  @override
  Future<List<HomeCircleSummary>> listCircles() async {
    return const <HomeCircleSummary>[
      HomeCircleSummary(
        id: 'circle-1',
        name: 'Family',
        memberCount: 2,
        myMembershipId: 'member-1',
      ),
    ];
  }

  @override
  Future<List<HomePresenceMember>> listCirclePresence(String circleId) async {
    return const <HomePresenceMember>[
      HomePresenceMember(
        membershipId: 'member-1',
        userId: 7,
        name: 'Maya',
        status: PresenceStatus.online,
        locationMode: PresenceLocationMode.precise,
      ),
      HomePresenceMember(
        membershipId: 'member-2',
        userId: 8,
        name: 'Noah',
        status: PresenceStatus.online,
        locationMode: PresenceLocationMode.approximate,
      ),
    ];
  }
}

class _FakePingRepository implements PingRepository {
  const _FakePingRepository();

  @override
  Future<List<PingItem>> listInbox() async => const <PingItem>[];

  @override
  Future<List<PingItem>> listSent() async => const <PingItem>[];

  @override
  Future<List<PingCircleOption>> listCircles() async =>
      const <PingCircleOption>[];

  @override
  Future<List<PingTarget>> listTargets(PingCircleOption circle) async =>
      const <PingTarget>[];

  @override
  Future<PingItem> send({
    required String circleId,
    required String recipientMembershipId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PingItem> respond(String pingId, PingResponseType responseType) {
    throw UnimplementedError();
  }

  @override
  Future<PingItem> dismiss(String pingId) {
    throw UnimplementedError();
  }
}
