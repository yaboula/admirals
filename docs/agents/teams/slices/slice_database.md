# Slice Database — Cherry-pick Blueprint v1.2

> **Cherry-pick blueprint para Database & Data Integrity Lead.** Apunta a las secciones canonical del blueprint v1.2 relevantes + decisiones founder filtered + counter-proposals filtered + open questions del dominio + entregables esperados.
>
> **Audiencia:** Database & Data Integrity Lead.
>
> **Fecha:** 2026-05-06.
> **Status:** 🟢 Locked.
> **Source canonical:** `@docs/design/proposals/03_bank_app_blueprint_v1.md` v1.2.

---

## 1. Resumen ejecutivo dominio Database

**Misión:** schema source-of-truth de toda la infraestructura financiera Bank-domain. Audit ledger inmutable + 15+ tablas nuevas + partitioning + indexes optimizados + perf chaos 200 concurrent <500ms p99 + migrations files numbered + reversibility documented.

**Por qué el orden 1º:** sin schema LOCKED no hay callbacks, no hay FSMs, no hay UI, no hay chaos test. **Eres la fundación.** Si el schema falla, todo lo demás falla.

**Tu output principal Phase A:**
- `docs/technical/03_db_schema.md` v1.1 → v1.2 LOCKED.
- `migrations/<NNN>_*.sql` numerados (post-009 existing).
- `progress/BENCHMARK_BANK_DB_v1.md` v1.0 NEW.

---

## 2. Cherry-pick secciones blueprint relevantes

### 2.1 Lectura prioridad ALTA

- **§3 Feature Taxonomy completo** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:200-700` (aprox). Tier 1-4 features. Cada feature implica tablas o columnas.
- **§5.2 DB Schema Bank-domain** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1000-1300` (aprox). Tablas propuestas + columns + indexes preliminares.
- **§5.3 FSMs (joint con Backend)** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1300-1500` (aprox). Estados + transitions impactan persistence columns + ENUM types.
- **§7.2 Scope changes Q8/Q1/Q16** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2209-2258`. Cambios derivados decisiones founder que afectan schema.

### 2.2 Lectura prioridad MEDIA

