import 'package:orbit_app/core/location/current_location_reader.dart';
import 'package:orbit_app/core/network/orbit_api_client.dart';
import 'package:orbit_app/core/security/auth_session.dart';
import 'package:orbit_app/core/security/session_store.dart';

class M3ApiCall {
  const M3ApiCall({required this.method, required this.path, this.data});

  final String method;
  final String path;
  final Object? data;
}

class M3FakeApiClient implements OrbitApiClient {
  final Map<String, Map<String, dynamic>> getMaps =
      <String, Map<String, dynamic>>{};
  final Map<String, List<dynamic>> getLists = <String, List<dynamic>>{};
  final Map<String, Map<String, dynamic>> postMaps =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> putMaps =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> patchMaps =
      <String, Map<String, dynamic>>{};
  final List<M3ApiCall> calls = <M3ApiCall>[];

  @override
  Future<Map<String, dynamic>> getDataMap(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    calls.add(M3ApiCall(method: 'GET', path: path));
    return Map<String, dynamic>.from(_mapFor(getMaps, path));
  }

  @override
  Future<List<dynamic>> getDataList(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    calls.add(M3ApiCall(method: 'GET', path: path));
    final value = getLists[path];
    if (value == null) {
      throw StateError('No fake list response for $path');
    }
    return List<dynamic>.from(value);
  }

  @override
  Future<Map<String, dynamic>> postDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    calls.add(M3ApiCall(method: 'POST', path: path, data: data));
    return Map<String, dynamic>.from(_mapFor(postMaps, path));
  }

  @override
  Future<Map<String, dynamic>> putDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    calls.add(M3ApiCall(method: 'PUT', path: path, data: data));
    return Map<String, dynamic>.from(_mapFor(putMaps, path));
  }

  @override
  Future<Map<String, dynamic>> patchDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    calls.add(M3ApiCall(method: 'PATCH', path: path, data: data));
    return Map<String, dynamic>.from(_mapFor(patchMaps, path));
  }

  @override
  Future<void> delete(
    String path, {
    bool authenticated = true,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    calls.add(M3ApiCall(method: 'DELETE', path: path));
  }

  @override
  Future<bool> refreshIdentitySession() async => true;

  @override
  void close() {}

  static Map<String, dynamic> _mapFor(
    Map<String, Map<String, dynamic>> source,
    String path,
  ) {
    final value = source[path];
    if (value == null) {
      throw StateError('No fake map response for $path');
    }
    return value;
  }
}

class M3MemorySessionStore implements SessionStore {
  M3MemorySessionStore(this.value);

  AuthSession? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<AuthSession?> read() async => value;

  @override
  Future<void> write(AuthSession session) async => value = session;
}

class M3FixedLocationReader implements CurrentLocationReader {
  const M3FixedLocationReader({
    this.latitude = 31.5204567,
    this.longitude = 74.3587123,
    this.accuracyMeters = 7.4,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  @override
  Future<CurrentLocation> read() async {
    return CurrentLocation(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
    );
  }
}
