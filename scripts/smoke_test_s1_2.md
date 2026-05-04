# Sprint S1.2 — Smoke Test Protocol (10 pasos)

> **Scope:** valida que `sonar_bank` v0.2.0 (C002 transfer atomic + idempotency DB-backed + migration 004 system seed treasury) + `sonar_bridges` v0.2.0 (dispatcher DB-backed swap) + `sonar_core` v0.3.0 (migrations runner + idempotency exports) arrancan, interoperan, cumplen SSoT contracts §3.1 C002, §4.3 event canonical, §4.2 double-entry ledger, y respetan performance budgets.
>
> **Ejecutor:** founder (yaboula).
> **Prerrequisito:** smoke test S1.1 (8/8 ✅) ejecutado y passing. DB con migrations 001+002+003 aplicadas. Server FiveM con bridges + core + bank listos. **2 player accounts** (player A + player B) con T1 conectados, cada uno con starter 2.500 €.
> **Duración estimada:** 40-55 min primera pasada.
>
> **Criterio sign-off Sprint S1.2:** 10/10 pasos ✅.

---

## Setup previo

1. Verifica MariaDB/MySQL running + migrations 001+002+003 aplicadas + **migration 004** (system seed) pendiente de verificar en paso 1.
2. `server.cfg` orden:
   ```
   ensure oxmysql
   ensure sonar_bridges
   ensure sonar_core
   ensure sonar_bank
   ```
3. Reinicia server. Conecta **2 players distintos** con framework T1. Anota sus `citizen_id` como `<A_CID>` y `<B_CID>`, y sus IBANs como `<A_IBAN>` y `<B_IBAN>` (visibles en boot logs o vía SQL del paso 2).
4. Prepara un editor SQL conectado a la DB `sonar` para los pasos de verificación.
5. **Admin commands smoke** disponibles en `sonar_bank/server/init.lua` (ver sección al final de este doc). Añádelos solo si no existen; removerlos o gatearlos tras `Config.Env == 'development'` al finalizar.

---

## Paso 1 — Pre-flight: 3 resources arrancan limpios, idempotency backend swapped a DB, migration 004 aplicada

**Acción:**
Start server. Observa console primeros 20s.

**Expectativa logs (en orden aproximado):**

```
[sonar_bridges] SONAR Bridges v0.2.0 booting...
[sonar_bridges] Idempotency backend: memory (in-process, lost on reboot)   ← default inicial
...
[sonar_core] sonar_core v0.3.0 booting...
[sonar_core] Boot: Bridges ready
[sonar_core] Boot: DB ready
[sonar_core] Running migration 004_bank_seed_system_account.sql...
[sonar_core] Migration 004 applied OK
[sonar_core] Bridges idempotency backend swapped to DB-backed              ← KEY log
[sonar_bridges] Idempotency backend swapped: resource=sonar_core (get=IdempotencyGet set=IdempotencySet gc=IdempotencyGC)
[sonar_core] sonar_core is READY
...
[sonar_bank] sonar_bank v0.2.0 booting...
[sonar_bank] Transfer module ready (fee=0€, max=1000000€, rate=bank.write)
[sonar_bank] Events module ready (transfer_completed schema §4.3 wired)
[sonar_bank] Callbacks registered: sonar:bank:getBalance (C001), sonar:bank:transfer (C002)
[sonar_bank] sonar_bank is READY
```

**Verificar migration 004 + system seed:**
```sql
-- Migration tracking:
SELECT version, filename, applied_at FROM sonar_schema_versions ORDER BY version DESC LIMIT 4;
-- → rows 1..4, version=4 con filename='004_bank_seed_system_account.sql'

-- System account en sonar_accounts:
SELECT id, char_id, framework_source, alias FROM sonar_accounts WHERE char_id = 'SYSTEM';
-- → id='00000000-0000-0000-0000-000000000001', char_id='SYSTEM', framework_source='sonar_core'

-- System bank account:
SELECT iban, type, balance, is_frozen FROM sonar_bank_accounts WHERE iban = 'AD-SYS0-0000-0001';
-- → iban='AD-SYS0-0000-0001', type='personal', balance=10000000.00, is_frozen=0

-- Seed movement audit trail:
SELECT amount, balance_after, category, concept, request_nonce FROM sonar_bank_movements
  WHERE request_nonce = 'a0000000-0000-0000-0000-00000000seed';
-- → amount=10000000.00, balance_after=10000000.00, category='adjustment', concept='System treasury seed (10M EUR per economy §4.2)'
```

