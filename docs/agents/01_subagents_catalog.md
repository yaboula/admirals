# 🧠 Admirals — Subagents Catalog (ARCHIVADO — referencia futura)

> ⚠️ **ESTADO: ARCHIVADO** (2026-05-01). Decisión founder ADR-001 en `planning/02_decision_log.md`: **subagents en paralelo no son fiables con la tooling AI actual**. Trabajamos **secuencial + planificación e2e robusta** en su lugar.
>
> Este documento se **conserva como referencia** — los checks que define (economy_validator, cross_ref_checker, etc.) siguen siendo **valiosos como checklists mentales secuenciales**, pero **sin ceremonia invocation ("activando rol X")**. El AI simplemente ejecuta el check cuando aplica, sin anunciar subagents.
>
> **Reactivación futura posible** cuando tooling multi-agent sea confiable.

> **Versión:** 1.0 (archivado — referencia).
> **Tipo:** Meta/AI infrastructure. Catálogo de **checks especializados** (originalmente framed como subagents, ahora reinterpretados como checklists secuenciales).
> **Documento padre:** `agents/00_BOOTSTRAP.md` v1.0 (firmado).
> **Documento hermano:** `agents/02_working_conventions.md` v1.0 (firmado).
> **Estado:** archivado (no deprecated — puede reactivarse).

> **Lectura previa obligatoria:** `agents/00_BOOTSTRAP.md` + `planning/02_decision_log.md` ADR-001.

---

## 0. Resumen ejecutivo

Este documento define los **subagents disponibles** en Admirals. Un subagent es un **mental model / persona especializada** que el AI principal **adopta temporalmente** cuando la tarea lo requiere.

> **Filosofía:** los subagents **NO son AIs separados**. Son **modos de operación** del AI principal. Cuando invocas un subagent, estás activando un **protocol específico** con inputs, workflow y outputs definidos.

Define:

- **Filosofía subagents** — qué son, qué no son, cuándo usarlos.
- **Catálogo completo** — 10 subagents con spec detallada:
  - `economy_validator` ⭐⭐⭐⭐
  - `cross_ref_checker` ⭐⭐⭐
  - `doc_writer` ⭐⭐⭐⭐
  - `ssot_auditor` ⭐⭐⭐
  - `signed_doc_guardian` ⭐⭐
  - `fivem_performance_reviewer` ⭐⭐⭐
  - `bus_factor_protector` ⭐⭐
  - `roadmap_planner` ⭐⭐
  - `onboarding_concierge` ⭐⭐
  - `changelog_curator` ⭐
- **Invocation protocol** — cómo activar + notificar al founder.
- **Chaining subagents** — combinar múltiples en workflows.
- **Anti-patterns** — cuándo NO usar subagents.
- **Creating new subagents** — protocolo para añadir al catálogo.

> **Por qué este doc importa:** sin subagents definidos, el AI principal opera en "modo genérico" y comete errores específicos (hallucinaciones números, broken refs, SSoT conflicts). Con subagents, cada tarea tiene **protocolo probado**.

---

## 1. Filosofía subagents

### 1.1 Qué SON los subagents

- ✅ **Protocols especializados** para tareas recurrentes.
- ✅ **Mental models** que fuerzan rigor.
- ✅ **Checklist ejecutable** con workflow definido.
- ✅ **Escalation paths** explícitos.
- ✅ **Output formats** predecibles para el founder.

### 1.2 Qué NO son los subagents

- ❌ **NO son AIs separados** corriendo en paralelo.
- ❌ **NO son tools independientes** con APIs propias.
- ❌ **NO son personalidades** (personality switching).
- ❌ **NO son excusa** para skip verification.
- ❌ **NO son magia** — siguen siendo AI con limitaciones.

### 1.3 Cuándo invocar subagent

