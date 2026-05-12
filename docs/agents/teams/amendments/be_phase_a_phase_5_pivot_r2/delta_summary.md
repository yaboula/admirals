# Phase 5 Pivot Round 2 — Delta Summary (DRAFT v0.1)

> **Package:** `docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/`
> **Status:** 🟡 DRAFT v0.1 PENDING-SIGNOFF.
> **Sesión emisora:** `BANK-BE.PHASE_5.1` Phase 1 — 2026-05-12.
> **Authority:** Founder LOCK Q1-Q8 + §9 — `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md` v1.0.
> **Scope:** 4 contratos LOCKED v1.0.1 R1 → propuesta v1.0.2 R2 (atomic in-place patch post sign-off triple).

---

## 1. Cross-contract delta tabular

| Contract | § | Before R1 (v1.0.1 LOCKED) | After R2 (v1.0.2 DRAFT) | Severity | Impact |
|---|---|---|---|---|---|
| **C-BE-04** | §4 Core Override module entera (`@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:311-422`, ~111 líneas) — §4.1 approach + §4.2 pseudo-code spec install_qbcore_override + §4.2.1 SHA256 utility + §4.3 caveats | **NULLIFY** — sección DEPRECATED bajo blockquote + `<details>` collapsible preservando contenido verbatim para audit trail. NO consume runtime. | MAJOR | Backend runtime: `core_override.lua` simplifica de 980 líneas a ~150-200 líneas (Phase 3.2 cleanup). qb-core local patch revertido (Phase 3.1, founder-side fuera workspace). |
| **C-BE-04** | §4' Server-to-Server Integration API surface | **NEW** — modelo arquitectónico Phase 5 + Tier 1/2/3 segregation + §4'.2 boundary convention split (Q1) + §4'.3 attack surface model + §4'.4 mirror simplified (best-effort, NO auth gate) + §4'.5 migration path operator-side (Q4 NO shim). Apunta a design SSoT `@docs/design/04_sonar_bank_api.md` v0.2. | MAJOR | Documenta superficie pública contractual NEW + boundary helpers mandate + AP cleanup. |
| **C-BE-04** | §8 Watchdog spec — referencias a Core Override drift detection | Edit minor — eliminar referencias específicas Core Override drift; preservar watchdog general (Bridges health + framework detect + idempotency lifecycle FSM #8). | MINOR | Watchdog runtime preservado funcionalmente. |
| **C-BE-04** | §9 Status FSM — descripción transition `native_full` | Edit textual — `native_full` ahora significa "framework detected + healthy adapter + mirror sync online", NO "Core Override sentinel verified". 4 transitions FSM preservadas verbatim. | MINOR | Sin cambio runtime (FSM logic same). |
| **C-BE-04** | Glosario fin documento | **NEW** — entries Exports Tier 1, Exports Tier 2, Boundary helper, MirrorSync (Phase 5 simplified). | MINOR | Doc clarity. |
| **C-BE-02** | §1.2 NEW principles — A9-A17 | **EXTEND** — añadir A18 Boundary convention split (Q1 LOCKED). Documenta INTEGER minor exports surface vs DECIMAL major callbacks/DB/Frontend Phase A. | MAJOR additive | Introduces boundary convention contract. ZERO breaking callbacks LOCKED. |
| **C-BE-02** | §3.1 Error codes registry tabla canonical | **EXTEND** — añadir 1 fila `PLAYER_NOT_LOADED` (HTTP 423) con `retry_after_event` hint (Q8 LOCKED). | MINOR additive | Backwards compatible (callers tienen default branch); distingue de `PLAYER_NOT_FOUND`. |
| **C-BE-02** | §NEW.10 — Server-to-Server Exports surface (post §9 callbacks LOCKED end) | **NEW SECTION ENTERA** — modelo + alcance §10.1 + boundary helpers §10.2 + Tier 1 tabla 11 exports §10.3 + opts schema §10.3.2 + Tier 2 tabla 10 exports §10.4 + `opts.allow_overdraft` Q5 + `Auth.RequireAdmin` helper + rigid fees Q7 + atomic guarantees §10.6 + side effects table §10.7 + `GetApiVersion` informational §10.8 + perf budgets §10.9. | MAJOR additive | NEW public ecosystem API surface. ZERO breaking callbacks C001-C040+C001b LOCKED v1.0.1 R1. |
| **C-BE-05** | §2.2.1 body canonical helper `publish_balance_update` | **PRESERVED VERBATIM** — signature unchanged Phase A path (a) Founder §9 LOCKED. | NONE | Frontend consumers no touch. |
| **C-BE-05** | §2.2.1.A — Tier 1/2 exports wrapper consumer pattern | **NEW** — boilerplate canonical wrapper invoke `publish_balance_update(cid, balance_major_decimal, account_class, opts)` post-COMMIT, UNA call per `account_class` afectado. AP-CP1-1 reaffirmed para superficie exports. | MINOR | Documenta consumer pattern obligatorio Tier 1/2. |
| **C-BE-05** | §2.2.1.B — Value type Phase A LOCKED | **NEW** — path (a) Founder §9 ratified — wrapper convierte INTEGER minor → DECIMAL major vía `units.from_minor()` antes del helper invoke. Phase A+1 migra holistically. | MINOR | Resuelve conflict Q1 ↔ Q2 documentalmente. ZERO Frontend touch. |
| **C-BE-05** | §1.5 + §2.4 anti-patterns AP-CP1-1 | **PRESERVED VERBATIM** — REAFFIRMED en §2.2.1.A para Tier 1/2 wrappers. | NONE | Mandate persiste. |
| **C-BE-05** | §4.2 update on mutation | Edit minor — añadir cross-ref nota a §2.2.1.A consumer pattern Phase 5. | MINOR | Doc clarity. |
| **C-SEC-01** | §1.1 Principios AH1-AH3 | **EXTEND** — añadir AH4 Atomic same-TX mandate (cross-decision #2 Founder). Audit insert vive dentro mismo SQL TX que balance mutation + movement append + idem upsert. NO `audit_complete` async path para Tier 1/2 exports. | MINOR | Reaffirms LOCKED behavior; explicit para superficie exports surface. |
| **C-SEC-01** | §1.2 Tabla hooks canonical (12 rows) | **EXTEND** — añadir 1 NEW row `audit_hook_bank_overdraft` (event_type `bank_overdraft`, severity HIGH). Q5 LOCKED. | MINOR additive | Distingue admin debit normal vs overdraft authorized. Dispara AR-P05 LOCKED. |
| **C-SEC-01** | §1.2.A — Tier 1/2 exports audit shape canonical 10-field | **NEW SUBSECTION** — confirma 10-field shape aplica a 22 exports + atomic insert ordering wrapper SQL TX (balance + movement + audit + idem upsert) + bank_transfer 2-row pattern + `previous_flag_snapshot` JSON shape canonical para freeze/unfreeze/overdraft. | MINOR | Documenta scope explícito Phase 5. ZERO breaking shape LOCKED. |
| **C-SEC-01** | §3 C-SEC-03 Autoraise Rules | **NO MODIFICATION** — `bank_overdraft` event_type dispara AR-P05 admin override existing. Cross-ref nota únicamente. | NONE | Autoraise infrastructure unchanged. |
| **C-SEC-01** | DB column type confirm | Pendiente DB Lead consult Phase 2 — `sonar_audit_log.delta_minor` posible BIGINT migration si actual DECIMAL. | TBD | Possible migration si schema actual no soporta BIGINT. Phase A+1 holistic. |

---

## 2. Severity rollup

| Severity | Count | Contracts |
|---|---|---|
| **MAJOR** (NULLIFY + replace OR new public contractual surface) | 4 | C-BE-04 §4 NULLIFY + §4' NEW + §4 (legacy nota glosario), C-BE-02 §1.2 A18 + §NEW.10 |
| **MINOR additive** (enum entries, scope clarifications, helpers reaffirmed) | 8 | C-BE-04 §8/§9/glosario, C-BE-02 §3.1 PLAYER_NOT_LOADED, C-BE-05 §2.2.1.A/§2.2.1.B/§4.2, C-SEC-01 §1.1 AH4 + §1.2 audit_hook_bank_overdraft + §1.2.A |
| **NONE / preserved verbatim** | 5 | C-BE-04 §3 Bridges API + Lite Mode §5 + Mutex §6 + Reconciliation §7, C-BE-05 §1 + §2.1/§2.2/§2.2.2/§3/§4, C-BE-02 callbacks C001-C040+C001b LOCKED, C-SEC-01 §1.3 shape base + §2 ACE matrix + §3 AR-P01..P05, C-BE-04 §3.2.1 BankStatus.Transition gate + §3.3.1 UUID entropy |
| **TBD pendiente DB Lead consult** | 1 | C-SEC-01 `sonar_audit_log.delta_minor` BIGINT confirm |

---

## 3. Breaking changes for downstream consumers

| Consumer | Breaking? | Notes |
|---|---|---|
| Frontend (`web-src/`) | **NO** | Path (a) preserves DECIMAL major end-to-end Phase A. Callbacks LOCKED v1.0.1 R1 unchanged. New error code `PLAYER_NOT_LOADED` is purely server-side exports surface (Frontend no consume). |
| Existing callbacks consumers (Frontend NUI flows) | **NO** | C001-C040 + C001b signatures + auth + error codes + idempotency LOCKED v1.0.1 R1 preservados. |
| Third-party resources currently using qb-core/QBox/ESX native money APIs | **YES (operator migration explicit Q4 LOCKED)** | NO `sonar_compat` shim — operator MUST migrate cada recurso vía `MIGRATION.md` + `/sonar_scan_legacy`. |
| `sonar_bridges/server/core_override.lua` | **YES (cleanup Phase 3.2)** | 980 líneas → ~150-200. Removed: install_qbcore_player + sentinel + watchdog drift + probe. Preserved: MirrorSync.SetBalance + login handlers + Reconcile.Enqueue. |
| qb-core local patch (founder-side, fuera workspace) | **YES (cleanup Phase 3.1)** | 4 hunks revert (helper block + AddMoney/RemoveMoney/SetMoney pre-hook lines). |
| Audit infrastructure (`sonar_audit_log` table consumers — Audit Explorer V4, Compliance V5) | **NO** | Shape 10-field LOCKED preservado. NEW event_type `bank_overdraft` displayable via existing infrastructure (i18n key add `audit.event.bankOverdraft` Phase A+1 si necesario). |
| StateBag/NetEvent consumers (`web-src/src/lib/bankStateBags.ts` + `sonar:bank:balance:update` handlers) | **NO** | Path (a) preserves DECIMAL major payload. Phase A+1 migrates holistically. |

---

## 4. Implementation gates post sign-off (Phase 3 + 4 references)

| Gate | Phase | Reference |
|---|---|---|
| qb-core local patch revert (founder-side instructions) | 3.1 | `@docs/agents/teams/prompts/08_phase_5_ecosystem_api_backend_lead.md:236-244` |
| `core_override.lua` simplification 980→~150-200 lines | 3.2 | Prompt §4 Phase 3.2 + C-BE-04 §4' R2 mandate |
| Delete `credit_command.lua` Phase 4 dev artifact | 3.3 | Prompt §4 Phase 3.3 |
| `units.lua` boundary helpers + property tests | 4.1 | Q1 LOCKED + C-BE-02 §NEW.10.2 |
| Migration `036_sonar_bank_idem.sql` + cron purge 24h TTL | 4.2 | C-BE-02 §NEW.10.3.2 + cross-decision #3 |
| `public_api.lua` 11 Tier 1 exports | 4.3 | C-BE-02 §NEW.10.3 |
| `admin_api.lua` 10 Tier 2 exports + `Auth.RequireAdmin` + allowlist convar | 4.4 | C-BE-02 §NEW.10.4 |
| `Bridges.Identity.IsLoaded(source)` helper | 4.5 | Q8 LOCKED + PLAYER_NOT_LOADED detection |
| Integration tests `/sonar_test_export_*` dev harness | 4.6 | Prompt §4 Phase 4.6 |
| `MIGRATION.md` operator guide + 20 recursos comunes | 4.7 | Q4 LOCKED |
| `/sonar_scan_legacy` helper | 4.8 | Q4 LOCKED |
| ST-024.1-10 smoke harness | 5.1 | Prompt §4 Phase 5.1 |
| `progress/PHASE_5_VALIDATION.md` founder manual | 5.2 | Prompt §4 Phase 5.2 |

---

## 5. Out of scope (explicit)

- DB column migrations DECIMAL → BIGINT (`sonar_bank_accounts.balance`, `sonar_bank_movements.amount`, etc.) — **Phase A+1** (`@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`).
- Callbacks C001-C040 + C001b signature migration to INTEGER minor — **Phase A+1**.
- Frontend types + queries + mutations + `useI18n().money()` semantic change — **Phase A+1**.
- StateBag/NetEvent payload `balance` field type DECIMAL→INTEGER migration — **Phase A+1**.
- Reconciliation full pipeline post-deploy boot + periodic — **Phase A+1** (cross-decision #4).
- `sonar_compat` Python auto-fixer script para clientes B2B futuros — **Phase A+N indefinite, no commitment**.

---

## 6. References

- Founder LOCK: `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md` v1.0.
- Prompt: `@docs/agents/teams/prompts/08_phase_5_ecosystem_api_backend_lead.md` §4 Phase 1.5.
- Design SSoT: `@docs/design/04_sonar_bank_api.md` v0.2 (Phase 1.8 same package).
- Roadmap Phase A+1: `@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md` (Phase 1.7 same package).
- 4 amendment proposals: this directory `c_be_04`/`c_be_02`/`c_be_05`/`c_sec_01_amendment_proposal_v0_1.md`.
- Sign-off matrix: `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/sign_off_matrix.md` (Phase 1.6 same package).

— Backend Lead Phase 5 (BANK-BE.PHASE_5.1)
2026-05-12
