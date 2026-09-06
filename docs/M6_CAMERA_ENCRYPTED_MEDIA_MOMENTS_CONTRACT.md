# Orbit Flutter M6 — Camera, Encrypted Media & Moments Contract

## Scope

M6 turns Orbit's Camera tab into the private capture path for Circle Moments and consumes the existing Laravel Media and Moments APIs without changing backend contracts.

## Security boundary

- Camera photo/video bytes remain local plaintext until the user chooses Publish.
- Flutter encrypts media before any upload.
- Laravel receives encrypted ciphertext, ciphertext hashes, media metadata required by the existing contract, and one encrypted content-key envelope per current encryption-ready Circle device.
- Laravel never receives the plaintext media key or plaintext photo/video bytes.
- Private device identity keys continue to live in secure device storage through the M5 identity store.
- Temporary ciphertext is deleted after the upload/decrypt workflow.
- Temporary decrypted viewer files are deleted when the viewer is disposed; video handles are released before deletion, and failed decrypts are cleaned up rather than leaving partial plaintext files.
- M6 does not request microphone or background permissions. Video capture is intentionally silent in this milestone.

## Client media format

M6 uses a versioned local ciphertext container beginning with `ORBITMEDIA1`. Large files are processed in bounded records rather than loaded completely into memory. Each plaintext record is encrypted with AES-256-GCM using a random 256-bit per-asset key. Ciphertext SHA-256 is calculated over the complete encrypted file and sent to Laravel as `sha256_ciphertext`.

The 256-bit media key is wrapped independently for each current recipient device using:

- X25519 ephemeral key agreement
- HKDF-SHA256
- AES-256-GCM
- algorithm identifier `orbit-media-key-x25519-aesgcm-v1`

The server remains authoritative for the recipient device set. Before wrapping keys, M6 reuses M5 peer-identity pinning so a known device whose public identity changes unexpectedly fails closed. If upload completion returns `MEDIA_STALE_DEVICE_SET`, M6 fetches the current device set, validates those peer identities, re-wraps the same media key for that exact set, and retries completion once.

## Existing Laravel Media endpoints consumed

- `POST /api/v1/circles/{circleId}/media/uploads`
- `PUT /api/v1/media/uploads/{uploadId}/chunks/{chunkIndex}`
- `POST /api/v1/media/uploads/{uploadId}/complete`
- `GET /api/v1/media/{assetId}`
- `GET /api/v1/media/{assetId}/key-envelope?device_id=...`
- `GET /api/v1/media/{assetId}/download?device_id=...`
- `DELETE /api/v1/media/{assetId}`

Chunk uploads are raw `application/octet-stream` bytes and include `X-Chunk-SHA256`. The app follows the server-returned chunk size rather than inventing a separate upload contract.

Automatic authentication replay is used only where the backend operation is safe/idempotent. Upload creation and destructive media/Moment deletes are never blindly replayed. Chunk writes and upload completion use the backend’s existing idempotent behavior.

## Existing Laravel Moments endpoints consumed

- `GET /api/v1/circles/{circleId}/moments`
- `POST /api/v1/circles/{circleId}/moments`
- `GET /api/v1/moments/{momentId}`
- `POST /api/v1/moments/{momentId}/view`
- `GET /api/v1/moments/{momentId}/viewers`
- `DELETE /api/v1/moments/{momentId}`

Publishing uses the client-generated `moment_id` as the backend idempotency key. M6 sends no caption or plaintext media field.

## Privacy and authorization

Laravel remains authoritative for:

- Circle membership
- media-upload eligibility
- current encryption-ready recipient devices
- `can_message` for the media recipient/device contract
- restricted-member Moment publishing rules
- `can_view_moments`
- Moment expiry
- Moment ownership/deletion
- viewer identity visibility
- Global Ghost Mode / Circle Ghost Mode anonymous view recording

The client does not try to override those rules.

## Moment viewing order

1. Fetch server-authoritative Moment metadata.
2. Fetch this device's encrypted media-key envelope.
3. Unwrap the media key locally.
4. Download ciphertext only to a random client-generated temporary path.
5. Verify ciphertext SHA-256.
6. Decrypt to a separate random client-generated temporary local file.
7. Render the media.
8. Best-effort record the Moment view with Laravel.
9. Delete the temporary plaintext viewer file when the screen is disposed.

A failed integrity/decryption operation does not render the media.

## Deliberately deferred

- encrypted media messages / voice messages: later media/messaging expansion
- Reverb live Moment events: M10
- push notifications: M10
- deep links: M10
- background capture/upload: not part of M6
- microphone/audio recording: not part of M6