| Situation | Subagent sugerido |
|---|---|
| Vas a afirmar un número económico | `economy_validator` |
| Vas a firmar un doc | `cross_ref_checker` + `ssot_auditor` |
| Vas a crear doc nuevo | `doc_writer` |
| Vas a modificar doc firmado | `signed_doc_guardian` |
| Vas a revisar código Lua/JS | `fivem_performance_reviewer` |
| Sesión AI nueva orientándose | `onboarding_concierge` |
| Has aprendido algo importante | `bus_factor_protector` |
| Feature añadida/cambiada | `roadmap_planner` |
| Doc firmado tiene cambio | `changelog_curator` |

### 1.4 Formato invocación estándar

Cuando el AI activa un subagent, anuncia:

> *"Activando rol `[subagent_name]`. [Brief statement de qué va a hacer]. [Inputs requeridos / ya disponibles]."*

Al terminar:

> *"Rol `[subagent_name]` completado. [Resultado resumen]. [Próximos pasos si los hay]."*

---

## 2. Catálogo subagents

### 2.1 `economy_validator` ⭐⭐⭐⭐

**🎯 Purpose:** Verificar que cualquier número económico mencionado (precio, markup, margin, salary, fee) **coincide con la SSoT** `economy/01_economic_model.md`.

**📋 When to invoke:**
- Antes de afirmar un número económico en un doc nuevo.
- Cuando founder pregunta "¿cuánto debería ser X?".
- Al revisar código que hardcodea pricing.
- Antes de firmar cualquier doc con contenido económico.

**📥 Inputs required:**
- El número en cuestión (valor + contexto).
- Categoría económica (pricing, salary, fee, markup, tax, etc.).

**📤 Output format:**
```
VALIDATION REPORT: economy_validator

✅ MATCH / ⚠️ DISCREPANCY / ❌ NOT FOUND

Number checked: X €
Context: "[donde se mencionó]"
SSoT reference: economy/01_economic_model.md §X.Y
Canonical value: X €
Status: [match / derived_ok / discrepancy / missing]

[If discrepancy]: Recommended action
[If derived]: Derivation formula validated
[If missing]: Propose as new canonical + justification
```

**🔄 Workflow:**
1. Extraer número + contexto.
2. Identificar categoría (pricing / salary / fee / etc.).
3. Leer `economy/01_economic_model.md` sección correspondiente.
4. Comparar valor exacto o derivación válida.
5. Si match → ✅ report.
6. Si derivación → verificar fórmula.
7. Si discrepancy → flag + propose resolution.
8. Si missing → flag + propose add to SSoT.

**🚨 Escalation:**
- Discrepancy > 5% vs SSoT → mandatory escalate al founder.
- Missing number que aparece en >2 docs → mandatory escalate.

**💡 Example invocation:**

> *Activando rol `economy_validator`. Voy a verificar el markup Bakery B2B mencionado en un nuevo doc (1.30) contra SSoT economy master.*
>
> *[lee `economy/01_economic_model.md` §6.3]*
>
> *Rol `economy_validator` completado. ⚠️ DISCREPANCY detectada: doc nuevo dice 1.30, SSoT canon dice 1.29 (§6.3.2). Recomiendo corregir doc nuevo a 1.29. ¿Confirmas?*

---

### 2.2 `cross_ref_checker` ⭐⭐⭐

**🎯 Purpose:** Validar que **todas las referencias cruzadas** en un doc son válidas (archivos existen, secciones existen, versiones correctas).

**📋 When to invoke:**
- Antes de firmar un doc.
- Tras actualizar un SSoT (otros docs pueden tener refs obsoletas).
- Auditorías periódicas de integridad documental.

**📥 Inputs:**
- Path del doc a verificar.
- O lista de docs.

**📤 Output format:**
```
CROSS-REF REPORT: cross_ref_checker

Doc analyzed: path/to/doc.md
Total refs found: N
✅ Valid: X
⚠️ Warning: Y (e.g., ref to doc in_progreso)
❌ Broken: Z

Broken refs:
- "ref string" → reason [file not found / section missing / version mismatch]
  Location: line N
  Fix suggested: [...]
```

