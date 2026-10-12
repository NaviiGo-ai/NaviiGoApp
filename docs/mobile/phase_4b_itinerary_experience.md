# Phase 4B — Itinerary Experience Handoff

Status: mobile handoff for the read-only itinerary experience. This records the
current source behavior; it does not expand the Website, backend, Firestore
schema, or mobile route contract.

## Scope, revisions, and freeze

- Published Phase 4A base: `8cd74c62d7722b4897e7129920e02b49c25845fc`.
- Website contract revision audited by the mobile docs: `a7fd4249128994fed167e4a89ba97fc054e2f958`.
- Branch: `astra/mobile-v2`.
- Phase 4B implementation changes cover `hive_service.dart`,
  `trip_repository.dart`, `trip_itinerary_model.dart`,
  `generated_itinerary_page.dart`, `trip_provider.dart`, and
  `itinerary_overview_widgets.dart`.
- Phase 4B owns presentation truthfulness, lifecycle handoff boundaries, and
  owner-scoped cache behavior. Website/backend changes, new backend fields or
  routes, a local editor, a mutation queue, dependencies, and the Phase 4A
  document remain frozen. Phase 4B adds focused regression tests below.

Phase 4A remains the source for generation request details. This document adds
the verified behavior and limitations around the generated result, itinerary
views, lifecycle handoff, and cache isolation.

## Ownership and persistence contract

The authoritative saved-itinerary path is:

```text
users/{uid}/itineraries/{id}
```

The verified Firebase UID, not a body field or a cached session value, scopes
reads and writes. `getUserTripsStream` and `getTripById` read this owner path;
the provider also filters retained values after an auth change. A public root
document is not an alternative owner path or a private-trip fallback.

### Direct generation remains an ephemeral Phase 4A preview

- Mobile calls the direct authenticated `POST /api/itinerary/generate` route
  described by Phase 4A. It validates the response owner and required nested
  day/activity shape before rendering it.
- The returned mobile model is marked `isEphemeral: true`. A response `id` or
  `uuid`, when present, is display/model data, not a mobile persistence receipt;
  a local fallback ID is not a receipt either.
- The direct backend may attempt its own persistence under the verified UID, but
  the mobile response has no durable receipt or stable reconciliation contract.
  Mobile does not issue a second client save for generation and must not present
  the preview as saved, live, or shareable.
- A timeout, navigation away, or retry does not cancel server work. The backend
  may finish after the client stops waiting, and a retry may create another
  server-side result. Receipt reconciliation, cancellation, progress stages,
  and idempotency are deferred.
- `saveTrip` explicitly rejects an ephemeral model. There is no mounted mobile
  action that converts this preview into a durable saved-trip record.

### `saveTrip` is a persistence helper, not a generation receipt

`TripRepository.saveTrip` is a client Firestore helper for an already durable,
non-ephemeral model. It requires the current UID, a non-empty ID, and matching
ownership, then merges the document at the owner path and updates the local
cache. It is not called as part of direct generation and does not reconcile a
backend-generated random document ID.

The helper has no documented idempotency key, revision, conflict, or retry
protocol. Profile counter updates and public-root mirror operations are
best-effort side effects; a successful owner document remains the authority.

## Journey Overview and Day in Motion

The generated itinerary page has two local, read-only views:

- **Chapters Overview** keeps the backend-provided `dayPlans` list order. It
  labels each chapter with the actual `TripDayPlanModel.dayNumber`; the client
  does not sort, renumber, or assume that list position is the day number.
- **Day in Motion** selects a day from that same ordered list and uses its actual
  `dayNumber` in the rail, context, and empty-state copy. If refreshed data has
  fewer days, the selected local index is clamped. View selection and selected
  day are transient UI state and are not persisted to Firestore or Hive.
- The Phase 4B vocabulary is **Activities/Stops**, not Waypoints; current visible
  labels use **Activities** and activity locations. Missing activity data is not
  turned into fabricated stops. Existing Live Journey check-in vocabulary is a
  separate surface and is not redefined here.

Only supplied, non-empty values are rendered:

- Destination and the model's approved hero image are shown. The optional
  input start date and group appear in the hero only when present.
