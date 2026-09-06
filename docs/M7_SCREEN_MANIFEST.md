# Orbit Flutter M7 Screen Manifest

| Screen | Route | Source |
|---|---|---|
| Activity | `/activity` | `lib/features/activity/presentation/activity_page.dart` |
| Notifications | `/notifications` | `lib/features/notifications/presentation/notifications_page.dart` |
| Notification preferences | `/notifications/preferences` | `lib/features/notifications/presentation/pages/notification_preferences_page.dart` |
| Announcement detail | `/announcements/{announcementId}` | `lib/features/notifications/presentation/pages/announcement_detail_page.dart` |

## Existing screens extended

| Screen | M7 change | Source |
|---|---|---|
| Home | Real Smart Activity preview backed by `/api/v1/activity/feed?limit=3` | `lib/features/home/presentation/home_page.dart` |
| Profile | Notification preferences entry | `lib/features/profile/presentation/profile_page.dart` |
| App router | Registers notification/preference/announcement routes while preserving the five indexed shell branches | `lib/app/routing/app_router.dart` |

## M7 feature architecture

```text
lib/features/activity/
├── data/activity_repository.dart
├── domain/activity_item.dart
└── presentation/
    ├── activity_page.dart
    ├── activity_providers.dart
    └── widgets/activity_card.dart

lib/features/notifications/
├── data/notifications_repository.dart
├── domain/orbit_notification.dart
└── presentation/
    ├── notification_providers.dart
    ├── notifications_page.dart
    ├── pages/
    │   ├── announcement_detail_page.dart
    │   └── notification_preferences_page.dart
    └── widgets/
        ├── announcement_card.dart
        ├── notification_bell_button.dart
        └── notification_card.dart
```