**🔄 Workflow:**
1. Scan doc por patrones refs: backticks con `.md`, `§`, `v1.X`.
2. Para cada ref: validar existencia archivo.
3. Si archivo existe: validar sección citada (`§X.Y`).
4. Validar versión citada vs versión real.
5. Reportar broken + suggest fix.

**🚨 Escalation:**
- Broken refs > 5 in single doc → mandatory review founder.
- Refs a docs inexistentes (nunca creados) → propose creation.

---

### 2.3 `doc_writer` ⭐⭐⭐⭐

**🎯 Purpose:** Redactar **nuevos docs** siguiendo el estilo Admirals (structure + voice + quality bar).

**📋 When to invoke:**
- Crear nuevo doc de cero.
- Re-estructurar doc existente pobre.

**📥 Inputs:**
- Tema del doc.
- Categoría (design / economy / technical / etc.).
- Docs hermanos/padres para coherencia.
- Requirements específicos del founder.

**📤 Output:**
- Doc completo siguiendo template Admirals.

**🔄 Workflow:**
1. Confirmar scope con founder.
2. Leer docs hermanos / padres para estilo.
3. Leer SSoTs relevantes.
4. Draft estructura (secciones + headings).
5. Redactar contenido siguiendo quality bar §5 BOOTSTRAP.
6. Cross-reference SSoTs.
7. Activar `cross_ref_checker` antes firmar.
8. Presentar a founder.

**📐 Template estructura Admirals:**
```
# [emoji] Admirals — [Título]

> Header (versión, padre, hermanos, referenciados, estado).
> Lectura previa obligatoria.

---

## 0. Resumen ejecutivo

## 1-N. Contenido

## [último-1]. Roadmap + estado

## [último]. Changelog

---

## Resumen ejecutivo (cierre)

> Quote final.

**FIN DEL DOCUMENTO `path.md` v1.0**
```

**🎨 Style reglas:**
- Concreto > abstracto.
- Tablas para datos estructurados.
- Bullets para listas, párrafos para explicaciones.
- Quotes (>) para reglas absolutas.
- Negritas para términos críticos.
- Emojis OK en section markers, NO en código.

**🚨 Escalation:**
- Scope ambiguo → preguntar founder antes drafting.
- Contradicciones con SSoTs → activar `ssot_auditor` primero.

---

### 2.4 `ssot_auditor` ⭐⭐⭐

**🎯 Purpose:** Auditar **consistencia interna** de un SSoT o cross-SSoT consistency.

**📋 When to invoke:**
- Antes firmar un SSoT.
- Periodicidad trimestral (health check).
- Cuando se detecta inconsistencia sospechada.

**📥 Inputs:**
- SSoT a auditar (o "all SSoTs").

**📤 Output:**
```
SSoT AUDIT REPORT: ssot_auditor

SSoT: economy/01_economic_model.md
Sections: N
Internal consistency: ✅ / ⚠️ / ❌
Cross-SSoT consistency: ✅ / ⚠️ / ❌

Issues found:
1. [severity] Description
   Location: §X.Y
   Impact: [...]
   Fix: [...]
```

**🔄 Workflow:**
1. Parse SSoT por claims numéricas / semánticas.
2. Verificar cada claim contra sí mismo (self-consistent).
3. Cross-check contra otros SSoTs.
4. Flag contradicciones.
5. Report prioritized.

**🚨 Escalation:**
- ❌ critical → mandatory escalate + halt further signing.
- ⚠️ warning → report + propose fix.

---

### 2.5 `signed_doc_guardian` ⭐⭐

**🎯 Purpose:** **Proteger docs firmados** de cambios accidentales o inadvertidos.

**📋 When to invoke:**
- Antes de editar doc ya firmado.
- Cuando founder pide "cambio rápido" en doc firmado.

**📥 Inputs:**
- Doc a modificar.
- Cambio propuesto.

