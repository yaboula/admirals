# AMEND-C-BE-05-r1-v0.2 — Surgical Patches DRAFT

> **Target contract:** `@docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md` v1.0 LOCKED → v1.0.1 R1 PENDING-LOCK.
> **Round:** 1 (BANK-BE.AMEND.1).
> **Status:** 🟡 DRAFT v0.2 — review founder + Security Lead.
> **Findings addressed:** **M004 (MEDIUM ⚠️ ARCHITECTURAL — founder APPROVED 2026-05-06).**

---

## §0 — Founder approval ratification

**M004 ADVISORY → APPROVED ARCHITECTURAL CHANGE (founder yaboula 2026-05-06):**

> _"M004: Aprobado al 100%. Ejecuta la migración de `bank.balance.<cid>` de CP1-A a CP1-B de inmediato. La privacidad financiera (Cero conocimiento para terceros) es un pilar innegociable de este producto."_

**Backend Lead extension (recommendation):** **`bank.savings.<citizen_id>` migrates also to CP1-B** by privacy parity (savings balance es financial PII tier idéntico al main balance). Si founder prefiere split (only main migrates), patch se reduce a `bank.balance.*` solamente — ambas variantes documentadas §3 below.

**Out-of-scope este patch (mantienen CP1-A):**
- `bank.business_treasury.<company_id>` — explícitamente "Government Console visible anyway" per spec.
- `bank.compliance.<citizen_id>.public` — already reduced shape (count + bool only, no detail).
- `bank.govt.taxBrackets` / `bank.govt.subsidies.active` — public law/knowledge.
- `bank.bridges.status` — transparency by design (CP8 + Q16.3).
- `bank.elections.<election_id>` — public phase info.
- `bank.recurring.<citizen_id>.summary` — metadata-only (count + next timestamp), no balance disclosure. Founder may revisit Phase B si privacy concern surge.

---

## §1 — M004 Architectural migration · `bank.balance.<cid>` CP1-A → CP1-B

**Severity:** MEDIUM (⚠️ ARCHITECTURAL — Frontend Lead consume pattern breaks; safe to apply now since Frontend not yet activated).
**Spec ref:** `@docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md` §1.5 + §2.1 + §3 + §4.
**Recommendation source:** `@docs/technical/08_audit_hooks.md:197-203`.

### Root cause analysis

CP1-A pattern (`GlobalState['bank.balance.<citizen_id>'] = balance`) genera **broadcast read-side a todos los clients** del servidor — FiveM engine NO filtra reads global state per-client. Cualquier cliente con un citizen_id (públicamente derivable de la roster) puede leer el balance de cualquier otro player. Contradice principio Zero-Knowledge de privacidad financiera.

`bank.savings.<citizen_id>` tiene idéntica clasificación PII financiera → mismo migration path por privacy parity (Backend Lead recommendation).

### 1.1 BEFORE — §1.5 patterns correctos

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md:43-45
- ✅ `GlobalState['bank.balance.<citizen_id>'] = number` — citizen propio lee, otros clients también pueden leer pero NO es leak (balance no es PII per se en este contexto).
- ✅ `TriggerLatentClientEvent('sonar:bank:complianceDetail', adminSource, payload)` — admin-only fire post ACE check.
- ✅ `TriggerLatentClientEvent('sonar:bank:escrowStateChanged', payerSource, payload); TriggerLatentClientEvent('sonar:bank:escrowStateChanged', payeeSource, payload)` — participants only.
```

### 1.1 AFTER (DRAFT v0.2)

```markdown
- 🚫 ~~`GlobalState['bank.balance.<citizen_id>']`~~ **REMOVED v0.2 R1 (M004 founder APPROVED)** — financial-grade privacy: balance es PII financiera. Migrated to CP1-B NetEvent pattern below.
- 🚫 ~~`GlobalState['bank.savings.<citizen_id>']`~~ **REMOVED v0.2 R1 (M004 parity Backend Lead rec)** — same reasoning.
- ✅ **NEW v0.2 R1:** `TriggerLatentClientEvent('sonar:bank:balance:update', ownerSource, { balance, account_class, occurred_at, correlation_id })` — owner-only fire post citizen_id == owner check (CP1-B). Admin govt audit ACE-checked vía evento separado `sonar:bank:balance:adminAudit` (P11).
- ✅ `TriggerLatentClientEvent('sonar:bank:complianceDetail', adminSource, payload)` — admin-only fire post ACE check.
- ✅ `TriggerLatentClientEvent('sonar:bank:escrowStateChanged', payerSource, payload); TriggerLatentClientEvent('sonar:bank:escrowStateChanged', payeeSource, payload)` — participants only.
```

### 1.2 BEFORE — §2.1 public bags table (rows balance/savings)

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md:53-56
| Key pattern | Type | Owner writer | Reader pattern | Privacy classification |
|---|---|---|---|---|
| `bank.balance.<citizen_id>` | `number` (DECIMAL atomic — fiat units, e.g. `1234.56` for €1,234.56) | `sonar_bank_app/server/balance_publisher.lua` | Frontend `AddStateBagChangeHandler('global', 'bank.balance.<citizen_id_self>')` | **Public-safe.** Citizen propio + servidor ven. Otros clients pueden leer numéricamente — no PII directa. |
| `bank.savings.<citizen_id>` | `number` (DECIMAL atomic) | mismo | mismo | Public-safe. Mismo razonamiento balance. |
```

