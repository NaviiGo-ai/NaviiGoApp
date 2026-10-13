# Phase 5 — Live Journey and Replanning Handoff

Status: mobile implementation handoff for the durable Live Journey surface and
its deliberately disabled replan boundary. This records the mobile behavior in
the intended Phase 5 wave; it does not authorize Website, backend, Firestore
rules, schema, or route changes.

## Revisions, ownership, and freeze

- Mobile review base: `b546a350a74fafb5122a6f9b55e6cdd2f1e08d34`.
- Website contract revision audited by this handoff:
  `a7fd4249128994fed167e4a89ba97fc054e2f958`.
- The mobile authority for saved itineraries remains:
  `users/{uid}/itineraries/{id}`.
- Phase 5 covers a durable active journey, day context, coordinate-only map
  handoff, truthful location/context states, and traveller-controlled manual
  check-ins.
- Phase 5 does **not** add a replan client, a local itinerary editor, an
  optimistic or queued mutation layer, a new map SDK, background location
  tracking, or any backend/Website change.

Read this document with
[`phase_4b_itinerary_experience.md`](phase_4b_itinerary_experience.md).
Phase 4B remains the source for owner-scoped reads, cache isolation and
fallback, direct-generation ephemerality, public-root behavior, and the general
lifecycle vocabulary. This document records the Live Journey additions and the
replan incompatibility rather than redefining those contracts.

## Durable journey authority and lifecycle

### The saved owner document is the durable journey

The Live Journey flow is available only for an owner-verifiable, non-ephemeral
itinerary. Its durable lifecycle is written to the owner document at
`users/{uid}/itineraries/{id}`. The mobile model and providers use the shared
`TripStatus` vocabulary; a canonical active journey is one whose lifecycle
resolves to `TripStatus.active`, not one whose dates merely include today.

Starting a journey is a handoff, not an assertion by the itinerary page:

1. A saved itinerary can expose **START LIVE JOURNEY**.
2. `/live-tracking` receives that explicit itinerary and owns the start gate.
3. Only after every gate passes does the repository write the active lifecycle.
4. A successful write records `isActive: true`, `status: "active"`, and the
   server timestamp on the owner document.
5. The owner stream is then the source used by the active-trip providers and
   other screens. A local button press, cached generation response, or calendar
   date does not by itself make a journey active.

An explicit **End Current Trip** action is separate from starting another
journey. When the traveller chooses it, the owner document is written with
`isActive: false` and terminal `status: "cancelled"`. Completed and cancelled
journeys are not offered another start. A failed start or end write leaves the
previous lifecycle visible and reports the real action failure; the UI does not
show a false success or a locally invented active state.

### One active journey at a time

The start gate checks the current owner's canonical active-trip projection
before location work. A different active journey produces a conflict state and
blocks the requested journey. The app does not silently end the other journey;
the traveller must explicitly view or end the currently active journey before
starting the requested one. An explicit itinerary passed to Live Journey takes
precedence over a positional list fallback, so a conflict is evaluated against
the journey the traveller actually opened.

This is a mobile flow boundary, not a new server concurrency protocol. The
Phase 5 wave adds no Firestore transaction, server lock, rules change, or
backend endpoint. Concurrent writers from multiple devices therefore remain
an external authority/rules limitation and must not be described as a mobile
conflict-resolution guarantee.

### Ephemeral generation remains ineligible

Direct generation still returns an ephemeral preview when mobile has no durable
receipt. The preview may render the supplied itinerary, but it is not a saved
journey and cannot start Live Journey, be treated as active, or receive a
replan/check-in persistence claim. `saveTrip` and the existing Phase 4B cache
guards continue to reject ephemeral models. The generated-preview banner and
the absence of a live action are intentional truthfulness boundaries.

## Start validation and truthful location states

The platform adapter reads foreground location only. It does not run a
background stream or write coordinates to the itinerary. The OS permission
prompt is reachable only from an explicit traveller action such as **VERIFY
YOUR START** or **TRY LOCATION AGAIN**; it is not requested at app launch or
because a widget rebuilt.

The start service fails closed and evaluates these gates in a named state:

1. signed-in traveller;
2. itinerary ownership matches the verified Firebase UID;
3. no other canonical active journey;
4. foreground location permission;
5. device location services enabled;
6. a usable position fix arrives within the bounded read;
7. the fix is fresh and accurate enough to use;
8. the fix is within the itinerary's start region; and
9. the destination-local date is inside the allowed start window.

