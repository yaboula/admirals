# 🔄 SONAR — State Machines (FSMs)

> **Versión:** 1.2 (post Phase 8+9 namespace migration ejecutada + NOTICE r1 obsoleto removido + prose Admirals→SONAR canonical post S1.10.x). **SSoT vigente** — filosofía + 16 FSMs core + transitions + guards + actions + persistence + recovery + testing + anti-patterns sin cambios foundational (pivot-agnostic). FSM table refs `sonar_*` + event triggers `sonar:*` scheduled rename `sonar_*` / `sonar:*` Phase 8+9 per ADR-013.
> **Tipo:** Technical/Implementation. Define todas las **Finite State Machines (FSM)** del producto — estados válidos, transiciones permitidas, guards, actions, persistence.
> **Documento padre:** `technical/01_architecture.md` v1.0 (firmado).
> **Documento hermano:** `technical/02_events_catalog.md` v1.1+ (post-pivot) — transiciones FSM disparan eventos.
> **Documento hermano:** `technical/03_db_schema.md` v1.1+ (post-pivot) — estado persiste en columnas `status`.
> **Documento hermano:** `technical/04_api_contracts.md` v1.1+ (post-pivot) — callbacks disparan transiciones.
> **Documento hermano próximo:** `technical/06_fivem_standards.md` v1.1+.
> **ADRs relacionados:** ADR-010 (hybrid audit_log) + ADR-011 (pivot) + ADR-012 (refinement) + **ADR-013 (namespace migration Phase 8+9 scheduled)**.
> **Estado:** firmado.

> **Lectura previa obligatoria:** `agents/00_BOOTSTRAP.md` v1.5, `technical/01_architecture.md`, `technical/04_api_contracts.md` v1.1+ §3, **`planning/02_decision_log.md` ADR-013** (namespace migration execution).

---


## 0. Resumen ejecutivo

Este documento define **todas las máquinas de estado** del producto SONAR (ex-Admirals). Cada entidad con lifecycle (empresa, contrato, escrow, ítem, plot granja, horno bakery, player session, etc.) **tiene una FSM formal** con:

- **Estados válidos** enumerados.
- **Transiciones permitidas** con guards (condiciones).
- **Actions** ejecutadas en cada transición (events, DB updates, side effects).
- **Estados terminales** (no more transitions).
- **Recovery** para estados stuck.

> **Filosofía:** **todo estado en SONAR es explícito y validado.** No hay "boolean flags dispersos" ni "status guessing from other fields". La DB tiene una columna `status` por entidad y el código **solo permite transiciones listadas aquí**.

Define:

- **16 FSMs core** cubriendo todas las entidades con lifecycle.
- **Notación estándar** (diagramas textuales + transitions table).
- **Persistence pattern** — cómo se guarda state en DB.
- **Event emission** — qué evento dispara cada transición.
- **Guards** — condiciones previas para transición.
- **Side effects** — qué pasa en cada transición (money movements, notifs).
- **Recovery strategies** — qué hacer con estados stuck.
- **Anti-patterns** comunes.
- **Testing** FSMs.

> **Por qué este doc importa:** sin FSMs formales, los devs implementan status ad-hoc y el producto acaba con estados inválidos en DB ("contrato en `completed` con escrow aún `locked`"), bugs imposibles de debuggear, y race conditions. Este doc **elimina esa clase de bugs**.

---

## 1. Filosofía FSMs SONAR

### 1.1 Principios

| # | Principio | Significado práctico |
|---|---|---|
| **F1** | **Un solo `status` por entidad** | La columna `status` es la SSoT del estado. Nada de boolean flags paralelos. |
| **F2** | **Transiciones explícitas** | Solo las transiciones listadas en este doc son legales. Cualquier otra → `INVALID_TRANSITION` error. |
| **F3** | **Guards validados server-side** | Cada transición tiene guards (condiciones). Server valida. |
| **F4** | **Actions atómicas** | Transición + side effects en MISMA transaction DB. |
| **F5** | **Eventos emitidos post-transition** | Cada transición dispara evento en bus para suscriptores. |
| **F6** | **Idempotency** | Attempting same transition twice con mismo request_id → no-op, mismo resultado. |
| **F7** | **Terminal states inmutables** | Estados terminales (`completed`, `cancelled`, `bankrupt`) no tienen transiciones salientes. |
| **F8** | **Audit log cada transición** | Changes en `status` siempre loguean quién, cuándo, por qué. |

### 1.2 Anti-principios

- ❌ **Boolean flags dispersos:** `is_active`, `is_paused`, `is_archived` en paralelo → pesadilla.
- ❌ **Status derivado de otros fields:** "está active si balance > 0 AND founder_online" → frágil.
- ❌ **Transiciones implícitas:** "si escribes X en field Y, se vuelve active" → no.
- ❌ **Mega-FSM** con 30 estados → descomponer en múltiples FSMs.
- ❌ **FSM sin persistence** (solo en memoria) → pérdida de estado al reiniciar server.

---

## 2. Notación y formato

### 2.1 Diagrama estados (textual)

Usamos notación simple tabular + flechas direccionales:

```
[initial] → state_A → state_B → [final]
              ↓
          state_C → [final]
```

### 2.2 Tabla transitions

Cada FSM incluye tabla:

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| `state_A` | `state_B` | Callback X | condition Y | INSERT Z, emit E |

