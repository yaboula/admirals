# C-BE-05 — StateBags Global Publishers Spec (LOCKED v1.0.2 R2)

> **Owner:** Backend Money & Compatibility Lead.
> **Consumer Leads:** Frontend Lead (consume bags client-side reactive) + Security Lead (audit privacy boundaries).
> **Status:** 🟢 **v1.0.2 R2 LOCKED 2026-05-12** (BANK-BE.PHASE_5.1 Phase 2 ceremony — Round 2 amendment promoted post Phase 5 ecosystem pivot Founder LOCK Q1-Q8 + §9 path (a)).
> **Fecha:** 2026-05-12 (BANK-BE.0 → BANK-BE.LOCK → BANK-BE.AMEND.1 → BANK-BE.LOCK.R1 → BANK-BE.PHASE_5.1.LOCK.R2).
> **Path canonical:** `docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md` v1.0.2 R2 LOCKED. Pointer cross-ref `docs/technical/02_events_catalog.md` v1.3.1 §statebags-global-publishers.
> **CP origin:** CP1 mandatory (State Bags global mandatory) + Q-BE-pre-02/03 founder LOCKED 2026-05-06 + **M004 architectural founder APPROVED 2026-05-06** (financial PII privacy non-negotiable).

---

## 1. Filosofía CP1 — re-definición alcance post Q-BE-pre-02/03

### 1.1 CP1 original (blueprint v1.2 §11.5.1)

> Refactor publishers Bank balance/state. Todo state cambio Bank publica via `GlobalState[key] = value` server-only writable + `AddStateBagChangeHandler` reactive client. Reemplaza `TriggerClientEvent` manual publishers Bank state.

### 1.2 CP1 re-definido v1.1 (Backend Lead Q-BE-pre-02/03 founder approved)

CP1 distingue dos sub-tracks per privacy boundary:

| Sub-track | Alcance | Mecanismo | Razón |
|---|---|---|---|
| **CP1-A público** | State no-sensitive: balance citizen propio (visible al jugador), counts agregados, status public flags-bool, timestamps. | `GlobalState['bank.<domain>.<id>'] = scalar_value`. Read-side broadcast a todos clients aceptable. | Hot-path reads frecuentes (UI render) sin overhead network event roundtrip. |
| **CP1-B admin-only / participant-only** | State sensitive con privacy implications: detalle compliance flags, escrow state, audit ledger queries, raw votes. | `TriggerLatentClientEvent('sonar:bank:<domain>:<event>', target_source, payload)` + ACE check server-side ANTES de fire. | FiveM engine NO filtra reads global state per-client — datos sensibles en GlobalState = leak. |

### 1.3 Justificación técnica privacy boundary

**Cita docs.fivem.net (research notes §1.1):** *"global state to be able to be written by the server"* — write policy es server-only **pero read-side está broadcast a todos los clients sin filtrado nativo**.

**Implicación práctica:** `GetStateBagValue('global', 'bank.compliance.123')` retorna valor a cualquier cliente conectado. Si publicamos detalles compliance flags raised contra citizen 123 en GlobalState → cualquier player puede leer leak.

**Conclusión:** sensitive state **NO va en GlobalState**. Va en discrete NetEvents directos a target source(s) con ACE check server-side.

### 1.4 Anti-patterns eliminados

- ❌ ~~`GlobalState['bank.compliance.<citizen_id>'] = { flags: [...detalles...] }`~~ → leak privacy.
- ❌ ~~`GlobalState['bank.escrow.<escrow_id>'] = { participants, amount, state }`~~ → leak shared state a non-participants.
- ❌ ~~`TriggerClientEvent` broadcast a -1 (all clients) Bank balance~~ → CP1 explicitly prohíbe.
- ❌ **NEW v1.0.1 R1 (M004 founder APPROVED):** ~~`GlobalState['bank.balance.<citizen_id>'] = number`~~ + ~~`GlobalState['bank.savings.<citizen_id>'] = number`~~ → financial PII tier prohibido en CP1-A (read-broadcast a todos clients FiveM-nativo permite leer balance ajeno con citizen_id derivable de roster). Migrated to CP1-B NetEvent pattern §2.2.1.

### 1.5 Patterns correctos (v1.0.1 R1 actualizado)

- ✅ **NEW v1.0.1 R1 (M004):** `TriggerLatentClientEvent('sonar:bank:balance:update', ownerSource, { balance, account_class, occurred_at, correlation_id, schema_version })` — owner-only fire post citizen_id == owner check (CP1-B). Helper canonical `publish_balance_update(cid, value, account_class, opts)` per §2.2.1.
- ✅ **NEW v1.0.1 R1 (M004 parity):** `TriggerLatentClientEvent('sonar:bank:savings:update', ownerSource, payload)` — savings idem balance, financial PII tier idéntico.
- ✅ `TriggerLatentClientEvent('sonar:bank:complianceDetail', adminSource, payload)` — admin-only fire post ACE check.
- ✅ `TriggerLatentClientEvent('sonar:bank:escrowStateChanged', payerSource, payload); TriggerLatentClientEvent('sonar:bank:escrowStateChanged', payeeSource, payload)` — participants only.

