# Orbit Flutter M9 — Profile, Identity, Privacy, Support & Subscription Contract

## Purpose

M9 completes the account/settings surface on top of Orbit's existing consumer APIs. Laravel remains authoritative for identity, session, privacy, deletion/export, content publication and subscription state. Flutter does not call admin APIs and does not invent consumer mutations that the backend does not expose.

## Consumer API contracts used

### Profile

- `GET /api/v1/profile`
- `PATCH /api/v1/profile`

Editable fields are limited to the current backend contract: `name`, `timezone`, and `locale`. Email is displayed as identity information but is not editable because no verified consumer email-change contract exists.

### Identity and session security

- `GET /api/v1/me/devices`
- `PUT /api/v1/me/devices/{deviceId}/name`
- `GET /api/v1/identity/sessions`
- `DELETE /api/v1/identity/sessions/{sessionId}`
- `POST /api/v1/identity/sessions/revoke-others`
- `GET /api/v1/identity/audit-logs`

The current local session is identified from Orbit's secure `SessionStore`; the UI does not offer a revoke button for the current session. Normal secure sign-out remains the current-session exit path. Access tokens, refresh tokens, raw audit metadata and other credentials are never rendered.

### Privacy, data export and account deletion

- `GET /api/v1/identity/privacy`
- `POST /api/v1/identity/data-exports`
- `GET /api/v1/identity/data-exports/{exportId}`
- `GET /api/v1/identity/account-deletion`
- `POST /api/v1/identity/account-deletion`
- `DELETE /api/v1/identity/account-deletion`

Laravel owns the account-deletion lifecycle. A deletion request starts the server-defined **30-day reversible grace period**. Server-side blockers, including ownership requirements, remain authoritative. The destructive mobile confirmation requires the user to type `DELETE`.

The data-export API currently exposes status/expiry and may return a server payload. M9 deliberately does not dump that raw payload into the UI and does not invent a download endpoint. The privacy screen reports the server status and expiry only.

Private message and media plaintext is not expected in the server export because Orbit's private content remains client-side encrypted.

### Subscription

- `GET /api/v1/me/subscription`

M9 subscription is intentionally read-only. The consumer API exposes current plan, billing interval, price snapshot, complimentary state, lifecycle dates and entitlements. It does **not** expose consumer checkout, plan change, cancellation or payment-credential operations. Flutter therefore does not create any of those calls and never handles card/CVV/payment-secret data.

### Help and support content

Orbit's consumer content contract is:

- `GET /api/v1/content/{slug}`

M9 requests the conventional published slug `support` as `GET /api/v1/content/support`. A 404 is a valid empty state: support content has not been published under that slug. The current consumer backend does not expose support-ticket creation, so M9 does not call `/api/admin/...`, does not call an invented `/support/tickets` endpoint, and does not claim a support request was submitted.

## Existing privacy/security screens reused

M9 links rather than duplicates the existing authoritative feature settings:

- Presence & Circle privacy: `/presence`
- Messaging security / E2EE: `/security/messaging`
- Notification preferences: `/notifications/preferences`
- Trusted device approvals: `/security/device-approvals`

## Navigation and primary tabs

The five primary tabs remain exactly:

1. Home
2. Circles
3. Camera
4. Activity
5. Profile

M9 settings screens are protected secondary routes and do not add or reorder primary tabs.

## Retry policy

Reads use the centralized authenticated network client. Idempotent set-value operations such as profile update/device rename and server-idempotent identity operations may allow one centralized auth-refresh retry. The UI itself does not implement blind transport loops.

## Responsive and runtime safety

- Settings bodies are width-constrained on larger phones/tablets and remain scrollable on compact devices.
- `ListTile` widgets inside `OrbitGlassCard` receive their own transparent `Material` ancestor so Flutter ink/background behavior is not hidden by the glass card's `DecoratedBox`.
- Async actions check widget mounting before using `BuildContext` after awaits.
- Loading, error, empty and retry states use Orbit shared UI primitives.

## Explicit M9 boundaries

M9 does not add:

- email-change flows without a backend verification contract;
- consumer subscription checkout or plan mutations;
- payment credential collection;
- admin support APIs;
- fake support ticket submission;
- raw audit metadata rendering;
- raw session/access/refresh token rendering;
- raw data-export payload rendering;
- realtime/push/deep-link infrastructure (M10);
- dependency/plugin modernization such as the `location` built-in Kotlin migration (M11).

## Verification gate

M9 is accepted only when the local Flutter toolchain passes:

1. package/baseline static contract checks;
2. `dart format --output=none --set-exit-if-changed lib test`;
3. `flutter analyze` with `No issues found!`;
4. M9 feature tests;
5. M8 SOS safety regression;
6. complete M1–M9 `flutter test` regression;
7. Android debug APK build;
8. final `Orbit Flutter M9 verification passed.` message.
