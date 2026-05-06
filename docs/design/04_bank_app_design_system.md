# C-FE-02 — Design System + Tactile UI Doctrine SONAR Bank Phase A v0.1 DRAFT

> **Owner:** Frontend & UX Premium Lead.
> **Status:** 🟡 v0.1 DRAFT BANK-FE.0 2026-05-06.
> **Path canonical:** `docs/design/04_bank_app_design_system.md` v0.1.
> **Artefacto canonical:** `resources/sonar_bank_app/web-src/design-tokens.json` v0.1.
> **Sibling:** C-FE-01 + C-FE-03.
> **ADR anchors:** ADR-016 ✅ inherited + ADR-017 🟡 proposed.

---

## 1. Filosofía + scope

### 1.1 Mandate

Este contrato define el **sistema de diseño canonical** Bank app — paleta extendida ADR-017 + Tactile UI primitives multi-layer shadow ladder + motion 12 presets + typography scale + iconography + SFX mapping + spacing/radius/z-index ladders. Es el **input directo** para implementar `web-src/src/components/ui/*` + `web-src/src/styles/tokens.css` + `web-src/tailwind.config.ts`.

### 1.2 Principles

- **D1 — Tactile UI inquebrantable.** Multi-layer box-shadow ladder ADR-017 D2. NO flat.
- **D2 — oklch() mandatory.** Tailwind v4 native. Wide-gamut P3. Chromium 111+ (CEF FiveM compatible).
- **D3 — Motion accessible.** 12 presets + reduced-motion fallback + spring physics motion v12.
- **D4 — Typography variable fonts.** Inter Variable + JetBrains Mono Variable (ADR-016 D2 inherited).
- **D5 — SFX disciplined.** 5 Tablet canonical + 2 Bank-specific NEW. Reduced trigger (no overlap >5 simultaneous).
- **D6 — Iconography Lucide.** Subset 48 canonical + stroke 1.5px default.
- **D7 — Tokens single source.** `design-tokens.json` → Tailwind v4 `@theme` + CSS custom properties → consumed components.

---

## 2. Paleta extendida (ADR-017 D1 — implementation reference)

### 2.1 Surface ladder dark (12 tiers)

| Tier | Token CSS | oklch() | Use |
|---|---|---|---|
| 0 | `--surface-abyss` | `oklch(0.04 0.005 270)` | App canvas root |
| 1 | `--surface-void` | `oklch(0.06 0.008 270)` | Sidebar nav |
| 2 | `--surface-card` | `oklch(0.10 0.010 270)` | Card baseline |
| 3 | `--surface-card-elevated` | `oklch(0.13 0.012 270)` | Card hover/selected |
| 4 | `--surface-card-glass` | `oklch(0.10 0.010 270 / 0.40)` | Glass cards |
| 5 | `--surface-modal-scrim` | `oklch(0.04 0.005 270 / 0.72)` | Modal overlay |
| 6 | `--surface-modal` | `oklch(0.13 0.012 270)` | Modal content |
| 7 | `--surface-input` | `oklch(0.08 0.008 270)` | Input baseline |
| 8 | `--surface-input-focus` | `oklch(0.13 0.014 270)` | Input focused |
| 9 | `--surface-tooltip` | `oklch(0.18 0.014 270)` | Tooltip + popover |
| 10 | `--surface-toast` | `oklch(0.13 0.012 270)` | Toast |
| 11 | `--surface-glow` | `oklch(0.65 0.22 40 / 0.06)` | Radial diffuse backdrop |

### 2.2 Brand tokens

- `--brand-signal-orange` = `oklch(0.65 0.22 40)` (ADR-016 D1 inherited)
- `--brand-signal-orange-light` = `oklch(0.78 0.18 55)` (gradient secondary)
- `--brand-signal-orange-glow` = `oklch(0.65 0.22 40 / 0.18)` (card halo)
- `--brand-signal-orange-subtle` = `oklch(0.65 0.22 40 / 0.06)` (subtle wash)

### 2.3 Semantic deep tokens (financial state)