**Verificar boot report bank_accounts ≥ 3:**
```sql
SELECT COUNT(*) FROM sonar_bank_accounts;
-- → ≥ 3 (player A + player B + system AD-SYS0-0000-0001)
```

**Verificar resmon idle:**
```
resmon
```
- `sonar_bank` idle: **<0.3 ms**.
- `sonar_bridges` idle: **<0.3 ms**.
- `sonar_core` idle: **<0.3 ms** (no regression).

**✅ Pass si:** 3 resources READY + log "Bridges idempotency backend swapped to DB-backed" + migration 004 row + system account balance=10.000.000 € + bank_accounts count ≥ 3 + resmon ≤ 0.3ms idle.

---

## Paso 2 — Happy path C002: A→B 100 €, response shape canónico, DB consistente, audit row

**Acción:**
Como player A, ejecuta callback C002 desde client:

```lua
-- En client resource de player A:
local result = lib.callback.await('sonar:bank:transfer', 5000, {
  from_iban  = '<A_IBAN>',
  to_iban    = '<B_IBAN>',
  amount     = 100.00,
  concept    = 'Test S1.2',
  request_id = 'smoke-s1-2-happy-001',
})
print(json.encode(result))
```

**Expectativa response (SSoT §3.1 C002 shape canónico):**
```json
{
  "success": true,
  "data": {
    "transaction_id": "<UUID v4 formato xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx>",
    "timestamp": <unix_ms ~1.7e12>,
    "new_balance_from": 2400.00,
    "fee_retained": 0.00
  }
}
```

- `transaction_id` es UUID v4 server-generado (no el `request_id` del cliente).
- `timestamp` en milisegundos (× 1000 del UNIX seconds).
- `new_balance_from` = 2400.00 (2500 - 100).
- `fee_retained` = 0.00 (internal transfer fee = 0 € per economy §10.3).

Anota el `transaction_id` retornado como `<TX_ID_1>`.

**Verificar DB balances:**
```sql
SELECT iban, balance FROM sonar_bank_accounts
  WHERE iban IN ('<A_IBAN>', '<B_IBAN>', 'AD-SYS0-0000-0001');
-- → A: 2400.00 | B: 2600.00 | system: 10000000.00 (NO cambia)
```

**Verificar double-entry movements (2 rows compartiendo request_nonce):**
```sql
SELECT bank_account_id, amount, balance_after, category, counterpart_iban, concept, request_nonce, initiated_by_account_id
  FROM sonar_bank_movements
  WHERE request_nonce = '<TX_ID_1>'
  ORDER BY amount ASC;
-- Row debit:  amount=-100.00, balance_after=2400.00, category='transfer', counterpart_iban='<B_IBAN>'
-- Row credit: amount=+100.00, balance_after=2600.00, category='transfer', counterpart_iban='<A_IBAN>'
-- → 2 rows exactamente, mismo request_nonce
```

**Verificar audit log:**
```sql
SELECT category, action, actor, target, payload FROM sonar_audit_log
  WHERE target = '<TX_ID_1>'
  ORDER BY ts DESC LIMIT 3;
-- → 1 row: category='bank.transfer', action='execute', actor='<A_CID>', target='<TX_ID_1>'
-- payload JSON debe incluir: transaction_id, from_iban, to_iban, amount=100, fee_retained=0, new_balance_from=2400
```

**Verificar idempotency entry persisted:**
```sql
SELECT idem_key, LEFT(response_json, 80) AS response_preview, expires_at, created_at,
       (expires_at - created_at) AS ttl_sec
  FROM sonar_bridge_idempotency
  WHERE idem_key = 'smoke-s1-2-happy-001';
-- → 1 row, ttl_sec = 3600 exacto, response_preview contiene 'success":true'
```

**✅ Pass si:** response shape exacto + A balance=2400 + B balance=2600 + system balance=10M sin cambio + 2 movement rows con request_nonce=TX_ID_1 (debit/credit signed) + 1 audit row bank.transfer + idempotency entry TTL=3600s.

---

## Paso 3 — Idempotency replay: mismo request_id → respuesta idéntica, DB sin cambios, audit idempotency_replay

**Acción:**
Como player A, envía **exactamente el mismo request** del paso 2 (mismo `request_id = 'smoke-s1-2-happy-001'`):

