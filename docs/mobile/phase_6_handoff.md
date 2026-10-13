# Phase 6 mobile handoff — 14 October 2026

Branch: `astra/mobile-v2`. Companion Website Phase 6 changes are merged into `main` through PRs #21 and #22. Shared interface: [mobile contract packet](phase_6_contract_packet.md), with the canonical packet in `NaviiGo-Website/docs/phase_6_contract_packet.md`.

## Delivered behavior

- Generation supplies a stable operation identity, validates authenticated-owner committed receipts, and confirms `users/{uid}/itineraries/{id}` before making a preview durable. Timeouts reconcile the same operation. Foreign/stale account results cannot become saved history, live state or Passport claims.
- The production replan adapter now connects request, review and explicit acceptance to the aligned backend. Only `I_AM_TIRED` is supported. Request/result state stays bound to owner, itinerary, operation and base revision. Typed failures retain stale/ambiguous/unsupported states instead of applying local simulated changes.
- Models read the actual backend `lastReceipt` and `acceptanceReceipts` fields alongside the generation receipt. Historical operation retries confirm their stored receipt while displaying the latest owner revision. Accepted receipts require the exact proposal and previous revision.
- New activities use unique immutable activity IDs; manual check-ins reconcile only by surviving stable IDs. Older positional/name-only records are not guessed onto new activities. Server writes and traveller reports remain distinct.
- Private owner detail/list reads do not use a public-root fallback. History and Passport exclude ephemeral previews and distinguish completed journeys, cancellation and saved places. Terminal journeys do not restart. Saved destination/venue/restaurant routing and image fallbacks remain supported.
- The existing memory action uses a deterministic owner-scoped trip/note key. Entry plus stats write in one Firestore transaction; duplicate and ambiguous retries do not increment twice. Ownership is checked before, within and after awaits, and write failures remain visible. Memory/XP remains client-controlled and is not an independently verified visit.
- Frozen adaptive preferences, analytics meanings, navigation/onboarding and native start/location thresholds are preserved.

## Verification

Final checks: formatting, `flutter analyze` (no issues), `flutter test` (**275 passed**) and `git diff --check` passed. Focused repository tests cover receipt history after a later revision, proposal-owner mismatch, missing acceptance identities and stale-account responses. Passport transaction tests cover duplicate awards, atomic failures, committed-response ambiguity and account switches. Five additional HTTP transport tests preserve canonical `{error: {code, message, details}}` errors and legacy FastAPI `detail` errors; native execution exposed the missing conflict-code parsing.

The Website companion has 125 passing backend tests (including the hotel-provider follow-up), 38 passing browser contract tests and 11 passing Firestore emulator tests, plus a clean type/lint/build gate. Companion rules are deployed to `naviigo-firebase/naviigo-db` and read-back verified against the checked-in file. Website/backend deployment status and subsequent follow-ups are tracked in the separate release report.

A pre-existing lifecycle test used a fixed 15 October 2026 departure date and failed as the real clock entered its start window. Its future fixture is now relative to the test date; production lifecycle/start-gate rules were not retuned.

## Remaining release validation

Four native Android emulator scenarios passed using the actual Geolocator and Firebase plugins: three real location/permission/start-gate checks and one combined account/owner/backend scenario. The latter exercised native token claims, A/B switching, named-database server reads and denial, actual deployed proposal creation/acceptance/replay, booked-activity preservation, typed 409 conflicts and bearer-derived cross-account denial. The token-switch race and 401 retry used an HTTP spy with real native Firebase tokens; they were not production 401 injections. The framework also reports its teardown as a fifth success.

The final emulator run passed after an initial transient `cloud_firestore/unavailable` failure; no assertion was relaxed. All fresh synthetic identities and records were cleaned up after each run. Host-side live checks separately passed 11 deployed rules cases, seven backend cases, seven Website-proxy cases and four generated tired-proposal cases.

Physical-device permission/accuracy behavior, process termination and owner-scoped offline Hive persistence remain unverified. Fresh itinerary generation currently fails closed with `DESTINATION_DATA_UNAVAILABLE`: Render lacks `GEOAPIFY_API_KEY`. The existing local key was verified without exposing it; specific approval to transfer it into Render is pending. This is a production release blocker, not a passed generation test.

Passport/history displays existing durable completion records; this phase adds no automatic completion or verified-visit award endpoint. Website's older non-atomic completion award is explicitly unavailable. Public sharing is explicit/view-only; legacy ownerless or malformed projections fail closed, with no automatic migration.

Independent release review identified and fixed retained Passport data during account switching, a stale journey-memory dialog writing under the next account, progress keys surviving removed activities, and historical receipt recovery without base validation. UID-family auto-disposed Passport streams, an owner check in the dialog, authoritative stable-ID progress reconciliation and exact receipt-base validation now cover those boundaries. Regression tests include delayed account streams and late local-write acknowledgments. The additional error-envelope and native-test scheduling changes received a narrow independent review with no blocker found. Physical-device behavior remains outside this verification.

Companion production Firestore rules deployment is verified. Website/backend merge and deployment status are tracked separately in the release report. No forced push, history rewrite, data wipe/bulk migration, credential revocation/rotation, billing change or later product phase was performed.

Windows Gradle 8.12 could not move temporary transform workspaces into its cache. An isolated WSL build using official Flutter 3.32.8, Java 17 and matching Android tools succeeded and ran on the read-only emulator. The three maintained location tests now wrap real plugin awaits in `tester.runAsync`, keeping their existing assertions outside the widget test's simulated clock. No SDK downgrade, endpoint-protection change, user AVD wipe or location-policy retuning was performed.
