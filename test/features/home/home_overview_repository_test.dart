import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/home/data/api_home_overview_repository.dart';
import 'package:orbit_app/features/presence/domain/presence_snapshot.dart';

import '../../support/m3_test_fakes.dart';

void main() {
  test(
    'Home uses real Circle and privacy-filtered presence contracts',
    () async {
      final api = M3FakeApiClient();
      api.getLists['v1/circles'] = <Object?>[
        <String, Object?>{
          'id': 'circle-1',
          'name': 'Family',
          'member_count': 2,
          'my_membership_id': 'member-1',
        },
      ];
      api.getLists['v1/circles/circle-1/presence'] = <Object?>[
        <String, Object?>{
          'membership_id': 'member-2',
          'user': <String, Object?>{'id': 8, 'name': 'Noah'},
          'presence': <String, Object?>{
            'status': 'online',
            'location': <String, Object?>{
              'mode': 'approximate',
              'latitude': 31.52,
              'longitude': 74.36,
            },
          },
        },
      ];

      final repository = ApiHomeOverviewRepository(apiClient: api);
      final circles = await repository.listCircles();
      final presence = await repository.listCirclePresence('circle-1');

      expect(circles.single.name, 'Family');
      expect(circles.single.memberCount, 2);
      expect(presence.single.name, 'Noah');
      expect(presence.single.locationMode, PresenceLocationMode.approximate);
    },
  );
}
