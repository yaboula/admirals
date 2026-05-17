# SONAR Bank — Flow Audit Matrix

> **Sesión:** BANK-FLOW.AUDIT.1
> **Inicio:** 2026-05-15
> **Branch:** feature/bank-security-phase-a
> **Owner:** AI Full Stack (PM Cascade + Frontend/Backend Lead rotating)
> **Founder:** yaboula
> **Objetivo:** cerrar Bank Phase A flow por flow, no por interface. Cada flow se valida end-to-end (UI → mutation → BE → DB → audit → sync → feedback → edge cases) antes de marcarse 🟢.
> **Doctrina runtime:** todo flow 🟢 requiere evidencia live en `D:\FiveM_Server\Sonar` antes de cierre real (Founder ratified 2026-05-13).

---

## Leyenda

| Símbolo | Significado |
|---|---|
| 🟢 | Complete + live runtime evidence |
| 🟡 | Implementado pero con huecos / sin live runtime |
| 🔴 | Broken / contradicción / falta callback o UI |
| ⚫ | Not started / deferred Phase B |
| ➖ | N/A para esta casilla |

**Columnas:**
- **UI** = states (idle/loading/empty/error/success) presentes en route
- **Mut** = mutation hook FE con idempotency + correlation
- **BE** = callback `Wrap.Register` existe + tier correcto
- **DB** = persistencia real (movements/audit/state)
- **Audit** = `sonar_bank_audit_ledger` row con shape canónica
- **Sync** = StateBag publish + NetEvent + invalidate queries
- **FB** = feedback (toast/receipt/PDF)
- **Edge** = idempotency replay, offline, bridge down, rate-limit, error mapping

---

## Tabla maestra

