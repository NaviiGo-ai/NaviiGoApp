# Mobile API Contract Matrix

**Audited Website commit:** `a7fd4249128994fedf64576ab59458b44d695ad` on
`NaviiGo-Website/main`.

**Base URL:** `AppConfig.apiBaseUrl` (production default
`https://naviigo-website.onrender.com`). `ApiClient` joins this base with the
path below and attaches `Authorization: Bearer <Firebase ID token>` when
`requiresAuth` is true.

## Important mounting finding

The Website has two route families in the current checkout:

1. Legacy/AI routers are mounted by `backend/main.py` below `/api/*`.
2. SQL trips/bookings/payments/wallet routers declare their own `/trips`,
   `/bookings`, `/payments`, and `/wallet` prefixes, but `main.py` includes
   them **without** an additional `/api` prefix. Therefore their actual
   FastAPI paths are root-level (`/wallet/*`, etc.) in this source revision.

The matrix records the actual mounted path, not the path suggested by an old
client or a planning document. The Website should be changed in a separate
backend-contract phase if `/api/wallet/*` and `/api/bookings/*` are intended.

## Endpoints used by the current mobile client

| Method | Actual path | Auth | Request schema | Response schema | Errors | Mobile repository | Coverage |
|---|---|---|---|---|---|---|---|
| `POST` | `/api/itinerary/generate` | Required; token UID is authoritative | `destName` required; optional `destination`, `purpose`, `group`, `days` 1–14, `budget`, `startDate`, `travelerType`, `preferences`, `browsingSignals`, arrival/departure logistics, `hotelArea`, `originCity`, `mustDo`, `routeStops[]` | `{success, itinerary, source, dataSources?, userId}`; itinerary contains `dayPlans`, weather/provenance fields as available | `400` invalid payload/route, `401` absent/invalid Firebase token, `429` rate limit, `503` unavailable destination, `500` generation failure | `TripRepository.generateItineraryFromBackend` | **Covered**; path and payload match |
| `GET` | `/api/places/autocomplete` | Public | Query `input`; fewer than 2 chars returns empty predictions | `{predictions:[{description, place_id, sub}]}` | Network errors are normalized by mobile to an empty list; backend degrades to empty list | `PlacesRepository.searchAutocomplete` | **Covered** |
| `GET` | `/api/places/` | Public | Query `lat`, `lng`, `type`, `radius` | `{places:[{name, vicinity, type, priceLevel, placeId, photo, lat, lng}]}` | Backend returns `{places:[]}` on provider failure | `PlacesRepository.getNearbyPlaces` | **Covered**; trailing slash is equivalent under FastAPI redirect |
| `GET` | `/api/places/details` | Public | Query `lat`, `lng`, `type`, `query`, `radius` | `{success, results:[{id,name,rating,userRatingsTotal,priceLevel,vicinity,lat,lng,isOpen,types,photo}], total?}` | Missing provider key returns honest empty results; upstream failure returns empty/error result | `PlacesRepository.getPlaceDetails` | **Covered** |
| `GET` | `/api/weather/` | Public | Optional query `lat`, `lng` | `{current, daily, source}`; unavailable data is `current:null`, `daily:[]`, `source:"none"` | Provider failure is represented as unavailable data | `PlacesRepository.getWeather` and weather providers | **Covered** |
| `POST` | `/api/explore/events` | Public | `{destination:string}` | `{events:[...]}` | `400` missing destination, `500` upstream failure | `PlacesRepository.getEvents` | **Covered** |
| `POST` | `/wallet/coupons/apply` | Required | `{code:string, bookingAmountMinor:int >= 0}` | `{code, discountType, discountValue, discountAmountMinor, finalAmountMinor, description?}` | Auth, validation, coupon eligibility/expiry errors | `WalletRepository.validateCoupon` | **Corrected**; old mobile path `/api/wallet/coupons/apply` was not mounted by current Website |
| `POST` | `/wallet/debit` | Required | `{amountMinor:int > 0, referenceId?, idempotencyKey?, description?}` | `WalletTransactionRead`: transaction ID, wallet/user IDs, type/direction, amount/balance, status, references, timestamps | Auth, validation, insufficient/locked wallet, idempotency/state errors | `WalletRepository.requestDebit` | **Corrected** |
| `POST` | `/wallet/refund` | Required | `{amountMinor:int > 0, referenceId?, idempotencyKey?, reason?}` | `WalletTransactionRead` | Auth, validation, idempotency/state errors | `WalletRepository.requestRefund` | **Corrected** |

## Production endpoints available but not currently called by mobile