### 1.2 AFTER

**Remove rows entirely from §2.1 public bags table.** Add nota inmediatamente después de la tabla:

```markdown
> **REMOVED v0.2 R1 (M004 founder APPROVED 2026-05-06):**
> - ~~`bank.balance.<citizen_id>`~~ → migrated to CP1-B `sonar:bank:balance:update` NetEvent (see §2.2.2 below).
> - ~~`bank.savings.<citizen_id>`~~ → migrated to CP1-B `sonar:bank:savings:update` NetEvent (parity).
>
> **Razón:** financial-grade privacy non-negotiable. CP1-A read-broadcast a todos clients FiveM-nativo NO permite filtrado per-client server-side — cualquier cliente con citizen_id derivable (públicamente accesible vía roster `GetPlayers()`) lee balance ajeno. Contradice principio Zero-Knowledge.
```

### 1.3 BEFORE — §2.2 restricted bags pattern (extend with new NetEvent rows)

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md:65
### 2.2 Restricted bags (CP1-B) — discrete NetEvents directos a participants/admin
```

### 1.3 AFTER — §2.2 reescrita + 2 nuevos rows

Mantener título sub-section. Después del párrafo intro (línea 67 `**Pattern:** **NO se publican...**`), insertar tabla NEW antes del §2.2.1 actual (compliance):

```markdown
### 2.2 Restricted bags (CP1-B) — discrete NetEvents directos a participants/admin

**Pattern:** **NO se publican en GlobalState.** Backend fires NetEvent dirigido al target source con ACE check server-side antes.

| Domain | NetEvent name | Target audience | ACE / role check |
|---|---|---|---|
| **Account balance update (NEW v0.2 R1 M004)** | `sonar:bank:balance:update` | **Owner only** — single target source resolved from `Bridges.Player.GetSource(citizen_id)` | Server-side: target must be online AND `Bridges.Player.GetCitizenId(target_source) == account.owner_id`. NO admin broadcast (admin path uses `sonar:bank:balance:adminAudit` separate event con P11 ACE). |
| **Savings balance update (NEW v0.2 R1 M004 parity)** | `sonar:bank:savings:update` | Owner only — same target resolution. | Same nil-safe + ownership check. |
| **Account balance admin audit (NEW v0.2 R1 M004)** | `sonar:bank:balance:adminAudit` | Admin govt clients ONLY (audit query response) | `IsPlayerAceAllowed(src, 'sonar.bank.govt.audit.full')` (P11). Fired ON-DEMAND post C035 audit query callback. NO push automatic on every mutation. |
| Compliance flag detail | `sonar:bank:compliance:detail` | Admin govt clients only | `IsPlayerAceAllowed(src, 'sonar.bank.govt.audit.full')` |
| Escrow state change | `sonar:bank:escrow:stateChanged` | Payer source + Payee source + admin clients (3 fires separados) | Per-target identity check: `Bridges.Player.GetCitizenId(source) ∈ {escrow.payer_id, escrow.payee_id}` OR `sonar.bank.govt.audit.full` |
| Audit ledger query result | `sonar:bank:audit:queryResult` | Requester (per Q13 3 scopes) | Per-scope ACE: `sonar.bank.audit.self` / `sonar.bank.empresas.<id>` / `sonar.bank.govt.audit.full` |
| Loan approval/rejection | `sonar:bank:loan:decisionResult` | Loan applicant source + admin source | `Bridges.Player.GetCitizenId(source) == loan.applicant_id` OR admin |
| Election votes raw access | `sonar:bank:elections:votesRaw` | Admin govt clients only (Q-DB-H dual-layer privacy) | `IsPlayerAceAllowed(src, 'sonar.bank.govt.audit.full')` |
| Business treasury approval pending | `sonar:bank:business:approvalPending` | Multi-signers de la empresa (M-of-N) | `Bridges.Player.GetCitizenId(source) ∈ business.signers_list` |
| Physical card pin failure / freeze | `sonar:bank:card:pinFailure` | Card owner source only | `Bridges.Player.GetCitizenId(source) == card.owner_id` |
```

### 1.4 ADD NEW — §2.2.1 Balance update NetEvent spec (canonical)

Insert as new sub-section (before existing §2.2.x compliance / escrow blocks):

```markdown
#### 2.2.1 `sonar:bank:balance:update` canonical spec (NEW v0.2 R1 — M004)

