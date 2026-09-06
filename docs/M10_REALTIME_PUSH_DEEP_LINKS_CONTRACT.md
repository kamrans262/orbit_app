# Orbit Flutter M10 — Realtime + Push + Deep Links Contract

## Scope demand

M10 adds contract-driven realtime delivery, provider-neutral push-token lifecycle seams, and safe app deep-link handling on top of the completed M1–M9 Flutter application. It does not redesign existing screens, invent backend endpoints, replace the durable notification inbox, weaken trusted-device security, or move encryption/privacy authority away from existing layers.

## Realtime transport

- Laravel Reverb is the only realtime transport.
- The client speaks the Pusher protocol over `web_socket_channel` and authenticates private channels through the existing Laravel `POST /api/broadcasting/auth` Sanctum route.
- Realtime channel auth reuses the central `DioOrbitApiClient` and its existing identity-session refresh machinery. A second token/auth stack is not introduced.
- Production Reverb configuration requires WSS. Local development may use WS.
- If `ORBIT_REVERB_APP_KEY` is empty, realtime is disabled and all existing refresh/polling paths remain functional.
- Reconnect uses bounded exponential backoff. Foreground resume refreshes durable notification/activity sources.

### Subscribed backend channels

Authenticated runtime subscriptions are derived from server-authenticated identity and Laravel Circle membership data:

- `private-users.{userId}`
- `private-devices.{serverDeviceId}`
- `private-orbit.user.{userId}`
- `private-circles.{circleId}` for current Circle memberships
- `private-orbit.circle.{circleId}` for current Circle memberships
- `private-orbit.sos.{sosId}` only as a requested protected subscription while an SOS incident page is open; Laravel remains the authority and authorizes only the originator or an engaged responder.

No client-side channel name grants access. Laravel channel authorization remains authoritative.

## E2EE preservation

Message realtime is only an acceleration/wake-up path. `message.received` carries the existing encrypted envelope shape from Laravel, and M10 does not decrypt it in the Reverb transport or log/read raw ciphertext. The existing M5 `MessagingService` remains the sole path that syncs the authenticated envelope, decrypts on-device, persists encrypted local state, and acknowledges delivery. Laravel `message.delivered` receipts update only the encrypted local message status; delivered state is monotonic so a later send/REST completion cannot downgrade an already-delivered message.

E2EE public identity is also preserved during push registration. Laravel's device upsert can null omitted fields, so M10's device push synchronization always includes the current `public_identity_key` together with `push_token`. A token refresh/unregister therefore cannot silently erase the device encryption identity. The successfully registered token is kept only in `flutter_secure_storage`, and the existing M5 identity-publishing upsert reads that secure token back so a later messaging bootstrap cannot erase push registration either. Sign-out explicitly unregisters the server push token while the Sanctum identity session is still valid, then performs the existing identity logout; M10 does not generate a fresh E2EE identity merely to unregister a token.

## Presence privacy

Presence remains server-authoritative. M10 subscribes to Laravel's `presence.updated` signal only to invalidate/refetch the existing Circle presence provider. It does not trust or render a raw client-generated location payload and does not bypass Global Ghost Mode or per-Circle privacy decisions.

## SOS safety

- SOS activation/resolve Circle events use the existing `private-orbit.circle.{circleId}` contract.
- Per-incident location/responder/escalation events use `private-orbit.sos.{sosId}` and Laravel authorization remains mandatory.
- A pending responder does not gain incident-channel access merely by opening the screen. After Laravel confirms `engaged`, the client retries the private incident subscription.
- The existing 15-second incident polling timer is intentionally retained as a polling fallback when Reverb is unavailable/suspended/unauthorized.
- Existing foreground-only SOS location behavior, originator-only resolution, responder authorization, recording safety, and all M8 rules remain unchanged.

## Durable notifications and deduplication

`notification.created` never creates a second local notification record. It only refreshes the existing M7 durable Laravel notification inbox. This keeps read/unread state and server idempotency authoritative and avoids duplicate realtime/push/inbox cards.

## Push boundary

The authoritative Laravel backend intentionally stops at a provider-neutral `notification_deliveries` boundary with `pending_provider`; it does not contain a real APNS/FCM sender. Therefore M10 does **not** fabricate remote push delivery or hard-code Firebase/APNS credentials.

M10 creates:

