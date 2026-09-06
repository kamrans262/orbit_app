# Orbit Flutter M9 — Screen Manifest

| Screen | Route | Source |
| --- | --- | --- |
| Profile hub | `/profile` | `lib/features/profile/presentation/profile_page.dart` |
| Profile details | `/profile/edit` | `lib/features/profile/presentation/pages/edit_profile_page.dart` |
| Privacy center | `/privacy` | `lib/features/identity/presentation/pages/privacy_center_page.dart` |
| Security & devices | `/security/sessions` | `lib/features/identity/presentation/pages/security_sessions_page.dart` |
| Security activity | `/security/activity` | `lib/features/identity/presentation/pages/security_activity_page.dart` |
| Subscription | `/subscription` | `lib/features/subscription/presentation/subscription_page.dart` |
| Help & support | `/support` | `lib/features/support/presentation/support_page.dart` |

## Existing screens connected by M9

| Existing screen | Route | M9 relationship |
| --- | --- | --- |
| Presence & privacy | `/presence` | Linked from Profile and Privacy Center |
| Notification preferences | `/notifications/preferences` | Linked from Profile and Privacy Center |
| Device approvals | `/security/device-approvals` | Linked from Profile Security section |
| Messaging security | `/security/messaging` | Linked from Profile and Privacy Center |

## Feature architecture

```text
lib/features/profile/
├── data/profile_repository.dart
├── domain/orbit_profile.dart
└── presentation/
    ├── profile_page.dart
    ├── profile_providers.dart
    └── pages/edit_profile_page.dart

lib/features/identity/
├── data/identity_repository.dart
├── domain/identity_models.dart
└── presentation/
    ├── identity_providers.dart
    └── pages/
        ├── privacy_center_page.dart
        ├── security_activity_page.dart
        └── security_sessions_page.dart

lib/features/subscription/
├── data/subscription_repository.dart
├── domain/orbit_subscription.dart
└── presentation/
    ├── subscription_page.dart
    └── subscription_providers.dart

lib/features/support/
├── data/support_repository.dart
├── domain/support_content.dart
└── presentation/
    ├── support_page.dart
    └── support_providers.dart
```