- **§6 Roadmap Phase A** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1700-1900` (aprox). Sub-tags + done criteria timing.
- **§11.2 Edge Case #2 Reconciliation perf** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2546-2597`. Performance target chaos + mitigations DB-relevantes.
- **§11.3 Cfx.re native primitives** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2666-2741`. State Bags global no afecta DB direct, pero cross-resource reads pueden cambiar query patterns.

### 2.3 Lectura prioridad BAJA (referencia opcional)

- **§4 UI/UX design** — solo para entender qué queries el Frontend va a invocar (indirect via Backend API).
- **§8 Identity preserved + ADR-017** — solo para entender naming conventions tablas (`sonar_*` prefix).
- **§9 Appendix** — referencias.

---

## 3. Decisiones founder Q1-Q16 filtered (DB-relevantes)

### 3.1 Q1 — Govt mode configurable (per server)

**Impact DB:** add 3 tablas elections.

- `sonar_govt_elections` — electoral process (FSM `election_lifecycle` 6 states).
- `sonar_govt_election_candidates` — candidates per election.
- `sonar_govt_votes` — votes (anonymous OR transparent — cuestionar).

**Cuestionar:** privacy votes — anonymous (hash citizen_id) vs transparent (raw citizen_id). Decisión policy founder.

### 3.2 Q8 — Multidivisa OFF

**Impact DB:** **eliminar** del scope:

- ❌ Tabla `sonar_bank_currencies` (NO crear).
- ❌ Columnas `currency_code` + `fx_rate` en `sonar_bank_movements` (NO añadir).
- ❌ JOIN currencies en queries.

Single currency global config server. `Config.Currency.Symbol` (default `€`).

### 3.3 Q10 — 5 patrones autoraise canonical

**Impact DB:** ENUM type para `sonar_bank_compliance_flags.flag_type`:

```sql
ENUM('structuring', 'large_transfer', 'late_tax', 'velocity', 'new_account_large_deposit')
```

**NO** incluir `unusual_destination_foreign_prefix` (Q10 elimination — no aplica single-currency).

### 3.4 Q12 — Tier 4 100% in-scope

**Impact DB:** crear tablas T4:

- `sonar_bank_loans` — préstamos FSM-driven.
- `sonar_bank_credit_scores` — score per citizen.
- `sonar_bank_crypto_wallets` — wallets crypto (atomic decimals per asset, BTC = 8 decimals).
- `sonar_bank_stocks_holdings` — relación N:M citizen ↔ company shares.
- `sonar_bank_recurring_payments` — subscriptions.
- `sonar_bank_atm_minigame_attempts` — log minigame ATM.
- `sonar_bank_physical_cards` — physical card tokens.
- `sonar_bank_loyalty_points` — bank loyalty program.
- `sonar_bank_round_ups` — round-up savings.

**Cuestionar:** stocks model — relación N:M con `avg_buy_price` materialized vs event-sourced from `sonar_bank_stocks_transactions`.

### 3.5 Q14 — Defaults agresivos config tax

**Impact DB:** schema soporta editable per server admin via tablas configurables:

- `sonar_bank_tax_brackets` — IRPF progressive editable.
- `sonar_bank_subsidies` — government subsidies issued.
- `sonar_bank_tax_history` — historical tax payments.

Defaults: IVA 8% + IRPF progresivo (0/15/25/35%) + Riqueza 1.2% above €500k.

### 3.6 Q16 — Hybrid 3-layer + 8 CP + cut ESX legacy

**Impact DB:**

- **CP3 reconciliation pipeline async** — joint con Backend Lead. Performance target 200 concurrent <500ms p99. Schema impact: column `sonar_bank_accounts.last_reconciled_at` + index `(citizen_id, last_reconciled_at)` para trust window 5min query.
- **CP6 reconciliation scope main only** — query queries excluyen `account_type IN ('savings', 'escrow', 'business_treasury', 'crypto_wallet')`.
- **CP8 sonar_bank_status FSM** — tabla `sonar_bank_status` (per-server o per-citizen — cuestionar). Estados: `native_full` / `lite_mode_active` / `compromised_load_order` / `framework_missing`.

---

## 4. Counter-proposals CP-relevantes filtered

| CP | DB Lead role |
|---|---|
| **CP1** State Bags global | NOT DB direct (Backend implementa publishers). Pero schema soporta queries que populan StateBags. |
| **CP2** Correlation-ID Mutex | NOT DB direct. Pero idempotency keys posiblemente DB persistent (consultative). |
| **CP3** Reconciliation pipeline async | **JOINT con Backend.** Schema design + index optimization + connection pool + batch SQL multi-row. |
| **CP4** Defensive boot + watchdog | NOT DB direct. |
| **CP5** Threshold auto-apply €1000 | Audit ledger entry per delta auto-applied. |
| **CP6** Reconciliation scope main only | Query patterns. |
| **CP7** README + convars | NOT DB direct. |
| **CP8** sonar_bank_status FSM | Tabla persistence FSM state. |

---

## 5. Anti-patterns DB-específicos prohibidos

(Per prompt §9. Re-enumerados aquí brief.)

- ❌ Schema sin migration paired.
- ❌ FK sin `ON DELETE/UPDATE` explicit.
- ❌ Money columns sin atomic strategy decidida.
- ❌ Audit ledger UPDATE/DELETE permitido.
- ❌ Index sin rationale documented.
- ❌ `SELECT *` en queries doc.
- ❌ Cambios schema post-LOCKED sin amendment.
- ❌ Hardcoded numbers económicos en CHECK constraints.

---

## 6. Research recomendado primitivas modernas

(Per prompt §6.1. Re-enumerados aquí brief.)

- MySQL 8 — JSON columns + GENERATED columns + window functions + INVISIBLE INDEXES + CHECK constraints + EXPLAIN ANALYZE.
- MariaDB 10.6 — system-versioned tables (alternativa audit ledger manual).
- oxmysql — `MySQL.prepare` vs `MySQL.query` perf + async patterns + transaction support.
- Partitioning — RANGE by date vs HASH by citizen_id vs híbrido. Pruning effectiveness.

---

## 7. Open questions del dominio (responder con autonomía o escalar)

| OQ | Pregunta | Recommendation Cascade PM |
|---|---|---|
| **OQ-DB-01** | DECIMAL vs BIGINT money columns | Recommend BIGINT cents (perf) — verify con founder. |
| **OQ-DB-02** | Audit ledger partitioning strategy | Recommend RANGE month + archive >12 months a tabla cold-storage. |
| **OQ-DB-03** | Triggers immutability vs app-level | Recommend defense-in-depth (ambos). |
| **OQ-DB-04** | Materialized views Government Console | Recommend on-demand cache LRU (no materialized native MySQL — usa ROLAP queries optimizados). |
| **OQ-DB-05** | sonar_bank_status per-server vs per-citizen | Recommend per-server (single row global) — coherencia operacional. |
| **OQ-DB-06** | Crypto wallets atomic decimals | Recommend column `decimals INT UNSIGNED` per asset + amount stored as raw integer atomic. |
| **OQ-DB-07** | JSON columns metadata vs normalization | Recommend JSON para `audit_ledger.context_data` + `compliance_flags.evidence` (flexibility) — relacional para fields queried. |
| **OQ-DB-08** | Stocks model | Recommend event-sourced `sonar_bank_stocks_transactions` + materialized current `sonar_bank_stocks_holdings` (perf reads). |
| **OQ-DB-09** | Idempotency keys storage | Recommend tabla DB `sonar_bank_idempotency_keys` con TTL 7 days + cron cleanup (Backend Lead implementa cron). |
| **OQ-DB-10** | Connection pool size oxmysql | Recommend ≥30 para 200 concurrent target. Tested + benchmarked. |
| **OQ-DB-11** | Privacy votes elections | Recommend hashed citizen_id + salt config server (audit-friendly + privacy). |

**Cuestiona** mis recommendations + propose alternativas si encuentras mejor diseño.

---

## 8. Entregables esperados v1.0 LOCKED

### 8.1 SSoT principal

- `docs/technical/03_db_schema.md` v1.1 → v1.2:
  - Header con changelog v1.1 → v1.2 + lista all tablas (existing + new).
  - Tabla resumen scope per domain (Bank core / Tax + Govt / T4 features / Empresas + Escrow).
  - Per tabla: columns + types + nullable + default + comment + indexes + FKs + constraints + partitioning + triggers + sample queries + EXPLAIN.
  - `### 🟡 Deviation from blueprint` blocks documenting cuestionamientos.
  - Cross-references blueprint citadas con `@path:LINE`.

