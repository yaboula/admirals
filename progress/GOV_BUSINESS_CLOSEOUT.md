# Gov + Business Closeout — Phase 1.1 to 2.1

## Status

- **Date:** 2026-05-14
- **Branch:** `feature/gov-business-closeout`
- **Status:** ✅ Implementation closeout complete; live runtime evidence still required for ST-025 and Security risk formula sign-off.

## Commits

| Commit | Scope |
|---|---|
| `4848aa2` | Tax Engine backend + FE wiring |
| `03ad07d` | Real `ListSanctionActions` lookup against audit ledger |
| `2c61820` | Subsidy grant endpoint + FE action |
| `11c1bb2` | Real GOVT reports fiscal aggregations |
| `740f71d` | Business withdrawal approval request |
| `274a070` | Security risk formula review request |
| `50c5955` | ST-025 callback lag smoke harness |

## Completed scope

### Phase 1.1 — Tax Engine backend + FE wiring

- Added backend tax repo/service/callbacks.
- Wired frontend tax queries/mutations to real callbacks.
- Added mock registry handlers for dev mode.
- Validated with FE typecheck/build during implementation.

### Phase 1.2 — ListSanctionActions real

- Replaced mock-only sanction action lookup with audit ledger query.
- Added service mapping for audit event context.
- Committed as `03ad07d`.

### Phase 1.3 — Subsidy grant endpoint

- Added `GOVT_SUBSIDY_GRANT` audit event.
- Added subsidy recipient lookups and grant transaction query builder.
- Added `GovtService.GrantSubsidy` with validation, idempotency, transaction, audit and replay behavior.
- Registered backend callback `sonar:bank:govt:subsidies:grant`.
- Added FE contract, mutation hook, mock handler and minimal grant action in `SubsidyDetail`.
- Validated `npm run typecheck`, `npm run build`, `git diff --check` before commit.

### Phase 1.4 — Reports aggregations

- Added report aggregation queries for revenue history, prior revenue, sector revenue and top contributors.
- Replaced placeholder reports service data (`MVP`, empty sector/top contributors, zero prior pct) with repo-backed data.
- Committed as `11c1bb2`.

### Phase 1.5 — Business withdrawal request

- Added `BUSINESS_WITHDRAWAL_REQUEST` audit event and missing `BUSINESS_PAYROLL_EXECUTED` enum used by existing service code.
- Added `CreateWithdrawalApproval` repo transaction using `operation_kind = 'large_withdraw'`.
- Added `BusinessService.RequestWithdrawal` with validation, idempotency, approval persistence and audit.
- Registered callback `sonar:bank:business:withdrawal:request`.
- Added FE request/response contracts, mutation hook, mock handler and enabled withdraw action.
- Validated `npm run typecheck`, `npm run build`, `git diff --check` before commit.

### Phase 1.6 — Security risk-formula review request

- Created `progress/SECURITY_RISK_FORMULA_REVIEW_REQUEST.md`.
- No formula change was made because risk scoring remains Security/Founder gated.

### Phase 2.1 — ST-025 smoke harness

- Created `scripts/smoke_test_st025.md` for callback response lag validation.
- Harness is manual/runtime-evidence oriented and avoids blind mutation automation.

## Remaining blockers / required live evidence

1. **ST-025 runtime evidence**
   - Execute `scripts/smoke_test_st025.md` on live dev server.
   - Capture NUI response, movement IDs, audit/correlation ID and idempotency replay.

2. **Security sign-off**
   - Security Lead must respond to `progress/SECURITY_RISK_FORMULA_REVIEW_REQUEST.md` with `APPROVE-AS-MVP`, `APPROVE-WITH-AMENDMENTS`, or `BLOCK`.

3. **Live Lua/runtime validation**
   - Local `lua/luac` availability remains unknown in this session.
   - Runtime validation should be performed in FXServer with real callbacks.

## Validation evidence from this session

- `npm run typecheck` passed after Phase 1.3 and Phase 1.5 FE wiring.
- `npm run build` passed after Phase 1.3 and Phase 1.5 FE wiring.
- `git diff --check` passed before atomic commits.
- Working tree was clean before Phase 2.2-2.6 closeout work.

## Next recommended actions

1. Run ST-025 live and paste evidence into a progress report.
2. Obtain Security Lead risk formula sign-off.
3. Push branch after founder approval.
4. Decide whether Phase 2.2-2.6 needs formal handoff ceremony or can close as implementation branch closeout.
