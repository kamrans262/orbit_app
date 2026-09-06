import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/orbit_api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../application/circle_change_signal.dart';
import '../data/circles_repository.dart';
import '../domain/orbit_circle.dart';

final circlesRepositoryProvider = Provider<CirclesRepository>((ref) {
  return HttpCirclesRepository(apiClient: ref.watch(orbitApiClientProvider));
});

final circlesProvider = FutureProvider<List<OrbitCircle>>((ref) {
  return ref.watch(circlesRepositoryProvider).listCircles();
});

final circleDetailProvider = FutureProvider.family<OrbitCircle, String>((
  ref,
  circleId,
) {
  return ref.watch(circlesRepositoryProvider).getCircle(circleId);
});

final circleMembersProvider =
    FutureProvider.family<List<OrbitCircleMember>, String>((ref, circleId) {
      return ref.watch(circlesRepositoryProvider).listMembers(circleId);
    });

final circleMutationControllerProvider =
    NotifierProvider<CircleMutationController, CircleMutationState>(
      CircleMutationController.new,
    );

enum CircleMutationKind {
  create,
  join,
  updateCircle,
  createInvite,
  updateRole,
  removeMember,
  leave,
  archive,
}

class CircleMutationState {
  const CircleMutationState({
    this.isBusy = false,
    this.kind,
    this.errorMessage,
  });

  final bool isBusy;
  final CircleMutationKind? kind;
  final String? errorMessage;

  bool hasErrorFor(Set<CircleMutationKind> kinds) {
    return errorMessage != null && kind != null && kinds.contains(kind);
  }
}

class CircleMutationController extends Notifier<CircleMutationState> {
  CirclesRepository get _repository => ref.read(circlesRepositoryProvider);

  @override
  CircleMutationState build() => const CircleMutationState();

  void clearError() {
    if (state.errorMessage != null) {
      state = CircleMutationState(isBusy: state.isBusy, kind: state.kind);
    }
  }

  Future<OrbitCircle?> createCircle(CreateCircleInput input) async {
    return _execute<OrbitCircle>(CircleMutationKind.create, () async {
      final circle = await _repository.createCircle(input);
      _markCircleDataChanged();
      ref.invalidate(circlesProvider);
      return circle;
    });
  }

  Future<OrbitCircle?> joinCircle(String code) async {
    return _execute<OrbitCircle>(CircleMutationKind.join, () async {
      final circle = await _repository.joinCircle(code);
      _markCircleDataChanged();
      ref.invalidate(circlesProvider);
      return circle;
    });
  }

  Future<OrbitCircle?> updateCircle({
    required String circleId,
    required String name,
    String? description,
  }) async {
    return _execute<OrbitCircle>(CircleMutationKind.updateCircle, () async {
      final circle = await _repository.updateCircle(
        circleId: circleId,
        name: name,
        description: description,
      );
      _markCircleDataChanged();
      ref.invalidate(circlesProvider);
      ref.invalidate(circleDetailProvider(circleId));
      return circle;
    });
  }

  Future<OrbitCircleInvite?> createInvite({
    required String circleId,
    required CreateCircleInviteInput input,
  }) {
    return _execute<OrbitCircleInvite>(
      CircleMutationKind.createInvite,
      () => _repository.createInvite(circleId: circleId, input: input),
    );
  }

  Future<OrbitCircleMember?> updateMemberRole({
    required String circleId,
    required String membershipId,
    required CircleRole role,
  }) async {
    return _execute<OrbitCircleMember>(CircleMutationKind.updateRole, () async {
      final member = await _repository.updateMemberRole(
        circleId: circleId,
        membershipId: membershipId,
        role: role,
      );
      ref.invalidate(circleMembersProvider(circleId));
      return member;
    });
  }

  Future<bool> removeMember({
    required String circleId,
    required String membershipId,
  }) async {
    final result = await _execute<bool>(
      CircleMutationKind.removeMember,
      () async {
        await _repository.removeMember(
          circleId: circleId,
          membershipId: membershipId,
        );
        _markCircleDataChanged();
        ref.invalidate(circleMembersProvider(circleId));
        ref.invalidate(circleDetailProvider(circleId));
        ref.invalidate(circlesProvider);
        return true;
      },
    );
    return result ?? false;
  }

  Future<bool> leaveCircle(String circleId) async {
    final result = await _execute<bool>(CircleMutationKind.leave, () async {
      await _repository.leaveCircle(circleId);
      _markCircleDataChanged();
      ref.invalidate(circlesProvider);
      return true;
    });
    return result ?? false;
  }

  Future<bool> archiveCircle(String circleId) async {
    final result = await _execute<bool>(CircleMutationKind.archive, () async {
      await _repository.archiveCircle(circleId);
      _markCircleDataChanged();
      ref.invalidate(circlesProvider);
      ref.invalidate(circleDetailProvider(circleId));
      return true;
    });
    return result ?? false;
  }

  void _markCircleDataChanged() {
    ref.read(circleChangeRevisionProvider.notifier).markChanged();
  }

  Future<T?> _execute<T>(
    CircleMutationKind kind,
    Future<T> Function() action,
  ) async {
    if (state.isBusy) {
      return null;
    }

    state = CircleMutationState(isBusy: true, kind: kind);
    try {
      final result = await action();
      state = CircleMutationState(kind: kind);
      return result;
    } on OrbitApiException catch (error) {
      state = CircleMutationState(kind: kind, errorMessage: error.message);
      return null;
    } on Object {
      state = CircleMutationState(
        kind: kind,
        errorMessage: 'Orbit could not complete that Circle action. Try again.',
      );
      return null;
    }
  }
}
