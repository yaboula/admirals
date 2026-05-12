# Roadmap Phase A+1 — Minor Units Migration End-to-End

> **Status:** 🟡 DRAFT v0.1 — emitted 2026-05-12 by Backend Lead Phase 5 (BANK-BE.PHASE_5.1) bajo Founder LOCK Q1 commitment.
> **Trigger:** Founder LOCK Q1 split convention 2026-05-12 (`@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md:13-29`) + cross-decision #4 reconciliation pendiente.
> **Scope:** holistic migration DB DECIMAL(19,2) major → BIGINT minor units end-to-end (DB columns + Backend service layer + callbacks signatures + Frontend types + StateBag/NetEvent payloads + audit shape final).
> **Phase A relationship:** Phase A LOCKS con split convention (exports surface INTEGER minor + boundary helpers + DB/callbacks/Frontend DECIMAL major). Phase A+1 unifica todo a INTEGER minor — boundary helpers desaparecen (no más conversion en runtime hot path), simplifica audit shape, alinea con fintech industry standard (Stripe/Wise/Revolut).
> **Owner sesión Phase A+1:** TBD — proposed prompt 09 + new session ID `BANK-BE.PHASE_A_PLUS_1.MINOR_UNITS.1`.
> **Estimated timeline:** 5-7 días development + 2-3 días validation + 1 día deployment ceremony = **~10 días session-time**.
> **Authority gate:** Founder green-light post Phase A LOCK (Phase 5 R2 amendments LOCKED + Phase 5 implementation 4.1-4.8 deployed + ST-024 PASS + PHASE_5_VALIDATION.md founder manual green).

---

## 0. Resumen ejecutivo

Phase A LOCK presenta una superficie pública moderna (Tier 1/2 exports INTEGER minor) sobre infrastructure legacy (DB DECIMAL major + callbacks LOCKED v1.0.1 R1 + Frontend types + StateBag payloads). Boundary helpers `units.lua` resuelven el desfase pero introducen runtime overhead + technical debt arquitectural. Phase A+1 unifica end-to-end:

1. **DB schema migration:** ~12 columns DECIMAL(19,2) → BIGINT signed cents en 8 tablas core.
2. **Service layer:** elimina `units.from_minor()` calls — DB layer trabaja directamente con BIGINT.
3. **Callbacks signatures (40+1):** payload `amount`/`balance`/`fee` field types `number` (DECIMAL) → `integer` (cents). Breaking Frontend.
4. **Frontend types + queries + components:** `BankAccount.balance: number` (decimal) → `number` (integer cents). All `useI18n().money(value)` calls + format helpers + chart Y-axis + transaction amount displays divide by 100 at presentation edge.
5. **StateBag/NetEvent:** payload `balance` field DECIMAL→INTEGER. Frontend `bankStateBags.ts` + handlers update.
6. **Audit shape final:** `delta_minor` field officially BIGINT canonical (already alined Q3 LOCKED).

**Justificación Phase A+1 separate:**

- Scope total ~10 días — bloquearía Phase A LOCK timeline (~3 semanas pivot crisis).
- Frontend churn significativo (rebuild + retests + screenshots) — mejor sesión dedicada.
- DB migration windows requieren downtime planning + rollback plan + production data sample (10K+ rows movements + 1K accounts realistic).
- Risk register independiente — separar de Phase A close ceremony.

---

## 1. Migration plan — 6 work streams

### Stream 1 — DB schema migration

