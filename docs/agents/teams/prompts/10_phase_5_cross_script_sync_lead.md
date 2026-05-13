---
prompt_id: 10_phase_5_cross_script_sync_lead
title: Phase 5 Cross-Script Synchronization Audit + Path E Listener Implementation (QBCore live)
phase: BANK-BE.PHASE_5.6 — Ecosystem Sync via Passive Event Listener
preceded_by: BANK-BE.PHASE_5.5 (manual adversarial probe in-isolation 22 exports)
emitted_by: PM Cascade
emitted_at: 2026-05-13 04:30 UTC+02 (revised 2026-05-13 04:55 UTC+02 post-research)
authority: Founder yaboula doctrine (live runtime evidence mandatory MEMORY[11ff0dd5]) + Founder concern 2026-05-13 04:25 UTC+02 "es la sincronizacion completa con los otros script realmente quiero probarlo yo, porque seguramente que falla" + Founder principle 2026-05-13 04:40 UTC+02 "cuando reducimos mas trabajo es mucho mejor"
status: SUPERSEDED 2026-05-13 05:00 UTC+02 by founder architectural decision — see prompt 11 + progress/MIGRATION_PATTERNS.md
superseded_reason: Path E (passive listener) descartado por loop-risk via MirrorSync echo (mismo error que Phase 3 cleanup removió). Founder ratificó Path A AUTOMATIZADO vía Python patcher determinístico. Cero lógica reactiva runtime. Doctrine SONAR authoritative master preservada.
superseded_by: docs/agents/teams/prompts/11_phase_5_6_a_migration_patcher_lead.md + progress/MIGRATION_PATTERNS.md
---

# 0. Pre-Audit Research Findings (PM Cascade 2026-05-13 04:55 UTC+02)

Founder pidió investigación a fondo sobre mecanismos disponibles antes del spawn. Research ejecutado contra docs oficiales QBCore + QBox + ox_inventory + qb-banking + source code real `qb-core/server/player.lua`. Resumen findings:

## 0.1 QBCore dispara evento server-side post-mutation AUTOMÁTICAMENTE

Verificado en `https://github.com/qbcore-framework/qb-core/blob/main/server/player.lua` (chunks 3+4). Las 3 funciones canónicas emiten event server-side:

```lua
-- Player.Functions.AddMoney post-mutation:
TriggerEvent('QBCore:Server:OnMoneyChange', source, moneytype, amount, 'add', reason)
-- Player.Functions.RemoveMoney post-mutation:
TriggerEvent('QBCore:Server:OnMoneyChange', source, moneytype, amount, 'remove', reason)
-- Player.Functions.SetMoney post-mutation:
TriggerEvent('QBCore:Server:OnMoneyChange', source, moneytype, amount, 'set', reason)
```

Documentación oficial QBCore (`qbcore.net/docs/resources/qb-core`) confirma uso canónico para 3rd party listeners:

```lua
AddEventHandler('QBCore:Server:OnMoneyChange', function(src, moneyType, amount, action, reason)
  -- Public API — 3rd party listening pattern oficial
end)
```

## 0.2 `reason` field convencional incluye attribution heuristic

Muestras reales scaneadas en server `D:/FiveM_Server/Sonar`:
- `'qb-shops:deliveryPay'`, `'qb-pawnshop:server:sellPawnItems'`, `'qb-drugs:server:sellCornerDrugs'`
- `'financed vehicle'`, `'paid off vehicle'`, `'bought-house'`, `'bought-furniture'`, `'sold vehicle back'`
- `'tow-received-bail'`, `'qb-drugs:server:successDelivery'`

Heurística para `invoker_resource` audit field: `reason:match('^([%w_-]+):')`. Para reasons sin prefijo formal, fallback `'qb-core-unknown'` + log warning para mejorar reason convention en futuras patches.

## 0.3 Inventario instalado server real (scan PM Cascade 2026-05-13 04:50 UTC)

| Paquete | Status | Implicación Phase A |
|---|---|---|
| qb-core | ✅ INSTALLED | listener primary target |
| qb-banking | ❌ NOT INSTALLED | future-proof listener si futuro instalan |
| qb-inventory | ✅ INSTALLED | cash items via inventory paradigm — Phase B scope |
| ox_inventory | ❌ NOT INSTALLED | si futuro migran → cash hooks pattern Phase B |
| qbx_core | ❌ NOT INSTALLED | si futuro migran → registerHook pattern equivalente |

**Phase A scope reducido: SOLO `moneyType == 'bank'` mutations.** Cash + crypto = Phase B scope (inventory paradigm + crypto-specific exports).

## 0.4 Fuera de scope Phase A (deferido Phase B con audit listeners adicionales si aplica)

- **qb-banking events** (no instalado actualmente, pero si futuro `exports['qb-banking']:AddMoney(accountName, ...)` para job/gang/shared accounts → 2do listener)
- **ox_inventory hooks** (no instalado, pero si futuro cash-as-item paradigm → `exports.ox_inventory:registerHook('swapItems', ...)` 3er listener)
- **qbx_core hooks** (no instalado, pero `registerHook` pattern equivalente si futuro migration)
- **Custom standalone scripts** que mutate dinero directo SQL bypassing qb-core (architectural error operator-side, audit detected via Reconcile drift)

