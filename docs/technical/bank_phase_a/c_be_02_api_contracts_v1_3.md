# C-BE-02 — API Contracts v1.3 Bank Phase A — 40+1 callbacks + 22 exports (LOCKED v1.0.2 R2)

> **Owner:** Backend Money & Compatibility Lead.
> **Consumer Leads:** Frontend Lead (consume callbacks UI) + Security Lead (audit auth + ACE matrix + idempotency + rate-limits).
> **Status:** 🟢 **v1.0.1 R1 LOCKED 2026-05-06** (BANK-BE.LOCK.R1 ceremony — Round 1 amendment promoted post Security Lead PASS veredicto BANK-SEC.1).
> **Fecha:** 2026-05-06 (BANK-BE.1 → BANK-BE.LOCK → BANK-BE.AMEND.1 → BANK-BE.LOCK.R1).
> **Path canonical:** `docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` v1.0.1 R1 LOCKED. Pointer §X.NEW `docs/technical/04_api_contracts.md` v1.3.1.
> **Cross-ref:** C-BE-01 v1.0.1 R1 (54 NetEvents — 3 NEW M004) + C-BE-03 v1.0.1 R1 (FSM hardening H005 + M005) + C-BE-04 v1.0.1 R1 (Bridges API + UUID PRNG §3.3.1 + 4 convars) + C-BE-05 v1.0.1 R1 (CP1-B publish_balance_update canonical helper).

---

## 1. Filosofía API Contracts Bank Phase A

### 1.1 Inherited principles (per `04_api_contracts.md` v1.2 §1.1 A1-A8)

- **A1** Cada callback es un contrato (request schema + response schema + auth + side effects).
- **A2** ox_lib `lib.callback.register` server-side + `lib.callback.await` client-side (Q-DB-K LOCKED).
- **A3** Validation server-side mandatory — NUNCA confiar payload client.
- **A4** Idempotency keys donde aplicable (mutations).
- **A5** Error codes ENUM canonical (no strings ad-hoc).
- **A6** Atomic transactions DB (BEGIN/COMMIT) per mutation.
- **A7** Audit ledger append-only per mutation.
- **A8** Performance budgets per callback documentados.

### 1.2 NEW principles Bank Phase A (Q-BE-pre-04 + Q-BE-pre-06 + Q-BE-pre-11 integration)

- **A9 (Q-BE-pre-04)** Granularidad **~40 callbacks** mantenida. Granular > monolithic per audit + perf + security review.
- **A10 (Q-BE-pre-06)** Idempotency **DB persistent** (`sonar_bank_idempotency_keys` migration 028) + **`result_payload` JSON cached** (replay devuelve mismo payload sin recompute).
- **A11** **Auth Server-side mandatory en cada callback** — `IsPlayerAceAllowed(src, perm)` o resolución `local citizen_id = Bridges.Player.GetCitizenId(source)` + nil-check obligatorio + comparación contra `resource.owner_id` o equivalent. **NUNCA `source.citizen_id` como acceso directo** — `source` es integer player handle, NO table (anti-pattern AP-AUTH-1 prohibido `@.windsurf/rules/bank.md` — v1.0.1 R1 H001 fix). NUNCA trust client claim.
- **A12** **Rate-limit explícito por callback** — token bucket via lib `sonar_bridges/lib/rate_limiter.lua` (NEW BANK-BE.1 commitment) — convars configurables defaults sensibles.
- **A13** **Idempotency keys mandatory en mutations**, optional en reads idempotentes (e.g. `bank.account.getInfo` natural idempotente sin key requerido).
- **A14** **Side effects documentados explícitamente** — DB writes + StateBag emits + NetEvents fired + audit ledger entries + cron triggers + cross-resource events. **Security Lead C-SEC-01 audit hook integration referenced explicitly.**
- **A15** **Error codes registry centralizado §3** — todos callbacks usan ENUM canonical. NO strings ad-hoc.
- **A16 (CP4 defensive)** **Early return BANK_DISABLED** si `Bridges.BankStatus.IsDisabled() == true` en TODOS callbacks (boilerplate first-line).
- **A17** **Performance perf target p99 documentado** per callback (consume DB Lead benchmark Q-BE-pre-08 Opción C estimación).
- **A18 (Phase 5 Q1 LOCKED — NEW v1.0.2 R2)** **Boundary convention split.** La superficie pública exports server-to-server (Tier 1/2 documentada en §10 abajo) usa **INTEGER minor units** en todos los amount fields. La superficie legacy callbacks (C001-C040 + C001b) y DB DECIMAL columns y Frontend display preservan **DECIMAL major units** Phase A. Boundary helpers `sonar_bank_app/server/lib/units.lua` (`to_minor` / `from_minor`, HALF_UP rounding) **mandatory** en cada wrapper Tier 1/2 — NUNCA float math en service layer una vez convertido a integer. Phase A+1 migra DB + callbacks + Frontend end-to-end a INTEGER minor — roadmap `@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`.

---

## 2. Authentication + ACE matrix framework

### 2.1 Auth tiers Bank Phase A

Cada callback declara explícitamente uno de los 5 auth tiers:

| Tier | Descripción | Check pattern |
|---|---|---|
| **AUTH-PUBLIC** | No auth — read-only data pública (e.g. `bank.tax.getBrackets`, `bank.subsidy:list`). | `source > 0` (player connected) — sin ACE check |
| **AUTH-OWNER** | Solo owner del recurso. | `auth.require_owner(source, resource.owner_id)` — internamente: `local cid = Bridges.Player.GetCitizenId(source); return cid ~= nil and cid == resource.owner_id` (v1.0.1 R1 H001) |
| **AUTH-OWNER_OR_PARTICIPANT** | Owner o participant explícito (e.g. escrow → payer/payee). | `auth.require_participant(source, {resource.payer_id, resource.payee_id})` — same nil-safe pattern, set membership |
| **AUTH-ROLE** | Role-based check via ACE permission. | `IsPlayerAceAllowed(source, '<perm>')` |
| **AUTH-ROLE_OR_OWNER** | Role-based OR owner (admin override path). | OR-combination |

### 2.2 ACE permissions matrix (canonical Bank Phase A)

| Permission | Descripción | Granted to |
|---|---|---|
| `sonar.bank.audit.self` | Read-only audit ledger entries del citizen propio. | Default ALL players (auto-granted). |
| `sonar.bank.empresas.<company_id>` | Read-only audit ledger entries empresa específica. | Granted dynamic empleados/owners empresa. |
| `sonar.bank.govt.audit.full` | Read-only audit ledger TODAS empresas + citizens. | Granted ROL govt official. |
| `sonar.bank.govt.tax.write` | Modify tax brackets + subsidies. | Granted ROL govt minister economic. |
| `sonar.bank.govt.subsidy.write` | Grant/revoke subsidies. | Mismo. |
| `sonar.bank.govt.elections.admin` | Elections force phase transitions / cancel. | Granted ROL govt elections committee. |
| `sonar.bank.govt.escrow.admin` | Force escrow refund / dispute resolution. | Granted ROL govt judge. |
| `sonar.bank.govt.loan.admin` | Approve/reject loan applications + write-off. | Granted ROL govt economic. |
| `sonar.bank.govt.compliance.admin` | Resolve compliance flags + raise manual flags. | Granted ROL govt audit officer. |
| `sonar.bank.govt.physical_card.admin` | Issue/freeze/unfreeze physical cards. | Granted ROL govt bank officer. |
| `sonar.devops.bank.diagnostics` | Read bank_status + cron tick reports + bridges echo metrics. | Granted ROL DevOps. |

**Security Lead C-SEC-02 (ACE Matrix Spec H2)** ratifica matrix completa post-handoff Backend → Security. Backend Lead spec proposal default — Security Lead amends/extends si necesario.

### 2.3 Auth check boilerplate (cada callback)

```lua
-- Boilerplate first lines cada callback Bank Phase A:
lib.callback.register('sonar:bank:<entity>:<verb>', function(source, payload)
  -- A16: Early return BANK_DISABLED defensive
  if Bridges.BankStatus.IsDisabled() then
    return { status = 'error', error = { code = 'BANK_DISABLED', reason = GetResourceKvpString('sonar_bank_disabled') } }
  end

  -- A11 (v1.0.1 R1 H001 fix): Auth check server-side mandatory via canonical helpers.
  -- ⚠️ NUNCA usar `source.citizen_id` — anti-patrón AP-AUTH-1 prohibido (source es integer, no table).
  local auth = require('sonar_bridges/lib/auth_helpers')
  local citizen_id, err = auth.require_citizen(source)
  if not citizen_id then
    return { status = 'error', error = { code = err == 'CITIZEN_UNRESOLVED' and 'AUTH_REQUIRED' or err } }
  end

  -- Per-callback specific auth tier (use auth helpers, NUNCA inline source.citizen_id):
  -- (AUTH-OWNER) local ok, e = auth.require_owner(source, resource.owner_id); if not ok then return { error = { code = e } } end
  -- (AUTH-ROLE) if not IsPlayerAceAllowed(source, '<perm>') then return { error = { code = 'AUTH_ACE_DENIED' } } end
  -- (AUTH-OWNER_OR_PARTICIPANT) local ok, e = auth.require_participant(source, {resource.payer_id, resource.payee_id}); ...
  -- (AUTH-ROLE_OR_OWNER) local ok, scope, e = auth.require_role_or_owner(source, '<perm>', resource.owner_id); ...

  -- A12: Rate-limit check
  local rl_ok, rl_err = RateLimiter.check(citizen_id, '<callback_id>', <budget>)
  if not rl_ok then return { status = 'error', error = { code = 'RATE_LIMIT_EXCEEDED', retry_after_ms = rl_err.retry_after_ms } } end

  -- A13: Idempotency (mutations only). Bridges.UUID.v4 spec §5.6 PRNG multi-entropy (v1.0.1 R1 M002 fix).
  local idempotency_key = payload.idempotency_key or Bridges.UUID.v4()
  local cached = IdempotencyKeys.Lock(idempotency_key, '<callback_domain>', payload)
  if cached.replay then return cached.result end

  -- ... business logic + DB transaction + audit ledger + StateBag emit + NetEvent fire
  -- ... final IdempotencyKeys.Complete(idempotency_key, result)
end)
```

### 2.3.1 Auth helpers lib (NEW v1.0.1 R1 — H001 fix) — `sonar_bridges/lib/auth_helpers.lua`

**Mandatory canonical helpers** — todo callback DEBE usar estos en lugar de inline checks. Anti-patrón H001 prohibido.

```lua
-- sonar_bridges/lib/auth_helpers.lua (NEW BANK-BE.AMEND.1 H001 fix)
local M = {}

local function resolve_citizen(source)
  if type(source) ~= 'number' or source <= 0 then return nil, 'INVALID_SOURCE' end
  local cid = Bridges.Player.GetCitizenId(source)
  if not cid or cid == '' then return nil, 'CITIZEN_UNRESOLVED' end
  return cid, nil
end

function M.require_citizen(source)
  -- Returns citizen_id or nil + error_code. Use as: local cid, err = auth.require_citizen(source); if not cid then return ... end
  return resolve_citizen(source)
end

function M.require_owner(source, owner_id)
  -- Returns true | false + error_code.
  local cid, err = resolve_citizen(source)
  if not cid then return false, err end
  if cid ~= owner_id then return false, 'AUTH_FORBIDDEN' end
  return true, nil
end

function M.require_participant(source, allowed_ids)
  -- allowed_ids: array of citizen_id strings (e.g. {payer_id, payee_id}).
  local cid, err = resolve_citizen(source)
  if not cid then return false, err end
  for _, allowed in ipairs(allowed_ids) do
    if cid == allowed then return true, nil end
  end
  return false, 'AUTH_FORBIDDEN'
end

function M.require_role_or_owner(source, ace_perm, owner_id)
  if IsPlayerAceAllowed(source, ace_perm) then return true, 'role', nil end
  local cid, err = resolve_citizen(source)
  if not cid then return false, nil, err end
  if cid == owner_id then return true, 'owner', nil end
  return false, nil, 'AUTH_FORBIDDEN'
end

return M
```

**Anti-patrón AP-AUTH-1 (H001 root cause — v1.0.1 R1 prohibición explícita):**
```lua
-- ❌ NUNCA. source es integer, source.citizen_id evalúa nil. Si owner_id también es nil (govt/system rows) → bypass.
if source.citizen_id == account.owner_id then ... end

-- ✅ SIEMPRE.
local ok, err = auth.require_owner(source, account.owner_id)
if not ok then return { status='error', error={ code=err } } end
```

### 2.3.2 Notational disclaimer (NEW v1.0.1 R1 — H001 fix)

A lo largo del §9 callback specifications, las descripciones textuales como _"source must equal payer (auto-derived from `source.citizen_id`)"_ o _"AUTH-OWNER (citizen_id default = `source.citizen_id`)"_ son **shorthand semántico**. **El código real DEBE usar `auth.require_*` helpers** §2.3.1 — NUNCA acceso directo `source.citizen_id`.

A partir de v1.0.1 R1, todas estas descripciones se reescriben como `Bridges.Player.GetCitizenId(source)` o invocación helper canónica para evitar ambigüedad.

---

## 3. Error codes registry canonical (A15)

### 3.1 Tabla canonical

| Code | HTTP-equivalent | Descripción | Retryable | Notes |
|---|---|---|---|---|
| `OK` | 200 | Success. | N/A | Implicit when status='ok'. |
| `BANK_DISABLED` | 503 | `Bridges.BankStatus.IsDisabled()` returned true. | NO (until admin recovery) | Per A16 defensive. |
| `AUTH_REQUIRED` | 401 | Source not connected o citizen_id no resolvable. | NO | Reconnect first. |
| `AUTH_FORBIDDEN` | 403 | Owner check failed. | NO | Wrong user. |
| `AUTH_ACE_DENIED` | 403 | ACE permission denied. | NO | Need role grant. |
| `PLAYER_NOT_LOADED` | 423 | Player source existe pero framework PlayerData no cargada (PRE-PlayerLoaded race). | YES (event-driven) | Hint en error data: `{ retry_after_event = '<framework-specific>' }`. Caller subscribe a PlayerLoaded antes de retry. NEW Q8 R2 v1.0.2 R2. Diferencia vs `RESOURCE_NOT_FOUND` que cubre source inexistente (player dropped, invalid handle); `PLAYER_NOT_LOADED` cubre source válido pero `Bridges.Identity.IsLoaded(source) == false`. |
| `RATE_LIMIT_EXCEEDED` | 429 | Token bucket empty. | YES | Retry after `retry_after_ms`. |
| `IDEMPOTENCY_INFLIGHT` | 409 | Same idempotency_key in `locked` state >1s. | YES | Retry timeout. |
| `VALIDATION_FAIL` | 400 | Schema validation fail (missing field / type mismatch / out-of-range). | NO | Fix payload. |
| `INSUFFICIENT_FUNDS` | 422 | Balance < amount required. | YES (post fund) | UX hint deposit/transfer in. |
| `INSUFFICIENT_QUORUM` | 422 | Multi-signer M-of-N not yet reached. | YES (post sign) | Wait more signers. |
| `INVALID_TRANSITION` | 422 | FSM transition not whitelisted from current state. | NO | UX should never propose invalid transition. |
| `INVALID_ACCOUNT_CLASS` | 422 | Operation incompatible con account_class (e.g. transfer FROM 'escrow' direct). | NO | UX guard. |
| `RESOURCE_NOT_FOUND` | 404 | Entity ID inexistent. | NO | Stale UI cache. |
| `RESOURCE_LOCKED` | 423 | Entity locked por otra operation in flight (e.g. escrow being released). | YES | Retry short. |
| `LIMIT_EXCEEDED_DAILY` | 429 | Daily transfer limit hit. | YES (next day) | UX show limit info. |
| `LIMIT_EXCEEDED_MONTHLY` | 429 | Monthly limit. | YES (next month) | mismo. |
| `COMPLIANCE_FLAG_BLOCK` | 451 | Active compliance flag blocks operation (e.g. frozen account). | NO | Resolve flag first. |
| `EXTERNAL_DEPENDENCY_FAIL` | 502 | DB transaction commit fail. | YES | Server hiccup. |
| `INTERNAL_SERVER_ERROR` | 500 | Unhandled exception. | YES | Log_error captured. |
| `UNSUPPORTED_PHASE_A` | 501 | Feature deferred Phase B+. | NO | UX disable button. |

### 3.2 Pattern response shape canonical

