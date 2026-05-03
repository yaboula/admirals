# R0 — Cuestionario Founder (BRIEF-LOGO-001 v2)

> **Ronda:** R0 Kickoff · **Designer:** Opus 4.7 MAX (AI executor path §9 brief) · **Fecha:** 2026-05-03
> **Brief:** `docs/art/briefs/01_brief_logo.md` v2 · **Pre-requisito R1:** este cuestionario respondido o defaults aceptados.
> **Propósito:** alinear ambigüedades del brief / decisiones bloqueantes ANTES de gastar ciclos en R1 conceptos. Cada pregunta tiene **default razonado** que se asume si no respondida — pero respuesta explícita reduce coste de retrabajo R2.

> **Cómo responder:** edita este archivo inline marcando `[x]` en la opción elegida o respondiendo libre. Commit + ping designer (= próxima sesión Opus 4.7 MAX). Si todas se quedan en default, R1 procede con defaults indicados.

---

## Q1 — Concepción del monograma: ¿"S" reconocible o símbolo abstracto puro?

**Contexto:** brief §3.1 lista 5 candidatos basados en la letra "S" (descent-layers, prisma, gradient depth, depth-grid, S-descent). Pero el brief §3.1 también permite "designer puede proponer alternativas C6+ siempre que respeten anti-patterns ADR-012". Pregunta: ¿el monograma DEBE leer como letra "S" o puede ser símbolo abstracto puro (e.g., 3 capas paralelas sin forma de S)?

- [ ] **A. La "S" debe leer claramente** (más reconocible cross-locale, alinea con wordmark "SONAR", baseline más conservadora).
- [ ] **B. Puede ser símbolo abstracto puro** sin forzar lectura "S" (más distintivo, más arriesgado memorability cross-locale).
- [ ] **C. Mix híbrido:** principal lectura "S" pero ambigüedad permitida (e.g., layered-symbol que sugiere S sin obligar). **DEFAULT.**

> **Default si no respondida:** C híbrido. R1 entregará 5 conceptos donde 4/5 leen como "S" + 1/5 explora abstract puro como sondeo.

---

## Q2 — Glow signature en R1 thumbnails: ¿incluir o reservar para R3?

**Contexto:** brief §2.3 menciona glow signature opcional radial Sonar Bright behind logo, pero solo para marketing hero (no favicon/UI). R1 son thumbnails B&W → glow no aplica. ¿Founder quiere ver mock con glow ya en R2 (cuando llega color), o reservarlo R3?

- [ ] **A. Reservar glow R3** (R2 = color sin glow puro; R3 añade glow signature variant). **DEFAULT.**
- [ ] **B. Mock glow ya R2** (alineamiento marketing más temprano, riesgo de evaluar glow antes de elegir concepto base).

> **Default si no respondida:** A. R2 entrega color puro (Sonar Bright sobre Abyss + Sonar Bright sobre Crew 100). R3 añade glow variant + reverse + lockups completos.

---

## Q3 — Tagline en lockup: ¿incluir desde R1 o reservar para R3?

**Contexto:** brief §4.4 menciona tagline opcional *"Hear the depth."* en lockup hero marketing (Inter Tight Medium 14px tracking +4%). ¿Mostrar lockup-with-tagline ya R2/R3 o solo lockup-no-tagline?

- [ ] **A. R3 entrega ambos:** lockup-no-tagline (default UI/web/Tebex) + lockup-with-tagline (hero/trailer). **DEFAULT.**
- [ ] **B. Solo lockup-no-tagline** (tagline gestionado independientemente como typography element fuera del lockup oficial).
- [ ] **C. Tagline como parte fija del lockup** (siempre presente — riesgo: ataja dimensión wordmark mid-zoom).

> **Default si no respondida:** A. Maximum flexibility downstream.

---

## Q4 — App-icon Tablet: ¿variante específica o monograma reutilizado?

**Contexto:** brief §2.1 lista `sonar_logo_monogram.svg` (favicon, app icon Tablet, watermark). Pregunta: ¿el app-icon de la Tablet in-game (que es un dispositivo físico GTA V con pantalla curve glass) requiere variante específica (e.g., con backplate dark + monogram center, optical adjustment para curve glass shader) o el SVG monograma plano se renderiza directo?

- [ ] **A. App-icon Tablet = monograma plano sobre Abyss Black** (`#03070A` rounded square 88px corner radius), sin variante específica. **DEFAULT.**
- [ ] **B. Variante específica** con backplate gradient sutil + safe area optical adjustment para curve glass shader (added como deliverable extra R3).
- [ ] **C. Decidir post-R3** cuando logo final esté locked y curve glass shader probado in-game.

> **Default si no respondida:** A. Flat monogram sobre Abyss Black canvas square. Si curve glass shader exhibe halation post-integración, hotfix R4+.

---

## Q5 — Wordmark "SONAR": ¿Geist Sans Bold o SemiBold?

**Contexto:** brief §4.2 indica Geist Sans SemiBold 600 o Bold 700 "según proporción final". R1 thumbnails NO incluyen wordmark (solo monogramas), pero R2 sí. Decision pre-emptive ahorra rework R2.

