# BENCHMARK_BANK_DB v1.0 DRAFT v0.1 — Bank Phase A Performance

> **Status:** 🟡 DRAFT v0.1 — DB Lead authoring 2026-05-06 (BANK-DB.1).
>
> **Scope:** Performance benchmarks chaos test 200 concurrent reconciliation <500ms p99 (Q16.5 + slice §8.3).
>
> **Mandatory para sign-off LOCKED v1.0:** ejecución completa todos targets §3 + reporte resultados.
>
> **Ejecución prevista:** BANK-DB.4 post completion DRAFT v0.3 + benchmark harness Backend Lead post-H1.

---

## 1. Engine + hardware reference

| Item | Valor |
|---|---|
| **Engine** | MariaDB 12.2.2 (locked Q-DB-A 2026-05-06) |
| **Storage engine** | InnoDB |
| **Charset / collation** | `utf8mb4` / `utf8mb4_unicode_ci` |
| **Connection pool** | `oxmysql` ≥30 connections (slice OQ-DB-10 recommendation) |
| **Hardware reference** | TBD — DevOps Lead post-H4 documentar (CPU cores, RAM, disk SSD/NVMe, MariaDB innodb_buffer_pool_size) |

---

## 2. Methodology

### 2.1 Test setup

- **Schema:** todas migrations 001-008 + 010-013 (DRAFT v0.1) + futuras v0.2/v0.3 aplicadas.
- **Seed data:** 10.000 citizens + 12.000 bank_accounts + 1.000.000 bank_movements (12 meses históricos sintéticos) + 100.000 audit_ledger rows.
- **Network simulation:** localhost + 10ms artificial latency simulando WAN realista.
- **Concurrency:** 200 concurrent simulated FiveM clients vía harness Lua + `oxmysql.transaction` parallel.

### 2.2 Test harness

> **Owner:** Backend Lead post-H1 implementa harness Lua + script ejecutor.

```lua
-- progress/bench_bank_db_v1.lua (TBD Backend Lead post-H1)
local function chaosTestReconciliation()
  -- 200 parallel reconciliation operations + measure p50/p95/p99 latency.
end
```

### 2.3 Métricas capturadas

| Métrica | Tooling |
|---|---|
| Latency p50 / p95 / p99 (ms) | `oxmysql` query timing + Lua `GetGameTimer()` |
| Throughput (ops/s) | counter ops finished / wall-clock |
| Connection pool saturation | `oxmysql:state()` periodic sample |
| InnoDB lock wait time | `INFORMATION_SCHEMA.INNODB_TRX` + `INNODB_LOCKS` snapshot |
| Partition pruning effectiveness | `EXPLAIN PARTITIONS` per query |

---

## 3. Targets canonical (sign-off LOCKED v1.0 mandatory)

### 3.1 Reconciliation pipeline (Q16.5 + CP3)

> **Target:** 200 concurrent reconciliation operations <500ms p99.

| Test | Target | Status DRAFT v0.1 |
|---|---|---|
| Reconciliation single account (warm cache) | <50ms p99 | ⏳ Pending v0.4 |
| Reconciliation 200 concurrent main accounts (CP6 scope) | <500ms p99 | ⏳ Pending v0.4 |
| Reconciliation pipeline async batch SQL multi-row | <300ms p99 | ⏳ Pending v0.4 |

### 3.2 Audit ledger insert throughput

> **Target:** >1000 inserts/s sustained.

| Test | Target | Status DRAFT v0.1 |
|---|---|---|
| Audit ledger INSERT single | <2ms p99 | ⏳ Pending v0.4 |
| Audit ledger INSERT batch 100 rows | <50ms p99 | ⏳ Pending v0.4 |
| Audit ledger throughput sustained | >1000 inserts/s | ⏳ Pending v0.4 |

### 3.3 Government Console "Todas" scope

> **Target:** <200ms scope full 5 años data.

| Test | Target | Status DRAFT v0.1 |
|---|---|---|
| Audit Explorer scope "Mi cuenta" 30 días | <50ms p99 | ⏳ Pending v0.4 |
| Audit Explorer scope "Todas" filtered event_type 5 años | <200ms p99 | ⏳ Pending v0.4 |
| Compliance dashboard "open critical" | <100ms p99 | ⏳ Pending v0.4 |

