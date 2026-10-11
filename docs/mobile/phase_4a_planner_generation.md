# Phase 4A — Planner and Generation Handoff

Status: mobile implementation handoff. This document records the bounded
contract used by Phase 4A; it does not authorize Website/backend changes.

## Contract source and route distinction

- Website contract revision: `a7fd4249128994fed167e4a89ba97fc054e2f958`.
- Mobile targets the direct FastAPI `POST /api/itinerary/generate` route. It is
  distinct from any Website Next proxy/route; the mobile client does not add a
  proxy dependency or call the extraction route for generation.
- Direct generation requires `Authorization: Bearer <Firebase ID token>`.
  The backend verifies the token and uses its UID; a body `userId` is not an
  authority (`backend/routers/itinerary.py:59-75,83-110`).
- `POST /api/itinerary/from-link` is extraction-only and returns
  `{success, extracted}` (`backend/routers/itinerary.py:241-250`). Phase 4A
  does not make it a generation action.

## Request and response contract

`ItineraryRequest` accepts `destName`, optional `destination`, purpose, group,
days `1..14`, budget `>=0`, optional arbitrary `startDate`, traveler preset,
preferences, browsing signals, optional logistics, must-do items, and validated
route stops (`backend/routers/itinerary.py:23-52`). The mobile repository now
validates supported registry destinations, days, budget, traveler presets, and
optional date strings before sending (`lib/features/trips/data/trip_repository.dart`).
It omits absent optional dates instead of inventing a seven-day date.

Supported submitted mobile values:

- `travelerType`: exactly `backpacker`, `comfort`, `luxury`, `family`, `flash`,
  or `slow`.
- `group`: `solo`, `couple`, `family`, `friends`, or `large`.
- `preferences.interests`: optional list of backend tag names such as
  `Heritage`, `Nature`, and `Food`.
- `preferences.dietary`: optional one-string ranking preference: vegetarian,
  Jain, or Halal. This is not a dietary safety guarantee.
- `savedPlaces`, `dismissedPlaces`, `visitedPlaces`, and `categoryAffinities`
  remain backend-supported fields, but Phase 4A does not add UI for them.
  Unsupported `pace`, `travelPace`, and `accessibility` preference keys are
  not submitted.

The backend's stored profile may override submitted traveler style and group,
and may provide interests when no preferences are submitted
(`backend/routers/itinerary.py:83-110`). The planner discloses the possible
traveler/group override and defaults optional interests/dietary choices to no
preference.

Success is manually assembled with `success`, `itinerary`, `source`, verified
`userId`, and optional `dataSources` (`backend/routers/itinerary.py:186-229`).
The mobile repository preserves source/data-source metadata, accepts nullable
optional itinerary fields, rejects malformed nested activity names, and
rejects a response whose owner does not match the initiating UID.

## Persistence, isolation, and lifecycle boundaries

Every successful direct generation attempts backend persistence under the
verified UID, but the random Firestore ID is discarded and there is no mobile
receipt or stable response ID (`backend/routers/itinerary.py:206-229`). There
is no idempotency key, cancellation endpoint, or backend progress-stage
contract. The mobile result is therefore marked ephemeral and displays
`Generated preview · save status unconfirmed`; saved/live/share actions remain
disabled for that result. A timeout or leaving the page may still allow the
server to finish/save, and retrying can create another trip.

Phase 4A captures the initiating UID, rejects stale responses before publishing,
reactively hides an explicit result after owner change/logout, scopes planner
draft/error state to the current account, and prevents overlapping UI submits.
The direct backend still owns persistence; receipt reconciliation is deferred.

## Known backend limitation

The deterministic model has a nullable Geoapify/provider rating crash risk in
the restaurant/hotel scoring paths (`backend/services/itinerary_model.py:569-572`
and `:893-899`). Mobile treats provider/server failure as an error and does not
invent replacement data; fixing that backend limitation is outside this pass.

## Verification and handoff

Focused checks run during this pass:

- `flutter test test/trip_generation_test.dart test/trip_planner_page_test.dart test/generated_itinerary_page_test.dart`
- `flutter test test/trip_itinerary_model_test.dart test/trip_generation_test.dart test/trip_planner_page_test.dart test/generated_itinerary_page_test.dart`
- `flutter analyze`

The focused boundary/UI suites pass after the final changes; the coordinator
will run the single final combined gate. Phase 4B presentation redesign,
offline generation caching, saved-trip receipt reconciliation, cancellation,
progress stages, and live-trip changes remain deferred.
