import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/orbit_api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../data/notifications_repository.dart';
import '../domain/orbit_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return HttpNotificationsRepository(
    apiClient: ref.watch(orbitApiClientProvider),
    envelopeClient: ref.watch(orbitApiEnvelopeClientProvider),
  );
});

final announcementsProvider = FutureProvider<List<OrbitAnnouncement>>((ref) {
  return ref.watch(notificationsRepositoryProvider).listAnnouncements();
});

final announcementByIdProvider =
    FutureProvider.family<OrbitAnnouncement?, String>((
      ref,
      announcementId,
    ) async {
      final announcements = await ref.watch(announcementsProvider.future);
      for (final announcement in announcements) {
        if (announcement.id == announcementId) {
          return announcement;
        }
      }
      return null;
    });

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, NotificationsViewState>(
      NotificationsController.new,
    );

class NotificationsViewState {
  const NotificationsViewState({
    required this.items,
    required this.unreadCount,
    this.busyNotificationId,
    this.isMarkingAllRead = false,
    this.errorMessage,
  });

  final List<OrbitNotification> items;
  final int unreadCount;
  final String? busyNotificationId;
  final bool isMarkingAllRead;
  final String? errorMessage;

  NotificationsViewState copyWith({
    List<OrbitNotification>? items,
    int? unreadCount,
    String? busyNotificationId,
    bool clearBusyNotification = false,
    bool? isMarkingAllRead,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsViewState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      busyNotificationId: clearBusyNotification
          ? null
          : busyNotificationId ?? this.busyNotificationId,
      isMarkingAllRead: isMarkingAllRead ?? this.isMarkingAllRead,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class NotificationsController extends AsyncNotifier<NotificationsViewState> {
  NotificationsRepository get _repository =>
      ref.read(notificationsRepositoryProvider);

  @override
  Future<NotificationsViewState> build() async {
    final feed = await _repository.listNotifications();
    return NotificationsViewState(
      items: feed.items,
      unreadCount: feed.unreadCount,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<NotificationsViewState>();
    state = await AsyncValue.guard(build);
    ref.invalidate(announcementsProvider);
  }

  Future<OrbitNotification?> markRead(OrbitNotification notification) async {
    final current = _current;
    if (current == null ||
        notification.isRead ||
        current.busyNotificationId != null) {
      return notification.isRead ? notification : null;
    }

    state = AsyncData<NotificationsViewState>(
      current.copyWith(busyNotificationId: notification.id, clearError: true),
    );
    try {
      final updated = await _repository.markRead(notification.id);
      state = AsyncData<NotificationsViewState>(
        current.copyWith(
          items: current.items
              .map((item) => item.id == updated.id ? updated : item)
              .toList(growable: false),
          unreadCount: current.unreadCount > 0 ? current.unreadCount - 1 : 0,
          clearBusyNotification: true,
          clearError: true,
        ),
      );
      return updated;
    } on OrbitApiException catch (error) {
      state = AsyncData<NotificationsViewState>(
        current.copyWith(
          clearBusyNotification: true,
          errorMessage: error.message,
        ),
      );
      return null;
    } on Object {
      state = AsyncData<NotificationsViewState>(
        current.copyWith(
          clearBusyNotification: true,
          errorMessage: 'Orbit could not update that notification. Try again.',
        ),
      );
      return null;
    }
  }

  Future<bool> markAllRead() async {
    final current = _current;
    if (current == null ||
        current.isMarkingAllRead ||
        current.unreadCount == 0) {
      return false;
    }

    state = AsyncData<NotificationsViewState>(
      current.copyWith(isMarkingAllRead: true, clearError: true),
    );
    try {
      await _repository.markAllRead();
      final now = DateTime.now();
      state = AsyncData<NotificationsViewState>(
        current.copyWith(
          items: current.items
              .map(
                (item) => item.isRead
                    ? item
                    : OrbitNotification(
                        id: item.id,
                        kind: item.kind,
                        priority: item.priority,
                        summary: item.summary,
                        circleId: item.circleId,
                        payload: item.payload,
                        deepLink: item.deepLink,
                        readAt: now,
                        createdAt: item.createdAt,
                      ),
              )
              .toList(growable: false),
          unreadCount: 0,
          isMarkingAllRead: false,
          clearError: true,
        ),
      );
      return true;
    } on OrbitApiException catch (error) {
      state = AsyncData<NotificationsViewState>(
        current.copyWith(isMarkingAllRead: false, errorMessage: error.message),
      );
      return false;
    } on Object {
      state = AsyncData<NotificationsViewState>(
        current.copyWith(
          isMarkingAllRead: false,
          errorMessage: 'Orbit could not mark notifications read. Try again.',
        ),
      );
      return false;
    }
  }

  NotificationsViewState? get _current {
    return state.when(
      data: (value) => value,
      error: (_, _) => null,
      loading: () => null,
    );
  }
}

final notificationPreferencesControllerProvider =
    AsyncNotifierProvider<
      NotificationPreferencesController,
      NotificationPreferencesViewState
    >(NotificationPreferencesController.new);

class NotificationPreferencesViewState {
  const NotificationPreferencesViewState({
    required this.preferences,
    this.isBusy = false,
    this.errorMessage,
  });

  final NotificationPreferences preferences;
  final bool isBusy;
  final String? errorMessage;

  NotificationPreferencesViewState copyWith({
    NotificationPreferences? preferences,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationPreferencesViewState(
      preferences: preferences ?? this.preferences,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class NotificationPreferencesController
    extends AsyncNotifier<NotificationPreferencesViewState> {
  NotificationsRepository get _repository =>
      ref.read(notificationsRepositoryProvider);

  @override
  Future<NotificationPreferencesViewState> build() async {
    return NotificationPreferencesViewState(
      preferences: await _repository.getPreferences(),
    );
  }

  Future<bool> save(NotificationPreferences preferences) async {
    final current = _current;
    if (current == null || current.isBusy) {
      return false;
    }

    state = AsyncData<NotificationPreferencesViewState>(
      current.copyWith(isBusy: true, clearError: true),
    );
    try {
      final updated = await _repository.updatePreferences(preferences);
      state = AsyncData<NotificationPreferencesViewState>(
        NotificationPreferencesViewState(preferences: updated),
      );
      return true;
    } on OrbitApiException catch (error) {
      state = AsyncData<NotificationPreferencesViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
      return false;
    } on Object {
      state = AsyncData<NotificationPreferencesViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Orbit could not save notification preferences.',
        ),
      );
      return false;
    }
  }

  NotificationPreferencesViewState? get _current {
    return state.when(
      data: (value) => value,
      error: (_, _) => null,
      loading: () => null,
    );
  }
}
