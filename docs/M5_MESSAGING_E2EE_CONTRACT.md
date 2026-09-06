# Orbit Flutter M5 — Messaging + Client-side E2EE Contract

## Scope

M5 implements the existing Laravel Messaging contracts as a mobile text-messaging client without moving plaintext or private-key responsibility to the backend.

### Backend routes consumed

- `GET /api/v1/messaging/settings`
- `PATCH /api/v1/messaging/settings`
- `GET /api/v1/circles/{circleId}/message-devices`
- `GET /api/v1/circles/{circleId}/messages`
- `POST /api/v1/circles/{circleId}/messages`
- `POST /api/v1/message-envelopes/{envelopeId}/delivered`
- `POST /api/v1/circles/{circleId}/messages/{messageId}/read`
- `POST /api/v1/circles/{circleId}/typing`
- `POST /api/v1/devices` to idempotently publish this device's public E2EE identity bundle.

The backend remains authoritative for Circle membership, `can_message`, recipient-device selection, message retention, read-receipt preference, typing suppression in Ghost Mode, delivery state, rate limits and authorization.

## Client cryptographic boundary

M5 uses per-device client-generated key material:

- X25519 for recipient-specific key agreement.
- HKDF-SHA256 for envelope-key derivation.
- AES-256-GCM for authenticated message encryption.
- Ed25519 for sender authentication.
- A fresh ephemeral X25519 key pair per recipient envelope.

The backend `public_identity_key` field contains only the versioned public X25519 + Ed25519 bundle. Private keys are persisted with `flutter_secure_storage` and never sent to Laravel.

The ciphertext payload is versioned and includes the ephemeral public key, nonce, ciphertext, authentication tag and sender signature. Message/circle/sender/recipient identifiers are included in authenticated context so an envelope cannot be silently transplanted to another recipient or conversation.

## Recipient-set safety

Before every send the client requests the server-authoritative message-device set. The current sender device is excluded; every other returned encryption-ready device receives its own envelope.

If Laravel returns `MESSAGING_RECIPIENT_DEVICES_CHANGED`, the client re-fetches the device set and re-encrypts once while preserving the same `message_id`. The backend already treats `message_id` as an idempotency key, so this is the only messaging mutation that is eligible for this controlled retry.

## Delivery safety

Incoming text envelopes are processed in this order:

1. obtain the sender public identity from the server-filtered/cached Circle device set;
2. verify the Ed25519 signature;
3. decrypt and authenticate AES-GCM;
4. encrypt the plaintext again with a device-local AES key;
5. durably persist that encrypted local record in SQLite;
6. acknowledge delivery to Laravel;
7. optionally send read state when the user's server preference is enabled;
8. advance the local sync cursor.

The delivery acknowledgement intentionally happens only after authenticated decrypt and durable encrypted local persistence, because the backend deletes/consumes the recipient ciphertext envelope after delivery acknowledgement.

## Local persistence

SQLite stores message metadata plus an `encrypted_body` blob. The local database encryption key is stored separately in secure device storage. Plaintext is decrypted only when rendering the local conversation.

Public peer identity keys may be cached locally. If a known device suddenly presents a different public identity key, M5 fails closed instead of silently trusting the new key.

## Deferred to later milestones

- Media/voice payload encryption and media-envelope handling: M6.
- Realtime incoming message, delivery/read events and live typing subscription via Laravel Reverb: M10.
- Push notification delivery and deep-link handling: M10.

M5 deliberately does not acknowledge unsupported media/voice envelopes so M6 can later process their ciphertext without prior data destruction.
