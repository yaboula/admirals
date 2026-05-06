# 📐 SONAR — API Contracts

> **Versión:** 1.2 (post Phase 8+9 namespace migration ejecutada + NOTICE r1 obsoleto removido + prose Admirals→SONAR canonical post S1.10.x). **SSoT vigente** — filosofía + callbacks catalog + exports + NUI bridges + DB access + error codes + rate limits + versioning + security sin cambios foundational (pivot-agnostic). Callback prefix `sonar:*:callback:*` scheduled rename `sonar:*:callback:*` Phase 8 per ADR-013. **C003 `getTransactions` DEFERRED S3** per ADR-015 (D1=B UI-heavy pivot).
> **Tipo:** Technical/Implementation. Contratos formales de **APIs síncronas** (callbacks, exports, NUI bridges, DB access) que el código SONAR expone e invoca.
> **Documento padre:** `technical/01_architecture.md` v1.0 (firmado).
> **Documento hermano:** `technical/02_events_catalog.md` v1.1+ (post-pivot) — cubre eventos fire-and-forget. Este doc cubre request/response.
> **Documento hermano:** `technical/03_db_schema.md` v1.1+ (post-pivot).
> **Documento hermano próximo:** `technical/05_state_machines.md` v1.1+, `technical/06_fivem_standards.md` v1.1+.
> **ADRs relacionados:** ADR-011 (pivot) + ADR-012 (refinement) + **ADR-013 (namespace migration Phase 8+9 scheduled)** + **ADR-015 (Sprint 2 UI-heavy, C003 DEFERRED S3)**.
> **Estado:** firmado.

> **Lectura previa obligatoria:** `agents/00_BOOTSTRAP.md` v1.5, `technical/01_architecture.md` §5 (bus eventos) + §10 (Tablet), `technical/02_events_catalog.md` v1.1+ §1 (filosofía), `00_PRODUCT_BIBLE.md` v1.4, **`planning/02_decision_log.md` ADR-013 + ADR-015**.

---


## 0. Resumen ejecutivo

Este documento define los **contratos API síncronos** (request/response) de SONAR (ex-Admirals). Complementa `events_catalog` (fire-and-forget) con las **APIs bidireccionales**:

1. **Server Callbacks** — cliente pide → servidor responde (validación + datos).
2. **Resource Exports** — funciones expuestas por un resource a otros resources.
3. **NUI Bridges** — Tablet UI (JS) ↔ client Lua (RegisterNUICallback + SendNUIMessage).
4. **Database Access Layer** — wrappers sobre MySQL con conventions SONAR.

> **Filosofía:** **cada contrato API es un acuerdo firmado** entre el código caller y el callee. Romper la forma (params, return shape) es breaking change → bump MAJOR del resource.

Define:

- **Tipos de API** en SONAR.
- **Catálogo completo Server Callbacks** (~40 callbacks críticos).
- **Catálogo Resource Exports** (funciones públicas por resource).
- **Catálogo NUI Bridges** (Tablet UI ↔ client).
- **Database Access Layer** (patterns + wrappers).
- **Error codes** + conventions.
- **Rate limits** + validation rules.
- **Versioning** + breaking changes.
- **Security** considerations.
- **Anti-patterns** APIs.

> **Por qué este doc importa:** sin contratos formales, devs escriben callbacks ad-hoc con shapes diferentes, NUI rompe cada release, exports se renombran sin avisar. Este doc **evita eso**.

---

## 1. Filosofía y convenciones

### 1.1 Principios API

| # | Principio | Significado |
|---|---|---|
| **A1** | **Signature inmutable** | Una vez published, el shape del request/response no cambia. Si cambia, nueva versión (e.g., `sonar:bank:getBalance_v2`). |
| **A2** | **Request/response tipados** | Todo API tiene schema input + output. Validación en ambos extremos. |
| **A3** | **Errores canónicos** | Uso de códigos error SONAR (§7). No strings arbitrarios. |
| **A4** | **Idempotencia donde aplique** | Callbacks de lectura idempotentes. Callbacks de escritura con request_id si retries posibles. |
| **A5** | **Autorización explícita** | Cada callback declara quién puede invocarlo. Validación server-side siempre. |
| **A6** | **Timeout explícito** | Default 5s callbacks, 2s exports. Definido por caller. |
| **A7** | **Rate limits documentados** | Cada callback tiene rate limit. Anti-abuse. |
| **A8** | **Versionado por resource** | Breaking change → bump MAJOR resource + soporte v1/v2 paralelo durante transition. |

### 1.2 Naming convention

```
sonar:<dominio>:<acción>
```

Para callbacks **y** eventos usamos el mismo naming. La diferencia es uso:

- **Evento:** `TriggerServerEvent` / `TriggerClientEvent` (fire-and-forget).
- **Callback:** `lib.callback.await` / `ESX.TriggerServerCallback` (request/response).

> **Importante:** un mismo nombre NO puede ser evento y callback simultáneamente. Choose one.

### 1.3 Framework assumption

Este doc asume:
- **ox_lib** para callbacks (`lib.callback.register` + `lib.callback.await`).
- **MySQL async** via oxmysql o ghmattimysql.
- **NUI** estándar FiveM (React preferred para Tablet).

Si el stack cambia, este doc se actualiza (breaking docs change → ADR + version bump).

### 1.4 Estructura contrato formal

Cada API en este doc usa la siguiente estructura:

````markdown
### [ID]. `sonar:dominio:accion`

**Tipo:** Server Callback / Export / NUI Bridge / DB Wrapper
**Dirección:** client → server (request) + server → client (response)
**Resource emisor:** `sonar_bank` (o similar)
**Schema version:** 1

**Request:**
```ts
{
  field1: string,    // descripción
  field2: number,    // rango
}
```

**Response (success):**
```ts
{
  success: true,
  data: { ... }
}
```

**Response (error):**
```ts
{
  success: false,
  error_code: string,   // Ver §7
  message: string,
}
```

**Authorization:** [Quien puede invocar]
**Rate limit:** [X calls / Y seconds per player]
**Timeout:** [default Xs]
**Idempotency:** [idempotent / requires request_id]
**Side effects:** [lista o "read-only"]
````

---

## 2. Tipos de API en SONAR

### 2.1 Server Callbacks (cliente → servidor → cliente)

**Pattern:** cliente solicita dato o acción → servidor valida + ejecuta → devuelve resultado.

**Uso típico:**
- Tablet app abre → necesita balance actual (callback `getBalance`).
- Player intenta transferir → servidor valida saldo → responde success/error.
- Founder pregunta "¿cuántos employees tengo?" → callback `getEmpresaEmployees`.

