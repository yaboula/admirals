# Sprint 0 — Smoke Test Protocol (10 pasos)

> **Scope:** valida que `sonar_bridges` v0.2.0 + `sonar_core` v0.1.0 + migrations 001/002 + subsistemas (Logger, Metrics, DB, EventBus, RateLimiter, Migrations) arrancan, interoperan y cumplen performance budgets.
>
> **Ejecutor:** founder (yaboula).
> **Prerrequisito:** servidor FiveM limpio con `oxmysql`, `qbx_core` (o framework T1), `ox_inventory`, `ox_target`, `ox_lib`, `lb-phone` habilitados en `server.cfg`. `sonar_bridges` + `sonar_core` añadidos a `ensure`.
> **Duración estimada:** 20-30 min primera pasada.
>
> **Criterio sign-off Sprint 0:** 10/10 pasos ✅.

---

## Setup previo

1. Verifica MariaDB/MySQL running + DB `sonar` existe (vacía o con migrations previas).
2. `server.cfg` incluye:
   ```
   set mysql_connection_string "mysql://sonar:PASSWORD@127.0.0.1:3306/sonar?charset=utf8mb4"
   set sonar_env "development"
   ensure oxmysql
   ensure sonar_bridges
   ensure sonar_core
   ```
3. Arranca server desde consola (no background) para ver logs en vivo.

---

## Paso 1 — Pre-flight: server arranca clean, bridges v0.2.0 ready, oxmysql conecta

**Acción:**
Start server. Observa console primeros 10s.

**Expectativa:**
- `[oxmysql] Database server connection established!`
- `[sonar_bridges] SONAR Bridges v0.2.0 booting...`
- Panel boot bridges: `Bank → qbox [T1 OFFICIAL]` (o tier que detecte).
- `[sonar_core] sonar_core v0.1.0 booting...`
- Logs INFO secuenciales: `Logger ready`, `Metrics ready`, `DB wrappers ready`, `EventBus ready`, `RateLimiter ready`, `Migrations runner ready`.
- Sin ERRORS.

**✅ Pass si:** panel SONAR Bridges impreso + 6 módulos ready + sonar_core boot report final ("sonar_core is READY").

---

## Paso 2 — Migration 001 aplicada (sonar_schema_versions existe + 1 row con hash)

**Acción:**
Conecta a DB con cliente SQL (TablePlus/MySQL Workbench/CLI):
```sql
SHOW TABLES LIKE 'sonar_schema_versions';
SELECT * FROM sonar_schema_versions WHERE version = 1;
```

**Expectativa:**
- Tabla existe con schema per `001_schema_versions.sql`.
- 1 row: `version=1, filename='001_schema_versions.sql', checksum` (64 hex chars), `duration_ms > 0`.

**✅ Pass si:** row presente + checksum no vacío + applied_by = `migrations_runner`.

---

## Paso 3 — Migration 002 aplicada (3 tablas + 1 row schema_versions per migration)

**Acción:**
```sql
SHOW TABLES LIKE 'sonar_%';
SELECT version, filename, applied_at, LEFT(checksum, 16) AS chk_prefix, duration_ms
  FROM sonar_schema_versions ORDER BY version;
```

**Expectativa:**
- 4 tablas: `sonar_schema_versions`, `sonar_accounts`, `sonar_audit_log`, `sonar_bridge_idempotency`.
- 2 rows en `sonar_schema_versions` (version 1 + 2).
- `sonar_accounts` schema exacto: id CHAR(36) PK, char_id, framework_source, alias, created_at, updated_at, last_login_at + 3 indexes.
- `sonar_audit_log` schema per 002.
- `sonar_bridge_idempotency` schema per 002.

**✅ Pass si:** las 4 tablas existen + 2 rows tracking + schemas match spec.

---

## Paso 4 — Migration idempotency (re-arrancar → 0 nuevas rows, hash match, log "already applied")

**Acción:**
- Restart el servidor (`quit` + rearrancar). NO tocar DB manualmente.
- Observa console boot segunda vez.

