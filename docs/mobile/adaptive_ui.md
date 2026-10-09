# Adaptive UI Contract

## Single controller

All contextual visual adaptation belongs behind one future
`AdaptiveExperienceController`. Feature pages consume a resolved state/tokens;
they do not independently calculate a theme from user data, destination, or
trip status.

```text
AdaptiveExperienceState =
  BrandBase
  + UserPreferenceProfile
  + JourneyLifecycle
  + DestinationContext
  + AccessibilityConstraints
```

`BrandBase` contains the fixed NaviiGo palette, typography, semantic colors,
navigation structure, and component geometry. The other inputs select density,
imagery emphasis, transition pace, and information hierarchy within those
limits.

## Planned state examples

| Lifecycle/context | Presentation direction |
|---|---|
| Discover + Culture | Cream/brown editorial surface, larger imagery, slower reveals |
| Discover + Adventure | Teal emphasis, stronger geographic movement, larger map/image surfaces |
| Planning | Balanced orange/cream, structured cards, Journey Line as planning spine |
| Active trip | Teal dominant, compact cards, low animation, NOW/NEXT/ROUTE hierarchy |
| Post trip | Brown/cream atmosphere, Journey Line as a memory trail |

These are presentation states, not separate personalization algorithms. The
Website remains the authority for preference collection and recommendation
scoring.

## Inputs and fallbacks

- User preference input comes from the existing profile/preferences repository.
- Journey lifecycle comes from the canonical trip model and confirmed backend
  state.
- Destination context comes only from verified itinerary/place/weather data.
- Accessibility constraints come from Flutter platform settings and are never
  overridden by a state preset.
- Missing input resolves to the neutral BrandBase presentation. It must not
  trigger fabricated travel data or random AI-generated styling.

## Phase boundary

No controller implementation or screen redesign is part of Phase 0. The
contract is recorded now so later phases can add one reusable controller rather
than six incompatible page-level rules.