| Token | oklch() | Use |
|---|---|---|
| `--semantic-success-deep` | `oklch(0.65 0.18 155)` | Saldo positivo + success |
| `--semantic-success-glow` | `oklch(0.65 0.18 155 / 0.18)` | Card halo |
| `--semantic-warning-deep` | `oklch(0.78 0.16 85)` | Compliance low/medium + tax warnings |
| `--semantic-warning-glow` | `oklch(0.78 0.16 85 / 0.16)` | Surface glow |
| `--semantic-danger-deep` | `oklch(0.62 0.21 25)` | Compliance HIGH/CRITICAL + insufficient_funds |
| `--semantic-danger-glow` | `oklch(0.62 0.21 25 / 0.18)` | Halo |
| `--semantic-info-deep` | `oklch(0.70 0.14 230)` | Info/recurring hints |
| `--semantic-info-glow` | `oklch(0.70 0.14 230 / 0.14)` | Glow |

### 2.4 Text scale (4 tiers — derived ADR-016)

| Token | oklch() | Use | Contrast Card |
|---|---|---|---|
| `--text-primary` | `oklch(0.98 0.005 270)` | Headings + balance hero | 15.8:1 AAA |
| `--text-secondary` | `oklch(0.98 0.005 270 / 0.72)` | Body + labels | 11.3:1 AAA |
| `--text-tertiary` | `oklch(0.98 0.005 270 / 0.48)` | Captions + ts | 7.2:1 AAA |
| `--text-quaternary` | `oklch(0.98 0.005 270 / 0.24)` | Disabled + dividers | n/a (decorative) |

### 2.5 Border tokens

- `--border-subtle` = `oklch(0.98 0.005 270 / 0.06)` (hairline divider)
- `--border-medium` = `oklch(0.98 0.005 270 / 0.12)` (card border)
- `--border-strong` = `oklch(0.98 0.005 270 / 0.24)` (active/focused)
- `--border-brand-subtle` = `oklch(0.65 0.22 40 / 0.16)` (brand hairline)
- `--border-brand-strong` = `oklch(0.65 0.22 40 / 0.48)` (brand active)

### 2.6 Status badge tokens (CP8 bridges)

- `--status-native_full` = `--semantic-success-deep` (success)
- `--status-lite_mode_active` = `--semantic-warning-deep` (warning)
- `--status-compromised` = `--semantic-danger-deep` (danger)
- `--status-framework_missing` = `oklch(0.40 0.02 270)` (neutral grey-dark — BANK_DISABLED)

---

## 3. Tactile UI primitives canonical (ADR-017 D2-D4)

### 3.1 Multi-layer box-shadow ladder

```css
/* Tier baseline tactile-card */
.tactile-card {
  box-shadow:
    inset 0 1px 0 oklch(1 0 0 / 0.08),       /* Top edge highlight (light from above) */
    inset 0 -1px 0 oklch(0 0 0 / 0.6),       /* Bottom edge shadow (depth) */
    0 8px 24px -8px oklch(0 0 0 / 0.5),      /* Outer ambient soft */
    0 24px 64px -16px oklch(0.65 0.22 40 / 0.12); /* Brand glow halo */
}

/* Tier elevated (hover + selected) */
.tactile-card-elevated {
  box-shadow:
    inset 0 1px 0 oklch(1 0 0 / 0.12),
    inset 0 -1px 0 oklch(0 0 0 / 0.7),
    0 12px 32px -8px oklch(0 0 0 / 0.6),
    0 32px 80px -16px oklch(0.65 0.22 40 / 0.18);
}

/* Tier button-primary (CTA) */
.tactile-button-primary {
  background: var(--gradient-primary);
  box-shadow:
    inset 0 1px 0 oklch(1 0 0 / 0.32),       /* Top bevel highlight strong */
    inset 0 -1px 0 oklch(0 0 0 / 0.32),      /* Bottom bevel shadow */
    0 4px 12px -2px oklch(0.65 0.22 40 / 0.40),  /* Outer brand glow */
    0 8px 24px -4px oklch(0 0 0 / 0.32);     /* Ambient depth */
}

.tactile-button-primary:active {
  /* Pressed-in feel — invert bevels */
  box-shadow:
    inset 0 1px 0 oklch(0 0 0 / 0.24),
    inset 0 -1px 0 oklch(1 0 0 / 0.10),
    inset 0 4px 8px -2px oklch(0 0 0 / 0.24),
    0 2px 6px -1px oklch(0.65 0.22 40 / 0.32);
  transform: translateY(1px);
}

/* Tier glass-card (Hero overview + Floating panels) */
.tactile-glass-card {
  background: oklch(0.10 0.010 270 / 0.40);
  backdrop-filter: blur(24px) saturate(180%);
  border: 1px solid transparent;
  background-clip: padding-box;
  box-shadow:
    inset 0 1px 0 oklch(1 0 0 / 0.12),
    inset 0 0 0 1px oklch(1 0 0 / 0.04),
    0 24px 48px -16px oklch(0 0 0 / 0.6),
    0 48px 96px -32px oklch(0.65 0.22 40 / 0.10);
  position: relative;
}

.tactile-glass-card::before {
  /* Edge highlight via mask composite */
  content: '';
  position: absolute;
  inset: 0;
  padding: 1px;
  border-radius: inherit;
  background: linear-gradient(135deg,
    oklch(1 0 0 / 0.12),
    oklch(1 0 0 / 0.02),
    oklch(1 0 0 / 0.08));
  -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  pointer-events: none;
}
```