**Implementación FiveM + ox_lib:**
```lua
-- Server
lib.callback.register('sonar:bank:getBalance', function(source, iban)
  -- validar auth
  -- query DB
  return balance
end)

-- Client
local balance = lib.callback.await('sonar:bank:getBalance', 500, iban)
```

### 2.2 Resource Exports

**Pattern:** un resource expone funciones públicas callable desde otros resources.

**Uso típico:**
- `sonar_bank` expone `GetPlayerBalance(source)` → cualquier otro resource puede leerlo.
- `sonar_inventory` expone `GiveItem(source, itemId, quality)`.

**Implementación FiveM:**
```lua
-- En sonar_bank server
exports('GetPlayerBalance', function(source)
  return Banking.GetBalance(source)
end)

-- Desde otro resource
local balance = exports.sonar_bank:GetPlayerBalance(source)
```

### 2.3 NUI Bridges (Tablet JS ↔ client Lua)

**Pattern:** Tablet React UI necesita datos del client Lua o enviar acciones.

**Dos direcciones:**

#### 2.3.1 NUI → Client (fetch pattern)
```ts
// En React Tablet
const response = await fetch(`https://sonar_tablet/getBalance`, {
  method: 'POST',
  body: JSON.stringify({}),
});
const { balance } = await response.json();
```

```lua
-- En client Lua
RegisterNUICallback('getBalance', function(data, cb)
  local balance = lib.callback.await('sonar:bank:getBalance', 500)
  cb({ balance = balance })
end)
```

#### 2.3.2 Client → NUI (push pattern)
```lua
-- En client Lua
SendNUIMessage({
  type = 'balance_updated',
  data = { balance = newBalance }
})
```

```ts
// En React Tablet
window.addEventListener('message', (event) => {
  if (event.data.type === 'balance_updated') {
    setBalance(event.data.data.balance);
  }
});
```

### 2.4 Database Access Layer

**Pattern:** wrappers estándar sobre oxmysql que aplican conventions SONAR (audit, retry, error handling).

**Ejemplo:**
```lua
-- Wrapper
local function DB_FetchOne(query, params)
  local result = MySQL.single.await(query, params)
  return result
end