**Expectativa:**
- Logs INFO: `Migration 001_schema_versions.sql already applied (skip)` + `Migration 002_foundation_tables.sql already applied (skip)`.
- Sin ERRORS, sin WARN de checksum mismatch.
- SQL: `SELECT COUNT(*) FROM sonar_schema_versions;` sigue = 2.

**✅ Pass si:** 2 skips + 0 applied + 0 errors + row count inmutado.

---

## Paso 5 — EventBus smoke (Subscribe + Publish round-trip + audit log entry)

**Acción:**
Ejecuta en consola server (requiere pequeño script ad-hoc o `txAdmin` eval):
```lua
-- En console o txAdmin live console:
SONAR.Bus.Subscribe('test:ping', function(payload)
  print('^2[TEST] Got ping: ' .. tostring(payload.msg) .. ' id=' .. payload._event_id)
end, { label = 'smoke_test' })

SONAR.Bus.Publish('test:ping', { msg = 'hola', actor = 'smoke' }, { audit = true })
```

**Expectativa:**
- Console: `[TEST] Got ping: hola id=<uuid v4>` (UUID con formato `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`).
- Logs: entry AUDIT `bus.publish/test:ping actor=smoke`.
- `/sonar_metrics` (admin): muestra `bus.publishes.test:ping = 1`, `bus.handler_latency_ms.test:ping` histogram con 1 sample.

**✅ Pass si:** handler ejecutó + UUID válido + metric counter + audit entry.

---

## Paso 6 — DB wrappers smoke (Insert account → Fetch → Scalar → Transaction rollback)

**Acción:**
```lua
-- Insert
local id = SONAR.DB.Insert(
  'INSERT INTO sonar_accounts (id, char_id, framework_source, alias, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
  { '11111111-1111-4111-8111-111111111111', 'TEST_CHAR_1', 'manual', 'smoke_tester', os.time(), os.time() }
)
print('Insert affected:', id)

-- FetchOne
local row = SONAR.DB.FetchOne('SELECT id, alias FROM sonar_accounts WHERE char_id = ?', { 'TEST_CHAR_1' })
print('Fetch:', row and row.alias or 'nil')

-- Scalar COUNT
local count = SONAR.DB.Scalar('SELECT COUNT(*) FROM sonar_accounts', {})
print('Count:', count)

-- Transaction con rollback forzado (duplicate key en 2ª query)
local ok = SONAR.DB.Transaction({
  { query = 'UPDATE sonar_accounts SET alias = ? WHERE char_id = ?', values = { 'shouldbereverted', 'TEST_CHAR_1' } },
  { query = 'INSERT INTO sonar_accounts (id, char_id, framework_source, alias, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
    values = { '11111111-1111-4111-8111-111111111111', 'DUP_TEST', 'manual', 'dup', os.time(), os.time() } },  -- dup PK
})
print('Transaction ok:', ok)

-- Verify rollback: alias sigue 'smoke_tester'
local check = SONAR.DB.FetchOne('SELECT alias FROM sonar_accounts WHERE char_id = ?', { 'TEST_CHAR_1' })
print('Alias post-rollback:', check.alias)

-- Cleanup
SONAR.DB.Execute('DELETE FROM sonar_accounts WHERE char_id = ?', { 'TEST_CHAR_1' })
```

**Expectativa:**
- Insert afecta 1 row.
- Fetch devuelve alias = `smoke_tester`.
- Count ≥ 1.
- Transaction returns `ok = false` (rollback por duplicate PK).
- **Alias post-rollback = `smoke_tester`** (la primera query del TX fue rollbackeada).
- Cleanup OK.

**✅ Pass si:** rollback preservó estado original + metrics `db.queries.*` incrementan.

**Bonus validación prepared-statement enforcement:**
```lua
local ok, err = pcall(function()
  SONAR.DB.FetchOne('SELECT * FROM sonar_accounts WHERE id = "' .. 'hardcoded' .. '"', {'hardcoded'})
end)
print('Inline concat rejected:', not ok)  -- expected: true
```

---

## Paso 7 — RateLimiter smoke (Check 10 calls/sec → bloquea 11ª)