### 2.3 Ejemplo completo

#### FSM: Traffic Light

**Estados:** `red`, `yellow`, `green`.
**Initial:** `red`.
**Terminal:** ninguno (cycle).

**Diagrama:**
```
red → green → yellow → red (cycle)
```

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| `red` | `green` | Timer 30s | — | SetLight(green) |
| `green` | `yellow` | Timer 25s | — | SetLight(yellow) |
| `yellow` | `red` | Timer 5s | — | SetLight(red) |

---

## 3. FSMs core transversales

### 3.1 FSM `empresa_lifecycle`

**Entidad:** `sonar_empresas`.
**Columna:** `status`.
**Estados:** `founded`, `active`, `suspended`, `bankrupt`, `sold`, `dissolved`.
**Initial:** `founded`.
**Terminal:** `bankrupt`, `dissolved`.

**Diagrama:**
```
founded → active ↔ suspended
                ↓
             bankrupt / sold / dissolved
```

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| — | `founded` | `sonar:empresa:foundEmpresa` callback | founding_fee paid, unique name | INSERT row, emit `empresa:founded` |
| `founded` | `active` | Auto (tras 24h probation) | no admin_hold | emit `empresa:activated` |
| `active` | `suspended` | Admin action | reason mandatory | freeze payroll, emit `empresa:suspended` |
| `suspended` | `active` | Admin unsuspend | resolution confirmed | unfreeze, emit `empresa:resumed` |
| `active` | `bankrupt` | Auto (cash < 0 + 7 days) o `declareBankruptcy` callback | — | liquidate, close IBAN, fire all, emit `empresa:bankrupt` |
| `active` | `sold` | `transferOwnership` callback completed | new founder accepts | transfer ownership, emit `empresa:sold` |
| `sold` | `active` | Auto (ownership confirmed) | — | new founder takes over |
| `active` | `dissolved` | Founder voluntary `dissolveEmpresa` callback | no active contracts | pay severances, return rent, emit `empresa:dissolved` |
| `suspended` | `dissolved` | Auto (60 days suspended) | — | same actions |

**Reglas cross-FSM:**
- `bankrupt` / `dissolved` → todos los active contracts de esta empresa → `cancelled` con penalties.
- `suspended` → salaries continue paying but no new actions (hire, contracts).

---

### 3.2 FSM `employee_lifecycle`

**Entidad:** `sonar_empresa_employees`.
**Columna:** `status`.
**Estados:** `hired`, `active`, `on_leave`, `terminated`, `resigned`.
**Initial:** `hired`.
**Terminal:** `terminated`, `resigned`.

**Diagrama:**
```
hired → active ↔ on_leave
              ↓
           terminated / resigned
```

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| — | `hired` | `sonar:empresa:hire` callback | valid role, salary in range | INSERT row, emit `empresa:employee_hired` |
| `hired` | `active` | First shift started | clocked in once | mark first_shift_at, emit `empresa:employee_activated` |
| `active` | `on_leave` | `setEmployeeLeave` callback | founder/mgr auth | pause salary accrual, emit event |
| `on_leave` | `active` | `returnFromLeave` callback | — | resume salary |
| `active` | `terminated` | `sonar:empresa:fire` callback | founder/mgr auth | pay severance, emit `empresa:employee_fired`, rep -2 empresa |
| `active` | `resigned` | `resignEmployee` callback (player) | notice period served | pay final salary, emit `empresa:employee_resigned` |
| `hired` | `terminated` | Probation fire | before 14 days | no severance |
| `on_leave` | `terminated` | Extended leave > 30 days | auto | standard severance |

---

### 3.3 FSM `item_lifecycle`

**Entidad:** `sonar_items`.
**Columna:** `status`.
**Estados:** `produced`, `in_inventory`, `in_transit`, `delivered`, `on_display`, `sold`, `consumed`, `expired`, `destroyed`.
**Initial:** `produced`.
**Terminal:** `sold`, `consumed`, `expired`, `destroyed`.

**Diagrama:**
```
produced → in_inventory → in_transit → delivered → on_display → sold / consumed
                                                               ↓
                                                            expired / destroyed (cualquier estado no-terminal)
```

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| — | `produced` | Node mechanic (bakery bake, granja harvest, etc.) | quality calculated | INSERT row + lineage, emit `item:produced` |
| `produced` | `in_inventory` | Auto (pickup o placed) | owner assigned | emit `item:stored` |
| `in_inventory` | `in_transit` | `sonar:logistics:pickup` | valid driver | change location owner=driver |
| `in_transit` | `delivered` | `sonar:logistics:deliver` | at destination | emit `item:delivered`, update ownership |
| `delivered` | `on_display` | Retail shelf placement | retail empresa | mark retail location |
| `on_display` | `sold` | Retail POS transaction | buyer pays | emit `item:sold`, transfer ownership player |
| `sold` | `consumed` | Consume action (eat, use) | owner action | emit `item:consumed`, delete row (or soft delete) |
| `*` (cualquiera no-terminal) | `expired` | TTL exceeded | `expires_at` < now | emit `item:expired`, quality → D |
| `*` | `destroyed` | Admin / damage | reason logged | emit `item:destroyed` |

**Reglas cross-FSM:**
- Quality puede degradar durante `in_inventory` / `in_transit` por tiempo/condiciones (ver `design/03_node_logistics.md`).
- Lineage chain se append cada transición con ownership change.