| Table | Column | Before (LOCKED Phase A) | After (Phase A+1) | Notes |
|---|---|---|---|---|
| `sonar_bank_accounts` | `balance` | DECIMAL(19,2) | BIGINT signed | Range: ±9.22e18 cents = ±$92 quintillion. Safe. |
| `sonar_bank_movements` | `amount` | DECIMAL(19,2) | BIGINT signed | Idem. Negative for debits. |
| `sonar_bank_movements` | `fee` | DECIMAL(19,2) | BIGINT unsigned | Fees always positive. |
| `sonar_bank_movements` | `balance_after` | DECIMAL(19,2) | BIGINT signed | Snapshot post-mutation. |
| `sonar_bank_business_payroll_lines` | `amount_net` / `amount_gross` | DECIMAL(19,2) | BIGINT unsigned | Payroll. |
| `sonar_bank_loans` | `principal` / `outstanding` / `monthly_payment` | DECIMAL(19,2) | BIGINT unsigned | 3 columns. |
| `sonar_bank_recurring_payments` | `amount` | DECIMAL(19,2) | BIGINT unsigned | Recurring. |
| `sonar_bank_subsidies` | `amount` | DECIMAL(19,2) | BIGINT unsigned | Govt subsidies. |
| `sonar_bank_govt_fines` | `amount` | DECIMAL(19,2) | BIGINT unsigned | Govt fines. |
| `sonar_audit_log` | `delta_minor` | DECIMAL(19,2) (legacy) OR existente BIGINT (verify schema actual) | BIGINT signed | Q3 LOCKED canonical name. Audit shape finalized. |
| `sonar_bank_idem` | `result_json` (no migration — JSON internamente puede contener cents fields) | JSON | JSON | NEW Phase 5 migration 036. No change Phase A+1. |

**Migration script structure (`resources/sonar_core/migrations/045_minor_units_migration.sql`, número estimated):**

```sql
-- ALTER COLUMN per table — multiplica DECIMAL value × 100 + cast BIGINT.
-- Atomic per-table:
ALTER TABLE sonar_bank_accounts MODIFY balance BIGINT SIGNED NOT NULL DEFAULT 0;
UPDATE sonar_bank_accounts SET balance = ROUND(balance * 100);  -- pre-ALTER would lose precision; reverse order in dry-run

-- Recommended order:
-- 1. Add BIGINT shadow column `balance_cents` per table.
-- 2. Backfill `balance_cents = ROUND(balance * 100)` (transaction-safe per-row).
-- 3. Validate sums match (sanity per citizen + global sum).
-- 4. Atomic swap: drop `balance` + rename `balance_cents` → `balance` (single ALTER per table).
-- 5. Validate post-swap.
```

**Rollback strategy:** keep DECIMAL backup tables `<table>_phase_a_backup` con snapshot pre-migration durante 30 días. Restore script `046_minor_units_rollback.sql` reverte ALTER + UPDATE / 100.

**Dry-run mandate:** ejecutar migration en staging server con production data sample copy (~10K movements + 1K accounts realistic). Founder signs dry-run report antes de production.

### Stream 2 — Backend service layer cleanup

- Eliminar `units.from_minor()` calls antes de DB INSERT/UPDATE — service layer ahora trabaja BIGINT nativo end-to-end.
- Boundary helpers `units.lua` PRESERVADOS PERO downgraded a "legacy compat for callbacks LOCKED until Stream 3 migration completes". Eventualmente removable post Stream 3.
- `transfer_service.lua` + `account_service.lua` + `loan_service.lua` + `business_service.lua` + `govt_service.lua` + `portfolio_service.lua` — todos los SQL que actualmente hacen `MySQL.update.await('UPDATE ... SET balance = ?', { decimal_string })` cambian a `{ integer_cents }`.
- Estimated touched files: ~15 service files + ~5 repo files.

### Stream 3 — Callbacks signatures migration (BREAKING)

40+1 callbacks LOCKED v1.0.1 R1 cambian payload types:

- Request payload `amount: number` (decimal) → `amount_minor: integer`. Field rename mandatory para evitar silent wrong-type bugs.
- Response payload `balance: number` (decimal) → `balance_minor: integer`. Same.
- `fees`, `delta`, `monthly_payment`, etc. — todos los money fields renombrados con sufijo `_minor`.

