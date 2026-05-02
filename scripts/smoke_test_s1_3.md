4# Smoke Test S1.3 — Escrow + FSM (C004 + C005)

**Sprint:** S1.3 — admirals_bank escrow lifecycle.
**Target:** 14/14 ✅ para sign-off + cleanup + close sprint 1.
**Pre-condición:** commit S1.3 Phase 1 aplicado + server restart.
**Fecha target:** 2026-05-02.

---

## 0. Pre-setup (founder)

### server.cfg — ACEs temporales (mismo patrón S1.2)

Añadir al `d:/fivem-dev/server-data/server.cfg` (eliminar post-sign-off):

```cfg
# S1.3 smoke harness — DELETE POST SIGN-OFF
# No admin commands nuevos en S1.3 (todos los smoke commands son client-side).
# Si quieres admin /admirals_escrow_* en el futuro, añade aquí.
```

(N/A en S1.3 — no admin server commands. Solo client commands ox_lib callbacks.)

### DB state esperado pre-smoke

```sql
-- Migration 006 ya aplicada + tracking row
SELECT version, filename, LEFT(checksum, 16) AS checksum_prefix, applied_by
FROM admirals_schema_versions WHERE version = 6;
-- Esperado: 1 row, applied_by='manual_pre_runner', checksum_prefix='7d37e4e2f765ce9a'

-- Tabla admirals_escrows existe + 0 rows pre-smoke
SELECT COUNT(*) AS escrows_count FROM admirals_escrows;
-- Esperado: 0

-- 2 player accounts personales + system treasury existentes
SELECT iban, type, balance FROM admirals_bank_accounts ORDER BY type;
-- Esperado ≥ 3 rows: 2 player (type=personal), 1 system (AD-SYS0-0000-0001)
```

### Players

- **Player A** (buyer) conectado → starter 2.500 €.
- **Player B** (seller) conectado → starter 2.500 €.
- Anota `IBAN_A`, `IBAN_B` para los pasos.

---

## 1. Pre-flight boot

**Acción:** `restart admirals_bank` en consola server.

**Esperado en consola:**
```
[admirals_core] Migration 006_escrow_schema.sql already applied (skip)
[admirals_core] Migrations done: 0 applied, 6 skipped, 0 errors
[admirals_bank] Admirals Bank v0.3.0 booting (C004 + C005 added)
[admirals_bank] IBAN module ready (prefix=AD-, charset_size=36, max_retries=5)
[admirals_bank] Accounts module ready (starter_balance=2500 €)
[admirals_bank] Movements module ready (ENUM categories: 13 valid)
[admirals_bank] Events module ready (transfer_completed §4.3 + escrow_created/released/refunded S1.3)
[admirals_bank] Transfer module ready (fee=0€, max=1000000€)
[admirals_bank] FSMEscrow module ready (states=5, transitions S1.3=3: created→locked, locked→released|refunded)
[admirals_bank] Escrow module ready (fee_rate=1.00%, fee_range=[2.00, 100.00]€, expiry_default=2592000s)
[admirals_bank] Callbacks registered: getBalance (C001), transfer (C002), createEscrow (C004), releaseEscrow (C005)
```

**resmon:** `admirals_bank` idle <0.3ms, `admirals_core` idle <0.3ms, `admirals_bridges` idle <0.3ms.

**Paso 1 ✅:** boot clean + logs orden correcto + sin errores.

---

## 2. C004 happy path — create escrow

**Acción (Player A buyer):** `/smoke_escrow_create <IBAN_B> 100`

**Esperado client:**
```
^2[smoke create] OK | escrow_id=<uuid> | fee_charged=2 | expires_at=<ts+30d> | request_id=<uuid>^7
```

- `fee_charged=2` (clamp mínimo per EscrowFeeMin — amount×0.01=1€ < 2€ floor).
- `expires_at ≈ now + 2592000`.

