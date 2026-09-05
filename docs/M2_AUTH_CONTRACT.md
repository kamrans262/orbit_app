# Orbit Flutter M2 — Authentication Contract Snapshot

This milestone consumes the existing Laravel API. It does not alter the backend contract.

## Passwordless bootstrap

1. `POST /api/v1/auth/email-otp/request`
   - request: `email`
   - response data: `email`, `expires_in_seconds`

2. `POST /api/v1/auth/email-otp/verify`
   - request: `email`, six-digit `otp`, `device_name`
   - response data: `user`, bootstrap `access_token`, `token_type`, `expires_at`

The bootstrap token is used only to register the device and request the hardened Identity session. After a successful Identity upgrade, Flutter makes a best-effort call to `POST /api/v1/auth/logout` with the bootstrap token so it does not remain needlessly active.

## Device registration

`POST /api/v1/devices`

Flutter sends the stable local `client_device_id`, platform, safe device name, app version and OS version. M2 does not invent or publish E2EE key material; that belongs to the messaging/media milestone.

The returned server `device.id` is the canonical `device_id` used by Identity.

## Hardened Identity session

`POST /api/v1/identity/sessions`

Request: `device_id`.

For the first device, Laravel establishes trust and returns:

- `token_type = Bearer`
- `access_token`
- `access_expires_at` — backend policy is 15 minutes
- `refresh_token`
- `refresh_expires_at` — backend policy is 60 days
- `session_id`

Flutter stores this token pair only in `flutter_secure_storage`.

## Additional-device approval

A second untrusted device receives HTTP `409` when requesting the Identity session. Flutter stores the pending bootstrap credential only in secure storage, presents an approval-required screen, and can retry the same Identity issuance after approval.

Trusted devices use:

- `GET /api/v1/identity/device-approvals`
- `POST /api/v1/identity/devices/{deviceId}/approve`
  - request: `approver_device_id`

## Restore / refresh

`POST /api/v1/auth/refresh`

Request:

- `refresh_token`
- server `device_id`

The backend rotates the refresh token family. Flutter serializes concurrent refresh attempts and replaces the entire stored token pair atomically after a successful refresh. Replayed, expired, invalid, or device-mismatched refresh credentials are not retried as if they were valid.

Authenticated restoration validates the user with:

`GET /api/v1/auth/me`

## Logout

Canonical hardened logout:

`POST /api/v1/identity/logout`

Flutter clears the local Identity credentials only after server logout succeeds, or when the backend already reports the credential as unauthorized/forbidden.

## Security boundaries

- No token or OTP is logged.
- Release/production API traffic requires HTTPS.
- Android cleartext HTTP is enabled only in the debug manifest for local Laravel development.
- Business authorization remains server-authoritative.
- The mobile app never talks directly to the database.
