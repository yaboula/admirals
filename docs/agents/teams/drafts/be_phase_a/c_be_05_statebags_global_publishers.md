# C-BE-05 — StateBags Global Publishers Spec (DRAFT v0.1)

> **Owner:** Backend Money & Compatibility Lead.
> **Consumer Leads:** Frontend Lead (consume bags client-side reactive) + Security Lead (audit privacy boundaries).
> **Status:** 🟡 **DRAFT v0.1 — review window open.** No LOCKED hasta sign-off triple founder + Backend + Frontend (consultative) + Security (consultative).
> **Fecha:** 2026-05-06 (BANK-BE.0).
> **Path canonical post-LOCKED:** sub-section dentro de `docs/technical/02_events_catalog.md` v1.3 §statebags-global-publishers.
> **CP origin:** CP1 mandatory (State Bags global mandatory) + Q-BE-pre-02/03 founder LOCKED 2026-05-06 (privacy redefinition).

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

### 1.4 Anti-pattern eliminado

- ❌ ~~`GlobalState['bank.compliance.<citizen_id>'] = { flags: [...detalles...] }`~~ → leak privacy.
- ❌ ~~`GlobalState['bank.escrow.<escrow_id>'] = { participants, amount, state }`~~ → leak shared state a non-participants.
- ❌ ~~`TriggerClientEvent` broadcast a -1 (all clients) Bank balance~~ → CP1 explicitly prohíbe.

### 1.5 Pattern correcto

- ✅ `GlobalState['bank.balance.<citizen_id>'] = number` — citizen propio lee, otros clients también pueden leer pero NO es leak (balance no es PII per se en este contexto).
- ✅ `TriggerLatentClientEvent('sonar:bank:complianceDetail', adminSource, payload)` — admin-only fire post ACE check.
- ✅ `TriggerLatentClientEvent('sonar:bank:escrowStateChanged', payerSource, payload); TriggerLatentClientEvent('sonar:bank:escrowStateChanged', payeeSource, payload)` — participants only.

---

## 2. Catálogo StateBags global publishers Bank Phase A

### 2.1 Public bags (CP1-A) — broadcast all clients OK

| Key pattern | Type | Owner writer | Reader pattern | Privacy classification |
|---|---|---|---|---|
| `bank.balance.<citizen_id>` | `number` (DECIMAL atomic — fiat units, e.g. `1234.56` for €1,234.56) | `sonar_bank_app/server/balance_publisher.lua` | Frontend `AddStateBagChangeHandler('global', 'bank.balance.<citizen_id_self>')` | **Public-safe.** Citizen propio + servidor ven. Otros clients pueden leer numéricamente — no PII directa. |
| `bank.savings.<citizen_id>` | `number` (DECIMAL atomic) | mismo | mismo | Public-safe. Mismo razonamiento balance. |
| `bank.business_treasury.<company_id>` | `number` (DECIMAL atomic) | `sonar_bank_app/server/treasury_publisher.lua` | Frontend treasury widget Empresas Dashboard | Public-safe — treasury balances son visibles en Government Console anyway. |
| `bank.compliance.<citizen_id>.public` | `{ has_active_flags: boolean, count: number }` | `sonar_bank_app/server/compliance_publisher.lua` (raise hooks Security Lead spec post-H2) | Frontend badge UI | **Public-safe reduced shape.** NO detalle (flag_type, severity, evidence). Detalle vía CP1-B NetEvent admin-only. |
| `bank.govt.taxBrackets` | `[{ income_min, income_max, rate }, ...]` | `sonar_bank_app/server/govt_publisher.lua` (admin sets via callback C015) | Frontend tax calculator | **Public-safe.** Tax brackets son ley pública en el server. |
| `bank.govt.subsidies.active` | `[{ category, amount, expires_at }, ...]` | mismo | Frontend government info | Public-safe. Subsidies activas son public knowledge. |
| `bank.bridges.status` | `string` ENUM (CP8 4 states: `native_full` / `lite_mode_active` / `compromised_load_order` / `framework_missing`) | `sonar_bridges/server/bank_status_publisher.lua` (CP8 FSM) | Frontend UI badge footer (CP8 + Q16.3) | Public-safe + transparency by design. Player ve estado infrastructure. |
| `bank.elections.<election_id>` | `{ phase: string, ends_at: epoch_ms, candidate_count: number }` | `sonar_bank_app/server/elections_publisher.lua` | Frontend elections widget | Public-safe — elections phase es info pública. **NO incluye votes counts en flight** (phase `voting_open` → tally hasta phase `vote_count`). |
| `bank.recurring.<citizen_id>.summary` | `{ active_count: number, next_payment_at: epoch_ms \| null }` | `sonar_bank_app/server/recurring_publisher.lua` | Frontend recurring widget | Public-safe reduced shape (no detalles de cada subscription). |

### 2.2 Restricted bags (CP1-B) — discrete NetEvents directos a participants/admin

**Pattern:** **NO se publican en GlobalState.** Backend fires NetEvent dirigido al target source con ACE check server-side antes.

