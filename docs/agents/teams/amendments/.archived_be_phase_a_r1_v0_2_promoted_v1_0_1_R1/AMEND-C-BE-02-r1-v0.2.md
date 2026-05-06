# AMEND-C-BE-02-r1-v0.2 — Surgical Patches DRAFT

> **Target contract:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` v1.0 LOCKED → v1.0.1 R1 PENDING-LOCK.
> **Round:** 1 (BANK-BE.AMEND.1).
> **Status:** 🟡 DRAFT v0.2 — review founder + Security Lead.
> **Findings addressed:** H001 + H006 (HIGH) + M002 + M003 + M006 (MEDIUM AMEND).

---

## §1 — H001 fix · `source.citizen_id` nil bypass eradication

**Severity:** HIGH
**Spec ref:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:29` (§1 A11) + `:48-49` (§2.1 tier matrix) + multiple §9 auth check sections.
**Recommendation source:** `@docs/technical/08_audit_hooks.md:125-131`.

### Root cause analysis

`source` en FiveM Lua server-side es un **integer** (player handle), no una table. La notación `source.citizen_id` en pseudo-code y descripciones del contrato evalúa a `nil` en runtime. La comparación `nil == resource.owner_id` es `false` casi siempre **excepto** cuando `resource.owner_id` también es `nil` (e.g. NPC accounts, govt accounts pre-init, malformed DB rows) — entonces `nil == nil → true` y la auth se bypassa.

El boilerplate principal §2.3 (línea 82) ya usa `Bridges.Player.GetCitizenId(source)` correctamente — pero la propagación notacional `source.citizen_id` aparece **>10 veces** como descriptor de patrones, lo que normaliza el anti-patrón en el imaginario implementador.

### 1.1 BEFORE (LOCKED v1.0) — §1 principle A11

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:29
- **A11** **Auth Server-side mandatory en cada callback** — `IsPlayerAceAllowed(src, perm)` o `source.citizen_id == resource.owner_id` o equivalent. NUNCA trust client claim.
```

### 1.1 AFTER (DRAFT v0.2)

```markdown
- **A11** **Auth Server-side mandatory en cada callback** — `IsPlayerAceAllowed(src, perm)` o resolución `local citizen_id = Bridges.Player.GetCitizenId(source)` + nil-check obligatorio + comparación contra `resource.owner_id` o equivalent. **NUNCA `source.citizen_id` como acceso directo** — `source` es integer player handle, NO table (anti-pattern AP-AUTH-1 prohibido `@.windsurf/rules/bank.md`). NUNCA trust client claim.
```

### 1.2 BEFORE — §2.1 auth tier matrix check pattern column

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:48-49
| **AUTH-OWNER** | Solo owner del recurso. | `source.citizen_id == resource.owner_id` |
| **AUTH-OWNER_OR_PARTICIPANT** | Owner o participant explícito (e.g. escrow → payer/payee). | `source.citizen_id ∈ {resource.payer_id, resource.payee_id}` |
```

### 1.2 AFTER

```markdown
| **AUTH-OWNER** | Solo owner del recurso. | `auth.require_owner(source, resource.owner_id)` — internamente: `local cid = Bridges.Player.GetCitizenId(source); return cid ~= nil and cid == resource.owner_id` |
| **AUTH-OWNER_OR_PARTICIPANT** | Owner o participant explícito (e.g. escrow → payer/payee). | `auth.require_participant(source, {resource.payer_id, resource.payee_id})` — same nil-safe pattern, set membership |
```

### 1.3 ADD NEW — §2.3.1 Auth helpers canonical lib

Insert after current §2.3 (boilerplate code block). New subsection:

```markdown
### 2.3.1 Auth helpers lib (NEW v0.2 R1) — `sonar_bridges/lib/auth_helpers.lua`

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

**Anti-patrón AP-AUTH-1 (H001 root cause):**
```lua
-- ❌ NUNCA. source es integer, source.citizen_id evalúa nil. Si owner_id también es nil (govt/system rows) → bypass.
if source.citizen_id == account.owner_id then ... end

-- ✅ SIEMPRE.
local ok, err = auth.require_owner(source, account.owner_id)
if not ok then return { status='error', error={ code=err } } end
```
```

### 1.4 BEFORE — §2.3 boilerplate (post-A11 line)

