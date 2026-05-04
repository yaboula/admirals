# 📚 Admirals — Storybook Guide (NUI Design System Tablet)

> **Versión:** 1.0 (firmado — completo, 14 secciones, 2 partes publicadas).
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.2
> **Documento hermano principal:** `02_sonar_tablet.md` v1.0 (§12 — design system overview), `art/01_art_direction.md` v1.0 (§12 — design system NUI completo).
> **Documentos técnicos referenciados:** `technical/01_architecture.md` v1.0 (§13 NUI técnico), `technical/02_events_catalog.md` v1.0 (eventos `tablet:*`).
> **Estado:** firmado.

> **Lectura previa obligatoria:** Tablet §0-§3 (anatomía Tablet), Art Direction §12 (tokens NUI), Architecture §13 (NUI render target).

---

## 0. Resumen ejecutivo

Este documento es **la referencia canónica del design system NUI de la Admirals Tablet** — el equivalente a un **Storybook** del producto.

Define:

- **Tech stack** del NUI confirmado.
- **Design tokens** consolidados (colors, spacing, typography, motion, radii, shadows).
- **Catálogo de componentes** primitivos + compuestos + domain-specific.
- **Anatomía** de cada componente (props, states, variantes, slots).
- **Composition patterns** (cómo se ensamblan en pantallas reales).
- **Animation conventions** (motion del producto).
- **Accessibility** (a11y) requirements.
- **Storybook setup** + conventions (cómo el equipo NUI documenta y testa).
- **Code conventions** + naming + folder structure.
- **Performance budgets** del NUI.

> **El NUI es la cara más visible del producto** — es lo que el player ve durante el 80% de su tiempo en gameplay (la Tablet siempre encendida en el bolsillo). Esta guía asegura que **cada pantalla del producto se siente Admirals** sin necesidad de ver el logo: paleta + tipografía + motion + iconografía + sound coordinado.

---

## 1. Filosofía + scope

### 1.1 Los 5 principios del NUI Admirals

> **Recapitulación de Tablet §12 + Art Direction §12 con foco operacional.**

#### Principio 1 — Brand-first, generic-never
> El UI de la Tablet **NO es Material 3 con tinte naranja**. Es **Admirals naval** — palette propia, tipografía propia, iconos con stroke brass-aware, motion tokens propios.

#### Principio 2 — Densidad alta sin ruido
> La Tablet es 10" horizontal. **Caben muchos datos sin agobio.** Tipografía clara + jerarquía estricta + spacing generoso pero no desperdiciado.

#### Principio 3 — Document-grade output
> Cada documento (contrato, albarán, recibo, ticket) generado por la Tablet es **profesional-grade** — exportable, imprimible, screenshot-able.

#### Principio 4 — Motion intencional
> No hay motion decorativo. Cada animación **comunica algo** (estado, jerarquía, feedback). Spring físico para interacción, ease para transiciones de estado.

#### Principio 5 — Accesibilidad real
> Contraste WCAG AA mínimo, navegación con keyboard hardcoded a los hotkeys de FiveM, focus rings visibles, screen reader labels (aunque FiveM no exponga screen reader, semantic HTML siempre).

### 1.2 Scope de este documento

**Cubre:**
- ✅ Component catalog completo (primitivos + compuestos + domain-specific).
- ✅ Token system unificado.
- ✅ Composition patterns frecuentes.
- ✅ Storybook conventions.
- ✅ Code conventions.

**NO cubre:**
- ❌ Lógica negocio dentro de componentes (eso es Tablet § por app).
- ❌ Mockups específicos de cada app (eso es Tablet §16-§28).
- ❌ Implementación interna de componentes (eso es código, no doc).

---

## 2. Tech stack confirmed

> **Recapitulación de Architecture §13 + Bible §13.6 — single source of truth.**

| Capa | Tecnología | Versión target oleada 1 |
|---|---|---|
| **Framework** | React | 18.3.x |
| **Language** | TypeScript | 5.5.x (strict mode) |
| **Bundler** | Vite | 5.x |
| **Styling** | Tailwind CSS | 3.4.x (con preset Admirals) |
| **Component primitives** | shadcn/ui (cherry-picked, customized) | latest stable |
| **Animations** | Framer Motion | 11.x |
| **Icons** | Lucide React | latest |
| **State global** | Zustand | 4.5.x |
| **Validation** | Zod | 3.23.x |
| **Forms** | react-hook-form | 7.x (con Zod resolver) |
| **Charts** | Recharts | 2.12.x (selectivo) |
| **Storybook** | @storybook/react-vite | 8.x |
| **Testing** | Vitest + React Testing Library | latest |

> **Decisiones críticas:**
> - **NO Material UI** — too generic, hard to brand.
> - **NO Bootstrap** — anti-modern.
> - **shadcn/ui customized** — ownership total del code, paste-and-modify approach (no NPM lock-in).
> - **Framer Motion** sobre CSS animations cuando hay físicas/spring/orquestación.

---

## 3. Design tokens

> **Single source of truth** consumido por Tailwind preset + tokens.css. Cualquier cambio aquí se propaga a TODOS los componentes.

### 3.1 Color tokens

#### 3.1.1 Brand core

| Token | Hex | Uso |
|---|---|---|
| `--color-brass-50` | #FBF6EE | Backgrounds tonalidad cálida muy clara |
| `--color-brass-100` | #F4E8D0 | Backgrounds cálida |
| `--color-brass-200` | #E5CFA0 | Borders sutiles |
| `--color-brass-300` | #D4B370 | Accent secundario |
| `--color-brass-500` | #B8893E | **Brass signature Admirals** ⭐ |
| `--color-brass-700` | #8A6225 | Brass profundo (hovers, pressed) |
| `--color-brass-900` | #4A3614 | Brass casi negro (texto premium) |

