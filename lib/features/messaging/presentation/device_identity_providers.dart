import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/device_identity_store.dart';

final deviceIdentityStoreProvider = Provider<DeviceIdentityStore>((ref) {
  return SecureDeviceIdentityStore(ref.watch(flutterSecureStorageProvider));
});
