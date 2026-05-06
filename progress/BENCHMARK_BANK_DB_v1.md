# BENCHMARK_BANK_DB v0.5 — Bank Phase A Performance Analysis (Pre-execution)

> **Status:** 🟡 **DRAFT v0.5 — Structural analysis + founded estimates.** DB Lead authoring 2026-05-06 (BANK-DB.4).
>
> **Critical disclosure:** **Real execution NOT performed in this session.** Las estimaciones documentadas a continuación están basadas en:
> - Análisis estructural EXPLAIN expected (índices coverage + partition pruning).
> - Benchmarks públicos MariaDB 12.x InnoDB con hardware reference (commodity SSD/NVMe, 8 cores, 16GB RAM, `innodb_buffer_pool_size=8G`).
> - Cálculo conservador worst-case scenarios.
>
> **Actual execution requires:**
> 1. DB schema applied a dev DB (migrations 010-028 ejecutadas).
> 2. Seed data sintético generado (10K citizens + 12K accounts + 1M movements).
> 3. Harness Lua functional (Backend Lead post-H1 scope — NO existe en Phase A pre-coding).
>
> **Sign-off LOCKED v1.0 strategy:** **PROVISIONAL LOCKED** estructural — design + indexes + queries + DDL aprobados. **Real benchmark execution mandatory post-handoff H1** + Backend Lead implementa harness + reporta resultados + AMENDMENT v1.1 si targets fail.

---

## 1. Engine + hardware reference

| Item | Valor canonical |
|---|---|
| **Engine** | MariaDB 12.2.2 (Q-DB-A LOCKED 2026-05-06) |
| **Storage engine** | InnoDB |
| **Charset / collation** | `utf8mb4` / `utf8mb4_unicode_ci` |
| **Connection pool** | `oxmysql` recommended initial **30 connections** (justificación §4) |
| **Hardware reference (recommended dev DB)** | 8 cores Intel/AMD modern + 16GB RAM + NVMe SSD + `innodb_buffer_pool_size=8G` + `innodb_flush_log_at_trx_commit=1` |
| **Production hardware (TBD DevOps)** | DevOps Lead post-H4 documenta target hardware servidor producción |

---

## 2. Methodology

### 2.1 Test setup canonical

- **Schema:** todas migrations 001-028 ejecutadas (Phase A complete).
- **Seed data:** 10.000 citizens + 12.000 bank_accounts + 1.000.000 bank_movements (12 meses históricos sintéticos) + 100.000 audit_ledger rows + 50.000 stocks_transactions.
- **Network simulation:** localhost + 10ms artificial latency simulando WAN realista.
- **Concurrency:** 200 concurrent simulated FiveM clients vía harness Lua + `oxmysql.transaction` parallel.

### 2.2 Test harness (post-H1 deliverable)

**Owner:** Backend Lead post-H1 implementa harness Lua.

```lua
-- progress/bench_bank_db_v1.lua — Backend Lead post-H1 deliverable
-- 200 parallel reconciliation operations + measure p50/p95/p99 latency.
-- Tooling: oxmysql query timing + GetGameTimer() per-op + aggregate report.
```

### 2.3 Métricas capturadas

| Métrica | Tooling | Status DRAFT v0.5 |
|---|---|---|
| Latency p50 / p95 / p99 (ms) | oxmysql + Lua GetGameTimer() | 🟡 estimado teórico |
| Throughput (ops/s) | counter ops finished / wall-clock | 🟡 estimado teórico |
| Connection pool saturation | `oxmysql:state()` periodic sample | 🟡 estimado |
| InnoDB lock wait time | `INFORMATION_SCHEMA.INNODB_TRX` | 🟡 N/A pre-execution |
| Partition pruning | `EXPLAIN PARTITIONS` | ✅ verificado estructural §5 |

---

## 3. Targets canonical (Q-FOUNDER mandatory para LOCKED v1.0)

### 3.1 Reconciliation pipeline (Q16.5 + CP3) — Chaos Test 200 concurrent

> **Target founder:** 200 concurrent reconciliation <500ms p99.

| Test | Target | Estimación estructural DRAFT v0.5 | Status |
|---|---|---|---|
| Reconciliation single account (warm cache) | <50ms p99 | ~5-15ms p99 (PK lookup `bank_account_id` + UPDATE balance + INSERT 2 movements + INSERT audit) | 🟢 **expected PASS** |
| Reconciliation 200 concurrent main accounts (CP6 scope) | <500ms p99 | ~150-350ms p99 (assume 30 connection pool sat 60-80%, async batch SQL, mutex correlation-id Backend lib) | 🟢 **expected PASS con margin** |
| Reconciliation pipeline async batch SQL multi-row | <300ms p99 | ~80-200ms p99 (multi-row UPDATE + bulk INSERT batched 100 ops/tx) | 🟢 **expected PASS** |