```lua
local result2 = lib.callback.await('sonar:bank:transfer', 5000, {
  from_iban  = '<A_IBAN>',
  to_iban    = '<B_IBAN>',
  amount     = 100.00,
  concept    = 'Test S1.2',
  request_id = 'smoke-s1-2-happy-001',
})
print(json.encode(result2))
```

**Expectativa response:**
- Idéntica byte-by-byte a la del paso 2. `transaction_id` = mismo `<TX_ID_1>`.
- `new_balance_from` = 2400.00 (NO re-ejecutó TX).

**Verificar DB NO cambió:**
```sql
SELECT iban, balance FROM sonar_bank_accounts
  WHERE iban IN ('<A_IBAN>', '<B_IBAN>');
-- → A: 2400.00 | B: 2600.00 (idéntico a tras paso 2)

SELECT COUNT(*) FROM sonar_bank_movements WHERE request_nonce = '<TX_ID_1>';
-- → 2 (sin filas nuevas)
```

**Verificar audit idempotency_replay:**
```sql
SELECT category, action, actor, target FROM sonar_audit_log
  WHERE action = 'idempotency_replay'
  ORDER BY ts DESC LIMIT 3;
-- → 1 row: category='bank.transfer', action='idempotency_replay', actor='<A_CID>', target='smoke-s1-2-happy-001'
```

**Verificar log server:**
```
[sonar_bank] [INFO] transfer idempotency replay: request_id=smoke-s1-2-happy-001
```
Y metric counter `bank.callbacks.transfer.idempotency_replay` incremented (verificable con `sonar_metrics`).

**✅ Pass si:** respuesta idéntica al paso 2 + DB balances sin cambio + movements count=2 + audit idempotency_replay row + metric counter.

---

## Paso 4 — Self-transfer: A→A propio IBAN → error SELF_TRANSFER, idempotency entry del error persisted

**Acción:**
```lua
local result = lib.callback.await('sonar:bank:transfer', 5000, {
  from_iban  = '<A_IBAN>',
  to_iban    = '<A_IBAN>',
  amount     = 50.00,
  concept    = 'Self test',
  request_id = 'smoke-s1-2-self-001',
})
print(json.encode(result))
```

**Expectativa response:**
```json
{
  "success": false,
  "error_code": "SELF_TRANSFER",
  "message": "No puedes transferir a tu propia cuenta."
}
```

**Verificar DB sin cambios:**
```sql
SELECT balance FROM sonar_bank_accounts WHERE iban = '<A_IBAN>';
-- → 2400.00 (sin cambio desde paso 2)
```

**Verificar idempotency entry del error persistido:**
```sql
SELECT idem_key, LEFT(response_json, 100) AS preview FROM sonar_bridge_idempotency
  WHERE idem_key = 'smoke-s1-2-self-001';
-- → 1 row, preview contiene '"success":false,"error_code":"SELF_TRANSFER"'
```

**Idempotency replay del error:** Reenvía mismo `request_id = 'smoke-s1-2-self-001'` → debe retornar mismo error (sin re-ejecutar Transfer.Execute). Esto confirma que los errores determinísticos también son PUT-like idempotentes per SSoT §3.1.

**✅ Pass si:** SELF_TRANSFER error + balance A sin cambio + idempotency entry del error persisted + re-attempt retorna mismo error.

---

## Paso 5 — Insufficient funds: A transfiere 5000 € (tiene 2400 €) → INSUFFICIENT_FUNDS

**Acción:**
```lua
local result = lib.callback.await('sonar:bank:transfer', 5000, {
  from_iban  = '<A_IBAN>',
  to_iban    = '<B_IBAN>',
  amount     = 5000.00,
  concept    = 'Overdraft test',
  request_id = 'smoke-s1-2-insuf-001',
})
print(json.encode(result))
```

**Expectativa response:**
```json
{
  "success": false,
  "error_code": "INSUFFICIENT_FUNDS",
  "message": "Saldo insuficiente."
}
```

**Verificar DB sin cambios:**
```sql
SELECT iban, balance FROM sonar_bank_accounts WHERE iban IN ('<A_IBAN>', '<B_IBAN>');
-- → A: 2400.00 | B: 2600.00
SELECT COUNT(*) FROM sonar_bank_movements WHERE request_nonce = 'smoke-s1-2-insuf-001';
-- → 0 (ninguna movement row — Transfer.Execute retorna antes de llegar a TX)
```

