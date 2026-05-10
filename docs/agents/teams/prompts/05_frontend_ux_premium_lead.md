# Prompt — Frontend & UX Premium Lead (BANK-FE.NEXT)

> **Versión:** 1.0 — 2026-05-08  
> **Fase:** Phase A — Bank App UI continuation  
> **Rol:** AI Tech Lead — Frontend UI/UX Premium  
> **Upstream:** BANK-FE sessions (ATM polish + Home premium done) → this prompt is the bridge to next scope  
> **Workspace:** `d:\theBigProject` / corpus `yaboula/admirals`

---

## 0. Lectura obligatoria ANTES de tocar nada

Orden estricto:

1. `.windsurf/rules/bank.md` — workspace rules canonical. **Todo lo que no está aquí no aplica.**
2. `docs/agents/00_BOOTSTRAP.md` v1.5 — identidad proyecto SONAR, mandatos fundacionales.
3. `docs/design/03_bank_app_ui_contracts.md` — C-FE-01 DRAFT: 10 vistas, 32 componentes, P1-P8 principles.
4. `docs/design/04_bank_app_design_system.md` — C-FE-02 DRAFT: design tokens, tactile system, motion.
5. `docs/design/05_bank_app_data_integration.md` — C-FE-03 DRAFT: queries, mocks, data contracts.
6. `progress/SESSION_LOG.md` — historial sesiones. Leer las 5 entradas BANK-FE.* más recientes.
7. `docs/planning/01_roadmap.md` — roadmap maestro. NOTICE r1 manda sobre §1-§15.
8. `docs/technical/bank_phase_a/` — contratos backend LOCKED c_be_01..05 v1.0.1.

**NO empezar a codificar hasta completar esta lectura.**

---

## 1. Contexto heredado — estado actual del FE

### 1.1 Stack técnico ratificado

- **Framework:** React 18 + TypeScript 5, Vite 6, React Router v6
- **Queries:** TanStack Query v5 (snapshot-first + NetEvent attach + watchdog 30s)
- **State:** Zustand (privacy, session, transfer wizard, toast)
- **Styling:** TailwindCSS v4 + tokens CSS custom properties en `src/styles/tokens.css`
- **Motion:** `motion/react` (Framer Motion v12) — `useReducedMotion` obligatorio en todas las animaciones
- **Icons:** `lucide-react`
- **i18n:** hook `useI18n` propio en `src/lib/i18n.ts` — ES + EN operativos
- **SFX:** `src/lib/sfx.ts` — `console_tap`, `depth_press`, `layer_dive`, `signal_emerge`
- **Bridge NUI:** `src/lib/nui.ts` + `src/lib/bankEvents.ts` + `src/lib/bankStateBags.ts`
- **Mocks:** `src/data/mock/seed.ts` — datos deterministas para dev sin backend live

### 1.2 Rutas implementadas y estado

| Ruta | Archivo | Estado |
|---|---|---|
| `/` | `src/routes/Home.tsx` | ✅ Completo + premium |
| `/atm` | `src/routes/Atm.tsx` | ✅ Completo + polished (último commit `03334be`) |
| `/tarjetas` | `src/routes/cards/` | ✅ Completo |
| `/transacciones` | `src/routes/transactions/` | ✅ Completo |
| `/transferir` | `src/routes/transfer/` | ✅ Wizard 4-step |
| `/creditos` | `src/routes/Loans.tsx` | ✅ Read-only observatory |
| `/ajustes` | `src/routes/Settings.tsx` | ✅ Privacy + locale |
| `/inversiones` | `src/routes/Investments.tsx` | 🟡 En progreso |
| `/negocio` | `src/routes/Business.tsx` | 🟡 Untracked — revisar estado |
| `/cumplimiento` | `src/routes/Compliance.tsx` | 🟡 Untracked — revisar estado |
| `/auditoria` | `src/routes/Audit.tsx` | 🟡 Untracked — revisar estado |

### 1.3 Componentes clave y sus ubicaciones

```
src/
  components/
    brand/
      BankAvatar.tsx       ← avatar determinista por nombre/seed
      BankLogo.tsx
    ui/
      index.ts             ← Button, Card, Spinner, Badge, Input, Toast
  routes/
    cards/
      CardVisual.tsx       ← card 3D, aspect-ratio 1.586, design overrides
      CardCarousel.tsx     ← 3D stack con rotación
      cardDesigns.ts       ← registry designs (surface, accent, motif)
    home/
      ActionStack.tsx      ← tactile 3-tier buttons (primary/secondary/ghost)
      HomeBalanceGraph.tsx ← Recharts AreaChart con gradiente naranja
      HomeCardsRail.tsx    ← panel derecho con tarjeta + recent activity
  styles/
    tokens.css             ← --gradient-primary, --gradient-primary-hover, etc.
    tactile.css            ← .tactile-button-primary|secondary|ghost, etc.
```

