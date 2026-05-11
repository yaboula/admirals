# QA + Development Session 1 — SONAR Bank — Roadmap + Findings

> **Session ID:** BANK-QA.DEV.1
> **Fecha inicio:** 2026-05-11
> **Framework target:** QBCore runtime
> **Branch:** feature/bank-security-phase-a (commit 7cb5d34)
> **Roles:** Founder (player) + AI Full Stack Dev/QA Lead
> **Modo:** Bug bash exploratorio + completar lógica backend/frontend
> **Status sesión:** 🟢 ACTIVE

---

## Roadmap de sesión

| # | Módulo | Estado | Descripción |
|---|---|---|---|
| 1 | Transferencias | ✅ COMPLETO | Wizard multi-step + idempotencia + receipt PDF funcional |
| 2 | Card Issuance | 🔍 INVESTIGANDO | Player entra sin tarjetas - verificar flujo bootstrap + issuance |
| 3 | ATM Access Console | ⏸️ PENDIENTE | Cash withdrawal/deposit + receipt printout |
| 4 | GOVT Vertical | ⏸️ PENDIENTE | Census, Sanctions, Treasury, Subsidies |
| 5 | BUSINESS Vertical | ⏸️ PENDIENTE | Registry, Payroll execute/approval |

---

## Estado entorno (onboarding)

| Ítem | Estado |
|---|---|
| Bootstrap snapshot (`sonar:bank:bootstrap:snapshot`) | ✅ Implementado + LRU cache 30s |
| Transfer wizard (`sonar:bank:transfer:execute`) | ✅ Implementado + idempotency UUID v4 |
| GOVT callbacks (`sonar:bank:govt:*`) | ✅ Implementados server-side; frontend conectado vía `useBankCallback` |
| Business callbacks (list/detail/payroll/approval) | ✅ Implementados BANK-BE.BUSINESS 2026-05-11 |
| ATM HMAC (`sonar_bank_atm_hmac_secret`) | ✅ Configurado + auto-test PASS |
| ESX ST-022 | ✅ PASS 6/6 |
| Chaos baseline ST-001→021 | ✅ PASS 100% |
| Issues abiertos conocidos | #001 sonar_companies FK pendiente, #002 migrations 029-032 |
| REQ-FE HIGH open | REQ-FE-006,007,009,010,012,013 (GOVT callbacks mock-only en algunos endpoints) |

---

## Investigación Card Issuance (Módulo #2)

**Estado actual del código:**

**Frontend:**
- `Cards.tsx` (línea 98-100): Si `cards.length === 0`, muestra `RequestFirstCardPanel`
- `RequestFirstCardPanel.tsx`: UI completa para pedir primera tarjeta (PIN 4 dígitos, tipo debit/virtual)
- `mutations/cards.ts`: `useIssueCard()` usa `useBankMutation('sonar:bank:card:issue')` ✅ CONECTADO AL CALLBACK REAL

**Backend:**
- `callbacks/card.lua`: C032 `sonar:bank:card:issue` registrado ✅
- `services/card_service.lua`: `Issue()` function implementada con validaciones (IBAN, PIN, max 3 cards) ✅
- `repos/cards.lua`: SQL queries contra `sonar_bank_physical_cards` ✅

**Bootstrap:**
- `bootstrap_service.lua`: `Cards.BuildSnapshotQuery(citizen_id, 8)` trae tarjetas del repo ✅
- `repos/cards.lua`: `ListByCitizen()` query a `sonar_bank_physical_cards` ✅

**Conclusión:**
El flujo de card issuance está COMPLETAMENTE implementado en ambos lados. El flujo debería ser:
1. Player entra → bootstrap trae `cards[]` (array vacío si no tiene)
2. `Cards.tsx` detecta `cards.length === 0` → muestra `RequestFirstCardPanel`
3. Player llena PIN 4 dígitos + tipo → llama `useIssueCard()`
4. Frontend llama `sonar:bank:card:issue` → backend `CardService.Issue()`
5. Backend inserta en `sonar_bank_physical_cards` → invalida bootstrap
6. Frontend refreshea bootstrap → nueva tarjeta aparece en carousel

**Próximo paso:** Necesito verificar in-game si:
- El UI `RequestFirstCardPanel` se renderiza cuando no hay tarjetas
- La mutation `useIssueCard` funciona en runtime
- Si hay algún error en consola que impida el flujo

---

## Tabla de Findings

| ID | Severity | Categoría | Descripción corta | Archivo(s) impacto | Root cause | Fix | Assigned-to | Status |
|---|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — | — |

*Tabla actualizada en tiempo real durante la sesión.*

---

## Log de reproducción

### BUG-001
*(pendiente primer reporte founder)*

---

## Resumen por categoría (actualizado en cierre)

| Categoría | Total | 🔴 HIGH | 🟡 MEDIUM | 🟢 LOW | ✅ Fixed inline | 🟡 Escalated |
|---|---|---|---|---|---|---|
| A. Core flows | — | — | — | — | — | — |
| B. ATM | — | — | — | — | — | — |
| C. GOVT vertical | — | — | — | — | — | — |
| D. BUSINESS vertical | — | — | — | — | — | — |
| E. Cross-resource | — | — | — | — | — | — |
| F. Concurrency | — | — | — | — | — | — |
| **TOTAL** | **—** | **—** | **—** | **—** | **—** | **—** |

---

## Escalaciones a Tech Leads formales

*(bugs que superan scope QA Tester y requieren issue file + Lead reactivation)*

| Bug ID | Lead responsable | Issue file | Prioridad |
|---|---|---|---|
| — | — | — | — |

---

## Fixes inline aplicados

*(scope simple — copy/styling/debug logs/issue creation)*

| Bug ID | Archivo(s) | Cambio | Commit propuesto |
|---|---|---|---|
| — | — | — | — |

---

*FIN — actualizar en cada bug reportado*
