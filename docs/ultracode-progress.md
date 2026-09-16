# Naviigo Mobile — Durable Progress Document
*Last updated: 2026-09-16 | Branch: `rebuild/hardening`*

---

## 1. Architecture Decisions

- **Framework & State**: Flutter 3.x with Riverpod 2.x (`flutter_riverpod`, `hooks_riverpod`). State managed through domain-scoped StateNotifiers / Notifiers and AsyncValue providers.
- **Routing**: `go_router` 14.x with declarative routing, typed parameters, custom transition builder (`_page`), and bottom shell (`StatefulShellRoute.indexedStack` / `ShellRoute`) supporting 5 primary tabs (Home, Explore, Trips, Bookings, Profile).
- **Network & API Layer**: Native `http.Client` wrapped by `ApiClient` (`lib/core/network/api_client.dart`) with retry with exponential backoff (up to 3 retries on transient network errors), structured exceptions (`ApiException`, `ServerException`, `NetworkException`, `UnauthorizedException`), auth token injection from Firebase Auth, and timeout tiers.
- **Local Persistence & Cache**: `hive_flutter` for offline itinerary caching (`HiveService.itineraryBox`, `HiveService.preferencesBox`), cached responses, and immediate local UI updates.
- **Motion & Haptics System**:
  - `NavHaptics` ladder: strictly 3 levels (`light`, `medium`, `strong`). Call sites routed through one vocabulary.
  - `NavMotion` & `NavEnvironment`: standardized durations/curves, reduced-motion compliance (`reducedMotion`), and environmental lighting/palette adjustments.
  - Compaction: Shell bottom bar auto-collapses on scroll down and restores on scroll up / route transition (`navChromeCollapseProvider`).
- **No Mock/Fake Fallback Policy**: No fake data generation, no Unsplash URLs in place data, no client-side coupon/debit evaluations. Server owns validation and transactions.
- **Trip Lifecycle (single vocabulary)**: `TripStatus` — `draft`, `planned`, `upcoming`, `eligibleToStart`, `active`, `completed`, `cancelled` — lives in `trip_itinerary_model.dart` with a tolerant `fromString` that absorbs the strings already in Firestore (`active` / `past` / `in_progress`). `TripItineraryModel.tripStatus` returns the server-written `status` when present, otherwise derives it. **Derived `active` comes only from the explicit `isActive` flag — arriving on the calendar makes a trip `eligibleToStart`, never silently `active`. `activeTripProvider` strictly filters on `tripStatus == TripStatus.active` as the single canonical source of truth.**
- **Start-trip gating**: `TripValidationService` (`domain/services/`) is pure Dart — Haversine proximity, no geo plugin. It fails closed through eleven named gates in order: authenticated → owner (fail-closed if unowned) → no active-trip conflict → location permission → location services enabled → location timeout → coordinates present → fix freshness (≤ 5 min) → GPS accuracy (≤ 500 m) → proximity to the start region (≤ 25 km) → destination-local date. Each failure is a distinct `StartTripStatus`, and wrong-city carries distance + destination so the UI can render recovery without re-deriving.
- **Location Architecture**: Decoupled platform adapter pattern (`LocationAdapter` / `GeolocatorLocationAdapter` / `LiveFix` / `LocationResult`). Foreground-only location reads with bounded accuracy retry (< 500m, max 3 attempts, 2s delay), freshness validation (≤ 5 min), granular failure mappings, and explicit OS settings navigation.
- **Live journey state**: `LiveTripState` derives everything the live screen renders from three honest sources — the itinerary, the traveller's own check-ins, and the latest real fix — with no simulated telemetry, no progress percentage, and no buddy data. Check-ins (`arrived` / `completed` / `skipped`) persist through Hive and work offline. `LiveTripController` takes position from `LocationAdapter` (wired to `GeolocatorLocationAdapter` in production).

---

## 2. Backend Contract & Services