---

## 2. Catálogo StateBags global publishers Bank Phase A

### 2.1 Public bags (CP1-A) — broadcast all clients OK

> **REMOVED v1.0.1 R1 (M004 founder APPROVED 2026-05-06):**
> - ~~`bank.balance.<citizen_id>`~~ → migrated to CP1-B `sonar:bank:balance:update` NetEvent (§2.2.1).
> - ~~`bank.savings.<citizen_id>`~~ → migrated to CP1-B `sonar:bank:savings:update` NetEvent (parity).
>
> **Razón:** financial-grade privacy non-negotiable. CP1-A read-broadcast a todos clients FiveM-nativo NO permite filtrado per-client server-side — cualquier cliente con citizen_id derivable (vía roster `GetPlayers()`) lee balance ajeno. Contradice principio Zero-Knowledge.

| Key pattern | Type | Owner writer | Reader pattern | Privacy classification |
|---|---|---|---|---|
| `bank.business_treasury.<company_id>` | `number` (DECIMAL atomic) | `sonar_bank_app/server/treasury_publisher.lua` | Frontend treasury widget Empresas Dashboard | Public-safe — treasury balances son visibles en Government Console anyway. |
| `bank.compliance.<citizen_id>.public` | `{ has_active_flags: boolean, count: number }` | `sonar_bank_app/server/compliance_publisher.lua` (raise hooks Security Lead spec post-H2) | Frontend badge UI | **Public-safe reduced shape.** NO detalle (flag_type, severity, evidence). Detalle vía CP1-B NetEvent admin-only. |
| `bank.govt.taxBrackets` | `[{ income_min, income_max, rate }, ...]` | `sonar_bank_app/server/govt_publisher.lua` (admin sets via callback C015) | Frontend tax calculator | **Public-safe.** Tax brackets son ley pública en el server. |
| `bank.govt.subsidies.active` | `[{ category, amount, expires_at }, ...]` | mismo | Frontend government info | Public-safe. Subsidies activas son public knowledge. |
| `bank.bridges.status` | `string` ENUM (CP8 4 states: `native_full` / `lite_mode_active` / `compromised_load_order` / `framework_missing`) | `sonar_bridges/server/bank_status_publisher.lua` (CP8 FSM) | Frontend UI badge footer (CP8 + Q16.3) | Public-safe + transparency by design. Player ve estado infrastructure. |
| `bank.elections.<election_id>` | `{ phase: string, ends_at: epoch_ms, candidate_count: number }` | `sonar_bank_app/server/elections_publisher.lua` | Frontend elections widget | Public-safe — elections phase es info pública. **NO incluye votes counts en flight** (phase `voting_open` → tally hasta phase `vote_count`). |
| `bank.recurring.<citizen_id>.summary` | `{ active_count: number, next_payment_at: epoch_ms \| null }` | `sonar_bank_app/server/recurring_publisher.lua` | Frontend recurring widget | Public-safe reduced shape (no detalles de cada subscription). |

### 2.2 Restricted bags (CP1-B) — discrete NetEvents directos a participants/admin

**Pattern:** **NO se publican en GlobalState.** Backend fires NetEvent dirigido al target source con ACE check server-side antes.

> **Notational disclaimer (v1.0.1 R1 cross-ref H001 fix):** `source.citizen_id ∈ {...}` es shorthand para `auth.require_participant(source, allowed_ids)` helper canonical (`@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` §2.3 + §A11). NO accesso `source.citizen_id` directo (source es player handle integer, NO table — H001 fix).

| Domain | NetEvent name | Target audience | ACE / role check |
|---|---|---|---|
| **Account balance update (NEW v1.0.1 R1 M004)** | `sonar:bank:balance:update` | **Owner only** — single target source resolved from `Bridges.Player.GetSourceByCitizenId(citizen_id)` | Server-side: target online AND `Bridges.Player.GetCitizenId(target_source) == account.owner_id`. NO admin broadcast (admin path uses `:adminAudit` separate event con P11 ACE). |
| **Savings balance update (NEW v1.0.1 R1 M004 parity)** | `sonar:bank:savings:update` | Owner only — same target resolution. | Same nil-safe + ownership check. |
| **Account balance admin audit (NEW v1.0.1 R1 M004)** | `sonar:bank:balance:adminAudit` | Admin govt clients ONLY (audit query response) | `IsPlayerAceAllowed(src, 'sonar.bank.govt.audit.full')` (P11). Fired ON-DEMAND post C035 audit query callback. NO push automatic on every mutation. |
| Compliance flag detail | `sonar:bank:compliance:detail` | Admin govt clients only | `IsPlayerAceAllowed(src, 'sonar.bank.govt.audit.full')` |
| Escrow state change | `sonar:bank:escrow:stateChanged` | Payer source + Payee source + admin clients (3 fires separados) | Per-target identity check: `auth.require_participant(source, {escrow.payer_id, escrow.payee_id})` OR `sonar.bank.govt.audit.full` |
| Audit ledger query result | `sonar:bank:audit:queryResult` | Requester (per Q13 3 scopes — Mis cuentas / Mis empresas / Todas govt) | Per-scope ACE: `sonar.bank.audit.self` / `sonar.bank.empresas.<id>` / `sonar.bank.govt.audit.full` |
| Loan approval/rejection | `sonar:bank:loan:decisionResult` | Loan applicant source + admin source | `auth.require_owner(source, loan.applicant_id)` OR admin |
| Election votes raw access | `sonar:bank:elections:votesRaw` | Admin govt clients only (Q-DB-H dual-layer privacy) | `IsPlayerAceAllowed(src, 'sonar.bank.govt.audit.full')` |
| Business treasury approval pending | `sonar:bank:business:approvalPending` | Multi-signers de la empresa (M-of-N) | `auth.require_participant(source, business.signers_list)` |
| Physical card pin failure / freeze | `sonar:bank:card:pinFailure` | Card owner source only | `auth.require_owner(source, card.owner_id)` |