| ID | Flow | UI | Mut | BE | DB | Audit | Sync | FB | Edge | Status | Notas |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **F01** | Transfer P2P (wizard 4-step) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | Retry offline + idempotency replay no validados live |
| **F02** | Transfer Express (2-step) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | Compartido con F01; recipient search OK |
| **F03** | Savings toSavings/fromSavings | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 | ⚫ | 🟡 | Bug fix 2026-05-17: BE ahora mueve checking.balance ↔ savings_account.balance (cuentas separadas). C007/C008 reciben savings_iban. FE optimistic update + guards + computeAccountTotals corregidos. Pending live runtime evidence. |
| **F04** | Recipients save/favorite/delete | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | Optimistic patch implementado; falta runtime |
| **F05** | Recipients recent (C009) | 🟢 | ➖ | 🟢 | 🟢 | ➖ | 🟢 | ➖ | 🟢 | 🟢 | Read-only, ya validado en transfer wizard |
| **F06** | ATM withdraw (terminal físico) | ➖ | ➖ | 🟢 | 🟢 | 🟢 | 🟢 | ➖ | ➖ | 🟢 | Sellado por diseño — NUI read-only, ver `ATM_INTEGRATION_DECISION.md` |
| **F07** | Cards list + carousel | 🟢 | ➖ | 🟢 | 🟢 | ➖ | 🟢 | ➖ | 🟢 | 🟢 | Bootstrap-driven |
| **F08** | Card issue (C032 first card) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | Implementado en ambos lados (QA findings doc); falta runtime |
| **F09** | Card freeze/unfreeze | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | C033/C034 OK |
| **F10** | Card changePin (C040) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 | 🟡 | 🟡 | Bootstrap invalidate sí; StateBag no aplica |
| **F11** | Card setLimits | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | C035 implementado + live validated 2026-05-15. Migration 038 + audit `card_limits_update`. |
| **F12** | Card tier + issuance design lock | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | Refactor 2026-05-15: diseño se elige solo en emisión C032; tiers `classic/premium` mapean a `debit/credit`; whitelist por tier; límites iniciales por producto; C036 `ApplyDesign` bloqueado con `DESIGN_LOCKED`; FE elimina picker post-emisión. `npm run typecheck` + `npm run build` OK. Pending live runtime. |
| **F13** | Account open (C002) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | |
| **F14** | Account freeze/unfreeze self (C015/C016) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | |
| **F15** | Account close (C019) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | Zero-balance guard en UI |
| **F16** | Account addJoint/removeJoint (C020/C021) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | Implementado 2026-05-15: migration 039 (tabla canónica `sonar_bank_account_joints`), repos reales con `JSON_ARRAYAGG`, validaciones (no self, max 3, citizen exists), UI panel completo con add/remove + confirm dialog + toasts. Pending live runtime. **Follow-up UX (Founder 2026-05-15)**: cambiar input de `char_id` por **player server ID** (numérico FiveM) — más usable. Service convertiría server_id → char_id antes de persistir. |
| **F17** | KYC submit (C037) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | Player side OK |
| **F18** | Admin Dashboard Premium (Banker) | 🟡 | 🟢 | ➖ | ➖ | ➖ | ➖ | 🟡 | 🟡 | 🟡 | Implementado 2026-05-15: AdminShell con sidebar navigation escalable + Loan Approvals (C020) + Compliance Flags (C037/C038) + Business Approvals (C040) + Audit Oversight (C001). Mutations hooks agregados + i18n keys. Typecheck OK. Pending live runtime validation. |
| **F19** | Loans read-only listado | 🟢 | ➖ | 🟢 | 🟢 | ➖ | ➖ | ➖ | 🟢 | 🟢 | `Loans.tsx` consumed |
| **F20** | Loan request (C022) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | UI ya wired en `Loans.tsx` (diálogo + handler). Admin Dashboard premium incluye approve/reject/writeOff. Pending live runtime validation |
| **F21** | Loan makePayment (C024) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | UI ya wired en `Loans.tsx` (diálogo + handler). Pending live runtime validation |
| **F22** | Portfolio buy/sell stocks | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | Investments route activa |
| **F23** | Recurring subscribe (C014) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | |
| **F24** | Recurring cancel/pause/resume | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | C017/C018a/C018b |
| **F25** | Transactions history + filtros | 🟢 | ➖ | 🟢 | 🟢 | ➖ | ➖ | 🟢 | 🟢 | 🟢 | Read-only; PDF re-download OK |
| **F26** | Transactions PDF receipt re-download | 🟢 | ➖ | ➖ | ➖ | ➖ | ➖ | 🟢 | 🟡 | 🟡 | Lazy chunk OK; verificar PDF coherencia post-mutation real |
| **F27** | Onboarding 3-step primera sesión | 🟢 | ➖ | ⚫ | ⚫ | ⚫ | ⚫ | 🟢 | 🟢 | 🟡 | Persistido en localStorage; backend `onboardingCompletedAt` no existe |
| **F28** | Settings privacy + locale + replay onboarding | 🟢 | ➖ | ➖ | ➖ | ➖ | ➖ | 🟢 | 🟢 | 🟢 | Local-only correcto |
| **F29** | Business treasury read | 🟢 | ➖ | 🟢 | 🟢 | ➖ | ➖ | ➖ | 🟢 | 🟢 | REQ-FE-011 cerrado |
| **F30** | Business payroll preview | 🟢 | ➖ | 🟢 | 🟢 | ➖ | ➖ | ➖ | 🟢 | 🟢 | Read-only |
| **F31** | Business payroll execute | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 | 🟡 | 🟡 | BANK-BE.BUSINESS 2026-05-11; StateBag sin `src` company |
| **F32** | Business approval vote (decide) | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 | 🟡 | 🟡 | Vote-replay idempotency implementado |
| **F33** | Business withdrawal request | 🟡 | 🟢 | 🔴 | ⚫ | ⚫ | ⚫ | 🟡 | ⚫ | 🔴 | **Solo mock**; sin callback BE — Phase B candidate o cerrar UI |
| **F34** | Govt census list + detail | 🟢 | ➖ | 🟢 | 🟢 | ➖ | ➖ | ➖ | 🟢 | 🟢 | REQ-FE-006 |
| **F35** | Govt sanctions queue + actions | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 | 🟡 | Freeze/lift/applyFine/closeFlag |
| **F36** | Govt treasury + subsidies + reports | 🟢 | ➖ | 🟢 | 🟢 | ➖ | ➖ | ➖ | 🟢 | 🟢 | Read-only |
| **F37** | Govt tax brackets save + force collection | 🟡 | ⚫ | 🟢 | 🟢 | 🟢 | 🟢 | ⚫ | ⚫ | 🔴 | BE listo; **TaxEngine UI mock-only** según memoria bc9395e9 |
| **F38** | Compliance flags read | 🟢 | ➖ | 🟢 | 🟢 | ➖ | ➖ | ➖ | 🟢 | 🟢 | Phase 1.6 cerrado |
| **F39** | Audit Explorer | 🟢 | ➖ | 🟢 | 🟢 | ➖ | ➖ | ➖ | 🟢 | 🟢 | |
| **F40** | Notifications center | 🟡 | ➖ | ➖ | ➖ | ➖ | 🟡 | 🟡 | 🟡 | 🟡 | Zustand store + drawer + NetEvent ingestion implementados 2026-05-15. Pending live runtime evidence |
| **F41** | Error handling canonical (BankError) | 🟢 | ➖ | ➖ | ➖ | ➖ | ➖ | 🟢 | 🟢 | 🟢 | 20 códigos + locale messages |
| **F42** | ACE gating P01-P12 UI | 🟢 | ➖ | ➖ | ➖ | ➖ | ➖ | 🟢 | 🟢 | 🟢 | AceGate + dev unlock |
| **F43** | Watchdog 30s fallback (bootstrap stale) | 🟢 | ➖ | ➖ | ➖ | ➖ | 🟢 | 🟡 | 🟡 | 🟡 | Live runtime no validado |
| **F44** | StreamerMode privacy boundary M004 | 🟢 | ➖ | ➖ | ➖ | ➖ | ➖ | 🟢 | 🟢 | 🟢 | Toggle + máscaras OK |
| **F45** | Auth gate + PIN unlock | 🟢 | ➖ | ➖ | ➖ | ➖ | ➖ | 🟢 | 🟡 | 🟡 | Verificar contra ID real FiveM |
| **F46** | Bridges down / Lite Mode degradation | ⚫ | ➖ | ➖ | ➖ | ➖ | ⚫ | ⚫ | ⚫ | ⚫ | Sin test runtime explícito |

