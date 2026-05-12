# AMEND C-BE-04 — Bridges Layer Spec — Round 2 Phase 5 Pivot (DRAFT v0.1)

> **Tipo:** AMENDMENT formal Round 2 — Phase 5 architectural pivot (Core Override model abandoned → Ecosystem Closed Public API model).
> **Contract afectado:** C-BE-04 Bridges Layer v1.0.1 R1 LOCKED → propuesta v1.0.2 R2.
> **Status:** 🟡 **DRAFT v0.1 PENDING-SIGNOFF**.
> **Sesión emisora:** `BANK-BE.PHASE_5.1` Phase 1 — 2026-05-12.
> **Backend Lead:** Cascade activated per prompt `@docs/agents/teams/prompts/08_phase_5_ecosystem_api_backend_lead.md`.
> **Authority source:** Founder LOCK `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md` v1.0 (Q1-Q8 + §9 path (a) StateBag value type).
> **Design SSoT:** `@docs/design/04_sonar_bank_api.md` (v0.2 emitted Phase 1.8 of this package).

---

## 0. Resumen ejecutivo

Phase 4 Core Override (parásito invisible) abandonado runtime-side por bloqueos arquitectónicos insuperables (FiveM resource-boundary serialization, third-party scripts ignoran `RemoveMoney` false return, admin tooling unreachable, qb-core local patch GPL-fragility). Founder LOCKED 2026-05-12 pivot a Phase 5 modelo ox_inventory: SONAR Bank declara superficie pública cerrada (22 exports server-only) y exige migración explícita operator-side de cada recurso que toca dinero.

Esta amendment nulifica enteramente **§4 Core Override module** (~111 líneas + dependencies §4.2.1 SHA256 utility) del LOCKED v1.0.1 R1 y la reemplaza con **§4' Server-to-Server Integration API surface** — sección breve apuntadora al design SSoT `04_sonar_bank_api.md` v0.2.

**Severidad cambio:** MAJOR (nulifica módulo entero LOCKED).

**Secciones preservadas sin cambio:**
- §1 Filosofía Bridges Layer (B1-B11 inherited + NEW).
- §2 Architecture overview + boot sequence.
- §3 Bridges API canonical (3.1 + 3.2 + 3.2.1 BankStatus.Transition auth gate H002 R1 + 3.3 + 3.3.1 UUID.v4 entropy M002 R1).
- §5 Lite Mode module ESX 1.10+ (Capa A/B/C).
- §6 Correlation-ID Mutex lib (mutex_echo.lua, 6.1 + 6.1.1 M008 R1).
- §7 Reconciliation Pipeline lib (H004 R1 + M002 R1).
- §8 Watchdog spec (general health, NOT Core Override drift detection).
- §9 Status FSM + transitions.

**Secciones nulificadas:**
- §4 Core Override module (`sonar_bridges/server/core_override.lua`) — §4.1 + §4.2 + §4.2.1 + §4.3.

---

## 1. Finding traceability

| ID | Trigger | Severity | Source | Action |
|---|---|---|---|---|
| **P5-001** | Phase 4 runtime validation founder-side encontró 4 bloqueos arquitectónicos insuperables (FiveM resource boundary, `RemoveMoney` return ignored, admin Lua isolation, qb-core GPL fragility). | CRITICAL | `@docs/agents/teams/prompts/08_phase_5_ecosystem_api_backend_lead.md:14-27` + Founder LOCK Q1-Q8 | NULLIFY §4 Core Override + emit §4' API surface |

---

## 2. §4 — Core Override module — **NULLIFY**

### BEFORE (LOCKED v1.0.1 R1)

```
## 4. Core Override module (QBox/QBCore) — `sonar_bridges/server/core_override.lua`

### 4.1 Approach decision (per Q-BE-pre-05 founder green-light)
[Hybrid B + C combined: sentinel attribute + métrica indirecta]

### 4.2 Pseudo-code spec
[~50 líneas Lua install_qbcore_override + Citizen.CreateThread monitor]

### 4.2.1 SHA256 utility (NEW v1.0.1 R1 — H003 dependency)
[sha256_hex implementation options + perf budget]

### 4.3 Caveats + edge cases
[QBox API surface diffs, multi-framework abort, hot-reload idempotency, external monkey-patches]
```

**Spec ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:311-422` (§4 entera).

### AFTER (DRAFT v0.2 R2)

Sección DEPRECATED — contenido preservado para audit trail histórico bajo blockquote, reemplazada por §4' siguiente.

```markdown
## 4. Core Override module — DEPRECATED Phase 5 pivot (2026-05-12)

