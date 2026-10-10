# Phase 2: entry and onboarding contract

## Website audit (read-only)

Audited `NaviiGo-ai/NaviiGo-Website/main` at
`a7fd4249128994fed167e4a89ba97fc054e2f958` before adding completion metadata.
Searched frontend TypeScript/TSX, backend Python, and Firestore rules for
`onboarding`, `onboarded`, `hasOnboard`, and completion variants. No reliable
completion signal or conflicting `onboardingCompleted` field exists.

Relevant sources:
- `Frontend/lib/firestoreSchema.ts`: `UserPreferences`, existing document path,
  travel styles (`budget`, `mid-range`, `luxury`), group values, free-form interest,
  diet, accessibility lists, home city.
- `Frontend/lib/firestore.ts`: `getUserPreferences`, `updateUserPreferences`;
  partial/transaction merge preserves unknown keys.
- `backend/services/user_data.py` and `backend/routers/itinerary.py`: existing
  preference consumption. No mobile recommendation/scoring engine is added.

## Durable completion

Single document: `users/{uid}/preferences/main` in the existing `naviigo-db`.
The only additive field is `onboardingCompleted: true`, written alongside the
full explicit selections when the traveller taps **Finish & start exploring**.
Missing, false, or invalid legacy values mean incomplete, even if other fields
are populated. Existing preferences hydrate the editor; legacy users review
them rather than losing them. Normal partial preference writes do not reset
completion. Clearing a list during onboarding writes an empty list explicitly.
Adaptive Appearance always serializes both true and false.

The completion Future awaits Firestore acknowledgement. The preference stream
ignores snapshots with pending local writes and includes metadata changes so
the confirmed snapshot is emitted. It accepts previously confirmed cached
snapshots offline. A 15-second wait limit reports **not confirmed**, not saved;
Firestore may still deliver the queued write later. Retrying is an idempotent
merge into the same document. No second onboarding document or local completion
flag exists.

The mobile preference stream attaches an in-memory `sourceUserId` provenance
tag, excluded from `toMap()` and never stored in Firestore. Entry guards and
editors reject retained AsyncValue data for a different UID, including after
read errors; cached usable state is accepted only for its own authenticated UID.

## Entry routing

- Auth unresolved or preferences not available: splash/loading.
- Error without usable state: splash/retry, with account-switch action.
- Signed out: login.
- Signed in, explicit completion absent: onboarding (vibe-match is the final
  optional-interest review and still requires explicit confirmed completion).
- Signed in, confirmed completion: Home or the preserved authenticated URL.
- Entry routes never redirect to themselves. Only relative, non-entry URLs
  are accepted as `next`; URL path/query survive the gate. Objects in route
  `extra` cannot survive authentication/restart and must be reopened by URL.
- Router instance remains stable across auth/preferences changes and uses
  Riverpod listeners plus GoRouter refresh. No timer decides authentication.

## Auth and session behavior

Mobile config supports Firebase email/password sign-in and registration. No
unconfigured social buttons are displayed. Auth errors use curated messages;
unknown exceptions never appear verbatim in UI. Passwords are not trimmed.
ApiClient retains sole responsibility for token refresh. Profile sync is
best-effort after genuine Firebase auth so it cannot block offline entry.
Logout awaits Firebase sign-out and clears the existing user-specific Hive
itinerary/profile caches and the signed-out user's local analytics queue, not
shared preferences or remote documents. Analytics envelopes carry a
local-only `ownerUid`; this is queue isolation metadata, never backend
identity, and is omitted from `POST /api/analytics/track`. Flushes select only
the current UID's envelopes and pass that expected UID through the existing
ApiClient token authority, so backend identity remains exclusively the Firebase
bearer token. Legacy unowned/malformed queue entries are discarded safely and
never submitted. Failed logout stays on the current screen with a retryable
message; flush-time ownership checks remain effective if cleanup fails.

The adaptive composition root uses one safe preference selector. Preferences
are accepted only when the authenticated UID exists and the in-memory
`sourceUserId` matches it. A retained value from another account, including
during an auth dependency reload, resolves to standard Naviigo defaults.

## Visual and accessibility scope

Existing NavHubPage retains Home, Explore, Trips, Passport, Profile in that
order. Nav labels support scaled/wrapped text, collapsed labels retain spoken
names, geometry respects reduced motion, and the keyboard hides bottom chrome.
Entry content uses a bounded scroll surface, SafeArea, existing typography,
Journey Line, frozen adaptive tokens, and bundled destination imagery. Vibe
cards only toggle their visible explicit interest labels and support undo.
Home city is optional text with existing autocomplete, never GPS permission.

## Limitations

Auth provider enablement, production Firestore rules, native deep-link platform
registration, and real offline persistence must also be checked on devices
against the deployed Firebase project. On web, cached offline entry is limited
to the persistence configured by the existing Firebase SDK setup. No platform
OAuth methods are introduced. Existing autocomplete converts backend/network
failure to empty suggestions; the UI says unavailable, allows retry, and keeps
manual text entry usable. No claim is made that dietary/accessibility preferences
guarantee venue availability.