```typescript
interface CallbackResponseSuccess<T> {
  status: 'ok';
  data: T;
  correlation_id: string;       // UUIDv4 echoed back
  idempotency_replay?: boolean; // true si cached replay
}

interface CallbackResponseError {
  status: 'error';
  error: {
    code: string;               // ENUM canonical §3.1
    message?: string;           // human-readable optional (i18n via Frontend)
    retry_after_ms?: number;    // for RATE_LIMIT_EXCEEDED + IDEMPOTENCY_INFLIGHT
    field?: string;             // for VALIDATION_FAIL — specific field
    details?: Record<string, unknown>;
  };
  correlation_id: string;
}
```

---

## 4. Rate-limit framework (A12)

### 4.1 Token bucket pattern

`sonar_bridges/lib/rate_limiter.lua` (NEW BANK-BE.1 commitment):

```lua
-- Token bucket per (citizen_id, callback_id) tuple.
-- Refill rate + capacity configurables vía convars.

function RateLimiter.check(citizen_id, callback_id, budget)
  -- budget: { capacity = 10, refill_rate_per_sec = 1 } (ejemplo)
  local key = citizen_id .. ':' .. callback_id
  local bucket = RateLimiter._buckets[key] or { tokens = budget.capacity, last_refill_ms = GetGameTimer() }

  -- Refill
  local now = GetGameTimer()
  local elapsed_sec = (now - bucket.last_refill_ms) / 1000
  bucket.tokens = math.min(budget.capacity, bucket.tokens + elapsed_sec * budget.refill_rate_per_sec)
  bucket.last_refill_ms = now

  if bucket.tokens >= 1 then
    bucket.tokens = bucket.tokens - 1
    RateLimiter._buckets[key] = bucket
    return true, nil
  else
    local retry_after_ms = math.ceil((1 - bucket.tokens) / budget.refill_rate_per_sec * 1000)
    return false, { retry_after_ms = retry_after_ms }
  end
end
```

### 4.2 Budget defaults Bank Phase A

| Budget tier | Capacity | Refill rate | Use case |
|---|---|---|---|
| **HIGH** | 30 | 5/sec | Reads idempotentes (e.g. `account.getInfo`, `tax.getBrackets`). |
| **NORMAL** | 10 | 1/sec | Mutations standard (transfers + savings ops + escrow ops). |
| **LOW** | 3 | 0.2/sec (1 per 5s) | Mutations costly (loan apply + business approval create + recurring create). |
| **ADMIN** | 5 | 0.5/sec | Admin operations (tax bracket update + subsidy grant + loan decide). |
| **CRITICAL** | 2 | 0.1/sec (1 per 10s) | Security-sensitive (PIN verify + pin fail counter sensitive). |

Convars override:
```
set sonar_bank_ratelimit_high_capacity 30
set sonar_bank_ratelimit_high_refill 5
... (per tier)
```

### 4.3 Anti-abuse considerations

- **Per-citizen_id**, NOT per-source — reconnect doesn't reset bucket.
- **Persistent across sessions optional Phase B** (Phase A: in-memory RAM, reset on resource restart).
- **Whitelist DevOps override** via ACE `sonar.devops.bank.ratelimit.bypass` (Phase B).

---

## 5. Idempotency framework (A10 + A13)

### 5.1 Storage spec (DB persistent + result_payload cached)

`sonar_bank_idempotency_keys` (migration 028):

```sql
CREATE TABLE sonar_bank_idempotency_keys (
  key_id VARCHAR(64) PRIMARY KEY,           -- UUIDv4 from client OR server-generated
  domain VARCHAR(64) NOT NULL,              -- e.g. 'bank.transfer', 'bank.escrow.release'
  state ENUM('locked', 'completed', 'failed') NOT NULL DEFAULT 'locked',
  payload_hash VARCHAR(64),                 -- sha256 of input payload (de-dup deterministic)
  result_payload JSON,                      -- cached response for replay
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  ttl_expires_at DATETIME NOT NULL,         -- created_at + 7 days (cron purge)
  INDEX idx_ttl (ttl_expires_at),
  INDEX idx_domain (domain, state)
);
```

### 5.2 Library interface

```lua
-- sonar_bridges/lib/idempotency_keys.lua

function IdempotencyKeys.Lock(key, domain, payload)
  -- INSERT IGNORE row with state='locked'
  -- Returns: { replay = boolean, result = {...} | nil, fresh = boolean }
end

function IdempotencyKeys.Complete(key, result_payload)
  -- UPDATE state='completed', result_payload=JSON_serialize(payload)
end

function IdempotencyKeys.Fail(key, error_payload)
  -- UPDATE state='failed', result_payload=JSON_serialize(error)
end
```

### 5.3 Replay logic (Q-BE-pre-06 founder approved)

| Current state | 2nd call same key | Behavior |
|---|---|---|
| `locked` | Wait short (50ms) + recheck. If still `locked` >1s → return `IDEMPOTENCY_INFLIGHT`. | Defensive — caller must retry timeout. |
| `completed` | Return cached `result_payload` directly. | NO recompute. NO new side effects. |
| `failed` | Return cached error payload. | NO retry — caller must use NEW key for retry attempt. |

### 5.4 Cron TTL purge

`sonar_bank_app/server/cron_idempotency_purge.lua` — daily tick removes rows `ttl_expires_at < NOW()`. DevOps Lead C-DO-* spec coordinates schedule.

### 5.5 Mandatory vs optional per callback

- **Mutations** (transfer + escrow ops + savings ops + loans + recurring + cards + business approvals): **idempotency_key MANDATORY** (auto-generated server-side if client omits).
- **Reads idempotentes** (account.getInfo + tax.getBrackets + audit.query): idempotency_key OPTIONAL — natural idempotente sin DB write.
- **Reads paginated cursor-based** (audit.query + transactions list): idempotency_key OPTIONAL pero cursor-based pagination recomendado para consistencia.

### 5.6 PRNG entropy spec (NEW v1.0.1 R1 — M002 fix)

`Bridges.UUID.v4()` (`@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md` §3.3.1 v1.0.1 R1) es la **única source canónica** de UUIDs en SONAR Bank — correlation_id (CP2 mutex), idempotency_key fallback (§5.2), audit hook correlation_id, sentinel signatures (C-BE-04 §4.2 H003).

- **PRNG:** combinación de 4 entropy sources mixed via SHA256 — `os.clock()` + `GetGameTimer()` + `os.time()*1000` + per-call `GetPlayerPing(source)` (or `math.random` reseeded). Output 8-4-4-4-12 hex (RFC 4122 v4).
- **Rationale:** `math.random()` plain en FiveM Lua usa seed estática inicial (predictable post-boot) → riesgo CSPRNG insuficiente para correlation-id mutex (CP2). Mixing 4 sources eleva entropy efectiva y previene predicción adversaria por resource cheat que llame `Bridges.UUID.v4()` paralelo intentando colisión.
- **Anti-patrón AP-UUID-1 prohibido (M002 root cause):** `math.random` directo sin re-seed, naïve `string.format('%x...', math.random(), ...)`, external no-canonical lib.
- **Phase B target:** migrar a FFI crypto nativo si disponible vía oxmysql/lua-crypto bindings.

---

## 6. Side effects taxonomy (A14)

### 6.1 Categorías side effects per callback

Cada callback documenta explícitamente sus side effects en estas categorías:

1. **DB writes** — tablas afectadas + INSERT/UPDATE/DELETE counts.
2. **StateBag emits** — keys publicadas (CP1-A) post-commit. **⚠️ v1.0.1 R1 M004:** `bank.balance.<cid>` y `bank.savings.<cid>` REMOVIDOS de CP1-A — financial PII tier — migrated a CP1-B NetEvent `sonar:bank:balance:update` / `sonar:bank:savings:update` via helper canonical `publish_balance_update(cid, balance, account_class, opts)` (per `c_be_05` §2.2.1). Toda referencia §9 a "StateBag emits: `bank.balance.<cid>`" debe leerse como "NetEvent fire `sonar:bank:balance:update` → owner source via `publish_balance_update()`" — versión textual literal §9 preservada por trazabilidad histórica + amendment changelog §13.
3. **NetEvents fired** — events emitted (server→client público + server→admin restringido + resource-internal).
4. **Audit ledger entries** — `sonar_bank_audit_ledger` rows appended (event_type + correlation_id + actor + payload).
5. **Cron triggers** — schedule new cron jobs (e.g. recurring tick post create).
6. **Cross-resource events** — `AddEventHandler` listeners notified.
7. **Compliance autoraise** — flag patterns triggered (Security Lead C-SEC-03 spec).
8. **Idempotency state transitions** — `locked → completed | failed`.

### 6.2 Audit ledger event_type ENUM (canonical Phase A)

```
movement_recorded          -- DB INSERT sonar_bank_movements
transfer_completed         -- C001 success
escrow_created             -- C007
escrow_funded              -- C009 (FSM transition pending_funding → funded)
escrow_released            -- C010 (FSM transition funded/disputed → released_partial/full)
escrow_disputed            -- C011
escrow_refunded            -- C012
loan_applied               -- C019
loan_decided               -- C020
loan_repayment_recorded    -- C021
loan_defaulted             -- Cron tick FSM transition
recurring_created          -- C027
recurring_cancelled        -- C028
recurring_tick_failed      -- Cron FSM transition
card_pin_set               -- C033
card_pin_failure           -- C034 (autoraise possible)
card_state_changed         -- FSM transitions
elections_phase_changed    -- FSM #5
business_approval_created  -- C040
business_approval_resolved -- FSM #6
status_transition          -- FSM #7 sonar_bank_status
reconciliation_auto_applied
```

**Shape canonical per event_type** — para audit hooks críticos (HIGH+ severity) la shape mandatory está definida en `@docs/technical/08_audit_hooks.md` §1.2 C-SEC-01 spec (v1.0.1 R1 H006 reforzado). Backend Lead implementations DEBEN cumplir shape mínima — e.g. `compliance_flag_resolved` MUST include `previous_flag_snapshot` (forensics tamper detection). Diferencias requieren amendment formal Round.

```text
-- (canonical ENUM continúa abajo si más event_types existen)
reconciliation_flagged
compliance_flag_raised
compliance_flag_resolved
admin_tax_brackets_updated
admin_subsidy_granted
admin_force_action         -- generic admin override path
```

---

## 7. Performance budgets per callback (A17)

### 7.1 Budget tiers

| Tier | p99 target | Use case |
|---|---|---|
| **FAST** | <50ms | Reads cached (StateBag-backed o mem cache). |
| **STANDARD** | <200ms | Reads DB single-row + simple mutations single-table UPDATE. |
| **MEDIUM** | <500ms | Mutations multi-table (transfer + escrow create + business approval). |
| **SLOW** | <1500ms | Heavy operations (audit query paginada + Stocks.RecomputeHoldings + business approval execute). |
| **BACKGROUND** | <5000ms | Async cron jobs (no client-facing). |

### 7.2 Verification path

DevOps Lead C-DO-01 smoke test harness verifica per-callback p99 contra budget. Si exceeded → regression flag. Backend Lead Q-BE-pre-08 Opción C harness Lua + mock oxmysql produce estimación fundada para budget assignment.

---

## 8. Catálogo callbacks Bank Phase A (~40 — full detail §9)

| ID | Event name | Auth tier | Rate-limit | Idempotency | Perf tier | FSM ref | Status |
|---|---|---|---|---|---|---|---|
| **C001** | `sonar:bank:transfer` | AUTH-OWNER | NORMAL | YES mandatory | MEDIUM | — | ✅ §9.1 |
| **C001b** | `sonar:bank:balance:snapshot` (NEW v1.0.1 R1 M004) | AUTH-OWNER | HIGH | NO | FAST | — | ✅ §9.5b |
| **C002** | `sonar:bank:savings:deposit` | AUTH-OWNER | NORMAL | YES | MEDIUM | — | ✅ §9.2 |
| **C003** | `sonar:bank:savings:withdraw` | AUTH-OWNER | NORMAL | YES | MEDIUM | — | ✅ §9.3 |
| **C004** | `sonar:bank:account:getInfo` | AUTH-OWNER | HIGH | NO | FAST | — | ✅ §9.4 |
| **C005** | `sonar:bank:account:list` | AUTH-OWNER | HIGH | NO | FAST | — | ✅ §9.5 |
| **C006** | `sonar:bank:account:close` | AUTH-OWNER | LOW | YES | MEDIUM | — | ✅ §9.6 |
| **C007** | `sonar:bank:escrow:create` | AUTH-OWNER | LOW | YES | MEDIUM | FSM #1 | ✅ §9.7 |
| **C008** | `sonar:bank:escrow:getDetail` | AUTH-OWNER_OR_PARTICIPANT | HIGH | NO | STANDARD | FSM #1 | ✅ §9.8 |
| **C009** | `sonar:bank:escrow:fund` | AUTH-OWNER | NORMAL | YES | MEDIUM | FSM #1 | ✅ §9.9 |
| **C010** | `sonar:bank:escrow:release` | AUTH-OWNER_OR_PARTICIPANT | NORMAL | YES | MEDIUM | FSM #1 | ✅ §9.10 |
| **C011** | `sonar:bank:escrow:dispute` | AUTH-OWNER_OR_PARTICIPANT | LOW | YES | STANDARD | FSM #1 | ✅ §9.11 |
| **C012** | `sonar:bank:escrow:refund` | AUTH-ROLE (`sonar.bank.govt.escrow.admin`) | ADMIN | YES | MEDIUM | FSM #1 | ✅ §9.12 |
| **C013** | `sonar:bank:tax:getBrackets` | AUTH-PUBLIC | HIGH | NO | FAST | — | ✅ §9.13 |
| **C014** | `sonar:bank:tax:calculate` | AUTH-OWNER | HIGH | NO | FAST | — | ✅ §9.14 |
| **C015** | `sonar:bank:tax:setBrackets` | AUTH-ROLE (`sonar.bank.govt.tax.write`) | ADMIN | YES | STANDARD | — | ✅ §9.15 |
| **C016** | `sonar:bank:subsidy:grant` | AUTH-ROLE (`sonar.bank.govt.subsidy.write`) | ADMIN | YES | MEDIUM | — | ✅ §9.16 |
| **C017** | `sonar:bank:subsidy:list` | AUTH-PUBLIC | HIGH | NO | FAST | — | ✅ §9.17 |
| **C018** | `sonar:bank:subsidy:claim` | AUTH-OWNER | NORMAL | YES | MEDIUM | — | ✅ §9.18 |
| **C019** | `sonar:bank:loan:apply` | AUTH-OWNER | LOW | YES | MEDIUM | FSM #2 | ✅ §9.19 |
| **C020** | `sonar:bank:loan:decide` | AUTH-ROLE (`sonar.bank.govt.loan.admin`) | ADMIN | YES | MEDIUM | FSM #2 | ✅ §9.20 |
| **C021** | `sonar:bank:loan:repay` | AUTH-OWNER | NORMAL | YES | MEDIUM | FSM #2 | ✅ §9.21 |
| **C022** | `sonar:bank:stocks:list` | AUTH-PUBLIC | HIGH | NO | FAST | — | ✅ §9.22 |
| **C023** | `sonar:bank:stocks:buy` | AUTH-OWNER | NORMAL | YES | MEDIUM | — | ✅ §9.23 |
| **C024** | `sonar:bank:stocks:sell` | AUTH-OWNER | NORMAL | YES | MEDIUM | — | ✅ §9.24 |
| **C025** | `sonar:bank:stocks:getPortfolio` | AUTH-OWNER | HIGH | NO | STANDARD | — | ✅ §9.25 |
| **C026** | `sonar:bank:stocks:recomputeHoldings` | AUTH-ROLE (`sonar.devops.bank.diagnostics`) o cron | ADMIN | YES | SLOW | — | ✅ §9.26 |
| **C027** | `sonar:bank:recurring:create` | AUTH-OWNER | LOW | YES | MEDIUM | FSM #3 | ✅ §9.27 |
| **C028** | `sonar:bank:recurring:cancel` | AUTH-OWNER | NORMAL | YES | STANDARD | FSM #3 | ✅ §9.28 |
| **C029** | `sonar:bank:crypto:list` | AUTH-PUBLIC | HIGH | NO | FAST | — | ✅ §9.29 |
| **C030** | `sonar:bank:crypto:swap` | AUTH-OWNER | NORMAL | YES | MEDIUM | — | ✅ §9.30 |
| **C031** | `sonar:bank:atm:getMinigameSession` | AUTH-OWNER | NORMAL | YES | STANDARD | — | ✅ §9.31 |
| **C032** | `sonar:bank:card:requestPhysical` | AUTH-OWNER | LOW | YES | MEDIUM | FSM #4 | ✅ §9.32 |
| **C033** | `sonar:bank:card:setPin` | AUTH-OWNER | NORMAL | YES | STANDARD | FSM #4 | ✅ §9.33 |
| **C034** | `sonar:bank:card:verifyPin` | AUTH-OWNER | CRITICAL | NO (rate-limited tighter) | STANDARD | FSM #4 | ✅ §9.34 |
| **C035** | `sonar:bank:audit:query` | AUTH-ROLE_OR_OWNER (per scope Q13) | NORMAL | NO | SLOW | — | ✅ §9.35 |
| **C036** | `sonar:bank:compliance:listFlags` | AUTH-OWNER | HIGH | NO | STANDARD | — | ✅ §9.36 |
| **C037** | `sonar:bank:compliance:queryDetail` | AUTH-ROLE (`sonar.bank.govt.compliance.admin`) | ADMIN | NO | STANDARD | — | ✅ §9.37 |
| **C038** | `sonar:bank:compliance:resolveFlag` | AUTH-ROLE (`sonar.bank.govt.compliance.admin`) | ADMIN | YES | STANDARD | — | ✅ §9.38 |
| **C039** | `sonar:bank:business:treasuryGet` | AUTH-OWNER (employee/owner) | HIGH | NO | FAST | — | ✅ §9.39 |
| **C040** | `sonar:bank:business:approvalCreate` | AUTH-OWNER (initiator role) | LOW | YES | MEDIUM | FSM #6 | ✅ §9.40 |