---

### 3.4 FSM `player_session`

**Entidad:** player connection (FiveM source).
**Columna (memoria):** state machine in-memory per session.
**Estados:** `connecting`, `authenticating`, `loading`, `active`, `tablet_open`, `idle`, `disconnecting`.
**Initial:** `connecting`.
**Terminal:** `disconnecting`.

**Diagrama:**
```
connecting → authenticating → loading → active ↔ tablet_open
                                             ↔ idle
                                             ↓
                                         disconnecting
```

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| — | `connecting` | Player joins server | — | allocate source id |
| `connecting` | `authenticating` | Steam ID verified | valid license | lookup `sonar_accounts` |
| `authenticating` | `loading` | Auth OK | account exists or new | load character, inventory, empresa |
| `loading` | `active` | All data loaded | character spawned | emit `session:active`, start tick |
| `active` | `tablet_open` | TAB key pressed | — | show Tablet NUI, focus |
| `tablet_open` | `active` | TAB key pressed / Tablet closed | — | hide Tablet NUI |
| `active` | `idle` | No input 5 min | — | dim screen, reduce updates |
| `idle` | `active` | Input detected | — | restore |
| `*` | `disconnecting` | Drop / quit | — | save state, emit `session:ending` |
| `disconnecting` | — | Cleanup done | — | free source |

---

## 4. FSMs financieras

### 4.1 FSM `escrow_lifecycle`

**Entidad:** `sonar_escrows` (see `technical/03_db_schema.md`).
**Columna:** `status`.
**Estados:** `created`, `locked`, `released`, `refunded`, `split`, `disputed`.
**Initial:** `created`.
**Terminal:** `released`, `refunded`, `split`.

**Diagrama:**
```
created → locked → released
                ↓  ↘
             refunded  disputed → released / refunded / split
                         ↓
                       split
```

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| — | `created` | `createEscrow` callback | buyer has funds | INSERT row, emit `bank:escrow_created` |
| `created` | `locked` | Auto (funds debited) | debit success | DEBIT buyer IBAN, CREDIT escrow IBAN, emit `bank:escrow_locked` |
| `locked` | `released` | `releaseEscrow` callback (release_to='seller') | buyer confirms or auto-release | CREDIT seller IBAN minus fee, emit `bank:escrow_released` |
| `locked` | `refunded` | `releaseEscrow` callback (release_to='buyer') | seller agrees or timeout + refund | CREDIT buyer IBAN, emit `bank:escrow_refunded` |
| `locked` | `disputed` | `disputeContract` callback | party disputes | freeze escrow, emit `dispute:opened` |
| `disputed` | `released` | Arbitration ruling seller-favor | arbitrator decision | CREDIT seller IBAN minus fee, emit ruling |
| `disputed` | `refunded` | Arbitration buyer-favor | — | CREDIT buyer IBAN |
| `disputed` | `split` | Arbitration split (e.g., 50/50, 75/25) | split_ratio set | CREDIT both IBANs per ratio |

**Guards detail:**
- `created → locked`: requires `DEBIT buyer IBAN` tx success.
- `locked → released`: requires either buyer confirmation OR auto-release time reached.
- `locked → disputed`: requires dispute window not expired (7 days post delivery).

---

### 4.2 FSM `contract_lifecycle` (B2B)

**Entidad:** `sonar_contracts`.
**Columna:** `status`.
**Estados:** `draft`, `proposed`, `negotiating`, `signed`, `fulfilling`, `completed`, `cancelled`, `disputed`, `defaulted`.
**Initial:** `draft`.
**Terminal:** `completed`, `cancelled`, `defaulted`.

**Diagrama:**
```
draft → proposed → negotiating → signed → fulfilling → completed
                              ↘        ↓         ↓ ↘
                             cancelled  disputed  defaulted
                                        ↓
                                    completed / cancelled / split
```

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| — | `draft` | `createContractDraft` callback | buyer empresa valid | INSERT draft |
| `draft` | `proposed` | `sendProposal` callback | all fields filled | notif seller, emit `contract:proposed` |
| `proposed` | `negotiating` | Seller `counterOffer` | modifiable fields | update terms, emit event |
| `negotiating` | `negotiating` | More counter-offers | — | iterate |
| `proposed` | `cancelled` | Either party cancels | pre-signature | emit `contract:cancelled` |
| `negotiating` | `cancelled` | Either party cancels | — | emit event |
| `proposed` | `signed` | Both sign | escrow created | create escrow, emit `contract:signed` |
| `negotiating` | `signed` | Both sign final terms | — | same |
| `signed` | `fulfilling` | Auto (first delivery initiated) | — | emit `contract:fulfilling` |
| `fulfilling` | `completed` | Last delivery confirmed | all quantities delivered + quality match | release escrow, emit `contract:completed`, +rep both |
| `fulfilling` | `disputed` | Quality issue / delay | dispute window open | freeze, escalate |
| `disputed` | `completed` | Arbitration favors seller | — | release escrow, continue |
| `disputed` | `defaulted` | Arbitration favors buyer | — | refund escrow, -rep seller, -rep empresa |
| `fulfilling` | `defaulted` | Grace period exceeded | no delivery after grace | refund escrow, emit `contract:defaulted` |

---

### 4.3 FSM `dispute_lifecycle`