### 3.2 Radial diffuse light sources

```css
/* Vista hero light backdrop */
.vista-hero-light {
  position: relative;
}

.vista-hero-light::before {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(
    ellipse 80% 60% at 50% -10%,
    oklch(0.65 0.22 40 / 0.18),
    transparent 70%
  );
  filter: blur(40px);
  pointer-events: none;
  z-index: -1;
}

/* Card hero radial top-glow */
.card-hero-glow::before {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(
    ellipse 60% 80% at 50% 0%,
    oklch(0.65 0.22 40 / 0.18),
    transparent 70%
  );
  pointer-events: none;
  border-radius: inherit;
}
```

### 3.3 Premium glassmorphism spec

- `background: oklch(0.10 0.010 270 / 0.40)` (smoked dark base ~40% opacity).
- `backdrop-filter: blur(24px) saturate(180%)` (intense blur + super-saturated for vivid glass on Chromium 111+).
- Edge highlight ultra-thin via `::before` mask composite (gradient border 1px).
- Text: `color: oklch(0.98 0.005 270)` 100% opacity always (legibility WCAG AA).
- Fallback `prefers-reduced-transparency`: replace with `--surface-card` opaque.

### 3.4 Inner gradient lift (subtle card depth)

```css
.card-inner-lift {
  background:
    linear-gradient(180deg,
      oklch(1 0 0 / 0.04) 0%,
      transparent 30%,
      transparent 70%,
      oklch(0 0 0 / 0.12) 100%),
    var(--surface-card);
}
```

---

## 4. Motion presets (12 canonical — D3 implementation)

### 4.1 Library + tokens

- **Library:** `motion` v12.x (`motion/react` import path).
- **Springs canonical:**
  - `soft` — `{ stiffness: 180, damping: 24, mass: 1 }` — hover + tab switch.
  - `snappy` — `{ stiffness: 380, damping: 30, mass: 1 }` — modal open + dropdown + page enter.
  - `premium` — `{ stiffness: 220, damping: 18, mass: 0.9, restSpeed: 0.5 }` — hero reveal + balance count-up.
  - `tactile` — `{ stiffness: 600, damping: 25, mass: 0.6 }` — button press + tap response.
- **Easings canonical:**
  - `out_quart` — `cubic-bezier(0.25, 1, 0.5, 1)` — exits + dismissals.
  - `out_expo` — `cubic-bezier(0.16, 1, 0.3, 1)` — entrances + reveals.
  - `in_out_smooth` — `cubic-bezier(0.65, 0, 0.35, 1)` — tab switch + tooltip.
  - `spring_premium` — `cubic-bezier(0.34, 1.56, 0.64, 1)` — confirm ripple + bounce-back.
- **Durations:** instant (0ms reduced) / fast (120ms) / base (200ms) / moderate (320ms) / slow (480ms) / deliberate (640ms).

### 4.2 12 presets canonical

