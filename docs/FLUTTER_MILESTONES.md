# Orbit Flutter Mobile — 11 Milestones

The current Flutter plan contains **11 milestones total**. M1 absorbs the original foundation/app-shell work; M2 is the authentication milestone in this package.

1. **M1 — UI Foundation + Authenticated App Shell** — design system, five-tab shell, reference Home composition, reusable states/components.
2. **M2 — Authentication & Account Bootstrap** — Email OTP, secure device registration, hardened Identity session upgrade, rotating refresh, restore, trusted-device approval and secure logout.
3. **M3 — Home, Presence & Ping** — real dashboard summary, privacy-safe presence/location modes, Ghost Mode, Ping flows.
4. **M4 — Circles** — circle list/detail/create/join/invites, memberships, roles, privacy permissions and member context.
5. **M5 — Messaging & Client-side E2EE** — client key lifecycle, encrypted envelopes, sync, receipts, typing and recovery; Laravel never receives plaintext message content.
6. **M6 — Camera, Encrypted Media & Moments** — capture, client encryption, resumable upload, per-device envelopes, decrypt/download, Moments lifecycle.
7. **M7 — Activity & Notifications** — activity feed, reporting/hide flows, notification center/preferences, announcements and safe deep-link destinations.
8. **M8 — SOS Safety Experience** — activation, live incident state, responders, location updates, encrypted recording reference, escalation and resolution.
9. **M9 — Profile, Identity, Privacy, Support & Subscription** — profile, devices/sessions/trust, privacy summary, export/deletion, support, entitlements, legal/regional/config surfaces.
10. **M10 — Realtime, Push & Deep Links** — Laravel Reverb/private channels, reconnect/backoff, push-token lifecycle, notification routing, event dedupe and background lifecycle.
11. **M11 — Production Mobile Readiness** — accessibility, adaptive layouts, localization, performance/memory, offline resilience, observability, Android/iOS security, signing/store/release regression.

Every milestone must preserve the existing Laravel contracts and must end with `flutter analyze` reporting no issues and `flutter test` reporting all tests passed before it is accepted.