**Esperado DB:**
```sql
-- Player A (buyer) — balance debited: 2500 - 100 - 2 = 2398
SELECT iban, balance FROM admirals_bank_accounts WHERE iban='<IBAN_A>';
-- Esperado: 2398.00

-- Player B (seller) — balance unchanged (release pending)
SELECT iban, balance FROM admirals_bank_accounts WHERE iban='<IBAN_B>';
-- Esperado: 2500.00

-- System treasury — balance credited +2
SELECT iban, balance FROM admirals_bank_accounts WHERE iban='AD-SYS0-0000-0001';
-- Esperado: 10000002.00

-- Escrow account creado (type='escrow', owner_* NULL, balance=100)
SELECT type, balance, owner_account_id, owner_company_id
FROM admirals_bank_accounts
WHERE id = (SELECT escrow_account_id FROM admirals_escrows ORDER BY created_at DESC LIMIT 1);
-- Esperado: escrow | 100.00 | NULL | NULL

-- admirals_escrows row
SELECT id, status, amount, fee_charged, request_nonce, expires_at
FROM admirals_escrows
WHERE request_nonce = '<request_id del smoke>';
-- Esperado: 1 row, status='locked', amount=100, fee_charged=2

-- 4 movements creados con request_nonce = escrow_id
SELECT bank_account_id, amount, category, counterpart_iban
FROM admirals_bank_movements
WHERE request_nonce = '<escrow_id>'
ORDER BY id;
-- Esperado: 4 rows
--   -100 escrow_lock    (buyer → escrow iban)
--   -2   escrow_release (buyer → AD-SYS0-0000-0001)
--   +100 escrow_lock    (escrow ← buyer iban)
--   +2   escrow_release (system ← buyer iban)
```

**Paso 2 ✅:** response canonical shape + DB state consistent.

---

## 3. Idempotency replay — mismo request_id

**Acción (Player A):** `/smoke_escrow_replay` (sin args — usa cached del paso 2).

**Esperado client:** response idéntica byte-by-byte a paso 2 (mismo `escrow_id`, mismo `fee_charged`, mismo `expires_at`).

**Esperado consola server:**
```
[admirals_bank] Audit: bank.escrow_created / idempotency_replay / actor=<cid_A> / target=<request_id>
```

**Esperado DB:**
```sql
-- admirals_escrows counts NO cambian
SELECT COUNT(*) FROM admirals_escrows WHERE request_nonce = '<request_id>';
-- Esperado: 1 (no duplicado)

-- admirals_bridge_idempotency row persisted
SELECT module, method, LEFT(result_json, 50) AS preview, expires_at
FROM admirals_bridge_idempotency WHERE idem_key = '<request_id>';
-- Esperado: 1 row con result_json comenzando '{"success":true,"data":{"escrow_id":"...'
```

**Paso 3 ✅:** replay no re-ejecuta TX, balances identical.

---

## 4. Self-escrow rejected

**Acción (Player A):** `/smoke_escrow_create <IBAN_A> 50` (mismo IBAN buyer=seller).

**Esperado client:**
```
^1[smoke create] FAIL | error_code=SELF_ESCROW | message=No puedes crear un escrow contigo mismo.^7
```

**Esperado DB:** balances unchanged.

**Paso 4 ✅:** SELF_ESCROW validation.

---

## 5. Insufficient funds

**Acción (Player A con balance 2398):** `/smoke_escrow_create <IBAN_B> 5000` (excede saldo).

**Esperado client:**
```
^1[smoke create] FAIL | error_code=INSUFFICIENT_FUNDS | message=Saldo insuficiente (monto + comisión).^7
```

**Esperado DB:** balances unchanged (pre-flight check evita TX).

**Paso 5 ✅:** INSUFFICIENT_FUNDS guard.

---

## 6. Fee clamps — boundary tests

**Acciones (Player A, crear nuevos escrows con amounts variados):**

| Amount | Expected fee | Reasoning |
|---|---|---|
| 100 | 2.00 | 100×0.01=1 → clamp min 2 |
| 500 | 5.00 | 500×0.01=5 → en rango |
| 10000 | 100.00 | 10000×0.01=100 → clamp max |
| 20000 | 100.00 | 20000×0.01=200 → clamp max |

**Para cada uno:** `/smoke_escrow_create <IBAN_B> <amount>` → verifica `fee_charged` del response.

**NOTA:** Player A ya debitó 2398. Para 10000/20000 necesita saldo extra. Admin puede hacer:
```sql
UPDATE admirals_bank_accounts SET balance = 50000, updated_at = UNIX_TIMESTAMP()
WHERE iban = '<IBAN_A>';
```

**Paso 6 ✅:** 4/4 fee clamps correctos.

---

## 7. C005 release to seller (direction='seller')

**Acción:**
1. Player A crea escrow 500€ a Player B: `/smoke_escrow_create <IBAN_B> 500` → anotar `ESCROW_ID`.
2. **Player B (seller)** ejecuta: `/smoke_escrow_release_seller <ESCROW_ID>`.

