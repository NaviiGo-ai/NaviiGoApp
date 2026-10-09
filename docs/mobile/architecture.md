# NaviiGo Mobile Architecture

## Phase 0 baseline

- **Chosen baseline:** `40d960b` (`fix(nav): prevent web bottom bar layout overflow`)
- **Working branch:** `astra/mobile-v2`
- **Rejected wholesale:** `e90c301` (`Added new stuff`). It was reverted by
  `7ce204a`; its large page/model changes contain duplicate declarations and
  malformed widget structure. Valid ideas were reintroduced only where they
  have a verified current Website contract.
- **Website source of truth:** `NaviiGo-ai/NaviiGo-Website`, `main`, audited at
  `a7fd4249128994fed167e4a89ba97fc054e2f958`.

## Runtime layers

```text
Flutter pages/widgets
        ↓
Riverpod providers/controllers
        ↓
Feature repositories (Firestore or ApiClient)
        ↓
Firebase Auth token / Firestore / Website FastAPI API
```

### Core responsibilities

- `lib/core/network/ApiClient` is the single HTTP client. It adds the Firebase
  ID token, force-refreshes and retries once after a `401`, applies timeouts,
  and maps HTTP failures to typed app exceptions.
- `lib/core/auth` owns Firebase sign-in and user identity.
- `lib/core/cache/HiveService` stores offline itinerary/profile data. Cached
  data is treated as a read fallback; it does not become server authority.
- `lib/core/router` and `lib/features/navigation` own the native shell and
  five-tab navigation: Home, Explore, Trips, Passport, Profile.
- `lib/core/motion` and `lib/core/widgets/journey_line.dart` are shared motion
  and journey primitives. Feature screens should compose them rather than
  creating competing motion rules.
- Feature repositories are clients only. Validation, personalization,
  provider access, booking truth, wallet balance, and server analytics remain
  Website/Firebase responsibilities.

## Data ownership

| Data | Authoritative owner | Mobile behavior |
|---|---|---|
| Firebase identity | Firebase Auth | Sends refreshed bearer token |
| Preferences/profile | Firestore `users/{uid}` and `preferences/main` | Reads/writes through repository |
| Saved itinerary | Firestore `users/{uid}/itineraries/{id}` | Streams and caches locally |
| Generated itinerary | Website `/api/itinerary/generate`, then Firestore | Parses returned data; never generates locally |
| Places/weather/transport | Website `/api/*` routers | Displays returned fields or honest empty state |
| Personalization | Website analytics/taste services | Sends events; does not reproduce algorithm |
| Wallet/bookings/payments | Website SQL API and/or explicitly documented Firestore contracts | Never fabricates balance, price, provider status, or booking reference |

## Trip lifecycle

`TripStatus` in `TripItineraryModel` is the shared mobile vocabulary:

```text
draft → planned → upcoming → eligible_to_start → active → completed
                         ↘ cancelled
```

Missing status is derived conservatively from dates and `isActive`; calendar
arrival never silently claims an active journey. A server-written status wins.
The mobile client may request an operation, but it must not invent a transition
or assert that a backend write succeeded before the backend confirms it.

## Adaptive experience boundary

Later visual phases must use one central `AdaptiveExperienceController`, not
page-local theme heuristics. Its planned input model is:

```text
AdaptiveExperienceState =
  BrandBase
  + UserPreferenceProfile
  + JourneyLifecycle
  + DestinationContext
  + AccessibilityConstraints
```

The controller may select a coherent experience state such as Discover/Culture,
Discover/Adventure, Planning, Active Trip, or Post Trip. It must not ask an AI
model to randomly generate colors or let six pages invent six personalization
algorithms. Brand tokens, semantic colors, navigation structure, and reduced
motion/accessibility constraints remain stable.

## Security and privacy boundaries

- No Gemini, Places, weather, transport, payment, or other server-provider key
  is bundled in Flutter.
- Firebase client configuration is public app configuration; server credentials
  stay in the Website backend.
- User identity is derived by the Website from the verified bearer token. A
  body `userId` is not trusted for server ownership decisions.
- Private itineraries remain in the user subcollection unless explicit sharing
  is part of the current contract.
- Location, buddy, emergency, booking, and route claims are rendered only when
  a real backend/device source supports them.