#### 3.1.2 Neutrals (navy-aware)

| Token | Hex | Uso |
|---|---|---|
| `--color-ink-50` | #F8F9FB | Backgrounds default |
| `--color-ink-100` | #EEF1F5 | Surfaces elevadas |
| `--color-ink-200` | #DDE3EB | Borders |
| `--color-ink-400` | #8A95A4 | Text muted |
| `--color-ink-600` | #4A5567 | Text secondary |
| `--color-ink-800` | #1F2937 | Text body |
| `--color-ink-900` | #0F1827 | **Navy signature Admirals** ⭐ Text primary |
| `--color-ink-950` | #070C16 | Headings premium |

#### 3.1.3 Semantic

| Token | Hex | Uso |
|---|---|---|
| `--color-success` | #1E8449 | OK, confirm, signed |
| `--color-warning` | #B8893E | Brass-aware warning (alineado con brand) |
| `--color-danger` | #B33A3A | Errores, deletes, critical |
| `--color-info` | #2E6FAD | Info notifs, links neutrals |

#### 3.1.4 Per-node accents (signature)

> **Recapitulación de Art Direction §3-§7.** Cada nodo tiene su accent secondary que aparece en headers + iconos del nodo.

| Nodo | Accent token | Hex |
|---|---|---|
| Granja | `--color-farm-green` | #6B9436 (trigo-verde) |
| Molino | `--color-mill-flour` | #E8DDC4 (harina cremoso) |
| Bakery | `--color-bakery-warmcopper` | #C97D3D (cobre cálido horno) |
| Retail | `--color-retail-multilum` | #FFFFFF (blanco luminoso, multi-tinte por sección) |
| Tablet | `--color-tablet-glass` | #1F2937 (navy + glass) |

### 3.2 Spacing tokens (8pt grid)

```
--space-0:    0px
--space-0.5:  2px
--space-1:    4px
--space-1.5:  6px
--space-2:    8px        ⭐ unit base
--space-3:    12px
--space-4:    16px
--space-5:    20px
--space-6:    24px
--space-8:    32px
--space-10:   40px
--space-12:   48px
--space-16:   64px
--space-20:   80px
--space-24:   96px
```

### 3.3 Typography tokens

> **Familias canónicas** (Art Direction §12.4):
> - **`font-display`** — Adelle Sans / Sora (headings, branding).
> - **`font-sans`** — Inter (body, UI default).
> - **`font-mono`** — JetBrains Mono (códigos, IBANs, numéricos técnicos).

#### 3.3.1 Type scale

| Token | Size | Line height | Weight | Uso |
|---|---|---|---|---|
| `text-xs` | 11px | 14px | 500 | Captions, labels micro |
| `text-sm` | 13px | 18px | 400 | Body small, table cells |
| `text-base` | 15px | 22px | 400 | Body default |
| `text-md` | 17px | 24px | 500 | Subheaders |
| `text-lg` | 20px | 28px | 600 | Section headings |
| `text-xl` | 24px | 32px | 600 | Page headings |
| `text-2xl` | 30px | 38px | 700 | Big numbers (KPIs) |
| `text-3xl` | 38px | 46px | 700 | Hero metrics |
| `text-display` | 56px | 64px | 800 | Brand reveals (rare) |

### 3.4 Border radius tokens

```
--radius-none:  0
--radius-sm:    4px
--radius-md:    8px       ⭐ default cards
--radius-lg:    12px      ⭐ surfaces premium
--radius-xl:    16px
--radius-2xl:   24px
--radius-full:  9999px    (pills)
```

### 3.5 Shadow tokens (depth system)

```
--shadow-xs:   0 1px 2px rgba(15, 24, 39, 0.04)
--shadow-sm:   0 2px 4px rgba(15, 24, 39, 0.06)
--shadow-md:   0 4px 8px rgba(15, 24, 39, 0.08)        ⭐ default cards
--shadow-lg:   0 8px 16px rgba(15, 24, 39, 0.10)       ⭐ modals
--shadow-xl:   0 12px 24px rgba(15, 24, 39, 0.12)
--shadow-2xl:  0 24px 48px rgba(15, 24, 39, 0.16)      (rare)
--shadow-brass-glow:  0 0 16px rgba(184, 137, 62, 0.35) ⭐ Admirals signature glow
```

### 3.6 Motion tokens (Framer Motion)

> **Tokens canónicos** consumidos por todos los componentes — NO hard-codear.

```ts
// tokens/motion.ts
export const motion = {
  // Springs (interactive — buttons, drags)
  spring: {
    snappy:   { type: "spring", stiffness: 380, damping: 30 },
    soft:     { type: "spring", stiffness: 220, damping: 25 },
    bouncy:   { type: "spring", stiffness: 280, damping: 18 },
  },
  // Easings (state transitions)
  ease: {
    out:      [0.16, 1, 0.3, 1],   // smooth out
    inOut:    [0.42, 0, 0.58, 1],  // standard
    brass:    [0.22, 1, 0.36, 1],  // ⭐ Admirals signature ease
  },
  // Durations
  duration: {
    instant:  0.08,
    fast:     0.15,
    normal:   0.24,    // ⭐ default
    slow:     0.4,
    epic:     0.8,
  },
};
```

### 3.7 Z-index tokens

```
--z-base:        0
--z-content:     10
--z-overlay:     50
--z-modal:       100
--z-toast:       200
--z-tooltip:     300
--z-notif-pulse: 400  (above all, transient)
```

---

