import 'package:orbit_app/core/device/device_metadata_service.dart';
import 'package:orbit_app/core/network/orbit_api_client.dart';
import 'package:orbit_app/core/network/orbit_api_exception.dart';
import 'package:orbit_app/core/security/auth_session.dart';
import 'package:orbit_app/core/security/local_device_id_store.dart';
import 'package:orbit_app/core/security/pending_bootstrap_store.dart';
import 'package:orbit_app/core/security/session_store.dart';
import 'package:orbit_app/features/auth/data/auth_repository.dart';
import 'package:orbit_app/features/auth/domain/auth_results.dart';
import 'package:orbit_app/features/auth/domain/device_approval.dart';
import 'package:orbit_app/features/auth/domain/otp_challenge.dart';

class ApiCall {
  const ApiCall({required this.path, this.data, this.bearerToken});

  final String path;
  final Object? data;
  final String? bearerToken;
}

class QueueOrbitApiClient implements OrbitApiClient {
  final Map<String, List<Object>> postResponses = <String, List<Object>>{};
  final Map<String, List<Object>> getMapResponses = <String, List<Object>>{};
  final Map<String, List<Object>> getListResponses = <String, List<Object>>{};
  final List<ApiCall> calls = <ApiCall>[];

  Object _next(Map<String, List<Object>> source, String path) {
    final queue = source[path];
    if (queue == null || queue.isEmpty) {
      throw StateError('No fake response queued for $path');
    }
    final value = queue.removeAt(0);
    if (value is OrbitApiException) {
      throw value;
    }
    return value;
  }

  @override
  Future<Map<String, dynamic>> getDataMap(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    calls.add(ApiCall(path: path, bearerToken: bearerToken));
    return Map<String, dynamic>.from(_next(getMapResponses, path) as Map);
  }

  @override
  Future<List<dynamic>> getDataList(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    calls.add(ApiCall(path: path, bearerToken: bearerToken));
    return List<dynamic>.from(_next(getListResponses, path) as List);
  }

  @override
  Future<Map<String, dynamic>> postDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    calls.add(ApiCall(path: path, data: data, bearerToken: bearerToken));
    return Map<String, dynamic>.from(_next(postResponses, path) as Map);
  }

  @override
  Future<Map<String, dynamic>> putDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> patchDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    throw UnimplementedError();
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

class MemorySessionStore implements SessionStore {
  AuthSession? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<AuthSession?> read() async => value;

  @override
  Future<void> write(AuthSession session) async => value = session;
}

class MemoryPendingBootstrapStore implements PendingBootstrapStore {
  PendingDeviceBootstrap? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<PendingDeviceBootstrap?> read() async => value;

  @override
  Future<void> write(PendingDeviceBootstrap pending) async => value = pending;
}

class FixedClientDeviceIdStore implements ClientDeviceIdStore {
  const FixedClientDeviceIdStore(this.value);

  final String value;

  @override
  Future<String> getOrCreate() async => value;
}

class FixedDeviceMetadataReader implements DeviceMetadataReader {
  const FixedDeviceMetadataReader();

  @override
  Future<DeviceMetadata> read() async {
    return const DeviceMetadata(
      platform: 'android',
      name: 'Pixel Test',
      appVersion: '1.0.0',
      osVersion: '16',
    );
  }
}

class SignedOutAuthRepository implements AuthRepository {
  @override
  Future<AuthRestoreResult> restore() async {
    return const AuthRestoreResult.signedOut();
  }

  @override
  Future<OtpChallenge> requestEmailOtp(String email) async {
    return OtpChallenge(
      email: email,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<AuthBootstrapResult> verifyEmailOtp({
    required String email,
    required String otp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthBootstrapResult> retryPendingDeviceApproval() {
    throw UnimplementedError();
  }

  @override
  Future<void> clearPendingBootstrap() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<List<DeviceApproval>> listDeviceApprovals() async {
    return const <DeviceApproval>[];
  }

  @override
  Future<void> approveDevice(String deviceId) async {}
}