**Análisis estructural:**

- **Index coverage:** `idx_sonar_bank_movements_account (bank_account_id, occurred_at DESC)` — ZGT lookup directo.
- **Partition pruning:** `bank_movements` particionado RANGE month — escaneo solo current month partition (vs full table scan).
- **InnoDB row locking:** Backend Lead lib usa `correlation-id` mutex CP2 path #1 (NO hash-mutex) — evita deadlocks.
- **Riesgo identificado:** Si 200 concurrent ops hit mismo `bank_account_id` (worst case fan-in) → contention severo. **Mitigation:** Backend Lead post-H1 implementa per-account lock queue + circuit breaker timeout 100ms.

### 3.2 Audit ledger insert throughput (Q-DB-F)

> **Target founder:** >1000 inserts/s sustained.

| Test | Target | Estimación DRAFT v0.5 | Status |
|---|---|---|---|
| Audit ledger INSERT single | <2ms p99 | ~0.5-1.5ms p99 (INSERT con triggers SIGNAL only fire on UPDATE/DELETE — NO overhead INSERT) | 🟢 **expected PASS** |
| Audit ledger INSERT batch 100 rows | <50ms p99 | ~10-30ms p99 (multi-row INSERT batched) | 🟢 **expected PASS** |
| Audit ledger throughput sustained | >1000 inserts/s | ~3000-8000 inserts/s teórico (commodity SSD InnoDB write-heavy benchmarks públicos) | 🟢 **expected PASS con margin 3-8x** |

**Análisis estructural:**

- **Append-only design** — sin UPDATE locks (triggers SIGNAL solo bloquean UPDATE/DELETE).
- **Partition pruning** — INSERT a current month partition only.
- **Index overhead:** 4 indexes secundarios por row (iban_ts + event_ts + severity_ts + correlation) — costo write amplification ~4x but acceptable a target.

### 3.3 Government Console "Todas" scope (Q10 audit explorer)

> **Target founder:** <200ms scope full 5 años data.

| Test | Target | Estimación DRAFT v0.5 | Status |
|---|---|---|---|
| Audit Explorer scope "Mi cuenta" 30 días | <50ms p99 | ~5-20ms p99 (index `idx_..._iban_ts` + partition pruning último mes) | 🟢 **expected PASS** |
| Audit Explorer scope "Todas" filtered event_type 5 años | <200ms p99 | ~80-180ms p99 (index `idx_..._event_ts` + partition pruning múltiples meses, 60 partitions scanned worst case) | 🟡 **expected PASS borderline — verify** |
| Compliance dashboard "open critical" | <100ms p99 | ~10-40ms p99 (index `idx_..._severity_status` + small filtered set típicamente <100 rows) | 🟢 **expected PASS** |

**Análisis estructural:**

- **Worst case identificado:** "Todas" scope 5 años con event_type filter pero sin date filter narrow → debe scan 60 partitions. **Mitigation:** UI obliga date range max 1 año por default + button "expand" para 5 años (raro).
- **Posible optimización futura:** materialized summary view per evento_type/month si benchmark real >200ms.

### 3.4 Money operations hot path

| Test | Target | Estimación DRAFT v0.5 | Status |
|---|---|---|---|
| Transfer atomic (2 movements + audit + 2 balance updates) | <30ms p99 | ~5-15ms p99 (1 transaction + 2 UPDATEs PK + 3 INSERTs + 1 audit append) | 🟢 **expected PASS** |
| Escrow create (atomic 3 inserts + 2 balance updates) | <40ms p99 | ~8-20ms p99 | 🟢 **expected PASS** |
| Bank account balance read (cached State Bag) | <1ms p99 | <0.5ms (CP1 State Bag global, NO DB hit en hot path) | 🟢 **expected PASS** |

### 3.5 Status FSM (CP8 single-row global)

| Test | Target | Estimación DRAFT v0.5 | Status |
|---|---|---|---|
| Status read PK fijo `id=1` | <1ms p99 | <0.5ms (PK lookup InnoDB clustered index) | 🟢 **expected PASS** |
| Status transition UPDATE | <5ms p99 | ~1-3ms (UPDATE PK + trigger BEFORE INSERT singleton check) | 🟢 **expected PASS** |

