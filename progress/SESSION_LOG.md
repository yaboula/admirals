# SESSION_LOG — SONAR Bank App

> Log secuencial append-only de todas las sesiones AI sobre el proyecto SONAR Bank.
>
> **Workspace rules:** `.windsurf/rules/bank.md`.
> **Workflows:** `/start-lead-session`, `/close-lead-session`, `/handoff-ceremony`, `/lock-contract`.
> **Archive pre-Bank:** `progress/SESSION_LOG_OLEADA_PRE_BANK.md` (sesiones Admirals históricas BANK-DESIGN.0-3 + Sprints anteriores).

---

### BANK.0 — Workspace cleanup + transition Admirals → Bank-only project

- **Fecha:** 2026-05-06
- **Duración:** ~30 min (continuación post BANK-DESIGN.3 packaging)
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.6)
- **Sprint / Phase:** -- (cleanup transition)
- **Perfil:** 🧹 CLEANUP + 🎯 PROJECT REFOCUS
- **Goal:** Limpiar workspace de referencias Admirals legacy (workflows + rules + memoria + log archivado). Dejar entorno fresh Bank-only para arrancar pipeline Tech Leads (DB → BE → SEC → FE → DO).
- **Status:** ✅ Done

#### Acciones ejecutadas

- ✅ `progress/SESSION_LOG.md` (Admirals histórico) → archivado a `progress/SESSION_LOG_OLEADA_PRE_BANK.md`.
- ✅ `progress/SESSION_LOG.md` fresh creado (este file) — solo Bank app scope.
- ✅ `.windsurf/rules/admirals.md` borrado.
- ✅ `.windsurf/rules/bank.md` creado — workspace rules canonical Bank-only (CDD + Handoff system + idiomas estricto + 4 mandatos founder + hard constraints + trust hierarchy + red flags).
- ✅ `.windsurf/workflows/start-session.md` borrado (Admirals legacy).
- ✅ `.windsurf/workflows/close-session.md` borrado (Admirals legacy).
- ✅ `.windsurf/workflows/sprint-retro.md` borrado (Admirals legacy).
- ✅ `.windsurf/workflows/start-lead-session.md` creado — onboarding canonical Tech Lead 10-step.
- ✅ `.windsurf/workflows/close-lead-session.md` creado — sign-off + SESSION_LOG entry + commit.
- ✅ `.windsurf/workflows/handoff-ceremony.md` creado — H1-H5 ceremony entre Tech Leads.
- ✅ `.windsurf/workflows/lock-contract.md` creado — promover DRAFT v0.x → LOCKED v1.0.

#### Pendiente founder (acción manual)

- 🟡 **Memoria global `MEMORY[admirals.md]` requiere update manual founder.** Pasos:
  1. Settings → Memories → busca `admirals.md`.
  2. Borra entry (o renombra título a `bank.md` y reemplaza contenido).
  3. Copy contenido nuevo desde `.windsurf/rules/bank.md` (este es el canonical).
  4. Save.
- Sin este paso, MEMORY auto-applied seguirá siendo Admirals legacy.

#### Outcomes

- Workspace fully refocused Bank app project.
- Workflows nuevos alineados pipeline CDD + Handoff (no más sprints Admirals).
- Rules nuevos alineados 4 mandatos founder + 18 contratos canonical + idiomas estricto.
- SESSION_LOG fresh start con sólo entradas Bank.

#### Files in scope respetados

- ✅ NO toco: `docs/**` / `resources/**` / `migrations/**` / blueprint v1.2 / paquete `docs/agents/teams/` 14 archivos.
- ✅ Modificados: `.windsurf/rules/*` + `.windsurf/workflows/*` + `progress/SESSION_LOG.md` archive + new.

#### Pendientes próximos

1. **Founder update MEMORY[admirals.md] manual** (instrucciones arriba).
2. **DB Lead activation** — founder spawn agente con `docs/agents/teams/prompts/01_database_integrity_lead.md` + aplicar `/start-lead-session` workflow.
3. **DB Lead delivers DRAFT v0.1** schema v1.2 + cuestionamientos preliminares.
4. **Cadena Handoffs H1 → H5** secuencial.
5. **Phase A coding** post H5 paralelo Leads.

#### Próxima sesión sugerida

- Session ID: **BANK.1** (DB Lead activation onboarding) o **BANK-DB.0** (si founder prefiere namespace per-Lead).
- Goal: DB Lead onboarding + cuestionamientos preliminares + research MySQL 8 + DRAFT v0.1 schema v1.2.
- Modelo sugerido: GPT-5 (DBA dense reasoning) o Sonnet 4.6 (continuidad consistencia decisiones blueprint).
- Files in scope: `docs/technical/03_db_schema.md` (v1.1 → v1.2 promotion) + `migrations/010_*.sql`+ + `progress/BENCHMARK_BANK_DB_v1.md` NEW.
- Estimado fase DB Lead: 4-6 días (3-5 sesiones).

---

### BANK-A.0 — PM packaging commit + push origin/main + branch isolation

- **Fecha:** 2026-05-06 (~05:25 UTC+02)
- **Duración:** ~5 min
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.6 — DB Lead activated)
- **Sprint / Phase:** Phase A pre-coding — repo hygiene
- **Perfil:** 🧹 GIT FLOW
- **Goal:** Commit BANK.0 cleanup + PM packaging organizativos a origin/main. Crear branch aislada `feature/bank-db-phase-a` para trabajo DB Lead.
- **Status:** ✅ Done

#### Acciones ejecutadas

- ✅ `git add` selectivo: `.windsurf/rules/` + `.windsurf/workflows/` + `docs/agents/teams/` + `docs/design/proposals/03_bank_app_blueprint_v1.md` + `progress/SESSION_LOG.md` + `progress/SESSION_LOG_OLEADA_PRE_BANK.md`.
- ❌ Excluidos commit: `resources/sonar_tablet/web-src/*` (Frontend scope), `cache/`, `resources/sonar_bank/simple-ref-bank-ui/` (referencia visual).
- ✅ Commit `a641fd5`: `BANK-A.0 PM packaging — manifest + brief + slices + prompts + workflows + rules + blueprint v1.2 LOCKED` (26 files, 11833+/2976-).
- ✅ Push origin main: `8b49069..a641fd5 main -> main`.
- ✅ Branch nueva: `feature/bank-db-phase-a` checkout.

#### Outcomes

- Repo origin/main protegido con artefactos PM organizativos.
- Workspace DB Lead aislado en branch dedicada — cero risk contaminación trabajo Frontend Tablet WIP.

---

### BANK-DB.0 — DB Lead onboarding + handshake + cuestionamientos preliminares

- **Fecha:** 2026-05-06 (~05:00 UTC+02)
- **Duración:** ~30 min
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.6 — DB Lead role activated)
- **Sprint / Phase:** Phase A — Database foundation
- **Perfil:** 🎯 ONBOARDING + 🔍 CRITICAL ANALYSIS
- **Goal:** Onboarding 10-step canonical (per `/start-lead-session`) + handshake confirmación + cuestionamientos preliminares fundados al blueprint v1.2 + slice + prompt antes de DRAFT v0.1.
- **Status:** ✅ Done — green-light founder Q-DB-A → Q-DB-J recibido.

#### Acciones ejecutadas

- ✅ Lectura mandatory 11 documentos: `bank.md` rules + `00_HANDOFF_MANIFEST.md` + `01_SHARED_BRIEF.md` + `02_INHERITED_BLUEPRINT_SLICES.md` + `03_CROSS_TEAM_CONTRACTS.md` + `slice_database.md` + `01_database_integrity_lead.md` prompt + `SESSION_LOG.md` + `00_BOOTSTRAP.md` + `03_founder_playbook.md` + `03_db_schema.md` v1.2 sample + migrations 003 + 006.
- ✅ Estado repo verificado: working branch `main` ahead 1 commit, `sonar_tablet/web-src` WIP ajeno DB scope.
- ✅ **10 cuestionamientos Q-DB-A → Q-DB-J fundados** entregados al founder con análisis técnico + recommendations + impact downstream.

#### Cuestionamientos resueltos (founder green-light 2026-05-06)

| Q | Decisión | Implication schema |
|---|---|---|
| Q-DB-A | MariaDB 12.x primary lock | DDL adaptado primitives MariaDB |
| Q-DB-B | DECIMAL(14,2) fiat + BIGINT atomic crypto | Money columns split per asset class |
| Q-DB-C | Path canonical `resources/sonar_core/migrations/010_*.sql` | Locked location |
| Q-DB-D | Refactor 2-col `owner_type` + `account_class` | Migration 014 v0.2 ALTER |
| Q-DB-E | Opcion 2 — opaque `company_id` sin FK | Issue #001 backend handoff |
| Q-DB-F | 3-tier defense-in-depth audit ledger | Triggers + REVOKE + app-layer |
| Q-DB-G | Particiones extend Sep 2026 → Dec 2027 | Migration 013 REORGANIZE |
| Q-DB-H | Dual-layer privacy votes (hash + audit raw) | 2 tablas govt_votes + govt_votes_audit |
| Q-DB-I | Stocks híbrido event-sourced + materialized | 2 tablas stocks_transactions + stocks_holdings |
| Q-DB-J | Single row global per-server bank_status FSM | PK fijo id=1 + trigger enforce |

#### Outcomes

- Sólido entendimiento estado real schema producción (MariaDB 12.x, workarounds CHECK, partitions May-Aug 2026, deferred FKs).
- Drift SSoT v1.1 vs realidad migrations identificado + plan corrección v1.3.
- Green-light explícito iniciar research time-box + DRAFT v0.1.

