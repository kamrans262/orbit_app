import '../../../core/device/device_metadata_service.dart';
import '../../../core/logging/orbit_logger.dart';
import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../../../core/security/auth_session.dart';
import '../../../core/security/local_device_id_store.dart';
import '../../../core/security/pending_bootstrap_store.dart';
import '../../../core/security/session_store.dart';
import '../domain/auth_results.dart';
import '../domain/auth_user.dart';
import '../domain/device_approval.dart';
import '../domain/otp_challenge.dart';

abstract interface class AuthRepository {
  Future<AuthRestoreResult> restore();
  Future<OtpChallenge> requestEmailOtp(String email);
  Future<AuthBootstrapResult> verifyEmailOtp({
    required String email,
    required String otp,
  });
  Future<AuthBootstrapResult> retryPendingDeviceApproval();
  Future<void> clearPendingBootstrap();
  Future<void> signOut();
  Future<List<DeviceApproval>> listDeviceApprovals();
  Future<void> approveDevice(String deviceId);
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({
    required OrbitApiClient apiClient,
    required SessionStore sessionStore,
    required PendingBootstrapStore pendingStore,
    required ClientDeviceIdStore clientDeviceIdStore,
    required DeviceMetadataReader deviceMetadataReader,
    required OrbitLogger logger,
  }) : this._(
         apiClient,
         sessionStore,
         pendingStore,
         clientDeviceIdStore,
         deviceMetadataReader,
         logger,
       );

  HttpAuthRepository._(
    this._api,
    this._sessionStore,
    this._pendingStore,
    this._clientDeviceIdStore,
    this._deviceMetadataReader,
    this._logger,
  );

  final OrbitApiClient _api;
  final SessionStore _sessionStore;
  final PendingBootstrapStore _pendingStore;
  final ClientDeviceIdStore _clientDeviceIdStore;
  final DeviceMetadataReader _deviceMetadataReader;
  final OrbitLogger _logger;

  @override
  Future<AuthRestoreResult> restore() async {
    final session = await _sessionStore.read();
    if (session != null) {
      if (session.refreshExpired()) {
        await _sessionStore.clear();
      } else {
        try {
          final data = await _api.getDataMap('v1/auth/me');
          return AuthRestoreResult.authenticated(
            AuthUser.fromJson(data.cast<String, Object?>()),
          );
        } on OrbitApiException catch (error) {
          if (error.isUnauthorized) {
            await _sessionStore.clear();
          } else {
            rethrow;
          }
        }
      }
    }

    final pending = await _pendingStore.read();
    if (pending == null) {
      return const AuthRestoreResult.signedOut();
    }
    if (pending.isExpired()) {
      await _pendingStore.clear();
      return const AuthRestoreResult.signedOut();
    }
    return AuthRestoreResult.pending(pending);
  }

  @override
  Future<OtpChallenge> requestEmailOtp(String email) async {
    final normalized = email.trim().toLowerCase();
    final data = await _api.postDataMap(
      'v1/auth/email-otp/request',
      authenticated: false,
      data: <String, Object?>{'email': normalized},
    );

    final responseEmail = _requiredString(data, 'email');
    final expiresIn = _requiredInt(data, 'expires_in_seconds');
    return OtpChallenge(
      email: responseEmail,
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
    );
  }

  @override
  Future<AuthBootstrapResult> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final metadata = await _deviceMetadataReader.read();
    final clientDeviceId = await _clientDeviceIdStore.getOrCreate();

    final verifyData = await _api.postDataMap(
      'v1/auth/email-otp/verify',
      authenticated: false,
      data: <String, Object?>{
        'email': email.trim().toLowerCase(),
        'otp': otp,
        'device_name': metadata.name,
      },
    );