**📤 Output:**
```
GUARDIAN CHECK: signed_doc_guardian

Doc: path/to/signed.md
Signed version: vX.Y
Change requested: [description]
Impact assessment:
- SSoT violations: [yes/no]
- Downstream docs affected: [list]
- Requires re-sign: [yes/no]
- Requires founder approval: [yes/no]

Verdict: ✅ SAFE / ⚠️ REVIEW / ❌ BLOCKED
```

**🔄 Workflow:**
1. Verificar que el cambio NO viola SSoTs.
2. Identificar docs downstream que citan este doc.
3. Determinar si cambio es patch (1.0.1) o minor (1.1) o major (2.0).
4. Requerir founder approval si major o SSoT.
5. Si aprueba: aplicar + actualizar changelog + notificar downstream.

**🚨 Escalation:**
- Cambio major a SSoT → siempre escalate founder.
- Cambio que rompe downstream > 3 docs → escalate.

---

### 2.6 `fivem_performance_reviewer` ⭐⭐⭐

**🎯 Purpose:** Revisar código Lua/JS contra **FiveM performance standards** (resmon, State Bags usage, memory).

**📋 When to invoke:**
- Code review Oleada 1+.
- Cuando resmon de un resource sube (>1ms idle).
- Antes de ship feature a server dev.

**📥 Inputs:**
- Path resource / código a revisar.

**📤 Output:**
```
PERFORMANCE REVIEW: fivem_performance_reviewer

Resource: resources/[name]
Resmon idle (measured): X ms
Resmon peak (measured): Y ms
Budget limit (idle / peak): [ref fivem_standards.md]

Issues found:
1. [severity] Description
   File: path:line
   Fix: [...]
```

**🔄 Workflow:**
1. Leer `technical/06_fivem_standards.md` (budgets + rules).
2. Analizar código: loops, intervals, event frequencies, NUI callbacks.
3. Benchmark si possible.
4. Flag anti-patterns: `Wait(0)` loops, state bag abuse, NUI spam.
5. Propose optimizations.

**🚨 Escalation:**
- Resmon > 5ms idle → mandatory escalate.
- State bag patterns incorrectos → mandatory fix.

**📌 Nota:** requiere `technical/06_fivem_standards.md` firmado para operar al 100%.

---

### 2.7 `bus_factor_protector` ⭐⭐

**🎯 Purpose:** Asegurar que **información crítica aprendida** se documenta, para que el proyecto no dependa de la memoria del founder / sesión AI actual.

**📋 When to invoke:**
- Founder comparte learning importante.
- AI descubre pattern durante trabajo.
- Decisión tomada en conversación sin doc.

**📥 Inputs:**
- Información a proteger.
- Contexto.

**📤 Output:**
```
BUS FACTOR CHECK: bus_factor_protector

Info: "[brief]"
Currently documented: [yes/no]
Proposed location:
- [doc path §section] — rationale
Action: [update existing / create ADR / update BOOTSTRAP / etc.]
```

**🔄 Workflow:**
1. Evaluar si info es "project-critical" (afecta decisiones futuras).
2. Buscar doc existente donde encaja.
3. Si no existe: propose ADR en `planning/02_decision_log.md`.
4. Si existe: update.
5. Cross-ref apropiado.

**🚨 Escalation:**
- Info contradice SSoT → combine con `ssot_auditor`.

---

### 2.8 `roadmap_planner` ⭐⭐

**🎯 Purpose:** Mantener `planning/01_roadmap.md` actualizado con nueva info.

**📋 When to invoke:**
- Feature nueva/modificada.
- Delay en sprint.
- Risk nuevo identificado.
- Done criteria cambiado.

**📥 Inputs:**
- Cambio al roadmap propuesto.

**📤 Output:**
```
ROADMAP UPDATE: roadmap_planner

Section affected: §X
Change type: [feature_add / sprint_slip / risk_add / done_criteria / etc.]
Proposed update: [...]
Impact downstream: [...]
```

**🔄 Workflow:**
1. Identificar sección roadmap afectada.
2. Evaluar impacto dependencies graph.
3. Propose update.
4. Founder approval (major changes).
5. Apply + update changelog roadmap.

