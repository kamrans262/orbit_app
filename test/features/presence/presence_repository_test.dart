import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/location/current_location_reader.dart';
import 'package:orbit_app/core/network/orbit_api_exception.dart';
import 'package:orbit_app/core/security/auth_session.dart';
import 'package:orbit_app/features/presence/data/presence_repository.dart';
import 'package:orbit_app/features/presence/domain/presence_snapshot.dart';

import '../../support/m3_test_fakes.dart';

void main() {
  test('owner presence parses server-side Ghost Mode without coordinates', () {
    final snapshot = PresenceSnapshot.fromJson(<String, Object?>{
      'status': 'ghost',
      'global_ghost_mode': true,
      'device_id': null,
      'location': <String, Object?>{
        'mode': 'ghost',
        'latitude': null,
        'longitude': null,
        'accuracy_meters': null,
        'updated_at': null,
      },
      'battery': <String, Object?>{'level': null, 'is_charging': null},
      'network_type': null,
      'movement_type': null,
      'last_seen_at': null,
    });

    expect(snapshot.status, PresenceStatus.ghost);
    expect(snapshot.globalGhostMode, isTrue);
    expect(snapshot.locationMode, PresenceLocationMode.ghost);
    expect(snapshot.hasCoordinates, isFalse);
  });

  test(
    'sharing current location binds the update to the hardened device',
    () async {
      final now = DateTime.utc(2026, 9, 6, 12);
      final api = M3FakeApiClient();
      final sessionStore = M3MemorySessionStore(
        AuthSession(
          accessToken: 'access',
          accessExpiresAt: now.add(const Duration(minutes: 15)),
          refreshToken: 'refresh',
          refreshExpiresAt: now.add(const Duration(days: 60)),
          sessionId: 'session-1',
          deviceId: 'device-1',
        ),
      );

      api.getMaps['v1/presence/me'] = _presence(globalGhostMode: false);
      api.putMaps['v1/presence'] = _presence(
        globalGhostMode: false,
        latitude: 31.5204567,
        longitude: 74.3587123,
      );

      final repository = HttpPresenceRepository(
        apiClient: api,
        sessionStore: sessionStore,
        locationReader: const M3FixedLocationReader(),
      );

      final result = await repository.shareCurrentLocation();

      expect(result.hasCoordinates, isTrue);
      expect(api.calls.map((call) => '${call.method} ${call.path}'), <String>[
        'GET v1/presence/me',
        'PUT v1/presence',
      ]);

      final payload = api.calls.last.data! as Map<String, Object?>;
      expect(payload['device_id'], 'device-1');
      expect(payload['status'], 'online');
      expect(payload['latitude'], 31.5204567);
      expect(payload['longitude'], 74.3587123);
    },
  );

  test(
    'Global Ghost Mode blocks location access before reading the device location',
    () async {
      final now = DateTime.utc(2026, 9, 6, 12);
      final api = M3FakeApiClient();
      final sessionStore = M3MemorySessionStore(
        AuthSession(
          accessToken: 'access',
          accessExpiresAt: now.add(const Duration(minutes: 15)),
          refreshToken: 'refresh',
          refreshExpiresAt: now.add(const Duration(days: 60)),
          sessionId: 'session-1',
          deviceId: 'device-1',
        ),
      );

      api.getMaps['v1/presence/me'] = _presence(globalGhostMode: true);

      final repository = HttpPresenceRepository(
        apiClient: api,
        sessionStore: sessionStore,
        locationReader: const _FailIfReadLocationReader(),
      );

      await expectLater(
        repository.shareCurrentLocation(),
        throwsA(
          isA<OrbitApiException>().having(
            (error) => error.code,
            'code',
            'GLOBAL_GHOST_MODE_ENABLED',
          ),
        ),
      );

      expect(api.calls.map((call) => '${call.method} ${call.path}'), <String>[
        'GET v1/presence/me',
      ]);
    },
  );

  test(
    'Global Ghost Mode uses the existing presence settings contract',
    () async {
      final api = M3FakeApiClient();
      api.patchMaps['v1/presence/settings'] = _presence(globalGhostMode: true);

      final repository = HttpPresenceRepository(
        apiClient: api,
        sessionStore: M3MemorySessionStore(null),
        locationReader: const M3FixedLocationReader(),
      );

      final result = await repository.setGlobalGhostMode(true);

      expect(result.globalGhostMode, isTrue);
      expect(api.calls.single.path, 'v1/presence/settings');
      expect(api.calls.single.data, <String, Object?>{
        'global_ghost_mode': true,
      });
    },
  );

  test(
    'Circle privacy updates use the existing member privacy contract',
    () async {
      final api = M3FakeApiClient();
      api.patchMaps['v1/circles/circle-1/members/member-1'] = <String, dynamic>{
        'membership_id': 'member-1',
        'location_mode': 'approximate',
        'can_ping': false,
      };

      final repository = HttpPresenceRepository(
        apiClient: api,
        sessionStore: M3MemorySessionStore(null),
        locationReader: const M3FixedLocationReader(),
      );

      final result = await repository.updateCirclePrivacy(
        current: const CirclePrivacySetting(
          circleId: 'circle-1',
          circleName: 'Family',
          membershipId: 'member-1',
          locationMode: PresenceLocationMode.precise,
          canPing: true,
        ),
        locationMode: PresenceLocationMode.approximate,
        canPing: false,
      );

      expect(result.locationMode, PresenceLocationMode.approximate);
      expect(result.canPing, isFalse);
      expect(api.calls.single.path, 'v1/circles/circle-1/members/member-1');
    },
  );
}

Map<String, dynamic> _presence({
  required bool globalGhostMode,
  double? latitude,
  double? longitude,
}) {
  return <String, dynamic>{
    'status': globalGhostMode ? 'ghost' : 'online',
    'global_ghost_mode': globalGhostMode,
    'device_id': globalGhostMode ? null : 'device-1',
    'location': <String, Object?>{
      'mode': globalGhostMode ? 'ghost' : 'precise',
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': latitude == null ? null : 7.4,
      'updated_at': latitude == null ? null : '2026-09-06T12:00:00Z',
    },
    'battery': <String, Object?>{'level': null, 'is_charging': null},
    'network_type': null,
    'movement_type': null,
    'last_seen_at': '2026-09-06T12:00:00Z',
  };
}

class _FailIfReadLocationReader implements CurrentLocationReader {
  const _FailIfReadLocationReader();

  @override
  Future<CurrentLocation> read() {
    throw StateError(
      'Location must not be read while Global Ghost Mode is enabled.',
    );
  }
}
