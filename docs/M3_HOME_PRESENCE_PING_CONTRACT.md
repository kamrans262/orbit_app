# Orbit Flutter M3 — Home, Presence & Ping Contract

This milestone consumes the existing Laravel `/api/v1` contracts without changing backend behavior.

## Home

- `GET /api/v1/circles`
- `GET /api/v1/circles/{circleId}/presence`
- Home no longer uses preview/demo repository data for Circles or presence.
- Circle presence is loaded per visible card through a Riverpod family provider rather than issuing a large eager request fan-out at Home startup.

## Presence

- `GET /api/v1/presence/me`
- `PUT /api/v1/presence`
- `PATCH /api/v1/presence/settings`
- `GET /api/v1/circles/{circleId}/members`
- `PATCH /api/v1/circles/{circleId}/members/{membershipId}` for the authenticated member's own privacy fields.

Privacy behavior remains server-authoritative:

- precise
- approximate
- hidden
- Circle ghost
- Global Ghost Mode

Global Ghost Mode is never implemented as a UI-only flag. The app calls the existing Laravel privacy endpoint, which clears and suppresses server-side presence metadata according to the established contract.

M3 requests foreground location only after an explicit user action. It does **not** request background location permission and does not implement background tracking.

## Ping

- `GET /api/v1/pings/inbox`
- `GET /api/v1/pings/sent`
- `POST /api/v1/pings`
- `POST /api/v1/pings/{pingId}/respond`
- `POST /api/v1/pings/{pingId}/dismiss`

The client preserves Laravel rules for:

- self-Ping prevention
- recipient `can_ping` privacy
- Circle membership boundaries
- cooldown/rate limits
- short-lived expiration
- recipient-only responses
- `hey` and `share_location` response intents

Ping mutation requests are deliberately not automatically replayed after an authentication failure because they are not inherently safe to duplicate. The centralized Identity session still refreshes before requests when the access token is near expiry.

## Platform permissions

M3 adds only foreground location permissions:

- Android `ACCESS_COARSE_LOCATION`
- Android `ACCESS_FINE_LOCATION`
- iOS `NSLocationWhenInUseUsageDescription`

Android `ACCESS_BACKGROUND_LOCATION`, iOS always-location usage descriptions, and background location modes are intentionally absent.