## 4. Component anatomy patterns

> **Pattern recurrente** en TODOS los componentes Admirals.

### 4.1 Anatomy convention

```tsx
<Component
  // 1. Identity props
  id="xxx"
  
  // 2. Variant props (visual)
  variant="primary | secondary | ghost | brass"
  size="sm | md | lg"
  
  // 3. State props
  isLoading={false}
  isDisabled={false}
  isActive={false}
  
  // 4. Slot content
  leadingIcon={<Icon />}
  trailingIcon={<Icon />}
  children="Label"
  
  // 5. Event handlers
  onPress={() => {}}
  onHover={() => {}}
  
  // 6. Style escape hatch
  className="custom-class"
/>
```

**Reglas:**
- ✅ Variant + size siempre present, defaults sensible.
- ✅ States expressados con `is*` boolean prefix.
- ✅ Icons via slot props (leading/trailing), no hardcoded children.
- ✅ Handlers con prefix `on*`.
- ✅ `className` como escape hatch SIEMPRE permitido.

### 4.2 Variant naming canónico

| Variant | Uso |
|---|---|
| `primary` | Acción principal de la pantalla |
| `secondary` | Acción secundaria |
| `ghost` | Acción terciaria, sin background |
| `brass` ⭐ | Acción premium-signature Admirals |
| `danger` | Delete, destroy, irreversible |
| `subtle` | Decorativo, no interactivo |

### 4.3 Size naming canónico

| Size | Height (componentes interactivos) | Uso |
|---|---|---|
| `sm` | 28px | Compact UIs, dense tables |
| `md` ⭐ | 36px | **Default** |
| `lg` | 44px | Primary CTAs, mobile-friendly |

---

## 5. Primitive components

> **Componentes base** — building blocks de TODA pantalla.

### 5.1 `<TabletButton>` ⭐

**Anatomy:**
```tsx
<TabletButton
  variant="primary"      // primary | secondary | ghost | brass | danger
  size="md"              // sm | md | lg
  isLoading={false}
  isDisabled={false}
  leadingIcon={<Plus />}
  trailingIcon={<ChevronRight />}
  onPress={() => {}}
>
  Crear contrato
</TabletButton>
```

**States:** default · hover · active · focus · disabled · loading.

**Storybook stories:** `Default`, `WithIcons`, `Loading`, `Disabled`, `AllVariants`, `AllSizes`.

### 5.2 `<TabletInput>`

**Anatomy:**
```tsx
<TabletInput
  size="md"
  type="text | number | email | password"
  placeholder="Cantidad"
  value={value}
  onChange={setValue}
  leadingIcon={<Search />}
  trailingAction={{ icon: <X />, onPress: clear }}
  errorMessage="Campo obligatorio"
  helpText="Mínimo 5 caracteres"
  isInvalid={false}
  isDisabled={false}
/>
```

**Variantes especiales:**
- `<TabletInputCurrency>` — auto-formatea EUR con símbolo brass.
- `<TabletInputIBAN>` — auto-spacing IBAN, mono font.
- `<TabletInputDate>` — date picker brass.

### 5.3 `<TabletToggle>`

**Anatomy:**
```tsx
<TabletToggle
  isChecked={true}
  onCheckedChange={setChecked}
  size="md"
  label="Aceptar B2B walk-ins"
  helpText="Permite que otros players firmen contratos"
/>
```

**Visual:** brass track when ON, muted when OFF, smooth spring transition.

### 5.4 `<TabletSelect>`

**Anatomy:**
```tsx
<TabletSelect
  size="md"
  options={[
    { value: "wheat", label: "Trigo" },
    { value: "oats", label: "Avena" },
  ]}
  value={selected}
  onChange={setSelected}
  placeholder="Selecciona cultivo"
  isMulti={false}
/>
```

### 5.5 `<TabletCheckbox>` y `<TabletRadio>`

Patrón estándar. Brass tick cuando checked. Focus ring visible.

### 5.6 `<TabletCard>` ⭐

**Anatomy:**
```tsx
<TabletCard
  variant="default | elevated | bordered | brass"
  padding="sm | md | lg"
  isInteractive={false}    // hover effect si true
  onPress={() => {}}
>
  {/* Slot libre — Heading + Body + Actions opcional */}
</TabletCard>
```

**Composición típica:**
```tsx
<TabletCard variant="elevated" padding="md">
  <CardHeader>
    <CardTitle>Pedido #4521</CardTitle>
    <CardSubtitle>Panadería La Almirantazgo</CardSubtitle>
  </CardHeader>
  <CardBody>
    150 baguettes · 80 panes integrales · 250€
  </CardBody>
  <CardActions>
    <TabletButton variant="ghost">Detalles</TabletButton>
    <TabletButton variant="brass">Firmar</TabletButton>
  </CardActions>
</TabletCard>
```

### 5.7 `<TabletModal>`

**Anatomy:**
```tsx
<TabletModal
  isOpen={open}
  onClose={() => setOpen(false)}
  size="sm | md | lg | xl"
  title="Confirmar firma"
  description="Esta acción no se puede deshacer."
  primaryAction={{ label: "Firmar", variant: "brass", onPress: sign }}
  secondaryAction={{ label: "Cancelar", variant: "ghost", onPress: cancel }}
>
  {/* Body slot */}
</TabletModal>
```

**Animation:** spring entry from below + backdrop fade.

### 5.8 `<TabletTabs>`

**Variantes:**
- `tabs-line` — underline brass.
- `tabs-pill` — segmented brass background.
- `tabs-icon-only` — barra lateral.

### 5.9 `<TabletAvatar>`

