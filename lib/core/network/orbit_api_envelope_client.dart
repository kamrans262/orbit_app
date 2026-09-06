abstract interface class OrbitApiEnvelopeClient {
  Future<Map<String, dynamic>> getEnvelope(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  });
}