---

### 2.9 `onboarding_concierge` ⭐⭐

**🎯 Purpose:** Guiar **sesiones AI nuevas** en su orientación inicial al proyecto.

**📋 When to invoke:**
- Primera interacción de sesión AI nueva.
- AI pregunta "¿por dónde empiezo?".

**📥 Inputs:**
- Estado sesión (nuevo / retomando).
- Tarea pendiente (si hay).

**📤 Output:**
- Lista priorizada de docs a leer.
- Tiempo estimado.
- Preguntas al founder si necesarias.

**🔄 Workflow:**
1. Confirmar si sesión nueva o continuación.
2. Si nueva: forzar leer `agents/00_BOOTSTRAP.md` (Round 1 reading §3.1).
3. Si continuación: verificar context transferido, identificar gaps.
4. Proponer reading order personalizado según tarea.
5. Verificar comprensión con quick quiz opcional.

**📋 Onboarding checklist:**
- [ ] Leído BOOTSTRAP.
- [ ] Leído working conventions.
- [ ] Leído roadmap §2 + §4.
- [ ] Leído BIBLE §4 (pilares).
- [ ] Identificado SSoTs.
- [ ] Clara la tarea actual.

---

### 2.10 `changelog_curator` ⭐

**🎯 Purpose:** Mantener changelogs de docs consistentes y informativos.

**📋 When to invoke:**
- Cambio en doc firmado.
- Bump versión doc.

**📥 Inputs:**
- Doc modificado.
- Cambio realizado.

**📤 Output:**
- Entry changelog formateado.

**🔄 Workflow:**
1. Determinar versión bump (patch / minor / major).
2. Redactar entry: versión + fecha + autor + cambios concretos.
3. Append al changelog del doc.
4. Si major change: update BOOTSTRAP §2.2 counters.

**📐 Template changelog entry:**
```
| 1.0.1 | 2026-MM-DD | Founder + Cascade | Patch: [descripción]. |
| 1.1 | 2026-MM-DD | Founder + Cascade | Minor: [descripción]. |
| 2.0 | 2026-MM-DD | Founder + Cascade | Major: [descripción completa]. **Re-sign requerido.** |
```

---

## 3. Invocation protocol

### 3.1 Cómo invocar un subagent

**Formato estándar:**

> *Activando rol `[subagent_name]`.*
>
> *[1 frase descripción tarea].*
>
> *[Inputs que ya tengo / inputs que requiero].*

**Ejemplo:**

> *Activando rol `economy_validator`. Voy a verificar el salary Panadero Tier 3 mencionado en progression_systems (3.800 €/quincena). Input: número + sección. Proceso...*

### 3.2 Cómo reportar finalización

**Formato estándar:**

> *Rol `[subagent_name]` completado.*
>
> *Resultado: [✅ / ⚠️ / ❌].*
>
> *[Resumen hallazgos].*
>
> *[Próximos pasos si los hay].*

### 3.3 Múltiples subagents en paralelo

> **SÍ se permite invocar varios subagents consecutivos** para cubrir aspectos distintos.

**Ejemplo workflow firma doc:**
1. `cross_ref_checker` → verifica refs.
2. `ssot_auditor` → verifica coherencia.
3. `economy_validator` → verifica números (si aplica).
4. `signed_doc_guardian` → verifica impacto downstream.
5. `changelog_curator` → actualiza changelog.

**Anuncio múltiple:**

> *Para firmar este doc, activaré en secuencia: `cross_ref_checker` → `ssot_auditor` → `economy_validator` → `signed_doc_guardian` → `changelog_curator`.*

---

## 4. Chaining subagents — workflows comunes

### 4.1 Workflow "Firmar doc nuevo"

