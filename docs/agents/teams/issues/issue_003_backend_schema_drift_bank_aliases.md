# Issue #003 — Backend schema drift: `bank_*` runtime repos vs `sonar_bank_*` DB schema

> **Tipo:** Backend consumer review finding — post BANK-DB.AMEND.1.
> **Status:** ✅ Closed — core + Tier 4 runtime schema drift normalized to canonical `sonar_bank_*` / `sonar_*` tables.
> **Severidad:** Alta — existing backend callbacks can query non-existent tables in the DB Phase A schema.
> **Reporter:** Backend Lead consumer review.
> **Owner requerido:** Backend Lead, with DB Lead consultative confirmation if compatibility views/migrations are considered.
> **Fecha apertura:** 2026-05-09.
> **Trigger:** Consumer review of DB amendment v2.1 DRAFT migrations `029-032` after commit `5eb6749`.

---

## 1. Resumen ejecutivo

DB Lead emitted `BANK-DB.AMEND.1` for Issue #002 and created the required persistence for GOVT/BUSINESS mock-to-real integration:

- `029_company_registry.sql`
- `030_subsidy_programs.sql`
- `031_business_payroll_persistence.sql`
- `032_govt_risk_scores_and_treasury_movements.sql`

Backend Lead consumer review confirms these migrations address the requested persistence gaps. However, the existing `sonar_bank_app` backend implementation has a broader schema drift: multiple repos/libs reference legacy or contract-only table names such as `bank_accounts`, `bank_transactions`, `bank_audit_ledger`, and `bank_idempotency_keys`, while the actual DB migrations create `sonar_bank_accounts`, `sonar_bank_movements`, `sonar_bank_audit_ledger`, and `sonar_bank_idempotency_keys`.

**Conclusion:** Issue #003 is resolved. Backend runtime data access has been normalized away from legacy `bank_*` tables for the audited core and Tier 4 paths.

---

## 2. Evidence

### 2.1 DB schema canonical tables

| Domain | Actual migration table |
|---|---|
| Accounts | `sonar_bank_accounts` |
| Movements ledger | `sonar_bank_movements` |
| Audit ledger | `sonar_bank_audit_ledger` |
| Compliance flags | `sonar_bank_compliance_flags` |
| Loans | `sonar_bank_loans` |
| Credit scores | `sonar_bank_credit_scores` |
| Stocks | `sonar_bank_stocks_assets`, `sonar_bank_stocks_transactions`, `sonar_bank_stocks_holdings` |
| Recurring payments | `sonar_bank_recurring_payments` |
| Physical cards | `sonar_bank_physical_cards` |
| Idempotency | `sonar_bank_idempotency_keys` |
| Companies | `sonar_companies`, `sonar_company_members` |
| Subsidy programs | `sonar_bank_subsidy_programs` |
| Payroll | `sonar_bank_business_payroll_batches`, `sonar_bank_business_payroll_lines` |
| GOVT risk | `sonar_bank_govt_risk_scores` |

### 2.2 Backend runtime references to legacy/non-existent tables

| File | Runtime reference |
|---|---|
| `server/repos/accounts.lua` | `bank_accounts` |
| `server/repos/transactions.lua` | `bank_transactions`, `bank_accounts` |
| `server/repos/recipients.lua` | `bank_saved_recipients` |
| `server/repos/loans.lua` | `bank_loans`, `bank_loan_payments` |
| `server/repos/recurring.lua` | `bank_recurring` |
| `server/repos/portfolio.lua` | `bank_portfolio_holdings` |
| `server/repos/cards.lua` | `bank_cards` |
| `server/repos/audit_query.lua` | `bank_audit_ledger` |
| `server/lib/audit.lua` | `bank_audit_ledger` |
| `server/lib/idempotency.lua` | `bank_idempotency_keys` |
| `server/services/loan_service.lua` | inline `UPDATE bank_loans` |

### 2.3 Core normalization progress — 2026-05-09

Path A core normalization has been applied for the first four priority areas:

| Area | Updated files | Current canonical target |
|---|---|---|
| Audit writer/query | `server/lib/audit.lua`, `server/repos/audit_query.lua` | `sonar_bank_audit_ledger` |
| Idempotency lifecycle | `server/lib/idempotency.lua` | `sonar_bank_idempotency_keys` |
| Accounts adapter | `server/repos/accounts.lua` | `sonar_bank_accounts` + `sonar_accounts` |
| Movements adapter | `server/repos/transactions.lua` | `sonar_bank_movements` + `sonar_bank_accounts` |
| IBAN/UUID validation compatibility | `server/lib/validators.lua`, `server/services/account_service.lua` | SONAR `AD-XXXX-XXXX-XXXX` format + canonical UUID v4 Lua patterns |