> **Status:** DEPRECATED — Phase 5 architectural pivot Founder LOCKED 2026-05-12.
>
> Esta sección describía el módulo Core Override (monkey-patch runtime de
> `Player.Functions.AddMoney/RemoveMoney/SetMoney/GetMoney` en QBox/QBCore).
> El modelo "parásito invisible" fue abandonado por bloqueos arquitectónicos
> insuperables (FiveM resource-boundary serialization, third-party scripts
> ignoran return values, admin tooling Lua-isolated, qb-core patch GPL-coupling).
>
> **Reemplazo canónico:** §4' Server-to-Server Integration API surface (abajo).
> **Design SSoT:** `@docs/design/04_sonar_bank_api.md` v0.2.
> **Phase 4 freeze baseline:** commit `c4ea87a` (rollback point).
> **Migration path operator-side:** `@MIGRATION.md` + `/sonar_scan_legacy` helper.
>
> Contenido original v1.0.1 R1 preservado en bloque siguiente para audit trail.
> NO consume este pseudo-código; queda como artefacto histórico únicamente.

<details>
<summary>Audit trail — contenido §4 v1.0.1 R1 (DEPRECATED, do not consume)</summary>

[contenido §4.1 + §4.2 + §4.2.1 + §4.3 preservado verbatim aquí]

</details>
```

**Notas implementación amendment:**

1. Contenido verbatim del §4 v1.0.1 R1 (líneas 311-422) preservado dentro del `<details>` HTML — Markdown estándar soporta esto. Sirve audit trail post-LOCK sin contaminar lectura primaria.
2. NO se borran las líneas — se envuelven en blockquote DEPRECATED + `<details>` collapsible.
3. SHA256 utility §4.2.1 también queda dentro del `<details>` — NO se elimina referencia pero NO se consume.

---

## 3. §4' — Server-to-Server Integration API surface — **NEW (replaces §4)**

### Propuesta inserción canónica (post §3.3.1 UUID entropy, pre §5 Lite Mode)

```markdown
## 4'. Server-to-Server Integration API surface (NEW v1.0.2 R2 — Phase 5 pivot)

### 4'.1 Modelo arquitectónico

SONAR Bank es un **ecosistema cerrado** en estilo ox_inventory (Overextended).
Los recursos third-party que mutan dinero NO interceptan funciones nativas del
framework — invocan explícitamente la superficie pública de exports SONAR
Bank documentada en `@docs/design/04_sonar_bank_api.md` v0.2.

**Cobertura de la superficie pública:**

- **Tier 1 (11 exports)** — mutaciones day-to-day (`AddMoney`, `RemoveMoney`,
  `CanAfford`, `GetBalance`, `TransferBySource`, `TransferByIban`) + 5
  `*ByCitizen` siblings para players offline (Q6 LOCKED).
- **Tier 2 (10 exports)** — admin/operator (`AdminCredit`, `AdminDebit`,
  `AdminSetBalance`, `Freeze`, `Unfreeze`) polymorphic en `target =
  source | citizen_id` (Q6 LOCKED). Tier 2 admite `opts.allow_overdraft =
  true` (Q5 LOCKED, único caso).
- **Tier 3 (internal)** — servicios bancarios consumidos sólo por Tier 1/2
  wrappers; no exportados a third parties.

### 4'.2 Boundary conversion convention (Q1 LOCKED split)

| Surface | Convention | Status |
|---|---|---|
| Exports surface (Tier 1/2) | INTEGER minor units | NEW Phase 5 |
| Service layer internal math | INTEGER minor units | Boundary conversion at wrapper |
| DB `sonar_bank_*` money columns | DECIMAL(19,2) major units | LOCKED Phase A (no touch) |
| Callbacks C001-C040 (LEGACY) | DECIMAL major units | LOCKED C-BE-02 (no touch Phase A) |
| Frontend display + input | DECIMAL major units | LOCKED Phase A (no touch) |

Helpers de boundary canonical `sonar_bank_app/server/lib/units.lua`:

- `units.to_minor(decimal_string|number) -> integer_minor` (HALF_UP rounding).
- `units.from_minor(integer_minor) -> decimal_string` (lossless representation
  para INSERT/UPDATE DB DECIMAL).

Helpers **mandatory** en el edge de cada wrapper Tier 1/2 (`to_minor` al
recibir input externo, `from_minor` al invocar service layer + DB layer + a
`Bridges.Player` events que esperan DECIMAL major).

Phase A+1 migra DB + callbacks + Frontend a INTEGER minor end-to-end —
roadmap canonical `@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`.

### 4'.3 Attack surface model

