import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preview_home_repository.dart';
import '../domain/home_dashboard.dart';
import '../domain/home_repository.dart';

final Provider<HomeRepository> homeRepositoryProvider =
    Provider<HomeRepository>((ref) => const PreviewHomeRepository());

final FutureProvider<HomeDashboard> homeDashboardProvider =
    FutureProvider<HomeDashboard>((ref) async {
      final repository = ref.watch(homeRepositoryProvider);
      return repository.loadDashboard();
    });