Static validation confirms no runtime SQL references to `bank_accounts`, `bank_transactions`, `bank_audit_ledger`, or `bank_idempotency_keys` remain in those normalized core files. Remaining `bank_*` references in those files are documentation/header comments only.

### 2.4 Tier 4 normalization closure — 2026-05-09

Path A Tier 4 normalization has been applied for the remaining legacy repositories and the ownership helper:

| Area | Updated files | Current canonical target |
|---|---|---|
| Saved recipients | `server/repos/recipients.lua`, `resources/sonar_core/migrations/033_bank_saved_recipients.sql` | `sonar_bank_saved_recipients` + `sonar_accounts` |
| Loans | `server/repos/loans.lua`, `server/services/loan_service.lua` | `sonar_bank_loans` + `sonar_bank_movements` |
| Recurring payments | `server/repos/recurring.lua`, `server/services/recurring_service.lua` | `sonar_bank_recurring_payments` |
| Portfolio / stocks | `server/repos/portfolio.lua`, `server/services/portfolio_service.lua` | `sonar_bank_stocks_assets`, `sonar_bank_stocks_transactions`, `sonar_bank_stocks_holdings` |
| Cards | `server/repos/cards.lua` | `sonar_bank_physical_cards` |
| Ownership lookup | `server/lib/auth.lua` | `sonar_bank_accounts` + `sonar_accounts` |

Static validation confirms no runtime SQL statements remain using `FROM bank_*`, `JOIN bank_*`, `INSERT INTO bank_*`, `UPDATE bank_*`, or `DELETE FROM bank_*`. Remaining `bank_*` mentions are historical comments/header documentation or canonical `sonar_bank_*` identifiers.

---

## 3. Impact

### 3.1 Existing callbacks at risk

The resource may boot and register callbacks, but callbacks depending on these repos can fail at runtime with DB errors if no compatibility tables/views exist.

Affected areas include:

- Bootstrap snapshot.
- Balance fallback.
- Transfers and recent transactions.
- Recent recipients.
- Audit Explorer.
- Loans.
- Recurring payments.
- Stocks/portfolio.
- Cards.
- Idempotent mutations.
- Audit writes.

### 3.2 New REQ-FE-006..015 risk

The new GOVT/BUSINESS endpoints can be written directly against `sonar_*` tables, but doing so while core libs still target `bank_*` creates split-brain behavior:

- New endpoints would read canonical `sonar_*` data.
- Existing transfer/audit/idempotency paths may still write or read `bank_*` names.
- Sanctions/fines/payroll require audit + idempotency; those libs are currently drifted.

Therefore mutation endpoints especially must wait until audit/idempotency/table-name drift is resolved.

---

## 4. Recommended resolution paths

### Path A — Backend normalization (recommended)

Refactor backend repos/libs to use canonical `sonar_*` tables and adapt payload mapping from DB schema to FE contracts.

Priority order:

1. `lib/audit.lua` + `repos/audit_query.lua` → `sonar_bank_audit_ledger` shape.
2. `lib/idempotency.lua` → `sonar_bank_idempotency_keys` lifecycle (`pending/completed/failed`).
3. `repos/accounts.lua` → `sonar_bank_accounts` with `id`, `owner_account_id`, `balance`, `owner_type`, `account_class`, `is_frozen`.
4. `repos/transactions.lua` → `sonar_bank_movements` read model instead of `bank_transactions`.
5. Tier 4 repos (`loans`, `recurring`, `portfolio`, `cards`) → corresponding `sonar_bank_*` schema.
6. Only then implement GOVT/BUSINESS services/callbacks on `sonar_*`.

### Path B — DB compatibility views/tables

DB Lead creates compatibility views/tables named `bank_*` matching current backend expectations.

This is **not recommended** unless Founder wants a short-term boot shim, because several current backend expectations are not simple table-name aliases:

- `bank_transactions` is transaction-oriented, while DB canonical table is ledger-oriented `sonar_bank_movements`.
- `bank_audit_ledger` expected columns differ from `sonar_bank_audit_ledger`.
- `bank_idempotency_keys` lifecycle differs from `sonar_bank_idempotency_keys`.

Core implementation notes from Path A:

