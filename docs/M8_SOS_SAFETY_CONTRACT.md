# Orbit Flutter M8 — SOS Safety Experience Contract

## Authority boundary

Laravel remains authoritative for Circle membership, SOS event state, responder eligibility, responder status, escalation stage, resolution, rate limits, and sensitive-data visibility. Flutter never manufactures responder permissions or escalation success.

Consumer routes used exactly as already implemented by Laravel:

- `POST /api/v1/sos/activate`
- `GET /api/v1/sos/{sosId}`
- `POST /api/v1/sos/{sosId}/respond`
- `PUT /api/v1/sos/{sosId}/location`
- `PUT /api/v1/sos/{sosId}/recording`
- `POST /api/v1/sos/{sosId}/resolve`

## Activation safety

- The app requires a continuous three-second hold before calling the activation endpoint.
- Flutter supplies a client UUID so activation retries retain Laravel's idempotency contract.
- Current location is optional; a permission or location-service failure must never block SOS activation.
- The UI explicitly explains that SOS location is separate from ordinary Presence/Ghost privacy.
- Orbit does not auto-dial emergency services and does not claim that stage-2 provider fallback was delivered when Laravel reports only `pending_provider`.
- The server's `sos_activation_rate_limited` response is surfaced with direct emergency-channel guidance rather than being hidden or bypassed.

## Responder safety

- Only Laravel-listed responders can engage or decline.
- The originator cannot respond to their own incident.
- Engaged responders and the originator may opt into foreground live SOS location updates.
- Live updates are approximately one sample per second while the incident screen remains open.
- Background location permission is not added by M8.
- Realtime Reverb subscription remains M10 scope; M8 uses bounded 15-second polling while the incident screen is visible.

## Local recovery

The current active SOS identifier is kept in `flutter_secure_storage` with the authenticated user ID. On the activation screen, Flutter validates the saved identifier against Laravel when connectivity is available. Resolved/missing incidents are cleared. During a temporary network outage, the local recovery pointer is retained so the user does not lose the incident entry point.

## Mutation retry rules

- Activation: auth retry allowed because the client-generated SOS UUID makes the backend contract idempotent.
- Responder engage/decline: auth retry allowed because the backend responder transition is idempotent and the responder hotfix suppresses duplicate engaged events.
- Location update: auth retry allowed because the latest sample replaces the prior sample.
- Resolution: auth retry allowed because Laravel resolution is idempotent.
- Recording attachment: automatic auth replay disabled because the existing endpoint has no dedicated client idempotency key.

## Encrypted recording boundary

Laravel accepts only an opaque `recording_ref`; it never accepts plaintext audio bytes. The repository contract for attaching an already-encrypted recording reference is included, but M8 intentionally does **not** fake AAC capture/upload. The current M6 encrypted-media consumer flow is Moment photo/video-oriented and no approved SOS-audio media contract/provider is present in the recovered backend. A future implementation must create ciphertext through the encrypted media path before calling the SOS recording endpoint.

## Notifications and navigation

M8 extends the existing M7 allowlist so trusted SOS notification kinds derive `/sos/{sosId}` only from the `sos_id` payload. Arbitrary server `deep_link` values are still never executed.

## Deferred to later milestones

- Reverb/private-channel realtime receive and event deduplication: M10.
- APNS/FCM high-priority push delivery: M10.
- Provider-backed stage-2 SMS delivery: backend/provider deployment dependent.
- Background WorkManager/BGTask location/upload retry: M11 production-readiness work after an explicit background-permission/product decision.
- Emergency-services auto-dial: deliberately absent from Orbit v1.