**Implementación standard (boilerplate):**

```lua
-- Pseudo-code C-BE-05 NetEvent fire pattern (CP1-B).
local function fire_restricted(event_name, citizen_id, payload, ace_perm)
  local src = get_source_by_citizen_id(citizen_id)
  if not src then
    -- Citizen offline — defer payload? or drop?
    -- DECISION: drop fire silently. Re-fetch on UI mount via callback.
    return
  end
  if ace_perm and not IsPlayerAceAllowed(src, ace_perm) then
    log_security('event_blocked_ace', { event = event_name, src = src, perm = ace_perm })
    return
  end
  TriggerLatentClientEvent(event_name, src, 64 * 1024, payload)  -- 64KB rate cap
end
```

#### 2.2.1 `sonar:bank:balance:update` canonical spec (NEW v1.0.1 R1 — M004)

**Purpose:** notify balance owner of any balance change (mutation reactivity replaces deprecated CP1-A StateBag pattern eliminado v1.0.1 R1).

**Server-side fire pattern (boilerplate canonical):**

```lua
-- sonar_bank_app/server/balance_publisher.lua (v1.0.1 R1 rewrite from CP1-A → CP1-B)
local function publish_balance_update(citizen_id, balance, account_class, opts)
  -- account_class: 'main' | 'savings' (route to corresponding event below).
  -- opts: { correlation_id?, occurred_at? } optional.

  -- Resolve target source from citizen_id (offline → no fire, balance persisted DB anyway).
  local target_source = Bridges.Player.GetSourceByCitizenId(citizen_id)
  if not target_source or target_source <= 0 then
    -- Player offline → skip event fire. Balance read on next login via callback C001b `bank.balance.snapshot` o playerJoining hook §2.2.2.
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

**Performance budget:**

- Per-event payload: ~150 bytes. Latent rate budget 50KB/s/player → 333 events/s sustained per player. Bank balance changes typically <1/min — headroom enormous.
- Replaces CP1-A `GlobalState[key] = value` (FiveM native event ~80 bytes broadcast a todos N clients) → migration **REDUCES total bandwidth** en N-player server (de O(N) por balance change a O(1)).

#### 2.2.1.A Tier 1/2 exports wrapper consumer pattern (NEW v1.0.2 R2 — Phase 5)

Cada Tier 1/2 mutation export (C-BE-02 §10 v1.0.2 R2 — 22 públicos = 21 mutation/read + 1 GetApiVersion informational) DEBE invocar `publish_balance_update(citizen_id, balance_major_decimal, account_class, opts)` inmediatamente post-COMMIT SQL transaction y ANTES del return al caller. UNA invocación por `account_class` afectado:

- Pure credit/debit sobre cuenta main → 1 call `account_class='main'`.
- Pure credit/debit sobre cuenta savings → 1 call `account_class='savings'`.
- Transfer cross-account interno (main → savings o reverso) → 2 calls (main + savings, mismo `correlation_id`).
- Transfer P2P entre 2 citizens distintos → 2 calls (1 por cada citizen_id, ambos `account_class='main'` típicamente).

**Boilerplate canonical Tier 1/2 wrapper post-Phase 5 LOCK:**

```lua
-- sonar_bank_app/server/exports/public_api.lua (Phase 5 implementation 4.3)
function AddMoney(source, amount_minor, reason, opts)
  -- ... validation + auth + idempotency lookup ...
  -- ... SQL TX: balance update + movement insert + audit insert + idem upsert ...
  -- TX COMMIT successful.

  -- Path (a) Founder §9 LOCKED 2026-05-12: balance arg en DECIMAL major.
  local balance_major_str = units.from_minor(new_balance_minor)  -- "1234.56" lossless string
  publish_balance_update(citizen_id, balance_major_str, 'main', {
    correlation_id = opts.correlation_id or generated_corr,
    occurred_at = now_epoch_ms,
  })

  return true, nil, { new_balance_minor = new_balance_minor, iban = iban, tx_id = tx_id }