**✅ Pass si:** INSUFFICIENT_FUNDS error + balances sin cambio + 0 movement rows.

---

## Paso 6 — Rate limit: 11 transfers válidos distintos → 10 OK + 11ª RATE_LIMIT_EXCEEDED

**Acción:**
Ejecuta 11 transfers con `request_id` únicos cada uno (para evitar que el idempotency cache cache los previos):

```lua
-- Client side player A:
local ok_count, blocked_count = 0, 0
for i = 1, 11 do
  local r = lib.callback.await('sonar:bank:transfer', 5000, {
    from_iban  = '<A_IBAN>',
    to_iban    = '<B_IBAN>',
    amount     = 1.00,
    concept    = 'Rate test ' .. i,
    request_id = 'smoke-s1-2-rate-' .. string.format('%03d', i),
  })
  if r and r.success then
    ok_count = ok_count + 1
  elseif r and r.error_code == 'RATE_LIMIT_EXCEEDED' then
    blocked_count = blocked_count + 1
  end
end
print(string.format('OK=%d BLOCKED=%d', ok_count, blocked_count))
```

> **NOTA:** La ventana `bank.write` es 10 llamadas / 60 segundos per citizen. Este loop debe ejecutarse en menos de 60 segundos para que el bucket no expire entre iteraciones.

**Expectativa output:**
```
OK=10 BLOCKED=1
```

> Si el player A tiene calls previas de `bank.write` en la ventana actual (pasos 2-5), el bucket puede agotarse antes de 10. Para un resultado limpio, espera 60s o usa un `citizen_id` fresco. Alternativamente: acepta OK=N BLOCKED=11-N donde N≤10.

**Verificar métricas:**
```
sonar_metrics
```
- `rate.blocked.bank.write` ≥ 1.
- `bank.callbacks.transfer.rate_limit_exceeded` ≥ 1.

**Verificar DB balance A:**
```sql
SELECT balance FROM sonar_bank_accounts WHERE iban = '<A_IBAN>';
-- → 2400.00 - (ok_count * 1.00) = 2390.00 si ok_count=10 desde paso 2
```

**✅ Pass si:** exactamente (10 - calls_previas_en_ventana) OK + el resto RATE_LIMIT_EXCEEDED + metric counters incrementados.

---

## Paso 7 — Restart durante idempotency window: DB-backed survive cross-restart

**Acción:**

1. Como player A, ejecuta una transferencia con request_id nuevo:
   ```lua
   local r = lib.callback.await('sonar:bank:transfer', 5000, {
     from_iban  = '<A_IBAN>',
     to_iban    = '<B_IBAN>',
     amount     = 10.00,
     concept    = 'Pre-restart test',
     request_id = 'smoke-s1-2-restart-001',
   })
   print(json.encode(r))  -- debe ser success=true
   ```
   Anota el `transaction_id` retornado como `<TX_ID_RESTART>` y el balance `new_balance_from`.

2. Anota balances actuales en DB.

3. **Reinicia el server FiveM** (`restart` o `quit` + relaunch).

4. Reconecta player A. Espera boot completo (log "Idempotency backend swapped to DB-backed" de nuevo).

5. Reenvía **exactamente el mismo request** con `request_id = 'smoke-s1-2-restart-001'`:
   ```lua
   local r2 = lib.callback.await('sonar:bank:transfer', 5000, {
     from_iban  = '<A_IBAN>',
     to_iban    = '<B_IBAN>',
     amount     = 10.00,
     concept    = 'Pre-restart test',
     request_id = 'smoke-s1-2-restart-001',
   })
   print(json.encode(r2))
   ```

**Expectativa:**
- `r2` es idéntico a `r`: mismo `transaction_id = <TX_ID_RESTART>`, mismo `new_balance_from`.
- El TX **NO se re-ejecutó**: balances siguen igual a post-paso-1 del restart.

**Verificar DB tras re-attempt post-restart:**
```sql
SELECT balance FROM sonar_bank_accounts WHERE iban IN ('<A_IBAN>', '<B_IBAN>');
-- → Idéntico a tras paso 1 del restart (NO deducción adicional)

SELECT COUNT(*) FROM sonar_bank_movements WHERE request_nonce = '<TX_ID_RESTART>';
-- → 2 (las 2 rows del intento original — sin duplicados)

SELECT expires_at FROM sonar_bridge_idempotency WHERE idem_key = 'smoke-s1-2-restart-001';
-- → expires_at > UNIX_TIMESTAMP() (entry sobrevivió el restart)
```