---

### BANK-DB.1 — Research MariaDB 12.x + DRAFT v0.1 schema v1.3 + migrations 010-013 + benchmark skeleton

- **Fecha:** 2026-05-06 (~05:30 UTC+02)
- **Duración:** ~90 min
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.6 — DB Lead)
- **Sprint / Phase:** Phase A — Database foundation
- **Perfil:** 🛠️ DRAFT AUTHORING + ⚙️ DDL CRAFTING
- **Goal:** Research MariaDB 12.x primitives + DRAFT v0.1 entrega núcleo crítico que desbloquea handoffs H1 (Backend) + H2 (Security): audit ledger inmutable + compliance flags + status FSM + partitions extension + benchmark skeleton.
- **Status:** ✅ Done DRAFT v0.1 — pending review founder.

#### Acciones ejecutadas

- ✅ Research synthesis MariaDB 12.x primitives — JSON OK, triggers SIGNAL OK, system-versioned descartado audit ledger, generated columns OK STORED indexable, partitioning OK, CHECK simples OK pero multi-col app-layer, `ON UPDATE` INT UNSIGNED illegal, `EXPLAIN ANALYZE` sintaxis distinta MySQL.
- ✅ `docs/agents/teams/issues/issue_001_sonar_companies_pending.md` creado — workaround Q-DB-E + acción Backend Lead post-H1.
- ✅ `docs/technical/03_db_schema.md` v1.2 → **v1.3 DRAFT v0.1**:
  - Header changelog v1.2 → v1.3 + tablas NEW + tablas existing extends + drift corrections SSoT v1.1 vs realidad migrations.
  - **§22 NEW** — Audit ledger inmutable + compliance flags (DDL completo + triggers SIGNAL + queries hot path + notas defense-in-depth 3-tier).
  - **§23 NEW** — Status FSM single-row (DDL + trigger BEFORE INSERT + seed inicial + FSM transitions canonical CP8 + queries hot path).
  - **§24-§28** — Roadmap pending v0.2 + v0.3 (tax + government + Tier 4 + empresas + idempotency).
  - **§29 NEW** — Deviations from blueprint Q-DB-A → Q-DB-J consolidated (10 bloques rationale + impact downstream).
  - Changelog entry v1.3 DRAFT v0.1 + FIN bumped.
- ✅ `resources/sonar_core/migrations/010_bank_audit_ledger.sql` (10885 bytes) — DDL + triggers SIGNAL `BEFORE UPDATE/DELETE` + partitions May-Dec 2026 + decision log D1-D10.
- ✅ `resources/sonar_core/migrations/011_bank_compliance_flags.sql` (8118 bytes) — DDL + 5 patterns autoraise canonical Q10 + indexes + constraints + decision log D1-D9.
- ✅ `resources/sonar_core/migrations/012_bank_status_fsm.sql` — DDL single-row + trigger BEFORE INSERT enforce + seed inicial framework_missing + decision log D1-D8.
- ✅ `resources/sonar_core/migrations/013_bank_movements_partitions_extend.sql` — REORGANIZE PARTITION procedure idempotente (pre-flight INFORMATION_SCHEMA check) extend Sep 2026 → Dec 2027 ambas tablas particionadas (movements + audit_ledger) + decision log D1-D5.
- ✅ `progress/BENCHMARK_BANK_DB_v1.md` v0.1 skeleton — methodology + targets canonical (Q16.5 reconciliation 200 concurrent <500ms + audit insert >1000/s + Government Console <200ms + others) + sign-off matrix.

#### Cuestionamientos preservados como Deviation blocks (§29)

10 bloques `### 🟡 Deviation Q-DB-*` documentando rationale + impact downstream para handoffs H1-H4.

#### Files in scope respetados

- ✅ NO toco: §1-§20 SSoT v1.2 LOCKED foundational + migrations 001-008 + 009 archived + `docs/economy/**` + `resources/sonar_tablet/**` + `resources/sonar_bank/**` + blueprint v1.2.
- ✅ Modificados/creados:
  - `docs/technical/03_db_schema.md` (extends v1.3 DRAFT v0.1 — apendeo §22-§29 post §20).
  - `docs/agents/teams/issues/issue_001_sonar_companies_pending.md` NEW.
  - `resources/sonar_core/migrations/010_*.sql` + `011_*.sql` + `012_*.sql` + `013_*.sql` NEW.
  - `progress/BENCHMARK_BANK_DB_v1.md` NEW.

#### Outcomes

- DRAFT v0.1 entrega **núcleo crítico** que desbloquea consumers H1 (Backend Lead — money flow + correlation-id + reconciliation) + H2 (Security Lead — audit ledger immutability + compliance flags). Resto scope (tax + govt + T4 + empresas + idempotency + benchmarks ejecutados) iterado v0.2-v0.4.
- 4 migrations files DRAFT v0.1 listas para apply en dev DB tras founder review + sign-off triple.
- Coverage Q-DB-A → Q-DB-J 100% — todos 10 cuestionamientos founder green-light implementados o documentados deviation.

#### Pendientes próximos

1. **Founder review DRAFT v0.1** + feedback antes de iterar v0.2.
2. **BANK-DB.2** (próxima sesión): §24 Tax + Government tablas (migrations 014-017 + dual-layer privacy Q-DB-H) + ALTER bank_accounts split owner_type + ALTER bank_movements category extend.
3. **BANK-DB.3:** §25-§27 Tier 4 features + Empresas extends + Idempotency keys (migrations 018-028).
4. **BANK-DB.4:** Benchmarks ejecutados + LOCKED v1.0 sign-off triple → handoff H1 ceremony Backend Lead.

#### Próxima sesión sugerida

- Session ID: **BANK-DB.2** — Tax + Government schema.
- Goal: §24 4 tablas tax + 4 tablas govt + ALTER 2-col split bank_accounts + ALTER ENUM extend bank_movements category. Migrations 014-017.
- Modelo sugerido: Sonnet 4.6 (continuidad DB Lead context).
- Files in scope: `docs/technical/03_db_schema.md` (§24 NEW) + `migrations/014_*.sql` → `017_*.sql`.
- Estimado: ~2-3h.

---

### BANK-DB.2 — DRAFT v0.2 Tax + Government schema + ALTER TABLES críticos

- **Fecha:** 2026-05-06 (~06:10 UTC+02)
- **Duración:** ~50 min
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.6 — DB Lead)
- **Sprint / Phase:** Phase A — Database foundation
- **Perfil:** ⚙️ DDL CRAFTING + 🛡️ DUAL-LAYER PRIVACY DESIGN
- **Goal:** Founder green-light DRAFT v0.1 + autorización BANK-DB.2. Implementar §24 Tax + Government (7 tablas) + ALTER TABLES críticos (bank_accounts split + bank_movements category extend). Push branch a origin (founder mandate).
- **Status:** ✅ Done DRAFT v0.2 — pending review founder.

#### Acciones ejecutadas

- ✅ `git push -u origin feature/bank-db-phase-a` — branch protegida en remoto post BANK-DB.1 (founder mandate "push al final de cada sesión").
- ✅ `resources/sonar_core/migrations/014_bank_accounts_owner_type_split.sql` — Q-DB-D ALTER bank_accounts split en 2 columns (`owner_type` + `account_class`) + ADD `last_reconciled_at` (CP3) + backfill data existing + override SYS treasury seed (AD-SYS0-0000-0001 → government + govt_treasury) + DROP column `type` legacy. Idempotency check via INFORMATION_SCHEMA.COLUMNS. Decision log D1-D8.
- ✅ `resources/sonar_core/migrations/015_bank_movements_category_extend.sql` — ALTER MODIFY ENUM aditiva 11 nuevos valores AL FINAL preservando 13 originales (NO rebuild físico). Idempotency check `tax_subsidy IN ENUM`. Decision log D1-D5.
- ✅ `resources/sonar_core/migrations/016_tax_brackets_history_subsidies.sql` — 3 tablas Tax: brackets editable + history append-only (triggers SIGNAL Q-DB-F tier 1) + subsidies PARTITIONED RANGE month (UBI volume). FK ON DELETE RESTRICT/SET NULL canonical. CHECK simples (Q-DB-A). Decision log D1-D8.
- ✅ `resources/sonar_core/migrations/017_govt_elections_candidates_votes.sql` — 4 tablas Government: elections FSM 4-state + candidates (FK CASCADE election_id) + votes hashed (UNIQUE voter_hash + election_id) + votes_audit raw ACE-gated. Triggers SIGNAL append-only en votes + votes_audit. Q-DB-H dual-layer privacy implementada. Decision log D1-D9 (server_salt management + dual-atomic INSERT + ACE check enforcement).
- ✅ `docs/technical/03_db_schema.md` v1.3 DRAFT v0.1 → **v1.4 DRAFT v0.2**:
  - Header changelog v1.3 → v1.4 + status update tablas tax/govt → ✅ DRAFT v0.2 + tablas existing → ✅ DRAFT v0.2.
  - **§24 NEW** — Tax + Government DDL completo (7 sub-secciones 24.1-24.8) + queries hot path Q1-Q6.
  - §25-§28 roadmap pending v0.3 actualizado.
  - Changelog entry v1.4 DRAFT v0.2 + FIN bumped.

#### Q-DB-H dual-layer privacy implementation

| Layer | Tabla | Acceso | Hash citizen_id |
|---|---|---|---|
| Public | `sonar_govt_votes` | Cualquier citizen UI Government Console | SHA-256 con `server_salt` secret |
| Admin-only | `sonar_govt_votes_audit` | ACE `sonar.bank.govt.audit.full` | RAW citizen_id |