- The accounts repo now exposes the previous Lua contract shape (`account_id`, `owner_citizen_id`, `balance_minor`, `savings_minor`, `status`, `frozen_flag`) while sourcing from canonical `sonar_bank_accounts`.
- `balance_minor` is derived from canonical `DECIMAL balance`; `savings_minor` is currently `0` because the canonical DB schema does not include the legacy `savings_minor` column.
- Joint owner mutation functions now fail explicitly because no canonical joint-owner persistence table is present in the reviewed migrations.
- Transactions are reconstructed from immutable `sonar_bank_movements`; transfer writes create debit/credit ledger rows with shared `related_doc_id`.

### Path C — Implement only read-only GOVT endpoints first

Implement GOVT read-only endpoints directly against `sonar_*` and defer all mutations.

This is possible but still carries integration risk because FE app bootstrap/audit areas may remain broken. It should be explicitly labeled partial/preview backend, not production-grade.

---

## 5. Backend Lead recommendation

Proceed with **Path A** before implementing mutation endpoints.

Minimum safe sequence:

1. Fix audit + idempotency canonical table drift.
2. Fix accounts + movements read/write canonical drift.
3. Run smoke/type/static checks.
4. Implement read-only GOVT endpoints.
5. Implement sanction/subsidy/business mutations after Security review of risk score formula and audit shapes.

---

## 6. Acceptance criteria

- [x] All `FROM bank_*`, `JOIN bank_*`, `INSERT INTO bank_*`, `UPDATE bank_*`, `DELETE FROM bank_*` runtime references are removed or formally justified.
- [x] Core runtime references for audit/idempotency/accounts/movements removed from SQL statements.
- [x] Backend static check validates canonical table names in normalized core files.
- [x] Audit writer writes to `sonar_bank_audit_ledger` with DB schema-compatible shape.
- [x] Idempotency lib writes to `sonar_bank_idempotency_keys` with DB schema-compatible lifecycle.
- [x] Accounts repo maps `sonar_bank_accounts` to the existing Lua/FE `Account` payload shape with documented `savings_minor=0` compatibility.
- [x] Movements repo maps `sonar_bank_movements` to the existing transaction payload shape.
- [x] Tier 4 repos (`recipients`, `loans`, `recurring`, `portfolio`, `cards`) normalized to canonical schema.
- [x] Ownership helper `server/lib/auth.lua` normalized to canonical `sonar_bank_accounts`.
- [x] REQ-FE-006..015 implementation may resume from the data-layer perspective; Security Lead review gates still apply for risk score formula/cadence and mutation audit shapes.
- [x] SESSION_LOG entry documents core normalization progress.

---

## 7. Cross-references

- `docs/agents/teams/issues/issue_002_phase_a_govt_business_persistence_gaps.md`
- `resources/sonar_core/migrations/003_bank_schema.sql`
- `resources/sonar_core/migrations/010_bank_audit_ledger.sql`
- `resources/sonar_core/migrations/028_bank_idempotency_keys.sql`
- `resources/sonar_core/migrations/029_company_registry.sql`
- `resources/sonar_core/migrations/030_subsidy_programs.sql`
- `resources/sonar_core/migrations/031_business_payroll_persistence.sql`
- `resources/sonar_core/migrations/032_govt_risk_scores_and_treasury_movements.sql`
- `resources/sonar_core/migrations/033_bank_saved_recipients.sql`
- `resources/sonar_bank_app/server/repos/*.lua`
- `resources/sonar_bank_app/server/lib/auth.lua`
- `resources/sonar_bank_app/server/lib/audit.lua`
- `resources/sonar_bank_app/server/lib/idempotency.lua`

---

## 8. Estado

| Fecha | Acción | Por |
|---|---|---|
| 2026-05-09 | Issue creado durante Backend Lead consumer review post DB amendment v2.1 DRAFT | Backend Lead |
| 2026-05-09 | Founder approved Path A normalization; core audit/idempotency/accounts/movements normalization applied | Founder + Backend Lead |
| 2026-05-09 | Static validation: `git diff --check` passed; no runtime SQL legacy references remain in normalized core files | Backend Lead |
| 2026-05-09 | Tier 4 repos normalized to canonical schema; `033_bank_saved_recipients.sql` added for missing saved recipients canonical table | Backend Lead |
| 2026-05-09 | Extra runtime drift fixed in `server/lib/auth.lua`; static validation confirms no legacy `bank_*` runtime SQL statements remain | Backend Lead |
| 2026-05-09 | Issue #003 closed; REQ-FE-006..015 may resume from data-layer perspective, subject to remaining Security/Founder gates | Backend Lead |

— **Issue #003 CLOSED. Backend runtime schema drift from legacy `bank_*` tables to canonical `sonar_bank_*` / `sonar_*` tables has been resolved.**
