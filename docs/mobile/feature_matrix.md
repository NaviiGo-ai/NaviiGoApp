# Mobile Feature Matrix — Phase 0

Status describes the clean baseline after auditing `rebuild/hardening`, its
parents, current mobile `main`, and Website `main`.

| Area | Existing mobile boundary | Source of truth | Phase 0 status |
|---|---|---|---|
| Auth/onboarding | Firebase Auth + Firestore preferences | Firebase and Website user context | Preserved |
| Home shell | Riverpod dashboard streams and curated destination registry | Firestore `destinations` plus existing curated assets | Preserved |
| Explore/places | `PlacesRepository` via `/api/places/*` | Website places router | Contract audited |
| Itinerary generation | `TripRepository.generateItineraryFromBackend` | Website `/api/itinerary/generate` | Contract audited |
| Saved trips | Firestore stream + Hive fallback | `users/{uid}/itineraries` | Preserved |
| Trip lifecycle | `TripStatus`, validation service, active-trip providers | Confirmed Firestore status and dates | Preserved |
| Journey Line | Shared widget used by planning/live surfaces | Mobile presentation of real itinerary sequence | Preserved |
| Active trip/location | Platform location adapter and live fix model | Device location plus confirmed trip data | Preserved; no fake telemetry |
| Profile/preferences | User repository and preferences model | Firestore `users/{uid}` and `preferences/main` | Preserved |
| Saved places | Bucket list repository | Firestore `users/{uid}/bucketList` | Preserved |
| Passport/reviews | Passport repository and post-trip surface | Firestore passport contract | Preserved |
| Analytics queue | Hive queue + Website `/api/analytics/track` | Website analytics router | Restored with corrected path; wiring remains incremental |
| Personalization | Event payloads and taste data | Website analytics/taste services | Client does not duplicate algorithm |
| Wallet | Read streams plus server mutation methods | Website wallet API/Firestore contract | Endpoint mismatch documented and corrected |
| Bookings/payments | Existing local booking display; no mobile SQL API client | Website redirect/booking/payment contracts | Not expanded in Phase 0 |
| AR | Existing truthful waypoint presentation | Real place/itinerary data only | No fake AR implementation |
| Adaptive experience | Documentation contract only | Brand tokens + lifecycle/profile context | Deferred to later phase |

## Deliberately discarded from the corrupt commit

- Wholesale `ongoing_trips_page.dart` replacement.
- Duplicate activity/model fields and duplicate widget declarations.
- Hard-coded buddy, weather, ETA, distance, cost, and booking claims.
- Any client-side replacement for server personalization or wallet authority.