**Properties:**
- Misma persona votando 2 veces → mismo hash → UNIQUE constraint rechaza.
- Dump DB sin `server_salt` → hash NO reversible (bcrypt-like).
- Dual-atomic INSERT Backend Lead `Vote.Cast()` lib en single transaction.
- Audit investigations admin (impugnación + fraude detection IP).

#### Files in scope respetados

- ✅ NO toco: §1-§21 SSoT v1.2 LOCKED foundational + §22-§23 DRAFT v0.1 + §29 deviations + migrations 001-013 (preservadas) + `resources/sonar_tablet/web-src/**` + `resources/sonar_bank/**` + blueprint v1.2.
- ✅ Modificados/creados:
  - `docs/technical/03_db_schema.md` (v1.3 → v1.4 DRAFT v0.2 — apendeo §24 + bump status tablas v0.2 + changelog).
  - `resources/sonar_core/migrations/014_*.sql` + `015_*.sql` + `016_*.sql` + `017_*.sql` NEW.

#### Outcomes

- **DRAFT v0.2 entrega completa Tax + Government** — 7 tablas NEW + 2 ALTER TABLE críticos + Q-DB-H dual-layer privacy implementada + queries hot path documented.
- **Branch protegida en origin** — push final BANK-DB.1 + commit BANK-DB.2 listo para push tras este SESSION_LOG.
- **Coverage Q-DB-D + Q-DB-H + Q-DB-A 100%** — Tax + Government completo per founder LOCKED decisions.

#### Pendientes próximos

1. **Founder review DRAFT v0.2** + feedback antes de iterar v0.3.
2. **BANK-DB.3** (próxima sesión): §25 Tier 4 features (loans + credit_scores + crypto + stocks híbrido + recurring + ATM + cards + loyalty + round_ups) + §26 Empresas extends (business_treasuries + escrow_releases) + §27 Idempotency keys.
3. **BANK-DB.4:** Benchmarks ejecutados + LOCKED v1.0 sign-off triple → handoff H1 ceremony Backend Lead.

#### Próxima sesión sugerida

- Session ID: **BANK-DB.3** — Tier 4 features + Empresas extends + Idempotency keys.
- Goal: §25 9 tablas Tier 4 + §26 2 tablas empresas + §27 1 tabla idempotency. Migrations 018-028 (~11 archivos).
- Modelo sugerido: Sonnet 4.6 (continuidad DB Lead context).
- Files in scope: `docs/technical/03_db_schema.md` (§25 + §26 + §27 NEW) + `migrations/018_*.sql` → `028_*.sql`.
- Estimado: ~3-4h.

---

### BANK-DB.3 — DRAFT v0.3 Tier 4 + Empresas + Idempotency keys (Phase A schema DDL complete)

- **Fecha:** 2026-05-06 (~06:35 UTC+02)
- **Duración:** ~80 min
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.6 — DB Lead)
- **Sprint / Phase:** Phase A — Database foundation (DDL final iteration)
- **Perfil:** ⚙️ DDL CRAFTING + 🏗️ HYBRID MODELS DESIGN
- **Goal:** Founder green-light DRAFT v0.2 + autorización BANK-DB.3. Implementar §25 Tier 4 (15 tablas) + §26 Empresas (4 tablas + 1 ALTER) + §27 Idempotency keys (1 tabla). Schema DDL Phase A completo — only benchmarks ejecutados pending v0.4 LOCKED.
- **Status:** ✅ Done DRAFT v0.3 — pending review founder.

#### Acciones ejecutadas

- ✅ `resources/sonar_core/migrations/018_bank_loans_credit_scores.sql` — Loans FSM 6-state (`requested`→`approved`→`disbursed`→`active`→`paid_off`/`defaulted`) + credit_scores rolling history (UNIQUE citizen_id+computed_at, score 0-1000).
- ✅ `resources/sonar_core/migrations/019_bank_crypto_wallets.sql` — Q-DB-B BIGINT atomic policy: 3 tablas (assets reference data + seed BTC/ETH/USDT, wallets UNIQUE citizen+asset, transactions append-only). decimals stored per asset (BTC=8, ETH=18, USDT=6). Fiat snapshot exchange_rate_atomic centavos EUR.
- ✅ `resources/sonar_core/migrations/020_bank_stocks_transactions_holdings.sql` — Q-DB-I híbrido event-sourced + materialized: 3 tablas (assets + transactions append-only + holdings materialized snapshot). qty DECIMAL(20,8) fractional shares + price DECIMAL(14,4) + last_recomputed_at staleness invalidation.
- ✅ `resources/sonar_core/migrations/021_bank_recurring_payments.sql` — FSM 4-state recurring + cron index `(state, next_charge_at)` hot path Backend lib. interval_kind canonical + consecutive_failures auto-pause >3.
- ✅ `resources/sonar_core/migrations/022_bank_atm_minigame_attempts.sql` — append-only fraud detection log + IP indexing pattern detection Security Lead post-H2.
- ✅ `resources/sonar_core/migrations/023_bank_physical_cards.sql` — FSM 4-state cards + opaque card_token CHAR(64) + PIN hash SHA-256 + auto-freeze >3 attempts + daily_limit override.
- ✅ `resources/sonar_core/migrations/024_bank_loyalty_points.sql` — balances 1:1 PK citizen_id + transactions append-only. tier ENUM bronze/silver/gold/platinum.
- ✅ `resources/sonar_core/migrations/025_bank_round_ups.sql` — configs 1:1 PK + transactions append-only + multiplier 1x-10x boost + trigger_movement_id link.
- ✅ `resources/sonar_core/migrations/026_bank_business_treasuries.sql` — multi-signer 3 tablas chained: treasuries config + signers + approvals FSM 5-state m-of-n. operation_payload JSON + approvals_json array. Cron expire pending Backend lib post-H1.
- ✅ `resources/sonar_core/migrations/027_bank_escrow_releases.sql` — partial release log append-only + ALTER sonar_escrows ADD release_log_count denormalized counter (idempotent procedure).
- ✅ `resources/sonar_core/migrations/028_bank_idempotency_keys.sql` — tabla central cross-domain Reconciliación Activa: idempotency_key UNIQUE + 14 domains canonical + state ENUM 3-state + JSON request/response + correlation-id link CP2 + TTL 7 days mandate founder + cron cleanup hint DevOps.
- ✅ `docs/technical/03_db_schema.md` v1.4 DRAFT v0.2 → **v1.5 DRAFT v0.3**:
  - Header changelog v1.4 → v1.5 + status update tablas Tier 4 + Empresas + Idempotency → ✅ DRAFT v0.3.
  - **§25 NEW** — Tier 4 (8 sub-secciones 25.1-25.8) DDL summary + decisions + queries hot path.
  - **§26 NEW** — Empresas extends (26.1 multi-signer + 26.2 escrow releases) DDL summary + decisions + queries.
  - **§27 NEW** — Idempotency keys (27.1 estructura + decisions + queries hot path Backend lib lifecycle).
  - **§28** — Performance benchmarks placeholder Pending v0.4 → LOCKED v1.0.
  - Changelog entry v1.5 DRAFT v0.3 + FIN bumped.

#### Files in scope respetados

- ✅ NO toco: §1-§24 SSoT v1.2 LOCKED + DRAFTs v0.1+v0.2 + §29 deviations + migrations 001-017 + `resources/sonar_tablet/web-src/**` + `resources/sonar_bank/**` + blueprint v1.2.
- ✅ Modificados/creados:
  - `docs/technical/03_db_schema.md` (v1.4 → v1.5 DRAFT v0.3 — apendeo §25 + §26 + §27 + §28 placeholder + bump status tablas v0.3 + changelog).
  - `resources/sonar_core/migrations/018_*.sql` → `028_*.sql` NEW (11 archivos).

#### Coverage Q-DB-A → Q-DB-J final DRAFT v0.3

| Q | DRAFT v0.1 | v0.2 | v0.3 |
|---|---|---|---|
| Q-DB-A MariaDB 12.x | ✅ | ✅ | ✅ extendido todas tablas Tier 4 + Empresas + Idempotency |
| Q-DB-B DECIMAL fiat / BIGINT crypto | ✅ | ✅ | ✅ implementado migration 019 atomic units + decimals stored |
| Q-DB-C Path migrations | ✅ | ✅ | ✅ |
| Q-DB-D bank_accounts split | 📝 | ✅ | ✅ |
| Q-DB-E sonar_companies opaque | ✅ | ✅ | ✅ extendido empresas + recurring + loans |
| Q-DB-F audit ledger 3-tier | ✅ | ✅ | ✅ extendido todas append-only tables (crypto + stocks + atm + loyalty + round_ups + escrow_releases) |
| Q-DB-G partitions Dec 2027 | ✅ | ✅ | ✅ |
| Q-DB-H privacy dual-layer | 📝 | ✅ | ✅ |
| Q-DB-I stocks híbrido event-sourced + materialized | 📝 | 📝 | ✅ implementado migration 020 |
| Q-DB-J bank_status single-row | ✅ | ✅ | ✅ |

**100% coverage Q-DB-A → Q-DB-J.**

#### Schema scope final Phase A

