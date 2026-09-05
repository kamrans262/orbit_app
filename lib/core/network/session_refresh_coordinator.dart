import 'package:dio/dio.dart';

import '../logging/orbit_logger.dart';
import '../security/auth_session.dart';
import '../security/session_store.dart';

class SessionRefreshCoordinator {
  SessionRefreshCoordinator({
    required Dio refreshDio,
    required SessionStore sessionStore,
    required OrbitLogger logger,
  }) : this._(refreshDio, sessionStore, logger);

  SessionRefreshCoordinator._(
    this._refreshDio,
    this._sessionStore,
    this._logger,
  );

  final Dio _refreshDio;
  final SessionStore _sessionStore;
  final OrbitLogger _logger;

  Future<bool>? _activeRefresh;

  Future<bool> refresh() {
    final inFlight = _activeRefresh;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _performRefresh();
    _activeRefresh = future;
    return future.whenComplete(() {
      if (identical(_activeRefresh, future)) {
        _activeRefresh = null;
      }
    });
  }

  Future<bool> _performRefresh() async {
    final current = await _sessionStore.read();
    if (current == null || current.refreshExpired()) {
      if (current != null) {
        await _sessionStore.clear();
      }
      return false;
    }

    try {
      final response = await _refreshDio.post<dynamic>(
        'v1/auth/refresh',
        data: <String, Object?>{
          'refresh_token': current.refreshToken,
          'device_id': current.deviceId,
        },
        options: Options(
          headers: const <String, String>{'Accept': 'application/json'},
        ),
      );

      final payload = response.data;
      if (payload is! Map) {
        _logger.error('Identity refresh returned an invalid response shape.');
        return false;
      }

      final rawData = payload['data'];
      if (rawData is! Map) {
        _logger.error('Identity refresh returned an invalid data shape.');
        return false;
      }

      final data = rawData.map((key, value) => MapEntry(key.toString(), value));
      final next = AuthSession.fromIdentityPair(
        data,
        deviceId: current.deviceId,
      );
      await _sessionStore.write(next);
      _logger.debug('Identity session refreshed.');
      return true;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      _logger.error(
        'Identity session refresh failed.',
        fields: <String, Object?>{'status': status},
      );
      if (status == 401 || status == 403) {
        await _sessionStore.clear();
      }
      return false;
    } on FormatException {
      _logger.error('Identity refresh contained invalid expiry data.');
      return false;
    } on TypeError {
      _logger.error('Identity refresh contained invalid token data.');
      return false;
    }
  }
}
