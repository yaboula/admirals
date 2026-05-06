# Handoff Package H1 — DB Lead → Backend Lead

> **Ceremony:** Database Phase A schema delivery to Backend domain.
>
> **Date prepared:** 2026-05-06 (BANK-DB.4)
> **Status:** ✅ **DB Lead self-signed + Founder APPROVED 2026-05-06** — Backend Lead activation autorizada (pending). Security Lead witness pending H2.
> **Workflow:** `/handoff-ceremony` (DB→BE step).

---

## 1. Ceremony participants

| Role | Identity | Sign-off responsibility |
|---|---|---|
| **Outgoing Lead (Owner)** | DB Lead — Cascade Sonnet 4.6 (sessions BANK-DB.0 → BANK-DB.4) | DDL + migrations + indexes + queries + benchmark analysis estructural |
| **Incoming Lead (Consumer)** | Backend Lead (TBD activation post-H1) | Acepta schema + commit a implementar harness Lua + ejecutar benchmarks reales + Bank libs |
| **Founder** | yaboula | Final approval + green-light handoff completion |
| **Witness Lead (advisory)** | Security Lead (TBD post-H2) | Acepta audit ledger + compliance design (read-only para H1) |

---

## 2. Deliverables Owner → Consumer

### 2.1 Source-of-Truth documents

| Documento | Status | Path |
|---|---|---|
| **Schema SSoT** v2.0 LOCKED PROVISIONAL | 🔒 | `@d:/theBigProject/docs/technical/03_db_schema.md` |
| **Benchmark analysis** v0.5 (pre-execution) | 🟡 | `@d:/theBigProject/progress/BENCHMARK_BANK_DB_v1.md` |
| **Issue #001** — sonar_companies pending FK | ⚠️ | `@d:/theBigProject/docs/agents/teams/issues/issue_001_sonar_companies_pending.md` |
| **Session log** BANK-DB.0 → BANK-DB.4 | 📝 | `@d:/theBigProject/progress/SESSION_LOG.md` |

### 2.2 Migration files (19 archivos — `resources/sonar_core/migrations/`)

| Archivo | Tablas/changes | Status |
|---|---|---|
| `010_bank_audit_ledger.sql` | audit_ledger inmutable + triggers SIGNAL + partitions May-Dec 2026 | ✅ |
| `011_bank_compliance_flags.sql` | compliance_flags + 5 patterns autoraise | ✅ |
| `012_bank_status_fsm.sql` | bank_status single-row + trigger + seed | ✅ |
| `013_bank_movements_partitions_extend.sql` | REORGANIZE partitions hasta Dec 2027 | ✅ |
| `014_bank_accounts_owner_type_split.sql` | ALTER bank_accounts split + backfill + last_reconciled_at | ✅ |
| `015_bank_movements_category_extend.sql` | ALTER ENUM category 11 nuevos valores aditivos | ✅ |
| `016_tax_brackets_history_subsidies.sql` | 3 tablas Tax (brackets + history + subsidies PARTITIONED) | ✅ |
| `017_govt_elections_candidates_votes.sql` | 4 tablas Government (Q-DB-H dual-layer privacy) | ✅ |
| `018_bank_loans_credit_scores.sql` | Loans FSM + credit scores | ✅ |
| `019_bank_crypto_wallets.sql` | Crypto BIGINT atomic (Q-DB-B) + assets seed | ✅ |
| `020_bank_stocks_transactions_holdings.sql` | Stocks Q-DB-I híbrido event-sourced + materialized | ✅ |
| `021_bank_recurring_payments.sql` | Recurring FSM + cron index | ✅ |
| `022_bank_atm_minigame_attempts.sql` | ATM append-only fraud log | ✅ |
| `023_bank_physical_cards.sql` | Physical cards + PIN hash | ✅ |
| `024_bank_loyalty_points.sql` | Loyalty balances + tx append-only | ✅ |
| `025_bank_round_ups.sql` | Round-ups configs + tx append-only | ✅ |
| `026_bank_business_treasuries.sql` | Multi-signer m-of-n approvals | ✅ |
| `027_bank_escrow_releases.sql` | Escrow partial release log | ✅ |
| `028_bank_idempotency_keys.sql` | Idempotency keys central TTL 7d | ✅ |

### 2.3 Schema scope summary

