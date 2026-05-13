# MIGRATION_PATTERNS — Spec técnica del patcher automatizado qb-* → SONAR exports

**Phase:** BANK-BE.PHASE_5.6 (reframed) — Automated Patcher Strategy
**Authors:** PM Cascade + Backend Lead + Product Engineer (next session)
**Authority:** Founder yaboula architectural decision 2026-05-13 05:00 UTC+02 — "Path A AUTOMATIZADO mediante herramientas de migración. Cero lógica de sincronización reactiva en qb-core. Sustitución limpia y directa del código viejo."
**Doctrine preserved:** SONAR authoritative master + Founder Q4 LOCKED 2026-05-12 "no shim, operator-side patch responsibility" + Phase 3 cleanup intact.
**Supersedes:** `docs/agents/teams/prompts/10_phase_5_cross_script_sync_lead.md` paragraph 8.5 Path E (descartado).
**Status:** SPEC — ready for patcher implementation in Phase 5.6.x

---

## 1. Mission del patcher

**Input:** árbol `D:\FiveM_Server\Sonar\resources\[qb]\` (56 resources) + cualquier custom resource adicional pasado vía `--include`.

**Output:**

1. **Patches unificados** (`migration_output/<resource>/<file>.diff`) listos para aplicar manualmente o vía `--apply` con backup automático `.bak`.
2. **`migration_output/auto_patched.md`** — inventario de cada sustitución segura aplicada con pattern ID + before/after snippet + line range.
3. **`migration_output/manual_review.md`** — catalog ordenado por severidad de cada call site **NO migrado automáticamente** con pattern ID + reason rejection + recomendación operator.
4. **`migration_output/summary.json`** — métricas estructuradas (resource, total_call_sites, auto_patched_count, manual_count, files_touched, pattern_distribution) para CI/observability.

**Modes (CLI flags):**

- `--dry-run` (default) — genera diffs y reportes sin tocar archivos.
- `--apply` — escribe `.bak` luego aplica patches in-place.
- `--filter-resource=<glob>` — restringe scope (ej `qb-vehicleshop` o `qb-*shop`).
- `--money-types=bank` (default) — Phase A scope. Phase B opt-in via `--money-types=bank,cash,crypto`.
- `--rollback` — restaura `.bak` (idempotente).
- `--no-color` — CI/log friendly output.

**Lenguaje:** Python 3.11+, dependencies mínimas (regex, pathlib, dataclasses, json). NO tree-sitter Phase A (overkill); regex + heurística scope-traversal suficiente. Tree-sitter-lua opcional Phase B si U3 nested-closure resolution justifica complejidad.

---

## 2. Source code real samples reference (server scan PM Cascade 2026-05-13)

Confirmado en `D:\FiveM_Server\Sonar\resources\[qb]\` — sample real de los 39 vanilla hits inicialmente identificados (top 6 resources):

```lua
-- qb-vehicleshop\server.lua:179-182
player.Functions.RemoveMoney('cash', paymentAmount, 'financed vehicle')
player.Functions.RemoveMoney('bank', paymentAmount, 'financed vehicle')

-- qb-vehicleshop\server.lua:206
player.Functions.RemoveMoney('cash', vehBalance, 'paid off vehicle')

-- qb-shops\main.lua:43
Player.Functions.AddMoney('bank', Config.DeliveryPrice, 'qb-shops:deliveryPay')

-- qb-shops\main.lua:79-83
if Player.Functions.RemoveMoney('cash', Config.TruckDeposit, 'tow-received-bail') then
  -- ...
elseif Player.Functions.RemoveMoney('bank', Config.TruckDeposit, 'tow-received-bail') then
  -- ...

-- qb-pawnshop\main.lua:38-40
Player.Functions.AddMoney('bank', totalPrice, 'qb-pawnshop:server:sellPawnItems')
Player.Functions.AddMoney('cash', totalPrice, 'qb-pawnshop:server:sellPawnItems')

-- qb-houses\main.lua:262, 416
pData.Functions.RemoveMoney('bank', HousePrice, 'bought-house')
pData.Functions.RemoveMoney('bank', price, 'bought-furniture')

-- qb-vehiclesales\main.lua:98, 114, 125
Player.Functions.AddMoney('bank', payout, 'sold vehicle back')
Player.Functions.RemoveMoney('bank', result[1].price, 'bought vehicle used lot')
SellerData.Functions.AddMoney('bank', NewPrice, 'sold vehicle used lot')

-- qb-drugs\cornerselling.lua:49
Player.Functions.AddMoney('cash', price, 'qb-drugs:server:sellCornerDrugs')

