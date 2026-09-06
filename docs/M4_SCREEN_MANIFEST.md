# Orbit Flutter M4 — Screen Manifest

| Screen | Route | Flutter file |
| --- | --- | --- |
| Circles list | `/circles` | `lib/features/circles/presentation/circles_page.dart` |
| Create Circle | `/circles/create` | `lib/features/circles/presentation/pages/create_circle_page.dart` |
| Join Circle | `/circles/join` | `lib/features/circles/presentation/pages/join_circle_page.dart` |
| Circle detail | `/circles/{circleId}` | `lib/features/circles/presentation/pages/circle_detail_page.dart` |
| Circle members | `/circles/{circleId}/members` | `lib/features/circles/presentation/pages/circle_members_page.dart` |
| Member access | `/circles/{circleId}/members/{membershipId}` | `lib/features/circles/presentation/pages/circle_member_settings_page.dart` |
| Create invite | `/circles/{circleId}/invite` | `lib/features/circles/presentation/pages/create_circle_invite_page.dart` |
| Circle settings | `/circles/{circleId}/settings` | `lib/features/circles/presentation/pages/circle_settings_page.dart` |

M4 also updates `lib/features/home/presentation/home_page.dart` so Home Circle cards open the real Circle detail screen and the Home `Add Member` quick action enters the Circles workflow.
