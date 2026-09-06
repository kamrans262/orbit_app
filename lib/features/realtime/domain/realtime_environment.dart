import '../../../core/config/app_environment.dart';

class RealtimeEnvironment {
  const RealtimeEnvironment({
    required this.appKey,
    required this.host,
    required this.port,
    required this.scheme,
  });

  factory RealtimeEnvironment.fromDartDefines(AppEnvironment appEnvironment) {
    const appKey = String.fromEnvironment(
      'ORBIT_REVERB_APP_KEY',
      defaultValue: '',
    );
    const configuredHost = String.fromEnvironment(
      'ORBIT_REVERB_HOST',
      defaultValue: '',
    );
    const configuredPort = int.fromEnvironment(
      'ORBIT_REVERB_PORT',
      defaultValue: 0,
    );
    const configuredScheme = String.fromEnvironment(
      'ORBIT_REVERB_SCHEME',
      defaultValue: '',
    );

    final apiUri = Uri.parse(appEnvironment.apiBaseUrl);
    final scheme = configuredScheme.trim().isEmpty
        ? (apiUri.scheme == 'https' ? 'wss' : 'ws')
        : configuredScheme.trim().toLowerCase();
    final host = configuredHost.trim().isEmpty
        ? apiUri.host
        : configuredHost.trim();
    final port = configuredPort > 0
        ? configuredPort
        : (scheme == 'wss' ? 443 : 8080);

    return RealtimeEnvironment.fromValues(
      appKey: appKey,
      host: host,
      port: port,
      scheme: scheme,
      requireTls: appEnvironment.isProduction,
    );
  }

  factory RealtimeEnvironment.fromValues({
    required String appKey,
    required String host,
    required int port,
    required String scheme,
    required bool requireTls,
  }) {
    final normalizedScheme = scheme.trim().toLowerCase();
    final normalizedHost = host.trim();
    if (!{'ws', 'wss'}.contains(normalizedScheme)) {
      throw ArgumentError.value(
        scheme,
        'scheme',
        'Reverb scheme must be ws or wss.',
      );
    }
    if (normalizedHost.isEmpty) {
      throw StateError('ORBIT_REVERB_HOST must not be empty.');
    }
    if (port < 1 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'Invalid Reverb port.');
    }
    if (requireTls && normalizedScheme != 'wss') {
      throw StateError('Production Orbit realtime traffic must use WSS.');
    }

    return RealtimeEnvironment(
      appKey: appKey.trim(),
      host: normalizedHost,
      port: port,
      scheme: normalizedScheme,
    );
  }

  final String appKey;
  final String host;
  final int port;
  final String scheme;

  bool get isEnabled => appKey.isNotEmpty;

  Uri get socketUri => Uri(
    scheme: scheme,
    host: host,
    port: port,
    path: '/app/$appKey',
    queryParameters: const <String, String>{
      'protocol': '7',
      'client': 'orbit-flutter',
      'version': '1.0',
      'flash': 'false',
    },
  );
}
