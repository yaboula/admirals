# ⚙️ SONAR — FiveM Standards

> **Versión:** 1.2 (post Phase 8+9 namespace migration ejecutada + NOTICE r1 obsoleto removido + prose Admirals→SONAR canonical post S1.10.x). **SSoT vigente** — performance budgets + realtime sync + security threat model + anti-patterns + code review + monitoring + emergency procedures sin cambios foundational (pivot-agnostic). State Bag namespace `sonar_*` scheduled rename `sonar_*` Phase 8 per ADR-013.
> **Tipo:** Technical/Implementation. **Consolidado:** realtime sync + security threat model + performance budgets. Reglas absolutas para código FiveM de SONAR.
> **Documento padre:** `technical/01_architecture.md` v1.0 (firmado).
> **Documento hermano:** `technical/04_api_contracts.md` v1.1+ (post-pivot).
> **Documento hermano:** `technical/05_state_machines.md` v1.1+ (post-pivot).
> **Documento hermano próximo:** `qa/01_testing_protocol.md`.
> **ADRs relacionados:** ADR-006 (consolidation) + ADR-011 (pivot Admirals → SONAR) + ADR-012 (identity refinement) + **ADR-013 (namespace migration Phase 8+9 scheduled)**.
> **Estado:** firmado.

> **Lectura previa obligatoria:** `agents/00_BOOTSTRAP.md` v1.5, `technical/01_architecture.md` §14 (performance budgets mentioned) + §15 (security overview), **`planning/02_decision_log.md` ADR-013** (namespace migration execution).

---


## 0. Resumen ejecutivo

Este documento consolida **3 disciplinas FiveM-específicas** en un solo doc (per ADR-006): **realtime sync**, **security threat model**, **performance budgets**. Son las **reglas absolutas** que el código SONAR debe cumplir para funcionar correctamente en FiveM.

> **Filosofía:** FiveM es una plataforma con **límites duros** (resmon CPU budget, tick rate, memoria, network packets). Ignorar estos límites = server lag, crashes, exploits. **No hay "optimizar después"** — se cumple desde sprint 1.

Define:

- **Performance budgets** — resmon, FPS, memoria, network (targets y cómo medir).
- **Realtime sync patterns** — State Bags vs events, throttling, networked entities.
- **Security threat model** — top 15 amenazas + mitigations obligatorias.
- **Anti-patterns FiveM** — errores clásicos que causan lag/exploits.
- **Code review checklist** — validación pre-merge.
- **Monitoring tooling** — resmon, profiler, log aggregation.
- **Emergency procedures** — qué hacer cuando server degrada.

> **Por qué este doc importa:** sin estas reglas, SONAR shipea lag, crashes, o server vulnerable a modders. **Estas reglas no son opcionales** — son contrato de calidad minimum.

---

## 1. Filosofía FiveM standards

### 1.1 Los 5 principios

#### Principio 1 — Performance es feature, no optimization
> **Resmon < 1ms idle, < 5ms peak es requirement, no aspiration.**

Si un resource supera esto, **no shippea** hasta optimizar. No "lo arreglamos después".

#### Principio 2 — Server siempre desconfía del cliente
> **Todo cliente es potencial cheater.** Validación duplicada innecesaria es mejor que trust roto.

#### Principio 3 — State Bags > events para sync continuo
> **Si un valor cambia frequently y varios clients necesitan saberlo, es State Bag.** Events son para cosas discretas.

#### Principio 4 — Network packets son caros
> **Minimizar bytes sobre wire.** Patrones: diffs vs full state, debouncing, batching.

#### Principio 5 — Medir antes de optimizar, pero medir siempre
> **Nunca "optimizar" a ciegas.** Resmon + profiler + logs concretos.

### 1.2 Anti-principios

- ❌ "Performance lo arreglamos al final."
- ❌ "Cliente es confiable si es mi jugador."
- ❌ "Events para todo, simple."
- ❌ "Enviamos el full state, es pequeño."
- ❌ "Si no hay bug reportado, está OK."

