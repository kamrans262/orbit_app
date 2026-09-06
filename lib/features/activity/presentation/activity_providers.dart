import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/orbit_api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../data/activity_repository.dart';
import '../domain/activity_item.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return HttpActivityRepository(
    apiClient: ref.watch(orbitApiClientProvider),
    envelopeClient: ref.watch(orbitApiEnvelopeClientProvider),
    commandClient: ref.watch(orbitApiCommandClientProvider),
  );
});

final activityPreviewProvider = FutureProvider<List<ActivityItem>>((ref) async {
  final page = await ref.watch(activityRepositoryProvider).listFeed(limit: 3);
  return page.items;
});

final activityControllerProvider =
    AsyncNotifierProvider<ActivityController, ActivityViewState>(
      ActivityController.new,
    );

class ActivityViewState {
  const ActivityViewState({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    this.isLoadingMore = false,
    this.busyActivityId,
    this.errorMessage,
  });

  final List<ActivityItem> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final String? busyActivityId;
  final String? errorMessage;

  ActivityViewState copyWith({
    List<ActivityItem>? items,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? hasMore,
    bool? isLoadingMore,
    String? busyActivityId,
    bool clearBusyActivity = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActivityViewState(
      items: items ?? this.items,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      busyActivityId: clearBusyActivity
          ? null
          : busyActivityId ?? this.busyActivityId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ActivityController extends AsyncNotifier<ActivityViewState> {
  ActivityRepository get _repository => ref.read(activityRepositoryProvider);

  @override
  Future<ActivityViewState> build() async {
    final page = await _repository.listFeed();
    return ActivityViewState(
      items: page.items,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<ActivityViewState>();
    state = await AsyncValue.guard(build);
    ref.invalidate(activityPreviewProvider);
  }

  Future<void> loadMore() async {
    final current = _current;
    if (current == null ||
        current.isLoadingMore ||
        !current.hasMore ||
        current.nextCursor == null) {
      return;
    }

    state = AsyncData<ActivityViewState>(
      current.copyWith(isLoadingMore: true, clearError: true),
    );

    try {
      final page = await _repository.listFeed(cursor: current.nextCursor);
      final existingIds = current.items.map((item) => item.id).toSet();
      final appended = <ActivityItem>[
        ...current.items,
        ...page.items.where((item) => existingIds.add(item.id)),
      ];
      state = AsyncData<ActivityViewState>(
        current.copyWith(
          items: List<ActivityItem>.unmodifiable(appended),
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          hasMore: page.hasMore,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } on OrbitApiException catch (error) {
      state = AsyncData<ActivityViewState>(
        current.copyWith(isLoadingMore: false, errorMessage: error.message),
      );
    } on Object {
      state = AsyncData<ActivityViewState>(
        current.copyWith(
          isLoadingMore: false,
          errorMessage: 'Orbit could not load more activity. Try again.',
        ),
      );
    }
  }

  Future<bool> hide(ActivityItem item) async {
    final current = _current;
    if (current == null || current.busyActivityId != null) {
      return false;
    }

    state = AsyncData<ActivityViewState>(
      current.copyWith(busyActivityId: item.id, clearError: true),
    );
    try {
      await _repository.hide(item.id);
      state = AsyncData<ActivityViewState>(
        current.copyWith(
          items: current.items
              .where((candidate) => candidate.id != item.id)
              .toList(growable: false),
          clearBusyActivity: true,
          clearError: true,
        ),
      );
      ref.invalidate(activityPreviewProvider);
      return true;
    } on OrbitApiException catch (error) {
      state = AsyncData<ActivityViewState>(
        current.copyWith(clearBusyActivity: true, errorMessage: error.message),
      );
      return false;
    } on Object {
      state = AsyncData<ActivityViewState>(
        current.copyWith(
          clearBusyActivity: true,
          errorMessage: 'Orbit could not hide that activity item. Try again.',
        ),
      );
      return false;
    }
  }

  Future<bool> report({
    required ActivityItem item,
    required ActivityReportReason reason,
    String? details,
  }) async {
    final current = _current;
    if (current == null || current.busyActivityId != null) {
      return false;
    }

    state = AsyncData<ActivityViewState>(
      current.copyWith(busyActivityId: item.id, clearError: true),
    );
    try {
      await _repository.report(
        activityId: item.id,
        reason: reason,
        details: details,
      );
      state = AsyncData<ActivityViewState>(
        current.copyWith(clearBusyActivity: true, clearError: true),
      );
      return true;
    } on OrbitApiException catch (error) {
      state = AsyncData<ActivityViewState>(
        current.copyWith(clearBusyActivity: true, errorMessage: error.message),
      );
      return false;
    } on Object {
      state = AsyncData<ActivityViewState>(
        current.copyWith(
          clearBusyActivity: true,
          errorMessage: 'Orbit could not report that activity item. Try again.',
        ),
      );
      return false;
    }
  }

  ActivityViewState? get _current {
    return state.when(
      data: (value) => value,
      error: (_, _) => null,
      loading: () => null,
    );
  }
}
