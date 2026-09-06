import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../core/widgets/orbit_feedback_state.dart';
import '../../../core/widgets/orbit_section_header.dart';
import '../domain/orbit_notification.dart';
import 'notification_providers.dart';
import 'widgets/announcement_card.dart';
import 'widgets/notification_card.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsControllerProvider);
    final announcements = ref.watch(announcementsProvider);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  OrbitSpacing.xs,
                  OrbitSpacing.xs,
                  OrbitSpacing.xs,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    const BackButton(),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Notification preferences',
                      onPressed: () =>
                          context.push('/notifications/preferences'),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: notifications.when(
                  loading: () => const OrbitLoadingState(),
                  error: (_, _) => OrbitErrorState(
                    title: 'Notifications could not be loaded',
                    message: 'Check your connection and try again.',
                    onRetry: () => ref
                        .read(notificationsControllerProvider.notifier)
                        .refresh(),
                  ),
                  data: (value) => _NotificationFeedView(
                    state: value,
                    announcements: announcements,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationFeedView extends ConsumerWidget {
  const _NotificationFeedView({
    required this.state,
    required this.announcements,
  });

  final NotificationsViewState state;
  final AsyncValue<List<OrbitAnnouncement>> announcements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 700
            ? OrbitSpacing.xxl
            : OrbitSpacing.md;
        final maxWidth = constraints.maxWidth >= 900 ? 760.0 : double.infinity;

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationsControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontal,
              OrbitSpacing.md,
              horizontal,
              OrbitSpacing.xxl,
            ),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _AnnouncementsSection(announcements: announcements),
                      const SizedBox(height: OrbitSpacing.lg),
                      OrbitSectionHeader(
                        title: state.unreadCount > 0
                            ? 'Inbox · ${state.unreadCount} unread'
                            : 'Inbox',
                        actionLabel: state.unreadCount > 0
                            ? 'Mark all read'
                            : null,
                        onAction:
                            state.unreadCount > 0 && !state.isMarkingAllRead
                            ? () => ref
                                  .read(
                                    notificationsControllerProvider.notifier,
                                  )
                                  .markAllRead()
                            : null,
                      ),
                      const SizedBox(height: OrbitSpacing.sm),
                      if (state.errorMessage != null) ...<Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(OrbitSpacing.sm),
                          decoration: BoxDecoration(
                            color: OrbitColors.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: OrbitColors.danger.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Text(
                            state.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: OrbitColors.danger),
                          ),
                        ),
                        const SizedBox(height: OrbitSpacing.sm),
                      ],
                      if (state.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: OrbitSpacing.xxl,
                          ),
                          child: OrbitEmptyState(
                            title: 'No notifications yet',
                            message:
                                'Pings, Moments, messages and important Orbit updates will appear here.',
                          ),
                        )
                      else
                        for (final notification in state.items) ...<Widget>[
                          NotificationCard(
                            notification: notification,
                            isBusy: state.busyNotificationId == notification.id,
                            onTap: () =>
                                _openNotification(context, ref, notification),
                          ),
                          const SizedBox(height: OrbitSpacing.sm),
                        ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    OrbitNotification notification,
  ) async {
    final updated = await ref
        .read(notificationsControllerProvider.notifier)
        .markRead(notification);
    if (updated == null || !context.mounted) {
      return;
    }

    final route = updated.internalRoute;
    if (route != null) {
      context.push(route);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Notification marked as read.')),
      );
  }
}

class _AnnouncementsSection extends StatelessWidget {
  const _AnnouncementsSection({required this.announcements});

  final AsyncValue<List<OrbitAnnouncement>> announcements;

  @override
  Widget build(BuildContext context) {
    return announcements.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const OrbitSectionHeader(title: 'Orbit announcements'),
            const SizedBox(height: OrbitSpacing.sm),
            for (final announcement in items.take(3)) ...<Widget>[
              AnnouncementCard(
                announcement: announcement,
                onTap: () => context.push('/announcements/${announcement.id}'),
              ),
              const SizedBox(height: OrbitSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}
