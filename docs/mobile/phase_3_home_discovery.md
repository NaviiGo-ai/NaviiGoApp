# Phase 3: adaptive Home and Discover contract

## Source revision

Mobile discovery contracts were checked against
`NaviiGo-ai/NaviiGo-Website/main` at
`a7fd4249128994fed167e4a89ba97fc054e2f958`.

Relevant supported contracts are:

- `GET /api/places/autocomplete?input=...` returning `predictions` with
  `description`, `place_id`, and `sub`.
- `GET /api/places?lat&lng&type&radius` returning nearby place records.
- `GET /api/places/details?lat&lng&type&query&radius` returning normalized
  provider fields when a provider is configured, or an empty result when it is
  unavailable.
- `POST /api/recommendations/` accepting explicit preference context and
  optional group; its response contains destination IDs, names, and reasons.
  The checked Website route does not verify a request-body UID, so mobile uses
  its stateless mode and does not send `userId` or request stored-account
  enrichment. Mobile does not display the recommendation score.
- `users/{uid}/bucketList/{itemId}` for saved places. The document contract is
  `id`, `name`, `type`, optional `image`, optional `location`, and `createdAt`.

The Website backend was not changed. Mobile continues to call the existing
configured Python API through `ApiClient`; provider keys and secrets remain
server-side.

## Home lifecycle

`homeJourneySurfaceProvider` consumes the existing
`adaptiveJourneyLifecycleProvider`. Pages do not calculate lifecycle state.

- `activeTrip`: Home shows the real destination and the first uncompleted
  itinerary activity when one exists, then enters `/ongoing-trips`.
- `upcoming`: Home shows the actual stored start date, a date-derived
  countdown, and whether parsed day plans are present.
- `discover`: Home shows the discovery action and curated registry destinations.
  Historical trips may expose a truthful Passport archive action, but they do
  not force a post-trip adaptive lifecycle.

Adaptive rendering continues to use the composition root and
`safeAdaptivePreferencesProvider`; appearance opt-out and frozen controller
rules are unchanged.

## Discover and truthfulness

Explore search is keyed by `(query, authenticated UID)`, waits 300 ms before
calling autocomplete, and only renders the currently keyed result. Older
responses cannot replace a newer query or cross an account transition. Local
curated destinations remain available when the provider is unavailable; live
place suggestions show only fields returned by the provider.

Provider-unavailable, empty, loading, and retry states are distinct. Missing
ratings, counts, prices, opening state, photos, and coordinates remain absent.
Map context is passed only from destinations with registry coordinates, and
place records expose `hasCoordinates` for future live-map consumers.

Destination details use the destination registry for identity and coordinates,
and nearby live provider results for places. Unsupported hard-coded iconic
stops, pacing claims, gallery substitutions, and guest saved writes are not
used by the Phase 3 flow.

## Saved state and analytics

Saved-place streams attach an in-memory `sourceUserId`; the safe selector
rejects retained values from another account. Repository writes return success
or failure so UI state can reconcile instead of claiming a failed save worked.

Phase 3 interactions reuse existing analytics meanings: `PLACE_VIEWED`,
`PLACE_SAVED`, and `PLACE_UNSAVED`. The existing account-owned queue remains
responsible for local `ownerUid`, expected-UID token binding, serialization,
retry, and the 200-entry per-user limit. `ownerUid` is never sent in the
backend event schema.

## Known limits

- Autocomplete supplies names and regions, not coordinates; a suggestion is
  therefore not presented as a detailed map-ready place until a supported
  provider record exists.
- The checked backend may return an empty recommendations or places result
  when provider configuration is unavailable.
- Real Firebase rules, provider availability, native maps, and offline
  persistence still require device/deployed-project verification.