- Duration and activity count come from the parsed itinerary/input data. A
  budget, when supplied by the input form, is labelled **INPUT BUDGET**; it is
  not described as actual spend or a calculated total. Optional pace is shown
  only when present.
- Chapter date, theme, and area focus are conditional. Missing chapter context
  produces an honest no-details message rather than a guessed theme or date.
- Activity preview titles and times are shown only when present. Missing or
  generic parser fallback titles are presented as unavailable rather than
  invented. Full activity cards similarly show only supplied description,
  location, category, duration, estimated cost, booking advisory, meal context,
  warning, source, and transfer fields.
- A day with no activities states that no activity details were provided. A
  missing itinerary or missing day plans produces an unavailable/incomplete
  state; it is not replaced with sample content.

### Coordinate-only map handoff

The map card and sheet use only activities with finite, valid latitude and
longitude values supplied by the itinerary. A location string, destination
name, or inferred city center is not geocoded into a marker. With no usable
coordinates the UI disables the handoff and says that the activity map is
unavailable.

When coordinates exist, the sheet lists those activity locations and hands an
existing coordinate-backed `PlaceModel` to the existing `/map` route. This is a
place handoff, not a generated route line, directions result, or new map
backend contract. A locally constructed fallback place ID is only for that
in-memory handoff when the activity has no `placeId`; it is not persisted as a
backend identity.

## Lifecycle and terminal action boundary

`TripStatus` is the shared lifecycle vocabulary. A server-written status wins;
when absent, the model derives a conservative state from dates and `isActive`.
Calendar arrival alone does not make a trip active. The active state requires an
explicit validated start or an explicit server-written active status.

The itinerary page exposes the **START LIVE JOURNEY** handoff only for a
non-ephemeral, non-terminal model. The page does not claim that the trip has
started. `/live-tracking` owns the start gate and confirms, in order, current
authentication and ownership, one-journey-at-a-time conflict, usable location
permission/services/fix, fresh and accurate coordinates, proximity to the
destination start region, and the destination-local date.

- A second active journey blocks the start. The client does not silently end the
  existing journey; the traveller must explicitly resolve the conflict.
- A confirmed start writes the active lifecycle through the repository. An
  explicit end writes `cancelled`, which is terminal. `completed` and
  `cancelled` journeys do not receive another start action.
- The live handoff is not available for an ephemeral generation preview. A
  terminal trip also has no bottom action bar. Failed writes leave the trip in
  its prior state rather than showing a false success.

This is a lifecycle boundary, not a general mutation contract. There is no
mounted mobile CRUD/edit/replan flow, no local pretend editor, and no queued
offline mutation that claims eventual server success.

## Hive cache isolation and fallback

Itineraries share the existing `itineraries_box` with legacy check-in records;
the cache service must not clear the box wholesale. New itinerary entries use
an owner- and trip-delimited key:

```text
itinerary:<ownerUid.length>:<ownerUid>:<tripId>
```

Each new entry is an envelope with this shape:

```text
{
  kind: "itinerary",
  schemaVersion: 1,
  ownerUid: <uid>,
  tripId: <id>,
  cachedAt: <parseable timestamp>,
  payload: <TripItineraryModel.toMap()>
}
```

`cachedAt` belongs to the envelope and is not model data. Writes reject empty
owner/trip values, ephemeral payloads, owner mismatches (`userId`/`uid`), and
payload IDs that disagree with the cache key.

Reads reject an envelope unless its key, kind, schema version, owner, trip ID,
timestamp, payload ownership, non-ephemeral state, and payload ID all match.
There is no permissive schema migration: unknown or malformed envelope
versions are unusable. A legacy bare record is accepted only when it has an
explicit matching top-level `userId` or `uid`, an attributable matching ID (or
no ID), and is non-ephemeral. Ownership is never inferred from a bare key, the
current session, or nested form data. Check-in keys are excluded from itinerary
cache scans. When both forms exist, a valid scoped envelope wins; an
authoritative list refresh replaces attributable legacy records with envelopes.

Firestore remains authoritative:

- The list stream may emit usable same-owner cache data first, then listens to
  `users/{uid}/itineraries`. A successful Firestore snapshot is authoritative,
  including an authoritative empty list. A cache write/replace failure is
  non-fatal; the Firestore result is still used.
