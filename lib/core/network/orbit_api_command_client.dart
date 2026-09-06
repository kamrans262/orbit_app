abstract interface class OrbitApiCommandClient {
  Future<void> postNoContent(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  });
}