The current location policy is explicit: a fix older than five minutes is
stale, accuracy looser than 500 metres is insufficient, and the start region is
25 km around the curated destination start. These values are validation inputs,
not a promise that the app tracks a route or continuously monitors the device.

The UI keeps materially different failures separate so the recovery action is
truthful:

| State | Meaning and recovery boundary |
|---|---|
| `unauthenticated` / `notOwner` | The account or ownership cannot be verified; the journey is not startable. |
| `missingCoordinates` | Either the fix or the itinerary start region is unavailable; no distance is invented. |
| `permissionDenied` | Permission has not been granted; the traveller can explicitly verify again. |
| `permissionPermanentlyDenied` / `locationRestricted` | The OS blocks the app; the action opens app settings rather than pretending to read a fix. |
| `servicesDisabled` | Permission and the device location switch are distinct; the action opens location settings. |
| `locationTimeout` | No bounded read completed; the traveller can retry. |
| `staleFix` / `inaccurateGps` | A fix exists but cannot prove the start; the UI asks for a fresh or clearer reading. |
| `wrongCity` | The measured distance is shown with the expected start region and directions recovery; it is not relabelled as a permission problem. |
| `dateMismatch` | The traveller is at the region but too early for the destination-local start window. |
| `conflictWithActiveTrip` | Another journey is already under way; only explicit traveller resolution can clear it. |

No fix is presented as a position. A fix on an active journey can support an
**Inferred from location** label, but it does not prove arrival at an activity.
Only the traveller's **I'M HERE** action produces **Confirmed by you**. Offline
is shown only after a real read or write failure, and the last-updated label is
the timestamp of a real successful operation or the honest absence
**Not yet synced**. The surface does not invent speed, ETA, battery, a buddy,
progress telemetry, route intent, or an emergency dispatch claim.

After a journey is active, a measured distance outside the start region may be
shown as **OFF THE PLANNED REGION**. This is a measurement and recovery prompt,
not proof that the traveller is lost or that a replan is required.

## Day-context and activity presentation rules

The itinerary supplies the day context; mobile does not manufacture it.

- **Chapters Overview** preserves the backend-provided `dayPlans` order and
  renders each plan's actual `dayNumber`. It does not renumber a non-sequential
  response from list position.
- **Day in Motion** selects a local day-plan index from that same ordered list.
  A refreshed itinerary with fewer day plans clamps the index to a valid day.
  The view mode and selected index are transient UI state; they are not written
  to Firestore or Hive.
- The context card renders only supplied, non-empty theme, date, area-focus,
  and weather/context values. Weather is labelled as itinerary-provided
  context; mobile does not imply a fresh weather lookup or a guarantee.
- If no context fields are supplied, the card says **No additional day context
  was provided**. If a selected day has no activities, the view says that no
  activity details were provided for that day.
- Activity title, time, description, location, category, duration, estimated
  cost, booking advisory, meal context, warnings, source, and transfer details
  are conditional on the parsed itinerary. A missing or generic title is
  presented as unavailable rather than replaced with a plausible stop.
- The itinerary's optional `activityId` is retained when supplied, but it is
  not by itself a verified cross-system replan identity. Live check-in keys
  remain positional (`<dayIndex>:<activityIndex>`) and are not a revision or
  receipt protocol.

Missing data produces an explicit incomplete/unavailable state. It does not
become sample content, a guessed date, a guessed theme, an inferred city
centre, or a fabricated activity.

## Coordinate-only activity map handoff

The itinerary map card is available only when the selected day contains at
least one activity with valid, finite coordinates supplied by the itinerary:

- latitude must be within `-90..90`;
- longitude must be within `-180..180`; and
- both values must be present and finite.

A location string, destination name, place title, or curated city centre is not
geocoded into an activity marker. With no usable coordinates, the map action is
disabled and the UI says **Activity map unavailable: no itinerary coordinates
were provided**. The disabled state is a contract, not a loading failure.

When coordinates exist, the activity-location sheet lists only those
coordinate-backed activities and passes an in-memory coordinate-backed
`PlaceModel` to the existing `/map` route. An explicit activity `placeId` may
be reused; otherwise the client may construct a deterministic in-memory
handoff ID from the itinerary/day/index. That fallback ID is not a backend
identity and is not persisted.

The existing map screen displays coordinates and hands them to the device's
maps app. This phase adds no map SDK, geocoder, route line, travel-time result,
turn-by-turn navigation contract, or new map backend. A map handoff is not
evidence that a place was visited.