**✅ Pass si:** respuesta idéntica post-restart + balances sin cambio adicional + movements count=2 + idempotency entry sobrevivió cross-restart (DB-backed confirmed).

---

## Paso 8 — Atomicity stress: 100 concurrent transfers → ledger 100% consistente (RecalcBalance delta=0)

> **Prerrequisito:** player A con saldo suficiente. Si es necesario, haz un reset de balance vía SQL admin:
> ```sql
> UPDATE sonar_bank_accounts SET balance = 50000.00, updated_at = UNIX_TIMESTAMP()
>   WHERE iban = '<A_IBAN>';
> ```
> (Solo en dev — anota el ajuste en SESSION_LOG como "balance reset para stress test paso 8".)

**Acción:**
Usando el comando admin `sonar_smoke_stress` (ver sección Admin Commands al final), ejecuta desde server console:

```
sonar_smoke_stress <A_IBAN> <B_IBAN> 100
```

Este comando lanza 100 transfers de 1.00 € con request_ids únicos vía `Citizen.Await` loop.

Si el comando no existe, ejecuta manualmente desde consola de la VM sonar_bank:

```lua
-- Server exec (consola resource):
local ok, err_count = 0, 0
for i = 1, 100 do
  local tid = string.format('smoke-stress-%04d', i)
  local s, d, ec = SONAR.Bank.Transfer.Execute(
    '<A_CID>', '<A_IBAN>', '<B_IBAN>', 1.00, 'Stress ' .. i, tid
  )
  if s then ok = ok + 1 else err_count = err_count + 1 end
end
print(string.format('[stress] ok=%d errors=%d', ok, err_count))
```

**Expectativa:**
- `ok + err_count = 100` (ningún pcall uncaught).
- `err_count` puede ser > 0 si rate limit o insufficient funds disparan — documentar.

**Verificar consistencia del ledger post-stress:**
```sql
-- RecalcBalance: delta entre SUM(movements) y balance actual debe ser 0.
-- (Esto es lo que Movements.RecalcBalance hace internamente.)

-- Balance declarado en tabla:
SELECT balance AS declared_balance FROM sonar_bank_accounts WHERE iban = '<A_IBAN>';

-- Balance recalculado desde movements:
SELECT SUM(amount) AS sum_movements FROM sonar_bank_movements
  WHERE bank_account_id = (SELECT id FROM sonar_bank_accounts WHERE iban = '<A_IBAN>');

-- Delta esperado = 0 (o muy próximo si hubo ajuste manual pre-stress):
-- declared_balance = balance_inicial_preciso + SUM(movements desde ese baseline)
```

O usar el comando admin (si disponible):

```
sonar_bank_recalc_balance <A_IBAN>
```

**Expectativa:** delta = 0 para ambas cuentas A y B. Si delta != 0:
- delta_ratio = |delta| / total_transferido.
- **Ratio < 1%**: race window documentada (S1.2 known tradeoff en `transfer.lua` header). Documentar en SESSION_LOG. Acceptable in S1.2.
- **Ratio > 1%**: escalate — revisar TX wrapper oxmysql o candidato a hotfix S1.2.1.

**Verificar resmon peak durante stress:**
```
resmon
```
- `sonar_bank` peak: **< 1 ms**.
- `sonar_bridges` peak: **< 1 ms**.

**✅ Pass si:** 100 transfers completados sin excepciones uncaught + RecalcBalance delta=0 para ambas cuentas (o ratio < 1% documentado) + resmon peak < 1ms.

---

## Paso 9 — Event subscription: sonar:bank:transfer_completed payload schema-valid §4.3

**Acción:**

1. En un micro-resource de test (o via `exec` en consola), subscribe al evento antes de hacer una transferencia:

```lua
-- Añadir a un test resource o exec en server console:
AddEventHandler('sonar_lib:dispatch', function(event_name, payload)
  if event_name ~= 'sonar:bank:transfer_completed' then return end
  print('[event_test] transfer_completed received:')
  print('  transaction_id:       ' .. tostring(payload.transaction_id))
  print('  from_iban:            ' .. tostring(payload.from_iban))
  print('  to_iban:              ' .. tostring(payload.to_iban))
  print('  amount:               ' .. tostring(payload.amount))
  print('  category:             ' .. tostring(payload.category))
  print('  requester_account_id: ' .. tostring(payload.requester_account_id))
  print('  occurred_at:          ' .. tostring(payload.occurred_at))
  print('  _event_id:            ' .. tostring(payload._event_id))
  print('  _emitted_at:          ' .. tostring(payload._emitted_at))
  print('  _schema_version:      ' .. tostring(payload._schema_version))
end)
```