### 8.2 Migrations files

- `migrations/010_<description>.sql` ... `migrations/0NN_<description>.sql` numerados secuenciales.
- Reversibility documented.
- Idempotency `IF NOT EXISTS` patterns.
- Order respecting FK dependencies.

### 8.3 Performance benchmarks

- `progress/BENCHMARK_BANK_DB_v1.md` v1.0 NEW:
  - Methodology test setup + hardware reference.
  - 200 concurrent reconciliation test result <500ms p99 ✅ (Q16.5 chaos test mandatory).
  - Audit ledger insert throughput >1000 inserts/s ✅.
  - Government Console "Todas" scope query <200ms (5 años data).
  - Connection pool size recommendation.

### 8.4 Sign-off

- founder ✅
- DB Lead ✅ (tú)
- Backend Lead ✅ (consumer principal)
- Security Lead ✅ (audit ledger consumer)

---

## 9. Cross-team contracts

### 9.1 QUÉ EXIGES

- Founder: decisiones Q1-Q16 ya in brief. Sub-questions tuyas → escala.

### 9.2 QUÉ ENTREGAS

- Backend Lead: schema LOCKED + migrations + perf benchmarks + index hints (post-H1).
- Security Lead: schema audit ledger + compliance_flags + ACE-relevant tables (post-H1).
- DevOps Lead: migrations files numbered + connection pool config + rollback procedure (post-H1).

---

## 10. Citas blueprint canonical

Todas estas citas usar formato `@docs/design/proposals/03_bank_app_blueprint_v1.md:LINE` (ranges aproximados — verifica al leer):

- Visión Stripe-class: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1-100`.
- Feature taxonomy: `@docs/design/proposals/03_bank_app_blueprint_v1.md:200-700`.
- DB schema: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1000-1300`.
- FSMs joint: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1300-1500`.
- Roadmap: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1700-1900`.
- Q1-Q15 decisions: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2186-2240`.
- Q16 audit + 8 CP: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2496-2942`.
- §11.9 Founder Final Decision: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2876-2942`.

---

## 11. Versioning

| Version | Fecha | Cambios |
|---|---|---|
| **v1.0** | 2026-05-06 | Initial release. Cherry-pick + Q1-Q16 + CP1-CP8 + 11 OQs filtered. |

— **Slice DB LOCKED** post founder green-light 2026-05-06.