**Esperado client (Player B):**
```
^2[smoke release_seller] OK | released_amount_seller=500 | released_amount_buyer=0 | timestamp=<ms> | request_id=<uuid>^7
```

**Esperado DB:**
```sql
-- admirals_escrows FSM transition locked→released
SELECT status, released_to, released_by_account_id, released_at
FROM admirals_escrows WHERE id = '<ESCROW_ID>';
-- Esperado: released | seller | <account_id_B> | <ts>

-- Player B balance += 500
SELECT balance FROM admirals_bank_accounts WHERE iban='<IBAN_B>';
-- Esperado: 3000.00 (2500 + 500)

-- Escrow account balance = 0 (funds moved out)
SELECT balance FROM admirals_bank_accounts
WHERE id = (SELECT escrow_account_id FROM admirals_escrows WHERE id='<ESCROW_ID>');
-- Esperado: 0.00

-- System treasury unchanged (fee cobrado en Create, NO se devuelve)
SELECT balance FROM admirals_bank_accounts WHERE iban='AD-SYS0-0000-0001';
-- Esperado: sin cambio respecto a paso anterior
```

**Paso 7 ✅:** release to seller + FSM transition + balances consistent.

---

## 8. C005 refund to buyer (direction='buyer')

**Acción:**
1. Player A crea escrow 300€ a Player B: `/smoke_escrow_create <IBAN_B> 300` → anotar `ESCROW_ID2`.
2. **Player A (buyer)** ejecuta: `/smoke_escrow_release_buyer <ESCROW_ID2>`.

**Esperado client (Player A):**
```
^2[smoke release_buyer] OK | released_amount_seller=0 | released_amount_buyer=300 | timestamp=<ms>^7
```

**Esperado DB:**
```sql
SELECT status, released_to FROM admirals_escrows WHERE id='<ESCROW_ID2>';
-- Esperado: refunded | buyer

-- Player A recupera 300 (pero fee=3€ retenido)
-- A pre-create: X, post-create: X - 303, post-refund: X - 3 (fee no devuelto)
SELECT balance FROM admirals_bank_accounts WHERE iban='<IBAN_A>';
-- Esperado: saldo - 3 respecto a pre-step8 (300 devuelto, 3 fee perdido).
```

**Paso 8 ✅:** refund flow + fee retained per economy §10.4.2.

---

## 9. NOT_AUTHORIZED — wrong caller

**Acción:**
1. Player A crea escrow 50€ a Player B: `/smoke_escrow_create <IBAN_B> 50` → anotar `ESCROW_ID3`.
2. **Player A (buyer, not seller)** intenta release to seller: `/smoke_escrow_release_seller <ESCROW_ID3>`.

**Esperado client:**
```
^1[smoke release_seller] FAIL | error_code=NOT_AUTHORIZED | message=No estás autorizado para esta liberación.^7
```

**Esperado DB:** escrow sigue `status='locked'` (no transition).

**Acción inversa:**
3. **Player B (seller)** intenta refund to buyer: `/smoke_escrow_release_buyer <ESCROW_ID3>`.

**Esperado:** mismo error `NOT_AUTHORIZED`.

**Paso 9 ✅:** auth matrix enforces direction×caller.

---

## 10. NOT_IMPLEMENTED — split release

**Acción (Player A o B, cualquier caller):** `/smoke_escrow_split <ESCROW_ID3>` (escrow aún locked del paso 9).

**Esperado client:**
```
^1[smoke split_rejected] FAIL | error_code=NOT_IMPLEMENTED | message=Modo split aún no implementado (S3+).^7
```

**Esperado DB:** escrow sigue `status='locked'`.

**Paso 10 ✅:** split deferred S3+, short-circuit antes de auth check.

---

## 11. Double-release protection — FSM guard

**Acción (reusa ESCROW_ID del paso 7, already released):**

**Player B:** `/smoke_escrow_release_seller <ESCROW_ID>` (2ª vez).

**Esperado client:**
```
^1[smoke release_seller] FAIL | error_code=INVALID_STATE | message=Escrow no está en estado liberable (locked requerido).^7
```

**Esperado consola server:**
```
[admirals_bank] Escrow.Release: FSM reject released→released for escrow=<uuid> (reason=TRANSITION_NOT_ALLOWED)
```

**Paso 11 ✅:** FSM guard previene double-release.

---