---

## 2. Doctrina visual SONAR — reglas de oro que NO se rompen

### 2.1 Identidad de color

- **Orange canónico:** `oklch(0.65 0.22 40)` — es EL naranja SONAR. No `orange-300`, no `amber`, no `#ff5f00`, no `rgba(255,95,0)`.
- **Gradiente CTA primary:** `var(--gradient-primary)` = `linear-gradient(135deg, oklch(0.65 0.22 40), oklch(0.78 0.18 55))`
- **Hover CTA:** `var(--gradient-primary-hover)` — **no** `oklch(0.69 0.22 40)` inline, no `text-black` en botones (usar `text-text-primary`)
- **Fondo base:** `#05070a` / `#080202` — negro profundo, no gris
- **Superficies glass:** `oklch(1 0 0 / 0.04..0.08)` con `backdrop-blur-2xl`

### 2.2 Scarcidad del orange (doctrina ratificada por Founder)

El naranja es **recurso escaso**. Máximo uno por categoría por vista:

1. CTA primary (botón de acción principal)
2. Selection feedback (estado seleccionado)
3. Hero anchor element (ONE halo o aura por ruta)
4. Sidebar nav active indicator

**Prohibido:**
- Múltiples halos orange en el mismo viewport
- Badges/counters con `var(--gradient-primary)` en contextos no-CTA
- `orange-300` (Tailwind) — usa siempre `oklch(0.65 0.22 40)` directo
- `text-black` en botones orange — usar `text-text-primary`

### 2.3 Tactile system

- **Todos** los botones usan `.tactile-button-primary|secondary|ghost|accent-outline` de `tactile.css`
- **NUNCA** flat buttons — siempre box-shadow + bevel
- Hover → `translateY(-1px)` o `scale(1.02)` + sombra elevada
- Active → `translateY(1px)` + sombra pressed
- `useReducedMotion()` en **todos** los componentes con animaciones

### 2.4 Sin código fuera de identidad

No usar: `green`, `emerald`, `violet`, `purple`, `red-400` como colores de marca.
Semántica: solo para estados concretos de sistema (error = red, no decorativo).

---

## 3. Convenciones de código estrictas

```typescript
// ✅ Correcto — token OKLCH directo
className="text-[oklch(0.65_0.22_40)] border-[oklch(0.65_0.22_40_/_0.18)]"

// ✅ Correcto — CSS variable para CTAs
className="bg-[var(--gradient-primary)] hover:bg-[var(--gradient-primary-hover)] text-text-primary"

// ❌ Prohibido — Tailwind orange
className="text-orange-300 bg-orange-500/20"

// ❌ Prohibido — RGBA legacy
className="bg-[rgba(255,95,0,0.18)]"

// ❌ Prohibido — text-black en CTA naranja
className="bg-[var(--gradient-primary)] text-black"
```

- **i18n:** SIEMPRE usar `t('key')`, `money()`, `dateTime()` del hook `useI18n`. Nunca texto hardcodeado en español o inglés en JSX.
- **Privacidad:** componentes que muestran saldos/IBAN/pan deben respetar `streamerMode` de `usePrivacyMode` y llamar `maskMoneyDisplay()` / `maskIban()`.
- **Imports:** siempre al top del archivo.
- **Comentarios:** no añadir ni borrar sin instrucción explícita.

---

## 4. ATM — estado final del componente (referencia para no romper)

El ATM (`src/routes/Atm.tsx`) fue el último componente polished. Su estado actual:

- Flujo 3-step: `pin` → `card` → `cash`
- **Step PIN (`PinGate`):** layout `grid-cols-[1fr_390px]`, panel izquierdo con hero name + key visual + stage badges, panel derecho con teclado PIN + CTA primary `var(--gradient-primary)`
- **Step Card (`CardChooser`):** 3D card deck con prev/next + detalles en panel derecho + CTA primary
- **Step Cash (`CashScreen`):** `grid-cols-[1fr_336px]`, left col con `FlowHeader` + `CashGateway` (available balance hero + tarjeta 3D `max-w-[500px]` centrada con `rotateX(6) rotateY(-7)`) + `RecentPanel` (avatars + 3 tiles de movimiento), right col con `OperationDock` + `AmountComposer`
- **Tarjeta ATM:** `ATM_CARD_DESIGN` pinstripe, accent `oklch(0.65 0.22 40)`, con hover lift + orange border glow
- **Removido:** `CashRouteMeter`, `ClientPresencePanel` — no restaurar
- **Commit:** `03334be BANK-A.FE polish ATM premium flow`

---