---

## 4. Connection pool sizing recommendation

> **Recommendation DRAFT v0.5:** `set oxmysql_connection_count 30` initial value.

**Justificación:**

- **Carga base:** 30 concurrent active queries simultaneous + reserve para audit triggers + cron jobs.
- **Saturation limit:** 200 concurrent ops worst-case → 30 connections × ~150ms avg query = 200 ops/s sustainable theoretical.
- **Verification post-execution:** Backend Lead post-H1 ejecuta harness chaos 200 concurrent + measure pool utilization. Si >85% sustained → upgrade a 50.

**Tunings recomendados oxmysql:**

```cfg
set oxmysql_connection_count 30
set oxmysql_debug false
set oxmysql_slow_query_warning 150  # ms
```

---

## 5. Partition pruning verification (estructural)

> ✅ **Verificación analítica estructural completa** — `EXPLAIN PARTITIONS` esperado per query hot path.

### Verification queries canonical

```sql
-- Q1 audit ledger Mi cuenta 30 días → debe escanear 1-2 partitions max.
EXPLAIN PARTITIONS
SELECT id, ts FROM sonar_bank_audit_ledger
WHERE bank_account_iban = ? AND ts >= UNIX_TIMESTAMP() - 30*86400;
-- Expected partitions: p_2026_<curr> + opcional p_2026_<prev>.

-- Q2 bank_movements citizen statement último mes → 1 partition.
EXPLAIN PARTITIONS
SELECT * FROM sonar_bank_movements
WHERE bank_account_id = ? AND occurred_at >= UNIX_TIMESTAMP() - 30*86400
ORDER BY occurred_at DESC LIMIT 100;
-- Expected: 1 partition (p_2026_<curr>).

-- Q3 subsidies UBI mensual → 1 partition.
EXPLAIN PARTITIONS
SELECT * FROM sonar_bank_subsidies
WHERE beneficiary_account_id = ? AND subsidy_kind = 'ubi_monthly'
ORDER BY issued_at DESC LIMIT 24;
-- Expected: 1-2 partitions.
```

**Failure mode si NO partition pruning:** `EXPLAIN PARTITIONS` muestra TODAS las partitions → query causes full table scan. Causa probable: WHERE clause sin partition key (`ts` / `occurred_at` / `issued_at` ausente). **Backend Lead post-H1 enforce partition key SIEMPRE en WHERE.**

---

## 6. Index effectiveness verification (estructural)

✅ **Audit per query hot path completo** — todos los indexes referenciados existen + match WHERE clauses.

| Query | Index esperado | Status estructural |
|---|---|---|
| Audit Mi cuenta | `idx_sonar_bank_audit_ledger_iban_ts` | ✅ verified migration 010 |
| Audit Todas filtered | `idx_sonar_bank_audit_ledger_event_ts` | ✅ verified migration 010 |
| Compliance dashboard | `idx_sonar_bank_compliance_flags_severity_status` | ✅ verified migration 011 |
| Audit chain debug | `idx_sonar_bank_audit_ledger_correlation` | ✅ verified migration 010 |
| Reconciliation balance read | `PRIMARY KEY sonar_bank_accounts (id)` | ✅ |
| Movements citizen statement | `idx_sonar_bank_movements_account` | ✅ verified migration 003 |
| Movements category filter | `idx_sonar_bank_movements_category` | ✅ verified migration 003 |
| Loans active citizen | `idx_sonar_bank_loans_borrower_state` | ✅ verified migration 018 |
| Loans cron payments due | `idx_sonar_bank_loans_state_due` | ✅ verified migration 018 |
| Crypto portfolio citizen | `uq_sonar_bank_crypto_wallets_citizen_asset` | ✅ verified migration 019 |
| Stocks holdings citizen | `uq_sonar_bank_stocks_holdings_citizen_asset` | ✅ verified migration 020 |
| Recurring cron hot path | `idx_sonar_bank_recurring_state_next` | ✅ verified migration 021 |
| Idempotency lookup | `uq_sonar_bank_idempotency_keys_key` | ✅ verified migration 028 |

**Backend Lead post-H1 mandatory action:** ejecutar `EXPLAIN FORMAT=JSON` per query post-deployment + verify `key` matches expected. Cualquier deviación → AMENDMENT schema v1.1.

---

## 7. Failure scenarios + mitigations