```
1. cross_ref_checker        (refs válidas?)
2. ssot_auditor             (coherente con SSoTs?)
3. economy_validator        (números OK?) — si aplica
4. bus_factor_protector     (info crítica documentada?)
5. → Founder review
6. → Aprobado → changelog_curator (update changelog)
7. → Firmar + update BOOTSTRAP §2.2
```

### 4.2 Workflow "Modificar doc firmado"

```
1. signed_doc_guardian      (safe to modify?)
2. → Aprobado → hacer edit
3. cross_ref_checker        (refs siguen válidas?)
4. ssot_auditor             (coherencia preservada?)
5. changelog_curator        (changelog update)
```

### 4.3 Workflow "Agregar feature al roadmap"

```
1. bus_factor_protector     (context capturado?)
2. roadmap_planner          (propose update)
3. → Founder review
4. → Aprobado → apply
5. changelog_curator        (roadmap changelog)
```

### 4.4 Workflow "Code review PR FiveM"

```
1. fivem_performance_reviewer  (perf OK?)
2. economy_validator           (hardcoded numbers OK?) — si aplica
3. → Issues? → fix
4. → OK → merge
```

### 4.5 Workflow "Nueva sesión AI"

```
1. onboarding_concierge     (guide reading)
2. → AI reads bootstrap + conventions + roadmap
3. → Founder define task
4. → Task-specific subagents según §1.3
```

---

## 5. Anti-patterns — cuándo NO usar subagents

### 5.1 Overhead trivial

- ❌ **NO invocar `economy_validator` para cambio $1**. Proporcional al impacto.
- ❌ **NO chain 5 subagents para typo fix**.

### 5.2 Security theater

- ❌ **NO anunciar subagent sin ejecutar workflow**. Si dices "activo X", DEBES hacer el workflow.
- ❌ **NO usar subagent como excusa** para saltar verification real.

### 5.3 Confusing founder

- ❌ **NO anunciar subagent en respuesta conversacional**. Si founder pregunta "¿cómo estás?", no "activo onboarding_concierge".
- ❌ **NO abusar jerga subagent** cuando comunicación natural basta.

### 5.4 Perfeccionismo

- ❌ **NO correr auditorías completas cada sprint** si no hay señal.
- ❌ **NO invocar `ssot_auditor` trimestral si sabes que no cambió nada**.

---

## 6. Creating new subagents

### 6.1 Cuándo crear nuevo subagent

> **Si una tarea/check se repite >3 veces, candidato a subagent.**

Signs:
- Pattern recurrente.
- Necesita inputs estructurados.
- Output predecible.
- Escalation rules claras.
- Founder pide consistency en este tipo de tarea.

### 6.2 Template para nuevo subagent

```markdown
### N.M `subagent_name` ⭐⭐⭐

**🎯 Purpose:** [1 frase objetivo].

**📋 When to invoke:**
- [Situación 1]
- [Situación 2]

**📥 Inputs required:**
- [Input 1]
- [Input 2]

**📤 Output format:**
```
REPORT TITLE: subagent_name
[estructura output]
```

**🔄 Workflow:**
1. [Step 1]
2. [Step 2]
...

**🚨 Escalation:**
- [Condición 1] → action
- [Condición 2] → action

**💡 Example invocation:**

> *[Ejemplo uso natural].*
```

### 6.3 Proceso añadir

1. Draft spec usando template §6.2.
2. Discuss con founder.
3. Aprobado → add a §2 catálogo.
4. Update tabla §1.3 (cuándo invocar).
5. Update BOOTSTRAP §11.2 (catálogo brief).
6. Test run primer uso + iterate.

---

## 7. Health metrics subagents

### 7.1 Cómo saber si subagents funcionan

| Metric | Target |
|---|---|
| **Hallucinations económicas (vs SSoT)** | 0 (thanks to `economy_validator`) |
| **Broken cross-refs at firma** | 0 (thanks to `cross_ref_checker`) |
| **SSoT contradictions detected** | >90% early (thanks to `ssot_auditor`) |
| **Signed docs corrupted accidentally** | 0 (thanks to `signed_doc_guardian`) |
| **Resmon violations caught pre-merge** | >95% (thanks to `fivem_performance_reviewer`) |
| **Info lost entre sesiones AI** | <5% (thanks to `bus_factor_protector`) |
| **Onboarding time nueva sesión AI** | <90 min (thanks to `onboarding_concierge`) |

