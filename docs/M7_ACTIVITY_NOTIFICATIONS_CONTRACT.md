# Orbit Flutter M7 — Activity + Notifications Contract

## Purpose

M7 replaces the Activity placeholder with the real Laravel-backed Activity feed and adds the authenticated in-app notification inbox, notification preferences and targeted consumer announcements.

The Flutter client consumes existing Laravel `/api/v1` contracts. M7 does not add, rename, weaken or emulate backend authorization rules.

## Activity API

- `GET /api/v1/activity/feed`
  - cursor pagination
  - `limit` max 50
  - Laravel returns only activity from Circles the authenticated user can currently access
  - Laravel excludes removed sources and the user's hidden activity items
- `POST /api/v1/activity/{activityId}/hide`
  - idempotent per-user hide
  - only affects the requesting user's feed
- `POST /api/v1/activity/{activityId}/report`
  - reasons: `spam`, `harassment`, `safety`, `other`
  - optional details max 500 characters
  - backend report creation is idempotent per user/activity item

Known backend Activity types are presented semantically:

- `moment.published`
- `member.joined`
- `member.left`
- `alert.sos_activated`
- `alert.sos_escalated`
- `alert.sos_resolved`

Unknown future types degrade to a safe generic Activity presentation rather than crashing.

## Notification API

- `GET /api/v1/notifications`
  - max 50 visible in-app notifications
  - consumes backend `meta.unread_count`
- `POST /api/v1/notifications/{notificationId}/read`
  - idempotent
- `POST /api/v1/notifications/read-all`
  - idempotent bulk read for the authenticated user
- `GET /api/v1/notifications/preferences`
- `PUT /api/v1/notifications/preferences`
  - `push_enabled`
  - `in_app_enabled`
  - `messages_enabled`
  - `moments_enabled`
  - `pings_enabled`
  - `activity_enabled`
  - `quiet_hours_enabled`
  - `quiet_hours_start`
  - `quiet_hours_end`
  - `timezone`
- `PUT /api/v1/notifications/circles/{circleId}`
  - supports backend `muted_until` / `silent` mutation contract
  - M7 intentionally does not expose a persistent per-Circle settings screen because the current backend provides no corresponding read endpoint to reliably reflect that state

## Consumer announcements

- `GET /api/v1/communications/announcements`
- Laravel remains authoritative for:
  - publication state
  - scheduling window
  - audience targeting
  - locale selection / published-English fallback
  - priority
  - security-announcement publication controls

M7 renders only the consumer fields returned by Laravel: id, type, priority, dismissible, deep link metadata, title, body, start and end timestamps.

There is no client-side audience recreation.

## Privacy and security boundaries

- Notification UI renders the server-safe `summary`; it never renders arbitrary notification payload values as message content.
- Encrypted message notifications remain metadata-only. M7 does not decrypt message previews in the notification inbox.
- Laravel remains authoritative for notification preference routing, Circle mutes, quiet hours and SOS emergency bypass behavior.
- M7 never trusts or executes arbitrary `deep_link` strings from the server. In-app navigation is derived only for a small allowlisted set of already-built routes (`ping.received`, `message.received`, `moment.published`).
- External push/deep-link ingestion, universal/app links and realtime delivery remain M10 scope.
- Push provider registration is not faked in M7. `push_enabled` is the existing server preference only.
- Activity hide/report and notification read/preference updates use only idempotent backend mutations when auth retry is enabled.

## Home integration

Home's Smart Activity section uses the same Activity repository with a three-item preview. The full Activity tab remains the source for pagination, hide and report actions.

## Error and UX states

M7 includes:

- loading states
- empty states
- connection/server error states
- pull-to-refresh
- Activity cursor pagination
- retry-safe load-more behavior
- per-item busy states
- destructive hide confirmation
- report validation bounded to the backend's 500-character limit
- responsive compact-phone and large-width constraints

## Deferred to later milestones

- M8: full SOS responder / incident experience
- M9: remaining profile/account/privacy/support/subscription controls
- M10: Reverb realtime delivery, push token lifecycle, push providers, notification-open routing and external deep links
- M11: release hardening, localization completion, performance, accessibility and store readiness