---

## 2. Performance budgets

### 2.1 Budgets principales

| Métrica | Idle | Peak | Critical threshold |
|---|---|---|---|
| **Resmon server-side** (per resource) | <0.5ms | <2ms | 5ms |
| **Resmon client-side** (per resource) | <0.3ms | <1ms | 3ms |
| **Client FPS** (server running) | ≥60 | — | <30 |
| **Server tick rate** | 60 ticks/s | — | <20 ticks/s |
| **DB query p99** | <50ms | — | >500ms |
| **Network outbound per player** | <5 KB/s | <20 KB/s | >100 KB/s |
| **Memory server-side** (total all resources) | <500 MB | <1 GB | >2 GB |
| **Memory client-side NUI** | <150 MB | — | >300 MB |

### 2.2 Resource-specific budgets

| Resource | Idle budget | Peak budget |
|---|---|---|
| `sonar_core` | <0.3ms | <1ms |
| `sonar_bank` | <0.2ms | <1ms |
| `sonar_empresa` | <0.2ms | <1ms |
| `sonar_tablet` (client) | <0.5ms | <2ms |
| `sonar_tablet` (server) | <0.3ms | <1ms |
| `sonar_inventory` | <0.3ms | <1ms |
| `sonar_bakery` | <0.3ms | <1ms |
| `sonar_logistics` | <0.4ms | <1.5ms |
| All node resources combined | <2ms | <8ms |

### 2.3 NUI performance

| Métrica | Target | Critical |
|---|---|---|
| **Tablet open→ready time** | <300ms | <1s |
| **App navigate transition** | <150ms | <500ms |
| **Frame render NUI** (60 FPS target) | <16ms/frame | <33ms |
| **NUI memory** | <150 MB | <300 MB |
| **HTTP callbacks NUI↔Lua** | <50ms | <200ms |
| **Initial React bundle size** | <1 MB gzipped | <3 MB |

### 2.4 Database performance

| Query type | p50 | p99 | Critical |
|---|---|---|---|
| Read single row (indexed) | <2ms | <20ms | >100ms |
| Read paginated (20 rows) | <10ms | <50ms | >200ms |
| Write single row | <5ms | <30ms | >100ms |
| Transaction multi-row | <20ms | <100ms | >500ms |
| Aggregation query | <50ms | <300ms | >2s |

### 2.5 Cómo medir

#### 2.5.1 Resmon (FiveM built-in)

```
// En consola server
resmon

// Salida ejemplo:
// sonar_core     0.24 ms  (idle avg)
// sonar_bank     0.31 ms
// sonar_tablet   0.52 ms
```

**Regla:** monitor en producción cada día. Alertas si cualquier resource >threshold.

#### 2.5.2 Server profiler

```lua
-- En sonar_core
profiler.enterScope('bank_transfer')
-- ... lógica ...
profiler.exitScope()

-- Export periodic: profiler_report.json
```

#### 2.5.3 Client FPS

- **Script tracker:** contador FPS ongoing.
- Alert si FPS < 45 sostenido.

#### 2.5.4 DB slow query log

```sql
-- my.cnf
slow_query_log = 1
long_query_time = 0.5  -- 500ms
```

Review diario. Cada slow query → index missing o rewrite.

### 2.6 Performance budget enforcement

- **CI check (si posible):** bench resource antes merge.
- **Manual check pre-release:** resmon 4h stress test.
- **Prod monitoring:** alerts automáticas.

---

## 3. Realtime sync

### 3.1 State Bags vs Events — cuándo usar

#### 3.1.1 State Bags

> **Uso:** valores que cambian frequently, varios clients necesitan saber, persistentes a la entity.

**Ejemplos SONAR:**
- Ítem quality visible (graffiti color en bolsa harina).
- Empresa current shift open/closed (visible en letrero tienda).
- Player tier badge visible en HUD.
- Bakery oven temperature (visible near oven).
- Granja plot growth stage (visible en terreno).

