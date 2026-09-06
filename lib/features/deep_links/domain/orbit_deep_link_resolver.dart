class OrbitDeepLinkResolver {
  const OrbitDeepLinkResolver();

  /// Resolves only backend-defined Orbit destinations. Unknown schemes, hosts,
  /// path shapes, query strings, fragments and non-UUID resource identifiers
  /// are rejected instead of being forwarded to the application router.
  String? resolve(Uri uri) {
    if (uri.scheme.toLowerCase() != 'orbit' ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      return null;
    }

    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments;

    switch (host) {
      case 'circles':
        if (segments.length == 2 &&
            _isUuid(segments[0]) &&
            segments[1] == 'chat') {
          return '/circles/${segments[0]}/messages';
        }
      case 'moments':
        if (segments.length == 1 && _isUuid(segments[0])) {
          return '/moments/${segments[0]}';
        }
      case 'pings':
        if (segments.length == 1 && _isUuid(segments[0])) {
          return '/pings';
        }
      case 'sos':
        if (segments.length == 1 && _isUuid(segments[0])) {
          return '/sos/${segments[0]}';
        }
    }
    return null;
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$',
    ).hasMatch(value);
  }
}