The current boilerplate at §2.3 is functionally correct (uses `Bridges.Player.GetCitizenId`). **Reinforce with prominent comment + auth helper integration:**

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:81-89
  -- A11: Auth check server-side mandatory
  local citizen_id = Bridges.Player.GetCitizenId(source)
  if not citizen_id then
    return { status = 'error', error = { code = 'AUTH_REQUIRED' } }
  end

  -- Per-callback specific auth tier:
  -- (AUTH-OWNER example) if not is_owner(citizen_id, payload.resource_id) then return { code = 'AUTH_FORBIDDEN' } end
  -- (AUTH-ROLE example) if not IsPlayerAceAllowed(source, '<perm>') then return { code = 'AUTH_ACE_DENIED' } end
```

### 1.4 AFTER

```lua
  -- A11 (R1 H001 fix): Auth check server-side mandatory via canonical helpers.
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
```

### 1.5 BEFORE — §9 auth check sections (notational shorthand fix)

Múltiples auth check secciones del §9 contienen notación shorthand `source.citizen_id`. **Patch global notacional**: cambiar TODAS las ocurrencias de `source.citizen_id` en descripciones (no en código real boilerplate línea 82) por `Bridges.Player.GetCitizenId(source)` o `auth.require_*(source, ...)`.

**Lugares afectados** (verified via grep `:source\\.citizen_id` en C-BE-02):
- `:413` (9.1.1 transfer auth tier)
- `:456-457` (9.1.4 — ya correcto, mantener)
- `:541` (9.2.4)
- `:624` (9.5)
- `:710` (9.7.4)
- `:771` (9.9.4)
- `:1003` (9.19.4)
- `:1407` (9.35.4)
- `:1475` (9.39 auth check)

### 1.5 AFTER — single global rule

**§2.3 nuevo párrafo NEW (after 2.3.1):**

```markdown
### 2.3.2 Notational disclaimer (R1 H001 fix)

A lo largo del §9 callback specifications, las descripciones textuales como _"source must equal payer (auto-derived from `source.citizen_id`)"_ o _"AUTH-OWNER (citizen_id default = `source.citizen_id`)"_ son **shorthand semántico**. **El código real DEBE usar `auth.require_*` helpers** §2.3.1 — NUNCA acceso directo `source.citizen_id`.

A partir de v0.2 R1, todas estas descripciones se reescriben como `Bridges.Player.GetCitizenId(source)` o invocación helper canónica para evitar ambigüedad.
```

**Surgical replacements §9** (literal find/replace):
- `source.citizen_id` → `Bridges.Player.GetCitizenId(source)` (descripciones).
- `Source.citizen_id` → `Bridges.Player.GetCitizenId(source)`.

### 1.6 Test scenarios (Security Lead validation)

- [ ] **T-AMEND-H001.1** — Mock callback con `auth.require_owner(source=42, owner_id=nil)` → return `false, 'AUTH_FORBIDDEN'` (NO bypass).
- [ ] **T-AMEND-H001.2** — Mock callback con `source=0` (console) que no resuelve citizen → `auth.require_citizen` returns `nil, 'INVALID_SOURCE'`.
- [ ] **T-AMEND-H001.3** — Static grep CI: `source\.citizen_id` debe retornar 0 hits en `resources/sonar_*/server/**.lua` (post-implementation Phase A code).
- [ ] **T-AMEND-H001.4** — Lint rule `sonar_lint_no_source_dot_citizenid.lua` propuesto a DevOps Lead (Phase B).

---

## §2 — H006 fix · C038 resolveFlag audit shape completa

**Severity:** HIGH
**Spec ref:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:1463` (§9.38) + `:291-322` (§6.2 audit ledger ENUM).
**Recommendation source:** `@docs/technical/08_audit_hooks.md:165-171`.

### Root cause

§9.38 C038 declara side effect `audit event_type='compliance_flag_resolved' con full resolution_notes` — pero NO especifica shape completo del audit hook entry. Security Lead C-SEC-01 §1.2 spec exige shape mandatory: `{flag_id, resolver_id, resolution, resolution_notes, resolved_at, previous_flag_snapshot}`. Falta de `previous_flag_snapshot` es CRÍTICO para forensics (admin tampering detection).

### 2.1 BEFORE — §9.38 side effects

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:1463
**Side effects:** UPDATE `sonar_bank_compliance_flags.status` + UPDATE `bank.compliance.<cid>.public` reduced bag (count decrement/recompute) + audit `event_type='compliance_flag_resolved'` con full resolution_notes (admin trail) + audit `event_type='admin_force_action'` cross-reference.
```

### 2.1 AFTER

```markdown
**Side effects:**
1. **DB UPDATE** `sonar_bank_compliance_flags` SET `status=payload.resolution`, `resolved_at=NOW()`, `resolver_id=citizen_id`, `resolution_notes=payload.resolution_notes` WHERE flag_id=payload.flag_id (atomic transaction with §2 step audit insert).
2. **DB SNAPSHOT pre-update** — SELECT row antes de UPDATE → serialize as JSON → pass como `previous_flag_snapshot` al audit hook (forensics tamper detection).
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
     "previous_flag_snapshot": { /* full pre-update flag row */ },
     "source_resource": "sonar_bank_app"
   }
   ```
5. **Audit ledger cross-reference** — INSERT segundo entry `event_type='admin_force_action'` con `cross_ref_audit_id` apuntando al `compliance_flag_resolved` row recién insertado (admin override path forensics).
6. **NetEvent** server→admin `sonar:bank:compliance:flagResolved` (target P10 admins) — payload pública minimal `{flag_id, status_new, resolver_id, resolved_at}`. NO `previous_flag_snapshot` (queda solo en audit ledger).
```