**Pattern:**
```lua
-- Server
Entity(entityId).state:set('empresa_shift_open', true, true)  -- (key, value, replicated)

-- Client (auto-synced)
local isOpen = Entity(entityId).state.empresa_shift_open
```

#### 3.1.2 Events

> **Uso:** acciones discretas, notificaciones, commands.

**Ejemplos:**
- `sonar:bank:transfer_completed` — evento one-off.
- `sonar:empresa:hired` — notif event.
- `sonar:item:produced` — state-level event.

#### 3.1.3 Callbacks

> **Uso:** request/response síncrono, validación.

Ver `technical/04_api_contracts.md`.

#### 3.1.4 Decision table

| Situation | Use |
|---|---|
| Value changes frequently, visible a muchos | State Bag |
| Value changes rarely, one-off action | Event |
| Need reply from server | Callback |
| UI data Tablet (no physical entity) | Callback + push events |
| Cross-resource coordination | Event bus |
| Persistent state | DB + event emit when change |

### 3.2 State Bags — reglas SONAR

#### 3.2.1 Namespace

**Prefix `sonar_`** para evitar conflictos con otros resources.

```lua
Entity(id).state:set('sonar_quality', 'A', true)
-- NOT 'quality' — too generic
```

#### 3.2.2 Types limitados

- ✅ string, number, boolean.
- ✅ table simple (JSON-serializable).
- ❌ NO functions, no entity refs, no userdata.

#### 3.2.3 Size limits

- Cada state bag value: **<1 KB**.
- Total state bags per entity: **<10**.
- Si mayor, factorizar en entity children o callbacks.

#### 3.2.4 Replication rules

- **`replicated=true`** solo si client necesita.
- `replicated=false` para server-internal (avoids network).

#### 3.2.5 Change handlers

```lua
-- Client
AddStateBagChangeHandler('sonar_quality', nil, function(bagName, key, value)
  -- actualizar UI
end)
```

**Rule:** handlers deben ser **lightweight** — no lógica pesada en change handler (causa cascada perf).

### 3.3 Event throttling

#### 3.3.1 High-frequency events

Eventos que potencialmente spam (growth ticks, position updates):

**Pattern:** throttle declarado.

```lua
-- sonar_core/shared.lua
EVENT_THROTTLES = {
  ['sonar:granja:growth_tick'] = { max_per_sec = 1, burst = 3 },
  ['sonar:logistics:position_update'] = { max_per_sec = 2, burst = 5 },
}
```

**Enforcement:** `Bus.Publish` rejects si exceeds.

#### 3.3.2 Debouncing

Client UI actualizaciones (search input, slider drag):

```lua
-- Client
local debouncedSearch = debounce(function(query)
  lib.callback.await('sonar:mercado:search', 500, query)
end, 300)  -- 300ms debounce
```

### 3.4 Networked entities

#### 3.4.1 Cuándo networked

- Visible a múltiples players simultáneamente.
- Physical presence mapa.
- Requires sync position/rotation.

**Ejemplos:** drivers truck, animated props (harvester, bakery oven door).

#### 3.4.2 Cuándo NO networked

- Solo server-side (logic).
- Solo 1 player puede ver.
- No visual.

### 3.5 Packet size optimization

#### 3.5.1 Diffs vs full state

```lua
-- BAD: send full state
TriggerClientEvent('sonar:empresa:update', -1, {
  empresa_id = id,
  name = name,
  cash = cash,
  employees = longList,
  contracts = anotherList,
  -- ... 50 fields
})

-- GOOD: send only changed
TriggerClientEvent('sonar:empresa:cash_changed', -1, {
  empresa_id = id,
  new_cash = cash,
})
```

#### 3.5.2 Batching

Ejemplo: múltiples PEDs arriving retail — batch spawn events.

#### 3.5.3 Compression

Para payloads > 2KB: considerar JSON minify o msgpack.

---

## 4. Security threat model

### 4.1 Top 15 amenazas + mitigations