**Total: 40 callbacks ratified Phase A.**

---

## 9. Callback specifications canonical (full detail per Q-BE-pre-04 granular)

> **Format estructura per callback** (mandatory cumplimiento per directriz founder BANK-BE.1):
>
> 1. **Event name + ID + Auth tier** (resumen tabla §8).
> 2. **Request schema** — payload shape TypeScript-style.
> 3. **Response schema** — success + error variants.
> 4. **Auth check details** (server-side validation specifics).
> 5. **Rate-limit budget** (tier per §4.2 + override convars).
> 6. **Idempotency** (key generation + replay behavior).
> 7. **Side effects** (DB + StateBag + NetEvent + audit + compliance).
> 8. **Error codes possible** (subset registry §3.1).
> 9. **Performance target** (perf tier per §7.1).
> 10. **Test scenarios** (happy + auth fail + rate limit + idempotency replay + concurrent + edge cases).

### 9.1 C001 — `sonar:bank:transfer`

#### 9.1.1 Identifier

- **Event name:** `sonar:bank:transfer`
- **Auth tier:** AUTH-OWNER (payer must be `Bridges.Player.GetCitizenId(source)`).
- **FSM ref:** — (no direct FSM, but emits `transfer:complete` event Tier 1).

#### 9.1.2 Request schema

```typescript
interface TransferRequest {
  to_iban: string;                  // payee IBAN canonical (Q-DB-D format)
  amount: number;                   // DECIMAL atomic (e.g. 1234.56)
  reason: string;                   // 1-200 chars, sanitized server-side
  idempotency_key?: string;         // UUIDv4 — auto-generated if missing
  correlation_id?: string;          // UUIDv4 — auto-generated
  account_class?: 'main' | 'savings'; // default 'main'
  metadata?: Record<string, unknown>;
}
```

#### 9.1.3 Response schema

```typescript
// Success
interface TransferResponseSuccess {
  status: 'ok';
  data: {
    movement_id_payer: number;
    movement_id_payee: number;
    balance_after_payer: number;
    balance_after_payee?: number;     // omitted if cross-server payee unknown
    correlation_id: string;
    occurred_at: number;              // epoch ms
  };
  correlation_id: string;
  idempotency_replay?: boolean;
}

// Errors possible: BANK_DISABLED | AUTH_REQUIRED | AUTH_FORBIDDEN | RATE_LIMIT_EXCEEDED |
//                  IDEMPOTENCY_INFLIGHT | VALIDATION_FAIL | INSUFFICIENT_FUNDS |
//                  RESOURCE_NOT_FOUND (payee IBAN) | LIMIT_EXCEEDED_DAILY |
//                  COMPLIANCE_FLAG_BLOCK (frozen account) | EXTERNAL_DEPENDENCY_FAIL
```

#### 9.1.4 Auth check details

- `citizen_id` resolved via `auth.require_citizen(source)` helper §2.3.1 (v1.0.1 R1 H001).
- Payer account ownership: `sonar_bank_accounts.owner_id == citizen_id AND owner_type = 'citizen'` (use `auth.require_owner(source, account.owner_id)`).
- Payee account existence: `sonar_bank_accounts.iban == payload.to_iban` row exists.
- Self-transfer guard: `payer_iban != to_iban` (returns `VALIDATION_FAIL` field=`to_iban`).

#### 9.1.5 Rate-limit budget

- Tier: **NORMAL** (capacity 10, refill 1/sec).
- Convar overrides: `sonar_bank_ratelimit_normal_capacity` / `sonar_bank_ratelimit_normal_refill`.

#### 9.1.6 Idempotency

- **Mandatory.** Auto-generated UUIDv4 if client omits.
- Domain: `bank.transfer`.
- Replay completed → return cached `{ movement_id_payer, movement_id_payee, balance_after_payer, ... }` (NO new side effects).
- Replay failed → return cached error.

#### 9.1.7 Side effects

1. **DB writes (atomic transaction):**
   - `UPDATE sonar_bank_accounts SET balance = balance - amount WHERE id = payer_account_id`.
   - `UPDATE sonar_bank_accounts SET balance = balance + amount WHERE id = payee_account_id`.
   - `INSERT INTO sonar_bank_movements (citizen_id, amount, category='transfer_out', ...) → movement_id_payer`.
   - `INSERT INTO sonar_bank_movements (citizen_id, amount, category='transfer_in', ...) → movement_id_payee`.
2. **StateBag emits (CP1-A post-commit):**
   - `GlobalState['bank.balance.<payer_citizen_id>'] = new_payer_balance`.
   - `GlobalState['bank.balance.<payee_citizen_id>'] = new_payee_balance`.
3. **NetEvents fired:**
   - `sonar:bank:transfer:complete` → payer_source + payee_source (Tier 1).
4. **Resource-internal events:**
   - `sonar:bank:internal:movementRecorded` × 2 (payer + payee).
5. **Audit ledger entries:**
   - 1 entry `event_type='transfer_completed'` con correlation_id + amount + payer_id + payee_id + reason.
6. **Compliance autoraise:**
   - Security Lead C-SEC-03 patterns invoked (large_transfer if amount > €10k, velocity if recent transfers > N in window).
7. **Round-Up hook:**
   - `sonar:bank:internal:roundUpAccrued` (if Round-Up enabled) → auto-deposit savings delta.
8. **Idempotency state:**
   - `IdempotencyKeys.Lock` → `Complete` post-success.

#### 9.1.8 Error codes possible

`BANK_DISABLED` / `AUTH_REQUIRED` / `AUTH_FORBIDDEN` / `RATE_LIMIT_EXCEEDED` / `IDEMPOTENCY_INFLIGHT` / `VALIDATION_FAIL` / `INSUFFICIENT_FUNDS` / `RESOURCE_NOT_FOUND` / `LIMIT_EXCEEDED_DAILY` / `LIMIT_EXCEEDED_MONTHLY` / `COMPLIANCE_FLAG_BLOCK` / `EXTERNAL_DEPENDENCY_FAIL`.

#### 9.1.9 Performance target

- Tier: **MEDIUM** — p99 <500ms.
- Hot path: 4 DB writes (atomic) + 2 StateBag emits + 1 NetEvent + 1 audit ledger INSERT + compliance autoraise checks.

#### 9.1.10 Test scenarios

- **Happy:** transfer €100 payer→payee, balances update, NetEvent fired, audit ledger entry exists.
- **Auth fail:** source != owner of from_iban → `AUTH_FORBIDDEN`.
- **Rate limit:** 11 transfers in 1 sec → 11th returns `RATE_LIMIT_EXCEEDED`.
- **Idempotency replay:** same key 2nd call → cached result returned, NO new side effects.
- **Insufficient funds:** payer balance < amount → `INSUFFICIENT_FUNDS`, no DB writes.
- **Concurrent:** 2 simultaneous transfers same payer → atomic DB serialization (one wins, one waits + retries or returns).
- **Self-transfer:** to_iban == from_iban → `VALIDATION_FAIL`.
- **Compliance flag block:** payer account frozen → `COMPLIANCE_FLAG_BLOCK`.
- **Large transfer audit:** amount > €10k → autoraise `large_transfer` flag (Security Lead pattern).

---

### 9.2 C002 — `sonar:bank:savings:deposit`

#### 9.2.1 Identifier
- Event: `sonar:bank:savings:deposit`. Auth: AUTH-OWNER. FSM: —.

#### 9.2.2 Request schema
```typescript
interface SavingsDepositRequest {
  amount: number;                 // DECIMAL atomic, > 0
  idempotency_key?: string;
  correlation_id?: string;
}
```

#### 9.2.3 Response schema
```typescript
// Success
{ status: 'ok', data: { movement_id, balance_main_after, balance_savings_after, correlation_id, occurred_at }, ... }
// Errors: BANK_DISABLED | AUTH_REQUIRED | RATE_LIMIT_EXCEEDED | IDEMPOTENCY_INFLIGHT | VALIDATION_FAIL | INSUFFICIENT_FUNDS | EXTERNAL_DEPENDENCY_FAIL
```

#### 9.2.4 Auth check
- Owner check: `account_class='main'` + `account_class='savings'` rows owned por `Bridges.Player.GetCitizenId(source)` (via `auth.require_owner` helper §2.3.1).
- Both accounts must exist (auto-create savings if missing — Phase A decision per Q-DB-D).

#### 9.2.5 Rate-limit
- Tier: **NORMAL**.

#### 9.2.6 Idempotency
- Mandatory. Domain: `bank.savings.deposit`.

#### 9.2.7 Side effects
1. **DB atomic:** UPDATE main balance -= amount, UPDATE savings balance += amount, INSERT 2 movements (`category='savings_deposit_out'` + `'savings_deposit_in'`).
2. **CP1-B NetEvent emit (v1.0.1 R1 M004):** `publish_balance_update(cid, balance_main_after, 'main', {correlation_id})` + `publish_balance_update(cid, balance_savings_after, 'savings', {correlation_id})` — replaces deprecated CP1-A `bank.balance.<cid>` + `bank.savings.<cid>` StateBag writes.
3. **NetEvents:** `sonar:bank:savings:depositComplete` → owner.
4. **Resource-internal:** `sonar:bank:internal:movementRecorded` × 2.
5. **Audit ledger:** `event_type='savings_deposit'` entry.
6. **Idempotency state:** Lock → Complete.

#### 9.2.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `RATE_LIMIT_EXCEEDED` / `IDEMPOTENCY_INFLIGHT` / `VALIDATION_FAIL` (amount ≤ 0) / `INSUFFICIENT_FUNDS` / `EXTERNAL_DEPENDENCY_FAIL`.

#### 9.2.9 Performance
- Tier: **MEDIUM** — p99 <500ms.

#### 9.2.10 Test scenarios
- Happy + auth fail (other citizen) + rate limit + idempotency replay + insufficient main balance + concurrent + amount=0 invalid + amount negative invalid.

---

### 9.3 C003 — `sonar:bank:savings:withdraw`

#### 9.3.1-9.3.10 Spec

Symmetric to C002 with sign reversed (savings → main). Same auth + rate-limit + idempotency + perf + errors. Side effect difference: balances move opposite direction. Movement categories `'savings_withdraw_out'` + `'savings_withdraw_in'`. NetEvent: `sonar:bank:savings:withdrawComplete`. Audit `event_type='savings_withdraw'`.

Additional error: `INSUFFICIENT_FUNDS` checks **savings balance** (not main).

---

### 9.4 C004 — `sonar:bank:account:getInfo`

#### 9.4.1 Identifier
- Auth: AUTH-OWNER. FSM: —.

#### 9.4.2 Request schema
```typescript
interface AccountGetInfoRequest {
  account_class?: 'main' | 'savings' | 'business_treasury' | 'crypto_wallet';  // default 'main'
  company_id?: string;            // CHAR(36) — required if account_class='business_treasury'
}
```

#### 9.4.3 Response schema
```typescript
// Success
{ status: 'ok', data: { account_id, iban, balance, account_class, owner_type, owner_id, currency, opened_at, last_movement_at }, ... }
// Errors: BANK_DISABLED | AUTH_REQUIRED | AUTH_FORBIDDEN | RATE_LIMIT_EXCEEDED | RESOURCE_NOT_FOUND | VALIDATION_FAIL
```

#### 9.4.4 Auth check
- AUTH-OWNER citizen accounts. AUTH-OWNER (employee role) for business_treasury accounts.

#### 9.4.5 Rate-limit
- Tier: **HIGH** — read idempotente.

#### 9.4.6 Idempotency
- Optional (read).

#### 9.4.7 Side effects
- NO mutations. Read-only.

#### 9.4.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `AUTH_FORBIDDEN` / `RATE_LIMIT_EXCEEDED` / `RESOURCE_NOT_FOUND` / `VALIDATION_FAIL`.

#### 9.4.9 Performance
- Tier: **FAST** — p99 <50ms (StateBag-backed o single-row DB query).

#### 9.4.10 Test scenarios
- Happy + auth fail (other citizen) + business_treasury auth (employee role) + non-existent account_class for owner.

---

### 9.5 C005 — `sonar:bank:account:list`

Returns all accounts owned by `Bridges.Player.GetCitizenId(source)` (across account_classes). AUTH-OWNER. Rate HIGH. Read-only. p99 <50ms (multi-row DB query small N).

#### Request: `{ }` (empty payload — derives from source).

#### Response: `{ status: 'ok', data: { accounts: [{ account_id, iban, balance, account_class, currency, opened_at }, ...] } }`.

#### Test scenarios: happy (citizen with multi-account) + happy (citizen no savings yet) + employee con business_treasury access (returns combined personal + business accounts).

---

### 9.5b C001b — `sonar:bank:balance:snapshot` (NEW v1.0.1 R1 — M004 cross-cutting)

#### 9.5b.1 Identifier
- **Event name:** `sonar:bank:balance:snapshot`
- **Auth tier:** AUTH-OWNER (returns own balances only — NO admin path; admin queries via C035 scope='govt_full' fire `:adminAudit` separately).
- **FSM ref:** — (read-only).

#### 9.5b.2 Request schema
```typescript
interface BalanceSnapshotRequest {
  correlation_id?: string;
}
```

#### 9.5b.3 Response schema
```typescript
{ status: 'ok', data: { main: number, savings: number, occurred_at: number, correlation_id: string } }
// Errors: BANK_DISABLED | AUTH_REQUIRED | RATE_LIMIT_EXCEEDED | RESOURCE_NOT_FOUND (no accounts row)
```

#### 9.5b.4 Auth check
- `auth.require_citizen(source)` helper §2.3.1 (returns own citizen_id only). NO `citizen_id` payload param accepted (prevents impersonation).

#### 9.5b.5 Rate-limit
- Tier: **HIGH** (read fallback path, low cost). Convar overrides: `sonar_bank_ratelimit_high_capacity` / `sonar_bank_ratelimit_high_refill`.

#### 9.5b.6 Idempotency
- Optional (read — natural idempotente).

#### 9.5b.7 Side effects
1. **DB:** SELECT `balance, account_class FROM sonar_bank_accounts WHERE owner_id = ? AND account_class IN ('main','savings')` — single query, 1-2 rows.
2. **NetEvent:** none (inline response only — NO `sonar:bank:balance:update` fire to avoid event storm; consumer reads inline data directly).
3. **Audit ledger:** none Phase A (read-only fallback path — do not pollute audit ledger). Phase B may add Tier-4 sampling.

#### 9.5b.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `RATE_LIMIT_EXCEEDED` / `RESOURCE_NOT_FOUND` (no accounts row — atypical, suggests citizen never bootstrapped).

#### 9.5b.9 Performance
- Tier: **FAST** — p99 <30ms (single PK index lookup).

#### 9.5b.10 Test scenarios
- **Happy:** UI mount post-connect → returns current main + savings balances.
- **Auth fail:** non-resolvable source (citizen char not loaded) → `AUTH_REQUIRED`.
- **Idempotency-free:** 5 rapid calls → 5 successful responses (no idempotency state).
- **Rate-limit:** flood attempt → `RATE_LIMIT_EXCEEDED`.
- **No accounts row:** edge case (citizen pre-bootstrap) → `RESOURCE_NOT_FOUND` o defaults `{main:0, savings:0}` (Backend Lead default = `RESOURCE_NOT_FOUND`).
- **Race condition vs `:update`:** client receives snapshot + concurrent `:update` event → client implementation reconciles by `occurred_at` max (Frontend Lead C-FE-* spec).

