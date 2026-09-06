import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../domain/support_content.dart';

abstract interface class SupportRepository {
  Future<SupportContent?> loadSupportContent();
}

class HttpSupportRepository implements SupportRepository {
  const HttpSupportRepository({required OrbitApiClient apiClient})
    : _api = apiClient;

  final OrbitApiClient _api;

  @override
  Future<SupportContent?> loadSupportContent() async {
    try {
      final data = await _api.getDataMap('v1/content/support');
      return SupportContent.fromJson(data.cast<String, Object?>());
    } on OrbitApiException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      rethrow;
    } on FormatException {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned unexpected support content.',
      );
    }
  }
}
