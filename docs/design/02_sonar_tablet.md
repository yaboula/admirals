# 📱 SONAR — Plataforma raíz: La SONAR Tablet

> **Versión:** **1.3** (post-ADR-016 — Tablet UI implementation stack frozen S2-S8 + NUI perf budgets locked + palette tokens canonical Black/Orange/White + dark-only doctrine product).
> **Documento padre:** `00_PRODUCT_BIBLE.md` (post v1.5 bump pendiente Item E).
> **Documento hermano:** `01_node_farm.md` v1.1 (la Granja consume el Manager Panel y varias apps de la SONAR Tablet).
> **Estado:** v1.0 firmada Admirals (archivada ADR-011) + v1.1+v1.2 surgical Pass 1+2 post-pivot SONAR (S1.8) + **v1.3 IDENTITY V3 LOCK NOTICE top-level** (S1.10.5 Item D).

> **Lectura previa obligatoria:** Product Bible §1 + §3 (5 Pilares — la Tablet es Pilar 5), §13.4 (División 3D vs Código), **`docs/planning/02_decision_log.md` ADR-011 (pivot SONAR) + ADR-012 (refinement metáfora abstract) + `02_decision_log_part2.md` v1.0 ADR-016 D1+D2+D3+D4+D5+D6 (identity v3 doctrine — palette + dark-only + 3-color strict + trend stack + stack frozen + perf budgets)**, **`docs/art/01_art_direction.md` v3.0-locked IDENTITY V3 LOCK NOTICE** (palette canonical 3-token + dark-only + trend stack T1/T2/T3), **`@art/branding/logo_v3/`** (logo v3 firmable post ADR-016).

> **SSoT canonical palette:** `@docs/art/branding/01_brief_logo.md` v3 §4.1 (3 tokens canonical Black `#060607` + Orange `#FF5100` + White `#FAFAFA`).
> **SSoT canonical stack:** `@resources/sonar_tablet/web-src/package.json` (downgrade D5 spec post Item A S1.10.5).

---

## 🟢 IDENTITY V3 LOCK NOTICE (per ADR-016, 2026-05-04)

**Este NOTICE es la capa canónica más reciente.** Supersedes NOTICE r1.1 (ADR-011+ADR-012) + redacción v1.0 inline §1-§29 en cualquier conflicto palette/theme/stack/perf. Lectura obligatoria ANTES de implementar Tablet UI Sprint 2.

### Precedencia (top → bottom)

1. **🟢 IDENTITY V3 LOCK NOTICE** (este — post-ADR-016 D1-D6).
2. **🔄 REFINEMENT NOTICE r1.1** (post-ADR-011 + ADR-012 — preservada para naming SONAR/SonarOS/Tienda/cuenta + voz neutral premium-tech + iconografía abstract + sound naming canonical).
3. **§1-§29 inline** redacción v1.0 + Pass 1+2 surgical (functional/architecture/UX flows válidos; palette + stack + perf override por v1.3).

### NEW CANONICAL v1.3 — vigente desde 2026-05-04

#### Palette tokens — 3 colores LOCKED (ADR-016 D1)

> **SSoT:** `@docs/art/branding/01_brief_logo.md` v3 §4.1 + `@docs/art/01_art_direction.md` v3.0-locked.

| Token Tablet UI | Hex | Rol Tablet | Implementación Tailwind v4 |
|---|---|---|---|
| `--sonar-black` | `#060607` | Background canvas (TODA superficie Tablet UI) | `bg-sonar-black` baseline default |
| `--sonar-orange` | `#FF5100` | Brand identity, CTAs primary, focus rings, alerts críticos, signal active states, app-icons primarios | `bg-sonar-orange`, `text-sonar-orange`, `ring-sonar-orange` |
| `--sonar-white` | `#FAFAFA` | Texto primario, iconografía Lucide, surfaces alpha layers high-emphasis | `text-sonar-white`, `border-sonar-white/[opacity]` |

**Implementación obligatoria post Sprint 2:**
- Definir 3 tokens en `tailwind.config.ts` via `@theme` directive (D5 stack).
- CSS custom properties fallback en `globals.css`.
- **NUNCA hardcodear hex** en componentes — siempre via Tailwind utility class o CSS var.

