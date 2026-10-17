# Pilgrimage pilot implementation — 17 October 2026

The existing platform remains intact. The app adds a five-destination entry,
city-specific preparation prompts and explicit spiritual-purpose planner handoffs.
Ujjain is the first field focus; Varanasi, Mathura–Vrindavan, Dwarka and Puri /
Jagannath complete the pilot scope. The Mathura–Vrindavan entry starts the planner
in Mathura and explicitly requires separate arrangements for the Vrindavan leg.
Existing trip lifecycle precedence, account isolation and other cities remain.

The public website adds Founder Travels only. It must not advertise this
five-destination rollout. Kainchi Dham is an upcoming founder field test for
Diwali 2026, not a completed trip or a sixth supported pilot destination.

## What is available

- App home entry and `/pilgrimage-pilot` hub with five city preparation pages.
- Before-departure, during-journey and changed-plan prompts for each city.
- City-bound planner entry with spiritual purpose; traveller/group choices remain
  for the user to make. No automatic booking, partner approval or payment.
- Links to the existing saved-trip library and help/contact options.
- Founder field-test plan clearly marked upcoming, on the app and website.

## Operational activation remains separate

The app says **Planning available · Assisted support preparing**. Before changing
that status, confirm support staffing/hours, escalation ownership, current venue
guidance and any participating businesses directly. Survey follow-up consent is
not partner approval. Research spreadsheets are raw material, not verified current
timings, entry rules, offers, prices or inventory. Personal contacts and survey
notes must stay out of public assets and source-controlled product data.

No continuous monitoring feed, staffed assistance, live founder location, live
rail integration or provider booking relationship is introduced by these pages.
The first founder observations and actual costs can be published after the visit,
with dates and source/verification context. This change does not train model weights.

## New city-centre coordinates

Checked 17 October 2026 against GeoNames (CC BY attribution); these are city
centres, not venue entrances or a verified route. New airport/rail codes, review
ratings and season recommendations remain unset rather than inferred.

| City | Latitude | Longitude | Source |
| --- | --- | --- | --- |
| Ujjain | 23.18239 | 75.77643 | https://www.geonames.org/1253914/ujjain.html |
| Mathura | 27.50350 | 77.67215 | https://www.geonames.org/1263364/mathura.html |
| Dwarka | 22.2394444 | 68.9677778 | https://www.geonames.org/advanced-search.html?q=%27Gujarat%2C+India%27&startRow=150 |
| Puri | 19.798254 | 85.824938 | https://www.geonames.org/advanced-search.html?q=Odisha%2CIndia |

GeoNames attribution and licence: https://www.geonames.org/ and
https://creativecommons.org/licenses/by/4.0/ . Varanasi uses its existing registry entry.

## Release validation

- Flutter analyzer: no issues.
- Full Flutter suite: 308 tests passed, including six new pilot regressions.
- Production web build: passed with bundled web resources.
- Real signed-in browser: existing upcoming Jaipur trip retained; app pilot hub
  and Ujjain preparation page checked at phone width. This is not a native-device
  or an operational-support acceptance test.
- Missing airport codes disable flight search and booking actions; existing
  connected-flight cold-start regression still passes.
- Whitespace check: passed. Existing destination ordering remains intact.