**Purpose:** notify balance owner of any balance change (mutation reactivity replaces deprecated CP1-A StateBag pattern).

**Server-side fire pattern (boilerplate):**

```lua
-- sonar_bank_app/server/balance_publisher.lua (R1 M004 rewrite from CP1-A → CP1-B)
local function publish_balance_update(citizen_id, balance, account_class, opts)
  -- account_class: 'main' | 'savings' (route to corresponding event below).
  -- opts: { correlation_id?, occurred_at? } optional.

  -- Resolve target source from citizen_id (offline → no fire, balance persisted DB anyway).
  local target_source = Bridges.Player.GetSourceByCitizenId(citizen_id)
  if not target_source or target_source <= 0 then
    -- Player offline → skip event fire. Balance read on next login via callback C001b `bank.balance.snapshot` (NEW callback — see cross-cutting §4 below).
    return
  end

  -- Server-side ownership check defensive (target must own this citizen_id).
  local target_cid = Bridges.Player.GetCitizenId(target_source)
  if target_cid ~= citizen_id then
    -- Source mismatch — defensive abort, do NOT fire (would leak balance to wrong player on edge case).
    log_security_alert('balance_publish_source_mismatch', { citizen_id = citizen_id, target_source = target_source, resolved_cid = target_cid })
    return
  end

  -- Event name routing per account_class
  local event_name = (account_class == 'savings') and 'sonar:bank:savings:update' or 'sonar:bank:balance:update'

  -- Latent fire (NOT critical-priority — balance updates batched-acceptable).
  TriggerLatentClientEvent(event_name, target_source, 50000, {  -- 50KB/s budget per Q-FE-pre cap (Frontend Lead amendable H4)
    citizen_id = citizen_id,
    balance = balance,
    account_class = account_class,
    occurred_at = (opts and opts.occurred_at) or (os.time() * 1000),
    correlation_id = (opts and opts.correlation_id) or Bridges.UUID.v4(),
    schema_version = '1.0',
  })
end
```

**Client-side consumer pattern (Frontend Lead C-FE-* — NEW v0.2 R1):**

```lua
-- Replaces deprecated AddStateBagChangeHandler('global', 'bank.balance.<cid>') pattern.
RegisterNetEvent('sonar:bank:balance:update', function(payload)
  -- payload: { citizen_id, balance, account_class='main', occurred_at, correlation_id, schema_version }
  -- Validate schema_version on first receive (Phase B enforcement L001).
  if payload.schema_version ~= '1.0' then
    print('[sonar:bank:balance:update] unknown schema_version: ' .. tostring(payload.schema_version))
    return
  end
  -- Update local UI state — Zustand store / NUI bridge per C-FE-* pattern.
  SetNuiFocusKeepBalance(payload.balance)
end)

RegisterNetEvent('sonar:bank:savings:update', function(payload)
  -- Same pattern, account_class='savings'.
end)
```

**Performance budget (Backend Lead allocation):**

