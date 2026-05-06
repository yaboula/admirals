# Slice Security — Cherry-pick Blueprint v1.2

> **Cherry-pick blueprint para Security, Compliance & Audit Lead.**
>
> **Audiencia:** Security, Compliance & Audit Lead.
>
> **Fecha:** 2026-05-06.
> **Status:** 🟢 Locked.
> **Source canonical:** `@docs/design/proposals/03_bank_app_blueprint_v1.md` v1.2.

---

## 1. Resumen ejecutivo dominio Security

**Misión:** mindset adversarial + audit ledger inmutable + ACE permissions matrix + autoraise compliance flags + exploit prevention + watchdog Core Override compromise detection. **El que construye no audita.** Tu rol: encontrar gaps en lo que Backend + DB Leads han producido.

**Por qué el orden 3º:** consumes API + FSMs + Bridges LOCKED post-H2 → audit crítico → entregas hooks + ACE + autoraise rules a Frontend (UI gating) y Backend (raisers implementation post amendment).

**Tu output principal Phase A:**
- `docs/technical/08_audit_hooks.md` v1.0 NEW LOCKED (single SSoT con 4 sub-secciones canonical).

---

## 2. Cherry-pick secciones blueprint relevantes

### 2.1 Lectura prioridad ALTA

- **§3 T3 Compliance + Autoraise** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:500-650` (aprox). 5 patterns canonical + thresholds + intervalos.
- **§5.5.2 Govt + ACE permissions** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1620-1680` (aprox). Government Console + Audit Explorer scopes.
- **§5.8 Audit ledger inmutable** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1850-1920` (aprox). Append-only triggers spec.
- **§6 Phase B compliance roadmap** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1700-1900`.
- **§11.2 Edge Case #1 Mutex desync race + #3 Load Order failsafe** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2499-2664`.
- **§11.4 Edge cases secundarios** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2745-2757`. Escrow drain + cuentas premium puras.

### 2.2 Lectura prioridad MEDIA

- **§5.7 Bridges Layer spec** — entender Core Override + Lite Mode para audit threats.
- **§7.2 Scope changes Q10/Q13** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2222-2230`.
- **§11.6 Veredicto técnico Q16** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2803-2826`. Risk score post-mitigations.

### 2.3 Lectura prioridad BAJA

- **§4 UI/UX design** — solo §4.5 Compliance Console + §4.7 Government Console.

---

## 3. Decisiones founder Q1-Q16 filtered (Security-relevantes)

### 3.1 Q10 — 5 patrones autoraise canonical

`structuring` + `large_transfer` + `late_tax` + `velocity` + `new_account_large_deposit`. Eliminado `unusual_destination_foreign_prefix`.

**Tu spec:** thresholds + sliding windows + actions + audit log entries + flag severity per pattern.

### 3.2 Q11 — `compliance_alert` RECHAZAR como evento

Visual fallback only. Frontend no recibe push event compliance_alert. Tu solution: badge derivado de query estado compliance flags (privacy-safe shape minimal en StateBag global).

### 3.3 Q13 — Audit Explorer 3 scopes

- **Mis cuentas** — citizen scope propio.
- **Mis empresas** — owner / employee scope per empresa.
- **Todas (ACE govt)** — `sonar.bank.govt.audit_full` permission only.

**Tu spec:** ACE permissions matrix + UI gating Frontend Lead + server-side enforcement Backend Lead.

### 3.4 Q14 — Defaults agresivos config tax

Review thresholds compliance no colisionen con tax brackets. (Ej. autoraise `late_tax` threshold no debe activarse para deudas <€100 dentro tolerance band.)

### 3.5 Q16 — Hybrid 3-layer + 8 CP

**Audit role tuyo:**

- **CP4 Defensive boot + watchdog** — auditas watchdog logic. ¿Es bypass-able? ¿30s suficiente o progressive needed?
- **CP5 Threshold auto-apply €1000** — define audit log entries per delta + admin flag queue.
- **Q16.6 Defer Discord webhook Phase D** — phase A KVP + console banner suficiente.

---

## 4. Counter-proposals CP-relevantes filtered

| CP | Security Lead role |
|---|---|
| **CP1** State Bags global | **Audit role.** Verifica privacy (compliance.<citizen_id> no leak details). Verifica auth (server-only writable enforced FiveM policy). |
| **CP2** Correlation-ID Mutex | **Audit role.** Cuestiona collision probabilidad UUID v4 + race window real. |
| **CP3** Reconciliation pipeline async | **Audit role.** Cuestiona threshold trust window 5min adaptive vs static. |
| **CP4** Defensive boot + watchdog | **Audit role + spec.** Define watchdog detection logic + bypass detection + alert flow. |
| **CP5** Threshold auto-apply €1000 | **Define audit log entries spec** per delta auto-applied + admin flag queue. |
| **CP6** Reconciliation scope main only | **Audit role.** Verifica premium tiers no leakage en reconciliation logic. |
| **CP7** README + convars | NOT direct Security. |
| **CP8** sonar_bank_status FSM | **Audit role.** Compromised state → audit entry + admin alert. |

---

## 5. Anti-patterns Security-específicos prohibidos

(Per prompt §9.)

- ❌ Server-side check ausente "porque UI ya gate".
- ❌ Hardcoded role names en code.
- ❌ Audit ledger sin retention policy.
- ❌ Compliance flag dismissal sin audit double-entry.
- ❌ Idempotency keys RAM-only.
- ❌ Sensitive data en logs.
- ❌ Risk-acceptance sin firma founder.
- ❌ Audit findings sin severity.

---

## 6. Research recomendado vectors ataque FiveM

(Per prompt §6.1.)

- Lua injection (sv_scriptHookAllowed + sv_pureLevel).
- RPC spoofing / event spoofing.
- NUI message exploitation.
- StateBag write spoofing (verify policy).
- Resource manifest injection.
- Race conditions money flow.
- Replay attacks.
- IDOR.
- Privilege escalation.
- TOCTOU.
- Watchdog bypass.
- Audit ledger tampering (DB direct access).
- Compliance flag dismissal abuse.
- Correlation-id collision (PRNG entropy verify).

---

## 7. Open questions del dominio

| OQ | Pregunta | Recommendation Cascade PM |
|---|---|---|
| **OQ-SEC-01** | 5 autoraise patterns suficientes? | Cuestiona. Quizá `unusual_amount_pattern` + `cross_business_funnel` agregan valor Phase B. Phase A 5 OK. |
| **OQ-SEC-02** | `compliance.<citizen_id>` StateBag privacy | Recommend reduced shape `{ has_active_flags: bool, count: number }`. NO leak flag types. |
| **OQ-SEC-03** | Audit ledger retention indefinite | Recommend 7 años hot + archive cold storage >7 years (legal compliance jurisdictions). |
| **OQ-SEC-04** | Triggers immutability vs app-level | Recommend defense-in-depth (ambos). |
| **OQ-SEC-05** | ACE permissions inheritance | Recommend hierarchy: govt implies player. Document. |
| **OQ-SEC-06** | Multi-signer treasury threshold | Recommend `Config.Empresas.TreasuryMultiSigner.MinSigners = 2` configurable. |
| **OQ-SEC-07** | Watchdog 30s window adequate? | Cuestiona. Recommend dual-tier 30s + 5min + 30min progressive. |
| **OQ-SEC-08** | Idempotency keys storage location | Recommend tabla DB persistent (con DB Lead). RAM-only insufficient. |
| **OQ-SEC-09** | Audit ledger sample fields | Recommend `ip_hash` + `framework_mode` + `sonar_bank_status_at_time` + `correlation_id` + `idempotency_key_used`. |
| **OQ-SEC-10** | Compliance flag dismissal audit double-entry shape | Recommend `flag_id` + `dismissed_by` + `reason` + `timestamp` + `admin_ace_role`. |
| **OQ-SEC-11** | Privacy votes elections (Q1) | Recommend hashed citizen_id + salt. Audit-friendly + privacy. |

---

## 8. Entregables esperados v1.0 LOCKED

### 8.1 SSoT principal

- `docs/technical/08_audit_hooks.md` v1.0 NEW:
  - **§audit-hooks-catalog** — todos hooks ~40 callbacks + 9 FSMs + Bridges events + StateBags writes críticos.
  - **§ace-matrix** — todas permissions canonical + roles + capabilities + enforcement spec.
  - **§autoraise-rules** — 5 patterns canonical Q10 + thresholds + windows + actions.
  - **§exploit-prevention-checklist** — verificación protections aplicadas Backend.
  - **§audit-findings** — findings críticos detected during review (severity + scenarios + mitigations + status).
  - **§watchdog-spec** — watchdog Core Override compromise detection logic.

### 8.2 Sign-off

- founder ✅
- Security Lead ✅ (tú)
- Backend Lead ✅
- DB Lead ✅
- Frontend Lead ✅ (review consultative)

---

## 9. Cross-team contracts

### 9.1 QUÉ EXIGES

- DB Lead: schema + audit ledger table (post-H1).
- Backend Lead: API + FSMs + Bridges (post-H2).
- Founder: ACE matrix design approval (especialmente Q1 govt elected mode).

### 9.2 QUÉ ENTREGAS

- Frontend Lead: ACE matrix UI gating spec + audit hooks (Audit Explorer entries) (post-H3).
- Backend Lead: audit hooks spec (post-H3 — implementación raisers via amendments).
- DB Lead: audit ledger query patterns + index optimization hints.
- DevOps Lead: watchdog detection logic + ACE matrix install procedure + exploit prevention checklist for smoke test.

---

## 10. Citas blueprint canonical

- Compliance + autoraise: `@docs/design/proposals/03_bank_app_blueprint_v1.md:500-650`.
- Govt + ACE: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1620-1680`.
- Audit ledger: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1850-1920`.
- Edge cases #1 + #3: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2499-2664`.
- Edge cases secundarios: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2745-2757`.
- §11.6 veredicto: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2803-2826`.

---

## 11. Versioning

| Version | Fecha | Cambios |
|---|---|---|
| **v1.0** | 2026-05-06 | Initial release. Cherry-pick + Q1-Q16 + CP1-CP8 + 11 OQs filtered. |

— **Slice Security LOCKED** post founder green-light 2026-05-06.
