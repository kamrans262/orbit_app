import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/design_system/orbit_theme.dart';
import 'package:orbit_app/features/notifications/data/notifications_repository.dart';
import 'package:orbit_app/features/notifications/domain/orbit_notification.dart';
import 'package:orbit_app/features/notifications/presentation/notification_providers.dart';
import 'package:orbit_app/features/notifications/presentation/notifications_page.dart';

void main() {
  testWidgets(
    'renders announcements, unread count and safe notification summary',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(
              const _FakeNotificationsRepository(),
            ),
          ],
          child: MaterialApp(
            theme: OrbitTheme.dark(),
            home: const Scaffold(body: NotificationsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Orbit announcements'), findsOneWidget);
      expect(find.text('Security update'), findsOneWidget);
      expect(find.text('Inbox · 1 unread'), findsOneWidget);
      expect(find.text('New message'), findsOneWidget);
      expect(find.text('must never render'), findsNothing);
    },
  );
}

class _FakeNotificationsRepository implements NotificationsRepository {
  const _FakeNotificationsRepository();

  @override
  Future<NotificationFeed> listNotifications({int limit = 50}) async {
    return NotificationFeed(
      unreadCount: 1,
      limit: 50,
      items: <OrbitNotification>[
        OrbitNotification(
          id: 'notification-1',
          kind: 'message.received',
          priority: 'normal',
          summary: 'New message',
          circleId: 'circle-1',
          payload: const <String, Object?>{
            'encrypted_preview': 'cipher',
            'plaintext': 'must never render',
          },
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  @override
  Future<List<OrbitAnnouncement>> listAnnouncements() async {
    return <OrbitAnnouncement>[
      OrbitAnnouncement(
        id: 'announcement-1',
        type: 'security',
        priority: 100,
        dismissible: false,
        title: 'Security update',
        body: 'Review this important Orbit security notice.',
      ),
    ];
  }

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
