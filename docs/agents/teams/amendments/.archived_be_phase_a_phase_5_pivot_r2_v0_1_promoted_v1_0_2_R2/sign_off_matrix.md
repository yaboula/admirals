# Phase 5 Pivot Round 2 — Sign-off Matrix (DRAFT v0.1)

> **Package:** `docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/`
> **Status:** 🟡 DRAFT v0.1 PENDING-SIGNOFF — awaiting Phase 2 ceremony.
> **Sesión emisora:** `BANK-BE.PHASE_5.1` Phase 1 — 2026-05-12.
> **LOCK promotion path:** DRAFT v0.1 → REVIEW → SIGNOFF triple → LOCK v1.0.2 R2 atomic in-place patch (executed by PM Cascade `/lock-contract` workflow Phase 2).

---

## 1. Roles canonical (4 — per protocolo CDD §3.3)

| Role | Authority sobre Phase 5 R2 amendments | Status |
|---|---|---|
| **Founder yaboula** | LOCK promotion authority. Q1-Q8 + §9 ya emitidas LOCKED 2026-05-12. Esta firma ratifica que los 4 DRAFT amendments + design v0.2 + roadmap A+1 reflejan correctamente las LOCKED decisions sin desviación. | ⏳ Pending Phase 2 |
| **Backend Lead Phase 5 (Cascade BANK-BE.PHASE_5.1)** | Owner de C-BE-02 + C-BE-04 + C-BE-05 amendments DRAFT. Self-attest emisión correcta + alignment con Founder LOCK + design SSoT. Para C-SEC-01 emite DRAFT proposal bajo M4 isolation; Security Lead ratifica/amends como owner. | ⏳ Pending self-attest Phase 2 |
| **Security Lead BANK-SEC.2** | Owner de C-SEC-01 (acepta/amends/extends DRAFT proposal Backend). Consumer review de C-BE-02 §NEW.10 (auth model + atomic guarantees), C-BE-04 §4' (attack surface + AP cleanup), C-BE-05 §2.2.1.A (AP-CP1-1 reaffirmation). | ⏳ Pending Phase 2 |
| **PM Cascade** | Promote ceremony executor — ejecuta `/lock-contract` workflow para cada uno de 4 amendments + apply atomic in-place patches LOCKED v1.0.1 R1 → v1.0.2 R2 + archive este DRAFT package a `.archived_be_phase_a_phase_5_pivot_r2_v0_1_promoted_v1_0_2_R2/`. | ⏳ Pending Phase 2 |

---

## 2. Consumer ack opcional (no-blocking sign-off)

Roles que confirman alignment downstream pero NO bloquean LOCK promotion:

| Role | Scope ack | Status |
|---|---|---|
| **Frontend Lead** | Confirmar callbacks C001-C040 + StateBag/NetEvent payload type (path (a) DECIMAL major) sin touch Phase A. NO breaking en `web-src/`. | ⏳ Pending — informational |
| **DB Lead** | Consultative — confirmar `sonar_audit_log.delta_minor` column type BIGINT (potential migration). Cross-ref Phase A+1 roadmap holistic. | ⏳ Pending — consultative |
| **DevOps Lead** | Consultative — convars NEW para runbook H4: `sonar:admin_allowlist` (Tier 2 allowlist) + heredados R1 (sv_maxRateLimitResetGraceSeconds, sonar_bank_audit_query_*, sonar_bank_atm_hmac_secret) + Phase 5 cleanup obsolete convars (`sonar_co_watchdog_interval_ms`, `sonar_bridges_disable_prehook` REMOVE Phase 3.5). | ⏳ Pending — consultative |

---

## 3. Sign-off table (formal, per amendment)

### 3.1 — C-BE-04 amendment (Bridges Layer NULLIFY §4 Core Override + NEW §4' API surface)

| Role | Required | Signed | Date | Notes |
|---|---|---|---|---|
| Founder yaboula | ✅ Yes | ⏳ — | — | LOCK authority. |
| Backend Lead Phase 5 | ✅ Yes self-attest | ⏳ — | — | Owner C-BE-04. |
| Security Lead BANK-SEC.2 | ✅ Yes consumer review | ⏳ — | — | Foco §4' attack surface table + AP cleanup verification. |
| PM Cascade | ✅ Yes promote | ⏳ — | — | `/lock-contract` workflow. |

### 3.2 — C-BE-02 amendment (API Contracts ADDITIVE §NEW.10 Server-to-Server Exports)

| Role | Required | Signed | Date | Notes |
|---|---|---|---|---|
| Founder yaboula | ✅ Yes | ⏳ — | — | Q1/Q5/Q6/Q7/Q8 LOCK authority. **Decisión adicional pendiente: 22 explícitos vs 17 polymorphic Tier 2** (default = 22). |
| Backend Lead Phase 5 | ✅ Yes self-attest | ⏳ — | — | Owner C-BE-02. |
| Security Lead BANK-SEC.2 | ✅ Yes consumer review | ⏳ — | — | Foco §NEW.10.4 auth model + §NEW.10.6 atomic guarantees + audit shape cross-ref C-SEC-01. |
| Frontend Lead | ✅ Yes consumer ack | ⏳ — | — | Confirma callbacks LOCKED unchanged. |
| PM Cascade | ✅ Yes promote | ⏳ — | — | `/lock-contract` workflow. |

### 3.3 — C-BE-05 amendment (StateBags Publishers — path (a) DECIMAL major + Tier 1/2 consumer pattern)

