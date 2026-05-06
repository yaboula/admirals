# SONAR Bank App — Frontend (BANK-FE.1)

> **Estado:** capa fundacional R1 emitida — pending founder review + `npm install`.
> **Owner:** Frontend & UX Premium Lead.
> **Branch:** `feature/bank-security-phase-a`.
> **Stack 2026 absolute (ADR-017 D5):** React 19.2 · Vite 6 · TypeScript 5.7 strict · Tailwind v4 (oklch) · Motion v12 · Zustand v5 · React Router v7 · TanStack Query v5 · Lucide · Zod v4.

---

## 1. Estructura

```
web-src/
├── package.json                  # Stack 2026 dep manifest
├── tsconfig.{json,app,node}.json # TS 5.7 strict + bundler resolution
├── vite.config.ts                # outDir → ../web (consumido por fxmanifest ui_page)
├── index.html                    # NUI entry (data-theme=dark)
├── design-tokens.json            # Source-of-truth tokens (ya emitido BANK-FE.0)
└── src/
    ├── main.tsx                  # React 19 createRoot + StrictMode
    ├── App.tsx                   # QueryClientProvider + Outlet
    ├── router.tsx                # createHashRouter (NUI) | createBrowserRouter (dev)
    ├── vite-env.d.ts             # Vite types + GetParentResourceName declaration
    ├── styles/
    │   ├── tokens.css            # @theme Tailwind v4 oklch tokens
    │   ├── tactile.css           # Tactile UI primitives canonical
    │   └── index.css             # Entry: Tailwind + tokens + tactile + resets
    ├── lib/
    │   ├── utils.ts              # cn + formatCurrency + UUID v4 + clamp
    │   ├── env.ts                # mock mode + GetParentResourceName + FE_VERSION
    │   └── sfx.ts                # 7 SFX canonical (Web Audio API sine + concurrency cap)
    ├── stores/                   # 5 Zustand stores canonical
    │   ├── session.ts            # citizenId + ACE perms + memberships + locale
    │   ├── status.ts             # bridges status + bankDisabled
    │   ├── toast.ts              # queue + toast.{success,warning,danger,info}()
    │   ├── onboarding.ts         # 3-step skippable Q9
    │   └── transferWizard.ts     # idempotency-key + 4 steps
    ├── components/
    │   ├── motion/MotionPreset.tsx   # 11 presets + reduced-motion fallback
    │   └── ui/                       # 5 primitives + Spinner stub
    │       ├── Button.tsx
    │       ├── IconButton.tsx
    │       ├── Input.tsx
    │       ├── Card.tsx
    │       ├── Badge.tsx
    │       └── Spinner.tsx
    └── routes/
        ├── Splash.tsx            # Landing + Dev Showcase entry
        ├── NotFound.tsx          # 404 fallback
        └── dev/Showcase.tsx      # P-01..P-05 visual verification (Q15)
```

---

## 2. Comandos

> **DevOps:** estos comandos **aún no se han ejecutado**. Pending founder review post-BANK-FE.1.

```bash
cd resources/sonar_bank_app/web-src

# Instalar Stack 2026
npm install

# Dev server (browser preview en http://127.0.0.1:5173)
npm run dev

# Type-check (sin emitir)
npm run typecheck

# Production build → ../web/ (consumed por fxmanifest ui_page)
npm run build
```

---

## 3. Mandatos arquitectónicos honrados

- **ADR-017 D2/D3/D4 — Tactile UI doctrine:** flat designs prohibidos. Todos los primitives usan multi-layer box-shadow ladder (inset bevel highlight + bottom shadow + brand glow + drop shadow). Glassmorphism premium en `Card variant="glass"`.
- **ADR-016 D3 + ADR-017 D7 — Dark-only:** `color-scheme: dark only` global, no media queries light, all tokens oklch dark-tier.
- **ADR-017 D8 — WCAG 2.2 AA:** focus ring 4px composite (`tactile-focus-ring`), tabular-nums helper, `prefers-reduced-motion` + `prefers-reduced-transparency` fallbacks.
- **Q11 founder — status badge tooltip simple text:** `Badge` 4 status tones (`native_full`, `lite_mode_active`, `compromised`, `framework_missing`).
- **Q9 founder — onboarding 3-step skippable:** `useOnboarding` store con `skipStep()` y `skipAll()`.
- **Q5 founder — Express transfer 2-step:** `useTransferWizard` con `setExpressMode()`.
- **M004 privacy boundary:** stores no exponen balances de empleados ni compliance flags admin (consumo se hará en BANK-FE.2 vía hooks dedicated con filtrado server-side).