end
```

**Notas:**

1. `publish_balance_update` retorna `nil` (helper fire-and-forget). Wrapper NO espera ack — eventual consistency aceptable. Si player offline o ownership mismatch, helper hace early return silencioso (§2.2.1 body lines 122-134) sin error propagado.
2. Cualquier Tier 1/2 wrapper que NO invoque el helper canónico ANTES del return = LOCK ceremony fail criterion. PM Cascade verifica grep en Phase 5 implementation review.
3. `publish_balance_update` se invoca **post-COMMIT atomic** — si el TX falla, NO se invoca helper (return error code apropiado al caller, no se emite NetEvent stale).

**AP-CP1-1 prohibition reafirmada Phase 5 (LOCKED §1.4):**

- ❌ ~~`TriggerClientEvent('sonar:bank:custom_balance', -1, ...)`~~ — broadcast all clients PROHIBIDO.
- ❌ ~~`GlobalState['bank.balance.<cid>'] = value`~~ — pattern removed v1.0.1 R1 M004 — financial PII leak.
- ❌ ~~`TriggerLatentClientEvent('my:custom:balance', source, ...)`~~ — canal paralelo PROHIBIDO. Único canal canónico = `publish_balance_update` helper.
- ✅ ÚNICA exception: wrapper puede invocar helper UNA vez por `account_class` afectado, mismo `correlation_id` para auditability.

#### 2.2.1.B Value type Phase A LOCKED — path (a) Founder §9 (NEW v1.0.2 R2)

**Founder LOCK 2026-05-12 (`@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md` §9):** el arg `balance` del helper `publish_balance_update(citizen_id, balance, account_class, opts)` preserva **DECIMAL major units** durante toda Phase A (string lossless `"1234.56"` o number 1234.56). El NetEvent payload `balance` field consume el mismo tipo.

**Rationale:** Q2 LOCKED literal mencionó "INTEGER minor" para el value, pero Q1 LOCKED preservó "Frontend DECIMAL major no touch Phase A". El conflicto se resolvió path (a) — boundary conversion `units.from_minor()` happens **dentro del wrapper export ANTES** de invocar el helper. El helper firma se mantiene LOCKED v1.0.1 R1 sin cambio.

**Frontend consumers Phase A (LOCKED no touch):**

- `@resources/sonar_bank_app/web-src/src/lib/bankStateBags.ts` (CP1-A residual) y handlers de `sonar:bank:balance:update` / `sonar:bank:savings:update` continúan parseando `balance` field como `number` DECIMAL major (e.g. `1234.56`) y formateando con `useI18n().money(value)`.
- Wrapper Tier 1/2 ejecuta `units.from_minor(new_balance_minor)` → string `"1234.56"` o coerced number — depending de implementation Phase 4 decision (string lossless preferred, number safe para amounts < 9 trillion).

**Phase A+1 migration commitment:**

Phase A+1 (`@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`) migra end-to-end:

1. DB columns DECIMAL(19,2) → BIGINT (cents).
2. Helper signature `publish_balance_update(cid, balance_int_minor, account_class, opts)`.
3. NetEvent `balance` field type INTEGER cents.
4. Frontend types `BankStateBagBalance.balance: number` semantic change + `useI18n().money(integer_cents / 100)`.
5. Callbacks C001-C040 signatures.

Hasta entonces Phase A path (a) LOCKED — wrapper convierte; helper preserva.

**Q2 intent preserved 100%:**

- CP1-B mandate (atomic NetEvent every mutation): ✅ enforced §2.2.1.A.
- AP-CP1-1 prohibition (no parallel channels): ✅ enforced §2.2.1.A.
- Solo aclaramos value TYPE para Phase A scope.

#### 2.2.2 Initial balance snapshot — replace hydrate-on-boot pattern (NEW v1.0.1 R1 — M004)

**Pre-M004 pattern:** §4.1 boot init hydrate ALL balances from DB → publish to GlobalState. Player connects → reads StateBag immediately.

**Post-M004 pattern:** balance NO se hydrata broadcast. Player connect:

1. **Server-side `playerJoining` handler** (`sonar_bank_app/server/connect_handler.lua`):
   ```lua
   AddEventHandler('playerJoining', function()
     local source = source
     -- Defer balance fetch until citizen_id resolves post-character-load.
     Citizen.SetTimeout(2000, function()
       local cid = Bridges.Player.GetCitizenId(source)
       if not cid then return end  -- char not loaded; client will request via callback C001b
       local balance = MySQL.scalar.await('SELECT balance FROM sonar_bank_accounts WHERE owner_id = ? AND account_class = ? LIMIT 1', { cid, 'main' })
       local savings = MySQL.scalar.await('SELECT balance FROM sonar_bank_accounts WHERE owner_id = ? AND account_class = ? LIMIT 1', { cid, 'savings' })
       publish_balance_update(cid, balance or 0, 'main', { correlation_id = 'connect_initial' })
       publish_balance_update(cid, savings or 0, 'savings', { correlation_id = 'connect_initial' })
     end)
   end)
   ```

2. **Client-side fallback callback C001b** `sonar:bank:balance:snapshot`:
   - Auth: AUTH-OWNER (returns own balances only).
   - Returns `{ main: number, savings: number, occurred_at, correlation_id }`.
   - Use case: client UI mount lifecycle requests balances if no `:update` event received yet (timing race).
   - Spec canonical en `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` §9 NEW callback C001b (v1.0.1 R1).

**Bandwidth impact:** N-player server: previously hydrate on boot = N × StateBag write broadcast (O(N²) read-fan). NEW pattern: lazy per-player connect = O(1) per join. **Significant bandwidth reduction.**

### 2.3 NO publicar (out-of-CP1 — internal server only)

| Data | Razón NO bag/event |
|---|---|
| Audit ledger raw rows | DB-only. Query vía callback C035 con scope filter. NO realtime push. |
| Idempotency keys table state | Internal Backend lib (`IdempotencyKeys.*`) — sin consumer client. |
| Reconciliation queue / batch state | Internal `sonar_bridges/lib/reconciliation.lua` — invisible al client. |
| Correlation-id mutex pending_echoes | Internal `sonar_bridges/lib/mutex_echo.lua` — RAM only + GC defensive. |
| Stocks holdings raw transactions log | Materialized view `sonar_bank_stocks_holdings` accessible vía callback C022/C026. NO realtime push (Q12 — Tier 4 phase A no requiere live ticker). |

---

## 3. Naming convention StateBag keys

**Pattern canonical:** `bank.<domain>.<id_or_scope>[.<sub_field>]`.

| Componente | Valores válidos | Ejemplo |
|---|---|---|
| `bank` | Prefijo fijo Bank Phase A. | `bank.business_treasury.abc-123` (post v1.0.1 R1 M004: `bank.balance.*` + `bank.savings.*` removed from StateBag — see §2.1) |
| `<domain>` | `business_treasury` / `compliance` / `govt` / `bridges` / `elections` / `recurring`. **REMOVED v1.0.1 R1 (M004):** `balance` / `savings` (now CP1-B NetEvent — see §2.2.1). | `bank.business_treasury.abc-123` |
| `<id_or_scope>` | `<citizen_id>` (uuid o numeric per `sonar_citizens.id` Q-DB-A) / `<company_id>` (CHAR(36)) / `<election_id>` / `'taxBrackets'` (literal scope). | `bank.business_treasury.abc-123-def-456` |
| `<sub_field>` opcional | `public` / `summary` / `active` (reduced shape qualifiers). | `bank.compliance.123.public` |

**Anti-patterns naming:**

- ❌ ~~`bankBalance.123`~~ — sin separador `.`.
- ❌ ~~`bank_balance_123`~~ — underscore (rompe convention).
- ❌ ~~`Bank.Balance.123`~~ — PascalCase (rompe convention).
- ❌ ~~`bank.balance.123.detail.transactions`~~ — depth >3 (shallow limitation + confusing).
- ❌ Keys dynamic per-session (e.g. `bank.session.<random>`) — no es state bag use case.
- ❌ **NEW v1.0.1 R1 (M004 enforcement) AP-CP1-1:** ~~`bank.balance.<cid>`~~ + ~~`bank.savings.<cid>`~~ — financial PII tier prohibido en CP1-A. Use CP1-B NetEvent `sonar:bank:balance:update` / `sonar:bank:savings:update` per §2.2.1.

---

## 4. Lifecycle StateBag keys

### 4.1 Boot init

`onResourceStart('sonar_bank_app')`:
1. Verify `BankStatus.IsDisabled()` — si disabled, **NO publish bags** (defensive).
2. Hydrate bags desde DB (v1.0.1 R1 reduced scope post-M004):
   ```
   -- REMOVED v1.0.1 R1 (M004): NO hydrate bank.balance.* / bank.savings.* — these now lazy-publish per-player connect via §2.2.2 pattern.
   -- Remaining hydrates:
   SELECT * FROM sonar_bank_business_treasuries → GlobalState['bank.business_treasury.<company_id>'] = balance.
   SELECT * FROM sonar_bank_recurring_summary → GlobalState['bank.recurring.<citizen_id>.summary'] = ...
   ```
3. Hydrate `bank.govt.taxBrackets` desde `sonar_bank_tax_brackets`.
4. Hydrate `bank.bridges.status` desde `sonar_bank_status` (CP8 FSM single-row).
5. Hydrate `bank.compliance.<citizen_id>.public` reduced shape.
6. Hydrate `bank.govt.subsidies.active`.
7. Hydrate `bank.elections.<election_id>` (active elections only).
8. **NEW v1.0.1 R1 (M004):** Register `playerJoining` handler per §2.2.2 — lazy publish balance/savings on connect.
9. Log info `[SONAR][bank] hydrate complete: <N> bags initialized (M004 R1: balance/savings excluded — lazy per-connect publish active).`

### 4.2 Update on mutation (v1.0.1 R1 amended)

Cada lib Bank mutation (transfer, deposit, escrow release, payroll, etc.) actualiza state(s) afectado(s) **en mismo transaction commit DB**. **v1.0.1 R1 change:** balance/savings updates ahora usan helper `publish_balance_update(cid, value, account_class, opts)` (NetEvent CP1-B) — NUNCA `GlobalState['bank.balance.*']` direct write (eliminated v1.0.1 R1).

Pattern boilerplate post-M004:

```lua
local function transfer_atomic(payer_cid, payee_cid, amount, reason, opts)
  -- ... DB transaction begin + UPDATE accounts + INSERT movements + INSERT audit ...
  MySQL.transaction.await({...})  -- DB atomic

  -- Post-COMMIT side effects:
  -- (1) Balance updates — v1.0.1 R1 M004 pattern (CP1-B NetEvent target):
  publish_balance_update(payer_cid, payer_new_balance, 'main', { correlation_id = opts.correlation_id })
  publish_balance_update(payee_cid, payee_new_balance, 'main', { correlation_id = opts.correlation_id })

  -- (2) Other StateBag updates remain CP1-A (e.g. business_treasury, recurring summary):
  if opts.affected_company_id then
    GlobalState['bank.business_treasury.' .. opts.affected_company_id] = treasury_new_balance  -- CP1-A still OK
  end

  -- (3) NetEvent fires (other CP1-B domains): escrow, compliance, etc — unchanged.
  -- audit ledger append + correlation-id metadata + idempotency commit (libs separadas)