| # | Preset name | Use case | Spec |
|---|---|---|---|
| 1 | **page-enter** | Vista mount entrance | `initial:{opacity:0,y:12}` `animate:{opacity:1,y:0}` `transition:{duration:0.48,ease:out_expo}` |
| 2 | **page-exit** | Vista unmount | `exit:{opacity:0,y:-8}` `transition:{duration:0.32,ease:out_quart}` |
| 3 | **tab-switch** | Tab content swap | `initial:{opacity:0,x:8}` `animate:{opacity:1,x:0}` `transition:{spring:soft}` |
| 4 | **modal-open** | Modal scale-fade in | `initial:{opacity:0,scale:0.96}` `animate:{opacity:1,scale:1}` `transition:{spring:snappy}` |
| 5 | **modal-close** | Modal scale-fade out | `exit:{opacity:0,scale:0.96}` `transition:{duration:0.2,ease:out_quart}` |
| 6 | **toast-enter** | Toast slide+fade from bottom-right | `initial:{opacity:0,x:32,y:0}` `animate:{opacity:1,x:0,y:0}` `transition:{spring:snappy}` |
| 7 | **toast-exit** | Toast dismiss | `exit:{opacity:0,x:32}` `transition:{duration:0.2}` |
| 8 | **confirm-ripple** | Button confirm CTA tap success | `animate:{scale:[1,1.04,1]}` `transition:{duration:0.4,ease:spring_premium}` |
| 9 | **hover-lift** | Card hover elevate | CSS `transition: box-shadow 200ms in_out_smooth, transform 200ms in_out_smooth` + `hover:translateY(-1px)` |
| 10 | **tap-press** | Button tactile press | `whileTap:{scale:0.98}` + CSS bevel inversion `:active` |
| 11 | **skeleton-shimmer** | Loading skeletons | CSS `@keyframes shimmer` background-position 200% 1.6s linear infinite |
| 12 | **wizard-step-slide** | Transfer Wizard step transition | `initial:{opacity:0,x:24}` `animate:{opacity:1,x:0}` `exit:{opacity:0,x:-24}` `transition:{duration:0.32,ease:out_expo,spring:premium}` |

### 4.3 Reduced motion fallback

Cada preset implementa fallback `{ duration: 0 }` automático via wrapper:

```typescript
import { motion, useReducedMotion } from 'motion/react'

export function MotionPreset({ preset, children, ...props }) {
  const reduced = useReducedMotion()
  const config = reduced ? { ...preset, transition: { duration: 0 } } : preset
  return <motion.div {...config} {...props}>{children}</motion.div>
}
```

### 4.4 GPU-only properties (ADR-016 D6 inherited principle)

- ALWAYS animate `transform` + `opacity`. NEVER animate `width/height/top/left/margin/padding` (causes layout reflow → jank).
- Exception accepted Phase A Bank: `box-shadow` + `backdrop-filter` GPU compositing on Chromium 111+ (acceptable per ADR-017 D6 budget elimination).

---

## 5. Typography canonical (D4)

### 5.1 Fonts (ADR-016 D2 inherited)

- **Sans:** `'Inter Variable', system-ui, -apple-system, sans-serif` — UI text.
- **Mono:** `'JetBrains Mono Variable', 'SF Mono', Menlo, monospace` — financial data rows + tabular figures.
- **Loading:** `font-display: swap` + WOFF2 preload `<link rel="preload" as="font" type="font/woff2" crossorigin>` for both.

### 5.2 Size scale (10 tiers)

| Token | Value | Use |
|---|---|---|
| `--font-size-xs` | 11px | Captions + audit row metadata |
| `--font-size-sm` | 13px | Secondary text + helper + labels |
| `--font-size-base` | 14px | Body + button text |
| `--font-size-md` | 16px | Subheadings + balance secondary |
| `--font-size-lg` | 18px | Card titles |
| `--font-size-xl` | 22px | Vista section titles |
| `--font-size-2xl` | 28px | Vista hero titles |
| `--font-size-3xl` | 36px | Balance hero amount |
| `--font-size-4xl` | 48px | Onboarding splash |
| `--font-size-5xl` | 64px | Onboarding completion celebration |

### 5.3 Weights (8 tiers via Variable axis)

- thin 100 / extralight 200 / light 300 / regular 400 / medium 500 / semibold 600 / bold 700 / extrabold 800.

### 5.4 Line heights + letter spacing

- Line heights: tight 1.1 / snug 1.25 / normal 1.5 / relaxed 1.625 / loose 1.875.
- Letter spacing: tight -0.02em / normal 0 / wide 0.02em / wider 0.06em / widest 0.12em (eyebrow uppercase metadata).

