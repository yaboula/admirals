# 🔌 Admirals — Bridges & Compatibility Layer

> **Versión:** 1.0 (firmado — completo, 18 secciones).
> **Tipo:** Technical/Implementation. **Último doc Oleada 0 antes de Sprint 1.** Define el **Bridges Layer** — capa de abstracción que permite a Admirals funcionar sobre múltiples frameworks FiveM (QBox, QBCore, ESX) y scripts custom (lb-phone, qs-inventory, Renewed-Banking, etc.) sin acoplarse a ninguno.
> **Documento padre:** `agents/00_BOOTSTRAP.md` v1.1 (firmado).
> **Documento hermano SSoT:** `technical/01_architecture.md` (Bridges layer mencionado §Layers), `technical/04_api_contracts.md` (todo API Admirals que toca dinero/items/fono pasa por aquí).
> **Documento hermano SSoT:** `technical/06_fivem_standards.md` (performance budgets y security aplican también a bridges).
> **ADR relacionado:** ADR-007 (pendiente firma en `planning/02_decision_log.md` tras cerrar este doc).
> **Estado:** firmado.

> **Lectura previa obligatoria:** `technical/01_architecture.md`, `technical/04_api_contracts.md`, `technical/06_fivem_standards.md`, `planning/01_roadmap.md` v1.1 (pivot MVP Granja).

---

## 0. Resumen ejecutivo

El **Bridges Layer** es la capa que desacopla Admirals de cualquier framework o script externo específico. Sin ella, Admirals solo funcionaría en QBox (o en QBCore, o en ESX — pero **no los tres**). Con ella, Admirals es un producto premium vendible a **cualquier servidor FiveM serio**, sin importar qué banco/inventario/teléfono/target usen.

> **Regla de oro:** ningún archivo de Admirals, nunca, jamás, llama directamente a una API externa (`exports['qb-banking']:AddMoney(...)`). **Siempre** pasa por `Bridges.Bank.AddMoney(...)`.

Define:

- **Filosofía bridges** (7 principios).
- **Arquitectura de la capa** — adapter pattern + dependency inversion + registry.
- **Tier system de soporte** — T1 oficial (garantizado), T2 compat (best-effort), T3 customer SDK.
- **6 módulos bridge:** `Bank`, `Inventory`, `Phone`, `Identity`, `Target`, `Notify`.
- **Interfaces exactas** de cada bridge (método, tipos, contrato, errores, idempotencia).
- **Adapters concretos** para frameworks/scripts populares.
- **Auto-detection** de scripts instalados al boot + config overrides convars.
- **Native fallbacks** — si nada detectado, Admirals provee mínimo funcional nativo.
- **Custom Adapter SDK** — customers escriben su adapter siguiendo template + test harness.
- **Lifecycle hooks** bidireccionales (Admirals↔external).
- **Testing matrix** — qué combos CI-tested, manual-tested, community-tested.
- **Versioning policy** — SEMVER bridges + deprecation 1 minor.
- **Anti-patterns** — errores que evitan el colapso de la abstracción.

> **Por qué este doc importa:** sin él, todo el código Oleada 1+ se acopla a 1 framework. Refactorizar 300 callsites hacia bridges después es **semanas de trabajo perdido**. Con él, desde la línea 1 de Sprint 0, el código es framework-agnostic y **el producto es vendible a cualquier customer FiveM premium**.

---

## 1. Filosofía Bridges

### 1.1 Los 7 principios

| # | Principio | Significado |
|---|---|---|
| **B1** | **Nunca llamar external directo** | 0 ocurrencias de `exports['qb-*']:...` o `ESX.GetPlayerFromId()` fuera de `bridges/adapters/*.lua`. |
| **B2** | **Interface estable, implementación variable** | La firma de `Bridges.Bank.AddMoney()` no cambia. Los adapters sí. |
| **B3** | **Detection + fallback, nunca crash** | Si el script esperado no está, Admirals usa native fallback + log warning, **no crashea**. |
| **B4** | **Single-responsibility bridges** | Cada bridge hace UNA cosa (Bank = dinero, Inventory = items). No "UtilityBridge" god-object. |
| **B5** | **Async-by-default, sync opt-in** | Todas las operaciones devuelven promise/callback. El caller decide sync si necesita. |
| **B6** | **Idempotent siempre que sea posible** | `AddMoney(citizenId, 100, tx_id)` con mismo `tx_id` es no-op 2ª vez. |
| **B7** | **Logged at boundary** | Cada call al bridge se loguea con adapter usado + latencia + result. Auditable. |

### 1.2 Anti-principios

- ❌ **Abstracción por abstracción.** Un bridge con 30 métodos "por si acaso" es basura. Solo los que Admirals realmente usa.
- ❌ **Bridge que leak types externos.** Si `QBCore.Player` aparece en la firma, la abstracción falló.
- ❌ **Feature detection en runtime por call.** Se detecta al boot, se cachea, se usa. No `if QBCore then ... else if ESX then ...` en cada llamada.
- ❌ **Bridge que hace más que pasar.** Si tiene lógica de negocio, esa lógica pertenece a `admirals_core`, no al bridge.

---

## 2. Arquitectura de la capa

### 2.1 Stack

```
┌─────────────────────────────────────────────────┐
│  admirals_core / nodes / tablet                │
│  (callbacks, FSMs, business logic)             │
│                                                 │
│  Bridges.Bank.AddMoney(citizenId, 100, reason) │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│  Bridges Layer (admirals_bridges resource)     │
│                                                 │
│  - Registry: adapters registrados              │
│  - Dispatcher: routes call al adapter activo   │
│  - Logger: audit boundary                      │
│  - Fallback: native si nada detectado          │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│  Adapter activo (p.ej. adapter_qbox.lua)       │
│                                                 │
│  exports['qbx_core']:AddMoney(src, 'bank', ...)│
└─────────────────────────────────────────────────┘
```

### 2.2 Resource `admirals_bridges`

Ubicación: `resources/admirals_bridges/`

