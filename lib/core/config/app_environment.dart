import 'package:flutter/foundation.dart';

class AppEnvironment {
  const AppEnvironment({required this.name, required this.apiBaseUrl});

  factory AppEnvironment.fromDartDefines() {
    const name = String.fromEnvironment(
      'ORBIT_ENVIRONMENT',
      defaultValue: 'local',
    );
    const apiBaseUrl = String.fromEnvironment(
      'ORBIT_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000/api',
    );

    return AppEnvironment.fromValues(
      name: name,
      apiBaseUrl: apiBaseUrl,
      isRelease: kReleaseMode,
    );
  }

  factory AppEnvironment.fromValues({
    required String name,
    required String apiBaseUrl,
    required bool isRelease,
  }) {
    final normalizedName = name.trim().toLowerCase();
    if (!{'local', 'staging', 'production'}.contains(normalizedName)) {
      throw ArgumentError.value(name, 'name', 'Unsupported Orbit environment.');
    }

    final normalizedUrl = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalizedUrl.isEmpty) {
      throw StateError('ORBIT_API_BASE_URL must not be empty.');
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError.value(
        apiBaseUrl,
        'apiBaseUrl',
        'Invalid Orbit API base URL.',
      );
    }

    if ((normalizedName == 'production' || isRelease) &&
        uri.scheme != 'https') {
      throw StateError(
        'Release and production Orbit API traffic must use HTTPS.',
      );
    }

    return AppEnvironment(name: normalizedName, apiBaseUrl: normalizedUrl);
  }

  final String name;
  final String apiBaseUrl;

  bool get isProduction => name == 'production';
}
