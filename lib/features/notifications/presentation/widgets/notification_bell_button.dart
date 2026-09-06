import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../notification_providers.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref
        .watch(notificationsControllerProvider)
        .when(
          data: (value) => value.unreadCount,
          error: (_, _) => 0,
          loading: () => 0,
        );

    return IconButton(
      tooltip: unread > 0 ? '$unread unread notifications' : 'Notifications',
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        backgroundColor: OrbitColors.danger,
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