---

## 4. Componentes implementados (5 + Spinner)

| ID | Componente | Variants | Sizes | SFX | Status |
|----|------------|----------|-------|-----|--------|
| P-01 | `<Button>` | primary · secondary · ghost · danger | sm · md · lg | depth_press / console_tap | ✅ |
| P-02 | `<IconButton>` | primary · secondary · ghost · danger | xs · sm · md · lg (square \| circle) | console_tap | ✅ |
| P-03 | `<Input>` | bevel inset (default · hover · focus · error · disabled) | sm · md · lg | — | ✅ |
| P-04 | `<Card>` | baseline · elevated · glass (+ hero glow + heroLight + interactive + innerLift) | padding none/sm/md/lg/xl | console_tap (interactive) | ✅ |
| P-05 | `<Badge>` | solid · soft · outline | xs · sm · md (10 tones inc. 4 bridges) | — | ✅ |
| P-10 | `<Spinner>` | brand · neutral · inverse | xs · sm · md · lg | — | ✅ stub |

Cards componentizadas:
`<CardHeader>`, `<CardTitle>`, `<CardEyebrow>`, `<CardDescription>`, `<CardContent>`, `<CardFooter>`.

---

## 5. SFX library (7 SFX canonical — `lib/sfx.ts`)

| ID | Nombre | Origen | Uso |
|----|--------|--------|-----|
| S-01 | `console_tap` | Tablet inherited | tap secundario / IconButton |
| S-02 | `layer_dive` | Tablet inherited | navegación pantalla → pantalla |
| S-03 | `depth_press` | Tablet inherited | botón primario confirm |
| S-04 | `signal_emerge` | Tablet inherited | toast success / state change |
| S-05 | `panel_open` | Tablet inherited | modal/sheet open |
| S-06 | `coin_clink` | **NEW Bank-specific** | transferencia confirmada / depósito |
| S-07 | `vault_close` | **NEW Bank-specific** | savings movement / card lock |

API:
```ts
import { sfx } from '@/lib/sfx'
sfx.depth_press()                       // play
sfx.coin_clink({ volume: 0.18 })        // override volume
sfx.setMuted(true)                      // localStorage persist
sfx.getMuted()                          // boolean
```

Concurrency cap: **5 simultaneous nodes**. Debounce: **30ms**. Reduced-motion → 50% volume.

---

## 6. Stores Zustand canonical (5)

| Hook | Responsabilidad | Privacy boundary |
|------|-----------------|------------------|
| `useBankSession` | citizenId + IBAN masked + ACE perms + memberships + locale | self-only |
| `useBankStatus` | bridges status (CP8) + bankDisabled flag | broadcast OK |
| `useToastQueue` + `toast.*()` | feedback queue 4 tones | n/a |
| `useOnboarding` | 3-step skippable (Q9) | n/a |
| `useTransferWizard` | wizard state + `idempotencyKey` + `correlationId` UUID v4 | self-only |

---

## 7. Pending (BANK-FE.2 next session)

- TanStack Query wrappers para 40+1 callbacks (C-FE-03 §3).
- NetEvent + StateBag subscription managers (C-FE-03 §4 + §5).
- Mock Data Layer 1:1 (C-FE-03 §6) — gated by `VITE_MOCK_MODE=true`.
- `BankError` class + 20 error codes UI mapping (C-FE-03 §8).
- Layout shell (Sidebar + Topbar + StatusBadge + Toast container).
- Vista 1 (Bank Home / Overview) full implementation.
- 27 primitives restantes (Modal, Sheet, Tooltip, Popover, Tabs, Stepper, Select, Combobox, etc.).
- Onboarding Coach 3-step (Q9).
- i18n bootstrap react-i18next + 4 bundles (es/en/fr/de).

---

## 8. Convenciones

- Imports absolutos via alias `@/*` → `src/*` (configurado en `tsconfig.app.json` + `vite.config.ts`).
- Strict TS: `noUnusedLocals`, `noUnusedParameters`, `verbatimModuleSyntax`.
- Tailwind v4 sin `tailwind.config.js` — todos los tokens en `tokens.css` via `@theme`.
- Code style: español en docs, **inglés en code + identifiers + commits** (workspace rule).

---

**Frontend Lead — Standby ON pending founder review.**
