# Orbit Flutter M5 Screen Manifest

| Screen | Route | Source |
|---|---|---|
| Circle Messages | `/circles/{circleId}/messages` | `lib/features/messaging/presentation/pages/circle_messages_page.dart` |
| Messaging Security | `/security/messaging` | `lib/features/messaging/presentation/pages/messaging_security_page.dart` |

## Existing screens extended

- `lib/features/circles/presentation/pages/circle_detail_page.dart` — adds the real Messages entry point.
- `lib/features/profile/presentation/profile_page.dart` — adds Messaging security under Security.
- `lib/app/routing/app_router.dart` — centrally registers both M5 routes.
