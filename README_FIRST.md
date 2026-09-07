# Orbit Flutter UI Runtime Polish v3

Focused patch for the reported runtime/UI issues after M10P:

- Profile Details red-screen correction.
- Notification Preferences red-screen correction.
- Remove home mission tagline + heart.
- Quick actions: three visible cards + horizontal scroll.
- Floating SOS: one visible SOS label.
- Camera preview: aspect-preserving cover instead of stretched output.
- v3 repair: preserves the non-null `activeCircle` only in `_capture`, while `_finishVideo(OrbitCircle circle)` correctly uses its own non-null `circle` parameter. This fixes the v2 undefined-identifier analyzer error without weakening the v1 null-safety repair.

## Install

Copy this package into the Flutter project root, then run:

```powershell
Set-Location "C:\laravel-projects\orbit_app"
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install-orbit-ui-runtime-polish-v3.ps1 -FlutterProjectPath "C:\laravel-projects\orbit_app"
```

## Verify

```powershell
.\tool\verify-ui-runtime-polish-v3.ps1 -FlutterProjectPath "C:\laravel-projects\orbit_app"
```

The installer reuses the earliest existing `.orbit-backups\ui-runtime-polish-*` checkpoint when repairing a partial v1 install, so the original pre-polish baseline remains authoritative.