**Anatomy:**
```tsx
<TabletAvatar
  size="xs | sm | md | lg | xl"
  src={imageUrl}
  fallback="CM"           // initials fallback
  status="online | busy | offline"
/>
```

### 5.10 `<TabletBadge>`

**Variantes:** `success | warning | danger | info | brass | neutral`.

### 5.11 `<TabletDivider>`

Horizontal o vertical. Variantes: `solid | dashed | brass`.

### 5.12 `<TabletSpinner>` y `<TabletProgress>`

- Spinner: brass-tinted, sizes sm/md/lg.
- Progress: linear o radial, con label opcional.

### 5.13 `<TabletTooltip>`

Brass-trim, fade + slide entry, max-width 280px.

---

## 6. Compound components (composiciones recurrentes)

### 6.1 `<DataTable>` ⭐

**Anatomy:**
```tsx
<DataTable
  columns={[
    { key: "id", label: "ID", width: 100 },
    { key: "client", label: "Cliente", sortable: true },
    { key: "total", label: "Total", align: "right", format: "currency" },
    { key: "status", label: "Estado", render: (row) => <TabletBadge>{row.status}</TabletBadge> },
  ]}
  rows={data}
  isLoading={loading}
  isEmpty={data.length === 0}
  emptyState={<EmptyState />}
  selectable={true}
  selectedIds={selected}
  onSelectionChange={setSelected}
  pagination={{ pageSize: 25, pageIndex: 0 }}
  onRowClick={(row) => openDetail(row)}
/>
```

**Features:**
- Sticky header brass-bordered.
- Sort indicators brass icons.
- Row hover subtle brass tint.
- Selection con TabletCheckbox.
- Pagination footer integrado.

### 6.2 `<KpiBlock>` ⭐

**Anatomy:**
```tsx
<KpiBlock
  label="Ventas hoy"
  value="4.250 €"
  trend={{ value: "+12%", direction: "up" }}
  icon={<TrendingUp />}
  variant="default | success | warning | brass"
  helperText="142 transacciones"
/>
```

**Visual:** big number `text-2xl font-display`, brass underline, subtle glow on hover.

**Storybook stories:** `Default`, `WithTrend`, `WithIcon`, `BrassPremium`, `Loading`.

### 6.3 `<ChatBubble>`

**Anatomy:**
```tsx
<ChatBubble
  author={{ name: "Carlos", avatar: "..." }}
  timestamp={1234567890}
  content="Confirmo entrega para mañana 6am"
  isOwn={false}
  isRead={true}
  attachments={[{ type: "document", id: "..." }]}
/>
```

**Visual:**
- `isOwn=true` → brass background, text-right.
- `isOwn=false` → ink-100 background, text-left.
- Read receipts con brass tick (single = sent, double = read).

### 6.4 `<NotificationToast>`

**Anatomy:**
```tsx
<NotificationToast
  title="Pedido firmado"
  description="Panadería La Almirantazgo ha aceptado el contrato"
  icon={<FileCheck />}
  variant="success"
  duration={5000}
  action={{ label: "Ver", onPress: view }}
  onDismiss={() => {}}
/>
```

**Animation:** slide-in from top-right + brass underline shimmer + auto-dismiss.

### 6.5 `<NotificationCenter>`

Lista vertical scrollable de notifs con grouping por dominio + badge de unread count + filter chips.

### 6.6 `<EmptyState>`

**Anatomy:**
```tsx
<EmptyState
  icon={<FileText />}
  title="No hay contratos"
  description="Crea tu primer contrato B2B con un proveedor"
  action={{ label: "Crear contrato", variant: "brass", onPress: create }}
/>
```

**Visual:** icon brass-tinted muted + spacious layout + single CTA.

### 6.7 `<DocumentViewer>`

Visor de documento (contrato/albarán/recibo) con look papel térmico — `mat_admirals_paper_document` shader.

### 6.8 `<AppShell>` y `<AppHeader>`

Layout estándar de cada app dentro de la Tablet:
- Header brass slim (40px).
- Body scrollable.
- Footer opcional con actions principales.

### 6.9 `<SearchBar>`

Search con autocomplete + recent searches + brass underline focus.

### 6.10 `<DateRangePicker>`

Calendario brass-themed para filtrar reports.

### 6.11 `<MapView>`

Componente embebido para mapas (apps Granja parcelas, Logística rutas, Retail tienda 2D).

### 6.12 `<Stepper>`

Wizards multi-step (crear contrato, crear promoción, firmar documento).

### 6.13 `<TimelineList>`

Lista de eventos cronológicos (movimientos bancarios, audit trail).

---

## 7. Domain-specific components

> **Componentes específicos del producto Admirals** — no genéricos. Cada uno encapsula un wow visual del producto.

### 7.1 `<DocumentCard>` ⭐

**Card preview de un documento** (contrato, albarán, recibo, ticket).

```tsx
<DocumentCard
  document={{
    id: "CTR-0042",
    type: "contract_b2b_supply",
    status: "pending_signature | signed | expired",
    parties: ["Panadería A", "Molino B"],
    signedAt: 1234567890,
    qrUri: "...",
  }}
  onClick={openDocument}
/>
```

**Visual:** mini doc preview con paper-aging shader applied + brass stamp si signed + QR badge.

### 7.2 `<LineageTrail>` ⭐⭐ (HERO COMPONENT del producto)

**Visualización del lineage trace del trigo → harina → pan → ticket Retail.**