    final userRaw = verifyData['user'];
    if (userRaw is! Map) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an invalid authentication response.',
      );
    }

    final user = AuthUser.fromJson(
      userRaw.map((key, value) => MapEntry(key.toString(), value)),
    );
    final bootstrapToken = _requiredString(verifyData, 'access_token');
    final bootstrapExpiresAt = DateTime.parse(
      _requiredString(verifyData, 'expires_at'),
    );

    final device = await _api.postDataMap(
      'v1/devices',
      authenticated: false,
      bearerToken: bootstrapToken,
      data: <String, Object?>{
        'client_device_id': clientDeviceId,
        'platform': metadata.platform,
        'name': metadata.name,
        'app_version': metadata.appVersion,
        'os_version': metadata.osVersion,
      },
    );
    final serverDeviceId = _requiredString(device, 'id');

    final pending = PendingDeviceBootstrap(
      bootstrapAccessToken: bootstrapToken,
      bootstrapExpiresAt: bootstrapExpiresAt,
      serverDeviceId: serverDeviceId,
      deviceName: metadata.name,
      user: user,
    );

    return _issueSecureIdentitySession(pending);
  }

  @override
  Future<AuthBootstrapResult> retryPendingDeviceApproval() async {
    final pending = await _pendingStore.read();
    if (pending == null || pending.isExpired()) {
      await _pendingStore.clear();
      throw const OrbitApiException(
        code: 'AUTH_BOOTSTRAP_EXPIRED',
        message: 'This sign-in attempt has expired. Request a new code.',
        statusCode: 401,
      );
    }

    return _issueSecureIdentitySession(pending);
  }

  Future<AuthBootstrapResult> _issueSecureIdentitySession(
    PendingDeviceBootstrap pending,
  ) async {
    try {
      final identityData = await _api.postDataMap(
        'v1/identity/sessions',
        authenticated: false,
        bearerToken: pending.bootstrapAccessToken,
        data: <String, Object?>{'device_id': pending.serverDeviceId},
      );

      final session = AuthSession.fromIdentityPair(
        identityData.cast<String, Object?>(),
        deviceId: pending.serverDeviceId,
      );
      await _sessionStore.write(session);
      await _pendingStore.clear();
      await _revokeBootstrapTokenBestEffort(pending.bootstrapAccessToken);

      return AuthBootstrapResult.authenticated(
        user: pending.user,
        session: session,
      );
    } on OrbitApiException catch (error) {
      if (error.statusCode != 409) {
        rethrow;
      }

      await _pendingStore.write(pending);
      return AuthBootstrapResult.approvalRequired(
        user: pending.user,
        pending: pending,
      );
    }
  }

  Future<void> _revokeBootstrapTokenBestEffort(String token) async {
    try {
      await _api.postDataMap(
        'v1/auth/logout',
        authenticated: false,
        bearerToken: token,
      );
    } on OrbitApiException catch (error) {
      _logger.error(
        'Bootstrap access token could not be revoked after identity upgrade.',
        fields: <String, Object?>{'status': error.statusCode},
      );
    }
  }

  @override
  Future<void> clearPendingBootstrap() => _pendingStore.clear();

  @override
  Future<void> signOut() async {
    final session = await _sessionStore.read();
    if (session == null) {
      await _pendingStore.clear();
      return;
    }

    try {
      await _api.postDataMap('v1/identity/logout', allowAuthRetry: true);
    } on OrbitApiException catch (error) {
      if (!error.isUnauthorized) {
        rethrow;
      }
    }

    await _sessionStore.clear();
    await _pendingStore.clear();
  }

  @override
  Future<List<DeviceApproval>> listDeviceApprovals() async {
    final data = await _api.getDataList('v1/identity/device-approvals');
    return data
        .map((item) {
          if (item is! Map) {
            throw const OrbitApiException(
              code: 'INVALID_RESPONSE',
              message: 'Orbit returned an invalid device approval response.',
            );
          }
          return DeviceApproval.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> approveDevice(String deviceId) async {
    final session = await _sessionStore.read();
    if (session == null) {
      throw const OrbitApiException(
        code: 'UNAUTHENTICATED',
        message: 'Sign in again to approve this device.',
        statusCode: 401,
      );
    }

    await _api.postDataMap(
      'v1/identity/devices/$deviceId/approve',
      data: <String, Object?>{'approver_device_id': session.deviceId},
      allowAuthRetry: true,
    );
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected response.',
      );
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw const OrbitApiException(
      code: 'INVALID_RESPONSE',
      message: 'Orbit returned an unexpected response.',
    );
  }
}
