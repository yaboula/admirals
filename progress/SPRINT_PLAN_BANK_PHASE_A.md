# SPRINT PLAN BANK PHASE A v0.1 DRAFT

> **Owner:** DevOps, Integration & QA Lead
> **Status:** 🟡 v0.1 DRAFT
> **Fecha:** 2026-05-11
> **Baseline:** Handoff H4 (Frontend → DevOps) + BANK-IT.1

---

## 0. Resumen Ejecutivo

Sprint de DevOps para SONAR Bank Phase A. Objetivo: validar integración end-to-end, ejecutar Smoke Chaos Matrix (55 tests), validar multi-framework compatibility (QBox → QBCore → ESX 1.10+), configurar 7 convars, y preparar release engineering para shipping.

**Duración estimada:** 3-5 días (dependiendo de resultados de chaos tests)

---

## 1. Objetivos del Sprint

### 1.1 Objetivos Primarios

- **OP-1:** Validar integración completa DB → Backend → Security → Frontend → DevOps
- **OP-2:** Ejecutar Smoke Chaos Matrix (ST-001 a ST-055) con 100% pass rate
- **OP-3:** Validar multi-framework compatibility (QBox, QBCore, ESX 1.10+)
- **OP-4:** Configurar y validar 7 convars obligatorias
- **OP-5:** Preparar release engineering (fxmanifest, boot order, README Install)
- **OP-6:** Documentar runbook de despliegue y troubleshooting

### 1.2 Objetivos Secundarios

- **OS-1:** Validar watchdog metrics con threshold 0.10
- **OS-2:** Validar production guard para ATM HMAC secret
- **OS-3:** Preparar script de validación pre-despliegue
- **OS-4:** Documentar procedimiento de rollback

---

## 2. Backlog

### 2.1 Sprint Items (Ordered by Priority)

| ID | Item | Prioridad | Estimación | Dependencias |
|---|---|---|---|---|
| **SP-01** | Validar 7 convars en server.cfg | HIGH | 0.5h | Ninguna |
| **SP-02** | Diseñar Smoke Chaos Matrix ST-001 a ST-055 | HIGH | 2h | SP-01 |
| **SP-03** | Implementar test harness Lua para chaos tests | HIGH | 4h | SP-02 |
| **SP-04** | Ejecutar ST-001 a ST-007 (regresión BANK-IT.1) | HIGH | 2h | SP-03 |
| **SP-05** | Ejecutar ST-008 a ST-020 (multi-framework) | HIGH | 4h | SP-04 |
| **SP-06** | Ejecutar ST-021 a ST-030 (lag spike injection) | HIGH | 3h | SP-05 |
| **SP-07** | Ejecutar ST-031 a ST-040 (concurrent reconciliation) | HIGH | 4h | SP-06 |
| **SP-08** | Ejecutar ST-041 a ST-050 (watchdog metrics) | MEDIUM | 2h | SP-07 |
| **SP-09** | Ejecutar ST-051 a ST-055 (ATM HMAC production guard) | MEDIUM | 1h | SP-08 |
| **SP-10** | Validar fxmanifest y load order | HIGH | 1h | SP-05 |
| **SP-11** | Preparar README Install v1.0 | HIGH | 2h | SP-10 |
| **SP-12** | Documentar runbook de despliegue | MEDIUM | 2h | SP-11 |
| **SP-13** | Preparar script de validación pre-despliegue | MEDIUM | 2h | SP-12 |
| **SP-14** | Documentar procedimiento de rollback | LOW | 1h | SP-13 |

---

## 3. Timeline

### Día 1: Setup + Regression Tests
- **09:00 - 09:30:** SP-01: Validar 7 convars en server.cfg ✅ COMPLETADO
- **09:30 - 11:30:** SP-02: Diseñar Smoke Chaos Matrix ✅ COMPLETADO
- **11:30 - 15:30:** SP-03: Implementar test harness Lua
- **15:30 - 17:30:** SP-04: Ejecutar ST-001 a ST-007 (regresión)

### Día 2: Framework + Lag Spike Tests
- **09:00 - 13:00:** SP-05: Ejecutar ST-008 a ST-020 (multi-framework)
- **13:00 - 16:00:** SP-06: Ejecutar ST-021 a ST-030 (lag spike injection)
- **16:00 - 17:30:** SP-10: Validar fxmanifest y load order