```
admirals_bridges/
  fxmanifest.lua
  config.lua              -- overrides customer-editable
  server/
    init.lua              -- boot: detect + register adapters
    registry.lua          -- Bridges.RegisterAdapter, Bridges.GetAdapter
    dispatcher.lua        -- Bridges.<Module>.<method> routing
    logger.lua            -- audit boundary
  bridges/
    bank.lua              -- Bridges.Bank interface + dispatcher
    inventory.lua         -- Bridges.Inventory interface + dispatcher
    phone.lua             -- Bridges.Phone interface + dispatcher
    identity.lua          -- Bridges.Identity interface + dispatcher
    target.lua            -- Bridges.Target interface + dispatcher
    notify.lua            -- Bridges.Notify interface + dispatcher
  adapters/
    bank/
      qbox.lua
      qbcore.lua
      esx.lua
      renewed_banking.lua
      okok_banking.lua
      native.lua          -- fallback
    inventory/
      ox_inventory.lua
      qs_inventory.lua
      qb_inventory.lua
      codem_inventory.lua
      native.lua
    phone/
      lb_phone.lua
      qs_smartphone.lua
      yseries.lua
      qb_phone.lua
      npwd.lua
      native.lua          -- usa el propio Tablet Admirals
    identity/
      qbox.lua
      qbcore.lua
      esx.lua
      native.lua
    target/
      ox_target.lua
      qb_target.lua
      native.lua          -- distance-check simple
    notify/
      ox_lib.lua
      qb.lua
      esx.lua
      native.lua          -- chat print simple
  sdk/
    README.md             -- guía custom adapter
    template_bank.lua
    template_inventory.lua
    template_phone.lua
    test_harness.lua
```

### 2.3 Load order FiveM

```lua
-- fxmanifest.lua de admirals_bridges
server_scripts {
  'server/logger.lua',
  'server/registry.lua',
  'bridges/bank.lua',
  'bridges/inventory.lua',
  'bridges/phone.lua',
  'bridges/identity.lua',
  'bridges/target.lua',
  'bridges/notify.lua',
  'adapters/**/*.lua',      -- registran al cargar
  'server/init.lua',         -- detect + activate
}
```

`admirals_bridges` debe arrancar **antes** que `admirals_core` (dependency en `fxmanifest.lua` de core: `dependency 'admirals_bridges'`).

### 2.4 Uso en resources downstream

```lua
-- admirals_core/server/bank/transfer.lua
local function transferToEmpresa(citizenId, empresaId, amount, reason)
  -- ❌ MAL: exports['qb-banking']:AddMoney(src, 'bank', -amount)
  -- ✅ BIEN:
  local ok, err = Bridges.Bank.RemoveMoney(citizenId, amount, reason)
  if not ok then return false, err end
  Bridges.Bank.AddMoney(empresaAccountId, amount, reason)
  ...
end
```

---

## 3. Tier system de soporte

### 3.1 Tier 1 — Oficialmente soportado (garantizado)

> **Admirals garantiza que funciona + smoke tested cada release.**

| Módulo | Script | Razón |
|---|---|---|
| Framework | **QBox Framework** | Modern fork activo, performance alto, exports TS-friendly, community premium |
| Inventory | **ox_inventory** | De-facto estándar premium, metadata robusta, state bags, calidad código |
| Target | **ox_target** | Modern, performant, API estable |
| Lib | **ox_lib** | Asumido (dialog, callbacks, util) |
| Phone | **lb-phone** | Leader premium phone, API estable, widely adopted |
| Notify | **ox_lib.notify** | Default Admirals |
| Bank | **qbx_management + qbx_core** | Bank nativo QBox |

**Stack recomendado "admirals-ready":** QBox + ox_* + lb-phone. Customer con este stack tiene 100% funcionalidad out-of-the-box.

### 3.2 Tier 2 — Compat layer provisto (best-effort)

> **Admirals provee adapter + smoke tested menos frecuentemente. Puede tener limitaciones documentadas.**

| Módulo | Scripts |
|---|---|
| Framework | QBCore (vanilla), ESX (legacy) |
| Inventory | qb-inventory, qs-inventory, codem-inventory |
| Target | qb-target, qtarget |
| Phone | qs-smartphone, yseries, qb-phone, npwd, gks-phone |
| Bank | qb-banking, Renewed-Banking, okok-banking, esx_addonaccount |
| Notify | qb-core notify, esx notify |

**Limitaciones típicas T2:**
- Metadata items menos rica → quality A/B/C/D serializada en description si inventory no soporta metadata nativa.
- Phone sin SDK → Admirals envía via chat si no hay API phone.
- Bank sin history API → Admirals mantiene su propio ledger parallel.

### 3.3 Tier 3 — Customer SDK (DIY)

> **Customer tiene script no soportado → escribe su propio adapter siguiendo SDK.**

Ver §12 "Custom Adapter SDK".

Admirals provee:
- Template files (`sdk/template_*.lua`).
- Spec interface exacta.
- Test harness automático (`scripts/test_adapter.lua`).
- Discord channel `#admirals-adapters` para community support.

### 3.4 Política upgrade de tier

| From → To | Criterios |
|---|---|
| T3 → T2 | 5+ customers usándolo en prod + adapter auditado por maintainers |
| T2 → T1 | Adoption >30% customers + CI automated + maintainer officially adopts |

---

## 4. `Bridges.Bank`

### 4.1 Responsabilidad

Todas las operaciones de dinero en accounts **distintos del ledger Admirals interno**. Admirals tiene su propio ledger (`admirals_bank_accounts` + `admirals_bank_movements`). Bridges.Bank se usa cuando el customer quiere que Admirals **mirror/sync** con el banco del framework externo (p.ej. el "cash/bank" de QBox).

**Dos modos operacionales:**

#### Modo A — Standalone (recomendado)
Admirals usa **solo** su ledger propio. IBANs `ES00 ADML XXXX` son la SSoT. Bridges.Bank es **no-op** (adapter `native`). El dinero en el cash/bank del framework externo es separado — no se toca.

**Ventaja:** cero conflictos, ledger Admirals puro, perfect economic integrity.
**Desventaja:** player tiene "dos carteras" (la del framework + la de Admirals). Requiere UX onboarding clear.

#### Modo B — Synced (avanzado, opt-in)
Admirals usa su ledger como SSoT pero **sincroniza** cambios con el bank del framework (bidirectionally). Cuando Admirals paga salario, el balance del framework bank sube.

