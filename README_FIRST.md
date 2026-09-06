# Orbit Flutter M10 — Realtime + Push + Deep Links

This package installs **M10 only** on the already-green M1–M9 Orbit Flutter project. It does not replace the Laravel backend and does not redo completed milestones.

## Install

From the extracted package directory in PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install-orbit-flutter-m10.ps1
```

The installer:

1. verifies this package's SHA-256 manifest;
2. verifies the final M9 baseline;
3. validates Laravel Reverb/channel/device contracts read-only;
4. creates `.orbit-backups\ui-m10-<timestamp>`;
5. overlays M10 source/tests/docs;
6. adds only `app_links:^7.2.1` and `web_socket_channel:^3.0.3` (it does not intentionally upgrade existing pins such as `flutter_secure_storage`);
7. safely configures Android/iOS `orbit://` deep links;
8. formats Dart and runs `flutter analyze` early.

If installation fails after the checkpoint, rollback with:

```powershell
.\rollback-latest-m10.ps1
```

## Configure local Reverb

The backend already owns Reverb. Start Laravel normally, then in a second backend terminal:

```powershell
php artisan reverb:start --debug
```

Use the same public value as Laravel's `REVERB_APP_KEY` in Flutter. Never copy `REVERB_APP_SECRET` into the app.

Example local Flutter defines:

```text
--dart-define=ORBIT_REVERB_APP_KEY=<same public Reverb app key>
--dart-define=ORBIT_REVERB_HOST=127.0.0.1
--dart-define=ORBIT_REVERB_PORT=8080
--dart-define=ORBIT_REVERB_SCHEME=ws
```

For an Android USB device using local Laravel/Reverb:

```powershell
adb reverse tcp:8000 tcp:8000
adb reverse tcp:8080 tcp:8080
```

Realtime is intentionally disabled if `ORBIT_REVERB_APP_KEY` is omitted, and existing polling/refresh behavior keeps working.

## Verify

From `C:\laravel-projects\orbit_app`:

```powershell
.\tool\verify-ui-m10.ps1
```

The verifier runs analyzer first, focused M10 tests, all security/privacy regressions, the complete M1–M10 suite, and an Android debug build.

## Push status

The authoritative Laravel backup has a provider-neutral notification delivery outbox but no real APNS/FCM sender. M10 therefore implements secure token lifecycle/provider injection and push-open routing without pretending remote push delivery is live. See `docs\M10_REALTIME_PUSH_DEEP_LINKS_CONTRACT.md`.


### Retry after FINAL v2 analyzer failure
If FINAL v2 failed with hundreds of `overlay\lib\...` URI errors, do not rollback first. Copy FINAL v3 over the project and rerun the installer. The existing pre-M10 checkpoint is reused and the staging overlay is removed before analysis.

FINAL v4 tightens all backend resource deep links to UUID-shaped identifiers, matching Laravel schema and fixing the final deep-link verifier regression.