### 5.5 Tabular figures (financial rows)

JetBrains Mono Variable `font-feature-settings: 'tnum' 1` mandatory en `<TransactionRow>` amount columns + `<DataTable>` numeric columns for grid alignment.

---

## 6. SFX mapping canonical (D5)

### 6.1 Library shared

- Tablet S2 canonical: `@resources/sonar_tablet/web-src/src/lib/sfx.ts` — 5 sine-class SFX reused 1:1 in Bank app.
- Bank-specific: 2 NEW sketched in this contract Phase A (implementation post-LOCK).

### 6.2 SFX catalog

| ID | SFX | Class reference | Spec | Use case |
|---|---|---|---|---|
| **S-01** | `console_tap` | Apple UIKeyClick | sine 1400Hz, 55ms, attack 5ms decay 50ms | Generic taps (button click, list row, tab open) |
| **S-02** | `layer_dive` | Apple page-flip | 1000→660Hz glide, 90ms, exp decay | Vista switch + wizard step + tab |
| **S-03** | `depth_press` | Tesla confirm | 1200+600Hz dual sine, 120ms, attack 8ms | Primary CTA confirm + transfer success |
| **S-04** | `signal_emerge` | Apple Mail-send | 880+1320Hz double-chirp, 160ms | Bank app mount + onboarding step complete |
| **S-05** | `panel_open` | Apple Notification reveal | 600→900Hz swell, 360ms | Modal open + popover reveal |
| **S-06 NEW** | `coin_clink` | Bank-specific Phase A | Two-tone sine 2000+2400Hz, 75ms, sharp attack 2ms decay 70ms exponential | Transfer confirm finalize moment |
| **S-07 NEW** | `vault_close` | Bank-specific Phase A | Descending sine 800→400Hz, 200ms, with low sub 200Hz subharmonic, fade-out 50ms | Transaction settle + audit ledger commit visual |

### 6.3 Implementation pattern (mirrors Tablet sfx.ts)

```typescript
// resources/sonar_bank_app/web-src/src/lib/sfx.ts
const ctx = new AudioContext()

function playSine(opts: { freq: number; duration: number; volume?: number; attackMs?: number; decayMs?: number }) {
  const osc = ctx.createOscillator()
  const gain = ctx.createGain()
  osc.type = 'sine'
  osc.frequency.value = opts.freq
  osc.connect(gain).connect(ctx.destination)
  const now = ctx.currentTime
  gain.gain.setValueAtTime(0, now)
  gain.gain.linearRampToValueAtTime(opts.volume ?? 0.12, now + (opts.attackMs ?? 5) / 1000)
  gain.gain.exponentialRampToValueAtTime(0.0001, now + opts.duration / 1000)
  osc.start(now)
  osc.stop(now + opts.duration / 1000)
}

export const sfx = {
  console_tap: () => playSine({ freq: 1400, duration: 55 }),
  layer_dive: () => { /* glide implementation */ },
  depth_press: () => { /* dual sine */ },
  signal_emerge: () => { /* double-chirp */ },
  panel_open: () => { /* swell */ },
  coin_clink: () => { /* NEW two-tone */ },
  vault_close: () => { /* NEW descending + sub */ },
}
```

### 6.4 Concurrency cap

- Max 5 simultaneous SFX triggers — beyond cap, drop new ones (avoid cacophony Payroll batch with 50 employees).
- Mute toggle persisted Zustand `useSettings.sfxMuted` + `localStorage`.
- `prefers-reduced-motion` → SFX volume reduced 50% (not muted entirely — informational beep retained).

---

## 7. Iconography canonical (D6)

### 7.1 Library + spec

- **Library:** `lucide-react` (latest). Match Tablet S2 inheritance.
- **Default size:** 16px.
- **Default stroke:** 1.5px.
- **Default color:** `currentColor` (inherits text color).

### 7.2 Canonical subset 48 icons

```
Wallet, ArrowRightLeft, ArrowLeft, ArrowRight, ArrowUpRight, ArrowDownLeft,
History, Receipt, FileText, Download, Upload,
Building2, Briefcase, Users, User, UserCheck,
Landmark, Crown, Scale, Gavel, ShieldAlert,
TrendingUp, TrendingDown, BarChart3, PieChart, LineChart,
Calendar, Clock, RefreshCw, Filter, Search,
AlertTriangle, AlertCircle, Info, CheckCircle2, XCircle,
Lock, Unlock, KeyRound, Eye, EyeOff,
Settings, MoreHorizontal, ChevronDown, ChevronRight,
Plus, Minus, X, Check
```

