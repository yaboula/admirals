# Sprint S1.1 — Smoke Test Protocol (8 pasos)

> **Scope:** valida que `sonar_core` v0.2.0 (con exports cross-resource + lib helper + migration 003) + `sonar_bank` v0.1.0 (IBAN + accounts + C001 getBalance + EnsureStarterAccount idempotent) arrancan, interoperan, cumplen performance budgets y respetan SSoT contracts.
>
> **Ejecutor:** founder (yaboula).
> **Prerrequisito:** smoke test S0 (10/10 ✅) ejecutado y passing previamente. DB con migrations 001+002 aplicadas. Server FiveM con bridges + core listos.
> **Duración estimada:** 25-35 min primera pasada.
>
> **Criterio sign-off Sprint S1.1:** 8/8 pasos ✅.

---

## Setup previo

1. Verifica MariaDB/MySQL running + DB `sonar` existe + migrations 001+002 aplicadas (1 row `version=1` + 1 row `version=2` en `sonar_schema_versions`).
2. `server.cfg` añade:
   ```
   ensure sonar_bank
   ```
   Orden: oxmysql → sonar_bridges → sonar_core → sonar_bank.
3. Reinicia server. Para test paso 4 necesitarás **conectar al menos un player** con framework T1 activo (qbox o lo que tengas configurado).
4. ACE permissions verificados:
   ```
   add_ace group.admin command.sonar_bank_status allow
   ```

---

## Paso 1 — Pre-flight: 3 resources arrancan clean, lib helper carga en VM bank

**Acción:**
Start server. Observa console primeros 15s.

**Expectativa:**
- `[sonar_bridges] SONAR Bridges v0.2.0 booting...` → READY.
- `[sonar_core] sonar_core v0.2.0 booting...` → boot report `sonar_core is READY`.
  - Boot report muestra **3 migrations applied**: 001, 002, **003** (la nueva).
- `^5[sonar_lib] loaded in sonar_bank — SONAR namespace ready^7` ← lib helper en VM bank.
- `[sonar_bank] sonar_bank v0.1.0 booting...`
- `[sonar_bank] IBAN module ready (prefix=AD-, charset_size=36, max_retries=5)`
- `[sonar_bank] Accounts module ready (starter_balance=2500.0 €, currency=EUR)`
- `[sonar_bank] Callbacks registered: sonar:bank:getBalance (C001)`
- `[sonar_bank] sonar_core ready (v0.2.0)`
- `[sonar_bank] Schema verified: sonar_bank_accounts + sonar_bank_movements OK`
- `[sonar_bank] Identity hooks registered (OnPlayerLoaded + OnPlayerDropped)`
- Boot report ASCII final: `^2 sonar_bank is READY^7`.

**Verificar resmon:**
```
resmon
```
- `sonar_bank` idle: **<0.2 ms** (per SSoT `06_fivem_standards.md` §2.2).
- `sonar_core` idle: <0.3 ms (no debe haber regresión vs S0.4).
- Sin errores rojos en consola.

**✅ Pass si:** los 3 panels boot OK + lib helper anuncia carga + resmon sonar_bank ≤0.2ms idle + 0 errors.

---

## Paso 2 — Migration 003 aplicada: 2 tablas banca + tracking row + columnas matchean SSoT

**Acción:**
```sql
SHOW TABLES LIKE 'sonar_bank_%';

SELECT version, filename, LEFT(checksum, 16) AS chk_prefix, duration_ms
  FROM sonar_schema_versions
  WHERE version = 3;

-- Verificar shape sonar_bank_accounts:
SHOW CREATE TABLE sonar_bank_accounts \G

-- Verificar partitioning sonar_bank_movements:
SELECT partition_name, partition_description, table_rows
  FROM information_schema.partitions
  WHERE table_schema = DATABASE() AND table_name = 'sonar_bank_movements';
```

