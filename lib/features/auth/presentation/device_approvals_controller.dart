import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../domain/device_approval.dart';

final deviceApprovalsControllerProvider =
    AsyncNotifierProvider<DeviceApprovalsController, List<DeviceApproval>>(
      DeviceApprovalsController.new,
    );

class DeviceApprovalsController extends AsyncNotifier<List<DeviceApproval>> {
  @override
  Future<List<DeviceApproval>> build() {
    return ref.read(authRepositoryProvider).listDeviceApprovals();
  }

  Future<void> refreshList() async {
    state = const AsyncLoading<List<DeviceApproval>>();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).listDeviceApprovals(),
    );
  }

  Future<void> approve(String deviceId) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading<List<DeviceApproval>>();
    state = await AsyncValue.guard(() async {
      await repository.approveDevice(deviceId);
      return repository.listDeviceApprovals();
    });
  }
}