#### T1 — Client sends fake event/callback data
**Vector:** cheat tools inject arbitrary `TriggerServerEvent` calls.
**Mitigation:**
- Server valida SIEMPRE input.
- Rate limiting per player.
- Sanity checks (amount > 0, IDs exist, ownership correct).

#### T2 — Client modifies local state to grant items/money
**Vector:** memory editors change client-side values.
**Mitigation:**
- Server es SSoT. Client display es espejo, no fuente.
- State Bags replicated desde server → client (no client→server).

#### T3 — SQL injection
**Vector:** user input en query strings sin escape.
**Mitigation:**
- **Prepared statements obligatorio** (via oxmysql parameters).
- Zero tolerance strings con concatenation dinámica.
- Code review check.

#### T4 — Replay attacks
**Vector:** re-enviar request anterior (e.g., transfer).
**Mitigation:**
- `request_id` UUID idempotency (see `technical/04_api_contracts.md`).
- TTL en request_ids (e.g., 10 min).

#### T5 — Race conditions exploits
**Vector:** 2 requests simultáneos exploit timing (e.g., doble transfer same saldo).
**Mitigation:**
- Transactions atómicas.
- Row-level locking (SELECT ... FOR UPDATE).
- Optimistic concurrency (UPDATE WHERE status=?).

#### T6 — Rate abuse (spam, DDoS)
**Vector:** script envía 1000 calls/sec.
**Mitigation:**
- RateLimiter per player per bucket.
- Ban after N violations.

#### T7 — Privilege escalation
**Vector:** player intenta ejecutar admin commands.
**Mitigation:**
- Admin auth verified via role table + license check.
- Admin commands audit-logged.

#### T8 — Exploits específicos FiveM (injector, resource replace)
**Vector:** player carga resource custom cheats.
**Mitigation:**
- Server-side validation obligatoria.
- Anti-cheat tool (txadmin integrated).
- Log anomalies (e.g., position teleports, impossible actions).

#### T9 — Packet tampering (man-in-the-middle)
**Vector:** modificar network packets in-flight.
**Mitigation:**
- FiveM native encryption (default).
- Integrity checks server-side.

#### T10 — Session hijacking
**Vector:** otro player se hace pasar por X.
**Mitigation:**
- License ID verification SteamID native.
- Session tokens NO necessary (FiveM native).

#### T11 — Data exfiltration
**Vector:** player accede a DB dump.
**Mitigation:**
- DB credentials server-only.
- No export endpoints publicados.
- Admin export comandos audit-logged.

#### T12 — Doxxing / info leak
**Vector:** player comparte info otro player (IP, real name).
**Mitigation:**
- Server NO expone IPs a otros players.
- Player data (IBAN balance) solo visible al owner.
- Policy ban para dox intentado.

#### T13 — Economy exploits (money duplication, item duping)
**Vector:** bug causa money appear ex nihilo.
**Mitigation:**
- Double-entry bookkeeping (debit === credit).
- Audit log continuous integrity check.
- Ledger balance reconciliation cron.
- Transaction atomicity obligatoria.

#### T14 — Pricing manipulation
**Vector:** player edita precios client-side o exploita dynamic pricing.
**Mitigation:**
- Server sets prices (caps enforced).
- Player can negotiate but server validates final.

#### T15 — Inventory dupes
**Vector:** bug crea 2 items cuando debería ser 1.
**Mitigation:**
- Item creation SOLO via `sonar_inventory:GiveItem` export.
- Unique item_id UUID.
- Audit log creation.
- Daily integrity check (total items vs logs).

### 4.2 Authentication

- **Identity source:** FiveM license (Steam/Rockstar).
- **NO password** (FiveM native auth).
- **Session = `source`** (source id valid during session).
- **Cross-session = `citizen_id`** (CHAR(36) UUID persistente).

### 4.3 Authorization

**Role matrix:**