## 12. Rate limit — 11 calls burst

**Acción (Player A, 11 escrows rápidos con request_ids únicos):**

Ejecutar 11 veces seguidas (dentro de 60s): `/smoke_escrow_create <IBAN_B> 10`.

**Esperado:**
- Primeras 10 calls: algunas succeed, eventualmente saldo insuficiente cuando Player A < 12€ por escrow.
- Call 11 (o antes si fondos ok): `error_code=RATE_LIMITED`.

**Esperado DB:**
```sql
SELECT Admirals.Rate.Stats();  -- via admin command /admirals_core_status o exec snippet
-- bank.write: allowed=10, blocked≥1
```

**Paso 12 ✅:** rate limit 10/60s en bucket bank.write compartido C002+C004+C005.

---

## 13. Event subscription

**Acción (consola server):**
```lua
Admirals.Bus.Subscribe('admirals:bank:escrow_created', function(p)
  print('[sub] escrow_created: ' .. json.encode(p))
end)

Admirals.Bus.Subscribe('admirals:bank:escrow_released', function(p)
  print('[sub] escrow_released: ' .. json.encode(p))
end)

Admirals.Bus.Subscribe('admirals:bank:escrow_refunded', function(p)
  print('[sub] escrow_refunded: ' .. json.encode(p))
end)
```

**Después:** Player A ejecuta 1 create + 1 release (seller o buyer).

**Esperado consola:** 2 líneas `[sub]` con payloads canonical (escrow_id, amount, fee_charged, _event_id, _emitted_at, _schema_version, etc.).

**Paso 13 ✅:** 3 eventos publicados + auto-decoración tracing keys.

---

## 14. resmon performance

**Acción:** durante step 12 burst + step 7/8 releases, observar consola: `resmon`.

**Esperado:**
- `admirals_bank` peak <1ms, idle post-stress <0.3ms.
- `admirals_core` peak <1ms, idle <0.3ms.
- `admirals_bridges` peak <0.5ms, idle <0.2ms.

**Paso 14 ✅:** performance dentro de budget §06 §2.2.

---

## Sign-off

**Criteria:** 14/14 ✅ todos los steps.

Tras sign-off:
1. Commit `S1.3 phase1 implement escrow + FSM + migration 006 + smoke 14/14`.
2. Cleanup commit separado (smoke harness delete): `S1.3 cleanup remove temporal smoke harness post sign-off`.
   - Delete `resources/admirals_bank/client/smoke_s1_3.lua`.
   - Edit `resources/admirals_bank/fxmanifest.lua` — remove `client_scripts` block.
3. Phase 2 close sprint:
   - Create `progress/SPRINT_RETRO_S1.md`.
   - Create `progress/SPRINT_PLAN_S2.md` (outline).
   - Update `docs/planning/01_roadmap.md` §4.2 S1 marked ✅ (o documentar para revisión founder).
   - Update `docs/agents/00_BOOTSTRAP.md` v1.3 → v1.4 si cambio de fase.
   - `git tag v0.1.0` + `git push --tags`.

**Si algún paso falla** → STOP + reporte + propuesta fix + green-light founder → sub-iteración.

---

## Troubleshooting

### Boot fail-fast en migration 006 (checksum mismatch)

Síntoma consola:
```
[admirals_core] 006_escrow_schema.sql checksum mismatch: stored=<X> current=<Y> (TAMPERING SUSPECT)
```

**Causa:** file `006_escrow_schema.sql` fue editado post-INSERT tracking row → hash cambió.

**Fix:** recalcular hash + UPDATE tracking row:
```powershell
(Get-FileHash -Algorithm SHA256 D:\theBigProject\resources\admirals_core\migrations\006_escrow_schema.sql).Hash.ToLower()
```
```sql
UPDATE admirals_schema_versions SET checksum = '<new_hash>' WHERE version = 6;
```

### Escrow account no se puede crear (CHECK violation)

Síntoma: `error_code=RACE_DETECTED` o `TX_ROLLBACK` en step 2 sin race real.

**Causa:** migration 006 constraint `chk_admirals_bank_accounts_owner_xor_or_escrow` mal aplicado (rama `type='escrow'` missing).

**Fix verify:**
```sql
SHOW CREATE TABLE admirals_bank_accounts\G
-- Buscar: CONSTRAINT `chk_admirals_bank_accounts_owner_xor_or_escrow` CHECK (`type` = 'escrow' or ...)
```
