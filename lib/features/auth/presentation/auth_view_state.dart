import '../domain/auth_user.dart';

const Object _unset = Object();

enum AuthStage {
  signedOut,
  otpRequested,
  deviceApprovalRequired,
  authenticated,
  restoreFailed,
}

class AuthViewState {
  const AuthViewState({
    required this.stage,
    this.user,
    this.email,
    this.otpExpiresAt,
    this.deviceName,
    this.isBusy = false,
    this.errorMessage,
  });

  const AuthViewState.signedOut({String? errorMessage})
    : this(stage: AuthStage.signedOut, errorMessage: errorMessage);

  const AuthViewState.otpRequested({
    required String email,
    required DateTime expiresAt,
    bool isBusy = false,
    String? errorMessage,
  }) : this(
         stage: AuthStage.otpRequested,
         email: email,
         otpExpiresAt: expiresAt,
         isBusy: isBusy,
         errorMessage: errorMessage,
       );

  AuthViewState.deviceApprovalRequired({
    required AuthUser user,
    required String deviceName,
    bool isBusy = false,
    String? errorMessage,
  }) : this(
         stage: AuthStage.deviceApprovalRequired,
         user: user,
         email: user.email,
         deviceName: deviceName,
         isBusy: isBusy,
         errorMessage: errorMessage,
       );

  AuthViewState.authenticated({
    required AuthUser user,
    bool isBusy = false,
    String? errorMessage,
  }) : this(
         stage: AuthStage.authenticated,
         user: user,
         email: user.email,
         isBusy: isBusy,
         errorMessage: errorMessage,
       );

  const AuthViewState.restoreFailed(String message)
    : this(stage: AuthStage.restoreFailed, errorMessage: message);

  final AuthStage stage;
  final AuthUser? user;
  final String? email;
  final DateTime? otpExpiresAt;
  final String? deviceName;
  final bool isBusy;
  final String? errorMessage;

  AuthViewState copyWith({bool? isBusy, Object? errorMessage = _unset}) {
    return AuthViewState(
      stage: stage,
      user: user,
      email: email,
      otpExpiresAt: otpExpiresAt,
      deviceName: deviceName,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