| Categoría | Count | Status |
|---|---|---|
| Tablas NEW Phase A | 30+ | ✅ DDL DRAFT v0.3 |
| Tablas existing extends | 6 (bank_accounts split + last_reconciled_at + bank_movements ENUM + 2 partitions REORGANIZE + escrows release_log_count) | ✅ DRAFT v0.3 |
| Migrations files | 19 (010-028) | ✅ DRAFT v0.3 |
| Append-only tables (triggers SIGNAL Q-DB-F) | 12 | ✅ DRAFT v0.3 |
| Partitioned tables | 4 (bank_movements + audit_ledger + subsidies + future-proof keys) | ✅ DRAFT v0.3 |
| FSM tables | 7 (loans + recurring + cards + elections + business_approvals + escrows + bank_status) | ✅ DRAFT v0.3 |
| Materialized snapshots | 3 (stocks_holdings + loyalty_balances + bank_status) | ✅ DRAFT v0.3 |

#### Outcomes

- **Schema DDL Phase A 100% complete** — todas las tablas + ALTER TABLES + indexes + FKs + CHECK + triggers + partitions + seeds canonical.
- **Coverage Q-DB-A → Q-DB-J 100%** — todos 10 cuestionamientos founder LOCKED implementados.
- **Mandatos founder cumplidos** — MariaDB 12.x estricto + FK ON DELETE/UPDATE estándar + Q-DB-B atomic crypto + Q-DB-I híbrido stocks + Q-DB-E opaque + Idempotency keys central + TTL 7 days.
- **Ready para benchmarks** — BANK-DB.4 ejecuta `progress/BENCHMARK_BANK_DB_v1.md` targets canonical (200 concurrent reconciliation <500ms p99 + audit insert >1000/s + Government Console <200ms + others) → LOCKED v1.0 sign-off triple → handoff H1 ceremony Backend Lead.

#### Pendientes próximos

1. **Founder review DRAFT v0.3** + feedback antes de iterar v0.4.
2. **BANK-DB.4** (próxima sesión): execute benchmarks (chaos test 200 concurrent + partition pruning verification + connection pool sizing + index effectiveness) + actualizar `progress/BENCHMARK_BANK_DB_v1.md` con resultados → LOCKED v1.0 sign-off triple.
3. **Handoff H1 ceremony** — DB Lead → Backend Lead (workflow `/handoff-ceremony`) post-LOCKED.

#### Próxima sesión sugerida

- Session ID: **BANK-DB.4** — Performance benchmarks execution + LOCKED v1.0 sign-off.
- Goal: Execute targets canonical §3 BENCHMARK doc + actualizar resultados + LOCKED v1.0 promotion + sign-off triple founder + Backend consumer + Security consumer → handoff H1 ceremony Backend Lead.
- Modelo sugerido: Sonnet 4.6 (continuidad DB Lead context) o Opus 4 (rigor analysis benchmarks).
- Files in scope: `progress/BENCHMARK_BANK_DB_v1.md` (DRAFT v0.1 → v1.0) + `docs/technical/03_db_schema.md` (v1.5 DRAFT v0.3 → v1.0 LOCKED) + harness Lua opcional + handoff package H1.
- Estimado: ~4-6h (benchmarks execution + analysis + sign-off ceremony).

---

### BANK-DB.4 — Benchmark structural analysis + Schema LOCKED PROVISIONAL + Handoff H1 package ready

- **Fecha:** 2026-05-06 (~06:50 UTC+02)
- **Duración:** ~40 min
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.6 — DB Lead final session)
- **Sprint / Phase:** Phase A — Database foundation (final consolidation + handoff prep)
- **Perfil:** 🔬 STRUCTURAL ANALYSIS + 🔒 LOCKED PROVISIONAL + 🤝 HANDOFF PACKAGE
- **Goal:** Founder green-light DRAFT v0.3 + autorización BANK-DB.4. Execute benchmark análisis estructural (NO real execution — harness Lua scope post-H1) + promote schema v1.5 → v2.0 LOCKED PROVISIONAL + crear handoff package H1.
- **Status:** ✅ Done — pending founder review + sign-off triple para handoff completion.

#### Acciones ejecutadas

- ✅ **`progress/BENCHMARK_BANK_DB_v1.md` v0.1 → v0.5** — análisis estructural completo:
  - **§1** Engine + hardware reference (MariaDB 12.2.2 + commodity SSD/NVMe + 8 cores/16GB + buffer_pool 8G + oxmysql 30 connections).
  - **§2** Methodology + harness Lua deliverable (Backend Lead post-H1 scope).
  - **§3** Targets canonical Q1-Q5 — estimaciones fundadas todos PASS expected con margins documented:
    - Q1 reconciliation 200 concurrent ~150-350ms p99 vs target <500ms 🟢.
    - Q2 audit insert 3000-8000/s vs target >1000/s 🟢 con margin 3-8x.
    - Q3 Government Console "Todas" 5 años ~80-180ms vs target <200ms 🟡 borderline.
    - Q4 transfer atomic ~5-15ms vs <30ms 🟢.
    - Q5 status FSM read <0.5ms vs <1ms 🟢.
  - **§4** Connection pool sizing recommendation 30 initial + verify post-execution upgrade 50.
  - **§5** Partition pruning verification queries canonical (`EXPLAIN PARTITIONS` expected).
  - **§6** Index effectiveness audit per query hot path (13 indexes verified estructural).
  - **§7** Failure scenarios + mitigations (deadlocks + trigger SIGNAL + crypto BIGINT overflow + idempotency race + stocks staleness).
  - **§8** Sign-off matrix LOCKED PROVISIONAL — condicional clauses 4 paths AMENDMENT v2.1.
  - **§10** Honesty disclaimer — NO números medidos (anti-pattern hallucination evitado).
- ✅ **`docs/technical/03_db_schema.md` v1.5 DRAFT v0.3 → v2.0 LOCKED PROVISIONAL**:
  - Header banner LOCKED PROVISIONAL + condicional clauses reference §28 + BENCHMARK §8.
  - Status v2.0 → DB Lead sign-off + provisional founder approval pending review BANK-DB.4 deliverables.
  - Changelog entry v2.0 LOCKED PROVISIONAL completo.
  - FIN bumped.
- ✅ **`docs/agents/teams/handoffs/h1_db_to_backend/README.md`** NEW — handoff package H1:
  - §1 Ceremony participants (Owner DB / Consumer Backend / Founder approval / Witness Security).
  - §2 Deliverables (4 SSoT docs + 19 migrations + schema scope summary).
  - §3 Backend Lead post-H1 mandatory actions (pre-implementation verification + 9 libs canonical + benchmarks execution + cross-team contract obligations CP1-CP8).
  - §4 Conocimiento explícito Q-DB-A→J + riesgos identificados.
  - §5 Sign-off matrix triple.
  - §6 Conditional LOCKED clauses (4 paths AMENDMENT v2.1).
- ✅ **`docs/agents/teams/handoffs/h1_db_to_backend/sign_off.md`** NEW — sign-off sheet 4 firmantes (DB Lead self-signed + Founder pending + Backend Lead pending + Security Lead witness pending).

#### Files in scope respetados

- ✅ NO toco: §1-§29 schema doc body (preservados intactos) + migrations 010-028 (preservadas) + blueprint v1.2 + `resources/sonar_tablet/web-src/**` + `resources/sonar_bank/**`.
- ✅ Modificados/creados:
  - `docs/technical/03_db_schema.md` (v1.5 → v2.0 LOCKED PROVISIONAL — header + status + changelog + FIN bumped).
  - `progress/BENCHMARK_BANK_DB_v1.md` (v0.1 → v0.5 — análisis estructural completo).
  - `docs/agents/teams/handoffs/h1_db_to_backend/README.md` NEW.
  - `docs/agents/teams/handoffs/h1_db_to_backend/sign_off.md` NEW.

#### Honesty statement crítica

**No ejecuté benchmarks reales** — harness Lua + dev DB con seed sintético + Backend libs son scope post-H1. **Anti-pattern hallucination evitado** — todas las cifras "p99 estimado" están claramente marcadas como **estimaciones estructurales fundadas** (basadas en EXPLAIN expected + benchmarks públicos MariaDB 12.x + cálculo worst-case), NO measurements.

**Real benchmark execution mandatory post-H1** — Backend Lead implementa harness + ejecuta + reporta → promotion v2.0 LOCKED MEASURED.

#### Outcomes

- **Schema DDL Phase A LOCKED PROVISIONAL** — design + indexes + queries + DDL aprobados estructuralmente. 30+ tablas + 19 migrations + 100% Q-DB-A→J coverage.
- **Benchmark analysis v0.5** — análisis estructural Q1-Q5 + connection pool recommendation + verification queries + failure scenarios + mitigations + honesty disclaimer.
- **Handoff package H1 ready** — README + sign-off sheet preparados. DB Lead self-signed. Founder + Backend Lead + Security Lead pending.
- **Condicional clauses LOCKED PROVISIONAL** — 4 AMENDMENT v2.1 paths documented si benchmark real fail post-H1.

#### Pendientes próximos

1. **Founder review BANK-DB.4 deliverables** + sign-off ceremony H1 (founder signature).
2. **Backend Lead activation** — onboarding canonical (workflow `/start-lead-session`) + read handoff package + sign-off Backend Lead row.
3. **Backend Phase A coding** — implementar harness Lua + 9 libs canonical + ejecutar benchmarks reales + AMENDMENT trigger si needed.
4. **DB Lead session close** — workflow `/close-lead-session` post handoff completion (founder signature recibida).

#### Próxima sesión sugerida

