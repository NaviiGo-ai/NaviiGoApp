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
| `/live-tracking` | `LiveTrackingPage` | Dashboard / Live Companion | Hardened (Honest telemetry, real SOS 112) |
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

- **Total Test Files**: 8
- **Total Unit & Widget Tests**: 59
- **Passing Status**: 59 / 59 (100%)
- **Analyzer Status**: 0 errors, 0 warnings, 0 lints (`flutter analyze` clean)
- **Test Files**:
  - `test/api_client_and_resilience_test.dart`
  - `test/motion_contract_test.dart`
  - `test/navigation_shell_test.dart`
  - `test/network_and_api_client_test.dart`
  - `test/trip_itinerary_model_test.dart`
  - `test/user_profile_and_passport_test.dart`
  - `test/wallet_and_places_test.dart`
  - `test/widget_test.dart`

---

## 5. Completed Hardening & Changes (Recent)

1. **Navigation Shell & Chrome Compaction**:
   - Wired `navChromeCollapseProvider` to actual scroll notifications (`UserScrollNotification` direction + `ScrollUpdateNotification` position).
   - Chrome automatically resets to expanded on route transitions.
2. **Haptics Unification**:
   - Replaced fragmented `HapticFeedback` invocations across 11 files with single `NavHaptics.fire(NavHapticType.light | medium | strong)`.
3. **Live Companion Honest Hardening**:
   - Removed fabricated buddy live-sharing state and non-existent safety sync claims.
   - Fixed SOS emergency button to directly invoke native 112 emergency dialer.
   - Cleaned hard-coded fake distance tiles; linked local essentials to real Maps intents.
   - Added atmospheric motion compliance with `reducedMotion` accessibility checks.
4. **Flagship Motion & Hero Transitions**:
   - Explore → Destination card Hero tag alignment (`destination-<id>`).
   - Pinned animation duration bounds and curves in `motion_contract_test.dart`.
5. **Passport & Waypoint Accuracy (In-flight)**:
   - Fixed `DigitalPassportPage` saved place tap routing: disambiguates city destinations (`/destination/:id`) from specific venue cards (`/place-details`).
   - Removed artificial multiplier padding (`totalDays * 3`) in `ItineraryStatsRow` when waypoints count is 0.

---

## 6. Known Blockers & External Dependencies

- **Live Device Location**: Web/desktop mock location fallback vs. Android/iOS native GPS permission loop.
- **Render FastAPI Cold Start**: Free/low tier Render instances take 30–50s on initial cold request. `AppConfig.connectTimeout` and `aiGenerationTimeout` (60s) accommodate this.
- **Firebase Auth on Native Emulators**: Requires configured `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) with valid SHA-1 for Google Sign-In.

---

## 7. Next Recommended Tasks

1. **Commit In-flight Hardening Diff**: Commit the completed fixes in `digital_passport_page.dart` and `itinerary_overview_widgets.dart`.
2. **Story Creator & Export Hardening**: Audit `lib/features/more/presentation/pages/story_creator_page.dart` for canvas export, permissions, and Instagram Stories sharing contracts.
3. **Booking Flow & Wallet Checkout End-to-End**: Test end-to-end integration between `BookingsPage`, `WalletRepository.requestDebit`, and itinerary reservation hooks.
4. **Offline Sync & Reconnection Flow**: Enhance `HiveService` cache invalidation when internet reconnects after offline itinerary viewing.
