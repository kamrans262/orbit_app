# Orbit Flutter M8 Screen Manifest

| Screen | Route | Source |
| --- | --- | --- |
| Emergency SOS | `/sos` | `lib/features/sos/presentation/pages/sos_activation_page.dart` |
| SOS Incident | `/sos/{sosId}` | `lib/features/sos/presentation/pages/sos_incident_page.dart` |

## Existing screens extended

| Existing screen | M8 change | Source |
| --- | --- | --- |
| Home | Quick SOS and floating SOS open the real activation flow | `lib/features/home/presentation/home_page.dart` |
| Home SOS action | Accessibility hint updated from placeholder to real flow | `lib/features/home/presentation/widgets/sos_floating_action.dart` |
| Notifications | SOS kinds derive a safe internal incident route | `lib/features/notifications/domain/orbit_notification.dart` |
| Router | Registers activation and incident routes | `lib/app/routing/app_router.dart` |

## Main feature architecture

```text
lib/features/sos/
├── data/
│   ├── sos_local_state_store.dart
│   └── sos_repository.dart
├── domain/
│   └── sos_models.dart
└── presentation/
    ├── sos_providers.dart
    ├── pages/
    │   ├── sos_activation_page.dart
    │   └── sos_incident_page.dart
    └── widgets/
        ├── sos_hold_button.dart
        ├── sos_responder_card.dart
        └── sos_status_card.dart
```