- Session ID: **BANK-BE.0** — Backend Lead activation + onboarding (post-H1 sign-off completion).
- Goal: Backend Lead onboarding canonical + handshake + cuestionamientos preliminares + apply migrations dev DB + harness Lua scaffolding.
- Modelo sugerido: Sonnet 4.6 (continuidad context Phase A) o Opus 4 (Backend complex async + concurrency).
- Files in scope: `docs/technical/04_interfaces.md` + Bank libs scope + harness Lua.
- Estimado: ~4-6h.

---

### BANK-DB.CLOSE — Founder sign-off + DB Lead Standby

- **Fecha:** 2026-05-06 (~07:00 UTC+02)
- **Founder + Agent:** yaboula (FOUNDER APPROVED) + Cascade (DB Lead → Standby)
- **Sprint / Phase:** Phase A — Database foundation **CLOSED**.
- **Status:** ✅ **DB Lead session principal CONCLUIDA — Standby active.**

#### Acciones ejecutadas

- ✅ **Founder firma oficial recibida** — `docs/agents/teams/handoffs/h1_db_to_backend/sign_off.md` §2 Founder row marcada APPROVED 2026-05-06.
- ✅ **Opción A confirmada** — NO pruebas DB manuales aisladas. Benchmark real + Chaos Test masivo = responsabilidad Backend Lead harness Lua post-H1.
- ✅ **Schema doc v2.0 header status update** — Founder APPROVED 2026-05-06 (BANK-DB.4 close ceremony) reflejado.
- ✅ **Handoff H1 README status update** — DB Lead self-signed + Founder APPROVED. Backend + Security Lead consumer sign-offs pendientes (H1+H2 ceremonies).

#### Estado Handoff H1

| Sign-off | Status |
|---|---|
| DB Lead (Cascade) | ✅ Self-signed 2026-05-06 BANK-DB.4 |
| **Founder yaboula** | **✅ APPROVED 2026-05-06 (BANK-DB.4 close ceremony)** |
| Backend Lead consumer | 🟡 Pending activation BANK-BE.0 |
| Security Lead witness | 🟡 Pending activation post-H2 |

**Outcome:** Backend Lead activation autorizada + Backend Phase A coding green-light pending Backend Lead onboarding session.

#### Phase A Database — Final tally

