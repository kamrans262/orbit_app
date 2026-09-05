import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/orbit_api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../data/ping_repository.dart';
import '../domain/ping_item.dart';

final pingRepositoryProvider = Provider<PingRepository>((ref) {
  return HttpPingRepository(apiClient: ref.watch(orbitApiClientProvider));
});

final pingCirclesProvider = FutureProvider<List<PingCircleOption>>((ref) {
  return ref.watch(pingRepositoryProvider).listCircles();
});

final pingTargetsProvider =
    FutureProvider.family<List<PingTarget>, PingCircleOption>((ref, circle) {
      return ref.watch(pingRepositoryProvider).listTargets(circle);
    });

final pingControllerProvider =
    AsyncNotifierProvider<PingController, PingViewState>(PingController.new);

class PingViewState {
  const PingViewState({
    required this.inbox,
    required this.sent,
    this.isBusy = false,
    this.errorMessage,
  });

  final List<PingItem> inbox;
  final List<PingItem> sent;
  final bool isBusy;
  final String? errorMessage;

  PingViewState copyWith({
    List<PingItem>? inbox,
    List<PingItem>? sent,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PingViewState(
      inbox: inbox ?? this.inbox,
      sent: sent ?? this.sent,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PingController extends AsyncNotifier<PingViewState> {
  PingRepository get _repository => ref.read(pingRepositoryProvider);

  @override
  Future<PingViewState> build() async {
    final results = await Future.wait<List<PingItem>>(<Future<List<PingItem>>>[
      _repository.listInbox(),
      _repository.listSent(),
    ]);
    return PingViewState(inbox: results[0], sent: results[1]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<PingViewState>();
    state = await AsyncValue.guard(build);
  }

  Future<bool> send({
    required PingCircleOption circle,
    required PingTarget target,
  }) async {
    final current = _current;
    if (current == null || current.isBusy || !target.canPing) {
      return false;
    }

    state = AsyncData<PingViewState>(
      current.copyWith(isBusy: true, clearError: true),
    );

    try {
      final ping = await _repository.send(
        circleId: circle.id,
        recipientMembershipId: target.membershipId,
      );
      state = AsyncData<PingViewState>(
        current.copyWith(
          sent: <PingItem>[ping, ...current.sent],
          isBusy: false,
          clearError: true,
        ),
      );
      return true;
    } on OrbitApiException catch (error) {
      state = AsyncData<PingViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
      return false;
    } on Object {
      state = AsyncData<PingViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Orbit could not send that Ping. Try again.',
        ),
      );
      return false;
    }
  }

  Future<void> respond(PingItem ping, PingResponseType responseType) async {
    await _completeIncoming(
      ping,
      action: () => _repository.respond(ping.id, responseType),
    );
  }

  Future<void> dismiss(PingItem ping) async {
    await _completeIncoming(ping, action: () => _repository.dismiss(ping.id));
  }

  Future<void> _completeIncoming(
    PingItem ping, {
    required Future<PingItem> Function() action,
  }) async {
    final current = _current;
    if (current == null || current.isBusy) {
      return;
    }

    state = AsyncData<PingViewState>(
      current.copyWith(isBusy: true, clearError: true),
    );

    try {
      await action();
      state = AsyncData<PingViewState>(
        current.copyWith(
          inbox: current.inbox
              .where((item) => item.id != ping.id)
              .toList(growable: false),
          isBusy: false,
          clearError: true,
        ),
      );
    } on OrbitApiException catch (error) {
      state = AsyncData<PingViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
    } on Object {
      state = AsyncData<PingViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Orbit could not update that Ping. Try again.',
        ),
      );
    }
  }

  PingViewState? get _current {
    return state.when(
      data: (value) => value,
      error: (_, _) => null,
      loading: () => null,
    );
  }
}
