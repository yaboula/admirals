# AMEND C-SEC-01 — Audit Hooks Catalog — Round 2 Phase 5 Pivot (DRAFT v0.1)

> **Tipo:** AMENDMENT formal Round 2 — Phase 5 architectural pivot. **MINOR clarification**: audit shape canonical preservada, extended con scope explícito sobre la NEW superficie Tier 1/2 exports + 1 NEW event_type enum entry.
> **Contract afectado:** C-SEC-01 Audit Hooks v0.2 LOCKED (consolidated en `@docs/technical/08_audit_hooks.md` §1) → propuesta v0.3 R2.
> **Status:** 🟡 **DRAFT v0.1 PENDING-SIGNOFF**.
> **Sesión emisora:** `BANK-BE.PHASE_5.1` Phase 1 — 2026-05-12.
> **Authority source:** Founder LOCK Q3 + Q5 + Q8 — `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md` v1.0.
> **Owner Lead:** Security Lead (Backend Lead Phase 5 EMITS DRAFT amendment under M4 isolation — Security consumer review mandatory durante Phase 2 sign-off).

---

## 0. Resumen ejecutivo

Esta amendment **NO redefine** la shape canonical del audit row LOCKED v0.2. La superficie Tier 1/2 exports (Phase 5 NEW C-BE-02 §NEW.10) **align verbatim** al shape existente 10-field. Tres cambios MINOR:

1. **Confirmar 10-field shape** aplica a la NEW superficie Tier 1/2 exports (un row per mutation export commit atomic, mismo SQL transaction que la balance mutation).
2. **Extender event_type enum** con `bank_overdraft` (Q5 LOCKED — Tier 2 admin debit con `opts.allow_overdraft=true` flag emite event_type especializado para audit traceability vs debit normal).
3. **Atomic insert mandate explícito** — el audit insert vive dentro del SQL TX de la mutation; no audit_complete async path para exports surface. Cross-ref C-BE-02 §9 R1 LOCKED.

**Severidad cambio:** MINOR (enum additive + scope clarification).

**Owner authority disclaimer:** Backend Lead Phase 5 emite **DRAFT proposal** únicamente. Security Lead BANK-SEC.2 ratifica/amends/extends durante Phase 2 sign-off ceremony per M4 isolation + protocolo CDD §3.3. Si Security Lead encuentra HIGH finding en la propuesta, este DRAFT se replaza por Security-authored amendment.

---

## 1. Finding traceability

| ID | Trigger | Severity | Source | Action |
|---|---|---|---|---|
| **P5-008** | Phase 5 NEW Tier 1/2 exports surface (22 exports) emite audit rows — necesita confirmation explícita de shape canonical aplica + atomic same-TX guarantee documentada. | MINOR | `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md:51-69` (Q3 LOCK) | ADD §1.2.A scope Tier 1/2 |
| **P5-009** | Q5 LOCKED introduce `opts.allow_overdraft=true` Tier 2 only — necesita event_type especializado `bank_overdraft` para distinguir admin_debit normal vs overdraft authorized. | MINOR additive | `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md:84-94` (Q5 LOCK) | ADD enum entry `bank_overdraft` |
| **P5-010** | Cross-decision constraint #2 (`@founder_phase_5_pivot_q1_q8:170`) mandata atomic same-TX (balance mutation + audit insert + idem upsert + StateBag publish). C-BE-02 §9 R1 LOCKED ya lo establecía para callbacks — reafirmar para exports surface explicitamente. | MINOR | Founder cross-decision #2. | ADD §1.1 atomic mandate reaffirm |

---

## 2. §1.1 — Principios — **ADD AH4 atomic mandate** (reaffirm para exports surface)

### BEFORE (LOCKED v0.2)

```markdown
### 1.1 Principios
- **AH1** Todo hook append-only. Nunca UPDATE/DELETE `sonar_bank_audit_ledger`.
- **AH2** Hooks criticos persisten antes de NetEvent/StateBag emit.
- **AH3** Cada hook incluye `correlation_id`, `event_type` ENUM, `occurred_at`.
```

**Spec ref:** `@docs/technical/08_audit_hooks.md:18-22`.

### AFTER (DRAFT v0.3 R2)