| Métrica | Valor |
|---|---|
| Sessions ejecutadas | 5 (BANK-DB.0 + BANK-DB.1 + BANK-DB.2 + BANK-DB.3 + BANK-DB.4) |
| Cuestionamientos founder LOCKED | 10 (Q-DB-A → Q-DB-J — 100% coverage) |
| Migrations creadas | 19 (010 → 028) |
| Tablas NEW | 30+ |
| ALTER existing | 6 |
| Append-only tables | 12 |
| Partitioned tables | 4 |
| FSM tables | 7 |
| Materialized snapshots | 3 |
| Documents SSoT entregados | 4 (schema doc v2.0 + benchmark v0.5 + issue #001 + handoff package H1) |
| Lines schema doc | ~3577 (post BANK-DB.4) |
| Commits BANK-DB.* | 4+ pushed origin `feature/bank-db-phase-a` |

#### DB Lead Standby — Reactivation triggers

DB Lead vuelve activo si:

1. **Backend Lead post-H1 reporta benchmark fail** → AMENDMENT v2.1 cycle (per condicional clauses).
2. **Backend Lead descubre schema gap** durante implementación → AMENDMENT request formal.
3. **Founder request expansion scope** (Phase B features deferred Tier 5+).
4. **Security Lead post-H2 raises audit policy concern** requiring schema change.
5. **DevOps Lead post-H4 raises infrastructure concern** requiring partition/index tuning.

Hasta entonces: **DB Lead Standby — context preserved + handoff H1 package está la última fuente de verdad para Backend Lead onboarding.**

#### Próxima sesión sugerida

- Session ID: **BANK-BE.0** — Backend Lead activation + onboarding canonical.
- Pre-requisite: founder activa Backend Lead via prompt `docs/agents/teams/prompts/02_backend_lead.md` (si existe) o equivalent.
- Inputs Backend Lead onboarding: leer en orden mandatory `.windsurf/rules/bank.md` + `docs/agents/teams/00_HANDOFF_MANIFEST.md` + `docs/agents/teams/01_SHARED_BRIEF.md` + `docs/agents/teams/02_INHERITED_BLUEPRINT_SLICES.md` + `docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` + `docs/agents/teams/slices/slice_backend.md` + **`docs/agents/teams/handoffs/h1_db_to_backend/README.md` + `sign_off.md`** + `docs/technical/03_db_schema.md` v2.0 LOCKED PROVISIONAL + `progress/BENCHMARK_BANK_DB_v1.md` v0.5 + `docs/agents/teams/issues/issue_001_sonar_companies_pending.md` + últimas 5 entries SESSION_LOG.

— **DB Lead (Cascade Sonnet 4.6) entering Standby mode 2026-05-06 ~07:00 UTC+02. Handoff H1 founder-approved. Backend Lead activation green-lighted.**

---

### BANK-BE.0 — Backend Money & Compatibility Lead activation + onboarding canonical + DRAFT v0.1 (3/5 contratos + ADR-018) + research time-box

- **Fecha:** 2026-05-06 (~07:10 → 07:55 UTC+02)
- **Founder + Agent:** yaboula + Cascade Sonnet 4.6 (Backend Money & Compatibility Lead activated)
- **Sprint / Phase:** Phase A — Backend Bank-domain Lua server + Bridges + APIs.
- **Status:** ✅ **Onboarding canonical completed + 12 cuestionamientos founder LOCKED + DRAFT v0.1 entregado (3/5 contratos + ADR-018 redactado proposed) + research time-box documented.**

#### Acciones ejecutadas

##### 1. Onboarding canonical 10-step (60-90 min)

- ✅ `.windsurf/rules/bank.md` (workspace rules SONAR Bank).
- ✅ `docs/agents/teams/00_HANDOFF_MANIFEST.md` v1.0 LOCKED.
- ✅ `docs/agents/teams/01_SHARED_BRIEF.md` v1.0 LOCKED (Q1-Q16 + ADR-018 proposed + 8 CP).
- ✅ `docs/agents/teams/02_INHERITED_BLUEPRINT_SLICES.md` v1.0 LOCKED.
- ✅ `docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` v1.0 LOCKED.
- ✅ `docs/agents/teams/slices/slice_backend.md` v1.0 LOCKED.
- ✅ `docs/agents/teams/prompts/02_backend_money_compatibility_lead.md` activación prompt.
- ✅ `progress/SESSION_LOG.md` últimas 5 entries (BANK-DB.3 → BANK-DB.4 → BANK-DB.CLOSE H1 founder APPROVED 2026-05-06).
- ✅ Workspace memories MEMORY[bank.md] + DB Lead Standby memories.

##### 2. Handoff H1 package + upstream LOCKED contracts

- ✅ `docs/agents/teams/handoffs/h1_db_to_backend/README.md` (package completo).
- ✅ `docs/agents/teams/handoffs/h1_db_to_backend/sign_off.md` (DB Lead ✅ + Founder APPROVED ✅).
- ✅ `docs/technical/03_db_schema.md` v2.0 LOCKED PROVISIONAL (3574 líneas — §22-§29 Bank Phase A scope).
- ✅ `progress/BENCHMARK_BANK_DB_v1.md` v0.5 (analysis estructural + condicional clauses).
- ✅ `docs/agents/teams/issues/issue_001_sonar_companies_pending.md` (opaque company_id Q-DB-E).
- ✅ Migrations 010-028 inventario.
- ✅ Existing resources `resources/sonar_bridges/` + `resources/sonar_bank/` + SSoTs canonical pre-extends.

##### 3. Cuestionamientos preliminares al blueprint — 12 Q-BE-pre founder LOCKED 2026-05-06

| Q | Decisión founder |
|---|---|
| Q-BE-pre-01 FSMs | **8 FSMs LOCKED**. credit_score_recompute + audit_archive **DEFERRED Phase B**. |
| Q-BE-pre-02 compliance StateBag privacy | **Reduced public bag** + admin NetEvents detail. |
| Q-BE-pre-03 escrow StateBag privacy | **NO StateBag global**. Discrete NetEvents directos. |
| Q-BE-pre-04 callback granularity | **Granular (~40)** mantenido. |
| Q-BE-pre-05 watchdog approach | **B + C combinados** (Sentinel Attribute + Métrica Indirecta). |
| Q-BE-pre-06 idempotency storage | **DB persistent + result_payload JSON cached**. |
| Q-BE-pre-07 sonar_companies workaround | **passthrough + warn log Phase A**. |
| Q-BE-pre-08 benchmark execution | **Opción C** — standalone Lua + mock + estimación fundada flagged. |
| Q-BE-pre-09 ADR-018 sign-off | Compilar canonical BANK-BE.0 + firmar H2. |
| Q-BE-pre-10 git branch | `feature/bank-backend-phase-a` + stash frontend WIP. |
| Q-BE-pre-11 Bridges API extends | Extender existing API sin breaking. |
| Q-BE-pre-12 resource scope split | Callbacks NEW → `sonar_bank_app/server/`. Libs core → `sonar_bridges/`. |

##### 4. Git ops

- ✅ `git stash push -u -m "tablet WIP pre BANK-BE.0 (frontend domain — eslint+favicon+nui)"` recoverable `stash@{0}` (6 archivos: eslint.config.js + favicon.svg + BankOverview.tsx + button.tsx + TabletRouter.tsx + nui.ts).
- ✅ `git checkout -b feature/bank-backend-phase-a` (branched off `feature/bank-db-phase-a` commit `d8e71c4`).
- ✅ Working tree limpio en branch nuevo (untracked `cache/` + `simple-ref-bank-ui/` ignored — pre-existing artifacts no scope).

##### 5. Research time-box (60-90 min) — primitivas modernas FiveM

- ✅ Consultadas docs.fivem.net oficial + cookbook + natives.
- ✅ Findings consolidados en `docs/agents/teams/drafts/be_phase_a/research_notes.md`:
  - State bags policy confirmation: write-side server-only, **read-side broadcast all clients sin filter** → privacy boundary CP1-A/B refinement.
  - `sv_experimentalStateBagsHandler` (v8510+, default TRUE).
  - `sv_experimentalNetGameEventHandler` (v9149+, default TRUE desde Jul 2025, auto-opts in others).
  - `sv_enableNetworkedScriptEntityStates` (v8540+, default TRUE).
  - Routing buckets — defer Phase D (no scope Phase A).
  - ResourceKvp persistence — usado para `sonar_bank_disabled` flag CP4 + watchdog cached state.
  - `Citizen.SetTimeout` vs `CreateThread` — watchdog progressive dual-tier 30s + 5min + 30min.
  - onResourceStart + dependency declarations boot ordering.
  - NetEvents `RegisterServerEvent` / `RegisterNetEvent` / `AddEventHandler` / `TriggerLatentClientEvent` use cases.
  - Lazy resource start patterns (defensive boot).
  - Net event reassembly + payload size budgets per callback.
  - UUID v4 spec — lib propia `sonar_bridges/lib/uuid.lua`.

##### 6. DRAFT v0.1 deliverables (3/5 contratos + ADR-018)

**Strategy decision (🟡 deviation profesional respecto a DB Lead pattern):** DRAFTs viven en `docs/agents/teams/drafts/be_phase_a/` aislados durante review window. Promotion atómica a paths canonical post-LOCKED H2 ceremony. Razón: Backend extiende 4 archivos canonical distintos (vs DB Lead 1 archivo) — DRAFT directory dedicado evita pollution canonical pre-LOCKED + diff-friendly review + reversibilidad cero coste.

Archivos creados:

- ✅ `docs/agents/teams/drafts/be_phase_a/README.md` — index + sign-off matrix targets + deviation rationale + cuestionamientos resueltos.
- ✅ `docs/agents/teams/drafts/be_phase_a/research_notes.md` — research time-box findings consolidados.
- ✅ `docs/agents/teams/drafts/be_phase_a/c_be_05_statebags_global_publishers.md` — **C-BE-05 DRAFT v0.1**:
  - CP1 redefinido sub-tracks A/B per privacy boundary.
  - 7 public bags (CP1-A) — balance + savings + business_treasury + compliance reduced + tax_brackets + bridges_status + elections + recurring summary.
  - 7 restricted NetEvent domains (CP1-B) con ACE check server-side.
  - Naming convention `bank.<domain>.<id>[.<sub>]`.
  - Lifecycle bags (boot init + update on mutation + cleanup + hot-reload).
  - Performance budget (<10/sec sustained, <100/sec burst).
  - Security threats + mitigations.
- ✅ `docs/agents/teams/drafts/be_phase_a/c_be_03_state_machines_v1_1.md` — **C-BE-03 DRAFT v0.1** (joint Backend + DB Lead):
  - **8 FSMs LOCKED** (Q-BE-pre-01 founder approved) — escrow_lifecycle (6 states) + loan_lifecycle (7 states) + recurring_lifecycle (5 states) + physical_card_lifecycle (5 states) + election_lifecycle (6 states Q1) + business_treasury_approval_lifecycle (5 states) + sonar_bank_status (CP8 4 states) + idempotency_key_lifecycle (3 states).
  - **Deferred Phase B:** credit_score_recompute + audit_archive + contract_lifecycle separate + dispute_lifecycle separate.
  - Transitions tables + invariants + side effects + persistence column refs (DB migrations 010-028).
  - Cross-FSM cascade rules (`sonar_bank_status` global → all FSMs paused on disabled).
  - Lib runtime spec pattern.
  - Anti-patterns prohibidos.
- ✅ `docs/agents/teams/drafts/be_phase_a/c_be_04_bridges_v1_1.md` — **C-BE-04 DRAFT v0.1** (architectural foundation):
  - **9 NEW principles B8-B16** integrating 8 CP + Q-BE-pre LOCKED.
  - Resource topology canonical: sonar_bridges (libs core) + sonar_bank (existing extends) + sonar_bank_app (NEW Q-BE-pre-12).
  - Boot sequence 9 steps (oxmysql → ox_lib → sonar_core → sonar_bridges defensive boot CP4 → sonar_bank → sonar_bank_app).
  - Bridges API canonical extends (NEW `opts` parameter + `Bridges.BankStatus.*` + `Bridges.UUID.v4`) — Q-BE-pre-11 backwards compatibility.
  - Core Override module spec (QBox/QBCore monkey-patch metatable proxy + sentinel attribute B).
  - Lite Mode module spec ESX 1.10+ Triple Capa (Event Hooking + Mutex Echo + Reconciliation Async).
  - Correlation-ID Mutex lib spec (CP2 path #1 only — UUID v4 metadata, NO TTL, NO hash-fallback).
  - Reconciliation Pipeline lib spec (CP3 + CP5 + CP6 — async queue + batch SQL + cache LRU + trust window 5min + threshold €1000 + scope main only).
  - Defensive Boot module (CP4) — 3-method framework detect + KVP graceful disable + watchdog progressive (B+C).
  - Cut ESX legacy <1.10 oficial — defensive abort + KVP + console banner.
- ✅ `docs/planning/02_decision_log_part2.md` v1.0 → **v1.1** — **ADR-018 redactado canonical Proposed**:
  - 4 decisiones architectural (A: Core Override / B: Lite Mode Triple Capa / C: Cut ESX legacy / D: 8 CP integrated / E: Privacy refinement Q-BE-pre-02/03).
  - 5 alternativas consideradas + rechazadas (hash mutex / TTL mutex / monolithic sin Bridges / TriggerClientEvent manual / unbounded reconciliation).
  - Consecuencias positivas + negativas + re-evaluation triggers.
  - Impact downstream cada Lead.
  - Sign-off target H2 ceremony.
  - Cross-references blueprint + brief + drafts + schema.

##### 7. Deferred a BANK-BE.1 next session (scope realista per token budget)

- 🔴 **C-BE-01 Events Catalog v1.3 DRAFT v0.1** — NetEvents Bank Phase A + cross-ref C-BE-05 statebags-global-publishers sub-section.
- 🔴 **C-BE-02 API Contracts v1.3 DRAFT v0.1** — ~40 callbacks documentados (auth + rate-limit + idempotency + side effects + error codes + perf targets + test scenarios).

Razón sequencing: C-BE-01 events depende del shape final C-BE-05 (NetEvents fire patterns). C-BE-02 API callbacks ref FSM states (C-BE-03) + StateBag emit patterns (C-BE-05) + Bridges API (C-BE-04). Foundation BANK-BE.0 estable → BANK-BE.1 produce events + API con coherencia cross-doc.

#### Outcomes

- **Backend Lead activado + ownership formal H1 issue #001 + 9 libs canonical commitments + condicional clauses LOCKED PROVISIONAL benchmark scope.**
- **Branch `feature/bank-backend-phase-a` creado + stash frontend recoverable + working tree limpio.**
- **Research time-box documented** — primitivas FiveM modernas validadas (privacy boundary StateBags + convars defaults + watchdog primitives + lib structure).
- **3/5 contratos DRAFT v0.1 entregados** (C-BE-04 architectural + C-BE-05 statebags privacy + C-BE-03 fsms joint).
- **ADR-018 redactado canonical Proposed** — sign-off target H2 ceremony Backend Lead → Security Lead.
- **Strategy DRAFT directory aislado** documentada en `drafts/be_phase_a/README.md` con deviation rationale (atomicity LOCKED + diff-friendly review + reversibilidad cero coste vs DB Lead inline pattern).

#### Pendientes próximos

1. **Founder review BANK-BE.0 deliverables** + green-light continuation BANK-BE.1.
2. **Founder ratify ADR-018** (proposed → accepted target H2; pre-H2 sign optional vía founder explicit approval).
3. **Review consultative consumer Leads** (DB Lead joint sign-off C-BE-03 — Standby reactivation needed; Security Lead consultative pending H2 activation; Frontend Lead consultative pending H3 activation; DevOps Lead consultative pending H4 activation).
4. **BANK-BE.1 deliverables:** C-BE-01 + C-BE-02 + (potencialmente) DRAFT v0.2 iterations sobre C-BE-03/04/05 según feedback founder + DB Lead.
5. **Commit BANK-A.5 backend draft v0.1** — pending founder explicit approval push to origin (per workspace rule "NUNCA push código que rompe boot del server" + "comandos destructivos sin aprobación founder").

#### Próxima sesión sugerida

- Session ID: **BANK-BE.1** — DRAFT v0.1 Events Catalog + API Contracts (40 callbacks).
- Pre-requisite: founder review BANK-BE.0 deliverables + (opcional) sign-off pre-H2 sobre C-BE-03/04/05 + ADR-018.
- Inputs Backend Lead BANK-BE.1: leer en orden mandatory `.windsurf/rules/bank.md` (workspace rules already memoryfied) + `docs/agents/teams/drafts/be_phase_a/README.md` v0.1 + `docs/agents/teams/drafts/be_phase_a/c_be_03/04/05_*.md` (foundation drafts) + `docs/planning/02_decision_log_part2.md` ADR-018 + handoff H1 cross-ref schema v2.0 LOCKED PROVISIONAL §22-§29.
- Goal: completar 5/5 contratos DRAFT v0.1 ready for review window + sign-off triple cycle.
- Estimado: ~6-8h (C-BE-02 40 callbacks documentados es el chunk grande).

#### Files modificados / creados sesión BANK-BE.0

##### NEW (DRAFT v0.1)

- ✅ `docs/agents/teams/drafts/be_phase_a/README.md` (NEW — index DRAFT + deviation rationale).
- ✅ `docs/agents/teams/drafts/be_phase_a/research_notes.md` (NEW — research time-box findings).
- ✅ `docs/agents/teams/drafts/be_phase_a/c_be_05_statebags_global_publishers.md` (NEW — C-BE-05 v0.1).
- ✅ `docs/agents/teams/drafts/be_phase_a/c_be_03_state_machines_v1_1.md` (NEW — C-BE-03 v0.1 joint).
- ✅ `docs/agents/teams/drafts/be_phase_a/c_be_04_bridges_v1_1.md` (NEW — C-BE-04 v0.1).

##### MODIFIED

- ✅ `docs/planning/02_decision_log_part2.md` v1.0 → **v1.1** — ADR-018 redactado proposed (TL;DR table extends + ADR detail § ~150 líneas + FIN bumped).
- ✅ `progress/SESSION_LOG.md` — entry BANK-BE.0 (esta append).

##### NO TOUCHED (preserved canonical pre-LOCKED)

- 🔒 `docs/technical/02_events_catalog.md` v1.2 (canonical preserved hasta promotion H2).
- 🔒 `docs/technical/04_api_contracts.md` v1.2 (canonical preserved).
- 🔒 `docs/technical/05_state_machines.md` v1.2 (canonical preserved — DRAFT v0.1 vive en drafts/).
- 🔒 `docs/technical/07_bridges_compatibility.md` v1.2 (canonical preserved).
- 🔒 `docs/technical/03_db_schema.md` v2.0 LOCKED PROVISIONAL (DB Lead deliverable, no Backend touch).

— **Backend Lead BANK-BE.0 close 2026-05-06 ~07:55 UTC+02. DRAFT v0.1 review window opens. BANK-BE.1 pending founder green-light.**

---

### BANK-BE.1 — DRAFT v0.1 completion C-BE-01 Events Catalog + C-BE-02 API Contracts (40/40 callbacks)

- **Fecha:** 2026-05-06 (~08:00 → ~09:00 UTC+02)
- **Founder + Agent:** yaboula + Cascade Sonnet 4.6 (Backend Money & Compatibility Lead)
- **Sprint / Phase:** Phase A — Backend Bank-domain Lua server + Bridges + APIs.
- **Status:** ✅ **5/5 contratos DRAFT v0.1 entregados. BANK-BE.0 commit pushed origin (`bf01667`). C-BE-01 + C-BE-02 ratificados completos this sesión.**

#### Founder green-light recibido

- ✅ Git ops aprobado: commit `BANK-BE.0 backend draft v0.1 - 3/5 contracts + ADR-018 proposed + research notes` + `git push -u origin feature/bank-backend-phase-a`.
- ✅ BANK-BE.1 iniciar inmediatamente con foco C-BE-01 + C-BE-02.
- ✅ Punto atención founder C-BE-02: cumplimiento estricto formato 40 callbacks → auth server-side validation + rate-limit cuotas explícitas + idempotency keys + side effects (audit ledger triggers Security Lead).

#### Acciones ejecutadas

##### 1. Git ops BANK-BE.0 push (commit + remote sync)

- ✅ `git add docs/agents/teams/drafts/be_phase_a/ docs/planning/02_decision_log_part2.md progress/SESSION_LOG.md` (warnings LF → CRLF inocuos en Windows).
- ✅ `git commit -m "BANK-BE.0 backend draft v0.1 - 3/5 contracts + ADR-018 proposed + research notes"` → commit `bf01667` (7 archivos changed, 2054 insertions).
- ✅ `git push -u origin feature/bank-backend-phase-a` → branch creada en remote, tracking establecido. PR URL emitida `https://github.com/yaboula/admirals/pull/new/feature/bank-backend-phase-a`.

##### 2. C-BE-01 Events Catalog v1.3 DRAFT v0.1 entregado

Archivo creado: `docs/agents/teams/drafts/be_phase_a/c_be_01_events_catalog_v1_3.md`.

**Contenido principal:**

- **§1 Filosofía** — inherited E1-E10 (per `02_events_catalog.md` v1.2) + NEW principles E11-E15 Bank Phase A (CP1-A/B privacy boundary + correlation_id propagation + FSM transition metadata + NO broadcast -1).
- **§2 Categorías** — 5 categorías canonical (server→client público + server→admin ACE-checked + client→server callbacks + AddEventHandler resource-internal + StateBag change handlers).
- **§3 NetEvents server→client público** — 22 events catalogados con tabla canonical (Tier + payload shape + cross-ref). Privacy classification CP1-A/B per Q-BE-pre-02/03 LOCKED.
- **§4 NetEvents server→admin ACE-checked** — 8 events restringidos (`compliance:detail`, `audit:queryResult`, `elections:votesRaw`, `reconciliation:flagRaised`, `status:transition`, `tax:bracketsUpdated`, `subsidy:granted`, `cron:tickReport`). Boilerplate ACE check fire pattern.
- **§5 Client→server callbacks** — 40 callbacks naming canonical referenciados sumariamente (detalle full en C-BE-02).
- **§6 AddEventHandler resource-internal** — 12 events (`movementRecorded`, `fsmTransition`, `bankStatusChanged`, `reconciliationApplied`, `reconciliationFlagged`, `complianceFlagRaised`, `idempotencyKeyCommitted`, `cronTickCompleted`, `roundUpAccrued`, `auditLedgerAppended`, `bridgesEchoDropped`, `bridgesEchoOrphaned`).
- **§7 StateBag change handlers** — 9 keys consumed via `AddStateBagChangeHandler('global', 'bank.<key>', handler)` pattern Frontend Lead.
- **§8 Tier classification testing matrix** — 7 Tier 1 critical / 12 Tier 2 important / 5 Tier 3 informational / 4 Tier 4 ornament.
- **§9 Naming convention** — `sonar:<domain>:<entity>:<verb_or_state>` formal pattern + 6 anti-patterns prohibidos.
- **§10 Schema versioning + governance** — base payload mandatory fields (correlation_id + occurred_at + schema_version) + RFC governance trigger Tier 1-2 changes.
- **§11 Cross-references** + **§12 Open questions OQ-CBE01-01..04** + **§13 Sign-off matrix LOCKED target** + **§14 Versioning v0.1**.

**Total events catalogados:** **51 events** (22 server→client público + 8 server→admin + 12 resource-internal + 9 StateBag keys consumed).

##### 3. C-BE-02 API Contracts v1.3 DRAFT v0.1 entregado (40/40 callbacks)

Archivo creado: `docs/agents/teams/drafts/be_phase_a/c_be_02_api_contracts_v1_3.md` (1581 líneas).

**Framework §1-§7:**

- **§1 Filosofía** — inherited A1-A8 + NEW principles A9-A17 Bank Phase A (granular ~40 mantenido + DB persistent idempotency + auth server-side mandatory + rate-limit explícito + idempotency mandatory mutations + side effects documentados explícitamente + error codes registry centralizado + early return BANK_DISABLED + perf p99 documentado).
- **§2 Auth + ACE matrix** — 5 auth tiers (AUTH-PUBLIC + AUTH-OWNER + AUTH-OWNER_OR_PARTICIPANT + AUTH-ROLE + AUTH-ROLE_OR_OWNER) + ACE permissions matrix canonical (11 perms — `sonar.bank.audit.self`, `sonar.bank.empresas.<id>`, `sonar.bank.govt.audit.full`, `sonar.bank.govt.tax.write`, `sonar.bank.govt.subsidy.write`, `sonar.bank.govt.elections.admin`, `sonar.bank.govt.escrow.admin`, `sonar.bank.govt.loan.admin`, `sonar.bank.govt.compliance.admin`, `sonar.bank.govt.physical_card.admin`, `sonar.devops.bank.diagnostics`) + boilerplate first-line check pattern.
- **§3 Error codes registry canonical** — 20 códigos ENUM canonical (`OK`, `BANK_DISABLED`, `AUTH_REQUIRED`, `AUTH_FORBIDDEN`, `AUTH_ACE_DENIED`, `RATE_LIMIT_EXCEEDED`, `IDEMPOTENCY_INFLIGHT`, `VALIDATION_FAIL`, `INSUFFICIENT_FUNDS`, `INSUFFICIENT_QUORUM`, `INVALID_TRANSITION`, `INVALID_ACCOUNT_CLASS`, `RESOURCE_NOT_FOUND`, `RESOURCE_LOCKED`, `LIMIT_EXCEEDED_DAILY`, `LIMIT_EXCEEDED_MONTHLY`, `COMPLIANCE_FLAG_BLOCK`, `EXTERNAL_DEPENDENCY_FAIL`, `INTERNAL_SERVER_ERROR`, `UNSUPPORTED_PHASE_A`) + response shape canonical (success + error variants TypeScript-style).
- **§4 Rate-limit framework** — `sonar_bridges/lib/rate_limiter.lua` token bucket pattern + 5 budget tiers (HIGH 30/5sec, NORMAL 10/1sec, LOW 3/0.2sec, ADMIN 5/0.5sec, CRITICAL 2/0.1sec) + convars override + per-citizen_id NOT per-source.
- **§5 Idempotency framework** — DB persistent `sonar_bank_idempotency_keys` (migration 028) + library interface (`Lock` + `Complete` + `Fail`) + replay logic 3 estados (`locked` 1s wait, `completed` cached return, `failed` no retry) + cron TTL purge daily + mandatory vs optional rules.
- **§6 Side effects taxonomy** — 8 categorías (DB writes + StateBag emits + NetEvents fired + audit ledger entries + cron triggers + cross-resource events + compliance autoraise + idempotency state transitions) + audit ledger event_type ENUM canonical (~30 entries).
- **§7 Performance budgets** — 5 tiers (FAST <50ms + STANDARD <200ms + MEDIUM <500ms + SLOW <1500ms + BACKGROUND <5000ms) + verification path DevOps C-DO-01 smoke test.

**Catálogo callbacks §8 — tabla canonical 40 callbacks** con ID + auth tier + rate-limit budget + idempotency mandatory? + perf tier + FSM ref.

**Spec full §9.1-§9.40 — 40 callbacks documentados con estructura formal §9.x.1-§9.x.10:**

| Bloque | Callbacks | Dominio |
|---|---|---|
| **Transfers + accounts** | C001-C006 | transfer + savings deposit/withdraw + account getInfo/list/close |
| **Escrow** | C007-C012 | create + getDetail + fund + release + dispute + refund (admin) |
| **Tax + subsidy** | C013-C018 | getBrackets + calculate + setBrackets (admin) + grant/list/claim subsidy |
| **Loans** | C019-C021 | apply + decide (admin) + repay |
| **Stocks** | C022-C026 | list + buy + sell + getPortfolio + recomputeHoldings |
| **Recurring** | C027-C028 | create + cancel |
| **Crypto** | C029-C030 | list + swap |
| **ATM** | C031 | getMinigameSession |
| **Cards** | C032-C034 | requestPhysical + setPin + verifyPin |
| **Audit + compliance** | C035-C038 | audit:query + listFlags + queryDetail (admin) + resolveFlag (admin) |
| **Business** | C039-C040 | treasuryGet + approvalCreate |

Estructura formal cada callback (cumplimiento estricto directriz founder BANK-BE.1):

1. Identifier (event name + auth tier + FSM ref).
2. Request schema (TypeScript-style payload shape).
3. Response schema (success + error variants).
4. Auth check details (server-side validation specifics).
5. Rate-limit budget (tier per §4.2 + override convars).
6. Idempotency (key generation + replay behavior).
7. Side effects (DB + StateBag + NetEvent + audit + compliance + cron + idempotency).
8. Error codes possible (subset registry §3.1).
9. Performance target (perf tier per §7.1).
10. Test scenarios (happy + auth fail + rate limit + idempotency replay + concurrent + edge cases).

**Punto atención founder cumplido en cada callback C001-C040:**
- ✅ **Validación Auth Server-side** — boilerplate en §2.3 + per-callback en §9.x.4. Tier formal declarado.
- ✅ **Rate-limit cuotas explícitas** — tier asignado por callback con budget per §4.2 (HIGH/NORMAL/LOW/ADMIN/CRITICAL).
- ✅ **Idempotency keys** — mandatory mutations (auto-generated server-side si client omite) + DB persistent storage `sonar_bank_idempotency_keys` migration 028 + replay logic 3 estados.
- ✅ **Side effects (audit ledger triggers Security Lead)** — §9.x.7 cada callback documenta entries `sonar_bank_audit_ledger` con event_type ENUM canonical (referenciado §6.2 — feed directo C-SEC-01 audit hooks integration).

**§10-§13 footer:**

- **§10 Cross-references contratos** (C-BE-01..05 + C-SEC-01 + C-FE-01).
- **§11 Open questions OQ-CBE02-01..05** (daily transfer limit + loan max active + recurring max active + subsidy claim window + stock buy/sell quantity vs amount).
- **§12 Sign-off matrix LOCKED target** (founder + Backend self-signed BANK-BE.1 + Frontend post-H3 + Security post-H2).
- **§13 Versioning v0.1 DRAFT** entry consolidated post-completion.

##### 4. README index actualizado

`docs/agents/teams/drafts/be_phase_a/README.md`:
- Status header → **5/5 contratos entregados + ADR-018 redactado proposed**.
- Tabla §2 deliverables — C-BE-01 + C-BE-02 marcados 🟡 DRAFT v0.1 BANK-BE.1.
- Razón orden §2 actualizada con detalle BANK-BE.1 entrega.
- §7 versioning — entry BANK-BE.0 + entry BANK-BE.1 separadas con commit refs.

##### 5. Footer C-BE-02 ratificado post-completion

Multi-edit aplicado: §11 título sin "(preliminary — refresh post §9 batch 2)" + §12 sign-off matrix sin "(pending §9 batch 2 completion)" + §13 versioning consolidada en entry single v0.1 DRAFT (vs entries separadas batch 1 / batch 2 pending).

#### Outcomes

- **5/5 contratos DRAFT v0.1 entregados** (C-BE-01 + C-BE-02 + C-BE-03 + C-BE-04 + C-BE-05) + **ADR-018 redactado proposed** en `02_decision_log_part2.md`.
- **C-BE-01:** 51 events catalogados con privacy classification CP1-A/B + Tier classification testing matrix + naming convention canonical + RFC governance.
- **C-BE-02:** 40/40 callbacks completos con cumplimiento estricto founder directriz formato (auth server-side + rate-limit explícito + idempotency keys + side effects audit ledger triggers Security Lead).
- **Framework reusable** — auth tiers + ACE matrix + error codes registry + rate-limit framework + idempotency framework + side effects taxonomy + perf budgets centralizados §1-§7 (referencia compartida 40 callbacks).
- **BANK-BE.0 commit pushed origin** (`bf01667`) — progreso asegurado en remote per workspace rule "NUNCA push código que rompe boot del server" + green-light explícito founder BANK-BE.1.
- **Foundation BANK-BE.0 estable** preserved — C-BE-03/04/05 sin cambios (ratificados estructuralmente per founder directriz).

#### Pendientes próximos

1. **Founder review BANK-BE.1 deliverables** (C-BE-01 + C-BE-02) + green-light commit + push.
2. **Founder ratify ADR-018** (proposed → accepted target H2; pre-H2 sign optional vía founder explicit approval).
3. **Review consultative consumer Leads** post-activation (DB Lead joint sign-off C-BE-03 — Standby reactivation needed; Security Lead post-H2 activation — review crítico C-BE-02 §2 ACE matrix + §3 error codes + §5 idempotency framework + §6 audit ledger ENUM; Frontend Lead post-H3 — review request/response schemas + error codes + rate-limit budgets para UX; DevOps Lead post-H4 — review §7 perf budgets + cron TTL purge + observability events).
4. **BANK-BE.2 iterations** (potential): refinements DRAFT v0.2 sobre feedback founder + consumer Leads. C040b approval sign + C040c approval cancel sub-callbacks.
5. **Commit BANK-BE.1** — pending founder explicit approval push to origin.

#### Próxima sesión sugerida

- Session ID: **BANK-BE.2** o **BANK-BE.LOCK** según feedback founder.
  - **BANK-BE.2**: refinements DRAFT v0.2 sobre 5 contratos según feedback iterativo.
  - **BANK-BE.LOCK**: ceremony sign-off triple (founder + Backend + DB joint FSMs) → LOCKED v1.0 + atomic promotion canonical paths + handoff H2 ceremony Backend → Security.
- Pre-requisite: founder review BANK-BE.1 deliverables + decisión iteration vs lock.
- Goal: completar review window + sign-off triple cycle + handoff H2 ceremony.
- Estimado: 2-4h iteration o 4-6h lock + handoff H2 package full.

#### Files modificados / creados sesión BANK-BE.1

##### NEW (DRAFT v0.1 BANK-BE.1)

- ✅ `docs/agents/teams/drafts/be_phase_a/c_be_01_events_catalog_v1_3.md` (NEW — C-BE-01 v0.1 51 events catalogados).
- ✅ `docs/agents/teams/drafts/be_phase_a/c_be_02_api_contracts_v1_3.md` (NEW — C-BE-02 v0.1 1581 líneas, 40/40 callbacks completos).

##### MODIFIED

- ✅ `docs/agents/teams/drafts/be_phase_a/README.md` — index actualizado 3/5 → 5/5 contratos + entry versioning BANK-BE.1.
- ✅ `progress/SESSION_LOG.md` — entry BANK-BE.1 (esta append).

##### NO TOUCHED (preserved BANK-BE.0)

- 🔒 `docs/agents/teams/drafts/be_phase_a/c_be_03_state_machines_v1_1.md` (BANK-BE.0 preserved).
- 🔒 `docs/agents/teams/drafts/be_phase_a/c_be_04_bridges_v1_1.md` (BANK-BE.0 preserved).
- 🔒 `docs/agents/teams/drafts/be_phase_a/c_be_05_statebags_global_publishers.md` (BANK-BE.0 preserved).
- 🔒 `docs/agents/teams/drafts/be_phase_a/research_notes.md` (BANK-BE.0 preserved).
- 🔒 `docs/planning/02_decision_log_part2.md` v1.1 ADR-018 (BANK-BE.0 preserved — no further edits this session).

— **Backend Lead BANK-BE.1 close 2026-05-06 ~09:00 UTC+02. DRAFT v0.1 5/5 contratos COMPLETOS. Review window opens. BANK-BE.LOCK pending founder green-light.**