- Per-event fire payload: ~150 bytes (citizen_id 36 + balance 16 + account_class 7 + occurred_at 13 + correlation_id 36 + schema_version 5 + JSON wrap overhead ~37).
- TriggerLatentClientEvent rate: bandwidth budget 50KB/s per player default — at 150B/event allows 333 events/sec sustained per player. Bank balance changes typically <1/min per player (transfers, payroll cron). Headroom enormous.
- Replaces CP1-A `GlobalState[key] = value` write (FiveM native event ~80 bytes broadcast a todos N clients) → migration **REDUCES total bandwidth** in N-player server (from O(N) to O(1) per balance change).
```

### 1.5 ADD NEW — §2.2.2 Initial balance snapshot on player connect

After §2.2.1, insert:

```markdown
#### 2.2.2 Initial balance snapshot — replace hydrate-on-boot pattern (NEW v0.2 R1 — M004)

**Pre-M004 pattern:** §4.1 boot init hydrate ALL balances from DB → publish to GlobalState. Player connects → reads StateBag immediately.

**Post-M004 pattern:** balance NO se hydrata broadcast. Player connect:

1. **Server-side `playerJoining` handler** (sonar_bank_app/server/connect_handler.lua NEW):
   ```lua
   AddEventHandler('playerJoining', function()
     local source = source
     -- Defer balance fetch until citizen_id resolves post-character-load.
     Citizen.SetTimeout(2000, function()
       local cid = Bridges.Player.GetCitizenId(source)
       if not cid then return end  -- char not loaded yet; client will request via callback C001b
       local balance = MySQL.scalar.await('SELECT balance FROM sonar_bank_accounts WHERE owner_id = ? AND account_class = ? LIMIT 1', { cid, 'main' })
       local savings = MySQL.scalar.await('SELECT balance FROM sonar_bank_accounts WHERE owner_id = ? AND account_class = ? LIMIT 1', { cid, 'savings' })
       publish_balance_update(cid, balance or 0, 'main', { correlation_id = 'connect_initial' })
       publish_balance_update(cid, savings or 0, 'savings', { correlation_id = 'connect_initial' })
     end)
   end)
   ```

2. **Client-side fallback callback C001b NEW** `sonar:bank:balance:snapshot`:
   - Auth: AUTH-OWNER (returns own balances only).
   - Use case: client UI mount lifecycle requests balances if no `:update` event received yet (timing race).
   - Returns `{ main: number, savings: number, occurred_at, correlation_id }`.
   - Cross-cutting: **add C-BE-02 §9 NEW callback C001b** (see §4 cross-cutting impacts below).

**Bandwidth impact:** N-player server: previously hydrate on boot = N × StateBag write broadcast (O(N²) read-fan). NEW pattern: lazy per-player connect = O(1) per join. **Significant bandwidth reduction.**
```

### 1.6 BEFORE — §3 naming convention examples

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md:116-117
| `bank` | Prefijo fijo Bank Phase A. | `bank.balance.123` |
| `<domain>` | `balance` / `savings` / `business_treasury` / `compliance` / `govt` / `bridges` / `elections` / `recurring`. | `bank.balance.123` |
```

### 1.6 AFTER

```markdown
| `bank` | Prefijo fijo Bank Phase A. | `bank.business_treasury.abc-123` (post-M004 R1: `bank.balance.*` + `bank.savings.*` removed from StateBag — see §2.1) |
| `<domain>` | `business_treasury` / `compliance` / `govt` / `bridges` / `elections` / `recurring`. **REMOVED v0.2 R1 (M004):** `balance` / `savings` (now CP1-B NetEvent — see §2.2.1). | `bank.business_treasury.abc-123` |
```

### 1.7 BEFORE — §3 anti-patterns naming convention

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md:123-127
- ❌ ~~`bankBalance.123`~~ — sin separador `.`.
- ❌ ~~`bank_balance_123`~~ — underscore (rompe convention).
- ❌ ~~`Bank.Balance.123`~~ — PascalCase (rompe convention).
- ❌ ~~`bank.balance.123.detail.transactions`~~ — depth >3 (shallow limitation + confusing).
- ❌ Keys dynamic per-session (e.g. `bank.session.<random>`) — no es state bag use case.
```

### 1.7 AFTER (add new anti-pattern row)

```markdown
- ❌ ~~`bankBalance.123`~~ — sin separador `.`.
- ❌ ~~`bank_balance_123`~~ — underscore (rompe convention).
- ❌ ~~`Bank.Balance.123`~~ — PascalCase (rompe convention).
- ❌ ~~`bank.balance.123.detail.transactions`~~ — depth >3 (shallow limitation + confusing).
- ❌ Keys dynamic per-session (e.g. `bank.session.<random>`) — no es state bag use case.
- ❌ **NEW v0.2 R1 (M004 enforcement):** ~~`bank.balance.<cid>`~~ + ~~`bank.savings.<cid>`~~ — financial PII tier prohibido en CP1-A. Use CP1-B NetEvent `sonar:bank:balance:update` / `sonar:bank:savings:update` per §2.2.1.
```

### 1.8 BEFORE — §4.1 boot init hydrate

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md:138-145
2. Hydrate bags desde DB:
   ```
   SELECT bank_account_id, citizen_id, balance, account_class FROM sonar_bank_accounts WHERE owner_type = 'citizen';
   → for each: GlobalState['bank.balance.<citizen_id>'] = balance (filter account_class = 'main').
   → for each: GlobalState['bank.savings.<citizen_id>'] = balance (filter account_class = 'savings').
   ```
3. Hydrate `bank.govt.taxBrackets` desde `sonar_bank_tax_brackets`.
4. Hydrate `bank.bridges.status` desde `sonar_bank_status` (CP8 FSM single-row).
5. Log info `[SONAR][bank] hydrate complete: <N> bags initialized`.
```