**Use case (Frontend Lead C-FE-* mount lifecycle):**
```lua
-- Client UI mount fallback if `sonar:bank:balance:update` event lost during connect.
local snap = lib.callback.await('sonar:bank:balance:snapshot', false)
if snap and snap.status == 'ok' then
  SetNuiFocusKeepBalance(snap.data.main)
  SetNuiFocusKeepSavings(snap.data.savings)
end
-- Subsequent `sonar:bank:balance:update` events override snapshot value (event-driven post-mount).
```

**Cross-reference:** `c_be_05` §2.2.2 (M004 lazy-publish on `playerJoining` is primary path — C001b is fallback only).

---

### 9.6 C006 — `sonar:bank:account:close`

#### 9.6.1 Identifier
- Auth: AUTH-OWNER. FSM: — (Phase B mostly; Phase A close = soft-close redirect to main).

#### 9.6.2 Request schema
```typescript
interface AccountCloseRequest {
  account_class: 'savings' | 'crypto_wallet';  // 'main' NEVER closeable in Phase A. business_treasury via separate flow Phase B.
  redirect_to_account_class: 'main';            // mandatory — final balance redirected
  idempotency_key?: string;
  correlation_id?: string;
  reason?: string;
}
```

#### 9.6.3 Response schema
```typescript
// Success
{ status: 'ok', data: { account_id_closed, final_balance_redirected, balance_main_after }, ... }
// Errors: BANK_DISABLED | AUTH_REQUIRED | AUTH_FORBIDDEN | RATE_LIMIT_EXCEEDED | IDEMPOTENCY_INFLIGHT | VALIDATION_FAIL (account_class='main') | RESOURCE_NOT_FOUND
```

#### 9.6.4 Auth check
- Owner check + account_class != 'main' guard.

#### 9.6.5 Rate-limit
- Tier: **LOW** (close is rare + slow).

#### 9.6.6 Idempotency
- Mandatory. Domain: `bank.account.close`.

#### 9.6.7 Side effects
1. **DB atomic:** UPDATE main balance += closing balance, UPDATE closing account balance=0 + status='closed', INSERT 2 movements (`'account_close_out'` + `'account_close_in'`).
2. **CP1-B NetEvent emit (v1.0.1 R1 M004):** `publish_balance_update(cid, balance_main_after, 'main', {correlation_id})` + `publish_balance_update(cid, 0, '<closed_class>', {correlation_id})` (zero-out signal to consumer) — replaces deprecated CP1-A balance/savings StateBag writes.
3. **NetEvents:** `sonar:bank:account:closed` → owner + admin.
4. **Audit ledger:** `event_type='account_closed'` entry.
5. **Idempotency state:** Lock → Complete.

#### 9.6.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `AUTH_FORBIDDEN` / `RATE_LIMIT_EXCEEDED` / `IDEMPOTENCY_INFLIGHT` / `VALIDATION_FAIL` / `RESOURCE_NOT_FOUND` / `EXTERNAL_DEPENDENCY_FAIL`.

#### 9.6.9 Performance
- Tier: **MEDIUM** — p99 <500ms.

#### 9.6.10 Test scenarios
- Happy savings close + main close attempt (rejected) + non-existent account_class + replay idempotent.

---

### 9.7 C007 — `sonar:bank:escrow:create`

#### 9.7.1 Identifier
- Auth: AUTH-OWNER (payer). FSM #1 ref → state `pending_funding` initial.

#### 9.7.2 Request schema
```typescript
interface EscrowCreateRequest {
  payee_citizen_id: string;
  amount: number;                  // DECIMAL atomic, > 0
  reason: string;                  // 1-500 chars, sanitized
  expires_at?: number;             // epoch ms — optional. Default null (no expiry).
  idempotency_key?: string;
  correlation_id?: string;
  metadata?: Record<string, unknown>;
}
```

#### 9.7.3 Response schema
```typescript
// Success
{ status: 'ok', data: { escrow_id, state: 'pending_funding', amount, payee_citizen_id, expires_at, created_at, correlation_id }, ... }
// Errors: BANK_DISABLED | AUTH_REQUIRED | RATE_LIMIT_EXCEEDED | IDEMPOTENCY_INFLIGHT | VALIDATION_FAIL | RESOURCE_NOT_FOUND (payee) | COMPLIANCE_FLAG_BLOCK
```

#### 9.7.4 Auth check
- Source must equal payer (auto-derived via `auth.require_owner(source, escrow.payer_citizen_id)`).
- Payee citizen_id must exist in `sonar_citizens`.

#### 9.7.5 Rate-limit
- Tier: **LOW** (escrow create is heavy operation).

#### 9.7.6 Idempotency
- Mandatory. Domain: `bank.escrow.create`.

#### 9.7.7 Side effects
1. **DB:** INSERT `sonar_bank_escrows` (state='pending_funding', balance=0).
2. **StateBag emits:** NONE (escrow CP1-B per Q-BE-pre-03 — sensitive).
3. **NetEvents:**
   - `sonar:bank:escrow:created` → payer + payee.
4. **Audit ledger:** `event_type='escrow_created'` entry.
5. **Idempotency state:** Lock → Complete.

#### 9.7.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `RATE_LIMIT_EXCEEDED` / `IDEMPOTENCY_INFLIGHT` / `VALIDATION_FAIL` / `RESOURCE_NOT_FOUND` / `COMPLIANCE_FLAG_BLOCK` / `EXTERNAL_DEPENDENCY_FAIL`.

#### 9.7.9 Performance
- Tier: **MEDIUM** — p99 <500ms.

#### 9.7.10 Test scenarios
- Happy + payee invalid + amount ≤ 0 + replay idempotent + concurrent same payer.

---

### 9.8 C008 — `sonar:bank:escrow:getDetail`

Read escrow detail. AUTH-OWNER_OR_PARTICIPANT (payer/payee/admin). Rate HIGH. Read-only. p99 <200ms (single-row + releases log join).

Request: `{ escrow_id }`. Response: `{ status: 'ok', data: { escrow_id, payer_citizen_id, payee_citizen_id, amount, state, balance_remaining, releases: [...], dispute_reason?, expires_at, created_at } }`.

Errors: `BANK_DISABLED` / `AUTH_REQUIRED` / `AUTH_FORBIDDEN` / `RATE_LIMIT_EXCEEDED` / `RESOURCE_NOT_FOUND`.

Test scenarios: happy as payer + happy as payee + happy as admin + auth fail (random citizen) + non-existent escrow.

---

### 9.9 C009 — `sonar:bank:escrow:fund`

#### 9.9.1 Identifier
- Auth: AUTH-OWNER (payer only). FSM #1 transition `pending_funding → funded`.

#### 9.9.2 Request schema
```typescript
interface EscrowFundRequest {
  escrow_id: number;
  idempotency_key?: string;
  correlation_id?: string;
}
```

#### 9.9.3 Response schema
```typescript
{ status: 'ok', data: { escrow_id, state: 'funded', amount_funded, balance_after_payer, occurred_at }, ... }
// Errors: BANK_DISABLED | AUTH_REQUIRED | AUTH_FORBIDDEN | RATE_LIMIT_EXCEEDED | IDEMPOTENCY_INFLIGHT | INVALID_TRANSITION (escrow not in pending_funding) | INSUFFICIENT_FUNDS | RESOURCE_NOT_FOUND
```

#### 9.9.4 Auth check
- Payer match: `auth.require_owner(source, escrow.payer_citizen_id)` (helper §2.3.1).
- FSM transition guard: state == 'pending_funding'.

#### 9.9.5 Rate-limit
- Tier: **NORMAL**.

#### 9.9.6 Idempotency
- Mandatory. Domain: `bank.escrow.fund`.

#### 9.9.7 Side effects
1. **DB atomic:** UPDATE escrow.state='funded' + balance=amount, UPDATE payer balance -= amount, INSERT movement (`category='escrow_fund'`).
2. **CP1-B NetEvent emit (v1.0.1 R1 M004):** `publish_balance_update(payer_cid, payer_balance_after, 'main', {correlation_id})` — replaces deprecated CP1-A `bank.balance.<payer_cid>` StateBag write.
3. **NetEvents:**
   - `sonar:bank:escrow:funded` → payer + payee.
   - `sonar:bank:escrow:stateChanged` (CP1-B) → payer + payee + admin (ACE-checked).
4. **Resource-internal:**
   - `sonar:bank:internal:movementRecorded`.
   - `sonar:bank:internal:fsmTransition` (escrow_lifecycle pending_funding → funded).
5. **Audit ledger:** `event_type='escrow_funded'` entry.
6. **Compliance autoraise:** `large_transfer` if amount > €10k.
7. **Idempotency state:** Lock → Complete.

#### 9.9.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `AUTH_FORBIDDEN` / `RATE_LIMIT_EXCEEDED` / `IDEMPOTENCY_INFLIGHT` / `INVALID_TRANSITION` / `INSUFFICIENT_FUNDS` / `RESOURCE_NOT_FOUND` / `EXTERNAL_DEPENDENCY_FAIL`.

#### 9.9.9 Performance
- Tier: **MEDIUM** — p99 <500ms.

#### 9.9.10 Test scenarios
- Happy + auth fail (non-payer attempt) + INVALID_TRANSITION (already funded) + INSUFFICIENT_FUNDS + replay idempotent + concurrent fund same escrow (only 1 succeeds).

---

### 9.10 C010 — `sonar:bank:escrow:release`

#### 9.10.1 Identifier
- Auth: AUTH-OWNER_OR_PARTICIPANT (payer or payee or admin). FSM #1 transition `funded → released_partial | released_full` o `disputed → released_full | refunded`.

#### 9.10.2 Request schema
```typescript
interface EscrowReleaseRequest {
  escrow_id: number;
  amount: number;                  // DECIMAL atomic, > 0, ≤ balance_remaining
  mode: 'partial' | 'full';        // explicit even if amount === balance_remaining
  idempotency_key?: string;
  correlation_id?: string;
  release_reason?: string;
}
```

#### 9.10.3 Response schema
```typescript
{ status: 'ok', data: { escrow_id, amount_released, balance_remaining, state_new, occurred_at, correlation_id }, ... }
// Errors: BANK_DISABLED | AUTH_REQUIRED | AUTH_FORBIDDEN | RATE_LIMIT_EXCEEDED | IDEMPOTENCY_INFLIGHT | INVALID_TRANSITION | VALIDATION_FAIL (amount > balance_remaining) | RESOURCE_NOT_FOUND
```

#### 9.10.4 Auth check
- Source ∈ {payer, payee} OR admin (`sonar.bank.govt.escrow.admin`).
- Phase A consensus rule: payer-initiated release OK + payee-initiated release requires payer agreement (not implemented Phase A; payee can only request → defer Phase B).
- **Phase A simplification:** payer can release fully unilaterally + admin can release any amount. Payee initiates dispute (C011) instead of release directly.

#### 9.10.5 Rate-limit
- Tier: **NORMAL**.

#### 9.10.6 Idempotency
- Mandatory. Domain: `bank.escrow.release`.

#### 9.10.7 Side effects
1. **DB atomic:** INSERT releases log row, UPDATE escrow.balance -= amount + state per FSM table, UPDATE payee balance += amount, INSERT movements.
2. **CP1-B NetEvent emit (v1.0.1 R1 M004):** `publish_balance_update(payee_cid, payee_balance_after, 'main', {correlation_id})` — replaces deprecated CP1-A `bank.balance.<payee_cid>` StateBag write.
3. **NetEvents:**
   - `sonar:bank:escrow:released` → payer + payee.
   - `sonar:bank:escrow:stateChanged` (CP1-B) → admin observers + participants.
4. **Resource-internal:** `movementRecorded` + `fsmTransition` (escrow_lifecycle).
5. **Audit ledger:** `event_type='escrow_released'` entry.
6. **Idempotency state:** Lock → Complete.

#### 9.10.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `AUTH_FORBIDDEN` / `RATE_LIMIT_EXCEEDED` / `IDEMPOTENCY_INFLIGHT` / `INVALID_TRANSITION` / `VALIDATION_FAIL` / `RESOURCE_NOT_FOUND` / `EXTERNAL_DEPENDENCY_FAIL`.

#### 9.10.9 Performance
- Tier: **MEDIUM** — p99 <500ms.

#### 9.10.10 Test scenarios
- Happy partial + happy full + amount > remaining → VALIDATION_FAIL + auth fail (random citizen) + INVALID_TRANSITION (already released_full) + concurrent + admin force.

---

### 9.11 C011 — `sonar:bank:escrow:dispute`

#### 9.11.1-9.11.10 Spec resumido

Open dispute on escrow. AUTH-OWNER_OR_PARTICIPANT. Rate LOW. Idempotency mandatory. FSM transition `funded | released_partial → disputed`.

**Request:** `{ escrow_id, dispute_reason: string (1-1000 chars), idempotency_key?, correlation_id? }`.

**Response:** `{ status: 'ok', data: { escrow_id, state_new: 'disputed', dispute_reason, opened_by, opened_at } }`.

**Side effects:** UPDATE state + INSERT dispute_reason + audit `event_type='escrow_disputed'` + NetEvents `escrow:disputeOpened` (payer + payee + admin).

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_FORBIDDEN / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / INVALID_TRANSITION (state ∉ {funded, released_partial}) / VALIDATION_FAIL / RESOURCE_NOT_FOUND.

**Perf:** STANDARD <200ms. **Tests:** happy + auth fail + double-dispute + concurrent.

---

### 9.12 C012 — `sonar:bank:escrow:refund` (admin)

AUTH-ROLE `sonar.bank.govt.escrow.admin`. Rate ADMIN. Idempotency mandatory. FSM transition `funded | disputed → refunded`.

**Request:** `{ escrow_id, refund_reason: string (mandatory), idempotency_key?, correlation_id? }`.

**Response:** `{ status: 'ok', data: { escrow_id, amount_refunded, state_new: 'refunded', balance_after_payer } }`.

**Side effects:** DB atomic (UPDATE escrow.state='refunded' + balance=0, UPDATE payer balance += amount, INSERT movement `'escrow_refund'`) + **v1.0.1 R1 M004** `publish_balance_update(payer_cid, balance_after, 'main', opts)` (CP1-B NetEvent — replaces deprecated CP1-A `bank.balance.<payer_cid>` StateBag) + NetEvents `escrow:refunded` (payer + admin) + audit `event_type='escrow_refunded'` + `admin_force_action`.

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_ACE_DENIED / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / INVALID_TRANSITION / RESOURCE_NOT_FOUND.

**Perf:** MEDIUM <500ms. **Tests:** happy + non-admin attempt → AUTH_ACE_DENIED + INVALID_TRANSITION (already refunded).

---

### 9.13 C013 — `sonar:bank:tax:getBrackets`

AUTH-PUBLIC. Rate HIGH. Read-only. **StateBag-backed** (`bank.govt.taxBrackets`).

**Request:** `{ }` (empty).

**Response:** `{ status: 'ok', data: { brackets: [{ income_min, income_max, rate }, ...] } }` — read directly from GlobalState bag.

**Errors:** BANK_DISABLED / RATE_LIMIT_EXCEEDED.

**Perf:** FAST <50ms (StateBag read).

---

### 9.14 C014 — `sonar:bank:tax:calculate`

AUTH-OWNER. Rate HIGH. Read-only (calculation, no DB write). 

**Request:** `{ income: number, period?: 'annual' | 'monthly' }`.

**Response:** `{ status: 'ok', data: { tax_amount, effective_rate, brackets_applied: [...], net_income } }`.

**Errors:** BANK_DISABLED / AUTH_REQUIRED / RATE_LIMIT_EXCEEDED / VALIDATION_FAIL.

**Perf:** FAST <50ms.

---

### 9.15 C015 — `sonar:bank:tax:setBrackets` (admin)

AUTH-ROLE `sonar.bank.govt.tax.write`. Rate ADMIN. Idempotency mandatory.

**Request:** `{ brackets: [{ income_min, income_max, rate }, ...], idempotency_key?, correlation_id? }`.

**Response:** `{ status: 'ok', data: { brackets_new, effective_at } }`.

**Side effects:** DELETE + INSERT `sonar_bank_tax_brackets` rows atomic + StateBag `bank.govt.taxBrackets` updated + audit `event_type='admin_tax_brackets_updated'` + NetEvent `sonar:bank:tax:bracketsUpdated` admin broadcast (ACE).

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_ACE_DENIED / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / VALIDATION_FAIL (overlapping brackets / non-monotonic income_min).

**Perf:** STANDARD <200ms. **Tests:** happy + non-admin → AUTH_ACE_DENIED + overlap brackets → VALIDATION_FAIL + replay idempotent.