| Role | Scope |
|---|---|
| `player` | Basic — operate own IBAN, inventory, apply jobs |
| `employee` | + operate empresa mecánicas per role |
| `manager` | + hire/fire dentro department |
| `co_founder` | + estrategia empresa + voting |
| `founder` | + full control empresa + transfer/dissolve |
| `moderator` | + mute/ban chat + review reports |
| `admin` | + all commands + DB direct access |

**Implementación:**
```lua
if not Authorize(source, { 'founder' }, empresaId) then
  return { success = false, error_code = 'NOT_AUTHORIZED' }
end
```

### 4.4 Audit logging obligatorio

Categories que siempre auditan (ver `technical/04_api_contracts.md` §10.3):

- Money movements.
- Ownership changes.
- Permission changes.
- Admin actions.
- Dispute resolutions.
- Login/logout (basic).

**Tabla:** `sonar_audit_log` (ver `technical/03_db_schema.md`).

### 4.5 Incident response

1. **Detect** — monitoring alerta anomaly (e.g., massive transfer).
2. **Freeze** — admin comando freezes affected accounts/empresas.
3. **Investigate** — audit log + slow query log + ledger check.
4. **Remediate** — rollback vía compensating transactions.
5. **Post-mortem** — ADR documentando root cause + prevention.

---

## 5. Anti-patterns FiveM comunes

### 5.1 Performance killers

#### 5.1.1 `Wait(0)` loops sin necesidad

❌ **BAD:**
```lua
Citizen.CreateThread(function()
  while true do
    Wait(0)  -- 60 veces por segundo
    -- checking algo
  end
end)
```

✅ **GOOD:**
```lua
Citizen.CreateThread(function()
  while true do
    Wait(500)  -- cada 500ms basta
    -- checking algo
  end
end)
```

**Rule:** `Wait(0)` solo si **realmente** necesitas cada frame (animation, input polling).

#### 5.1.2 Check distance constante

❌ **BAD:** loop every frame checking distance to 10 MLOs.

✅ **GOOD:** event-driven (player entra zone → spawn logic).

#### 5.1.3 NUI polling constante

❌ **BAD:** React component fetching `/getBalance` cada 1s.

✅ **GOOD:** React listens `SendNUIMessage` push updates.

#### 5.1.4 State Bag change handlers pesados

❌ **BAD:**
```lua
AddStateBagChangeHandler('sonar_quality', nil, function(bag, key, val)
  -- Re-render toda la UI
  -- Query DB
  -- Calculate complex stuff
end)
```

✅ **GOOD:** lightweight handler. Dispara event si necesita más.

#### 5.1.5 Loops sin break condition

❌ **BAD:** `for i=1,10000 do ... end` cada tick.

✅ **GOOD:** batches con breaks.

### 5.2 Security anti-patterns

#### 5.2.1 Client-side validation only

❌ **BAD:** "El client ya verificó saldo, server just processes."

✅ **GOOD:** Server valida **todo** independent.

#### 5.2.2 Hardcoded credentials

❌ **BAD:**
```lua
local DB_PASS = "admin123"
```

✅ **GOOD:** convar/env.

#### 5.2.3 Log sensitive data

❌ **BAD:** `print("User password: " .. pwd)`.

✅ **GOOD:** log IDs only, never secrets.

#### 5.2.4 Trust `source` without verify

❌ **BAD:** `local citizenId = GetCitizenIdBySource(source)` sin check source existe.

✅ **GOOD:** verify source válido antes.

### 5.3 Sync anti-patterns

#### 5.3.1 Events para state continuo

❌ **BAD:** `TriggerClientEvent('sonar:quality_changed', -1, id, quality)` 10 veces por segundo.

✅ **GOOD:** State Bag.

#### 5.3.2 State Bags para eventos one-off

❌ **BAD:** toggle state bag para disparar acción.

✅ **GOOD:** event.

#### 5.3.3 Full state broadcasts

❌ **BAD:** send entire empresa object 1 vez/segundo a todos employees.

✅ **GOOD:** diffs + on-demand fetch.

### 5.4 DB anti-patterns

#### 5.4.1 SELECT *

❌ **BAD:** `SELECT * FROM sonar_bank_movements` (50 fields).