| Method | Actual path | Auth | Request schema | Response schema | Error states | Mobile coverage |
|---|---|---|---|---|---|---|
| `POST` | `/api/itinerary/from-link` | Public in current router | `{url?, captionText?}` | `{success, extracted}` | `400` invalid link, `500` extraction failure | Unused |
| `POST` | `/api/itinerary/replan` | Required | `{tripId, currentDay, currentTime, reason, completedActivityIds[], skippedActivityIds[], location?, destinationTimezone?, baseRevisionId?}` | `{success, proposal}` | `401`, `404`, stale/data/provider failures currently collapse to router `500` in implementation | Unused; frozen contextual-replanning backend not changed |
| `POST` | `/api/itinerary/replan/accept` | Required | `{tripId, proposalId, proposalData}`; server re-reads proposal and validates revision | `{success}` or `{success,message:"Already accepted"}` | `401`, `404`, `409 STALE_PROPOSAL`, implementation-level `500` | Unused; no client business logic added |
| `POST` | `/api/chat/` | Public in current router | `{message, context?, currentPlans?, itineraryContext?}` | AI service result, typically reply/content fields | `502` upstream AI, `503` missing AI provider configuration | Unused |
| `POST` | `/api/recommendations/` | Public in current router | Optional `userId`, `budget`, `month`, `group`, `purpose`, `preferences`, `pastDestinations`, `tasteVector`, `browsingSignals` | `{success, recommendations:[...]}` | Current router maps failures to `500`; user context enrichment is server-side | Unused; personalization is not duplicated |
| `POST` | `/api/explore/deep-dive` | Public | `{destination, companion?, vibe?}` | Deep-dive object from server engine | `500` provider/engine failure | Unused |
| `GET` | `/api/transport/` | Public | Query `fromLat`, `fromLng`, `toLat`, `toLng`; all required | `{distance, source, options:[{mode,emoji,duration,cost,tip}]}` | `400` missing coordinates; provider fallback may return `source:haversine` | Unused; mobile transportation UI is not an API repository yet |
| `POST` | `/api/taste/update` | Public in current router | Optional `userId`, `currentVector`, `selectedDestId`, `selectedTags[]`, `purpose` | `{success, newVector}` | `500` embedding failure/provider failure | Unused; client must not reproduce EMA/vector algorithm |
| `GET` | `/api/places/photo` | Public proxy; provider key server-side | Query `name` resource `places/{id}/photos/{photoId}`, optional `maxwidth` | Image bytes | `400` missing key/invalid resource, `502` unavailable photo, `500` proxy failure | Unused directly; image URLs may be carried by place response |
| `GET` | `/api/places/osm/verify` | Public in current router | None | Verification/status object | Provider/service errors | Unused |
| `POST` | `/api/analytics/track` | Required; UID from bearer token | `{events:[{eventId,schemaVersion,eventType,occurredAt,receivedAt?,tripId?,dayId?,activityId?,placeId?,destinationId?,sessionId?,context?,metadata?}]}` | `{status:"accepted", count}` | `401` invalid/missing token; validation/rate-limit errors | `AnalyticsRepository` queue; corrected path |
| `POST` | `/api/analytics/reset` | Required | Empty body | `{status:"accepted"}` | `401` invalid/missing token | Unused |

## SQL API routes present in Website source

These are **not `/api/*` in the current `backend/main.py` mount**. They use a
separate SQL database and `CurrentUserId` Firebase dependency. They are listed
so mobile work does not infer a route from the filename or expected family.

| Method | Actual path | Request/response | Mobile status |
|---|---|---|---|
| `POST`/`GET` | `/trips`, `/trips/{tripId}` | `TripCreate`/`TripRead`, summary list; UUID IDs; owner-only | Not called; mobile uses Firestore itinerary contract |
| `PATCH` | `/trips/{tripId}` | `TripUpdate` → `TripRead` | Not called |
| `POST` | `/trips/{tripId}/status` | `{status, reason?}` → `TripRead` | Not called |
| `POST` | `/trips/{tripId}/days`, `/trips/{tripId}/days/{dayId}/items` | Typed day/item payloads → `TripRead` | Not called |
| `PATCH`/`DELETE` | `/trips/{tripId}/items/{itemId}` | Typed item update → `TripRead` | Not called |
| `POST` | `/trips/{tripId}/undo` | Empty body → `TripRead` | Not called |
| `GET` | `/trips/{tripId}/versions` | `limit` query → version list | Not called |
| `POST` | `/trips/{tripId}/chat` | `{message}` → `{reply, trip}` | Not called |
| `POST`/`GET` | `/bookings`, `/bookings/{bookingId}` | `BookingCreate` → `BookingRead`; owner-only | Not called; mobile booking display is Firestore-backed |
| `POST` | `/bookings/{bookingId}/cancel`, `/bookings/{bookingId}/confirm` | cancel reason or empty body → `BookingRead` | Not called |
| `POST` | `/payments/order` | `{booking_id, method?, description?, idempotency_key}` → `PaymentRead` | Not called |
| `POST` | `/payments/verify` | Razorpay order/payment/signature IDs → `PaymentRead` | Not called |
| `POST` | `/payments/webhook` | Raw Razorpay body + `X-Razorpay-Signature` | Server webhook only; never mobile |
| `GET` | `/wallet/account` | Empty body → authoritative `WalletAccountRead` | Not called; mobile currently streams Firestore wallet account |
| `GET` | `/wallet/transactions?limit=1..100` | Empty body → `WalletTransactionRead[]` | Not called; mobile currently streams Firestore ledger |

## Firebase/Firestore contracts used alongside HTTP

- `users/{uid}`: profile counters and identity metadata.
- `users/{uid}/preferences/main`: travel style, group, interests, diet,
  accessibility, home city, recent searches.
- `users/{uid}/ai_profile/main`: server-owned taste vector and browsing signals.
- `users/{uid}/itineraries/{id}`: generated/saved itineraries and lifecycle
  flags.
- `users/{uid}/bucketList/{id}`: saved places.
- `users/{uid}/passport/stats` and `users/{uid}/passport/entries/{id}`:
  passport state as used by current mobile repository.
- `users/{uid}/bookings/{id}`: current mobile booking stream; production
  Website frontend also documents redirect-truthful booking fields.
- Named Firestore database: `naviigo-db`.

Firestore owner rules are the Website contract: user subcollections are owner
only, public itinerary reads require explicit sharing, and destination metadata
is read-only to clients.