```markdown
### 1.1 Principios
- **AH1** Todo hook append-only. Nunca UPDATE/DELETE `sonar_bank_audit_ledger`.
- **AH2** Hooks criticos persisten antes de NetEvent/StateBag emit.
- **AH3** Cada hook incluye `correlation_id`, `event_type` ENUM, `occurred_at`.
- **AH4 (Phase 5 R2)** **Atomic same-TX mandate.** El audit insert vive
  **dentro del mismo SQL transaction** que la balance mutation +
  movement append + idempotency upsert. Si cualquier paso falla, rollback
  total. NO `audit_complete` async path para superficie Tier 1/2 exports
  (cross-ref C-BE-02 §9 R1 LOCKED — mismo pattern para callbacks
  C001-C040). Post-COMMIT side effects (`publish_balance_update` NetEvent
  CP1-B + MirrorSync) son best-effort fire-and-forget — sus fallos NO
  rollbacken el audit.
```

---

## 3. §1.2 — Tabla hooks — **EXTEND scope** (Tier 1/2 exports surface)

### Inserción canónica al final de §1.2 tabla (NEW row)

```markdown
| `audit_hook_exports_mutation` | Tier 1/2 export mutation commit | `bank_credit` / `bank_debit` / `bank_transfer` / `admin_credit` / `admin_debit` / `admin_set_balance` / `account_freeze` / `account_unfreeze` / `bank_overdraft` | 10-field canonical §1.2.A | MEDIUM (NEW row insufficient) — fail blocks TX rollback |
```

### §1.2.A — **NEW** — Shape canonical 10-field aplica a Tier 1/2 exports

Inserción canónica post-§1.3 (shape base) como subsección:

