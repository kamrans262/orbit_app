import 'package:flutter/material.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../domain/home_dashboard.dart';
import '../domain/home_repository.dart';

class PreviewHomeRepository implements HomeRepository {
  const PreviewHomeRepository();

  @override
  Future<HomeDashboard> loadDashboard() async {
    return const HomeDashboard(
      user: HomeUser(name: 'Maya', initials: 'M', activeCircleCount: 3),
      circles: <HomeCircle>[
        HomeCircle(
          name: 'Family',
          memberCount: 5,
          members: <HomeMember>[
            HomeMember(name: 'Maya', initials: 'M'),
            HomeMember(name: 'Chris', initials: 'C'),
            HomeMember(name: 'Ana', initials: 'A'),
          ],
          accent: OrbitColors.primary,
          icon: Icons.groups_2_rounded,
          alertCount: 3,
        ),
        HomeCircle(
          name: 'Close Friends',
          memberCount: 4,
          members: <HomeMember>[
            HomeMember(name: 'Leo', initials: 'L'),
            HomeMember(name: 'Maya', initials: 'M'),
            HomeMember(name: 'Nora', initials: 'N'),
          ],
          accent: OrbitColors.purple,
          icon: Icons.groups_2_rounded,
          alertCount: 2,
        ),
        HomeCircle(
          name: 'Weekend Trip',
          memberCount: 6,
          members: <HomeMember>[
            HomeMember(name: 'Chris', initials: 'C'),
            HomeMember(name: 'Maya', initials: 'M'),
            HomeMember(name: 'Leo', initials: 'L'),
          ],
          accent: OrbitColors.teal,
          icon: Icons.terrain_rounded,
          alertCount: 0,
        ),
      ],
      moments: <HomeMoment>[
        HomeMoment(
          owner: 'Maya',
          ownerInitials: 'M',
          age: '12m',
          circleName: 'Family',
          accent: OrbitColors.primary,
          icon: Icons.groups_2_rounded,
          palette: <Color>[Color(0xFFF0A45B), Color(0xFF685C7F)],
        ),
        HomeMoment(
          owner: 'Leo',
          ownerInitials: 'L',
          age: '28m',
          circleName: 'Close Friends',
          accent: OrbitColors.purple,
          icon: Icons.groups_2_rounded,
          palette: <Color>[Color(0xFF70984D), Color(0xFF283E2B)],
        ),
        HomeMoment(
          owner: 'Ana',
          ownerInitials: 'A',
          age: '1h',
          circleName: 'Family',
          accent: OrbitColors.primary,
          icon: Icons.groups_2_rounded,
          palette: <Color>[Color(0xFFB76E63), Color(0xFF34456E)],
        ),
        HomeMoment(
          owner: 'Chris',
          ownerInitials: 'C',
          age: '2h',
          circleName: 'Weekend Trip',
          accent: OrbitColors.teal,
          icon: Icons.terrain_rounded,
          palette: <Color>[Color(0xFF5C7088), Color(0xFF1B2737)],
        ),
      ],
      activities: <HomeActivity>[
        HomeActivity(
          title: 'Ana arrived at Home',
          subtitle: 'Today at 7:28 PM',
          circleName: 'Family',
          accent: OrbitColors.teal,
          icon: Icons.home_rounded,
        ),
        HomeActivity(
          title: "Leo's battery is low",
          subtitle: '20% remaining • 12m ago',
          circleName: 'Close Friends',
          accent: OrbitColors.warning,
          icon: Icons.battery_2_bar_rounded,
        ),
        HomeActivity(
          title: 'Trip starts in 2 hours',
          subtitle: 'Sat, Nov 16 • 10:00 AM',
          circleName: 'Weekend Trip',
          accent: OrbitColors.textSecondary,
          icon: Icons.calendar_month_rounded,
        ),
      ],
      upcoming: <HomeUpcomingItem>[
        HomeUpcomingItem(
          title: 'Dinner at Casa Luna',
          subtitle: 'Today • 8:00 PM',
          circleName: 'Family',
          members: <HomeMember>[
            HomeMember(name: 'Maya', initials: 'M'),
            HomeMember(name: 'Ana', initials: 'A'),
            HomeMember(name: 'Chris', initials: 'C'),
          ],
          icon: Icons.calendar_today_rounded,
          accent: OrbitColors.primary,
        ),
        HomeUpcomingItem(
          title: 'Weekend Trip to Tahoe',
          subtitle: 'Sat, Nov 16 • 10:00 AM',
          circleName: 'Weekend Trip',
          members: <HomeMember>[
            HomeMember(name: 'Maya', initials: 'M'),
            HomeMember(name: 'Chris', initials: 'C'),
            HomeMember(name: 'Leo', initials: 'L'),
          ],
          icon: Icons.flight_rounded,
          accent: OrbitColors.teal,
        ),
      ],
    );
  }
}
