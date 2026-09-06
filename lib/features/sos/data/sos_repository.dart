import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../domain/sos_models.dart';

abstract interface class SosRepository {
  Future<SosIncident> activate(SosActivationInput input);

  Future<SosIncident> getIncident(String sosId);

  Future<SosIncident> respond({
    required String sosId,
    required SosResponderStatus status,
  });

  Future<void> updateLocation({
    required String sosId,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
  });

  Future<SosIncident> resolve({
    required String sosId,
    SosResolutionReason? reason,
  });

  Future<SosIncident> attachRecording({
    required String sosId,
    required String recordingRef,
  });
}

class HttpSosRepository implements SosRepository {
  const HttpSosRepository({required OrbitApiClient apiClient})
    : _api = apiClient;

  final OrbitApiClient _api;

  @override
  Future<SosIncident> activate(SosActivationInput input) async {
    final data = await _api.postDataMap(
      'v1/sos/activate',
      data: input.toApiPayload(),
      // Activation is explicitly idempotent because the client supplies the
      // SOS UUID. Replaying the exact same ID is safe after auth refresh.
      allowAuthRetry: true,
    );
    return _parseIncident(data);
  }

  @override
  Future<SosIncident> getIncident(String sosId) async {
    final data = await _api.getDataMap('v1/sos/${Uri.encodeComponent(sosId)}');
    return _parseIncident(data);
  }

  @override
  Future<SosIncident> respond({
    required String sosId,
    required SosResponderStatus status,
  }) async {
    final data = await _api.postDataMap(
      'v1/sos/${Uri.encodeComponent(sosId)}/respond',
      data: <String, Object?>{'status': status.apiValue},
      // Laravel's responder transition is idempotent and suppresses duplicate
      // engaged events on identical retries.
      allowAuthRetry: true,
    );
    return _parseIncident(data);
  }

  @override
  Future<void> updateLocation({
    required String sosId,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
  }) async {
    await _api.putDataMap(
      'v1/sos/${Uri.encodeComponent(sosId)}/location',
      data: <String, Object?>{
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_m': ?accuracyMeters,
      },
      // A location update replaces the current sample, so replay is safe.
      allowAuthRetry: true,
    );
  }

  @override
  Future<SosIncident> resolve({
    required String sosId,
    SosResolutionReason? reason,
  }) async {
    final data = await _api.postDataMap(
      'v1/sos/${Uri.encodeComponent(sosId)}/resolve',
      data: <String, Object?>{'reason': ?reason?.apiValue},
      // Laravel resolution is idempotent.
      allowAuthRetry: true,
    );
    return _parseIncident(data);
  }

  @override
  Future<SosIncident> attachRecording({
    required String sosId,
    required String recordingRef,
  }) async {
    final data = await _api.putDataMap(
      'v1/sos/${Uri.encodeComponent(sosId)}/recording',
      data: <String, Object?>{'recording_ref': recordingRef},
      // Do not auto-replay sensitive recording attachment without a dedicated
      // backend idempotency contract.
      allowAuthRetry: false,
    );
    return _parseIncident(data);
  }

  SosIncident _parseIncident(Map<String, dynamic> data) {
    try {
      return SosIncident.fromJson(data.cast<String, Object?>());
    } on FormatException {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected SOS response.',
      );
    }
  }
}