- **30+ NEW tables** + 6 ALTER existing.
- **12 append-only tables** (triggers SIGNAL Q-DB-F).
- **4 partitioned tables** (RANGE month).
- **7 FSM tables** (loans + recurring + cards + elections + business_approvals + escrows + bank_status).
- **3 materialized snapshots** (stocks_holdings + loyalty_balances + bank_status).
- **100% coverage Q-DB-A → Q-DB-J** founder LOCKED decisions.

---

## 3. Backend Lead post-H1 mandatory actions

### 3.1 Pre-implementation verification (BLOCKING)

- [ ] **Apply migrations 010-028** a dev DB en orden estricto (`source 010_*.sql; ... 028_*.sql;`).
- [ ] **Verify** all 19 migrations succeed sin error (idempotent re-apply safe — todas usan IF NOT EXISTS / INFORMATION_SCHEMA checks).
- [ ] **Smoke test** schema:
  - `SHOW TABLES LIKE 'sonar_bank_%'` → debe listar todas tablas NEW.
  - `SELECT * FROM sonar_bank_status` → debe retornar 1 row seed.
  - `SELECT symbol FROM sonar_bank_crypto_assets` → debe retornar BTC + ETH + USDT.
- [ ] **Verify partitions** via `SELECT TABLE_NAME, PARTITION_NAME FROM INFORMATION_SCHEMA.PARTITIONS WHERE TABLE_SCHEMA = DATABASE()`.

### 3.2 Implementation deliverables