2. Ejecuta una transferencia nueva (player A → B, 5 €, request_id único):
   ```lua
   lib.callback.await('sonar:bank:transfer', 5000, {
     from_iban = '<A_IBAN>', to_iban = '<B_IBAN>',
     amount = 5.00, concept = 'Event test', request_id = 'smoke-s1-2-event-001',
   })
   ```

**Expectativa — payload schema-valid (SSoT §4.3):**

| Campo | Valor esperado |
|---|---|
| `transaction_id` | UUID v4 (36 chars hex+dashes) |
| `from_iban` | `<A_IBAN>` |
| `to_iban` | `<B_IBAN>` |
| `amount` | `5.0` (numeric) |
| `concept` | `'Event test'` |
| `category` | `'transfer'` |
| `requester_account_id` | UUID v4 del sonar_accounts de player A |
| `occurred_at` | UNIX seconds (integer ~1.7e9) |
| `_event_id` | UUID v4 auto-decorado por Bus.Publish |
| `_emitted_at` | UNIX ms auto-decorado |
| `_schema_version` | `'1'` o string semver (depende de sonar_core Bus impl) |

- Ningún campo requerido es `nil`.
- `category = 'transfer'` exactamente (no `'bank.transfer'` — ese es el audit, no el event).

**✅ Pass si:** evento recibido con todos los campos required non-nil + category='transfer' + _event_id auto-decorado.

---

## Paso 10 — resmon verificación final: idle <0.3ms + peak stress <1ms

**Acción:**
Inmediatamente después del paso 8 (stress test), observa resmon:

```
resmon
```

**Expectativa:**
- `sonar_bank` idle post-stress: **< 0.3 ms** (per SSoT `06_fivem_standards.md` §2.2).
- `sonar_bridges` idle post-stress: **< 0.3 ms**.
- `sonar_core` idle: **< 0.3 ms** (no regression).
- Peak observado durante paso 8: **< 1 ms** para bank + bridges.
- Ningún resource en steady state > 0.5 ms idle.

Si el paso 8 no capturó el peak:
1. Ejecuta 10 transfers consecutivos rápidos.
2. Observa resmon en tiempo real para ver peak momentáneo.

**✅ Pass si:** idle ≤ 0.3ms post-stress + pico durante stress < 1ms confirmado (observación manual o captura resmon durante paso 8).

---

## Resultado final

**Sign-off Sprint S1.2:** 10/10 pasos ✅.

Si algún paso falla:
- Reportar en `progress/SESSION_LOG.md` entry S1.2 con paso exacto + output observado vs esperado.
- NO marcar S1.2 done hasta resolución.
- Race window paso 8 delta < 1% es **acceptable** — documentar pero no bloquea sign-off.

**Cleanup post-smoke:**
- Remover o gatear (`Config.Env == 'development'`) los admin commands smoke añadidos.
- Reset de balance SQL del paso 8 (si aplica) queda como data dev — no requiere rollback.
- Resetear bucket rate limit de player A si se va a seguir testeando: esperar 60s o reconectar player.

**Performance budget final (per `docs/technical/06_fivem_standards.md` §2.2):**

| Resource | Idle budget | Peak budget |
|---|---|---|
| `sonar_bank` | ≤ 0.3 ms | ≤ 1 ms |
| `sonar_bridges` | ≤ 0.3 ms | ≤ 1 ms |
| `sonar_core` | ≤ 0.3 ms | ≤ 0.5 ms |

---

## Admin Commands (smoke only — añadir a `sonar_bank/server/init.lua`, gatear o remover tras smoke)

### `/sonar_bank_recalc_balance <iban>`

Recalcula el balance de una cuenta desde sus movements y reporta el delta respecto al balance declarado. Útil para paso 8 y reconciliación operacional.

