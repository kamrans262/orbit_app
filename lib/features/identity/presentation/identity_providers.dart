import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/orbit_api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/security/auth_session.dart';
import '../data/identity_repository.dart';
import '../domain/identity_models.dart';

final identityRepositoryProvider = Provider<IdentityRepository>((ref) {
  return HttpIdentityRepository(apiClient: ref.watch(orbitApiClientProvider));
});

final currentAuthSessionProvider = FutureProvider<AuthSession?>((ref) {
  return ref.watch(sessionStoreProvider).read();
});

final privacySummaryProvider = FutureProvider<PrivacySummary>((ref) {
  return ref.watch(identityRepositoryProvider).privacySummary();
});

final identityDevicesProvider = FutureProvider<List<OrbitIdentityDevice>>((
  ref,
) {
  return ref.watch(identityRepositoryProvider).listDevices();
});

final identitySessionsProvider =
    FutureProvider<List<OrbitIdentitySessionSummary>>((ref) {
      return ref.watch(identityRepositoryProvider).listSessions();
    });

final securityAuditProvider = FutureProvider<List<SecurityAuditEntry>>((ref) {
  return ref.watch(identityRepositoryProvider).listAuditLogs();
});

final dataExportProvider =
    FutureProvider.family<DataExportRequestSummary, String>((ref, exportId) {
      return ref.watch(identityRepositoryProvider).getDataExport(exportId);
    });

final identityMutationControllerProvider =
    NotifierProvider<IdentityMutationController, IdentityMutationState>(
      IdentityMutationController.new,
    );

class IdentityMutationState {
  const IdentityMutationState({this.busyKey, this.errorMessage});

  final String? busyKey;
  final String? errorMessage;

  bool isBusy(String key) => busyKey == key;
  bool get hasBusyOperation => busyKey != null;
}

class IdentityMutationController extends Notifier<IdentityMutationState> {
  IdentityRepository get _repository => ref.read(identityRepositoryProvider);

  @override
  IdentityMutationState build() => const IdentityMutationState();

  void clearError() {
    if (state.errorMessage != null) {
      state = const IdentityMutationState();
    }
  }

  Future<bool> renameDevice(String deviceId, String name) {
    return _run('device:$deviceId', () async {
      await _repository.renameDevice(deviceId, name);
      ref.invalidate(identityDevicesProvider);
    });
  }

  Future<bool> revokeSession(String sessionId) {
    return _run('session:$sessionId', () async {
      await _repository.revokeSession(sessionId);
      ref.invalidate(identitySessionsProvider);
      ref.invalidate(securityAuditProvider);
    });
  }

  Future<int?> revokeOtherSessions() async {
    int? revoked;
    final ok = await _run('sessions:others', () async {
      revoked = await _repository.revokeOtherSessions();
      ref.invalidate(identitySessionsProvider);
      ref.invalidate(securityAuditProvider);
    });
    return ok ? revoked : null;
  }

  Future<DataExportRequestSummary?> requestDataExport() async {
    DataExportRequestSummary? result;
    final ok = await _run('privacy:export', () async {
      result = await _repository.requestDataExport();
      ref.invalidate(privacySummaryProvider);
      final export = result;
      if (export != null) {
        ref.invalidate(dataExportProvider(export.id));
      }
    });
    return ok ? result : null;
  }

  Future<AccountDeletionRequestSummary?> requestAccountDeletion({
    String? reason,
  }) async {
    AccountDeletionRequestSummary? result;
    final ok = await _run('privacy:delete', () async {
      result = await _repository.requestAccountDeletion(reason: reason);
      ref.invalidate(privacySummaryProvider);
      ref.invalidate(securityAuditProvider);
    });
    return ok ? result : null;
  }

  Future<bool> cancelAccountDeletion() {
    return _run('privacy:cancel-delete', () async {
      await _repository.cancelAccountDeletion();
      ref.invalidate(privacySummaryProvider);
      ref.invalidate(securityAuditProvider);
    });
  }

  Future<bool> _run(String key, Future<void> Function() operation) async {
    if (state.hasBusyOperation) {
      return false;
    }
    state = IdentityMutationState(busyKey: key);
    try {
      await operation();
      state = const IdentityMutationState();
      return true;
    } on OrbitApiException catch (error) {
      state = IdentityMutationState(errorMessage: error.message);
      return false;
    } on Object {
      state = const IdentityMutationState(
        errorMessage:
            'Orbit could not complete that security action. Try again.',
      );
      return false;
    }
  }
}
