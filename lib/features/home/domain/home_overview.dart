import '../../presence/domain/presence_snapshot.dart';

class HomeCircleSummary {
  const HomeCircleSummary({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.myMembershipId,
  });

  final String id;
  final String name;
  final int memberCount;
  final String myMembershipId;
}

class HomePresenceMember {
  const HomePresenceMember({
    required this.membershipId,
    required this.userId,
    required this.name,
    required this.status,
    required this.locationMode,
  });

  final String membershipId;
  final int userId;
  final String name;
  final PresenceStatus status;
  final PresenceLocationMode locationMode;
}
