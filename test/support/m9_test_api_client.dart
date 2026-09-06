import 'package:orbit_app/core/network/orbit_api_client.dart';
import 'package:orbit_app/core/network/orbit_api_exception.dart';

class M9ApiCall {
  const M9ApiCall({
    required this.method,
    required this.path,
    this.data,
    this.queryParameters,
    this.allowAuthRetry = false,
  });

  final String method;
  final String path;
  final Object? data;
  final Map<String, Object?>? queryParameters;
  final bool allowAuthRetry;
}

class M9TestApiClient implements OrbitApiClient {
  final Map<String, List<Object>> getMapResponses = <String, List<Object>>{};
  final Map<String, List<Object>> getListResponses = <String, List<Object>>{};
  final Map<String, List<Object>> postResponses = <String, List<Object>>{};
  final Map<String, List<Object>> putResponses = <String, List<Object>>{};
  final Map<String, List<Object>> patchResponses = <String, List<Object>>{};
  final Map<String, List<Object>> deleteResponses = <String, List<Object>>{};
  final List<M9ApiCall> calls = <M9ApiCall>[];

  Object _next(Map<String, List<Object>> source, String path) {
    final queue = source[path];
    if (queue == null || queue.isEmpty) {
      throw StateError('No M9 fake response queued for $path');
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
    calls.add(
      M9ApiCall(method: 'GET', path: path, queryParameters: queryParameters),
    );
    return Map<String, dynamic>.from(_next(getMapResponses, path) as Map);
  }

  @override
  Future<List<dynamic>> getDataList(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    calls.add(
      M9ApiCall(method: 'GET', path: path, queryParameters: queryParameters),
    );
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
    calls.add(
      M9ApiCall(
        method: 'POST',
        path: path,
        data: data,
        allowAuthRetry: allowAuthRetry,
      ),
    );
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
    calls.add(
      M9ApiCall(
        method: 'PUT',
        path: path,
        data: data,
        allowAuthRetry: allowAuthRetry,
      ),
    );
    return Map<String, dynamic>.from(_next(putResponses, path) as Map);
  }

  @override
  Future<Map<String, dynamic>> patchDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    calls.add(
      M9ApiCall(
        method: 'PATCH',
        path: path,
        data: data,
        allowAuthRetry: allowAuthRetry,
      ),
    );
    return Map<String, dynamic>.from(_next(patchResponses, path) as Map);
  }

  @override
  Future<void> delete(
    String path, {
    bool authenticated = true,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    calls.add(
      M9ApiCall(method: 'DELETE', path: path, allowAuthRetry: allowAuthRetry),
    );
    final queue = deleteResponses[path];
    if (queue == null || queue.isEmpty) {
      return;
    }
    _next(deleteResponses, path);
  }

  @override
  Future<bool> refreshIdentitySession() async => false;

  @override
  void close() {}
}