---

### 9.16 C016 — `sonar:bank:subsidy:grant` (admin)

AUTH-ROLE `sonar.bank.govt.subsidy.write`. Rate ADMIN. Idempotency mandatory.

**Request:** `{ recipient_citizen_id, amount, category, expires_at?, idempotency_key?, correlation_id?, reason }`.

**Response:** `{ status: 'ok', data: { subsidy_id, granted_at, expires_at, balance_recipient_after } }`.

**Side effects:** INSERT `sonar_bank_subsidies` + UPDATE recipient balance += amount + INSERT movement `'subsidy_grant'` + **v1.0.1 R1 M004** `publish_balance_update(recipient_cid, balance_after, 'main', opts)` (CP1-B NetEvent — replaces deprecated `bank.balance.<recipient_cid>` StateBag) + StateBag `bank.govt.subsidies.active` updated (CP1-A still OK — public knowledge) + NetEvent `sonar:bank:subsidy:granted` (recipient + admin) + audit `event_type='admin_subsidy_granted'`.

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_ACE_DENIED / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / VALIDATION_FAIL / RESOURCE_NOT_FOUND (recipient).

**Perf:** MEDIUM <500ms.

---

### 9.17 C017 — `sonar:bank:subsidy:list`

AUTH-PUBLIC. Rate HIGH. Read-only. StateBag-backed (`bank.govt.subsidies.active`).

**Request:** `{ }`. **Response:** `{ status: 'ok', data: { subsidies: [{ category, amount, expires_at }, ...] } }`.

**Perf:** FAST <50ms.

---

### 9.18 C018 — `sonar:bank:subsidy:claim`

AUTH-OWNER. Rate NORMAL. Idempotency mandatory.

**Request:** `{ subsidy_category, idempotency_key?, correlation_id? }`.

**Response:** `{ status: 'ok', data: { subsidy_id_claimed, amount_received, balance_after } }`.

**Side effects:** UPDATE subsidy claim status + UPDATE recipient balance += amount + INSERT movement `'subsidy_claim'` + **v1.0.1 R1 M004** `publish_balance_update(recipient_cid, balance_after, 'main', opts)` (CP1-B NetEvent) + NetEvent `sonar:bank:subsidy:claimed` + audit `event_type='subsidy_claim_recorded'`.

**Errors:** BANK_DISABLED / AUTH_REQUIRED / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / VALIDATION_FAIL / RESOURCE_NOT_FOUND (subsidy expired / already claimed) / COMPLIANCE_FLAG_BLOCK.

**Perf:** MEDIUM <500ms.

---

### 9.19 C019 — `sonar:bank:loan:apply`

#### 9.19.1 Identifier
- Auth: AUTH-OWNER. FSM #2 initial state `applied`.

#### 9.19.2 Request schema
```typescript
interface LoanApplyRequest {
  principal: number;
  term_days: number;                // 7-365
  purpose_category: string;
  collateral_account_id?: number;
  idempotency_key?: string;
  correlation_id?: string;
}
```

#### 9.19.3 Response schema
```typescript
{ status: 'ok', data: { loan_id, state: 'applied', principal, term_days, applied_at, decision_eta_at } }
// Errors: BANK_DISABLED | AUTH_REQUIRED | RATE_LIMIT_EXCEEDED | IDEMPOTENCY_INFLIGHT | VALIDATION_FAIL | COMPLIANCE_FLAG_BLOCK | LIMIT_EXCEEDED_DAILY (max 1 application/day)
```

#### 9.19.4 Auth check
- `auth.require_owner(source, applicant_citizen_id)` matches applicant (helper §2.3.1). Active loan check (max 3 simultaneous active per Phase A).

#### 9.19.5 Rate-limit
- Tier: **LOW** + max 1 application per day per citizen (separate quota outside token bucket).

#### 9.19.6 Idempotency
- Mandatory. Domain: `bank.loan.apply`.

#### 9.19.7 Side effects
1. **DB:** INSERT `sonar_bank_loans` (state='applied').
2. **NetEvents:** `sonar:bank:loan:applied` → applicant.
3. **Resource-internal:** `fsmTransition` (initial create).
4. **Audit ledger:** `event_type='loan_applied'` entry.
5. **Idempotency state:** Lock → Complete.

#### 9.19.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `RATE_LIMIT_EXCEEDED` / `IDEMPOTENCY_INFLIGHT` / `VALIDATION_FAIL` (term out of range / negative principal) / `LIMIT_EXCEEDED_DAILY` / `COMPLIANCE_FLAG_BLOCK`.

#### 9.19.9 Performance
- Tier: **MEDIUM** — p99 <500ms.

#### 9.19.10 Test scenarios
- Happy + invalid term + LIMIT_EXCEEDED_DAILY (2nd attempt same day) + replay idempotent.

---

### 9.20 C020 — `sonar:bank:loan:decide` (admin)

AUTH-ROLE `sonar.bank.govt.loan.admin`. Rate ADMIN. Idempotency mandatory. FSM #2 transitions `applied → approved | rejected` or `defaulted → written_off`.

**Request:** `{ loan_id, decision: 'approved' | 'rejected' | 'written_off', reason?, custom_interest_rate?, idempotency_key?, correlation_id? }`.

**Response:** `{ status: 'ok', data: { loan_id, state_new, principal_disbursed?, repayment_schedule?, decided_at } }`.

**Side effects:** Atomic transaction: UPDATE loan.state + (if approved) UPDATE applicant balance += principal + INSERT movement `'loan_disbursement'` + **v1.0.1 R1 M004** `publish_balance_update(applicant_cid, balance_after, 'main', opts)` (CP1-B NetEvent — replaces deprecated balance StateBag) + INSERT repayment_schedule rows + NetEvent `sonar:bank:loan:decisionResult` (CP1-B → applicant + admin ACE) + audit `event_type='loan_decided'`.

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_ACE_DENIED / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / INVALID_TRANSITION / RESOURCE_NOT_FOUND.

**Perf:** MEDIUM <500ms.

---

### 9.21 C021 — `sonar:bank:loan:repay`

AUTH-OWNER (borrower). Rate NORMAL. Idempotency mandatory. FSM #2 transitions `active_repaying → paid_off | active_repaying` (continued).

**Request:** `{ loan_id, amount, idempotency_key?, correlation_id? }`.

**Response:** `{ status: 'ok', data: { loan_id, amount_paid, balance_remaining, state_new, balance_after } }`.

**Side effects:** Atomic: UPDATE loan.balance_remaining -= amount, UPDATE borrower balance -= amount, INSERT movement `'loan_repayment'`, IF balance_remaining=0 → state='paid_off', **v1.0.1 R1 M004** `publish_balance_update(borrower_cid, balance_after, 'main', opts)` (CP1-B NetEvent) + NetEvent `sonar:bank:loan:repaymentRecorded` (borrower + admin) + audit `event_type='loan_repayment_recorded'`.

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_FORBIDDEN / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / VALIDATION_FAIL (amount > balance_remaining) / INSUFFICIENT_FUNDS / INVALID_TRANSITION (state != 'active_repaying') / RESOURCE_NOT_FOUND.

**Perf:** MEDIUM <500ms.

---

### 9.22 C022 — `sonar:bank:stocks:list`

AUTH-PUBLIC. Rate HIGH. Read-only. Materialized view o cron-refreshed cache.

**Request:** `{ filter?: { sector?: string }, limit?: number, cursor?: string }`. **Response:** `{ status: 'ok', data: { stocks: [{ ticker, name, sector, price_current, change_24h_pct, market_cap }, ...], next_cursor? } }`.

**Errors:** BANK_DISABLED / RATE_LIMIT_EXCEEDED / VALIDATION_FAIL. **Perf:** FAST <50ms.

---

### 9.23 C023 — `sonar:bank:stocks:buy`

#### 9.23.1 Identifier
- Auth: AUTH-OWNER. FSM ref: — (stock holding mutation logged via `recomputeHoldings` C026 cron).

#### 9.23.2 Request schema
```typescript
interface StocksBuyRequest {
  ticker: string;
  quantity: number;                 // integer shares > 0
  limit_price?: number;             // optional limit order Phase A — default market price
  idempotency_key?: string;
  correlation_id?: string;
}
```

#### 9.23.3 Response schema
```typescript
{ status: 'ok', data: { holding_id, ticker, quantity_bought, price_per_share, total_cost, balance_after, occurred_at } }
// Errors: BANK_DISABLED | AUTH_REQUIRED | RATE_LIMIT_EXCEEDED | IDEMPOTENCY_INFLIGHT | VALIDATION_FAIL | INSUFFICIENT_FUNDS | RESOURCE_NOT_FOUND (ticker)
```

#### 9.23.4 Auth check
- Owner check + active investment account presence (auto-create stock_holdings sub-account si missing).

#### 9.23.5 Rate-limit
- Tier: **NORMAL**.

#### 9.23.6 Idempotency
- Mandatory. Domain: `bank.stocks.buy`.

#### 9.23.7 Side effects
1. **DB atomic:** UPDATE buyer balance -= total_cost, INSERT/UPDATE `sonar_bank_stocks_holdings` (avg_price recompute), INSERT movement `'stock_purchase'`.
2. **CP1-B NetEvent emit (v1.0.1 R1 M004):** `publish_balance_update(cid, balance_after, 'main', opts)` — replaces deprecated `bank.balance.<cid>` StateBag. NO emit per holding (heavy + Q12 Tier 4 no realtime ticker).
3. **NetEvents:** `sonar:bank:stocks:buyComplete` → buyer.
4. **Resource-internal:** `movementRecorded`.
5. **Audit ledger:** `event_type='stock_purchase'` entry.
6. **Idempotency state:** Lock → Complete.

#### 9.23.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `RATE_LIMIT_EXCEEDED` / `IDEMPOTENCY_INFLIGHT` / `VALIDATION_FAIL` (quantity ≤ 0) / `INSUFFICIENT_FUNDS` / `RESOURCE_NOT_FOUND` / `EXTERNAL_DEPENDENCY_FAIL`.

#### 9.23.9 Performance
- Tier: **MEDIUM** — p99 <500ms.

#### 9.23.10 Test scenarios
- Happy + invalid ticker → RESOURCE_NOT_FOUND + INSUFFICIENT_FUNDS + replay idempotent + concurrent same ticker (atomic serialization).

---

### 9.24 C024 — `sonar:bank:stocks:sell`

Symmetric to C023 — sell position. AUTH-OWNER. Rate NORMAL. Idempotency mandatory. p99 <500ms.

**Request:** `{ ticker, quantity, limit_price?, idempotency_key?, correlation_id? }`. **Response:** `{ status: 'ok', data: { holding_id, ticker, quantity_sold, price_per_share, total_proceeds, balance_after, realized_gain_loss, occurred_at } }`.

**Side effects:** DB atomic UPDATE seller balance += proceeds, UPDATE/DELETE holding row, INSERT movement `'stock_sale'`, audit `event_type='stock_sale'` (con realized_gain_loss for tax computation Phase B).

**Errors adicional:** `VALIDATION_FAIL` (quantity > current holding) + `RESOURCE_NOT_FOUND` (no holding for ticker).

---

### 9.25 C025 — `sonar:bank:stocks:getPortfolio`

AUTH-OWNER. Rate HIGH. Read-only. p99 <200ms (multi-row holdings + price lookup join).

**Request:** `{ }`. **Response:** `{ status: 'ok', data: { holdings: [{ ticker, quantity, avg_price, current_price, unrealized_gain_loss, position_value }, ...], total_value, total_cost_basis, total_unrealized } }`.

**Errors:** BANK_DISABLED / AUTH_REQUIRED / RATE_LIMIT_EXCEEDED.

---

### 9.26 C026 — `sonar:bank:stocks:recomputeHoldings`

AUTH-ROLE `sonar.devops.bank.diagnostics` o cron triggered. Rate ADMIN. Idempotency mandatory. Heavy operation.

**Request:** `{ citizen_id?: string, idempotency_key?, correlation_id? }` — sin citizen_id → recompute all holdings server-wide. **Response:** `{ status: 'ok', data: { holdings_recomputed_count, duration_ms, errors: [] } }`.

**Side effects:** Materialized view `sonar_bank_stocks_holdings` recompute via batch SQL (avg_price + current_value per ticker per citizen) + audit `event_type='stocks_recomputed'`.

**Errors:** BANK_DISABLED / AUTH_ACE_DENIED / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / EXTERNAL_DEPENDENCY_FAIL.

**Perf:** SLOW <1500ms. (Phase B optimization: incremental recompute vs full scan.)

---

### 9.27 C027 — `sonar:bank:recurring:create`

#### 9.27.1 Identifier
- Auth: AUTH-OWNER. FSM #3 initial state `active`.

#### 9.27.2 Request schema
```typescript
interface RecurringCreateRequest {
  payee_iban_or_citizen_id: string;
  amount: number;
  period: 'daily' | 'weekly' | 'monthly';
  start_at: number;                 // epoch ms
  end_at?: number;                  // optional — default null (no expiry)
  reason: string;
  idempotency_key?: string;
  correlation_id?: string;
}
```

#### 9.27.3 Response schema
```typescript
{ status: 'ok', data: { recurring_id, state: 'active', period, next_payment_at, total_max_payments? } }
// Errors: BANK_DISABLED | AUTH_REQUIRED | RATE_LIMIT_EXCEEDED | IDEMPOTENCY_INFLIGHT | VALIDATION_FAIL | RESOURCE_NOT_FOUND | LIMIT_EXCEEDED_DAILY (max 10 active per citizen)
```

#### 9.27.4 Auth check
- Owner check + payee resolution (IBAN o citizen_id) + max active recurring per citizen quota Phase A 10.

#### 9.27.5 Rate-limit
- Tier: **LOW**.

#### 9.27.6 Idempotency
- Mandatory. Domain: `bank.recurring.create`.

#### 9.27.7 Side effects
1. **DB:** INSERT `sonar_bank_recurring_payments` (state='active').
2. **StateBag emits:** `bank.recurring.<owner_cid>.summary` updated (count + next_payment_at).
3. **NetEvents:** `sonar:bank:recurring:created` → owner.
4. **Cron triggers:** Recurring tick scheduled (or auto-discovered next cron tick).
5. **Resource-internal:** `fsmTransition` (initial create).
6. **Audit ledger:** `event_type='recurring_created'` entry.
7. **Idempotency state:** Lock → Complete.

#### 9.27.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `RATE_LIMIT_EXCEEDED` / `IDEMPOTENCY_INFLIGHT` / `VALIDATION_FAIL` / `RESOURCE_NOT_FOUND` / `LIMIT_EXCEEDED_DAILY`.

#### 9.27.9 Performance
- Tier: **MEDIUM** — p99 <500ms.

#### 9.27.10 Test scenarios
- Happy + invalid period + max 10 active → LIMIT_EXCEEDED_DAILY + replay idempotent.

---

### 9.28 C028 — `sonar:bank:recurring:cancel`

AUTH-OWNER. Rate NORMAL. Idempotency mandatory. FSM #3 transitions `active | paused | failed_insufficient_funds → cancelled` o `active ↔ paused`.

**Request:** `{ recurring_id, mode: 'pause' | 'resume' | 'cancel', idempotency_key?, correlation_id? }`. **Response:** `{ status: 'ok', data: { recurring_id, state_new, mode_applied } }`.

**Side effects:** UPDATE state per FSM table + StateBag `bank.recurring.<owner_cid>.summary` updated + NetEvent `sonar:bank:recurring:cancelled` (owner) + audit `event_type='recurring_cancelled'` (con mode).

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_FORBIDDEN / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / INVALID_TRANSITION / RESOURCE_NOT_FOUND.

**Perf:** STANDARD <200ms.

---

### 9.29 C029 — `sonar:bank:crypto:list`

AUTH-PUBLIC. Rate HIGH. Read-only. p99 <50ms (cron-refreshed cache).

**Request:** `{ filter? }`. **Response:** `{ status: 'ok', data: { coins: [{ symbol, name, price_current, change_24h_pct }, ...] } }`.

**Errors:** BANK_DISABLED / RATE_LIMIT_EXCEEDED.

---

### 9.30 C030 — `sonar:bank:crypto:swap`

AUTH-OWNER. Rate NORMAL. Idempotency mandatory. p99 <500ms.

**Request:** `{ from_symbol: string, to_symbol: string, amount_from: number, idempotency_key?, correlation_id? }`. **Response:** `{ status: 'ok', data: { swap_id, amount_from, amount_to, exchange_rate, fee, balance_from_after, balance_to_after, occurred_at } }`.

