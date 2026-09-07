# Orbit M10P — Remote Push Delivery Completion

M10P completes the provider layer intentionally left behind the M10 `pending_provider` boundary. It does not create a second notification system. Laravel's existing `orbit_notifications`, `notification_deliveries`, notification preferences, E2EE device registration, strict `orbit://` deep-link resolver, Reverb wake-up paths, and SOS authorization remain authoritative.

## Delivery architecture

- Android and iOS both register an FCM registration token through `firebase_messaging`.
- Laravel sends through Firebase Cloud Messaging HTTP v1 using a short-lived OAuth access token minted from a Google service-account JSON file.
- iOS messages are handed from Firebase to APNs. The APNs authentication key is uploaded to Firebase Console; the private APNs key is never bundled in Flutter or Laravel source.
- The Laravel service-account JSON file remains server-side only and is referenced by `GOOGLE_APPLICATION_CREDENTIALS`.
- Provider delivery runs on the existing Laravel database queue. `php artisan queue:work --queue=push,default` is the preferred local/VPS worker.
- `orbit:notifications:enqueue-push` catches pending provider rows and is scheduled every minute; this also supports cron-driven hosting environments.

## Localhost development

Laravel may remain at `http://localhost:8000` while testing remote push. Sending to Firebase is outbound HTTPS, so Laravel does not need a public domain to send a notification. A physical Android phone can register its device token through `adb reverse tcp:8000 tcp:8000` while the app is open. FCM then reaches the phone independently over the internet.

Reverb remains separate. For a USB Android phone using local Reverb, also use `adb reverse tcp:8080 tcp:8080`.

## Hostinger migration

When Orbit is moved to a temporary Hostinger domain:

- Use HTTPS for the Laravel API.
- Set Flutter `ORBIT_API_BASE_URL=https://<temporary-domain>/api`.
- Keep the same Firebase project and service-account design; push tokens do not need to change merely because the API hostname changes.
- Set Laravel `APP_URL` to the temporary HTTPS domain.
- Put the Firebase service-account JSON outside the public web root and point `GOOGLE_APPLICATION_CREDENTIALS` at its absolute server path.
- Run a persistent queue worker on a VPS. If the Hostinger plan does not support persistent workers, run `queue:work --stop-when-empty --queue=push,default` from cron at the shortest supported interval.
- Laravel Reverb requires a long-running WebSocket process and WSS termination. This is suitable for a VPS/long-running-process environment; do not assume ordinary shared hosting can run Reverb continuously.

## Privacy and security invariants

Remote push is never the sole SOS safety transport. Existing authenticated Reverb updates, the SOS incident polling fallback, and server-side SOS authorization remain in place even when Firebase is enabled.

Remote push payloads contain only:

- notification ID
- notification kind
- priority
- allowlisted Orbit deep link
- generic notification title/body

Push payloads do not contain message plaintext, E2EE ciphertext/envelopes, encryption keys, SOS coordinates, sender identity metadata, Moment media, or other authoritative feature state. The phone refreshes durable Laravel state after foreground receipt/open.

An `UNREGISTERED` FCM response clears only the matching device push token. It never clears the device E2EE public identity. Quota, unavailable, internal, and connection failures are retried with delay. Permanent provider failures are marked failed without logging registration tokens or notification payloads.

## Flutter runtime

Firebase is disabled unless the build uses `--dart-define=ORBIT_FIREBASE_ENABLED=true` plus the platform configuration values. This means a normal M10 build remains functional without Firebase credentials.

Required common defines:

- `ORBIT_FIREBASE_ENABLED=true`
- `ORBIT_FIREBASE_PROJECT_ID`
- `ORBIT_FIREBASE_MESSAGING_SENDER_ID`

Android additionally requires:

- `ORBIT_FIREBASE_ANDROID_API_KEY`
- `ORBIT_FIREBASE_ANDROID_APP_ID`

Apple additionally requires:

- `ORBIT_FIREBASE_IOS_API_KEY`
- `ORBIT_FIREBASE_IOS_APP_ID`
- `ORBIT_FIREBASE_IOS_BUNDLE_ID`

These client Firebase configuration values identify the Firebase app; the server service-account private key is never a Dart define.

Foreground pushes are wake-up signals. Orbit refreshes the existing durable notification/feature providers and suppresses a duplicate foreground OS banner. Background/terminated notification taps enter the existing M10 strict deep-link allowlist.

## Apple requirements

Before iOS push can be considered production-ready:

1. Register the iOS app in the Firebase project.
2. Enable Push Notifications capability in Xcode.
3. Enable Background Modes > Remote notifications.
4. Upload an APNs authentication key in Firebase Console > Project Settings > Cloud Messaging.
5. Build/sign with the appropriate Apple provisioning profile.

M11 remains responsible for the final iOS signing/release audit.

## Server environment

```dotenv
ORBIT_PUSH_ENABLED=true
ORBIT_PUSH_QUEUE=push
ORBIT_PUSH_MAX_ATTEMPTS=5
ORBIT_FIREBASE_PROJECT_ID=your-firebase-project-id
GOOGLE_APPLICATION_CREDENTIALS=C:\\secure\\orbit-firebase-service-account.json
ORBIT_FIREBASE_TIMEOUT_SECONDS=10
```

On Linux/Hostinger, use an absolute Linux path for `GOOGLE_APPLICATION_CREDENTIALS`.

## Worker commands

Local/VPS continuous worker:

```bash
php artisan queue:work database --queue=push,default --sleep=1
```

Shared/cron fallback:

```bash
php artisan queue:work database --queue=push,default --stop-when-empty --max-time=50
```

The push job has its own bounded retry ceiling and uses exponential provider backoff while honoring a larger `Retry-After` value when Firebase supplies one.

## Physical-device test

After the app has logged in and registered a push token:

```bash
php artisan orbit:push:test user@example.com
```

Keep a push queue worker running. Test all three states separately: foreground, background, and terminated. Then verify a notification tap routes only to an allowlisted `orbit://` destination.