-- qb-drugs\deliveries.lua:23, 56
Player.Functions.AddMoney('cash', amount * Config.Dealers[dealer]['products'][itemData.slot].price, '...')
Player.Functions.AddMoney('cash', math.floor(payout * copModifier), 'qb-drugs:server:successDelivery')
```

**Variables de player binding observadas:** `Player`, `player`, `pData`, `SellerData`, `target`, `xPlayer`, `Target`, `victim` (extensible).

**Patrones de derivación de `source`:**
- `local Player = QBCore.Functions.GetPlayer(source)` — más común
- `local Player = QBCore.Functions.GetPlayer(src)` — equivalente
- `local Player = QBCore.Functions.GetPlayer(playerId)` — callback/RPC
- `local Player = QBCore.Functions.GetOfflinePlayer(citizenid)` — offline path
- `local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)` — online by cid
- `Player.PlayerData.source` — derive desde player object directo
- `self.PlayerData.source` — closure context

---

## 3. SONAR exports surface canónica (Phase 5 LOCKED v1.0.2 R2)

Verificado en `resources/sonar_bank_app/server/api/public_api.lua:337-351` y `admin_api.lua:220-229` — **22 exports total**.

### 3.1 Public exports (12) — caller debe ser online player o context con `source`

| SONAR export | Signature | Replaces |
|---|---|---|
| `AddMoney(src, amount_minor, reason, opts?)` | `(src:int, amt:int, reason:str, opts:tbl?)` → `(ok:bool, err:str?, data:tbl?)` | `Player.Functions.AddMoney('bank', amount, reason)` |
| `RemoveMoney(src, amount_minor, reason, opts?)` | idem | `Player.Functions.RemoveMoney('bank', amount, reason)` |
| `CanAfford(src, amount_minor)` | `(src:int, amt:int)` → `(ok:bool, err:str?, data:tbl?)` | gate check pre-mutation |
| `GetBalance(src)` | `(src:int)` → `(ok:bool, err:str?, data:tbl{balance_minor})` | `Player.PlayerData.money.bank` read |
| `TransferBySource(from_src, to_src, amt_minor, reason, opts?)` | atomic 2-row | manual transfer logic |
| `TransferByIban(from_iban, to_iban, amt_minor, reason, opts?)` | atomic 2-row | manual IBAN transfer |
| `AddMoneyByCitizen(cid, amt_minor, reason, opts?)` | offline-safe | `OfflinePlayer.Functions.AddMoney('bank', ...)` |
| `RemoveMoneyByCitizen(cid, amt_minor, reason, opts?)` | offline-safe | `OfflinePlayer.Functions.RemoveMoney('bank', ...)` |
| `CanAffordByCitizen(cid, amt_minor)` | offline-safe | gate check by cid |
| `GetBalanceByCitizen(cid)` | offline-safe | balance read by cid |
| `TransferByCitizen(from_cid, to_cid, amt_minor, reason, opts?)` | offline-safe atomic | cid-to-cid transfer |
| `GetApiVersion()` | `()` → `tbl{major,minor,patch,phase,api_lock}` | introspection |

### 3.2 Admin exports (10) — requires `actor_src` con ACE `sonar.bank.admin.*`

| Export | Replaces | Patcher action |
|---|---|---|
| `AdminCredit(actor_src, target, amt_minor, reason, opts?)` | `/admincash`, GM tools, qb-adminmenu give | MANUAL (admin context) |
| `AdminDebit(actor_src, target, amt_minor, reason, opts?)` | admin debit tools | MANUAL |
| `AdminSetBalance(actor_src, target, new_amt_minor, reason, opts?)` | `Player.Functions.SetMoney('bank', x, ...)` admin context | MANUAL |
| `Freeze(actor_src, iban, reason)` | freeze account compliance | MANUAL |
| `Unfreeze(actor_src, iban, reason)` | unfreeze | MANUAL |
| `AdminCreditByCitizen` / `AdminDebitByCitizen` / `AdminSetBalanceByCitizen` / `FreezeByCitizen` / `UnfreezeByCitizen` | cid-scoped admin variants | MANUAL |

**Patcher decision: TODOS los admin exports = MANUAL.** Razón: requieren `actor_src` que es ACE-checked, contexto humano admin no derivable automáticamente.

### 3.3 `opts` shape canonical

```lua
opts = {
  idempotency_key = string|nil,    -- SHA256/UUID; if nil, NO idempotency (vanilla qb behavior)
  correlation_id = string|nil,     -- UUID for cross-call traceability; if nil, generated server-side
  allow_overdraft = boolean|nil,   -- admin/system only; default false
}
```

**Phase A patcher emite siempre `nil` opts** → `exports.sonar_bank_app:AddMoney(src, amt, reason, nil)` o equivalente sin opts (signature soporta omisión). Operadores opt-in idem keys vía manual review post-migration.

### 3.4 Return value translation table

| QBCore call | Vanilla return | SONAR return | Patcher rewrite |
|---|---|---|---|
| `Player.Functions.AddMoney(...)` | `bool` (true=success) | `(ok, err, data)` triple | `local ok = exports.sonar_bank_app:AddMoney(...)` (drops err+data) — safe Phase A |
| `Player.Functions.RemoveMoney(...)` | `bool` | triple | idem |
| `if Player.Functions.RemoveMoney(...) then` | bool truthy check | triple — solo `ok` interesa | `local ok = exports.sonar_bank_app:RemoveMoney(...); if ok then` |
| `Player.Functions.GetMoney('bank')` | `number` (decimal major) | `(ok, err, data{balance_minor})` | `local ok, _, data = exports.sonar_bank_app:GetBalance(src); local balance = ok and (data.balance_minor / 100) or 0` (decimal major restored) |

---

## 4. Unit conversion analysis (CRITICAL — fuente principal de bugs si patcher no es estricto)

QBCore opera en **DECIMAL major** (`5000` = $5000.00). SONAR opera en **INTEGER minor** (`500000` = $5000.00). Patcher **DEBE** multiplicar por 100 — pero solo cuando es **provably safe**.

### 4.1 Reglas de safety

| Caso | Ejemplo | Patcher action |
|---|---|---|
| Literal integer | `Player.Functions.AddMoney('bank', 5000, 'reason')` | ✅ AUTO `amt * 100` → `500000` directo (constant fold) |
| Literal float (NO esperado en qb pero defensivo) | `... 'bank', 50.5, ...` | 🔴 MANUAL — qb-core requiere int, float es bug-canary |
| Variable simple | `Player.Functions.AddMoney('bank', amount, 'reason')` | 🟡 AUTO con `amount * 100` runtime — **siempre que `amount` sea verificadamente major** (ver §4.2) |
| `Config.X` | `Player.Functions.AddMoney('bank', Config.DeliveryPrice, 'reason')` | 🟡 AUTO con `Config.DeliveryPrice * 100` — Config values en qb son major por convención (high confidence) |
| Field access | `Player.Functions.AddMoney('bank', item.price, 'reason')` | 🟡 AUTO con `item.price * 100` — qb item prices son major (high confidence) |
| Aritmética compleja | `Player.Functions.AddMoney('bank', amount * 0.85, 'reason')` | 🟡 AUTO con `(amount * 0.85) * 100` — paréntesis para preservar precedence; floor opcional vía wrapper |
| Function call | `Player.Functions.AddMoney('bank', math.floor(payout * mod), 'reason')` | 🟡 AUTO con `math.floor((payout * mod) * 100)` — re-flooring inner |
| Return value | `Player.Functions.AddMoney('bank', GetPrice(), 'reason')` | 🔴 MANUAL — patcher no puede inferir retorno semantics |

### 4.2 Heurística "amount is major"

Patcher asume MAJOR (no minor) por default porque:
- 100% de los samples observados en 39 hits son major (qb convention)
- Variables nombradas con prefijo/sufijo `_minor`, `_cents` → flag MANUAL (operator ya migró parcialmente, no double-shift)
- Variables nombradas `_major` → confirmar major

Lista de identifier names que disparan flag MANUAL (heurística defensiva):
- `*_minor`, `*_cents`, `*_centavos`, `minor_amount`, `amountMinor`, `amount_minor`, `cents`

### 4.3 Anti-doble-shift safeguard

Patcher inserta marker comment para audit:
```lua
-- SONAR_PATCHED v1: <pattern_id> <orig_line> <date>
exports.sonar_bank_app:AddMoney(source, (amount) * 100, reason, nil)
```

Si patcher detecta marker `SONAR_PATCHED` en file → skip file con warning "already patched, idempotent re-run". Previene double-shift en re-ejecución.

---

## 5. Source resolution rules (binding traversal)

El patcher debe resolver `<player_var>` → `<src_expression>` antes de emitir replacement. Algoritmo:

### 5.1 Función scope analyzer

1. Identificar scope de la línea con call site: walk backwards hasta hallar `function` keyword o top-of-file.
2. En ese scope, buscar pattern de binding (regex):
   ```regex
   local\s+(\w+)\s*=\s*QBCore\.Functions\.GetPlayer\s*\(\s*([^)]+)\s*\)
   local\s+(\w+)\s*=\s*QBCore\.Functions\.GetOfflinePlayer\s*\(\s*([^)]+)\s*\)
   local\s+(\w+)\s*=\s*QBCore\.Functions\.GetPlayerByCitizenId\s*\(\s*([^)]+)\s*\)
   ```
3. Para cada binding `(<var_name>, <arg_expr>)`:
   - Si `<var_name>` matches `<player_var>` del call site → resolver:
     - GetPlayer / GetPlayerByCitizenId con arg `source|src|playerId|playerSource|<int_literal>` → ONLINE path → `<src_expression> = arg_expr`
     - GetOfflinePlayer con arg `<cid_string>` → OFFLINE path → use `*ByCitizen` variants

### 5.2 Pattern variations supported

```lua
-- Online direct (most common)
local Player = QBCore.Functions.GetPlayer(source)
Player.Functions.AddMoney('bank', 100, 'r')
-- → exports.sonar_bank_app:AddMoney(source, 100 * 100, 'r', nil)

