# Research notes — primitivas modernas FiveM (BANK-BE.0)

> **Owner:** Backend Money & Compatibility Lead.
> **Time-box:** 60-90 min consolidados durante BANK-BE.0 onboarding (post-handshake green-light founder 2026-05-06).
> **Status:** ✅ findings consolidated → input directo para C-BE-04 + C-BE-05 + ADR-018.
> **Source canonical:** `https://docs.fivem.net/docs/` (Cfx.re official documentation, accessed 2026-05-06).

---

## 1. State Bags global — confirmación CP1 + privacy boundary

### 1.1 Política write-side (server-only) — confirmada

> Cita docs Cfx.re: *"Currently, the only policy limitation implemented is to filter player state to be able to be written by the player and the server, entity state to be written by the owning player and the server, and global state to be able to be written by the server."*
>
> — `https://docs.fivem.net/docs/scripting-manual/networking/state-bags/`

**Implicación CP1:** servidor escribe `GlobalState['bank.balance.<citizen_id>'] = value` con autoridad nativa. Cliente NO puede escribir global state — write attempt rechazado por engine.

### 1.2 Política read-side (broadcast all clients) — privacy concern crítico

**El engine NO filtra reads de global state per-client.** Cualquier cliente conectado puede ejecutar `GetStateBagValue('global', 'bank.compliance.123')` o iterar `LocalPlayer.state` para buscar keys leak.

**Conclusión:** Q-BE-pre-02 + Q-BE-pre-03 founder approval VALIDADO técnicamente — global state no es un mecanismo apto para datos sensibles per-citizen. **C-BE-05 redefine alcance CP1** para distinguir:

- **CP1-A (público):** balances + counts + flags-bool (no leak privacy).
- **CP1-B (admin-only):** detalles compliance + escrow state + audit ledger queries → **NetEvents directos** con ACE check server-side.

### 1.3 Shallow limitations

State bags re-serializan **el valor completo del key** en cada change (no deep-merge). Implicación design:

- Mantener bag values **flat + small** (e.g. balance number scalar, no objetos anidados grandes).
- Para state compuesto (e.g. `bank.govt.taxBrackets` = array brackets), considerar split keys per-bracket si update granular es frecuente.

---

## 2. Convars experimentales relevantes (CP7 input para DevOps)

| Convar | Server version | Default actual | Recomendación SONAR Bank |
|---|---|---|---|
| `sv_experimentalStateBagsHandler` | v8510+ | **TRUE default** | Mantener default. **Mandatory recommended** README install (CP7 + Q16.4). |
| `sv_experimentalNetGameEventHandler` | v9149+ | **TRUE default** (desde Jul 2025) | Mantener default. **Mandatory** — auto-opts in `experimentalStateBagsHandler` + `experimentalOneSyncPopulation`. |
| `sv_experimentalOnesyncPopulation` | v8823+ | TRUE default | Mantener default. Fixes 8192 → 65535 entity ID limit. |
| `sv_enableNetworkedScriptEntityStates` | v8540+ | TRUE default | Mantener default. Anti-malicious entity state routing. |
| `sv_enableNetEventReassembly` | older | TRUE default | Mandatory CP7 — net event payload reassembly para callbacks Bank con payloads >1.5KB (e.g. transactions list paginada). |
| `onesync` | foundational | `legacy` / `on` / `off` | **Required `on`** (infinity sync) — SONAR Bank diseñado sobre OneSync infinity. `legacy` o `off` → defensive abort boot CP4. |

**DevOps Lead C-DO-03 README install** spec coordinará convars finales en H4. Backend Lead spec asume todas las convars en defaults TRUE actuales.

---

## 3. Routing buckets — defer Phase D (NO scope Phase A)

`SetEntityRoutingBucket` + `SetPlayerRoutingBucket` permiten split server state en buckets aislados (entity-level + player-level visibility).

**Aplicabilidad SONAR Bank:**
- ❌ **Phase A:** NO scope. Bank app es UI-only (NUI) — no requiere split entity state.
- 🟡 **Phase D potencial:** Government Console "session room" privacy si govt entity tiene UI compartida live durante elections (votes raw access ACE check). Defer founder decisión Phase D.

