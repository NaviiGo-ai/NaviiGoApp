# Mobile API Contract Matrix

**Audited Website commit:** `a7fd4249128994fed167e4a89ba97fc054e2f958` on
`NaviiGo-Website/main`.

**Base URL:** `AppConfig.apiBaseUrl` (production default
`https://naviigo-website.onrender.com`). `ApiClient` joins this base with the
path below and attaches `Authorization: Bearer <Firebase ID token>` when
`requiresAuth` is true.

## Actual FastAPI mounting

`backend/main.py` mounts the analytics, bookings, payments, and wallet route
groups under `/api/analytics`, `/api/bookings`, `/api/payments`, and
`/api/wallet`. Router-level prefixes then determine the final path:

- `routers/analytics.py` has no additional prefix, so analytics is
  `/api/analytics/track` and `/api/analytics/reset`.
- `app/api/wallet.py` has no additional prefix, so wallet is
  `/api/wallet/account`, `/api/wallet/transactions`, `/api/wallet/debit`,
  `/api/wallet/refund`, and `/api/wallet/coupons/apply`.
- `app/api/bookings.py` declares `prefix="/bookings"`, so the effective SQL
  booking paths are double-prefixed under the mount:
  `/api/bookings/bookings`, `/api/bookings/bookings/{booking_id}`,
  `/api/bookings/bookings/{booking_id}/cancel`, and
  `/api/bookings/bookings/{booking_id}/confirm`.
- `app/api/payments.py` declares `prefix="/payments"`, so the effective SQL
  payment paths are `/api/payments/payments/order`,
  `/api/payments/payments/verify`, and `/api/payments/payments/webhook`.
- `backend/app/api/trips.py` exists but is not included by `backend/main.py`.
  Its declared SQL trip routes are therefore currently not mounted.

These paths are recorded as-is. This phase does not normalize or redesign the
Website route mounting.

## Endpoints used by the current mobile client

| Method | Actual path | Auth | Request schema | Response schema | Errors | Mobile repository | Coverage |
|---|---|---|---|---|---|---|---|
| `POST` | `/api/itinerary/generate` | Required; token UID is authoritative | `destName` required; optional `destination`, `purpose`, `group`, `days` 1–14, `budget`, `startDate`, `travelerType`, `preferences`, `browsingSignals`, arrival/departure logistics, `hotelArea`, `originCity`, `mustDo`, `routeStops[]` | `{success, itinerary, source, dataSources?, userId}`; itinerary contains `dayPlans`, weather/provenance fields as available | `400` invalid payload/route, `401` absent/invalid Firebase token, `429` rate limit, `503` unavailable destination, `500` generation failure | `TripRepository.generateItineraryFromBackend` | **Covered**; path and payload match |
| `GET` | `/api/places/autocomplete` | Public | Query `input`; fewer than 2 chars returns empty predictions | `{predictions:[{description, place_id, sub}]}` | Network errors are normalized by mobile to an empty list; backend degrades to empty list | `PlacesRepository.searchAutocomplete` | **Covered** |
| `GET` | `/api/places/` | Public | Query `lat`, `lng`, `type`, `radius` | `{places:[{name, vicinity, type, priceLevel, placeId, photo, lat, lng}]}` | Backend returns `{places:[]}` on provider failure | `PlacesRepository.getNearbyPlaces` | **Covered**; trailing slash is equivalent under FastAPI redirect |
| `GET` | `/api/places/details` | Public | Query `lat`, `lng`, `type`, `query`, `radius` | `{success, results:[{id,name,rating,userRatingsTotal,priceLevel,vicinity,lat,lng,isOpen,types,photo}], total?}` | Missing provider key returns honest empty results; upstream failure returns empty/error result | `PlacesRepository.getPlaceDetails` | **Covered** |
| `GET` | `/api/weather/` | Public | Optional query `lat`, `lng` | `{current, daily, source}`; unavailable data is `current:null`, `daily:[]`, `source:"none"` | Provider failure is represented as unavailable data | `PlacesRepository.getWeather` and weather providers | **Covered** |
| `POST` | `/api/explore/events` | Public | `{destination:string}` | `{events:[...]}` | `400` missing destination, `500` upstream failure | `PlacesRepository.getEvents` | **Covered** |
| `POST` | `/api/wallet/coupons/apply` | Required | `{code:string, bookingAmountMinor:int >= 0}` | `{code, discountType, discountValue, discountAmountMinor, finalAmountMinor, description?}` | Auth, validation, coupon eligibility/expiry errors | `WalletRepository.validateCoupon` | **Covered** |
| `POST` | `/api/wallet/debit` | Required | `{amountMinor:int > 0, referenceId?, idempotencyKey?, description?}` | `WalletTransactionRead`: transaction ID, wallet/user IDs, type/direction, amount/balance, status, references, timestamps | Auth, validation, insufficient/locked wallet, idempotency/state errors | `WalletRepository.requestDebit` | **Covered** |
| `POST` | `/api/wallet/refund` | Required | `{amountMinor:int > 0, referenceId?, idempotencyKey?, reason?}` | `WalletTransactionRead` | Auth, validation, idempotency/state errors | `WalletRepository.requestRefund` | **Covered** |