**Entidad:** `sonar_disputes`.
**Columna:** `status`.
**Estados:** `opened`, `evidence_gathering`, `negotiating`, `arbitration`, `resolved`.
**Initial:** `opened`.
**Terminal:** `resolved`.

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| — | `opened` | `disputeContract` callback | contract active + valid reason | emit `dispute:opened`, notify parties |
| `opened` | `evidence_gathering` | Auto (24h post open) | — | collect tx logs, chat, quality scores |
| `evidence_gathering` | `negotiating` | Either party proposes settlement | — | private channel opened |
| `negotiating` | `resolved` | Both parties agree | — | apply settlement, emit `dispute:resolved` |
| `negotiating` | `arbitration` | Either party escalates | — | assign 3 arbitrators (Oleada 2+) |
| `evidence_gathering` | `arbitration` | Auto (48h passed) | — | skip negotiation |
| `arbitration` | `resolved` | Majority ruling | 2 of 3 agree | apply ruling, emit event |

---

## 5. FSMs mecánicas nodos

### 5.1 FSM `bakery_mixer`

**Entidad:** `sonar_bakery_stations` (subtype=mixer).
**Columna:** `status`.
**Estados:** `idle`, `filling`, `mixing`, `complete`, `emptied`, `out_of_order`.
**Initial:** `idle`.

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| `idle` | `filling` | `startMix` callback | employee has ingredients | lock mixer to player, start timer |
| `filling` | `mixing` | All ingredients added | recipe match | start mixing animation + timer |
| `mixing` | `complete` | Timer ends (60-120s) | — | output masa item_id spawned |
| `complete` | `emptied` | Player removes masa | — | return to idle after cleanup |
| `emptied` | `idle` | Auto | — | ready for next use |
| `*` | `out_of_order` | Damage / malfunction | admin / threshold | block use, emit event |
| `out_of_order` | `idle` | Repair action | repaired | reset |

---

### 5.2 FSM `bakery_oven`

**Estados:** `idle`, `preheating`, `ready`, `baking`, `done`, `cooling`, `out_of_order`.

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| `idle` | `preheating` | `startPreheating` | gas/electricity ok | start timer 3-5min |
| `preheating` | `ready` | Temperature reached | — | notify ready |
| `ready` | `baking` | `putInOven` callback | masa ready + temp ok | start baking timer |
| `baking` | `done` | Timer end | correct time | calc final quality, spawn baguette |
| `done` | `cooling` | `removeFromOven` | — | cooling timer |
| `cooling` | `idle` | Cooled down | — | ready next |

**Quality calc on `baking→done`:**
```lua
quality = base_quality_of_masa
  * (1 - temp_deviation_pct)
  * (1 - time_deviation_pct)
  * skill_multiplier
```

---

### 5.3 FSM `granja_plot`

**Entidad:** `sonar_granja_plots`.
**Columna:** `status`.
**Estados:** `fallow`, `prepared`, `planted`, `growing`, `mature`, `harvesting`, `harvested`, `diseased`.
**Initial:** `fallow`.

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| `fallow` | `prepared` | `prepareSoil` action | tractor available | +soil_quality_score |
| `prepared` | `planted` | `plantSeeds` action | seeds in inventory | subtract seeds, start growth timer |
| `planted` | `growing` | Auto (tick 1h) | — | advance growth stage |
| `growing` | `mature` | Growth timer ends (7 days) | — | signal ready harvest |
| `mature` | `harvesting` | `startHarvest` action | harvester available | lock plot |
| `harvesting` | `harvested` | Harvest complete | — | spawn wheat items, lineage origin |
| `harvested` | `fallow` | Auto (cleanup) | — | reset, +fallow_days |
| `growing` | `diseased` | Random disease event | no pesticide | quality degrades |
| `diseased` | `growing` | `applyPesticide` | pesticide in inventory | back to growing |

**Quality factors accumulating during `growing`:**
- `soil_quality_score` (0-100)
- `irrigation_score` (0-100)
- `fertilization_score` (0-100)
- `pest_control_score` (0-100)
- `weather_score` (0-100, system-controlled)

Final quality calculated on `harvesting→harvested`.

---

### 5.4 FSM `molino_batch`

**Entidad:** `sonar_molino_batches`.
**Columna:** `status`.
**Estados:** `created`, `loading`, `processing`, `complete`, `rejected`.
**Initial:** `created`.

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| — | `created` | Operator creates batch | input wheat available | INSERT batch, lineage capture |
| `created` | `loading` | Load wheat | wheat in silo | subtract wheat |
| `loading` | `processing` | Start mill | all wheat loaded | start timer + process |
| `processing` | `complete` | Timer ends | — | spawn flour items, quality calc |
| `processing` | `rejected` | Malfunction / bad input | — | emit event, no flour, refund wheat partial |

---

### 5.5 FSM `retail_shift`

**Entidad:** `sonar_retail_shifts`.
**Columna:** `status`.
**Estados:** `closed`, `opening`, `open`, `closing`, `emergency_closed`.
**Initial:** `closed`.

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| `closed` | `opening` | Cajero arrives + clocks in | opening hours | unlock door, inventory check |
| `opening` | `open` | Checks complete | — | spawn PED clients, emit `retail:opened` |
| `open` | `closing` | Cajero clocks out / closing hour | — | stop PED spawns, process pending |
| `closing` | `closed` | All PEDs out | — | lock, reconcile cash |
| `open` | `emergency_closed` | Admin / incident | — | freeze, investigate |