**Ventaja:** UX unificado (player ve mismo saldo en Tablet Admirals y en phone del framework).
**Desventaja:** complejidad sync, race conditions posibles, requiere cron de reconciliación.

**Default:** Modo A. Modo B opt-in via `convar admirals_bridge_bank_mode = synced`.

### 4.2 Interface

```lua
--- Bridges.Bank.GetBalance(identifier, account_type)
--- @param identifier string citizenId (player) o IBAN (empresa/escrow)
--- @param account_type 'cash'|'bank' (solo Modo B)
--- @return number|nil balance, string|nil error
Bridges.Bank.GetBalance(identifier, account_type)

--- Bridges.Bank.AddMoney(identifier, amount, reason, idempotency_key)
--- @param identifier string
--- @param amount number (positivo)
--- @param reason string human-readable ("salary_payment", "contract_fulfilled")
--- @param idempotency_key string unique per logical op
--- @return boolean success, string|nil error, table|nil metadata
Bridges.Bank.AddMoney(identifier, amount, reason, idempotency_key)

--- Bridges.Bank.RemoveMoney(identifier, amount, reason, idempotency_key)
--- @return boolean success, string|nil error ('INSUFFICIENT_FUNDS'|'NOT_FOUND'|'FAILED')
Bridges.Bank.RemoveMoney(identifier, amount, reason, idempotency_key)

--- Bridges.Bank.Transfer(from, to, amount, reason, idempotency_key)
--- @return boolean success, string|nil error
Bridges.Bank.Transfer(from, to, amount, reason, idempotency_key)

--- Bridges.Bank.IsAvailable()
--- @return boolean true si un adapter externo está activo (Modo B)
Bridges.Bank.IsAvailable()
```

### 4.3 Contrato detallado

| Propiedad | Spec |
|---|---|
| **Thread safety** | Adapter debe ser safe para concurrent calls. Si framework no lo es, adapter usa mutex interno. |
| **Atomicidad Transfer** | Debe ser atómico. Si framework no soporta transacción, adapter implementa rollback manual (try AddMoney después RemoveMoney, si falla AddMoney → revert RemoveMoney). |
| **Idempotencia** | Mismo `idempotency_key` en <5min → no-op 2ª vez + devuelve result cacheado. Store en `admirals_bridge_idempotency` table (TTL 1h). |
| **Error codes** | `INSUFFICIENT_FUNDS`, `NOT_FOUND`, `TIMEOUT`, `BRIDGE_UNAVAILABLE`, `VALIDATION_FAILED` |
| **Timeout** | 5 segundos max. Timeout → error `TIMEOUT`. |
| **Logging** | Toda call audit-logged con (adapter_name, method, identifier_hash, amount, reason, result, latency_ms). |

### 4.4 Adapters

#### 4.4.1 `adapter_qbox.lua` (T1)

```lua
local QBX = exports.qbx_core

local function GetBalance(identifier, account_type)
  local Player = QBX:GetPlayerByCitizenId(identifier)
  if not Player then return nil, 'NOT_FOUND' end
  return Player.PlayerData.money[account_type or 'bank'], nil
end

local function AddMoney(identifier, amount, reason, idem_key)
  if Bridges._IsIdemReplay(idem_key) then return true, nil, {replay=true} end
  local Player = QBX:GetPlayerByCitizenId(identifier)
  if not Player then return false, 'NOT_FOUND' end
  local ok = Player.Functions.AddMoney('bank', amount, reason)
  Bridges._StoreIdem(idem_key, ok)
  return ok, ok and nil or 'FAILED'
end
-- ... RemoveMoney, Transfer similar

Bridges.RegisterAdapter('bank', 'qbox', {
  GetBalance = GetBalance,
  AddMoney = AddMoney,
  RemoveMoney = RemoveMoney,
  Transfer = Transfer,
  IsAvailable = function() return GetResourceState('qbx_core') == 'started' end,
})
```

#### 4.4.2 `adapter_qbcore.lua` (T2)

Similar a QBox pero usa `exports['qb-core']:GetCoreObject().Functions.GetPlayer(...)`. Mismas 4 operaciones.

#### 4.4.3 `adapter_renewed_banking.lua` (T2)

Para customers con Renewed-Banking standalone (no acoplado al framework):

```lua
local RB = exports['Renewed-Banking']

local function GetBalance(iban, account_type)
  -- Renewed usa account_id directamente, no citizenId
  return RB:getAccountMoney(iban), nil
end
-- ...
```

#### 4.4.4 `adapter_native.lua` (fallback)

No-op para Modo A, o usa `admirals_bank_accounts` table directo si el customer marca modo synced pero no tiene script externo.

### 4.5 Expectativas testing adapter

Cada adapter debe pasar el test harness (§12.5):

- [ ] `GetBalance` retorna número para player válido.
- [ ] `GetBalance` retorna `NOT_FOUND` para citizenId inexistente.
- [ ] `AddMoney` incrementa balance correctamente.
- [ ] `RemoveMoney` falla `INSUFFICIENT_FUNDS` si balance < amount.
- [ ] `Transfer` es atómico (test concurrent → no double-spend).
- [ ] Idempotencia: 2 calls con mismo key → 1 cambio balance.
- [ ] Latencia p99 <100ms.

---

## 5. `Bridges.Inventory`

### 5.1 Responsabilidad

Operaciones sobre el inventario del **player** (carry, pockets) y de containers (vehicles, stashes). Admirals tiene ítems propios (`admirals_items` table con quality + lineage + atributos) pero necesita darlos/quitarlos del inventario activo del player para que los vea en su UI del framework.

> **Decisión clave:** Admirals **almacena** los ítems en su tabla (SSoT atributos). El bridge **refleja** la presencia del ítem en el inventario del framework (para UI/carry mechanics). Sync bidireccional.

### 5.2 Interface

