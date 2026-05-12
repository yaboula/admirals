# AMEND C-BE-05 — StateBags Global Publishers — Round 2 Phase 5 Pivot (DRAFT v0.1)

> **Tipo:** AMENDMENT formal Round 2 — Phase 5 pivot reaffirm CP1-B mandate + path (a) value type clarification.
> **Contract afectado:** C-BE-05 StateBags Global Publishers v1.0.1 R1 LOCKED → propuesta v1.0.2 R2.
> **Status:** 🟡 **DRAFT v0.1 PENDING-SIGNOFF**.
> **Sesión emisora:** `BANK-BE.PHASE_5.1` Phase 1 — 2026-05-12.
> **Authority source:** Founder LOCK Q2 + §9 path (a) — `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md` v1.0.

---

## 0. Resumen ejecutivo

Esta amendment es **MINOR clarificación**, NO breaking. Tres cambios:

1. **Reafirmar mandate CP1-B publish** para la NEW superficie de Tier 1/2
   exports (Phase 5). Cada mutation export DEBE invocar
   `publish_balance_update(citizen_id, balance, account_class, opts)` (§2.2.1
   canonical helper, NetEvent CP1-B post-M004 R1) UNA call por account_class
   afectado, **antes del return al caller**.
2. **Path (a) Founder §9 LOCKED 2026-05-12** — el `balance` arg del helper
   §2.2.1 preserva **DECIMAL major units** durante Phase A. Wrapper Tier 1/2
   convierte INTEGER minor → DECIMAL major vía `units.from_minor(...)`
   ANTES de invocar el helper. Frontend consumers (`web-src/src/lib/bankStateBags.ts`)
   no se tocan Phase A. Phase A+1 migra el tipo (DECIMAL→INTEGER) junto con
   Frontend + DB + callbacks holisticamente.
3. **AP-CP1-1 reaffirmation** — prohibición de canales paralelos preserved.
   Ningún wrapper Tier 1/2 puede inventar su propio `TriggerClientEvent` /
   `GlobalState` para propagar balance. Único canal canónico = `publish_balance_update`.

**Severidad cambio:** MINOR (semantic-preserving clarification).

**Sección modificada:** §2.2.1 + nueva subsección §2.2.1.A (Phase 5 Tier 1/2 wrappers consumer pattern).

**Secciones preservadas verbatim:** §1 + §2.1 + §2.2 + §2.2.1 (body) + §2.2.2 + §3 + §4.

---

## 1. Finding traceability

| ID | Trigger | Severity | Source | Action |
|---|---|---|---|---|
| **P5-005** | Phase 5 introduce NEW Tier 1/2 exports surface — necesita explicitar mandate canonical helper consumption pattern para audit/contract clarity. | MINOR | `@docs/design/04_sonar_bank_api.md` v0.2 §6 mirror + Founder LOCK Q2. | ADD §2.2.1.A consumer pattern Tier 1/2 |
| **P5-006** | Founder §9 LOCKED 2026-05-12 path (a) resuelve conflicto Q1 ↔ Q2 sobre StateBag value type. Sin path (a) explícita, Backend Lead implementación ambigua. | MINOR | `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md:204-254` (§9 NEW). | ADD §2.2.1.B value type Phase A LOCKED |
| **P5-007** | AP-CP1-1 (no parallel state propagation) ya LOCKED v1.0.1 R1 §2.4. Phase 5 NEW exports surface debe reafirmar la prohibición explícitamente para evitar drift implementation. | MINOR | LOCKED v1.0.1 R1 §2.4. | REAFFIRM en §2.2.1.A |

---

## 2. §2.2.1 — Canonical spec balance update — **EXTEND con §2.2.1.A + §2.2.1.B**

### Body §2.2.1 LOCKED v1.0.1 R1 — PRESERVADO verbatim

Referencia LOCKED: `@docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md:109-149` (signature `publish_balance_update(citizen_id, balance, account_class, opts)` + NetEvent CP1-B `sonar:bank:balance:update` / `sonar:bank:savings:update` + offline skip + ownership defensive check + TriggerLatentClientEvent 50KB/s budget).