## Production endpoints available but not currently called by mobile

| Method | Actual path | Auth | Request schema | Response schema | Error states | Mobile coverage |
|---|---|---|---|---|---|---|
| `POST` | `/api/itinerary/from-link` | Public in current router | `{url?, captionText?}` | `{success, extracted}` | `400` invalid link, `500` extraction failure | Unused |
| `POST` | `/api/itinerary/replan` | Required | `{tripId, currentDay, currentTime, reason, completedActivityIds[], skippedActivityIds[], location?, destinationTimezone?, baseRevisionId?}` | `{success, proposal}` | The broad router handler can collapse auth, missing-trip, stale/data/provider failures into `500` | **Disabled/unused**; Website authority targets `users/{uid}/trips`, while mobile authority is `users/{uid}/itineraries`; activity/revision/receipt contract is not aligned |
| `POST` | `/api/itinerary/replan/accept` | Required | `{tripId, proposalId, proposalData}`; server re-reads proposal and validates revision | `{success}` or `{success,message:"Already accepted"}`; no updated itinerary is returned | Intended `409 STALE_PROPOSAL` and resource/auth failures are not reliable through the broad `500` handler | **Disabled/unused**; no mobile acceptance or reconciliation logic |
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

These use a separate SQL database and `CurrentUserId` Firebase dependency. The
effective paths below include both the `main.py` mount and each router's own
prefix. They are listed so mobile work does not infer a route from the filename
or expected family.

| Method | Actual path | Request/response | Mobile status |
|---|---|---|---|
| `POST`/`GET` | **Not mounted** | `backend/app/api/trips.py` declares `/trips` routes, but `backend/main.py` does not include this router | Not called; mobile uses Firestore itinerary contract |
| `POST`/`GET` | `/api/bookings/bookings`, `/api/bookings/bookings/{bookingId}` | `BookingCreate` → `BookingRead`; owner-only | Not called; mobile booking display is Firestore-backed |
| `POST` | `/api/bookings/bookings/{bookingId}/cancel`, `/api/bookings/bookings/{bookingId}/confirm` | cancel reason or empty body → `BookingRead` | Not called |
| `POST` | `/api/payments/payments/order` | `{booking_id, method?, description?, idempotency_key}` → `PaymentRead` | Not called |
| `POST` | `/api/payments/payments/verify` | Razorpay order/payment/signature IDs → `PaymentRead` | Not called |
| `POST` | `/api/payments/payments/webhook` | Raw Razorpay body + `X-Razorpay-Signature` | Server webhook only; never mobile |
| `GET` | `/api/wallet/account` | Empty body → authoritative `WalletAccountRead` | Not called; mobile currently streams Firestore wallet account |
| `GET` | `/api/wallet/transactions?limit=1..100` | Empty body → `WalletTransactionRead[]` | Not called; mobile currently streams Firestore ledger |

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