```lua
--- Bridges.Inventory.GiveItem(citizenId, item_name, count, metadata)
--- @param metadata table { admirals_item_id, quality, lineage_origin, ... }
--- @return boolean success, string|nil error
Bridges.Inventory.GiveItem(citizenId, item_name, count, metadata)

--- Bridges.Inventory.RemoveItem(citizenId, item_name, count, admirals_item_id)
--- @param admirals_item_id string opcional, para remove item específico por ID
--- @return boolean success, string|nil error
Bridges.Inventory.RemoveItem(citizenId, item_name, count, admirals_item_id)

--- Bridges.Inventory.HasItem(citizenId, item_name, count)
--- @return boolean has, number actual_count
Bridges.Inventory.HasItem(citizenId, item_name, count)

--- Bridges.Inventory.GetItems(citizenId, filter)
--- @param filter table { item_name?, admirals_item_id? }
--- @return table[] items [{name, count, metadata}]
Bridges.Inventory.GetItems(citizenId, filter)

--- Bridges.Inventory.RegisterItem(item_spec)
--- @param item_spec table { name, label, weight, stack, close_on_use, description }
--- Call al boot para registrar items Admirals en el inventory.
Bridges.Inventory.RegisterItem(item_spec)

--- Bridges.Inventory.GetCapacity(citizenId)
--- @return number current_weight, number max_weight
Bridges.Inventory.GetCapacity(citizenId)

--- Bridges.Inventory.IsMetadataSupported()
--- @return boolean true si el adapter soporta metadata rica (ox_inventory sí, qb-inventory parcial)
Bridges.Inventory.IsMetadataSupported()
```

### 5.3 Contrato metadata

| Campo | Tipo | Propósito |
|---|---|---|
| `admirals_item_id` | string UUID | Link al row `admirals_items`. **Obligatorio** si Admirals-owned. |
| `quality` | 'A'\|'B'\|'C'\|'D' | Quality tier. |
| `quality_score` | number 0-100 | Score numérico. |
| `lineage_origin` | table | `{ granja_id, plot_id, harvest_ts }` para wheat/crops. |
| `lineage_chain` | string[] | Chain IDs upstream (wheat→flour→baguette). |
| `expires_at` | number | Unix timestamp expiración. |
| `producer_empresa_id` | string | Empresa que lo produjo. |

### 5.4 Metadata fallback para inventarios sin soporte

Si `IsMetadataSupported() == false` (p.ej. qb-inventory vanilla), el adapter serializa metadata en el `description` del ítem como JSON comprimido:

```
Description: "Wheat — Quality A\n[adm:eyJhIjoiQSIsIm9fZCI6MTIzNDV9]"
```

Admirals decoda al leer. Trade-off: no visible bonito al user pero funcional.

### 5.5 Adapters

#### 5.5.1 `adapter_ox_inventory.lua` (T1)

```lua
local ox_inv = exports.ox_inventory

local function GiveItem(citizenId, item_name, count, metadata)
  local source = GetSourceFromCitizenId(citizenId) -- helper
  if not source then return false, 'PLAYER_OFFLINE' end
  local ok = ox_inv:AddItem(source, item_name, count, metadata)
  return ok, ok and nil or 'FAILED'
end

local function IsMetadataSupported() return true end
-- ...

Bridges.RegisterAdapter('inventory', 'ox_inventory', {
  GiveItem = GiveItem, RemoveItem = RemoveItem, HasItem = HasItem,
  GetItems = GetItems, RegisterItem = RegisterItem,
  GetCapacity = GetCapacity,
  IsMetadataSupported = IsMetadataSupported,
  IsAvailable = function() return GetResourceState('ox_inventory') == 'started' end,
})
```

#### 5.5.2 `adapter_qs_inventory.lua` (T2)

Usa `exports['qs-inventory']` API. Soporta metadata básica. Puede requerir config manual de items en `qs-inventory/shared/items.lua`.

#### 5.5.3 `adapter_qb_inventory.lua` (T2)

Vanilla qb-inventory: metadata serializada en info field (JSON). Admirals decoda.

#### 5.5.4 `adapter_native.lua` (fallback)

Sin inventory script → Admirals provee inventario minimal propio via Tablet "Inventory app" + carry mechanic simple.

### 5.6 Edge cases

- **Player offline:** `PLAYER_OFFLINE` error. Caller debe encolar (p.ej. salary accrual pendiente reconnect).
- **Inventory lleno:** `INVENTORY_FULL` error. Caller notifica player.
- **Item no registrado:** boot-time check que todos los items Admirals están registered. Si no → warning log.

---

## 6. `Bridges.Phone`

### 6.1 Responsabilidad

Envío de notifications, SMS, llamadas desde Admirals al phone del player **si el customer tiene phone script separado**. Si no, Admirals usa el propio Tablet como único device (fallback native).

**Importante:** Tablet Admirals NO es un phone. Es un device corporativo adicional. El player puede tener ambos.

### 6.2 Interface

```lua
--- Bridges.Phone.SendNotification(citizenId, opts)
--- @param opts table { title, message, icon?, app?, duration? }
--- @return boolean success
Bridges.Phone.SendNotification(citizenId, opts)

--- Bridges.Phone.SendSMS(citizenId_to, citizenId_from, message)
--- @return boolean success
Bridges.Phone.SendSMS(citizenId_to, citizenId_from, message)

--- Bridges.Phone.StartCall(citizenId_to, citizenId_from, opts)
--- @return boolean success
Bridges.Phone.StartCall(citizenId_to, citizenId_from, opts)

--- Bridges.Phone.GetPhoneNumber(citizenId)
--- @return string|nil phone_number
Bridges.Phone.GetPhoneNumber(citizenId)

--- Bridges.Phone.IsAvailable()
--- @return boolean true si phone script externo activo
Bridges.Phone.IsAvailable()
```

### 6.3 Comportamiento si phone no disponible

Adapter `native`:
- `SendNotification` → envía al Tablet Admirals (app "Inbox").
- `SendSMS` → chat message server-only al player destinatario + persisted en ledger Tablet.
- `StartCall` → ❌ unsupported (error), porque calls voice requieren script dedicado.

### 6.4 Adapters

- `adapter_lb_phone.lua` (T1) — lb-phone API completa.
- `adapter_qs_smartphone.lua` (T2) — qs-smartphone API.
- `adapter_yseries.lua` (T2).
- `adapter_qb_phone.lua` (T2).
- `adapter_npwd.lua` (T2).
- `adapter_native.lua` (fallback al Tablet Admirals).

