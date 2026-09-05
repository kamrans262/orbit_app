import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/orbit_api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_results.dart';
import 'auth_view_state.dart';
import 'device_approvals_controller.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthViewState>(AuthController.new);

class AuthController extends AsyncNotifier<AuthViewState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthViewState> build() async {
    return _restore();
  }

  Future<AuthViewState> _restore() async {
    try {
      final result = await _repository.restore();
      return _stateFromRestore(result);
    } on OrbitApiException catch (error) {
      return AuthViewState.restoreFailed(error.message);
    } on Object {
      return const AuthViewState.restoreFailed(
        'Orbit could not restore your session. Check your connection and retry.',
      );
    }
  }

  Future<void> retryRestore() async {
    state = const AsyncLoading<AuthViewState>();
    state = AsyncData<AuthViewState>(await _restore());
  }

  Future<void> requestOtp(String email) async {
    final current = _currentOr(const AuthViewState.signedOut());
    final normalized = email.trim().toLowerCase();
    if (!_looksLikeEmail(normalized)) {
      state = AsyncData<AuthViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Enter a valid email address.',
        ),
      );
      return;
    }

    state = AsyncData<AuthViewState>(
      current.copyWith(isBusy: true, errorMessage: null),
    );

    try {
      final challenge = await _repository.requestEmailOtp(normalized);
      state = AsyncData<AuthViewState>(
        AuthViewState.otpRequested(
          email: challenge.email,
          expiresAt: challenge.expiresAt,
        ),
      );
    } on OrbitApiException catch (error) {
      state = AsyncData<AuthViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
    } on Object {
      state = AsyncData<AuthViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Orbit could not send the sign-in code. Try again.',
        ),
      );
    }
  }

  Future<void> resendOtp() async {
    final current = _currentOr(const AuthViewState.signedOut());
    final email = current.email;
    if (email == null || email.isEmpty) {
      state = const AsyncData<AuthViewState>(AuthViewState.signedOut());
      return;
    }

    state = AsyncData<AuthViewState>(
      current.copyWith(isBusy: true, errorMessage: null),
    );
    try {
      final challenge = await _repository.requestEmailOtp(email);
      state = AsyncData<AuthViewState>(
        AuthViewState.otpRequested(
          email: challenge.email,
          expiresAt: challenge.expiresAt,
        ),
      );
    } on OrbitApiException catch (error) {
      state = AsyncData<AuthViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
    } on Object {
      state = AsyncData<AuthViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Orbit could not resend the code. Try again.',
        ),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    final current = _currentOr(const AuthViewState.signedOut());
    final email = current.email;
    if (email == null || email.isEmpty) {
      state = const AsyncData<AuthViewState>(AuthViewState.signedOut());
      return;
    }

    final normalizedOtp = otp.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedOtp)) {
      state = AsyncData<AuthViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Enter the 6-digit code from your email.',
        ),
      );
      return;
    }

    state = AsyncData<AuthViewState>(
      current.copyWith(isBusy: true, errorMessage: null),
    );

    try {
      final result = await _repository.verifyEmailOtp(
        email: email,
        otp: normalizedOtp,
      );
      state = AsyncData<AuthViewState>(_stateFromBootstrap(result));
    } on OrbitApiException catch (error) {
      state = AsyncData<AuthViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
    } on Object {
      state = AsyncData<AuthViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Orbit could not finish signing you in. Try again.',
        ),
      );
    }
  }

  Future<void> checkDeviceApproval() async {
    final current = _currentOr(const AuthViewState.signedOut());
    state = AsyncData<AuthViewState>(
      current.copyWith(isBusy: true, errorMessage: null),
    );

    try {
      final result = await _repository.retryPendingDeviceApproval();
      state = AsyncData<AuthViewState>(_stateFromBootstrap(result));
    } on OrbitApiException catch (error) {
      state = AsyncData<AuthViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
    } on Object {
      state = AsyncData<AuthViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Orbit could not check the approval yet. Try again.',
        ),
      );
    }
  }

  Future<void> startOver() async {
    await _repository.clearPendingBootstrap();
    state = const AsyncData<AuthViewState>(AuthViewState.signedOut());
  }

  Future<void> signOut() async {
    final current = _currentOr(const AuthViewState.signedOut());
    state = AsyncData<AuthViewState>(
      current.copyWith(isBusy: true, errorMessage: null),
    );

    try {
      await _repository.signOut();
      ref.invalidate(deviceApprovalsControllerProvider);
      state = const AsyncData<AuthViewState>(AuthViewState.signedOut());
    } on OrbitApiException catch (error) {
      state = AsyncData<AuthViewState>(
        current.copyWith(isBusy: false, errorMessage: error.message),
      );
    } on Object {
      state = AsyncData<AuthViewState>(
        current.copyWith(
          isBusy: false,
          errorMessage: 'Orbit could not sign out securely. Try again.',
        ),
      );
    }
  }

  AuthViewState _stateFromRestore(AuthRestoreResult result) {
    switch (result.status) {
      case AuthRestoreStatus.signedOut:
        return const AuthViewState.signedOut();
      case AuthRestoreStatus.pendingDeviceApproval:
        final pending = result.pending!;
        return AuthViewState.deviceApprovalRequired(
          user: pending.user,
          deviceName: pending.deviceName,
        );
      case AuthRestoreStatus.authenticated:
        return AuthViewState.authenticated(user: result.user!);
    }
  }

  AuthViewState _stateFromBootstrap(AuthBootstrapResult result) {
    switch (result.status) {
      case AuthBootstrapStatus.authenticated:
        return AuthViewState.authenticated(user: result.user);
      case AuthBootstrapStatus.approvalRequired:
        return AuthViewState.deviceApprovalRequired(
          user: result.user,
          deviceName: result.pending!.deviceName,
        );
    }
  }

  AuthViewState _currentOr(AuthViewState fallback) {
    return state.when(
      data: (value) => value,
      error: (_, _) => fallback,
      loading: () => fallback,
    );
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }
}