**Side effects:** DB atomic — UPDATE crypto_wallet balances (decrement from / increment to), INSERT 2 movements (`'crypto_swap_out'` + `'crypto_swap_in'`), INSERT swap log row, audit `event_type='crypto_swap'`. NO StateBag emit (Phase A — Tier 4 no realtime crypto ticker per Q12).

**Errors:** BANK_DISABLED / AUTH_REQUIRED / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / VALIDATION_FAIL (same symbol from/to) / INSUFFICIENT_FUNDS / RESOURCE_NOT_FOUND (symbol).

---

### 9.31 C031 — `sonar:bank:atm:getMinigameSession`

AUTH-OWNER. Rate NORMAL. Idempotency mandatory. p99 <200ms.

**Request:** `{ atm_id, action: 'withdraw' | 'deposit' | 'check_balance', amount?, idempotency_key?, correlation_id? }`. **Response:** `{ status: 'ok', data: { session_id, minigame_difficulty, time_limit_ms, expected_outcome_token } }`.

**Side effects:** INSERT `sonar_bank_atm_sessions` (status='in_progress', expected_token = HMAC(action+amount+session_id+server_secret)) + audit `event_type='atm_session_started'`.

**Errors:** BANK_DISABLED / AUTH_REQUIRED / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / VALIDATION_FAIL / INSUFFICIENT_FUNDS (pre-check withdrawal) / RESOURCE_NOT_FOUND (atm_id).

**Note:** Actual outcome callback (success/fail post-minigame) → defer Phase B spec C031b. Phase A: session creation + token generation only.

#### 9.31.7 HMAC secret management (NEW v1.0.1 R1 — M006 fix)

**`server_secret` provenance + storage + rotation:**

- **Storage:** **convar exclusiva `sonar_bank_atm_hmac_secret`** declarada en `server.cfg` (NUNCA en `.lua` file dentro del repo). Default value vacío `""` → resource fail boot defensivo (`defensive_abort('atm_hmac_secret_missing', ...)`) si convar empty.
- **Provenance:** generated by sysadmin ANTES de primera deploy via `openssl rand -hex 32` (32 bytes / 64 hex chars entropy mínima). Documented en runbook DevOps H4 deploy guide.
- **Min length:** 32 bytes (64 hex chars). Resource boot valida `#secret >= 64` o defensive abort.
- **Rotation:** manual on-demand (no auto-rotation Phase A). Sysadmin updates `server.cfg` convar + `txAdmin restart sonar_bank` → all in-flight ATM sessions invalidated (acceptable: ATM minigame TTL <60s). Phase B: rolling dual-secret window (current + previous accepted 5min) for zero-downtime rotation.
- **NEVER:** secret en `.lua` file, en git history, en logs (incluso debug). HMAC verify falla siempre logged WITHOUT secret material.
- **Audit:** boot event `atm_hmac_secret_loaded_OK` (sin secret material) + `atm_hmac_secret_failed_validation` si len<64.

**Anti-patrón AP-HMAC-1 prohibido (M006 root cause):**
```lua
-- ❌ NUNCA. Hardcoded, leakable via repo / git history / file extraction.
local SECRET = 'my_super_secret_42'

-- ✅ SIEMPRE.
local SECRET = GetConvar('sonar_bank_atm_hmac_secret', '')
if #SECRET < 64 then
  defensive_abort('atm_hmac_secret_missing_or_short', 'sonar_bank_atm_hmac_secret convar must be set in server.cfg, min 64 hex chars (openssl rand -hex 32).')
  return
end
```

**DevOps Lead H4 runbook obligation:** documentar steps generación + storage + rotation HMAC secret. Backend Lead M006 cross-cutting handoff DevOps cuando active.

---

### 9.32 C032 — `sonar:bank:card:requestPhysical`

#### 9.32.1 Identifier
- Auth: AUTH-OWNER. FSM #4 initial state `pending_request`.

#### 9.32.2 Request schema
```typescript
interface CardRequestPhysicalRequest {
  card_type: 'debit' | 'credit';
  delivery_address?: string;        // optional — default citizen home
  idempotency_key?: string;
  correlation_id?: string;
}
```

#### 9.32.3 Response schema
```typescript
{ status: 'ok', data: { card_id, masked_pan, state: 'pending_request', estimated_delivery_at, fee_charged, balance_after } }
// Errors: BANK_DISABLED | AUTH_REQUIRED | RATE_LIMIT_EXCEEDED | IDEMPOTENCY_INFLIGHT | VALIDATION_FAIL | INSUFFICIENT_FUNDS | LIMIT_EXCEEDED_DAILY (max 1 active per type per citizen)
```

#### 9.32.4 Auth check
- Owner check + max 1 active per card_type per citizen quota.

#### 9.32.5 Rate-limit
- Tier: **LOW**.

#### 9.32.6 Idempotency
- Mandatory. Domain: `bank.card.requestPhysical`.

#### 9.32.7 Side effects
1. **DB atomic:** INSERT `sonar_bank_physical_cards` (state='pending_request', card_id generated, masked_pan visible, real_pan stored encrypted), UPDATE owner balance -= card_fee, INSERT movement `'card_issuance_fee'`.
2. **CP1-B NetEvent emit (v1.0.1 R1 M004):** `publish_balance_update(owner_cid, balance_after, 'main', opts)` — replaces deprecated `bank.balance.<owner_cid>` StateBag.
3. **NetEvents:** `sonar:bank:card:requestSubmitted` → owner.
4. **Resource-internal:** `fsmTransition` (initial create).
5. **Audit ledger:** `event_type='card_request_submitted'` entry.
6. **Idempotency state:** Lock → Complete.

#### 9.32.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `RATE_LIMIT_EXCEEDED` / `IDEMPOTENCY_INFLIGHT` / `VALIDATION_FAIL` / `INSUFFICIENT_FUNDS` / `LIMIT_EXCEEDED_DAILY`.

#### 9.32.9 Performance
- Tier: **MEDIUM** — p99 <500ms.

#### 9.32.10 Test scenarios
- Happy + INSUFFICIENT_FUNDS for fee + max 1 active per type → LIMIT_EXCEEDED_DAILY + replay idempotent.

---

### 9.33 C033 — `sonar:bank:card:setPin`

AUTH-OWNER. Rate NORMAL. Idempotency mandatory. p99 <200ms. FSM #4 transition `pending_request → active`.

**Request:** `{ card_id, new_pin: string (4 digits), idempotency_key?, correlation_id? }`. **Response:** `{ status: 'ok', data: { card_id, state_new: 'active', pin_set_at } }`.

**Side effects:** UPDATE `sonar_bank_physical_cards.pin_hash = bcrypt(new_pin)` + UPDATE state='active' (per FSM whitelisted transition) + audit `event_type='card_pin_set'`.

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_FORBIDDEN / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / VALIDATION_FAIL (PIN format) / INVALID_TRANSITION (state != 'pending_request') / RESOURCE_NOT_FOUND.

---

### 9.34 C034 — `sonar:bank:card:verifyPin`

#### 9.34.1 Identifier
- Auth: AUTH-OWNER. FSM #4 transition `active → frozen_pin_failures` on 3rd consecutive fail.

#### 9.34.2 Request schema
```typescript
interface CardVerifyPinRequest {
  card_id: string;
  pin_attempt: string;
  context?: 'atm' | 'transfer' | 'pos';
  correlation_id?: string;
}
```

#### 9.34.3 Response schema
```typescript
// Success
{ status: 'ok', data: { card_id, verified: true, fail_count_reset: true } }
// Failure (NOT error — controlled response)
{ status: 'ok', data: { card_id, verified: false, fail_count: number, frozen: boolean, retry_allowed: boolean } }
// Errors: BANK_DISABLED | AUTH_REQUIRED | RATE_LIMIT_EXCEEDED | RESOURCE_NOT_FOUND
```

#### 9.34.4 Auth check
- Owner check + card state must be 'active' (frozen returns frozen=true response).

#### 9.34.5 Rate-limit
- Tier: **CRITICAL** (capacity 2, refill 0.1/sec — 1 per 10s) — anti-bruteforce additional layer.

#### 9.34.6 Idempotency
- **NO idempotency_key** — verify is naturally non-idempotent (fail counter mutation).

#### 9.34.7 Side effects
1. **DB:** INSERT `sonar_bank_card_pin_attempts` (success/fail logged) + UPDATE `sonar_bank_physical_cards.pin_fail_count` (increment on fail, reset on success) + IF pin_fail_count >= 3 → UPDATE state='frozen_pin_failures' (FSM transition).
2. **NetEvents:** IF fail → `sonar:bank:card:pinFailure` (CP1-B → owner only) con fail_count + frozen.
3. **Resource-internal:** IF fail 3rd → `fsmTransition`.
4. **Audit ledger:** `event_type='card_pin_attempt_<success|fail>'` entry. Severity escalado on 3rd fail.
5. **Compliance autoraise:** 3rd consecutive fail → autoraise flag pattern (Security Lead C-SEC-03 spec).
6. **NO StateBag emit** (PII card detail).
7. **NO idempotency Lock/Complete.**

#### 9.34.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `RATE_LIMIT_EXCEEDED` / `RESOURCE_NOT_FOUND`.

(Note: PIN verification fail no es `error` code — es `data.verified=false`. Solo errors infraestructurales son code.)

#### 9.34.9 Performance
- Tier: **STANDARD** — p99 <200ms.

#### 9.34.10 Test scenarios
- Happy correct PIN + 1st fail (counter=1) + 2nd fail (counter=2) + 3rd fail (counter=3 → frozen, FSM transition) + verify on frozen card → frozen=true response + CRITICAL rate-limit (3 attempts in 10s → RATE_LIMIT_EXCEEDED on 3rd) + post-success counter reset.

---

### 9.35 C035 — `sonar:bank:audit:query`

#### 9.35.1 Identifier
- Auth: AUTH-ROLE_OR_OWNER per Q13 3 scopes. FSM ref: —.

#### 9.35.2 Request schema
```typescript
interface AuditQueryRequest {
  scope: 'self' | 'empresa' | 'govt_full';
  empresa_id?: string;              // mandatory if scope='empresa'
  filter?: {
    event_type?: string | string[];
    citizen_id?: string;            // ignored unless scope='govt_full'
    from_at?: number;                // epoch ms
    to_at?: number;
    correlation_id?: string;         // trace single chain
  };
  limit?: number;                    // default 50, max 500
  cursor?: string;                   // pagination
  correlation_id?: string;
}
```

#### 9.35.3 Response schema
```typescript
{ status: 'ok', data: { rows: [{ audit_id, event_type, occurred_at, citizen_id, payload_summary, correlation_id }, ...], next_cursor?: string, total_estimated?: number } }
// Errors: BANK_DISABLED | AUTH_REQUIRED | AUTH_ACE_DENIED | RATE_LIMIT_EXCEEDED | VALIDATION_FAIL | RESOURCE_NOT_FOUND
```

#### 9.35.4 Auth check
- scope='self' → AUTH-OWNER (citizen_id default = `Bridges.Player.GetCitizenId(source)` via `auth.require_citizen` helper §2.3.1).
- scope='empresa' → AUTH-ROLE `sonar.bank.empresas.<empresa_id>` (employee/owner).
- scope='govt_full' → AUTH-ROLE `sonar.bank.govt.audit.full`.

#### 9.35.5 Rate-limit
- Tier: **NORMAL** + max query rows budget (cap 500 per request).

#### 9.35.5.1 Special recursive rate-limit (NEW v1.0.1 R1 — M003 fix)

C035 implementa **dual rate-limit**:
1. **Standard token bucket** §4.3 framework (tier NORMAL or LOW per scope).
2. **Recursive guard NEW (M003):** independiente del bucket general.
   - **Per-citizen:** max **1 audit query per minute** per `citizen_id` (sliding window 60s).
   - **Global:** max **10 audit queries per minute** server-wide (sliding window 60s).
   - **Storage:** in-RAM ring buffer (Phase A acceptable per M001 advisory) en `sonar_bridges/lib/audit_query_throttle.lua` NEW.
   - **On reject:** return `{ status='error', error={ code='AUDIT_QUERY_THROTTLED', retry_after_ms=<remaining_window> } }` + audit hook `audit_hook_rate_limit_violation` con context `recursive_audit_query`.
   - **Bypass exception:** queries con scope=`'self'` **single-row by movement_id** (e.g. drill-down detail single audit_id) **excluyen** del recursive guard — usan bucket general only.

**Rationale:** previene DoS recursivo (audit log of audit log → explosion logarítmica O(n²)) + mantiene UX legítimo (admin self-audit detail single-record). Convars `sonar_bank_audit_query_per_citizen_per_min=1` + `sonar_bank_audit_query_global_per_min=10` configurables sysadmin (DevOps H4 runbook).

#### 9.35.6 Idempotency
- Optional (read with cursor — natural idempotente per cursor).

#### 9.35.7 Side effects
1. **DB:** SELECT con index `idx_audit_event_type_occurred` + scope filter atomic.
2. **NetEvents:** IF payload >32KB → fire `sonar:bank:audit:queryResult` (CP1-B → requester) en lugar de inline response.
3. **Audit ledger meta:** `event_type='audit_query_executed'` entry (recursive logging — high-frequency audit queries themselves logged Tier 4).

#### 9.35.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `AUTH_ACE_DENIED` / `RATE_LIMIT_EXCEEDED` / `VALIDATION_FAIL` / `RESOURCE_NOT_FOUND` / `EXTERNAL_DEPENDENCY_FAIL`.

#### 9.35.9 Performance
- Tier: **SLOW** — p99 <1500ms (paginated query con index).

#### 9.35.10 Test scenarios
- Happy scope='self' + scope='empresa' authorized + scope='empresa' unauthorized → AUTH_ACE_DENIED + scope='govt_full' authorized + filter date range + cursor pagination + filter correlation_id (trace chain) + large payload → CP1-B NetEvent fire path.

---

### 9.36 C036 — `sonar:bank:compliance:listFlags`

AUTH-OWNER (citizen propio default). Rate HIGH. Read-only. p99 <200ms.

**Request:** `{ citizen_id?: string, status?: 'active' | 'resolved' | 'all' }`. citizen_id only if requester has `sonar.bank.govt.compliance.admin`. **Response:** `{ status: 'ok', data: { flags_public: [{ flag_id, type, severity_label, raised_at }, ...] } }` — **public reduced shape (NO evidence detail, NO raw PII).**

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_FORBIDDEN / RATE_LIMIT_EXCEEDED / VALIDATION_FAIL.

**Note:** Para detail full → C037 (admin only).

---

### 9.37 C037 — `sonar:bank:compliance:queryDetail` (admin)

AUTH-ROLE `sonar.bank.govt.compliance.admin`. Rate ADMIN. Read-only. p99 <200ms. **CP1-B NetEvent fire pattern.**

**Request:** `{ citizen_id, flag_id?, correlation_id? }`. **Response:** server fires `sonar:bank:compliance:detail` (CP1-B) NetEvent al requester con full detail (`{ flags: [{ flag_id, type, severity, evidence, raised_at, resolved_at, resolver, resolution_notes }, ...] }`) — **inline response empty `{ status: 'ok', data: { delivered_via_event: 'sonar:bank:compliance:detail' } }`** to avoid leak via callback response (paranoid privacy).

**Side effects:** Audit ledger `event_type='admin_compliance_query'` entry (admin queries themselves audited).

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_ACE_DENIED / RATE_LIMIT_EXCEEDED / RESOURCE_NOT_FOUND.

---

### 9.38 C038 — `sonar:bank:compliance:resolveFlag` (admin)

AUTH-ROLE `sonar.bank.govt.compliance.admin`. Rate ADMIN. Idempotency mandatory. p99 <200ms.

**Request:** `{ flag_id, resolution: 'resolved' | 'rejected' | 'escalated', resolution_notes: string (mandatory), idempotency_key?, correlation_id? }`. **Response:** `{ status: 'ok', data: { flag_id, status_new, resolved_at, resolver_id } }`.

**Side effects (v1.0.1 R1 H006 hardened — full audit shape per C-SEC-01 §1.2):**