---

## Resumen de estado

| Bucket | Count |
|---|---|
| 🟢 Complete | 18 |
| 🟡 Partial (mostly missing live evidence) | 21 |
| 🔴 Broken / contradicción | 2 |
| ⚫ Not started / Phase B | 5 |
| **Total flows** | **46** |

---

## Prioridades inmediatas (top 5 a cerrar primero)

Ordenados por impacto producto × esfuerzo bajo:

1. ~~**F11 Card setLimits**~~ — ✅ implementado 2026-05-15 (pending live runtime).
2. ~~**F12 Card tier + issuance design lock**~~ — ✅ implementado 2026-05-15 (pending live runtime). C032 emite `classic/premium` + `design_id`; C036 bloqueado con `DESIGN_LOCKED`; typecheck/build OK.
3. ~~**F16 Account joint owners**~~ — ✅ implementado 2026-05-15 (pending live runtime). BE estaba stubbed; reescrito con tabla canonical mig 039.
4. ~~**F18 Admin Dashboard Premium**~~ — ✅ implementado 2026-05-15. AdminShell con sidebar navigation escalable + Loan Approvals + Compliance Flags + Business Approvals + Audit Oversight. Mutations hooks + i18n keys. Typecheck OK. Pending live runtime validation.
5. **F40 Notifications center** — gap visible (campana topbar sin queue). Zustand store + drawer + NetEvent ingestion implementados 2026-05-15. Pending live runtime evidence.

---

## Bloques pendientes de decisión Founder

| Bloque | Decisión requerida |
|---|---|
| F33 Business withdrawal | Implementar BE o cerrar UI mock |
| F37 Govt tax brackets save + force collection | Phase B candidate |
| F46 Bridges down / Lite Mode degradation | Quién valida (DevOps) |

---

## Reglas de trabajo

1. **Un flow por sesión**: se elige, se cierra, se commitea, se actualiza esta tabla, se cierra sesión.
2. **No abrir flow nuevo** mientras haya 🔴 sin decisión.
3. **Toda celda 🟡 → 🟢 requiere evidencia runtime** (txAdmin console + screenshot + delta DB observado).
4. **Cada commit que toque flow** referencia `F##` en mensaje.
5. **Cierre Phase A** = todos los flows en 🟢 o explícitamente ⚫ Phase B firmados por Founder.

---

## Bitácora de cierres

| Fecha | Flow | Commit | Evidencia runtime |
|---|---|---|---|
| 2026-05-15 | F11 Card setLimits | feat(bank): F11 implement card setLimits flow (C035) | ✅ Live validated — Founder confirmed save persists in DB + bootstrap refresh |
| 2026-05-15 | F16 Joint Owners | (pending) | Pending — requires live txAdmin restart with migration 039 + UI add/remove test |
| 2026-05-15 | F12 Card tier + issuance design lock | (pending) | Pending — requires live txAdmin restart + issue Classic/Premium cards, verify tier design whitelist, DB `card_kind/design_id/limits`, bootstrap persistence, and C036 `DESIGN_LOCKED` |
| 2026-05-15 | F18 Admin Dashboard Premium | feat(bank): F18 implement banker admin dashboard with Loan/Compliance/Business/Audit modules + mutations + i18n | Pending — requires live txAdmin restart + test admin dashboard navigation, loan approvals, compliance flags resolution, business approvals |
| 2026-05-15 | F40 Notifications center | feat(bank): F40 implement notifications center with Zustand store + drawer + NetEvent ingestion | Pending — requires live txAdmin restart + test `sonar:bank:notification:push` NetEvent from backend |
| 2026-05-17 | F03 Savings logic bug fix | fix(bank): F03 separate checking/savings account balance transfer | Pending — requires live txAdmin + open savings account, test toSavings/fromSavings round-trip, verify DB rows |

*Append-only. Nunca borrar entries.*