FiveM server-side `exports` son **invocables únicamente por otros recursos
server-side**. Clients no tienen canal directo. Por tanto:

- NO se usa HMAC / JWT / signed tokens en la superficie exports — sería
  theater (cualquier recurso server-side es equally trusted por el FiveM
  runtime).
- SÍ se usa `GetInvokingResource()` para audit (campo `invoker_resource`
  del shape canónico §1.2 C-SEC-01) y — para Tier 2 admin exports — para
  allowlisting opcional vía convar `sonar:admin_allowlist` (Q4 LOCKED no
  shim; allowlist es defensa adicional, no requisito).
- Client-triggered flows (NUI buttons, in-game commands) siguen pasando
  exclusivamente por `sonar:bank:*` net events / ox_lib callbacks con ACL +
  rate limit + ownership checks (LOCKED C-BE-02). Esa capa NO cambia.

| Surface | Callable from client? | Validation |
|---|---|---|
| `exports.sonar_bank_app:*` (Tier 1/2) | NO | Strict arg checks + boundary helpers + audit |
| `sonar:bank:*` callbacks (Tier 3 fronts) | YES (via NUI) | ACL + rate limit + ownership + idempotency |
| Direct SQL | NO (DB only) | Not exposed |

### 4'.4 Mirror to framework wallet (best-effort, no auth gate)

Cada mutación Tier 1/2 que afecte saldo invoca atomicamente
`publish_balance_update(citizen_id, balance_major_decimal, account_class, opts)`
(C-BE-05 §2.2.1 canonical helper, NetEvent CP1-B post-M004 R1) — ver
`@docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md:109-149`.

Adicionalmente, `sonar_bridges/server/core_override.lua` se simplifica a
~150-200 líneas y conserva ÚNICAMENTE:

- `MirrorSync.SetBalance(citizen_id, balance_decimal, opts)` — best-effort
  push al wallet del framework activo (`players.money.bank` qb-core,
  `accounts.bank` ESX) post-mutation. Mirror failure NO bloquea la mutation —
  SONAR ledger es authoritative; mirror retry on player next login.
- `QBCore:Server:PlayerLoaded` + ESX + QBox equivalents login handlers para
  trigger initial mirror sync al rejoin.
- `Reconcile.Enqueue(citizen_id, drift_minor, reason)` — public API surface,
  consumida posiblemente Phase A+1 cuando se implemente reconciliation full.

**REMOVED del module simplificado (era parte de §4 Core Override DEPRECATED):**

- `install_qbcore_player` + wrappers + TRAP `__index`/`__newindex`.
- Sentinel triple-defense + SHA256 checksum + probe `_G._sonar_core_override_probe`.
- `state.in_flight`, `mirror_reason`, `consume_mirror_token`,
  `parse_mirror_token`.
- `OnMoneyPreHook` export (consumer qb-core local patch desinstalado Phase 3.1).
- Watchdog drift detection thread tier 1/2/3.
- `VerifyIntercept`, `GetCoreOverrideHealth` exports.
- `RegisterCommand('sonar_test_forge', ...)` dev probe.
- `RegisterCommand('mirror_sync_now', ...)` (no auto-mirror).
- QBox `registerHook` blocks (Phase 4 attempt abandonado).
- ESX observer blocks (Phase 4 attempt abandonado).

### 4'.5 Migration path operator-side (referencia)

Phase 5 NO ships `sonar_compat` shim (Q4 LOCKED — DROP definitivo). El
operador del server migra cada recurso third-party explícitamente:

- `MIGRATION.md` top-level (Phase 4.7 implementation) con tabla
  `OLD → NEW` para 20+ recursos comunes (qb-vehicleshop, qb-banking, ...).
- `/sonar_scan_legacy` dev command (Phase 4.8) — grep resources cargados
  buscando `Functions\.(Add|Remove|Set)Money.*bank`, `exports.qbx_core:`,
  `xPlayer\.(add|remove)(Money|AccountMoney)` → reporte por recurso.