-- Uso
local account = DB_FetchOne(
  'SELECT * FROM sonar_bank_accounts WHERE iban = ?',
  { iban }
)
```

---

## 3. Catálogo Server Callbacks

> **Convención:** todos los callbacks retornan `{ success, data?, error_code?, message? }` uniformemente.

### 3.1 Banking callbacks

#### C001. `sonar:bank:getBalance`

**Tipo:** Server Callback
**Resource:** `sonar_bank`
**Schema version:** 1

**Request:**
```ts
{
  iban?: string,  // opcional, default = IBAN personal del player source
}
```

**Response (success):**
```ts
{
  success: true,
  data: {
    iban: string,
    balance: number,         // en euros
    currency: 'EUR',
    tier: 'personal' | 'empresa',
    last_updated: number,    // unix ms
  }
}
```

**Authorization:** player debe ser owner del IBAN o co-founder si es empresa IBAN. Si no es owner y pide otro IBAN → error `NOT_AUTHORIZED`.
**Rate limit:** 30 calls / 10s per player.
**Timeout:** 2s.
**Idempotency:** idempotent (read-only).
**Side effects:** none.
**DB access:** `sonar_bank_accounts` SELECT.

#### C002. `sonar:bank:transfer`

**Tipo:** Server Callback
**Resource:** `sonar_bank`
**Schema version:** 1

**Request:**
```ts
{
  from_iban: string,          // IBAN origen (debe ser del player)
  to_iban: string,            // IBAN destino
  amount: number,             // > 0, en euros, 2 decimales max
  concept: string,            // 1-120 chars
  request_id: string,         // UUID v4 — idempotency key
}
```

**Response (success):**
```ts
{
  success: true,
  data: {
    transaction_id: string,
    timestamp: number,
    new_balance_from: number,
    fee_retained: number,     // si aplica (escrow, tax)
  }
}
```

**Response (error):**
- `INSUFFICIENT_FUNDS` — saldo < amount.
- `INVALID_IBAN` — destino no existe.
- `SELF_TRANSFER` — from_iban == to_iban.
- `AMOUNT_OUT_OF_RANGE` — amount <= 0 o > 1M €.
- `NOT_AUTHORIZED` — player no es owner from_iban.
- `DUPLICATE_REQUEST` — request_id ya procesado.

**Authorization:** player owner/co-founder del from_iban.
**Rate limit:** 10 transfers / 60s per player.
**Timeout:** 5s.
**Idempotency:** via `request_id` (duplicados devuelven resultado original sin re-ejecutar).
**Side effects:**
- INSERT `sonar_bank_transactions` (2 rows — débito + crédito).
- UPDATE balances both accounts.
- Emite evento `sonar:bank:transfer_completed`.
- Audit log.
**DB access:** TX (transaction) obligatoria.

#### C003. `sonar:bank:getTransactions`

**Request:**
```ts
{
  iban: string,
  limit?: number,           // default 20, max 100
  offset?: number,          // default 0
  filter_type?: 'all' | 'in' | 'out' | 'fees',
  date_from?: number,       // unix ms
  date_to?: number,
}
```

**Response (success):**
```ts
{
  success: true,
  data: {
    transactions: Array<{
      id: string,
      timestamp: number,
      type: 'in' | 'out' | 'fee',
      amount: number,
      concept: string,
      counterparty_iban?: string,
      counterparty_name?: string,
    }>,
    total_count: number,
  }
}
```

**Authorization:** owner/co-founder IBAN.
**Rate limit:** 20 calls / 10s per player.
**Timeout:** 3s.
**Idempotency:** idempotent.

#### C004. `sonar:bank:createEscrow`

**Request:**
```ts
{
  buyer_iban: string,
  seller_iban: string,
  amount: number,
  contract_id: string,       // referencia contrato B2B
  release_condition: 'delivery_confirmed' | 'manual' | 'time_based',
  release_date?: number,     // si time_based
  request_id: string,
}
```

**Response (success):**
```ts
{
  success: true,
  data: {
    escrow_id: string,
    fee_charged: number,     // 0.3-1% según contract tier
    expires_at: number,
  }
}
```

**Authorization:** buyer o vendedor del contrato.
**Rate limit:** 5 / 60s per player.
**Side effects:**
- INSERT `sonar_escrows`.
- DEBIT buyer IBAN → escrow account.
- Emite `sonar:bank:escrow_created`.

#### C005. `sonar:bank:releaseEscrow`

**Request:**
```ts
{
  escrow_id: string,
  release_to: 'seller' | 'buyer' | 'split',
  split_ratio?: number,     // si 'split', 0.0-1.0 (% al seller)
  reason: string,
  request_id: string,
}
```

**Response:**
```ts
{
  success: true,
  data: {
    released_amount_seller: number,
    released_amount_buyer: number,
    timestamp: number,
  }
}
```

**Authorization:** buyer, seller, o admin (disputes).
**Idempotency:** required via request_id.

### 3.2 Empresa callbacks

#### C010. `sonar:empresa:foundEmpresa`

**Request:**
```ts
{
  name: string,              // 3-30 chars, unique
  sector: 'bakery' | 'granja' | 'molino' | 'retail',
  mlo_location_id: string,
  founding_fee_iban: string, // IBAN personal para pagar fee
  co_founders?: Array<{
    citizen_id: string,
    equity_pct: number,      // 0-100, suma <=100 con founder
  }>,
  request_id: string,
}
```

**Response (success):**
```ts
{
  success: true,
  data: {
    empresa_id: string,
    iban: string,
    fee_paid: number,
    equity_ledger: Array<{ citizen_id: string, equity: number }>,
  }
}
```

**Response (error):**
- `NAME_TAKEN`
- `INSUFFICIENT_FUNDS` (founding fee)
- `INVALID_EQUITY_SUM` (co-founders > 100%)
- `MLO_NOT_AVAILABLE`
- `INVALID_SECTOR`

**Authorization:** cualquier player con saldo suficiente + reputation tier ok.
**Rate limit:** 1 / 24h per player.
**Side effects:**
- INSERT `sonar_empresas`.
- INSERT `sonar_bank_accounts` (empresa IBAN).
- DEBIT founding fee.
- Emite `sonar:empresa:founded`.

#### C011. `sonar:empresa:hire`

**Request:**
```ts
{
  empresa_id: string,
  citizen_id: string,        // player a hire
  role: 'employee' | 'specialist' | 'manager',
  salary: number,            // > 0, dentro caps
  contract_duration_days?: number,
  request_id: string,
}
```

**Response (success):**
```ts
{
  success: true,
  data: {
    hire_id: string,
    start_date: number,
  }
}
```

**Authorization:** founder o manager con permission de hire.
**Side effects:** INSERT `sonar_empresa_employees`, notif al hired.

#### C012. `sonar:empresa:fire`

**Request:**
```ts
{
  empresa_id: string,
  citizen_id: string,
  reason: string,
  severance_amount: number,   // min 1 quincena salary per conventions
  request_id: string,
}
```

**Authorization:** founder o manager.
**Side effects:** UPDATE employee status, transfer severance, emit events.

#### C013. `sonar:empresa:listEmployees`

**Request:**
```ts
{
  empresa_id: string,
}
```

**Response:**
```ts
{
  success: true,
  data: {
    employees: Array<{
      citizen_id: string,
      name: string,
      role: string,
      salary: number,
      hired_at: number,
      performance_score?: number,
    }>
  }
}
```

**Authorization:** employees visible solo a founder/co-founder/manager.

#### C014. `sonar:empresa:paySalaries`

**Request:** (trigger auto cada 15 días, también manual)
```ts
{
  empresa_id: string,
  force_pay?: boolean,       // true = pagar aunque cash bajo
  request_id: string,
}
```

**Response:**
```ts
{
  success: true,
  data: {
    paid_count: number,
    total_paid: number,
    tax_retained: number,     // 8%
    failures: Array<{ citizen_id: string, reason: string }>,
  }
}
```

**Authorization:** founder.
**Idempotency:** required.

### 3.3 Item physical callbacks

#### C020. `sonar:item:getInventory`

**Request:**
```ts
{
  owner_type: 'player' | 'empresa' | 'container',
  owner_id: string,
}
```

**Response:**
```ts
{
  success: true,
  data: {
    items: Array<{
      item_id: string,
      type: string,              // 'wheat', 'flour', 'baguette', etc.
      quality: 'A' | 'B' | 'C' | 'D',
      quantity: number,
      lineage_origin?: string,   // empresa_id de origen
      lineage_chain?: Array<{ empresa_id: string, node: string, timestamp: number }>,
      produced_at: number,
      expires_at?: number,
    }>
  }
}
```

**Authorization:** owner.

#### C021. `sonar:item:transferOwnership`

**Request:**
```ts
{
  item_id: string,
  from_owner_type: 'player' | 'empresa',
  from_owner_id: string,
  to_owner_type: 'player' | 'empresa',
  to_owner_id: string,
  quantity: number,
  request_id: string,
}
```

**Side effects:** UPDATE items, append lineage_chain if relevant, emit events.

#### C022. `sonar:item:spawn` (admin only)

**Request:**
```ts
{
  type: string,
  quality: string,
  quantity: number,
  owner_type: string,
  owner_id: string,
  reason: string,
  request_id: string,
}
```

**Authorization:** admin role only.

### 3.4 Mercado / Contract callbacks

#### C030. `sonar:mercado:createListing`

**Request:**
```ts
{
  seller_empresa_id: string,
  item_type: string,
  quality_required: 'A' | 'B' | 'C' | 'D' | 'any',
  quantity: number,
  price_per_unit: number,
  duration_hours: number,
  lineage_required?: boolean,
  request_id: string,
}
```

#### C031. `sonar:mercado:acceptListing`

**Request:**
```ts
{
  listing_id: string,
  buyer_empresa_id: string,
  quantity: number,
  request_id: string,
}
```

**Side effects:** crea contract, escrow, etc.

#### C032. `sonar:contract:sign`

**Request:**
```ts
{
  contract_draft_id: string,
  signing_party_iban: string,
  request_id: string,
}
```

#### C033. `sonar:contract:dispute`

**Request:**
```ts
{
  contract_id: string,
  reason: string,
  evidence?: Array<{ type: string, data: any }>,
  request_id: string,
}
```

### 3.5 Tablet callbacks

#### C040. `sonar:tablet:getAppData`

**Request:**
```ts
{
  app_id: 'bank' | 'workplace' | 'comm' | 'mercado' | 'manager' | ...,
  params?: Record<string, any>,
}
```

**Response:** depends on app_id. Router pattern.

#### C041. `sonar:tablet:sendCommand`

**Request:**
```ts
{
  app_id: string,
  command: string,
  data: Record<string, any>,
  request_id: string,
}
```

### 3.6 Quality / Node-specific callbacks

#### C050. `sonar:bakery:startMix`

**Request:**
```ts
{
  station_id: string,
  ingredients: Array<{ item_id: string, quantity: number }>,
  recipe_id: string,
}
```

**Response:** mix_session_id, expected_output_quality_range.

#### C051. `sonar:bakery:completeBake`

**Request:**
```ts
{
  oven_id: string,
  bake_session_id: string,
  actual_time_ms: number,
  temperature_accurate: boolean,
}
```

**Response:** output item_id, final_quality.

> **Nota:** callbacks de nodos específicos (granja, molino, bakery, retail) están detallados en cada `design/0X_node_*.md` — este catálogo solo lista los signatures.

### 3.7 Tabla resumen callbacks críticos

| ID | Callback | Dominio | Rate limit | Auth level |
|---|---|---|---|---|
| C001 | getBalance | bank | 30/10s | owner |
| C002 | transfer | bank | 10/60s | owner |
| C003 | getTransactions | bank | 20/10s | owner |
| C004 | createEscrow | bank | 5/60s | party |
| C005 | releaseEscrow | bank | 5/60s | party/admin |
| C010 | foundEmpresa | empresa | 1/24h | any+$$ |
| C011 | hire | empresa | 10/h | founder/mgr |
| C012 | fire | empresa | 10/h | founder/mgr |
| C013 | listEmployees | empresa | 30/10s | member |
| C014 | paySalaries | empresa | auto+manual | founder |
| C020 | getInventory | item | 30/10s | owner |
| C021 | transferOwnership | item | 20/60s | owner |
| C022 | spawn (admin) | item | unlim | admin |
| C030 | createListing | mercado | 10/60s | empresa |
| C031 | acceptListing | mercado | 10/60s | empresa |
| C032 | signContract | contract | 10/60s | party |
| C033 | disputeContract | contract | 3/24h | party |
| C040 | getAppData | tablet | 60/10s | player |
| C041 | sendCommand | tablet | 30/10s | player |
| C050 | startMix | bakery | 20/10s | employee |
| C051 | completeBake | bakery | 20/10s | employee |

---

## 4. Catálogo Resource Exports

### 4.1 Filosofía exports

> **Exports son APIs entre resources.** Menos cambiantes que callbacks. Cuidado al exponer: breaking change → actualizar todos los callers.

### 4.2 Resource `sonar_bank`

```lua
-- Server exports
exports('GetPlayerBalance', function(source) -> number | nil end)
exports('GetIbanByCitizenId', function(citizenId) -> string | nil end)
exports('IsAccountOwner', function(source, iban) -> boolean end)
exports('ChargeFee', function(source, amount, concept) -> { success, ... } end)
exports('CreditPlayer', function(source, amount, concept, source_iban) -> boolean end)
exports('LockIban', function(iban, reason) -> boolean end)  -- admin
```

### 4.3 Resource `sonar_empresa`

```lua
exports('GetEmpresaByPlayer', function(source) -> { empresa_id, role, equity_pct } | nil end)
exports('IsEmpresaMember', function(source, empresaId) -> boolean end)
exports('GetEmpresaCash', function(empresaId) -> number end)
exports('HasPermission', function(source, empresaId, permission) -> boolean end)
-- permissions: 'hire', 'fire', 'set_pricing', 'sign_contracts', 'withdraw_dividends'
exports('GetFounderIban', function(empresaId) -> string end)
```

### 4.4 Resource `sonar_inventory`

```lua
exports('GiveItem', function(source, itemType, quality, quantity, lineageOrigin) -> itemId | nil end)
exports('RemoveItem', function(itemId, quantity) -> boolean end)
exports('GetItemQuality', function(itemId) -> string end)
exports('TransferItemOwnership', function(itemId, fromOwnerId, toOwnerId, quantity) -> boolean end)
exports('HasLineage', function(itemId) -> boolean end)
exports('GetLineageChain', function(itemId) -> array end)
```

### 4.5 Resource `sonar_tablet`

```lua
-- Client exports (Tablet UI)
exports('OpenTablet', function() end)
exports('CloseTablet', function() end)
exports('NavigateToApp', function(appId) end)
exports('ShowNotification', function({ title, message, type, duration }) end)
exports('IsTabletOpen', function() -> boolean end)
```

### 4.6 Resource `sonar_core`

```lua
-- Utilities compartidas
exports('GetCitizenId', function(source) -> string end)
exports('FormatEuro', function(amount) -> string end)  -- "1.234,56 €"
exports('GenerateUUID', function() -> string end)
exports('LogAuditEvent', function(category, action, data) end)
exports('GetReputation', function(citizenId) -> { score, tier } end)
```

### 4.7 Resource `sonar_bakery` (node-specific, ejemplo)

```lua
exports('GetBakeryEmpresaByMlo', function(mloId) -> empresaId | nil end)
exports('GetActiveRecipes', function(empresaId) -> array end)
exports('GetQualityOutput', function(ingredients, skillLevel, temperatureAccuracy) -> string end)
```

### 4.8 Tabla exports críticos

| Resource | Export | Usado por |
|---|---|---|
| `sonar_bank` | GetPlayerBalance | Tablet, empresa, mercado |
| `sonar_bank` | ChargeFee | founding, rent, taxes |
| `sonar_empresa` | IsEmpresaMember | ACL checks everywhere |
| `sonar_empresa` | HasPermission | ACL hire/fire/etc. |
| `sonar_inventory` | GiveItem | todos los nodos |
| `sonar_inventory` | TransferItemOwnership | POS, contracts |
| `sonar_tablet` | OpenTablet | keybind handler |
| `sonar_core` | GetCitizenId | everywhere |
| `sonar_core` | LogAuditEvent | compliance, events |

---

## 5. NUI Bridges (Tablet UI ↔ Client)

### 5.1 Filosofía

> **Tablet UI es React NUI.** Comunicación con client Lua via:
> 1. **NUI → Client:** `fetch('https://sonar_tablet/endpoint', { method: 'POST', body })`.
> 2. **Client → NUI:** `SendNUIMessage({ type, data })`.

Cada app Tablet usa este bridge extensivamente.

### 5.2 Endpoints NUI → Client (fetch)

#### NUI1. `POST /open`
**Body:** `{}`
**Response:** `{ success: true }`
**Uso:** Tablet announces it's ready; client responds OK.

#### NUI2. `POST /close`
**Body:** `{}`
**Response:** `{ success: true }`

#### NUI3. `POST /getAppData`
**Body:** `{ app_id: string, params?: object }`
**Response:** app-specific payload.
**Uso:** router que proxy a `sonar:tablet:getAppData` callback server.

#### NUI4. `POST /sendCommand`
**Body:** `{ app_id, command, data, request_id }`
**Response:** success/error.
**Uso:** router que proxy a `sonar:tablet:sendCommand`.

#### NUI5. `POST /playSound`
**Body:** `{ sound_id: string, volume?: number }`
**Response:** `{ success }`
**Uso:** Tablet wants to play a sound (see `art/03_sound_bible.md` SFX catalog).

#### NUI6. `POST /showMapMarker`
**Body:** `{ x, y, z, label, color, duration_ms }`
**Response:** `{ success, marker_id }`
**Uso:** Map app muestra punto en mapa real mundo.

#### NUI7. `POST /focusTab`
**Body:** `{ focus: boolean }`
**Response:** `{ success }`
**Uso:** activar/desactivar cursor mouse sobre Tablet.

#### NUI8. `POST /logTelemetry`
**Body:** `{ event: string, data: object }`
**Response:** `{ success }`
**Uso:** Tablet envía event analytics al server.

### 5.3 Messages Client → NUI (SendNUIMessage)

#### NUI_PUSH1. `type: 'balance_updated'`
**Data:** `{ iban, balance, timestamp }`
**Listener:** Bank app React component.

#### NUI_PUSH2. `type: 'notification'`
**Data:** `{ title, message, type: 'info'|'warn'|'error'|'success', icon?, sound?, duration_ms }`
**Listener:** global notification overlay.

#### NUI_PUSH3. `type: 'dm_received'`
**Data:** `{ from_citizen_id, from_name, message, timestamp, thread_id }`
**Listener:** Comm app.

#### NUI_PUSH4. `type: 'empresa_event'`
**Data:** `{ event: 'hired' | 'fired' | 'salary_paid' | 'dividend_issued', ... }`
**Listener:** Workplace app badge / modal.

#### NUI_PUSH5. `type: 'contract_proposed'`
**Data:** `{ contract_id, from_empresa, items, price, duration }`
**Listener:** Comm or Mercado app.

#### NUI_PUSH6. `type: 'performance_update'`
**Data:** `{ metric, new_value, delta }`
**Listener:** Profile app, achievements.

#### NUI_PUSH7. `type: 'app_switch'`
**Data:** `{ target_app: string }`
**Listener:** Tablet router (forced navigation).

#### NUI_PUSH8. `type: 'sound_effect'`
**Data:** `{ sound_id, volume? }`
**Listener:** sound engine React.

#### NUI_PUSH9. `type: 'animation_trigger'`
**Data:** `{ element_id, animation_name, duration_ms }`
**Listener:** UI animator.

#### NUI_PUSH10. `type: 'close_tablet'`
**Data:** `{}`
**Listener:** root Tablet component.

### 5.4 Patrones avanzados

#### 5.4.1 Debouncing
Tablet UI no debe spam requests. Ejemplo: search input → debounce 300ms.

#### 5.4.2 Optimistic updates
Balance display puede mostrar optimistic value pre-confirmation, revert si fails.

#### 5.4.3 Caching
Data inmutable (achievements, titles) cache localmente. Invalidación via push.

#### 5.4.4 Error boundaries
Cada app Tablet envuelta en React ErrorBoundary. Errors → log + fallback UI.

---

## 6. Database Access Layer

### 6.1 Filosofía

> **Nunca escribir SQL ad-hoc fuera del DB layer.** Toda query pasa por wrapper que aplica:
> - Prepared statements (SQL injection prevention).
> - Retry en deadlocks.
> - Audit logging si relevante.
> - Timeout (default 3s).

### 6.2 Wrappers estándar

```lua
-- En sonar_core
DB = {
  FetchOne = function(query, params) -> row | nil,
  FetchAll = function(query, params) -> array,
  Execute = function(query, params) -> affectedRows,
  Insert = function(query, params) -> insertId,
  Transaction = function(queriesArray) -> boolean,  -- atomic
}
```

### 6.3 Patterns por tabla

#### 6.3.1 `sonar_bank_accounts`

```lua
-- Fetch balance
local acc = DB.FetchOne(
  'SELECT iban, balance, owner_citizen_id FROM sonar_bank_accounts WHERE iban = ?',
  { iban }
)

