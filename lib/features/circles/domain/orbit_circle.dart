enum CircleType {
  standard('standard'),
  temporary('temporary');

  const CircleType(this.apiValue);

  final String apiValue;

  static CircleType parse(Object? value) {
    return switch (value) {
      'standard' => CircleType.standard,
      'temporary' => CircleType.temporary,
      _ => throw FormatException('Unsupported Circle type: $value'),
    };
  }
}

enum CircleRole {
  owner('owner'),
  admin('admin'),
  member('member'),
  restricted('restricted');

  const CircleRole(this.apiValue);

  final String apiValue;

  bool get canManageMembers => this == owner || this == admin;
  bool get canEditCircle => canManageMembers;
  bool get canArchiveCircle => this == owner;
  bool get canLeaveCircle => this != owner;

  static CircleRole parse(Object? value) {
    return switch (value) {
      'owner' => CircleRole.owner,
      'admin' => CircleRole.admin,
      'member' => CircleRole.member,
      'restricted' => CircleRole.restricted,
      _ => throw FormatException('Unsupported Circle role: $value'),
    };
  }
}

class OrbitCircle {
  const OrbitCircle({
    required this.id,
    required this.name,
    required this.type,
    required this.myRole,
    required this.myMembershipId,
    required this.memberCount,
    required this.isArchived,
    required this.isExpired,
    this.description,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final CircleType type;
  final CircleRole myRole;
  final String myMembershipId;
  final int memberCount;
  final DateTime? expiresAt;
  final bool isArchived;
  final bool isExpired;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => !isArchived && !isExpired;
  bool get canEdit => isActive && myRole.canEditCircle;
  bool get canManageMembers => isActive && myRole.canManageMembers;
  bool get canArchive => isActive && myRole.canArchiveCircle;
  bool get canLeave => myRole.canLeaveCircle;
}

class OrbitCircleMember {
  const OrbitCircleMember({
    required this.membershipId,
    required this.role,
    required this.locationMode,
    required this.canPing,
    required this.canMessage,
    required this.canViewMoments,
    required this.activityVisibility,
    required this.userId,
    required this.name,
    required this.email,
    this.joinedAt,
  });

  final String membershipId;
  final CircleRole role;
  final String locationMode;
  final bool canPing;
  final bool canMessage;
  final bool canViewMoments;
  final bool activityVisibility;
  final DateTime? joinedAt;
  final int userId;
  final String name;
  final String email;
}

class OrbitCircleInvite {
  const OrbitCircleInvite({
    required this.id,
    required this.code,
    required this.maxUses,
    required this.usesCount,
    required this.expiresAt,
  });

  final String id;
  final String code;
  final int maxUses;
  final int usesCount;
  final DateTime expiresAt;
}

class CreateCircleInput {
  const CreateCircleInput({
    required this.name,
    required this.type,
    this.description,
    this.expiresAt,
  });

  final String name;
  final String? description;
  final CircleType type;
  final DateTime? expiresAt;
}

class CreateCircleInviteInput {
  const CreateCircleInviteInput({
    required this.expiresInMinutes,
    required this.maxUses,
  });

  final int expiresInMinutes;
  final int maxUses;
}