---

## 6. FSMs Tablet + UI

### 6.1 FSM `tablet_session`

**Estados:** `closed`, `opening_animation`, `open`, `app_navigating`, `closing_animation`, `closed`.

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| `closed` | `opening_animation` | TAB keybind | player_session=active | start open anim 300ms |
| `opening_animation` | `open` | Anim end | — | show home app, focus NUI |
| `open` | `app_navigating` | App switch tap | — | transition anim |
| `app_navigating` | `open` | Nav done | — | app mounted |
| `open` | `closing_animation` | TAB keybind | — | start close anim |
| `closing_animation` | `closed` | Anim end | — | hide NUI, unfocus |

---

### 6.2 FSM `app_lifecycle` (per app Tablet)

**Estados:** `unmounted`, `loading`, `ready`, `active`, `suspended`, `error`.

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| `unmounted` | `loading` | Navigate to app | — | fetch initial data |
| `loading` | `ready` | Data loaded | no error | render, awaiting input |
| `ready` | `active` | User interaction | — | same, just marked active |
| `active` | `suspended` | Navigate away | keep data | unmount UI but keep state cached |
| `suspended` | `active` | Navigate back | — | remount, refresh diff |
| `loading` | `error` | Fetch fail | — | show error UI, retry button |
| `error` | `loading` | Retry tap | — | refetch |

---

## 7. FSM Logística

### 7.1 FSM `logistics_job`

**Entidad:** `sonar_logistics_jobs`.
**Columna:** `status`.
**Estados:** `posted`, `accepted`, `loading`, `in_transit`, `delivering`, `delivered`, `failed`, `cancelled`.
**Initial:** `posted`.

**Transitions:**

| From | To | Trigger | Guard | Actions |
|---|---|---|---|---|
| — | `posted` | Empresa creates job | valid route | INSERT job, available to drivers |
| `posted` | `accepted` | Driver accepts | driver available | assign driver, lock |
| `posted` | `cancelled` | Empresa cancels | pre-accept | emit event |
| `accepted` | `loading` | Driver at pickup | within 50m | start loading anim |
| `loading` | `in_transit` | Load complete | items in truck | start GPS tracking |
| `in_transit` | `delivering` | Driver near destination | within 200m | notify destination |
| `delivering` | `delivered` | Unload complete | at destination | transfer ownership, pay driver |
| `in_transit` | `failed` | Truck destroyed / timeout | — | insurance claim, emit event |

---

## 8. Reglas cross-FSM

### 8.1 Cascade rules

> **Cuando una FSM transiciona, puede forzar transiciones en FSMs dependientes.**

#### 8.1.1 Empresa bankrupt → cascades

- All `employee_lifecycle` → `terminated` con severance zero.
- All `contract_lifecycle` active → `defaulted` con penalty.
- All `escrow_lifecycle` active → `refunded` to buyers.
- All `item_lifecycle` owned by empresa → transferred to bank collateral.

#### 8.1.2 Contract `defaulted` → cascades

- Related `escrow_lifecycle` → `refunded` (buyer favor).
- Seller reputation -5.
- Buyer reputation -1 (minor for involvement).

#### 8.1.3 Player disconnect during `logistics_job` in_transit

- Job status → `failed` (if no teammate takes over).
- Insurance auto-claim.

### 8.2 Interaction matrix

| Source FSM | Transition | Dest FSM | Forced transition |
|---|---|---|---|
| empresa | → `bankrupt` | all employees | → `terminated` |
| empresa | → `bankrupt` | all contracts | → `defaulted` |
| empresa | → `bankrupt` | all escrows | → `refunded` |
| contract | → `defaulted` | escrow | → `refunded` |
| contract | → `completed` | escrow | → `released` |
| item | → `expired` | on_display in retail | auto remove from shelf |

---

## 9. Persistence

### 9.1 DB column pattern

Toda entidad con FSM tiene:

```sql
status VARCHAR(32) NOT NULL DEFAULT 'initial_state',
status_changed_at INT UNSIGNED NOT NULL,
status_changed_by CHAR(36) NULL,  -- citizen_id o 'system'
status_change_reason VARCHAR(255) NULL,
```

### 9.2 Audit log

Cada transición insert row:

```sql
INSERT INTO sonar_fsm_transitions (
  entity_type,     -- 'empresa' / 'contract' / etc.
  entity_id,
  from_state,
  to_state,
  trigger,         -- 'callback_X' / 'auto' / 'admin'
  actor_id,
  reason,
  timestamp,
  metadata         -- JSON con params
)
```

### 9.3 Recovery stuck states

Si un FSM se queda en estado intermedio (e.g., `mixing` por 24h):

1. **Watcher process** detecta (query "status = 'mixing' AND updated > 1h").
2. **Alertar admin** vía log.
3. **Auto-recovery** si posible (e.g., `mixing → complete` con quality reducida 50%).
4. **Manual intervention** si auto-recovery imposible.

### 9.4 Transaction atomicity

Toda transición:

