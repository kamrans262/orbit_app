import '../../../core/security/auth_session.dart';
import 'auth_user.dart';

class PendingDeviceBootstrap {
  const PendingDeviceBootstrap({
    required this.bootstrapAccessToken,
    required this.bootstrapExpiresAt,
    required this.serverDeviceId,
    required this.deviceName,
    required this.user,
  });

  factory PendingDeviceBootstrap.fromJson(Map<String, Object?> json) {
    final userJson = json['user'];
    if (userJson is! Map) {
      throw const FormatException('Invalid pending Orbit bootstrap user.');
    }

    return PendingDeviceBootstrap(
      bootstrapAccessToken: _requiredString(json, 'bootstrap_access_token'),
      bootstrapExpiresAt: DateTime.parse(
        _requiredString(json, 'bootstrap_expires_at'),
      ),
      serverDeviceId: _requiredString(json, 'server_device_id'),
      deviceName: _requiredString(json, 'device_name'),
      user: AuthUser.fromJson(
        userJson.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }

  final String bootstrapAccessToken;
  final DateTime bootstrapExpiresAt;
  final String serverDeviceId;
  final String deviceName;
  final AuthUser user;

  bool isExpired({DateTime? now}) {
    return bootstrapExpiresAt.toUtc().isBefore((now ?? DateTime.now()).toUtc());
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'bootstrap_access_token': bootstrapAccessToken,
    'bootstrap_expires_at': bootstrapExpiresAt.toUtc().toIso8601String(),
    'server_device_id': serverDeviceId,
    'device_name': deviceName,
    'user': user.toJson(),
  };

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid $key.');
    }
    return value;
  }
}

enum AuthBootstrapStatus { authenticated, approvalRequired }

class AuthBootstrapResult {
  const AuthBootstrapResult._({
    required this.status,
    required this.user,
    this.session,
    this.pending,
  });

  const AuthBootstrapResult.authenticated({
    required AuthUser user,
    required AuthSession session,
  }) : this._(
         status: AuthBootstrapStatus.authenticated,
         user: user,
         session: session,
       );

  const AuthBootstrapResult.approvalRequired({
    required AuthUser user,
    required PendingDeviceBootstrap pending,
  }) : this._(
         status: AuthBootstrapStatus.approvalRequired,
         user: user,
         pending: pending,
       );

  final AuthBootstrapStatus status;
  final AuthUser user;
  final AuthSession? session;
  final PendingDeviceBootstrap? pending;
}

enum AuthRestoreStatus { signedOut, pendingDeviceApproval, authenticated }

class AuthRestoreResult {
  const AuthRestoreResult._({required this.status, this.user, this.pending});

  const AuthRestoreResult.signedOut()
    : this._(status: AuthRestoreStatus.signedOut);

  AuthRestoreResult.pending(PendingDeviceBootstrap pending)
    : this._(
        status: AuthRestoreStatus.pendingDeviceApproval,
        user: pending.user,
        pending: pending,
      );

  const AuthRestoreResult.authenticated(AuthUser user)
    : this._(status: AuthRestoreStatus.authenticated, user: user);

  final AuthRestoreStatus status;
  final AuthUser? user;
  final PendingDeviceBootstrap? pending;
}