### 6.5 Anti-patterns phone

- ❌ **Usar phone como canal crítico de negocio.** (p.ej. escrow release requires phone delivery). → Admirals usa Tablet + audit log como SSoT. Phone es opcional notificación nice-to-have.
- ❌ **Esperar respuesta del phone.** Bridges.Phone es fire-and-forget. Player replies van via Tablet o framework chat.

---

## 7. `Bridges.Identity`

### 7.1 Responsabilidad

Resolver identidad del player — `src` (server id efímero) ↔ `citizenId` (stable) ↔ datos player (name, job, etc.). Admirals usa `citizenId` como SSoT en toda su DB. Bridges.Identity es el único que sabe cómo obtenerlo del framework externo.

### 7.2 Interface

```lua
--- Bridges.Identity.GetCitizenId(source)
--- @param source number player server id
--- @return string|nil citizenId
Bridges.Identity.GetCitizenId(source)

--- Bridges.Identity.GetSource(citizenId)
--- @return number|nil source (nil si offline)
Bridges.Identity.GetSource(citizenId)

--- Bridges.Identity.GetPlayerData(citizenId)
--- @return table|nil { citizenId, firstname, lastname, charinfo?, ... }
Bridges.Identity.GetPlayerData(citizenId)

--- Bridges.Identity.GetJob(citizenId)
--- @return table|nil { name, grade, label } del framework (no jobs Admirals)
Bridges.Identity.GetJob(citizenId)

--- Bridges.Identity.IsOnline(citizenId)
--- @return boolean
Bridges.Identity.IsOnline(citizenId)

--- Bridges.Identity.OnPlayerLoaded(callback)
--- @param callback function(citizenId, source)
--- Registrar listener global.
Bridges.Identity.OnPlayerLoaded(callback)

--- Bridges.Identity.OnPlayerDropped(callback)
--- @param callback function(citizenId, source, reason)
Bridges.Identity.OnPlayerDropped(callback)
```

### 7.3 Diferenciación jobs framework vs empresas Admirals

**Crítico:** un player puede tener:
- Un **job framework** (police, ambulance, mechanic) — gestionado por el framework.
- Uno o más **empresa Admirals** membership (Granja La Roja, Panadería X) — gestionado por Admirals.

`Bridges.Identity.GetJob()` devuelve **solo** el job framework. Los empresa Admirals se consultan via `admirals_core` APIs.

### 7.4 Adapters

- `adapter_qbox.lua` (T1): `QBX:GetPlayerByCitizenId()`, `QBX:GetPlayer()`, eventos `QBCore:Server:OnPlayerLoaded`.
- `adapter_qbcore.lua` (T2): similar.
- `adapter_esx.lua` (T2): `ESX.GetPlayerFromIdentifier()`. ESX usa `identifier` (license:xxx) en lugar de citizenId — adapter normaliza a string citizenId.
- `adapter_native.lua`: usa license como citizenId, sin framework. Permite Admirals standalone.

---

## 8. `Bridges.Target`

### 8.1 Responsabilidad

Registrar puntos de interacción (zones, entities) que el player ve con ox_target (o equivalente). Admirals registra interactions para: plots granja, mixer bakery, POS retail, ovens, silos, etc.

### 8.2 Interface

```lua
--- Bridges.Target.AddBoxZone(id, coords, size, heading, options)
--- @param options table[] [{ name, label, icon, action=function(entity) ... end, distance?, canInteract? }]
Bridges.Target.AddBoxZone(id, coords, size, heading, options)

--- Bridges.Target.AddEntity(entity_handle, options)
--- Add interaction to specific entity (vehicle, ped, object).
Bridges.Target.AddEntity(entity_handle, options)

--- Bridges.Target.AddModel(model_hashes, options)
--- Add interaction to all entities with given model.
Bridges.Target.AddModel(model_hashes, options)

--- Bridges.Target.RemoveZone(id)
--- @return boolean success
Bridges.Target.RemoveZone(id)

--- Bridges.Target.IsAvailable()
--- @return boolean
Bridges.Target.IsAvailable()
```

### 8.3 Adapters

- `adapter_ox_target.lua` (T1): API directa.
- `adapter_qb_target.lua` (T2): wrapper sobre qb-target.
- `adapter_qtarget.lua` (T2): wrapper legacy.
- `adapter_native.lua` (fallback): distance-check simple con marker ground. Sin eye-target polish.

---

## 9. `Bridges.Notify`

### 9.1 Responsabilidad

Notifications in-game (top-right corner, typical). Distintas de phone notifications (Bridges.Phone) que van al device del player.

### 9.2 Interface

```lua
--- Bridges.Notify.Show(source, opts)
--- @param opts table { type='info'|'success'|'warning'|'error', title?, message, duration?=5000 }
Bridges.Notify.Show(source, opts)

--- Bridges.Notify.Broadcast(opts)
--- A todos los players conectados.
Bridges.Notify.Broadcast(opts)
```

### 9.3 Adapters

- `adapter_ox_lib.lua` (T1): `lib.notify`.
- `adapter_qb.lua` (T2): `QBCore:Notify`.
- `adapter_esx.lua` (T2): `ESX.ShowNotification`.
- `adapter_native.lua`: `TriggerClientEvent('chat:addMessage')` simple.

---

## 10. Auto-detection + config overrides

### 10.1 Auto-detection al boot

```lua
-- admirals_bridges/server/init.lua
local detected = {
  bank = 'native',
  inventory = 'native',
  phone = 'native',
  identity = 'native',
  target = 'native',
  notify = 'native',
}

-- Priority per module (first match wins)
local priority = {
  bank = { 'qbox', 'qbcore', 'esx', 'renewed_banking', 'okok_banking' },
  inventory = { 'ox_inventory', 'qs_inventory', 'codem_inventory', 'qb_inventory' },
  phone = { 'lb_phone', 'qs_smartphone', 'yseries', 'qb_phone', 'npwd' },
  identity = { 'qbox', 'qbcore', 'esx' },
  target = { 'ox_target', 'qb_target', 'qtarget' },
  notify = { 'ox_lib', 'qb', 'esx' },
}

for module, adapters in pairs(priority) do
  for _, adapter_name in ipairs(adapters) do
    local adapter = Bridges.GetAdapter(module, adapter_name)
    if adapter and adapter.IsAvailable() then
      detected[module] = adapter_name
      break
    end
  end
end

-- Aplicar overrides convars
for module in pairs(detected) do
  local override = GetConvar('admirals_bridge_' .. module, '')
  if override ~= '' then
    if Bridges.GetAdapter(module, override) then
      detected[module] = override
    else
      Logger.Warn('Override %s=%s no encontrado, usando detected', module, override)
    end
  end
end

Bridges.SetActive(detected)
Logger.Info('Bridges configuradas: %s', json.encode(detected))
```