```lua
-- En sonar_bank/server/init.lua (smoke only — remover o gatear post-smoke):
RegisterCommand('sonar_bank_recalc_balance', function(source, args)
  if source ~= 0 then return end  -- console only
  local iban = args[1]
  if not iban then print('Usage: sonar_bank_recalc_balance <IBAN>') return end

  local acc = SONAR.Bank.Accounts.GetByIban(iban)
  if not acc then print('IBAN not found: ' .. iban) return end

  local result = SONAR.Bank.Movements.RecalcBalance(acc.id)
  if not result then print('RecalcBalance returned nil for ' .. iban) return end

  local declared = tonumber(acc.balance) or 0.0
  local delta = math.abs(declared - (result.sum or 0.0))
  print(string.format(
    '[recalc] %s | declared=%.2f | sum_movements=%.2f | delta=%.2f | rows=%d',
    iban, declared, result.sum or 0.0, delta, result.rows or 0
  ))
  if delta == 0.0 then
    print('^2[recalc] LEDGER OK — delta=0^7')
  elseif delta / math.max(math.abs(result.sum or 1.0), 1.0) < 0.01 then
    print(string.format('^3[recalc] RACE WINDOW detected — delta=%.4f (< 1%% threshold, S1.2 known)^7', delta))
  else
    print(string.format('^1[recalc] LEDGER INCONSISTENCY — delta=%.4f (> 1%% threshold, escalate)^7', delta))
  end
end, true)
```

### `/sonar_bridge_idem_count`

Reporta el número de entradas activas en el backend de idempotency (memory mode: count in-process; DB mode: SQL count).

```lua
-- En sonar_bank/server/init.lua (smoke only — remover o gatear post-smoke):
RegisterCommand('sonar_bridge_idem_count', function(source)
  if source ~= 0 then return end

  -- Introspección del backend activo:
  local backend_name_ok, backend_name = pcall(function()
    return exports.sonar_bridges:IdemBackendName()
  end)
  local name = backend_name_ok and tostring(backend_name) or 'unknown'

  if name:sub(1, 2) == 'db' then
    -- DB mode: contar entradas activas en sonar_bridge_idempotency.
    local rows = SONAR.DB.Query(
      'SELECT COUNT(*) AS cnt FROM sonar_bridge_idempotency WHERE expires_at > UNIX_TIMESTAMP()'
    )
    local cnt = (rows and rows[1] and rows[1].cnt) or 'N/A'
    print(string.format('[idem] backend=%s | active_entries=%s', name, tostring(cnt)))
  else
    -- Memory mode: size in-process.
    print(string.format('[idem] backend=%s | (memory — query IdemStoreSize via Bridges._IdemStoreSize())', name))
  end
end, true)
```

### `/sonar_smoke_stress <from_iban> <to_iban> <count>` (paso 8)

```lua
-- En sonar_bank/server/init.lua (smoke only):
RegisterCommand('sonar_smoke_stress', function(source, args)
  if source ~= 0 then return end
  local from_iban = args[1]
  local to_iban   = args[2]
  local count     = tonumber(args[3]) or 10

  local from_acc = SONAR.Bank.Accounts.GetByIban(from_iban)
  if not from_acc then print('from_iban not found: ' .. tostring(from_iban)) return end

  local from_cid = from_acc.owner_citizen_id  -- necesita Accounts.GetCitizenIdByAccountId o similar
  -- Alternativa si citizen_id no está en acc row: pásalo como 4º arg: args[4]
  from_cid = args[4] or from_cid

  if not from_cid then
    print('Usage: sonar_smoke_stress <from_iban> <to_iban> <count> <from_citizen_id>')
    return
  end

  local ok_count, err_count = 0, 0
  for i = 1, count do
    local tid = string.format('smoke-stress-%04d', i)
    local s, _, ec = SONAR.Bank.Transfer.Execute(
      from_cid, from_iban, to_iban, 1.00, 'Stress ' .. i, tid
    )
    if s then ok_count = ok_count + 1
    else   err_count = err_count + 1
           if i <= 5 then print(string.format('  [stress] i=%d err=%s', i, tostring(ec))) end
    end
  end
  print(string.format('[smoke_stress] count=%d ok=%d errors=%d', count, ok_count, err_count))
end, true)
```

> **NOTA:** `Transfer.Execute` se llama server-side directo (no vía callback/rate-limit). El rate limit del callback C002 NO aplica aquí — el stress test mide atomicidad TX, no el path HTTP/callback. Si quieres testear rate limit, usa el loop de cliente del paso 6.
