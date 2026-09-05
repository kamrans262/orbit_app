import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceMetadata {
  const DeviceMetadata({
    required this.platform,
    required this.name,
    required this.appVersion,
    required this.osVersion,
  });

  final String platform;
  final String name;
  final String appVersion;
  final String osVersion;
}

abstract interface class DeviceMetadataReader {
  Future<DeviceMetadata> read();
}

class DeviceMetadataService implements DeviceMetadataReader {
  DeviceMetadataService(this._deviceInfo, this._packageInfoLoader);

  final DeviceInfoPlugin _deviceInfo;
  final Future<PackageInfo> Function() _packageInfoLoader;

  @override
  Future<DeviceMetadata> read() async {
    final packageInfo = await _packageInfoLoader();

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return DeviceMetadata(
        platform: 'android',
        name: info.model.trim().isEmpty ? 'Android device' : info.model.trim(),
        appVersion: packageInfo.version,
        osVersion: info.version.release,
      );
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return DeviceMetadata(
        platform: 'ios',
        name: info.name.trim().isEmpty ? 'iPhone' : info.name.trim(),
        appVersion: packageInfo.version,
        osVersion: info.systemVersion,
      );
    }

    throw UnsupportedError('Orbit mobile currently supports Android and iOS.');
  }
}
