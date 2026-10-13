# Phase 6 shared contract packet

The canonical Website/backend packet is
`NaviiGo-Website/docs/phase_6_contract_packet.md`. This copy records the mobile
gate and the exact stable decisions used by the mobile implementation.

- Owner authority is the verified Firebase UID; body `userId` is never trusted.
- Durable authority is `users/{uid}/itineraries/{itineraryId}`.
- Generation uses one caller-supplied `operationId` as the idempotency key and
  canonical owner-document ID. Mobile requires a committed receipt containing
  `ownerUid`, `itineraryId`, `operationId`, and `revisionId` before clearing
  `isEphemeral`, caching, sharing, history, live journey, or Passport claims.
- An ambiguous generation/acceptance result stays unconfirmed until a same-ID
  retry or owner-path reconciliation succeeds.
- New activities require unique immutable `activityId` values. Titles, place IDs,
  day numbers and list positions are not identity. Legacy duplicate/name-only
  mappings disable replan rather than guessing.
- Day numbers are preserved display identities and are not converted to array
  positions.
- Replan is supported only for `I_AM_TIRED`; proposals are server-owned and
  acceptance returns an authoritative itinerary plus revision-bound receipt.
- Manual local check-ins remain separate from server persistence. On an
  authoritative refresh, `arrived`, `completed`, and `skipped` records are
  retained only when the same stable activity ID still exists. Positional legacy
  records are not migrated by guesswork.
- Private owner reads never fall back to public-root projections. Public sharing
  is explicit and the public projection is sanitized.
- Completed history is lifecycle-authoritative; cancelled is terminal but not a
  completed visit. Unconfirmed previews cannot appear in history or Passport.

This packet is implemented together with the Website contract packet and the
Phase 6 handoffs. It does not authorize production deployment or migration.