1. **DB UPDATE** `sonar_bank_compliance_flags` SET `status=payload.resolution`, `resolved_at=NOW()`, `resolver_id=citizen_id`, `resolution_notes=payload.resolution_notes` WHERE flag_id=payload.flag_id (atomic transaction with §2 step audit insert).
2. **DB SNAPSHOT pre-update** — SELECT row antes de UPDATE → serialize as JSON → pass como `previous_flag_snapshot` al audit hook (forensics tamper detection — H006 mandatory).
3. **StateBag** — UPDATE `bank.compliance.<citizen_id_target>.public` reduced bag (count decrement / status histogram recompute) — CP1-A pattern.
4. **Audit ledger** — INSERT `event_type='compliance_flag_resolved'` con shape canónica C-SEC-01 `audit_hook_compliance_flag_resolved`:
   ```json
   {
     "event_type": "compliance_flag_resolved",
     "occurred_at": <epoch_ms>,
     "correlation_id": "<uuid_v4>",
     "flag_id": <int>,
     "resolver_id": "<admin_citizen_id>",
     "resolution": "resolved" | "rejected" | "escalated",
     "resolution_notes": "<string mandatory>",
     "resolved_at": <epoch_ms>,
     "previous_flag_snapshot": { /* full pre-update flag row JSON */ },
     "source_resource": "sonar_bank_app"
   }
   ```
5. **Audit ledger cross-reference** — INSERT segundo entry `event_type='admin_force_action'` con `cross_ref_audit_id` apuntando al `compliance_flag_resolved` row recién insertado (admin override path forensics).
6. **NetEvent** server→admin `sonar:bank:compliance:flagResolved` (target P10 admins) — payload pública minimal `{flag_id, status_new, resolver_id, resolved_at}`. NO `previous_flag_snapshot` (queda solo en audit ledger).

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_ACE_DENIED / RATE_LIMIT_EXCEEDED / IDEMPOTENCY_INFLIGHT / RESOURCE_NOT_FOUND / INVALID_TRANSITION (already resolved).

---

### 9.39 C039 — `sonar:bank:business:treasuryGet`

AUTH-OWNER (employee or owner of the empresa). Rate HIGH. Read-only. p99 <50ms (StateBag-backed `bank.business_treasury.<company_id>`).

**Request:** `{ company_id }`. **Response:** `{ status: 'ok', data: { company_id, balance, currency, employees_with_access: number, recent_movements_count } }`.

**Auth check:** `sonar.bank.empresas.<company_id>` ACE granted OR `Bridges.Player.GetCitizenId(source)` in business_owners table (use `auth.require_role_or_owner` helper §2.3.1).

**Errors:** BANK_DISABLED / AUTH_REQUIRED / AUTH_FORBIDDEN / RATE_LIMIT_EXCEEDED / RESOURCE_NOT_FOUND.

---

### 9.40 C040 — `sonar:bank:business:approvalCreate`

#### 9.40.1 Identifier
- Auth: AUTH-OWNER (initiator must be employee with role permitting initiation). FSM #6 initial state `pending_approvals`.

#### 9.40.2 Request schema
```typescript
interface BusinessApprovalCreateRequest {
  company_id: string;
  action: 'transfer' | 'payroll_run' | 'expense_register' | 'asset_purchase';
  action_payload: Record<string, unknown>;       // e.g. { to_iban, amount, reason }
  signers_required: number;                      // M (subset of N total signers)
  expires_at?: number;                            // default now + 48h (configurable convar)
  idempotency_key?: string;
  correlation_id?: string;
}
```

#### 9.40.3 Response schema
```typescript
{ status: 'ok', data: { approval_id, state: 'pending_approvals', signers_required, signers_total, expires_at } }
// Errors: BANK_DISABLED | AUTH_REQUIRED | AUTH_FORBIDDEN | RATE_LIMIT_EXCEEDED | IDEMPOTENCY_INFLIGHT | VALIDATION_FAIL | RESOURCE_NOT_FOUND | INSUFFICIENT_QUORUM (M > N)
```

#### 9.40.4 Auth check
- Initiator must be employee con permission `sonar.bank.empresas.<company_id>.initiate_approval`.
- Quorum validation: signers_required ≤ count(eligible signers) of empresa.

#### 9.40.5 Rate-limit
- Tier: **LOW** (multi-signer creates raros).

#### 9.40.6 Idempotency
- Mandatory. Domain: `bank.business.approvalCreate`.

#### 9.40.7 Side effects
1. **DB atomic:** INSERT `sonar_bank_business_treasury_approvals` (state='pending_approvals') + INSERT signers_pending rows (1 per eligible signer).
2. **StateBag emits:** NONE (CP1-B sensible empresa internal).
3. **NetEvents:** `sonar:bank:business:approvalPending` (CP1-B) → signers list (per ACE check `sonar.bank.empresas.<company_id>.sign`).
4. **Resource-internal:** `fsmTransition` (initial create).
5. **Audit ledger:** `event_type='business_approval_created'` entry con action_payload metadata.
6. **Cron triggers:** Approval expiry tick scheduled.
7. **Idempotency state:** Lock → Complete.

#### 9.40.8 Error codes
`BANK_DISABLED` / `AUTH_REQUIRED` / `AUTH_FORBIDDEN` / `RATE_LIMIT_EXCEEDED` / `IDEMPOTENCY_INFLIGHT` / `VALIDATION_FAIL` / `RESOURCE_NOT_FOUND` / `INSUFFICIENT_QUORUM`.

#### 9.40.9 Performance
- Tier: **MEDIUM** — p99 <500ms.

#### 9.40.10 Test scenarios
- Happy + non-employee initiator → AUTH_FORBIDDEN + signers_required > eligible → INSUFFICIENT_QUORUM + invalid action → VALIDATION_FAIL + replay idempotent + approval auto-resolve via cron tick.

---

> **Note placeholder:** **C040b approval sign + C040c approval cancel (initiator)** — sub-callbacks deferred sub-spec a v0.2 BANK-BE.2 (refinements iteration). Phase A foundational create + cron resolve via FSM #6 transitions cubre flow básico.

---

## 10. NEW — Server-to-Server Exports surface (Phase 5 R2 — 22 públicos)

### 10.1 Modelo + alcance

Recursos third-party server-side (vehicle shops, jobs, fines, taxes, ATMs, businesses) invocan `exports.sonar_bank_app:<Op>(...)` para mutar dinero. NO hay equivalente client-callable — los exports son **server-only** por naturaleza FiveM.

Design SSoT: `@docs/design/04_sonar_bank_api.md` v0.2.

**Trust model:** `GetInvokingResource()` se persiste en audit (`invoker_resource` field per C-SEC-01 §1.2.A 10-field shape v0.3 R2) y se chequea contra `sonar:admin_allowlist` convar para Tier 2 cuando `actor_src == 0` (console). NO HMAC / NO JWT (server-side exports already privileged by FiveM runtime). Detalles attack surface model: `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md` §4'.3.

**Numbering canonical — 22 públicos = 21 mutation/read + 1 informational:**