**Contract amendment Round 3:** C-BE-02 v1.0.2 R2 LOCKED → v1.1.0 R3 (MAJOR breaking — version bump). Sign-off triple cycle.

Frontend coordinated update Stream 4 mismo session.

### Stream 4 — Frontend migration (BREAKING)

`web-src/` types/queries/components/i18n updates:

- `src/data/contracts.ts` — todos los TypeScript interfaces money fields `number` (decimal) → `number` (integer cents) + field rename `balance` → `balanceMinor` o keep `balance` con semantic change documentada via type alias `type CentsBigInt = number`.
- `src/lib/i18n.ts` — `useI18n().money(value)` semantic: argument now integer cents, internally divide by 100 for `Intl.NumberFormat({ style: 'currency' })`. Single change point.
- `src/lib/privacy.ts` — `maskMoneyDisplay()` adapt.
- All `useBootstrap()`, `useAccountList()`, `useTransferQuery()`, etc. — query contracts updated.
- All chart components `IncomeExpenseChart`, `HomeBalanceGraph`, `LoansRepaymentChart` — Y-axis values now integer cents. `tooltipFormatter` divide by 100.
- All transaction amount displays — `<TransactionRow amount={tx.amount}>` semantic shift.

Estimated touched: ~80 frontend files + 200+ component instances.

**Critical regression area:** Streamer Mode masks (`maskMoneyDisplay`) — verify mask logic does not depend on decimal point character. Streamer mode currently masks via `123.45 → ***.**` heuristic — adapt para integer cents `12345 → *****`.

**Test plan:** screenshots regression all 22+ routes pre/post migration + Playwright e2e suite.

### Stream 5 — StateBag/NetEvent payload migration (BREAKING)

C-BE-05 v1.0.2 R2 LOCKED → v1.1.0 R3 (MAJOR breaking — version bump):

- `publish_balance_update(citizen_id, balance_int_minor, account_class, opts)` — `balance` arg type INTEGER cents. Wrapper Tier 1/2 ya pasa INTEGER nativamente — `units.from_minor()` removable.
- NetEvent `sonar:bank:balance:update` + `sonar:bank:savings:update` payload `balance: integer` (cents).
- Frontend `web-src/src/lib/bankStateBags.ts` + handlers update tipo.

### Stream 6 — Audit shape final

C-SEC-01 v0.3 R2 LOCKED → v0.4 R3 (MINOR if column type alined Phase A+1):

- `sonar_audit_log.delta_minor` confirmed BIGINT post Stream 1 migration.
- Audit Explorer V4 frontend `src/routes/Audit.tsx` updates display tipo.

---

## 2. Sequencing + dependencies

```
Stream 1 (DB migration) ──┬─ Stream 2 (Backend service layer cleanup)
                          │
                          └─ Stream 6 (Audit shape final, alined post Stream 1)
Stream 3 (Callbacks) ─────┬─ Stream 4 (Frontend) — coordinated same session
                          │
Stream 5 (StateBag/NetEvent) ─ alined post Stream 3 (semantic consistency)
```

Phase A+1 timeline propuesto:

- **Day 1-2:** Stream 1 dry-run + production migration.
- **Day 2-3:** Stream 2 backend cleanup.
- **Day 3-5:** Stream 3 + Stream 4 coordinated (callbacks + Frontend lockstep).
- **Day 5-6:** Stream 5 StateBag/NetEvent.
- **Day 6:** Stream 6 audit shape final.
- **Day 7:** Integration testing + chaos smoke harness.
- **Day 8-10:** Founder runtime validation + screenshot regression + e2e Playwright + bugfix.

---

## 3. Risk register