✅ **GOOD:** `SELECT id, amount, timestamp FROM ...`.

#### 5.4.2 N+1 queries

❌ **BAD:**
```lua
for _, empresa in ipairs(empresas) do
  local employees = DB.FetchAll('SELECT * FROM employees WHERE empresa_id = ?', { empresa.id })
end
```

✅ **GOOD:** JOIN o IN query.

#### 5.4.3 No indexes on filter columns

❌ **BAD:** Query `WHERE status = 'active' AND empresa_id = ?` sin index.

✅ **GOOD:** compound index (empresa_id, status).

#### 5.4.4 SQL ad-hoc fuera wrapper

❌ **BAD:** `MySQL.query('SELECT ...')` direct en feature resource.

✅ **GOOD:** via `DB.FetchOne/FetchAll` wrapper.

---

## 6. Code review checklist

### 6.1 Pre-merge obligatorio

Para cada PR / merge a main:

#### Performance
- [ ] No `Wait(0)` loops sin justificar.
- [ ] No polling UI (fetch repetido).
- [ ] No loops constantes client-side.
- [ ] Resmon midé <budget (per resource).
- [ ] NUI bundle size checked.

#### Security
- [ ] Server-side validation para todo callback.
- [ ] Prepared statements en queries.
- [ ] No credentials hardcoded.
- [ ] Rate limiting aplicado.
- [ ] Idempotency via request_id en writes.
- [ ] Audit log para money/ownership changes.

#### Sync
- [ ] State Bags vs events correctly chosen.
- [ ] Namespace `sonar_` (pre-Phase-8) / `sonar_` (post-Phase-8 per ADR-013) en state bags.
- [ ] Diff updates, not full state.
- [ ] Change handlers lightweight.

#### Code quality
- [ ] FSM transitions validadas.
- [ ] Error codes canónicos (no strings libres).
- [ ] Logging descriptive.
- [ ] Comments en español / términos técnicos inglés.
- [ ] Tests manual smoke pasado.

### 6.2 Admin-only features

Extra checks:
- [ ] Authorization server-side.
- [ ] Audit log con reason.
- [ ] Admin commands no accesibles por player regular.

---

## 7. Monitoring y tooling

### 7.1 Server monitoring

#### 7.1.1 Resmon dashboard

```
// tee a file
resmon > /var/log/admirals/resmon_YYYYMMDD.log
```

Cron hourly snapshot.

#### 7.1.2 Alerts

Setup via txAdmin or custom:

- Any resource > 5ms peak → alert.
- Any query > 1s → alert.
- Player count >90% cap → info.
- Error rate > 10/min → alert.

### 7.2 Client monitoring

- FPS tracker in-game (DEV mode visible).
- NUI profiler (React Devtools in dev).

### 7.3 DB monitoring

- Slow query log review daily.
- Connection pool utilization.
- Table size growth trends.

### 7.4 Application metrics

Custom metrics via `sonar_core`:

```lua
Metrics.Increment('transactions_processed')
Metrics.Gauge('active_empresas', count)
Metrics.Histogram('callback_duration_ms', duration)
```

Export JSON hourly / Grafana si advanced.

### 7.5 Log aggregation

- Server logs: `/var/log/admirals/server.log` (rotating daily).
- Audit log: DB table + export weekly archive.
- Error log: separate file with stack traces.

---

## 8. Emergency procedures

### 8.1 Server lag spike

**Symptoms:** resmon spike, FPS drop general.

**Steps:**
1. `resmon` → identify culprit resource.
2. If identifiable → `stop <resource>` temporalmente.
3. Log + investigate.
4. Root cause: loop, query, network flood.
5. Fix + restart resource.

### 8.2 Economy exploit detected

**Symptoms:** player con saldo anómalo, items inesperados.

**Steps:**
1. Freeze cuenta afectada.
2. Audit log review last 24h.
3. Ledger integrity check.
4. Rollback vía compensating transaction.
5. Bug fix code.
6. Post-mortem + ADR.

