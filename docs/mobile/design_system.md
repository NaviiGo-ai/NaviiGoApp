# NaviiGo Mobile Design System

This is the stable visual contract for later phases. Phase 0 records tokens and
boundaries only; it does not redesign screens.

## Brand tokens

| Token | Value | Use |
|---|---|---|
| Primary orange | `#EC6426` | Primary actions and emphasis |
| Warm brown | `#632713` | Editorial depth, dark mastheads |
| Cream | `#FDE3CF` | Warm surfaces, pills, highlights |
| Deep teal | `#00666A` | Active journey, verified/safe states |
| Accent yellow | `#F8A91F` | Highlights and stars |
| Charcoal | `#24323A` | Primary body text |
| Background | `#FDF8F5` | Warm paper canvas |
| Surface | `#FFFFFF` | Cards and sheets |

Semantic colors in `AppColors` remain stable:

- success: `#10B981`
- warning: `#F59E0B`
- error: `#EF4444`

Semantic colors must describe state, not decorate unsupported claims. For
example, teal does not mean that GPS is live unless a real fix exists.

## Typography

- **Epilogue:** display hero, editorial title, section title, trip title.
- **Plus Jakarta Sans:** body, labels, buttons, navigation, metadata.
- Existing scale and helpers live in `lib/core/theme/app_typography.dart`.

## Component rules

- Prefer small reusable components and the existing Journey Line/motion
  primitives over new page-wide bespoke systems.
- Cards use warm, low-contrast borders and restrained shadows from `AppColors`.
- A loading, unavailable, or empty response is an explicit state. It is not a
  reason to insert a made-up price, rating, ETA, temperature, activity, or
  provider status.
- External booking and map actions must disclose that they leave NaviiGo when
  the current contract is a redirect.

## Accessibility invariants

- Honor the reduced-motion signal used by `NavReduce`.
- Preserve text hierarchy and contrast when an adaptive state changes emphasis.
- Do not encode meaning with color alone.
- Keep touch targets and text scaling compatible with Flutter accessibility
  settings.
- Accessibility constraints are an input to adaptive presentation and always
  override decorative motion or density choices.