### Día 3: Concurrent + Watchdog Tests
- **09:00 - 13:00:** SP-07: Ejecutar ST-031 a ST-040 (concurrent reconciliation)
- **13:00 - 15:00:** SP-08: Ejecutar ST-041 a ST-050 (watchdog metrics)
- **15:00 - 16:00:** SP-09: Ejecutar ST-051 a ST-055 (ATM HMAC guard)

### Día 4: Documentation + Release Engineering
- **09:00 - 11:00:** SP-11: Preparar README Install v1.0
- **11:00 - 13:00:** SP-12: Documentar runbook de despliegue
- **13:00 - 15:00:** SP-13: Preparar script de validación pre-despliegue
- **15:00 - 16:00:** SP-14: Documentar procedimiento de rollback

### Día 5: Buffer + Sign-off
- **09:00 - 12:00:** Buffer para re-tests de failures
- **12:00 - 14:00:** Preparar reporte final de Smoke Chaos
- **14:00 - 16:00:** Sign-off ceremony (DevOps + Security + Founder)

---

## 4. Definition of Done

### 4.1 Por Item

Cada item del backlog está completado cuando:
- ✅ Código implementado y commitado
- ✅ Tests ejecutados y resultados documentados
- ✅ Code review self-attested
- ✅ No bloquea items downstream

### 4.2 Por Sprint

El sprint está completado cuando:
- ✅ Todos los items SP-01 a SP-14 completados
- ✅ Smoke Chaos Matrix 55/55 tests PASS
- ✅ Multi-framework compatibility validada (QBox, QBCore, ESX 1.10+)
- ✅ ESX legacy intentional failure validada
- ✅ 7 convars configuradas y validadas
- ✅ README Install v1.0 listo
- ✅ Runbook de despliegue documentado
- ✅ Script de validación pre-despliegue funcional
- ✅ Procedimiento de rollback documentado
- ✅ Sign-off cuádruple (DevOps, Security, Founder, PM Cascade)

---

## 5. Riesgos y Mitigaciones

### 5.1 Riesgos Identificados

| ID | Riesgo | Impacto | Probabilidad | Mitigación |
|---|---|---|---|---|
| **R-01** | Lag spike tests revelan race conditions | HIGH | MEDIUM | Si ocurre, escalar a Backend Lead para patch |
| **R-02** | ESX 1.10+ bridge detection falla | HIGH | LOW | T2 compatibility best-effort, documentar limitation |
| **R-03** | Watchdog threshold 0.10 genera falsos positivos | MEDIUM | MEDIUM | Ajustar threshold basado en datos reales |
| **R-04** | Concurrent reconciliation causa deadlock | CRITICAL | LOW | Escalar inmediato a Backend Lead |
| **R-05** | Production guard bloquea despliegue por error | HIGH | LOW | Documentar procedimiento de override manual |

### 5.2 Plan de Contingencia

**Si R-01 (race conditions):**
- Pausar sprint
- Escalar a Backend Lead
- Re-activar Backend Lead session BANK-BE.R2
- DevOps Lead en modo consultivo

**Si R-02 (ESX 1.10+ bridge detection falla):**
- Documentar como T2 known limitation
- Marcar ESX 1.10+ como best-effort en README
- Prioridad QBox + QBCore

**Si R-04 (deadlock):**
- CRITICAL: detener tests inmediatamente
- Escalar a Backend Lead + Founder
- No continuar hasta resolución

---

## 6. Dependencies

### 6.1 Upstream Dependencies

- ✅ DB schema v1.2 LOCKED (C-DB-01)
- ✅ Backend contracts v1.0.1 R1 LOCKED (C-BE-01..05)
- ✅ Security audit C-SEC-01/02/03 v0.2 PASS
- ✅ Frontend UI contracts v0.1 DRAFT + BANK-IT.1 first-light

### 6.2 Downstream Dependencies

- Release engineering → Founder approval for Phase A shipping
- README Install → Customer deployment
- Runbook de despliegue → Ops team

---

## 7. Metrics

### 7.1 Success Metrics