- [ ] **A. SemiBold 600** (más refinado, mejor tracking-tight, alinea Vercel/Linear class). **DEFAULT.**
- [ ] **B. Bold 700** (más identity-pop, mejor visibilidad small sizes, riesgo blocky).
- [ ] **C. Decidir R2 cuando se vea con monograma final.**

> **Default si no respondida:** A SemiBold 600 con tracking -3% (medio del rango -2% a -4% brief §4.2).

---

## Q6 — Tagline "Hear the depth": ¿inglés único o ES también canonical?

**Contexto:** Bible v1.4 §1 lista 3 taglines (principal EN *"Hear the depth."*, comercial ES *"La economía RP que escucha cada movimiento."*, operacional EN *"Production-grade roleplay infrastructure."*). Para lockup-with-tagline marketing hero, ¿default tagline = principal EN?

- [ ] **A. Principal EN** (`Hear the depth.`) único en lockup. **DEFAULT.**
- [ ] **B. Variante bilingüe**: lockup-EN para Tebex/web global + lockup-ES para mercado FiveM hispano.
- [ ] **C. Operacional EN** (`Production-grade roleplay infrastructure.`) en hero — más explicativo pero menos memorable.

> **Default si no respondida:** A. Principal EN único; comercial ES y operacional EN se gestionan como copy independiente fuera del lockup oficial.

---

## Q7 — Sign-off founder: ¿yo (yaboula) sólo o veto comunidad?

**Contexto:** brief §1 lista "Reviewer: Founder (final sign-off)". Pregunta administrativa: ¿alguna otra parte (early-access community, advisor designer humano externo) tiene voto blocker antes R4 lock?

- [ ] **A. Founder yaboula único sign-off** R1-R4. **DEFAULT.**
- [ ] **B. Founder + 1 advisor designer humano externo** invited R3 review (no blocker, opinión weighted).
- [ ] **C. Founder + early-access poll comunidad** R3 (riesgo: design-by-committee, brief NO recomienda).

> **Default si no respondida:** A. Founder único decision-maker. Si quieres external advisor R3, abre nuevo issue post-R2.

---

## Q8 — Iconografía coherence: ¿bloquear logo R4 antes de R0 ICONS, o paralelo?

**Contexto:** README briefs SSoT establece BRIEF-ICONS-001 v2 depende de "LOGO R4 cerrado". Pero algunos elementos formales (stroke-width, geometric vocabulary) son cross-pollinables. ¿Founder OK con esperar logo R4 antes de empezar iconos R0, o quiere paralelo?

- [ ] **A. Esperar logo R4 lock** antes de empezar iconos R0 (clean handoff, evita rewrite icons si logo cambia). **DEFAULT (= readme briefs canonical).**
- [ ] **B. Paralelo:** iconos R0 (moodboard + cuestionario) en paralelo a logo R2-R3 (ahorra ~1 semana wallclock, riesgo: rework parcial iconos si logo final invalida assumption stroke-width).

> **Default si no respondida:** A canonical README briefs jerarquía.

---

## Q9 — Founder timezone availability sync R3 (45min)

**Contexto:** brief §7 lista R3 como "Sync 45 min". Si AI path (Opus 4.7 MAX), el "sync" se transforma en review async profundo + ronda preguntas batched. ¿Founder prefiere mantener formato sync simbólico o full async R1-R4?

- [ ] **A. Full async R1-R4** (Opus 4.7 MAX path nativo, no sync calls). **DEFAULT AI path.**
- [ ] **B. Sync R3 simbólico** = founder dedica 45min focus uninterrupted a review + reply async batched mismo día (no llamada).
- [ ] **C. Sync R3 real** = call con designer humano contratado (= cambio de path, brief §9 alternativa).

> **Default si no respondida:** A. Opus 4.7 MAX path async puro.

---

## Q10 — Backlog post-R4: ¿logo motion `sonar_logo_splash_hero.mp4` opt-in?

**Contexto:** brief §2.1 deliverable #12 marca como "stretch goal". Vídeo 4s loop 1080p60 marketing hero + Tablet splash. ¿Founder lo quiere ya R4 o difiere a BRIEF-MOTION-001 v1?

- [ ] **A. Diferir a BRIEF-MOTION-001 v1** (motion designer dedicated). **DEFAULT.**
- [ ] **B. Opus 4.7 MAX path entrega R4 stretch:** SVG animado con SMIL o Lottie minimal (4s loop). Limitación: no After Effects-class polish — baseline functional.
- [ ] **C. Skip motion completamente** logo lockup permanece estático en hero marketing.

> **Default si no respondida:** A. Logo motion gestionado como deliverable BRIEF-MOTION-001 v1 separado, post-LOGO R4 lock.

---

## Notas adicionales founder libres

> Espacio libre para founder añadir contexto, vetos, deseos, edge cases no previstos en preguntas Q1-Q10:

```
[Founder yaboula — escribir aquí free-form si aplica]
```

---

**Fin cuestionario R0 — handoff a Opus 4.7 MAX para R1 conceptos (defaults asumidos si no respondido).**