-- Debit (always inside TX)
DB.Transaction({
  { query = 'UPDATE sonar_bank_accounts SET balance = balance - ? WHERE iban = ? AND balance >= ?',
    params = { amount, from_iban, amount } },
  { query = 'UPDATE sonar_bank_accounts SET balance = balance + ? WHERE iban = ?',
    params = { amount, to_iban } },
  { query = 'INSERT INTO sonar_bank_transactions (...) VALUES (...)',
    params = { ... } },
})
```

#### 6.3.2 `sonar_empresas`

```lua
-- Buscar empresa por player
local empresa = DB.FetchOne([[
  SELECT e.*
  FROM sonar_empresas e
  JOIN sonar_empresa_employees emp ON emp.empresa_id = e.id
  WHERE emp.citizen_id = ? AND emp.active = 1
]], { citizenId })
```

#### 6.3.3 `sonar_items`

```lua
-- Move ownership
DB.Transaction({
  { query = 'UPDATE sonar_items SET owner_type = ?, owner_id = ? WHERE id = ?',
    params = { newType, newId, itemId } },
  { query = 'INSERT INTO sonar_item_lineage (item_id, owner_type, owner_id, timestamp) VALUES (?, ?, ?, NOW())',
    params = { itemId, newType, newId } },
})
```

### 6.4 Audit logging

Toda operación financiera o con ownership change **debe** audit log:

```lua
AuditLog({
  category = 'bank_transfer',
  action = 'debit',
  actor_citizen_id = source_citizen_id,
  target_iban = to_iban,
  amount = amount,
  metadata = { concept, request_id },
})
```

→ tabla `sonar_audit_log` (ver `technical/03_db_schema.md`).

### 6.5 Connection pooling

- Max connections: **10** server-wide (configurable).
- Timeout default: **3s**.
- Slow query log: > **500ms**.

### 6.6 Migrations

- Schema changes **siempre** via migration files numbered.
- Applied during server start si version DB < version code.
- Rollback plan per migration.

---

## 7. Error codes canónicos

### 7.1 Estructura código error

**Formato:** `[CATEGORY]_[SPECIFIC]` snake_case upper.

### 7.2 Catálogo

#### Auth / permissions
- `NOT_AUTHENTICATED`
- `NOT_AUTHORIZED`
- `PERMISSION_DENIED`
- `ROLE_INSUFFICIENT`

#### Validation
- `INVALID_INPUT`
- `MISSING_FIELD`
- `FIELD_OUT_OF_RANGE`
- `INVALID_FORMAT`
- `DUPLICATE_REQUEST` (idempotency)
- `NAME_TAKEN`
- `INVALID_IBAN`
- `INVALID_CITIZEN_ID`
- `INVALID_ITEM_ID`

#### Business logic
- `INSUFFICIENT_FUNDS`
- `INSUFFICIENT_ITEMS`
- `SELF_TRANSFER`
- `AMOUNT_OUT_OF_RANGE`
- `RATE_LIMIT_EXCEEDED`
- `QUOTA_EXCEEDED`
- `ESCROW_NOT_FOUND`
- `CONTRACT_NOT_SIGNABLE`
- `EMPRESA_NOT_FOUND`
- `EMPLOYEE_NOT_FOUND`
- `MLO_UNAVAILABLE`
- `ITEM_EXPIRED`
- `LINEAGE_INCOMPLETE`
- `QUALITY_MISMATCH`

#### System
- `INTERNAL_ERROR`
- `DB_ERROR`
- `TIMEOUT`
- `SERVICE_UNAVAILABLE`
- `THROTTLED`

### 7.3 Response format error

```ts
{
  success: false,
  error_code: 'INSUFFICIENT_FUNDS',
  message: 'Saldo insuficiente. Saldo actual: 150€, requerido: 500€.',
  details?: {
    current_balance: 150,
    required: 500,
    missing: 350,
  }
}
```

### 7.4 Client-side error handling

Cada código error tiene mensaje UI localizado en `/locale/es/errors.json`:

```json
{
  "INSUFFICIENT_FUNDS": "Saldo insuficiente",
  "NOT_AUTHORIZED": "No tienes permiso para esta operación",
  "RATE_LIMIT_EXCEEDED": "Demasiadas peticiones. Espera un momento.",
  ...
}
```

---

## 8. Rate limits y validation

### 8.1 Rate limits globales

| Callback category | Limit |
|---|---|
| Read (getBalance, getInventory) | 30 / 10s per player |
| Write (transfer, hire) | 10 / 60s per player |
| Heavy (foundEmpresa) | 1 / 24h per player |
| Disputes | 3 / 24h per player |
| Tablet UI queries | 60 / 10s per player |

### 8.2 Implementación rate limit

```lua
-- En sonar_core
RateLimiter = {
  Check = function(source, bucketKey, max, windowSec) -> boolean,
}

