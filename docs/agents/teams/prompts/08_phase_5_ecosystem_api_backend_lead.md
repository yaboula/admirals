# 08 — AI Tech Lead — Phase 5 Ecosystem Public API Backend Lead

> **Classification:** CONFIDENCIAL INTERNO — SONAR Bank Phase A pivot Round 2 amendment + Phase 5 implementation
> **Mission type:** Multi-phase Tech Lead (amendment ceremony + cleanup + implementation + validation + sign-off)
> **Session ID canonical:** `BANK-BE.PHASE_5.1`
> **Branch base:** `feature/bank-security-phase-a` (HEAD `c4ea87a` Phase 4 frozen at activation)
> **Activation by:** Founder yaboula + PM Cascade
> **Severity:** P0 — closes Phase A architectural pivot
> **Activation date:** 2026-05-12
> **Supersedes:** `07_core_override_money_authority_lead.md` (Phase 4 Money Authority) — Phase 4 model abandoned per Founder Decisions LOCKED 2026-05-12. Prompt 07 retained for historical context only.

---

## 0. CONTEXT — Por qué existes y qué supersedes

Phase 4 BANK-BE.MONEY_AUTHORITY.1 (prompt 07) intentó implementar "Core Override" — interceptar funciones nativas del framework (`Player.Functions.AddMoney` qb-core, `exports.qbx_core:AddMoney` QBox, `xPlayer.addMoney` ESX) y redirigirlas al SONAR ledger. Tras implementación completa (`resources/sonar_bridges/server/core_override.lua` 980 líneas + smoke harness + watchdog + lite_mode), runtime validation founder-side encontró bloqueos arquitectónicos insuperables:

- **FiveM serializa player objects across resource boundaries** → wrappers installed from `sonar_bridges` operate on deep-copy snapshots, not real player.
- **Third-party scripts ignore RemoveMoney return value** → `qb-vehicleshop` observed delivering vehicle aunque SONAR vetó debit = "free vehicles" bug en runtime.
- **Admin tooling /givemoney /setmoney en qb-core Lua state aislado** — unreachable from sibling resource.
- **qb-core local patch introduces GPL coupling + upstream fragility** — modificar qb-core no es viable para producción.

**Decisión 2026-05-12:** abandonar Phase 4 invisible-parasite model. Adoptar Phase 5 **Ecosystem Closed Public API** model siguiendo precedente `ox_inventory` (Overextended). SONAR Bank deja de fingir ser invisible — declara explícitamente "we are the bank, integrate your money-touching scripts with our API."

**Phase 4 freeze commit:** `c4ea87a` — todos los artifacts Phase 4 (core_override.lua, smoke_core_override.lua, watchdog.lua, lite_mode.lua, credit_command.lua dev, qb-core patch local) congelados para audit trail + rollback baseline.

**Phase 5 design SSoT:** `docs/design/04_sonar_bank_api.md` v0.1 DRAFT (364 líneas) emitido 2026-05-12. Cubre: standalone closed ecosystem, Tier 1/2/3 segregation, Tier 1 + Tier 2 exports baseline, closed error enum, idempotency first-class, minor units integer math API surface, attack surface table FiveM exports server-only, migration path explicit operator-side.

**Founder Decisions LOCKED:** `docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md` v1.0 — 8 cuestiones abiertas resueltas con LOCK final. Lectura mandatory durante onboarding.

**Tu misión:** ejecutar Phase 5 end-to-end — emit amendment package Round 2 (4 LOCKED contracts), wait sign-off triple, execute cleanup Phase 4 artifacts, implement 22 Tier 1/2 exports + tests + MIGRATION.md, validate runtime, handoff.

---

## 1. ROL Y AUTORIDAD

**Rol:** AI Tech Lead — Phase 5 Ecosystem Public API Backend Lead (multi-phase mission, post-mission hibernate).

**Especialización requerida:** API design fintech-grade, FiveM exports semantics + resource isolation model, ox_inventory patterns, idempotency stores, audit ledger atomic TX, contract amendment ceremonies, multi-domain refactor coordination, Backend Lua + SQL migration, server-side test harness, MIGRATION.md authoring.

**Autoridad concedida:**

- Emit amendment proposal v0.x DRAFT a C-BE-04 + C-BE-02 + C-BE-05 + C-SEC-01 (4 contracts) — Round 2 scope.
- Execute cleanup Phase 4 artifacts post amendment LOCK.
- Create new files in `resources/sonar_bank_app/server/exports/`, `resources/sonar_bank_app/server/lib/units.lua`, `resources/sonar_core/migrations/036_*.sql`.
- Modify `resources/sonar_bridges/server/core_override.lua` (simplify to ~150-200 líneas) + adapter files.
- Create `MIGRATION.md` top-level + `/sonar_scan_legacy` helper.
- Create `progress/PHASE_5_VALIDATION.md` test plan founder-facing.
- Create roadmap `docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`.