- **Tier 1 (11 mutation/read):** AddMoney + RemoveMoney + CanAfford + GetBalance + TransferBySource + TransferByIban + 5 `*ByCitizen` siblings.
- **Tier 2 (10 mutation):** AdminCredit + AdminDebit + AdminSetBalance + Freeze + Unfreeze + 5 `*ByCitizen` siblings (Founder Decision #1 LOCKED 2026-05-12 = 22 explicit explicits, NO polymorphic).
- **GetApiVersion (informational, +1):** read-only feature-detect, no audit, no mutation. Total públicos = 22.

### 10.2 Boundary helpers `lib/units.lua` (mandatory)

```lua
-- sonar_bank_app/server/lib/units.lua (NEW Phase 5 implementation 4.1)
-- HALF_UP rounding. Float math prohibido downstream.

units.to_minor(decimal_input)   -- (string|number) -> integer cents
units.from_minor(integer_minor) -- integer cents -> string "1234.56" for DB DECIMAL
```

Every Tier 1/2 wrapper applies `to_minor` al recibir `amount_minor` desde caller (defensive — caller debe ya pasar integer pero validation idempotente) y `from_minor` al invocar service layer + DB insert + `publish_balance_update`. Property tests Phase 5 validation §5.1 ST-024.1: round-trip identity, edge cases (0, max int64 cents, negative).

### 10.3 Tier 1 — Public mutation exports (11)

#### 10.3.1 Tabla canónica Tier 1

| # | Export | Args | Return tuple `(ok, error, data)` | Error codes possible | Idempotency | ACE gate |
|---|---|---|---|---|---|---|
| 1 | `AddMoney` | `(source:int, amount_minor:int, reason:string, opts?:table)` | `(boolean, string?, {new_balance_minor, iban, tx_id}?)` | `INVALID_ARGUMENT, INVALID_AMOUNT, PLAYER_NOT_FOUND, PLAYER_NOT_LOADED, ACCOUNT_NOT_FOUND, ACCOUNT_FROZEN, ACCOUNT_CLOSED, IDEMPOTENCY_REPLAY (ok=true), INTERNAL_ERROR` | `opts.idempotency_key?` | None (Tier 1) |
| 2 | `RemoveMoney` | `(source:int, amount_minor:int, reason:string, opts?:table)` | idem + `tx_id` | + `INSUFFICIENT_FUNDS` | `opts.idempotency_key?` | None |
| 3 | `CanAfford` | `(source:int, amount_minor:int)` | `(boolean, string?, {balance_minor, sufficient}?)` | `INVALID_ARGUMENT, PLAYER_NOT_FOUND, PLAYER_NOT_LOADED, ACCOUNT_NOT_FOUND` | N/A (read) | None |
| 4 | `GetBalance` | `(source:int)` | `(boolean, string?, {balance_minor, savings_minor, iban}?)` | idem | N/A | None |
| 5 | `TransferBySource` | `(from_src:int, to_src:int, amount_minor:int, reason:string, opts?:table)` | `(boolean, string?, {from_iban, to_iban, amount_minor, fee_minor, tx_id}?)` | + `INSUFFICIENT_FUNDS, LIMIT_EXCEEDED, ACCOUNT_FROZEN (either)` | `opts.idempotency_key?` | None |
| 6 | `TransferByIban` | `(from_iban:string, to_iban:string, amount_minor:int, reason:string, opts?:table)` | idem | idem + `IBAN_INVALID` | `opts.idempotency_key?` | None |
| 7 | `AddMoneyByCitizen` | `(citizen_id:string, amount_minor:int, reason:string, opts?:table)` | idem export #1 | `INVALID_ARGUMENT, INVALID_AMOUNT, CITIZEN_NOT_FOUND, ACCOUNT_NOT_FOUND, ACCOUNT_FROZEN, ACCOUNT_CLOSED, IDEMPOTENCY_REPLAY, INTERNAL_ERROR` | `opts.idempotency_key?` | None |
| 8 | `RemoveMoneyByCitizen` | `(citizen_id:string, amount_minor:int, reason:string, opts?:table)` | idem export #2 | + `INSUFFICIENT_FUNDS` | `opts.idempotency_key?` | None |
| 9 | `CanAffordByCitizen` | `(citizen_id:string, amount_minor:int)` | idem export #3 | `CITIZEN_NOT_FOUND, ACCOUNT_NOT_FOUND` | N/A | None |
| 10 | `GetBalanceByCitizen` | `(citizen_id:string)` | idem export #4 | idem | N/A | None |
| 11 | `TransferByCitizen` | `(from_cid:string, to_cid:string, amount_minor:int, reason:string, opts?:table)` | idem export #5 | + `INSUFFICIENT_FUNDS, LIMIT_EXCEEDED, ACCOUNT_FROZEN` | `opts.idempotency_key?` | None |

**Notas Tier 1:**

- `TransferByIban` (#6) NO requiere `*ByCitizen` sibling (IBAN ya citizen-agnostic). Total Tier 1 = **11 exports** (6 baseline + 5 *ByCitizen) per Q6 LOCKED.
- `*ByCitizen` variants resuelven `citizen_id → IBAN primario` via `AccountService.GetPrimaryByCitizen(cid)`. NO requieren player online; si citizen offline, mutation persiste DB + audit; mirror sync deferred a next `PlayerLoaded` event (Q6 LOCKED offline-safe semantics).
- Tier 1 NUNCA acepta `opts.allow_overdraft` — `RemoveMoney`/`TransferBy*` rechazan con `INSUFFICIENT_FUNDS` si balance < amount (Q5 LOCKED).
- `CanAfford` returns ambos `balance_minor` actual y `sufficient: bool` para evitar double-fetch en caller pattern típico (`if CanAfford ... then RemoveMoney`).

#### 10.3.2 `opts` table schema canonical (Tier 1 mutations)

```lua
opts = {
  idempotency_key = string?,    -- UUIDv4 preferido; max 128 chars; persisted en sonar_bank_idem 24h TTL
  correlation_id  = string?,    -- UUIDv4 trace cross-resource; auto-generated si absent
  account_iban    = string?,    -- override target IBAN si player tiene multiple accounts; default = primary
  reason_meta     = table?,     -- key-value pairs additional audit context (max 16 keys, 256 chars each)
}
```

**Idempotency persistence:** Phase 5 introduce nueva tabla simple `sonar_bank_idem` (PRIMARY KEY `idem_key`, `result_json`, `invoker_resource`, `created_at`, 24h TTL cron purge) — migration `036_sonar_bank_idem.sql` Phase 4.2 implementation. Justificación tabla separada de `sonar_bank_idempotency_keys` LOCKED v1.0.1 R1 (callbacks): callbacks usan FSM `idempotency_lifecycle` con states (locked, completed, failed); exports surface usa modelo más simple "INSERT IGNORE + cached result_json" sin FSM, suficiente para semantic Tier 1/2 atomic exports.

### 10.4 Tier 2 — Admin/operator exports (10)

#### 10.4.1 Tabla canónica Tier 2

| # | Export | Args | Return tuple | Error codes possible | Idempotency | Auth gate |
|---|---|---|---|---|---|---|
| 12 | `AdminCredit` | `(actor_src:int, target:int|string, amount_minor:int, reason:string, opts?:table)` | `(boolean, string?, {iban, new_balance_minor, tx_id}?)` | `INVALID_ARGUMENT, INVALID_AMOUNT, AUTH_ACE_DENIED, AUTH_ALLOWLIST_DENIED, PLAYER_NOT_FOUND, CITIZEN_NOT_FOUND, ACCOUNT_NOT_FOUND, ACCOUNT_CLOSED, IDEMPOTENCY_REPLAY, INTERNAL_ERROR` | `opts.idempotency_key?` | `Auth.RequireAdmin(actor_src)` OR `actor_src==0` console OR `GetInvokingResource() ∈ sonar:admin_allowlist` |
| 13 | `AdminDebit` | idem | idem | + `INSUFFICIENT_FUNDS` (si `opts.allow_overdraft != true`) | idem | idem |
| 14 | `AdminSetBalance` | `(actor_src, target, new_balance_minor, reason, opts?)` | `(boolean, string?, {iban, prev_balance_minor, new_balance_minor, delta_minor, tx_id}?)` | idem (sin INSUFFICIENT_FUNDS — overwrite total) | `opts.idempotency_key?` | idem |
| 15 | `Freeze` | `(actor_src, target_iban:string, reason)` | `(boolean, string?, {iban, previous_flag_snapshot}?)` | `INVALID_ARGUMENT, AUTH_ACE_DENIED, AUTH_ALLOWLIST_DENIED, IBAN_INVALID, ACCOUNT_NOT_FOUND, ACCOUNT_ALREADY_FROZEN` | None (state mutation idempotent natively) | idem |
| 16 | `Unfreeze` | idem | idem | + `ACCOUNT_NOT_FROZEN` | None | idem |
| 17 | `AdminCreditByCitizen` | `(actor_src, citizen_id, amount_minor, reason, opts?)` | idem #12 | idem #12 con `CITIZEN_NOT_FOUND` reemplaza `PLAYER_NOT_FOUND` | idem | idem |
| 18 | `AdminDebitByCitizen` | idem | idem #13 | idem #13 | idem | idem |
| 19 | `AdminSetBalanceByCitizen` | idem | idem #14 | idem #14 | idem | idem |
| 20 | `FreezeByCitizen` | `(actor_src, citizen_id, reason)` | resuelve citizen → IBAN primary → idem #15 | idem #15 + `CITIZEN_NOT_FOUND` | None | idem |
| 21 | `UnfreezeByCitizen` | idem | idem #16 | idem #16 + `CITIZEN_NOT_FOUND` | None | idem |

**Founder Decision #1 LOCKED 2026-05-12:** Tier 2 = 10 exports explícitos (5 baseline + 5 `*ByCitizen` siblings con type-checked args). Paridad con Tier 1, type safety contractual surface. Polymorphic auto-detect descartado.

#### 10.4.2 `opts.allow_overdraft` semantic (Q5 LOCKED)

```lua
opts = {
  -- ... Tier 1 fields ...
  allow_overdraft = boolean?,    -- DEFAULT false. true → permite balance negativo post-mutation.
                                 -- Audit event_type → 'bank_overdraft' (NEW C-SEC-01 v0.3 R2 enum entry).
                                 -- Tier 1 IGNORA este flag (siempre false). Tier 2 honra explícitamente.
}
```

#### 10.4.3 `Auth.RequireAdmin` helper canonical

`Auth.RequireAdmin(actor_src)` retorna `(true, citizen_id)` o `(false, 'AUTH_ACE_DENIED' | 'AUTH_ALLOWLIST_DENIED')`. Lookup order:

1. `actor_src == 0` (console) → `(true, nil)` (audit `actor_account_id = NULL`, `invoker_resource = GetInvokingResource() OR 'console'`).
2. `actor_src > 0` + `IsPlayerAceAllowed(actor_src, 'sonar.bank.admin')` → `(true, Bridges.Player.GetCitizenId(actor_src))`.
3. `actor_src > 0` falla ACE pero `GetInvokingResource() ∈ split(GetConvar('sonar:admin_allowlist', ''))` → `(true, Bridges.Player.GetCitizenId(actor_src))` con audit flag `actor_via_allowlist = true`.
4. Else → `(false, 'AUTH_ACE_DENIED')` o `(false, 'AUTH_ALLOWLIST_DENIED')` según rama.

ACE permission `sonar.bank.admin` documentado en C-SEC-02 §2.1 (P-ADMIN reuses P10 `sonar.bank.govt.compliance.admin` OR dedicated permission Phase 5.1 implementation decision). Convar `sonar:admin_allowlist` (comma-separated resource names) documentado en DevOps runbook H4 (NEW post-Phase 5 LOCK).

### 10.5 Rigid fee policy (Q7 LOCKED — NO override)

Cada `TransferBy*` Tier 1 y `AdminCredit/AdminDebit/AdminSetBalance` Tier 2 honra `Config.FeePolicies` (LOCKED Phase A `@resources/sonar_bank_app/config.lua`) automaticamente. **NO `opts.skip_fees`**, **NO `opts.fee_override_minor`**.

Rationale Q7: matemáticas simples, reglas aplican a todos, audit shape limpio, operator ajusta fees globales vía config.

### 10.6 Atomic guarantees per export

Cada Tier 1/2 mutation export ejecuta dentro de **un solo SQL transaction** con commit atomic de:

1. Balance mutation (`sonar_bank_accounts.balance` update).
2. Movement row insert (`sonar_bank_movements` append-only).
3. Audit row insert (`sonar_audit_log` 10-field shape per C-SEC-01 §1.2.A v0.3 R2, `event_type = bank_credit | bank_debit | bank_transfer | admin_credit | admin_debit | admin_set_balance | account_freeze | account_unfreeze | bank_overdraft`).
4. Idempotency row insert (si `opts.idempotency_key` presente) en `sonar_bank_idem`.

**Post-commit (best-effort, NO bloquea return):**

5. `publish_balance_update(citizen_id, balance_decimal_major, account_class, opts)` invocado per C-BE-05 §2.2.1 NetEvent CP1-B canonical (UNA call por account_class afectado: main + savings si transfer cross-account, sino una sola call). Path (a) Founder §9 LOCKED: signature de `publish_balance_update` preservada (`balance` arg en DECIMAL major) — wrapper invoca `units.from_minor(new_balance_minor)` antes del publish. Boilerplate canonical: ver `@docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md` §2.2.1.A.
6. `MirrorSync.SetBalance` best-effort framework wallet (player online).

**Si pasos 1-4 fallan → rollback total + return error.** Si paso 5 falla → log warning, NO rollback (StateBag/NetEvent eventual consistency aceptable). Si paso 6 falla → log warning, retry on next login.

Atomic mandate cross-ref C-SEC-01 AH4 v0.3 R2 (`@docs/technical/08_audit_hooks.md` §1.1).

### 10.7 Side effects table

| Side effect | Tier 1 mutations | Tier 2 mutations | Notas |
|---|---|---|---|
| `sonar_bank_accounts.balance` mutation | ✅ | ✅ | Atomic same TX. |
| `sonar_bank_movements` append | ✅ | ✅ | Append-only LOCKED Phase A. |
| `sonar_audit_log` append | ✅ | ✅ | 10-field shape C-SEC-01 §1.2.A v0.3 R2. |
| `sonar_bank_idem` upsert | ✅ si `opts.idempotency_key` | ✅ idem | NEW migration 036. |
| `sonar:bank:balance:update` NetEvent (per account_class) | ✅ | ✅ | C-BE-05 §2.2.1. DECIMAL major path (a). |
| `sonar:bank:savings:update` NetEvent | ✅ si savings affected | ✅ idem | Idem. |
| Mirror to framework wallet | ✅ best-effort | ✅ best-effort | `MirrorSync.SetBalance` simplificado C-BE-04 §4'.4. |
| Compliance autoraise hook | Mantained existing AR-P01/P02/P03 LOCKED | Mantained existing AR-P05 admin override LOCKED | C-SEC-03 §3.1 unchanged. |

### 10.8 GetApiVersion() informational export (NEW)

```lua
exports.sonar_bank_app:GetApiVersion()
-- returns table { major=1, minor=0, patch=0, phase='5', api_lock='2026-05-12' }
```

Consumers feature-detect via `local v = exports.sonar_bank_app:GetApiVersion(); if v.major >= 1 then ... end`. NO contado en los 21 mutation/read exports (es read-only informational, no audit). Total públicos = 22 (21 + 1 informational).

### 10.9 Performance budgets per export

Heredan budgets de service layer LOCKED. Wrapper overhead target:

- Validation + boundary conversion + audit insert + idempotency lookup: **<5 ms p99**.
- Total wrapper latency (incluido SQL TX): **<50 ms p99** Tier 1 reads, **<150 ms p99** Tier 1/2 mutations.
- Idempotency replay (cached hit): **<10 ms p99** (single PRIMARY KEY lookup).

Validación en Phase 5 ST-024 smoke harness (`@resources/sonar_bank/server/smoke_phase_5_exports.lua`).

### 10.10 Compat existing callbacks C001-C040

| Componente | Impacto | Acción |
|---|---|---|
| Callbacks C001-C040 + C001b signatures | ZERO breaking | None — todo LOCKED v1.0.1 R1 preservado intacto. |
| Auth helpers §2.3 H001 R1 | ZERO breaking | None. |
| Error codes registry §3.1 | ADDITIVE (1 NEW code `PLAYER_NOT_LOADED`) | Frontend callers tienen default branch — backwards compatible. |
| ACE matrix §2.2 | ZERO breaking | None. NEW Tier 2 reuse `sonar.bank.admin` P-ADMIN (Phase 5.1 perm decision). |
| Rate-limit infrastructure §4 | Exports NOT rate-limited Phase A (server-side trust) | DevOps Lead H4 runbook documents. |
| Idempotency lifecycle FSM #8 §9.2 + table `sonar_bank_idempotency_keys` | Mantained — callbacks siguen consumiendo este. Exports usan tabla separada `sonar_bank_idem` (migration 036). | None. |

---

## 11. Cross-references contratos

- C-BE-01 v0.1 — NetEvents emitted per callback referenciados en §9.x.7 side effects.
- C-BE-03 v0.1 — FSM transitions invoked via `<FSM>.Transition` lib (pattern §9 callbacks marked `FSM ref`).
- C-BE-04 v0.1 — `Bridges.Bank.*` API consumed por cada callback con mutation.
- C-BE-05 v0.1 — StateBag emits per CP1-A pattern §9.x.7. Privacy CP1-B per `dispute` + `compliance:queryDetail` + `loan:decisionResult`.
- C-SEC-01 (Security Lead H2) — audit hooks integration referenced en §9.x.7 (audit ledger entries) + compliance autoraise patterns §9.1.7 + §9.9.7.
- C-FE-01 (Frontend Lead H4) — UI callbacks consume con `lib.callback.await`.

---

## 12. Open questions BANK-BE.1

| OQ | Tema | Resolution target |
|---|---|---|
| **OQ-CBE02-01** | Daily transfer limit default Phase A — €50k? Configurable convar `sonar_bank_transfer_daily_limit`. | Default €50k. Founder confirma. |
| **OQ-CBE02-02** | Loan max simultaneous active per citizen Phase A — 3? | Default 3. Founder confirma. |
| **OQ-CBE02-03** | Recurring max active per citizen — 10? | Default 10. Founder confirma. |
| **OQ-CBE02-04** | Subsidy claim window — 30 days post-grant default? | Default 30d. Founder confirma. |
| **OQ-CBE02-05** | Stock buy/sell quantity vs amount-based — Phase A quantity-based o amount-based primary? | Default quantity-based (shares int). Amount-based pending Phase B. |

---

## 13. Sign-off matrix C-BE-02 v1.3 LOCKED target

| Stakeholder | Scope | Status DRAFT v0.1 |
|---|---|---|
| ☐ **Founder yaboula** | Final approval 40 callbacks + auth tiers + rate-limit budgets + idempotency policy + error codes registry | **PENDIENTE** review window |
| ☐ **Backend Lead (owner)** | Self-attest spec coherente con C-BE-01..05 + foundation BANK-BE.0 | **DRAFT v0.1 self-signed BANK-BE.1** |
| ☐ **Frontend Lead (consumer consultative)** | Acepta request/response schemas + error codes + rate-limit budgets para UX | **PENDIENTE** activation post-H3 |
| ☐ **Security Lead (consumer consultative)** | Acepta auth tiers + ACE matrix + idempotency framework + audit ledger event_type ENUM | **PENDIENTE** activation post-H2 |

---

## 14. Versioning C-BE-02

| Version | Fecha | Cambios |
|---|---|---|
| **v0.1 DRAFT** | 2026-05-06 (BANK-BE.1) | DRAFT inicial completo — framework §1-§7 (philosophy + auth tiers + ACE matrix + error codes registry + rate-limit framework + idempotency framework + side effects taxonomy + perf budgets) + tabla canonical 40 callbacks §8 + spec full C001-C040 §9.1-§9.40 (cumplimiento estructura formal §9.x.1-§9.x.10 — auth server-side + rate-limit explícito + idempotency keys + side effects audit ledger triggers per directriz founder BANK-BE.1). |

| **v1.0 LOCKED** | 2026-05-06 (BANK-BE.LOCK) | Promotion atomic post-DRAFT v0.1 review window. Sign-off triple ratificado: founder yaboula APPROVED + Backend Lead self-attested + Security Lead (consumer consultative — review crítico ACE matrix §2 + error codes §3 + idempotency §5 + audit ledger ENUM §6) handoff via H2. Promoted DRAFT → canonical: `docs/agents/teams/drafts/be_phase_a/c_be_02_api_contracts_v1_3.md` → `docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md`. Pointer §X.NEW Bank Phase A added en `docs/technical/04_api_contracts.md` v1.2 → v1.3 LOCKED. 40/40 callbacks C001-C040 ratificados. |
| **v1.0.1 R1 LOCKED** | 2026-05-06 (BANK-BE.LOCK.R1) | BANK-BE.AMEND.1 surgical patches Round 1 reactive a Security Lead audit C-SEC-01/02/03 v0.1 (founder APPROVED 2026-05-06): **H001** (`source.citizen_id` nil bypass — auth helpers canonical lib §2.3.1 `auth.require_citizen` + `require_owner` + `require_participant` + `require_role_or_owner` + boilerplate rewrite §2.3 + AP-AUTH-1 prohibido + notational disclaimer §2.3.2 + 9 callsites §9 reescritos a `Bridges.Player.GetCitizenId(source)` o helper canonical) + **H006** (C038 `compliance_flag_resolved` audit shape completa C-SEC-01 §1.2 mandatory `previous_flag_snapshot` forensics + cross_ref_audit_id) + **M002** (PRNG entropy spec §5.6 multi-entropy mix referenced canonical C-BE-04 §3.3.1 + AP-UUID-1 prohibido) + **M003** (C035 dual rate-limit recursive guard §9.35.5.1 — per-citizen 1/min + global 10/min sliding window + bypass exception scope='self' single-row + 2 convars sysadmin) + **M006** (C031 ATM HMAC secret management §9.31.7 — convar `sonar_bank_atm_hmac_secret` mandatory min 64 hex chars + defensive_abort si missing/short + audit boot events + AP-HMAC-1 prohibido). **Cross-cutting M004** (founder APPROVED architectural — CP1-A → CP1-B migration `bank.balance.<cid>` + `bank.savings.<cid>`): NEW callback **C001b** `sonar:bank:balance:snapshot` §9.4b + 14 callbacks side effects §9 reescritos `StateBag emits: bank.balance.<cid>` → `publish_balance_update(cid, balance, account_class, opts)` CP1-B NetEvent emit (C001 transfer / C002 savings deposit / C003 savings withdraw / C006 close / C009 escrow fund / C010 escrow release / C012 escrow refund / C016 subsidy grant / C018 subsidy claim / C020 loan decide / C021 loan repay / C023 stocks buy / C024 stocks sell / C031 ATM / C032 card request — listing canónico §6.1) + global note §6.1.2 deprecation + §6.2 ENUM cross-reference C-SEC-01 audit hook shape. Sin schema migration impact (DB Lead consultative confirmed). 4 convars DevOps H4 runbook (`sonar_bank_audit_query_per_citizen_per_min`, `sonar_bank_audit_query_global_per_min`, `sonar_bank_atm_hmac_secret`, cross-ref C-BE-04 M007). Security Lead BANK-SEC.1 re-audit ✅ PASS veredicto + `08_audit_hooks.md` v0.2. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested + Security Lead PASS. |

| **v1.0.2 R2 LOCKED** | 2026-05-12 (BANK-BE.PHASE_5.1.LOCK.R2) | Phase 5 ecosystem pivot Round 2 reactive a Founder LOCK Q1-Q8 + §9 path (a). **ADDITIVE only** — callbacks C001-C040 + C001b LOCKED v1.0.1 R1 ZERO breaking. **NEW §1.2 A18** Boundary convention split (INTEGER minor exports surface vs DECIMAL major callbacks/DB/Frontend Phase A; helpers `units.to_minor`/`from_minor` mandatory). **NEW §3.1 PLAYER_NOT_LOADED row** (HTTP 423, retry_after_event hint, distingue de PLAYER_NOT_FOUND + RESOURCE_NOT_FOUND, Q8 LOCKED). **NEW §10 entera** Server-to-Server Exports surface — 22 públicos = 21 mutation/read + 1 informational: §10.1 modelo + alcance + trust model GetInvokingResource + Founder Decision #1 LOCKED 22 explicit (NO polymorphic), §10.2 boundary helpers `lib/units.lua` mandatory, §10.3 Tier 1 11 exports (AddMoney/RemoveMoney/CanAfford/GetBalance/TransferBy{Source,Iban} + 5 *ByCitizen) + opts schema canonical (idempotency_key + correlation_id + account_iban + reason_meta) + sonar_bank_idem migration 036, §10.4 Tier 2 10 exports (AdminCredit/AdminDebit/AdminSetBalance/Freeze/Unfreeze + 5 *ByCitizen) + opts.allow_overdraft Q5 LOCKED + Auth.RequireAdmin 4-tier helper canonical + sonar:admin_allowlist convar, §10.5 rigid fee policy Q7 LOCKED (no opts override), §10.6 atomic guarantees per export (4-step SQL TX rollback total + post-COMMIT publish_balance_update path (a) + MirrorSync best-effort + cross-ref C-SEC-01 AH4 v0.3 R2), §10.7 side effects table, §10.8 GetApiVersion informational, §10.9 perf budgets, §10.10 compat callbacks ZERO breaking. **RENUMBER:** §10 Cross-references → §11, §11 Open questions → §12, §12 Sign-off matrix → §13, §13 Versioning → §14. Cross-cutting LOCK-time impacts: C-BE-04 v1.0.2 R2 (NULLIFY §4 + NEW §4') + C-BE-05 v1.0.2 R2 (§2.2.1.A wrapper consumer pattern + §2.2.1.B value type Phase A LOCKED) + C-SEC-01 v0.3 R2 (AH4 atomic + §1.2.A 10-field shape + bank_overdraft event_type). Security consumer review absorbed by PM Cascade per Founder Decision #3 — BANK-SEC.2 deuda técnica re-audit pending Phase B. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested + Security consumer PM Cascade absorbed + Frontend Lead consumer ack (callbacks LOCKED unchanged Phase A) + PM Cascade promote ceremony. |

— **C-BE-02 v1.0.2 R2 LOCKED** 2026-05-12 (BANK-BE.PHASE_5.1.LOCK.R2 ceremony). Sign-off founder + Backend Lead + Security consumer PM-absorbed + Frontend Lead consumer ack. **Effective immediately.** Phase 5 implementation Tier 1/2 exports per §10 + boundary helpers `units.lua` Phase 4.1 + sonar_bank_idem migration 036 Phase 4.2. Amendments adicionales require formal Round 3 protocol.