**Expectativa:**
- 2 tablas: `sonar_bank_accounts`, `sonar_bank_movements`.
- Tracking row: `version=3, filename='003_bank_schema.sql', checksum` 64 hex, `duration_ms>0`.
- `sonar_bank_accounts` columns exactos:
  - `id CHAR(36) PK`, `iban VARCHAR(20) UNIQUE`, `type ENUM('personal','company','cooperative','escrow')`, `owner_account_id CHAR(36)`, `owner_company_id CHAR(36)`, `balance DECIMAL(14,2)`, `daily_limit_out DECIMAL(12,2)`, `is_frozen TINYINT(1)`, `frozen_reason VARCHAR(255)`, `created_at INT UNSIGNED`, `updated_at INT UNSIGNED`, `closed_at INT UNSIGNED`.
  - 4 indexes (uq_iban, idx_owner_account, idx_owner_company, idx_type_active).
  - 1 FK a `sonar_accounts(id)` ON DELETE RESTRICT.
  - CHECK constraint XOR ownership.
  - Engine InnoDB, charset utf8mb4, collation **utf8mb4_unicode_ci** (NO 0900_ai_ci).
- `sonar_bank_movements` partitioned: 5 partitions (`p_2026_05`, `p_2026_06`, `p_2026_07`, `p_2026_08`, `p_future` con MAXVALUE). Todas con `table_rows = 0`.
- ENUM `category` incluye `starter_seed` (12 valores total).

**✅ Pass si:** las 2 tablas existen con schema correcto + tracking row + 5 partitions + 0 rows iniciales.

---

## Paso 3 — IBAN.Generate produce IBANs unique con checksum verifiable (100 invocaciones)

**Acción:**
Crea/edita un comando admin temporal en `sonar_bank/server/init.lua` SOLO PARA SMOKE (a removerlo después):

```lua
RegisterCommand('sonar_smoke_iban_gen', function(source)
  if source ~= 0 then return end
  local seen = {}
  local collisions = 0
  local checksum_failures = 0
  for i = 1, 100 do
    local iban = SONAR.Bank.IBAN.Generate()
    if seen[iban] then collisions = collisions + 1 end
    seen[iban] = true

    -- Verificar checksum cierra con Validate.
    local ok, err = SONAR.Bank.IBAN.Validate(iban)
    if not ok then
      checksum_failures = checksum_failures + 1
      print(string.format('FAIL %s: %s', iban, err))
    end

    if i <= 5 then print(string.format('  IBAN[%d] = %s', i, iban)) end
  end
  print(string.format('^2[smoke] 100 IBANs generated. Collisions=%d. ChecksumFailures=%d^7',
    collisions, checksum_failures))
end, true)
```

> **NOTA**: tras este paso, **revertir** este comando (o dejarlo gated tras `Config.Env == 'development'`).

Reinicia server, ejecuta desde consola:
```
sonar_smoke_iban_gen
```

**Expectativa:**
- Output muestra 5 IBANs ejemplo formato `AD-XXXX-XXXX-XXXX` (17 chars literales).
- Final: `100 IBANs generated. Collisions=0. ChecksumFailures=0`.
- Cleanup DB (los 100 IBANs se generaron sin INSERT real — Generate solo SELECT WHERE iban=? para uniqueness check, no INSERT a sonar_bank_accounts).

**Verificar metric:**
```
sonar_metrics
```
Busca counters: `bank.iban.generated = 100`, `bank.iban.collisions = 0` (probablemente no aparece si fue 0).

**✅ Pass si:** 100 generadas, 0 colisiones, 0 checksum failures, format correcto. **Recordar remover/gatear el comando smoke antes commit.**

---

## Paso 4 — EnsureStarterAccount idempotent: 1 row INSERT en bank_accounts + 1 row en bank_movements + sonar_accounts row creado

**Acción:**
Conecta un player real al server (qbox/qbcore/esx framework T1 — el que tengas active). Verifica logs:

```
[sonar_bank] Identity loaded: source=N citizen_id=ABCD1234
[sonar_bank] Created sonar_accounts row id=<uuid> char_id=ABCD1234 framework=qbox
[sonar_bank] EnsureStarterAccount created: ABCD1234 → AD-XXXX-XXXX-XXXX (2500.0 €) in <duration>ms
[sonar_bank] Starter account created for ABCD1234: AD-... (balance=2500.0 €)
```

