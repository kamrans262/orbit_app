# Orbit Flutter M10 Screen Manifest

## New route-level screens

**No new route-level screens were created in M10.** This milestone is intentionally infrastructure-first.

## Existing screen enhanced

### Circle Messages
- Route: `/circles/{circleId}/messages`
- Source: `lib/features/messaging/presentation/pages/circle_messages_page.dart`
- M10 enhancement: ephemeral realtime typing indicator driven by Laravel `typing.updated` events, plus Laravel `message.delivered` receipts updating the existing outgoing double-check status.
- Security: existing M5 E2EE send/sync/decrypt flow is unchanged; realtime never displays ciphertext or decrypts inside the transport.

### SOS Incident
- Route: `/sos/{sosId}`
- Source: `lib/features/sos/presentation/pages/sos_incident_page.dart`
- M10 enhancement: requests the protected `orbit.sos.{sosId}` Reverb channel while open and retries only after Laravel confirms an engaged responder.
- Fallback: existing 15-second polling remains.
- Safety: backend authorization, foreground-only location sharing, originator-only resolution, and M8 SOS rules are unchanged.

## App-level infrastructure (not screens)

- `lib/features/realtime/presentation/orbit_realtime_bridge.dart` — authenticated runtime lifecycle, channel orchestration, event refresh dispatch, deep-link routing, push token lifecycle.
- `lib/features/realtime/data/reverb_realtime_client.dart` — Reverb/Pusher transport, private-channel auth, reconnect, subscription management.
- `lib/features/deep_links/domain/orbit_deep_link_resolver.dart` — centralized destination allowlist.
- `lib/features/deep_links/data/app_links_ingress.dart` — cold-start/foreground OS URI ingress plus push-open URI ingress.
- `lib/features/push/data/device_push_registration_service.dart` — complete device upsert preserving E2EE identity.
- `lib/features/push/domain/push_token_source.dart` — provider-neutral mobile push adapter boundary.