---

## 4. ResourceKvp persistence

`SetResourceKvp(key, value)` + `GetResourceKvpString(key)` — KV store persistente per-resource. Survive restart.

**Uso recomendado SONAR Bank:**

| Caso uso | Key | Storage tipo | Razón |
|---|---|---|---|
| Defensive boot disable flag (CP4) | `sonar_bank_disabled` | string (reason code) | Persiste post-restart si framework detection falla. Admin lee via console + Backend lib `BankStatus.IsDisabled()`. |
| Watchdog Core Override last check ts | `sonar_bank_override_last_check` | string (epoch ms) | Detection compromise post-restart Core Override no aplicó. |
| Sonar bank status FSM cached state | `sonar_bank_status_cached` | string (state name) | Backup de DB `sonar_bank_status` row si DB read fail durante boot. Fallback graceful degradation. |

**NOT used for:**
- ❌ Idempotency keys → DB tabla `sonar_bank_idempotency_keys` (migration 028, TTL 7d managed).
- ❌ Balance / movements → DB authoritative.

---

## 5. Citizen.SetTimeout vs CreateThread vs CreateThreadNow (watchdog timing)

| Primitive | Use case | Trade-off |
|---|---|---|
| `Citizen.SetTimeout(ms, fn)` | One-shot delayed task. **Watchdog 30s post-boot CP4.** | Simple, single execution. Si server crash 0-30s post-boot → watchdog skipped (acceptable per defensive design). |
| `CreateThread(fn)` con `Wait(ms)` loop | Periodic recurring task. **Watchdog progressive checks** (Q-BE-pre-05 sub-question — propongo dual-tier 30s + 5min + 30min). | Coroutine yield-friendly. Recomendado para periodic. |
| `CreateThreadNow(fn)` | Immediate execution + return tras Wait/yield. | Útil para boot init code que necesita correr ANTES de otro init. |

**Decisión BANK-BE.0:** watchdog Core Override progresivo:
- T+30s: primer check (sentinel attribute B).
- T+5min: segundo check + métrica indirecta (C — esx events sin correlation-id sonar inyectado).
- T+30min: tercer check (defensive long-tail).
- Después: idle (no más checks) — si compromise no detectado post 30min, asumimos override estable.

---

## 6. onResourceStart + onResourceStarting + dependency declarations

### 6.1 fxmanifest dependencies

```lua
-- fxmanifest.lua sonar_bridges/
fx_version 'cerulean'
game 'gta5'

dependencies {
  '/server:8510',     -- minimum server version (sv_experimentalStateBagsHandler default TRUE)
  '/onesync',          -- requires onesync on
  'oxmysql',
  'ox_lib',
}
```

**Backend Lead recommendation:** declarar `dependencies` en `sonar_bank_app/fxmanifest.lua` + `sonar_bridges/fxmanifest.lua` para auto-fail si missing. Coordinación H4 con DevOps Lead.

### 6.2 Boot ordering

```
load_resource_file('oxmysql') → onResourceStarting('sonar_core') → onResourceStart('sonar_core')
  → onResourceStarting('sonar_bridges') → ... defensive boot CP4 → onResourceStart('sonar_bridges')
  → onResourceStarting('sonar_bank') → ... → onResourceStart('sonar_bank')
  → onResourceStarting('sonar_bank_app') → ... callbacks register → onResourceStart('sonar_bank_app')
```

**CP4 defensive boot check** ejecuta en `onResourceStart('sonar_bridges')` — antes de cualquier otro `sonar_bank*` resource cargue. Si framework detection falla → `SetResourceKvp('sonar_bank_disabled', 'reason_code')` + console banner + abort.

---

## 7. NetEvents internos vs cross-resource

