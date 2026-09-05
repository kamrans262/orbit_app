import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/current_location_reader.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../data/presence_repository.dart';
import '../domain/presence_snapshot.dart';

final currentLocationReaderProvider = Provider<CurrentLocationReader>((ref) {
  return const LocationCurrentLocationReader();
});

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  return HttpPresenceRepository(
    apiClient: ref.watch(orbitApiClientProvider),
    sessionStore: ref.watch(sessionStoreProvider),
    locationReader: ref.watch(currentLocationReaderProvider),
  );
});

final presenceControllerProvider =
    AsyncNotifierProvider<PresenceController, PresenceViewState>(
      PresenceController.new,
    );

class PresenceViewState {
  const PresenceViewState({
    required this.presence,
    required this.circleSettings,
    this.isBusy = false,
    this.errorMessage,
  });

  final PresenceSnapshot presence;
  final List<CirclePrivacySetting> circleSettings;
  final bool isBusy;
  final String? errorMessage;

  PresenceViewState copyWith({
    PresenceSnapshot? presence,
    List<CirclePrivacySetting>? circleSettings,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PresenceViewState(
      presence: presence ?? this.presence,
      circleSettings: circleSettings ?? this.circleSettings,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PresenceController extends AsyncNotifier<PresenceViewState> {
  PresenceRepository get _repository => ref.read(presenceRepositoryProvider);

  @override
  Future<PresenceViewState> build() async {
    final results = await Future.wait<Object>(<Future<Object>>[
      _repository.getMyPresence(),
      _repository.listCirclePrivacy(),
    ]);

    return PresenceViewState(
      presence: results[0] as PresenceSnapshot,
      circleSettings: results[1] as List<CirclePrivacySetting>,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<PresenceViewState>();
    state = await AsyncValue.guard(build);
  }

  Future<void> shareCurrentLocation() async {
    final current = _current;
    if (current == null || current.isBusy) {
      return;
    }

    state = AsyncData<PresenceViewState>(
      current.copyWith(isBusy: true, clearError: true),
    );

    try {
      final presence = await _repository.shareCurrentLocation();
      state = AsyncData<PresenceViewState>(
        current.copyWith(presence: presence, isBusy: false, clearError: true),
      );
    } on LocationAccessException catch (error) {
      state = AsyncData<PresenceViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
    } on OrbitApiException catch (error) {
      state = AsyncData<PresenceViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
    } on Object {
      state = AsyncData<PresenceViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Orbit could not update your presence. Try again.',
        ),
      );
    }
  }

  Future<void> setGlobalGhostMode(bool enabled) async {
    final current = _current;
    if (current == null || current.isBusy) {
      return;
    }

    state = AsyncData<PresenceViewState>(
      current.copyWith(isBusy: true, clearError: true),
    );

    try {
      final presence = await _repository.setGlobalGhostMode(enabled);
      state = AsyncData<PresenceViewState>(
        current.copyWith(presence: presence, isBusy: false, clearError: true),
      );
    } on OrbitApiException catch (error) {
      state = AsyncData<PresenceViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
    } on Object {
      state = AsyncData<PresenceViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Orbit could not change Global Ghost Mode.',
        ),
      );
    }
  }

  Future<void> updateCircleLocationMode(
    CirclePrivacySetting setting,
    PresenceLocationMode mode,
  ) async {
    await _updateCircle(setting, locationMode: mode);
  }

  Future<void> updateCirclePingPermission(
    CirclePrivacySetting setting,
    bool canPing,
  ) async {
    await _updateCircle(setting, canPing: canPing);
  }

  Future<void> _updateCircle(
    CirclePrivacySetting setting, {
    PresenceLocationMode? locationMode,
    bool? canPing,
  }) async {
    final current = _current;
    if (current == null || current.isBusy) {
      return;
    }

    state = AsyncData<PresenceViewState>(
      current.copyWith(isBusy: true, clearError: true),
    );

    try {
      final updated = await _repository.updateCirclePrivacy(
        current: setting,
        locationMode: locationMode,
        canPing: canPing,
      );
      final settings = current.circleSettings
          .map(
            (item) =>
                item.membershipId == updated.membershipId ? updated : item,
          )
          .toList(growable: false);

      state = AsyncData<PresenceViewState>(
        current.copyWith(
          circleSettings: settings,
          isBusy: false,
          clearError: true,
        ),
      );
    } on OrbitApiException catch (error) {
      state = AsyncData<PresenceViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
    } on Object {
      state = AsyncData<PresenceViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Orbit could not update this Circle privacy setting.',
        ),
      );
    }
  }

  PresenceViewState? get _current {
    return state.when(
      data: (value) => value,
      error: (_, _) => null,
      loading: () => null,
    );
  }
}