```lua
DB.Transaction({
  -- 1. Validate guards (SELECT)
  { query = 'SELECT status FROM X WHERE id = ?', params = { id } },
  -- 2. Apply transition
  { query = 'UPDATE X SET status = ?, status_changed_at = ? WHERE id = ? AND status = ?',
    params = { to_state, now, id, from_state } },
  -- 3. Insert audit log
  { query = 'INSERT INTO sonar_fsm_transitions (...) VALUES (...)',
    params = { ... } },
  -- 4. Apply side effects (money movements, etc.)
  ...
})

-- Si TX OK → emit event bus post-commit
```

---

## 10. Recovery + edge cases

### 10.1 Orphan states

**Problema:** entidad en estado intermedio sin trigger que la avance.

**Ejemplos:**
- `locked` escrow sin buyer ni seller active (ambos abandoned).
- `growing` plot con dueño empresa bankrupt.
- `in_transit` job con driver banned.

**Solución:**
- Watcher process daily.
- Timeout-based auto-transitions.
- Admin commands para force transition.

### 10.2 Race conditions

**Problema:** 2 transiciones simultáneas mismo entity.

**Ejemplo:** cajero atiende cliente + founder cierra tienda simultáneamente.

**Solución:**
- Row-level lock en SELECT ... FOR UPDATE.
- Atomic transitions via `UPDATE ... WHERE status = ?` (optimistic locking).

### 10.3 Server restart mid-transition

**Problema:** server crash entre steps transition.

**Solución:**
- Audit log escrito ANTES de side effects.
- Recovery al boot: detectar audit log sin side effect ejecutado → retry.

### 10.4 Eventos perdidos

**Problema:** bus event emit fail.

**Solución:**
- Eventos crítico con outbox pattern: DB row → process later.
- Retry con exponential backoff.

---

## 11. Testing FSMs

### 11.1 Test matrix

Cada FSM: **Nstates × Ntransitions** test cases.

Para cada transición:
- ✅ Happy path (guard passes).
- ❌ Guard fails (invalid transition).
- ❌ Invalid from_state (e.g., `completed → fulfilling`).
- ✅ Idempotency (same trigger twice).
- ✅ Concurrency (2 simultaneous).

### 11.2 Tooling

```lua
-- Test helper
FSM.Test = {
  AttemptTransition = function(entityId, toState, triggerParams)
    -- returns { success, error, actual_state }
  end,
  AssertState = function(entityId, expected)
  end,
  GetAuditTrail = function(entityId)
  end,
}
```

### 11.3 Integration tests

Scenarios end-to-end combining FSMs:

- **Scenario: Happy B2B contract.** draft → proposed → signed → fulfilling → completed + escrow released.
- **Scenario: Bakery bankruptcy.** empresa active → bankrupt + all 5 employees terminated + 2 contracts defaulted + 3 escrows refunded.
- **Scenario: Contract dispute.** signed → fulfilling → disputed → arbitration → resolved (split 75/25).

---

## 12. Anti-patterns

### 12.1 FSM design

- ❌ **Boolean flags paralelos** (`is_active`, `is_paused`). Usar único `status`.
- ❌ **Estados "otros"** vagos. Cada estado tiene semántica clara.
- ❌ **Transiciones no documentadas.** Solo las listadas son legales.
- ❌ **Side effects inconsistentes.** Mismo trigger, mismas actions.
- ❌ **Mega-FSMs 30 estados.** Descomponer.
- ❌ **Status derivado de otros fields.** Status es source of truth.

### 12.2 Implementation

- ❌ **Skip audit log** para transiciones.
- ❌ **No transactions** → inconsistencies.
- ❌ **Guards client-side only** → tampering.
- ❌ **No timeouts** para estados intermedios → stuck forever.
- ❌ **No recovery strategy** para crashes.

### 12.3 Testing

- ❌ **Testing solo happy path.**
- ❌ **No test para concurrency.**
- ❌ **No test cross-FSM cascades.**

---

## 13. Roadmap + estado

### 13.1 Roadmap FSMs coverage

#### Oleada 1 (MVP)
- ✅ `empresa_lifecycle`
- ✅ `employee_lifecycle`
- ✅ `item_lifecycle`
- ✅ `player_session`
- ✅ `escrow_lifecycle` (básico)
- ✅ `bakery_mixer` + `bakery_oven`
- ✅ `tablet_session` + `app_lifecycle`

#### Oleada 2
- 🔜 `contract_lifecycle` completo (B2B player↔player).
- 🔜 `dispute_lifecycle`.
- 🔜 `granja_plot`, `molino_batch`, `retail_shift`.
- 🔜 `logistics_job`.
- 🔜 Cross-FSM cascade rules formalizadas.

#### Oleada 3+
- 🔜 FSMs para features avanzadas (federation, marketplace global).

### 13.2 Estado del documento

- **Versión:** 1.0 (firmable — completo, 13 secciones, 16 FSMs core).
- **Próxima revisión:** primer sprint Oleada 1 con code real validará FSMs.
- **Documento padre:** `technical/01_architecture.md`.
- **Documento hermano:** `technical/04_api_contracts.md`.