### 2.2 BEFORE — §6.2 audit ledger ENUM (`compliance_flag_resolved` already listed)

Already canonical line `:318` lists `compliance_flag_resolved`. **No change to ENUM** — solo add cross-reference note.

### 2.2 AFTER — §6.2 add comment block

After the current ENUM block (after line 322), append:

```markdown
**Shape canonical per event_type** — para audit hooks críticos (HIGH+ severity) la shape mandatory está definida en `@docs/technical/08_audit_hooks.md` §1.2 C-SEC-01 spec. Backend Lead implementations DEBEN cumplir shape mínima. Diferencias requieren amendment formal Round.
```

### 2.3 Test scenarios

- [ ] **T-AMEND-H006.1** — C038 callback execution → audit ledger entry contiene `previous_flag_snapshot` no-empty + cross_ref_audit_id válido.
- [ ] **T-AMEND-H006.2** — Snapshot pre-update siempre tomado en MISMA transacción que el UPDATE (atomic).
- [ ] **T-AMEND-H006.3** — Schema validation: audit row JSON satisface shape C-SEC-01 §1.2 (Security Lead provides JSONSchema validator post-AMEND lock).

---

## §3 — M002 fix (parcial C-BE-02) · UUID v4 CSPRNG entropy

**Severity:** MEDIUM
**Spec ref:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:96` (boilerplate UUID call) + §5.2 lib (storage spec).
**Recommendation source:** `@docs/technical/08_audit_hooks.md:181-187`.

> Cross-reference: M002 también afecta C-BE-04 §3.3 — patch en `AMEND-C-BE-04-r1-v0.2.md` §4. Aquí solo definimos el **lib spec canónica** consumida por C-BE-02.

### 3.1 BEFORE — §5.2 lib idempotency (uses Bridges.UUID.v4)

The lib `IdempotencyKeys.Lock(idempotency_key, '<callback_domain>', payload)` (línea 97 boilerplate) and §5.2 reference `Bridges.UUID.v4()` per ADR-018 — but no PRNG spec.

### 3.1 ADD NEW — §5.6 PRNG entropy spec

Insert after §5.5 (mandatory vs optional). New subsection:

```markdown
### 5.6 PRNG entropy spec (NEW v0.2 R1 — M002 fix)

`Bridges.UUID.v4()` (`@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md` §3.3 R1) es la **única source canónica** de UUIDs en SONAR Bank. Su implementación cumple:

- **PRNG:** combinación de 4 entropy sources mixed via SHA256:
  1. `os.clock()` (sub-second monotonic).
  2. `GetGameTimer()` (FiveM-internal monotonic).
  3. `os.time() * 1000` (epoch ms).
  4. **Per-call entropy:** `GetPlayerPing(source)` si `source > 0`, sino `math.random(1, 2^31-1)` re-seeded con `GetGameTimer()` cada llamada.