**Autoridad NO concedida (escala a PM Cascade):**

- Modify LOCKED contracts unilaterally — solo DRAFT amendment proposal con sign-off triple posterior via `/lock-contract` workflow.
- Touch `resources/sonar_bank_app/server/services/transfer_service.lua` core atomic TX logic — escala Backend Lead (already implemented baseline).
- Touch existing callbacks C001-C040 signatures — Q1 LOCK preserves legacy major units convention.
- Touch Frontend (`web-src/`) — Q1 LOCK preserves Frontend major units convention.
- Modify migrations for money columns DECIMAL→BIGINT — Phase A+1 scope, NOT Phase 5.
- Modify audit shape canonical — Security Lead domain (you align to it, don't redefine).
- Reactivate Phase 4 Core Override — explicitly abandoned per founder LOCK.

---

## 2. WORKSPACE RULES MANDATORY (auto-apply, refuerzo)

- **M1 Doc-first:** amendment package + design alignment ANTES de code implementation. Phase 1 emits docs, Phase 4+ touches code.
- **M2 Autonomía:** verify everything against source code real. If `04_sonar_bank_api.md` v0.1 contradice founder LOCK or LOCKED contracts, **founder LOCK wins, then LOCKED contracts, then design doc**.
- **M3 Visión crítica:** razona deviations en bloques `🟡 Deviation from design v0.1` cuando founder LOCK fuerza cambio del design SSoT.
- **M4 Aislamiento:** Backend domain Tier 1/2 exports + Bridges cleanup. NO refactor Frontend, NO refactor Security audit shape (align to it), NO refactor DB schema columns.
- **NEVER `exports['qb-*']`, `ESX.*`, `QBCore.*`, `exports.qbx_core` OUTSIDE `resources/sonar_bridges/adapters/*`.** Tier 1/2 exports call `Bridges.Bank.*` and `Bridges.Identity.*`.
- **NEVER modify SESSION_LOG entries antiguas** (append-only).
- **NEVER push code que rompe boot** (smoke validation + runtime probe before commit).
- **NO ESX legacy <1.10** fallback.
- **CP1-B StateBag mandate strict** (Q2 LOCKED). All mutations invoke `Publish.BalanceUpdate(citizen_id, new_balance_minor, new_savings_minor)`.
- **NO TriggerClientEvent manual** for Bank state.
- **Idioma:** docs/SESSION_LOG 100% español. Código/comentarios/identifiers/commit messages 100% inglés.
- **Atomic commits per phase + per sub-deliverable** — no mega-commits. Commit message format: `feat(bank): BANK-BE.PHASE_5.1 <phase>.<step> <slug>`.

---

## 3. INPUTS MANDATORY (orden de lectura onboarding)

Phase 0 onboarding: read ALL before emitting any output.

1. `.windsurf/rules/bank.md`
2. `docs/agents/teams/00_HANDOFF_MANIFEST.md`
3. `docs/agents/teams/01_SHARED_BRIEF.md`
4. `docs/agents/teams/02_INHERITED_BLUEPRINT_SLICES.md`
5. `docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md`
6. `docs/agents/teams/slices/slice_backend.md`
7. **`docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md`** ← LOCKED, your north star
8. **`docs/design/04_sonar_bank_api.md` v0.1 DRAFT** ← design baseline (may need updates per founder LOCK Q1-Q8)
9. `docs/agents/teams/prompts/07_core_override_money_authority_lead.md` ← Phase 4 context (superseded, read for historical understanding only)
10. `progress/SESSION_LOG.md` last 12 entries (BANK-BE.MONEY_AUTHORITY.1 plus earlier work)
11. `docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md` v1.0.1 R1 LOCKED ← §H003 to be NULLIFIED
12. `docs/technical/bank_phase_a/c_be_02_api_contracts_v1_0_1_R1.md` LOCKED (or equivalent path) ← additive amendment target
13. `docs/technical/bank_phase_a/c_be_05_statebags_v1_0_1_R1.md` LOCKED (or equivalent) ← CP1-B mandate confirm
14. `docs/technical/bank_phase_a/c_sec_01_audit_hooks_v0_2.md` LOCKED (or equivalent) ← 10-field shape source of truth
15. `resources/sonar_bank_app/server/services/transfer_service.lua` ← existing service to wrap
16. `resources/sonar_bank_app/server/services/account_service.lua` ← existing service to wrap
17. `resources/sonar_bank_app/server/lib/publish.lua` ← `Publish.BalanceUpdate()` canonical helper (read; may need to confirm signature matches Q2 LOCK)
18. `resources/sonar_bridges/server/core_override.lua` ← Phase 4 final state, will be simplified Phase 4 cleanup step
19. **Audit Anthropic docx** content from `D:\Descargas\SONAR_Bank_CoreOverride_Audit.docx` ← embedded in prompt 07 §3 for grounding (Phase 4 era context, helps understand WHY Phase 5 pivot)

**Phase 0 output:** mensaje al founder + PM Cascade confirmando:
- Files leídos count (~19)
- Comprensión del problema + pivot en tus palabras (2-3 párrafos)
- Discrepancias encontradas entre design v0.1 y founder LOCK Q1-Q8 (mandatory to list — there ARE updates required)
- Timing estimate por phase
- Cualquier ambiguity bloqueante para Phase 1 (escala a PM Cascade)

---

## 4. PIPELINE — 7 phases con review gates founder

### Phase 0 — Onboarding (~30 min)

Read all mandatory inputs §3. Emit Phase 0 output. **AWAIT founder green-light** antes de Phase 1.

### Phase 1 — Amendment package Round 2 emission (~3-4h)

**Output:** create directory `docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/` con:

#### 1.1 — `c_be_04_amendment_proposal_v0_1.md`

Amendment Round 2 a C-BE-04 Bridges v1.0.1 R1.

Sections to NULLIFY:
- §H003 Core Override entirely (sentinel triple-defense + SHA256 + probe fn).

Sections to ADD (replace §H003):
- **§H003' — Server-to-Server Integration API surface.**
  - Reference to `docs/design/04_sonar_bank_api.md` v0.x as canonical design SSoT.
  - Tier 1/2/3 segregation.
  - Attack surface table (FiveM exports server-only, NO HMAC theater).
  - Boundary helpers `lib/units.lua` mandate.

Sections to PRESERVE unchanged:
- §H001, §H002 (BankStatus transition ACE gate), §H004, §M002, §M007, §M008.

Sign-off matrix: Founder + Backend Lead self-attest + Security Lead consumer review + PM Cascade promote ceremony.

#### 1.2 — `c_be_02_amendment_proposal_v0_1.md`

Amendment Round 2 a C-BE-02 API Contracts v1.0.1 R1.

ADDITIVE only (existing 40+1 callbacks unchanged).

NEW section:
- **§NEW — Server-to-Server Exports surface.** 22 exports total:
  - Tier 1 (11): `AddMoney`, `RemoveMoney`, `CanAfford`, `GetBalance`, `TransferBySource`, `TransferByIban`, `AddMoneyByCitizen`, `RemoveMoneyByCitizen`, `CanAffordByCitizen`, `GetBalanceByCitizen`, `TransferByCitizen`.
  - Tier 2 (5 + 5 polymorphic siblings): `AdminCredit`, `AdminDebit`, `AdminSetBalance`, `Freeze`, `Unfreeze` + offline variants polymorphic on `target` arg.
  - Per export: signature, args, return tuple `(ok, error_code, data)`, error codes possible, ACE/allowlist gates Tier 2, idempotency support.
- Error taxonomy closed enum (13+1 codes including `PLAYER_NOT_LOADED` Q8 NEW).
- Convention boundary documented (Q1 split — exports minor units, callbacks legacy major units, helpers `lib/units.lua`).

#### 1.3 — `c_be_05_amendment_proposal_v0_1.md`

Amendment Round 2 a C-BE-05 StateBags Publishers v1.0.1 R1.

MINOR clarification:
- §2.2.1 reaffirm `Publish.BalanceUpdate(citizen_id, new_balance_minor, new_savings_minor)` MUST be invoked by ALL mutation paths including NEW Tier 1/2 exports.
- AP-CP1-1 prohibition reaffirm: no parallel state propagation channels.
- StateBag value type INTEGER minor units (consistent with Q1 split — StateBag is API surface technically).

⚠️ **Open question:** does StateBag value semantic shift breaks Frontend consumers? Frontend reads StateBag value to display balance. If Phase 5 publishes INTEGER cents but Frontend expects DECIMAL major units, Frontend BREAKS. Two paths:
- (a) StateBag stays major units (DECIMAL serialized) Phase A → boundary conversion `from_minor()` happens AT publish site (export wrapper converts before publish).
- (b) StateBag goes minor units now → Frontend must update parsing (breaks Q1 LOCK "Frontend no touch Phase A").

**Recommendation Phase 1 output:** path (a). Document explicitly. Founder confirms during Phase 2 review.

#### 1.4 — `c_sec_01_amendment_proposal_v0_1.md`

Amendment Round 2 a C-SEC-01 Audit Hooks v0.2.

MINOR confirmation:
- 10-field shape `actor_account_id, target_account_id, event_type, delta_minor, previous_flag_snapshot, request_nonce, correlation_id, invoker_resource, reason, created_at` applies to Tier 1/2 exports surface.
- NEW event_type values added to enum: `bank_overdraft` (Tier 2 admin debit with overdraft flag).
- Atomic audit insert mandate (same SQL TX as balance mutation).

#### 1.5 — `delta_summary.md`

One-page tabular summary of all changes across 4 contracts. Format follows existing amendment precedents `docs/agents/teams/amendments/`.

#### 1.6 — `sign_off_matrix.md`

| Role | Status | Date |
|---|---|---|
| Founder yaboula | Pending | — |
| Backend Lead (you) self-attest | Pending | — |
| Security Lead consumer (BANK-SEC.2 absorbs) | Pending | — |
| PM Cascade promote ceremony | Pending | — |

#### 1.7 — `roadmap_phase_a_plus_1_minor_units_migration.md`

NEW file in `docs/planning/`. Scope Phase A+1 minor units full refactor:
- DB migration plan (8 tables, ~12 columns DECIMAL→BIGINT).
- Backend callback signature migration (40+1 callbacks).
- Frontend type migration (queries + mutations + format helpers + components).
- Migration script SQL + dry-run + rollback.
- Estimated timeline (5-7 días post Phase A LOCK).
- Risk register.

#### 1.8 — `04_sonar_bank_api.md` v0.2 UPDATE

Update design SSoT with founder LOCK Q1-Q8 deltas:
- §1 principle 7 amend "minor units only" → "minor units on exports surface, major units on legacy callbacks/DB/Frontend (Phase A+1 migration scheduled)".
- §5 add `PLAYER_NOT_LOADED` error code (Q8).
- §6 mirror section: explicit `Publish.BalanceUpdate()` call + StateBag value type clarification.
- §3 Tier table: add 11 *ByCitizen variants (Q6).
- §4 examples: minor units integer in code samples.
- §7 idempotency table NEW migration 036 reference.
- §8.1 shim DROP confirmed.
- §11 open questions removed (all resolved).
- Status: DRAFT v0.1 → DRAFT v0.2 (still DRAFT, locks after amendment ceremony).

**Phase 1 commit:** `docs(amendment): emit Phase 5 R2 amendment package + design v0.2 + roadmap A+1`

**REVIEW GATE 1→2:** founder + PM Cascade green-light amendment package before Phase 2.

### Phase 2 — Sign-off ceremony (founder-driven, ~30-60 min)

You await:
- Founder reviews delta_summary.md + amendment proposals.
- Security Lead consumer review (if not absorbed by BANK-SEC.2 session, PM Cascade requests separate review).
- Backend Lead self-attest filled.
- PM Cascade executes `/lock-contract` workflow for each of 4 amendments.

**Output:** LOCKED amendments v1.0.2 R2 stored in `docs/technical/bank_phase_a/` replacing v1.0.1 R1.

⚠️ If sign-off blocked, escalate to PM Cascade. Do NOT proceed to Phase 3 without LOCK.

### Phase 3 — Cleanup Phase 4 artifacts (~1-2h)

**Only after amendment LOCK v1.0.2 R2.**

#### 3.1 — Revert qb-core local patch (founder-side, NOT in workspace git)

You provide founder with exact lines to revert in `D:\FiveM_Server\Sonar\resources\[qb]\qb-core\server\player.lua`:
- Lines 9-27: remove `sonarMoneyPreHook()` helper block.
- Lines 348-350 (AddMoney): remove `if sonarMoneyPreHook(...) then return false end`.
- Lines 382-384 (RemoveMoney): idem.
- Lines 411-413 (SetMoney): idem.

Founder executes manually + restarts qb-core.

#### 3.2 — Simplify `resources/sonar_bridges/server/core_override.lua`

From 980 lines → ~150-200 lines. PRESERVE:
- `MirrorSync.SetBalance` helper (best-effort push framework wallet on login + post-mutation via export wrappers — REPURPOSED for Phase 5).
- Login event handler `QBCore:Server:PlayerLoaded` (+ ESX + QBox equivalents) to trigger initial mirror sync on player connect.
- `Reconcile.Enqueue` API surface (public, may be used Phase A+1).

REMOVE:
- All install_qbcore_player + wrappers + TRAP __index/__newindex code.
- `state.in_flight`, `mirror_reason`, `consume_mirror_token`, `parse_mirror_token`.
- `OnMoneyPreHook` export (hook caller in qb-core patch disappears after Phase 3.1).
- Watchdog thread drift detection.
- `VerifyIntercept`, `GetCoreOverrideHealth` exports.
- `RegisterCommand('sonar_test_forge', ...)` dev probe.
- `RegisterCommand('mirror_sync_now', ...)` (no auto-mirror anymore).
- QBox `registerHook` blocks (Phase 4 attempt).
- ESX observer blocks (Phase 4 attempt).

#### 3.3 — Delete `resources/sonar_bank_app/server/admin/credit_command.lua`

Dev file from Phase 4. Will be regenerated cleanly as `server/exports/admin_api.lua` in Phase 4 implementation.

#### 3.4 — Edit `resources/sonar_bank_app/fxmanifest.lua`

Remove line registering `'server/admin/credit_command.lua'` (~line 133-135).

#### 3.5 — Edit `resources/sonar_bridges/config.lua`

Remove obsolete convars (per founder list):
- `sonar_co_watchdog_interval_ms`
- `sonar_bridges_disable_prehook`
- KEEP `sonar_dev_mode` (still useful Phase 5).

#### 3.6 — Archive Phase 4 design artifacts

Move Phase 4 in-flight design proposals (if any) to `docs/design/_archive/phase_4_core_override/`. The `04_sonar_bank_api.md` is PHASE 5 design, not Phase 4 — does NOT move.

**Phase 3 commits (atomic):**
- `chore(bridges): BANK-BE.PHASE_5.1 3.1 instruct founder revert qb-core patch (out of workspace)`
- `refactor(bridges): BANK-BE.PHASE_5.1 3.2 simplify core_override.lua to mirror-sync only`
- `chore(bank-app): BANK-BE.PHASE_5.1 3.3 delete Phase 4 dev credit_command.lua`
- `chore(bank-app): BANK-BE.PHASE_5.1 3.4 unregister credit_command from fxmanifest`
- `chore(bridges): BANK-BE.PHASE_5.1 3.5 remove obsolete Phase 4 convars`
- `chore(docs): BANK-BE.PHASE_5.1 3.6 archive Phase 4 design artifacts`

**Cleanup success criteria:**
- Server arranca sin errores.
- Login citizen: NO logs `[PREHOOK]`, `[TRAP]`, `[INTERCEPT]`.
- `/givemoney 1 bank 1000` funciona como qb-core nativo (no veto, no SONAR ledger update — that's Phase 4 implementation).
- Banking app sigue funcionando para transfers, balances UI.
- `players.money.bank` queda en valor qb-core legacy (no tocado from SONAR hasta Phase 4 implementation).

⚠️ Si server falla al boot after cleanup → escala founder + PM Cascade. NO continúes Phase 4.

### Phase 4 — Implementation (~6-10h, atomic commits per sub-deliverable)

#### 4.1 — Boundary helpers `lib/units.lua` (~30 min)

NEW file `resources/sonar_bank_app/server/lib/units.lua`:

```lua
-- Boundary conversion between DECIMAL major (legacy) and INTEGER minor (Phase 5 API).
-- HALF_UP rounding (matches MySQL DECIMAL standard).
function ToMinor(decimal_major)
  -- accepts string (preferred, no float precision) or number
  -- returns integer cents
end

function FromMinor(integer_minor)
  -- returns string formatted "1234.56" for DB DECIMAL insertion
  -- Lua double has 15-digit precision; safe for amounts < 9 trillion
end

return { ToMinor = ToMinor, FromMinor = FromMinor }
```

Property tests (Phase 5 validation): round-trip identity, edge cases (0, max int64 cents, negative).

#### 4.2 — Idempotency store migration `036_sonar_bank_idem.sql` (~15 min)

NEW migration:

```sql
CREATE TABLE IF NOT EXISTS sonar_bank_idem (
  idem_key VARCHAR(128) NOT NULL PRIMARY KEY,
  result_json JSON NOT NULL,
  invoker_resource VARCHAR(64),
  created_at INT NOT NULL,
  INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Register in `resources/sonar_core/config.lua` MigrationsFiles list.

Cron purge: rows con `created_at < UNIX_TIMESTAMP() - 86400` (24h TTL). Add to `resources/sonar_bank_app/server/boot/cron.lua`.

#### 4.3 — Public API Tier 1 `server/exports/public_api.lua` (~2-3h)

NEW file. 11 exports (6 base + 5 *ByCitizen). Each wrapper:

```lua
-- Pattern per wrapper:
function AddMoney(source, amount_minor, reason, opts)
  -- 1. Validate args (type checks + non-negative integer + non-empty reason)
  -- 2. Resolve citizen from source via Bridges.Identity (may return PLAYER_NOT_LOADED if PRE-PlayerLoaded)
  -- 3. Idempotency check: if opts.idempotency_key exists in sonar_bank_idem, return cached result
  -- 4. Begin SQL transaction
  -- 5. Convert minor → DECIMAL via FromMinor for service call
  -- 6. Call AccountService.CreditPrimary(citizen_id, amount_decimal, reason)
  -- 7. Insert audit row 10-field shape (Q3 LOCKED)
  -- 8. Insert idempotency row (if opts.idempotency_key)
  -- 9. Commit TX
  -- 10. Publish.BalanceUpdate(citizen_id, new_balance_minor, new_savings_minor) (Q2 LOCKED)
  -- 11. Return tuple (true, nil, {new_balance_minor, iban, tx_id})
end
exports('AddMoney', AddMoney)
```

Same pattern for 10 other Tier 1 exports.

Register in `resources/sonar_bank_app/fxmanifest.lua` server_scripts section.

#### 4.4 — Admin API Tier 2 `server/exports/admin_api.lua` (~2h)

NEW file. 5 base exports + polymorphic target arg (source OR citizen_id auto-detect).

Each wrapper adds:
- ACE check `Auth.RequireAdmin(actor_src)` when `actor_src > 0`.
- Convar-configured allowlist check `sonar:admin_allowlist` when `actor_src == 0` (console).
- `opts.allow_overdraft` flag support (Q5 LOCKED, Tier 2 only).
- Audit `event_type` mapping: `admin_credit`, `admin_debit`, `admin_set_balance`, `account_freeze`, `account_unfreeze`, `bank_overdraft` (if overdraft flag used).

Register in fxmanifest.

#### 4.5 — Bridge `Bridges.Identity.IsLoaded(source)` helper (~30 min)

NEW function in `resources/sonar_bridges/bridges/identity.lua`. Per-framework:
- qbcore: `QBCore.Functions.GetPlayer(source) ~= nil and Player.PlayerData.citizenid ~= nil`
- qbox: equivalent
- esx: `ESX.GetPlayerFromId(source) ~= nil and xPlayer.identifier ~= nil`

Used by Tier 1/2 wrappers to detect PRE-PlayerLoaded race (Q8 LOCKED).

#### 4.6 — Integration tests `server/exports/integration_tests.lua` (~1-2h)

DEV ONLY (gated by `sonar_dev_mode=1`). Register commands:

- `/sonar_test_export_add 100` — tests AddMoney with current player
- `/sonar_test_export_remove 50` — tests RemoveMoney
- `/sonar_test_export_idem` — tests idempotency replay
- `/sonar_test_export_overdraft` — tests overdraft rejection Tier 1, allow Tier 2
- `/sonar_test_export_offline <cid> 1000` — tests AddMoneyByCitizen offline
- `/sonar_test_export_race` — tests PLAYER_NOT_LOADED error
- `/sonar_test_export_full_matrix` — runs all 22 exports happy + error paths

Each prints PASS/FAIL + error_code observed. Founder runs in QBCore + ESX runtime for Phase 5 validation.

#### 4.7 — MIGRATION.md top-level (~1-2h)

NEW file `MIGRATION.md` at repo root (or `docs/MIGRATION.md`). Cover:
- Why Phase 5 (1-paragraph summary).
- Quick migration table: old patterns → new exports for qb-core + QBox + ESX.
- 20 common 3rd-party resources with concrete diff examples: qb-vehicleshop, qb-banking, qb-phone, qb-bossmenu, qb-houses, qb-jobs, esx_jobs, esx_policejob, esx_addons, nc-fuel, qb-fuel, qb-shops, ox_inventory shops, qb-garages, qb-management, qb-traphouse, qb-storerobbery, qb-truckrobbery, ps-mdt, atm scripts.
- Error handling patterns (deterministic switch on error_code).
- Idempotency best practices.
- `/sonar_scan_legacy` helper usage.

#### 4.8 — `/sonar_scan_legacy` helper (~1h)

NEW file `resources/sonar_bank_app/server/dev/scan_legacy.lua`. Command grep loaded resources' Lua files for `\.Functions\.(Add|Remove|Set)Money.*bank` + `exports.qbx_core:(Add|Remove|Set)Money` + `xPlayer\.(add|remove|set)(Money|AccountMoney)` patterns. Print report grouped by resource. Output to server console + optionally to a JSON file.

**Phase 4 commits atomic:**
- `feat(bank-app): BANK-BE.PHASE_5.1 4.1 units.lua boundary helpers + property tests`
- `feat(bank-app): BANK-BE.PHASE_5.1 4.2 migration 036 idempotency store + cron purge`
- `feat(bank-app): BANK-BE.PHASE_5.1 4.3 public_api.lua 11 Tier 1 exports`
- `feat(bank-app): BANK-BE.PHASE_5.1 4.4 admin_api.lua 5 Tier 2 exports polymorphic target`
- `feat(bridges): BANK-BE.PHASE_5.1 4.5 Bridges.Identity.IsLoaded helper`
- `feat(bank-app): BANK-BE.PHASE_5.1 4.6 integration tests dev harness`
- `docs: BANK-BE.PHASE_5.1 4.7 MIGRATION.md operator guide`
- `feat(bank-app): BANK-BE.PHASE_5.1 4.8 /sonar_scan_legacy helper`

### Phase 5 — Validation (~1-2h)

#### 5.1 — Smoke test ST-024 series

NEW file `resources/sonar_bank/server/smoke_phase_5_exports.lua`:
- ST-024.1 boot detect: all 22 exports registered.
- ST-024.2 Tier 1 AddMoney happy path → ledger row + StateBag update + audit row.
- ST-024.3 Tier 1 RemoveMoney insufficient funds → INSUFFICIENT_FUNDS error code.
- ST-024.4 Tier 1 RemoveMoney overdraft rejected.
- ST-024.5 Tier 2 AdminDebit with overdraft allowed.
- ST-024.6 Idempotency replay: same idem_key returns IDEMPOTENCY_REPLAY ok=true.
- ST-024.7 PRE-PlayerLoaded race: PLAYER_NOT_LOADED with retry hint.
- ST-024.8 *ByCitizen offline player: ledger update + StateBag publish + deferred mirror.
- ST-024.9 Audit shape 10 fields validation.
- ST-024.10 StateBag value INTEGER minor units (after Phase 1 review confirms path a/b).

Register harness in `resources/sonar_bank/fxmanifest.lua` DEV ONLY.

#### 5.2 — Founder runtime validation `progress/PHASE_5_VALIDATION.md`

Manual test plan founder-facing:
- Boot server QBCore (founder triple-cfg).
- Run `/sonar_test_export_full_matrix` → expect 22/22 PASS.
- Run `/sonar_scan_legacy` → expect report of resources to migrate.
- Manual test: open Bank app → transfer between 2 players → verify works.
- Manual test: qb-vehicleshop migration trial → re-route to `exports.sonar_bank_app:RemoveMoney` → buy vehicle → verify ledger captures + vehicle delivered.
- Manual test: cron payroll mock → 5 offline players credited via *ByCitizen → next login mirror syncs.
- Final smoke: server reboot → all StateBag values restored on player rejoin.

**REVIEW GATE 5→6:** founder green-light runtime validation 100% before Phase 6.

### Phase 6 — Sign-off + handoff (~30 min)

Execute `/close-lead-session` workflow:

- `progress/SESSION_LOG.md` append BANK-BE.PHASE_5.1 entry: summary, files changed, commits list, validation results, pending Phase B items, sign-off matrix.
- Update `progress/FE_BACKEND_REQUESTS.md` (if any consumer-facing gap arose).
- Update `docs/agents/teams/issues/issue_005_core_override_money_authority.md` status → CLOSED + cross-reference issue 006 NEW phase A+1 minor units migration (if relevant).
- Commit + push.

Handoff package to:
- **Founder:** Phase A LOCK readiness summary + Phase A+1 roadmap.
- **Security Lead BANK-SEC.2:** new audit surface to review (Tier 1/2 exports audit shape).
- **DevOps Lead (next session):** add ST-024 series to chaos harness baseline.

---

## 5. SUCCESS CRITERIA

Mission `BANK-BE.PHASE_5.1` is **CLOSED ✅** when:

- [ ] Phase 0 onboarding output emitted + founder green-lighted.
- [ ] Phase 1 amendment package (4 contracts + design v0.2 + roadmap A+1) emitted.
- [ ] Phase 2 LOCK ceremony executed by PM Cascade → 4 contracts v1.0.2 R2 LOCKED.
- [ ] Phase 3 cleanup executed → server boots clean, no PREHOOK logs, /givemoney native.
- [ ] Phase 4 implementation: 22 exports + units.lua + migration 036 + admin allowlist + Bridges helper + tests + MIGRATION.md + scan_legacy helper.
- [ ] Phase 5 validation: ST-024.1-10 PASS QBCore runtime + founder manual checklist 100% green.
- [ ] Phase 6 sign-off: SESSION_LOG + handoff + branch clean.
- [ ] Boot smoke server passes.
- [ ] No untracked secret files in commits.
- [ ] All atomic commits per phase.step pushed to `feature/bank-security-phase-a`.

---

## 6. RED FLAGS — STOP y consulta founder o PM Cascade

- Founder pide algo que contradice founder LOCK Q1-Q8 → escalate, NO arregles unilateral.
- Server boot falla post-cleanup Phase 3 → STOP, escala, revert option.
- StateBag value type decision (path a vs b §1.3 above) needs founder confirm Phase 2.
- Security Lead consumer review encuentra HIGH finding en audit shape → escalate.
- DB migration 036 colisión con migration en flight otra session → escala.
- ESX hooks investigation reveals no viable mechanism for `IsLoaded` per-framework → escala founder for decision.
- Cross-team conflict (e.g. Phase A+1 roadmap collides with already planned work) → escala Round 1/2/3 PM Cascade.

---

## 7. ANTI-PATTERNS PROHIBIDOS (refuerzo)

- ❌ Preámbulos validación ("Tienes razón!", "Excelente!", etc) → JUMP STRAIGHT.
- ❌ Recreate file when modify suffices.
- ❌ Hallucinated APIs — siempre verify against source.
- ❌ Mega-commit — atomic per phase.step.
- ❌ Skip amendment ceremony y jump to implementation → M1 violation.
- ❌ Skip validation Phase 5 y declare CLOSED → founder live test mandatory.
- ❌ Mix major + minor units inside service layer post-conversion → boundary helpers ONLY at wrapper edge.
- ❌ Bypass `Publish.BalanceUpdate()` — Q2 LOCKED non-negotiable.
- ❌ Trust audit document Anthropic blindly → founder LOCK + LOCKED contracts win.
- ❌ Reactivate Phase 4 Core Override "just to fix one edge case" → explicitly abandoned.

---

## 8. INSTRUMENTOS

- `/start-lead-session` (al inicio onboarding).
- `/close-lead-session` (al final sign-off).
- `/lock-contract` (PM Cascade ejecuta durante Phase 2 ceremony; you support).
- `/handoff-ceremony` NOT applicable (single-mission).

**Trust hierarchy (ordered):**

1. Founder Decisions LOCKED Q1-Q8 (`founder_phase_5_pivot_q1_q8_2026_05_12.md`).
2. Founder real-time green-light en chat.
3. Contratos LOCKED firmados (incluyendo amendments post-LOCK v1.0.2 R2).
4. SSoTs técnicos firmados.
5. ADRs accepted.
6. Blueprint frozen v1.2.
7. Existing functional code (BANK-BE.LOCK + BANK-BE.GOVT + BANK-BE.BUSINESS baseline).
8. Phase 4 frozen artifacts (`c4ea87a`) — historical reference, do NOT reactivate.
9. Design SSoT `04_sonar_bank_api.md` v0.1 — needs v0.2 update per Q1-Q8.
10. Audit document Anthropic — read but verify always.
11. AI training knowledge — lowest, verify always.

---

## 9. ACTIVATION CHECKLIST — para founder

```
Rol: AI Tech Lead — Phase 5 Ecosystem Public API Backend Lead
Session ID: BANK-BE.PHASE_5.1
Severity: P0 closes Phase A architectural pivot
Activation by: Founder yaboula + PM Cascade

Branch: feature/bank-security-phase-a (HEAD c4ea87a at activation)
Framework target: QBCore active (founder triple-cfg setup)
Mode: 7-phase mission (onboarding -> amendment -> sign-off -> cleanup -> implementation -> validation -> handoff)

Mission prompt: docs/agents/teams/prompts/08_phase_5_ecosystem_api_backend_lead.md (this file)
Founder Decisions LOCKED: docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md
Design SSoT: docs/design/04_sonar_bank_api.md v0.1 (needs v0.2 update per Q1-Q8)
Superseded prompt: 07 (Phase 4, abandoned — historical context only)
Phase 4 freeze baseline: commit c4ea87a (rollback point)

INMEDIATA ACCIÓN:
1. Ejecutar /start-lead-session workflow.
2. Leer prompt 08 completo.
3. Leer founder decisions LOCKED Q1-Q8.
4. Leer design SSoT 04 v0.1 + identify deltas required for v0.2 update.
5. Emit Phase 0 onboarding output:
   - Files read count (~19)
   - Pivot understanding 2-3 paragraphs
   - Deltas between design v0.1 and founder LOCK Q1-Q8 enumerated
   - Phase timing estimates
   - Blocking ambiguities (escalate if any)
6. AWAIT founder green-light before Phase 1 amendment package emission.

NO TOUCH (refuerzo):
- LOCKED contracts unilaterally (only DRAFT amendments in docs/agents/teams/amendments/)
- Core transfer TX (transfer.lua + transfer_service.lua)
- Existing callbacks C001-C040 signatures
- Frontend any
- DB migrations for money columns DECIMAL->BIGINT (Phase A+1 only)
- Audit shape canonical (align to it, don't redefine)
- Phase 4 Core Override revival (explicitly abandoned)

Idioma: docs/SESSION_LOG español, código/comentarios/commits inglés.

Bienvenido. Esta misión cierra Phase A architectural pivot. Build it clean.
```

---

## 10. POST-MISSION HIBERNATION

`/close-lead-session` ejecutado → role hibernates. Reactivación SOLO si:
- Founder/PM Cascade escala bug en Phase 5 API runtime production-side.
- Security Lead BANK-SEC.2 re-audit encuentra HIGH finding en NEW exports surface.
- Phase A+1 minor units migration kick-off (separate prompt 09 likely).

— PM Cascade
2026-05-12