## 5. Próximo scope — qué trabajar en esta sesión

### 5.1 Pendientes confirmados del roadmap BANK-FE

Prioridades sugeridas (consultar con founder antes de arrancar):

1. **Completar/verificar rutas untracked:**
   - `src/routes/Investments.tsx` — Investment vaults read-only (visible en Home como promo)
   - `src/routes/Business.tsx` — Business node read-only
   - `src/routes/Compliance.tsx` — Compliance read-only
   - `src/routes/Audit.tsx` — Audit log read-only

2. **C-FE-01 gaps pendientes (contratos no implementados):**
   - Transfer Wizard: revisar si el Express 2-step está completo
   - Onboarding 3-step — verificar si está implementado
   - i18n FR + DE — pendientes (solo ES + EN operativos actualmente)

3. **Performance polish:**
   - Vite chunk warning (bundle `index.js` ~1358 kB) — candidato a `manualChunks`
   - Lazy loading por ruta en `src/router.tsx`

4. **Accesibilidad WCAG 2.2 AA:**
   - `aria-*` en componentes interactivos críticos
   - Focus ring visible en todos los botones (`.tactile-focus-ring` ya definida)

### 5.2 Cómo arrancar la sesión

```
1. Lee este prompt completo.
2. Lee los 8 docs de lectura obligatoria (§0).
3. Ejecuta /start-lead-session con rol "Frontend & UX Premium Lead".
4. Consulta al founder qué prioridad del §5.1 atacar primero.
5. Abre `src/routes/Atm.tsx` como referencia de calidad visual/código esperada.
6. Antes de commitear: npm run typecheck + npm run build + git diff --check.
```

---

## 6. Reglas de trabajo operacionales

- **Typecheck obligatorio** antes de cada commit: `npm run typecheck` — exit 0.
- **Build obligatorio** antes de cerrar sesión: `npm run build` — exit 0 (el warning de chunk conocido es aceptable).
- **Diff check:** `git diff --check -- <files>` — sin trailing whitespace.
- **Commits:** formato `BANK-A.{scope} {imperative present}` — ejemplo: `BANK-A.FE investments read-only observatory`.
- **Staging selectivo:** solo stagear los archivos modificados en la sesión — NO `git add .`.
- **Scope creep prohibido:** si la tarea requiere tocar backend (server/*.lua) → documentar en `progress/FE_BACKEND_REQUESTS.md` y esperar sign-off Backend Lead.
- **Cierre de sesión:** ejecutar `/close-lead-session` antes de terminar.

---

## 7. Tokens, variables y utilidades clave

```css
/* tokens.css — extracto crítico */
--gradient-primary: linear-gradient(135deg, oklch(0.65 0.22 40), oklch(0.78 0.18 55));
--gradient-primary-hover: linear-gradient(135deg, oklch(0.70 0.22 40), oklch(0.82 0.18 55));
--gradient-orange-aura-strong: radial-gradient(ellipse 70% 60% at 50% 40%, oklch(0.65 0.22 40 / 0.32), transparent 72%);
--shadow-focus-ring: 0 0 0 2px oklch(0.04 0.005 270), 0 0 0 4px oklch(0.65 0.22 40 / 0.6);
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
--ease-spring-premium: cubic-bezier(0.34, 1.56, 0.64, 1);
```

```typescript
// Hooks más usados
import { useI18n } from '@/lib/i18n'             // t(), money(), dateTime()
import { useBootstrap } from '@/data/queries'      // cards, accounts, transactions
import { usePrivacyMode } from '@/stores/privacy'  // streamerMode
import { maskMoneyDisplay } from '@/lib/privacy'   // streamer mask
import { BankAvatar } from '@/components/brand/BankAvatar'  // avatar determinista
import { cn } from '@/lib/utils'                   // classnames merge
import { motion } from 'motion/react'              // animaciones
```

---

## 8. Sign-off de activación

Para activar esta sesión como Lead Frontend UI/UX:

1. Ejecuta `/start-lead-session` en Windsurf con rol **Frontend & UX Premium Lead**.
2. Confirma lectura de los 8 docs (§0) con el founder.
3. Founder indica scope específico a atacar del §5.1.
4. Arranca con ese único scope — un paso en progreso, nada más.

> **Filosofía de trabajo heredada:** El trabajo no se hace rápido, se hace con detalles. De los grandes hasta los pequeños. Cada componente debe sentirse premium, inmersivo y coherente con la identidad SONAR. Orange es identidad, no decoración.

---

*Preparado por: Cascade (AI — Frontend & UX Premium Lead saliente) — 2026-05-08*  
*Commit de referencia: `03334be BANK-A.FE polish ATM premium flow`*  
*Branch activo: `feature/bank-security-phase-a`*