NO se modifica el body.

---

### §2.2.1.A — **NEW** — Tier 1/2 exports wrapper consumer pattern (Phase 5)

```markdown
#### 2.2.1.A — Tier 1/2 exports wrapper consumer pattern (NEW v1.0.2 R2 — Phase 5)

Cada Tier 1/2 mutation export (C-BE-02 §NEW.10 v1.0.2 R2) DEBE invocar
`publish_balance_update(citizen_id, balance_major_decimal, account_class, opts)`
inmediatamente post-COMMIT SQL transaction y ANTES del return al caller. UNA
invocación por `account_class` afectado:

- Pure credit/debit sobre cuenta main → 1 call `account_class='main'`.
- Pure credit/debit sobre cuenta savings → 1 call `account_class='savings'`.
- Transfer cross-account interno (main → savings o reverso) → 2 calls (main + savings, mismo `correlation_id`).
- Transfer P2P entre 2 citizens distintos → 2 calls (1 por cada citizen_id, ambos `account_class='main'` típicamente).

**Boilerplate canonical Tier 1/2 wrapper post-Phase 5 LOCK:**

\`\`\`lua
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
\`\`\`

**Notas:**

1. `publish_balance_update` retorna `nil` (helper fire-and-forget). Wrapper
   NO espera ack — eventual consistency aceptable. Si player offline o
   ownership mismatch, helper hace early return silencioso (LOCKED §2.2.1
   body lines 122-134) sin error propagado.
2. Cualquier Tier 1/2 wrapper que NO invoque el helper canónico ANTES del
   return = LOCK ceremony fail criterion. PM Cascade verifica grep en
   Phase 5 implementation review.
3. `publish_balance_update` se invoca **post-COMMIT atomic** — si el TX
   falla, NO se invoca helper (return error code apropiado al caller, no
   se emite NetEvent stale).

**AP-CP1-1 prohibition reafirmada Phase 5 (LOCKED §2.4):**

- ❌ ~~`TriggerClientEvent('sonar:bank:custom_balance', -1, ...)`~~ — broadcast all clients PROHIBIDO.
- ❌ ~~`GlobalState['bank.balance.<cid>'] = value`~~ — pattern removed v1.0.1 R1 M004 — financial PII leak.
- ❌ ~~`TriggerLatentClientEvent('my:custom:balance', source, ...)`~~ — canal paralelo PROHIBIDO. Único canal canónico = `publish_balance_update` helper.
- ✅ ÚNICA exception: wrapper puede invocar helper UNA vez por `account_class` afectado, mismo `correlation_id` para auditability.
```

---

### §2.2.1.B — **NEW** — Value type Phase A LOCKED (path (a) Founder §9)

```markdown
#### 2.2.1.B — Value type Phase A LOCKED path (a) (NEW v1.0.2 R2)

**Founder LOCK 2026-05-12 (`@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md` §9):** el arg `balance` del helper `publish_balance_update(citizen_id, balance, account_class, opts)` preserva **DECIMAL major units** durante toda Phase A (string lossless `"1234.56"` o number 1234.56). El NetEvent payload `balance` field consume el mismo tipo.

**Rationale:** Q2 LOCKED literal mencionó "INTEGER minor" para el value, pero Q1 LOCKED preservó "Frontend DECIMAL major no touch Phase A". El conflicto se resolvió path (a) — boundary conversion `units.from_minor()` happens **dentro del wrapper export ANTES** de invocar el helper. El helper firma se mantiene LOCKED v1.0.1 R1 sin cambio.

**Frontend consumers Phase A (LOCKED no touch):**

- `@resources/sonar_bank_app/web-src/src/lib/bankStateBags.ts` (CP1-A residual) y handlers de `sonar:bank:balance:update` / `sonar:bank:savings:update` continúan parseando `balance` field como `number` DECIMAL major (e.g. `1234.56`) y formateando con `useI18n().money(value)`.
- Wrapper Tier 1/2 ejecuta `units.from_minor(new_balance_minor)` → string `"1234.56"` o coerced number — depending de implementation Phase 4 decision (string lossless preferred, number safe para amounts < 9 trillion).

**Phase A+1 migration commitment:**

Phase A+1 (`@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`) migra
end-to-end:

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
```