### 8.3 DB corruption

**Symptoms:** queries fail, data inconsistent.

**Steps:**
1. Read-only mode server.
2. Restore from backup.
3. Replay audit log.
4. Investigate root cause.

### 8.4 DDoS / spam

**Symptoms:** rate limits tripeando masivamente.

**Steps:**
1. Identify source (IPs, accounts).
2. Ban affected accounts.
3. Tighten rate limits temporary.
4. Logs para IP blocklist.

---

## 9. Validation tooling SONAR-specific

### 9.1 Dev smoke tests

```bash
# Run pre-release
bash scripts/smoke_test.sh
# - Connect test player
# - Transfer money
# - Create empresa
# - Hire employee
# - Produce item
# - Assert budgets not exceeded
```

### 9.2 Load simulation

Simulate 50 concurrent players via bots:

- Login, navigate, transfer, etc.
- Measure resmon + FPS impact.
- Target: 50 concurrent with 60 FPS + <5ms resmon total.

### 9.3 Economy integrity daily check

```sql
-- Total money in circulation should balance
SELECT SUM(balance) FROM sonar_bank_accounts
WHERE type IN ('personal', 'empresa', 'escrow')
```

Compare vs expected (initial seed + minted - sinks).

Diff > 0.01% threshold → investigate.

### 9.4 Lineage chain verification

```sql
-- Every delivered item should have lineage back to origin
SELECT COUNT(*) FROM sonar_items
WHERE status IN ('delivered', 'on_display', 'sold')
  AND lineage_json IS NULL
```

Expected: 0. If > 0 → bug.

---

## 10. Roadmap + estado

### 10.1 Roadmap FiveM standards

#### Oleada 1 (MVP)
- ✅ Performance budgets enforcement.
- ✅ Top 15 security threats mitigations implementadas.
- ✅ Realtime sync patterns consolidated (State Bags + events).
- ✅ Code review checklist activo.
- ✅ Basic monitoring (resmon, slow queries).

#### Oleada 2
- 🔜 Advanced monitoring (Grafana / metrics export).
- 🔜 Automated load testing bot suite.
- 🔜 Daily integrity checks cron.
- 🔜 Enhanced threat model (more specific exploits).

#### Oleada 3+
- 🔜 Cross-server federation security.
- 🔜 Advanced anti-cheat integration.

### 10.2 Estado del documento

- **Versión:** 1.2 (post Phase 8+9 namespace migration ejecutada + NOTICE r1 obsoleto removido + prose Admirals→SONAR canonical post S1.10.x).
- **Próxima revisión:** tras Sprint 2 (S2 Granja MVP + companies + T2 adapters) + smoke regression + post-S2 learnings (→ v1.3 si cambios estructurales o nuevos bridges T3).
- **Documento padre:** `technical/01_architecture.md`.
- **Documentos hermanos:** `04_api_contracts.md` v1.1+, `05_state_machines.md` v1.1+.
- **ADRs relacionados:** ADR-006 + ADR-011 + ADR-012 + **ADR-013**.