| Domain | NetEvent name | Target audience | ACE / role check |
|---|---|---|---|
| Compliance flag detail | `sonar:bank:compliance:detail` | Admin govt clients only | `IsPlayerAceAllowed(src, 'sonar.bank.govt.audit.full')` |
| Escrow state change | `sonar:bank:escrow:stateChanged` | Payer source + Payee source + admin clients (3 fires separados) | Per-target identity check: source.citizen_id ∈ {escrow.payer_id, escrow.payee_id} OR `sonar.bank.govt.audit.full` |
| Audit ledger query result | `sonar:bank:audit:queryResult` | Requester (per Q13 3 scopes — Mis cuentas / Mis empresas / Todas govt) | Per-scope ACE: `sonar.bank.audit.self` / `sonar.bank.empresas.<id>` / `sonar.bank.govt.audit.full` |
| Loan approval/rejection | `sonar:bank:loan:decisionResult` | Loan applicant source + admin source | source.citizen_id == loan.applicant_id OR admin |
| Election votes raw access | `sonar:bank:elections:votesRaw` | Admin govt clients only (Q-DB-H dual-layer privacy) | `IsPlayerAceAllowed(src, 'sonar.bank.govt.audit.full')` |
| Business treasury approval pending | `sonar:bank:business:approvalPending` | Multi-signers de la empresa (M-of-N) | source.citizen_id ∈ business.signers_list |
| Physical card pin failure / freeze | `sonar:bank:card:pinFailure` | Card owner source only | source.citizen_id == card.owner_id |

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
| `bank` | Prefijo fijo Bank Phase A. | `bank.balance.123` |
| `<domain>` | `balance` / `savings` / `business_treasury` / `compliance` / `govt` / `bridges` / `elections` / `recurring`. | `bank.balance.123` |
| `<id_or_scope>` | `<citizen_id>` (uuid o numeric per `sonar_citizens.id` Q-DB-A) / `<company_id>` (CHAR(36)) / `<election_id>` / `'taxBrackets'` (literal scope). | `bank.business_treasury.abc-123-def-456` |
| `<sub_field>` opcional | `public` / `summary` / `active` (reduced shape qualifiers). | `bank.compliance.123.public` |

**Anti-patterns naming:**

- ❌ ~~`bankBalance.123`~~ — sin separador `.`.
- ❌ ~~`bank_balance_123`~~ — underscore (rompe convention).
- ❌ ~~`Bank.Balance.123`~~ — PascalCase (rompe convention).
- ❌ ~~`bank.balance.123.detail.transactions`~~ — depth >3 (shallow limitation + confusing).
- ❌ Keys dynamic per-session (e.g. `bank.session.<random>`) — no es state bag use case.

---

## 4. Lifecycle StateBag keys

### 4.1 Boot init

`onResourceStart('sonar_bank_app')`:
1. Verify `BankStatus.IsDisabled()` — si disabled, **NO publish bags** (defensive).
2. Hydrate bags desde DB:
   ```
   SELECT bank_account_id, citizen_id, balance, account_class FROM sonar_bank_accounts WHERE owner_type = 'citizen';
   → for each: GlobalState['bank.balance.<citizen_id>'] = balance (filter account_class = 'main').
   → for each: GlobalState['bank.savings.<citizen_id>'] = balance (filter account_class = 'savings').
   ```
3. Hydrate `bank.govt.taxBrackets` desde `sonar_bank_tax_brackets`.
4. Hydrate `bank.bridges.status` desde `sonar_bank_status` (CP8 FSM single-row).
5. Log info `[SONAR][bank] hydrate complete: <N> bags initialized`.

### 4.2 Update on mutation

Cada lib Bank mutation (transfer, deposit, escrow release, payroll, etc.) actualiza bag(s) afectados **en mismo transaction commit DB**. Pattern:

```lua
local function transfer_atomic(payer_cid, payee_cid, amount, reason)
  MySQL.transaction.await({...})  -- DB atomic
  -- post-commit success:
  local new_payer_balance = GlobalState['bank.balance.' .. payer_cid] - amount
  local new_payee_balance = GlobalState['bank.balance.' .. payee_cid] + amount
  GlobalState['bank.balance.' .. payer_cid] = new_payer_balance
  GlobalState['bank.balance.' .. payee_cid] = new_payee_balance
  -- audit ledger append + correlation-id metadata + idempotency commit (libs separadas)
end
```

**Invariant:** bag value siempre refleja DB authoritative balance post-commit. Pre-commit (mid-transaction) NO update bag — evita inconsistency si transaction rollback.

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

Frontend Lead consume via `AddStateBagChangeHandler('global', 'bank.balance.<citizen_id_self>', handler)` para subscription reactive. NO query polling. Throughput driven by Backend emit rate.

---

## 6. Security threats + mitigations

### 6.1 Threat: client lee balance otro citizen

- **Posibilidad:** YES — `GetStateBagValue('global', 'bank.balance.456')` desde client 123. Engine no filtra reads.
- **Mitigation:** balance NO es PII directa. Player puede inspeccionar otros balances pero NO actuar sin auth server-side. Mutaciones requieren callback con auth check server-side (C-BE-02).
- **Acceptable risk:** YES, per founder scope public-safe (game con economía visible — feature, no bug).

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

— **C-BE-05 DRAFT v0.1** open review.
