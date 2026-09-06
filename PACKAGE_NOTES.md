# Package notes

- Milestone: Orbit Flutter M10 — Realtime + Push + Deep Links
- Baseline: final green M9 only
- Backend changes: none; Laravel contracts are validated read-only
- New runtime dependencies: `app_links:^7.2.1`, `web_socket_channel:^3.0.3`
- New route-level screens: none
- Existing screens enhanced: Circle Messages, SOS Incident
- E2EE: preserved; message realtime remains encrypted-envelope wake-up only
- Presence: server-authoritative; realtime only invalidates/refetches server privacy-filtered data
- SOS: protected incident channel plus retained 15-second polling fallback
- Deep links: centralized strict allowlist; arbitrary URLs are rejected
- Push: provider-neutral token lifecycle and open-routing seam; no fake APNS/FCM sender
- Rollback: latest `.orbit-backups\ui-m10-*` checkpoint


## FINAL v3 installer repair

- Removes an in-project `overlay/` staging directory after the overlay is merged, before `flutter analyze`.
- Reuses the original M10/M9 regression checkpoint on retries instead of backing up a partially installed M10 state.
- Preserves the public named dependency-injection constructors while explicitly suppressing `prefer_initializing_formals` where that lint would require private named parameters.
- Verifier now fails clearly if an installer staging overlay ever leaks into the project.

## FINAL v4 deep-link contract correction

- Fixes the final M10 verifier failure where `orbit://sos/../secret` normalizes to `/secret` before the resolver sees it.
- Enforces UUID-shaped identifiers for Circle, Moment, Ping, and SOS deep links, matching the authoritative Laravel `uuid`/`foreignUuid` schema.
- Rejects arbitrary slugs, traversal-normalized remnants, extra path segments, query strings, and fragments.
- Strengthens the verifier to assert the backend UUID schema and the UUID-only client resolver contract.
- Reuses the existing pre-M10 M9 rollback checkpoint when rerun over the current installed M10 state.
