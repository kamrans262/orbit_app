import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/orbit_api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../data/profile_repository.dart';
import '../domain/orbit_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return HttpProfileRepository(apiClient: ref.watch(orbitApiClientProvider));
});

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileViewState>(
      ProfileController.new,
    );

class ProfileViewState {
  const ProfileViewState({
    required this.profile,
    this.isSaving = false,
    this.errorMessage,
  });

  final OrbitProfile profile;
  final bool isSaving;
  final String? errorMessage;

  ProfileViewState copyWith({
    OrbitProfile? profile,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileViewState(
      profile: profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ProfileController extends AsyncNotifier<ProfileViewState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  Future<ProfileViewState> build() async {
    return ProfileViewState(profile: await _repository.loadProfile());
  }

  Future<bool> save({
    String? name,
    required String timezone,
    required String locale,
  }) async {
    final current = _current;
    if (current == null || current.isSaving) {
      return false;
    }

    final cleanTimezone = timezone.trim();
    final cleanLocale = locale.trim();
    if (cleanTimezone.isEmpty || cleanLocale.isEmpty) {
      state = AsyncData<ProfileViewState>(
        current.copyWith(errorMessage: 'Timezone and locale are required.'),
      );
      return false;
    }

    state = AsyncData<ProfileViewState>(
      current.copyWith(isSaving: true, clearError: true),
    );
    try {
      final updated = await _repository.updateProfile(
        name: name,
        timezone: cleanTimezone,
        locale: cleanLocale,
      );
      state = AsyncData<ProfileViewState>(ProfileViewState(profile: updated));
      return true;
    } on OrbitApiException catch (error) {
      state = AsyncData<ProfileViewState>(
        current.copyWith(isSaving: false, errorMessage: error.message),
      );
      return false;
    } on Object {
      state = AsyncData<ProfileViewState>(
        current.copyWith(
          isSaving: false,
          errorMessage: 'Orbit could not update your profile. Try again.',
        ),
      );
      return false;
    }
  }

  ProfileViewState? get _current {
    return state.when(
      data: (value) => value,
      error: (_, _) => null,
      loading: () => null,
    );
  }
}