Forzar migración explícita es **security-positive**: el operador adquiere
visibilidad completa de qué scripts tocan banco.
```

**Acción en LOCK promotion:**

- Insertar §4' completo post-§3.3.1 entropy spec, pre-§5 Lite Mode header.
- Renumerar referencias internas si alguna citaba §4 (verificar §8 watchdog + §9 FSM — la mayoría apuntan a CP4 detect framework, no Core Override).
- Verificar TOC al inicio del documento — añadir línea "§4'. Server-to-Server Integration API surface".

---

## 4. Side effects en otras secciones C-BE-04

### 4.1 §8 Watchdog spec — minor edit

C-BE-04 §8 actualmente puede referenciar Core Override drift detection (métrica C indirect). Revisar líneas que citen "Core Override" en §8 y eliminar referencia (o sustituir por "framework adapter health"). El watchdog **general** (Bridges health, framework detect, idempotency lifecycle FSM #8) PRESERVADO sin cambio semantic.

### 4.2 §9 Status FSM — sin cambio semantic

Las 4 transitions de Bank Status FSM (`native_full / lite_mode_active / compromised_load_order / framework_missing`) preservadas verbatim. La transition `native_full` en post-Phase 5 significa "framework detected + healthy adapter + mirror sync online" — NO "Core Override sentinel verified". Documentación textual de la transition ajustable durante LOCK ceremony.

### 4.3 Glosario — NEW entries

Añadir al final del documento sección "Glosario v1.0.2 R2":

- **Exports Tier 1:** superficie pública de 11 exports server-side para
  recursos third-party mutar dinero (`AddMoney`, `RemoveMoney`, etc.).
- **Exports Tier 2:** superficie admin/operator de 10 exports server-side
  con ACE + allowlist gates.
- **Boundary helper:** función `to_minor`/`from_minor` de
  `sonar_bank_app/server/lib/units.lua` para convertir entre INTEGER minor
  (exports surface) y DECIMAL major (DB + callbacks + Frontend).
- **MirrorSync (Phase 5 simplified):** mecanismo best-effort para
  sincronizar el wallet del framework activo con el saldo SONAR
  authoritative — NO es el ledger primary.

---

## 5. Compat existing code

| Componente | Impacto | Acción operator-side |
|---|---|---|
| `Bridges.Bank.AddMoney / RemoveMoney / Transfer` API §3.1 | ZERO breaking | None — sigue funcionando idem v1.0.1 R1. |
| `Bridges.BankStatus.Transition` H002 R1 gate | ZERO breaking | None. |
| `Bridges.UUID.v4` PRNG entropy M002 R1 | ZERO breaking | None. |
| Lite Mode Capa A/B/C ESX 1.10+ | ZERO breaking | None — Lite Mode preservado. |
| Mutex Echo lib + Reconciliation pipeline | ZERO breaking | None. |
| **Core Override module §4** | **REMOVED runtime** | qb-core local patch revert (Phase 3.1) + `core_override.lua` simplification (Phase 3.2). |

---

## 6. Sign-off proposal Round 2

| Role | Sign-off requerido | Notas |
|---|---|---|
| Founder yaboula | ✅ Sí | LOCK promotion authority. Base ya emitida en `founder_phase_5_pivot_q1_q8_2026_05_12.md` (Q1-Q8 + §9). |
| Backend Lead Phase 5 | ✅ Sí self-attest | Esta DRAFT v0.1. |
| Security Lead (BANK-SEC.2 absorbs) | ✅ Sí consumer review | Foco: §4' attack surface table + audit hook integration (cross-ref C-SEC-01 amendment). |
| PM Cascade | ✅ Sí promote ceremony | Ejecuta `/lock-contract` workflow Phase 2. |

Sign-off matrix completo en `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/sign_off_matrix.md`.

---

## 7. LOCK promotion path

```
DRAFT v0.1 (este file) →
REVIEW window founder + Security Lead BANK-SEC.2 →
SIGNOFF triple (Founder + Backend Lead self-attest + Security consumer + PM promote) →
LOCK v1.0.2 R2 atomic in-place patch (apply NULLIFY §4 + INSERT §4' + minor §8/§9 edits + glosario) →
Update v1.0.1 R1 → v1.0.2 R2 header + immutability stamp →
SESSION_LOG entry BANK-BE.PHASE_5.1 Phase 2 LOCK →
Archive este DRAFT a `.archived_be_phase_a_phase_5_pivot_r2_v0_1_promoted_v1_0_2_R2/`.
```

---

## 8. References

- Founder LOCK Q1-Q8 + §9: `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md`.
- Prompt activación: `@docs/agents/teams/prompts/08_phase_5_ecosystem_api_backend_lead.md` (§4 Phase 1 spec).
- Design SSoT Phase 5: `@docs/design/04_sonar_bank_api.md` v0.2 (Phase 1.8 same package).
- C-BE-04 LOCKED v1.0.1 R1: `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md`.
- Phase 4 freeze baseline: commit `c4ea87a`.
- Precedente formato amendment: `@docs/agents/teams/amendments/.archived_be_phase_a_r1_v0_2_promoted_v1_0_1_R1/AMEND-C-BE-04-r1-v0.2.md`.

— Backend Lead Phase 5 (BANK-BE.PHASE_5.1)
2026-05-12
