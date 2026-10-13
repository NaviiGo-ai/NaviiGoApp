# Phase 6 mobile handoff — 14 October 2026

Branch: `astra/mobile-v2`. Companion Website branch: `codex/phase-6-contract-alignment`. Shared interface: [mobile contract packet](phase_6_contract_packet.md), with the canonical packet in `NaviiGo-Website/docs/phase_6_contract_packet.md`.

## Delivered behavior

- Generation supplies a stable operation identity, validates authenticated-owner committed receipts, and confirms `users/{uid}/itineraries/{id}` before making a preview durable. Timeouts reconcile the same operation. Foreign/stale account results cannot become saved history, live state or Passport claims.
- The production replan adapter now connects request, review and explicit acceptance to the aligned backend. Only `I_AM_TIRED` is supported. Request/result state stays bound to owner, itinerary, operation and base revision. Typed failures retain stale/ambiguous/unsupported states instead of applying local simulated changes.
- Models read the actual backend `lastReceipt` and `acceptanceReceipts` fields alongside the generation receipt. Historical operation retries confirm their stored receipt while displaying the latest owner revision. Accepted receipts require the exact proposal and previous revision.
- New activities use unique immutable activity IDs; manual check-ins reconcile only by surviving stable IDs. Older positional/name-only records are not guessed onto new activities. Server writes and traveller reports remain distinct.
- Private owner detail/list reads do not use a public-root fallback. History and Passport exclude ephemeral previews and distinguish completed journeys, cancellation and saved places. Terminal journeys do not restart. Saved destination/venue/restaurant routing and image fallbacks remain supported.
- The existing memory action uses a deterministic owner-scoped trip/note key. Entry plus stats write in one Firestore transaction; duplicate and ambiguous retries do not increment twice. Ownership is checked before, within and after awaits, and write failures remain visible. Memory/XP remains client-controlled and is not an independently verified visit.
- Frozen adaptive preferences, analytics meanings, navigation/onboarding and native start/location thresholds are preserved.

## Verification

Final checks: `dart format .` (150 files, no outstanding changes), `flutter analyze` (no issues), `flutter test` (**264 passed**) and `git diff --check` passed. Focused repository tests cover receipt history after a later revision, proposal-owner mismatch, missing acceptance identities and stale-account responses. Passport transaction tests cover duplicate awards, atomic failures, committed-response ambiguity and account switches.

The Website companion has 118 passing backend tests, 35 passing browser contract tests and 11 passing Firestore emulator tests, plus a clean type/lint/build gate. Emulator proposal-write restrictions require deploying the companion rules in the later rollout.

A pre-existing lifecycle test used a fixed 15 October 2026 departure date and failed as the real clock entered its start window. Its future fixture is now relative to the test date; production lifecycle/start-gate rules were not retuned.

## Remaining release validation

Native-device/deployed-Firebase checks remain for platform token acquisition during account transitions, OS location permissions/accuracy, process termination and owner-scoped Hive persistence, deployed bearer attribution, transaction acknowledgment and repeated replan recovery across mobile and browser. No native/deployed environment was claimed verified.

Passport/history displays existing durable completion records; this phase adds no automatic completion or verified-visit award endpoint. Website's older non-atomic completion award is explicitly unavailable. Public sharing is explicit/view-only; legacy ownerless or malformed projections fail closed, with no automatic migration.

A fresh independent post-fix agent review was not started in this takeover. The listed gates and direct contract/source review support implementation publication; production approval/deployment and an independent release review remain separate.

No production deployment, forced push, history rewrite, data wipe/bulk migration, credential rotation, billing change or later product phase was performed.
