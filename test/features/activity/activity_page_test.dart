import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/design_system/orbit_theme.dart';
import 'package:orbit_app/features/activity/data/activity_repository.dart';
import 'package:orbit_app/features/activity/domain/activity_item.dart';
import 'package:orbit_app/features/activity/presentation/activity_page.dart';
import 'package:orbit_app/features/activity/presentation/activity_providers.dart';
import 'package:orbit_app/features/notifications/data/notifications_repository.dart';
import 'package:orbit_app/features/notifications/domain/orbit_notification.dart';
import 'package:orbit_app/features/notifications/presentation/notification_providers.dart';

void main() {
  testWidgets('renders real Activity feed and remains compact-phone safe', (
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
          activityRepositoryProvider.overrideWithValue(
            const _FakeActivityRepository(),
          ),
          notificationsRepositoryProvider.overrideWithValue(
            const _FakeNotificationsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: OrbitTheme.dark(),
          home: const Scaffold(body: ActivityPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('A new Moment was shared'), findsOneWidget);
    expect(find.text('Image Moment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeActivityRepository implements ActivityRepository {
  const _FakeActivityRepository();

  @override
  Future<ActivityFeedPage> listFeed({int limit = 20, String? cursor}) async {
    return ActivityFeedPage(
      items: <ActivityItem>[
        ActivityItem(
          id: 'activity-1',
          type: 'moment.published',
          circleId: 'circle-1',
          actorUserId: 7,
          sourceType: 'moment',
          sourceId: 'moment-1',
          payload: const <String, Object?>{'media_type': 'image'},
          occurredAt: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ],
      hasMore: false,
    );
  }

  @override
  Future<void> hide(String activityId) async {}

  @override
  Future<void> report({
    required String activityId,
    required ActivityReportReason reason,
    String? details,
  }) async {}
}

class _FakeNotificationsRepository implements NotificationsRepository {
  const _FakeNotificationsRepository();

  @override
  Future<NotificationFeed> listNotifications({int limit = 50}) async {
    return const NotificationFeed(
      items: <OrbitNotification>[],
      unreadCount: 0,
      limit: 50,
    );
  }

  @override
  Future<List<OrbitAnnouncement>> listAnnouncements() async =>
      const <OrbitAnnouncement>[];

  @override
  Future<NotificationPreferences> getPreferences() =>
      throw UnimplementedError();

  @override
  Future<OrbitNotification> markRead(String notificationId) =>
      throw UnimplementedError();

  @override
  Future<int> markAllRead() => throw UnimplementedError();

  @override
  Future<void> updateCirclePreference({
    required String circleId,
    DateTime? mutedUntil,
    bool clearMute = false,
    bool? silent,
  }) => throw UnimplementedError();

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) => throw UnimplementedError();
}
