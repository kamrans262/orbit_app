abstract interface class OrbitBinaryTransferClient {
  Future<void> putBytes(
    String path,
    List<int> bytes, {
    Map<String, String>? headers,
    bool allowAuthRetry = false,
  });

  Future<void> downloadToFile(
    String path,
    String destinationPath, {
    Map<String, Object?>? queryParameters,
  });
}