Verifica DB:
```sql
-- Cuenta sonar_accounts:
SELECT id, char_id, framework_source, alias, created_at, last_login_at
  FROM sonar_accounts WHERE char_id = '<TU_CITIZEN_ID>';

-- Cuenta bank_account:
SELECT id, iban, type, owner_account_id, balance, created_at
  FROM sonar_bank_accounts
  WHERE owner_account_id = (SELECT id FROM sonar_accounts WHERE char_id = '<TU_CITIZEN_ID>');

-- Movement starter_seed:
SELECT id, bank_account_id, occurred_at, amount, balance_after, category, concept, request_nonce, source_resource
  FROM sonar_bank_movements
  WHERE bank_account_id = (SELECT id FROM sonar_bank_accounts WHERE owner_account_id = (SELECT id FROM sonar_accounts WHERE char_id = '<TU_CITIZEN_ID>'));
```

**Expectativa:**
- 1 row sonar_accounts (framework_source matchea bridges active).
- 1 row sonar_bank_accounts: type=`personal`, balance=`2500.00`, iban formato AD-XXXX-XXXX-XXXX.
- 1 row sonar_bank_movements: amount=2500, balance_after=2500, category=`starter_seed`, concept=`Saldo inicial SONAR`, request_nonce=`<UUID v4>` (36 chars hex+dashes), source_resource=`sonar_bank`.

**Idempotency test:** Disconnect + reconnect player. Verifica logs:
```
[sonar_bank] EnsureStarterAccount: existing bank_account for ABCD1234 (iban=..., balance=2500.00)
```

Verifica DB **NO** se duplicaron rows:
```sql
SELECT COUNT(*) FROM sonar_bank_accounts WHERE owner_account_id = (SELECT id FROM sonar_accounts WHERE char_id = '<TU_CITIZEN_ID>');
-- → 1
SELECT COUNT(*) FROM sonar_bank_movements WHERE category = 'starter_seed' AND bank_account_id = (SELECT id FROM sonar_bank_accounts WHERE owner_account_id = (SELECT id FROM sonar_accounts WHERE char_id = '<TU_CITIZEN_ID>'));
-- → 1
```

**✅ Pass si:** 3 rows totales (sonar_accounts + sonar_bank_accounts + sonar_bank_movements) tras 1ª conexión. Tras reconexión: counts mantienen 1/1/1 (no duplicados).

---

## Paso 5 — C001 sonar:bank:getBalance happy path (shape canónico §3.1)

**Acción:**
Con player conectado (mismo del paso 4), ejecuta desde un client console o test resource (vía ox_lib client `lib.callback.await`):

```lua
-- En client de test resource:
local result = lib.callback.await('sonar:bank:getBalance', 2000, {})
print(json.encode(result))
```

**Expectativa response (shape canónico SSoT §3.1):**
```json
{
  "success": true,
  "data": {
    "iban": "AD-XXXX-XXXX-XXXX",
    "balance": 2500.0,
    "currency": "EUR",
    "tier": "personal",
    "last_updated": <unix_ms>
  }
}
```

- `balance` numeric (no string).
- `currency` exactly `'EUR'`.
- `tier` exactly `'personal'`.
- `last_updated` en milisegundos (no segundos) — orden magnitud ~1.7e12 para 2026.

**Verificar metric:**
```
sonar_metrics
```
Buscar `bank.callbacks.get_balance.ok` counter incremented.

**✅ Pass si:** response shape exacto + balance=2500 + tier='personal'.

---

## Paso 6 — C001 unauthorized: player A pide IBAN de player B → NOT_AUTHORIZED

**Acción:**
- Conecta 2 players distintos (citizen_id A y citizen_id B).
- Ambos triggerean EnsureStarterAccount automáticamente (logs muestran 2 starter accounts creados).
- Anota IBAN del player B (visible en log o en DB).
- Como player A, ejecuta el callback con request `{ iban = '<IBAN_DE_B>' }`:
  ```lua
  local result = lib.callback.await('sonar:bank:getBalance', 2000, { iban = 'AD-XXXX-XXXX-XXXX' })
  print(json.encode(result))
  ```

**Expectativa:**
```json
{
  "success": false,
  "error_code": "NOT_AUTHORIZED",
  "message": "You are not the owner of this account"
}
```

Logs server:
```
[sonar_bank] [WARN] getBalance unauthorized: citizen=<A_CITIZEN_ID> requested iban=<IBAN_DE_B> (type=personal)
```

**Verificar metric:**
- `bank.callbacks.get_balance.unauthorized` counter incremented.

**✅ Pass si:** error response NOT_AUTHORIZED + log warn server-side + metric counter.

---

## Paso 7 — C001 rate limit: 31 calls en <10s → 30 OK + 1 RATE_LIMITED

