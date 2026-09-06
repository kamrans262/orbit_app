import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/device/device_metadata_service.dart';
import 'package:orbit_app/core/network/orbit_api_client.dart';
import 'package:orbit_app/core/security/local_device_id_store.dart';
import 'package:orbit_app/features/messaging/data/messaging_remote_repository.dart';
import 'package:orbit_app/features/messaging/domain/messaging_models.dart';

void main() {
  test(
    'publishes the E2EE public identity through canonical device endpoint',
    () async {
      final api = _FakeApiClient();
      final repository = HttpMessagingRemoteRepository(
        apiClient: api,
        clientDeviceIdStore: _FakeClientDeviceIdStore(),
        deviceMetadataReader: _FakeDeviceMetadataReader(),
      );

      await repository.publishDeviceIdentity(publicIdentityKey: '{"v":1}');

      expect(api.lastPath, 'v1/devices');
      expect(api.lastData?['client_device_id'], 'client-device-id');
      expect(api.lastData?['public_identity_key'], '{"v":1}');
      expect(api.lastAllowAuthRetry, isTrue);
    },
  );

  test('send payload preserves backend message idempotency contract', () async {
    final api = _FakeApiClient();
    final repository = HttpMessagingRemoteRepository(
      apiClient: api,
      clientDeviceIdStore: _FakeClientDeviceIdStore(),
      deviceMetadataReader: _FakeDeviceMetadataReader(),
    );

    await repository.sendEncryptedMessage(
      circleId: 'circle-id',
      messageId: 'message-id',
      senderDeviceId: 'device-id',
      clientSentAt: DateTime.utc(2026, 9, 6, 1, 2, 3),
      envelopes: const <OutboundEnvelope>[
        OutboundEnvelope(
          envelopeId: 'envelope-id',
          recipientDeviceId: 'recipient-device-id',
          ciphertext: 'opaque-ciphertext',
        ),
      ],
    );

    expect(api.lastPath, 'v1/circles/circle-id/messages');
    expect(api.lastData?['message_id'], 'message-id');
    expect(api.lastData?['sender_device_id'], 'device-id');
    expect(api.lastData?['type'], 'text');
    expect(api.lastAllowAuthRetry, isTrue);
    final envelopes = api.lastData?['envelopes']! as List<Object?>;
    final first = envelopes.single as Map<String, Object?>;
    expect(first['ciphertext'], 'opaque-ciphertext');
  });

  test('parses server-filtered recipient device identity bundles', () async {
    final api = _FakeApiClient()
      ..listResponse = <Object?>[
        <String, Object?>{
          'membership_id': 'membership-id',
          'user_id': 7,
          'name': 'Avery',
          'devices': <Object?>[
            <String, Object?>{
              'device_id': 'device-id',
              'platform': 'android',
              'public_identity_key': DevicePublicIdentity(
                keyAgreementPublicKey: List<int>.filled(32, 1),
                signingPublicKey: List<int>.filled(32, 2),
              ).toServerValue(),
              'key_updated_at': '2026-09-06T00:00:00Z',
            },
          ],
        },
      ];
    final repository = HttpMessagingRemoteRepository(
      apiClient: api,
      clientDeviceIdStore: _FakeClientDeviceIdStore(),
      deviceMetadataReader: _FakeDeviceMetadataReader(),
    );

    final devices = await repository.getCircleMessageDevices('circle-id');

    expect(devices, hasLength(1));
    expect(devices.single.userId, 7);
    expect(devices.single.displayName, 'Avery');
    expect(devices.single.deviceId, 'device-id');
  });
}

class _FakeClientDeviceIdStore implements ClientDeviceIdStore {
  @override
  Future<String> getOrCreate() async => 'client-device-id';
}

class _FakeDeviceMetadataReader implements DeviceMetadataReader {
  @override
  Future<DeviceMetadata> read() async => const DeviceMetadata(
    platform: 'android',
    name: 'Test phone',
    appVersion: '1.0.0',
    osVersion: '16',
  );
}

class _FakeApiClient implements OrbitApiClient {
  String? lastPath;
  Map<String, Object?>? lastData;
  bool? lastAllowAuthRetry;
  List<dynamic> listResponse = <dynamic>[];
  Map<String, dynamic> mapResponse = <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> getDataMap(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    lastPath = path;
    return mapResponse;
  }

  @override
  Future<List<dynamic>> getDataList(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    lastPath = path;
    return listResponse;
  }

  @override
  Future<Map<String, dynamic>> postDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    lastPath = path;
    lastData = data is Map<String, Object?> ? data : null;
    lastAllowAuthRetry = allowAuthRetry;
    return mapResponse;
  }

  @override
  Future<Map<String, dynamic>> putDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async => <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> patchDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    lastPath = path;
    lastData = data is Map<String, Object?> ? data : null;
    lastAllowAuthRetry = allowAuthRetry;
    return mapResponse;
  }

  @override
  Future<void> delete(
    String path, {
    bool authenticated = true,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {}

  @override
  Future<bool> refreshIdentitySession() async => true;

  @override
  void close() {}
}