-- Online via src alias
local p = QBCore.Functions.GetPlayer(src)
p.Functions.RemoveMoney('bank', 50, 'r')
-- → exports.sonar_bank_app:RemoveMoney(src, 50 * 100, 'r', nil)

-- Online via custom param name
QBCore.Functions.CreateCallback('xx', function(playerId, cb, args)
  local Target = QBCore.Functions.GetPlayer(playerId)
  Target.Functions.AddMoney('bank', args.amount, 'r')
end)
-- → exports.sonar_bank_app:AddMoney(playerId, args.amount * 100, 'r', nil)

-- Offline by citizenid
local Pdata = QBCore.Functions.GetOfflinePlayer(citizenid)
Pdata.Functions.AddMoney('bank', amount, 'r')
-- → exports.sonar_bank_app:AddMoneyByCitizen(citizenid, amount * 100, 'r', nil)
```

### 5.3 Cuando binding NO se resuelve → MANUAL

- Player object passed as function parameter sin binding visible: `function processBuy(buyer, amount) buyer.Functions.AddMoney('bank', amount, 'r') end` → MANUAL (caller context unknown)
- Loop iterator: `for _, p in pairs(QBCore.Functions.GetQBPlayers()) do p.Functions.AddMoney(...) end` → MANUAL (multi-target)
- `self.Functions.AddMoney(...)` (method context) → MANUAL (binding desde caller, requiere AST)
- Binding fuera de scope analyzable (módulo lib, file include, etc.) → MANUAL

---

## 6. SAFE patterns S1-S4 (auto-replace)

### S1 — Online player AddMoney/RemoveMoney bank

**Detection regex** (anchor):
```regex
\b(\w+)\.Functions\.(AddMoney|RemoveMoney)\(\s*['"]bank['"]\s*,\s*([^,]+)\s*,\s*([^)]+)\)
```

**Pre-conditions:**
- `<var>` (group 1) resuelve a binding GetPlayer/GetPlayerByCitizenId (NOT GetOfflinePlayer) en mismo scope
- `<amount_expr>` (group 3) NO matches anti-shift heuristic §4.2
- Call NO es bare statement con return-check no-trivial (para esos S2)

**Replacement template:**
```lua
exports.sonar_bank_app:<MappedExport>(<src_expr>, (<amount_expr>) * 100, <reason_expr>, nil)
```

`<MappedExport>` = `AddMoney` | `RemoveMoney`.

### S2 — Online player RemoveMoney with truthy if-check

**Detection regex:**
```regex
\bif\s+(\w+)\.Functions\.RemoveMoney\(\s*['"]bank['"]\s*,\s*([^,]+)\s*,\s*([^)]+)\)\s+then
```

**Replacement template** (multi-line, requires hash for unique local names):
```lua
local ok_<HASH8>, _, _ = exports.sonar_bank_app:RemoveMoney(<src_expr>, (<amount_expr>) * 100, <reason_expr>, nil)
if ok_<HASH8> then
```

`<HASH8>` = first 8 hex chars of MD5(file_path + line_number + amount_expr) — collision-resistant within file scope.

**Edge case `elseif`:** patcher transforma `elseif Player.Functions.RemoveMoney(...) then` analógicamente con local intermedio:
```lua
-- antes
if A then ...
elseif Player.Functions.RemoveMoney('bank', x, 'r') then ...
end
-- después
if A then ...
else
  local ok_<H>, _, _ = exports.sonar_bank_app:RemoveMoney(src, x * 100, 'r', nil)
  if ok_<H> then ...
  end
end
```
🟡 Patcher MAY emit este shape pero requiere extra-care; flag REVIEW si elseif chain length > 1.

### S3 — Offline player by citizenid AddMoney/RemoveMoney bank

**Detection prerequisite:** binding upstream `local <var> = QBCore.Functions.GetOfflinePlayer(<cid_expr>)`.

**Replacement template:**
```lua
exports.sonar_bank_app:<MappedExport>ByCitizen(<cid_expr>, (<amount_expr>) * 100, <reason_expr>, nil)
```

### S4 — GetBalance read pattern

**Detection regex:**
```regex
\b(\w+)\.PlayerData\.money\.bank\b
```

**Pre-conditions:**
- `<var>` resuelve a online binding GetPlayer

**Replacement template:**
```lua
(select(3, exports.sonar_bank_app:GetBalance(<src_expr>)) or { balance_minor = 0 }).balance_minor / 100
```

🟡 Verbose. Patcher emite solo si call site es read-only (right-hand side of expression). Write context (`P.PlayerData.money.bank = ...`) → U4 MANUAL.

**Better strategy (Phase A safer):** S4 = MANUAL by default. Operators preservan `Player.PlayerData.money.bank` reads en Phase A (no breaking — son lecturas, no mutations); Phase B refactor opcional. Esto reduce riesgo patcher Phase A.

**Decision Phase A:** S4 SKIPPED en patcher v1. Solo S1+S2+S3 active.

---

## 7. UNSAFE patterns U1-U9 (manual review required)

Patcher detecta + reporta + NO modifica. Cada uno con regex detection + reasoning emitido a `manual_review.md`.

### U1 — Cash or crypto moneytype (Phase A out-of-scope)

```regex
\b\w+\.Functions\.(AddMoney|RemoveMoney|SetMoney)\(\s*['"](cash|crypto|black_money)['"]\s*,
```

**Severity:** INFO (Phase B scope deferral).
**Action:** Skip silently in summary count. Optional list in `manual_review.md` for inventory.

### U2 — SetMoney always

```regex
\b\w+\.Functions\.SetMoney\(\s*['"]bank['"]\s*,
```

**Severity:** HIGH.
**Reasoning:** SetMoney sobreescribe balance entero (destructive). SONAR equivalente requiere `GetBalance` + delta computation + `AddMoney`/`RemoveMoney` con reason explanatorio. Operator debe analizar caso-por-caso si la semántica "set" es intencional o si fue uso lazy de `Add`+ override implícito.

**Manual review template:**
```
File: <path>:<line>
Original: <Identifier>.Functions.SetMoney('bank', <amount>, '<reason>')
Recommended migration:
  local ok, _, data = exports.sonar_bank_app:GetBalanceByCitizen(<cid>)
  if ok then
    local current_minor = data.balance_minor
    local target_minor = (<amount>) * 100
    local delta_minor = target_minor - current_minor
    if delta_minor > 0 then
      exports.sonar_bank_app:AddMoneyByCitizen(<cid>, delta_minor, 'set: <reason>', nil)
    elseif delta_minor < 0 then
      exports.sonar_bank_app:RemoveMoneyByCitizen(<cid>, -delta_minor, 'set: <reason>', nil)
    end
  end
```

### U3 — Nested closure / multi-target / iterator

```regex
\bfor\s+\w+\s*,\s*(\w+)\s+in\s+pairs\s*\([^)]+\)\s+do[\s\S]*?\1\.Functions\.(Add|Remove|Set)Money
```

**Severity:** MEDIUM.
**Reasoning:** Loop binding `<player_var>` no resoluble a `src` único; cada iteration tiene `src` distinto. Operator debe inyectar `local src = <player>.PlayerData.source` dentro del loop o switch a `*ByCitizen` con `<player>.PlayerData.citizenid`.

### U4 — Direct PlayerData memory mutation (legacy/hostile)

```regex
\b\w+\.PlayerData\.money\.bank\s*=
\b\w+\.PlayerData\.money\[['"]bank['"]\]\s*=
```

**Severity:** CRITICAL.
**Reasoning:** Bypass total de QBCore Player.Functions API + bypass total SONAR. No genera evento `QBCore:Server:OnMoneyChange` ni cualquier audit. Operator DEBE refactor a llamada SONAR export.

### U5 — Inline raw SQL bypassing both layers

```regex
(MySQL\.\w+\(['"][^'"]*UPDATE\s+players\s+SET\s+money|exports\.oxmysql:\w+\(['"][^'"]*JSON_SET\([^)]*money)
```

**Severity:** CRITICAL.
**Reasoning:** Direct SQL mutation. No audit, no balance sync, no integrity. Manual rewrite obligatorio.

### U6 — qb-banking exports (society/job/gang accounts)

```regex
exports\[?['"]qb-banking['"]\]?:(AddMoney|RemoveMoney|GetAccount|GetAccountBalance|CreatePlayerAccount)
```

**Severity:** INFO (Phase B scope).
**Reasoning:** qb-banking maneja society accounts (job/gang/shared) — diferente paradigma que player accounts. Phase A scope solo player.bank. Phase B = SONAR society accounts API si futuro instalan qb-banking.

### U7 — Cash-as-item via inventory

```regex
exports\[?['"](qb-inventory|ox_inventory)['"]\]?:(AddItem|RemoveItem)\(\s*[^,]+,\s*['"]money['"]
exports\[?['"](qb-inventory|ox_inventory)['"]\]?:(AddItem|RemoveItem)\(\s*[^,]+,\s*['"]cash['"]
```

**Severity:** INFO (Phase B).

### U8 — Custom function call returning amount (unit unknown)

```regex
\b\w+\.Functions\.(AddMoney|RemoveMoney)\(\s*['"]bank['"]\s*,\s*\w+\([^)]*\)\s*,
```

**Severity:** MEDIUM.
**Reasoning:** Function call return value unit indeterminate. Operator confirma manually if return is major or pre-multiplied minor.

### U9 — Identifier name suggests already-minor unit

```regex
\b\w+\.Functions\.(AddMoney|RemoveMoney)\(\s*['"]bank['"]\s*,\s*\w*(_minor|_cents|_centavos|Minor|Cents)\b
```

**Severity:** HIGH (potential double-shift bug).
**Reasoning:** Variable suffix sugiere que ya está en minor units. Auto `* 100` causaría double-shift = catastrophic balance corruption.

---

## 8. Reason field passthrough rules

`reason` es free-form string en SONAR (acepta literal, concatenación, variable, function call). Patcher passes through verbatim. SONAR server-side adopta:
- `invoker_resource` = `GetInvokingResource()` (the qb-* resource calling the export)
- `actor_account_id` = derivado de `src` o `cid` provisto
- `correlation_id` = generado server-side si no provisto en opts

**Convention recommendation (MIGRATION.md addendum):** operators SHOULD prefix reason con `<resource>:<action>` formato (ej `qb-vehicleshop:purchase_financed`) para audit forensic clarity post-migration. Patcher NO altera reason existing — solo emit recomendación en `manual_review.md` si reason no matches `^[a-z][a-z_-]+:` regex (heurística "structured reason").

---

## 9. Idempotency strategy migrated calls

Phase A patcher emite `nil` opts (sin idempotency_key). Razón:

- Vanilla qb behavior = no idempotency (replays generan duplicate mutations)
- Migrated calls preservan vanilla semantics (no breaking)
- Operators opt-in idem keys vía manual review post-migration para HIGH-VALUE calls (vehicle purchase, house buy, salary)

**Phase B opcional:** patcher v2 podría inyectar `idempotency_key = ('migrated:' .. resource_name .. ':' .. file_hash .. ':' .. line_number .. ':' .. tostring(GetGameTimer()))` — pero requiere análisis call-site whether replay is intentional or bug. Phase A safer = nil.

---

## 10. fxmanifest.lua dependency injection

**Pre-condition de patcher:** cada qb-* resource patched DEBE declarar `dependency 'sonar_bank_app'` en su `fxmanifest.lua` para garantizar load order y export availability.

Patcher detecta `fxmanifest.lua` (or `__resource.lua` legacy) en cada resource patched y:
- Si `dependencies` o `dependency` block presente → INJECT `'sonar_bank_app'` si no existe
- Si NO presente → CREATE `dependencies { 'sonar_bank_app' }` block después de `fx_version` line

**Patch ejemplo:**
```lua
-- antes
fx_version 'cerulean'
game 'gta5'
description 'qb-vehicleshop'

-- después
fx_version 'cerulean'
game 'gta5'
description 'qb-vehicleshop'
dependencies {
  'sonar_bank_app',
}
```

Si dependencies block ya existe con otros entries:
```lua
-- antes
dependencies {
  'qb-core',
  'oxmysql',
}
-- después
dependencies {
  'qb-core',
  'oxmysql',
  'sonar_bank_app',
}
```

---

## 11. Output artifacts spec (CLI behavior)

### 11.1 `migration_output/` directory layout

```
migration_output/
  auto_patched.md          # Inventory de cada sustitución safe aplicada
  manual_review.md         # Catalog ordenado U1-U9 con recomendaciones
  summary.json             # Métricas estructuradas para CI
  qb-vehicleshop/
    server.lua.diff        # Unified diff
    server.lua.bak         # Backup pre-apply (only if --apply)
    fxmanifest.lua.diff    # Dependency injection
  qb-shops/
    main.lua.diff
    fxmanifest.lua.diff
  ...
```

### 11.2 `summary.json` schema

```json
{
  "phase": "5.6",
  "patcher_version": "1.0.0",
  "scope_money_types": ["bank"],
  "executed_at": "2026-05-13T05:30:00Z",
  "mode": "dry-run",
  "totals": {
    "resources_scanned": 56,
    "resources_with_hits": 14,
    "files_touched": 28,
    "auto_patched_call_sites": 87,
    "manual_review_call_sites": 45,
    "fxmanifest_injections": 14
  },
  "pattern_distribution": {
    "S1": 62,
    "S2": 19,
    "S3": 6,
    "U1_cash_crypto": 33,
    "U2_setmoney": 4,
    "U3_loop": 2,
    "U4_direct_memory": 0,
    "U5_raw_sql": 0,
    "U6_qb_banking": 0,
    "U7_inventory_cash": 0,
    "U8_func_call_amt": 5,
    "U9_minor_suffix": 1
  },
  "resources": [
    {
      "name": "qb-vehicleshop",
      "files_scanned": 1,
      "auto_patched": 14,
      "manual_review": 6,
      "patterns": { "S1": 12, "S2": 2, "U1_cash_crypto": 6 }
    }
  ]
}
```

### 11.3 `auto_patched.md` per-entry format

```markdown
### qb-vehicleshop/server.lua:179
- Pattern: S1
- Original: `player.Functions.RemoveMoney('bank', paymentAmount, 'financed vehicle')`
- Patched:  `exports.sonar_bank_app:RemoveMoney(source, (paymentAmount) * 100, 'financed vehicle', nil)`
- Source binding: `local player = QBCore.Functions.GetPlayer(source)` line 175
```

### 11.4 `manual_review.md` per-entry format

```markdown
### qb-vehicleshop/server.lua:179 — U1 cash moneytype (Phase B)
- Original: `player.Functions.RemoveMoney('cash', paymentAmount, 'financed vehicle')`
- Reason: cash moneytype is Phase A out-of-scope (qb-inventory paradigm)
- Action: defer to Phase B SONAR cash module
```

---

## 12. Phase A scope vs Phase B deferred

| Item | Phase A (this patcher) | Phase B (future) |
|---|---|---|
| `'bank'` moneytype | ✅ S1+S2+S3 auto + U2/U3/U8/U9 manual | — |
| `'cash'` moneytype | 🔴 U1 deferred | ✅ SONAR cash module + qb-inventory bridge |
| `'crypto'` moneytype | 🔴 U1 deferred | ✅ SONAR crypto module |
| qb-banking exports | 🔴 U6 deferred | ✅ SONAR society accounts API |
| qb-inventory cash items | 🔴 U7 deferred | ✅ qb-inventory bridge listener |
| ox_inventory cash | 🔴 U7 deferred | ✅ ox_inventory hooks |
| qbx_core compatibility | 🔴 not in server | ✅ qbx_core listener pattern |
| ESX framework | 🟡 patterns equivalentes (`xPlayer.addAccountMoney`/`removeAccountMoney`) | ✅ ESX patcher v2 |
| GetBalance read context (S4) | 🔴 deferred | ✅ post-migration cleanup |
| Idempotency key injection | 🔴 nil opts | ✅ opt-in HIGH-VALUE calls |

---

## 13. Test fixture corpus (real samples regression suite)

Construir `migration_patcher/tests/fixtures/` con:

- `qb_shops_main.lua.in` (input snapshot) + `qb_shops_main.lua.expected` (golden output)
- `qb_vehicleshop_server.lua.in` + `.expected`
- `qb_pawnshop_main.lua.in` + `.expected`
- `qb_houses_main.lua.in` + `.expected`
- `qb_vehiclesales_main.lua.in` + `.expected`
- `qb_drugs_cornerselling.lua.in` + `.expected` (cash → U1 only, no auto-patch)

**Test harness** (`pytest` o `unittest`):
- `test_S1_simple_addmoney_bank` — verifica regex match + binding resolution + replacement template
- `test_S2_if_removemoney_chain` — multi-line transform
- `test_S3_offline_path` — citizenid binding
- `test_U1_cash_skipped` — no modification, manual entry generated
- `test_U2_setmoney_manual` — recommendation template verbatim
- `test_U9_minor_suffix_protection` — defense double-shift
- `test_idempotent_rerun` — applying patcher 2x = no-op (marker detection)
- `test_fxmanifest_inject_existing_block` + `test_fxmanifest_inject_no_block` + `test_fxmanifest_inject_already_present`
- `test_summary_json_schema` — output validation

**Coverage criteria:** ≥85% line coverage on patcher modules + 100% pattern coverage S1-S4 + U1-U9.

---

## 14. Validation methodology pre-deployment

### 14.1 Static validation (CI-runnable, no live server)

1. Run patcher `--dry-run` contra `D:\FiveM_Server\Sonar\resources\[qb]\` snapshot (sandbox copy).
2. Verify `summary.json` totals match expected pattern distribution from preliminary scan.
3. Run `lua -p` (luac syntax check) sobre cada `.lua.diff` output applied to `.bak` → must parse 100%.
4. Diff review founder/Backend Lead spot-check 10 random auto-patched call sites.

### 14.2 Live runtime validation (Phase 5.6.x post-patcher)

1. `--apply` patcher contra sandbox copy `D:\FiveM_Server\Sonar_sandbox\`.
2. Boot sandbox txAdmin + verify all qb-* resources start clean (no missing dependency, no Lua errors).
3. Re-execute Phase 5.5 manual probe matrix (22 exports + adversarial S1-S12 from previous prompt 10 paragraph 7) — but now scenarios trigger patched qb-* resources INSTEAD of vanilla path.
4. Diff matrix: `qbcore_balance_after == sonar_balance_after_immediate` MUST hold (no drift, ledger authoritative since qb-* now calls SONAR exports directly).
5. Audit row presence: `invoker_resource = 'qb-vehicleshop'` actual (not heurística), `actor_account_id` real, `event_type = 'bank_credit' or 'bank_debit'` (NOT bank_external_*).

### 14.3 Rollback drill

`migration_patcher --rollback --filter-resource=qb-vehicleshop` → restore .bak → verify resource boots vanilla → confirm idempotent.

---

## 15. Boundary recordatorio

- ✅ Contracts LOCKED v1.0.2 R2 — no touch (patcher es operator-side tool, no toca SSoT)
- ✅ Founder Q4 LOCKED 2026-05-12 "no shim" preservado (patcher emite calls directos, no shim runtime)
- ✅ Phase 3 cleanup intact (zero re-introduction of OnMoneyPreHook / Core Override / MirrorSync echo loop)
- ✅ Doctrine "SONAR authoritative master" reinforced (qb-* migrated → SONAR es THE truth)
- 🔴 NO patcher for cash/crypto/society accounts/inventory cash (Phase B explicit)
- 🔴 NO automated patches for U2-U9 (manual operator review obligatorio con templates emitted)
- 🔴 NO modification de qb-core mainline (solo qb-* downstream resources que LLAMAN qb-core)

---

## 16. Próximas sesiones spawnables

| Session | Lead | Mission | ETA |
|---|---|---|---|
| BANK-BE.PHASE_5.6.A | Product Engineer | Build Python patcher v1 + tests + CLI per esta spec | 4-6h |
| BANK-BE.PHASE_5.6.B | Backend Lead | Run patcher --dry-run + Backend Lead curate manual_review.md → produce operator-actionable migration playbook | 2-3h |
| BANK-BE.PHASE_5.6.C | Founder + Backend Lead | --apply contra sandbox + live validation suite §14.2 | 2-3h |
| BANK-BE.PHASE_5.6.D | Founder | GO MANUAL Phase A complete + tag bank-phase-a + MIGRATION.md final | 30min |

**Total ETA Phase 5.6 reframed:** 8-12h vs 5-6h Path E (descartado por complejidad architectural). Path A automatizado paga el price upfront (build patcher) pero entrega clean artifact reusable + zero runtime burden + zero recursion risk + zero contract amendment.

---

## 17. Sign-off

- PM Cascade (autor spec): ✅ documented per founder directive 2026-05-13 05:00 UTC+02
- Backend Lead: ⏳ pending review + spec ratification before BANK-BE.PHASE_5.6.A spawn
- Product Engineer: ⏳ pending spawn
- Founder yaboula: ⏳ pending spec review + GO BANK-BE.PHASE_5.6.A spawn