**Acción:**
Como player A (válido owner), ejecuta 31 llamadas back-to-back en menos de 10 segundos:

```lua
-- Client side test:
local ok_count, blocked_count = 0, 0
for i = 1, 31 do
  local r = lib.callback.await('sonar:bank:getBalance', 2000, {})
  if r and r.success then
    ok_count = ok_count + 1
  elseif r and r.error_code == 'RATE_LIMITED' then
    blocked_count = blocked_count + 1
  end
end
print(string.format('OK=%d BLOCKED=%d', ok_count, blocked_count))
```

**Expectativa:**
- Output: `OK=30 BLOCKED=1` (bucket `bank.read` = 30/10s defaults en `sonar_core/config.lua:122-126`).

**Verificar metric:**
```
sonar_metrics
```
- `rate.allowed.bank.read` ≥ 30.
- `rate.blocked.bank.read` ≥ 1.
- `bank.callbacks.get_balance.rate_limited` ≥ 1.

**✅ Pass si:** exactly 30 OK + ≥1 RATE_LIMITED + metric counters reflejan.

---

## Paso 8 — Audit log + Bus.Publish: starter_seed audit row + account_created event observable

**Acción:**

(a) Verificar audit row en DB tras paso 4 (player conectado primera vez):
```sql
SELECT id, ts, category, action, actor_account_id, target_id, amount, currency, metadata, resource
  FROM sonar_audit_log
  WHERE category = 'bank.starter_seed'
  ORDER BY ts DESC LIMIT 5;
```

**Expectativa audit:**
- 1 row mínimo (uno per starter created en pasos 4/6).
- `category='bank.starter_seed'`, `action='credit'`, `actor_account_id=<citizen_id>` (no UUID — diseño S1.1 acepta citizen_id raw como actor; refine S2+).
- `metadata` JSON contiene `{ iban, balance: 2500, currency: 'EUR', nonce }`.

(b) Verificar Bus stats (registros de events publicados):
```
sonar_core_status
```
**Expectativa:**
- Bus stats: `<N> events, ...` donde uno de ellos es `sonar:bank:account_created`.

(c) Verificar log ring buffer:
```
sonar_log_dump 30
```
Buscar entries:
- `[INFO] [sonar_bank] EnsureStarterAccount created: ...`
- `[AUDIT] [sonar_core] bank.starter_seed/credit actor=<citizen_id> target=<bank_account_id>`
- `[INFO] [sonar_bank] Identity hooks registered`

(d) Test cross-resource subscription via lib helper (opcional, advanced):
Crea micro-resource test que use `@sonar_core/lib/sonar.lua` y subscribe a `sonar:bank:account_created`:
```lua
-- en test resource:
SONAR.Core.WaitReady(30000)
SONAR.Bus.Subscribe('sonar:bank:account_created', function(payload)
  print('^2[test_listener] received: iban=' .. payload.iban .. ' balance=' .. payload.balance .. '^7')
end)
```
Reconecta player → debe ver el log `[test_listener]` confirmando dispatch cross-resource via TriggerEvent('sonar_lib:dispatch').

**✅ Pass si:** (a) audit row presente con metadata correcto + (b) Bus reporta event en stats + (c) log ring contiene audit entry. (d) opcional pero recomendado.

---

## Resultado final

**Sign-off Sprint S1.1:** 8/8 pasos ✅.

Si algún paso falla:
- Reportar en SESSION_LOG.md S1.1 con paso exacto + output observado.
- NO marcar S1.1 done hasta resolución.
- Considerar si el fallo es regresión S0 (smoke S0 debe seguir 10/10 ✅).

**Cleanup post-smoke:**
- Remover `sonar_smoke_iban_gen` command del paso 3 (o gatear tras `Config.Env == 'development'`).
- Resetear DB **NO** se requiere — los starter accounts creados son data legítima de development.

**Performance budget assertions** (per `docs/technical/06_fivem_standards.md` §2.2):
- `sonar_bank` idle ≤ 0.2 ms ✅
- `sonar_core` idle ≤ 0.3 ms ✅ (regression check)
- `sonar_bridges` idle ≤ 0.5 ms ✅ (no regression vs S0)
- DB query p99 sonar_bank_accounts < 5ms (per SSoT §03 §11.2 sample query target).