### 10.2 Config overrides (convars)

```cfg
# server.cfg
setr admirals_bridge_bank "qbox"               # o "renewed_banking", "native", "custom_mine"
setr admirals_bridge_inventory "ox_inventory"
setr admirals_bridge_phone "lb_phone"
setr admirals_bridge_identity "qbox"
setr admirals_bridge_target "ox_target"
setr admirals_bridge_notify "ox_lib"
setr admirals_bridge_bank_mode "standalone"    # "standalone" (Modo A) | "synced" (Modo B)
```

### 10.3 Conflict detection

Si 2 scripts del mismo módulo activos (p.ej. qb-inventory + ox_inventory), Admirals:
1. Usa el **primero en priority order** por default.
2. Logs **WARNING** explícito.
3. Recomienda al customer usar convar override explícito.

### 10.4 Boot report

Al acabar detection, Admirals prints reporte al console server:

```
═══════════════════════════════════════════════
  Admirals Bridges — Configuration Report
═══════════════════════════════════════════════
  Bank      → qbox             ✅
  Inventory → ox_inventory     ✅
  Phone     → lb_phone         ✅
  Identity  → qbox             ✅
  Target    → ox_target        ✅
  Notify    → ox_lib           ✅
  Bank mode → standalone
═══════════════════════════════════════════════
  Tier 1: 6 / 6 modules
  Warnings: 0
═══════════════════════════════════════════════
```

---

## 11. Native fallbacks

### 11.1 Filosofía fallback

> **Admirals debe arrancar y ser usable incluso sin ningún script externo.** Fallbacks nativos proveen mínimo funcional. UX puede ser inferior pero **nada crashea**.

### 11.2 Tabla fallbacks nativos

| Módulo | Native behavior | Limitaciones |
|---|---|---|
| **Bank** | Usa solo `admirals_bank_accounts`. No-op sync externo. | Player no ve su saldo en su phone framework (pero sí en Tablet). |
| **Inventory** | Tabla `admirals_items_carry` + UI Tablet "Inventory app". Carry limit simple por peso. | Sin drag-drop HUD framework-native. |
| **Phone** | Notifications al Tablet Admirals (app "Inbox"). SMS → chat message + ledger. Calls → unsupported. | No voice calls. |
| **Identity** | Usa `GetPlayerIdentifiers(source)` directo, license como citizenId. | No jobs/charinfo framework-level. |
| **Target** | Distance-check + keypress E. Marker ground visible. | No eye-target polish. |
| **Notify** | `chat:addMessage` simple. | Sin colores/iconos rich. |

### 11.3 Cuándo native es OK

- **Dev / testing:** yes, saves framework dependencies.
- **Small private server Admirals-centric:** yes, si el valor es el loop económico y no carry inventory.
- **Public premium server:** ❌ no, se espera stack premium.

---

## 12. Custom Adapter SDK

### 12.1 Cuándo usar SDK

Customer usa un script:
- No listado en T1/T2 (p.ej. custom-built banking interno, fork privado).
- Versión forked con API divergente del official.

### 12.2 Template files (`sdk/`)

#### `sdk/template_bank.lua`

```lua
-- Admirals Bridges SDK — Custom Bank Adapter Template
-- Copy to admirals_bridges/adapters/bank/my_bank.lua
-- Implement los 5 métodos. Register at bottom.

local MyBankAdapter = {}

function MyBankAdapter.GetBalance(identifier, account_type)
  -- TODO: implement
  -- Return: number balance, nil error
  --     o: nil balance, string error ('NOT_FOUND', etc.)
end

function MyBankAdapter.AddMoney(identifier, amount, reason, idempotency_key)
  -- TODO: implement idempotency check primero
  if Bridges._IsIdemReplay(idempotency_key) then
    return true, nil, {replay=true}
  end
  -- TODO: call your bank API
  -- Store idempotency result
  Bridges._StoreIdem(idempotency_key, result)
  return ok, err
end

function MyBankAdapter.RemoveMoney(identifier, amount, reason, idempotency_key)
  -- TODO: implement. Error si INSUFFICIENT_FUNDS.
end

function MyBankAdapter.Transfer(from, to, amount, reason, idempotency_key)
  -- TODO: ATOMIC. Rollback si falla mid-way.
end

function MyBankAdapter.IsAvailable()
  return GetResourceState('my_bank_resource') == 'started'
end

Bridges.RegisterAdapter('bank', 'my_bank', MyBankAdapter)
```

#### `sdk/template_inventory.lua`

Similar estructura para inventory.

#### `sdk/template_phone.lua`

Similar para phone.

### 12.3 SDK README (`sdk/README.md`)

Documento con:
- Quick start (copy template → edit → register).
- Lista required methods per bridge.
- Error code reference.
- Idempotency pattern.
- Testing con test harness.
- Common gotchas.
- Support channels.

### 12.4 Registration

```lua
-- Customer edita admirals_bridges/config.lua
Config.CustomAdapters = {
  bank = 'my_bank',       -- nombre del adapter registrado
  inventory = 'my_inv',
}
```

Al boot, si config lista custom adapter, Admirals lo usa (prioriza sobre auto-detection).

### 12.5 Test harness

