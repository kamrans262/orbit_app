# Orbit Flutter M4 — Circles Contract

M4 consumes the existing Laravel `/api/v1/circles` contract. It does not add, rename, or weaken backend routes or authorization rules.

## Canonical endpoints consumed

- `GET /api/v1/circles`
- `POST /api/v1/circles`
- `POST /api/v1/circles/join`
- `GET /api/v1/circles/{circleId}`
- `PATCH /api/v1/circles/{circleId}`
- `DELETE /api/v1/circles/{circleId}`
- `POST /api/v1/circles/{circleId}/invites`
- `GET /api/v1/circles/{circleId}/members`
- `PATCH /api/v1/circles/{circleId}/members/{membershipId}`
- `DELETE /api/v1/circles/{circleId}/members/{membershipId}`
- `POST /api/v1/circles/{circleId}/leave`

## Backend rules preserved

- Circle types are `standard` and `temporary`.
- Temporary Circles require a future `expires_at`.
- Roles are `owner`, `admin`, `member`, and `restricted`.
- Owners/admins can edit the Circle and create invites while active.
- Only the owner can archive a Circle.
- Owners cannot leave through the current API contract.
- The owner cannot be removed.
- Admins cannot manage another admin and cannot promote a member to admin.
- Only a member may change their own privacy settings; M3 remains the client surface for personal presence/privacy.
- Archived/expired Circles cannot be modified.
- Invite code usage/expiry validation remains server authoritative.

## Mutation replay policy

Circle mutations are not opted into automatic 401 replay. The central client may proactively refresh an expiring session before sending the request, but create/join/invite/update/remove/leave/archive mutations are not blindly repeated after an unauthorized response.

## Deliberately not invented

The Laravel Circle contract in the recovered backend does not expose an ownership-transfer route. M4 therefore does not fake ownership transfer. The owner is informed that leaving is unavailable under the current contract and may archive the Circle instead.
