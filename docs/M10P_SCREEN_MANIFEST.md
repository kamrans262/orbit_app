# Orbit M10P Screen Manifest

M10P creates no new route-level screen.

The module is infrastructure-only. Existing notification, messaging, Ping, Moments, Activity, and SOS screens continue to own their durable state and authorization. Foreground remote push merely invalidates/refetches those existing providers; push taps are routed by the M10 central deep-link allowlist.