- **M-01:** 55/55 Smoke Chaos tests PASS (100%)
- **M-02:** 3/3 frameworks validados (QBox, QBCore, ESX 1.10+)
- **M-03:** 0 regressions de BANK-IT.1
- **M-04:** 7/7 convars configuradas correctamente
- **M-05:** Watchdog threshold 0.10 validado sin falsos positivos
- **M-06:** Production guard validado

### 7.2 Health Metrics

- **H-01:** Tiempo de ejecución Smoke Chaos Matrix < 8h
- **H-02:** 0 bloqueos críticos (deadlock, data corruption)
- **H-03:** < 5% false positives watchdog
- **H-04:** 0 ESX legacy false positives (intentional failure solo en <1.10)

---

## 8. Communication

### 8.1 Daily Standup (Async)

**Formato:**
```
## Progreso
- Items completados: [SP-XX]
- Items en progreso: [SP-YY]
- Bloqueadores: [descripción]

## Próximos pasos
- Items planificados para mañana: [SP-ZZ]

## Métricas
- Tests pass/fail: X/Y
- Frameworks validados: A/B/C
```

### 8.2 Escalation Matrix

- **Tier 1:** DevOps Lead self-resolution
- **Tier 2:** Escalar a Backend Lead (bugs backend)
- **Tier 3:** Escalar a Security Lead (audit hooks)
- **Tier 4:** Escalar a Founder (critical decisions)

---

## 9. Deliverables

### 9.1 Documentación

- ✅ `progress/SMOKE_BANK_PHASE_A_v1.md` v0.1 DRAFT
- 🟡 `progress/SPRINT_PLAN_BANK_PHASE_A.md` v0.1 DRAFT (este documento)
- 🟡 `progress/SMOKE_CHAOS_RESULTS.md` (post-ejecución)
- 🟡 `resources/sonar_bank/README_INSTALL.md` v1.0
- 🟡 `resources/sonar_bank/DEPLOYMENT_RUNBOOK.md` v1.0
- 🟡 `resources/sonar_bank/ROLLBACK_PROCEDURE.md` v1.0

### 9.2 Código

- 🟡 `resources/sonar_bank/tests/smoke_chaos.lua` (test harness)
- 🟡 `resources/sonar_bank/scripts/pre_deploy_validation.lua`
- 🟡 `server.cfg` actualizado con 7 convars ✅

### 9.3 Release Engineering

- 🟡 `fxmanifest.lua` validado (load order correcto)
- 🟡 Boot order documentado
- 🟡 Release sub-tag preparado (v1.0.0-rc1)

---

## 10. Sign-off Matrix

| Role | Status | Fecha | Comentarios |
|---|---|---|---|
| DevOps Lead | 🟡 PENDING | - | Self-attestation post-sprint |
| Security Lead | 🟡 PENDING | - | Audit hooks verification |
| Founder | 🟡 PENDING | - | Production guard validation |
| PM Cascade | 🟡 PENDING | - | Sprint completion acknowledgment |

---

## 11. Post-Sprint

### 11.1 Retrospective

**Questions:**
- ¿Qué fue bien?
- ¿Qué podría mejorar?
- ¿Qué aprendimos?
- ¿Qué acción items para el próximo sprint?

### 11.2 Handoff Preparation

**Post-Phase A shipping:**
- Archivar H4 package
- Preparar H5 package (DevOps → Founder) si aplica
- Documentar lessons learned
- Actualizar SESSION_LOG

---

## 12. Appendix

### 12.1 Referencias

- `docs/agents/teams/prompts/05_devops_integration_qa_lead.md`
- `docs/agents/teams/handoffs/h4_frontend_to_devops/`
- `docs/technical/03_db_schema.md` v1.2 LOCKED
- `docs/technical/04_api_contracts.md` v1.3 LOCKED
- `docs/technical/08_audit_hooks.md` v0.1 DRAFT (LOCKED para Phase A)

### 12.2 Terminología

- **Smoke Test:** Validación rápida de funcionalidad básica
- **Chaos Test:** Validación bajo condiciones adversas (lag, concurrencia)
- **Regression Test:** Validación que bugs antiguos no reaparecen
- **Watchdog:** Monitor de salud del sistema con threshold 0.10
- **Production Guard:** Validación que bloquea despliegue si convars inseguras