### 3.4 Money operations hot path

| Test | Target | Status DRAFT v0.1 |
|---|---|---|
| Transfer atomic (2 movements + audit + balance update) | <30ms p99 | ⏳ Pending v0.4 |
| Escrow create (atomic 3 inserts + 2 balance updates) | <40ms p99 | ⏳ Pending v0.4 |
| Bank account balance read (cached State Bag) | <1ms p99 | ⏳ Pending v0.4 |

### 3.5 sonar_bank_status FSM (CP8)

| Test | Target | Status DRAFT v0.1 |
|---|---|---|
| Status read PK fijo `id=1` | <1ms p99 | ⏳ Pending v0.4 |
| Status transition UPDATE | <5ms p99 | ⏳ Pending v0.4 |

---

## 4. Connection pool sizing recommendation

> **Status:** 🟡 Pending benchmark execution. Initial recommendation `oxmysql_connection_count = 30` (slice OQ-DB-10).

**Validation strategy v0.4:**

1. Run chaos 200 concurrent con pool size 20 → measure saturation %.
2. Increase 30 → measure improvement.
3. Increase 50 → measure diminishing returns.
4. Lock recommendation con margen 50% over saturation point.

---

## 5. Partition pruning verification

> **Status:** 🟡 Pending verification post migrations 010 + 013 applied.

```sql
-- Verification query
EXPLAIN PARTITIONS
SELECT id, ts FROM sonar_bank_audit_ledger
WHERE bank_account_iban = ? AND ts >= UNIX_TIMESTAMP() - 30*86400;

-- Expected: only p_2026_<current_month> + p_2026_<prev_month> scanned.
-- Failure mode: all partitions scanned → index not used or partition key not in WHERE.
```

---

## 6. Index effectiveness

> **Status:** 🟡 Pending benchmark execution v0.4.

**Audit per index:**

- `idx_sonar_bank_audit_ledger_iban_ts` — used by Q1 (Audit Explorer Mi cuenta).
- `idx_sonar_bank_audit_ledger_event_ts` — used by Q2 (Government Console Todas).
- `idx_sonar_bank_audit_ledger_severity_ts` — used by Q3 (Compliance dashboard).
- `idx_sonar_bank_audit_ledger_correlation` — used by Q4 (audit chain debug).
- `idx_sonar_bank_compliance_flags_citizen_status_raised` — used by citizen dashboard.
- `idx_sonar_bank_compliance_flags_severity_status` — used by Security dashboard.

Each index validated via `EXPLAIN FORMAT=JSON` showing `key` field matches expected.

---

## 7. Failure scenarios + mitigations

| Scenario | Mitigation tested | Status |
|---|---|---|
| Reconciliation deadlock 200 concurrent | Backend Lead mutex CP2 correlation-id + retry exponential backoff | ⏳ Pending v0.4 |
| Audit ledger trigger SIGNAL fires legitimate operation | Backend lib `BankAuditLedger.Append` only INSERT, no UPDATE/DELETE attempts | ⏳ Pending v0.4 |
| Partition p_future fills before cron rolling forward | DevOps Lead alert + manual REORGANIZE PARTITION emergency procedure | ⏳ Pending v0.4 documented |
| Connection pool saturation 100% | Sizing 30 + monitoring + alert | ⏳ Pending v0.4 |

---

## 8. Sign-off matrix LOCKED v1.0

- ☐ founder ✅ green-light targets §3 met.
- ☐ DB Lead ✅ benchmarks ejecutados + reproducibles.
- ☐ Backend Lead ✅ harness Lua functional + integrated CI.
- ☐ DevOps Lead ✅ hardware reference documented + monitoring stack ready.
- ☐ Security Lead ✅ audit ledger immutability tested (triggers SIGNAL fires UPDATE/DELETE).

---

## 9. Versioning

| Version | Fecha | Cambios |
|---|---|---|
| **v1.0 DRAFT v0.1** | 2026-05-06 | Initial release skeleton — methodology + targets + sign-off matrix. Ejecución pending BANK-DB.4. |

— **BENCHMARK DRAFT v0.1** — DB Lead authoring 2026-05-06 (BANK-DB.1).