end
```

**Anti-pattern AP-CP1-1 prohibido (v1.0.1 R1 M004 enforcement):**
```lua
-- ❌ NUNCA. v1.0.1 R1 eliminó CP1-A para balance/savings.
GlobalState['bank.balance.' .. cid] = balance

-- ✅ SIEMPRE.
publish_balance_update(cid, balance, 'main', { correlation_id = ... })
```

**Invariant:** state value siempre refleja DB authoritative balance post-commit. Pre-commit (mid-transaction) NO update state — evita inconsistency si transaction rollback.

**Cross-ref Phase 5 R2:** la nueva superficie Tier 1/2 exports (C-BE-02 §10 v1.0.2 R2) consume `publish_balance_update` con el mismo pattern boilerplate documentado aquí — ver §2.2.1.A para wrapper consumer flow específico Phase 5.

### 4.3 Cleanup on disconnect / cleanup periodic

- Citizen disconnect: NO clear bag — balance persiste (otros clients podrían referenciarla; reconnect rehidrata).
- Server shutdown: state bags ephemeral RAM-only — DB authoritative on next boot rehydrate.
- Bag explicit delete: `GlobalState['bank.balance.123'] = nil` solo en circumstances específicas (account closed callback C006 close path — defer Phase B).

### 4.4 Hot-reload `restart sonar_bank_app`

- StateBags global persisten across resource restart (no scoped resource).
- **Pero:** `AddStateBagChangeHandler` callbacks DESREGISTRAN en restart. Frontend client debe rehydrate handlers post `onResourceStart` client-side.
- Backend `onResourceStart('sonar_bank_app')` re-ejecuta hydrate §4.1 — idempotente, bag values match DB.

---

## 5. Performance budget StateBag publishes

### 5.1 Hot-path frequency budgets

| Bag | Frequency típica | Frecuencia worst-case | Mitigation worst-case |
|---|---|---|---|
| `bank.balance.<citizen_id>` | 1 update / transfer (típica 1-5 txs / hora / citizen) | Payroll batch 50 employees simultaneous | Batch publish: agrupar updates en single transaction → emit bags post-commit en lote ms-paced (NO 50 simultaneous emit). |
| `bank.bridges.status` | 0-1 update / hour (FSM transitions raros) | Watchdog detection fail Core Override → transition `compromised_load_order` | Single emit, no flooding. |
| `bank.govt.taxBrackets` | 0-1 / week (admin edit C015) | N/A | Single emit. |
| `bank.compliance.<citizen_id>.public` | 0-1 / day per citizen (autoraise rare) | Mass autoraise event Q-velocity bot detection | Throttle emit: si >10 raises/sec → coalesce + emit 1x/sec aggregate. |
| `bank.elections.<election_id>` | 4 transitions per election lifecycle (idle → nomination_open → voting_open → vote_count → term_active) | Event burst durante phase change broadcast | Single emit per transition. |
| `bank.recurring.<citizen_id>.summary` | Recurring tick periodic Q-15 min | Hourly batch | Cron tick coalesce 1 emit/citizen/hour. |

**Backend Lead target:** total bag emits Bank-domain ≤ 10/sec sustained server-wide. Burst <100/sec acceptable. `sv_experimentalStateBagsHandler TRUE` reduce serialization cost (research notes §2).

### 5.2 Read-side performance Frontend

**v1.0.1 R1 M004 update:** balance/savings reactive consumption via `RegisterNetEvent('sonar:bank:balance:update', handler)` + `RegisterNetEvent('sonar:bank:savings:update', handler)` (NetEvent CP1-B) — replaces deprecated `AddStateBagChangeHandler` pattern para estos dos domains.

Other public bags (business_treasury / govt / bridges / elections / recurring summary / compliance public) consume via `AddStateBagChangeHandler('global', '<key>', handler)` (CP1-A unchanged).

NO query polling. Throughput driven by Backend emit rate.

---

## 6. Security threats + mitigations

### 6.1 Threat: client lee balance otro citizen — RESOLVED v1.0.1 R1 (M004)

- **Pre v1.0.1 R1 (legacy CP1-A):** ~~Posibilidad YES — `GetStateBagValue('global', 'bank.balance.456')` desde client 123. Engine no filtra reads. Mitigated as accepted risk.~~
- **v1.0.1 R1 status (post M004 founder APPROVED):** **MITIGATED ARCHITECTURAL.** `bank.balance.<cid>` + `bank.savings.<cid>` removed from CP1-A. NetEvent CP1-B `sonar:bank:balance:update` fires only to owner source post defensive ownership check. Other clients NO reciben balance ajeno via engine-native channel.
- **Residual surface:** admin govt audit query C035 emits `sonar:bank:balance:adminAudit` to admin source ONLY (P11 ACE-checked). Non-admin clients cannot subscribe.
- **Acceptable risk:** ZERO leak. Financial-grade Zero-Knowledge principle satisfied (founder pillar).

### 6.2 Threat: client lee compliance detail

- **Posibilidad:** mitigated por design — sensitive state NO va en GlobalState (CP1-B). Solo `bank.compliance.<citizen_id>.public = { has_active_flags: bool, count: number }` en bag.
- **Detail leak path:** NetEvent `sonar:bank:compliance:detail` requiere ACE check server-side antes de fire. Client malicioso que intente `RegisterNetEvent('sonar:bank:compliance:detail')` solo recibe events si server le envía (no broadcast).
- **Acceptable risk:** NO leak detail.

### 6.3 Threat: replay / spoof StateBag write

- **Posibilidad:** NO — engine policy bloquea writes de client a global state.
- **Mitigation:** engine-enforced.

### 6.4 Threat: bag flooding (DoS)

- **Posibilidad:** Backend bug emit loop infinito → bag updates flooding.
- **Mitigation:** rate budgeting §5.1 + watchdog metric `bank_bags_emit_rate` (DevOps Lead C-DO-01 smoke test bracket). Si >1000 emit/sec → console warn.

---

## 7. Cross-references contratos

- C-BE-01 Events Catalog v1.3 — registra NetEvents CP1-B + AddStateBagChangeHandler patterns Frontend consumption.
- C-BE-02 API Contracts v1.3 — callbacks que mutan state → emiten bags post-commit (referencia §4.2 pattern).
- C-BE-03 State Machines v1.1 — transitions que afectan bag values (e.g. `sonar_bank_status` FSM → `bank.bridges.status` bag emit).
- C-BE-04 Bridges v1.1 — `Bridges.Bank.AddMoney/RemoveMoney` API debe emit bag post-DB commit.
- C-SEC-01/02 (Security Lead H2) — ACE matrix permissions referenciadas desde §2.2 NetEvent fire ACE checks.
- C-FE-01 (Frontend Lead H4) — UI components consume bags + register handlers.

---

## 8. Open questions BANK-BE.0

| OQ | Tema | Resolution target |
|---|---|---|
| **OQ-CBE05-01** | `bank.business_treasury.<company_id>` — ¿bag global público OK o restringir a employees + govt? | Founder + Frontend Lead consultative review v0.2. Default proposal: público (treasuries empresa son visibles en Empresas Dashboard + Government Console anyway). |
| **OQ-CBE05-02** | `bank.compliance.<citizen_id>.public` shape — ¿count exact o bucket (`<5`, `5-10`, `>10`)? | Default exact count. Founder confirma o pide bucket. |
| **OQ-CBE05-03** | NetEvent `sonar:bank:escrow:stateChanged` — ¿payload incluye amount o solo state ENUM? | Default NO amount (privacy preserve — amount visible solo via callback `bank.escrow.getDetail` con auth check). |
| **OQ-CBE05-04** | Bag emit batching for payroll Q-50 employees simultáneo | Default 10ms-paced batch emit. Confirmation post-research perf real Phase A. |

---

## 9. Sign-off matrix C-BE-05 v1.0 LOCKED target

| Stakeholder | Scope | Status DRAFT v0.1 |
|---|---|---|
| ☐ **Founder yaboula** | Final approval privacy contract + CP1 re-definition + 7 public bags + 7 restricted NetEvent domains | **PENDIENTE** review window |
| ☐ **Backend Lead (owner)** | Self-attest spec coherente con C-BE-01..04 + research notes + Q-BE-pre-02/03 founder approved | **DRAFT v0.1 self-signed BANK-BE.0** |
| ☐ **Frontend Lead (consumer consultative)** | Acepta bags shape + NetEvent payloads como UI contract | **PENDIENTE** activation post-H3 |
| ☐ **Security Lead (consumer consultative)** | Acepta privacy boundary + ACE check checkpoints + threat model | **PENDIENTE** activation post-H2 |

---

## 10. Versioning C-BE-05

| Version | Fecha | Cambios |
|---|---|---|
| **v0.1 DRAFT** | 2026-05-06 | BANK-BE.0 — DRAFT inicial post Q-BE-pre-02/03 founder LOCKED. CP1 re-definido sub-tracks A/B. 7 public bags + 7 restricted NetEvent domains. |
| **v1.0 LOCKED** | 2026-05-06 (BANK-BE.LOCK) | Promotion atomic. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested + Frontend Lead (consumer consultative) handoff via H4 future. Promoted: `drafts/be_phase_a/c_be_05_*` → `docs/technical/bank_phase_a/c_be_05_*`. Pointer cross-ref en `docs/technical/02_events_catalog.md` v1.3 LOCKED §statebags-global-publishers. |
| **v1.0.1 R1 LOCKED** | 2026-05-06 (BANK-BE.LOCK.R1) | BANK-BE.AMEND.1 architectural patch Round 1 reactive a Security Lead audit C-SEC-01/02/03 v0.1 DRAFT (founder yaboula APPROVED 2026-05-06): **M004** (`bank.balance.<cid>` + `bank.savings.<cid>` migrated CP1-A → CP1-B; `sonar:bank:balance:update` + `sonar:bank:savings:update` + `sonar:bank:balance:adminAudit` NEW NetEvents canonical; `publish_balance_update()` helper canonical; `playerJoining` lazy publish handler; AP-CP1-1 anti-pattern explicit; bandwidth impact O(N²)→O(1) reduction; financial-grade Zero-Knowledge principle non-negotiable). Sin schema migration impact. **Cross-cutting LOCK-time impacts** aplicados atomic: C-BE-01 (+3 NetEvents → 54 events total), C-BE-02 (callback side effects refactor + new C001b snapshot callback), C-BE-04 (reconciliation pipeline §7.1 step 5 emit refactor). Security Lead BANK-SEC.1 re-audit ✅ PASS veredicto + `08_audit_hooks.md` v0.2 RE-AUDIT. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested + Security Lead PASS. |
| **v1.0.2 R2 LOCKED** | 2026-05-12 (BANK-BE.PHASE_5.1.LOCK.R2) | Phase 5 ecosystem pivot amendment Round 2 reactive a Founder LOCK Q1-Q8 + §9 path (a). **§2.2.1 body PRESERVED VERBATIM** — signature `publish_balance_update(cid, balance, account_class, opts)` unchanged Phase A. **NEW §2.2.1.A** Tier 1/2 exports wrapper consumer pattern (mandate invoke helper post-COMMIT antes del return + UNA call per `account_class` afectado + boilerplate canonical + AP-CP1-1 reafirmada para Phase 5 superficie). **NEW §2.2.1.B** value type Phase A LOCKED path (a) — wrapper convierte INTEGER minor → DECIMAL major vía `units.from_minor()` ANTES del helper invoke; Frontend ZERO touch Phase A; Phase A+1 migra holisticamente con DB + callbacks + Frontend (`@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`). **§4.2 cross-ref nota** Tier 1/2 consumer pattern §2.2.1.A. AP-CP1-1 (§1.4 + §1.5) PRESERVED VERBATIM — REAFFIRMED para Phase 5 superficie. **Sin schema migration impact.** **Cross-cutting LOCK-time impacts** aplicados atomic: C-BE-04 NULLIFY §4 Core Override + NEW §4' Integration API surface, C-BE-02 ADDITIVE §1.2 A18 + §3.1 PLAYER_NOT_LOADED + §10 Server-to-Server Exports surface (22 públicos), C-SEC-01 v0.3 R2 (AH4 atomic mandate + §1.2.A 10-field shape Tier 1/2 + `bank_overdraft` event_type). Security consumer review absorbed by PM Cascade per Founder Decision #3 — BANK-SEC.2 deuda técnica re-audit pending Phase B. Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested + Security consumer PM Cascade absorbed + PM Cascade promote ceremony. |

— **C-BE-05 v1.0.2 R2 LOCKED** 2026-05-12 (BANK-BE.PHASE_5.1.LOCK.R2 ceremony). Sign-off founder + Backend Lead + Security consumer PM-absorbed. **Effective immediately.** Phase 5 implementation Tier 1/2 exports consumes `publish_balance_update` per §2.2.1.A boilerplate. Amendments adicionales require formal Round 3 protocol.
