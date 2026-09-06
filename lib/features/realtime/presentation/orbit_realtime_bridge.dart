import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/logging/orbit_logger.dart';
import '../../../core/providers/core_providers.dart';
import '../../activity/presentation/activity_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_view_state.dart';
import '../../circles/domain/orbit_circle.dart';
import '../../circles/presentation/circle_providers.dart';
import '../../deep_links/data/app_links_ingress.dart';
import '../../deep_links/presentation/deep_link_providers.dart';
import '../../home/presentation/home_overview_providers.dart';
import '../../messaging/presentation/messaging_providers.dart';
import '../../moments/presentation/moment_providers.dart';
import '../../notifications/presentation/notification_providers.dart';
import '../../ping/presentation/ping_controller.dart';
import '../../presence/presentation/presence_controller.dart';
import '../../push/domain/push_token_source.dart';
import '../../push/presentation/push_providers.dart';
import '../../sos/presentation/sos_providers.dart';
import '../data/reverb_realtime_client.dart';
import '../domain/orbit_realtime_event.dart';
import 'realtime_providers.dart';

class OrbitRealtimeBridge extends ConsumerStatefulWidget {
  const OrbitRealtimeBridge({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<OrbitRealtimeBridge> createState() =>
      _OrbitRealtimeBridgeState();
}

class _OrbitRealtimeBridgeState extends ConsumerState<OrbitRealtimeBridge>
    with WidgetsBindingObserver {
  StreamSubscription<OrbitRealtimeEvent>? _eventSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  StreamSubscription<OrbitPushToken?>? _pushTokenSubscription;

  late final ReverbRealtimeClient _realtime;
  late final DeepLinkIngress _deepLinkIngress;
  late final PushTokenSource _pushSource;
  late final OrbitLogger _logger;

  String? _runtimeFingerprint;
  String? _pushSessionId;
  Uri? _pendingUri;
  String? _lastIngressKey;
  DateTime? _lastIngressAt;
  bool _streamsBound = false;

  @override
  void initState() {
    super.initState();
    _realtime = ref.read(reverbRealtimeClientProvider);
    _deepLinkIngress = ref.read(deepLinkIngressProvider);
    _pushSource = ref.read(pushTokenSourceProvider);
    _logger = ref.read(orbitLoggerProvider);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bindStreams());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeRealtime());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_realtime.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_eventSubscription?.cancel());
    unawaited(_deepLinkSubscription?.cancel());
    unawaited(_pushTokenSubscription?.cancel());
    unawaited(_realtime.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider).asData?.value;
    final authenticated = auth?.stage == AuthStage.authenticated;
    final circles = authenticated
        ? ref.watch(circlesProvider).asData?.value ?? const <OrbitCircle>[]
        : const <OrbitCircle>[];

    final circleIds = circles.map((item) => item.id).toList()..sort();
    final fingerprint = authenticated
        ? '${auth!.user!.id}:${circleIds.join(',')}'
        : 'signed-out';
    if (_runtimeFingerprint != fingerprint) {
      _runtimeFingerprint = fingerprint;
      scheduleMicrotask(() {
        unawaited(_synchronizeRuntime(auth, circles));
      });
    }