**Tokens DEPRECATED v1.0+v1.1+v1.2 (purgados v1.3 — ignorar refs §1-§29 + NOTICE r1.1):**
- ❌ Tier A canvas: `#03070A` Abyss Black + `#0A1418` Depth Reduced — REPLACED por `--sonar-black` `#060607`.
- ❌ Tier A canvas light: `#F0F4F4` Crew 100 — ELIMINADO (no light canvas product post D2).
- ❌ Tier B identity: `#2DD4BF` Sonar Bright + `#14E5DD` Sonar Pulse — REPLACED por `--sonar-orange` `#FF5100`.
- ❌ Tier C structural: `#175A5F` Coloro deep-teal — ELIMINADO.
- ❌ Crew neutrals tier (#B8C5C5 / #6B7878 / #2A3438) — ELIMINADOS.
- ❌ Signal functional tier (Critical/Warn/OK/Info colored) — ELIMINADOS post D3 3-color strict.
- ❌ Heritage Admirals "azul marino + dorado" — purgado v1.1 (preserved deprecated).

#### Theme — DARK-ONLY DOCTRINE (ADR-016 D2)

- **Tablet UI in-game:** **dark-only**. NO toggle light/dark. NO `prefers-color-scheme: light` honor.
- **NO hybrid theme dark+white surfaces** (DEPRECATED post v1.1 NOTICE r1.1 hybrid 5-tier).
- **100% dark canvas product** + Orange brand siempre + White foreground texto.
- **Excepción única:** `monogram_s_black.svg` Black sobre fondos blancos — print/external NON-product (D-S1.10E-A). NO uso Tablet UI.

#### 3-color strict (ADR-016 D3)

- Tablet apps NO usan green success / red error / yellow warning / blue info colored.
- **Estados via:**
  - **Lucide icons:** `<CheckCircle2/>` success, `<AlertTriangle/>` warning, `<XCircle/>` error, `<Info/>` info.
  - **Typography weight + opacity** (semantic emphasis sin color).
  - **Layout / motion:** Framer Motion shake on error, fade-in success, pulse on alert.
  - **Orange como único accent semántico** (CTAs primary, alerts críticos, signal active).
- **Re-evaluable post-MVP S2** — si UX research reveals friccion semantic genuine → ADR-XXX.

#### Tablet UI implementation stack — FROZEN S2-S8 (ADR-016 D5) ⭐

> **SSoT:** `@resources/sonar_tablet/web-src/package.json` post downgrade S1.10.5 Item A.

Stack inmutable durante Sprint 2-8 (Oleada 1 completa):

| Tier | Dependencia | Versión pin | Razón inclusion |
|---|---|---|---|
| Framework | React | `^18.3.1` | Stable + ecosystem maturity. NO React 19 durante S2. |
| Build | Vite | `^5.4.10` | Fast HMR + plugin ecosystem. NO Vite 6+ hasta post-Oleada 1. |
| Lang | TypeScript | `^5.6.3` | Strict mode + `noUncheckedIndexedAccess: true`. |
| Styling | Tailwind CSS | `^4.0.0` (`@theme`) | Tokens-first paleta D1 + class-based dark-only. |
| Components | shadcn/ui | CLI install per-component | Dark-only variant baseline. |
| Motion | Framer Motion | `^11.11.0` | Microinteractions + spring physics premium-tech. |
| Icons | Lucide React | `^0.460.0` | Iconography universal — NO emoji, NO custom SVG salvo `@art/branding/logo_v3/*`. |
| Charts | Recharts | `^2.13.0` | Data viz Bank app S3+ (NO needed Sprint 2 shell). |
| State | React Context + `useReducer` | (built-in) | Sprint 2 — NO Zustand / Redux salvo gap real S3+. |
| NUI Bridge | lb-phone NUI message API | (resource externo) | Comunicación cliente Lua ↔ NUI per S0 setup. |

**Cambios stack durante S2-S8 → ADR firmable obligatorio.**

**DEPRECATED stack v1.0/v1.1 (purgados v1.3):**
- ❌ Inter Tight como primary font — REPLACED por Geist Sans (per art_direction §4 post-pivot, preserved v1.3).
- ❌ Stack flexible / sin pin — REPLACED por D5 stack frozen pin exact versions.
- ❌ Zustand state management — eliminado (D5 Context + useReducer).

#### NUI performance — HARD CONSTRAINTS (ADR-016 D6) ⭐

Budgets de obligatorio cumplimiento Sprint 2 onwards (60 FPS target cliente FiveM):

| Budget | Límite | Verificación |
|---|---|---|
| Frame budget paint | ≤ 4ms per frame | Chrome DevTools Performance profile (75% reservado al juego) |
| Bundle size JS gzipped initial | ≤ 500KB | `vite build` + analyzer |
| Bundle size CSS gzipped | ≤ 200KB | idem |
| Memory ceiling NUI heap | ≤ 80MB | Chrome DevTools Memory profile |
| Lazy-loading apps | Obligatorio (Bank/Map/Phone via `React.lazy()` + Suspense) | Initial bundle = shell + Home only |
| Animaciones | GPU-only (`transform`, `opacity`) | NO animar `width/height/top/left/margin/padding` |
| Re-render guard listas | `React.memo` + virtualization react-window si >50 items | transactions, contacts, notifs feed |
| Asset budget brand SVGs | ≤ 8KB cada uno | `@art/tools/logo_export/export.mjs` warn threshold |
| Performance baseline | Sprint 2 setup includes Chrome DevTools Performance profile baseline + regression check pre-merge | Cualquier PR Tablet UI |

#### App icons primarios — Lucide React + brand assets (D5 + Logo v3)

- **Iconografía universal:** Lucide React v0.460+ canonical (per D5).
- **App-icons SONAR Tablet:** SVGs custom abstract pendientes Phase 4.5 v2 (post-MVP). Sprint 2 baseline = Lucide icons como bridge ESHA aceptable.
- **Brand assets:** `@art/branding/logo_v3/*` (4 monogramas + wordmark + 2 lockups). Favicon Tablet = `monogram_s.svg` Orange solid sobre Black canvas.

### Cómo navegar este doc post-v1.3

1. **Lee primero IDENTITY V3 LOCK NOTICE (este) + ADR-016.**
2. **Lee NOTICE r1.1** para naming canonical (SONAR/SonarOS/Tienda/cuenta) + voz neutral + iconografía abstract + sound naming (preservado vigente, NO supersedido por v1.3 en esos aspectos).
3. **§1-§29 inline:** funcionalidad/arquitectura/UX flows válidos. **Override v1.3:** palette + theme + stack + perf — gana esta NOTICE.
4. **Si duda interpretación → ADR-016 manda.**

---

## 🔄 REFINEMENT NOTICE r1.1 (post ADR-011 + ADR-012, 2026-05-03)

**Este documento contiene redacción v1.0 escrita pre-pivot SONAR — naming Admirals + paleta heritage azul marino/dorado + iconografía naval-militar + tipografía Inter/Manrope sugerida + boot sound "campana naval" + wallpapers "motivos navales/militares/cinematográficos".** ADR-011 + ADR-012 cambian todo eso. **NOTICE r1.1 establece la interpretación canónica vigente**; en cualquier conflicto entre lo siguiente y el contenido §1-§29 abajo, **gana este NOTICE + ADRs 011+012 + `01_art_direction.md` v2.0-scaffold-r7**.

### NEW CANONICAL — vigente desde 2026-05-03

#### Naming canonical
- **Producto:** SONAR (no Admirals).
- **Tablet:** SONAR Tablet (no Admirals Tablet).
- **Sistema operativo:** SonarOS (no AdmiralsOS).
- **Cuenta cloud:** cuenta SONAR (no cuenta Admirals).
- **Tienda app:** Tienda SONAR (no Tienda Admirals).
- **Logo grabado dorso:** logo SONAR concept A "S-curl open" (ver `art/branding/logo_v2/`).

#### Paleta canónica (DEPRECATED heritage Admirals "azul marino + dorado + blancos sobrios")
Per `01_art_direction.md` v2.0-scaffold-r7 §3.4 (post-ADR-012 hybrid theme):
- **Tier A canvas dark (~30-40%):** `#03070A` Abyss Black + `#0A1418` Depth Reduced (sidebar, hero dark, splash, modal backdrops).
- **Tier A canvas light (~30-40%):** `#F0F4F4` Crew 100 (paneles, cards, content areas, drawer interiors, dashboard workspaces).
- **Tier B identity pop (~10-15%):** `#2DD4BF` Sonar Bright (logo, CTAs primary, active states, focus rings, branding) + `#14E5DD` Sonar Pulse (glow accents).
- **Tier C structural support (~10%):** `#175A5F` Coloro deep-teal (glassmorphism tints, inactive borders, dim instruments).
- **Signal functional (<5%):** Critical/Warn/OK/Info reservados momentos atención.
- **DEPRECATED Admirals heritage:** azul marino profundo + dorado discreto + blancos neutros — purgado.

#### Tipografía canonical (DEPRECATED Inter/Manrope/SF Pro sugerencias)
Per `01_art_direction.md` §4 (post-pivot):
- **Display + UI:** Geist Sans (300/500/600). Fallback `Inter Tight → Inter → system-ui`.
- **Mono / numerics:** Geist Mono.
- **DEPRECATED:** Inter / Manrope / SF Pro como recomendación primary (Inter Tight queda solo como fallback secundario).

#### Voz / copy canonical (DEPRECATED voz "naval / militar / capitán")
Per ADR-012 D3 + `01_art_direction.md` §3.2:
- **Tono:** neutral premium-tech (Vercel/Linear/Stripe/Apple Pro apps class). Preciso, terse, calmo, professional, atemporal.
- **DEPRECATED:** voz "campana al subir a puente naval", "silent service", "almirante", "capitán", "comandante", "tripulación", "a bordo", "tactical-grade", "operación naval".
- **Ejemplos canonical SONAR Tablet copy:** *"Console activated. Ready."* / *"Transferencia recibida: 1,240€"* / *"Manifesto signed."* / *"Hear the depth."*
- **Ejemplos DEPRECATED:** *"Bienvenido a bordo, almirante."* / *"Console SONAR activada. Profundidad operativa."*

#### Iconografía canonical (DEPRECATED iconos navales literales)
Per ADR-012 D1 + `BRIEF-ICONS-001 v2`:
- **Iconografía abstract:** capas profundidad + claridad de señal (NO submarinos / periscopios / sonar-pings radio / hydrophones / torpedos).
- **App icons primarios SONAR Tablet:** `descent-layers` (drill-down), `signal-clarity` (notif), `depth-grid` (dashboard), `observation-field` (map), `lineage-trace` (audit), `bioluminescence` (active state), `pressure-hull` reconceptualizado (privacy/encrypted), `depth-gauge` (status). Preliminares Phase 4.5 v2 — designer pro pendiente per brief §7.
- **DEPRECATED app icon emoji refs §5.1 (🏢 / 📊 / 🏷️ / 🚚 / etc.):** son placeholders v1.0 — replacement con custom abstract icons SONAR cuando entreguen (Lucide React acceptable como bridge S2-S3).

#### Sound naming canonical (DEPRECATED "campana naval" + sounds Admirals heritage)
Per ADR-012 D5 + `BRIEF-SOUND-001 v1` + `01_art_direction.md` §7.2 — 5 SFX firma canonical:
- `signal_emerge` (notificación crítica primaria, 400-800ms premium-tech tonal Apple Mail/Vercel deploy class). DEPRECATED v1 `sonar_ping` literal radio.
- `depth_press` (firma documento, confirmación, 200-400ms Apple Touch ID success class). DEPRECATED v1 `sonar_pressure`.
- `layer_dive` (submit / escritura / drill-down, 150-300ms Notion page transition class). DEPRECATED v1 `sonar_depth`.
- `console_tap` (confirmación premium click, 50-150ms Apple trackpad haptic class). DEPRECATED v1 `sonar_console`.
- `panel_open` (abrir modal/drawer/panel, 200-400ms Apple notification center reveal class). DEPRECATED v1 `sonar_hatch`.
- **Boot sound canonical:** premium-tech tonal class (Mac chime class moderna, neutral) — NO "campana al subir a puente naval" militar literal. ~1.2s con tonal rise + click decay (cero metáfora naval).

#### Logo SONAR canonical (working v2)
Per `art/branding/logo_v2/README.md` + decisión founder S1.7:
- **Concept A "S-curl open"** working canonical adopted 2026-05-03. 3 arcs trazando una S con eco a la derecha.
- **Lectura semántica founder:** los 3 arcs representan **capas de profundidad / trabajar a fondo** (NO ondas sonar radio literal).
- **Status:** WORKING CANONICAL no firmado ADR (deferred ~2-4 semanas uso real). Si hold, formalizar ADR-013.
- **Aplicado en SONAR Tablet:** boot splash logo reveal (§3 §4.2), lock screen logo discreto (§4.3), dorso grabado (§2 §2.4), dock con logo (§21).
- **DEPRECATED en este doc:** "logo Admirals + ondas de señal naval expandiéndose / 3 anillos concéntricos" → reinterpretado como **3 arcs S-curl reveal** del logo concept A (la metáfora "anillos concéntricos" se mantiene visualmente PERO semántica = capas profundidad NO ondas señal).

### Cómo navegar este doc post-pivot

1. **Lee primero esta NOTICE r1.1 + ADRs 011/012 + `01_art_direction.md` v2.0-scaffold-r7 NOTICE r6.**
2. **Funcionalidad/arquitectura/UX flows §1-§29 siguen válidos** — Tablet 5º Pilar + dispositivo físico + 4 estados + 8 apps base + dock despacho + multi-cuenta + permisos. La FUNCIÓN no cambia con el pivot.
3. **Lo que cambia es el "wrapping" identidad/visual/voz/sound:** naming SONAR + paleta hybrid + tipografía Geist + voz neutral + iconografía abstract + sound canonical 5 SFX + logo v2 concept A.
4. **Refs literales pre-pivot SUPERSEDED:** "Admirals" en cualquier forma → SONAR; "azul marino + dorado" → Sonar Bright + Tier A/B/C; "Inter/Manrope" → Geist Sans; "campana naval" → tonal premium-tech; "señal naval" → capas profundidad / signal abstract; "navales/militares/cinematográficos wallpapers" → wallpapers abstract depth/bioluminescence per moodboard `01_brief_marketing.md` v1.
5. **Pass 1 + Pass 2 ejecutados S1.8:** (Pass 1) bulk identity purge + key sections §2.4/§3/§4.1/§4.2/§4.3/§29. (Pass 2) apps detail-pass §5.2 + §6.4/§6.5 + §10.5 + §11.4/§11.6 + §15.2 notif table canonical SFX mapping + §21.4 docking + §22.4 Costa Naval flag + §26 sounds canonical full rewrite (tablas) + §27 anti-patrones NEW post-pivot §27.2. Doc 1/8 Phase 6 **100% Pass done**.
6. **Si duda interpretación → ADR-012 + `01_art_direction.md` v2.0-scaffold-r7 mandan.**

---

## 0. Resumen ejecutivo

La **SONAR Tablet** es la **plataforma raíz de software del ecosistema** y el **único "menú" aceptable de SONAR**.

Es a la vez:

- **Un dispositivo físico** con modelo 3D propio, animaciones de manipulación, sonidos identitarios, variantes de hardware. Cuando un jugador lo saca del bolsillo, todo el mundo lo ve.
- **Un sistema operativo** (SonarOS) con boot, home, notificaciones, ajustes — diseñado como un sistema empresarial, no como un smartphone genérico.
- **Una plataforma de apps modulares** que cada producto SONAR instala. La Granja añade su Manager Panel. El Molino añade su panel de molienda. Los Restaurantes añaden su panel de cocina. Etc.
- **El gancho universal** que conecta jugadores entre sí y con el ecosistema: mensajes, contratos, banca, ofertas de trabajo, comercio.

Sin la Tablet, SONAR sería un conjunto de scripts. **Con la Tablet, SONAR es un ecosistema unificado.**

---

## 1. Filosofía y posicionamiento

### 1.1 Por qué la Tablet es el 5º Pilar

La pregunta original del fundador fue: *"¿Cómo abrimos un menú sin romper el Pilar 1 (todo es físico)?"*

**Respuesta:** no abrimos un menú. Sacamos un dispositivo. El dispositivo es real, es un objeto del mundo, tiene modelo 3D, animación de manipulación, sonidos, peso visual. La pantalla del dispositivo muestra la UI — pero la UI **vive dentro del dispositivo, no flotando sobre el HUD**.

Esto resuelve la tensión filosófica:

- **Pilar 1 respetado:** todo es físico, incluida la interfaz administrativa. La Tablet es un objeto.
- **Pilar 3 respetado:** el detalle obsesivo se vuelca también en la UI — animaciones, transiciones, sonidos, polish AAA.
- **Pilar 4 respetado:** modelo propio, branding propio, OS propio.
- **Pilar 5 nuevo:** la Tablet es el sistema nervioso del ecosistema. Cualquier vertical futura instala apps; ninguna inventa su propio menú.

### 1.2 La Tablet NO es un teléfono

> **Decisión de diseño crítica.** En FiveM hay decenas de scripts de "phone" (lb-phone, qb-phone, gksphone). La Tablet **no compite con ellos**. La Tablet es **complementaria**.

Diferencias intencionadas con un phone genérico:

| Phone genérico FiveM | SONAR Tablet |
|---|---|
| Vida personal del personaje | Vida profesional / empresarial del jugador |
| Twitter / Instagram in-game | Mercado laboral, contratos B2B |
| Llamadas privadas, mensajes ligeros | Comunicación profesional, documentos firmables |
| Apps "redes sociales" | Apps de gestión de empresa, dashboards, analytics |
| Pequeño, vertical, pantalla 6" | Tablet 10" horizontal, pensada para ver datos y tablas |
| 1 app de banca básica | Banca empresarial real con cuentas, contratos, libros |
| 1 app de fotos | Cámara para documentar (uso profesional, no selfies) |

**Convivencia con phones de terceros:** la Tablet es opcional — un servidor puede usar phone genérico para vida social + Tablet SONAR para vida empresarial. **No competimos por el mismo espacio mental del jugador.**

### 1.3 La Tablet NO es un menú

Lo que la Tablet **NO hace**:

- ❌ No abre flotando con un comando `/menu`.
- ❌ No es invisible cuando el jugador la usa (otros jugadores la ven en sus manos).
- ❌ No tiene UI sobre el HUD de GTA. La UI está **dentro de la pantalla del modelo 3D**.
- ❌ No es instantánea. Hay animación de sacarla del bolsillo, encenderla, cerrarla, guardarla.
- ❌ No reemplaza a la acción física. Sembrar sigue siendo físico, pagar nóminas no.

### 1.4 Anti-patrones específicos de la Tablet

> Lo que **JAMÁS** vamos a hacer en este producto.

- ❌ **UI flotante sobre HUD** que no esté contenida en el modelo 3D del dispositivo.
- ❌ **"Phone clone"** con apps de redes sociales, swipe-to-match, etc. Eso es vida personal — no es nuestro espacio.
- ❌ **App que sustituye una acción física** (cosechar desde la Tablet, sembrar desde la Tablet). La Tablet **organiza**, no **ejecuta** trabajo manual.
- ❌ **Apps con UIs cada una a su rollo.** El sistema operativo impone consistencia: tipografía, paleta, controles, transiciones — todos comparten librería de componentes.
- ❌ **Notificaciones genéricas tipo "tienes 1 mensaje".** Cada notificación tiene icono, color, sonido, contexto.
- ❌ **Boot instantáneo.** El boot es parte del wooow — no se salta.
- ❌ **App icons mal pensados.** Cada app tiene un icono propio diseñado, coherente con la paleta y el lenguaje visual SONAR.
- ❌ **No tener identidad de marca en la UI.** El logo SONAR aparece en el boot, en el lock screen, en el dorso de la tablet. La marca está omnipresente sin ser invasiva.
- ❌ **Apps imposibles de quitar.** Aunque las apps de SONAR son las predeterminadas, el jugador puede ocultar/reordenar.

---

## 2. Hardware — el dispositivo físico

### 2.1 Modelo 3D y formato

**Form factor:** tablet horizontal de 10 pulgadas. Estilo industrial-elegante, no consumer-cute. Inspiración: iPad Pro + tablet rugged de empresa.

**Dimensiones aproximadas (in-game):**
- 24cm × 17cm × 0.9cm.
- Peso visual: se siente sólida cuando se manipula (animaciones con cierta inercia).

**Elementos físicos visibles:**
- **Pantalla** (frontal, ocupa ~85% del frente).
- **Marco** delgado con el nombre **SONAR** grabado en la parte inferior (sutil, no llamativo).
- **Cámara frontal** pequeña en el bisel superior (selfie / video-llamadas).
- **Cámara trasera** en esquina superior izquierda (para documentación in-world: fotos de campos, productos).
- **Botón físico de power** en lateral derecho.
- **Botón físico de volumen** (subir/bajar) en lateral derecho.
- **Puerto de carga** en lateral inferior (decorativo, no funcional gameplay).
- **logo SONAR** grabado en el dorso (con acabado especular sutil).
- **Identificador del propietario** opcional — el jugador puede grabar su nombre en el dorso desde Settings (texto plano).

**Materiales por variante (ver §2.2):**
- Básica: aluminio mate.
- Pro: aluminio cepillado + bisel acentuado.
- Enterprise: marco de titanio mate + dorso con patrón sutil tipo carbono.

### 2.2 Variantes (3 tiers)

> **Decisión de diseño:** las variantes son **mismo software**, diferente hardware. La diferenciación es estética + algunas features secundarias. **No bloqueamos apps por tier** — un nuevo jugador con Tablet Básica puede operar una empresa igual que uno con Enterprise. El upgrade es por estatus, no por gating.

| Tier | Coste in-game | Hardware | Beneficios extra |
|---|---|---|---|
| **Básica** | Bajo (o gratis al crear personaje) | Aluminio mate, color gris | Acceso a todas las apps base. 6 wallpapers. 3 ringtones. |
| **Pro** | Medio | Aluminio cepillado, 4 colores (gris, negro, dorado, plata) | + 20 wallpapers premium. + 10 ringtones. + Skin "Premium" para SonarOS. + Animación de boot premium. |
| **Enterprise** | Alto | Titanio + dorso carbono, 2 acabados (negro mate / champagne) | + 50 wallpapers exclusivos. + 25 ringtones. + Skin "Enterprise" (paleta más sobria, tipografía más fina). + **Dock-ready certificado** (anim distinta al docking). + Grabado personalizado del dorso (logo de empresa). + Soporte para **2 cuentas simultáneas** (útil para gerentes de varias empresas). |

**Compra:** desde la **Tienda SONAR** (la propia app, ver §13). NPC vendedor opcional + entrega física (caja con animación de unboxing — wooow).

**Pérdida/robo:** la Tablet puede perderse o ser robada. Si pasa, el jugador puede comprar una nueva en la Tienda y **toda su data se restaura** (cuenta cloud SONAR — ver §16). Los archivos privados (notas, fotos) se restauran si tenía sync activo; si no, se pierden.

### 2.3 Estados físicos de la Tablet

La Tablet tiene **4 estados físicos** distintos que el mundo ve:

| Estado | Descripción | Visual |
|---|---|---|
| **Guardada** | En el bolsillo del personaje | No visible — solo bulto sutil en bolsillo trasero o mochila |
| **En mano (off)** | Sacada pero pantalla apagada | Modelo 3D en mano, pantalla negra con logo apenas visible |
| **En mano (on)** | Pantalla encendida y operativa | Modelo 3D en mano, pantalla con UI activa |
| **En dock / mesa** | Apoyada en superficie o en dock | Modelo 3D estático sobre prop, pantalla puede estar on/off |

**Transiciones:** cada cambio entre estados tiene animación específica (ver §3 y §25).

### 2.4 Identidad visual de la marca

- **logo SONAR** grabado en dorso — siempre visible cuando otro jugador ve la Tablet de espaldas.
- **Splash screen de boot** — logo SONAR concept A "S-curl open" + 3 arcs reveal sequential (capas profundidad). DEPRECATED v1.0: "ondas de señal naval expandiéndose". Ver §3 §4.2 + `art/branding/logo_v2/README.md` + `01_brief_motion.md` v1 §4.5 `logo_descent_reveal`.
- **Wallpapers oficiales** — motivos abstractos profundidad (`depth-grid`, `bioluminescence`, `descent-layers`, `signal-clarity` per `01_brief_marketing.md` v1 moodboard). DEPRECATED v1.0: "navales/militares/cinematográficos".
- **Tipografía** — **Geist Sans** (300/500/600) primary canonical per `01_art_direction.md` §4. Mono/numerics: Geist Mono. Fallback `Inter Tight → Inter → system-ui`. DEPRECATED v1.0 sugerencias Inter/Manrope/SF Pro como primary.
- **Paleta** — hybrid theme post-ADR-012: Tier A canvas (~30-40% Abyss Black `#03070A` + ~30-40% Crew 100 `#F0F4F4`) + Tier B identity pop (~10-15% Sonar Bright `#2DD4BF` + Sonar Pulse `#14E5DD`) + Tier C structural (~10% Coloro `#175A5F`) + signals <5%. SSoT canonical: `01_art_direction.md` v2.0-scaffold-r7 §3.4. DEPRECATED v1.0: "azul marino profundo + dorado discreto + blanco/gris neutros".
- **Sonidos identitarios** — 5 SFX canonical post-ADR-012: `signal_emerge` (notif primary), `depth_press` (firma/confirm), `layer_dive` (submit/drill-down), `console_tap` (click premium), `panel_open` (modal/drawer). Boot sound = tonal premium-tech class (Mac chime moderna neutral). DEPRECATED v1.0: "boot sound naval" + "campana naval". Ver `01_art_direction.md` §7.2 + `01_brief_sound.md` v1.

---

## 3. La animación de saque/guarde — el wooow del primer segundo

> **Esta animación es lo primero que ve un jugador nuevo de SONAR.** Tiene que ser memorable.

### 3.1 Sacar la Tablet

**Trigger:** tecla configurable (default: `K`) o comando `/tablet`.

**Secuencia:**
1. Personaje detiene movimiento principal (no se cancela conducción ni acciones críticas).
2. Mano dominante se mueve hacia bolsillo trasero / interior chaqueta. **Animación 1: alcanzar bolsillo**.
3. Saca la Tablet (visible). **Animación 2: extraer**.
4. Lleva la Tablet a posición de uso (frente al pecho, ligeramente inclinada). **Animación 3: posicionar**.
5. Pulsa botón de power con el pulgar. **Animación 4: encender**.
6. Pantalla pasa de negro a logo SONAR (boot).
7. Boot completo en 1.5-2 segundos.
8. Aparece **lock screen** o, si está desbloqueada, **home**.

**Tiempo total:** ~2.5 segundos. Es lento adrede — comunica **"esto es algo que estás haciendo, no algo que se abre"**.

**Variaciones contextuales:**
- Si está conduciendo: la Tablet se monta automáticamente en un dock del salpicadero (modelos de coche con dock real visible — futuro). Por ahora: la Tablet se saca pero la animación es más rápida y la mano izquierda mantiene volante.
- Si va a pie: secuencia completa.
- Si está sentado en silla del despacho: la Tablet ya está en el dock (no hay sacar — ver §21).
- Si está en un vehículo agrícola: lo mismo, dock del salpicadero (futuro).

### 3.2 Boot sound — el sonido identitario

> **Premium-tech tonal class.** Distintivo, breve, professional. Apple/Vercel/Linear class — cero metáfora militar/naval. DEPRECATED v1.0: "campana al subir a puente naval".

- **Sonido:** ~1.2 segundos. Tonal rise mid-frequency con leve pitch-emerging + acorde sintético sobrio + click discreto al final. Carácter premium-tech neutral (Apple chime moderno class). Ver `01_brief_sound.md` v1 §2.4 boot sequence sound spec.
- **No es alegre.** Es preciso, calmo, professional. Como un Mac chime moderno con identidad propia SONAR — cero connotación naval/militar.
- **No se puede silenciar al 100%** — el volumen mínimo es bajo pero perceptible. Es parte del branding.
- **Variantes Pro / Enterprise:** versiones con más capas armónicas tonales, más "ricas". Mismo motivo premium-tech, calidad de mezcla mayor.

### 3.3 Guardar la Tablet

**Trigger:** misma tecla, o gesto "swipe down + close" en la propia Tablet, o pulsando botón de power.

**Secuencia:**
1. Pantalla muestra animación de "apagado" — la UI hace fade-out a un punto en el centro (como TV antigua), 0.4s.
2. Pantalla apagada (negra con logo apenas tenue).
3. Personaje guarda la Tablet en el bolsillo. **Animación inversa de saque** (1s).

**Tiempo total:** ~1.4 segundos. Más rápido que sacar — porque guardar es menos ceremonia.

### 3.4 Estados intermedios visibles

- **Notificación entrante mientras Tablet guardada:** sutil vibración del personaje (ligero shake del modelo + sonido de vibración amortiguada del bolsillo). El jugador decide sacarla o no.
- **Llamada entrante:** vibración + ringtone audible (proporcional al volumen configurado). Si el jugador no responde en X segundos, va al buzón.
- **Tablet boca abajo en mesa:** las notificaciones se silencian visualmente (la pantalla no se enciende). Sonido sigue. Es un gesto humano: poner el "móvil boca abajo" para concentrarse.

---

## 4. SonarOS — el sistema operativo

### 4.1 Filosofía: tablet empresarial, no smartphone

SonarOS está diseñado como un **sistema operativo de productividad empresarial premium-tech**, no como un sistema social-personal. Voz neutral premium-tech (Vercel/Linear/Stripe/Apple Pro apps class) per `01_art_direction.md` §3.2 — cero arquetipo naval/militar.

- **Layout horizontal por defecto** (la Tablet vive horizontal — formato dashboard).
- **Densidad de información alta** — caben varios paneles a la vez. No es minimalismo decorativo; es información útil empaquetada con jerarquía clara.
- **Colores hybrid theme post-ADR-012** — Tier A canvas (Abyss Black + Crew 100) + Tier B identity (Sonar Bright + Sonar Pulse) + Tier C structural (Coloro) + signals <5%. Cero saturación gratuita. SSoT: `01_art_direction.md` §3.4. DEPRECATED: azul marino + dorado + blancos.
- **Animaciones contenidas** — transiciones suaves 200-300ms (`motion-base`), nunca rebotes ni "spring" llamativos. Per `01_art_direction.md` §16 + `01_brief_motion.md` v1. Easing default `ease-depth-descent` (deprecated v1 `submarine-ease-out`).
- **Sonidos discretos** — clicks tonales premium-tech (`console_tap` 50-150ms canonical), sin chimes alegres ni metáfora naval.

### 4.2 Boot sequence

**Cuando se enciende la Tablet desde apagada:**

| Fase | Duración | Visual | Audio |
|---|---|---|---|
| **0 — Pantalla negra** | 0.2s | Negro absoluto | Silencio |
| **1 — logo SONAR aparece** | 0.4s | Logo SONAR concept A "S-curl open" (`art/branding/logo_v2/`) reveal por capas (3 arcs sequential) en Sonar Bright `#2DD4BF` sobre Abyss Black `#03070A` | Inicio del boot sound (tonal rise) |
| **2 — 3 arcs S-curl reveal completo** | 0.5s | Los 3 arcs del logo concept A se completan + leve glow halation Sonar Bright. **DEPRECATED v1.0: "ondas de señal naval expandiéndose / 3 anillos concéntricos"** — reinterpretado: los 3 arcs son **capas profundidad** (ver NOTICE r1.1 §Logo SONAR canonical), NO ondas radio/sonar literal. Per `01_brief_motion.md` v1 §4.5 `logo_descent_reveal` signature animation | Climax del boot sound |
| **3 — Texto "SonarOS"** debajo del logo | 0.3s | Aparece tipografía Geist Sans 300 thin + versión OS muy pequeña Geist Mono | Decay del sonido |
| **4 — Fade a home/lock** | 0.4s | Cross-fade limpio (`ease-depth-descent`) | `console_tap` discreto al final |

Total boot: ~1.8 segundos. **No skippable** — es parte de la firma.

**Boot rápido** (cuando la Tablet ya estaba en standby, no apagada del todo): solo fase 4. Pasa en 0.4s.

### 4.3 Lock screen

**Cuándo aparece:**
- Tras boot completo (si lock activado en Settings — default off para reducir fricción inicial; admins de servidor pueden forzar lock por config).
- Tras N minutos de inactividad (configurable).

**Layout:**
- **Wallpaper** (configurable, ver §2.4).
- **Hora grande** en la esquina superior izquierda (fuente fina elegante).
- **Fecha** debajo de la hora.
- **logo SONAR** sutil en esquina superior derecha.
- **Indicador de notificaciones** si hay alguna pendiente (badges en los iconos abajo).
- **Indicador de estado** (señal in-world, batería decorativa, modo silencio).
- **Texto inferior**: *"Toca para desbloquear"* o equivalente.

**Desbloqueo:**
- **Modo simple** (default): tap en pantalla → home directo.
- **Modo PIN** (opt-in): el jugador define un PIN de 4-6 dígitos. Aparece teclado numérico al tap. Si falla 3 veces, espera 30s.
- **Modo huella** (futuro RP): swipe sobre lector de huella.
- **Modo facial** (futuro): cámara frontal "escanea" al personaje (animación + verificación instantánea).

### 4.4 Home screen

> **El centro neurálgico de la experiencia.**

**Layout horizontal de pantalla (1280x800 efectivo):**

```
┌─────────────────────────────────────────────────┐
│ [Hora] [Notif badge] [Wifi] [Bat] │ [Buscar...] │  ← status bar
├─────────────────────────────────────────────────┤
│                                                 │
│   [📊] [🌾] [💼] [📨] [🏦] [📋] [🛒] [⚙]      │  ← grid de apps (4 columnas × 2 filas por defecto)
│   Empr  Mngr  Mrkt  Msgs  Banca Notas Tienda Set│
│                                                 │
│   [⊕]   [⊕]   [⊕]   [⊕]                          │  ← slots libres para apps de futuras verticales
│                                                 │
├─────────────────────────────────────────────────┤
│  Widget: tareas pendientes  │  Widget: caja     │  ← widgets opcionales en la fila inferior
└─────────────────────────────────────────────────┘
```

**Elementos clave:**
- **Status bar superior** (40px): hora, notificaciones, indicadores, **buscador global** (tap → busca en apps, contactos, contratos, etc.).
- **Grid de apps** (4 columnas × 2 filas, expandible scrolleando hacia derecha si hay más apps instaladas).
- **Widgets opcionales** en la franja inferior — cada app puede registrar widget (Manager Panel ofrece "tareas pendientes hoy", Banca ofrece "saldo de caja", etc.). Configurables.

**Wallpaper:** detrás de todo. 30-50% de oscurecimiento dinámico para que los iconos contrasten siempre.

**Reordenar apps:** long-press en un icono → modo "shake" sutil → drag-and-drop. Igual que iPad pero más sobrio (shake casi imperceptible).

### 4.5 App switcher (multitarea)

**Trigger:** swipe desde el borde inferior con dos dedos, o gesto "borde + swipe up", o botón Home doble-tap.

**Layout:**
- Vista de **tarjetas grandes** de cada app abierta — preview en vivo de lo que estaba haciendo.
- Tarjetas se pueden swipe-up para cerrarlas.
- Tap en una tarjeta = volver a esa app.

**Wooow:** en el preview se ve la UI viva de la app (tareas asignadas en Manager Panel, último mensaje en Mensajes, etc.). No es un screenshot estático.

### 4.6 Panel de notificaciones (centro de control)

**Trigger:** swipe desde borde superior hacia abajo.

**Layout:**

```
┌─────────────────────────────────────────────────┐
│         [Brillo ─────●──]  [Vol ───●────]       │
│                                                 │
│ [WiFi] [Silencio] [No molestar] [Cámara] [Modo] │  ← toggles
│                                                 │
│ ─── Notificaciones ─────────────────────── Limpiar
│                                                 │
│ 🔴 Plaga detectada — Granja Marcos    hace 2min │
│ 💰 Pago recibido — 1,240$              hace 8min │
│ 📋 Contrato firmado — Molino Pedro    hace 23min │
│ 🌦️ Tormenta entrante — 30 min          hace 45min │
│                                                 │
│ ─── Anteriores ─────────────────────────         │
│ ...                                              │
└─────────────────────────────────────────────────┘
```

**Notificaciones:**
- Cada una tiene **icono + color + sonido distintivo según tipo** (ver Granja §12.4 — el mismo sistema vale para todo el ecosistema).
- Tap en una → abre la app correspondiente en el contexto exacto (ej. tap en plaga → abre Manager Panel directamente en parcela afectada).
- Swipe-left → ocultar.
- Swipe-right → marcar como leída sin abrir.

**Toggles del centro de control:**
- **WiFi** (in-world: activar conexión — afecta a si recibes notificaciones).
- **Silencio** (mute notificaciones).
- **No molestar** (silencio + bloquea pop-ups en pantalla).
- **Cámara** (acceso rápido a la app cámara — ver §13 / oleada futura).
- **Modo trabajo / personal** (futuro — perfila qué notificaciones llegan).

### 4.7 App de Settings (visión previa, detalle en §14)

Acceso a configuración global del dispositivo. Incluye:

- Personalización (wallpaper, ringtones, theme).
- Sonidos (volumen general, ringtones por app, vibración).
- Notificaciones (qué apps notifican, qué tipos).
- Cuenta(s) (gestionar cuenta(s) SONAR — ver §16).
- Privacidad (PIN, qué apps son visibles a otros jugadores que vean tu pantalla).
- Almacenamiento (qué apps ocupan más espacio — uso narrativo / RP).
- Acerca de (versión OS, modelo, número de serie, soporte).
- Apagar / Reiniciar.

### 4.8 Sistema operativo — principios técnicos visibles al jugador

Estos no son detalles internos — son cosas que **el jugador percibe**:

- **Apps siempre disponibles si están instaladas.** No hay "no tengo cobertura". Solo el toggle WiFi cambia la disponibilidad de funciones online (mensajes, mercado).
- **Sincronización cloud SONAR.** Los datos de cuenta (banca, contratos, mensajes, notas) se guardan en cuenta cloud. Cambias de Tablet → todo restaurado (ver §16).
- **Apps modulares.** Cada producto SONAR añade su(s) app(s) sin tocar el OS. Si un servidor instala solo Granja, en la Tablet se ven las apps base + las apps de Granja. Si añade Molino, aparecen las apps de Molino.
- **Updates de apps in-world.** Visualmente: cuando un servidor actualiza un producto, el jugador ve un breve splash *"App Manager Panel actualizada"* la próxima vez que abra la Tablet. Detalle de inmersión.

---

## 5. Catálogo de apps de lanzamiento — visión general

> Las apps siguientes son las **apps base** que cualquier jugador del ecosistema SONAR tiene instaladas desde el momento que adquiere su primera Tablet. Son apps **transversales** — no dependen de un nodo concreto. Los productos SONAR (Granja, Molino, Restaurantes…) **añaden** apps adicionales (como Manager Panel del granjero, panel del molinero, etc.).

### 5.1 Mapa de apps de lanzamiento

| # | App | Icono concept | Propósito |
|---|---|---|---|
| 1 | **Empresa** | 🏢 silueta edificio | Gestionar las empresas a las que perteneces (dueño, gerente, empleado) |
| 2 | **Manager Panel** ⭐ | 📊 dashboard | App insignia — ERP de gestión empresarial avanzada (5 vistas) |
| 3 | **Mercado** | 🏷️ etiqueta | Compra-venta entre jugadores, ofertas de trabajo temporal, marketplace |
| 4 | **Logística** | 🚚 camión | Gestión de transportes, rutas, entregas, recibos |
| 5 | **Mensajes** | 💬 burbuja | Comunicación profesional 1-a-1 y grupal entre jugadores y empresas |
| 6 | **Banca** | 🏦 columna | Cuentas personales y empresariales, transferencias, contratos financieros |
| 7 | **Notas & Contratos** | 📋 pergamino | Documentos personales y contratos B2B con firma digital |
| 8 | **Tienda SONAR** | 🛒 carro | Compra de productos SONAR (variantes Tablet, licencias, skins, apps) |
| 9 | **Settings** | ⚙ engranaje | Configuración global del dispositivo |

> **Nota sobre Manager Panel:** la app es **una sola** pero su contenido **se compone dinámicamente** según las empresas a las que el jugador pertenezca. Un dueño de Granja ve el Manager Panel del granjero (descrito en `01_node_farm.md` §12). Un dueño de Molino verá el del molinero (futuro). Un jugador con Granja + Molino verá un selector de empresa al abrir la app y luego el panel correspondiente.

### 5.2 Lenguaje visual común a todas las apps

> **El OS impone consistencia. Cada app sigue el mismo lenguaje.**

- **Header** estándar: nombre de app a la izquierda, acciones contextuales a la derecha, badge de notificación si aplica.
- **Tab bar** lateral izquierda (rara) o superior (común) para sub-secciones.
- **Tipografía**: **Geist Sans** canonical (300/500/600) per NOTICE r1.1. DEPRECATED v1.0: "sans-serif corporativa" generic.
- **Colores**: cada app puede tener un **color de acento** tomado de Tier B Sonar Bright `#2DD4BF` o Tier C Coloro `#175A5F`, pero todas comparten paleta hybrid post-ADR-012 (Tier A canvas + Tier B identity + signals).
- **Botones primarios**: estilo SONAR (Sonar Bright `#2DD4BF` fill + Sonar Pulse `#14E5DD` glow al hover per `01_art_direction.md` §3.4 + §16 motion). DEPRECATED v1.0: "azul marino + dorado al hover".
- **Tablas**: estilo dashboard Crew 100 panels, filas alternadas, sortable, filtrable.
- **Modales**: con fade + slight scale-in `motion-base` 200ms `ease-depth-descent` + `panel_open` SFX canonical.
- **Toasts**: arriba a la derecha, fade-out 4s `ease-deliberate`.

---

## 6. App Empresa

### 6.1 Propósito

Permite a cualquier jugador **ver y gestionar las empresas a las que pertenece** (como dueño, gerente, empleado o temporal). Es la **lista de afiliaciones laborales del personaje**.

### 6.2 Layout

**Vista principal (Inicio):**

```
┌─────────────────────────────────────────────────┐
│ Empresa                              [+ Nueva]  │
├─────────────────────────────────────────────────┤
│  Mis empresas                                   │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 🌾 Granja del Valle                       │  │
│  │ Rol: Dueño                                │  │
│  │ Empleados: 4 │ Reputación: 87 │ Caja: ✓  │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ 🍞 Panadería Pedro                         │  │
│  │ Rol: Empleado · Tendero                   │  │
│  │ Próx. salario: 1,200$ en 2h               │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  Tap en empresa → detalle / Manager Panel       │
└─────────────────────────────────────────────────┘
```

### 6.3 Detalle de empresa (al tap)

**Para una empresa donde eres Dueño/Gerente:**

- Resumen visual: nombre, logo, reputación (estrella + número), sede (ubicación), antigüedad.
- Acciones rápidas: **Abrir Manager Panel** (botón grande), Ver libro contable, Ver empleados, Pagar nóminas.
- Métricas top 3: Beneficio mes / Empleados / Producción acumulada.
- Acceso a los detalles administrativos (modificar nombre, logo, vender empresa, dar de baja).

**Para una empresa donde eres Empleado/Temporal:**

- Resumen: nombre, tu rol, antigüedad, salario, próximo pago.
- Tareas pendientes (si gerente te asignó alguna).
- Botón "Solicitar día libre" / "Hablar con gerente" (abre Mensajes).
- Botón "Renunciar" (con confirmación + nota al dueño).

### 6.4 Crear nueva empresa

Botón **[+ Nueva]** → wizard:
1. Selección de **vertical** (Granja, Molino, Restaurante, etc. — solo aparecen las verticales que el servidor tenga instaladas).
2. **Nombre comercial** + **logo** (subir o elegir entre presets).
3. **Sede física** (selección en mapa — solo lugares disponibles que el servidor permita).
4. **Pago de licencia** (tarifa única configurable por servidor — sink económico).
5. **Confirmar.** Animación de "registrando empresa" + `depth_press` ceremonial (~800ms peso settle) + fade-in certificado generated (~2s total animation).
6. Aparece en la lista. Acceso al Manager Panel desbloqueado.

### 6.5 Wooow específicos

- **Animación ceremonial al fundar** la empresa (`depth_press` + fade-in certificado: el sistema genera certificado virtual + lo añade a Notas & Contratos). DEPRECATED v1.0: "sello al fundar" metáfora física preserve, sound canonical post-ADR-012.
- **Logo de empresa visible en TODOS los lugares** del ecosistema donde aparece esa empresa (saco con logo, camión con livery del logo, contrato firmado con el logo, Tablet de empleados con el logo en su Empresa app).
- **Reputación visible** como insignia con icono `bioluminescence` (active/premium) o `depth-gauge` (standard) + tier color metal (dorado/plateado/bronce) solo para rank visual, NO brand paleta.

---

## 7. App Manager Panel ⭐ (la app insignia)

### 7.1 Propósito

> **Esta es la app que más identifica a SONAR.**

El **ERP de gestión empresarial** del ecosistema. Cuando una empresa tiene complejidad (empleados, parcelas, inventario, finanzas), el jugador la opera desde el Manager Panel.

Su contenido **es modular**: cada vertical aporta sus propias vistas. Para la **Granja**, las vistas se describen en detalle en `01_node_farm.md` §12 (Operations / Personnel / Finance / Inventory / Strategic). Para Molino, Restaurantes, etc., habrá vistas equivalentes adaptadas a su gameplay.

### 7.2 Estructura común a todas las verticales

Independientemente del nodo, el Manager Panel siempre tiene **5 áreas conceptuales**:

| Área | Pregunta que responde | Ejemplo Granja |
|---|---|---|
| **Operations** | "¿Qué está pasando ahora mismo en mi negocio?" | Mapa de parcelas, tareas del día |
| **Personnel** | "¿Quién trabaja para mí y cómo de bien?" | Lista de empleados, productividad, salarios |
| **Finance** | "¿Cómo va el dinero?" | Ingresos, gastos, beneficio, gráficos |
| **Inventory** | "¿Qué tengo en stock?" | Silos, cámaras, almacenes |
| **Strategic** | "¿Cuál es la mejor decisión a futuro?" | Sugerencias, calendario, comparativa, contratos |

Cada vertical instancia estas 5 áreas con su contenido. **Esta consistencia es clave**: un jugador que aprende a operar la Granja, ya sabe dónde mirar cuando opere un Molino o un Restaurante.

### 7.3 Selector de empresa

Si el jugador es dueño/gerente de **varias empresas**, al abrir Manager Panel aparece un **selector** en el header:

```
┌─────────────────────────────────────────────────┐
│ Manager Panel                                    │
│ Empresa: [▼ Granja del Valle]                    │
│  ─ Granja del Valle                              │
│  ─ Panadería Pedro                               │
│  ─ Cooperativa Norte                             │
└─────────────────────────────────────────────────┘
```

Cambiar empresa = recargar el panel con sus datos. **Wooow:** transición suave de 300ms entre datasets, no flash bruto.

### 7.4 Datos en tiempo real

> Toda la información se actualiza en vivo. El bus de eventos del ecosistema (`SONAR:state_change`) garantiza que cualquier cambio en el mundo aparece en la Tablet inmediatamente.

Esto permite escenas wooow: el dueño está en la oficina viendo el Manager Panel y, **al mismo tiempo que su empleado termina una cosecha**, el silo se llena en la pantalla. Sin refrescar.

### 7.5 Modo dock (pantalla grande)

Cuando la Tablet está **acoplada al dock del despacho** (ver §21), el Manager Panel se redimensiona automáticamente al monitor del despacho. La densidad de información sube (más columnas, más gráficos visibles a la vez). El control sigue siendo desde la Tablet.

---

## 8. App Mercado

### 8.1 Propósito

Marketplace abierto del ecosistema. Aquí los jugadores y empresas publican y descubren:

- **Ofertas de trabajo temporal** (publicadas por empresas, aceptables por cualquier jugador — ver `01_node_farm.md` §11.7).
- **Productos físicos a la venta** (B2B y B2C).
- **Servicios** (transporte, mantenimiento, seguridad, consultoría RP).
- **Compra-venta de empresas** completas (oleada 3 — para ya escribirlo en arquitectura).

### 8.2 Layout

**Tabs principales:**

```
┌─────────────────────────────────────────────────┐
│ Mercado    [Trabajo] [Productos] [Servicios]    │
│                                       [Empresas]│
├─────────────────────────────────────────────────┤
│ Filtros: [Categoría ▼] [Ubicación ▼] [Precio ▼] │
│ Buscar: [_________________________]   [Buscar]  │
├─────────────────────────────────────────────────┤
│ Listado de ofertas/productos en cards           │
│                                                 │
│ ┌────────────────────────────────────────────┐  │
│ │ 🌾 Cosechar parcela hortícola 2            │  │
│ │ Granja Marcos · Hortalizas Premium          │  │
│ │ Pago: 500$ · Estimado: 30 min · Hoy         │  │
│ │ [Ver detalle]  [Aceptar]                    │  │
│ └────────────────────────────────────────────┘  │
│                                                 │
│ ┌────────────────────────────────────────────┐  │
│ │ 🍞 Pan rústico Calidad A · 50 unidades     │  │
│ │ Panadería del Sur · Reputación 92          │  │
│ │ Precio: 4.5$/unidad · Recoger en sede       │  │
│ │ [Ver]  [Comprar]                            │  │
│ └────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### 8.3 Mecánicas clave

- **Trabajo temporal:**
  - Publicación desde Manager Panel del empleador.
  - Aceptación 1-click. Sistema valida disponibilidad horaria + reputación mínima.
  - **Notificación push al aceptarla** (con dirección y descripción).
  - Al completar, **pago automático** + actualización de reputación de ambas partes.

- **Productos físicos:**
  - Las empresas publican lotes con precio. Los compradores reservan o compran.
  - **Si producto perecedero**, la oferta caduca con el producto.
  - **Logística:** opción de recogida en sede o entrega a domicilio (servicio de logística contratable, ver §9).

- **Servicios:**
  - Jugadores con licencias específicas (mecánico, transportista, fumigador, seguridad) publican sus servicios.
  - Las empresas contratan puntualmente.

- **Empresas en venta** (oleada 3):
  - Lista pública de empresas que el dueño ha puesto en venta.
  - Valoración automática del sistema (precio sugerido) + precio del vendedor.
  - Comprador potencial puede solicitar **due diligence** (acceso temporal al libro contable público).
  - Cierre vía notaría (nodo futuro).

### 8.4 Sistema de reputación visible

Cada usuario y cada empresa tiene **reputación pública** visible en sus listings:
- Estrellas + número (ej. 4.7 ★ — 124 transacciones).
- Insignias (Verificada, Premium Vendor, etc.).
- Historial de últimas transacciones (sin valores monetarios privados, solo "OK" / "Issue").

### 8.5 Wooow específicos

- **Mapa de oportunidades** (vista alternativa): las ofertas se muestran como pins en un minimap del servidor. El jugador puede aceptar la más cercana — geolocalización de oportunidades.
- **Notificaciones push** cuando aparece una oferta que matchea las preferencias guardadas (ej. *"Buscas trabajo de cosecha cerca de Sandy → nueva oferta a 1km"*).

---

## 9. App Logística

### 9.1 Propósito

Gestión de transportes, rutas, entregas. Tanto para el dueño que envía/recibe productos, como para el jugador transportista que ofrece servicios.

### 9.2 Layout

**Tabs:**

| Tab | Para quién | Contenido |
|---|---|---|
| **Mis envíos** | Dueño / gerente | Envíos pendientes, en ruta, completados |
| **Mis recogidas** | Dueño / gerente | Productos comprados que están por llegar |
| **Mis rutas** | Transportista | Rutas asignadas, estado, GPS in-game |
| **Tarifas** | Todos | Tabla de tarifas de transporte por distancia/peso |

### 9.3 Crear un envío

Wizard:
1. **Origen:** sede de mi empresa (auto) o ubicación custom.
2. **Destino:** sede del cliente (si tengo contrato), o dirección manual.
3. **Producto + cantidad** (selección desde inventario del almacén).
4. **Vehículo:** propio (uno de mis vehículos + chofer empleado) o **contratado** (pinchar transportista del Mercado).
5. **Coste estimado:** km × tarifa + recargos (refrigerado, peso, prisa).
6. **Programar:** ahora / en X horas / cuando producto esté listo.
7. **Confirmar.** Se genera **albarán físico** (un PDF impreso si docking + impresora — wooow del Granja §11.4 reusado).

### 9.4 Tracking en vivo

Una vez en ruta:
- **Mapa con la posición actual del vehículo** (ping en tiempo real).
- **Estado del producto** (peso restante, calidad — si refrigerado, alerta si la temperatura ha subido).
- **ETA**.
- **Botón llamar al transportista** (si es jugador) → abre Mensajes o llamada.

### 9.5 Wooow específicos

- **Albarán impreso físicamente** al confirmar el envío (impresora del despacho hace el ruido).
- **Tracking en tiempo real** real (no fake): el camión del transportista está físicamente moviéndose por el mapa. El pin de la app sigue la posición real.
- **Firma de entrega:** al llegar el vehículo, el receptor firma en su Tablet. La firma se sincroniza al albarán original. **Cierre del ciclo logístico.**
- **Hub futuro:** cuando salga la vertical "Distribución / Almacenes", esta app conecta directamente con almacenes profesionales jugables.

---

## 10. App Mensajes

### 10.1 Propósito

Comunicación profesional entre jugadores y empresas. **Mensajes 1-a-1**, **grupales**, y **canales empresariales** (toda la empresa).

### 10.2 Layout

```
┌─────────────────────────────────────────────────┐
│ Mensajes                          [+ Nuevo chat]│
├──────────────┬──────────────────────────────────┤
│ Chats        │  Conversación                    │
│              │                                  │
│ ● Pedro      │  Pedro:                          │
│   "Cuándo... │  "¿Cuándo me entregas el trigo?" │
│              │                                  │
│ ● Granja...  │  Tú:                             │
│   2 mensajes │  "Mañana al amanecer."           │
│              │                                  │
│ ● Molino...  │                                  │
│              │  [Adjuntar 📎] [Foto 📷] [Enviar]│
└──────────────┴──────────────────────────────────┘
```

### 10.3 Funciones

- **Chats 1-a-1** entre jugadores.
- **Chats grupales** (creas un grupo, añades miembros).
- **Canales empresariales:** cada empresa tiene un canal propio. Todos los empleados están suscritos por defecto. El gerente puede publicar avisos.
- **Adjuntar documentos** (PDF de Notas & Contratos), **fotos** (de la app cámara), **ubicaciones** del mapa.
- **Mensajes de voz** (oleada 2 — graban audio in-game vía pma-voice).
- **Llamadas de voz** (oleada 2 — directo entre Tablets, ringtone).
- **Indicadores:** entregado / leído / escribiendo... (típicos pero pulidos).

### 10.4 Privacidad

- Los mensajes son **privados**. Solo participantes del chat los ven.
- **Cifrado simulado** (visual: indicador 🔒 que dice *"Mensajes cifrados de extremo a extremo SONAR"*) — RP, no implementación real, pero refuerza profesionalismo.
- **Borrar mensaje** disponible (deja "mensaje eliminado" como placeholder).

### 10.5 Wooow específicos

- **Notificación cuando contacto importante escribe** — los jugadores VIP del jugador (ej. su jefe, sus empleados) tienen prioridad alta y notifican incluso en modo silencio (configurable).
- **Sticker pack SONAR**: 12 stickers con motivos abstractos SONAR (profundidad/capas/bioluminescence) + sector-specific (agrícolas, logística, contractual) (futuro) — el lado humano del profesionalismo. DEPRECATED v1.0: "motivos navales" literal.

---

## 11. App Banca

### 11.1 Propósito

Gestión financiera personal y empresarial. Cuentas, transferencias, contratos financieros, libro de movimientos.

### 11.2 Layout

**Tabs:**

| Tab | Contenido |
|---|---|
| **Cuentas** | Lista de cuentas accesibles (personal + empresariales) con saldos |
| **Movimientos** | Historial completo, filtrable |
| **Transferir** | Wizard de transferencia |
| **Contratos** | Préstamos, hipotecas, depósitos (oleada 2-3) |
| **Caja física** | Si tengo permiso → estado de la caja física de mi empresa |

### 11.3 Cuentas

Cada cuenta tiene:
- Nombre (ej. "Cuenta personal Marcos", "Cuenta Granja del Valle").
- Saldo actual.
- IBAN ficticio SONAR (formato `AD-XXXX-XXXX-XXXX`).
- Tipo (personal / empresarial / cooperativa).
- Permisos (quién puede operar — relevante en empresarial).

### 11.4 Transferencia

Wizard simple:
1. Cuenta origen (selección si tengo varias).
2. Cuenta destino (IBAN o nombre — autocompleta de contactos).
3. Cantidad.
4. Concepto (texto libre).
5. **Confirmar.** Animación de transferencia Sonar Bright pulse + `depth_press` canonical (Apple Touch ID success class 200-400ms) + micro-particle trail Sonar Glow hacia destino.
6. Recibo digital aparece en Notas & Contratos automáticamente.

### 11.5 Caja física (si tengo permiso)

Vista del estado de la caja fuerte de mi empresa:
- Cantidad actual visible.
- Última apertura (quién, cuándo).
- Movimientos recientes.
- **No permite operar desde la app** — la caja física es **acción en mundo** (Pilar 1). Solo monitorización.

### 11.6 Wooow específicos

- **Animación de transferencia** — sutil Sonar Bright pulse + `depth_press` canonical, no festiva. DEPRECATED v1.0: "animación de moneda" literal monetaria.
- **Recibos auto-archivados** en Notas & Contratos. Cada transferencia genera un PDF con timestamp + firma digital SONAR (DEPRECATED v1.0: "sello" metáfora física sigue válida conceptualmente pero implementación digital canonical).
- **Alertas anti-fraude** (RP): si hay un pago grande inesperado, el sistema pregunta confirmación adicional + `signal_emerge` warning variant. Detalle de profesionalismo.

---

## 12. App Notas & Contratos

### 12.1 Propósito

Repositorio de **documentos personales y contractuales** del personaje.

- **Notas privadas** (libreta digital — solo el jugador las ve).
- **Contratos B2B firmados** (con otras empresas).
- **Albaranes y recibos** (auto-generados por Logística y Banca).
- **Certificados** (licencias, alta de empresa, escrituras, etc.).
- **Documentos compartidos** (compartidos por otros jugadores con el personaje).

### 12.2 Layout

```
┌─────────────────────────────────────────────────┐
│ Notas & Contratos                  [+ Nueva]    │
├──────────────┬──────────────────────────────────┤
│ Carpetas     │  Vista previa del documento      │
│              │                                  │
│ 📁 Notas     │  CONTRATO DE SUMINISTRO           │
│ 📁 Contratos │  ─────────────────────────────    │
│ 📁 Albaranes │  Entre Granja del Valle...       │
│ 📁 Recibos   │  ...y Molino Pedro...            │
│ 📁 Certif    │                                  │
│ 📁 Compart.  │  [Imprimir] [Compartir] [Firmar] │
└──────────────┴──────────────────────────────────┘
```

### 12.3 Tipos de documento

**Notas privadas:**
- Texto libre con formato básico (negrita, listas).
- Etiquetables.
- Adjuntables a chats.
- 100% privadas (no salen del personaje).

**Contratos B2B:**
- Plantillas oficiales por tipo (Suministro recurrente / Compra puntual / Exclusividad / Calidad mínima — descritas en `01_node_farm.md` §11.4).
- Editables (rellenar campos: partes, fechas, cantidades, precios, calidad).
- **Firma digital** (animación de teclear nombre + huella).
- Una vez firmado por ambas partes → **inmutable**. Cualquier cambio requiere addendum.
- **Estado visible:** Borrador / Pendiente firma / Activo / Cumplido / Incumplido.

**Albaranes y recibos:**
- Auto-generados por Logística y Banca.
- No editables (auditoría).
- **Imprimibles** desde dock de oficina (Pilar 1: papel físico opcional).

**Certificados:**
- Licencias (de conducir maquinaria, fumigación, transporte, etc.).
- Alta de empresa.
- Escrituras de propiedades.
- **Actualización automática** — si pierdes una licencia, el certificado se marca caducado.

**Documentos compartidos:**
- Cuando alguien te comparte un PDF (vía Mensajes), aparece aquí.
- Puedes archivarlo o eliminarlo.

### 12.4 Firma digital

Cuando un contrato requiere firma:
1. Apertura del PDF en pantalla completa.
2. El sistema resalta los campos pendientes de firma.
3. Tap en el campo → **animación de firma** (el jugador "dibuja" su firma con el dedo en pantalla, o usa una firma guardada).
4. Sello SONAR se aplica con timestamp.
5. Notificación a la otra parte si ya cerraron por ambos lados.
6. **Si docking + impresora física en oficina:** el contrato se imprime físicamente al cerrarse.

### 12.5 Wooow específicos

- **Sello SONAR con timestamp visible** en cada documento firmado.
- **Animación de impresora** cuando se imprime físicamente.
- **Búsqueda potente** dentro de los documentos (tipo Apple Notes — buscas "trigo 200kg" y aparecen los contratos relevantes).
- **OCR de fotos** (futuro): si el jugador toma una foto de un papel del mundo, la Tablet la guarda como nota con texto reconocido.

---

## 13. App Tienda SONAR

### 13.1 Propósito

Tienda oficial dentro del ecosistema. Donde se compran:

- **Variantes de Tablet** (Pro, Enterprise) — upgrades de hardware.
- **Skins de OS** (incluidas con tiers o sueltas).
- **Wallpapers premium**, ringtones, packs de stickers.
- **Apps adicionales** que el servidor monetiza (oleada 2+).
- **Licencias profesionales** (de maquinaria — Granja §9.5, de mecánico, de transporte, etc.). Esta es la entrada al sistema de licencias del ecosistema.
- **Servicios premium** (verificación de empresa, entrega prioritaria, etc.).

### 13.2 Layout

```
┌─────────────────────────────────────────────────┐
│ Tienda SONAR                       [Carrito] │
├─────────────────────────────────────────────────┤
│ Categorías:                                     │
│ [Hardware] [Skins] [Apps] [Licencias] [Premium] │
├─────────────────────────────────────────────────┤
│ Destacados                                      │
│                                                 │
│ ┌─────────────┐  ┌─────────────┐  ┌──────────┐  │
│ │ Tablet Pro  │  │ Skin Carbon │  │ Lic Cosec│  │
│ │ Aluminio    │  │ Tema OS     │  │ Cosechad │  │
│ │ 4 colores   │  │ +tipografía │  │ Tractor+ │  │
│ │ 5,000$      │  │ 800$        │  │ 2,500$   │  │
│ └─────────────┘  └─────────────┘  └──────────┘  │
│                                                 │
│ Recomendados para ti                            │
│ ...                                              │
└─────────────────────────────────────────────────┘
```

### 13.3 Mecánica de compra

1. Selección de producto.
2. Vista detalle (descripción, beneficios, capturas).
3. **Añadir al carrito** o **Comprar ahora**.
4. Confirmación de pago (cuenta personal o empresarial).
5. **Animación de compra** (carro avanzando + check verde).
6. Entrega:
   - **Hardware (Tablet)**: NPC delivery → camión SONAR llega a la dirección registrada del jugador → animación de unboxing wooow.
   - **Skins / digital**: aplicado instantáneamente.
   - **Licencias**: añadidas a Notas & Contratos > Certificados, accesibles por el sistema de validación de la vertical correspondiente.

### 13.4 Cursos asociados a licencias

Algunas licencias requieren un **mini-curso** antes de obtenerse:
- **Licencia de cosechadora**: tras pagar, el jugador debe ir a un punto de la finca/granja, hacer un mini-tutorial de 5 min (animación + checkpoint físico). Solo entonces se entrega el certificado.
- Esto **gamifica el sink económico** y enseña el sistema. **Wooow** porque no es solo "paga y ya".

### 13.5 Wooow específicos

- **Entrega de Tablet por NPC delivery** — animación de unboxing en la oficina/casa del jugador.
- **Mini-cursos de licencias** físicos en mundo, no en menú.
- **Integración total con verticales** — al comprar la "Licencia de Mecánico SONAR" desde la Tienda, automáticamente se desbloquea el rol en el nodo Mecánico (futuro).

---

## 14. App Settings — detalle

### 14.1 Estructura

| Sección | Contenido |
|---|---|
| **Personalización** | Wallpaper, theme (Auto/Claro/Oscuro), color de acento, tamaño tipografía |
| **Sonido** | Volumen general, ringtone por app, vibración on/off, modo silencio horario |
| **Notificaciones** | Lista de apps con toggle y prioridad por app |
| **Privacidad** | PIN, modo huella (futuro), apps ocultas a vista externa, sync cloud |
| **Cuenta(s)** | Mi cuenta SONAR, cambiar de cuenta (Enterprise: 2 simultáneas) |
| **Almacenamiento** | Uso por app, limpieza de cache (RP) |
| **Hardware** | Modelo Tablet, número serie, tier, accesorios (dock, teclado futuro) |
| **Acerca de** | Versión OS, créditos, soporte |
| **Apagar / Reiniciar** | Acciones del dispositivo |

### 14.2 Wooow específicos

- **Toggle "Pantalla privada":** cuando otro jugador mira tu Tablet (cámara cerca), si está activo, ven solo el wallpaper y el logo (oculta UI sensible). Si está desactivado, ven lo mismo que tú. **Esto crea decisiones RP**.
- **Modo nocturno automático:** al anochecer in-game, la Tablet baja la luminosidad (efecto en pantalla del modelo 3D — el dispositivo emite menos luz al mundo).
- **Ringtone per-contact:** asignar un sonido específico a cada contacto importante (mi gerente / mi pareja in-game / mi proveedor estrella).
- **Apagado real:** al apagar la Tablet, deja de recibir notificaciones, no llegan mensajes (entran en cola). Wooow porque es coherente con el dispositivo físico.

---

## 15. Sistema de notificaciones — diseño cross-app

### 15.1 Filosofía

> Las notificaciones son la **voz del ecosistema** entrando al jugador. Mal hechas, son ruido. Bien hechas, son **el latido del juego**.

Reglas SONAR:
- **Cada notificación tiene contexto, no solo texto.** Icono + color + sonido + acción profunda.
- **Cada notificación es accionable.** Tap → abre la app en el contexto exacto (parcela afectada, mensaje nuevo, contrato pendiente).
- **Cada notificación tiene caducidad.** Si pasa N tiempo sin atender, se archiva como "no leída antigua" (no se pierde, pero no presiona).
- **El jugador controla el ruido.** Settings permite silenciar tipos enteros, apps enteras, contactos individuales.

### 15.2 Tipología de notificaciones (espectro completo)

> **Sound column mapping canonical post-ADR-012:** cada tipo usa variante del set de 5 SFX (`signal_emerge`, `depth_press`, `layer_dive`, `console_tap`, `panel_open`) + parameters (pitch/volume/decay) per tipo. **DEPRECATED v1.0:** vernaculares literales ("Alerta urgente", "Moneda", "Sello/papel", "Viento", "Camión", "Cha-ching", "Estrella") — son nombres conceptuales pre-canonical, sustituidos por `signal_emerge` variants per `01_art_direction.md` §7.2 + `01_brief_sound.md` v1.

| Tipo | Color | Sound canonical | DEPRECATED v1.0 | Cuándo | Ejemplo |
|---|---|---|---|---|---|
| **Crítica operativa** | 🔴 `critical` | `signal_emerge` urgency variant (higher pitch + 2-pulse) | Alerta urgente | Algo en mi negocio se rompe ahora | "Plaga detectada en parcela 3" |
| **Crítica financiera** | 🔴 `critical` | `signal_emerge` critical variant (deeper tone + longer decay) | Alarma grave | Dinero en riesgo | "Caja insuficiente para nóminas" |
| **Importante** | 🟡 `warn` | `signal_emerge` medium variant | Bip medio | Decisión próxima necesaria | "Riego fuera de ventana" |
| **Informativa** | 🟢 `ok` | `signal_emerge` soft variant | Bip suave | Algo bueno pasó | "Cosecha lista — Calidad A" |
| **Financiera positiva** | � `ok` Sonar Bright | `depth_press` Apple Touch ID success class | Moneda | Ingreso recibido | "Pago recibido — 1,200$" |
| **Contractual** | � `info` | `depth_press` (firma metaphor preservada) | Sello/papel | Contrato implicado | "Contrato propuesto por Molino" |
| **Mensajería** | � `info` Sonar Pulse | `console_tap` light variant | Pop | Comunicación humana | "Pedro: ¿Cuándo entregas?" |
| **Meteorológica** | 🟦 `info` cyan | `signal_emerge` ambient soft variant | Viento | Clima va a cambiar | "Tormenta entrante en 30 min" |
| **Sistema** | ⚪ `neutral` Coloro | `console_tap` neutral variant | Click | Eventos OS | "App actualizada" |
| **Mercado** | 🟠 `accent` | `console_tap` soft variant | Cha-ching suave | Marketplace | "Nueva oferta cerca de ti" |
| **Logística** | � `accent` | `signal_emerge` soft variant | Camión | Envíos / recogidas | "Tu camión llegó a destino" |
| **Reputación** | 🟢 `ok` Sonar Bright | `signal_emerge` positive variant (pitch-rise emerging) | Estrella | Cambio de status | "Subiste a reputación 90 — Premium Vendor" |

> **Color column:** DEPRECATED v1.0 emoji refs (🔴/🟡/🟢/💰/📋/💬/🌦️/⚙/🏷️/🚚/⭐) → canonical functional color tokens Signal tier (`critical`/`warn`/`ok`/`info`/`neutral`/`accent`) per `01_art_direction.md` §3.4 signal palette. Emojis preservados como visual shorthand pero token names = SSoT canonical.

### 15.3 Anatomía visual de una notificación

```
┌───────────────────────────────────────────────────┐
│ 🔴 [Icono color]                    hace 2 min    │
│ Plaga detectada                                   │
│ Parcela hortícola 3 — pulgón                      │
│ Daño estimado: 30% si no se trata en 24h          │
│ [Tratar ahora]   [Ver detalle]   [Ignorar]        │
└───────────────────────────────────────────────────┘
```

- **Icono coloreado** a la izquierda.
- **Título corto** (máx. 4 palabras).
- **Subtítulo** con contexto (parcela, empresa, persona).
- **Cuerpo** con la consecuencia o la información clave (máx. 1 línea).
- **Acciones rápidas** integradas (1-3 botones).
- **Timestamp relativo** ("hace 2 min").

### 15.4 Modos de entrega

| Modo | Comportamiento |
|---|---|
| **Push pop-up** | Banner desplegable arriba a la derecha, 6s, click para abrir |
| **Banner inferior** | Aparece en la pantalla si la Tablet está abierta, en la zona inferior — no obstaculiza |
| **Solo en panel** | Va al panel de notificaciones, sin pop-up (sutil) |
| **Bloqueante** | Modal en la Tablet que requiere acción (críticas) |

Cada tipo de notificación tiene su modo por defecto, y el jugador lo puede ajustar.

### 15.5 Integración con el mundo físico

- **Vibración del bolsillo** cuando la Tablet está guardada (modelo del personaje vibra sutilmente + sonido amortiguado).
- **Pantalla se enciende** brevemente al recibir push si la Tablet está fuera del bolsillo (incluso boca abajo en mesa — la pantalla NO se enciende si está boca abajo, RP coherente).
- **Sonido espacial:** la notificación viene del bolsillo del jugador → audio 3D, los demás jugadores cerca también la oyen sutilmente. **Wooow.**

---

## 16. Sistema multi-cuenta y multi-empresa

### 16.1 cuenta SONAR (cloud)

> **Cada personaje tiene una cuenta SONAR**. Es la identidad del personaje en el ecosistema.

La cuenta guarda:
- Datos personales (nombre, alias, foto de perfil).
- Contactos (otros jugadores, empresas).
- Preferencias de Tablet (wallpaper, ringtones, layout).
- Documentos (Notas & Contratos).
- Historial de mensajes.
- Saldos y movimientos bancarios.
- Empresas a las que pertenece (con su rol).
- Reputación.

### 16.2 Sincronización cloud

- Toda la cuenta vive en el servidor (SONAR Cloud — RP).
- Cambias de Tablet → todo restaurado al hacer login.
- Si pierdes la Tablet, los datos no se pierden.
- **Detalle inmersivo:** hay una breve animación de "Sincronizando con SONAR Cloud" al hacer login en una Tablet nueva (~5s). Recuerda al primer setup de un iPhone.

### 16.3 Multi-empresa (jugador único, varias empresas)

Un jugador puede ser:
- Dueño de la Granja del Valle (rol Owner).
- Gerente de Panadería Pedro (rol Manager).
- Empleado de Cooperativa Norte (rol Employee).
- Y temporal en cualquier oferta del Mercado.

**La Tablet maneja todas estas afiliaciones simultáneamente:**
- App Empresa → lista todas las empresas.
- Manager Panel → selector entre las empresas donde tiene rol gerencial.
- Banca → todas las cuentas (personal + las empresariales accesibles).
- Mensajes → canales de cada empresa visibles.

### 16.4 Multi-cuenta (Tablet Enterprise)

> **Solo tier Enterprise (§2.2).** Permite **dos cuentas SONAR simultáneas** en el mismo dispositivo.

Caso de uso: jugadores que mueven multi-personaje muy estructurado (admin RP, periodista que cubre dos empresas, etc.). Excepción RP — no es default.

- Switch entre cuentas con un menú en el avatar superior derecho.
- Cada cuenta tiene su propia configuración, datos, notificaciones.
- **Nunca se mezclan.** Aislamiento absoluto.

### 16.5 Login y logout

- **Primer arranque:** Tablet pide vincular cuenta (escribir nombre del personaje + verificación in-world).
- **Logout:** desde Settings > Cuentas > Cerrar sesión. Borra la sesión local. Datos siguen en cloud.
- **Login en otra Tablet:** restaura cuenta. Logout automático en la Tablet anterior (una sesión por cuenta — salvo Enterprise).

---

## 17. Permisos y seguridad

### 17.1 Niveles de seguridad

| Nivel | Ejemplo | Cómo se protege |
|---|---|---|
| **Datos públicos** | Nombre, alias, reputación | Visibles a todos |
| **Datos profesionales** | Empresas a las que pertenezco | Visibles según política de la empresa |
| **Datos personales** | Mensajes, notas, banca | Solo el dueño (PIN si activado) |
| **Datos críticos** | Permisos de admin de empresa | Doble confirmación + ventana de tiempo |

### 17.2 PIN y bloqueo

- **PIN:** 4-6 dígitos, opt-in.
- Tras 3 intentos fallidos: bloqueo 30s. Tras 6: bloqueo 5min. Tras 10: requiere reset desde cuenta cloud.
- **Bloqueo automático:** tras N min de inactividad de la Tablet (configurable, default 5 min).

### 17.3 Vista privada de pantalla

> **Wooow del Pilar 5** mencionado en §14.2.

Settings > Privacidad > Pantalla privada (toggle).

Cuando activo, si otro jugador acerca su cámara a la Tablet del personaje (target raycast detecta), **la pantalla se enmascara**: solo se ve el wallpaper y el logo. Esto crea decisiones RP — *"¿Te muestro mi Tablet o no?"*

Cuando inactivo, todos pueden ver lo mismo que el dueño.

### 17.4 Anti-suplantación

- Cada Tablet tiene un **número de serie único**.
- Si un jugador roba una Tablet de otro (mecánica oleada 2), no puede entrar — la Tablet pide login. **Es solo hardware sin la cuenta**.
- El robo afecta a la persona porque pierde el dispositivo físico (necesita comprar otro), pero no compromete sus datos.

---

## 18. Capa de personalización por servidor

> **Los servidores que compren SONAR deben poder retocar la marca para encajar con su universo.** Pero sin destruir la identidad SONAR.

### 18.1 Qué pueden personalizar los servidores

| Personalizable | Cómo |
|---|---|
| **Boot logo splash** | Servidor puede añadir su logo en una sub-pantalla "Servidor: [Nombre]" antes del logo SONAR. Pero el logo SONAR siempre está. |
| **Wallpapers default** | Servidor puede añadir wallpapers propios al pack base. |
| **Idiomas de UI** | Servidor selecciona idioma default. Multi-idioma soportado. |
| **Coste de Tablet básica** | Configurable (gratis a alto). |
| **Disponibilidad de tiers** | Servidor puede deshabilitar Pro / Enterprise si quiere homogeneidad. |
| **Apps disponibles** | Servidor activa/desactiva apps según los productos SONAR que tenga. |
| **Apps de terceros** | Servidor puede instalar **apps de terceros compatibles** con el SDK SONAR (oleada 2 — ver §20). |
| **Branding de impresión** | Los PDFs (contratos, albaranes) pueden llevar logo del servidor además del de SONAR. |

### 18.2 Qué NO pueden personalizar

- ❌ Quitar el logo SONAR del boot.
- ❌ Cambiar la fuente del OS (consistencia de marca).
- ❌ Cambiar el sonido de boot a otro genérico (es identidad).
- ❌ Reemplazar la app Manager Panel por otra (es la app insignia).
- ❌ Skins que ridiculicen la marca (TOS de licencia).

> **Filosofía:** queremos que servidores sientan la Tablet **suya** sin destruir lo que la hace **SONAR**.

---

## 19. La Tablet en el mundo físico — interacciones especiales

### 19.1 Cámara — capturar el mundo

> **Oleada 1 incluye una app Cámara básica.** Permite tomar fotos del mundo y guardarlas.

**Funciones (oleada 1):**
- Apuntar con la Tablet (cámara trasera) y capturar.
- Visor en pantalla con framing en vivo.
- Foto se guarda en **Galería** (sub-app o sección de Notas & Contratos).
- Adjuntable a Mensajes (para enviar evidencia, productos a la venta, ubicaciones, etc.).

**Funciones (oleada 2-3):**
- **Selfies con cámara frontal**.
- **Vídeos cortos**.
- **OCR** sobre fotos de papeles → reconocimiento a texto en notas.
- **Foto cenital con drone** (cuando salga la app Drones — Granja §20 oleada 3).

### 19.2 Inter-tablet — interacciones entre dispositivos

- **Compartir contacto:** acercar dos Tablets y tap en "Compartir" → swap de tarjeta de contacto. Animación bonita.
- **Pago rápido cara a cara:** en mostrador de tienda, dueño y cliente acercan Tablets, dueño introduce monto, cliente confirma → pago instantáneo. **Reemplaza el TPV.** **Wooow.**
- **Transferencia de archivo:** un PDF de un contrato → swipe de "compartir" entre dos Tablets cercanas.
- **Llamadas inter-Tablet** (oleada 2): timbrar como un teléfono, descolgar con animación.

### 19.3 Tablet vs Phone genérico — convivencia

> **La Tablet NO sustituye al phone.** Se diseña para que **convivan**.

Si el servidor tiene phone genérico instalado:
- **Phone:** vida personal — Twitter, mensajes informales, llamadas privadas, fotos casuales.
- **Tablet:** vida profesional — empresa, contratos, banca, marketplace, apps SONAR.
- Algunos datos pueden duplicarse (Mensajes pueden estar en ambos — el jugador elige a qué responde desde dónde).
- Numeros de teléfono y mensajes son interoperables (oleada 2 — bridge configurable).

Si el servidor solo tiene Tablet: la Tablet asume todas las funciones, incluyendo las personales si quiere.

### 19.4 Modos de uso especiales

- **En vehículo:** la Tablet se monta en dock del salpicadero (modelos compatibles), animación de mostrar pantalla mientras se conduce. Solo lectura — para acciones complejas hay que parar.
- **En oficina:** dock fijo (ver §21).
- **En reuniones / sala de juntas:** hay un dock proyector — la Tablet emite a una pantalla grande de la sala. Útil para presentar Manager Panel a inversores RP.

---

## 20. Integración con apps de servidor (compatibilidad con stack)

### 20.1 Filosofía: SONAR como ciudadano modelo del servidor

> La Tablet **no impone**. Se integra elegantemente con QBox, QBCore, ESX, ox_inventory, ox_target, pma-voice, sistemas de phone existentes, etc.

### 20.2 Bridges nativos

| Sistema | Cómo se integra Tablet |
|---|---|
| **QBox / QBCore** | Detecta automáticamente. Cuentas se sincronizan. Roles de empresa SONAR interopera con jobs/gangs nativos. |
| **ox_inventory** | Tablet es item físico estándar. Se ve en inventario, se puede dar/quitar. |
| **ox_target** | Interacción con docks, dispensadores, lectores de tarjeta usa ox_target. |
| **pma-voice** | Llamadas y mensajes de voz usan el voice nativo del servidor. |
| **Phone scripts** | Bridge configurable: pasar mensajes entre Tablet y phone. Default: separados (Tablet pro, phone personal). |
| **Banking nativo** | Banca de Tablet puede usar las cuentas del banco nativo o tener sus propias. Configurable. |

### 20.3 SDK para apps de terceros (oleada 2-3)

> **Visión a futuro: la SONAR Tablet será una plataforma con SDK público.**

Cualquier desarrollador puede crear apps que se instalan en la Tablet:
- **Definidas por API**: estructura de datos, eventos, layout.
- **Distribuidas vía Tienda SONAR** (o sideload por servidor).
- **Sandboxed**: no pueden romper apps del core ni acceder a datos de otras apps sin permiso explícito del usuario.

Esto convierte a SONAR en **plataforma**, no solo en producto. Estratégicamente clave a largo plazo.

---

## 21. Dock de la Tablet — el wooow del despacho

### 21.1 Concepto

> **Pieza icónica del Pilar 5 + Pilar 1 unidos.**

En el despacho del dueño de una empresa hay un **dock físico**: una base de metal con un slot vertical para la Tablet, conectada a un **monitor grande** (curvo, ultrawide, 32"+) y un teclado físico.

Cuando el dueño llega a su despacho:
1. Saca la Tablet del bolsillo.
2. La introduce en el dock (animación de slide-in con click magnético + sonido satisfactorio).
3. **El monitor grande se enciende.** La Tablet **proyecta su contenido** ampliado al monitor.
4. La Tablet sigue siendo el control (touch), pero la información se ve en el monitor enorme.
5. El teclado físico permite escribir más cómodo (mensajes largos, contratos, búsquedas).
6. **Wooow:** ver la oficina con el dueño escribiendo en el teclado mientras el monitor muestra Manager Panel con todos los gráficos del Granja en vivo.

### 21.2 Beneficios funcionales

- Más densidad de información (multi-panel en vez de mono-panel).
- Más cómodo para sesiones largas (planificar la siembra, revisar contabilidad, firmar contratos).
- Permite gameplay **"trabajo de oficina"** RP — un dueño puede quedarse 30 min en su despacho gestionando.
- Permite **reuniones**: el dueño y un visitante (jugador) pueden ver el monitor juntos. Negociaciones físicas en el despacho.

### 21.3 Variantes de dock

| Variante | Para quién | Qué incluye |
|---|---|---|
| **Dock básico** | Cualquier oficina | Solo dock + monitor mediano |
| **Dock pro** | Despachos premium | Dock + monitor curvo grande + teclado físico + impresora |
| **Dock enterprise** | Sala de juntas | Dock + pantalla 65" + sistema de proyección a mesa de reuniones |

Vendidos en Tienda SONAR.

### 21.4 Animación del docking

1. Personaje se acerca al dock.
2. Saca Tablet (anim §3.1).
3. **Acerca la Tablet al dock — los imanes la atraen visiblemente** (los últimos cm la Tablet "salta" al dock).
4. **Click magnético** + `console_tap` canonical (50-150ms Apple trackpad haptic class).
5. El monitor del despacho se enciende con fade desde negro al wallpaper de la Tablet + `panel_open` canonical (200-400ms breath-like reveal).
6. DEPRECATED v1.0: "sonido de conexión periférica" genérico — reemplazado por `panel_open` canonical post-ADR-012.
7. La UI de la Tablet se redibuja en el monitor con layout expandido (`ease-deliberate` 480ms).
8. Personaje se sienta en la silla.
9. Listo para trabajar.

### 21.5 Salida del dock

- **Pulsar botón eject** (físico en el dock) o **soltar tirando de la Tablet** (cierre suave magnético).
- Animación inversa: monitor se apaga con fade, Tablet vuelve a UI compacta, personaje guarda Tablet o la lleva en mano.

---

## 22. Casos de uso narrativos

### 22.1 Caso A — Mañana de Marcos (granjero solo)

> Marcos despierta en su casa de la granja. Es lunes 06:30 in-game. La Tablet vibra en la mesilla.
>
> Marcos coge la Tablet. Ve **3 notificaciones**:
> - 🔴 Plaga detectada en parcela hortícola 3 (4h)
> - 💰 Pago recibido: 4,200$ del Molino (1h)
> - 🌦️ Tormenta entrante a las 14:00
>
> Tap en la primera. Manager Panel se abre directamente en la parcela 3, vista detalle. Calcula: tratar le cuesta 30 min y 200$ en fitosanitario. No tratar = perder 30% del cultivo (~3,000$). Decide tratar.
>
> Va al despacho. Mete la Tablet en el dock. Monitor grande se enciende. Empieza a planificar el día desde el panel ampliado: marca las tareas (regar parcela 5 antes del medio día, tratar parcela 3 ya), revisa la previsión meteorológica detallada.
>
> Saca la Tablet del dock. Va al granero. Engancha la fumigadora al tractor. Trata la parcela 3 (acción física — fuera de Tablet). Vuelve. Recibe push: "Granja Marcos — Reputación subió a 88. Nuevo descuento del 5% en Tienda SONAR."
>
> Sonríe.

### 22.2 Caso B — Lucía en sala de juntas

> Lucía es CEO de Lucía Foods (granja + molino + panadería). Tiene reunión con un inversor RP.
>
> Llega a la sala de juntas de su casa. Mete la Tablet en el dock enterprise. La pantalla 65" muestra Manager Panel — vista Strategic.
>
> El inversor se sienta enfrente. Lucía navega:
> - Beneficio mes pasado: +18,400$ (gráfico verde subiendo).
> - Producción: 3 cultivos top, 1 underperforming.
> - Reputación cross-empresa: 91 / 100.
> - Contratos B2B activos: 7. Cumplimiento: 100%.
>
> El inversor está impresionado. Lucía abre Notas & Contratos > plantilla "Inversión externa". La rellena en vivo en el monitor. La firma con su huella en la Tablet. El inversor firma con la suya (acerca su Tablet — inter-tablet sharing).
>
> El contrato se imprime en la impresora del despacho. Cierre con apretón de manos físico (animación).

### 22.3 Caso C — Trabajador temporal Diego

> Diego es jugador casual, no quiere comprometerse con ninguna empresa. Conecta al servidor un sábado por la noche.
>
> Saca su Tablet básica. Abre Mercado. Tab "Trabajo". Filtra por "Cerca de mí" + "Hoy" + "Pago > 200$".
>
> Aparecen 4 ofertas. Acepta una: "Cosechar parcela hortícola 2 — Granja del Valle — 500$ — 30 min".
>
> Recibe push con dirección + descripción. Llega a la granja. Ficha con tarjeta (lector físico). Su Tablet vibra: "Acceso temporal concedido a parcela hortícola 2."
>
> Cosecha la parcela. Al terminar, recibe push: "Pago de 500$ recibido. Reputación temporal: +1." Vuelve al servidor a hacer otra oferta o a desconectar.

### 22.4 Caso D — Servidor temático personalizando (ejemplo genérico)

> **NOTA post-pivot:** ejemplo v1.0 usó "Costa Naval" (tema marino-portuario) — preserved como EJEMPLO de server temático que personaliza, pero **el server personaliza SU marca sin imponer metáfora naval sobre SONAR**. Otros ejemplos válidos: server medieval, server cyberpunk, server rural. Key: server-branding ortogonal a SONAR-identity. **Si un servidor quiere tema literal naval/militar para su experiencia RP, puede — pero el logo SONAR + boot sound + paleta SONAR + voz neutral premium-tech se preservan**. Ver §18.2 "Qué NO pueden personalizar".

> Server "Puerto de los Vientos" tiene tema marino-portuario RP (ejemplo histórico v1.0 "Costa Naval"). Compran SONAR.
>
> Configuran:
> - Wallpapers default: añaden 5 imágenes de barcos del puerto **al pack de wallpapers server-specific** (coexist con wallpapers SONAR abstractos canonical).
> - Boot splash: muestra "Puerto de los Vientos" antes del logo SONAR (~0.5s). Logo SONAR concept A "S-curl open" sigue apareciendo canonical post-split.
> - Idiomas: español + portugués (la comunidad es ibérica).
> - Apps disponibles: solo Granja oleada 1 + Cadena Pan.
> - Coste Tablet básica: gratis (la entregan con el contrato de personaje).
>
> El branding server se siente personal para sus jugadores, sin destruir la identidad SONAR canonical (logo + boot sound + paleta hybrid + voz neutral).

---

## 23. Arquitectura técnica resumida (briefing programación)

> **No es una especificación de implementación**, es la guía de qué necesitamos construir. La arquitectura técnica completa irá en `technical/01_architecture.md` cuando se redacte.

### 23.1 Stack tecnológico

| Capa | Tecnología | Por qué |
|---|---|---|
| **NUI (frontend Tablet)** | React + TypeScript + Vite | UI moderna, hot-reload en dev, ecosistema rico |
| **Estilos** | TailwindCSS + componentes propios (estilo shadcn/ui) | Velocidad de desarrollo, consistencia |
| **Iconos** | Lucide + set propio SONAR | Profesional + identidad de marca |
| **Animaciones** | Framer Motion | Transiciones AAA |
| **Estado global** | Zustand o Redux Toolkit | Reactivo, simple |
| **Sockets / eventos** | NUI ↔ Lua bridge estándar FiveM | Compatible con QBox/QBCore |
| **Persistencia** | MySQL/MariaDB (oxmysql) | Estándar del stack QBox |
| **Voice** | pma-voice integration | Estándar comunidad |
| **3D model en escena** | GTA V prop attached al ped + render targets para pantalla | Pantalla in-world real |

### 23.2 Componentes técnicos clave

#### A — El modelo 3D con pantalla "viva"

La pantalla del modelo 3D **renderiza la UI real**. Esto se consigue con:
- **Render target / scaleform** sobre la cara frontal de la Tablet.
- La UI se renderiza en un canvas 2D que se proyecta a la textura.
- Cuando otro jugador mira la Tablet del dueño, ve **literalmente lo mismo** (salvo modo Pantalla Privada §17.3).
- Esto es el **wooow técnico crítico** — sin esto, la Tablet sería una excusa.

#### B — Bus de eventos `SONAR:*`

Toda la integración entre nodos y la Tablet pasa por un bus de eventos único:
- `SONAR:state_change` — algo en el mundo cambió, las Tablets afectadas refrescan.
- `SONAR:notification` — empujar una notificación a una o varias Tablets.
- `SONAR:tablet_action` — algo se ejecutó desde una Tablet (firma, transferencia, oferta).
- `SONAR:dock_in` / `SONAR:dock_out` — Tablet se acopla / desacopla.
- `SONAR:account_login` / `SONAR:account_logout` — cambio de sesión.

Diseño: pub/sub eficiente, escalable, con throttling en eventos chatty.

#### C — Sistema de apps modulares

Cada app es un **paquete** con:
- Manifest (id, nombre, icono, permisos requeridos, vertical asociada).
- Componente React principal.
- Componentes de widget (opcional, para Home).
- Listeners de eventos del bus (qué events consume).

productos SONAR (Granja, Molino, etc.) registran sus apps en el bootstrap del OS. Si un servidor desinstala el resource de Granja, su app desaparece del OS automáticamente.

#### D — Cuenta cloud

Tabla `SONAR_accounts` en MySQL guarda estado por cuenta. La Tablet consulta y muta vía API Lua → MySQL.

Estructura simplificada:
```sql
SONAR_accounts (account_id, char_id, alias, profile_data_json, ...)
SONAR_tablets (tablet_serial, owner_account_id, tier, customizations_json, ...)
SONAR_notifications (notif_id, account_id, type, data_json, read, created_at, ...)
SONAR_messages (msg_id, chat_id, sender_id, body, attachments_json, ...)
SONAR_documents (doc_id, account_id, type, content_json, signatures_json, ...)
SONAR_companies (company_id, owner_account_id, name, vertical, ...)
SONAR_company_members (company_id, account_id, role, ...)
SONAR_market_offers (offer_id, type, publisher_id, data_json, ...)
SONAR_logistics_jobs (job_id, origin_id, destination_id, vehicle_id, status, ...)
```

#### E — Performance

- La Tablet **NO renderiza en el HUD permanentemente**. Solo cuando está visible.
- Los render targets se reactivan al sacar/dock, se desactivan al guardar.
- Las animaciones de UI son lightweight (transform, opacity — nada de re-render por frame).
- Las notificaciones llegan vía evento, no polling.
- Las consultas pesadas (libro contable, búsqueda en miles de documentos) son async + paginadas.

### 23.3 Compatibilidad

- **QBox / QBCore:** detección automática + bridge.
- **ESX:** bridge limitado (oleada 2).
- **ox_inventory:** la Tablet es item con metadata `tablet_serial`.
- **ox_target:** docks y lectores de tarjeta usan ox_target.
- **ox_lib:** notificaciones nativas opcional para fallback.

---

## 24. Lista de assets 3D (briefing equipo 3D)

> **Aplicando regla global Bible §13.4:** el 3D entrega asset funcional con idea wooow CORE. El código (shaders, partículas, post, swap dinámico) lo añadimos nosotros.

### 24.1 Assets de hardware Tablet

| ID | Asset | Origen | Prioridad | Oleada |
|---|---|---|---|---|
| TBL-01 | **Tablet Básica** (modelo único, color gris, aluminio mate, pantalla con render target activo) | Custom propio | Alta | 1 |
| TBL-02 | **Tablet Pro** (4 colores: gris/negro/dorado/plata, aluminio cepillado) | Custom propio | Media | 1 |
| TBL-03 | **Tablet Enterprise** (titanio, dorso carbono, 2 acabados) | Custom propio | Media | 1 |
| TBL-04 | **Caja unboxing** (animación de apertura, espuma, accesorios visibles) | Custom propio | Media | 1 |

### 24.2 Assets de docking

| ID | Asset | Origen | Prioridad | Oleada |
|---|---|---|---|---|
| DCK-01 | **Dock básico** (base metálica, slot vertical, monitor mediano 27") | Custom propio | Alta | 1 |
| DCK-02 | **Dock pro** (dock + monitor curvo 32" + teclado físico + impresora) | Custom propio | Alta | 1 |
| DCK-03 | **Dock enterprise** (pantalla 65" + sistema proyección sala juntas) | Custom propio | Media | 1 |
| DCK-04 | **Dock vehículo** (montaje en salpicadero) | Custom propio | Baja | 2 |

### 24.3 Props auxiliares

| ID | Asset | Origen | Prioridad | Oleada |
|---|---|---|---|---|
| PRP-01 | Lector de tarjeta (pequeño, LED operable) | Custom propio | Alta | 1 |
| PRP-02 | Tarjeta de empleado / cliente | Custom propio | Alta | 1 |
| PRP-03 | Impresora de oficina (con animación papel saliendo) | Custom propio | Alta | 1 |
| PRP-04 | Documento físico / contrato impreso | Custom propio | Media | 1 |
| PRP-05 | Camión SONAR delivery (livery propia) | GTA V tuneo | Media | 1 |

### 24.4 Lo que NO se pide al 3D

> **Regla Bible §13.4 aplicada:**
>
> No se pide al 3D:
> - Animaciones internas de UI (CÓDIGO).
> - Boot animation visual (CÓDIGO con render target).
> - Sonidos de boot (AUDIO).
> - Notificaciones, transiciones, modos privacidad (CÓDIGO).
> - Wallpapers (DISEÑO 2D — diseñador gráfico, no equipo 3D).
> - Iconos de app (DISEÑO 2D).
>
> Briefing 3D = compacto: ~10 modelos hardware/dock + ~5 props auxiliares. Total **< 20 assets para oleada 1**. Razonable.

---

## 25. Lista de animaciones requeridas

### 25.1 Animaciones del personaje con Tablet

- Sacar Tablet del bolsillo (mano dominante, alcanzar, extraer, posicionar) — ~2.5s.
- Guardar Tablet en bolsillo — ~1.4s.
- Sostener Tablet en mano (idle de uso, dos manos, ligero ajuste).
- Tap en pantalla con dedo (movimiento sutil del pulgar / índice).
- Swipe en pantalla.
- Pinch zoom (dos dedos).
- Encender Tablet (pulsar botón power).
- Apagar Tablet (mismo gesto).
- Dejar Tablet en mesa (boca arriba o boca abajo).
- Coger Tablet de mesa.
- **Insertar Tablet en dock** (acercar + click magnético).
- **Sacar Tablet del dock** (eject).
- Cubrirse de la lluvia con la Tablet (idle pequeño, raro).
- Mirar pantalla de Tablet ajena (cuando hay otra cerca, target raycast).

### 25.2 Animaciones de la Tablet (el dispositivo en sí)

- Pantalla encendiéndose (fade negro → wallpaper).
- Pantalla apagándose (fade a punto central).
- Vibración (sutil shake del modelo).
- Pulsación de botón power (tactile feedback en el modelo).

### 25.3 Animaciones internas de UI (responsabilidad CÓDIGO)

> Estas las hace el frontend React + Framer Motion, no el equipo 3D.

- Boot sequence completa (logo + ondas + texto).
- Lock screen → home (transición).
- App switcher (cards animadas).
- Apertura de app (zoom-in del icono).
- Cierre de app (zoom-out).
- Notificación pop-up (slide-down).
- Notificación pop-up dismiss (slide-up).
- Modal (fade + scale-in 200ms).
- Toast (slide-in derecha + fade-out 4s).
- Cambio entre vistas Manager Panel (cross-fade 300ms).
- Animación de firma digital (línea siendo dibujada).
- Animación de transferencia bancaria (Sonar Bright pulse + `depth_press` + check; DEPRECATED v1.0 "moneda + check" literal monetaria).
- Animación de impresión (impresora trabajando dentro de la app + impresora física en mundo).

---

## 26. Lista de sonidos requeridos

> **Canonical post-ADR-012:** todos los sonidos UI se mapean al set de 5 SFX firma (`signal_emerge`, `depth_press`, `layer_dive`, `console_tap`, `panel_open`) con variantes de pitch/volume/decay per contexto. Sound ambient/físico del mundo puede ser material-specific (impresora, lector tarjeta, vehículo) — NO son SFX UI. Ver `01_art_direction.md` §7.2 + `01_brief_sound.md` v1 SSoT canonical. **DEPRECATED v1.0 terminology** ("campana naval", "whoosh", "bip", "pop", "cha-ching", "moneda", "estrella mágica", etc.) preserved en tabla DEPRECATED column — reemplazo canonical en uso.

### 26.1 Sonidos del dispositivo (SFX UI canonical)

| Event | Canonical SFX | Variant | DEPRECATED v1.0 |
|---|---|---|---|
| **Boot sequence** | Premium-tech tonal rise + `console_tap` final | 1.2s ceremonial | "campana naval suavizada + acorde sintético" |
| **Boot Pro variant** | Premium-tech tonal rise + harmonic layers | 1.2s richer mix | "más capas" |
| **Boot Enterprise variant** | Premium-tech tonal rise + full harmonic layers | 1.2s premium mix | "variante premium" |
| **Pantalla enciende** | `console_tap` | 50ms light | "click discreto" |
| **Pantalla apaga** | `console_tap` | 50ms softer | "click más suave" |
| **Tap en UI** | `console_tap` | 50-80ms haptic class | "click ultra-discreto" |
| **Swipe** | `layer_dive` soft | 150-200ms transition | "whoosh muy sutil" |
| **Vibración bolsillo** | buzz amortiguado (físico, NO SFX UI) | ambient | "buzz amortiguado" |
| **Vibración mesa** | buzz contra superficie (físico, NO SFX UI) | ambient | "buzz tableteando" |

### 26.2 Sonidos de notificación

> Ver tabla §15.2 — mapping canonical completo por tipo notif con variantes `signal_emerge` + `depth_press` + `console_tap` per contexto. DEPRECATED v1.0 vernacular column preserved para trazabilidad.

### 26.3 Sonidos de docking

| Event | Canonical SFX | Duration | DEPRECATED v1.0 |
|---|---|---|---|
| **Tablet to dock (magnet click)** | `console_tap` haptic | 50-150ms | "click magnético" |
| **Monitor enciende + UI redibuja** | `panel_open` breath-like reveal | 200-400ms | "sonido de conexión periférica" |
| **Zumbido monitor on** | buzz eléctrico (físico, NO SFX UI) | ambient | "zumbido eléctrico breve" |
| **Eject del dock** | `console_tap` softer variant | 50ms | "click suave" |

### 26.4 Sonidos de inter-tablet

| Event | Canonical SFX | DEPRECATED v1.0 |
|---|---|---|
| **Acercar 2 Tablets (acoplamiento detected)** | `console_tap` | "bip discreto" |
| **Compartir contacto / archivo** | `layer_dive` + `console_tap` check | "whoosh + check" |
| **Pago cara a cara** | `depth_press` Apple Touch ID success class | "moneda + check verde" |

### 26.5 Sonidos ambiente del entorno (físico, NO SFX UI)

> **Nota:** estos sonidos son del MUNDO FÍSICO (Pilar 1), NO sonidos UI Tablet. No se mapean a los 5 SFX canonical.

- **Impresora trabajando** (motor + papel saliendo).
- **Lector de tarjeta bip** (al fichar).

---

## 27. Anti-patrones específicos de la Tablet

> Lo que **JAMÁS** vamos a hacer en este producto.

### 27.1 Anti-patrones estructurales/UX (preserved v1.0)

- ❌ **UI flotante sobre HUD** que no esté contenida en el modelo 3D del dispositivo.
- ❌ **Comando `/menu`** que abre la Tablet sin animación de saque.
- ❌ **Tablet invisible para otros jugadores** mientras la usas.
- ❌ **Phone-clone** con Twitter, Instagram, Tinder, etc. — no es nuestro espacio.
- ❌ **App que ejecuta una acción física por ti** (cosechar desde Tablet, sembrar desde Tablet).
- ❌ **Cada app con su UI propia** sin seguir el lenguaje del OS.
- ❌ **Notificaciones genéricas** ("Tienes 1 mensaje") sin contexto, color, sonido específicos.
- ❌ **Boot instantáneo** que se salta el sound + animación.
- ❌ **Apps imposibles de quitar / reordenar.**
- ❌ **Sin identidad de marca visible en el dispositivo** (logo, branding, paleta).
- ❌ **Reemplazar la Tablet por menú clásico** en cualquier acción administrativa.
- ❌ **Ringtone único genérico** para todo.
- ❌ **Pantalla siempre 100% visible a otros** sin opción de privacidad.
- ❌ **Dock que es solo decorativo** (debe transformar la experiencia).
- ❌ **Sin sincronización cloud** (perder datos al cambiar de Tablet sería frustrante).
- ❌ **Sin SDK pensado para apps de terceros** (mata la visión de plataforma).

### 27.2 Anti-patrones identidad SONAR post-pivot (NEW post-ADR-011 + ADR-012)

> Lo que **JAMÁS** vamos a hacer en la capa identidad/voz/visual/sound post-pivot SONAR. Estos son NEW anti-patrones vigentes desde 2026-05-03 per NOTICE r1.1.

- ❌ **Voz naval/militar/capitán** en copy UI ("Bienvenido a bordo", "Console SONAR activada, Profundidad operativa", "Almirante", "Tripulación", "Capitán", "Comandante", "Silent service", "Tactical-grade"). Voz canonical = neutral premium-tech (Vercel/Linear/Stripe/Apple Pro apps class).
- ❌ **Boot sound "campana naval" literal** o cualquier metáfora militar/submarino. Canonical = premium-tech tonal class (Apple chime moderno).
- ❌ **Iconografía sonar-ping/periscope/submarine/hydrophone/torpedo literal**. Canonical = abstract profundidad/capas (`descent-layers`, `signal-clarity`, `depth-grid`, `observation-field`, `lineage-trace`, `bioluminescence`, `pressure-hull` reconceptualizado, `depth-gauge`).
- ❌ **Paleta azul marino + dorado** como brand identity. Canonical = hybrid theme Tier A canvas (Abyss Black + Crew 100) + Tier B identity (Sonar Bright + Sonar Pulse) + Tier C structural (Coloro).
- ❌ **Tipografía Inter / Manrope / SF Pro** como primary. Canonical = Geist Sans (300/500/600). Inter Tight solo fallback.
- ❌ **Sound naming literal radio/acoustic** (`sonar_ping`, `sonar_sweep`, `sonar_dive`, `sonar_hatch`, `sonar_console`, `sonar_pressure`). Canonical = 5 SFX neutral premium-tech (`signal_emerge`, `depth_press`, `layer_dive`, `console_tap`, `panel_open`).
- ❌ **Wallpapers oficiales con motivos navales/militares/cinematográficos literales**. Canonical = abstract depth/bioluminescence/descent-layers per `01_brief_marketing.md` v1 moodboard.
- ❌ **Metáfora "submarino tech" literal** (hulls con remaches, periscopios, bridge-as-command-center militar, crew submarino, hatches físicas). Canonical = abstracción simbólica de profundidad / exploración paciente.
- ❌ **Logo alternativo propuesto por AI agent** sin consultar `art/branding/logo_v2/` working canonical. Logo concept A "S-curl open" adopted founder 2026-05-03 — NO proponer re-diseño unilateralmente.

---

## 28. Roadmap de oleadas Tablet

### Oleada 1 — Lanzamiento

**Hardware:**
- 3 tiers (Básica, Pro, Enterprise) con todos los acabados.
- 3 docks (básico, pro, enterprise).
- Camión delivery + animación de unboxing.

**OS:**
- Boot, lock screen, home, panel notificaciones, settings.
- 3 themes (Auto, Claro, Oscuro).
- 30+ wallpapers (mix de packs).
- 13 ringtones.
- Multi-idioma (ES, EN — base; resto como overlay).

**Apps de lanzamiento (8):**
- Empresa, Manager Panel, Mercado, Logística, Mensajes, Banca, Notas & Contratos, Tienda SONAR + Settings.

**Apps de productos:**
- Manager Panel del Granjero (incluido con resource Granja).
- Manager Panel del Molinero (incluido con Molino).
- Manager Panel del Panadero (incluido con Panadería).
- Manager Panel del Tendero (incluido con Retail).

**Sistemas:**
- Notificaciones cross-app completo.
- Multi-empresa (no multi-cuenta — solo Enterprise).
- Cloud sync.
- PIN básico.
- Pantalla privada toggle.
- Inter-tablet (compartir contacto, pago cara a cara).
- Cámara básica (foto solo).

### Oleada 2 — Update gratis tras 2-3 meses

- **Mensajes de voz** + **llamadas inter-Tablet** (con ringtone, descolgar).
- **Robo de Tablet** (mecánica RP — pierde dispositivo, recupera datos).
- **Galería extendida** (vídeos cortos + selfies).
- **Bridge configurable** con phone scripts (ESX phone, lb-phone, qb-phone).
- **Modo huella** para desbloqueo.
- **Apps adicionales:** Servicios externos (mecánico, seguridad — cuando salgan los nodos).
- **Compostaje, granizo, etc.** (apps de Granja oleada 2 enchufadas).

### Oleada 3 — Update tras 6 meses

- **App Drones** (con la vertical de drones agrícolas — Granja oleada 3).
- **OCR** sobre fotos de papeles → notas.
- **SDK público** para apps de terceros + Tienda SONAR con sección "Apps de la comunidad" (curado).
- **Sistema de notaría** (compra/venta de empresas vía Mercado + escritura digital).
- **Pago cara a cara con QR físico** (variante alternativa al inter-Tablet).
- **Modo facial** (cámara frontal escanea al personaje).
- **Cuenta multi-personaje** (admin RP, periodistas RP, etc.).

### Oleada 4+ — visión a largo plazo

- **Plataforma:** SONAR Tablet como SO público con cientos de apps de terceros.
- **Mercado de apps SONAR:** developers cobran, comparten ingreso con SONAR.
- **Tablet for Server Admins:** versión especial con apps administrativas (gestión de jugadores, métricas, intervención RP).

---

## 29. Estado del documento

- **Versión:** 1.2 (Pass 1 + Pass 2 surgical completos post-pivot SONAR — doc 1/8 Phase 6 **100% Pass done**).
- **v1.0 firmada original:** archivada en commit history pre-S1.8 (Admirals heritage 1185 líneas, naval/militar identity pre-pivot).
- **Próxima revisión:** (a) firma v2.0 post uso real S2 Tablet shell implementación, o (b) refactor si founder decide replan iconografía/sound assets con designer pro post briefs v2. Este doc está **ready-to-read para S2.0 planning** — Tablet shell + Bank app + Map app pueden leer este spec con identidad SONAR canonical coherente.
- **Documentos derivados pendientes:**
  - `technical/01_architecture.md` — arquitectura técnica completa (NUI, render target, bus de eventos, schema DB).
  - `art/01_art_direction.md` v2.0-scaffold-r7 — **YA FIRMADO post-pivot.** SSoT canonical visual.
  - `economy/01_economic_model.md` — precios de SONAR Tablet por tier, precios de licencias, sinks económicos, márgenes de tienda.
  - `02_sonar_tablet_apps_spec.md` (futuro) — especificaciones de cada app a nivel de UI/UX detallado (mockups, flows). **NOTA:** post-rename (no más `02_SONAR_tablet_apps_spec.md` upper-case).
- **Reemplaza:** `02_admirals_tablet.md` v1.0 (rename git mv en S1.8 → `02_sonar_tablet.md` v1.1).
- **ADR origen pivot:** ADR-011 + ADR-012 (`docs/planning/02_decision_log.md`).
- **NOTICE canonical top-level:** §🔄 REFINEMENT NOTICE r1.1 supersede cualquier conflict §1-§29.

### Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026 (varias) | Founder + Cascade | v1.0 firmada Admirals/Almirantazgo (1185 líneas, 29 secciones). Identidad: Tablet 5º Pilar + dispositivo físico + 4 estados + 8 apps base + AdmiralsOS + voz naval/militar + paleta azul marino+dorado + Inter/Manrope tipografía + boot sound "campana naval". Archivado por ADR-011 + ADR-012. |
| 1.1 | 2026-05-03 | Founder + Cascade (S1.8 Pass 1) | **Pass 1 surgical post-pivot SONAR.** (a) **File rename** `02_admirals_tablet.md` → `02_sonar_tablet.md` (git mv preserva history). (b) **NOTICE r1.1 top-level** establecida (~70 líneas) con NEW CANONICAL: naming SONAR + paleta hybrid Tier A/B/C + tipografía Geist Sans + voz neutral premium-tech + iconografía abstract + sound canonical 5 SFX + logo v2 working canonical concept A. (c) **Bulk identity purge** PowerShell (Admirals→SONAR + AdmiralsOS→SonarOS + Tablet Admirals→Tablet SONAR + Tienda Admirals→Tienda SONAR + cuenta Admirals→cuenta SONAR + producto/s Admirals→producto/s SONAR + logo/marca/ecosistema/apps Admirals → SONAR + ADMIRALS uppercase → SONAR) — 126 instances replaced. (d) **Surgical inline edits secciones críticas:** §2.4 Identidad visual (5 bullets refactored: wallpapers abstract + Geist Sans canonical + paleta hybrid + 5 SFX canonical + splash logo v2 ref); §3.2 Boot sound (premium-tech tonal class, deprecated "campana naval"); §4.1 Filosofía OS (voz neutral premium-tech + paleta hybrid + motion §16 + sounds canonical); §4.2 Boot sequence (Fase 1+2: logo v2 concept A reveal por capas 3 arcs + glow halation, deprecated "ondas señal naval"; Fase 3: Geist Sans + Geist Mono; Fase 4: ease-depth-descent + console_tap). (e) **§29 footer + changelog** bumped. **Pass 2 pendiente:** §6-§19 apps detail-pass + §26 sounds full + §27 anti-patterns. **Cross-refs:** ADR-011 + ADR-012 + `01_art_direction.md` v2.0-scaffold-r7 + `01_brief_logo.md` v2 + `01_brief_motion.md` v1 + `01_brief_sound.md` v1 + `01_brief_marketing.md` v1 + `art/branding/logo_v2/README.md` + Bible v1.4. |
| 1.2 | 2026-05-03 | Founder + Cascade (S1.8 Pass 2) | **Pass 2 surgical apps detail-pass post-pivot SONAR.** (a) **§5.2 Lenguaje visual común** — Geist Sans canonical + Tier B Sonar Bright accent + panel_open modales + ease-deliberate toasts (DEPRECATED azul marino + dorado hover). (b) **§6.4 + §6.5 Empresa** — depth_press ceremonial al fundar empresa (DEPRECATED "sello" literal) + iconografía bioluminescence/depth-gauge para reputación insignia. (c) **§10.5 Mensajes sticker pack** — motivos abstractos SONAR (profundidad/capas/bioluminescence) + sector-specific (DEPRECATED "navales"). (d) **§11.4 + §11.6 Banca** — Sonar Bright pulse + depth_press canonical + signal_emerge warning anti-fraude (DEPRECATED "moneda" literal monetaria). (e) **§15.2 Tipología notif table** — mapping canonical completo 12 tipos a 5 SFX canonical variants (signal_emerge urgency/critical/medium/soft/ambient/positive + depth_press success/firma + console_tap light/neutral/soft) + DEPRECATED v1.0 column preserved + color tokens functional Signal tier. (f) **§21.4 Animación docking** — console_tap magnet click + panel_open monitor reveal + ease-deliberate UI redraw (DEPRECATED "conexión periférica" genérica). (g) **§22.4 Costa Naval** — flag ejemplo v1.0 como server-branding ortogonal a SONAR canonical (server temático NO impone metáfora naval sobre SONAR). Ejemplo renombrado a "Puerto de los Vientos" neutral. (h) **§26 Sonidos requeridos** — rewrite completo con tablas canonical 4 tablas (§26.1 dispositivo + §26.3 docking + §26.4 inter-tablet + §26.5 ambient). Mapping 5 SFX + DEPRECATED v1.0 vernacular preserved. (i) **§27 Anti-patrones** — split en §27.1 structural/UX (preserved v1.0) + §27.2 identidad SONAR NEW post-pivot (9 anti-patrones: voz naval/militar, boot campana naval, iconografía sonar-ping/periscope, paleta azul marino+dorado, tipografía Inter/Manrope, sound naming radio, wallpapers navales, metáfora submarino literal, logo alternativo unilateral). (j) **§25.3 + NOTICE r1.1 line 77** minor status updates. **Doc 1/8 Phase 6 100% Pass done**, ready-to-read para S2.0 planning. |
| **1.3** | 2026-05-04 | Founder + Cascade (Sonnet 4.5, S1.10.5 Item D) | **🟢 IDENTITY V3 LOCK NOTICE inserted top-level** post-ADR-016 (`@docs/planning/02_decision_log_part2.md` v1.0). Capa canónica más reciente — supersedes NOTICE r1.1 + redacción v1.0 inline §1-§29 en cualquier conflicto palette/theme/stack/perf. **6 doctrines locked Tablet UI:** (D1) Palette tokens canonical 3-color: `--sonar-black` `#060607` + `--sonar-orange` `#FF5100` + `--sonar-white` `#FAFAFA` con tabla implementación Tailwind v4 utility classes. Tokens DEPRECATED v1.0+v1.1+v1.2 explicit purgados (Tier A/B/C hybrid + Crew + Sonar Bright/Pulse/Coloro + Signal functional). (D2) Dark-only doctrine product — Tablet UI in-game 100% dark canvas, NO light variant, NO `prefers-color-scheme` honor. Excepción única `monogram_s_black.svg` print/external NON-product. (D3) 3-color strict — estados via Lucide icons + typography weight + motion. (D5 ⭐) **Tablet UI implementation stack FROZEN S2-S8** con tabla 10 dependencias pinned: React 18.3 + Vite 5.4 + TS 5.6 strict + Tailwind v4 `@theme` + shadcn dark-only + Framer Motion 11 + Lucide React 0.460+ + Recharts 2.13 + React Context+useReducer (NO Zustand) + lb-phone NUI bridge. Cambios stack S2-S8 → ADR firmable obligatorio. DEPRECATED stack v1.0/v1.1: Inter Tight primary, Stack flexible sin pin, Zustand. (D6 ⭐) **NUI performance hard constraints** tabla 9 budgets: ≤4ms paint/frame, ≤500KB JS gzipped, ≤200KB CSS gzipped, ≤80MB heap, lazy-loading apps obligatorio, animaciones GPU-only, react-window virtualization >50 items, brand SVGs ≤8KB, Performance baseline pre-merge. **Header bumped v1.1 → v1.3** (skip header/footer desync existing). **SSoT cross-refs** brief logo v3 + art_direction v3.0 + package.json downgrade. Logo v3 firmable referenced. **Cómo navegar post-v1.3:** NOTICE v3 → NOTICE r1.1 (naming/voz/iconografía/sound preserved) → §1-§29 inline (functional/architecture/UX válidos; palette+theme+stack+perf override por v1.3). |

---

*"Hear the depth. Understand the patterns."*

**FIN DEL DOCUMENTO `docs/design/02_sonar_tablet.md` v1.3 (post-ADR-016 IDENTITY V3 LOCK NOTICE — Tablet UI implementation stack frozen S2-S8 + NUI perf budgets locked + palette tokens canonical Black/Orange/White + dark-only doctrine product).**