- **Output format:** 8-4-4-4-12 hex (RFC 4122 v4, 122-bit randomness target).
- **Rationale:** `math.random()` plain en FiveM Lua usa seed estática inicial (predictable post-boot) → riesgo CSPRNG insuficiente para correlation-id mutex (CP2). Mixing 4 sources eleva entropy efectiva y previene predicción adversaria por resource cheat que llame `Bridges.UUID.v4()` paralelo intentando colisión.
- **Phase B target:** migrar a FFI crypto nativo (`require('crypto.random_bytes')(16)`) si disponible vía oxmysql/lua-crypto bindings. Phase A: pure-Lua mix acceptable.

**Anti-patrón AP-UUID-1 (M002 root cause):**
```lua
-- ❌ NUNCA. math.random sin re-seed → predictable post-boot. Colisión correlation-id = CP2 mutex bypass.
local function bad_uuid() return string.format('%08x-%04x-...', math.random(0, 0xffffffff), math.random(0, 0xffff), ...) end

-- ✅ SIEMPRE.
local uuid = Bridges.UUID.v4()  -- consumes lib canonical multi-entropy mix.
```
```

### 3.2 BEFORE — boilerplate línea 96

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:96
  local idempotency_key = payload.idempotency_key or Bridges.UUID.v4()
```

### 3.2 AFTER (no change to line — just clarification comment)

```lua
  -- A13: Idempotency (mutations only). Bridges.UUID.v4 spec §5.6 PRNG multi-entropy (R1 M002 fix).
  local idempotency_key = payload.idempotency_key or Bridges.UUID.v4()
```

### 3.3 Test scenarios

- [ ] **T-AMEND-M002.1** — 1M iterations `Bridges.UUID.v4()` paralelo → 0 colisiones.
- [ ] **T-AMEND-M002.2** — Distinct seed re-init across 10 server boots → no UUID prefix collision (validar entropy mix).
- [ ] **T-AMEND-M002.3** — Static lint: `math.random` directo prohibido en `lib/uuid.lua` (lint rule Phase B).

---

## §4 — M003 fix · C035 audit query recursive DDoS

**Severity:** MEDIUM
**Spec ref:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:1377-1420` (§9.35 C035).
**Recommendation source:** `@docs/technical/08_audit_hooks.md:189-195`.

### Root cause

C035 `bank.audit.query` cada execución genera audit entry `audit_query_executed`. Llamadas recursivas (e.g. admin queries audit, audit insert dispara nuevo audit, etc.) causan explosión logarítmica O(n²). Standard rate-limit token bucket general no es suficiente para este patrón recursivo.

### 4.1 ADD NEW — §9.35.7 special rate-limit

Insert as new sub-section §9.35.7 after current §9.35.6 (rate-limit). NEW:

```markdown
#### 9.35.7 Special recursive rate-limit (NEW v0.2 R1 — M003 fix)

C035 implementa **dual rate-limit**:
1. **Standard token bucket** §4.3 framework (tier NORMAL or LOW per scope).
2. **Recursive guard NEW (M003):** independiente del bucket general.
   - **Per-citizen:** max **1 audit query per minute** per `citizen_id` (sliding window 60s).
   - **Global:** max **10 audit queries per minute** server-wide (sliding window 60s).
   - **Storage:** in-RAM ring buffer (Phase A acceptable per M001 advisory) en `sonar_bridges/lib/audit_query_throttle.lua` NEW.
   - **On reject:** return `{ status='error', error={ code='AUDIT_QUERY_THROTTLED', retry_after_ms=<remaining_window> } }` + audit hook `audit_hook_rate_limit_violation` con context `recursive_audit_query`.
   - **Bypass exception:** queries con scope=`'self'` **single-row by movement_id** (e.g. drill-down detail single audit_id) **excluyen** del recursive guard — usan bucket general only.

**Rationale:** previene DoS recursivo + mantiene UX legítimo (admin self-audit detail single-record). Convars `sonar_bank_audit_query_per_citizen_per_min=1` + `sonar_bank_audit_query_global_per_min=10` configurables sysadmin.
```

### 4.2 Test scenarios

- [ ] **T-AMEND-M003.1** — 10 calls C035 same citizen en 60s → call #2 returns `AUDIT_QUERY_THROTTLED`.
- [ ] **T-AMEND-M003.2** — 11 calls C035 distintos citizens en 60s → call #11 returns `AUDIT_QUERY_THROTTLED` (global cap).
- [ ] **T-AMEND-M003.3** — 100 calls C035 scope='self' single audit_id → todas pasan (bypass exception válido).
- [ ] **T-AMEND-M003.4** — Audit ledger contiene entry `audit_hook_rate_limit_violation` por cada throttle.

---

## §5 — M006 fix · ATM HMAC secret management

**Severity:** MEDIUM
**Spec ref:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:1247-1253` (§9.31 C031).
**Recommendation source:** `@docs/technical/08_audit_hooks.md:213-219`.