```tsx
<LineageTrail
  trace={[
    { node: "farm",   actor: "Granja del Río",        date: "2026-04-26", parcel: "P03" },
    { node: "mill",   actor: "Molino San Juan",       date: "2026-04-29", batch: "MIL-..." },
    { node: "bakery", actor: "Panadería La Almir.",   date: "2026-04-30", batch: "BAK-..." },
    { node: "retail", actor: "Supermercado Vespucci", date: "2026-04-30", ticket: "#4521" },
  ]}
  variant="vertical | horizontal | compact"
/>
```

**Visual:** stepper brass con iconos por nodo (granja=plot, molino=mill, bakery=oven, retail=cart) + connecting lines + dates + actor names. **Marketing showcase obligatorio.**

### 7.3 `<ShelfMap>` ⭐ (Retail-specific)

**Vista 2D top-down de la tienda Retail con código de colores stock.**

```tsx
<ShelfMap
  layout={retailLayout}
  shelves={[
    { id: "Z2-1", category: "panadería", fillRatio: 0.15, sku: "baguette" },
    { id: "Z2-2", category: "panadería", fillRatio: 0.65, sku: "pan_blanco" },
    ...
  ]}
  onShelfClick={(shelf) => openShelfDetail(shelf)}
/>
```

**Visual:** plano de la tienda con cada lineal coloreado 🟢🟡🔴 según `fillRatio`. Click → detail panel.

### 7.4 `<PromoBuilder>` (Retail-specific)

Wizard para crear promociones temporales.

```tsx
<PromoBuilder
  onComplete={(promo) => createPromo(promo)}
/>
```

**Steps:** seleccionar SKUs → tipo descuento → duración → cantidad límite → preview → confirmar.

### 7.5 `<QualityTrack>` (Granja-specific)

Visualización de los 5 scores de calidad del cultivo (soil + irrigation + fertilization + pest_control + weather).

```tsx
<QualityTrack scores={{ soil: 85, irrigation: 90, fertilization: 70, pest: 95, weather: 80 }} />
```

**Visual:** radar chart brass-trim + final letter grade (A/B/C/D).

### 7.6 `<FermentationTimer>` (Bakery-specific)

Timer real-time visible para fermentación en proceso (mecánica única Bakery).

```tsx
<FermentationTimer
  startedAt={timestamp}
  targetMinutes={180}
  recipe="sourdough"
/>
```

**Visual:** progress radial brass + tiempo restante + visual de "ventana óptima" highlighted.

### 7.7 `<OvenStatus>` (Bakery-specific)

Estado del horno: temperatura visible + ítems dentro + tiempo estimado.

### 7.8 `<POSTerminal>` (Retail/Bakery specific)

UI del POS dentro de la Tablet del cajero — listado productos cinta + total + botones cobro.

### 7.9 `<ContractWizard>`

Wizard multi-step para crear contrato B2B.

### 7.10 `<BankMovementList>`

Extracto bancario con filters + búsqueda + categorías brass-coded.

### 7.11 `<EmployeeRoster>`

Tabla turnos + asignación drag-and-drop semanal.

### 7.12 `<MarketListingCard>`

Card de oferta en Mercado Admirals — preview + acciones + reputation seller.

### 7.13 `<ReputationBadge>`

Badge brass con score reputation + breakdown tooltip.

---

## 8. App shell patterns — composición de pantallas

> **Patterns canónicos** que toda app de la Tablet debe seguir.

### 8.1 Layout base de la Tablet

```
┌─────────────────────────────────────────────────────────┐
│  [SystemBar]  09:42  ⚓ Admirals  🔋 87%  📶  🔔 3      │  ← 24px brass slim
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [App actual — full canvas]                             │
│                                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
│  [HomeBar]    🏠 Home   🔍 Spotlight   📂 Apps          │  ← 32px brass slim
└─────────────────────────────────────────────────────────┘
```

- **SystemBar fija** — hora, notif badge, battery (cosmetic), wifi.
- **HomeBar fija** — Home + Spotlight (search global) + App switcher.
- **App canvas central** — full-bleed, scroll vertical si necesario.

### 8.2 Patrón "App estándar" (ej. Banca, Empresa)

```tsx
<AppShell appId="banca">
  <AppHeader
    title="Banca"
    subtitle="Cuenta empresa: Panadería La Almirantazgo"
    leadingAction={{ icon: <ArrowLeft />, onPress: goBack }}
    trailingActions={[
      { icon: <Settings />, onPress: openSettings },
      { icon: <Search />, onPress: openSearch },
    ]}
  />
  <AppBody>
    <KpiRow>
      <KpiBlock label="Saldo" value="12.450 €" />
      <KpiBlock label="Movimientos hoy" value="8" />
      <KpiBlock label="Pendiente" value="3" />
    </KpiRow>
    <Section title="Movimientos recientes">
      <BankMovementList movements={data} />
    </Section>
  </AppBody>
  <AppFooter optional>
    <TabletButton variant="brass">Hacer transferencia</TabletButton>
  </AppFooter>
</AppShell>
```

### 8.3 Patrón "Manager Panel" (Granja, Molino, Bakery, Retail)

```tsx
<AppShell appId="manager">
  <AppHeader title="Manager Panel — Bakery" />
  <ManagerPanelLayout>
    <ManagerPanelSidebar>
      <SidebarItem icon={<Home />} label="Dashboard" />
      <SidebarItem icon={<Package />} label="Recetas" />
      <SidebarItem icon={<Users />} label="Empleados" />
      <SidebarItem icon={<TrendingUp />} label="Ventas" />
      <SidebarItem icon={<FileText />} label="Contratos" />
      <SidebarItem icon={<Box />} label="Inventario" />
    </ManagerPanelSidebar>
    <ManagerPanelContent>
      {/* Vista activa según item seleccionado */}
    </ManagerPanelContent>
  </ManagerPanelLayout>
</AppShell>
```