| Risk | Severity | Mitigation |
|---|---|---|
| DB migration data loss / precision drift | CRITICAL | Backup tables + dry-run staging + ROUND(value × 100) audit per row + production sample test. |
| Frontend Streamer Mode masks regress | HIGH | Targeted test cases + Playwright screenshots pre/post + reduced-motion regression. |
| Third-party resources currently calling exports Phase 5 (INTEGER minor) keep working post Phase A+1 | LOW (NO breaking) | Phase 5 exports surface ya INTEGER minor — sin cambio. Solo callbacks (NUI-internal) y DB cambian. |
| `useI18n().money()` semantic shift breaks 200+ component instances | HIGH | Single change point in i18n.ts; comprehensive screenshot regression + Playwright. |
| Audit Explorer + Compliance Console queries break | MEDIUM | DB column type alined first (Stream 1) before Frontend Stream 4. Backend service layer Stream 2 already INTEGER. |
| Loan amortization calculations precision drift (BIGINT cents may have rounding artifacts vs DECIMAL) | MEDIUM | Loan service `loan_service.lua` uses integer math throughout post Stream 2 — explicit ROUND() at boundaries. Test interest calculation with sample loans pre/post. |
| Phase A+1 timeline collides with new feature work | MEDIUM | Phase A+1 sessions dedicated, no parallel feature work. |
| Frontend i18n locale-specific decimal/grouping separator (es-ES `1.234,56` vs en-US `1,234.56`) regress | LOW | `Intl.NumberFormat` handles correctly both INTEGER cents (divide by 100 internally) and DECIMAL major; verify in test suite. |
| Mobile/touch interaction in tablet 1280×800 changes due to layout shift | LOW | Frontend display values change but layout dimensions unchanged. |

---

## 4. Out of scope Phase A+1 (deferred Phase B+)

- Multi-currency support (Q8 LOCKED Phase A — single currency global). Phase B candidate.
- Decimal precision configuration per currency (USD 2 decimals vs JPY 0 decimals vs BTC 8 decimals). Phase B if multi-currency.
- DECIMAL precision >2 (sub-cent for FX trading). Phase C+.
- Migration of legacy `bank_*` (non-prefixed) tables — already resolved Issue #003 RESOLVED.

---

## 5. Acceptance criteria Phase A+1 CLOSE

- [ ] Stream 1: 12 columns migrated DECIMAL→BIGINT in 8 tables. Zero data loss validated.
- [ ] Stream 2: `units.from_minor()` calls removed from service layer. `units.to_minor()` kept solo en exports surface boundary (callers external pass integer; helper validates).
- [ ] Stream 3: 40+1 callbacks signature LOCKED v1.1.0 R3 + sign-off triple cycle.
- [ ] Stream 4: Frontend types + components + i18n + charts migrated. Streamer Mode regression zero. Playwright suite green.
- [ ] Stream 5: StateBag/NetEvent payload INTEGER cents. Frontend handlers updated.
- [ ] Stream 6: Audit shape final v0.4 R3.
- [ ] Boundary helpers `units.lua` deprecated (kept as historical artifact for reference, NO runtime calls).
- [ ] ST-024 series Phase 5 smoke harness re-validated post-migration.
- [ ] Founder manual checklist 100% green (per `progress/PHASE_A_PLUS_1_VALIDATION.md` to-be-emitted).
- [ ] Branch `feature/bank-phase-a-plus-1-minor-units` merged to main (or feature line equivalent).
- [ ] SESSION_LOG entry BANK-BE.PHASE_A_PLUS_1.MINOR_UNITS.1 close.

---

## 6. References

- Founder LOCK Q1 split convention: `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md:13-29`.
- Founder cross-decision #4 reconciliation: `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md:166-177`.
- Phase 5 design SSoT: `@docs/design/04_sonar_bank_api.md` v0.2.
- Phase 5 amendment package: `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/`.
- DB schema reference: `@docs/technical/03_db_schema.md` v2.1.
- Phase 5 prompt: `@docs/agents/teams/prompts/08_phase_5_ecosystem_api_backend_lead.md` §4 Phase 1.7.

— Backend Lead Phase 5 (BANK-BE.PHASE_5.1) emisión inicial — to be ratified Founder Phase 2 ceremony.
2026-05-12