**Acción:**
```lua
SONAR.Rate.RegisterBucket('smoke.test', { max = 10, window_sec = 5 })

local results = {}
for i = 1, 12 do
  results[i] = SONAR.Rate.Check('smoke_id', 'smoke.test')
end
for i, allowed in ipairs(results) do
  print(('  call %d: %s'):format(i, allowed and 'ALLOW' or 'BLOCK'))
end
```

**Expectativa:**
- Calls 1-10: ALLOW.
- Calls 11-12: BLOCK.
- `/sonar_metrics` (admin): `rate.allowed.smoke.test = 10`, `rate.blocked.smoke.test = 2`.

**✅ Pass si:** distribución exacta 10 allow / 2 block.

---

## Paso 8 — Logger ring buffer + command sonar_log_dump admin-only

**Acción:**
- En RCON/console (source=0): `sonar_log_dump 20`
- Como player no-admin: intenta `/sonar_log_dump 5` desde chat.
- `sonar_log_level debug` → `sonar_log_level info` (toggle).
- `sonar_log_clear` → verify `SONAR.Log.Size() == 0` post-clear (requiere comando custom o log siguiente línea para verificar).

**Expectativa:**
- Console (admin): imprime últimas 20 entries ordenadas, formato `[timestamp] [LEVEL] [resource] message`.
- Player non-admin: no output (ACE-gated, fails silently o "Access denied.").
- Level change: próximos debug logs aparecen/desaparecen en console.
- Clear: ring buffer vaciado (Size=0, confirmable con próximo `sonar_log_dump 5` → shows solo logs post-clear).

**✅ Pass si:** dump funciona + ACL protege + level/clear funcionan.

---

## Paso 9 — Metrics counter+histogram + command sonar_metrics

**Acción:**
- `sonar_metrics` desde console (source=0).
- Inspecciona output.
- `sonar_metrics_reset` → `sonar_metrics` de nuevo.

**Expectativa primera llamada:**
- Header `=== SONAR Core — Metrics Snapshot ===`.
- Counters: al menos `db.queries.select`, `db.queries.insert`, `bus.publishes.sonar:core:ready`, `migrations.applied`.
- Histograms: `db.duration_ms.*` con count/min/avg/p50/p95/p99/max.
- Gauges: `core.boot_duration_ms`, `bus.active_subscriptions`.

**Expectativa post-reset:**
- Todos counters/histograms vaciados (output prácticamente vacío, excepto lo que se haya emitido entre reset y dump).

**✅ Pass si:** snapshot tiene datos esperados + reset funciona.

---

## Paso 10 — resmon sonar_core idle <0.3ms, peak <1ms

**Acción:**
- En console server: `resmon`
- Mantén abierto 2-3 min idle (server arrancado, sin actividad extra).
- Ejecuta pasos 5-9 en paralelo y observa pico.

**Expectativa (per `docs/technical/06_fivem_standards.md` §2.2):**
- `sonar_core` idle: **< 0.3ms**.
- `sonar_core` peak (durante smoke tests): **< 1ms**.
- `sonar_bridges` idle: < 0.3ms (ya verificado S0.2).

**✅ Pass si:** ambos budgets respetados.

**🚩 Fail action:** si excede → ADR-011 + optimization task en S1 antes de continuar.

---

## Checklist final sign-off Sprint 0

- [ ] Paso 1 — Pre-flight boot ✅
- [ ] Paso 2 — Migration 001 aplicada ✅
- [ ] Paso 3 — Migration 002 aplicada ✅
- [ ] Paso 4 — Idempotency ✅
- [ ] Paso 5 — EventBus smoke ✅
- [ ] Paso 6 — DB wrappers ✅
- [ ] Paso 7 — RateLimiter ✅
- [ ] Paso 8 — Logger ring + admin cmd ✅
- [ ] Paso 9 — Metrics dump ✅
- [ ] Paso 10 — resmon budgets ✅

**10/10 ✅ → Sign-off Sprint 0 + tag v0.0.0**

Si algún paso falla:
1. Anotar en `progress/SPRINT_RETRO_S0.md` § "Issues encontrados".
2. Decidir: (a) slip 1 semana para fix → cerrar después, (b) mover fix a S1 si no bloquea critical path.
3. Founder decision, no auto-merge.