| Event type | Use case Bank Phase A | Recommendation |
|---|---|---|
| `RegisterServerEvent` | Server-side handlers desde clientes (`TriggerServerEvent` from client) | Mandatory para callbacks user-initiated (ox_lib `lib.callback` wraps esto). |
| `RegisterNetEvent` (client-side) | Receive NetEvents desde server (`TriggerClientEvent` from server) | Mandatory para discrete notifications post-CP1 — `sonar:bank:transferComplete` + `sonar:bank:escrowStateChanged` (privacy CP1-B path) + `sonar:bank:complianceDetail` (admin-only). |
| `AddEventHandler` (resource-internal) | Coordinación cross-resource sin network roundtrip | **Performance optimal** — usar entre `sonar_bridges` ↔ `sonar_bank` ↔ `sonar_bank_app` (mismo server, no network cost). |
| `TriggerLatentClientEvent` | Payloads grandes (>1.5KB) split en chunks | Para `bank.getTransactions` response paginada full year — descarta chunking manual. |

---

## 8. Lazy resource start patterns (CP4 defensive)

**Pattern:** `sonar_bank_app` declara `dependency 'sonar_bridges'` + `dependency 'sonar_bank'`. Si bridges/bank fail boot (defensive disable) → `sonar_bank_app` no arranca = silent abort downstream.

**Mejora propuesta:** durante `onResourceStart('sonar_bank_app')`, query `BankStatus.IsDisabled()` (lib `sonar_bridges`) — si disabled, register stub callbacks que respondan `{ status: 'error', error: { code: 'BANK_DISABLED', reason: <kvp> } }` para user-facing UX. NO crash chain.

---

## 9. Net event reassembly + payload size budgets

`sv_enableNetEventReassembly TRUE` (default) permite payloads >1.5KB MTU. **Pero:** payloads grandes consume bandwidth significativo + latency.

**Budget propuesto callbacks Bank:**
- Pequeño: <512 bytes — preferred (e.g. `bank.transfer` request 5 fields).
- Mediano: 512-4KB — acceptable (e.g. `bank.getAccountInfo` response con multi-account summary).
- Grande: 4-32KB — warning bracket (e.g. `bank.getTransactions` paginada 50 rows). Considerar pagination cursor.
- Crítico: >32KB — **REJECT design**. Refactor a paginated o streaming pattern.

C-BE-02 API contracts spec impone budget per callback explícito.

---

## 10. UUID v4 random — ox_lib vs custom

**ox_lib provee** `lib.string.random` pero NO uuid v4 spec-compliant. Backend Lead recommendation:

```lua
-- lib/uuid.lua (sonar_bridges)
-- UUIDv4 compliant per RFC 4122 §4.4.
-- Uso: correlation-id mutex CP2 + idempotency keys generation.
local function uuid4()
  -- ... implementation con math.random + bit ops + format
  return string.format('%08x-%04x-%04x-%04x-%012x',
    math.random(0, 0xFFFFFFFF),
    math.random(0, 0xFFFF),
    bit.bor(0x4000, bit.band(math.random(0, 0xFFFF), 0x0FFF)),
    bit.bor(0x8000, bit.band(math.random(0, 0xFFFF), 0x3FFF)),
    math.random(0, 0xFFFFFFFFFFFF)
  )
end
```

**Decisión:** lib propia `sonar_bridges/lib/uuid.lua` exportada `Bridges.UUID.v4()`. Math.random seeded `os.time() ^ GetGameTimer()` durante boot.

---

## 11. Cita references canonical Cfx.re docs (accessed 2026-05-06)

- State bags: `https://docs.fivem.net/docs/scripting-manual/networking/state-bags/`.
- Server commands + convars: `https://docs.fivem.net/docs/server-manual/server-commands/`.
- OneSync: `https://docs.fivem.net/docs/scripting-reference/onesync/`.
- onResourceStart: `https://docs.fivem.net/docs/scripting-reference/events/list/onResourceStart/`.
- Routing buckets: `https://docs.fivem.net/docs/cookbook/2020/11/27/routing-buckets-split-game-state/`.
- AddStateBagChangeHandler native: `https://docs.fivem.net/natives/?_0x5BA35AAF=`.
- SetResourceKvp native: `https://docs.fivem.net/natives/?_0x21C7A35B=`.

---

## 12. Versioning

| Version | Fecha | Cambios |
|---|---|---|
| **v0.1** | 2026-05-06 | BANK-BE.0 research time-box consolidated. Findings → input directo para C-BE-04 + C-BE-05 + ADR-018. |

— **Research notes BANK-BE.0** — input downstream contracts.
