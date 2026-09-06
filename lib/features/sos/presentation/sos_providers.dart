import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/location/current_location_reader.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/sos_local_state_store.dart';
import '../data/sos_repository.dart';
import '../domain/sos_models.dart';

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  return HttpSosRepository(apiClient: ref.watch(orbitApiClientProvider));
});

final sosLocalStateStoreProvider = Provider<SosLocalStateStore>((ref) {
  return SecureSosLocalStateStore(ref.watch(flutterSecureStorageProvider));
});

final sosLocationReaderProvider = Provider<CurrentLocationReader>((ref) {
  return const LocationCurrentLocationReader();
});

final sosIncidentProvider = FutureProvider.family<SosIncident, String>((
  ref,
  sosId,
) {
  return ref.watch(sosRepositoryProvider).getIncident(sosId);
});

final sosRecoveryProvider = FutureProvider<SosLocalIncident?>((ref) async {
  final auth = ref.watch(authControllerProvider).asData?.value;
  final userId = auth?.user?.id;
  if (userId == null) {
    return null;
  }

  final store = ref.watch(sosLocalStateStoreProvider);
  final local = await store.read();
  if (local == null || local.userId != userId) {
    return null;
  }

  try {
    final incident = await ref
        .watch(sosRepositoryProvider)
        .getIncident(local.sosId);
    if (!incident.isActive) {
      await store.clear();
      return null;
    }
  } on OrbitApiException catch (error) {
    if (error.code == 'sos_event_unavailable' || error.statusCode == 404) {
      await store.clear();
      return null;
    }
    // Preserve the local recovery pointer during a temporary network outage.
  } on Object {
    // Preserve the local recovery pointer during a temporary network outage.
  }

  return local;
});

final sosMutationControllerProvider =
    NotifierProvider<SosMutationController, SosMutationState>(
      SosMutationController.new,
    );

class SosMutationState {
  const SosMutationState({
    this.isBusy = false,
    this.errorMessage,
    this.errorCode,
  });

  final bool isBusy;
  final String? errorMessage;
  final String? errorCode;
}

class SosMutationController extends Notifier<SosMutationState> {
  SosRepository get _repository => ref.read(sosRepositoryProvider);
  SosLocalStateStore get _localStore => ref.read(sosLocalStateStoreProvider);

  @override
  SosMutationState build() => const SosMutationState();

  void clearError() {
    if (state.errorMessage != null || state.errorCode != null) {
      state = const SosMutationState();
    }
  }

  Future<SosIncident?> activate({
    required int userId,
    required String circleId,
    CurrentLocation? location,
  }) async {
    if (state.isBusy) {
      return null;
    }
    state = const SosMutationState(isBusy: true);
    try {
      final pending = await _localStore.readPendingActivation();
      final sosId =
          pending != null &&
              pending.userId == userId &&
              pending.circleId == circleId
          ? pending.sosId
          : const Uuid().v4();
      if (pending == null ||
          pending.userId != userId ||
          pending.circleId != circleId) {
        await _localStore.writePendingActivation(
          SosPendingActivation(
            sosId: sosId,
            circleId: circleId,
            userId: userId,
          ),
        );
      }

      final incident = await _repository.activate(
        SosActivationInput(
          id: sosId,
          circleId: circleId,
          latitude: location?.latitude,
          longitude: location?.longitude,
          locationAccuracyMeters: location?.accuracyMeters,
        ),
      );
      await _localStore.clearPendingActivation();
      await _localStore.write(
        SosLocalIncident(
          sosId: incident.id,
          circleId: incident.circleId,
          userId: userId,
          isOriginator: true,
        ),
      );
      ref.invalidate(sosRecoveryProvider);
      state = const SosMutationState();
      return incident;
    } on OrbitApiException catch (error) {
      if (error.code == 'sos_id_conflict' ||
          error.code == 'sos_circle_unavailable') {
        await _localStore.clearPendingActivation();
      }
      state = SosMutationState(
        errorMessage: error.message,
        errorCode: error.code,
      );
      return null;
    } on Object {
      state = const SosMutationState(
        errorMessage:
            'Orbit could not activate SOS. Check your connection and try again.',
        errorCode: 'SOS_NETWORK_FAILURE',
      );
      return null;
    }
  }

  Future<SosIncident?> respond({
    required int userId,
    required String sosId,
    required SosResponderStatus status,
  }) async {
    if (state.isBusy) {
      return null;
    }
    state = const SosMutationState(isBusy: true);
    try {
      final incident = await _repository.respond(sosId: sosId, status: status);
      if (status == SosResponderStatus.engaged) {
        await _localStore.write(
          SosLocalIncident(
            sosId: incident.id,
            circleId: incident.circleId,
            userId: userId,
            isOriginator: false,
          ),
        );
      } else {
        final local = await _localStore.read();
        if (local?.sosId == sosId && local?.userId == userId) {
          await _localStore.clear();
        }
      }
      ref.invalidate(sosIncidentProvider(sosId));
      ref.invalidate(sosRecoveryProvider);
      state = const SosMutationState();
      return incident;
    } on OrbitApiException catch (error) {
      state = SosMutationState(
        errorMessage: error.message,
        errorCode: error.code,
      );
      return null;
    } on Object {
      state = const SosMutationState(
        errorMessage: 'Orbit could not update your SOS response. Try again.',
      );
      return null;
    }
  }

  Future<SosIncident?> resolve({
    required String sosId,
    required SosResolutionReason reason,
  }) async {
    if (state.isBusy) {
      return null;
    }
    state = const SosMutationState(isBusy: true);
    try {
      final incident = await _repository.resolve(sosId: sosId, reason: reason);
      await _localStore.clear();
      ref.invalidate(sosIncidentProvider(sosId));
      ref.invalidate(sosRecoveryProvider);
      state = const SosMutationState();
      return incident;
    } on OrbitApiException catch (error) {
      state = SosMutationState(
        errorMessage: error.message,
        errorCode: error.code,
      );
      return null;
    } on Object {
      state = const SosMutationState(
        errorMessage: 'Orbit could not resolve this SOS. Try again.',
      );
      return null;
    }
  }
}
