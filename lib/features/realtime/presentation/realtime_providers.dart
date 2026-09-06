import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/reverb_realtime_client.dart';
import '../domain/realtime_environment.dart';

final realtimeEnvironmentProvider = Provider<RealtimeEnvironment>((ref) {
  return RealtimeEnvironment.fromDartDefines(ref.watch(appEnvironmentProvider));
});

final reverbRealtimeClientProvider = Provider<ReverbRealtimeClient>((ref) {
  final client = ReverbRealtimeClient(
    environment: ref.watch(realtimeEnvironmentProvider),
    authClient: ref.watch(orbitBroadcastAuthClientProvider),
    logger: ref.watch(orbitLoggerProvider),
  );
  ref.onDispose(() => unawaited(client.dispose()));
  return client;
});

final realtimeActiveConversationProvider =
    NotifierProvider<RealtimeActiveConversationController, String?>(
      RealtimeActiveConversationController.new,
    );

class RealtimeActiveConversationController extends Notifier<String?> {
  @override
  String? build() => null;

  void setActive(String circleId) {
    state = circleId;
  }

  void clear(String circleId) {
    if (state == circleId) {
      state = null;
    }
  }
}

final realtimeTypingProvider =
    NotifierProvider<RealtimeTypingController, Map<String, Set<int>>>(
      RealtimeTypingController.new,
    );

class RealtimeTypingController extends Notifier<Map<String, Set<int>>> {
  final Map<String, Timer> _timers = <String, Timer>{};

  @override
  Map<String, Set<int>> build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return const <String, Set<int>>{};
  }

  void update({
    required String circleId,
    required int userId,
    required bool isTyping,
    required Duration expiresIn,
    int? currentUserId,
  }) {
    if (currentUserId == userId) {
      return;
    }
    final key = '$circleId:$userId';
    _timers.remove(key)?.cancel();

    final next = <String, Set<int>>{
      for (final entry in state.entries) entry.key: Set<int>.of(entry.value),
    };
    final users = next.putIfAbsent(circleId, () => <int>{});
    if (isTyping) {
      users.add(userId);
      _timers[key] = Timer(expiresIn, () => _remove(circleId, userId));
    } else {
      users.remove(userId);
      if (users.isEmpty) {
        next.remove(circleId);
      }
    }
    state = Map<String, Set<int>>.unmodifiable(
      next.map((key, value) => MapEntry(key, Set<int>.unmodifiable(value))),
    );
  }

  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    state = const <String, Set<int>>{};
  }

  void _remove(String circleId, int userId) {
    _timers.remove('$circleId:$userId')?.cancel();
    final next = <String, Set<int>>{
      for (final entry in state.entries) entry.key: Set<int>.of(entry.value),
    };
    final users = next[circleId];
    if (users == null) {
      return;
    }
    users.remove(userId);
    if (users.isEmpty) {
      next.remove(circleId);
    }
    state = Map<String, Set<int>>.unmodifiable(
      next.map((key, value) => MapEntry(key, Set<int>.unmodifiable(value))),
    );
  }
}
