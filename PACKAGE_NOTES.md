Orbit Flutter UI Runtime Polish v3

Scope: UI/runtime corrections only. No Laravel overlay.

v3 repair:
- keeps the v1 null-safety fix by pinning the validated Circle to `activeCircle` inside `_capture`.
- fixes the v2 regression where `_finishVideo(OrbitCircle circle)` incorrectly referenced `activeCircle` outside its scope; video review now uses the method's `circle` parameter.
- reuses the earliest UI-polish rollback checkpoint instead of backing up partial v1/v2 states.

Modified runtime files:
- lib/features/profile/presentation/pages/edit_profile_page.dart
- lib/features/notifications/presentation/pages/notification_preferences_page.dart
- lib/features/home/presentation/widgets/home_header.dart
- lib/features/home/presentation/widgets/quick_actions.dart
- lib/features/home/presentation/widgets/sos_floating_action.dart
- lib/features/camera/presentation/camera_page.dart

Added regression contract:
- test/features/ui_polish/ui_polish_source_contract_test.dart

No changes to:
- backend APIs or migrations
- authentication/device trust policy
- E2EE
- Firebase provider credentials
- Reverb contracts
- SOS server authority/fallback behavior