## 0.5 Path E surgió como primary recommendation (~50-80 LOC vs ~500 patches)

Ver paragraph 8.5 detalle implementation. Comparativa:

| Path | Effort | Audit | Real-time | Amendment | Recomendación |
|---|---|---|---|---|---|
| A operator patches ~500 hits | 🔴 MASSIVE | ✅ perfect | ✅ | none | descartado por effort |
| B re-introduce Pre-Hook | 🟡 MEDIUM | ✅ perfect | ✅ | Round 3 (4 contratos) | descartado por recursion risk + reverse Q4 |
| C hybrid Reconcile + selective | 🟡 MEDIUM | 🟡 partial | 🔴 30s drift | C-BE-04 minor | descartado por audit gap aggregate |
| D defer Phase B | 🟢 ZERO | 🔴 GAP | 🔴 | none | descartado por production gap |
| **🌟 E passive event listener** | **🟢 ~50-80 LOC** | **✅ near-perfect** | **✅ same tick** | **C-SEC-01 v0.4 minor additive** | **PRIMARY** |

## 0.6 Mission reframed (post-research)

La mission original (paragraph 1-12 abajo) fue **AUDIT-ONLY enumerate bypasses + propose paths**. Post-research, la mission se reframe en:

**Phase 5.6 = Path E listener implementation + adversarial validation** (no audit-enumerate-paths, ya tenemos suficiente evidence preliminar). Sub-fases:

- **5.6.1 amendment minor C-SEC-01 v0.4** (NEW event_types `bank_external_credit/debit/set` en paragraph 1.2 audit_hook_exports_mutation row + paragraph 1.2.B shape canonical para external mutations) — Backend Lead emit DRAFT + Founder ratifies in same session.
- **5.6.2 implement Path E listener** — `resources/sonar_bridges/server/qbcore_money_listener.lua` + nuevo wrapper `Bridges.MoneyListener.RecordExternalMutation` (atomic TX 4-step idem-store/audit/balance/movement + post-COMMIT publish).
- **5.6.3 adversarial probe live** — los 12 escenarios S1-S12 paragraph 7 ahora son validation criteria del listener, no audit. Cada uno PASS con audit row event_type correcto + invoker_resource heurística + balance sync immediate + UI app real-time.
- **5.6.4 sign-off founder GO MANUAL** Path E live + new MIGRATION.md paragraph "Cross-script sync via passive event listener".

ETA estimada nueva: 3-4h (vs 5-6h audit-only original). Paths A/B/C/D quedan documentados como alternativas descartadas para audit trail.

---

# Mission — BANK-BE.PHASE_5.6 — Cross-Script Sync Reality Check (revised post-research)