```markdown
### 1.2.A — Tier 1/2 exports audit shape (NEW v0.3 R2)

La nueva superficie Tier 1/2 exports server-to-server (C-BE-02 §NEW.10
v1.0.2 R2 — 22 exports) emite **uno y solo un audit row por mutation
commit**, dentro del mismo SQL TX. Shape canonical 10-field (alineado
Q3 LOCKED + AH4 atomic mandate):

| Field | Type | Nullable | Semantic |
|---|---|---|---|
| `actor_account_id` | VARCHAR(64) | YES | Resolved del actor_src (Tier 2) o source (Tier 1). NULL si console (`actor_src == 0`). Para `*ByCitizen` variants Tier 1 cuando se invoca offline-scheduled (cron payroll, taxes), actor_account_id = `system` literal OR resolved del invoker_resource si el resource declara actor explícito. |
| `target_account_id` | VARCHAR(64) | NO | Target citizen/IBAN UUID afectado. MANDATORY. |
| `event_type` | ENUM | NO | Uno de: `bank_credit` (Tier 1 AddMoney/*ByCitizen), `bank_debit` (Tier 1 RemoveMoney/*ByCitizen), `bank_transfer` (Tier 1 TransferBy*), `admin_credit` (Tier 2 AdminCredit), `admin_debit` (Tier 2 AdminDebit), `admin_set_balance` (Tier 2 AdminSetBalance), `account_freeze` (Tier 2 Freeze), `account_unfreeze` (Tier 2 Unfreeze), `bank_overdraft` (Tier 2 AdminDebit/SetBalance + `opts.allow_overdraft=true`). |
| `delta_minor` | BIGINT | NO | Signed minor units. Positivo = credit, negativo = debit. Para `bank_transfer` se inserta 2 rows (1 debit en payer + 1 credit en payee) con mismo `correlation_id`. Para `account_freeze/unfreeze` delta = 0. |
| `previous_flag_snapshot` | JSON | YES | `{frozen, closed, overdraft_authorized, ...}` ANTES del cambio. NULL para `bank_credit/bank_debit/bank_transfer` puros. MANDATORY para `account_freeze/account_unfreeze/admin_set_balance/bank_overdraft`. Idem H006 R1 fix para shape completa. |
| `request_nonce` | VARCHAR(36) | NO | `opts.idempotency_key` del caller OR `Bridges.UUID.v4()` generado si absent. Persistido también en `sonar_bank_idem.idem_key` (Phase 5 migration 036). |
| `correlation_id` | VARCHAR(36) | NO | `opts.correlation_id` del caller OR mismo valor que `request_nonce` si absent. Cross-resource trace ID. |
| `invoker_resource` | VARCHAR(64) | NO | `GetInvokingResource()` retornado dentro del wrapper export. `'console'` literal si Tier 2 invocado por console (`actor_src == 0`). |
| `reason` | VARCHAR(255) | NO | Free-text sanitized server-side (strip control chars + cap 255 + collapse whitespace). MANDATORY non-empty. |
| `created_at` | INT (epoch sec) OR TIMESTAMP | NO | Server timestamp commit moment. Aligned con LOCKED schema column type per `@docs/technical/03_db_schema.md` v2.1. |

**Atomic insert ordering dentro del wrapper Tier 1/2 wrapper SQL TX:**

\`\`\`lua
-- sonar_bank_app/server/exports/public_api.lua (Phase 5 implementation)
MySQL.transaction.await({
  -- 1. Balance mutation
  { 'UPDATE sonar_bank_accounts SET balance = balance + ? WHERE owner_id = ? AND account_class = ?',
    { units.from_minor(amount_minor_signed), citizen_id, 'main' } },
  -- 2. Movement append-only
  { 'INSERT INTO sonar_bank_movements (...) VALUES (...)', { ... } },
  -- 3. Audit row 10-field shape (this section)
  { 'INSERT INTO sonar_audit_log (actor_account_id, target_account_id, event_type, delta_minor, previous_flag_snapshot, request_nonce, correlation_id, invoker_resource, reason, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    { actor_cid, target_cid, event_type, amount_minor_signed, prev_flag_json or nil, request_nonce, correlation_id, invoker_resource, reason_sanitized, now_epoch } },
  -- 4. Idempotency upsert (si opts.idempotency_key)
  { 'INSERT IGNORE INTO sonar_bank_idem (idem_key, result_json, invoker_resource, created_at) VALUES (?, ?, ?, ?)',
    { opts.idempotency_key, json.encode(result), invoker_resource, now_epoch } },
})
-- TX COMMIT atomic. Post-commit side effects (publish_balance_update + MirrorSync) fire-and-forget.
\`\`\`

**Si cualquier paso 1-4 falla → rollback total + return error code apropiado al caller.** Eventual consistency `publish_balance_update` y `MirrorSync` viven post-COMMIT — sus fallos NO afectan el audit (eventual reconcile path).

**Notas:**

- `delta_minor` se persiste en BIGINT incluso si LOCKED schema actual usa DECIMAL — Founder Q3 explicit "delta_minor: BIGINT signed minor units". DB schema migration MAY require column ALTER si actual `sonar_audit_log.delta` es DECIMAL → revisar `@docs/technical/03_db_schema.md` durante Phase 2 LOCK (DB Lead consult). Phase A+1 holistic.
- Para `bank_transfer` el wrapper inserta **2 audit rows** (1 debit payer + 1 credit payee) mismo `correlation_id` mismo `request_nonce` mismo `created_at`. Permite reconstruir P2P transfer auditing single-key.
- `previous_flag_snapshot` JSON shape canonical para freeze/unfreeze: `{"frozen": false, "frozen_reason": null, "frozen_at": null}` ANTES del cambio. Para `bank_overdraft`: `{"balance_before_minor": <int>, "overdraft_authorized_by": "<actor_cid|console>"}`.
```

---

## 4. §1.2 tabla — **EXTEND event_type enum** con `bank_overdraft`

### BEFORE (LOCKED v0.2 — `audit_hook_admin_override` event_type)

```
| `audit_hook_admin_override` | Admin force action | `admin_force_action` | `{admin_id, action_type, target_citizen_id, justification, previous_state_snapshot}` | HIGH |
```

### AFTER (DRAFT v0.3 R2 — NEW row añadida)

Inserción canónica post `audit_hook_admin_override` row:

```markdown
| `audit_hook_bank_overdraft` | Tier 2 AdminDebit/SetBalance con `opts.allow_overdraft=true` que resulta en balance final negativo | `bank_overdraft` | 10-field canonical §1.2.A + `previous_flag_snapshot` MANDATORY `{balance_before_minor, overdraft_authorized_by}` | HIGH |
```

**Justificación severity HIGH:** overdraft authorized es admin override sobre regla canonical SONAR — toda violación trazable + raisable to compliance pattern AR-P05 (admin override) C-SEC-03 §3.1. Audit trail debe permitir reconciliation forense post-incidente.

