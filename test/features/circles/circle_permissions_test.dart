import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/circles/domain/circle_permissions.dart';
import 'package:orbit_app/features/circles/domain/orbit_circle.dart';

void main() {
  group('CirclePermissions', () {
    test('owner can manage non-owner roles and members', () {
      final circle = _circle(CircleRole.owner);
      final target = _member(role: CircleRole.member);

      expect(
        CirclePermissions.assignableRoles(circle: circle, target: target),
        <CircleRole>[
          CircleRole.admin,
          CircleRole.member,
          CircleRole.restricted,
        ],
      );
      expect(
        CirclePermissions.canRemove(circle: circle, target: target),
        isTrue,
      );
    });

    test('admin cannot manage another admin', () {
      final circle = _circle(CircleRole.admin);
      final target = _member(role: CircleRole.admin);

      expect(
        CirclePermissions.canChangeRole(circle: circle, target: target),
        isFalse,
      );
      expect(
        CirclePermissions.canRemove(circle: circle, target: target),
        isFalse,
      );
    });

    test('member cannot manage Circle memberships', () {
      final circle = _circle(CircleRole.member);
      final target = _member(role: CircleRole.member);

      expect(
        CirclePermissions.assignableRoles(circle: circle, target: target),
        isEmpty,
      );
      expect(
        CirclePermissions.canRemove(circle: circle, target: target),
        isFalse,
      );
    });

    test('nobody can remove the owner through the current contract', () {
      final circle = _circle(CircleRole.owner);
      final target = _member(role: CircleRole.owner);

      expect(
        CirclePermissions.canRemove(circle: circle, target: target),
        isFalse,
      );
      expect(
        CirclePermissions.canChangeRole(circle: circle, target: target),
        isFalse,
      );
    });
  });
}

OrbitCircle _circle(CircleRole role) {
  return OrbitCircle(
    id: 'circle-1',
    name: 'Family',
    type: CircleType.standard,
    myRole: role,
    myMembershipId: 'membership-me',
    memberCount: 3,
    isArchived: false,
    isExpired: false,
  );
}

OrbitCircleMember _member({required CircleRole role}) {
  return OrbitCircleMember(
    membershipId: role == CircleRole.owner
        ? 'owner-membership'
        : 'target-membership',
    role: role,
    locationMode: 'hidden',
    canPing: true,
    canMessage: true,
    canViewMoments: true,
    activityVisibility: true,
    userId: 3,
    name: 'Member',
    email: 'member@example.test',
  );
}