### 13.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Primera redacción. 13 secciones, 16 FSMs core (empresa, employee, item, session, escrow, contract, dispute, bakery_mixer, oven, granja_plot, molino_batch, retail_shift, tablet, app, logistics), cross-FSM cascade rules, persistence, recovery, testing, anti-patterns. **Firmable.** |
| 1.2 | 2026-05-04 | Founder + Cascade (S1.10.x) | **v1.2 — Phase 8+9 namespace migration ejecutada + NOTICE r1 obsoleto removido + prose Admirals→SONAR canonical.** S1.10 Phase 8+9 ejecutada (`admirals_*` → `sonar_*` code + DB tables + events + exports + server.cfg.example + 004 seed alias). S1.10.2 docs auto-rewrite Phase 1 (1075 identifiers code blocks). S1.10.3 docs Phase 2 surgical (NOTICE r1 block removed; prose "Admirals" → "SONAR" en §1-§N preservando refs históricos en este changelog; "Versión" + "FIN" bumped). Smoke harness inline admin commands cumulative S0+S1.1+S1.2+S1.3 = 10/10 PASS. **NO touched:** architecture + interfaces + contratos + tier + anti-patterns (pivot-agnostic). |

---

## 14. TL;DR

### Los 16 FSMs core

| # | FSM | Estados | Entidad DB |
|---|---|---|---|
| 1 | `empresa_lifecycle` | 6 | empresas |
| 2 | `employee_lifecycle` | 5 | empresa_employees |
| 3 | `item_lifecycle` | 9 | items |
| 4 | `player_session` | 7 | memoria |
| 5 | `escrow_lifecycle` | 6 | escrows |
| 6 | `contract_lifecycle` | 9 | contracts |
| 7 | `dispute_lifecycle` | 5 | disputes |
| 8 | `bakery_mixer` | 6 | bakery_stations |
| 9 | `bakery_oven` | 7 | bakery_stations |
| 10 | `granja_plot` | 8 | granja_plots |
| 11 | `molino_batch` | 5 | molino_batches |
| 12 | `retail_shift` | 5 | retail_shifts |
| 13 | `tablet_session` | 5 | memoria |
| 14 | `app_lifecycle` | 6 | memoria |
| 15 | `logistics_job` | 8 | logistics_jobs |
| 16 | Cross-FSM cascades | — | matrix |

### Reglas absolutas

- 🔒 Único `status` por entidad (no boolean flags paralelos).
- 🔑 Transiciones solo las listadas.
- ⚛ Guards validados server-side.
- ⚡ Actions atómicas (misma TX).
- 📡 Evento bus post-transition.
- 🔁 Idempotency via request_id.
- 🏁 Terminal states inmutables.
- 📝 Audit log cada transición.

### Anti-patterns top

- ❌ Boolean flags paralelos.
- ❌ Status derivado de otros fields.
- ❌ Skip audit log.
- ❌ Guards client-side only.
- ❌ No timeouts estados intermedios.
- ❌ Mega-FSMs.

---

## Resumen ejecutivo (cierre)

Las **State Machines SONAR (ex-Admirals)** formalizan el ciclo de vida de cada entidad del sistema:

- **16 FSMs core** cubren empresa + employee + items + sessions + financieras + mecánicas nodos + tablet + logistics.
- **Notación estándar** (tabla transitions con from/to/trigger/guard/actions).
- **Cross-FSM cascade rules** explícitas (bankrupt → defaults todos contracts).
- **Persistence pattern** (columna status + audit log + transactions atómicas).
- **Recovery strategies** para orphan states, race conditions, server crashes, eventos perdidos.
- **Testing matrix** exhaustivo (happy + guards + idempotency + concurrency).
- **Anti-patterns** documentados (boolean flags, status derivado, skip audit, mega-FSMs).

> **Cada status en SONAR es explícito, validado, auditado.** Sin esto, la economía se corrompe silenciosamente (empresas zombie, escrows huérfanos, contratos fantasmas). Con esto, el ledger es íntegro.

---

*"Un estado sin transitions documentadas es un bug esperando a pasar."*

---

## 15. Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026 (Oleada 0 firma) | Founder + Cascade | Primera redacción completa 14 secciones, 16 FSMs core (empresa + employee + escrow + contract + items + sessions + mecánicas nodos + tablet + logistics), notación estándar transitions tables con from/to/trigger/guard/actions, cross-FSM cascade rules, persistence pattern (column status + audit log + transactions atómicas), recovery strategies, testing matrix exhaustivo, anti-patterns. **Firmable Oleada 0.** |
| 1.1 | 2026-05-04 | Founder + Cascade (S1.9 EXTENDED) | **Light refresh post-pivot SONAR** (ADR-011 + ADR-012 + ADR-013). Title rebrand Admirals → SONAR. NOTICE r1 top-level (~70 líneas) establece: naming canonical FSM audit table (`sonar_fsm_transitions`) + FSM entity tables 16 FSMs (mapping 1:1 todas tablas rename) + event triggers canonical (`sonar:*` rename) + state strings + transitions + guards + cascade rules INVARIANTES pre/post + escrow FSM S1 shipped reference (5 estados + transitions whitelist operacionalmente probada 14/14 smoke S1.3) + transaction atomicity pattern unchanged + voz neutral error messages ADR-012 §D3 + migration execution schedule Phase 8+9 (next session) + reading guide §1-§14 legacy vs canonical. §0 resumen + §Filosofía + §cierre + §Cada status rebrand + hermanos refs bumped v1.1+ + ADRs 010/011/012/013 linked. **NO touched:** §1-§14 filosofía + 16 FSMs definiciones + transitions + guards + actions + cross-FSM cascade + persistence + recovery + testing + anti-patterns (pivot-agnostic foundational FSM design). Table refs `sonar_*` + event triggers `sonar:*` preservados legacy inline hasta Phase 8+9 execution per ADR-011 §5.5.8 excepciones. Próxima v1.2 post-Phase-8+9: 16 FSMs + audit table + ejemplos SQL rename 1:1 inline body. |

