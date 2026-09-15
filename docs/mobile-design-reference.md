# Naviigo Mobile — Design & UX Reference

Extracted from React Native prototype architectures (`naviigo-app` through `naviigo-v7-explore`) for native Flutter production implementation.

---

## 1. Brand Tokens & Typography
- **Display / Editorial Font**: `Epilogue` (Display headers, trip titles, destination mastheads)
- **Product UI Font**: `Plus Jakarta Sans` (Body, labels, buttons, navigation, metadata)
- **Palette**:
  - Primary Orange: `#EC6426`
  - Accent Yellow: `#F8A91F`
  - Warm Dark Brown: `#632713`
  - Subtle Cream / Surface: `#FDE3CF`
  - Deep Teal: `#00666A`
  - Charcoal Body Text: `#24323A`
  - Background Neutral: `#F8F9FA` / Dark `#12181B`

---

## 2. Information Architecture & Navigation

### Primary Shell (Bottom Navigation)
1. **Home**: Dynamic contextual feed adapted to trip lifecycle state (Discovery vs. Upcoming vs. Active vs. Post-trip).
2. **Explore**: Curated destination discovery, search, category pills, verified places.
3. **Trips / Itinerary**: Saved, upcoming, and active journeys with day-by-day vertical timeline.
4. **Bookings / Wallet**: Ticket vouchers, PNRs, redirect status, booking references.
5. **Passport / Profile**: Verified stamps, XP level, states visited, travel history, preferences.

---

## 3. Core Screen Patterns & Layout Concepts

### A. Home — Context-Aware Hub
- **Header**: Warm greeting, avatar, location context, notification bell.
- **Dynamic Hero**:
  - *No Trip*: Inspiring curated destination showcase with "Start Planning" CTA.
  - *Upcoming Trip*: Countdown banner ("4 days until Jaipur"), dates, quick pack/weather checklist.
  - *Active Trip*: "Ongoing Journey" card with Day X of Y progress, "Next Stop" banner, and 1-tap jump to Live Mode.
  - *Post Trip*: "Memories from [Trip]" prompt to create Story or view Passport stamp.
- **Category Filter Chips**: Single-select horizontal pill rail (Spiritual, Heritage, Adventure, Beach, Nature, Food).
- **Featured / Recommended Destinations**: Editorial aspect-ratio cards with location pin, rating, and duration.
- **Inspiration Banner**: Editorial quote/journal snippet with subtle warm gradient overlay.

### B. Explore & Search
- **Curated Search**: Search input with debounced query and category filters.
- **5–7 Curated Picks First**: Clean, non-cluttered results with expandable "View More".
- **Destination / Place Card**: High-res image, title, state/region, rating chip, tag badges.
- **Filter Sheet**: Budget tier (Budget, Mid-Range, Luxury), Pace (Relaxed, Moderate, Fast), Vibe.

### C. Destination & Place Detail
- **Hero Image Header**: Full-bleed 300dp image with back button, bookmark/save toggle, and subtle dark gradient.
- **Metadata Badges**: Elevation, category, duration, difficulty tag.
- **Highlights Grid**: 3-column pill cards with iconography (e.g. Best for Photography, Panoramic Views, Cultural).
- **About Section**: High-legibility editorial summary with collapsible "Read More".
- **Gallery Rail**: Horizontal thumbnail preview with tap-to-view fullscreen.
- **Persistent Bottom Action Bar**: "Add to Itinerary" and "Get Directions" CTAs.

### D. Itinerary — "Day in Motion"
- **Trip Masthead**: Title, date range, total estimated budget breakdown (Stay, Travel, Food, Activities).
- **Day Selector Tabs**: Sticky horizontal bar (`Day 1`, `Day 2`, `Day 3`...).
- **Vertical Journey Line**:
  - Circular sequence badges (1, 2, 3...) connected by a dashed/solid brand track.
  - Activity nodes: Time, title, category icon, duration, address, notes.
  - Transfer connectors: Distance & estimated transit time between stops.
  - Stay & Meal markers: Distinctive cards distinguishing transit from destinations.
- **Route Preview**: Compact inline mini-map preview with a "View Full Route" sheet trigger.

### E. Ongoing Trip (Live Mode)
- **Live Progress Header**: "Day X of Y", visual progress bar percentage.
- **Next Up Card**: Destination name, ETA, quick navigation shortcut.
- **Quick Action Bar**:
  - `Next Stop`
  - `View Route`
  - `I'm Safe` (Check-in)
  - `Share with Buddy`
  - `Safety & Local Help`
  - `Add Moment`
- **Today's Timeline**: Interactive checklist of activities for the current day.

### F. Trip Booking & Planner Flow
- Progressive multi-step sheet:
  1. Destination & dates selection
  2. Group size / travelers counter
  3. Budget preference slider with real-time bracket calculation
  4. Travel style & dietary preferences
  5. Instant itinerary generation trigger

---

## 4. Key UX Principles
1. **Zero Fake Data**: If an itinerary, booking, or place has no data, present clean empty states with positive actions, not dummy Santorini/Mussoorie fallbacks.
2. **Offline-First Resilience**: Always cache active trip details, offline notes, and verified emergency contacts.
3. **Calm, High-Utility Safety**: Safety and Buddy features must be accessible within 1 tap from active trips without inducing panic.