---

## 3. §1.5 + §2.4 reaffirmation post-Phase 5

LOCKED v1.0.1 R1 §1.5 + §2.4 (AP-CP1-1 anti-patterns) PRESERVADAS verbatim. La amendment NO modifica esas secciones — únicamente las **cita explícitamente en §2.2.1.A** como mandate persistente sobre la NEW superficie de exports Tier 1/2.

---

## 4. §4 update on mutation — minor edit cross-ref

LOCKED v1.0.1 R1 §4.2 update on mutation describe pattern boilerplate post-M004. Añadir nota cross-ref al final de §4.2:

```markdown
**Cross-ref Phase 5 R2:** la nueva superficie Tier 1/2 exports (C-BE-02 §NEW.10 v1.0.2 R2) consume `publish_balance_update` con el mismo pattern boilerplate documentado aquí — ver §2.2.1.A para wrapper consumer flow específico.
```

---

## 5. Compat existing publishers

| Componente | Impacto |
|---|---|
| `publish_balance_update` helper signature LOCKED §2.2.1 | ZERO breaking (path (a) preserves DECIMAL major). |
| `sonar:bank:balance:update` + `sonar:bank:savings:update` NetEvent payload schema | ZERO breaking. |
| `playerJoining` initial snapshot pattern §2.2.2 | ZERO breaking. |
| AP-CP1-1 prohibition §2.4 | ZERO breaking — REAFFIRMED para Tier 1/2 exports. |
| Frontend consumers `web-src/src/lib/bankStateBags.ts` + handlers NetEvent | ZERO touch Phase A — path (a) preserves DECIMAL major. |

---

## 6. Sign-off proposal Round 2

| Role | Sign-off requerido | Notas |
|---|---|---|
| Founder yaboula | ✅ Sí | LOCK Q2 + §9 path (a) authority. |
| Backend Lead Phase 5 | ✅ Sí self-attest | Esta DRAFT v0.1. |
| Security Lead (BANK-SEC.2) | ✅ Sí consumer review | Foco: §2.2.1.A AP-CP1-1 reaffirmation + atomic ordering pattern. |
| Frontend Lead | ✅ Sí consumer ack | Confirma path (a) preserve Frontend types Phase A — no touch consumers. |
| PM Cascade | ✅ Sí promote ceremony | `/lock-contract` Phase 2. |

---

## 7. LOCK promotion path

```
DRAFT v0.1 → REVIEW founder + Security + Frontend ack → SIGNOFF →
LOCK v1.0.2 R2 atomic in-place patch (ADD §2.2.1.A + §2.2.1.B + §4.2 cross-ref nota) →
SESSION_LOG entry BANK-BE.PHASE_5.1 Phase 2 LOCK → Archive este DRAFT.
```

---

## 8. References

- Founder LOCK Q2 + §9 path (a): `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md`.
- Prompt: `@docs/agents/teams/prompts/08_phase_5_ecosystem_api_backend_lead.md` (§4 Phase 1.3).
- C-BE-05 LOCKED v1.0.1 R1: `@docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md:109-184`.
- C-BE-02 R2 amendment (Tier 1/2 exports consumer): `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/c_be_02_amendment_proposal_v0_1.md`.
- C-SEC-01 R2 amendment (audit shape atomic): `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/c_sec_01_amendment_proposal_v0_1.md`.
- Precedente formato: `@docs/agents/teams/amendments/.archived_be_phase_a_r1_v0_2_promoted_v1_0_1_R1/AMEND-C-BE-05-r1-v0.2.md`.

— Backend Lead Phase 5 (BANK-BE.PHASE_5.1)
2026-05-12