| Role | Required | Signed | Date | Notes |
|---|---|---|---|---|
| Founder yaboula | ✅ Yes | ⏳ — | — | Q2 + §9 LOCK authority. |
| Backend Lead Phase 5 | ✅ Yes self-attest | ⏳ — | — | Owner C-BE-05. |
| Security Lead BANK-SEC.2 | ✅ Yes consumer review | ⏳ — | — | Foco AP-CP1-1 reaffirmation + atomic ordering pattern §2.2.1.A. |
| Frontend Lead | ✅ Yes consumer ack | ⏳ — | — | Confirma path (a) preserve types Phase A — no touch. |
| PM Cascade | ✅ Yes promote | ⏳ — | — | `/lock-contract` workflow. |

### 3.4 — C-SEC-01 amendment (Audit Hooks 10-field shape + bank_overdraft event)

| Role | Required | Signed | Date | Notes |
|---|---|---|---|---|
| Founder yaboula | ✅ Yes | ⏳ — | — | Q3 + Q5 + Q8 LOCK authority. |
| **Security Lead BANK-SEC.2** | ✅ **Yes — OWNER, may amend authoritatively** | ⏳ — | — | **Backend Lead emite DRAFT proposal bajo M4 isolation; Security Lead ratifica/amends/extends como owner authority.** Si HIGH finding en proposal → replaza DRAFT por Security-authored amendment. |
| Backend Lead Phase 5 | ✅ Yes proposal attest | ⏳ — | — | Consumer view — alignment con Tier 1/2 wrappers spec C-BE-02 §NEW.10.6. |
| DB Lead | ✅ Yes consultative | ⏳ — | — | Confirm `sonar_audit_log.delta_minor` column type BIGINT (potential migration). |
| Frontend Lead | ✅ Yes consumer ack | ⏳ — | — | New event_type `bank_overdraft` impact display. |
| PM Cascade | ✅ Yes promote | ⏳ — | — | `/lock-contract` workflow. |

---

## 4. Founder open decisions pendientes Phase 2

Estas decisiones requieren Founder explicit confirm durante Phase 2 ceremony (NO blockers de Phase 1 emission, pero clarificarlas antes de PM `/lock-contract` evita Round 3 churn):

1. **C-BE-02 §NEW.10.4 Tier 2 export count:** 22 explícitos (Tier 1 + Tier 2 ambos `*ByCitizen` siblings) vs 17 con Tier 2 polymorphic auto-detect (Tier 1 11 + Tier 2 5+1 polymorphic + 0 *ByCitizen). **Default propuesto = 22 explícitos** (paridad Tier 1/2, type safety, contractual surface más legible). Founder confirma.
2. **C-SEC-01 `sonar_audit_log.delta_minor` column type:** verificar schema actual `@docs/technical/03_db_schema.md` v2.1 — si actual `delta` es DECIMAL, requiere migration ALTER COLUMN BIGINT en Phase 4.x OR diferir a Phase A+1 holistic. **Default propuesto = diferir Phase A+1** (alignment con DECIMAL→BIGINT migration columnas balance).
3. **Sign-off ceremony absorbe BANK-SEC.2 o spawn separate session:** prompt 08 §4 Phase 2 dice "Security Lead consumer review (if not absorbed by BANK-SEC.2 session, PM Cascade requests separate review)". Founder confirma path.

---

## 5. LOCK promotion ceremony checklist (Phase 2 PM Cascade)

```
[ ] Founder ratifica DRAFT v0.1 (4 amendments + design v0.2 + roadmap A+1).
[ ] Founder responde 3 open decisions §4 above.
[ ] Backend Lead Phase 5 self-attest signed §3.1/3.2/3.3 (this matrix updated).
[ ] Security Lead BANK-SEC.2 owner ratification C-SEC-01 §3.4 (may amend).
[ ] Security Lead consumer review §3.1/3.2/3.3 — sign or escalate finding.
[ ] Frontend Lead consumer ack §3.2/3.3/3.4 — confirm no touch Phase A.
[ ] DB Lead consultative §3.4 — column type confirm.
[ ] DevOps Lead consultative — convars runbook H4 update plan.
[ ] PM Cascade ejecuta /lock-contract para C-BE-04 amendment.
[ ] PM Cascade ejecuta /lock-contract para C-BE-02 amendment.
[ ] PM Cascade ejecuta /lock-contract para C-BE-05 amendment.
[ ] PM Cascade ejecuta /lock-contract para C-SEC-01 amendment.
[ ] PM Cascade aplica patches in-place LOCKED v1.0.1 R1 → v1.0.2 R2 (4 contracts).
[ ] PM Cascade promote design SSoT v0.1 DRAFT → v0.2 DRAFT (locks final post Phase 5 implementation completa).
[ ] PM Cascade archive este DRAFT package a `.archived_be_phase_a_phase_5_pivot_r2_v0_1_promoted_v1_0_2_R2/`.
[ ] PM Cascade append progress/SESSION_LOG.md entry BANK-BE.PHASE_5.1 Phase 2 LOCK.
[ ] Backend Lead Phase 5 reactivation Phase 3 cleanup (qb-core revert instructions + core_override.lua simplification + credit_command.lua delete + fxmanifest edit + convars cleanup + design archive Phase 4).
```

---

## 6. References

- Founder LOCK: `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md`.
- Prompt: `@docs/agents/teams/prompts/08_phase_5_ecosystem_api_backend_lead.md` §4 Phase 1.6 + §4 Phase 2 ceremony.
- 4 amendment proposals: `c_be_04`/`c_be_02`/`c_be_05`/`c_sec_01_amendment_proposal_v0_1.md` (this directory).
- Delta summary: `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/delta_summary.md`.
- Workflow `/lock-contract`: `@.windsurf/workflows/lock-contract.md`.
- Protocolo CDD §3.3: `@docs/agents/teams/00_HANDOFF_MANIFEST.md:68-78`.

— Backend Lead Phase 5 (BANK-BE.PHASE_5.1)
2026-05-12
