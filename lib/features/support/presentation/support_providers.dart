import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/support_repository.dart';
import '../domain/support_content.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return HttpSupportRepository(apiClient: ref.watch(orbitApiClientProvider));
});

final supportContentProvider = FutureProvider<SupportContent?>((ref) {
  return ref.watch(supportRepositoryProvider).loadSupportContent();
});
