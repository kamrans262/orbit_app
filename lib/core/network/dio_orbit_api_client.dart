import 'package:dio/dio.dart';

import '../config/app_environment.dart';
import '../logging/orbit_logger.dart';
import '../security/session_store.dart';
import 'orbit_api_client.dart';
import 'orbit_api_exception.dart';
import 'session_refresh_coordinator.dart';

class DioOrbitApiClient implements OrbitApiClient {
  DioOrbitApiClient({
    required AppEnvironment environment,
    required SessionStore sessionStore,
    required OrbitLogger logger,
  }) : this._(environment, sessionStore, logger);

  DioOrbitApiClient._(
    AppEnvironment environment,
    this._sessionStore,
    this._logger,
  ) : _dio = Dio(_options(environment.apiBaseUrl)),
      _refreshDio = Dio(_options(environment.apiBaseUrl)) {
    _refreshCoordinator = SessionRefreshCoordinator(
      refreshDio: _refreshDio,
      sessionStore: _sessionStore,
      logger: _logger,
    );
  }

  final SessionStore _sessionStore;
  final OrbitLogger _logger;
  final Dio _dio;
  final Dio _refreshDio;
  late final SessionRefreshCoordinator _refreshCoordinator;

  static BaseOptions _options(String baseUrl) => BaseOptions(
    baseUrl: '$baseUrl/',
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
    headers: const <String, String>{'Accept': 'application/json'},
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
  );

  @override
  Future<Map<String, dynamic>> getDataMap(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    final response = await _request(
      method: 'GET',
      path: path,
      authenticated: authenticated,
      queryParameters: queryParameters,
      bearerToken: bearerToken,
      allowAuthRetry: true,
    );
    return _extractDataMap(response);
  }

  @override
  Future<List<dynamic>> getDataList(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    final response = await _request(
      method: 'GET',
      path: path,
      authenticated: authenticated,
      queryParameters: queryParameters,
      bearerToken: bearerToken,
      allowAuthRetry: true,
    );
    return _extractDataList(response);
  }

  @override
  Future<Map<String, dynamic>> postDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    final response = await _request(
      method: 'POST',
      path: path,
      authenticated: authenticated,
      data: data,
      bearerToken: bearerToken,
      allowAuthRetry: allowAuthRetry,
    );
    return _extractDataMap(response);
  }

  @override
  Future<Map<String, dynamic>> putDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    final response = await _request(
      method: 'PUT',
      path: path,
      authenticated: authenticated,
      data: data,
      bearerToken: bearerToken,
      allowAuthRetry: allowAuthRetry,
    );
    return _extractDataMap(response);
  }

  @override
  Future<Map<String, dynamic>> patchDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    final response = await _request(
      method: 'PATCH',
      path: path,
      authenticated: authenticated,
      data: data,
      bearerToken: bearerToken,
      allowAuthRetry: allowAuthRetry,
    );
    return _extractDataMap(response);
  }

  @override
  Future<void> delete(
    String path, {
    bool authenticated = true,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    await _request(
      method: 'DELETE',
      path: path,
      authenticated: authenticated,
      bearerToken: bearerToken,
      allowAuthRetry: allowAuthRetry,
    );
  }

  @override
  Future<bool> refreshIdentitySession() => _refreshCoordinator.refresh();

  Future<Response<dynamic>> _request({
    required String method,
    required String path,
    required bool authenticated,
    Object? data,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
    required bool allowAuthRetry,
    bool retried = false,
  }) async {
    final effectiveBearer = await _resolveBearerToken(
      authenticated: authenticated,
      bearerToken: bearerToken,
    );

    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: effectiveBearer == null
              ? null
              : <String, String>{'Authorization': 'Bearer $effectiveBearer'},
        ),
      );

      _logger.debug(
        'API response',
        fields: <String, Object?>{
          'method': method,
          'path': Uri.parse(path).path,
          'status': response.statusCode,
          'request_id': _requestId(response),
        },
      );
      return response;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      _logger.error(
        'API request failed',
        fields: <String, Object?>{
          'method': method,
          'path': Uri.parse(path).path,
          'status': status,
          'request_id': _requestId(error.response),
        },
      );

      final mayRetry =
          authenticated &&
          bearerToken == null &&
          !retried &&
          status == 401 &&
          (allowAuthRetry ||
              const <String>{'GET', 'HEAD', 'OPTIONS'}.contains(method));

      if (mayRetry && await _refreshCoordinator.refresh()) {
        return _request(
          method: method,
          path: path,
          authenticated: authenticated,
          data: data,
          queryParameters: queryParameters,
          bearerToken: bearerToken,
          allowAuthRetry: allowAuthRetry,
          retried: true,
        );
      }

      throw OrbitApiException.fromPayload(
        statusCode: status,
        payload: error.response?.data,
        requestId: _requestId(error.response),
      );
    }
  }

  Future<String?> _resolveBearerToken({
    required bool authenticated,
    String? bearerToken,
  }) async {
    if (bearerToken != null && bearerToken.isNotEmpty) {
      return bearerToken;
    }
    if (!authenticated) {
      return null;
    }

    var session = await _sessionStore.read();
    if (session == null) {
      return null;
    }

    if (session.shouldRefresh()) {
      await _refreshCoordinator.refresh();
      session = await _sessionStore.read();
    }

    return session?.accessToken;
  }

  Map<String, dynamic> _extractDataMap(Response<dynamic> response) {
    final payload = _stringMap(response.data);
    if (payload == null) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected response.',
      );
    }

    final data = payload['data'];
    if (data == null) {
      return <String, dynamic>{};
    }
    final map = _stringMap(data);
    if (map == null) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected response.',
      );
    }
    return Map<String, dynamic>.from(map);
  }

  List<dynamic> _extractDataList(Response<dynamic> response) {
    final payload = _stringMap(response.data);
    if (payload == null || payload['data'] is! List) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected response.',
      );
    }
    return List<dynamic>.from(payload['data']! as List);
  }

  Map<String, Object?>? _stringMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  String? _requestId(Response<dynamic>? response) {
    final values = response?.headers.map['x-request-id'];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }

  @override
  void close() {
    _dio.close(force: true);
    _refreshDio.close(force: true);
  }
}