### Base URLs & Environment
- **Production Backend**: `https://naviigo-website.onrender.com` (FastAPI on Render)
- **Development Backend**: `http://localhost:8000` (Web/iOS/Desktop) or `http://10.0.2.2:8000` (Android Emulator)
- **Configuration Source**: `--dart-define=API_BASE_URL=...`, `--dart-define=APP_ENV=dev|stage|prod` via `lib/core/config/app_config.dart`.
- **Firebase Project**: `naviigo-firebase` | Named Firestore DB: `naviigo-db`
- **Timeouts**: Standard 15s, Connect 15s, Receive 30s, AI Generation 60s.

### FastAPI Endpoints

| Method | Endpoint | Auth | Purpose | Repository / Client |
|---|---|---|---|---|
| `GET` | `/api/places/autocomplete` | No | India-wide place search predictions (`input`) | `PlacesRepository.searchAutocomplete` |
| `GET` | `/api/places` | No | Nearby places query (`lat`, `lng`, `type`, `radius`) | `PlacesRepository.getNearbyPlaces` |
| `GET` | `/api/places/details` | No | Deep place details & photos (`lat`, `lng`, `type`, `query`) | `PlacesRepository.getPlaceDetails` |
| `GET` | `/api/weather` | No | Destination live weather conditions (`lat`, `lng`) | `PlacesRepository.getWeather` |
| `POST` | `/api/explore/events` | No | Destination cultural / live events (`destination`) | `PlacesRepository.getEvents` |
| `POST` | `/api/itinerary/generate` | Yes | Gemini AI multi-day itinerary generation | `TripRepository.generateAiItinerary` |
| `POST` | `/api/wallet/coupons/apply` | Yes | Server-side coupon validation & discount calculation | `WalletRepository.validateCoupon` |
| `POST` | `/api/wallet/debit` | Yes | Idempotent Naviigo Credit debit for booking checkout | `WalletRepository.requestDebit` |
| `POST` | `/api/wallet/refund` | Yes | Idempotent refund to Naviigo Credit balance | `WalletRepository.requestRefund` |

### Firestore Collections Hierarchy

```
users/{uid}
├── (fields: email, displayName, photoUrl, phone, createdAt, xpLevel, statesVisited)
├── preferences/default           (Budget, pace, interests, dietary, mobility, styles)
├── bookings/{bookingId}          (Hotel, flight, activity vouchers, PNR, status)
├── passport/{docId}              (Passport overview stats, verification level)
│   └── entries/{stampId}         (Verified travel stamps, state codes, timestamps)
├── bucketList/{placeId}          (Saved places, destination bookmarks, notes)
├── itineraries/{tripId}          (User-created / AI-generated trip plans)
├── wallet/{walletId}             (Balance in paise, points, active status)
└── wallet_transactions/{txId}    (Ledger history: credits, debits, refunds, refs)

destinations/{destId}             (Curated destination catalogue & metadata)
journal_articles/{articleId}      (Curated editorial travel stories)
premium_itineraries/{itinId}      (Signature multi-day expert routes)
```

---

## 3. Route Inventory & Screens