```lua
-- scripts/test_adapter.lua — run via exec test_adapter
local function testBankAdapter(name)
  local adapter = Bridges.GetAdapter('bank', name)
  if not adapter then return print('Adapter '..name..' not found') end

  local test_id = 'test_' .. GetGameTimer()
  local tests = {
    {
      name = 'GetBalance - invalid citizen',
      fn = function()
        local bal, err = adapter.GetBalance('INVALID_ID', 'bank')
        assert(err == 'NOT_FOUND', 'expected NOT_FOUND got '..tostring(err))
      end,
    },
    {
      name = 'AddMoney - idempotency',
      fn = function()
        local ok1 = adapter.AddMoney(TEST_CITIZEN, 100, 'test', test_id)
        local ok2 = adapter.AddMoney(TEST_CITIZEN, 100, 'test', test_id) -- same key
        local bal = adapter.GetBalance(TEST_CITIZEN, 'bank')
        -- should only add 100 total, not 200
      end,
    },
    -- ... 15+ tests más
  }

  for _, test in ipairs(tests) do
    local ok, err = pcall(test.fn)
    print(string.format('[%s] %s %s', ok and 'PASS' or 'FAIL', test.name, err or ''))
  end
end
```

Customer runs: `exec resources/admirals_bridges/scripts/test_adapter.lua` + console command `admirals_test_adapter bank my_bank`.

---

## 13. Lifecycle hooks bidireccional

### 13.1 Admirals → External (outbound)

Admirals emite eventos cuando cambia estado relevante, para que externa sincronice si quiere:

```lua
-- Admirals emite tras pagar salario:
TriggerEvent('admirals:bridge:moneyChanged', {
  citizenId = '...',
  delta = 2000,
  new_balance = 5500,
  reason = 'salary_payment',
  bridge_account = 'bank',
})

-- External scripts pueden escuchar:
AddEventHandler('admirals:bridge:moneyChanged', function(data)
  -- actualizar UI phone o lo que sea
end)
```

Eventos emitidos:
- `admirals:bridge:moneyChanged`
- `admirals:bridge:itemGiven` / `admirals:bridge:itemRemoved`
- `admirals:bridge:empresaJoined` / `admirals:bridge:empresaLeft`
- `admirals:bridge:contractSigned`

### 13.2 External → Admirals (inbound)

Si external script cambia dinero/items del player directamente (bypass Admirals), Admirals necesita saberlo para keep ledger consistent. Convention:

```lua
-- External script paga al player (p.ej. robo al banco, evento custom)
-- DEBE emitir:
TriggerEvent('admirals:external:moneyAdded', {
  citizenId = '...',
  amount = 500,
  reason = 'bank_heist_payout',
  source = 'my_heist_script',
})

-- Admirals registra en audit log pero NO modifica ledger Admirals (que es separate SSoT).
```

**Importante:** este hook es **advisory**. Admirals lo audita pero no lo reconcilia automáticamente con su ledger propio (Modo A). En Modo B, reconciliation cron runs diario.

---

## 14. Testing matrix

### 14.1 Combos garantizados

| # | Framework | Inventory | Phone | Target | Notify | Tier |
|---|---|---|---|---|---|---|
| 1 | QBox | ox_inventory | lb_phone | ox_target | ox_lib | T1 baseline |
| 2 | QBox | ox_inventory | qs_smartphone | ox_target | ox_lib | T1-T2 mix |
| 3 | QBCore | ox_inventory | lb_phone | ox_target | ox_lib | T2 framework + T1 rest |
| 4 | QBCore | qb-inventory | qb-phone | qb-target | qb | T2 all vanilla QB |
| 5 | ESX | ox_inventory | lb_phone | ox_target | ox_lib | T2 ESX + T1 rest |
| 6 | Native | Native | Native | Native | Native | Fallback baseline |

### 14.2 Testing cadence

| Combo | CI automated? | Pre-release smoke? | Community-tested? |
|---|---|---|---|
| #1 (QBox+ox_*+lb) | 🔜 Oleada 2 | ✅ cada release | ✅ primary |
| #2-3 | 🔜 Oleada 2 | ✅ cada release | ✅ |
| #4 | ❌ | ✅ cada Oleada | ⚠️ limited |
| #5 | ❌ | ✅ cada Oleada | ⚠️ limited |
| #6 (native) | ❌ | ✅ cada release | N/A dev |

### 14.3 Customer reporting

Customers reportan issues con combo específico via Discord + issue template:

```
**Combo:**
- Framework: QBox v1.9.2
- Inventory: ox_inventory v2.41
- Phone: custom fork of lb-phone v1.3

**Issue:** Bridges.Phone.SendNotification no llega...
**Logs:** ...
```

Admirals maintainers reproducen si posible.

---

## 15. Versioning + deprecation policy

### 15.1 SEMVER bridges

Las interfaces Bridges son SEMVER independiente del versioning Admirals general:

- **MAJOR** — breaking change en firma (rompe adapters existentes).
- **MINOR** — añadir método nuevo (backward-compatible).
- **PATCH** — bugfix en dispatcher/registry, interface sin cambio.

### 15.2 Breaking changes policy

Cada breaking change:
1. **Anuncio 1 minor version antes** (MINOR deprecation warning).
2. **Log warning runtime** al llamar método deprecated.
3. **Documentado en CHANGELOG** con migration path.
4. **Customer notice Discord** 2 semanas antes del MAJOR.

Ejemplo:
```
v1.2 (current): Bridges.Bank.AddMoney(identifier, amount, reason)
v1.3 (deprecation): añade Bridges.Bank.AddMoneyV2(identifier, amount, reason, idempotency_key)
        AddMoney v1 runtime warn "deprecated, use AddMoneyV2"
v2.0: remueve AddMoney, mantiene solo AddMoneyV2 (renombrado AddMoney).
```

### 15.3 Current version

- **Bridges interface v1.0** (al firmar este doc).
- Committed Oleada 1 completa sin breaking changes.

---

## 16. Anti-patterns

- ❌ **`exports['script-name']` fuera de adapters.** Grep el repo pre-merge: ningún match excepto en `admirals_bridges/adapters/`.
- ❌ **Bridges con lógica de negocio.** Bridge routes + traduce. Lógica va en `admirals_core`.
- ❌ **Hardcoded framework check.** `if QBCore then...` prohibido fuera de adapters. En su lugar: feature-detect vía `Bridges.X.IsMetadataSupported()` etc.
- ❌ **Leak tipos externos.** `Bridges.Bank.GetBalance` NUNCA devuelve un `QBCore.Player` — devuelve número puro.
- ❌ **No-op silencioso.** Si adapter no soporta algo, throw clear error, no return true.
- ❌ **Sync pesado per-call.** Si adapter no es idempotent, adapter wrappea con cache. No cada caller.
- ❌ **Bridges que conocen `source`.** Siempre usan `citizenId`. Adapter internamente mapea si necesita `source`.
- ❌ **Bridges blocking thread.** Si operación >50ms, debe ser async/promise.
- ❌ **Silent migration.** Breaking change sin deprecation window = customers angry.
- ❌ **SDK template desactualizado.** Cada bump minor/major en bridges interface → update templates.