---

---

## §X.NEW — Bank Phase A Extension (LOCKED 2026-05-06 BANK-BE.LOCK.R1)

> **Estado:** v1.3.1 LOCKED — extensión Bank-specific Phase A R1 amendment hardening. Sin tocar §1-§N foundational pivot-agnostic.
> **Owner:** Backend Lead joint con DB Lead (sessions BANK-BE.0 / BANK-BE.1 / BANK-BE.LOCK / BANK-BE.AMEND.1 / BANK-BE.LOCK.R1).
> **Scope:** SONAR Bank financial-grade — **8 FSMs core Bank** + R1 hardening: H005 (FSM #1 escrow lifecycle release_amount > 0 boundary guard 3 transitions) + M005 (FSM #8 idempotency orphan TTL `orphan_purged` state + cron PurgeOrphans 5min + audit entry).

### Canonical reference

→ **`@docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md`** (v1.0.1 R1 LOCKED — 8 FSMs + H005 escrow guard hardening + M005 idempotency orphan TTL purge)

### Por qué documento dedicado en sub-directorio

- **Aislamiento dominio (M4 mandato founder):** FSMs Bank tienen invariants financial-grade (e.g. transaction_lifecycle requires reconciliation_correlation FSM completion before COMMIT, idempotency_lifecycle requires unique key constraint enforcement, bridge_correlation_mutex requires CP2 path #1 only).
- **Joint ownership Backend + DB Lead:** persistence patterns están en DB Schema v2.0 LOCKED PROVISIONAL (FSM tables 7 — accounts/transactions/reconciliation/fraud_reviews/govt_decisions/admin_audits/idempotency_keys). Backend Lead define semantics + transitions + guards.
- **Pivot-agnostic preservado:** §1-§N de este SSoT padre son foundational (16 FSMs core SONAR + transitions schema + guards/actions semantics + recovery strategies + testing matrix + anti-patterns) — Bank Phase A **extiende** con 8 FSMs Bank-specific.

### Cross-references

- **Sibling Bank contracts:** `@docs/technical/bank_phase_a/README.md`.
- **Pivot SSoTs hermanos extendidos:** `@docs/technical/02_events_catalog.md` v1.3, `@docs/technical/04_api_contracts.md` v1.3, `@docs/technical/07_bridges_compatibility.md` v1.3.
- **DB Schema upstream:** `@docs/technical/03_db_schema.md` v2.0 LOCKED PROVISIONAL (7 FSM tables backing).
- **ADR anchor:** `@docs/planning/02_decision_log_part2.md` ADR-018.
- **Handoffs:** H1 DB→Backend received; H2 Backend→Security emitted.

### Sign-off Bank Phase A extension

| Rol | Status | Fecha |
|---|---|---|
| **Founder yaboula** | ✅ APPROVED (BANK-BE.LOCK + BANK-BE.LOCK.R1 green-light) | 2026-05-06 |
| **Backend Lead (Cascade)** | ✅ self-attested (owner) v1.0.1 R1 | 2026-05-06 |
| **DB Lead** | ⚠️ implicit endorsement via DB Schema v2.0 LOCKED PROVISIONAL consistency (no schema migration impact R1 — confirmed `ttl_expires_at` column reuse for M005 orphan purge) | 2026-05-06 |
| **Security Lead** | ✅ ACCEPTED-FINAL (BANK-SEC.1 re-audit PASS veredicto + `08_audit_hooks.md` v0.2) | 2026-05-06 |
| **Frontend Lead** | ⏳ PENDING H3 future (consume state ENUMs para UI badges) | — |

**Amendments post-LOCKED** requieren formal Round 1/2/3 protocol.

---

## Versioning v1.3 entry

| 1.3 | 2026-05-06 | Founder + Backend Lead (BANK-BE.LOCK) | **v1.3 LOCKED — Bank Phase A extension §X.NEW.** Append pointer hacia `docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md` v1.0 LOCKED (8 FSMs Bank). Sign-off founder + Backend Lead. DB Lead joint endorsement deferred. **NO touched** §1-§N foundational pivot-agnostic 16 FSMs core SONAR. |
| 1.3.1 | 2026-05-06 | Founder + Backend Lead + Security Lead (BANK-BE.LOCK.R1) | **v1.3.1 LOCKED — Bank Phase A R1 amendment hardening pointer.** Append updated pointer C-BE-03 v1.0.1 R1 LOCKED: H005 (FSM #1 escrow lifecycle 3 transitions hardened with `release_amount > 0 AND release_amount <= escrow_balance` boundary guard) + M005 (FSM #8 idempotency lifecycle NEW `orphan_purged` state + `ttl_expires_at` column reuse + cron `PurgeOrphans` 5min sweep + `event_type='idempotency_orphan_purged'` audit entry). Sin schema migration impact (DB Lead consultative confirmed). Sign-off founder + Backend Lead + Security Lead PASS (BANK-SEC.1 re-audit veredicto). **NO touched** §1-§N foundational pivot-agnostic 16 FSMs core SONAR. |

---

**FIN DEL DOCUMENTO `technical/05_state_machines.md` v1.3.1 LOCKED (Bank Phase A R1 extension)**