48 icons cover ALL surfaces Phase A. Adding requires Frontend Lead amendment (avoid scope creep).

### 7.3 Icon sizing scale

| Token | Size | Use |
|---|---|---|
| `--icon-xs` | 12px | Inline metadata + badge prefixes |
| `--icon-sm` | 14px | Button leading/trailing icons |
| `--icon-md` | 16px | Default — IconButton + nav |
| `--icon-lg` | 20px | Card actions + filter chips |
| `--icon-xl` | 24px | Vista section icons |
| `--icon-2xl` | 32px | Empty states + onboarding step icons |

---

## 8. Spacing + radius + z-index ladders

### 8.1 Spacing (8px-base + 4px micro)

`0 / 0.5 (2px) / 1 (4px) / 1.5 (6px) / 2 (8px) / 3 (12px) / 4 (16px) / 5 (20px) / 6 (24px) / 8 (32px) / 10 (40px) / 12 (48px) / 16 (64px) / 20 (80px) / 24 (96px) / 32 (128px)`.

### 8.2 Radius

`none 0 / xs 4 / sm 6 / md 8 / lg 12 / xl 16 / 2xl 20 / 3xl 24 / full 9999`.

**Per component canonical:**
- `<Button>` → `lg` (12px).
- `<IconButton>` → `md` (8px) or `full` for circular variant.
- `<Card>` → `xl` (16px).
- `<Card hero>` → `2xl` (20px).
- `<Modal>` → `2xl` (20px).
- `<Input>` → `md` (8px).
- `<Badge>` → `full` (pill).
- `<Toast>` → `lg` (12px).

### 8.3 Z-index ladder

`base 0 / raised 10 / sticky 20 / sidebar 30 / header 40 / dropdown 50 / tooltip 60 / popover 70 / modal-scrim 80 / modal 90 / toast 100 / splash 110`.

---

## 9. Tailwind v4 config (oklch native + @theme)

### 9.1 Config sketch

```typescript
// resources/sonar_bank_app/web-src/tailwind.config.ts
import type { Config } from 'tailwindcss'

export default {
  content: ['./src/**/*.{ts,tsx}', './index.html'],
  theme: {
    // CSS-first via @theme in tokens.css — minimal JS config
  },
  plugins: [],
} satisfies Config
```

### 9.2 tokens.css `@theme` (Tailwind v4 CSS-first)