### 7.2 Cuándo retirar un subagent

- Si >3 meses sin uso.
- Si reemplazado por tooling automático (linter, test suite).
- Si founder explícitamente dice "ya no necesito esto".

---

## 8. Roadmap + estado

### 8.1 Roadmap subagents

#### Oleada 0 (incluido)
- ✅ 10 subagents core definidos.
- ✅ Invocation protocol.
- ✅ Chaining workflows comunes.

#### Oleada 1 (durante MVP)
- 🔜 `test_runner` (manual test suite FiveM).
- 🔜 `sprint_retro_facilitator` (estructura retros).
- 🔜 `demo_preparer` (prep demo fin-sprint).

#### Oleada 2
- 🔜 `player_feedback_analyzer`.
- 🔜 `economy_balance_tuner` (real data).
- 🔜 `community_moderator_assistant`.

### 8.2 Estado del documento

- **Versión:** 1.0 (firmable — completo, 8 secciones).
- **Próxima revisión:** tras primeros usos reales Oleada 1 (validar workflows en runtime).
- **Documento padre:** `agents/00_BOOTSTRAP.md` v1.0.
- **Documento hermano:** `agents/02_working_conventions.md` (próximo).

### 8.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Primera redacción. 10 subagents core + invocation protocol + chaining workflows + anti-patterns + creation template. **Firmable.** |

---

## 9. TL;DR — reference rápida

### Los 10 subagents

| # | Subagent | Primary use |
|---|---|---|
| 1 | `economy_validator` | Verificar números económicos |
| 2 | `cross_ref_checker` | Validar refs entre docs |
| 3 | `doc_writer` | Redactar docs nuevos |
| 4 | `ssot_auditor` | Auditar SSoTs coherencia |
| 5 | `signed_doc_guardian` | Proteger docs firmados |
| 6 | `fivem_performance_reviewer` | Code review FiveM perf |
| 7 | `bus_factor_protector` | Documentar info crítica |
| 8 | `roadmap_planner` | Update roadmap |
| 9 | `onboarding_concierge` | Guiar sesiones nuevas |
| 10 | `changelog_curator` | Mantener changelogs |

### Workflows comunes

- **Firmar doc:** cross_ref → ssot_audit → economy_val → guardian → changelog.
- **Modificar firmado:** guardian → edit → cross_ref → ssot_audit → changelog.
- **Nueva sesión AI:** onboarding_concierge → task-specific.
- **Code review:** fivem_perf → economy_val → merge.

### Cuándo NO usar

- Tareas triviales.
- Comunicación conversacional.
- Perfeccionismo sin señal.
- Security theater sin workflow real.

---

## Resumen ejecutivo (cierre)

Los **Subagents Admirals** son protocols especializados que:

- **10 subagents core** cubren economía, refs, docs, SSoTs, firmas, FiveM perf, bus factor, roadmap, onboarding, changelogs.
- **Invocation protocol** explícito: anuncia → ejecuta workflow → reporta.
- **Chaining workflows** para tareas compuestas (firmar doc, modificar, code review).
- **Anti-patterns** previenen overhead trivial + security theater.
- **Template creation** para añadir nuevos según se descubren patterns.
- **Health metrics** miden si funcionan (0 hallucinations, 0 broken refs, etc.).

> **Objetivo final:** cualquier AI agent que opere en Admirals con este catálogo tiene **herramientas mentales** para no cometer los errores comunes de AI en codebase complejo. El catálogo es la **memoria institucional** de cómo trabajamos con calidad.

---

*"Un AI sin subagents es ruido. Un AI con subagents es una disciplina."*

**FIN DEL DOCUMENTO `agents/01_subagents_catalog.md` v1.0**
