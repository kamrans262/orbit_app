import 'orbit_circle.dart';

abstract final class CirclePermissions {
  static bool canChangeRole({
    required OrbitCircle circle,
    required OrbitCircleMember target,
  }) {
    if (!circle.isActive || !circle.myRole.canManageMembers) {
      return false;
    }
    if (target.membershipId == circle.myMembershipId ||
        target.role == CircleRole.owner) {
      return false;
    }
    if (circle.myRole == CircleRole.admin) {
      return target.role != CircleRole.admin;
    }
    return true;
  }

  static List<CircleRole> assignableRoles({
    required OrbitCircle circle,
    required OrbitCircleMember target,
  }) {
    if (!canChangeRole(circle: circle, target: target)) {
      return const <CircleRole>[];
    }
    if (circle.myRole == CircleRole.admin) {
      return const <CircleRole>[CircleRole.member, CircleRole.restricted];
    }
    return const <CircleRole>[
      CircleRole.admin,
      CircleRole.member,
      CircleRole.restricted,
    ];
  }

  static bool canRemove({
    required OrbitCircle circle,
    required OrbitCircleMember target,
  }) {
    if (!circle.isActive || !circle.myRole.canManageMembers) {
      return false;
    }
    if (target.membershipId == circle.myMembershipId ||
        target.role == CircleRole.owner) {
      return false;
    }
    if (circle.myRole == CircleRole.admin && target.role == CircleRole.admin) {
      return false;
    }
    return true;
  }
}