-- Uso callback
lib.callback.register('sonar:bank:transfer', function(source, params)
  if not RateLimiter.Check(source, 'bank:transfer', 10, 60) then
    return { success = false, error_code = 'RATE_LIMIT_EXCEEDED' }
  end
  -- ...
end)
```

### 8.3 Input validation

> **Server valida SIEMPRE.** Client validation es UX, no security.

Validations típicas:
- **IBAN format:** regex `^ES[0-9]{2} ADML [A-Z0-9]{8}$`.
- **Amount:** number > 0, <= 1M, max 2 decimales.
- **String lengths:** declared per callback.
- **Enum values:** against allowed list.
- **Citizen ID:** existe en players table.
- **IDs existencia:** todos los referenced IDs verificados.

### 8.4 Anti-cheat validations

- **Physical position:** algunos callbacks validan que player esté cerca del MLO relevante (e.g., `completeBake` requiere distance < 3m del horno).
- **State consistency:** e.g., `startMix` requires que mixer status = 'idle'.
- **Timing sanity:** completeBake requires actual_time >= min_bake_time per recipe.

---

## 9. Versioning y breaking changes

### 9.1 Cuándo es breaking

- Cambiar shape request (remover field required).
- Cambiar shape response (remover field presente en v1).
- Cambiar semántica (e.g., field "balance" ahora en centavos en vez de euros).
- Cambiar authorization (antes público, ahora restringido).

### 9.2 Cuándo NO es breaking

- Añadir field opcional request.
- Añadir field response (clientes ignoran fields desconocidos).
- Relajar validation.
- Mejorar performance sin cambiar contrato.

### 9.3 Protocol breaking change

1. Decide breaking change necesario.
2. Crea nuevo callback `sonar:dominio:accion_v2`.
3. Mantén `sonar:dominio:accion` (v1) activo.
4. Update callers 1 por 1 a v2.
5. Cuando todos los callers migrados: deprecate v1 (retorna error `VERSION_DEPRECATED`).
6. Tras 1 Oleada: remove v1.

### 9.4 Deprecation marker

```lua
lib.callback.register('sonar:bank:transfer', function(source, params)
  -- LEGACY v1 — use sonar:bank:transfer_v2
  LogDeprecation('sonar:bank:transfer', source)
  -- ... still works
end)
```

---

## 10. Security considerations

### 10.1 Threat model

> Ver `technical/06_fivem_standards.md` para detalle completo.

Top threats APIs:
1. **SQL injection** — mitigated via prepared statements (DB layer).
2. **Rate abuse** — mitigated via RateLimiter.
3. **Authorization bypass** — mitigated via per-callback auth checks.
4. **Replay attacks** — mitigated via `request_id` idempotency.
5. **Client tampering** — mitigated via server-side validation.

### 10.2 Secrets management

- ❌ **NUNCA** hardcodear credentials en Lua/JS.
- ✅ DB credentials via `server.cfg` convars.
- ✅ API keys externos (si los hay) via env vars.

### 10.3 Audit logging obligatorio

Categorías que **siempre** auditan:
- Money movements (transfers, fees, escrows).
- Ownership changes (items, empresas).
- Permission changes (hire, fire, promote).
- Admin actions (spawn, force_unlock).
- Dispute resolutions.

### 10.4 Admin commands

- Separados en namespace `sonar:admin:*`.
- Restricted a role admin verificado.
- Todo admin command → audit log con reason mandatory.

---

## 11. Anti-patterns

### 11.1 API design

- ❌ **Callbacks silenciosos** — fail sin retornar error claro.
- ❌ **Shape inconsistente** — `{ balance }` vs `{ data: { balance } }` en diferentes callbacks.
- ❌ **Too granular** — 20 callbacks donde 1 con params router basta.
- ❌ **Too coarse** — 1 mega-callback con 30 possible actions.
- ❌ **Missing idempotency** — writes sin request_id.
- ❌ **Server trust client** — no validar porque "el cliente ya validó".

### 11.2 NUI

- ❌ **Polling 60fps** — usar push patterns.
- ❌ **Bloatante messages** — payloads grandes innecesarios.
- ❌ **No error handling** — fetch sin try/catch.
- ❌ **Missing unmount cleanup** — event listeners leak.

### 11.3 DB

- ❌ **SQL ad-hoc fuera del wrapper.**
- ❌ **No transactions** for multi-row writes.
- ❌ **SELECT \*** en prod (bandwidth).
- ❌ **No indexes** en columnas filtradas.
- ❌ **Long-running queries** bloqueando.

### 11.4 Security

- ❌ **Validar solo client-side.**
- ❌ **Log sensitive data** (password, tokens) en audit.
- ❌ **Trust ` source`** sin verificar existencia player.
- ❌ **Open exports críticos** sin auth.

---

## 12. Testing APIs

### 12.1 Manual testing protocol

> Ver `qa/01_testing_protocol.md` para detalle.

Cada callback:
1. **Happy path:** valid input → success.
2. **Validation:** invalid input → specific error.
3. **Auth:** unauthorized user → NOT_AUTHORIZED.
4. **Rate limit:** exceed → RATE_LIMIT_EXCEEDED.
5. **Idempotency:** duplicate request_id → same result.
6. **Concurrency:** 2 simultaneous requests → atomic.

### 12.2 Test commands dev

```
/test_callback sonar:bank:getBalance {"iban":"ES00 ADML ABCD1234"}
/test_callback sonar:bank:transfer {"from_iban":"...","to_iban":"...","amount":100,"concept":"test"}
```

### 12.3 Stress testing

- 10 players concurrentes transfer → integrity ledger.
- 100 getBalance/sec → performance.

---

## 13. Roadmap + estado

### 13.1 Roadmap API coverage

#### Oleada 1 (MVP)
- ✅ Banking callbacks (C001-C005).
- ✅ Empresa callbacks (C010-C014).
- ✅ Item callbacks (C020-C022).
- ✅ Tablet callbacks (C040-C041).
- ✅ Bakery callbacks (C050-C051).
- 🔴 Mercado callbacks (C030-C033) — oleada 2.

#### Oleada 2
- 🔜 Mercado + contracts completos.
- 🔜 Comm callbacks (DMs, channels).
- 🔜 Review / reputation callbacks.
- 🔜 Additional node callbacks (granja, molino, retail, logistics).

#### Oleada 3+
- 🔜 Federation APIs cross-server.
- 🔜 Advanced analytics APIs.

### 13.2 Estado del documento

- **Versión:** 1.0 (firmable — completo, 13 secciones, ~40 callbacks + exports + NUI bridges).
- **Próxima revisión:** primer sprint Oleada 1 con code real validará contratos.
- **Documento padre:** `technical/01_architecture.md`.
- **Documento hermano:** `technical/02_events_catalog.md`.

### 13.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Primera redacción. 13 secciones: filosofía, tipos API, server callbacks (40+), resource exports, NUI bridges, DB access, error codes, rate limits, versioning, security, anti-patterns, testing. **Firmable.** |
| 1.2 | 2026-05-04 | Founder + Cascade (S1.10.x) | **v1.2 — Phase 8+9 namespace migration ejecutada + NOTICE r1 obsoleto removido + prose Admirals→SONAR canonical.** S1.10 Phase 8+9 ejecutada (`admirals_*` → `sonar_*` code + DB tables + events + exports + server.cfg.example + 004 seed alias). S1.10.2 docs auto-rewrite Phase 1 (1075 identifiers code blocks). S1.10.3 docs Phase 2 surgical (NOTICE r1 block removed; prose "Admirals" → "SONAR" en §1-§N preservando refs históricos en este changelog; "Versión" + "FIN" bumped). Smoke harness inline admin commands cumulative S0+S1.1+S1.2+S1.3 = 10/10 PASS. **NO touched:** architecture + interfaces + contratos + tier + anti-patterns (pivot-agnostic). |

---

## 14. TL;DR

### Tipos API

1. **Server Callbacks** — `lib.callback` request/response (~40 catalogados).
2. **Resource Exports** — funciones públicas entre resources.
3. **NUI Bridges** — Tablet UI ↔ client (fetch + SendNUIMessage).
4. **DB Access** — wrappers estándar sobre oxmysql.

### Callbacks críticos

- **Banking:** getBalance, transfer, getTransactions, createEscrow, releaseEscrow.
- **Empresa:** foundEmpresa, hire, fire, paySalaries.
- **Item:** getInventory, transferOwnership.
- **Tablet:** getAppData (router), sendCommand (router).
- **Node-specific:** bakery startMix, completeBake (y similares futuros).

### Reglas absolutas

- 🔒 **Server valida siempre.**
- 🔑 **Idempotency via request_id** en writes.
- 📊 **Audit log** money + ownership changes.
- ⏱ **Rate limits** por category.
- 📝 **Prepared statements** (no SQL inyectable).
- 🚫 **Breaking change** → nuevo callback `_v2`, mantén v1.
- 📋 **Errors canónicos** (catálogo §7), no strings libres.

### Anti-patterns

- ❌ Shape inconsistente responses.
- ❌ Trust client validation.
- ❌ Silent failures.
- ❌ Missing idempotency writes.
- ❌ SQL ad-hoc fuera del DB wrapper.
- ❌ Polling 60fps NUI.

---

## Resumen ejecutivo (cierre)

Los **API Contracts SONAR (ex-Admirals)** son el puente formal entre código. Cubren:

- **40+ server callbacks** documented signatures (request/response/errors/auth/rate).
- **5 resource exports catalogs** (bank, empresa, inventory, tablet, core + node-specific).
- **NUI bridges completos:** 8 endpoints NUI→Client + 10 push messages Client→NUI.
- **DB access layer** con wrappers estándar, transactions, audit.
- **Error codes canónicos** (~30 codes categorizados).
- **Rate limits** por category + implementación RateLimiter.
- **Versioning protocol** (breaking vs non-breaking + deprecation flow).
- **Security considerations** (top 5 threats mitigations).
- **Testing protocol** manual + stress.

> Cada contrato es **firmado** — callers pueden confiar que el shape no cambia sin version bump. Sin esto, integración backend↔NUI↔code es caos. Con esto, dev puede trabajar en paralelo sin romperse mutuamente.

---

*"Un contrato API firmado vale más que cien reuniones de sincronización."*

---

## 15. Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026 (Oleada 0 firma) | Founder + Cascade | Primera redacción completa 14 secciones, 40+ callbacks catalogados, 5 resource exports catalogs (bank/empresa/inventory/tablet/core + node-specific), NUI bridges 8 endpoints + 10 push messages, DB access layer wrappers + transactions + audit, error codes canonical ~30 categorized, rate limits per category, versioning protocol breaking vs non-breaking + deprecation flow, security top 5 threats mitigations, testing protocol manual + stress. **Firmable Oleada 0.** |
| 1.1 | 2026-05-04 | Founder + Cascade (S1.9 EXTENDED) | **Light refresh post-pivot SONAR** (ADR-011 + ADR-012 + ADR-013 + ADR-015). Title rebrand Admirals → SONAR. NOTICE r1 top-level (~80 líneas) establece: naming canonical callbacks/exports/NUI bridges (mapping 1:1 5 callbacks shipped S1 + 35+ planned) + **C003 `getTransactions` DEFERRED S3 per ADR-015 (D1=B UI-heavy pivot)** + request/response schemas + error codes + rate limits + auth matrix INVARIANTES pre/post Phase-8 + voz neutral ADR-012 §D3 en error message strings + migration execution schedule Phase 8 (next session) + reading guide §1-§14 legacy vs canonical. §0 resumen + §cierre rebrand + hermanos refs bumped v1.1+ + ADRs 011/012/013/015 linked. **NO touched:** §1-§14 filosofía + tipos API + 40+ callbacks catalog + exports catalog + NUI bridges + DB access + error codes + rate limits + versioning + security + testing (pivot-agnostic foundational API design). Callback prefix `sonar:*:callback:*` + exports `sonar_*` + NUI prefixes preservados legacy inline hasta Phase 8 execution per ADR-011 §5.5.8 excepciones. Próxima v1.2 post-Phase-8: 40+ callbacks + exports rename 1:1 inline body + C003 DEFERRED S3 tag reinforced. |

---

---

## §X.NEW — Bank Phase A Extension (LOCKED 2026-05-06 BANK-BE.LOCK.R1)

> **Estado:** v1.3.1 LOCKED — extensión Bank-specific Phase A R1 amendment hardening. Sin tocar §1-§N foundational pivot-agnostic.
> **Owner:** Backend Lead (Cascade activated, sessions BANK-BE.0 / BANK-BE.1 / BANK-BE.LOCK / BANK-BE.AMEND.1 / BANK-BE.LOCK.R1).
> **Scope:** SONAR Bank financial-grade — **40+1 callbacks C001-C040 + C001b** fully specified post R1 hardening (H001 auth helpers canonical lib `auth.require_*` + AP-AUTH-1 prohibido + H006 audit shape completa C-SEC-01 + M002 PRNG entropy spec + M003 audit query dual rate-limit recursive guard + M006 ATM HMAC convar mandatory + M004 cross-cutting CP1-A → CP1-B 14 callbacks side effects refactor + C001b NEW `balance:snapshot` fallback).

### Canonical reference

→ **`@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md`** (v1.0.1 R1 LOCKED, 40+1 callbacks)

### Por qué documento dedicado en sub-directorio

- **Aislamiento dominio (M4 mandato founder):** APIs Bank son financial-grade — auth server-side estricta, idempotency keys persistentes en DB con result payloads cached, rate-limit token bucket per player+tier, audit ledger triggered en cada side effect.
- **Pivot-agnostic preservado:** §1-§N de este SSoT padre son foundational (philosophy + callback catalog SONAR Core + exports + NUI bridges + DB access + error codes baseline + versioning + security generic) compartidos por TODOS los recursos SONAR. Bank Phase A los **extiende** sin reemplazarlos.
- **Auditability:** Security Lead H2 audit scope incluye crítico ACE matrix §2 + error codes §3 + idempotency §5 + audit ledger ENUM §6 del documento dedicado.

### Cross-references

- **Sibling Bank contracts:** `@docs/technical/bank_phase_a/README.md` (índice 5 contratos LOCKED).
- **Pivot SSoTs hermanos extendidos:** `@docs/technical/02_events_catalog.md` v1.3, `@docs/technical/05_state_machines.md` v1.3, `@docs/technical/07_bridges_compatibility.md` v1.3.
- **DB Schema upstream:** `@docs/technical/03_db_schema.md` v2.0 LOCKED PROVISIONAL — tablas idempotency_keys + audit ledger + accounts + transactions consumed por callbacks Bank.
- **ADR anchor:** `@docs/planning/02_decision_log_part2.md` ADR-018.
- **Handoffs:** H1 DB→Backend received; H2 Backend→Security emitted (`@docs/agents/teams/handoffs/h2_backend_to_security/`).

### Sign-off Bank Phase A extension

| Rol | Status | Fecha |
|---|---|---|
| **Founder yaboula** | ✅ APPROVED (BANK-BE.LOCK + BANK-BE.LOCK.R1 green-light) | 2026-05-06 |
| **Backend Lead (Cascade)** | ✅ self-attested (owner) v1.0.1 R1 | 2026-05-06 |
| **Security Lead** | ✅ ACCEPTED-FINAL (BANK-SEC.1 re-audit PASS veredicto + `08_audit_hooks.md` v0.2) | 2026-05-06 |
| **Frontend Lead** | ⏳ PENDING H3 future | — |

**Amendments post-LOCKED** requieren formal Round 1/2/3 protocol.

---

## Versioning v1.3 entry

| 1.3 | 2026-05-06 | Founder + Backend Lead (BANK-BE.LOCK) | **v1.3 LOCKED — Bank Phase A extension §X.NEW.** Append pointer hacia `docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` v1.0 LOCKED (40 callbacks C001-C040 fully specified). Sign-off founder + Backend Lead. **NO touched** §1-§N foundational pivot-agnostic. |
| 1.3.1 | 2026-05-06 | Founder + Backend Lead + Security Lead (BANK-BE.LOCK.R1) | **v1.3.1 LOCKED — Bank Phase A R1 amendment hardening pointer.** Append updated pointer C-BE-02 v1.0.1 R1 LOCKED: H001 (auth helpers canonical lib + AP-AUTH-1 prohibido + 9 callsites refactored) + H006 (C038 audit shape complete C-SEC-01 §1.2 mandatory `previous_flag_snapshot`) + M002 (PRNG entropy spec §5.6) + M003 (C035 dual rate-limit recursive guard §9.35.5.1) + M006 (C031 ATM HMAC convar mandatory §9.31.7) + M004 cross-cutting (C001b NEW `balance:snapshot` callback fallback + 14 callbacks side effects CP1-A → CP1-B refactor `publish_balance_update()`). Sign-off founder + Backend Lead + Security Lead PASS (BANK-SEC.1 re-audit veredicto). **NO touched** §1-§N foundational pivot-agnostic. |

---

**FIN DEL DOCUMENTO `technical/04_api_contracts.md` v1.3.1 LOCKED (Bank Phase A R1 extension)**