- `PushTokenSource`, an injectable provider adapter contract for token acquisition, token rotation/removal, and notification-open URIs.
- `DevicePushRegistrationService`, which securely registers, rotates, and unregisters tokens through existing `/api/v1/devices` while preserving E2EE public identity.
- `UnavailablePushTokenSource`, the safe default. It reports unavailable and does not clear an existing backend token merely because no concrete provider adapter is installed.
- push-open deep-link ingress wired into the same centralized allowlist as OS custom-scheme links.

A future provider adapter can be supplied through Riverpod without changing Laravel contracts or the rest of M10. Actual APNS/FCM sender/provider completion is explicitly not faked here.

## Deep-link allowlist

Only the backend-emitted Orbit custom scheme is accepted. Query strings/fragments and unknown destinations are rejected.

Allowed backend forms and internal routes:

- `orbit://circles/{circleId}/chat` → `/circles/{circleId}/messages`
- `orbit://moments/{momentId}` → `/moments/{momentId}`
- `orbit://pings/{pingId}` → `/pings`
- `orbit://sos/{sosId}` → `/sos/{sosId}`

All `{circleId}`, `{momentId}`, `{pingId}`, and `{sosId}` values must be canonical UUID-shaped identifiers because the authoritative Laravel schema stores these resource primary keys as UUIDs. Arbitrary slugs, normalized traversal remnants, extra path segments, query strings, and fragments are rejected before router navigation.

Links are validated against the allowlist before they can be deferred. Valid links are deferred until the app is authenticated. Cold-start and stream delivery of the same URI are suppressed for a short duplicate window. Destination screens then load from authenticated Laravel endpoints, so Circle/SOS authorization remains server-authoritative. Arbitrary server `deep_link` strings are not executed.

Android and iOS register only the `orbit://` custom scheme. Flutter's built-in deep-link dispatcher is disabled for these native targets so `app_links` owns the ingress consistently.

## Realtime event integrations

- Messaging: `message.received`, `message.delivered`, `message.read`, `typing.updated`
- Presence: `presence.updated`
- Ping: `ping.received`, `ping.responded`
- Moments: `moment.published`, `moment.deleted`, `moment.viewed`
- Activity: `activity.created`, `activity.removed`
- Notifications: `notification.created`
- SOS: `sos.activated`, `sos.location.updated`, `sos.responder.engaged`, `sos.escalated`, `sos.resolved`

Events invalidate/refetch existing authoritative repositories rather than inventing duplicate client state.

## Configuration

Flutter Dart defines:

- `ORBIT_REVERB_APP_KEY` — public Reverb app key; empty disables realtime.
- `ORBIT_REVERB_HOST` — optional; defaults to API host.
- `ORBIT_REVERB_PORT` — optional; defaults to `8080` for WS and `443` for WSS.
- `ORBIT_REVERB_SCHEME` — `ws` or `wss`; production requires `wss`.

The Flutter `ORBIT_REVERB_APP_KEY` must match Laravel `REVERB_APP_KEY`. Reverb secrets are backend-only and must never be placed in Flutter Dart defines.

For a physical Android device with local services, reverse both API and Reverb ports:

```powershell
adb reverse tcp:8000 tcp:8000
adb reverse tcp:8080 tcp:8080
```

Then use `127.0.0.1` for the local API/Reverb host on the device.

## Verification gate

M10 verification requires:

1. M9 baseline static checks.
2. Read-only Laravel Reverb/channel/device/notification contract checks.
3. Dependency resolution and formatting.
4. `flutter analyze` before milestone tests.
5. M10 realtime/push/deep-link tests.
6. Messaging/E2EE, Presence/Ping, Notifications, Moments/Activity, and SOS regressions.
7. Complete M1–M10 Flutter regression suite.
8. Android debug APK build, which also validates Android plugin/deep-link integration.
9. Native Android/iOS deep-link static checks, including proof that Flutter's built-in deep-link dispatcher is disabled for `app_links`.
10. Push sign-out unregister, E2EE identity-preservation, and delivery-receipt static contracts.

## Deferred to M11 / provider-specific work

M10 does not alter the previously deferred `location` Kotlin Gradle Plugin warning. Dependency churn remains deferred to M11 unless it becomes a build blocker.

Actual provider delivery requires a deliberate APNS/FCM backend sender plus a concrete mobile `PushTokenSource` implementation. That work must preserve this provider-neutral contract rather than being simulated.