### 8.4 Patrón "Document detail"

```tsx
<AppShell>
  <AppHeader title="Contrato B2B-0042" />
  <DocumentViewer
    document={contract}
    actions={[
      { label: "Firmar", variant: "brass", onPress: sign },
      { label: "Rechazar", variant: "danger", onPress: reject },
    ]}
  />
</AppShell>
```

### 8.5 Patrón "Wizard / multi-step"

```tsx
<AppShell>
  <Stepper currentStep={2} totalSteps={5} steps={["Tipo", "SKUs", "Duración", "Preview", "Firma"]} />
  <AppBody>
    {/* Contenido del step actual */}
  </AppBody>
  <WizardActions>
    <TabletButton variant="ghost" onPress={prev}>Atrás</TabletButton>
    <TabletButton variant="brass" onPress={next}>Siguiente</TabletButton>
  </WizardActions>
</AppShell>
```

### 8.6 Patrón "List + Detail" (split view)

```tsx
<AppShell>
  <SplitView>
    <SplitView.List width={320}>
      <SearchBar />
      <DocumentList items={docs} onSelect={setSelected} />
    </SplitView.List>
    <SplitView.Detail>
      {selected ? <DocumentViewer document={selected} /> : <EmptyState />}
    </SplitView.Detail>
  </SplitView>
</AppShell>
```

### 8.7 Patrón "Dashboard" (vista resumen)

Grid de KpiBlocks + 1-2 charts + lista actividad reciente. Ejemplo: app Empresa overview.

---

## 9. Animations + motion

> **Recapitulación de Art Direction §11 + tokens §3.6 con composition patterns.**

### 9.1 Reglas de oro motion

1. **Toda transición respeta el motion token** — NO hard-code durations.
2. **Spring para interacción**, ease para state transitions.
3. **Stagger** para listas (50-80ms entre items, máx 8 items animated).
4. **No motion en elementos críticos** (notif modals, errors — instantáneos).
5. **`prefers-reduced-motion`** respetado — fallback a duration `instant`.

### 9.2 Animation primitives canónicos

#### 9.2.1 Page transitions

```tsx
const pageVariants = {
  initial: { opacity: 0, y: 8 },
  animate: { opacity: 1, y: 0, transition: motion.ease.brass },
  exit:    { opacity: 0, y: -8 },
};
```

#### 9.2.2 Modal entry

```tsx
const modalVariants = {
  initial: { opacity: 0, scale: 0.96, y: 20 },
  animate: { opacity: 1, scale: 1, y: 0, transition: motion.spring.snappy },
  exit:    { opacity: 0, scale: 0.96, y: 20 },
};
```

#### 9.2.3 Toast slide-in

```tsx
const toastVariants = {
  initial: { opacity: 0, x: 100 },
  animate: { opacity: 1, x: 0, transition: motion.spring.bouncy },
  exit:    { opacity: 0, x: 100 },
};
```

#### 9.2.4 List stagger

```tsx
const listContainer = {
  animate: { transition: { staggerChildren: 0.06 } },
};
const listItem = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0 },
};
```

### 9.3 Brass-signature animations ⭐

> **Animaciones únicas Admirals** — usadas con cautela en momentos premium.

| Animation | Uso |
|---|---|
| **`brass-shimmer`** | Skeleton loading + post-success success |
| **`brass-stamp`** | Documento firmado (zoom + opacity de sello rojo) |
| **`brass-glow-pulse`** | Notif crítica + dock charging |
| **`brass-page-reveal`** | Brand splash + onboarding |

### 9.4 Performance rules motion

- ✅ Animar `transform` + `opacity` ONLY (GPU accelerated).
- ✅ `will-change` solo durante anim activa, remover post-anim.
- ❌ **NO animar** width/height/padding (layout thrash).
- ❌ **NO animar** box-shadow (paint heavy) — usar pseudo-element con opacity.
- ❌ **NO** más de 8 items animated simultáneamente.

---

## 10. Accessibility (a11y)

> **WCAG 2.1 Level AA mínimo.** Aunque FiveM no expone screen reader, semantic HTML + keyboard nav + contraste son obligatorios para UX inclusivo.

### 10.1 Contraste

- **Body text:** ratio 4.5:1 mínimo sobre background.
- **Large text (18pt+):** ratio 3:1 mínimo.
- **UI components:** ratio 3:1 (borders, focus rings).
- **Brass on white:** verified — ratio 4.6:1 ✅.
- **Ink-900 on Ink-50:** verified — ratio 16.2:1 ✅.

### 10.2 Keyboard navigation

- ✅ **Tab order** lógico en cada pantalla.
- ✅ **Focus rings** visibles (brass outline 2px).
- ✅ **Escape** cierra modals/dropdowns.
- ✅ **Enter/Space** activa botones.
- ✅ **Arrows** navegan listas y selects.

### 10.3 Semantic HTML

- ✅ `<button>` para acciones, NUNCA `<div onClick>`.
- ✅ `<nav>` para navegación.
- ✅ `<main>` para contenido principal.
- ✅ `<form>` con `<label>` asociadas.
- ✅ `aria-*` cuando semantic no aplica (custom components).

### 10.4 Reduced motion

```tsx
const reducedMotion = useReducedMotion();
const transition = reducedMotion ? motion.duration.instant : motion.spring.snappy;
```

### 10.5 Color blindness

- ✅ **Nunca color-only** state communication. Usar icon + color + texto.
- ✅ **Stock states** (🟢🟡🔴) refuerzan con shape diff (filled/empty/cross).

---

## 11. Storybook conventions

> **Cada componente Admirals tiene Storybook stories obligatorias.**

