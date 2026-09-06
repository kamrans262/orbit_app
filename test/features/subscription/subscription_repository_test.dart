import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/subscription/data/subscription_repository.dart';

import '../../support/m9_test_api_client.dart';

void main() {
  test(
    'loads the read-only current subscription and nested entitlements',
    () async {
      final api = M9TestApiClient();
      api.getMapResponses['v1/me/subscription'] = <Object>[
        <String, dynamic>{
          'id': 'subscription-1',
          'user_id': 1,
          'status': 'active',
          'plan': <String, Object?>{
            'id': 'plan-free',
            'slug': 'free',
            'name': 'Free',
          },
          'billing_interval': null,
          'price': <String, Object?>{'amount_minor': 0, 'currency': 'USD'},
          'complimentary': false,
          'started_at': '2026-09-01T12:00:00Z',
          'current_period_end': null,
          'cancel_at': null,
          'ends_at': null,
          'entitlements': <String, Object?>{
            'ads': <String, Object?>{'enabled': true},
            'circle_limit': <String, Object?>{'value': 3},
          },
        },
      ];
      final repository = HttpSubscriptionRepository(apiClient: api);

      final subscription = await repository.loadCurrentSubscription();

      expect(subscription.plan.slug, 'free');
      expect(subscription.isFree, isTrue);
      expect(subscription.entitlements['ads'], isA<Map>());
      expect(api.calls.single.path, 'v1/me/subscription');
      expect(api.calls.single.method, 'GET');
    },
  );
}