## Manual check-in boundaries

The traveller is the source of truth for what happened at a waypoint. The
live rail derives its order from the itinerary and pairs each position with a
local `TripCheckIn` value:

| Check-in | Meaning |
|---|---|
| `pending` | No traveller report; the waypoint remains unlogged. |
| `arrived` / **I'M HERE** | The traveller reports standing at the waypoint; it is not complete and remains **NOW**. |
| `completed` / **COMPLETE** | The traveller reports that the waypoint was visited and finished; the rail advances. |
| `skipped` / **SKIP** | The traveller deliberately passed it over; it counts as logged but never as completed. |

Check-ins are stored locally in the existing itinerary Hive box under an
owner-and-trip-scoped check-in key and survive a controller/app restart. They
do not require a network request, do not mutate the authoritative itinerary,
and do not claim server persistence. Unowned legacy check-in keys are rejected
rather than attributed to the current account; the pre-Phase-5 unscoped format
cannot be safely migrated without an owner receipt. **Undo check-in** clears
the local report and returns the waypoint to the rail. A local write failure
rolls back to the last confirmed snapshot and is shown as an action error;
rapid actions are serialized so a failed earlier write cannot leave a later
optimistic state looking persisted. The shared box must remain intact:
itinerary cache replacement or account cleanup must not wholesale-clear
check-ins or another owner's cache.

An itinerary activity's server-side `isCompleted` can provide an initial
completed presentation when there is no contradictory local report. A local
traveller report wins for the live rail. GPS proximity, a fix, passing time,
opening a map, or completing every visible card never auto-completes a stop.

## Replanning is unavailable in this mobile phase

Mobile deliberately exposes no **Replan**, proposal review, or **Accept
replan** action. There is no mobile repository call, local editor, optimistic
mutation, queued mutation, or fallback that rewrites a day when a traveller is
off-region or skips a stop. The current itinerary and its manual check-ins
remain the visible record.

The audited Website endpoints are not a compatible mobile contract:

- the Website replan implementation targets `users/{uid}/trips`, while mobile
  authority is `users/{uid}/itineraries`;
- Website activity IDs and revision/base-revision semantics do not line up with
  the mobile itinerary and positional check-in model;
- the Website acceptance request does not return an updated itinerary that
  mobile could safely reconcile; it returns success/already-accepted status;
- stale, missing, provider, and related implementation failures collapse into
  broad HTTP errors in the audited route instead of a mobile-safe typed result.

Consequently, calling the Website route from mobile could produce a proposal
or acceptance acknowledgement without a trustworthy owner document,
activity/check-in mapping, revision comparison, or updated itinerary. It is
disabled rather than presented as a partially working feature. Replan requires
an explicitly aligned authority, activity identity, revision/conflict, updated
itinerary response, and receipt contract before mobile can opt in.

This is a contract limitation, not a claim that the Website route was removed
or that the backend was changed by Phase 5. The audited endpoint remains
recorded as available-but-unused in
[`api_contract_matrix.md`](api_contract_matrix.md).

## Unsupported claims and external limitations

Do not infer any of the following from the mobile surface:

- background or continuous location tracking;
- automatic arrival, completion, skip, or route-deviation correction;
- a server receipt for a direct generation preview or local check-in;
- a server-side replan, revision merge, or updated itinerary;
- atomic multi-device enforcement of one active journey;
- a map route, geocoder, travel time, or directions result produced by mobile;
- a guarantee that an external maps app, OS settings page, dialer, Firebase
  service, location provider, or Firestore rule is available on a device.

The active owner document and Firestore rules remain authoritative. The mobile
client fails closed where owner, lifecycle, location, coordinate, or response
information is missing instead of inventing a value.

## Verification record

Checks run against the final local Phase 5 tree with Flutter 3.35.4 / Dart 3.9.2:

- Focused live controller, live page, lifecycle, location, model and identity
  coverage: **62 tests passed**.
- Full Flutter test suite: **230 tests passed**.
- `dart format .`: **141 files formatted, 1 file changed during the final
  formatting pass**.
- `flutter analyze`: **no issues found**.
- `git diff --check`: passed.

The full suite includes the Phase 0–4 regression coverage. No Website/backend,
Firestore rules, native-device, deployed-service, Firebase-provider, external
maps, or OS location matrix was run; those remain real runtime limitations.
