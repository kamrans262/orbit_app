import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/circles/data/circles_repository.dart';
import 'package:orbit_app/features/circles/domain/orbit_circle.dart';

import '../../support/m3_test_fakes.dart';

void main() {
  group('HttpCirclesRepository', () {
    test('parses the canonical Circle list contract', () async {
      final api = M3FakeApiClient();
      api.getLists['v1/circles'] = <Object?>[
        _circleJson(
          id: 'circle-1',
          name: 'Family',
          role: 'owner',
          memberCount: 4,
        ),
      ];
      final repository = HttpCirclesRepository(apiClient: api);

      final circles = await repository.listCircles();

      expect(circles, hasLength(1));
      expect(circles.single.name, 'Family');
      expect(circles.single.myRole, CircleRole.owner);
      expect(circles.single.memberCount, 4);
      expect(api.calls.single.path, 'v1/circles');
    });

    test('creates a temporary Circle with the backend payload shape', () async {
      final api = M3FakeApiClient();
      api.postMaps['v1/circles'] = _circleJson(
        id: 'circle-2',
        name: 'Trip',
        role: 'owner',
        memberCount: 1,
        type: 'temporary',
      );
      final repository = HttpCirclesRepository(apiClient: api);
      final expiresAt = DateTime.utc(2026, 9, 20, 12);

      final circle = await repository.createCircle(
        CreateCircleInput(
          name: ' Trip ',
          description: '  Weekend group  ',
          type: CircleType.temporary,
          expiresAt: expiresAt,
        ),
      );

      expect(circle.id, 'circle-2');
      final call = api.calls.single;
      expect(call.method, 'POST');
      expect(call.path, 'v1/circles');
      expect(call.data, <String, Object?>{
        'name': 'Trip',
        'type': 'temporary',
        'description': 'Weekend group',
        'expires_at': expiresAt.toIso8601String(),
      });
    });

    test('normalizes invite codes before joining', () async {
      final api = M3FakeApiClient();
      api.postMaps['v1/circles/join'] = _circleJson(
        id: 'circle-3',
        name: 'Friends',
        role: 'member',
        memberCount: 3,
      );
      final repository = HttpCirclesRepository(apiClient: api);

      await repository.joinCircle(' a1b2c3d4e5 ');

      expect(api.calls.single.data, <String, Object?>{'code': 'A1B2C3D4E5'});
    });

    test(
      'maps member roles and sends only the requested role change',
      () async {
        final api = M3FakeApiClient();
        api.patchMaps['v1/circles/circle-1/members/member-2'] = _memberJson(
          role: 'admin',
        );
        final repository = HttpCirclesRepository(apiClient: api);

        final member = await repository.updateMemberRole(
          circleId: 'circle-1',
          membershipId: 'member-2',
          role: CircleRole.admin,
        );

        expect(member.role, CircleRole.admin);
        expect(api.calls.single.data, <String, Object?>{'role': 'admin'});
      },
    );

    test(
      'routes destructive Circle mutations to canonical endpoints',
      () async {
        final api = M3FakeApiClient();
        api.postMaps['v1/circles/circle-1/leave'] = <String, dynamic>{};
        final repository = HttpCirclesRepository(apiClient: api);

        await repository.removeMember(
          circleId: 'circle-1',
          membershipId: 'member-2',
        );
        await repository.archiveCircle('circle-1');
        await repository.leaveCircle('circle-1');

        expect(api.calls.map((call) => '${call.method} ${call.path}'), <String>[
          'DELETE v1/circles/circle-1/members/member-2',
          'DELETE v1/circles/circle-1',
          'POST v1/circles/circle-1/leave',
        ]);
      },
    );
  });
}

Map<String, dynamic> _circleJson({
  required String id,
  required String name,
  required String role,
  required int memberCount,
  String type = 'standard',
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'description': null,
    'type': type,
    'my_role': role,
    'my_membership_id': 'membership-me',
    'member_count': memberCount,
    'expires_at': null,
    'archived_at': null,
    'is_archived': false,
    'is_expired': false,
    'created_at': '2026-09-01T10:00:00Z',
    'updated_at': '2026-09-01T10:00:00Z',
  };
}

Map<String, dynamic> _memberJson({required String role}) {
  return <String, dynamic>{
    'membership_id': 'member-2',
    'role': role,
    'location_mode': 'hidden',
    'can_ping': true,
    'can_message': true,
    'can_view_moments': true,
    'activity_visibility': true,
    'joined_at': '2026-09-01T10:00:00Z',
    'user': <String, dynamic>{
      'id': 9,
      'name': 'Maya',
      'email': 'maya@example.test',
    },
  };
}