```css
/* resources/sonar_bank_app/web-src/src/styles/tokens.css */
@import 'tailwindcss';

@theme {
  /* Colors — surface ladder */
  --color-surface-abyss: oklch(0.04 0.005 270);
  --color-surface-void: oklch(0.06 0.008 270);
  --color-surface-card: oklch(0.10 0.010 270);
  --color-surface-card-elevated: oklch(0.13 0.012 270);
  /* ... 12 surface tiers + brand + semantic + text + border ... */

  /* Spacing scale — Tailwind v4 uses --spacing-* */
  --spacing-0_5: 2px;
  --spacing-1_5: 6px;
  /* base 8px scale via Tailwind defaults */

  /* Radius */
  --radius-xs: 4px;
  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-2xl: 20px;
  --radius-3xl: 24px;

  /* Typography */
  --font-sans: 'Inter Variable', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono Variable', 'SF Mono', monospace;

  --font-size-xs: 11px;
  --font-size-sm: 13px;
  --font-size-base: 14px;
  /* ... 10 sizes ... */

  /* Shadows tactile */
  --shadow-tactile-card:
    inset 0 1px 0 oklch(1 0 0 / 0.08),
    inset 0 -1px 0 oklch(0 0 0 / 0.6),
    0 8px 24px -8px oklch(0 0 0 / 0.5),
    0 24px 64px -16px oklch(0.65 0.22 40 / 0.12);

  --shadow-tactile-card-elevated: /* ... */;
  --shadow-tactile-button-primary: /* ... */;
  --shadow-tactile-glass: /* ... */;
  --shadow-modal: 0 32px 64px -16px oklch(0 0 0 / 0.7), 0 64px 128px -32px oklch(0 0 0 / 0.5);
  --shadow-tooltip: 0 4px 12px -2px oklch(0 0 0 / 0.5), 0 8px 24px -4px oklch(0 0 0 / 0.3);
  --shadow-toast: 0 8px 24px -4px oklch(0 0 0 / 0.6), 0 16px 48px -8px oklch(0.65 0.22 40 / 0.16);

  /* Gradients */
  --gradient-primary: linear-gradient(135deg, oklch(0.65 0.22 40), oklch(0.78 0.18 55));
  --gradient-primary-glow: radial-gradient(ellipse 60% 80% at 50% 0%, oklch(0.65 0.22 40 / 0.18), transparent 70%);
  --gradient-orange-shimmer: linear-gradient(135deg, oklch(0.65 0.22 40), oklch(0.85 0.15 65), oklch(0.65 0.22 40));
  --gradient-glass-edge: linear-gradient(135deg, oklch(1 0 0 / 0.12), oklch(1 0 0 / 0.02), oklch(1 0 0 / 0.08));

  /* Transitions */
  --ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1);
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-in-out-smooth: cubic-bezier(0.65, 0, 0.35, 1);
  --ease-spring-premium: cubic-bezier(0.34, 1.56, 0.64, 1);
}

/* Global resets */
:root {
  color-scheme: dark only;
  background: var(--color-surface-abyss);
  color: var(--text-primary);
}

body {
  font-family: var(--font-sans);
  font-size: var(--font-size-base);
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Tactile primitives */
.tactile-card { box-shadow: var(--shadow-tactile-card); }
.tactile-card-elevated { box-shadow: var(--shadow-tactile-card-elevated); }
.tactile-button-primary {
  background: var(--gradient-primary);
  box-shadow: var(--shadow-tactile-button-primary);
  transition: box-shadow 120ms var(--ease-spring-premium), transform 120ms var(--ease-spring-premium);
}
.tactile-button-primary:active { /* invert bevels — see §3.1 */ }
.tactile-glass-card {
  background: var(--color-surface-card-glass);
  backdrop-filter: blur(24px) saturate(180%);
  box-shadow: var(--shadow-tactile-glass);
  position: relative;
}
.tactile-glass-card::before { /* mask composite edge — see §3.1 */ }

/* Reduced motion */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

/* Reduced transparency fallback */
@media (prefers-reduced-transparency: reduce) {
  .tactile-glass-card {
    backdrop-filter: none;
    background: var(--color-surface-card);
  }
}
```

### 9.3 Build pipeline

- Vite 6 Rolldown stable (5x cold start vs Vite 5).
- Tailwind v4 PostCSS plugin (auto-loaded).
- TypeScript 5.7+ + Vite plugin React 19 SWC.
- Compress: brotli + gzip (DevOps H4 future).

---

## 10. Component implementation patterns

### 10.1 `<Button>` example canonical

```tsx
// resources/sonar_bank_app/web-src/src/components/ui/Button.tsx
import { motion } from 'motion/react'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
  disabled?: boolean
  icon?: React.ReactNode
  children?: React.ReactNode
  onClick?: () => void
  type?: 'button' | 'submit'
  'aria-label'?: string
}

export function Button({ variant = 'primary', size = 'md', loading, disabled, icon, children, onClick, type = 'button', ...rest }: ButtonProps) {
  const handleClick = () => {
    if (loading || disabled) return
    if (variant === 'primary') sfx.depth_press()
    else sfx.console_tap()
    onClick?.()
  }

  return (
    <motion.button
      type={type}
      onClick={handleClick}
      disabled={disabled || loading}
      whileTap={!disabled && !loading ? { scale: 0.98 } : undefined}
      aria-busy={loading}
      aria-disabled={disabled}
      className={cn(
        'inline-flex items-center justify-center gap-2 font-medium rounded-lg transition-all',
        // Variant
        variant === 'primary' && 'tactile-button-primary text-text-primary',
        variant === 'secondary' && 'tactile-card border border-border-medium hover:border-border-strong text-text-primary',
        variant === 'ghost' && 'hover:bg-surface-card text-text-secondary hover:text-text-primary',
        variant === 'danger' && 'bg-semantic-danger-deep text-text-primary',
        // Size
        size === 'sm' && 'h-8 px-3 text-sm',
        size === 'md' && 'h-10 px-4 text-base',
        size === 'lg' && 'h-12 px-6 text-md',
        // Disabled
        (disabled || loading) && 'opacity-60 pointer-events-none',
      )}
      {...rest}
    >
      {loading && <Spinner size="sm" />}
      {!loading && icon}
      {children}
    </motion.button>
  )
}
```

