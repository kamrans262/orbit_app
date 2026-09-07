# Orbit Flutter UI Runtime Polish v3

This patch is a focused post-M10P UI/runtime correction. It does not change Laravel APIs, Firebase credentials, E2EE contracts, device trust rules, Presence privacy, or SOS server-authoritative behavior.

## Corrected surfaces

1. **Profile details** (`/profile/edit`)
   - Adds an explicit `Scaffold`/Material surface for the top-level route.
   - Keeps the existing profile provider, repository, validation and save behavior unchanged.

2. **Notification preferences** (`/notifications/preferences`)
   - Adds an explicit `Scaffold`/Material surface for the top-level route.
   - Keeps existing notification preference APIs and SOS bypass semantics unchanged.

3. **Home**
   - Removes the "Safer people / brighter tomorrows" mission copy and heart icon.
   - Quick actions are now a horizontal rail with three cards visible at a time on the available content width; the fourth action is reached by horizontal scroll.
   - Actions are presented as Ping, SOS, Circle and Location.
   - The floating emergency control has a single visible `SOS` label; the icon is no longer the glyph that itself spells SOS.

4. **Camera** (`/camera`)
   - The live camera surface uses the controller preview dimensions and `BoxFit.cover` through a clipped fitted surface.
   - The camera image is uniformly fitted/cropped rather than stretched to the screen.
   - Capture, video duration, Circle selection and device-side encryption behavior are unchanged.

## Security and architecture invariants

- No backend files are modified.
- No Firebase service-account or client config is embedded by this patch.
- No plaintext message/media content is added to transport or logs.
- Existing M10P push and M10 realtime/deep-link behavior are untouched.
- Existing SOS activation routes and server-authoritative rules are untouched.

## v3 camera null-safety repair

- `_capture` pins the validated nullable Circle to `final OrbitCircle activeCircle = circle;` before asynchronous/timer use.
- `_finishVideo(OrbitCircle circle)` uses its own non-null method parameter when building the video review draft.
- This keeps the timer callback null-safe while preventing the out-of-scope `activeCircle` reference introduced by v2.