### Root cause

C031 ATM minigame session HMAC `HMAC(action+amount+session_id+server_secret)` previene tampering — pero spec actual NO define provenance/storage/rotation de `server_secret`. Hardcode en `.lua` file = leakable via repository compromise. Sin rotation = adversary que extraiga secret 1 vez tiene tampering capability indefinida.

### 5.1 ADD NEW — §9.31.7 HMAC secret spec

Insert as §9.31.7 after current §9.31.6 (or end-of-callback). NEW:

```markdown
#### 9.31.7 HMAC secret management (NEW v0.2 R1 — M006 fix)

**`server_secret` provenance + storage + rotation:**

- **Storage:** **convar exclusiva `sonar_bank_atm_hmac_secret`** declarada en `server.cfg` (NUNCA en `.lua` file dentro del repo). Default value vacío `""` → resource fail boot defensivo (`defensive_abort('atm_hmac_secret_missing', ...)`) si convar empty.
- **Provenance:** generated by sysadmin ANTES de primera deploy via:
  ```bash
  # Documentado en runbook DevOps H4 deploy guide.
  openssl rand -hex 32  # 32 bytes (64 hex chars) entropy mínima.
  ```
- **Min length:** 32 bytes (64 hex chars). Resource boot valida `#secret >= 64` o defensive abort.
- **Rotation:** manual on-demand (no auto-rotation Phase A). Sysadmin updates `server.cfg` convar + `txAdmin restart sonar_bank` → all in-flight ATM sessions invalidated (acceptable: ATM minigame TTL <60s).
- **Phase B:** rotation rolling con dual-secret window (current + previous accepted 5min) para zero-downtime rotation. Phase A: hard-cut acceptable.
- **NEVER:** secret en `.lua` file, en git history, en logs (incluso debug). HMAC verify falla siempre logged WITHOUT secret material.
- **Audit:** boot event `atm_hmac_secret_loaded_OK` (sin secret material) + `atm_hmac_secret_failed_validation` si len<64.

**Anti-patrón AP-HMAC-1 (M006 root cause):**
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
```

### 5.2 Test scenarios

- [ ] **T-AMEND-M006.1** — Boot con convar empty → `defensive_abort('atm_hmac_secret_missing')` + `BANK_DISABLED` activo.
- [ ] **T-AMEND-M006.2** — Boot con convar 32-char (insufficient) → `defensive_abort('atm_hmac_secret_short')`.
- [ ] **T-AMEND-M006.3** — Boot con convar válido 64-hex → boot OK + audit entry `atm_hmac_secret_loaded_OK` (sin secret material).
- [ ] **T-AMEND-M006.4** — Static grep CI: `sonar_bank_atm_hmac_secret\s*=\s*['"]` debe retornar 0 hits in repo (post-implementation).

---

## §6 — Versioning + sign-off

### 6.1 Versioning entry (post-LOCK promotion)

Append a §13 Versioning C-BE-02 row pendiente:

```markdown
| **v1.0.1 R1 LOCKED** | TBD post-founder approval | BANK-BE.AMEND.1 surgical patches Round 1 reactive a Security Lead audit C-SEC-01/02/03 v0.1: H001 (`source.citizen_id` nil bypass — auth helpers canonical lib + AP-AUTH-1 prohibited) + H006 (C038 audit shape completa C-SEC-01 spec) + M002 (UUID v4 multi-entropy PRNG mix) + M003 (C035 recursive DDoS guard dual rate-limit) + M006 (ATM HMAC secret convar mandatory). Sin schema migration impact (DB Lead consultative confirmed). Sign-off founder + Backend + Security re-audit. |
```

### 6.2 Sign-off (this AMEND file)

| Rol | Status |
|---|---|
| Backend Lead (Cascade) | ✅ self-attested DRAFT v0.2 emitted |
| Founder yaboula | ⏳ PENDING review |
| Security Lead (Cascade) | ⏳ PENDING re-audit closure H001 + H006 + M002 + M003 + M006 |

---

**FIN AMEND-C-BE-02-r1-v0.2 DRAFT** — 5 patches surgical (H001 + H006 + M002-partial + M003 + M006).
