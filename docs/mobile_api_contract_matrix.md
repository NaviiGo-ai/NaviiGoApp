# Mobile API Contract Matrix

The maintained matrix is in
[`docs/mobile/api_contract_matrix.md`](mobile/api_contract_matrix.md). This
compatibility entry point is kept because the Phase 0 brief originally named
this root-level path.

Key audited findings:

- AI/places/weather/transport/taste/analytics routes are mounted under
  `/api/*` by the current Website `backend/main.py`.
- Wallet is mounted at `/api/wallet/*`, producing `/api/wallet/account`,
  `/api/wallet/transactions`, `/api/wallet/debit`, `/api/wallet/refund`, and
  `/api/wallet/coupons/apply`.
- The bookings router adds its own `/bookings` prefix to the `/api/bookings`
  mount, so effective SQL booking routes are `/api/bookings/bookings...`.
- The payments router similarly produces `/api/payments/payments/order`,
  `/api/payments/payments/verify`, and `/api/payments/payments/webhook`.
- `backend/app/api/trips.py` is not included by `backend/main.py`; SQL trip
  routes are not mounted.
- The Website was not modified in this phase.
