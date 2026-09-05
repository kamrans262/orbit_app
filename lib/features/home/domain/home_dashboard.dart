import 'package:flutter/material.dart';

class HomeDashboard {
  const HomeDashboard({
    required this.user,
    required this.circles,
    required this.moments,
    required this.activities,
    required this.upcoming,
  });

  final HomeUser user;
  final List<HomeCircle> circles;
  final List<HomeMoment> moments;
  final List<HomeActivity> activities;
  final List<HomeUpcomingItem> upcoming;

  bool get isEmpty =>
      circles.isEmpty &&
      moments.isEmpty &&
      activities.isEmpty &&
      upcoming.isEmpty;
}

class HomeUser {
  const HomeUser({
    required this.name,
    required this.initials,
    required this.activeCircleCount,
  });

  final String name;
  final String initials;
  final int activeCircleCount;
}

class HomeMember {
  const HomeMember({
    required this.name,
    required this.initials,
    this.isOnline = true,
  });

  final String name;
  final String initials;
  final bool isOnline;
}

class HomeCircle {
  const HomeCircle({
    required this.name,
    required this.memberCount,
    required this.members,
    required this.accent,
    required this.icon,
    required this.alertCount,
    this.mapLabel = 'All calm',
  });

  final String name;
  final int memberCount;
  final List<HomeMember> members;
  final Color accent;
  final IconData icon;
  final int alertCount;
  final String mapLabel;
}

class HomeMoment {
  const HomeMoment({
    required this.owner,
    required this.ownerInitials,
    required this.age,
    required this.circleName,
    required this.accent,
    required this.icon,
    required this.palette,
  });

  final String owner;
  final String ownerInitials;
  final String age;
  final String circleName;
  final Color accent;
  final IconData icon;
  final List<Color> palette;
}

class HomeActivity {
  const HomeActivity({
    required this.title,
    required this.subtitle,
    required this.circleName,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String circleName;
  final Color accent;
  final IconData icon;
}

class HomeUpcomingItem {
  const HomeUpcomingItem({
    required this.title,
    required this.subtitle,
    required this.circleName,
    required this.members,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String circleName;
  final List<HomeMember> members;
  final IconData icon;
  final Color accent;
}
