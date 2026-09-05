import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/ping/data/ping_repository.dart';
import 'package:orbit_app/features/ping/domain/ping_item.dart';

import '../../support/m3_test_fakes.dart';

void main() {
  test(
    'Ping targets exclude the current membership and preserve can_ping',
    () async {
      final api = M3FakeApiClient();
      api.getLists['v1/circles/circle-1/members'] = <Object?>[
        <String, Object?>{
          'membership_id': 'mine',
          'can_ping': true,
          'user': <String, Object?>{
            'name': 'Maya',
            'email': 'maya@example.com',
          },
        },
        <String, Object?>{
          'membership_id': 'member-2',
          'can_ping': true,
          'user': <String, Object?>{
            'name': 'Noah',
            'email': 'noah@example.com',
          },
        },
        <String, Object?>{
          'membership_id': 'member-3',
          'can_ping': false,
          'user': <String, Object?>{'name': 'Ava', 'email': 'ava@example.com'},
        },
      ];

      final repository = HttpPingRepository(apiClient: api);
      final targets = await repository.listTargets(
        const PingCircleOption(
          id: 'circle-1',
          name: 'Family',
          myMembershipId: 'mine',
        ),
      );

      expect(targets, hasLength(2));
      expect(targets.first.name, 'Noah');
      expect(targets.first.canPing, isTrue);
      expect(targets.last.canPing, isFalse);
    },
  );

  test(
    'send Ping uses the canonical Laravel payload and parses response',
    () async {
      final api = M3FakeApiClient();
      api.postMaps['v1/pings'] = _pingResponse();
      final repository = HttpPingRepository(apiClient: api);

      final ping = await repository.send(
        circleId: 'circle-1',
        recipientMembershipId: 'member-2',
      );

      expect(ping.status, PingStatus.pending);
      expect(ping.recipient.name, 'Noah');
      expect(api.calls.single.path, 'v1/pings');

      final payload = api.calls.single.data! as Map<String, Object?>;
      expect(payload, <String, Object?>{
        'circle_id': 'circle-1',
        'recipient_membership_id': 'member-2',
      });
    },
  );

  test('responding with Share Location sends intent only', () async {
    final api = M3FakeApiClient();
    api.postMaps['v1/pings/ping-1/respond'] = _pingResponse(
      status: 'responded',
      responseType: 'share_location',
    );
    final repository = HttpPingRepository(apiClient: api);

    final ping = await repository.respond(
      'ping-1',
      PingResponseType.shareLocation,
    );

    expect(ping.responseType, 'share_location');
    final payload = api.calls.single.data! as Map<String, Object?>;
    expect(payload['response_type'], 'share_location');
  });
}

Map<String, dynamic> _pingResponse({
  String status = 'pending',
  String? responseType,
}) {
  return <String, dynamic>{
    'id': 'ping-1',
    'circle': <String, Object?>{'id': 'circle-1', 'name': 'Family'},
    'sender': <String, Object?>{
      'membership_id': 'mine',
      'user_id': 7,
      'name': 'Maya',
    },
    'recipient': <String, Object?>{
      'membership_id': 'member-2',
      'user_id': 8,
      'name': 'Noah',
    },
    'status': status,
    'response_type': responseType,
    'expires_at': '2026-09-06T12:02:00Z',
    'responded_at': status == 'responded' ? '2026-09-06T12:01:00Z' : null,
    'dismissed_at': null,
    'created_at': '2026-09-06T12:00:00Z',
  };
}