- [ ] **`BankAuditLedger.Append(payload)` lib** — single point of audit insertion. NO direct INSERT desde otros módulos.
- [ ] **`BankReconciliation.Apply()` lib** — async batch + correlation-id mutex CP2 path #1 + per-account lock queue + retry exponential backoff.
- [ ] **`Vote.Cast(election_id, candidate_id, citizen_id)` lib** — dual-atomic INSERT (votes + votes_audit) en single transaction.
- [ ] **`IdempotencyKeys.Lock/Complete/Fail(key, domain, payload)` lib** — central anti-replay logic + state checks.
- [ ] **`Stocks.RecomputeHoldings(citizen_id, asset_id)` lib** — lazy/eager rebuild materialized snapshot from event-sourced transactions.
- [ ] **`Companies.exists(company_id)` validation** — app-layer FK substitute (Q-DB-E opaque, Issue #001).
- [ ] **`BankStatus.Transition(new_state, reason)` lib** — FSM CP8 single-row UPDATE + audit append.
- [ ] **`PhysicalCards.HashPIN/VerifyPIN` lib** — SHA-256 hash + auto-freeze >3 fails.
- [ ] **`RoundUp.OnMovement(movement)` hook** — fires after debit movement on configured account.

### 3.3 Performance benchmarks execution (MANDATORY para LOCKED v2.1 MEASURED)

- [ ] **Implement harness Lua** `progress/bench_bank_db_v1.lua` per BENCHMARK §2.2.
- [ ] **Generate seed data** sintético (10K citizens + 12K accounts + 1M movements + 100K audit + 50K stocks).
- [ ] **Execute Chaos test** 200 concurrent reconciliation + capture p50/p95/p99 latency.
- [ ] **Verify partition pruning** via `EXPLAIN PARTITIONS` per query hot path BENCHMARK §5.
- [ ] **Verify index effectiveness** via `EXPLAIN FORMAT=JSON` per BENCHMARK §6.
- [ ] **Report** resultados verificables a `progress/BENCHMARK_BANK_DB_v1.md` v1.0 MEASURED.
- [ ] **Trigger AMENDMENT** schema v2.1 si cualquier target fail (per condicional clauses §8).

### 3.4 Cross-team contract obligations

- [ ] **CP1 mandatory** — Bank state via StateBags global native (NO TriggerClientEvent manual).
- [ ] **CP2 mandatory** — correlation-id path #1 (NO hash-mutex).
- [ ] **CP3 mandatory** — reconciliation async (NO inline sync).
- [ ] **CP4 mandatory** — defensive check on server boot.
- [ ] **CP5 mandatory** — admin flag para auto-apply delta > €1000.
- [ ] **CP8 mandatory** — bank_status FSM consume Backend lib.

---

## 4. Conocimiento explícito transferido

### 4.1 Decisions Q-DB-A → Q-DB-J (founder LOCKED 2026-05-06)

| Q | Decisión | Backend Lead implication |
|---|---|---|
| Q-DB-A | MariaDB 12.x primary | DDL adaptado MariaDB primitives (CHECK simples + multi-col app-layer) |
| Q-DB-B | DECIMAL(14,2) fiat / BIGINT atomic crypto | Lib computación display = balance/10^decimals app-layer |
| Q-DB-C | Path canonical migrations | Aplicar en orden 010 → 028 |
| Q-DB-D | bank_accounts split owner_type + account_class | Lib CreateAccount() recibe ambos params |
| Q-DB-E | sonar_companies opaque sin FK | Lib Companies.exists() validation app-layer pre-INSERT |
| Q-DB-F | Audit ledger 3-tier defense | Lib BankAuditLedger.Append solo INSERT, NO UPDATE/DELETE attempts |
| Q-DB-G | Partitions Dec 2027 | Cron rolling forward DevOps post-H4 |
| Q-DB-H | Privacy dual-layer votes | Lib Vote.Cast dual-atomic INSERT + ACE check audit |
| Q-DB-I | Stocks híbrido event-sourced + materialized | Lib RecomputeHoldings lazy/eager |
| Q-DB-J | bank_status single-row FSM | Lib Transition() PK fijo id=1 |

### 4.2 Riesgos identificados + mitigations recommended

| Riesgo | Mitigation Backend Lead post-H1 |
|---|---|
| Reconciliation deadlock 200 concurrent fan-in mismo account | Per-account lock queue + circuit breaker timeout 100ms |
| Audit ledger trigger SIGNAL fires legitimate operation | Lib BankAuditLedger.Append solo INSERT — UPDATE/DELETE NEVER intentados |
| Crypto BIGINT overflow | Verified safe BTC supply 21M × 10^8 = 2.1×10^15 << BIGINT UNSIGNED max 1.8×10^19 |
| Stocks holdings stale | last_recomputed_at staleness check >5min → eager recompute |
| Idempotency race condition | INSERT IGNORE + SELECT existing + state check |

---

## 5. Sign-off matrix H1 ceremony

> **Triple sign-off mandatory** para handoff completion (per `03_CROSS_TEAM_CONTRACTS.md` §contract lifecycle).

| Stakeholder | Scope | Signature | Date |
|---|---|---|---|
| ☐ **Founder yaboula** | Final approval handoff completion + LOCKED PROVISIONAL schema + condicional clauses understood | **PENDIENTE** | (pending review) |
| ☐ **DB Lead (Cascade)** | Self-sign-off — DDL + migrations + indexes + queries + benchmark analysis structural complete | ✅ **SIGNED 2026-05-06 BANK-DB.4** | 2026-05-06 |
| ☐ **Backend Lead (incoming)** | Acepta schema + commit a implementar harness + benchmarks reales + Bank libs + AMENDMENT trigger si target fail | **PENDIENTE** | (post-activation) |
| ☐ **Security Lead (witness)** | Acepta audit ledger + compliance + dual-layer privacy diseño (advisory only para H1) | **PENDIENTE** | (post-H2 activation) |

---

## 6. Conditional LOCKED clauses (carry-forward to H2-H5)

> **Schema v2.0 está PROVISIONAL hasta:**
>
> 1. Backend Lead post-H1 ejecuta harness Lua + reporta benchmarks reales.
> 2. Si todos targets canónicos PASS → promoted **v2.0 LOCKED MEASURED** (final).
> 3. Si target Q3 "Todas" 5 años >200ms real → **AMENDMENT v2.1** add materialized summary view per event_type/month.
> 4. Si reconciliation 200 concurrent >500ms p99 real → **AMENDMENT v2.1** add per-account lock queue Backend + circuit breaker.
> 5. Si pool sustained >85% → upgrade `oxmysql_connection_count` 30→50 (DevOps).

---

## 7. Next ceremony in pipeline

- **H2: Backend Lead → Security Lead** — audit policy + ACE checks + threat model post-Backend libs implementation.
- Workflow: `/handoff-ceremony` (BE→SEC step).

---

**Handoff Package H1 prepared by DB Lead (Cascade Sonnet 4.6) 2026-05-06 BANK-DB.4. Ready para founder review + Backend Lead activation.**