> **Founder gut concern 2026-05-13 04:25 UTC:**
> *"hemos hecho con el lead tech es espectacular, pero no hemos dado en el clavo. Es la sincronización completa con los otros script realmente quiero probarlo yo. Porque seguramente que falla."*
>
> El founder identificó la brecha REAL del modelo Ecosystem Closed Public API: **los 56 resources qb-\* instalados en `D:\FiveM_Server\Sonar\resources\[qb]\` siguen llamando `Player.Functions.AddMoney/RemoveMoney` vanilla**, NO los exports SONAR. Phase 3 cleanup removió `OnMoneyPreHook` (era el hook QBCore→SONAR de la era Core Override). Post-Phase 3 + Phase 4 + Phase 5.4 GO, la dirección **QBCore→SONAR** solo se sincroniza vía `Reconcile.Run` periódico (eventually consistent, sin audit row event_type real, sin StateBag publish coherente, sin idempotency, sin actor_account_id).
>
> Phase 5.5 manual probe valida los 22 exports **en aislamiento**. No valida la integración cross-script. Esta phase 5.6 es el **Ecosystem Sync Reality Check** que el founder exige antes del tag `bank-phase-a`.

## 1. Evidence preliminar discovery scan (PM Cascade ejecutó 2026-05-13 04:28 UTC)

| Resource | `Functions.AddMoney/RemoveMoney/SetMoney` hits | Status sync con SONAR |
|---|---|---|
| qb-vehicleshop | **20** | ⚠️ BYPASS — financiamiento, compra, reposesion |
| qb-drugs | **7** | ⚠️ BYPASS — corner sell, deliveries |
| qb-shops | 5 | ⚠️ BYPASS — delivery pay, truck deposit |
| qb-vehiclesales | 3 | ⚠️ BYPASS — used lot buy/sell |
| qb-pawnshop | 2 | ⚠️ BYPASS — sell items |
| qb-houses | 2 | ⚠️ BYPASS — buy house, furniture |
| qb-management | 0 | ✅ Probable society money (no player path) |
| qb-mechanicjob | 0 | ✅ Probable consultar más |
| qb-bankrobbery | 0 | ✅ Probable consultar más |
| qb-jewelery | 0 | ✅ Probable consultar más |
| **resto 46 qb-\*** | **NO ESCANEADO** | ❓ TBD durante audit |

Hits totales conocidos solo en sample: **39** llamadas vanilla bypass. Total real **mucho mayor** (56 resources × promedio).

Vectores adicionales sin escanear:
- ATM scripts (qb-banking? no presente en lista, posiblemente vanilla qb-core)
- `/givemoney`, `/admincash`, `/setmoney` admin commands de qb-adminmenu (probable)
- Salaries/paychecks via qb-core scheduler (probable)
- qb-jobs payouts (busjob, taxijob, garbagejob, hotdogjob, newsjob, recyclejob, policejob, ambulancejob, truckrobbery, scrapyard, mechanicjob)
- qb-houserobbery, qb-storerobbery payouts criminal
- qb-crypto trading (si usa Player.Functions money)
- qb-cityhall (taxes, ID renewal)
- qb-fuel (gas station purchases)
- qb-prison (fines)
- qb-streetraces / qb-lapraces buy-in/payout
- qb-weed grow/sell

## 2. Hipótesis a validar live (HIGH severity findings esperados)

### H1 (esperado FAIL): QBCore→SONAR real-time sync rota post-Phase 3

Post `OnMoneyPreHook` removal, mutation vanilla `xPlayer.Functions.AddMoney('bank', 5000, 'qb-vehicleshop:purchase')` en qb-vehicleshop server.lua:
- ❌ NO emite audit row `bank_credit/bank_debit` con event_type SONAR
- ❌ NO genera idempotency_key forensic
- ❌ NO popula `actor_account_id` real ni `invoker_resource = qb-vehicleshop`
- ❌ NO publica StateBag `bank.balance.<cid>` post-COMMIT (CP1-B mandate)
- ❌ NO escribe `sonar_bank_movements` row con category coherent
- ✅ Mutation aplicada en QBCore `PlayerData.money.bank` (KVP/DB QBCore_FFAED3)
- ⚠️ `Reconcile.Run` periódico (cada N seg/min) eventualmente sincroniza balance numérico SONAR → pero **drift window** = ventana donde SONAR ledger diverge de QBCore truth.

### H2 (esperado PASS): SONAR→QBCore push real-time vía MirrorSync

Mutation SONAR export `AddMoney(src, 5000, ...)` → `Wrappers.publish_balance_update` → `MirrorSync.SetBalance` push a `xPlayer.Functions.SetMoney('bank', new_balance)` (preserved Phase 3). Esperado:
- ✅ QBCore `PlayerData.money.bank` actualizado en mismo tick
- ✅ SONAR audit row escrita en mismo TX
- ✅ StateBag publicado

### H3 (esperado FAIL): UI SONAR Bank App muestra valor stale tras vanilla mutation

Tras buy-car qb-vehicleshop (vanilla path) → drift hasta próximo `Reconcile.Run` → UI app muestra balance pre-compra. Frontend cliente recibe StateBag o NetEvent SOLO si `Reconcile.Run` emite eventos (verificar en código).

### H4 (esperado FAIL): Audit ledger forensic gap

Compliance/forensic queries (`SELECT FROM sonar_audit_log WHERE event_type='bank_debit' AND target_account_id=?`) **NO mostrarán** las transacciones vanilla path. Audit completeness = solo 22 exports SONAR + Reconcile periódico aggregate. Para reguladores in-world / GTA V Government Audit Explorer V4 → trail incompleto.

## 3. Authority + boundary (estricto)

### ✅ Permitido

- Audit completo de los **56 resources qb-\*** instalados — categorizar cada uno por sync_status.
- Reusar `sonar_bank_qa_probe` (commands ya creados) + agregar nuevos `qa_*_baseline` y `qa_*_diff` helpers.
- Modificar/extender `MIGRATION.md` con nuevo paragraph "Cross-script sync inventory + operator patch guide".
- Crear `progress/PHASE_5_6_CROSS_SCRIPT_AUDIT.md` (audit report 56 resources + repro scenarios + findings).
- Probar adversarial scenarios live + capturar evidencia DB diff QBCore vs SONAR.
- **NO implementar fixes en esta phase**. Phase 5.6 es **AUDIT-ONLY**. Resolution paths se proponen, founder decide en Phase 5.7 si corresponde.

### ❌ Prohibido sin escalation founder

- Tocar contracts SSoT LOCKED v1.0.2 R2.
- Modificar exports surface (paragraph 4 implementation).
- Re-introducir `OnMoneyPreHook` o equivalente sin amendment Round 3 formal (modelo Ecosystem cambia → contrato cambia).
- Patchear qb-* resources directamente (responsabilidad operator MIGRATION.md, no Backend Lead unilateral).
- Cambiar Reconcile.Run cadence/scope sin amendment.

## 4. Inputs lectura obligatoria

1. **`docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md` paragraph 4 prime + paragraph 4 DEPRECATED** — modelo Ecosystem ratificado + Core Override nullified.
2. **`docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md`** — Q4 LOCKED "no shim, operator-side patch responsibility".
3. **`resources/sonar_bridges/server/core_override.lua`** (196 líneas post Phase 3) — verificar qué SE PRESERVÓ: `MirrorSync.SetBalance`, `Reconcile.Enqueue`, `Reconcile.Run`, login mirror sync.
4. **`resources/sonar_bank_app/MIGRATION.md`** — operator current guidance.
5. **`docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md` paragraph 2.2.1.A** — wrapper consumer pattern (verificar si Reconcile.Run lo invoca o no).
6. **`docs/technical/08_audit_hooks.md` paragraph 1.1 AH4** — atomic mandate (verificar si Reconcile.Run cumple AH4 o emite eventos no-atómicos).
7. **MEMORY[11ff0dd5]** — doctrine live evidence mandatory.
8. **MEMORY[dc00d46d]** — QBCore official docs URLs (Player.Functions.AddMoney source).

## 5. Pre-flight checklist

- [ ] Pull branch `feature/bank-security-phase-a` HEAD `9f42ca7` (Phase 5.5 prompt commit) o posterior.
- [ ] Boot server txAdmin QBCore mode + verificar console boot smoke + 71 callbacks + bridges qbcore active.
- [ ] HeidiSQL connect ambas DBs:
  - `qbcore_ffaed3` → tabs `players` (PlayerData JSON), payment-related qb tables.
  - `sonar` → tabs `sonar_bank_accounts`, `sonar_bank_movements`, `sonar_audit_log`, `sonar_bank_idem`.
- [ ] `restart sonar_bank_qa_probe` + `/qa_help` para probe baseline.
- [ ] Tener 1 player real conectado con bank balance conocido (anotar valor inicial).
- [ ] **CRÍTICO:** verificar dirección actual del bridge mode (`setr sonar_bridge_bank_mode "standalone"` confirmed). En modo standalone, el repo de truth balance es **SONAR**, no QBCore. QBCore es mirror. Operación inversa: QBCore mutation tiene que sincronizarse de vuelta a SONAR.

## 6. Audit fase 1 — code-level scan (dev solo, ~1h)

### 6.1 Scan exhaustivo 56 resources qb-*

```powershell
$qbroot = 'D:\FiveM_Server\Sonar\resources\[qb]'
$pattern = 'Functions\.AddMoney|Functions\.RemoveMoney|Functions\.SetMoney|exports\[''sonar_bank_app''\]|exports\.sonar_bank_app|sonar:bank:'
Get-ChildItem -LiteralPath $qbroot -Directory | ForEach-Object {
  $hits = Get-ChildItem -LiteralPath $_.FullName -Recurse -Include *.lua -ErrorAction SilentlyContinue |
    Select-String -Pattern $pattern -ErrorAction SilentlyContinue
  $vanilla = ($hits | Where-Object { $_.Line -match 'Functions\.(Add|Remove|Set)Money' } | Measure-Object).Count
  $sonar = ($hits | Where-Object { $_.Line -match 'sonar_bank' } | Measure-Object).Count
  [PSCustomObject]@{ Resource = $_.Name; VanillaHits = $vanilla; SonarHits = $sonar; Status = (if ($vanilla -gt 0 -and $sonar -eq 0) { 'BYPASS' } elseif ($vanilla -eq 0) { 'CLEAN' } else { 'MIXED' }) }
} | Sort-Object VanillaHits -Descending | Format-Table -AutoSize
```

Output capturado → `progress/PHASE_5_6_CROSS_SCRIPT_AUDIT.md` paragraph "Code-level inventory".

### 6.2 Categorización por severidad volumen

- **CRITICAL** ≥10 vanilla hits o resource alto-tráfico (qb-vehicleshop, qb-banking, qb-jobs payouts, qb-shops).
- **HIGH** 3-9 vanilla hits o resource medio-tráfico.
- **MEDIUM** 1-2 vanilla hits o low-volume.
- **CLEAN** 0 vanilla hits, ya migrado o no toca dinero player.

### 6.3 Vectores especiales — buscar en qb-core/server/player.lua + qb-adminmenu

- Salary scheduler interval (qb-core internal): `grep -i 'PaycheckInterval\|paycheck\|payday'` en qb-core.
- Admin money commands: `grep -in 'givemoney\|setmoney\|RegisterCommand' qb-adminmenu/server/*.lua`.
- ATM in-world: probable absorbido por qb-core o resource standalone — confirmar.

## 7. Audit fase 2 — runtime probe matrix (founder + dev paralelo, ~2h)

Para cada resource CRITICAL/HIGH, ejecutar el patrón **8-step diff matrix**:

| Step | Acción | Captura |
|---|---|---|
| 1 | Snapshot SONAR pre: `/qa_account_by_src 1` → `balance_minor` | `sonar_balance_before` |
| 2 | Snapshot QBCore pre: HeidiSQL `SELECT JSON_EXTRACT(money, '$.bank') FROM qbcore_ffaed3.players WHERE citizenid=?` | `qbcore_balance_before` |
| 3 | Trigger evento in-game (ej: comprar moto en qb-vehicleshop, vender drogas, depositar ATM, recibir paycheck) | game console output capturado |
| 4 | Snapshot QBCore post: misma query | `qbcore_balance_after` |
| 5 | Snapshot SONAR post **inmediato** (≤1 segundo): `/qa_account_by_src 1` | `sonar_balance_after_immediate` — **CLAVE para H3** |
| 6 | Esperar 1 ciclo Reconcile.Run (verificar period en code) | timer logged |
| 7 | Snapshot SONAR post **tras Reconcile**: `/qa_account_by_src 1` | `sonar_balance_after_reconcile` |
| 8 | Audit query SONAR `/qa_audit_recent bank_debit 5` y `/qa_audit_recent bank_credit 5` | filas ¿hay? ¿con qué `invoker_resource`? ¿con qué `event_type`? |

**Criterio FAIL:**
- `sonar_balance_after_immediate ≠ qbcore_balance_after` → DRIFT REAL-TIME (esperado FAIL H1)
- `sonar_balance_after_reconcile ≠ qbcore_balance_after` → DRIFT PERMANENT (escalation BLOCKER)
- `audit row missing for vanilla mutation` → AUDIT GAP (esperado FAIL H4, severity HIGH)
- `invoker_resource = 'sonar_core' o 'reconcile'` en lugar de `qb-vehicleshop` → AUDIT FORENSIC INCORRECT

### 7.1 Repro scenarios concretos founder

Founder ejecuta cada uno + dev captura métricas paralelo:

| # | Escenario | Resource origen | Esperado vs realidad |
|---|---|---|---|
| S1 | Comprar vehículo en concesionario PDM | qb-vehicleshop server.lua:179 | FAIL H1 H4 |
| S2 | Vender droga (corner sell) | qb-drugs cornerselling.lua:49 | FAIL H1 H4 |
| S3 | Comprar item shop 24/7 | qb-shops main.lua | FAIL H1 H4 |
| S4 | Depositar/retirar ATM (banking vanilla qb-core) | qb-core internal | FAIL H1 H4 si vanilla; PASS si SONAR ATM C031 hooked |
| S5 | Recibir paycheck job | qb-core paycheck scheduler | FAIL H1 H4 (paycheck es vanilla scheduler) |
| S6 | `/givemoney <id> bank 5000` admin command | qb-adminmenu | FAIL H1 H4 — particularmente grave porque admins esperan audit |
| S7 | Sell vehicle used lot | qb-vehiclesales main.lua:98 | FAIL H1 H4 |
| S8 | Transfer SONAR app player1 → player2 | sonar_bank_app UI | PASS H2 (validación reverse direction) |
| S9 | `qa_admin_credit` via probe | sonar_bank_qa_probe | PASS (validación sanity) |
| S10 | Robar tienda (qb-storerobbery) | qb-storerobbery payout | TBD según implementación |
| S11 | Pagar multa cárcel (qb-prison) | qb-prison fine | TBD |
| S12 | Comprar casa qb-houses | qb-houses main.lua:262 | FAIL H1 H4 |

Para CADA escenario S1-S12: 8-step diff matrix completa + screenshot UI app SONAR si aplicable + console output verbatim.

## 8. Resolution paths (PROPOSE only — founder decides Phase 5.7)

Backend Lead propone, **NO implementa**, las siguientes opciones después del audit:

### Path A — Operator Patch Responsibility (current contract Q4)

Operator (server admin yaboula u otros) edita CADA qb-* resource para reemplazar `Player.Functions.AddMoney/RemoveMoney` por `exports.sonar_bank_app:AddMoney/RemoveMoney`.

- ✅ Modelo más limpio arquitectónicamente, alineado contract Q4 LOCKED
- ✅ Audit forensic completo per resource
- ❌ **EFFORT MASIVO** — 56 resources × promedio 3-10 hits = ~200-500 patches manuales
- ❌ Cada update qb-core mainline reintroduce vanilla calls → maintenance burden permanente
- ❌ Operadores menos técnicos no podrán hacerlo → adoption barrier
- ❌ Algunos qb-* resources usan scheduler/eventos internos imposibles de patchear sin fork

### Path B — Re-introduce Sync Hook (amendment Round 3 required)

Hook qb-core `Player.Functions.AddMoney/RemoveMoney/SetMoney` post-mutation → emite evento → SONAR reconcile transactional con audit row event_type sintético `bank_external_credit`/`bank_external_debit` + invoker_resource real (capturable via stack trace o convención).

- ✅ Adoption near-zero effort para operators (drop-in)
- ✅ Audit completeness recuperado
- ✅ Real-time sync (no drift window)
- ❌ Re-introduce el problema "Core Override" que se removió en Phase 3 (recursion, race, stale state)
- ❌ Modelo "Closed Public API" se compromete — es semi-open en realidad
- ❌ Requiere amendment Round 3 sobre 4 contratos LOCKED v1.0.2 R2 + Founder Q4 reverse decision

### Path C — Hybrid Reconcile.Run aggressive + Operator patches selective (PROPOSED PM Cascade default)

- Reconcile.Run cadence agresiva (cada 30s en lugar de N min) + emite audit row aggregate por delta detected post-cycle (event_type `bank_external_reconcile` con metadata `delta_minor`, `qbcore_balance_observed`, `sonar_balance_before_reconcile`, sin invoker_resource real)
- Operator patches **ONLY** los CRITICAL ≥10 hits resources (qb-vehicleshop, qb-banking) via MIGRATION.md guided patches.
- High/Medium resources: aceptan drift window 30s + audit aggregate event_type (forensic less precise but acceptable Phase A).
- Path B (hook) deferido Phase B con design proper recursion/race-resistant.

- ✅ Compromiso pragmático
- ✅ MIGRATION.md scope reducido a 5-10 resources (operator-feasible)
- ✅ Audit no perfecto pero presente
- ❌ Reconcile.Run cadence 30s = carga DB
- ❌ Audit aggregate no imputable a actor real
- ❌ Drift window aún existe

### Path D — Defer to Phase B + accept Phase A scope

- Phase A ships con disclaimer: "SONAR Bank Phase A es authoritative SOLO para mutations via SONAR exports. Mutations vanilla qb-* aplican a QBCore directamente y se reconcilian periódicamente sin audit forensic granular."
- MIGRATION.md exhaustivo paragraph "Known limitations Phase A".
- Phase B = full sync hook design (Path B done right).

- ✅ Honesty con operators
- ✅ Phase A ships ahora (founder GO ya emitido en aislamiento)
- ❌ Founder concern actual ("seguramente falla") = **se confirma** y se acepta como Phase A trade-off
- ❌ Production-ready depende de Phase B timing

### 🌟 Path E — Passive Event Listener (PRIMARY RECOMMENDATION post-research)

QBCore dispara `QBCore:Server:OnMoneyChange` server-side automáticamente post-mutation (verificado en source code, paragraph 0.1). SONAR registra un event handler pasivo que captura TODAS las mutations de `moneyType='bank'` provenientes de cualquier qb-* resource sin patches.

**Architecture:**

```lua
-- resources/sonar_bridges/server/qbcore_money_listener.lua (NEW ~80 LOC)
local Bridges = Bridges or {}
Bridges.MoneyListener = Bridges.MoneyListener or {}

AddEventHandler('QBCore:Server:OnMoneyChange', function(src, moneyType, amount, action, reason)
  -- Phase A scope: only 'bank' moneyType
  if moneyType ~= 'bank' then
    -- Phase B: cash/crypto handlers
    return
  end
  if not src or src <= 0 then return end
  if not amount or amount <= 0 then return end
  reason = reason or 'qb-core-unknown'

  -- Resolve citizen via SONAR identity bridge
  local cid_ok, cid = pcall(function() return exports.sonar_bridges:GetCitizenId(src) end)
  if not cid_ok or type(cid) ~= 'string' or cid == '' then return end

  -- Heuristic invoker_resource from reason convention
  local invoker_resource = reason:match('^([%w_%-]+):') or 'qb-core-unknown'

  -- Map QBCore action -> SONAR event_type
  local event_type_map = {
    add = 'bank_external_credit',
    remove = 'bank_external_debit',
    set = 'bank_external_set',
  }
  local event_type = event_type_map[action]
  if not event_type then return end

  -- Compute delta_minor (DECIMAL major QBCore amount -> INTEGER minor SONAR)
  local delta_minor = math.floor(amount * 100)
  if action == 'remove' then delta_minor = -delta_minor end
  if action == 'set' then
    -- For 'set', amount is the new total. Compute delta vs current SONAR balance.
    -- Defer to wrapper RecordExternalMutation to compute delta.
  end

  -- Dispatch to atomic wrapper
  exports.sonar_bank_app:RecordExternalMutation({
    citizen_id = cid,
    actor_src = src,
    action = action,
    amount_major = amount,
    delta_minor = delta_minor,
    reason = reason,
    invoker_resource = invoker_resource,
    event_type = event_type,
    moneyType = moneyType,
  })
end)
```

**New wrapper `RecordExternalMutation`** (additive a `sonar_bank_app/server/api/external_sync.lua` o `wrappers.lua`, NO toca los 22 exports paragraph 4):

1. SQL TX atómica AH4-compliant (mismo pattern existing exports):
   - SELECT current SONAR balance for cid
   - For 'set': delta_minor = new_total_minor - current_balance_minor
   - INSERT idempotency row (key = SHA256 hash of cid+timestamp_ms+amount_major+reason — collision-resistant per-tick)
   - INSERT audit row 10-field shape canonical event_type=`bank_external_*` + invoker_resource heurística + actor_account_id=cid + correlation_id=newly-generated UUID
   - UPDATE balance SONAR to match QBCore (delta apply)
   - INSERT movement row category=`adjustment_external` reason=passthrough
2. Post-COMMIT: `publish_balance_update(cid, new_balance_minor, 'main', correlation_id, reason)` para CP1-B StateBag tier financial PII update.
3. Return success/failure logged but NOT propagated (event listener is fire-and-observe; QBCore mutation already committed regardless of SONAR sync result; failure-to-sync triggers Reconcile.Run fallback).

**Pros:**

- 🟢 **Effort minimal** — ~80 LOC new file + ~150 LOC wrapper + ~30 LOC migration audit shape extension = ~260 LOC total Phase 5.6
- 🟢 **Real-time sync** — same tick post QBCore mutation
- 🟢 **Audit forensic recovered** — invoker_resource heurística (acceptable Phase A) + actor_account_id real + event_type canonical
- 🟢 **StateBag CP1-B publish** — UI Bank App actualiza inmediatamente
- 🟢 **Zero patches qb-\*** — operator drop-in, future qb-core updates resilient
- 🟢 **No reverse Founder Q4** — Q4 LOCKED "no shim" se preserva (listener ≠ shim, listener es passive observer)
- 🟢 **No re-introduce OnMoneyPreHook** — Pre-Hook era VETO (synchronous mutate-or-cancel), listener es POST-OBSERVE (ya commited en QBCore)

**Cons:**

- 🟡 **invoker_resource heurística** — reason convention not enforced; `reason:match('^([%w_%-]+):')` fallback `qb-core-unknown` para reasons sin prefijo. Mitigation: MIGRATION.md guidance "recommend qb-* maintainers prefix reason with `<resource_name>:`"
- 🟡 **Cash + crypto fuera de scope Phase A** — handled Phase B (qb-inventory cash items + qb-crypto exports diferentes paths)
- 🟡 **Offline player path** — `Player.Functions.AddMoney` en QBCore tiene `if not self.Offline` check antes de TriggerEvent. Offline mutations NO disparan listener. Mitigation: `Reconcile.Run` periódico cubre este edge case con eventually-consistent sync (Phase A acceptable; Phase B optional offline event hook).
- 🟡 **Amendment minor C-SEC-01 v0.4** — agregar `bank_external_credit/debit/set` event_types al paragraph 1.2 audit_hook_exports_mutation row + paragraph 1.2.B shape canonical para external mutations (10-field con invoker_resource heurística + actor_src=qbcore-source). Scope MINOR additive 1 contrato (vs Round 3 que sería 4 contratos).
- 🟡 **Idempotency en QBCore→SONAR direction** — QBCore no provee idem_key per-mutation. Composite SHA256 hash (cid+timestamp_ms+amount+reason) collision risk en ráfagas mismo-tick mismo-amount mismo-reason. Mitigation: include incremental counter persisted in `sonar_bank_external_seq` table (additive migration) or accept low collision probability Phase A.

**Path E es la primary recommendation. Backend Lead implementa en Phase 5.6 como sub-fase 5.6.1 (amendment minor) + 5.6.2 (implementation) + 5.6.3 (validation S1-S12) + 5.6.4 (founder GO MANUAL).**

## 9. Bug intake protocol (durante audit)

Si durante audit aparece comportamiento NO esperado por el modelo Phase 3+4+5.4:

- **F-PH5.6-001+** ascending IDs.
- **Severity classification:**
  - **BLOCKER**: SONAR balance pierde fondos vs QBCore (drift permanente no recuperado por Reconcile)
  - **HIGH**: Audit gap completo + UI stale > 60s + StateBag no publicado
  - **MEDIUM**: Audit gap parcial pero balance reconciliado eventually
  - **LOW**: Cosmetic drift UI fix-able con refresh manual
- **Escalation BLOCKER → STOP audit + founder immediate.**

## 10. Evidence format

`progress/PHASE_5_6_CROSS_SCRIPT_AUDIT.md` template:

```markdown
# Phase 5.6 Cross-Script Synchronization Audit

## Session metadata
- Date: YYYY-MM-DD HH:MM UTC
- Server: D:\FiveM_Server\Sonar (QBCore active)
- Branch HEAD: <commit>
- Dev: <handle> | Founder: yaboula

## Code-level inventory (paragraph 6.1 PowerShell scan)
| Resource | Vanilla hits | SONAR hits | Status | Severity |
|---|---|---|---|---|
| qb-vehicleshop | 20 | 0 | BYPASS | CRITICAL |
| ... 56 rows ... |

## Vectores especiales (paragraph 6.3)
- Paycheck scheduler: <findings>
- Admin /givemoney: <findings>
- ATM in-world: <findings>

## Runtime probe matrix S1-S12 (paragraph 7)
### S1 Comprar vehículo qb-vehicleshop
- sonar_balance_before: 50000 minor
- qbcore_balance_before: 500 (DECIMAL major as QBCore stores)
- trigger: bought Sultan @ 95000
- qbcore_balance_after: -45000 wait that's NEGATIVE! [example placeholder]
- sonar_balance_after_immediate: 50000 (UNCHANGED — DRIFT confirmed)
- sonar_balance_after_reconcile: -45000 (synced after 60s)
- audit row immediate: NONE
- audit row post-reconcile: 1 row event_type=`bank_external_reconcile` invoker_resource=`sonar_core`
- finding: F-PH5.6-001 HIGH — DRIFT REAL-TIME 60s window + AUDIT FORENSIC INCORRECT (no qb-vehicleshop attribution)
- evidence: console output + screenshot UI

... S2-S12 ...

## Findings consolidados
| ID | Severity | Title | Resource | Resolution path proposed |
|---|---|---|---|---|
| F-PH5.6-001 | HIGH | DRIFT real-time vehicleshop | qb-vehicleshop | Path C |

## Resolution paths analysis
- Path A pros/cons + estimated effort
- Path B pros/cons + amendment scope
- Path C (default proposed) pros/cons + scope reducido
- Path D pros/cons

## Recommendation Backend Lead
- Recommended: Path X for reasons Y/Z
- Effort estimate: Phase 5.7 = N hours
- Amendment scope (if Path B): contracts affected list

## Sign-off
- Backend Lead: ✅ audit complete, no fix executed
- Founder yaboula: 🟡 DECISION PENDING (Path A/B/C/D)
- PM Cascade: standby awaiting founder decision
```

## 11. Activation checklist

```
Spawn Backend Lead BANK-BE.PHASE_5.6 with this prompt:

Branch: feature/bank-security-phase-a HEAD post-aebe97e
Server: D:\FiveM_Server\Sonar (QBCore — 56 qb-* resources, qb-inventory only, no qb-banking, no ox_inventory, no qbx)
DB: D:\laragon — both sonar AND qbcore_ffaed3 schemas

Read prompt: docs/agents/teams/prompts/10_phase_5_cross_script_sync_lead.md (paragraph 0 research findings + paragraph 8.5 Path E primary)

Mission revised post-research (Path E primary, no más audit-only):

Sub-phase 5.6.1 — Amendment C-SEC-01 v0.3 R2 -> v0.4 R2 MINOR additive
  - paragraph 1.2 audit_hook_exports_mutation row: extend event_type enum con bank_external_credit/debit/set
  - paragraph 1.2.B NEW shape canonical para external mutations (10-field con invoker_resource heuristica + actor_src=qbcore-source + delta_minor signed + previous_flag_snapshot.balance_before_minor)
  - DRAFT emit + founder ratify in same session (no Round 3 ceremony, MINOR additive 1 contract)
  - Update docs/technical/08_audit_hooks.md atomic in-place patch

Sub-phase 5.6.2 — Path E listener implementation
  - NEW resources/sonar_bridges/server/qbcore_money_listener.lua (~80 LOC)
  - NEW resources/sonar_bank_app/server/api/external_sync.lua (~150 LOC) con RecordExternalMutation wrapper (4-step atomic TX same pattern existing exports)
  - Migration additive 037_sonar_bank_external_seq.sql para idempotency dedup ráfagas mismo-tick (opcional, accept low collision probability Phase A si scope tight)
  - exports('RecordExternalMutation', ...) NEW additive (no toca los 22 exports paragraph 4)
  - fxmanifest.lua wire ambos archivos
  - Atomic commits: feat(bank-bridges): BANK-BE.PHASE_5.6 5.6.2 add qbcore money listener + feat(bank-api): BANK-BE.PHASE_5.6 5.6.2 add external sync wrapper

Sub-phase 5.6.3 — Adversarial probe live (S1-S12 paragraph 7 + paragraph 7.1)
  - Founder paralelo ejecuta 12 escenarios in-game (buy car, sell drugs, paycheck, /givemoney, etc.)
  - Dev captura para CADA escenario: balance QBCore antes/después + balance SONAR inmediato (≤1s post-event) + audit row event_type=bank_external_* + invoker_resource heuristica + StateBag publish observed + UI Bank App refresh real-time.
  - Criterio PASS S1-S12: zero drift real-time + audit row presente + invoker_resource attribution correcta (heurística OK, fallback acceptable).
  - Criterio FAIL: cualquier drift > 1s o audit row missing o event_type incorrecto.

Sub-phase 5.6.4 — Sign-off + MIGRATION.md update
  - progress/PHASE_5_6_CROSS_SCRIPT_AUDIT.md emit con cobertura S1-S12 PASS + listener implementation evidence.
  - MIGRATION.md NEW paragraph "Cross-script sync via QBCore:Server:OnMoneyChange listener" + reason convention guidance + offline player limitation note + Phase B scope cash/crypto deferred.
  - Founder GO MANUAL formal Path E ratification.

Founder paralelo: ejecuta 12 escenarios in-game S1-S12 mientras dev captura SQL diffs + listener console output.

Boundary STRICT:
- NO touch contracts LOCKED v1.0.2 R2 EXCEPTO C-SEC-01 v0.3 R2 -> v0.4 R2 MINOR additive (path Founder ratify in-session, no Round 3 ceremony — additive enum + new shape canonical no breaking).
- NO patch qb-* resources (Path E es zero-patch by design).
- NO re-introduce OnMoneyPreHook (Path E es POST-OBSERVE listener, semánticamente distinto de Pre-Hook VETO).
- NO scope creep cash/crypto/qb-banking/ox_inventory (Phase B scope explicit).

ETA: 3-4h (vs 5-6h audit-only original):
- 5.6.1 amendment ~30min DRAFT + founder ratify
- 5.6.2 implementation ~1.5-2h listener + wrapper + migration + tests
- 5.6.3 adversarial probe ~1h (12 escenarios paralelo)
- 5.6.4 sign-off + docs ~30min

GO.
```

## 12. Boundary recordatorio

- Phase 5.6 = AUDIT + REPRO ONLY.
- Findings + Resolution paths se documentan, **founder decide Phase 5.7** scope (A/B/C/D o híbrido).
- Si founder elige Path B → Round 3 amendment ceremony obligatoria sobre C-BE-04 paragraph 4 prime + nuevo §C-BE-04 paragraph 4 Sync Hook + C-SEC-01 (event_type nuevo) + Q4 founder decision reverse.
- Si founder elige Path A o C → MIGRATION.md update + scope qb-* patches inventario + sin amendment.
- Si founder elige Path D → MIGRATION.md "Known Limitations Phase A" + Phase B roadmap.

---

**PM Cascade emitió este prompt 2026-05-13 04:30 UTC+02 respondiendo gut concern founder validado por preliminar scan (39 vanilla hits en 6 resources, 50 más sin escanear).**
**Siguiente sesión: BANK-BE.PHASE_5.6 — awaiting founder spawn.**
