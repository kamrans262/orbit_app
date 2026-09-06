import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/network/orbit_api_client.dart';
import 'package:orbit_app/features/sos/data/sos_repository.dart';
import 'package:orbit_app/features/sos/domain/sos_models.dart';

void main() {
  test(
    'uses the canonical idempotent SOS activation and response contracts',
    () async {
      final client = _SosApiFake();
      final repository = HttpSosRepository(apiClient: client);

      await repository.activate(
        const SosActivationInput(id: 'sos id', circleId: 'circle-1'),
      );
      expect(client.lastMethod, 'POST');
      expect(client.lastPath, 'v1/sos/activate');
      expect(client.lastAllowAuthRetry, isTrue);
      expect(client.lastData, <String, Object?>{
        'id': 'sos id',
        'circle_id': 'circle-1',
      });

      await repository.respond(
        sosId: 'sos id',
        status: SosResponderStatus.engaged,
      );
      expect(client.lastPath, 'v1/sos/sos%20id/respond');
      expect(client.lastAllowAuthRetry, isTrue);
      expect(client.lastData, <String, Object?>{'status': 'engaged'});

      await repository.resolve(
        sosId: 'sos id',
        reason: SosResolutionReason.helpArrived,
      );
      expect(client.lastPath, 'v1/sos/sos%20id/resolve');
      expect(client.lastAllowAuthRetry, isTrue);
      expect(client.lastData, <String, Object?>{'reason': 'help_arrived'});
    },
  );

  test(
    'publishes location with replay-safe PUT and does not auto-retry recording attachment',
    () async {
      final client = _SosApiFake();
      final repository = HttpSosRepository(apiClient: client);

      await repository.updateLocation(
        sosId: 'sos-1',
        latitude: 31.5,
        longitude: 74.3,
        accuracyMeters: 6,
      );
      expect(client.lastMethod, 'PUT');
      expect(client.lastPath, 'v1/sos/sos-1/location');
      expect(client.lastAllowAuthRetry, isTrue);

      await repository.attachRecording(
        sosId: 'sos-1',
        recordingRef: 'media:sos:opaque',
      );
      expect(client.lastPath, 'v1/sos/sos-1/recording');
      expect(client.lastAllowAuthRetry, isFalse);
    },
  );
}

class _SosApiFake implements OrbitApiClient {
  String? lastMethod;
  String? lastPath;
  Object? lastData;
  bool? lastAllowAuthRetry;

  static Map<String, dynamic> get _incident => <String, dynamic>{
    'id': 'sos-1',
    'circle_id': 'circle-1',
    'originator_user_id': 7,
    'status': 'active',
    'escalation_stage': 0,
    'activated_at': '2026-09-06T12:00:00Z',
    'resolved_at': null,
    'resolution_reason': null,
    'recording_ref': null,
    'recording_expires_at': null,
    'originator_location': null,
    'responders': <Object?>[],
  };

  @override
  Future<Map<String, dynamic>> getDataMap(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    return _incident;
  }

  @override
  Future<Map<String, dynamic>> postDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastData = data;
    lastAllowAuthRetry = allowAuthRetry;
    return _incident;
  }

  @override
  Future<Map<String, dynamic>> putDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    lastMethod = 'PUT';
    lastPath = path;
    lastData = data;
    lastAllowAuthRetry = allowAuthRetry;
    if (path.endsWith('/location')) {
      return <String, dynamic>{'accepted': true};
    }
    return _incident;
  }

  @override
  Future<List<dynamic>> getDataList(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> patchDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) => throw UnimplementedError();

  @override
  Future<void> delete(
    String path, {
    bool authenticated = true,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) => throw UnimplementedError();

  @override
  Future<bool> refreshIdentitySession() async => false;

  @override
  void close() {}
}