### 11.1 Folder structure

```
src/
├── components/
│   ├── primitives/
│   │   ├── TabletButton/
│   │   │   ├── TabletButton.tsx
│   │   │   ├── TabletButton.stories.tsx    ⭐
│   │   │   ├── TabletButton.test.tsx
│   │   │   └── index.ts
│   │   └── ...
│   ├── compound/
│   │   ├── DataTable/
│   │   ├── KpiBlock/
│   │   └── ...
│   └── domain/
│       ├── DocumentCard/
│       ├── LineageTrail/
│       └── ...
├── tokens/
│   ├── colors.ts
│   ├── motion.ts
│   ├── typography.ts
│   └── ...
└── stories/
    └── docs/                       ← MDX docs por categoría
```

### 11.2 Stories obligatorias por componente

> **Cada componente expone MÍNIMO 5 stories:**

1. **`Default`** — render estado base.
2. **`AllVariants`** — todas las variants visualizadas en grid.
3. **`AllSizes`** — todas las sizes visualizadas en grid.
4. **`AllStates`** — default + hover + active + focus + disabled + loading.
5. **`Composition`** — uso real en context (ej. botón dentro de card dentro de modal).

### 11.3 Story format

```tsx
// TabletButton.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { TabletButton } from './TabletButton';

const meta: Meta<typeof TabletButton> = {
  title: 'Primitives/TabletButton',
  component: TabletButton,
  tags: ['autodocs'],
  argTypes: {
    variant: { control: 'select', options: ['primary', 'secondary', 'ghost', 'brass', 'danger'] },
    size: { control: 'select', options: ['sm', 'md', 'lg'] },
  },
};
export default meta;

type Story = StoryObj<typeof TabletButton>;

export const Default: Story = {
  args: { children: 'Crear contrato', variant: 'primary' },
};

export const AllVariants: Story = {
  render: () => (
    <div className="flex flex-wrap gap-3">
      {(['primary', 'secondary', 'ghost', 'brass', 'danger'] as const).map(v => (
        <TabletButton key={v} variant={v}>{v}</TabletButton>
      ))}
    </div>
  ),
};
// ...
```

### 11.4 MDX docs

Cada categoría (Primitives, Compound, Domain) tiene un MDX overview en `stories/docs/` con:
- Filosofía de la categoría.
- Cuando usar qué componente.
- Anti-patterns documentados.

### 11.5 Visual regression testing

> **Chromatic** integrado en CI:
- Cada PR captura screenshots de TODAS las stories.
- Diff visual vs main → review obligatorio si cambia.
- Approval workflow para cambios intencionales.

---

## 12. Code conventions

### 12.1 File naming

- **Components:** `PascalCase.tsx` — `TabletButton.tsx`.
- **Hooks:** `useCamelCase.ts` — `useTabletState.ts`.
- **Utils:** `camelCase.ts` — `formatCurrency.ts`.
- **Types:** colocados en mismo file que component, exportados via `index.ts`.

### 12.2 Imports order

```tsx
// 1. React + libs externos
import { useState } from 'react';
import { motion } from 'framer-motion';

// 2. Imports absolutos del project (paths relativos a src/)
import { tokens } from '@/tokens';
import { useAdmiralsStore } from '@/stores/useAdmiralsStore';

// 3. Imports relativos
import { TabletButton } from '../TabletButton';

// 4. Types
import type { ComponentProps } from 'react';

// 5. Styles (raros — Tailwind primary)
import styles from './Component.module.css';
```

### 12.3 Component template

```tsx
'use client'; // si aplica
import { motion } from 'framer-motion';
import { tokens } from '@/tokens';
import type { ReactNode } from 'react';

export interface ComponentProps {
  /** Descripción JSDoc obligatoria de cada prop pública */
  variant?: 'primary' | 'secondary';
  size?: 'sm' | 'md' | 'lg';
  children: ReactNode;
  className?: string;
  onPress?: () => void;
}

const variantClasses = {
  primary: 'bg-brass-500 text-white',
  secondary: 'bg-ink-100 text-ink-900',
} as const;

const sizeClasses = {
  sm: 'h-7 px-2 text-xs',
  md: 'h-9 px-3 text-sm',
  lg: 'h-11 px-4 text-md',
} as const;

export function Component({
  variant = 'primary',
  size = 'md',
  children,
  className,
  onPress,
}: ComponentProps) {
  return (
    <motion.button
      type="button"
      whileTap={{ scale: 0.97 }}
      transition={tokens.motion.spring.snappy}
      onClick={onPress}
      className={cn(
        'rounded-md font-medium transition-colors',
        variantClasses[variant],
        sizeClasses[size],
        className,
      )}
    >
      {children}
    </motion.button>
  );
}
```

### 12.4 TypeScript rules

- ✅ **Strict mode obligatorio** (`strict: true` + `noImplicitAny`).
- ✅ **No `any`** — usar `unknown` + narrow.
- ✅ **Discriminated unions** para variants.
- ✅ **`as const`** para enums-like objects.
- ❌ **NO** `// @ts-ignore` sin comentario explicando.

### 12.5 State management rules

- **Local state:** `useState` para state efímero.
- **Form state:** `react-hook-form` + Zod resolver.
- **Server state:** `Zustand store` con slices por dominio.
- **NUI ↔ Game state:** mensajes vía `fetch('https://admirals/<event>')` + listener `onmessage`.

### 12.6 Testing convention

