---
prompt_id: 10_phase_5_cross_script_sync_lead
title: Phase 5 Cross-Script Synchronization Audit + Adversarial Probe (QBCore live)
phase: BANK-BE.PHASE_5.6 — Ecosystem Sync Reality Check
preceded_by: BANK-BE.PHASE_5.5 (manual adversarial probe in-isolation 22 exports)
emitted_by: PM Cascade
emitted_at: 2026-05-13 04:30 UTC+02
authority: Founder yaboula doctrine (live runtime evidence mandatory MEMORY[11ff0dd5]) + Founder concern 2026-05-13 04:25 UTC+02 "es la sincronizacion completa con los otros script realmente quiero probarlo yo, porque seguramente que falla"
status: ACTIVE — awaiting dev session spawn (HIGH SEVERITY)
---

# Mission — BANK-BE.PHASE_5.6 — Cross-Script Sync Reality Check

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

Branch: feature/bank-security-phase-a HEAD post-9f42ca7
Server: D:\FiveM_Server\Sonar (QBCore — 56 qb-* resources installed)
DB: D:\laragon — both sonar AND qbcore_ffaed3 schemas

Read prompt: docs/agents/teams/prompts/10_phase_5_cross_script_sync_lead.md

Mission:
- Phase 5.6 is AUDIT-ONLY. NO fixes.
- Phase 1: code-level scan 56 qb-* resources (paragraph 6) — output inventory table.
- Phase 2: runtime probe S1-S12 with founder paralelo (paragraph 7) — output diff matrix.
- Phase 3: classify findings + propose Path A/B/C/D (paragraph 8) — output recommendation.
- Phase 4: emit progress/PHASE_5_6_CROSS_SCRIPT_AUDIT.md (paragraph 10).

Founder paralelo: ejecuta 12 escenarios in-game S1-S12 mientras dev captura SQL diffs.

Boundary:
- NO touch contracts LOCKED v1.0.2 R2.
- NO patch qb-* resources (operator MIGRATION.md responsibility, founder decides).
- NO re-introduce OnMoneyPreHook sin amendment Round 3 explicit.

ETA: 2-3h scan + 2h runtime probe + 1h analysis = 5-6h total.

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