### 10.2 `<BalanceCard>` example

```tsx
// composite C-01 sketch
import { motion, useSpring, useTransform } from 'motion/react'
import { Card } from '@/components/ui/Card'
import { Spinner } from '@/components/ui/Spinner'
import { useFormatCurrency } from '@/hooks/useFormatCurrency'

interface BalanceCardProps {
  accountType: 'main' | 'savings' | 'business'
  balance: number
  delta?: number
  currency?: string
  lastUpdate?: number
  loading?: boolean
}

export function BalanceCard({ accountType, balance, delta, currency = 'EUR', lastUpdate, loading }: BalanceCardProps) {
  const formatted = useFormatCurrency(balance, currency)
  // Count-up spring
  const motionValue = useSpring(0, { stiffness: 220, damping: 18, mass: 0.9 })
  useEffect(() => { motionValue.set(balance) }, [balance])

  return (
    <Card variant="glass" hero className="card-hero-glow vista-hero-light p-6 relative overflow-hidden">
      <div className="text-xs uppercase tracking-widest text-text-tertiary mb-2">
        {accountType === 'main' ? 'CUENTA PRINCIPAL' : accountType === 'savings' ? 'AHORROS' : 'TESORERÍA EMPRESA'}
      </div>
      <motion.div className="text-3xl font-mono font-semibold tabular-nums text-text-primary">
        {loading ? <Spinner size="md" /> : formatted}
      </motion.div>
      {delta != null && (
        <div className={cn('mt-2 text-sm', delta > 0 ? 'text-semantic-success-deep' : 'text-semantic-danger-deep')}>
          {delta > 0 ? '+' : ''}{delta.toFixed(2)} %
        </div>
      )}
      {lastUpdate && (
        <div className="mt-4 text-xs text-text-tertiary">
          Actualizado {formatRelative(lastUpdate)}
        </div>
      )}
    </Card>
  )
}
```

---

## 11. Dev page `/dev/components` (Q15 LOCKED — minimal Vite route)

### 11.1 Spec

- Path: `/dev/components` gated `import.meta.env.DEV` (tree-shaken in prod build).
- Layout: sidebar (component categories) + main showcase area.
- Categories: Primitives (10) / Composites (12) / Vista shells (10).
- Per component: live preview + props playground (Zustand-backed state) + code snippet + a11y annotations + variants matrix.

### 11.2 Implementation

```tsx
// src/routes/dev/components.tsx
if (!import.meta.env.DEV) {
  // Dev page disabled in prod — redirect to Overview
  return <Navigate to="/" replace />
}

return <DevComponentsGallery />
```

NO Storybook, NO ladle, NO histoire — single Vite route minimal.

---

## 12. Cross-references

- **Artefacto canonical:** `@resources/sonar_bank_app/web-src/design-tokens.json` v0.1.
- **Sibling contracts:** C-FE-01 + C-FE-03.
- **ADRs:** `@docs/planning/02_decision_log_part2.md` ADR-016 ✅ + ADR-017 🟡.
- **SFX Tablet inherited:** `@resources/sonar_tablet/web-src/src/lib/sfx.ts`.
- **Identity SONAR v3:** `@docs/design/IDENTITY.md`.
- **Blueprint visual reference:** `@docs/design/proposals/03_bank_app_blueprint_v1.md` v1.2 §3-§4.
- **Imágenes referencia founder:** `@resources/sonar_bank/simple-ref-bank-ui/*.jpg` — Fintrixity-class.
- **Tailwind v4 docs:** `https://tailwindcss.com/docs/v4-beta`.
- **Motion v12 docs:** `https://motion.dev/docs/react`.
- **React 19 docs:** `https://react.dev`.

---

**FIN C-FE-02 v0.1 DRAFT** — BANK-FE.0 2026-05-06. Sign-off triple target BANK-FE.LOCK.
