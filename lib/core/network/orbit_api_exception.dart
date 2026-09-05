class OrbitApiException implements Exception {
  const OrbitApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.requestId,
    this.validationErrors = const <String, Object?>{},
  });

  factory OrbitApiException.fromPayload({
    required int? statusCode,
    required Object? payload,
    String? requestId,
  }) {
    final map = _stringMap(payload);
    if (map != null) {
      final nested = _stringMap(map['error']);
      final rawCode = map['code'] ?? nested?['code'];
      final rawMessage = map['message'] ?? nested?['message'];
      final rawErrors = _stringMap(map['errors']);

      return OrbitApiException(
        code: rawCode is String && rawCode.isNotEmpty
            ? rawCode
            : _fallbackCode(statusCode),
        message: rawMessage is String && rawMessage.isNotEmpty
            ? rawMessage
            : _fallbackMessage(statusCode),
        statusCode: statusCode,
        requestId: requestId,
        validationErrors: rawErrors ?? const <String, Object?>{},
      );
    }

    return OrbitApiException(
      code: _fallbackCode(statusCode),
      message: _fallbackMessage(statusCode),
      statusCode: statusCode,
      requestId: requestId,
    );
  }

  final String code;
  final String message;
  final int? statusCode;
  final String? requestId;
  final Map<String, Object?> validationErrors;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  bool get isNetworkFailure => statusCode == null;

  static Map<String, Object?>? _stringMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String _fallbackCode(int? statusCode) {
    if (statusCode == null) {
      return 'NETWORK_ERROR';
    }
    return 'HTTP_$statusCode';
  }

  static String _fallbackMessage(int? statusCode) {
    if (statusCode == null) {
      return 'Unable to reach Orbit. Check your connection and try again.';
    }
    if (statusCode == 401) {
      return 'Your Orbit session is no longer valid.';
    }
    if (statusCode == 403) {
      return 'This action is not permitted.';
    }
    if (statusCode == 409) {
      return 'This action needs another step before it can continue.';
    }
    if (statusCode == 422) {
      return 'Please review the submitted information and try again.';
    }
    if (statusCode == 429) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (statusCode >= 500) {
      return 'Orbit is temporarily unavailable. Please try again.';
    }
    return 'Orbit could not complete the request.';
  }

  @override
  String toString() => 'OrbitApiException($code, status: $statusCode)';
}