    return widget.child;
  }

  Future<void> _bindStreams() async {
    if (!mounted || _streamsBound) {
      return;
    }
    _streamsBound = true;

    _eventSubscription = _realtime.events.listen(
      _handleRealtimeEvent,
      onError: (Object error, StackTrace stackTrace) {
        _logger.error('Realtime event stream failed');
      },
    );

    _deepLinkSubscription = _deepLinkIngress.uriStream.listen(
      _handleUri,
      onError: (Object error, StackTrace stackTrace) {
        _logger.debug('Deep-link ingress stream failed');
      },
    );
    try {
      final initialUri = await _deepLinkIngress.getInitialUri();
      if (initialUri != null && mounted) {
        _handleUri(initialUri);
      }
    } on Object {
      _logger.debug('Cold-start deep link could not be read');
    }

    if (_pushSource.isAvailable) {
      _pushTokenSubscription = _pushSource.tokenChanges.listen(
        (token) => unawaited(_synchronizePushToken(token)),
        onError: (Object error, StackTrace stackTrace) {
          _logger.debug('Push token stream failed');
        },
      );
    }
  }

  Future<void> _synchronizeRuntime(
    AuthViewState? auth,
    List<OrbitCircle> circles,
  ) async {
    try {
      if (auth?.stage != AuthStage.authenticated || auth?.user == null) {
        _pushSessionId = null;
        ref.read(realtimeTypingProvider.notifier).clear();
        await _realtime.stop();
        return;
      }

      final session = await ref.read(sessionStoreProvider).read();
      if (session == null || !mounted) {
        return;
      }

      final userId = auth!.user!.id;
      final channels = <String>{
        'users.$userId',
        'devices.${session.deviceId}',
        'orbit.user.$userId',
        for (final circle in circles) 'circles.${circle.id}',
        for (final circle in circles) 'orbit.circle.${circle.id}',
      };

      await _realtime.start();
      await _realtime.setPersistentChannels(channels);

      if (_pushSource.isAvailable && _pushSessionId != session.sessionId) {
        final synchronized = await _synchronizePushToken(
          await _pushSource.currentToken(),
        );
        if (synchronized) {
          _pushSessionId = session.sessionId;
        }
      }

      final pending = _pendingUri;
      if (pending != null && mounted) {
        _pendingUri = null;
        _navigateAllowedUri(pending);
      }
    } on Object {
      // Realtime is an acceleration path. Durable REST-backed refresh/polling
      // remains available when session/socket/provider synchronization fails.
      _logger.error('Realtime runtime synchronization failed');
    }
  }

  Future<void> _resumeRealtime() async {
    final auth = ref.read(authControllerProvider).asData?.value;
    if (auth?.stage != AuthStage.authenticated) {
      return;
    }
    final circles =
        ref.read(circlesProvider).asData?.value ?? const <OrbitCircle>[];
    _runtimeFingerprint = null;
    await _synchronizeRuntime(auth, circles);

    // Foreground recovery deliberately refreshes durable sources. This is the
    // fallback when the socket was suspended or remote push is not configured.
    ref.invalidate(announcementsProvider);
    await _runRealtimeTask(
      'Foreground notification refresh failed',
      () => ref.read(notificationsControllerProvider.notifier).refresh(),
    );
    await _runRealtimeTask(
      'Foreground activity refresh failed',
      () => ref.read(activityControllerProvider.notifier).refresh(),
    );
  }

  Future<bool> _synchronizePushToken(OrbitPushToken? token) async {
    final auth = ref.read(authControllerProvider).asData?.value;
    if (auth?.stage != AuthStage.authenticated) {
      return false;
    }
    try {
      await ref.read(devicePushRegistrationServiceProvider).synchronize(token);
      return true;
    } on Object {
      // Never log provider tokens or E2EE key material.
      _logger.error('Push token synchronization failed');
      return false;
    }
  }

  void _handleUri(Uri uri) {
    if (ref.read(orbitDeepLinkResolverProvider).resolve(uri) == null) {
      return;
    }

    final now = DateTime.now();
    final ingressKey = uri.toString();
    if (_lastIngressKey == ingressKey &&
        _lastIngressAt != null &&
        now.difference(_lastIngressAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastIngressKey = ingressKey;
    _lastIngressAt = now;

    final auth = ref.read(authControllerProvider).asData?.value;
    if (auth?.stage != AuthStage.authenticated) {
      _pendingUri = uri;
      return;
    }
    _navigateAllowedUri(uri);
  }

  void _navigateAllowedUri(Uri uri) {
    final route = ref.read(orbitDeepLinkResolverProvider).resolve(uri);
    if (route == null) {
      return;
    }
    // Destination pages still load through the authenticated Laravel API, so
    // Circle/SOS authorization remains server-authoritative after allowlisting.
    ref.read(appRouterProvider).go(route);
  }

  void _handleRealtimeEvent(OrbitRealtimeEvent event) {
    final auth = ref.read(authControllerProvider).asData?.value;
    if (auth?.stage != AuthStage.authenticated) {
      return;
    }

    switch (event.name) {
      case 'message.received':
        final envelope = _nestedMap(event.data['envelope']);
        final circleId = _stringValue(envelope['circle_id']);
        if (circleId != null) {
          ref.invalidate(circleConversationProvider(circleId));
        }
        break;
      case 'message.delivered':
        final messageId = event.stringValue('message_id');
        if (messageId != null) {
          unawaited(_applyDeliveryReceipt(messageId));
        }
        break;
      case 'message.read':
        final circleId = event.stringValue('circle_id');
        if (circleId != null) {
          ref.invalidate(circleConversationProvider(circleId));
        }
        break;
      case 'typing.updated':
        final circleId = event.stringValue('circle_id');
        final userId = event.intValue('user_id');
        if (circleId != null && userId != null) {
          final seconds = event.intValue('expires_in_seconds') ?? 5;
          ref
              .read(realtimeTypingProvider.notifier)
              .update(
                circleId: circleId,
                userId: userId,
                isTyping: event.data['is_typing'] == true,
                expiresIn: Duration(
                  seconds: seconds < 1 ? 1 : (seconds > 30 ? 30 : seconds),
                ),
                currentUserId: auth!.user!.id,
              );
        }
        break;
      case 'presence.updated':
        final circleId = event.stringValue('circle_id');
        if (circleId != null) {
          ref.invalidate(homeCirclePresenceProvider(circleId));
        }
        if (event.intValue('user_id') == auth!.user!.id) {
          ref.invalidate(presenceControllerProvider);
        }
        break;
      case 'ping.received':
      case 'ping.responded':
        unawaited(
          _runRealtimeTask(
            'Realtime Ping refresh failed',
            () => ref.read(pingControllerProvider.notifier).refresh(),
          ),
        );
        break;
      case 'moment.published':
        final moment = _nestedMap(event.data['moment']);
        final circleId = _stringValue(moment['circle_id']);
        if (circleId != null) {
          ref.invalidate(circleMomentsProvider(circleId));
        }
        ref.invalidate(recentMomentsProvider);
        break;
      case 'moment.deleted':
        final circleId = event.stringValue('circle_id');
        if (circleId != null) {
          ref.invalidate(circleMomentsProvider(circleId));
        }
        ref.invalidate(recentMomentsProvider);
        break;
      case 'moment.viewed':
        final momentId = event.stringValue('moment_id');
        if (momentId != null) {
          ref.invalidate(momentViewersProvider(momentId));
        }
        break;
      case 'activity.created':
      case 'activity.removed':
        unawaited(
          _runRealtimeTask(
            'Realtime activity refresh failed',
            () => ref.read(activityControllerProvider.notifier).refresh(),
          ),
        );
        ref.invalidate(circlesProvider);
        ref.invalidate(homeCirclesProvider);
        break;
      case 'notification.created':
        // Realtime is only a wake-up signal. The durable inbox remains the
        // source of truth, preventing duplicate realtime/push/inbox cards.
        unawaited(
          _runRealtimeTask(
            'Realtime notification refresh failed',
            () => ref.read(notificationsControllerProvider.notifier).refresh(),
          ),
        );
        break;
      case 'sos.activated':
      case 'sos.location.updated':
      case 'sos.responder.engaged':
      case 'sos.escalated':
      case 'sos.resolved':
        final sosId = event.stringValue('sos_id');
        if (sosId != null) {
          ref.invalidate(sosIncidentProvider(sosId));
        }
        break;
      default:
        break;
    }
  }

  Future<void> _applyDeliveryReceipt(String messageId) async {
    try {
      await ref.read(messagingServiceProvider).applyDeliveryReceipt(messageId);
      final activeCircle = ref.read(realtimeActiveConversationProvider);
      if (activeCircle != null) {
        ref.invalidate(circleConversationProvider(activeCircle));
      }
    } on Object {
      _logger.debug('Realtime delivery receipt could not be applied');
    }
  }

  Future<void> _runRealtimeTask(
    String failureMessage,
    Future<void> Function() task,
  ) async {
    try {
      await task();
    } on Object {
      _logger.debug(failureMessage);
    }
  }

  Map<String, Object?> _nestedMap(Object? value) {
    if (value is! Map) {
      return const <String, Object?>{};
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  String? _stringValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num) {
      return value.toString();
    }
    return null;
  }
}