```tsx
// TabletButton.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { TabletButton } from './TabletButton';

describe('TabletButton', () => {
  it('renders with label', () => {
    render(<TabletButton>Firmar</TabletButton>);
    expect(screen.getByRole('button', { name: 'Firmar' })).toBeInTheDocument();
  });

  it('calls onPress when clicked', async () => {
    const onPress = vi.fn();
    render(<TabletButton onPress={onPress}>Firmar</TabletButton>);
    await userEvent.click(screen.getByRole('button'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('disables interaction when isDisabled', async () => {
    const onPress = vi.fn();
    render(<TabletButton isDisabled onPress={onPress}>Firmar</TabletButton>);
    await userEvent.click(screen.getByRole('button'));
    expect(onPress).not.toHaveBeenCalled();
  });
});
```

**Coverage targets:**
- Primitivos: ≥90%.
- Compound: ≥70%.
- Domain-specific: ≥50%.

---

## 13. Performance budgets

### 13.1 Bundle size

> **Target oleada 1:**

| Métrica | Target |
|---|---|
| **Initial JS** (gzipped) | <300 KB |
| **Initial CSS** (gzipped) | <40 KB |
| **Time to Interactive** (Tablet boot) | <2s en hardware mid-tier |
| **First Contentful Paint** | <800ms |

### 13.2 Render performance

- **Cada app render** target: <16ms (60fps).
- **DataTable** con 1000 rows: virtual scroll obligatorio.
- **Long lists** (>50 items): virtualization vía `@tanstack/react-virtual`.

### 13.3 Optimization rules

- ✅ **React.memo** en componentes en listas (DocumentCard, ChatBubble).
- ✅ **useMemo** + **useCallback** en handlers que pasan a children memoizados.
- ✅ **Lazy load** apps con `React.lazy` + `Suspense`.
- ✅ **Code split** por app (cada app es un chunk).
- ❌ **NO** inline styles dinámicos pesados (preferir CSS custom props).
- ❌ **NO** re-render del shell por cambio en app interno (Zustand selectors granulares).

### 13.4 NUI ↔ Game communication budget

- **Max 30 messages/sec** del client Lua → NUI (rate-limit en client side).
- **Batching** de updates relacionados (ej. inventory diff full state, no item-by-item).
- **Debouncing** de input search (300ms).

---

## 14. Roadmap del documento + estado

### 14.1 Roadmap

#### Oleada 1 (T-0 — incluido)
- ✅ Tech stack confirmado.
- ✅ ~30 componentes catalogados (primitivos + compound + domain).
- ✅ Token system completo.
- ✅ App shell patterns establecidos.
- ✅ Storybook conventions + visual regression CI.
- ✅ Code conventions + testing setup.
- ✅ Performance budgets.

#### Oleada 2 (T+6 meses)
- 🔜 +10 componentes domain-specific (verticals nuevas).
- 🔜 Theme switcher (light → dark mode opcional).
- 🔜 Componentes Hipermercado-specific.
- 🔜 Voice command components (oleada 2 + features).

#### Oleada 3+ (T+12 meses)
- 🔜 SDK NUI público para third-party developers.
- 🔜 Marketplace de apps Tablet (developers contribuyen).
- 🔜 Theming system server-customizable.

### 14.2 Estado del documento

- **Versión:** 1.0 (firmado — completo, 14 secciones, 2 partes publicadas).
- **Próxima revisión:** evolución cuando se añadan componentes de oleada 2 (verticales nuevas + theme switcher).
- **Documentos hijos pendientes:** ninguno — terminal-leaf del subsistema NUI.
- **Documentos relacionados:**
  - `02_sonar_tablet.md` v1.0 — anatomía Tablet + apps detalladas.
  - `art/01_art_direction.md` v1.0 — design tokens visual.
  - `art/02_shader_contracts.md` v1.0 — shaders del device físico Tablet.
  - `art/03_sound_bible.md` v1.0 — UI sounds + notif chimes.
  - `technical/01_architecture.md` v1.0 — NUI técnico (render target, IPC).

### 14.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 (parte 1) | 2026-05-01 | Founder + Cascade | §0-§7 (filosofía, tech stack, tokens, primitivos, compound, domain components). |
| 1.0 (parte 2) | 2026-05-01 | Founder + Cascade | §8-§14 (app shell, animations, a11y, storybook, code conventions, performance, roadmap). **Documento completo, firmable.** |

---

## Resumen ejecutivo del documento (cierre)

El **Storybook Guide** consolida la promesa Pilar 5 (THE TABLET) en design system formal:

- **~30 componentes catalogados** distribuidos en 3 capas (primitivos / compound / domain-specific).
- **Token system unificado** — colors brass-aware + 8pt grid + type scale + motion + radii + shadows.
- **App shell patterns** canónicos (estándar / manager / wizard / split / dashboard).
- **Domain-specific components** que son hero del producto: `<LineageTrail>` ⭐, `<DocumentCard>`, `<ShelfMap>`, `<FermentationTimer>`, `<KpiBlock>`.
- **Storybook obligatorio** por componente con 5+ stories + visual regression CI vía Chromatic.
- **Code conventions** estrictas: TypeScript strict, semantic HTML, Zustand granular, react-hook-form + Zod.
- **Performance budget** — <300KB initial JS, <2s TTI, 60fps render, virtualization de listas largas.
- **Accessibility WCAG AA** — contraste verificado, keyboard nav, reduced motion respect.

> **El día que un developer NUI nuevo se incorpore al equipo, abra Storybook, vea cada componente con sus stories funcionales, lea este doc en 90 minutos, y empiece a entregar UI Admirals-grade su mismo primer día — habrá funcionado este Storybook Guide.**

---

*"El NUI es la cara más visible del producto."*

**FIN DEL DOCUMENTO `art/04_storybook_guide.md` v1.0**