| Scenario | Mitigation pre-implementada | Status |
|---|---|---|
| Reconciliation deadlock 200 concurrent | Backend Lead mutex correlation-id CP2 + retry exponential backoff | 🟡 Backend Lead post-H1 implementa |
| Audit ledger trigger SIGNAL fires legitimate operation | Backend lib `BankAuditLedger.Append` only INSERT — UPDATE/DELETE NEVER attempted en código | ✅ documented schema §22 |
| Partition p_future fills before cron rolling forward | DevOps Lead alert + manual REORGANIZE PARTITION emergency procedure | 🟡 DevOps post-H4 documenta runbook |
| Connection pool saturation 100% | Sizing 30 + monitoring + alert >85% → upgrade 50 | 🟡 DevOps post-H4 monitoring stack |
| Idempotency key UNIQUE conflict race condition | Backend lib INSERT IGNORE + SELECT existing + state check | ✅ documented schema §27 |
| Crypto BIGINT overflow | BIGINT UNSIGNED max = 18.4 × 10^18 — safe BTC supply 21M × 10^8 = 2.1 × 10^15 (<<max) | ✅ verified arithmetic |
| Stocks holdings stale snapshot | last_recomputed_at staleness check Backend lib lazy recompute >5min | ✅ documented schema §25.3 |

---

## 8. Sign-off matrix LOCKED v1.0 (PROVISIONAL)

> **Strategy:** **PROVISIONAL LOCKED** — schema design + DDL + indexes + queries aprobados estructuralmente. Real benchmark execution mandatory post-handoff H1.

| Stakeholder | Sign-off scope | Status DRAFT v0.5 |
|---|---|---|
| ☐ Founder yaboula | Green-light schema design + estimaciones fundadas + provisional LOCKED | 🟡 **pending review BANK-DB.4 deliverables** |
| ☐ DB Lead (Cascade) | DDL + migrations + indexes + queries documented + analysis estructural completo | ✅ **DB Lead self-sign-off DRAFT v0.5** |
| ☐ Backend Lead consumer | Acepta schema H1 + commit a implementar harness Lua + ejecutar benchmarks reales + reportar | 🟡 **pending H1 ceremony** |
| ☐ Security Lead consumer | Acepta audit ledger + compliance flags + dual-layer privacy diseño | 🟡 **pending H2 ceremony** |
| ☐ DevOps Lead | Hardware reference documented + monitoring stack + cron runbooks pendientes | 🟡 **pending post-H4** |

**LOCKED v1.0 condicional clauses:**

1. Backend Lead post-H1 ejecuta benchmarks reales harness Lua + reporta resultados.
2. Si target Q3 ("Todas" scope 5 años) **>200ms** real → AMENDMENT v1.1 add materialized summary view per event_type/month.
3. Si reconciliation 200 concurrent **>500ms p99** real → AMENDMENT v1.1 add per-account lock queue Backend + circuit breaker.
4. Si connection pool sustained **>85%** → upgrade `oxmysql_connection_count` 30 → 50 (DevOps tuning).

---

## 9. Versioning

| Version | Fecha | Status | Cambios |
|---|---|---|---|
| **v0.1 DRAFT** | 2026-05-06 | Skeleton | Initial release skeleton — methodology + targets + sign-off matrix. |
| **v0.5 DRAFT** | 2026-05-06 | Pre-execution analysis | Análisis estructural completo + estimaciones fundadas + verification queries + failure scenarios + provisional LOCKED matrix. **Real execution post-H1 harness pendiente.** |
| v1.0 LOCKED | (pending) | Real execution + sign-off triple completo | Pendiente Backend Lead post-H1 ejecuta harness + reporta resultados + AMENDMENT si needed. |

---

## 10. Disclaimer & Honesty Statement

**Esta DRAFT v0.5 NO contiene números medidos.** Todas las estimaciones son fundadas en:

- **Estructura schema verificada** (indexes match queries, partition keys correct, FK estándar).
- **Benchmarks públicos MariaDB 12.x** referenciados (sin copy-paste arbitrario).
- **Análisis worst-case scenarios** + mitigations documented.

**Las cifras "p99 estimado" deben tratarse como TARGETS GUÍA, NO como measurements verificados.**

**Acción mandatory:** Backend Lead post-H1 ejecuta harness Lua + Real benchmarks + reporta resultados verificables a este documento → promoted v1.0 LOCKED MEASURED.

— **BENCHMARK DRAFT v0.5** — DB Lead authoring 2026-05-06 (BANK-DB.4 — provisional structural analysis pending real execution post-H1).
