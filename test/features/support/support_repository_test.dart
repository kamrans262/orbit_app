import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/network/orbit_api_exception.dart';
import 'package:orbit_app/features/support/data/support_repository.dart';

import '../../support/m9_test_api_client.dart';

void main() {
  test(
    'loads published support content through the consumer content contract',
    () async {
      final api = M9TestApiClient();
      api.getMapResponses['v1/content/support'] = <Object>[
        <String, dynamic>{
          'id': 'content-support',
          'type': 'page',
          'slug': 'support',
          'title': 'Orbit Support',
          'body': 'Trusted support information.',
          'metadata': <String, Object?>{},
        },
      ];
      final repository = HttpSupportRepository(apiClient: api);

      final content = await repository.loadSupportContent();

      expect(content?.slug, 'support');
      expect(content?.body, 'Trusted support information.');
      expect(api.calls.single.path, 'v1/content/support');
    },
  );

  test('treats an unpublished support slug as an honest empty state', () async {
    final api = M9TestApiClient();
    api.getMapResponses['v1/content/support'] = <Object>[
      const OrbitApiException(
        code: 'HTTP_404',
        message: 'Not found.',
        statusCode: 404,
      ),
    ];
    final repository = HttpSupportRepository(apiClient: api);

    final content = await repository.loadSupportContent();

    expect(content, isNull);
  });
}