---

## 5. §3 — C-SEC-03 Autoraise Rules — cross-ref nota (NO modification)

LOCKED v0.2 §3.1 ya define AR-P05 (admin override cuenta ajena). Phase 5 NEW `bank_overdraft` event_type es CASO específico de admin override — disparará AR-P05 misma manera. NO se requiere NEW autoraise rule. Notar en LOCK ceremony:

```markdown
**Cross-ref Phase 5 R2:** event_type `bank_overdraft` dispara AR-P05 igual que `admin_force_action`. Suppression LOCKED v0.2 §3.1 (1 por admin+target+día TTL 90d) aplica idem.
```

---

## 6. §4 — Findings traceability — no modification

LOCKED v0.2 §4 listing findings H001-M008 R1 preservado verbatim. NEW findings P5-008/009/010 R2 listados en este DRAFT §1 above — no necesitan inserción en §4 LOCKED (Phase 5 amendment package gestiona su propia traceability).

---

## 7. Compat existing audit infrastructure

| Componente | Impacto |
|---|---|
| 12 hooks canonical §1.2 LOCKED | ZERO breaking — 1 NEW row añadida (`audit_hook_bank_overdraft`). |
| Shape base interface `AuditHookBase` §1.3 | ZERO breaking. |
| ACE matrix P01-P12 §2.1 | ZERO breaking. |
| Autoraise rules AR-P01..P05 §3.1 | ZERO breaking — `bank_overdraft` consume AR-P05 existing. |
| `sonar_audit_log` schema | Posible BIGINT column type confirm/migrate (DB Lead consult Phase 2). |
| Frontend Audit Explorer V4 consumer | Streamer Mode masks apply same — NO touch. New event_type localized via i18n key `audit.event.bankOverdraft` (Frontend lead deferred Phase A+1 si necesario). |

---

## 8. Sign-off proposal Round 2

| Role | Sign-off requerido | Notas |
|---|---|---|
| Founder yaboula | ✅ Sí | Q3 + Q5 + Q8 LOCK authority. |
| **Security Lead (BANK-SEC.2)** | ✅ **Sí — OWNER, NOT consumer** | Esta DRAFT v0.1 emitida by Backend Lead bajo M4 isolation; Security ratifica/amends/extends como owner authority del contracto. Si HIGH finding → replaza DRAFT. |
| Backend Lead Phase 5 | ✅ Sí proposal attest | Esta DRAFT v0.1 (consumer view sobre la propuesta — alignment con Tier 1/2 wrappers spec). |
| DB Lead | ✅ Sí consultative | Confirm `sonar_audit_log.delta_minor` column type BIGINT (potential migration). |
| Frontend Lead | ✅ Sí consumer ack | New event_type `bank_overdraft` impact display + i18n keys. |
| PM Cascade | ✅ Sí promote ceremony | `/lock-contract` Phase 2. |

---

## 9. LOCK promotion path

```
DRAFT v0.1 (este file) → REVIEW window Security Lead OWNER + cross-team ack →
SIGNOFF (Security Lead may amend authoritatively durante review) →
LOCK v0.3 R2 atomic in-place patch (apply ADD AH4 + §1.2.A + enum entry bank_overdraft + cross-ref AR-P05) →
SESSION_LOG entry BANK-BE.PHASE_5.1 Phase 2 LOCK → Archive este DRAFT.
```

---

## 10. References

- Founder LOCK Q3 + Q5 + Q8 + cross-decision #2: `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md:51-162`.
- Prompt: `@docs/agents/teams/prompts/08_phase_5_ecosystem_api_backend_lead.md` (§4 Phase 1.4).
- C-SEC-01 LOCKED v0.2: `@docs/technical/08_audit_hooks.md:16-49`.
- C-BE-02 R2 amendment (Tier 1/2 exports consumer): `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/c_be_02_amendment_proposal_v0_1.md`.
- C-BE-05 R2 amendment (NetEvent CP1-B post-COMMIT): `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/c_be_05_amendment_proposal_v0_1.md`.
- DB schema reference: `@docs/technical/03_db_schema.md` v2.1 (BIGINT column type confirm).

— Backend Lead Phase 5 PROPOSAL (BANK-BE.PHASE_5.1)
2026-05-12
**Security Lead OWNER ratification mandatory Phase 2.**