---

## 17. Roadmap + estado

### 17.1 Roadmap implementación

#### Sprint 0 Oleada 1 (inmediato post-firma doc)
- ✅ Skeleton `admirals_bridges` resource structure.
- ✅ Registry + Dispatcher + Logger.
- ✅ Interfaces de los 6 bridges (sin adapters).
- ✅ Auto-detection mecanismo.
- ✅ Config overrides convars.
- ✅ Adapter `qbox` (T1 primary) completo.
- ✅ Adapter `ox_inventory` (T1) completo.
- ✅ Adapter `ox_target` (T1) completo.
- ✅ Adapter `ox_lib` notify (T1) completo.
- ✅ Adapter `native` para bank/inventory/phone/target/notify (fallbacks).
- ✅ Boot report al console.
- ✅ Test harness esqueleto.

#### Sprint 1-3 Oleada 1
- 🔜 Adapter `lb_phone` (T1).
- 🔜 Integración con admirals_core: primer callback usa bridges (transfer money Sprint 1).

#### Sprint 4+ Oleada 1
- 🔜 Adapters T2 adicionales (QBCore, ESX, qb-inventory, qs-inventory, qb-phone) según demanda.
- 🔜 Testing matrix combos documentados.

#### Oleada 2
- 🔜 CI automated para combos T1.
- 🔜 Custom Adapter SDK público + documentado.
- 🔜 Community adapters en T3.

#### Oleada 3+
- 🔜 Bridge cross-server (federation).
- 🔜 Bridges.Dispatch (police/ems).
- 🔜 Bridges.Fuel (logistics).

### 17.2 Estado del documento

- **Versión:** 1.0 (firmable — completo, 17 secciones).
- **Próxima revisión:** tras implementación Sprint 0 Oleada 1 con learnings reales + v1.1 con adapters adicionales validados.
- **Documento padre:** `agents/00_BOOTSTRAP.md` v1.1.
- **Documentos hermanos:** `technical/01_architecture.md`, `technical/04_api_contracts.md`, `technical/06_fivem_standards.md`.
- **ADR relacionado:** ADR-007 (pendiente firma `planning/02_decision_log.md`).

### 17.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Primera redacción. 17 secciones: filosofía + arquitectura + tier system + 6 bridges (Bank/Inventory/Phone/Identity/Target/Notify) con interfaces exactas + adapters T1/T2/native + auto-detection + config overrides + native fallbacks + Custom Adapter SDK + lifecycle hooks + testing matrix + versioning policy + anti-patterns + roadmap. **Firmable.** |

---

## 18. TL;DR — reglas absolutas bridges

### Regla 1: Nunca external directo
```
grep -r "exports\['qb-" admirals_core/ → 0 matches
grep -r "exports\['qbx-" admirals_core/ → 0 matches (incluso QBox primary)
grep -r "ESX\." admirals_core/ → 0 matches
```

### Regla 2: 6 bridges, 6 responsibilidades
- `Bridges.Bank` — dinero framework externo (Modo B) o no-op (Modo A).
- `Bridges.Inventory` — items carry.
- `Bridges.Phone` — notificaciones phone externo.
- `Bridges.Identity` — citizenId ↔ source ↔ player data.
- `Bridges.Target` — interacciones world.
- `Bridges.Notify` — notifications in-game.

### Regla 3: Tier system
- **T1 garantizado:** QBox + ox_* + lb-phone.
- **T2 compat:** QBCore, ESX, vanilla qb-*, qs-*, yseries.
- **T3 customer:** SDK + templates.

### Regla 4: Fallback always works
Sin scripts externos → Admirals boota y funciona con native fallbacks. UX degradada pero no crashea.

### Regla 5: Config-driven
Convars overriding auto-detection. Customer nunca edita código Admirals.

### Regla 6: Versioned + deprecated con aviso
1 minor version warning antes de cualquier breaking. Customers happy.

### Regla 7: Tested
Testing matrix con 6 combos baseline. Cada release smoke-tested. CI para T1 Oleada 2+.

---

## Resumen ejecutivo (cierre)

El **Bridges Layer Admirals** es **la inversión más importante pre-code** del proyecto. Sin él:

- Admirals se acopla a 1 framework → 70% del mercado FiveM premium excluido.
- Refactorizar post-Sprint-3 es **semanas perdidas**.
- Customers con scripts custom no pueden comprarnos.

Con él:

- **Admirals vende a QBox + QBCore + ESX + customs.**
- **Desde línea 1, el código es framework-agnostic.**
- **Custom Adapter SDK permite comunidad extender sin tocar core.**
- **Fallbacks nativos garantizan que nada crashea.**
- **Versioning disciplinado protege customers.**

Este doc define:
- **7 principios** + arquitectura clara.
- **6 bridges con interfaces exactas** (contratos firmables).
- **Tier system T1/T2/T3** con soporte claro.
- **Auto-detection + config overrides** para zero-friction setup.
- **Native fallbacks** para robustez.
- **SDK customer** con templates + test harness.
- **Testing matrix** de 6 combos.
- **Versioning policy** SEMVER + deprecation.
- **Anti-patterns** que evitan colapso abstracción.

> **Tras firmar este doc: Oleada 0 100% CERRADA (29/29 docs).** Sprint 0 Oleada 1 puede empezar **inmediatamente** con la confianza de que cada línea de código escrita es framework-agnostic, customer-friendly, y vendible.

---

*"Una abstracción bien diseñada es dinero en el banco. Una abstracción mal diseñada es un banco que quiebra."*

**FIN DEL DOCUMENTO `technical/07_bridges_compatibility.md` v1.0**
