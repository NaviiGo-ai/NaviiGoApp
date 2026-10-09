# Mobile API Contract Matrix

The maintained matrix is in
[`docs/mobile/api_contract_matrix.md`](mobile/api_contract_matrix.md). This
compatibility entry point is kept because the Phase 0 brief originally named
this root-level path.

Key audited findings:

- AI/places/weather/transport/taste/analytics routes are mounted under
  `/api/*` by the current Website `backend/main.py`.
- The SQL wallet, bookings, payments, and trips routers are currently mounted
  at root-level `/wallet/*`, `/bookings/*`, `/payments/*`, and `/trips/*`.
- Mobile wallet mutation paths were corrected to the current mounted `/wallet/*`
  contract. The Website was not modified in this phase.