### 10.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Primera redacción consolidando 3 temas (realtime sync, security threat model, performance budgets) per ADR-006. 10 secciones. **Firmable.** |
| 1.1 | 2026-05-04 | Founder + Cascade (S1.9 EXTENDED) | **Light refresh post-pivot SONAR** (ADR-011 + ADR-012 + ADR-013). Title rebrand Admirals → SONAR. NOTICE r1 top-level (~45 líneas) establece: naming canonical producto + state bag namespace target state post-Phase-8 (`sonar_*`) + event prefixes canonical + DB tables canonical post-migration-009 per ADR-013 scheduled + voz + copy-in-production alineada ADR-012 §D3 (NO militar/capitán) + reading guide §1-§11 legacy vs canonical. §0 resumen + §6.1 sync checklist dual pre/post-Phase-8 + hermanos refs bumped v1.1+ + ADRs 006/011/012/013 linked + §FIN bump. **NO touched:** §1-§10 performance budgets + realtime sync patterns + security threat model + anti-patterns + code review + monitoring + emergency procedures (pivot-agnostic foundational engineering). Code namespace `sonar_*` preservado legacy ejemplos hasta Phase 8 execution per ADR-011 §5.5.8 excepciones. |
| 1.2 | 2026-05-04 | Founder + Cascade (S1.10.x) | **v1.2 — Phase 8+9 namespace migration ejecutada + NOTICE r1 obsoleto removido + prose Admirals→SONAR canonical.** S1.10 Phase 8+9 ejecutada (`admirals_*` → `sonar_*` code + DB tables + events + exports + server.cfg.example + 004 seed alias). S1.10.2 docs auto-rewrite Phase 1 (1075 identifiers code blocks). S1.10.3 docs Phase 2 surgical (NOTICE r1 block removed; prose "Admirals" → "SONAR" en §1-§N preservando refs históricos en este changelog; "Versión" + "FIN" bumped). Smoke harness inline admin commands cumulative S0+S1.1+S1.2+S1.3 = 10/10 PASS. **NO touched:** architecture + interfaces + contratos + tier + anti-patterns (pivot-agnostic). |

---

## 11. TL;DR

### Performance budgets absolutos

- Resmon server idle <0.5ms, peak <2ms per resource.
- Resmon client idle <0.3ms, peak <1ms per resource.
- Client FPS ≥60.
- DB p99 <50ms single row.
- NUI open <300ms, render <16ms/frame.

### Realtime sync cheat sheet

| Situation | Use |
|---|---|
| Continuous visible value | State Bag |
| Discrete action / notification | Event |
| Request/response | Callback |
| Cross-resource | Event bus |

### Security top 5 (must-have mitigations)

1. **Server validates everything** — no trust client.
2. **Prepared statements** — zero SQL injection tolerance.
3. **Idempotency via request_id** — no replay.
4. **Transactions atomic** — no race conditions.
5. **Audit log obligatorio** money + ownership.

### Anti-patterns top 10

1. `Wait(0)` loops no justificados.
2. NUI polling instead of push.
3. State Bag handlers pesados.
4. Events for continuous state.
5. SELECT * en prod.
6. N+1 queries.
7. SQL ad-hoc fuera wrapper.
8. Full state broadcasts frequent.
9. Client-side validation only.
10. Hardcoded credentials.

### Code review minimum checklist

- [ ] Resmon budget OK.
- [ ] Server validation present.
- [ ] Prepared statements.
- [ ] Rate limits applied.
- [ ] Idempotency writes.
- [ ] Audit log money/ownership.
- [ ] State Bags vs events correct.
- [ ] Error codes canónicos.

---

## Resumen ejecutivo (cierre)

Los **FiveM Standards SONAR (ex-Admirals)** son las reglas de calidad absolutas para todo código del proyecto:

- **Performance budgets** enforcement: resmon <1ms idle, <5ms peak, FPS ≥60, NUI <300ms open.
- **Realtime sync** disciplined: State Bags para continuos visibles, events para discretos, callbacks para request/response, diffs no full state.
- **Security threat model** top 15 amenazas con mitigations obligatorias: server-validates-all, prepared statements, idempotency, atomic transactions, audit logs, rate limits.
- **Anti-patterns** documentados (Wait(0), polling, N+1, state bag abuse, hardcoded creds).
- **Code review checklist** pre-merge obligatorio.
- **Monitoring tooling** resmon + slow queries + integrity checks daily.
- **Emergency procedures** para lag spikes, exploits, DB corruption, DDoS.

> Estos standards **no son opcionales**. Son el contrato de calidad que hace que SONAR shipee **server stable 4h+, FPS smooth, ledger íntegro, resistente a exploits**. Sin esto, el producto muere en closed beta.

---

*"FiveM tiene límites duros. Respetarlos desde sprint 1 es la diferencia entre un server que escala y uno que colapsa."*

**FIN DEL DOCUMENTO `technical/06_fivem_standards.md` v1.2**