| Route Path | Widget | Feature Domain | Status |
|---|---|---|---|
| `/` | `SplashPage` | Splash / Bootstrap | Complete |
| `/login` | `LoginPage` | Auth | Complete |
| `/onboarding` | `OnboardingPage` | Auth / Onboarding | Complete |
| `/vibe-match` | `VibeMatchPage` | Onboarding / Preferences | Complete |
| `/destination/:id` | `DestinationDetailPage` | Destinations / Explore | Complete (Hero transitions wired) |
| `/place-details` | `PlaceDetailsPage` | Places | Complete |
| `/restaurant/:id` | `RestaurantDetailPage` | Places / Dining | Complete |
| `/trip-planner` | `TripPlannerPage` | Trips / Wizard | Complete |
| `/home` | `HomePage` | Dashboard / Feed | Complete (Lifecycle-aware) |
| `/explore` | `ExplorePage` | Explore | Complete |
| `/explore-discover` | `ExploreDiscoverPage` | Explore | Complete |
| `/places` | `PlacesPage` | Places | Complete |
| `/trips` | `TripsPage` | Trips / Hub | Complete |
| `/digital-passport` | `DigitalPassportPage` | Bookings / Passport | Complete (Route disambiguation verified) |
| `/profile` | `ProfilePage` | Profile / Preferences | Complete |
| `/itinerary` | `ItineraryPage` | Trips / Timeline | Complete (Day-in-motion, budget stats) |
| `/upcoming-trips` | `UpcomingTripsPage` | Trips | Complete |
| `/ongoing-trips` | `OngoingTripsPage` | Trips | Complete |
| `/live-tracking` | `LiveTrackingPage` | Dashboard / Live Journey | Hardened (Lifecycle-gated start, manual check-in, real SOS 112) |
| `/past-trips` | `PastTripsPage` | Trips | Complete |
| `/analytics` | `AnalyticsPage` | Profile / Insights | Complete |
| `/hidden-gems` | `HiddenGemsPage` | Explore | Complete |
| `/restaurants` | `RestaurantsPage` | Places / Dining | Complete |
| `/transportation` | `TransportationPage` | More / Logistics | Complete |
| `/local-guides` | `LocalGuidesPage` | More / Concierge | Complete |
| `/map` | `MapPage` | More / Navigation | Complete |
| `/ar-explore` | `ArExplorePage` | More / AR | Complete |
| `/saved-places` | `SavedPlacesPage` | Bookings / Bucket List | Complete |
| `/payment-history` | `PaymentHistoryPage` | Wallet | Complete |
| `/bookings` | `BookingsPage` | Bookings | Complete |
| `/story-creator` | `StoryCreatorPage` | More / Story Maker | Complete |
| `/settings` | `SettingsPage` | Profile / Settings | Complete |
| `/help-support` | `HelpSupportPage` | Profile / Support | Complete |

---

## 4. Test Suite & Health

- **Total Test Files**: 12
- **Total Unit & Widget Tests**: 119
- **Passing Status**: 119 / 119 (100%)
- **Analyzer Status**: 0 errors, 0 warnings, 0 lints (`flutter analyze` clean)
- **Test Files**:
  - `test/api_client_and_resilience_test.dart`
  - `test/live_tracking_page_test.dart` — start gate, wrong-city recovery, live sections, closed journeys
  - `test/live_trip_controller_test.dart` — check-in rail, confidence, gating, deviation, sync honesty
  - `test/location_and_active_trip_test.dart` — platform adapter behaviors, fail-closed accuracy/freshness, active trip canonical truth, multiple active trip conflict prevention
  - `test/motion_contract_test.dart`
  - `test/navigation_shell_test.dart`
  - `test/network_and_api_client_test.dart`
  - `test/trip_itinerary_model_test.dart`
  - `test/trip_validation_test.dart` — lifecycle enum, `copyWith`, Haversine, all eleven start gates
  - `test/user_profile_and_passport_test.dart`
  - `test/wallet_and_places_test.dart`
  - `test/widget_test.dart`

---

## 5. Completed Hardening & Changes (Recent)

1. **Navigation Shell & Chrome Compaction**:
   - Wired `navChromeCollapseProvider` to actual scroll notifications (`UserScrollNotification` direction + `ScrollUpdateNotification` position).
   - Chrome automatically resets to expanded on route transitions.
2. **Haptics Unification**:
   - Replaced fragmented `HapticFeedback` invocations across 11 files with a single `NavHaptics.fire(NavHaptic.light | medium | strong)`.
3. **Live Companion Honest Hardening**:
   - Removed fabricated buddy live-sharing state and non-existent safety sync claims.
   - Fixed SOS emergency button to directly invoke native 112 emergency dialer.
   - Cleaned hard-coded fake distance tiles; linked local essentials to real Maps intents.
   - Added atmospheric motion compliance with `reducedMotion` accessibility checks.
