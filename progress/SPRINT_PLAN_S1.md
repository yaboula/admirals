# 📋 Sprint 1 — Plan (outline, refinable pre-S1.1)

> **Sprint:** S1 — Banco core + IBAN + balance + transferencias.
> **Duración estimada:** 2 semanas (guidance, ajustable por split/merge dinámico).
> **Sessions:** 3 (tentativo — ver §2.3 founder_playbook para dinamismo).
> **Dependencias:** Sprint 0 cerrado ✅ (Bridges + admirals_core + migrations OK).
> **Goal global:** Founder puede abrir consola FiveM y: crear IBAN personal, consultar balance, ejecutar transfer player→player + audit log entry + event emitido + rate limit activo.

> ⚠️ Este plan es **outline**. Founder refina pre-S1.1 en sesión planning dedicada (30-60 min per `03_founder_playbook.md` §3.2).

---

## Done criteria SPRINT (tentativo)

- [ ] 3 sessions S1.1-S1.3 completadas.
- [ ] Smoke test S1 → 100% pass (a redactar en S1.3).
- [ ] `git tag v0.1.0` aplicado + pushed.
- [ ] `progress/SPRINT_RETRO_S1.md` escrito.
- [ ] `docs/planning/01_roadmap.md` §4.2 S1 marked ✅.
- [ ] `docs/agents/00_BOOTSTRAP.md` v1.4 si cambio significativo.

---

## Sessions tentativas

### S1.1 — admirals_bank skeleton + IBAN generator + schema

| Campo | Valor |
|---|---|
| **Perfil** | 🏗️ ARCHITECT + 🔧 BUILDER |
| **Modelo recomendado** | **Opus 4.7** |
| **Duración estimada** | 3-4h |
| **Dependencias** | S0 cerrado + `Admirals.DB` + `Admirals.Bus` + `Admirals.Rate` disponibles |

**Goal:** Crear resource `admirals_bank` con fxmanifest + config + migration 003_bank_schema.sql (admirals_bank_accounts + admirals_bank_transactions + admirals_escrows) + IBAN generator + callbacks básicos getBalance + audit wrapper integrado con Admirals.Audit.

**Files in scope tentativos:**
- `resources/admirals_bank/fxmanifest.lua`
- `resources/admirals_bank/config.lua`
- `resources/admirals_bank/server/iban.lua`
- `resources/admirals_bank/server/accounts.lua`
- `resources/admirals_bank/server/init.lua`
- `resources/admirals_core/migrations/003_bank_schema.sql`
- Actualizar `resources/admirals_core/config.lua` MigrationsFiles list.

**Files OUT of scope:**
- `admirals_bridges/*` (congelado — usa vía Admirals.DB + Bridges.Bank dispatch).
- Transfer logic (S1.2).
- Tablet UI (S2).

**Reference docs obligatorios:**
- `docs/technical/03_db_schema.md` §4 (dominio banca DDL).
- `docs/technical/04_api_contracts.md` §3.1 (C001-C005 callbacks).
- `docs/technical/05_state_machines.md` §4.1 (FSM escrow_lifecycle).
- `docs/technical/07_bridges_compatibility.md` §4 (Bridges.Bank interface).

---

### S1.2 — Transfer player→player + events + ratelimit + idempotency

| Campo | Valor |
|---|---|
| **Perfil** | 🏗️ ARCHITECT + 🔧 BUILDER |
| **Modelo recomendado** | **Opus 4.7** |
| **Duración estimada** | 3-4h |
| **Dependencias** | S1.1 completa |

**Goal:** Transfer callback + atomic TX + fee calc + audit log + event emit + rate limit 'bank.write' + **promote admirals_bridges._idem_store a DB-backed admirals_bridge_idempotency**.

**Files in scope tentativos:**
- `resources/admirals_bank/server/transfer.lua`
- `resources/admirals_bank/server/events.lua`
- `resources/admirals_bank/server/callbacks.lua`
- Modificación `resources/admirals_bridges/server/dispatcher.lua` (idempotency DB-backed path).
- Modificación `resources/admirals_bridges/config.lua` (Config.IdempotencyBackend flag).

**Files OUT of scope:**
- `docs/*` firmados.
- Escrow (S1.3).

---

### S1.3 — Escrow + FSM + tests harness + sprint close

| Campo | Valor |
|---|---|
| **Perfil** | 🏗️ ARCHITECT + ⚡ SPRINTER + 📝 SCRIBE |
| **Modelo recomendado** | **Opus 4.7** (arquitectura FSM) **+ Sonnet 4.6** (harness + retro) |
| **Duración estimada** | 4-5h |
| **Dependencias** | S1.2 completa |

**Goal:** Escrow createEscrow + releaseEscrow callbacks + FSM `escrow_lifecycle` implementado per `05_state_machines.md` §4.1 + harness tests manuales + `scripts/smoke_test_s1.md` + `SPRINT_RETRO_S1.md` + tag v0.1.0.

**Files in scope tentativos:**
- `resources/admirals_bank/server/escrow.lua`
- `resources/admirals_bank/server/fsm_escrow.lua`
- `scripts/smoke_test_s1.md`
- `progress/SPRINT_RETRO_S1.md`
- Updates `docs/planning/01_roadmap.md` + `docs/agents/00_BOOTSTRAP.md`.

---

## Notas founder pre-S1.1

- S1 puede incluir **migration 003 ampliando admirals_accounts** columnas (reputation_global, preferred_locale, etc.) si founder decide en planning.
- **SSoT consistency linter** (identificado en retro S0) es buen candidate a sprint S1 tail si sobra tiempo, o spike dedicado entre sprints.
- Descanso 1-2 días pre-S1.1 recomendado (Opus fatigue tras S0.4).

---

**FIN SPRINT_PLAN_S1 (outline)**
