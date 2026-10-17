# Continuous home discovery feed

Home keeps active/upcoming-trip precedence and the app-only pilgrimage entry.
The discovery area now appends supported-city and nearby-place cards as the
reader scrolls, with category filters, pull-to-refresh and a back-to-top control.
The upcoming-trip card includes its destination photo. Content is constrained
to a readable width on larger screens.

## Data and paging

- The supported destination registry supplies city cards, prioritising the five
  pilgrimage destinations. Nearby listings use the existing public Places API.
- One nearby request runs per page/city, with an 8 km search radius and a maximum
  of 20 returned places. Missing/out-of-area coordinates and generic category
  names are excluded; place IDs are deduplicated across pages.
- Concurrent scroll requests are coalesced. Filters, refresh and account changes
  discard late results from the previous generation.
- Failed pages retain their cursor for Retry. Readers can explicitly continue
  past an unavailable city. Valid empty pages advance normally.
- Paging ends when the available catalogue is consumed, with an honest caught-up
  state. Cards are not repeated to simulate unlimited content.
- The feed is public discovery content, separate from account-owned trips and
  saved places. No GPS permission, booking, fabricated rating or partner approval
  is introduced.

## Images

Photo widgets are built lazily with a small scroll cache. Existing approved
assets and the existing server-side Places photo service are reused. Loading
and failures preserve the card's dimensions. Metadata and image failures offer
Retry, and provider credits remain available. Decoded network images are bounded
to the display width, capped at 1600 pixels. Finite fades respect reduced motion;
there is no repeating decorative animation.

Queries are limited to 100 Unicode characters before calling the existing API.
Malformed metadata is rejected safely. External images require HTTPS; a configured
HTTP development API may supply photos from its own Places proxy only.

## Verification — 17 October 2026

- Full Flutter suite: 323 passed, including 14 new feed/image regressions.
- Flutter analyzer: no issues; production web build: passed.
- Tests cover paging, concurrency, deduplication/location checks, outages/retry,
  late responses, account resets, real scroll loading, category/refresh gestures,
  320 px large-text/reduced-motion layout, record navigation and image failures.
- A real signed-in browser retained the upcoming trip and loaded Ujjain venues,
  their Google Maps photos/credits, and the next Varanasi page on scroll.
- Native-device performance and provider availability remain dependent on the
  actual device and external services; those are not guarantees from this test.

For the local release preview, an existing Flutter service worker can temporarily
serve the previous bundle. Closing and reopening the preview tab activated the
new build while preserving the Firebase sign-in and stored app data.
