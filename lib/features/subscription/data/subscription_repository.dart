import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../domain/orbit_subscription.dart';

abstract interface class SubscriptionRepository {
  Future<OrbitSubscription> loadCurrentSubscription();
}

class HttpSubscriptionRepository implements SubscriptionRepository {
  const HttpSubscriptionRepository({required OrbitApiClient apiClient})
    : _api = apiClient;

  final OrbitApiClient _api;

  @override
  Future<OrbitSubscription> loadCurrentSubscription() async {
    final data = await _api.getDataMap('v1/me/subscription');
    try {
      return OrbitSubscription.fromJson(data.cast<String, Object?>());
    } on FormatException {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned unexpected subscription information.',
      );
    }
  }
}