### 1.8 AFTER

```markdown
2. Hydrate bags desde DB (M004 R1 reduced scope):
   ```
   -- REMOVED v0.2 R1 (M004): NO hydrate bank.balance.* / bank.savings.* — these now lazy-publish per-player connect via §2.2.2 pattern.
   -- Remaining hydrates:
   SELECT * FROM sonar_bank_business_treasuries → GlobalState['bank.business_treasury.<company_id>'] = balance.
   SELECT * FROM sonar_bank_recurring_summary → GlobalState['bank.recurring.<citizen_id>.summary'] = ...
   ```
3. Hydrate `bank.govt.taxBrackets` desde `sonar_bank_tax_brackets`.
4. Hydrate `bank.bridges.status` desde `sonar_bank_status` (CP8 FSM single-row).
5. Hydrate `bank.compliance.<citizen_id>.public` reduced shape.
6. Hydrate `bank.govt.subsidies.active`.
7. Hydrate `bank.elections.<election_id>` (active elections only).
8. **NEW v0.2 R1 (M004):** Register `playerJoining` handler per §2.2.2 — lazy publish balance/savings on connect.
9. Log info `[SONAR][bank] hydrate complete: <N> bags initialized (M004 R1: balance/savings excluded — lazy per-connect publish active).`
```

### 1.9 BEFORE — §4.2 update on mutation pattern

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md:152
local function transfer_atomic(payer_cid, payee_cid, amount, reason)
```

### 1.9 AFTER — extend pattern with publish_balance_update

In §4.2 transfer_atomic boilerplate (lines 152+), at the post-DB-commit StateBag emit step, replace any `GlobalState['bank.balance.<cid>'] = value` calls with `publish_balance_update(cid, value, 'main', { correlation_id = opts.correlation_id })` per §2.2.1 helper. Add explicit comment in the doc block:

```markdown
### 4.2 Update on mutation (R1 M004 amended)

Cada lib Bank mutation (transfer, deposit, escrow release, payroll, etc.) actualiza state(s) afectado(s) **en mismo transaction commit DB**. **R1 M004 change:** balance/savings updates ahora usan helper `publish_balance_update(cid, value, account_class, opts)` (NetEvent CP1-B) — NUNCA `GlobalState['bank.balance.*']` direct write (eliminated v1.0.1 R1).

Pattern boilerplate post-M004:
```lua
local function transfer_atomic(payer_cid, payee_cid, amount, reason, opts)
  -- ... DB transaction begin + UPDATE accounts + INSERT movements + INSERT audit ...
  -- Post-COMMIT side effects:

  -- (1) Balance updates — NEW R1 M004 pattern (CP1-B NetEvent target):
  publish_balance_update(payer_cid, payer_new_balance, 'main', { correlation_id = opts.correlation_id })
  publish_balance_update(payee_cid, payee_new_balance, 'main', { correlation_id = opts.correlation_id })

  -- (2) Other StateBag updates remain CP1-A (e.g. business_treasury, recurring summary):
  if opts.affected_company_id then
    GlobalState['bank.business_treasury.' .. opts.affected_company_id] = treasury_new_balance  -- CP1-A still OK
  end

  -- (3) NetEvent fires (other CP1-B domains): escrow, compliance, etc — unchanged.
end
```