4. **Flagship Motion & Hero Transitions**:
   - Explore → Destination card Hero tag alignment (`destination-<id>`).
   - Pinned animation duration bounds and curves in `motion_contract_test.dart`.
5. **Passport & Waypoint Accuracy**:
   - Fixed `DigitalPassportPage` saved place tap routing: disambiguates city destinations (`/destination/:id`) from specific venue cards (`/place-details`).
   - Removed artificial multiplier padding (`totalDays * 3`) in `ItineraryStatsRow` when waypoints count is 0.
   - De-duplicated a repeated test name in `user_profile_and_passport_test.dart`.
6. **Trip Lifecycle & Start Validation (vertical slice)**:
   - Added the `TripStatus` enum, `copyWith` on all three trip models, and the `userId` / `startLat` / `startLng` / `status` fields the start gate needs. Start coordinates fall back to the curated destination registry, which also supplies `startRegionName` for user-facing copy.
   - Added `TripValidationService` with the eleven fail-closed gates and a typed `StartTripValidationResult`.
   - Gate 2 hardened to fail closed on missing or empty owner IDs (`StartTripStatus.notOwner`), and `userId` stamped on itinerary creation in `TripRepository` and `TripPlannerPage`.
   - Removed unvalidated direct trip activation bypass in `generated_itinerary_page.dart` (now routes directly to `/live-tracking` start gate).
7. **Platform Location Adapter & Canonical Active Trip**:
   - Implemented `GeolocatorLocationAdapter` using `geolocator: ^14.0.2` with foreground-only reads, bounded accuracy retry loop (< 500m, max 3 attempts, 2s delay), freshness validation (≤ 5 min), granular failure mappings, and explicit OS settings navigation (`openAppSettings`, `openLocationSettings`).
   - Declared Android permissions (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) and iOS privacy strings (`NSLocationWhenInUseUsageDescription`).
   - Replaced date-matching heuristic `isCurrentlyActive` with `activeTripProvider` / `activeTripsProvider` strictly selecting trips where `t.tripStatus == TripStatus.active`.
   - Handled multiple active trip conflicts with UI warning/recovery cards and atomic Firestore batch cleanup in `TripRepository.setActiveTrip`.
8. **Live Journey Screen**:
   - Rebuilt `LiveTrackingPage` around NOW / NEXT / ROUTE / BOOKINGS / BUDDY / LOCAL / SAFETY.
   - Wrong-city state names the destination and distance and offers all four recovery actions (Get Directions, View Trip, Try Location Again, Pre-Trip Mode).
   - Manual check-in (`I'M HERE` / `COMPLETE` / `SKIP`) with undo; `SKIP` is recorded as skipped, never as completed. Arrival confidence is labelled "Confirmed by you" or "Inferred from location".
   - Route deviation states a measured distance and that nothing is shared automatically. Offline shows a real `Last Updated`, or "Not yet synced".
   - Bookings lists only vouchers whose airport/station code resolves to the destination. Local essentials and directions hand off to the device maps app — no invented nearby places.

---

## 6. Known Blockers & External Dependencies

- **Render FastAPI Cold Start**: Free/low tier Render instances take 30–50s on initial cold request. `AppConfig.connectTimeout` and `aiGenerationTimeout` (60s) accommodate this.
- **Firebase Auth on Native Emulators**: Requires configured `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) with valid SHA-1 for Google Sign-In.

---

## 7. Next Recommended Tasks

1. **Sync check-ins to Firestore**: `LiveTripController.logCheckIn` is local-first via Hive today. Add a repository write and a conflict rule so a second device sees the same rail.
2. **Story Creator & Export Hardening**: Audit `lib/features/more/presentation/pages/story_creator_page.dart` for canvas export, permissions, and Instagram Stories sharing contracts.
3. **Booking Flow & Wallet Checkout End-to-End**: Test end-to-end integration between `BookingsPage`, `WalletRepository.requestDebit`, and itinerary reservation hooks.
4. **Offline Sync & Reconnection Flow**: Enhance `HiveService` cache invalidation when internet reconnects after offline itinerary viewing.