- If the Firestore stream fails after usable same-owner data was emitted, the
  last verified list is retained/emitted. If there is no usable cache, the
  stream preserves the error instead of manufacturing an empty successful
  result.
- A detail read uses the owner document first. A confirmed owner-document miss
  clears that owner's cached trip and returns no itinerary. A transport failure
  may fall back to that same owner's validated cache; the public root collection
  is never a detail fallback. Cache write failure does not turn a successful
  Firestore read into a client failure.

### Account switch and signed-out behavior

Every cache read, Firestore emission, cache refresh, and provider projection is
rechecked against the current UID. A late event for account A yields no A data
after the session moves to account B. Retained Riverpod values are filtered to
the new owner, and the signed-out trip stream is empty. An explicit itinerary
result also fails closed when signed out or when its `userId` differs from the
current account.

Sign-out records the UID before Firebase sign-out, then removes only that
owner's attributable itinerary cache and profile cache. The shared Hive box,
other owners' valid records, and raw check-ins are not globally cleared. If no
UID is available at sign-out, owner-attributable itinerary cleanup cannot be
performed; the app still clears the profile cache. Retained records remain
inaccessible to another account because all reads require explicit ownership.

## Sharing and root behavior

Private itineraries remain at `users/{uid}/itineraries/{id}`. `saveTrip` mirrors
to root `itineraries/{id}` only when `isPublic` is explicitly true, including
the owner and public flag. When `isPublic` is false it attempts to delete a
previous root mirror so unsharing removes public visibility. Both mirror and
delete failures are logged as non-fatal; consequently root visibility can lag
after a failed mirror operation, while the owner document remains authoritative.

The itinerary page shows a copy-link action only for a non-ephemeral public
model and copies the existing `https://naviigo.com/itinerary/{uuid}` string. A
copy action is not a mobile public-read contract: this phase adds no public
fetch route, sharing mutation UI, or guarantee that a root mirror operation
completed. No private or ephemeral result receives that action.

## Unsupported conflict and idempotency claims

Do not infer any of the following from the current helper or presentation:

- a mobile save receipt for direct generation;
- a generation idempotency key, cancellation token, progress-stage API, or
  retry deduplication;
- optimistic or queued edit/replan/delete/share mutations;
- a Firestore revision/base-revision conflict protocol for `saveTrip` or the
  public mirror; or
- public-root reads as a substitute for owner-scoped reads.

The live start conflict gate is limited to the one-active-journey rule and
requires explicit traveller resolution. It is not a general synchronization or
write-conflict mechanism.

## Verification record and limitations

Actual checks for the final Phase 4B tree:

- Focused cache/repository/presentation/model checks: **27 tests passed**.
- Existing affected lifecycle/live/Phase 3 regression suites: **67 tests
  passed**.
- Full Flutter suite: **222 tests passed**.
- `dart format .`: **141 files, 0 changed**.
- `flutter analyze`: no issues found.
- `git diff --check`: passed.

The final gate used Flutter 3.35.4 and the lockfile-resolved dependency cache.
No `pubspec.yaml` or `pubspec.lock` changes are part of Phase 4B.

The bounded review found and resolved owner-mirror deletion, stale-cache
resurrection, legacy-cache promotion, cache replacement rollback, accessibility
tap-target, neutral image fallback, and frozen-provider test-seam issues.

Remaining runtime limitations are intentional:

- No real-device visual or accessibility matrix is represented here. Responsive
  wrapping, text scaling, reduced-motion tokens, and asset/network image
  fallback are source behaviors, not proof of every device layout.
- The map handoff depends on the existing map screen and platform/provider
  availability; it does not supply a route renderer or geocoder.
- Live start depends on Firebase auth/Firestore rules, OS permission and
  location services, GPS freshness/accuracy, and destination-local time. Those
  external conditions are not simulated by this handoff.
- The direct generation service, Firebase rules, and Website contract can drift
  after their audited revisions. The mobile client must continue to fail closed
  for owner, shape, coordinate, and persistence-receipt gaps rather than
  inventing data.