**Anti-pattern AP-CP1-1 prohibido (M004 enforcement):**
```lua
-- ❌ NUNCA. R1 M004 eliminó CP1-A para balance/savings.
GlobalState['bank.balance.' .. cid] = balance

-- ✅ SIEMPRE.
publish_balance_update(cid, balance, 'main', { correlation_id = ... })
```
```

### 1.10 Test scenarios (Security Lead validation)

- [ ] **T-AMEND-M004.1** — Player A logged-in, Player B logged-in. A initiates transfer. B tries `GetStateBagValue('bank.balance.A_citizen_id')` → returns nil (StateBag removed). NO leak.
- [ ] **T-AMEND-M004.2** — A receives `sonar:bank:balance:update` event with new balance. B does NOT receive event (target=A only).
- [ ] **T-AMEND-M004.3** — Server-side ownership check: try fire `publish_balance_update(cid_A, X, 'main')` but resolve target = source_B (e.g. citizen_id collision bug) → defensive abort + security alert + NO fire.
- [ ] **T-AMEND-M004.4** — Player offline, balance changes (cron payroll, admin force) → DB updated, NO event fire (skip), next login `playerJoining` handler fires `sonar:bank:balance:update` with current balance.
- [ ] **T-AMEND-M004.5** — Admin C035 audit query scope=`govt_full` returns balances of all citizens → server fires `sonar:bank:balance:adminAudit` to admin source ONLY (P11 ACE-checked).
- [ ] **T-AMEND-M004.6** — Static grep CI post-implementation: `GlobalState\[?'bank\.(balance|savings)\.` returns 0 hits in `resources/sonar_*/server/**.lua`.
- [ ] **T-AMEND-M004.7** — Bandwidth benchmark: 50-player server, 100 transfers/min → measure total NetEvent bytes/s vs pre-M004 GlobalState write broadcast bytes/s. Expected: post-M004 ≤ pre-M004 (likely lower).

---

## §2 — Versioning + sign-off

### 2.1 Versioning entry (post-LOCK promotion)

Append a §10 Versioning C-BE-05 row pendiente:

```markdown
| **v1.0.1 R1 LOCKED** | TBD post-Security re-audit + founder LOCK approval | BANK-BE.AMEND.1 architectural patch Round 1 reactive a Security Lead audit C-SEC-01/02/03 v0.1 (founder yaboula APPROVED 2026-05-06): M004 (`bank.balance.<cid>` + `bank.savings.<cid>` migrated CP1-A → CP1-B; `sonar:bank:balance:update` + `sonar:bank:savings:update` + `sonar:bank:balance:adminAudit` NEW NetEvents canonical; `publish_balance_update()` helper canonical; `playerJoining` lazy publish handler; AP-CP1-1 anti-pattern explicit; bandwidth impact O(N²)→O(1) reduction). Sign-off founder + Backend + Security re-audit. **Frontend Lead consumer pattern break SAFE** (Frontend not yet activated — no production code affected). **Cross-cutting LOCK-time impacts §4** (C-BE-01 + C-BE-02 + C-BE-04). |
```

### 2.2 Sign-off (this AMEND file)

| Rol | Status |
|---|---|
| Founder yaboula | ✅ **APPROVED architectural change** 2026-05-06 |
| Backend Lead (Cascade) | ✅ self-attested DRAFT v0.2 emitted |
| Security Lead (Cascade) | ⏳ PENDING re-audit closure M004 + cross-cutting validation |
| Frontend Lead | ⚠️ N/A round 1 (not yet activated — pattern change captured in C-BE-05 spec for future H4 activation) |

---

## §3 — Founder optional decision (split vs parity)

**Question:** ¿Migra `bank.savings.<citizen_id>` también a CP1-B (parity con balance) o se mantiene en CP1-A (split decision)?

**Backend Lead recommendation:** **PARITY** — savings es financial PII tier idéntico al main balance. Mismo razonamiento Zero-Knowledge.

**This AMEND file assumes PARITY (default).** Si founder prefiere SPLIT (only `bank.balance.<cid>` migrates, `bank.savings.<cid>` stays CP1-A):
- Edit §1.2 + §1.6 + §1.7 + §1.9 to scope solo a `bank.balance` only.
- Edit §1.3 table → remove row `sonar:bank:savings:update`.
- Edit §1.4 helper → only emit for `account_class='main'`.

**No founder decision required ahora** — default PARITY proceed unless founder objects en review window.

---

## §4 — Cross-cutting LOCK-time impacts (consumer contracts)

Este AMEND file actualiza C-BE-05 (owner contract). **Al momento de LOCK v1.0.1 R1**, los siguientes contratos consumers necesitan edits sincronizadas:

### 4.1 C-BE-01 (events catalog) — add NEW NetEvents

`@docs/technical/bank_phase_a/c_be_01_events_catalog_v1_3.md` §3 (server→client público) + §4 (server→admin ACE-checked) — add 3 new NetEvent rows:

| NetEvent | Sección | Tier | Privacy | Notes |
|---|---|---|---|---|
| `sonar:bank:balance:update` | §3 server→client público (target single) | Tier 1 critical | CP1-B owner-only | Replaces CP1-A `bank.balance.<cid>` StateBag (M004 R1) |
| `sonar:bank:savings:update` | §3 server→client público (target single) | Tier 1 critical | CP1-B owner-only | Replaces CP1-A `bank.savings.<cid>` StateBag (M004 R1 parity) |
| `sonar:bank:balance:adminAudit` | §4 server→admin ACE-checked | Tier 2 important | CP1-B P11 ACE | Admin audit query response (C035 scope=govt_full) |

**Total events count post-R1 v1.0.1:** 51 + 3 = **54 events catalogados**.

### 4.2 C-BE-02 (api contracts) — adjust callback side effects + add C001b

`@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md`:

1. **§9 callbacks side effects** — every callback that previously documented "StateBag emit `bank.balance.<cid>`" should be rewritten to "NetEvent emit `sonar:bank:balance:update` to owner source". Affected callbacks (rough list — verify at LOCK):
   - C001 (transfer): payer + payee balance updates → NetEvent fires.
   - C002 (swap_to_savings): main + savings balance updates.
   - C007 (escrow_create): payer balance reduction.
   - C009 (escrow_fund): payer balance reduction.
   - C010 (escrow_release): payee balance increase.
   - C012 (escrow_refund admin): payer balance restore.
   - C013 (deposit_cash): main balance increase.
   - C014 (withdraw_cash): main balance reduction.
   - C019 (loan_apply approved cron): main balance increase.
   - C021 (loan_repayment): main balance reduction.
   - C026 (cron payroll): batch balance increases per recipient.
   - C027 (recurring_create initial): main balance reduction.
   - C031 (atm_minigame): main balance modify post-success.
   - C035 (audit_query scope=govt_full): emit `:adminAudit` event to requester.
   - C037, C038 (compliance flag actions): no balance impact.

2. **§9.x NEW callback C001b** `sonar:bank:balance:snapshot`:
   - Auth: AUTH-OWNER. Read-only. Idempotency: optional. p99 <30ms.
   - Request: `{ }` (derives from source).
   - Response: `{ status='ok', data: { main: number, savings: number, occurred_at, correlation_id } }`.
   - Use case: client UI mount fallback if `:update` event lost on connect.
   - Auth check: `auth.require_citizen(source)` (R1 H001 helper).
   - Rate limit: HIGH tier.

3. **§6.2 audit ENUM** — no change needed (balance updates do not generate new audit event_type — existing `movement_recorded` covers).

### 4.3 C-BE-04 (bridges) — reconciliation pipeline emit refactor

`@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md` §7.1 step 5 (lines 503-506):

**BEFORE:**
```lua
-- Emit StateBag updates (CP1-A) batched 10ms-paced
for _, x in ipairs(apply_batch) do
  GlobalState['bank.balance.' .. x.citizen_id] = x.new_balance
end
```

**AFTER (R1 M004):**
```lua
-- Emit balance updates via CP1-B NetEvent (R1 M004 — replaces deprecated CP1-A pattern)
for _, x in ipairs(apply_batch) do
  publish_balance_update(x.citizen_id, x.new_balance, 'main', {
    correlation_id = x.correlation_id or 'reconciliation_apply',
    occurred_at = GetGameTimer(),
  })
end
```

Add cross-amendment note in `AMEND-C-BE-04-r1-v0.2.md` §3 (H004 fix) at LOCK time — currently §3 only addresses SQL injection, but step 5 emit pattern changes also.

---

**FIN AMEND-C-BE-05-r1-v0.2 DRAFT** — M004 architectural CP1-A → CP1-B migration (founder APPROVED 2026-05-06). Cross-cutting LOCK-time impacts §4 documented for atomic application.
