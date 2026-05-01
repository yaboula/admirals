# 🎨 Admirals — Art Direction (Studio + Ecosystem)

> **Versión:** 1.0 (firmado — completo, 20 secciones)
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.2
> **Documentos hermanos:** `01_node_farm.md` v1.1 · `02_admirals_tablet.md` v1.0 · `03_node_mill.md` v1.0 · `04_node_bakery.md` v1.0
> **Documentos técnicos referenciados:** `technical/01_architecture.md` v1.0 (§13 NUI, §15 performance), `technical/02_events_catalog.md` v1.0, `technical/03_db_schema.md` v1.0.
> **Estado:** firmado.

> **Lectura previa obligatoria:** `00_PRODUCT_BIBLE.md` §13.4 (3D vs Código), `02_admirals_tablet.md` §0-§3 (anatomía Tablet).

---

## 0. Resumen ejecutivo

Este documento es **la dirección artística oficial de Admirals**. Define cómo el ecosistema **SE VE**, **SE SIENTE** y **SE OYE**.

Cubre dos capas inseparables:

1. **Meta-brand Admirals (Studio):** la identidad visual del producto comercial — logo, website, store, marketing, packaging, voz de marca.
2. **Identidad por vertical (cada nodo):** cada parte de la cadena (Granja, Molino, Banca, Mercado, Tablet, futuras) tiene **su propio mundo visual** distinguible — pero todos respiran bajo la misma meta-brand.

> **Tesis central:** Admirals no es un script. Admirals es **la Almirantazgo** que coordina una flota de mundos de trabajo, cada uno con su cultura propia. Cuando un jugador entra en Granja, huele a tierra mojada y madera vieja. Cuando entra en Molino, oye el ronroneo de los rodillos. Cuando abre el Tablet, todo converge en navy + latón premium. **Inmersión completa, identidad fragmentada-pero-coherente.**

Cubre:

- **Filosofía Art Direction Admirals** (10 principios).
- **La metáfora central:** la Almirantazgo (Admiralty) como hilo conductor.
- **Identidad de Studio** completa (logo, palette, tipografía, voz, marketing).
- **Identidad por nodo** (Granja, Molino, Tablet, futuros) — cada uno autocontenido.
- **Sistema de UI** del Tablet (donde toda la cadena converge).
- **Motion, sound, textura, materiales** — detalle al nivel del píxel.
- **3D vs Código** aplicado al arte: qué renderiza el 3D, qué hace el código.
- **Comparativa** vs 17 Movement / 0Resmon — y cómo los superamos.
- **Marketing materials, store pages, trailer style.**
- **Plan de assets** y **governance** del arte.

> **Cualquier decisión visual del ecosistema Admirals (en producto, en web, en marketing) DEBE pasar por este documento.** Si no está aquí, no es Admirals.

---

## 1. Filosofía del Art Direction Admirals

### 1.1 Los 10 principios A1-A10

| # | Principio | Significado práctico |
|---|---|---|
| **A1** | **La metáfora primero, la decoración después** | Todo elemento visual sirve a una historia (la Almirantazgo + el puerto). Nunca decoración por decoración. |
| **A2** | **Identidad por nodo, coherencia por meta-brand** | Cada vertical es **su propio mundo cultural**. La meta-brand Admirals los une mediante elementos hub (Tablet UI, formularios oficiales, branding de Studio). |
| **A3** | **Premium se siente, no se grita** | Nada de neón, nada de tipografías chillonas. Premium = espacio, peso, materiales nobles, micro-detalle. |
| **A4** | **3D rinde el sólido, el código rinde la magia** (Bible §13.4) | Modelos 3D tienen wow en la **idea geométrica**. Shaders, partículas, lighting, post-FX, motion → 100% código. |
| **A5** | **Textura sutil siempre, gradients evidentes nunca** | Paleta plana sólida + textura sutil sobre ella (parchment, brushed brass, soil, navy weave). Cero gradients de mediados-2010. |
| **A6** | **Motion con peso, nunca floaty** | Spring physics con buen damping. Las cosas se mueven como objetos reales con masa, no como webs JS de portfolio. |
| **A7** | **El silencio es diseño** | Sound design intencional. Cada acción importante tiene su sonido firma. El silencio entre sonidos también está diseñado. |
| **A8** | **Tipografía como protagonista** | Dos familias por nodo (display + body), elegidas con la misma rigurosidad que las funcionalidades. La tipografía narra. |
| **A9** | **Estilo coherente cross-touchpoint** | El logo en Tebex se siente como el Tablet en juego, que se siente como el website, que se siente como el trailer. Una sola voz. |
| **A10** | **Detalle obsesivo siempre** (Bible Pillar 3) | Una parcela tiene texturas distintas en estado seco vs húmedo. El silo cambia de sonido cuando está vacío vs lleno. **Nadie hace eso. Nosotros sí.** |

### 1.2 Relación con los 5 Pilares de la Bible

| Pilar Bible | Cómo lo materializa el Art Direction |
|---|---|
| **P1 — Físico siempre** | Cada vertical tiene su props 3D modelados + shaders/lighting que los hacen sentir reales (no models flotantes con UI encima). |
| **P2 — Cadena interconectada** | Visualmente: el material físico (saco de grano, sello del documento, código de rastreo) **viaja** y **se ve** en cada eslabón. |
| **P3 — Detalle obsesivo** | Este documento entero. Especificar al nivel de píxel/grado-RGB/ms-de-spring. |
| **P4 — Assets propios** | Ningún asset stock plug-and-play. Cada modelo, ícono, sonido pasa por la curaduría artística Admirals. |
| **P5 — La Tablet** | El Tablet es **el portal premium** que une todos los mundos. Su identidad navy+latón es la cara más vista de Admirals. |

### 1.3 Lo que NO somos (anti-references)

> **Para tener identidad clara, hay que rechazar identidades equivocadas.**

| ❌ NO somos | Por qué lo evitamos |
|---|---|
| **Sci-fi cyberpunk neón** | Saturado en FiveM (Cyberpunk 2077-clones). No queremos parecer otro reskin. |
| **Cartoon flat 2018** | Estilo Material Design genérico. Sin alma, sin diferenciación. |
| **Skeumorfismo medieval RPG** | Cuero sintético, scrolls medievales. Tackier, ages poorly. |
| **Glassmorphism iOS clone** | Imitación clara de Apple — mejor inspirarse en autoridad naval clásica que copiar Cupertino. |
| **Dark mode tacticool militar negro/lima** | El típico aesthetic "operator". Demasiado masculino agresivo. La Almirantazgo es **autoritaria pero distinguida**, no agresiva. |

### 1.4 Comparativa con 17 Movement y 0Resmon

> **Inspiraciones explícitas + diferenciación.**

| Aspecto | 17 Movement | 0Resmon | **Admirals (nosotros)** |
|---|---|---|---|
| **Paleta core** | Dark navy + cyan electric | Off-white + soft blue | **Deep navy admiral + brass gold + ivory parchment** |
| **Mood** | Tactical, urgent, ops | Modern, clean, productivity | **Authoritative, distinguished, naval heritage** |
| **Tipografía** | Sharp condensed sans | Inter / system | **Serif heritage para branding + sans premium para UI** |
| **Iconografía** | Tactical/ops symbols | Functional mono icons | **Maritime classic + functional modern híbrido** |
| **Storytelling de marca** | "We move products" | "We make tools" | **"Coordinamos tu flota comercial. Te enrolas con la Almirantazgo."** |
| **Diferenciación per-vertical** | No / mínima | No (es una herramienta única) | **Cada vertical tiene SU mundo cultural completo** ⭐ |
| **Sound design** | Mínimo | Mínimo | **Signature sound por nodo + comportamiento ambiente** ⭐ |
| **Materialidad** | Plana digital | Plana digital | **Texturas sutiles físicas (parchment/brass/oak/navy weave)** ⭐ |
| **Motion philosophy** | Sharp tactical cuts | Smooth productivity | **Spring con peso — como un barco en aguas tranquilas** ⭐ |
| **Marketing tono** | "Pro tools for ops" | "Clean minimal productivity" | **"Fundá tu casa de comercio. Ízate la enseña."** |

> **⭐ Nuestra ventaja:** ellos son herramientas. Nosotros somos **un mundo**.

---

## 2. La metáfora central — La Almirantazgo

### 2.1 ¿Qué es la Almirantazgo?

> **Naval Admiralty.** Cuerpo histórico naval británico/europeo siglo XVII-XIX que coordinaba flotas comerciales y militares. Combinaba **autoridad institucional** + **registros meticulosos** + **estética distinguida** (deep navy uniforms, latón, sextantes, mapas, sellos de cera, ledgers contables del comercio mundial).

**¿Por qué encaja Admirals?**

- ✅ **Coordinación de flota** — exactamente lo que hacemos: coordinamos una **flota de empresas** que comercian entre sí.
- ✅ **Registro meticuloso** — nuestro DB schema, audit trail, contratos firmados, lineage de batches = los **logbooks de la Almirantazgo**.
- ✅ **Autoridad institucional** — somos el árbitro neutral del ecosistema RP. No vendemos un producto, **otorgamos credenciales** (licencias, contratos, IBANs). Esa es la voz de la Almirantazgo.
- ✅ **Estética distinguida atemporal** — naval clásico envejece bien. No será "outdated" en 5 años como cyberpunk neón sí lo sería.
- ✅ **Diferenciación radical** — **nadie en FiveM usa esta metáfora.** La gente espera tactical-ops o cyberpunk. Lleguemos con una **chaqueta de almirante** y los hayamos reescrito el género.

### 2.2 Los elementos del lenguaje "Almirantazgo"

| Elemento | Uso visual | Ejemplos en producto |
|---|---|---|
| **Compass rose (rosa de los vientos)** | Logo, app icons, cargadores, fondos sutiles | App de Tablet "Brújula" (acceso rápido empresas) |
| **Sextante / catalejo** | Decoración + iconografía técnica | Splash screen Tablet, marketing |
| **Bandera de señales (signal flags)** | Estados, notificaciones, categorías | Mercado: cada offer-type = una signal flag distinta |
| **Sello de cera / lacre** | Confirmación, firma, autoridad | Documentos firmados, contratos cerrados |
| **Ancla** | Anclar/guardar/marcar favorito | Tablet — chats anclados, contactos favoritos |
| **Mapa náutico (chart)** | Mapas, diagramas, dashboards | Vista geográfica del Mercado, supply chain map |
| **Cinta-cordel + nudo** | Vínculo entre entidades | Visualización de relaciones (empresa↔empresa, contrato↔partes) |
| **Cuaderno de bitácora (logbook)** | Histórico, registros, audit | Extracto bancario, audit trail Tablet |
| **Esfera armilar / globo de comercio** | Vista global del ecosistema | Pantalla "Admirals Network" (oleada futura) |
| **Latón pulido (brushed brass)** | Acentos, separadores, micro-detalles | Bordes de cards premium, controles del Tablet |

### 2.3 El concepto del "puerto"

Cada **vertical** es un **puerto** distinto donde la flota Admirals atraca:

- **Granja** = puerto rural agrícola con muelles para grano y tractores en patio. Olor a tierra.
- **Molino** = puerto industrial con conveyors hacia los almacenes. Olor a harina y aceite.
- **Banca** = sede de la Almirantazgo en sí — la oficina principal. Olor a parchment y cera.
- **Mercado** = el zoco/lonja del puerto. Las signal flags ondean indicando qué se vende.
- **Logística** = los barcos/carros que conectan los puertos. Cargados con cargo.
- **Futuras (Panadería, Retail, Cervecería, Mecánico…)** = nuevos puertos en la red.

Cada puerto tiene su **bandera local** (su identidad visual), pero todos despachan bajo **el sello de la Almirantazgo** (la meta-brand Admirals).

> **Esto es el corazón del documento.** Toda decisión de identidad por nodo deriva de "qué tipo de puerto somos".

---

## 3. Identidad de Studio — Admirals como empresa

### 3.1 La marca Admirals

**Nombre comercial:** Admirals
**Tagline principal:** *"Founded by the fleet."*
**Tagline secundario español:** *"La economía RP que recuerda cada movimiento."*
**Tagline operacional:** *"Vertical-grade roleplay infrastructure."*

**Naming hierarchy:**

```
Admirals                          (la Studio + la marca paragua)
├── Admirals OS                   (el sistema operativo del Tablet — la marca del producto-portal)
├── Admirals Bank                 (el dominio bancario, sub-marca)
├── Admirals Market               (el mercado público, sub-marca)
├── Admirals Granja               (vertical, naming en español del cliente)
├── Admirals Molino               (vertical)
├── Admirals Panadería            (futuro)
└── Admirals <Vertical>           (cualquier vertical futuro)
```

> **Regla de naming:** "Admirals" es el **prefijo institucional** que da autoridad. Los nodos llevan el sustantivo en **español o catalán o francés** según la cultura del puerto (futuro: localizable).

### 3.2 Voz de marca

| Aspecto | Dirección |
|---|---|
| **Tono** | Confiado, distinguido, ligeramente formal — pero cálido. Como un capitán experimentado que te explica algo importante en cubierta. |
| **Persona** | "Almirante experimentado, no soberbio." Tiene autoridad porque la ha ganado, no porque la grita. |
| **Vocabulario** | Léxico naval-comercial mezclado con tecnología moderna: *flota, puerto, enrolarse, izar enseña, bitácora, sello, contramaestre, manifiesto*. |
| **Length** | Prefiere frases medias-cortas pero **densas**. Cero relleno corporate. |
| **Humor** | Subtle, seco, ocasional. Un capitán bromea raras veces y eso lo hace más memorable. |
| **Cosa que NO hacemos** | Nada de "hey amigo!", nada de exclamaciones, nada de jerga gen-Z, nada de "vibes". |

**Ejemplos de voz aplicada:**

- ✅ *"Bienvenido a bordo. Tu primera Tablet espera en el muelle."*
- ✅ *"El contrato lleva el sello de la Almirantazgo. Ambas partes pueden invocar arbitraje en cualquier momento."*
- ✅ *"Tu cosecha ha sido registrada. Calidad: A. Lote: FARM-2026-0042."*
- ❌ *"¡Hey, listo para comenzar tu aventura RP?!"* (tono Disney) — no.
- ❌ *"Roleplay infrastructure for serious operators."* (genérico tactical) — no.

### 3.3 El logotipo Admirals

> **Concepto:** un **monograma "A"** estilizado como una **brújula sobre ancla** — pero geométrico, no ilustrativo. Funciona en favicon 16px y en valla 8 metros.

**Construcción visual del logo:**

```
        ╱╲
       ╱  ╲              ← rosa de los vientos (los 4 puntos cardinales)
      ╱ ◆◆ ╲
     ╱  ╳╳  ╲
    ╱──────╲             ← travesaño que forma la "A"
   │        │
   │   ╋    │            ← cruz/áncora central (autoridad + amarre)
   │   ║    │
    ╲       ╱
     ╲_____╱
```

> **Implementación real:** SVG vectorial, peso visual balanceado, no demasiado fino. Inspiración de logos navales clásicos (Cunard Line, Lloyd's of London) pero modernizado.

**Variantes del logo:**

| Variante | Uso |
|---|---|
| **Logo completo** (monograma + wordmark "Admirals" + opcional tagline) | Website hero, packaging Tebex, splash screens primer arranque |
| **Solo monograma** (la "A" ancla-brújula) | Favicon, app icon Tablet, watermark esquinas, sello en docs firmados |
| **Wordmark solo** | Footers, créditos, bibliografía documentación |
| **Lockup vertical vs horizontal** | Variantes de aspect ratio |
| **Reverso (en oscuro vs en claro)** | Dos colorways: navy sobre ivory + ivory sobre navy |

**Reglas del logo (clara mind para PR del founder):**

1. **Espacio libre obligatorio:** alrededor del logo, mínimo el ancho de la "A" en zona muerta.
2. **Tamaño mínimo:** 24px alto en pantalla, 8mm en print. Por debajo, pasar a monograma solo.
3. **Color permitido:** navy `#0A2A47`, ivory `#F4EFE6`, brass `#C9A14A`, monocromo blanco/negro. **Cero versiones rainbow, gradient o efecto.**
4. **Prohibido:** stretch, rotate fuera de lockup, drop shadow, outline, efectos.
5. **Sello con timestamp:** las versiones de logo en docs firmados llevan año (ej. "Admirals 2026") — opcional.

### 3.4 Paleta de color META-BRAND Admirals

> **La paleta de Studio — la que usa el website, store, marketing, packaging, branding global. Cada nodo tiene su sub-paleta (§9-§11), pero todos pueden referenciar estos hex cuando son materiales "oficiales" Admirals.**

#### 3.4.1 Colores institucionales (uso constante)

| Nombre | Hex | RGB | Uso |
|---|---|---|---|
| **Admiralty Navy** | `#0A2A47` | 10, 42, 71 | Primario absoluto. Fondo de cards premium, headers, branding. |
| **Deep Navy** | `#061A2E` | 6, 26, 46 | Variante más oscura para fondos full-screen, modo oscuro Tablet. |
| **Brass Gold** | `#C9A14A` | 201, 161, 74 | Acento institucional. Bordes premium, micro-detalles, sellos, separadores. |
| **Brushed Brass** | `#A88539` | 168, 133, 57 | Variante mate del brass para áreas grandes. |
| **Ivory Parchment** | `#F4EFE6` | 244, 239, 230 | Fondo claro principal. Documentos, cards, pasajes de texto. |
| **Aged Parchment** | `#E8DFCC` | 232, 223, 204 | Variante envejecida para texturas y áreas históricas (audit, archive). |

#### 3.4.2 Colores funcionales (señalización)

> **Todos derivados de las banderas de signal flag navales (autoridad, claridad, atemporal).**

| Nombre | Hex | RGB | Uso |
|---|---|---|---|
| **Signal Crimson** | `#9B2D2D` | 155, 45, 45 | Errores, alertas críticas, banderas "stop". Un rojo profundo no estridente. |
| **Signal Saffron** | `#C5872D` | 197, 135, 45 | Warnings, banderas "caution". |
| **Signal Forest** | `#3F6B3A` | 63, 107, 58 | Success, banderas "go", confirmaciones. |
| **Signal Slate** | `#5A6B7A` | 90, 107, 122 | Neutral / disabled / info. Storm gray. |

> **Importante:** estos colores aparecen **en pequeñas dosis** (banners de notif, badges, estados). El primario nunca es uno de estos — el primario es siempre navy + brass + ivory.

#### 3.4.3 Reglas de uso de paleta

1. **Regla 60/30/10:** 60% navy + ivory (fondo + estructura), 30% brass (acento), 10% signal colors (estado funcional).
2. **Cero gradients linealesvisibles.** Si necesitamos transición, usar una **textura sutil con dos tonos cercanos** (técnica del paño naval), no un gradient liso.
3. **Contraste WCAG AA** mínimo siempre. Texto sobre navy debe ser ivory o brass+200% peso. **Tested.**
4. **Modo claro y modo oscuro:** ambos diseñados desde día 1. El modo oscuro NO es solo "invertir" — es su propio diseño con navy profundo, brass más cálido, contraste más blando.

---

## 4. Sistema tipográfico META-BRAND

### 4.1 Las dos familias

> **Una sola pareja para todo Studio + Tablet OS.** Los nodos pueden añadir su display propio (ver §9-§11), pero esta pareja es **el ADN tipográfico**.

#### 4.1.1 Display — la voz de la Almirantazgo

**Familia:** **Cormorant Garamond** (serif clásica, contemporánea revisited) o alternativa **Playfair Display**.

**Razón:** estos serif transitional/didone son **la tipografía de los registros históricos navales y comerciales**. Tienen autoridad sin ser pomposos. Funcionan en titulares y branding.

**Pesos usados:** Light, Regular, SemiBold (italic disponible para citas y enfasis).

**Aplicación:**
- Logos y wordmarks.
- Headlines website.
- Headers de sección en docs y Tablet (h1, h2 grandes).
- Citas y blockquotes.
- "Admirals" wordmark institucional.

**Anti-uso:** body text, UI controls, datos numéricos. Los serif fatigan en lecturas largas y se vuelven ilegibles a 14px en interfaces densas.

#### 4.1.2 Body / UI — la voz operativa

**Familia:** **Inter** (Rasmus Andersson) — la sans premium contemporánea.

**Razón alternativa considerada:** Söhne, Suisse Int'l, IBM Plex Sans. Inter gana por **disponibilidad gratuita + variable font + ecosistema FiveM-friendly + soporte multi-idioma sólido**.

**Pesos usados:** Regular (400), Medium (500), SemiBold (600), Bold (700). Cero light en UI (legibilidad).

**Aplicación:**
- Body text en Tablet, website, docs.
- UI controls (botones, inputs, labels).
- Datos numéricos (con `font-feature-settings: 'tnum'` para tabular nums).
- Navegación, etiquetas, microcopia.

#### 4.1.3 Mono — datos técnicos / RP-funcional

**Familia:** **JetBrains Mono** o **Berkeley Mono** (si licencia disponible).

**Aplicación:**
- IBANs y batch IDs en juego.
- Códigos de producto, serial numbers de Tablets.
- Audit trail entries.
- Developer Mode console del Tablet.
- Snippets de código en docs técnicos.

### 4.2 Type scale (tablet + web)

> **Modular scale 1.250 (Major Third)** — pareja perfecta entre ritmo y compacidad.

| Token | Tamaño | Familia | Uso |
|---|---|---|---|
| `display-xl` | 64px / 4rem | Cormorant SemiBold | Hero website, splash Tablet |
| `display-lg` | 48px / 3rem | Cormorant SemiBold | Section heros |
| `display-md` | 36px / 2.25rem | Cormorant Regular | h1 docs, page titles Tablet |
| `display-sm` | 28px / 1.75rem | Cormorant Regular | h2, modal titles |
| `body-xl` | 22px / 1.375rem | Inter Regular | Lead paragraphs |
| `body-lg` | 18px / 1.125rem | Inter Regular | Body web |
| `body-md` | 16px / 1rem | Inter Regular | Body Tablet, body docs |
| `body-sm` | 14px / 0.875rem | Inter Regular | Secondary, captions |
| `body-xs` | 12px / 0.75rem | Inter Medium | Labels, badges, micro-data |
| `mono-md` | 14px / 0.875rem | JetBrains Mono | Datos técnicos |
| `mono-sm` | 12px / 0.75rem | JetBrains Mono | Audit trails, console |

**Line-height regla general:**
- Display sizes: 1.1 - 1.2 (compactos, autoritarios).
- Body sizes: 1.5 - 1.6 (cómodos para lectura larga).
- Mono: 1.4 (legible para datos).

### 4.3 Reglas tipográficas

1. **Cero ALL CAPS en body**. Permitido en labels micro (badges, buttons opcionalmente) con tracking +0.05em.
2. **Cero italic-bold combinado** salvo enfasis muy puntual.
3. **Tabular nums obligatorio** en columnas de números (extractos bancarios, tablas).
4. **Ligaturas activas** en serif display, desactivadas en mono (legibilidad de IDs).
5. **Tracking:** display sizes -0.02em (apretar), body 0, micro-labels +0.05em.

---

## 5. Iconografía META-BRAND

### 5.1 Estilo base de iconos

**Familia primaria:** **Lucide** (línea fina, abierta, neutra, premium).

**Razón:** ya está en el stack (`technical/01_architecture.md` §13.5), tiene 1000+ iconos, mantenida activamente, peso visual coherente con Inter, y permite tweaks.

**Configuración estándar Admirals:**
- Stroke width: **1.5px** (entre la default 2px y la fina 1px).
- Stroke linecap: round.
- Stroke linejoin: round.
- Sizes: 16, 20, 24, 32px (4 tokens).

### 5.2 Custom Admirals icon set

> **Para los conceptos navales-Admirals que Lucide no cubre, dibujamos custom.** Mismo estilo (stroke 1.5px, round, neutral) para coherencia.

**Custom set planeado (~20 iconos oleada 1):**

| Icono | Concepto | Uso |
|---|---|---|
| `compass-rose` | Brújula 4 puntos | App "Empresas" Tablet |
| `signal-flag` | Bandera triangular signal | Mercado offers |
| `sextant` | Sextante | Splash, marketing |
| `wax-seal` | Sello de cera | Documentos firmados |
| `ledger` | Libro de bitácora abierto | Audit trail, banca |
| `chart-nautical` | Mapa náutico con líneas batiméticas | Mapa supply chain |
| `anchor-pin` | Ancla con cordón | Pinear chat / contacto |
| `quill` | Pluma de escribir | Crear documento, firmar |
| `wheel-helm` | Timón | Configuración / control empresa |
| `cargo-crate` | Caja con flejes | Cargo logística |
| `port-lighthouse` | Faro | Sede principal / HQ |
| `cordage-knot` | Nudo marinero | Vínculo / conexión |
| `hourglass` | Reloj de arena | Pendiente / processing |
| `medallion` | Medallón naval | Reputación, premio |
| `armillary` | Esfera armilar | Vista global ecosistema (futuro) |
| `wheat-sheaf` | Manojo de trigo | Granja |
| `mill-stone` | Piedra de molino | Molino |
| `loaf` | Pan rústico | Panadería (futuro) |
| `barrel` | Barril | Cervecería (futuro) |
| `wrench-classic` | Llave inglesa clásica | Mecánico (futuro) |

> **Reglas custom set:**
> - 24x24 grid base, stroke alineado a píxel.
> - Opticamente balanceados (no centro matemático, centro visual).
> - SVG con `currentColor` para herencia de tema.
> - Versionado en repo bajo `art/icons/admirals_icons_v1/`.

### 5.3 Iconos por estado

> **Estados visuales canónicos.** Cada estado tiene un color signal + un icono, formando un par universal en todo el producto.

| Estado | Color | Icono Lucide / Custom |
|---|---|---|
| Success / completado / fulfilled | Signal Forest `#3F6B3A` | `check-circle` |
| Warning / caution | Signal Saffron `#C5872D` | `alert-triangle` |
| Error / breached / cancelled | Signal Crimson `#9B2D2D` | `x-circle` |
| Info / neutral | Signal Slate `#5A6B7A` | `info` |
| Pending / processing | Brass Gold `#C9A14A` | `hourglass` (custom) |
| Locked / signed | Brass Gold | `wax-seal` (custom) |
| Active / live | Forest verde apagado | `radio` (animado) |

---

## 6. Texturas y materiales

### 6.1 La filosofía: "subtle physical"

> **Premium táctil sin caer en skeuomorfismo.** La diferencia es la **sutileza**: una textura debe ser **sentida más que vista**.

**Test del 50%:** si reduces opacidad de la textura al 50% y aún se siente la materia, perfecto. Si tienes que subirla a 100% para que se vea, demasiado.

### 6.2 Las 5 texturas base del meta-brand

| Textura | Aplicación | Cómo se renderiza |
|---|---|---|
| **Navy Weave** | Fondos navy de cards premium | SVG seamless tile + opacity 0.06 sobre el navy base |
| **Brushed Brass** | Bordes premium, controles físicos del Tablet | Linear gradient horizontal sutil + noise SVG fine |
| **Aged Parchment** | Documentos, audit trails, contratos | SVG paper grain + leve "varianza" cromática (pixel-shader sutil) |
| **Polished Oak** | Bordes de Tablet (frame del device) | Texture map con grano de madera real escaneada — proporción 1:1 mapeo |
| **Wax Seal Embossed** | Sellos en documentos firmados | SVG complejo con sombras internas + textura cera |

### 6.3 Cómo se aplican (técnico)

**En NUI (React/Tailwind/CSS):**

```css
/* navy weave usado como background-image en cards premium */
.card-premium {
  background-color: #0A2A47;
  background-image: url('/textures/navy-weave.svg');
  background-size: 8px 8px;
  background-blend-mode: overlay;
  background-blend-opacity: 0.06;
}

/* brushed brass como border decorativo */
.card-premium__border {
  border: 1px solid;
  border-image: url('/textures/brass-brush.svg') 1 stretch;
}
```

**En GTA V world (props 3D):**
- Textures van al modelo 3D directamente.
- Shaders aplicados via `SetEntityShader` o materiales custom — manejado por código (Bible §13.4).
- LOD: textura full a < 10m, simplificada a > 30m.

### 6.4 Anti-textura: lo que NO usamos

- ❌ **Glassmorphism / frosted glass** completo (caemos en clone Apple). Lo usamos **muy sutil** en banners flotantes solamente.
- ❌ **Gradients holográficos / iridescent** (anti A5).
- ❌ **Texture stock fotorrealista de stones/concrete plug-and-play.** Toda textura pasa por curaduría.
- ❌ **Glow / neon outer glow.** Cero. La luz se simula con shaders 3D, no con CSS box-shadow neón.

---

## 7. Sound design META-BRAND

### 7.1 Filosofía sonora

> **Cada acción importante tiene su sonido firma.** El silencio entre sonidos también está diseñado. Sound es **diseño**, no decoración.

**Inspiraciones:**
- **iOS click sounds (Apple)** — pero más cálidos, menos digitales.
- **Mecánica suiza de relojería** — para acciones de confirmación.
- **Bell de barco / ship's bell** — para notificaciones.
- **Pluma sobre parchment** — para firmas.

### 7.2 Sound library Studio

> **5 sonidos firma del meta-brand Admirals.** Cualquier nodo puede usar estos. Los nodos añaden los suyos propios encima (§9-§11).

| Sound | Uso | Carácter |
|---|---|---|
| **`admirals_chime`** | Notificación entrante crítica/importante | Dos campanas de barco, separadas 200ms. Cálido, autoritario. |
| **`admirals_seal`** | Firma de documento, confirmación contractual | "Plop" suave de sello de cera + microscópico crackle. |
| **`admirals_quill`** | Inicio de escritura/firma | Pluma sobre parchment, 1 segundo. |
| **`admirals_brass_click`** | Confirmación de acción premium (botón importante) | Click brass mecánico. Más serio que iOS click. |
| **`admirals_parchment`** | Apertura de documento, abrir bitácora | Hojas de pergamino doblando. 600ms. |

### 7.3 Reglas de sound

1. **Volumen base bajo (-12dB).** Nunca asustamos al jugador.
2. **Spatialized cuando aplica** (pma-voice 3D — sonidos del Tablet salen del Tablet, no de "todas partes").
3. **Cero loops molestos.** Si algo necesita seguir sonando, fade-out a -30dB después de 2 ciclos.
4. **Mute completo siempre disponible** en Tablet settings.
5. **Frecuencia limitada**: la misma acción no spamea sonido si se repite < 200ms (debounce).

### 7.4 Música (oleada futura)

> **Oleada 1: solo SFX. Cero música.**
> **Oleada 2 / SDK: música ambient opcional por nodo** (Tablet con player propio + Music API SDK).

---

## 8. Principios de identidad por nodo

> **Cada nodo es un puerto.** Cada puerto tiene su cultura, su clima, sus colores, sus sonidos. Pero todos los puertos despachan bajo el mismo sello de la Almirantazgo (Tablet UI + documentos oficiales + branding Studio).

### 8.1 Anatomía de la identidad de un nodo

> **Cada nodo se define en 7 dimensiones.** Esta plantilla aplica a §9 (Granja), §10 (Molino), §11 (Tablet OS), §17 (verticales placeholder) y a cualquier vertical futura.

| # | Dimensión | Qué define |
|---|---|---|
| **1** | **Concept statement** | 1-2 frases que capturan la esencia cultural del puerto. |
| **2** | **Sub-paleta del nodo** | 5-7 colores propios + cómo se relacionan con la meta-paleta Admirals. |
| **3** | **Type display propio** (opcional) | Familia tipográfica adicional usada SOLO en el branding del nodo (signage, props in-world). El UI del Tablet siempre Inter + Cormorant — el display propio aparece solo en el mundo. |
| **4** | **Iconografía firma** | 5-10 iconos custom propios del nodo (además del set base Lucide+Admirals custom). |
| **5** | **Texturas y materiales** | Materiales firma del nodo (madera, metal, telas, etc.) y cómo se aplican en 3D y NUI. |
| **6** | **Sound signature** | 3-5 sonidos firma del nodo (ambient + acciones específicas). |
| **7** | **Motion signature** | Cómo se mueven los elementos visuales del nodo (acciones, transiciones, partículas, tiempo del nodo). |

### 8.2 Regla: cuándo aparece la meta-brand vs identidad de nodo

> **Decisión crítica.** Cuando un jugador está en Granja viendo su Tablet, ¿el Tablet se ve "como Granja" o "como Admirals OS"?

**Respuesta:** **Admirals OS siempre se ve como Admirals OS** (navy + brass + ivory premium minimalist). El **contenido** que muestra puede tener acentos del nodo origen — un card de cosecha puede tener un borde sutil terracota — pero **el chrome del OS es invariante**.

**Razón:** consistencia premium del Tablet. Si cambia de aspecto cada vez que abres una app distinta, parece desorganizado. La autoridad de la Almirantazgo se nota en que **el Tablet siempre tiene el mismo respeto institucional**.

**Regla concreta:**

| Surface | Identidad |
|---|---|
| **Tablet OS chrome** (status bar, dock, app switcher, settings, bandeja notif) | **100% Admirals OS** (navy + brass + ivory) |
| **Apps Admirals** (Banca, Mercado, Empresa, Mensajes, Documentos, Notificaciones, Configuración) | **100% Admirals OS** |
| **Apps de nodo** (Granja, Molino, Panadería…) — vista principal del Tablet | **80% Admirals OS chrome + 20% acentos del nodo** (card borders, iconografía, sound signature) |
| **Mundo 3D del nodo** (sede, props, signage in-world, MLO interior, vehículos) | **100% identidad del nodo** |
| **Documentos oficiales** (contratos, recibos, certificados) | **Admirals OS — sello + branding meta** + opcional logo del nodo emisor en esquina |
| **Signage in-world del nodo** (cartel de la sede, uniformes, vehículos, packaging de producto físico) | **100% identidad del nodo** + pequeño "Admirals" wordmark abajo (como un sello de calidad) |

> **Métaphora:** los puertos de la Almirantazgo. Cada puerto tiene su bandera local visible al atracar (mundo 3D, signage). Pero los manifiestos comerciales y los registros van en el formulario oficial de la Almirantazgo (Tablet UI). Y todo barco lleva la bandera Admirals además de la local.

### 8.3 Regla: 3D vs Código aplicada al arte

> **Extiende Bible §13.4.** Aplica explícitamente a este documento.

| Asset | Quién lo construye | Notas |
|---|---|---|
| Modelo 3D (props, MLOs, vehículos, ropa) | **Equipo 3D externo** | Geometría con wow IDEA. Texturas base. UV bien hecho. Materials assignados. |
| Texturas físicas del modelo | **Equipo 3D externo** | Fotorealistas-pero-curadas. PBR si aplica. |
| **Shaders custom** (post-FX, color grading, vignettes, depth-of-field, chromatic aberration tasteful, etc.) | **CÓDIGO** | Vía FiveM `Citizen.SetTimecycleModifier`, `ReplaceHudColourWithRgba`, scaleforms o NUI overlays. |
| **Lighting dinámica** (golden hour en granja, fluorescente parpadeante en molino, lámpara cálida del banco) | **CÓDIGO** | Vía timecycles, `SetArtificialLightsState`, light entities. |
| **Partículas** (polvo de harina molino, partículas de heno granja, polvo brass del Tablet) | **CÓDIGO** | Particle FX nativos GTA o NUI overlays. |
| **Motion / animación de UI** (Framer Motion springs) | **CÓDIGO** | Specs en §13. |
| **Sound design** | **CÓDIGO + audio assets curados** | Audio assets viene de Studio o de proveedores curados. La capa de mixing/spatial es código. |
| **Iconografía** (Lucide + custom set) | **CÓDIGO + diseño en Figma** | Generamos SVGs, los servimos via NUI. |
| **Tipografía** | **CÓDIGO** (carga via @font-face en NUI; in-world textos via NUI rendertarget si aplica) | |
| **Branding aplicado a packaging in-world** (saco con logo, etiqueta de botella, signage MLO) | **3D recibe los assets curados de art** | El 3D los aplica a los modelos. |

> **Resultado:** el equipo 3D recibe **una hoja de assets de art** (logos, color codes, textures references, signage layouts) y los aplica a sus modelos. Toda la riqueza dinámica (shaders, lighting, motion, sound) la inyecta el código.

---

## 9. Granja — Earth & Harvest

### 9.1 Concept statement

> *"El puerto rural agrícola. Tierra que conoce el ciclo del año. Madera vieja, telas crudas, aire caliente al mediodía y frío al amanecer. La cosecha es el contrato más antiguo entre humano y suelo."*

**Mood reference:**
- Películas: *Days of Heaven* (Malick), *The Tree of Life* (Malick), *First Cow* (Reichardt).
- Pintores: Andrew Wyeth, Millet (*L'Angélus*).
- Estética: granja paleto americana × mas de la Provence × heritage rural mediterráneo.

**Lo que NO es Granja:**
- ❌ Granja arcade colorida tipo *Stardew Valley* (encantadora pero infantil).
- ❌ Realismo Farming Simulator (técnico pero sin alma).
- ❌ Cottagecore Pinterest 2020 (ya saturado).
- ✅ **Heritage rural premium con peso melancólico-trabajador.**

### 9.2 Sub-paleta Granja

| Nombre | Hex | Uso |
|---|---|---|
| **Wheat Gold** | `#C9A85B` | Acento principal. Harvested wheat. Card highlights "ready to harvest". |
| **Terracotta** | `#A85A3F` | Tejas de la sede, cards "alerta plaga" suave (no rojo signal — tono cálido). |
| **Sage Olive** | `#7B8A5C` | Verde de hojas, status "creciendo". Leve, no saturado. |
| **Tilled Earth** | `#5C4530` | Marrón profundo de tierra arada. Fondos secundarios, props madera. |
| **Sun Bleached Linen** | `#E8DFC4` | Telas, sacos, packaging. Variante cálida de ivory parchment. |
| **Sky Pale** | `#A9B8C5` | Cielo de día. Acentos cool muy sutiles para balancear los tonos cálidos dominantes. |
| **Rust Iron** | `#7A4A2D` | Maquinaria envejecida, herramientas. |

**Relación con meta-paleta:** la Granja es **dominantemente cálida** (wheat gold, terracotta, earth). El brass admiralty se siente natural al lado de wheat gold (mismo "warm gold family"). El navy admiralty aparece **solo cuando la Tablet/Admirals interviene** (header del app, sello en documentos), creando un contraste deliberado: "el campo es del granjero, pero el contrato es de la Almirantazgo".

### 9.3 Tipografía display propia (in-world)

**Familia:** **Recoleta** o alternativa libre **Bricolage Grotesque** — un display cálido con peso ligeramente "rural premium".

**Aplicaciones in-world:**
- Cartel de la sede ("Granja Admirals", "Cooperativa", nombres de empresas).
- Etiquetas de sacos en packaging físico ("HARVEST 2026", "WHEAT SOFT - GRADE A").
- Signage en MLO (pizarras de tareas, menus de almacén, certificados framed en pared).
- Manuales/folletos de licencias.

**El UI del Tablet sigue Inter + Cormorant.** Recoleta solo aparece en el mundo 3D del nodo Granja.

### 9.4 Iconografía firma Granja

> **Custom icons del nodo, además del custom set Admirals base (§5.2).**

| Icono | Uso |
|---|---|
| `wheat-sheaf` (ya en custom Admirals base) | App "Granja" en Tablet |
| `tractor` | Maquinaria / vehículos |
| `silo` | Capacidades de almacenamiento |
| `weather-cloud-rain` | Eventos meteorológicos |
| `bug-leaf` | Plagas detectadas |
| `seedling` | Stage temprano de cultivo |
| `sun-warm` | Stage maduro / golden hour |
| `bucket-water` | Riego |
| `sack-grain` | Producto físico (saco de grano) |
| `mesh-protective` | Malla anti-granizo instalada |

### 9.5 Texturas y materiales Granja

| Material | Aplicación |
|---|---|
| **Madera envejecida (oak/pine seca)** | Vallas, puertas de la sede, paneles del MLO, bancos. |
| **Hierro forjado oxidado** | Herramientas, herrajes de puertas, bisagras. |
| **Lino crudo / cotton sack** | Sacos de grano, ropa de trabajo, packaging del producto físico. |
| **Tierra labrada** | Parcelas (con shader que cambia según estado: seca, húmeda, recién arada). |
| **Tejas de barro cocido** | Tejado de la sede MLO. |
| **Hierba parcial / paja** | Patio, áreas de descanso. |

**Shader-driven dynamics (CÓDIGO):**
- **Suelo de parcela:** color sample-based según `soil_quality_score` y `irrigation_score` (DB §10.1). Más oscuro = más húmedo. Crackeado = seco. Dynamic.
- **Cultivos:** shader transitiona entre stages (sprouting/leafing/flowering/mature/rotten) — crossfade de texturas + escala vertical de mesh.
- **Particles:** polvo levantándose cuando un tractor labra. Polen volando en stage flowering. Hojas cayendo en otoño (season).
- **Lighting:** golden hour real al amanecer/atardecer. Sol cenital duro al mediodía. Niebla matinal en madrugada (timecycle modifier `farm_morning_mist`).

### 9.6 Sound signature Granja

| Sound | Trigger |
|---|---|
| `farm_ambient_day` | Loop ambient durante el día — gallos lejanos, viento suave, pájaros. |
| `farm_ambient_night` | Loop ambient nocturno — grillos, búhos lejanos, viento más frío. |
| `farm_tractor_idle` / `farm_tractor_working` | Motor del tractor — diferenciados según trabajo. |
| `farm_seeding` | Caída de semillas en la tierra arada. |
| `farm_harvest_combine` | Cosechadora trabajando — sonido firma, profundo y rítmico. |
| `farm_silo_fill` | Cargando un silo — chorro de grano sobre metal. |
| `farm_bell_lunch` | Campana de mediodía (opcional, ambient cultural). |
| `farm_rain_on_roof` | Lluvia sobre teja del MLO (clima dinámico). |

### 9.7 Motion signature Granja

> **El tiempo en la Granja es lento y deliberado.** Las cosas crecen, no cambian de golpe.

- **Cultivos:** transiciones de stage de 2-5 segundos con easing `easeInOutCubic` — nunca pop instantáneo.
- **Tractor:** acceleración 1200ms, frenada 800ms — pesado.
- **Cards UI** "harvest ready": pulso suave 2s loop (scale 1.00 → 1.02), alertando sin estridencia.
- **Particles:** se quedan ~3-5s en aire después de su trigger (más tiempo del que esperarías — siente "atmósfera").

---

## 10. Molino — Industrial Heritage

### 10.1 Concept statement

> *"El puerto industrial. Donde el grano se convierte en harina. Maquinaria de cien años puesta a punto, polvo blanco suspendido en el aire, conveyors que ronronean toda la jornada. Es el corazón mecánico de la cadena."*

**Mood reference:**
- Películas: *There Will Be Blood* (Anderson) — esa estética de industria heroica meticulosa.
- Estética: molino harinero italiano histórico × fábrica art-déco × workshop de ingeniero suizo.
- Materialidad: hierro fundido pulido, brass, harina blanca, sacos yute.

**Lo que NO es Molino:**
- ❌ Sci-fi factory neón cyberpunk.
- ❌ Industrial-decay post-apocalíptico oxidado abandonado.
- ❌ Fábrica corporativa Henry Ford en blanco/gris asíptico.
- ✅ **Industrial heritage premium — orgullo mecánico, elegancia de lo bien hecho.**

### 10.2 Sub-paleta Molino

| Nombre | Hex | Uso |
|---|---|---|
| **Cast Iron Charcoal** | `#2D2A26` | Maquinaria principal. Casting iron pulido. Dominante en MLO interior. |
| **Flour Ivory** | `#EFE8DA` | Harina, polvo, paredes claras del molino, sacos. |
| **Copper Bright** | `#B5703A` | Cubiertas de caldera, conductos, instrumentos. Acento principal. |
| **Oxidized Brass** | `#7A6539` | Placas, manivelas, etiquetas grabadas. |
| **Dust Beige** | `#C7B894` | Polvo de harina depositado, ambiente. |
| **Oxide Red Maquinaria** | `#7A3027` | Pinturas roja oxidada de maquinaria heritage (válvulas, levas). Acento puntual. |
| **Steam White** | `#D4D0C8` | Vapor / polvo en aire. |

**Relación con meta-paleta:** Molino es **monocromo dramático** (charcoal + ivory + copper accents). El brass admiralty conversa muy bien con el copper de la maquinaria — ambos son metales nobles cálidos. El navy admiralty contrasta como **autoridad limpia** sobre el trabajo industrial.

### 10.3 Tipografía display propia (in-world)

**Familia:** **Stencil Sans** (con peso, tipo "industrial pochoir") + **Recoleta** para signage premium. Alternativa libre: **Bebas Neue** + **Playfair Display**.

**Aplicaciones:**
- Etiquetas de sacos de harina ("FLOUR BAKER 25KG · GRADE A · BATCH MILL-2026-0042").
- Placas de máquinas grabadas en latón ("Mill Rollers Mk.III · Admirals Industrial").
- Cartelería de seguridad MLO ("ATENCIÓN · POLVO DE HARINA · NO FUMAR").
- Manuales y certificados.

### 10.4 Iconografía firma Molino

| Icono | Uso |
|---|---|
| `mill-stone` (ya en custom Admirals base) | App "Molino" en Tablet |
| `gear-cog` | Maquinaria |
| `roller-mill` | Rodillos específicos |
| `sieve-mesh` | Tamices/sasors |
| `bag-flour-stamped` | Saco de harina con sello |
| `pallet-stacked` | Pallet completo |
| `valve-pipe` | Conductos de transporte |
| `dust-particle-cloud` | Polvo en aire (warning seguridad) |
| `temperature-gauge` | Instrumentos |
| `humidity-drop` | Humedad (warning calidad) |

### 10.5 Texturas y materiales Molino

| Material | Aplicación |
|---|---|
| **Hierro fundido pulido** | Maquinaria principal — rodillos, carcasa de cleaner, conveyors. |
| **Cobre patinado** | Calderas, conductos visibles, etiquetas. |
| **Latón engrasado** | Manivelas, válvulas, gauges. |
| **Madera dura barnizada (heritage)** | Mostrador de oficina del jefe de molino, archivero. |
| **Yute / tela basta** | Sacos. |
| **Concrete pulido suelo** | Suelo del molino — gris cálido con manchas de harina. |
| **Vidrio industrial** | Mirillas en máquinas, lámparas de jaula. |

**Shader-driven dynamics (CÓDIGO):**
- **Polvo de harina suspendido:** particles globales en el MLO interior — sutil, omnipresente, intensifica cerca de máquinas activas.
- **Vapor:** salidas localizadas de máquinas en operación.
- **Lighting:** **lámparas industriales de jaula** colgantes con tungsteno cálido. Fluorescentes en oficinas. Sodio amarillo en almacenes (heritage). Algún parpadeo aleatorio sutil para atmósfera (cero estridente).
- **Maquinaria animada:** rodillos rotando (visualmente perceptible), conveyors moviéndose con belt textura scroll.
- **Visual de batches:** sacos generan visualmente al `batch_packed` con etiqueta legible.

### 10.6 Sound signature Molino

| Sound | Trigger |
|---|---|
| `mill_ambient_running` | Loop principal cuando hay máquinas activas — ronroneo profundo + conveyor + ventilación. |
| `mill_ambient_silent` | Cuando todo parado (mantenimiento, fuera de horas). Muy quieto, ecos. |
| `mill_rollers_starting` | Arranque de los rodillos — crescendo 3 segundos. |
| `mill_grain_falling` | Grano cayendo en tolva. |
| `mill_sack_drop` | Saco cayendo en pallet — golpe sordo característico. |
| `mill_sieve_shake` | Tamiz vibratorio — sonido firma del sasor. |
| `mill_machine_alarm` | Alarma de máquina averiada — distintiva, no estridente, autoritaria. |
| `mill_cleaning_brush` | Cepillado de máquinas durante limpieza. |

### 10.7 Motion signature Molino

> **El tiempo en el Molino es mecánico y rítmico.** Cosas se mueven a tempo constante. Predictibilidad industrial.

- **Maquinaria 3D:** rotación constante, no acelerada/frenada visualmente. Simple, eterna.
- **Conveyors:** belt scroll constante — feedback "está funcionando".
- **UI status maquinaria:** badges con pulso 3s loop más industrial (más nítido que el Granja, sigue siendo no agresivo).
- **Notificaciones de batch:** cuando termina molienda, slide-in de la card con spring tipo "satisfacción mecánica" — overshoot leve y settle.

---

## 11. Tablet (Admirals OS) — Naval Premium

### 11.1 Concept statement

> *"El catalejo del capitán. La única ventana premium por la que se ve toda la red. Es la oficina central de la Almirantazgo bolsillada en la chaqueta. Cuando lo desbloqueas, suena la campana del barco y aparece la rosa de los vientos."*

**Mood reference:**
- iPadOS / iOS premium — pero con peso, sin ser clone.
- Heritage brass + glass instruments (sextant, marine chronometer Patek Philippe).
- Apple Vision Pro restraint visual — espacio, calma.

**Lo que NO es:**
- ❌ Phone clone iPhone literal (visto y revisto).
- ❌ Cyberpunk overlay HUD (anti-A1).
- ❌ Material Design genérico.
- ✅ **Premium naval instrument — autoridad, peso, calma.**

> **Detalle: ya tenemos `02_admirals_tablet.md` v1.0 firmado** definiendo la anatomía completa del Tablet (físico-objeto, dock, apps, comportamiento). Esta sección **se enfoca exclusivamente en la dirección artística** — cómo se ve, no cómo funciona.

### 11.2 Sub-paleta Tablet OS

> **La paleta del Tablet ES la meta-paleta Admirals (§3.4)** porque el Tablet es **el caracter principal** de la marca. Pero refinada:

| Nombre | Hex | Uso |
|---|---|---|
| **Admiralty Navy** | `#0A2A47` | Background principal (modo dark). Cards. |
| **Deep Navy** | `#061A2E` | Background apps full-screen modo dark. |
| **Navy Mist** | `#163E5C` | Cards elevadas en modo dark — un escalón por encima del background. |
| **Brass Gold** | `#C9A14A` | Acento principal. Bordes premium, micro-detalles, brand chrome. |
| **Brass Highlight** | `#E0B660` | Hover/active state en controles brass. |
| **Ivory** | `#F4EFE6` | Texto sobre navy. Background principal en modo light. |
| **Ivory Dim** | `#D4CCB9` | Texto secundario sobre navy. |
| **Glass Tint** | `rgba(244,239,230,0.08)` | Banners flotantes glassmorphism muy sutil. |
| **Border Brass Subtle** | `rgba(201,161,74,0.20)` | Bordes 1px de cards premium. |

### 11.3 El frame del Tablet (físico-objeto en mundo + render NUI)

> **El Tablet es un objeto físico** (Bible P1) — tiene **chasis 3D** + **pantalla NUI rendertarget**. La dirección artística aplica a ambos:

**Chasis 3D (modelo + textura — equipo 3D):**
- **Frame material:** **brushed brass + polished oak inlay** en bordes. Premium táctil.
- **Espesor:** ~12mm — sentido peso, no smartphone fino.
- **Grosor del marco frente a pantalla:** 8mm — espacio respetable, no edge-to-edge moderno.
- **Detalle:** logo Admirals en relieve sutil en la parte de atrás del Tablet (visible cuando pasa otro jugador).
- **Botón físico:** un solo botón en lateral derecho, brass — para encender/bloquear.
- **Color del frame (3 modelos):**
  - **Basic:** chasis charcoal + brass inlay.
  - **Pro:** chasis navy + brass inlay + oak details.
  - **Enterprise:** chasis navy + brass inlay + ivory parchment back con logo grabado.

**Pantalla NUI (CÓDIGO):**
- Aspect ratio: 16:10 (proporción tablet, no phone).
- Densidad: 144dpi simulada (sharp pero no microscópica).
- **Overlay vidrio:** muy sutil glass reflection encima en zonas brillantes — efecto NUI con pseudo-element + blend-mode `screen` opacity 0.04.

### 11.4 Tipografía Tablet OS

> **100% Cormorant Garamond + Inter (paleta meta-brand §4).**

**Reglas específicas Tablet:**
- **App titles:** Cormorant Regular 28px (display-sm).
- **Body content:** Inter Regular 16px (body-md).
- **Status bar / dock:** Inter Medium 12px (body-xs) con tracking +0.05em.
- **Datos numéricos** (saldos, IDs, batch codes): JetBrains Mono.
- **Splash de apertura:** Cormorant SemiBold 64px "Admirals" centrado, fondo navy con monograma brass.

### 11.5 Iconografía Tablet OS

> **Set completo Lucide + Custom Admirals (§5).**

**Reglas Tablet:**
- App icons home screen: 56x56px en grid 8x8.
- App icons dock: 48x48px.
- Status bar icons: 16x16px.
- Acción icons en cards: 20x20px.
- Stroke 1.5px universal. Color brass `#C9A14A` para iconos estado-activo, ivory dim `#D4CCB9` para iconos pasivos.

**Cada app principal tiene su icono firma:**

| App | Icono | Color de fondo de tile |
|---|---|---|
| Brújula (Empresas) | `compass-rose` | Navy con brass border |
| Banco | `ledger` | Navy con brass seal corner |
| Mercado | `signal-flag` | Navy con multiple flags subtitle |
| Mensajes | `chat-bubble-classic` | Navy con brass dot |
| Documentos | `quill` + `wax-seal` | Parchment con brass seal |
| Notificaciones | `chart-nautical` | Navy |
| Mapa | `chart-nautical` | Navy |
| Configuración | `wheel-helm` | Navy |
| Granja (cuando es vertical activa) | `wheat-sheaf` | Wheat gold acentos sobre navy |
| Molino | `mill-stone` | Copper acentos sobre navy |

### 11.6 Texturas y materiales Tablet OS

| Material NUI | Aplicación |
|---|---|
| **Navy weave** (subtle) | Background full-screen apps OS (Banco, Mercado, etc). |
| **Brushed brass thin** | Borders 1px-2px de cards premium, separadores entre secciones. |
| **Glass tint** | Banners flotantes modal/toast con `backdrop-filter: blur(20px)` + tint navy 0.08. |
| **Aged parchment** | Background de docs (Banca extracto, contratos) — `linear-gradient` + texture overlay opacity 0.05. |
| **Wax seal embossed** | Sello en documentos firmados — SVG complejo con drop-shadow inner. |

### 11.7 Sound signature Tablet OS

> **5 sonidos firma del meta-brand Admirals (§7.2)** + 5 específicos del Tablet:

| Sound | Trigger |
|---|---|
| `tablet_unlock` | Desbloquear Tablet — campana + chime breve. |
| `tablet_lock` | Bloquear Tablet — un click brass + fade. |
| `tablet_app_open` | Abrir una app — micro-swoosh + brass click 80ms. |
| `tablet_app_close` | Cerrar app / volver al home — fade reverse del open. |
| `tablet_switch` | Cambiar entre apps con app switcher — brass slide 200ms. |
| `tablet_keyboard_tap` | Tap en teclado virtual — micro-click 30ms muy bajo. |
| `tablet_swipe` | Gesto de swipe — fricción suave brass-on-felt. |
| `tablet_notification_arrived` | Notif de tipo `important` — campana doble breve. |
| `tablet_notification_critical` | Notif de tipo `critical_op|critical_fin` — campana triple + chime más fuerte. |
| `tablet_error` | Error de validación — un solo click corto descendente. |

### 11.8 Motion signature Tablet OS

> **El tiempo del Tablet es deliberado y premium.** Spring physics con weight, nunca floaty.

**Stack:** Framer Motion (`technical/01_architecture.md` §13.5).

**Motion tokens canónicos Admirals:**

```typescript
// Speed tokens
const SPEED = {
  micro: 120,    // hover, focus, instant feedback
  fast: 200,     // small UI elements (button press, toggle)
  base: 300,     // standard transitions (modal in, card flip)
  slow: 500,     // major transitions (page change, app switch)
  glacial: 800,  // ceremonial moments (signing seal, splash)
};

// Spring tokens
const SPRING = {
  // calmSurface: cards, modals, surfaces que aparecen tranquilamente
  calmSurface: { type: 'spring', stiffness: 300, damping: 30, mass: 0.8 },
  // confidentControl: botones, toggles, controles inmediatos
  confidentControl: { type: 'spring', stiffness: 500, damping: 35, mass: 0.5 },
  // ceremonialReveal: documentos firmados, seal stamping, eventos importantes
  ceremonialReveal: { type: 'spring', stiffness: 200, damping: 25, mass: 1.2 },
  // industrialPunch: confirmación de acciones críticas (transfer ok, contract signed)
  industrialPunch: { type: 'spring', stiffness: 700, damping: 28, mass: 0.6 },
};

// Easing tokens (para animaciones non-spring)
const EASING = {
  premium: [0.32, 0.72, 0, 1],         // cubic-bezier — entradas premium
  exit: [0.4, 0, 0.6, 1],               // salidas suaves
  microFeedback: [0.5, 0, 0.5, 1],     // micro interactions
};
```

**Reglas universal de motion:**
1. **Cero animaciones > 800ms** salvo splash de apertura (1500ms permitido).
2. **Cero springs muy bouncy** (damping < 20). La Almirantazgo no rebota.
3. **Stagger en listas** de 30-50ms entre items (no cascada larga).
4. **Reduced motion respect:** detect `prefers-reduced-motion` y simplificar a fade simple.

**Patrones canónicos aplicados:**

| Acción | Token |
|---|---|
| Botón hover | `EASING.microFeedback`, `SPEED.micro` |
| Botón press | `SPRING.confidentControl` |
| Card aparición | `SPRING.calmSurface`, opacity 0→1 + y 8→0 |
| Modal entrada | `SPRING.calmSurface`, scale 0.95→1 + opacity |
| App swipe transition | `SPRING.confidentControl`, x slide |
| Document seal aplicación | `SPRING.ceremonialReveal`, scale 0.5→1 + rotate -15°→0° |
| Bank transfer success | `SPRING.industrialPunch`, scale pulse + checkmark draw |
| Notification slide-in | `SPRING.calmSurface` + fade |

---

## 12. Sistema NUI Tablet — Design System completo

> **El Tablet es el rostro digital de Admirals.** Esta sección define el design system formal — tokens, componentes, layouts, patrones — que cualquier app interna o de SDK terceros (oleada 3) debe respetar para sentirse "Admirals".

### 12.1 Filosofía de design system

| Principio | Aplicación |
|---|---|
| **Token-first** | Cero valores literales en componentes. Todo color, spacing, radius, shadow viene de tokens. |
| **Composición sobre variantes** | Componentes pequeños bien hechos > componentes monolíticos con 30 props. |
| **Densidad calibrada** | El Tablet no es móvil ni desktop. Densidad propia: 16px base, gap 12px medio, padding 20px cards. |
| **Light + Dark obligatorio** | Modo dark default (Admiralty Navy). Modo light alternativo con paleta Ivory base. Nunca un solo modo. |
| **Accesibilidad mínima AA** | Contrast ratio ≥ 4.5:1 body, ≥ 3:1 large text. Todos los focus states visibles brass 2px outline. |
| **Stack canónico** (`technical/01_architecture.md` §13) | React 18 + TS 5 + Tailwind + Framer Motion + Lucide + Zustand. Nada de jQuery, nada de Bootstrap, nada de MUI. |

### 12.2 Tokens del design system (`tokens.ts`)

> **Todos los componentes consumen estos tokens.** Si quieres añadir un valor nuevo, va aquí primero.

```typescript
// admirals_tablet/web/src/design/tokens.ts

export const TOKENS = {
  // Color (alias de paleta meta-brand §3.4 + Tablet sub-paleta §11.2)
  color: {
    bg: {
      primary:    '#0A2A47',  // Admiralty Navy — background principal dark
      deep:       '#061A2E',  // Deep Navy — full-screen apps
      raised:     '#163E5C',  // Navy Mist — cards elevadas
      lightPrimary: '#F4EFE6',  // Ivory — modo light background
      lightRaised:  '#FFFFFF',  // White card light mode
    },
    fg: {
      primary:    '#F4EFE6',  // Ivory — texto principal sobre navy
      secondary:  '#D4CCB9',  // Ivory Dim — texto secundario
      muted:      'rgba(244,239,230,0.55)', // texto deshabilitado
      onLight:    '#0A2A47',  // texto sobre fondo claro
      onLightMuted:'#5C6B7A',
    },
    accent: {
      brass:      '#C9A14A',  // brand accent
      brassHover: '#E0B660',  // hover/active
      brassPress: '#A8862F',  // press
      brassDim:   'rgba(201,161,74,0.20)', // bordes sutiles
    },
    semantic: {
      success: '#5B8C5A',     // verde sage (no fluorescente)
      warning: '#D4A04A',     // amber (cercano al brass para coherencia)
      danger:  '#A04848',     // rojo terracotta
      info:    '#5B7A8C',     // azul slate
    },
    overlay: {
      modalScrim: 'rgba(6,26,46,0.72)',
      glassTint:  'rgba(244,239,230,0.08)',
    },
  },

  // Spacing (multiplicador 4px)
  space: {
    0: '0',
    '0.5': '2px',
    1: '4px',
    2: '8px',
    3: '12px',
    4: '16px',  // base unit Tablet
    5: '20px',  // padding cards
    6: '24px',
    8: '32px',
    10: '40px',
    12: '48px',
    16: '64px',
  },

  // Radius
  radius: {
    none:  '0',
    sm:    '4px',   // chips, pills, micro-cards
    md:    '8px',   // botones, inputs
    lg:    '12px',  // cards estándar
    xl:    '16px',  // cards premium, modals
    pill:  '9999px',
  },

  // Shadow (sutil — no Material Design dramático)
  shadow: {
    none:  'none',
    sm:    '0 1px 2px rgba(0,0,0,0.20)',
    md:    '0 2px 8px rgba(0,0,0,0.25)',
    lg:    '0 8px 24px rgba(0,0,0,0.30)',
    glow:  '0 0 16px rgba(201,161,74,0.25)',  // brass glow para focus premium
    inset: 'inset 0 1px 0 rgba(244,239,230,0.06)', // inner highlight cards navy
  },

  // Typography (referencia §4 + §11.4)
  font: {
    display: '"Cormorant Garamond", "Times New Roman", serif',
    body:    '"Inter", -apple-system, "Segoe UI", sans-serif',
    mono:    '"JetBrains Mono", "Cascadia Code", monospace',
  },

  fontSize: {
    'display-lg': '48px',  // splash, headers ceremoniales
    'display-md': '32px',  // app titles principales
    'display-sm': '28px',  // section titles
    'body-lg':    '18px',  // párrafo destacado
    'body-md':    '16px',  // body default
    'body-sm':    '14px',  // captions
    'body-xs':    '12px',  // status bar, dock labels
  },

  // Z-index scale
  z: {
    base: 0,
    raised: 10,
    dropdown: 100,
    sticky: 200,
    overlay: 500,
    modal: 1000,
    toast: 2000,
    contextMenu: 3000,
  },

  // Motion (referencia §11.8 motion signature)
  motion: { /* SPEED + SPRING + EASING ya definidos en §11.8 */ },
} as const;
```

> **Lint rule (CI):** ESLint custom rule `admirals/no-magic-color` que falla el build si encuentra hex colors hardcoded en componentes — todos deben venir de `TOKENS.color.*`.

### 12.3 Grid y layout del Tablet

**Resolución canónica del rendertarget:** **1280×800** (16:10).

> Esta es **la única resolución soportada en oleada 1.** El rendertarget se renderiza a esta resolución y se aplica al material del Tablet. No es responsive. Diseñamos píxel-perfect para 1280×800.

**Grid base:**
- **Columnas:** 12 columnas con gutter 16px.
- **Padding global lateral:** 32px.
- **Status bar height:** 28px (top).
- **Dock height:** 72px (bottom).
- **Área de contenido útil:** 1280×700 px (entre status bar y dock).

**Densidad:**
- Touch targets mínimo 44×44px (heredado iOS HIG — válido también para mouse en NUI).
- Lista item height estándar: 56px.
- Lista item compacta: 44px.
- Card padding: 20px (`TOKENS.space[5]`).

### 12.4 Catálogo de componentes (component library Admirals)

> **Cada componente es atomic + composable.** Lista exhaustiva — esto es la materia prima de TODA la NUI Admirals.

#### 12.4.1 Foundations

| Componente | Descripción | Variantes |
|---|---|---|
| **`<Surface>`** | Wrapper base para cualquier zona "elevada". Aplica bg, radius, optional border brass, optional shadow. | `flat` / `raised` / `premium` (border brass + shadow.lg) |
| **`<Stack>`** | Vertical flex con gap token. | gap = `TOKENS.space.*` |
| **`<Inline>`** | Horizontal flex con gap + alineación. | `align="start|center|end"`, `justify="..."` |
| **`<Divider>`** | Separador horizontal/vertical, 1px brass dim. | `subtle` / `accent` (brass solid) |

#### 12.4.2 Tipografía

| Componente | Variant prop | Caso uso |
|---|---|---|
| **`<Display>`** | `lg|md|sm` | App titles, ceremoniales (Cormorant). |
| **`<Heading>`** | `1|2|3` | Sección dentro de app (Inter SemiBold). |
| **`<Text>`** | `lg|md|sm|xs` | Body paragraphs (Inter Regular). |
| **`<Mono>`** | `md|sm|xs` | Datos numéricos (JetBrains). |
| **`<Caption>`** | (single) | Etiquetas debajo de campos, hints. |

#### 12.4.3 Controles de input

| Componente | Estado |
|---|---|
| **`<Button>`** | `primary` (brass fill) / `secondary` (navy mist + brass border) / `ghost` (transparent + brass text) / `danger` (terracotta) / `icon-only` |
| **`<IconButton>`** | Botón solo icono, 40×40 default, 32×32 compact. |
| **`<TextInput>`** | Single-line text, label flotante opcional, validation states. |
| **`<TextArea>`** | Multi-line, auto-resize opcional. |
| **`<Select>`** | Dropdown nativo customizado, brass arrow. |
| **`<Combobox>`** | Searchable select. |
| **`<Checkbox>`** | Brass check, navy box. |
| **`<Radio>`** | Brass dot dentro navy ring. |
| **`<Switch>`** | Toggle físico — track navy mist, thumb brass. Animación spring `confidentControl`. |
| **`<Slider>`** | Track navy, thumb brass con mini-shadow. |
| **`<DatePicker>`** | Calendar inline, mes navy header brass accent en día seleccionado. |
| **`<TimePicker>`** | Wheel-style scroll (estética cronómetro naval). |
| **`<NumberStepper>`** | `−` y `+` brass icon buttons + display Mono central. |
| **`<FileDropzone>`** | Para upload imágenes en marketplace, perfil empresa. |

#### 12.4.4 Display de información

| Componente | Caso uso |
|---|---|
| **`<Card>`** | Contenedor genérico. Variants: `default` / `interactive` (hover lift) / `premium` (border brass). |
| **`<Tile>`** | Card cuadrado / rectangular para grids de apps en home, productos en mercado. |
| **`<Avatar>`** | Foto perfil — round o square. Fallback: monogram. |
| **`<CompanyLogo>`** | Logo empresa renderizado — fallback: shield mono brass + initials. |
| **`<Badge>`** | Pill text pequeño. Semantic: `info|success|warning|danger|brass`. |
| **`<Tag>`** | Similar a badge pero clickable/dismissible. |
| **`<Chip>`** | Filtros activos en mercado. |
| **`<Progress>`** | Linear / circular. Brass fill sobre navy mist track. |
| **`<Stat>`** | Número grande Mono + label Inter sm + delta opcional. |
| **`<DataPoint>`** | Label : valor compacto inline. |
| **`<Timeline>`** | Vertical timeline para histórico (movimientos banco, lineage batch). Brass dots, navy line. |
| **`<KeyValueList>`** | Listado dt/dd, brass labels, ivory values. |
| **`<MetricCard>`** | Card con título + stat principal + delta + spark mini-chart opcional. |

#### 12.4.5 Listas y tablas

| Componente | Notas |
|---|---|
| **`<List>`** | Vertical lista de `<ListItem>`. Soporta dividers automáticos. |
| **`<ListItem>`** | Slot izq (avatar/icon), slot center (title + subtitle), slot der (action/badge/chevron). |
| **`<DataTable>`** | Tabla con columnas configurables. Navy mist header, ivory rows alt sutil 0.02 opacity. Cero zebras agresivas. |
| **`<VirtualList>`** | Para listas >100 items (mensajes, movimientos banco). Library: `@tanstack/virtual`. |
| **`<EmptyState>`** | Cuando lista vacía: ícono brass grande + Cormorant title + Inter description + opcional CTA. |

#### 12.4.6 Navegación

| Componente | Notas |
|---|---|
| **`<AppShell>`** | Layout principal del Tablet — status bar + content + dock. |
| **`<TopBar>`** | Header dentro de cada app — back button + title + action(s). |
| **`<Tabs>`** | Tabs horizontales, brass underline en activo. |
| **`<SegmentedControl>`** | Toggle con 2-4 opciones, similar a iOS — pill brass slide animation. |
| **`<Breadcrumb>`** | `Empresa > Banca > Movimiento #123` — separador "›" brass. |
| **`<Pagination>`** | Compact: `‹ 1 2 3 ›` con brass active. |
| **`<SideNav>`** | Solo en Manager Panel — navy mist sidebar 240px wide. |

#### 12.4.7 Feedback

| Componente | Notas |
|---|---|
| **`<Toast>`** | Slide-in top, navy + brass border, 4s default duration. Variants semantic. |
| **`<Modal>`** | Center-screen, scrim overlay, max-width 560px default. Spring `calmSurface`. |
| **`<Dialog>`** | Modal con confirmación (Sí/No, Aceptar/Cancelar). |
| **`<Drawer>`** | Slide desde el derecho, 480px wide. Para ver detalle sin perder contexto. |
| **`<Banner>`** | Fila ancha en top de app — info/warning/success persistente. |
| **`<Skeleton>`** | Loading placeholder — navy mist con shimmer brass diagonal subtle (animación CSS keyframes). |
| **`<Spinner>`** | Compass-rose girando lentamente (custom — no genérico) — 24/32/48px. |
| **`<Tooltip>`** | Pequeño popover navy + brass border, max 240px wide, 200ms delay. |
| **`<ContextMenu>`** | Right-click menu o long-press en Tablet — navy mist + brass dividers. |

#### 12.4.8 Composiciones específicas Admirals

> **Componentes "high-level" propios que aparecen en muchas apps.**

| Componente | Caso uso |
|---|---|
| **`<DocumentCard>`** | Tile que muestra preview de documento con sello brass + estado (pendiente/firmado). |
| **`<SealStamp>`** | Sello cera brass animado al firmar — ceremonial (`ceremonialReveal` spring). |
| **`<SignaturePad>`** | Canvas para firma digital. |
| **`<MoneyDisplay>`** | Cantidad formateada con currency, color semantic (verde si in, terracotta si out). |
| **`<IBANDisplay>`** | Formato grouped 4-char con copy button brass. |
| **`<BatchCodeDisplay>`** | Código batch Mono + copy + lineage trace icon clickable. |
| **`<QualityBadge>`** | Letra A-E grande dentro circle brass + score numérico. |
| **`<CompanyMemberRow>`** | Avatar + nombre + role pill + actions (kick/promote). |
| **`<ChatBubble>`** | Mensaje texto — propio (brass align-right) / ajeno (navy mist align-left). |
| **`<NotificationItem>`** | Icon priority + title + body trunc + timestamp + actions. |
| **`<MarketListingTile>`** | Foto producto + precio + grade + vendedor + acción. |
| **`<MapPinAdmirals>`** | Pin en mapa Tablet — brass shield + label compacto. |
| **`<ContractPreview>`** | Documento parchment con sellos + partes + cláusulas previsualizadas. |
| **`<TimelineLineage>`** | Visualización lineage de batch (Granja → Molino → cliente). Connections brass. |

### 12.5 Patrones de layout Tablet

> **Cada app del Tablet sigue uno de estos 5 layouts canónicos.** Cero apps inventan layouts propios.

**L1 — Master/Detail (List + Drawer):**
- Lista a la izquierda 360px ancho.
- Drawer derecho 920px ancho con detalle del seleccionado.
- Caso: Banco extracto (lista mov + detail), Mensajes (chat list + chat), Notificaciones.

**L2 — Grid + Filters:**
- Filter bar arriba 56px.
- Grid de tiles flex-wrap con gap 16px.
- Caso: Mercado (listings), Documentos (docs), Empresas browser.

**L3 — Dashboard:**
- Top bar.
- Grid 12-col de cards (`<MetricCard>`, `<Stat>`, `<Chart>`).
- Caso: Dashboard empresa, Manager Panel home.

**L4 — Form/Wizard:**
- Top bar con stepper opcional.
- Form vertical centrado max-width 720px.
- Acciones bottom sticky (Cancel + Continuar).
- Caso: Crear empresa, Crear oferta mercado, Onboarding.

**L5 — Full-canvas (Mapa, Pizarra):**
- Sin padding.
- Toolbar flotante glass tint.
- Caso: App Mapa, Pizarra interna empresa, Photo viewer.

### 12.6 Patrones de interacción canónicos

| Patrón | Comportamiento |
|---|---|
| **App switch** | Swipe horizontal con dock visible o tap en dock — `confidentControl` spring, slide x. |
| **Drawer detail open** | Click ListItem → Drawer slide-in derecha 480px — `calmSurface` spring. |
| **Modal confirmación** | Click acción crítica → Dialog center con scrim — `calmSurface` + scrim fade-in 200ms. |
| **Inline edit** | Doble-click texto → input edit con border brass. ESC cancela. ENTER confirma. |
| **Search ubiquitous** | `Ctrl+K` o tap search icon top → spotlight overlay con palette brass border. |
| **Pull to refresh** | Gesto drag down en listas — appears compass rose spinning brass. |
| **Long-press context** | 600ms hold → context menu aparece en posición. Vibration sutil (sound `tablet_long_press_haptic`). |
| **Multi-select listas** | Long-press primer item activa modo selección, checkboxes aparecen, top-bar cambia a action mode. |

### 12.7 Estados de componentes (state matrix)

> **Cada componente interactivo tiene los siguientes estados visuales obligatorios.** Si falta uno, el componente NO está completo.

| Estado | Treatment visual |
|---|---|
| **Default** | Token base. |
| **Hover** | brass dim border 0.30 alpha + shadow.sm. |
| **Focus** | brass solid 2px outline + shadow.glow. (Visible siempre — accesibilidad keyboard). |
| **Active/Press** | brass press color + scale 0.98 (spring `confidentControl`). |
| **Disabled** | opacity 0.4, cursor not-allowed. |
| **Loading** | Skeleton shimmer o Spinner inline. |
| **Error** | border terracotta + caption error con icon. |
| **Success** | Brass check inline + toast confirm. |
| **Empty** | `<EmptyState>` con CTA opcional. |

### 12.8 Light mode (alternativo)

> **Modo light existe pero no es default.** Pensado para sesiones diurnas largas o preferencia personal.

**Diferencias clave:**
- Background: `#F4EFE6` Ivory base, cards white, navy → ivory-on-navy invertido en chips/badges.
- Texto principal: `#0A2A47` Navy.
- Brass mantiene mismo hex `#C9A14A` (funciona en ambos modos — testado).
- Shadows: más suaves (color black con menos alpha).
- **Logo** y headers ceremoniales: navy color en lugar de ivory.

> **Switch:** ajuste en App "Configuración" — toggle persistente en `admirals_settings_per_account` (DB §11). Transición suave 400ms cross-fade entre temas (no instant flash).

### 12.9 Responsive interna (zoom assist)

> **El rendertarget es 1280×800 fijo, pero el OS soporta `zoom level`** (Configuración → Pantalla → Tamaño de texto: Small | Medium | Large) para accesibilidad.

| Nivel | Multiplier base font | Comportamiento |
|---|---|---|
| Small | 0.875× | Densidad alta — power users. |
| **Medium (default)** | 1.0× | Standard. |
| Large | 1.125× | Texto más grande, padding cards aumenta proporcional. |

> Implementación: variable CSS `--admirals-zoom: 1.0` en root, todos los font-sizes en `calc(var(--admirals-zoom) * <value>)`.

### 12.10 Accesibilidad (a11y mínimo)

| Aspecto | Requisito |
|---|---|
| **Contrast ratio** | ≥ 4.5:1 body, ≥ 3:1 large text. CI lint con `axe-core`. |
| **Focus states** | Visibles SIEMPRE — brass 2px outline + shadow.glow. |
| **Keyboard navigation** | Tab order lógico, ESC cierra modals, ENTER confirma forms. |
| **ARIA labels** | Todos los IconButton tienen `aria-label`. |
| **Reduced motion** | `prefers-reduced-motion` detect → simplifica springs a fades 200ms. |
| **Screen reader** | Roles ARIA correctos en List, Tabs, Modal, etc. |

### 12.11 Component governance

- **Storybook obligatorio:** cada componente tiene su `.stories.tsx` con todas las variantes y estados.
- **Visual regression:** Chromatic / Playwright snapshot por componente — un PR que cambie pixels requiere review explícito.
- **Versionado:** componentes versionados con semver. Breaking change → mayor.
- **No fork:** ningún resource node puede forkear componentes. Si necesita variante, se añade al design system central.
- **Naming:** `Admirals` namespace en exports si hay risk de colisión con libs externas (`AdmiralsButton`, `AdmiralsCard` opcional).

---

## 13. Partículas y FX (code-driven)

> **Bible §13.4:** los modelos 3D no traen partículas builtin. Las partículas son **100% código** — emisores Lua client-side llamando a natives FiveM (`StartParticleFxLoopedAtCoord`, `StartParticleFxNonLoopedAtCoord`) con dicts canónicos GTA + dicts custom Admirals limitados.

### 13.1 Filosofía de partículas Admirals

| Principio | Aplicación |
|---|---|
| **Sutiles, no carnaval** | Una partícula bien usada vale por 50 mal usadas. Cero efectos "festival de fuegos artificiales". |
| **Físicamente plausible** | Polvo va donde hay polvo, vapor donde hay calor, niebla donde hay humedad. Nunca por estética sola. |
| **Performance budget** | Total partículas activas concurrentes per cliente ≤ 200. Throttling agresivo si distancia > 30m. |
| **Dicts canónicos** | Reusar `core`, `core_snow`, `proj_indep_firework`, `scr_*` dicts GTA. Custom dicts Admirals solo si imposible reusar. |
| **Sincronizadas con sound** | Cada efecto particle relevante tiene su sound layer. Polvo silencioso = mal diseño. |

### 13.2 Catálogo de FX por nodo (resumen)

#### 13.2.1 Granja FX

| FX ID | Trigger | Dict | Detalle |
|---|---|---|---|
| `granja_fx_dust_field` | Player camina sobre parcela seca | `core` / `ent_anim_paper_dust` | Polvo bajo pies, 0.5s burst, 0.3 alpha. |
| `granja_fx_dust_tractor` | Tractor moving en terrain dirt | custom `admirals_granja` o `scr_re_yacht_attack` adapted | Trail de polvo detrás de tractor, looped mientras se mueve. |
| `granja_fx_water_irrigation` | Aspersor activo regando | `core_snow` (water particles) o native water spray | Spray de agua en arco, sound layer `granja_irrigation_loop`. |
| `granja_fx_steam_morning` | Amanecer + parcela húmeda + temperatura templada | `core` ground steam | Vapor sutil de tierra, max 30s tras amanecer. |
| `granja_fx_seed_drop` | Action sembrar | `core` light dust + sound `granja_seed_drop` | Mini burst de semillas (visual abstract — no semilla individual). |
| `granja_fx_pest_swarm` | Plot infectado plaga | custom `admirals_granja` `pest_flies` | Pequeño enjambre flies sobre la parcela visible si distancia <15m. |
| `granja_fx_harvest_chaff` | Cosechadora trabajando | `scr_re_yacht_attack` chaff adapted | Paja saliendo por trasera de la cosechadora, looped. |
| `granja_fx_silo_fill` | Vertiendo grano en silo | `core` dust + grain visual | Polvo sale por la tapa del silo durante carga. |

#### 13.2.2 Molino FX

| FX ID | Trigger | Dict | Detalle |
|---|---|---|---|
| `molino_fx_flour_dust_ambient` | Ambiente sala molienda activa | `core` flour dust subtle | Motas de harina suspendidas en aire, visible en haces de luz. Performance: muy bajo emit rate. |
| `molino_fx_flour_burst_pour` | Acción rellenar saco harina | `core` dust + bag impact | Burst breve de harina cuando cae al saco. |
| `molino_fx_steam_engine` | Máquina rodillos working | `scr_carsteal4_wheel_burnout` adapted vapor | Vapor saliendo de tubería superior — looped. |
| `molino_fx_sparks_grinding` | Piedra molinera contra grano (raro, error de calibración) | `core` sparks | Solo en estado error/maintenance. |
| `molino_fx_packaging_belt_dust` | Cinta transportadora moviendo sacos | low `core` dust | Polvo sutil bajo la cinta. |

#### 13.2.3 Tablet FX (NUI-side, no world)

> **Las partículas del Tablet son DOM/Canvas, no FiveM particles.** Implementación: `framer-motion` particles + canvas para confetti/seal-burst.

| FX ID | Trigger | Implementación |
|---|---|---|
| `tablet_fx_seal_dust` | Aplicación de sello de cera al firmar doc | Canvas — polvo brass que cae 600ms tras stamp. |
| `tablet_fx_money_in` | Recepción de transferencia | Sutil brass particle burst desde icono money + sound. |
| `tablet_fx_compass_glow` | Splash apertura + transiciones home | Glow pulse brass alrededor del compass-rose. |
| `tablet_fx_notification_pop` | Notif crítica entrante | Tile vibrate + brass spark micro 200ms. |
| `tablet_fx_loading_compass` | Spinner large (carga lenta >2s) | Compass rose girando lentamente con trail brass. |

#### 13.2.4 Banca / Documento FX (3D world side cuando aparece)

| FX ID | Trigger | Detalle |
|---|---|---|
| `bank_fx_atm_paper` | Sacar dinero ATM in-world | Pequeño billete papel cae 1s + sound `bank_paper_print`. |
| `doc_fx_seal_world` | Notario in-world aplicando sello | Mini puff de humo cera 0.3s + sound `doc_seal_burn`. |

### 13.3 Pipeline técnico de partículas

```
[ Evento gameplay ]
        │
        ▼
[ admirals_<node>:fx:trigger ] (event bus interno cliente)
        │
        ▼
[ admirals_fx (resource client-only) ]
   │
   ├─ Lookup en `fx_catalog.lua` (FX ID → dict + name + params)
   ├─ Verifica budget global (≤200 active)
   ├─ Verifica distancia player ↔ origin (cull > 30m)
   ├─ Llama native `StartParticleFxLoopedAtCoord` o `StartParticleFxNonLoopedAtCoord`
   └─ Sound layer paralelo (PlaySoundFromCoord o pma-voice positional)
```

> **Resource único `admirals_fx`** centraliza el catálogo. Nodos NO llaman natives directamente — solo emiten `admirals_fx:trigger` con FX ID. Ventaja: budget global controlado, fácil mute por debug, fácil A/B.

### 13.4 Performance budget partículas

| Nivel | Concurrent FX cap | Cull distance |
|---|---|---|
| Low (PC modesto) | 80 | 20m |
| Medium (default) | 200 | 30m |
| High (powerful PC) | 350 | 50m |

> **Detect automático** basado en FPS rolling avg primeros 30s de sesión. Player puede override en Configuración → Rendimiento.

---

## 14. Lighting, post-FX y atmósfera (code-driven)

> **Bible §13.4:** los MLOs y models 3D entregan **geometría + materiales base**. Toda la atmósfera (lighting dinámico, time-of-day reaction, post-processing, fog, color grading) es **código**.

### 14.1 Filosofía de lighting Admirals

| Principio | Aplicación |
|---|---|
| **Lighting cuenta historias** | Granja se ve cálida al atardecer; Molino tiene haces polvorientos cinemáticos; Tablet Office es neutra y profesional. |
| **Time-of-day awareness** | Cada zona reacciona a hora del día — luces interiores se encienden auto al anochecer, ambient cambia. |
| **Cero "luces irreales"** | Cero luces flotando sin fuente. Cada light tiene su lámpara/ventana/farol justificada. |
| **Performance: forward+ baked when possible** | GTA V renderer es lo que es. Code añade light entities con criterio (max 8 dynamic lights por interior). |
| **Post-FX sutil siempre** | Cero LUTs de "estética Instagram". Color grading delicado con propósito narrativo. |

### 14.2 Sistema de zonas atmosféricas (`admirals_atmosphere`)

> Resource client-only que **registra zonas** y aplica perfiles atmosféricos contextuales.

```lua
-- admirals_atmosphere/client/zones.lua

local ATMOSPHERE_ZONES = {
  {
    id = 'granja_field_outdoor',
    type = 'sphere',
    coords = vec3(2400, 4800, 35),
    radius = 250,
    profile = 'granja_outdoor_pastoral',
  },
  {
    id = 'granja_warehouse_interior',
    type = 'box',
    bounds = { ... },
    profile = 'granja_warehouse_dim',
  },
  {
    id = 'molino_grinding_room',
    type = 'box',
    bounds = { ... },
    profile = 'molino_industrial_dusty',
  },
  -- ...
}

local PROFILES = {
  granja_outdoor_pastoral = {
    timecycle_modifier = 'admirals_pastoral',  -- timecycle custom registrado
    ambient_volume = 'granja_field_amb',
    fog = { density = 0.02, color = vec3(0.95, 0.92, 0.85) },  -- niebla cálida sutil
    bloom = 0.15,
    sun_intensity_multiplier = 1.05,
  },
  granja_warehouse_dim = {
    timecycle_modifier = 'admirals_warehouse_warm',
    ambient_volume = 'granja_warehouse_amb',
    interior_lights = {
      { coords = vec3(...), color = {255,200,140}, intensity = 8, range = 12 },
      -- ...
    },
    fog = { density = 0.05, color = vec3(0.9, 0.8, 0.6) },
    bloom = 0.3,
    -- 3 haces godrays code-driven via DRAW_VOLUMETRIC_LIGHT en zonas marcadas
    godrays = {
      { from = vec3(...), dir = vec3(...), intensity = 0.6, color = vec3(1,0.9,0.7) },
    },
  },
  molino_industrial_dusty = {
    timecycle_modifier = 'admirals_industrial',
    ambient_volume = 'molino_grinding_amb',
    interior_lights = { ... },
    fog = { density = 0.08, color = vec3(0.95, 0.92, 0.82) },  -- "polvo en aire"
    particles = 'molino_fx_flour_dust_ambient',  -- emisión continua flour dust
    bloom = 0.25,
    godrays = { ... },
    contrast_multiplier = 1.05,
  },
  tablet_office_neutral = {
    -- cuando estás cerca del Tablet abierto, push leve de neutralidad
    color_grade = 'neutral_admirals',
    saturation_multiplier = 0.95,
  },
}
```

> **Detección zona:** cron 500ms revisa coords del player vs zonas registradas, aplica/quita profile con cross-fade 1500ms (no flash). Multi-zona: priority numeric, mayor gana.

### 14.3 Timecycles modifiers Admirals

> **GTA V timecycle modifiers** son la herramienta canónica para cambiar look-and-feel. Registramos los nuestros (custom) usando `timecycle_modifier_table.xml` empaquetados en stream.

| Modifier ID | Caracter visual |
|---|---|
| `admirals_pastoral` | Granja exterior — tibieza ámbar, niebla cálida sutil, sun warmth +5%. Atmósfera "tarde de campo". |
| `admirals_warehouse_warm` | Almacén granja — penumbra ámbar, contraste medio, vignette sutil. |
| `admirals_industrial` | Molino — gris polvoriento, contraste alto, vignette más fuerte, color desat -10%. |
| `admirals_neutral` | Default Admirals fallback — minimal modifier, casi imperceptible. |
| `admirals_ceremonial` | Splash apertura del Tablet, eventos firma de contrato grande (modal world-stop) — slight bloom + warmth + soft vignette. |

### 14.4 Lights interiores (point lights code-side)

> **MLOs entregan `coords` de cada lámpara.** Code añade el `point light` real con color, intensidad, rango.

```lua
-- ejemplo: encender lámparas de un interior cuando es de noche
function ApplyInteriorLights(zone)
  local hour = GetClockHours()
  if hour >= 19 or hour <= 6 then
    for _, light in ipairs(zone.interior_lights) do
      DrawLightWithRange(
        light.coords,
        light.color[1], light.color[2], light.color[3],
        light.range,
        light.intensity
      )
    end
  end
end
```

> **Iteración por frame:** sí, las point lights se redibujan cada frame con `DrawLightWithRange`. Performance: ≤8 lights por interior visible. Si player está fuera del interior, NO se dibujan.

### 14.5 Color grading & post-FX

> **Pipeline post-procesado Admirals:**

```
[ raw scene ] → [ timecycle_modifier ] → [ admirals_color_grade ] → [ admirals_bloom ] → [ admirals_vignette ] → [ output ]
```

| Pass | Implementación FiveM | Notas |
|---|---|---|
| **Color grade** | timecycle modifier `posfx_*` + LUT scrip (`SetTimecycleModifier`) | LUT artistically-tuned por zona. Subtle — desat ≤5%, contrast ≤+5%. |
| **Bloom** | timecycle modifier `bloom_*` parameters | Per-profile. Más bloom en Molino dusty, menos en exterior pastoral. |
| **Vignette** | timecycle modifier `vignet*` parameters | Sutil siempre. +0.10 en interiores premium (Tablet en mano, contratos firma). |
| **Chromatic aberration** | `_SET_TIMECYCLE_MODIFIER_STRENGTH` con timecycle especial | **Solo** en momentos ceremoniales muy puntuales (firma de contrato gran valor) — 0.5s pulse. |
| **Letterbox cinemático** | Native `DRAW_RECT` top + bottom black bars | Solo en cinemáticas onboarding y cinemática contratos premium. Toggle controlado por code. |

> **Anti-pattern:** cero "Instagram filter" siempre activo. El post-FX **respira** — entra y sale con narrativa.

### 14.6 Ambient sound layers

> Cada profile atmosphere tiene `ambient_volume` — clip de ambient loop posicional 3D.

| Volume ID | Composición sonora |
|---|---|
| `granja_field_amb` | Wind-through-wheat layer + birds occasional + distant tractor very faint. Loop 60s seamless. |
| `granja_warehouse_amb` | Hollow wooden creaks + distant farm sounds + occasional grain settling. Loop 90s. |
| `molino_grinding_amb` | Mechanical low rumble + distant gear metal + occasional steam hiss. Loop 60s. |
| `tablet_office_amb` | Silencio casi total + occasional paper rustle + brass click far. Loop 45s. |

> Audio engine: `pma-voice` o `xsound` para 3D positional. Volumen base 0.3 (background). Ducking automático cuando hay diálogo voice prominente.

### 14.7 Weather reactivity

| Clima | Reacciones por nodo |
|---|---|
| Lluvia | Granja: parcelas se humedecen visualmente (shader switch dry→wet — 3D entrega ambos states); irrigation_score se incrementa pasivamente. Molino: gotera animada en ventana específica del techo (FX). Tablet: cero impacto. |
| Niebla densa | Granja exterior: visibility reduce, lighting de farolas se enciende antes. Molino: cero impacto interior. |
| Nieve | (Si se introduce algún día — fuera oleada 1) parcelas con coverage de nieve, funcionalidad cosecha pausada. |
| Tormenta | SFX truenos audibles con leve flash global. Cero impacto gameplay oleada 1. |

### 14.8 Lighting ceremonial moments

> **Momentos donde la atmósfera "se detiene" para narrar.**

| Momento | Treatment |
|---|---|
| **Firma de contrato premium** (>50.000$) | World blur background, vignette +0.20, slight zoom-in cinemático, bloom +0.15, sound: scratching de pluma + sello cera. Duración 2.5s. |
| **Aplicación de sello en doc Tablet** | NUI: scrim aparece, doc se centra, sello cae con `ceremonialReveal` spring, brass dust particle, sound `tablet_seal_apply`. Duración 1.2s. |
| **Cosecha completada exitosa Grade A+** | Al cerrar la operación: brass shimmer subtle del Tablet en mano + sound double-bell. Duración 0.8s. |
| **Login fresh** (primer login del día del player) | Splash Tablet 1.5s con compass rose girando + sound de campana + texto "Buenos días, Capitán {Apellido}". |

---

## 15. Materiales en mundo — split 3D vs Código

> **La regla de oro Bible §13.4** aplicada a materiales:
> - **3D entrega:** la geometría + el material base (texturas albedo, normal, roughness, metallic) horneado en YTD/YDR/YMAP.
> - **Código entrega:** el shimmer dinámico — variaciones de estado (mojado/seco, lleno/vacío, encendido/apagado), reflexiones contextuales, animation de uniforms (flow, pulse), y todo lo que cambia con gameplay.

### 15.1 Capas materiales Admirals

> Cada material en mundo tiene hasta **5 capas** repartidas entre 3D y código:

| Capa | Owner | Ejemplo Granja |
|---|---|---|
| **L1 — Geometría base** | 3D | Mesh del silo de madera. |
| **L2 — Texture base set** (albedo / normal / roughness / metallic) | 3D | Madera envejecida, anillos visibles, clavos oxidados. |
| **L3 — Variants estáticos** | 3D | Versión limpia + versión sucia + versión muy desgastada (3 variantes pre-bakeadas, código elige cuál mostrar). |
| **L4 — Shimmer dinámico shader uniforms** | Código | Wetness multiplier, fill level shader (silo bajo→alto), light intensity de lámpara, dust accumulation overlay. |
| **L5 — FX overlay** | Código | Partículas que se montan ENCIMA del material (polvo, vapor, agua) — §13. |

> **3D nunca toca L4-L5.** Código nunca toca L1-L3. Si un asset necesita comportamiento dinámico, **3D entrega los uniforms shader expuestos** y el código los modula.

### 15.2 Catálogo de uniforms shader expuestos (contrato 3D ↔ Código)

> Cada material custom Admirals declara qué uniforms ofrece al código. Esta tabla es **el contrato**.

| Material | Uniforms expuestos | Range / Type | Owner código |
|---|---|---|---|
| `mat_admirals_field_soil` | `wetness` | float 0.0–1.0 | `admirals_granja_visuals` |
|  | `fertility` | float 0.0–1.0 | id. |
|  | `dust_overlay` | float 0.0–1.0 | id. |
| `mat_admirals_silo_wood` | `fill_level` | float 0.0–1.0 (controla shader band height) | `admirals_granja_visuals` |
|  | `weather_grime` | float 0.0–1.0 | id. |
| `mat_admirals_mill_metal` | `temperature_glow` | float 0.0–1.0 (calor en piezas operando) | `admirals_molino_visuals` |
|  | `flour_dust_layer` | float 0.0–1.0 | id. |
| `mat_admirals_lamp_brass` | `emissive_intensity` | float 0.0–10.0 | `admirals_atmosphere` |
| `mat_admirals_tablet_glass` | `screen_emission` | float 0.0–1.0 (Tablet en mano apagado/encendido) | `admirals_tablet` |
|  | `glass_smudge` | float 0.0–0.3 | id. |
| `mat_admirals_paper_doc` | `wax_seal_present` | bool | `admirals_documents` |
|  | `wear` | float 0.0–1.0 | id. |
| `mat_admirals_crop_wheat` | `growth_stage` | float 0.0–1.0 (planta crece visible) | `admirals_granja_visuals` |
|  | `quality_color_shift` | vec3 (color subtle desat si calidad baja) | id. |

> **Documentación viva:** este catálogo está en `docs/art/02_shader_contracts.md` (a crear) — **cada nuevo material custom DEBE registrar sus uniforms ahí antes de mergear el asset.**

### 15.3 Pipeline asset 3D → game

```
[Blender / Maya — modelado + UVs + texture bake]
        │
        ▼
[Substance Painter — texture authoring (albedo/normal/rough/metal)]
        │
        ▼
[Custom shader Admirals — añade uniforms expuestos]
        │
        ▼
[Export YDR/YDD + YTD]
        │
        ▼
[stream/ folder de resource correspondiente]
        │
        ▼
[Code lee uniforms vía native FiveM / shader API y modula]
```

### 15.4 Texture authoring guidelines

| Aspecto | Estándar Admirals |
|---|---|
| **Resolución** | 2048×2048 default. 4096 solo en hero props (Tablet, sello notario, cosechadora). 1024 para props pequeños/lejanos. |
| **Albedo** | Color base físicamente plausible (PBR-correct values, ej. madera envejecida 0.18–0.25 luminance). Cero saturación high. |
| **Normal map** | Tangent space, OpenGL Y+ convention. Detalle físico real (vetas madera, golpes metal, costuras tela). |
| **Roughness** | Variación importante. Cero superficies "uniform plastic". |
| **Metallic** | Solo donde hay metal real. Brass = 1.0 metallic + roughness 0.35. |
| **Emissive** | Solo en lámparas, pantalla Tablet, sellos brass cuando glow ceremonial. Modulado por código. |
| **Wear & tear** | Cada hero prop tiene **wear pass** sutil — golpes, manchas, oxidación leve. Materiales nuevos = mal diseño. |

### 15.5 Reglas anti-pattern materiales

| ❌ NO | ✅ SÍ |
|---|---|
| Texturas stock CC0 sin retoque | Textures pasadas por curaduría — al menos retoque + grading en Substance |
| Roughness flat 0.5 en todo | Roughness variado (mín 0.10, máx 0.95) por material |
| Normal maps muy ruidosos | Normal con propósito — vetas reales, no noise procedural genérico |
| Albedo saturado +130% | Albedo PBR-correct, saturación naval clásica (sutil) |
| Materiales sin wear | Todos con wear pass mínimo |
| Animación de UV "flow" como si todo fuera lava | Solo donde hay flujo real (agua canalón, vapor tubería) |

---

## 16. Escenografía MLOs — narrativa de espacio

> **Un MLO no es un asset. Es un escenario.** Cada interior cuenta una historia mediante props deliberados, sin sobrecargar (Bible: ≤25 assets per node oleada 1, deco-props no cuentan dentro de ese límite si son **nativos GTA** reposicionados).

### 16.1 Filosofía de escenografía Admirals

| Principio | Aplicación |
|---|---|
| **Cada habitación responde a un porqué** | El despacho del cooperativa Granja tiene mapas porque el dueño coordina cosecha, no porque "queda bien". |
| **3 capas por interior:** essentials + narrative + delight | Essentials (gameplay), narrative (storytelling), delight (micro-detail wow). |
| **Reusar nativos GTA siempre que sea posible** | Sillas, mesas, libros nativas GTA reposicionadas es 90% del decor. Custom solo donde el wow lo justifica. |
| **Iluminación natural cuando posible** | Ventanas grandes hacia el exterior — sun rays naturales son mejores que farolas baratas. |
| **Cero clutter aleatorio** | Si pones 20 papeles en una mesa, esos 20 papeles cuentan algo. Si no, quita 18. |

### 16.2 Sistema de capas escenográficas (per MLO)

| Capa | Tipo | Owner |
|---|---|---|
| **C1 — Estructural** (paredes, suelo, techo, ventanas) | Asset MLO 3D | 3D |
| **C2 — Mobiliario funcional** (mesas, sillas, mostrador, bóveda) | Nativos GTA reposicionados | Designer escenografía |
| **C3 — Props narrativos** (mapas, pizarras, cajas, sacos) | Mix nativos + 1-3 custom hero | Designer + 3D |
| **C4 — Hero prop** (1 por sala — la pieza memorable) | Custom 3D Admirals | 3D |
| **C5 — Iluminación + atmósfera** | Code-side (§14) | Code |

### 16.3 Escenografía Granja

> **Story:** "Una cooperativa rural española de los años 70 que se modernizó conservando el alma."

**Cooperativa office (interior principal):**
- C2: Mesa de roble grande central + 4 sillas + mostrador con caja registradora vintage.
- C3: Mapa de la región pinned con chinchetas brass marcando parcelas activas. Pizarra con calendario cosecha. Sacos de muestra apoyados pared. Báscula vieja de hierro decorando esquina. Reloj de pared circular con manillas brass. Estante con frascos de semilla etiquetados.
- C4 (hero): **Maqueta a escala de la región Granja** sobre mesa lateral — 60×60cm de extensión, parcelas miniatura, pequeños silos, río — visible al entrar. **Wow detail.**
- C5: Sun rays por ventana grande hacia el oeste, lighting cálido al atardecer.

**Almacén granos (interior conexo):**
- C2: Estanterías metálicas industriales nativas GTA con sacos.
- C3: Sacos apilados en geometría cuidada, pala apoyada, carretilla de mano, inventario clipboard colgando de gancho.
- C4 (hero): **Báscula industrial grande** en el centro — donde se pesa el grano antes de ir a silo. Mecanismo brass visible.
- C5: Single bombilla colgante con haz visible (godray code), penumbra controlada.

**Greenhouses:**
- C2: Mesas de cultivo nativas + bancos.
- C3: Macetas con plantas en distintos stages (3D entrega stages diferentes pre-bakeados, código elige stage según gameplay), regaderas, herramientas colgando de pegboard.
- C4 (hero): **Sistema de irrigación con tuberías brass + medidores de presión** corriendo por el techo — material `mat_admirals_lamp_brass` con uniforms + agua animada code-side.

### 16.4 Escenografía Molino

> **Story:** "Una vieja fábrica industrial heredada, donde el maestro molinero todavía supervisa cada batch a mano."

**Sala de molienda principal:**
- C2: Mostrador de control con palancas vintage + banco trabajador + escalera metálica al altillo.
- C3: Sacos llenos apilados, balanzas de precisión, cuaderno de batch abierto sobre mostrador con pluma, reloj fichador, pizarra con turno actual escrito en tiza.
- C4 (hero): **Los 2 rodillos molineros** (ya en Bible) — pieza central con piedra circular masiva, transmisión de correas brass visible, vapor saliendo por arriba (FX code).
- C5: Industrial lighting con haces dust-filled (godrays + flour particles).

**Despacho del maestro molinero:**
- C2: Escritorio de madera oscura + sillón de cuero envejecido + librería pared.
- C3: Diplomas y certificaciones colgados pared, fotos antiguas del molino, ábaco tradicional, archivo metálico vintage.
- C4 (hero): **Reloj de pie tipo cronómetro naval** (link a la Almirantazgo metáfora) — péndulo brass animado code-side.
- C5: Lámpara de mesa banker green-shade brass, lighting íntimo.

**Almacén producto terminado:**
- C2: Estanterías metálicas industriales con producto empacado.
- C3: Cajas etiquetadas con destino, paletas de madera, transpaleta, plástico film en rollo.
- C4 (hero): **Cinta transportadora funcional** que mueve sacos hacia la zona de carga camiones — animación looped + sound `molino_belt_loop`.

### 16.5 Escenografía Banca (preview oleada 1)

> **Story:** "Una banca histórica con aires de Banco de España + private banking premium."

**Lobby principal:**
- C2: Mostradores de mármol + bancos espera + columnas estilo neoclásico (nativos GTA).
- C3: Lámparas brass colgantes, alfombra patrón naval, plantas grandes en macetas de bronce.
- C4 (hero): **Compass-rose patterning en suelo** — diseño grande embebido en el mármol del lobby. Visible al entrar. Wow moment.
- C5: Ventanas altas con luz natural filtrada, color grade casi neutro premium.

**Sala de cajas / mostrador empleados:**
- Mostrador con tres ventanillas, vidrios brass-framed, cubículos detrás con sillas oficina premium nativos.

**Despacho privado (firma de contratos premium):**
- C2: Mesa de reuniones grande de madera noble + 6 sillones de cuero.
- C3: Cuadros con marina clásica colgados pared, decanter de cristal con copas brass.
- C4 (hero): **Sello notarial de bronce + cera** sobre mesa — usado en cinemática firma contrato premium (§14.8).
- C5: Lighting cinemático con vignette sutil, ambient `silence_premium`.

### 16.6 Escenografía Tablet (no MLO — pero "escenario en mano")

> El Tablet **es un escenario en sí** — pero portátil. La escenografía aquí es **el rendertarget NUI** + el modelo 3D del chasis.

- Chasis 3D ya descrito §11.3.
- Cuando el player **lo deja sobre una mesa** (no en mano), permanece visible en world con `screen_emission` uniform a 0 (apagado) o > 0 si hay notif activa pulsando.
- Detalle: si hay notificación crítica pendiente, el LED brass del lateral del Tablet **parpadea sutilmente** aún cuando está bloqueado — emissive uniform pulsando. **Wow detail.**

### 16.7 Deco-budget per MLO (oleada 1)

| MLO | Custom hero props (C4) | Native props reposicionados (C2-C3) | Total custom Admirals |
|---|---|---|---|
| Granja Cooperativa | 1 (maqueta) | ~50 | 1 |
| Granja Almacén | 1 (báscula industrial) | ~30 | 1 |
| Granja Greenhouse | 1 (irrigación brass) | ~25 | 1 |
| Molino Sala molienda | 1 (rodillos — ya counted en Bible §13.4) | ~40 | 0 (reusa hero asset Molino) |
| Molino Despacho | 1 (reloj cronómetro) | ~25 | 1 |
| Molino Almacén | 1 (cinta transportadora) | ~35 | 1 |
| Banca Lobby | 1 (compass-rose suelo) | ~50 | 1 |
| Banca Despacho | 1 (sello notarial) | ~30 | 1 |
| **Total custom hero props oleada 1** | | | **7** |

> **Suma controlada:** 7 hero props custom + assets gameplay nodos (≤25 per nodo Bible) = total custom 3D oleada 1 ≈ **70 piezas**. Manejable para un equipo 3D pequeño.

---

## 17. Marketing visual — la batalla por la percepción de marca ⭐

> **Esta sección es crítica.** 17 Movement y 0Resmon ya tienen presencia consolidada en FiveM. Tenemos que **superarlos en percepción** desde el día 1 — antes de que el primer admin instale el script. La calidad técnica es necesaria pero no suficiente. **El marketing es donde se gana la batalla.**

> **Tesis central de marketing Admirals:** ellos venden **scripts**. Nosotros vendemos **una casa de comercio**. Cuando un admin entra a nuestra Tebex, no debe sentir que está viendo un asset; debe sentir que está siendo enrolado en una **flota mercantil del siglo XIX modernizada**.

### 17.1 Análisis competitivo de presencia visual

> **Estudio honesto de la competencia para superarlos consciente.**

| Touchpoint | 17 Movement | 0Resmon | **Admirals (objetivo)** |
|---|---|---|---|
| **Tebex page hero** | Banner texto + screenshot UI dark | Banner ilustración minimal + UI clean | **Cinematic hero video loop 6s + tagline Cormorant + CTA brass** |
| **Screenshots quantity** | ~10 caps UI directos | ~12 caps composiciones limpia | **30+ caps producidos:** UI hero shots + scenes in-world + macro detail shots + composiciones marketing |
| **Trailer** | 60-90s features highlight | 90s smooth product demo | **2-3min cinemático narrativo + 30s teaser + 60s feature highlight** (3 deliverables) |
| **Discord presencia** | Active soporte focus | Active comunidad | **Active + dev blog posts + insider community para subscribers** |
| **Web propia** | Landing simple | Landing bonita pero genérica | **Web de Studio multi-página estilo casa editorial naval — único en el espacio** |
| **Documentación** | GitBook estándar | Docs site clean | **Docs como libro maestro — Cormorant + parchment subtle, lectura placentera** |
| **Voz de marca** | "We move products" | "We make tools" | **"Coordinamos tu flota comercial. Te enrolas con la Almirantazgo."** Storytelling > features |
| **Screenshots gameplay** | Foco en UI tablet | Foco en UI productividad | **50/50 UI + escenas in-world cinematográficas con lighting Admirals §14** |
| **Update reveals** | Patch notes formato técnico | Changelog clean | **"Bitácora del Capitán" — devblog narrativo con renders + concepts + decisiones** |

### 17.2 Tebex Store page — anatomía completa

> **La Tebex page es nuestro "puerto comercial"** — donde el admin desconocido decide si embarca con nosotros. Cada elemento está diseñado.

#### 17.2.1 Above-the-fold (primer scroll)

```
┌───────────────────────────────────────────────────────────────┐
│  [HERO VIDEO LOOP 6s — autoplay muted]                        │
│  · Open: Tablet en mano de Capitán (cámara cinemática)        │
│  · Mid: Tablet desbloquea, compass-rose splash                │
│  · Close: zoom out, vista de Granja al atardecer + texto      │
│                                                               │
│  ┌──────────────────────────────────┐                         │
│  │  ADMIRALS                        │  ← Cormorant SemiBold 80px
│  │  La Almirantazgo de tu servidor  │  ← Inter Light 24px
│  │                                  │                         │
│  │  [▶ Ver trailer]  [📦 Comprar]   │  ← CTAs brass
│  └──────────────────────────────────┘                         │
│                                                               │
│  Disponible: One-time · Licencia anual · Suscripción mensual  │
└───────────────────────────────────────────────────────────────┘
```

**Especificaciones:**
- Hero video: 1920×1080, 6s loop seamless, ≤4MB (heavy compression mantenida fidelidad), MP4 H.264, mute autoplay.
- Tipografía: Cormorant SemiBold 80px (hero name) + Cormorant Italic 32px (subtitle) + Inter Light 18px (tagline tertiary).
- Color: navy `#0A2A47` base + brass `#C9A14A` para CTAs y subrayados.
- CTAs: brass fill primary "Comprar" + ghost brass "Ver trailer". Hover: lift 2px + shadow.glow.

#### 17.2.2 Sección "Por qué Admirals" (segundo scroll)

> **3 promesas grandes** con icono custom + heading Cormorant + body Inter:

- **⚓ Cadena Real** — "Granja → Molino → Pan → Mesa. Cada eslabón físicamente trazable."
- **📜 Detalle Obsesivo** — "Cada parcela tiene humedad, fertilidad, historia. Cada batch firma su lineage."
- **📱 La Tablet Universal** — "Una sola interfaz que une todo el ecosistema. Premium naval en mano."

#### 17.2.3 Sección "Cada nodo, su mundo" (showcase per-vertical)

> **3 grandes cards, una por vertical activo en oleada 1, cada uno con su mood propio:**

**Card Granja** (earth tones, parchment texture bg)
- Photo hero: campo trigo dorado al atardecer.
- Heading Cormorant: "Granja"
- Tagline Inter Italic: *"Donde nace todo."*
- Bullets: terrain dinámico · 5 cultivos · 3 invernaderos · cooperativa propia.
- CTA secondary: "Ver más en bitácora →"

**Card Molino** (industrial copper bg)
- Photo hero: rodillos en operación con haz de polvo de harina.
- Heading: "Molino"
- Tagline: *"El ronroneo de los rodillos."*
- Bullets: trazabilidad lineage · contratos B2B · maquinaria custom.

**Card Tablet** (navy + brass premium bg)
- Photo hero: Tablet en mano con UI compass-rose.
- Heading: "La Tablet"
- Tagline: *"El catalejo del Capitán."*
- Bullets: 8 apps · multi-empresa · dock customizable · NUI premium.

#### 17.2.4 Sección "Detalle obsesivo" (galería macro)

> **Grid 4-cols de macro-shots in-world con lighting Admirals §14.** Cada imagen es un wow moment:

1. Sello de cera siendo aplicado a contrato (close-up, brass dust particles).
2. Rodillos del molino girando con haz de luz polvoriento.
3. Tractor levantando polvo en trail al atardecer.
4. Tablet en mano con compass-rose splash brass glow.
5. Maqueta de la región Granja en la cooperativa.
6. Báscula industrial brass en almacén.
7. Lobby de banca con compass-rose en mármol.
8. Documento parchment con sellos múltiples y lineage trace.

> **Cada imagen lleva caption Cormorant Italic 14px en hover** explicando el detalle. Estilo museo.

#### 17.2.5 Sección "Comparativa honesta" (tabla)

> **Tabla mostrando Admirals vs alternativas (sin nombrar competidores específicos — tono distinguido).** Esta es **nuestra arma** — no atacamos, mostramos.

| Aspecto | Scripts genéricos | **Admirals** |
|---|---|---|
| Cadena de suministro | Ítems aislados, transferencia por menú | Cadena física trazable end-to-end |
| Calidad de producto | Score arbitrario | 5 factores físicos (suelo, riego, plaga, clima, fertilizante) |
| UI | UI distinta por script | Tablet universal coherente |
| Documentos | Strings en chat | Documentos físicos firmados con sello |
| Empresas | Job único | Empresas multi-vertical con miembros y roles |
| Atmósfera | Lighting GTA default | Atmósfera per-zona con timecycles propios |
| Branding | Genérico | Casa de comercio naval premium |

#### 17.2.6 Sección "Pricing" (3 columnas)

> **Tres canales claros** con diferenciación brass nivel premium:

- **Tebex One-time** — €XXX · Pago único · Updates 1 año.
- **Licencia Anual** — €XXX/año · Updates + Beta + SLA.
- **Suscripción Mensual** ⭐ (Recomendado) — €XX/mes · Updates + Beta + SLA + flexibilidad.

> Card central (subscription) destacada con border brass + badge "Recomendado" brass. **El precio nunca se grita — Cormorant Regular 36px, no bold giant.**

#### 17.2.7 Sección "Compatibilidad técnica"

- **Frameworks soportados:** QBox primary · QBCore compatible · ESX limited.
- **Dependencias mandatorias:** ox_inventory · ox_target · ox_lib · oxmysql.
- **Recomendadas:** pma-voice.
- **Servidores mínimos:** XX players · YY% CPU headroom · MySQL 8/MariaDB.

#### 17.2.8 Sección "Equipo y proceso"

> **Diferenciación clave** — los competidores no humanizan el equipo. Nosotros sí.

- Foto del founder (tono profesional, no selfie).
- Quote Cormorant Italic: *"Construimos Admirals como construirías un barco que cruzará océanos. Todo cuenta. Todo se queda."*
- 3 valores: **Calidad sobre deadline · Soporte sobre fix-and-forget · Comunidad sobre cantidad.**
- Link a "Nuestra bitácora" (devblog).

#### 17.2.9 Sección "Soporte y garantías"

- Discord soporte: respuesta < 24h.
- Documentación completa.
- Updates regulares (cadencia trimestral grande, parches semanal).
- Bug bounty para encontrar issues críticos.
- Política de refund clara.

#### 17.2.10 Footer

- Links: Trailer · Documentación · Bitácora · Discord · Twitter.
- Logo Admirals brass + "© 2026 Admirals Studio".
- Texto Cormorant Italic 12px: *"Coordinamos tu flota."*

### 17.3 Trailer cinemático — guión y dirección

> **Tres deliverables de video:**

#### 17.3.1 Trailer principal (2-3 minutos) — "La Almirantazgo"

**Estructura narrativa (3 actos):**

**ACTO I — La invitación (0:00 - 0:45)**
- 0:00 Black screen. Sound: campana naval distante.
- 0:03 Texto Cormorant Italic blanco sobre negro: *"Toda flota necesita un puerto."* Fade.
- 0:08 Cinemática slow pan over Granja al amanecer, niebla cálida (atmosphere `granja_outdoor_pastoral` §14.2).
- 0:15 Voiceover (voz cálida pero autoritaria, español ibérico neutro):
  > *"Hace siglos, las potencias del mar coordinaban sus flotas mercantes desde una sola institución: la Almirantazgo. Cada barco con su carga, cada puerto con su sello, cada contrato con su firma."*
- 0:30 Transición a Molino interior, haz de polvo cinemático.
- 0:35 Voiceover continúa:
  > *"Hoy, en el siglo XXI, esa institución renace en tu servidor."*
- 0:42 Black flash + sound brass swell.

**ACTO II — La promesa (0:45 - 2:00)**
- 0:45 Logo Admirals aparece en negro con animación brass shimmer reveal — sound `admirals_brand_reveal` (campana + chime).
- 0:52 Cut a player abriendo el Tablet — close-up de la mano + chasis brass + screen unlock con compass-rose splash.
- 1:00 Quick cuts (cada 1.5-2s):
  - Tractor sembrando con polvo trail.
  - Saco de grano siendo pesado en báscula brass.
  - Camión llegando al Molino.
  - Rodillos en operación con haz de luz.
  - Notificación pop en Tablet "Pedido entregado".
  - Sello cera siendo aplicado a contrato.
  - Compass-rose en suelo lobby banca.
  - Maqueta cooperativa con cámara recorriendo.
- 1:30 Beat de pausa. Voiceover:
  > *"Granja. Molino. Mercado. Banca. Logística. Cinco mundos. Una flota. Un sello."*
- 1:45 Wide shot composición: jugador en muelle con Tablet, vista panorámica de los 3 nodos visibles.
- 1:55 Voiceover suave:
  > *"Te enrolas con Admirals."*

**ACTO III — La invitación final (2:00 - 2:30)**
- 2:00 Logo Admirals en pantalla completa, fondo navy, brass glow alrededor.
- 2:05 Texto reveal Cormorant SemiBold:
  > *"ADMIRALS"*
  > *"La Almirantazgo de tu servidor."*
- 2:15 Sub-text Inter Light:
  > *"Disponible: Tebex · Licencia · Suscripción"*
- 2:22 CTA brass: *"admirals.studio"*
- 2:28 Fade to black + sound campana fadeout.

**Especificaciones técnicas trailer:**
- Resolución: 4K master, 1080p delivery.
- Aspect: 16:9.
- Duración: 2:30 (sweet spot atención).
- Música: original score compuesto (no library) — strings cálidos + brass orquestal sutil + percusión mínima. Inspiración: scores de Patrick Doyle (período / heritage) más restraint moderno.
- Voiceover: profesional, español neutro ibérico (alternativa: versión inglesa para mercado internacional).
- Color grade: timecycle modifier `admirals_ceremonial` (§14.3) aplicado en post.
- Edición: cortes con propósito narrativo, cero cuts random a beat.
- Captura in-engine: 100% — no renders fuera de FiveM (autenticidad).

#### 17.3.2 Teaser (30s) — "Avistamiento"

- Loop perfecto, formato squared 1:1 (Instagram/Twitter friendly) Y vertical 9:16 (TikTok/Shorts).
- Estructura: 3-4 cuts hero + logo reveal final.
- Cero voiceover. Solo música + texto Cormorant on-screen.
- CTA al final: *"30 días para zarpar — admirals.studio"*

#### 17.3.3 Feature highlight (60-90s)

- Para audience más técnica (admins servidores).
- Estructura: feature → demo → feature → demo (formato "what you get").
- Voiceover funcional + screen captures Tablet UI.
- Música más rítmica, menos cinemática.

### 17.4 Screenshots — protocolo de captura

> **Las screenshots son la moneda de cambio en FiveM.** Cada admin futuro las verá en Tebex, Discord, foros, comparaciones. Tienen que ser **artefactos cuidados**, no caps casuales.

#### 17.4.1 Categorías de screenshots (mínimo 30 producidas)

| Categoría | Cantidad | Notas |
|---|---|---|
| **Hero shots cinematográficos** | 6 | Composiciones de marketing — wide, color graded, golden hour. |
| **UI Tablet showcase** | 8 | Una por app principal: Brújula, Banco, Mercado, Mensajes, Documentos, Notificaciones, Mapa, Configuración. |
| **Macro detail in-world** | 6 | Sello cera, báscula brass, rodillos, compass-rose suelo, irrigación brass, maqueta. |
| **Gameplay action shots** | 6 | Sembrando, cosechando, transferencia banco, firmando contrato, entregando carga, supervisando molienda. |
| **Atmósfera por nodo** | 4 | Granja al atardecer · Molino con haz polvoriento · Banca lobby premium · Tablet en mano with screen on. |

#### 17.4.2 Estándares técnicos de screenshot

- **Resolución:** 3840×2160 (4K) — escalado a 1920×1080 para Tebex hero.
- **Composición:** **regla de los tercios** o **simetría narrativa** — nunca centrado random.
- **Lighting:** capturadas con timecycle modifier Admirals activo (`admirals_pastoral`, `admirals_industrial` etc).
- **HUD:** **siempre apagado** durante captura. Si la NUI Tablet aparece, en estado curado (apps abiertas con datos representativos, no demo data feo).
- **Color grade:** post-process en Photoshop/Lightroom — sutil, jamás "Instagram filter". Levantar shadows sutil, contrast +5, saturation -3.
- **Watermark:** **cero watermark** en screenshots Tebex. Mínimo logo discreto en footer 8% opacity solo en marketing externo (Twitter, Reddit).
- **Naming convention:** `admirals_[category]_[node]_[shotnum]_v[version].jpg`. Ej: `admirals_hero_granja_03_v2.jpg`.

#### 17.4.3 Setup de captura in-engine

**Resource interno `admirals_screenshot_studio` (debug-only, no shipping):**
- Free-cam mode con depth of field controlable.
- Time-of-day lock (forzar hora específica).
- Weather lock.
- HUD toggle.
- NUI demo data injector (carga datasets curados para Tablet UI).
- FOV slider.
- Cinematic letterbox toggle.

> Permite al equipo marketing capturar screenshots de calidad reproducible.

### 17.5 Web propia — "admirals.studio"

> **Los competidores tienen Tebex page + opcional landing minimal.** Nosotros tenemos **una web de Studio multi-página estilo casa editorial naval**. Único en el espacio. Genera percepción premium **antes** de llegar a Tebex.

#### 17.5.1 Estructura de la web

```
/                   → Home (hero + manifesto + CTA Tebex)
/products           → Listado productos (oleada 1: Granja, Molino, Tablet)
/products/granja    → Página detalle Granja
/products/molino    → Página detalle Molino
/products/tablet    → Página detalle Tablet
/bitacora           → Devblog (artículos)
/bitacora/[slug]    → Artículo individual
/sobre              → Sobre Admirals (founder, manifesto, valores)
/soporte            → Soporte + FAQ + Discord link
/comunidad          → Community showcase + servidores destacados
/docs               → Link directo a docs site (subdomain o external)
/legal              → Términos · privacidad · refund
```

#### 17.5.2 Stack técnico web

- **Framework:** Astro (SSG, performance excelente, perfect for static-mostly).
- **Estilos:** Tailwind con tokens Admirals importados (mismos hex que el Tablet).
- **CMS para devblog:** Markdown + frontmatter en repo (no CMS externo, control total).
- **Hosting:** Cloudflare Pages (CDN global, free tier suficiente al inicio).
- **Domain:** `admirals.studio` (verificar disponibilidad — fallback `getadmirals.com`).
- **Performance budget:** LCP < 1.5s, CLS < 0.05, total JS < 100KB.

#### 17.5.3 Diseño visual web

> **Paleta meta-brand §3.4 idéntica al Tablet.** Tipografía Cormorant Garamond + Inter §4. Texturas parchment + brass accents.

**Home page (anatomía):**
- Hero full-screen con video loop Tablet en mano + manifesto Cormorant.
- "Manifesto Admirals" — 5 promesas grandes Cormorant Italic con icon brass.
- "Productos" — 3 cards (Granja, Molino, Tablet) con foto hero y CTA.
- "Bitácora" — últimos 3 artículos con thumbnail.
- "Comunidad" — quotes de admins + servidores destacados.
- Footer rich con links + newsletter signup brass.

**Detalles per-página producto:**
- Hero video del nodo.
- Filosofía del nodo (Cormorant copy).
- Galería screenshots categorizados.
- Feature list con icons Lucide brass.
- Trailer embed.
- Pricing card.
- FAQ específico nodo.
- CTA final.

#### 17.5.4 SEO + meta

- Meta tags ricos OG (Open Graph) con hero video + Cormorant title.
- JSON-LD structured data (`Product`, `SoftwareApplication`).
- Sitemap.xml + robots.txt.
- Hreflang para versión EN/ES.

---

### 17.6 Bitácora del Capitán — devblog editorial

> **Differenciador masivo.** Los competidores publican changelogs técnicos. Nosotros publicamos **artículos editoriales** sobre el making-of, decisiones, comunidad. **Cada post es un artefacto.**

#### 17.6.1 Categorías de posts

| Categoría | Cadencia | Tono |
|---|---|---|
| **Making-of** (cómo construimos X) | Mensual | Narrativo + técnico, photos process. |
| **Diseño en profundidad** (decisiones art/UX) | Mensual | Pedagógico, mostrar trabajo. |
| **Comunidad** (servidores destacados, quotes) | Mensual | Cálido, foco humano. |
| **Patch notes "Cuaderno de a bordo"** | Por release | Funcional pero con voz narrativa, no aburrido. |
| **Roadmap reveals** | Trimestral | Visión, hype controlado, transparencia. |
| **Devlog técnico** (para SDK builders) | Bimensual | Profundo, código, audience técnica. |

#### 17.6.2 Anatomía de un post devblog

```
[Hero image — render in-engine 4K]
[Título Cormorant SemiBold 56px]
[Subtítulo Cormorant Italic 24px]
[Meta: autor · fecha · categoría · tiempo lectura]

[Lead paragraph Inter 18px]
[Body Inter 16px line-height 1.7]
[Sub-headings Cormorant SemiBold 32px]
[Imágenes inline con caption Italic 14px]
[Pull-quotes Cormorant 28px brass border-left 4px]
[Code blocks JetBrains Mono navy bg]

[Footer: tags · siguiente post · suscríbete a bitácora]
```

#### 17.6.3 Pipeline editorial

- **Cadencia:** 1 post por semana mínimo en oleada 1.
- **Author:** founder principalmente, eventual guest post.
- **Process:** outline → first draft → 1 review → publish.
- **Engagement:** cada post se promociona Twitter + Discord + Reddit r/FiveM.
- **Newsletter:** suscribers reciben digest mensual con highlights — sutil push hacia Tebex.

#### 17.6.4 Posts inaugurales planificados (oleada 1)

> **Lista de los primeros 10 artículos a publicar — mapa editorial confirmado:**

1. *"Por qué construimos Admirals"* (manifesto founder).
2. *"La metáfora de la Almirantazgo: por qué un script necesita una historia"*.
3. *"Cómo modelamos un silo que se siente lleno"* (technical art).
4. *"La Tablet: anatomía de un objeto físico digital"* (hardware + UI).
5. *"Cinco factores que deciden la calidad de tu cosecha"* (quality system).
6. *"Lineage: por qué un saco de harina sabe de dónde viene"* (trazabilidad).
7. *"Cormorant + Inter: por qué Admirals lee como un libro"* (typography deep dive).
8. *"Servidor destacado: [primer servidor admin partner]"* (comunidad).
9. *"Roadmap visión 5 años — la flota que viene"* (oleadas 2-4).
10. *"Construyendo nuestra primera SDK pública"* (technical, audience builders).

### 17.7 Discord community design

> El Discord es el **club de oficiales**. Discord también respira la marca.

#### 17.7.1 Estructura de canales

```
📜 BIENVENIDA
  ├─ #carta-de-bienvenida (rules + manifesto)
  ├─ #anuncios (anuncios oficiales)
  └─ #cambios (changelog automático bot)

🚢 PUERTO COMÚN
  ├─ #plaza-mayor (general chat)
  ├─ #presentaciones (members new)
  └─ #vitrina-servidores (admins muestran sus servers con Admirals)

⚓ FLOTA TÉCNICA
  ├─ #soporte-instalación
  ├─ #soporte-config
  ├─ #bugs-reportes
  └─ #builders-sdk (oleada 3+)

🛠️ TABERNA DEL CAPITÁN
  ├─ #ideas-y-feedback
  ├─ #beta-testers (subscribers exclusive)
  └─ #rfc-discusiones (governance changes)

📰 BITÁCORA
  ├─ #devblog (auto-post nuevos artículos)
  └─ #behind-the-scenes (work in progress, sneak peeks)
```

#### 17.7.2 Roles Discord

| Role | Color | Permission |
|---|---|---|
| **Almirante** (founder) | brass `#C9A14A` | All |
| **Oficial** (team Admirals) | navy `#0A2A47` | Mods, support |
| **Capitán** (subscribers) | ivory `#F4EFE6` | Beta access, exclusive channels |
| **Marinero** (license owners) | navy mist `#163E5C` | Standard premium |
| **Grumete** (free / Tebex one-time) | ivory dim `#D4CCB9` | Standard |
| **Visitante** (sin compra aún) | grey | Public channels only |

#### 17.7.3 Bot custom Admirals

- Bot Discord personalizado con avatar compass-rose brass.
- Comandos: `/changelog [version]`, `/docs [topic]`, `/server-status`, `/myorder` (verificar compra).
- Auto-post devblog nuevos posts en `#devblog`.
- Auto-rol según compra Tebex (vía Tebex API).

### 17.8 Social media playbook

#### 17.8.1 Twitter/X — `@admirals_studio`

- **Cadencia:** 3-5 posts/semana.
- **Formats:**
  - Macro screenshots con caption Cormorant.
  - Devblog teasers con link.
  - Behind-the-scenes work in progress.
  - Community quotes (admins).
  - Trailer clips (15s recortes).
- **Voz:** distinguida, calmada, ocasional humor seco. NUNCA all-caps hype, NUNCA emoji spam.
- **Hashtags:** mínimos. `#FiveM #RP` ocasional, no spam.

#### 17.8.2 YouTube — channel "Admirals Studio"

- Trailer principal pinned.
- Feature highlights por nodo.
- Devblog video versions (algunos posts adaptados a video).
- Tutorials técnicos para admins.
- Cadencia: 2 videos/mes.

#### 17.8.3 Instagram (opcional, low priority)

- Solo macro screenshots curados.
- Reel del trailer.
- Cadencia baja: 1-2 posts/semana.

#### 17.8.4 TikTok / Shorts

- Recortes 15-30s del trailer.
- Macro detail loops (rodillos, sello, compass).
- Cadencia oportunista cuando hay material listo.

#### 17.8.5 Reddit — r/FiveM, r/FiveMServers

- **No spam.** Posts solo cuando hay contenido sustantivo (release, devblog importante).
- Engagement honesto en threads de comunidad.
- AMA ocasional founder.

### 17.9 Launch campaign — los primeros 90 días

> **El timing del launch es crítico.** No solo "soltar el producto" — **una campaña narrativa.**

#### 17.9.1 Pre-launch (T-30 a T-1)

| Día | Acción |
|---|---|
| T-30 | Anuncio "Avistamiento" — teaser 30s en redes. Web teaser page con email signup. |
| T-21 | Primer devblog "Por qué construimos Admirals". |
| T-14 | Reveal nodo Granja — devblog + hero screenshots + 60s feature video. |
| T-7 | Reveal nodo Molino + Tablet. Trailer principal 2:30 publicado. |
| T-3 | Discord abierto a waitlist. Pre-orders early-bird con descuento simbólico. |
| T-1 | "Mañana zarpamos." Push final redes + newsletter. |

#### 17.9.2 Launch day (T-0)

- Tebex live a las 18:00 hora EU sábado (timing FiveM admins).
- Tweet anuncio + thread con hero shots.
- Discord announcement + AMA founder en `#plaza-mayor`.
- Email a waitlist subscribers.
- Reddit post en r/FiveM (cuidado, no spam — 1 post bien curado).

#### 17.9.3 Post-launch (T+1 a T+90)

| Período | Acción |
|---|---|
| Semana 1 | Soporte intensivo, ningún bug se queda > 24h. Live updates Discord. |
| Semana 2 | Primer servidor partner destacado en bitácora. |
| Semana 4 | First patch notes "Cuaderno de a bordo" con voice narrative. |
| Mes 2 | Devblog "Lecciones del primer mes" — transparency post. |
| Mes 3 | Reveal teaser oleada 2 (próxima vertical). |

### 17.10 Branding cross-touchpoint — quality assurance

> **Cualquier touchpoint Admirals** (Tebex, web, Discord, Twitter, trailer, packaging email) debe pasar el "5-point check":

1. ✅ ¿Usa la paleta meta-brand §3.4?
2. ✅ ¿Usa Cormorant + Inter (§4)?
3. ✅ ¿Usa metáfora naval / Almirantazgo de algún modo?
4. ✅ ¿Tiene voice apropiado (distinguido, cálido, no hype)?
5. ✅ ¿Tendría sentido al lado del Tablet en mano del player?

Si algún punto falla → reject + iterate.

### 17.11 Métricas de éxito marketing (KPIs)

> **Cómo sabremos que estamos ganando vs 17mov / 0Resmon en percepción:**

| KPI | Target oleada 1 (mes 6) | Target oleada 2 (mes 12) |
|---|---|---|
| Tebex visits/month | 5.000 | 15.000 |
| Tebex conversion rate | ≥ 3% | ≥ 4% |
| Discord members | 1.500 | 5.000 |
| Newsletter subscribers | 800 | 3.000 |
| Twitter followers | 1.000 | 4.000 |
| YouTube subscribers | 300 | 1.500 |
| Devblog reads/month | 3.000 | 10.000 |
| Servidor partners destacados | 5 | 20 |
| Reviews positivas Tebex | ≥ 4.7/5.0 (≥ 30 reviews) | ≥ 4.8/5.0 (≥ 100 reviews) |
| Brand mentions orgánicos comunidad | Tracking baseline | +200% vs mes 1 |

### 17.12 Antipatrones marketing Admirals

> **Cosas que JAMÁS haremos** — guardarail de marca:

- ❌ Hype trailers all-caps con cuts cada 0.3s (estilo gaming Twitter genérico).
- ❌ Banners "BIG SALE 50% OFF!!!" estilo Steam frenesí.
- ❌ Comparativas atacando explícitamente a competidores (mencionarlos por nombre).
- ❌ Emoji spam en posts oficiales (un emoji aislado con propósito sí, 6 emojis seguidos no).
- ❌ Texto giant bold-shouty "ÚLTIMA OPORTUNIDAD" en CTAs.
- ❌ Stock photos de "diverse smiling team" obviamente falsas.
- ❌ Lorem ipsum en mockups que se hacen públicos (todo placeholder es contenido real).
- ❌ Screenshots con HUD GTA default visible.
- ❌ Memes de moda (jamás envejece bien).
- ❌ Promesas de features que no están listas ("coming soon" sin fecha realista).

### 17.13 Marketing assets deliverables — checklist pre-launch

> **Lista exhaustiva para no olvidar nada antes de zarpar:**

**Video (5 piezas):**
- [ ] Trailer principal 2:30 — 4K master + 1080p + 720p versions.
- [ ] Teaser 30s — 16:9 + 1:1 + 9:16 (3 aspect ratios).
- [ ] Feature highlight 60-90s — 16:9 1080p.
- [ ] Hero loop Tebex 6s — 1080p MP4 < 4MB.
- [ ] Hero loop web 8s — WebM optimizado.

**Imagen (40+ piezas):**
- [ ] 30+ screenshots in-game categorizados (§17.4.1).
- [ ] 6 hero composiciones para Tebex page principal.
- [ ] Logo pack: SVG + PNG (varios sizes) + favicon + social avatars.
- [ ] OG images per página web (1200×630).
- [ ] Discord assets: server icon + banner + emoji set custom.
- [ ] Twitter banner + avatar.
- [ ] YouTube channel art + thumbnails template.

**Texto (writing):**
- [ ] Tebex page copy completo (todas secciones §17.2).
- [ ] Web copy completo (home + 3 product pages + sobre + soporte).
- [ ] 10 devblog posts inaugurales en draft (§17.6.4).
- [ ] FAQ exhaustivo (≥30 preguntas).
- [ ] Email templates (welcome, pre-launch, launch, monthly digest).
- [ ] Discord canal descriptions + bot messages.
- [ ] Press kit (PDF distribuible a streamers / press FiveM).

**Audio:**
- [ ] Score original trailer (composer brief + final delivery).
- [ ] Voiceover trailer (ES + EN versions).
- [ ] Sound stings de marca (`admirals_brand_reveal`, `admirals_chime`, etc).

**Web:**
- [ ] Site Astro deployable.
- [ ] Domain registrado + DNS configured.
- [ ] Analytics (Plausible — privacy-friendly, no GA).
- [ ] Newsletter system (ConvertKit / Beehiiv).
- [ ] Discord bot deployed.

---

## 18. Plan de assets + governance del arte

> **Quién entrega qué, cuándo, con qué calidad.** Sin este plan, el arte se descontrola — ya sea por scope creep 3D o por inconsistencias entre nodos.

### 18.1 Inventario maestro de assets oleada 1

> **Suma total de assets visuales/sonoros que entregar antes del launch.** Cada uno tiene owner + estado + DRI (directly responsible individual).

#### 18.1.1 Assets 3D

| Categoría | Cantidad | Owner |
|---|---|---|
| MLOs interiores (Granja office, almacén, greenhouse, Molino sala, despacho, almacén, Banca lobby, despacho) | 8 | 3D team |
| Hero props (§16.7) | 7 | 3D team |
| Maquinaria gameplay Granja (tractor, cosechadora, sembradora, fertilizadora, aspersor) | 5 | 3D team |
| Maquinaria gameplay Molino (rodillos, cinta, balanza, máquina embolsado) | 4 | 3D team |
| Tablet chasis (3 variants) | 3 | 3D team |
| Items físicos (sacos, semillas, harina paquete, contratos enrollados) | ~15 | 3D team |
| Texturas custom (Substance) | ~20 sets | 3D team |
| **Total ≈ 62 piezas custom** | | |

#### 18.1.2 Assets código (NUI / FX / Lighting)

| Categoría | Cantidad | Owner |
|---|---|---|
| Componentes design system Tablet (§12.4) | ~60 | Frontend team |
| FX particle effects (§13.2) | ~20 | Client Lua team |
| Atmosphere zones + profiles (§14.2) | 8 zones / 5 profiles | Client Lua team |
| Timecycle modifiers Admirals (§14.3) | 5 | Client Lua + 3D collab |
| Sound design (§7 + ambientes + signature) | ~80 sounds | Sound designer |
| Animaciones NUI (Framer Motion patterns) | ~30 patterns | Frontend team |
| Iconos custom Admirals (§5) | ~25 SVGs | Brand designer |
| **Total assets código ≈ 230 piezas** | | |

#### 18.1.3 Assets marketing (§17)

| Categoría | Cantidad |
|---|---|
| Trailers + videos | 5 |
| Screenshots in-game | 30+ |
| Hero composiciones marketing | 6 |
| Logo pack (variantes + sizes) | ~15 archivos |
| Web pages | ~10 |
| Devblog posts inaugurales | 10 |
| Discord assets | 1 server full setup |
| Press kit | 1 PDF + asset zip |

### 18.2 Roles y responsabilidades

| Rol | Responsabilidad principal |
|---|---|
| **Founder / Art Director** | Curaduría final. Approve / reject final per asset. Mantiene este documento vivo. |
| **3D Lead** | Supervisa pipeline 3D. Define qué es nativo GTA reusable vs custom. Optimiza poly-counts. |
| **3D Modeler(s)** | Modelado, UVs, texture authoring. |
| **Frontend Lead (NUI)** | Mantiene design system. Approve nuevos componentes. Storybook completo. |
| **Frontend Devs** | Implementan apps Tablet usando design system. |
| **Client Lua / FX Dev** | Sistema partículas + atmosphere + lighting code-side. |
| **Sound Designer** | Diseño + producción de todos los sonidos. Mastering uniforme volumen. |
| **Brand Designer** | Logo + iconos + ilustraciones marketing + estilo redes. |
| **Web Developer** | Build + mantiene admirals.studio. |
| **Editorial / Devblog Writer** | Posts de bitácora. Founder lead, eventual contributor. |
| **Video Editor** | Trailer + recortes + thumbnails. |

> **En equipo pequeño** (1 founder + 1-2 devs + 1 3D + 1 sound + freelancers), un mismo individuo cubre múltiples roles. Lo importante es que **cada role tenga DRI** identificado.

### 18.3 Pipeline de aprobación de assets (art review)

> **Toda pieza visual o sonora pasa por art review antes de mergear a `main`.**

```
[Asset producido por DRI]
        │
        ▼
[Pull request o asset upload con metadata: nombre, owner, categoría, version]
        │
        ▼
[Art Director review — checklist art (§17.10 + criterios specifc)]
        │
        ├─ ✅ Approve → merge / publish
        ├─ ⚠️  Iterate → cambios solicitados con feedback constructivo
        └─ ❌ Reject → no encaja con dirección, replan
```

**Checklist art review per categoría:**

**3D model checklist:**
- [ ] Poly-count dentro de budget (definido per asset class).
- [ ] LODs presentes (al menos LOD0 + LOD1).
- [ ] UVs sin overlapping unintencional, optimizadas.
- [ ] Texture set 4-channel completo (albedo/normal/roughness/metallic).
- [ ] Wear pass aplicado.
- [ ] Origen pivot correcto (para rotación / placement).
- [ ] Collisions definidas si interactivo.
- [ ] Documentación: shader uniforms expuestos registrados en `02_shader_contracts.md`.
- [ ] Render preview en lighting Admirals subido al PR.

**NUI component checklist:**
- [ ] Storybook story con todas variantes y states.
- [ ] Tokens consumidos (cero hex hardcoded).
- [ ] Light + Dark mode supported.
- [ ] A11y (contrast, keyboard, ARIA).
- [ ] Reduced motion fallback.
- [ ] Visual regression snapshot.
- [ ] TypeScript types exportados.

**FX checklist:**
- [ ] FX ID registrado en `fx_catalog.lua`.
- [ ] Distance culling configurado.
- [ ] Sound layer paired.
- [ ] Performance: no degrada FPS perceptiblemente en escena media.
- [ ] Visualmente alineado con paleta del nodo.

**Sound checklist:**
- [ ] Volume normalized (LUFS estándar Admirals).
- [ ] No clipping.
- [ ] Mastered en ducking-friendly mix.
- [ ] Filename sigue convención (`<node>_<category>_<id>_v<X>.ogg`).
- [ ] Loop seamless si es ambient.
- [ ] Documentado en sound bible (a crear: `docs/art/03_sound_bible.md`).

### 18.4 Versionado de assets

- Cada asset visual/sonoro lleva versión semver: `v1.0.0` baseline launch.
- Cambios visuales menores (color tweak, texture refinement): bump minor `v1.1.0`.
- Cambios drásticos (re-modelado completo, re-design componente): bump major `v2.0.0` con changelog explícito.
- **Asset original NUNCA se borra.** Se conserva en `assets/archive/` por si hay rollback necesario.

### 18.5 Naming conventions globales

| Tipo asset | Convención |
|---|---|
| Modelos 3D | `admirals_<node>_<category>_<id>.ydr` (ej. `admirals_granja_silo_wood_01.ydr`) |
| Texturas | `admirals_<node>_<material>_<map>.dds` (ej. `admirals_granja_soil_albedo.dds`) |
| Particle FX | `<node>_fx_<id>` (ej. `granja_fx_dust_field`) |
| Sounds | `<node>_<category>_<id>_v<X>.ogg` (ej. `tablet_unlock_v1.ogg`) |
| NUI components | `Admirals<Component>` o namespace `<Component>` (ej. `<DocumentCard>`) |
| Marketing screenshots | `admirals_<category>_<node>_<num>_v<X>.jpg` |
| Devblog posts | `YYYY-MM-DD-slug-en-kebab-case.md` |

### 18.6 Localización (l10n) preview

> **Oleada 1 launch:** español ibérico + inglés.
> **Oleada 2:** francés + alemán + portugués (mercados FiveM grandes).

**Reglas l10n:**
- Toda string user-facing en NUI debe pasar por `t('key')` i18next-style.
- Cero strings hardcoded en componentes.
- Voz de marca se mantiene per-lengua (no es traducción literal — es "transcreation").
- Cormorant tiene buen multi-language support; fallback fonts definidos por idioma si fuera necesario.

### 18.7 Brand asset library — repositorio único

> **Un solo lugar donde vive todo el arte oficial.**

**Estructura:**

```
admirals-brand-assets/
├── 01_logos/
│   ├── primary/ (svg, png en sizes)
│   ├── monochrome/
│   ├── monogram/
│   └── lockups/
├── 02_typography/
│   ├── fonts/ (Cormorant Garamond, Inter, JetBrains Mono — licenses)
│   └── specimens/
├── 03_color/
│   ├── palette.ase (Adobe Swatch)
│   ├── palette.css
│   └── palette.json
├── 04_iconography/
│   ├── lucide-customized/
│   └── admirals-custom/ (svg sources)
├── 05_textures/
│   ├── parchment/
│   ├── brass/
│   ├── navy-weave/
│   └── soil-burlap/
├── 06_audio/
│   ├── brand-stings/
│   ├── tablet-signature/
│   └── ambient-loops/
├── 07_marketing/
│   ├── screenshots/
│   ├── trailers/
│   ├── press-kit/
│   └── social-assets/
├── 08_3d-renders/ (renders out-of-game para press, NOT in-game assets)
└── 09_templates/
    ├── devblog-cover.psd
    ├── tweet-template.fig
    └── thumbnail-yt.fig
```

> **Acceso:** Git LFS o Dropbox/Drive con permisos. Backup mensual obligatorio.

### 18.8 Pruebas y validación visual continua

| Tipo test | Frecuencia | Tooling |
|---|---|---|
| **Visual regression NUI** | Cada PR | Chromatic / Playwright snapshot. |
| **A11y NUI** | Cada PR | axe-core en CI. |
| **Performance NUI** | Semanal | Lighthouse + custom Tablet bench. |
| **Performance 3D** | Per release | Internal benchmark scene + FPS log. |
| **Sound levels normalize** | Per release | LUFS analyzer batch script. |
| **Marketing assets brand check** | Per asset | Manual checklist §17.10. |

### 18.9 Escalación: cuando 3D scope-creep o algo no encaja

> **Política clara:** si en algún momento el equipo 3D pide más scope que lo definido (ej. "queremos modelar todas las plantas individuales del campo"), el founder dice **NO** con autoridad amistosa y redirige a la rule Bible §13.4: **3D entrega volumen + idea, código entrega magia.**

**Decision tree art conflict:**

```
¿El asset propuesto cabe en el budget definido (§16.7, §18.1)?
  ├─ SÍ → ¿pasa el art review checklist?
  │    ├─ SÍ → approve
  │    └─ NO → iterate
  └─ NO → ¿el over-scope añade valor 10x al gameplay?
       ├─ SÍ → revisar Bible §13.4 + ajustar plan oficial (RFC)
       └─ NO → reject + redirect a alternativa code-side
```

---

## 19. Roadmap art + changelog

### 19.1 Roadmap por oleadas

#### Oleada 1 (T-0 launch)
- ✅ Meta-brand definida (logo, paleta, tipografía, iconos, sound, motion).
- ✅ Identidad Granja, Molino, Tablet implementada.
- ✅ Design system Tablet completo + Storybook.
- ✅ Sistema atmósfera + 5 timecycles Admirals.
- ✅ Catálogo FX particle 20+ efectos.
- ✅ Sound bible v1.0 con ~80 sonidos.
- ✅ Web admirals.studio live.
- ✅ Trailer 2:30 + teaser 30s + feature highlight.
- ✅ 30+ screenshots curados.
- ✅ Devblog con 10 posts publicados.
- ✅ Discord activo con bot custom.

#### Oleada 2 (T+6 meses)
- 🔜 Identidad nueva vertical (probablemente Panadería) con su propio mood.
- 🔜 Manager Panel webapp launch (browser-based) — design system extendido.
- 🔜 5+ devblog posts post-launch.
- 🔜 Trailer "Capítulo 2" reveal teaser oleada 2.
- 🔜 Localización FR + DE + PT.
- 🔜 Marketing iteration basado en KPI feedback oleada 1.

#### Oleada 3 (T+12 meses)
- 🔜 SDK pública para third-party apps Tablet — design system documentado público.
- 🔜 5+ verticales activas con cohesion.
- 🔜 Premium themes per-server admin (custom branding per servidor).
- 🔜 Mobile companion app real (iOS + Android nativa) — extender brand.

#### Oleada 4 (T+18-24 meses)
- 🔜 Internacionalización completa.
- 🔜 Partner programs con servidores premium.
- 🔜 Conferencia / showcase anual Admirals (digital event).
- 🔜 Coffee-table book físico "The Admirals Anthology" — coleccionable.

### 19.2 Cambios pendientes / debt

> **Cosas conocidas que tendremos que abordar post-oleada 1:**

- [ ] Acoplar timecycle modifiers Admirals con feedback real de player en condiciones diversas.
- [ ] Validación a11y nivel AAA (actualmente AA).
- [ ] Soporte responsive del Tablet para resoluciones no-1280×800 (medium priority).
- [ ] Localización profunda para mercados asiáticos (long term).
- [ ] Renovación trailer al año 1 con community footage.

### 19.3 Documentos hijos que crear

> **Spin-offs del art direction master que necesitamos eventualmente:**

| Documento | Propósito | Prioridad |
|---|---|---|
| `02_shader_contracts.md` | Contratos uniforms 3D ↔ Código (§15.2) | Alta — antes 3D empieza |
| `03_sound_bible.md` | Catálogo exhaustivo de todos los sonidos con specs | Alta |
| `04_storybook_guide.md` | Cómo contribuir al Storybook NUI | Media |
| `05_marketing_playbook.md` | Calendario editorial + workflows redes | Media |
| `06_brand_voice_guide.md` | Tono escrito en español + inglés (templates emails, tweets) | Media |
| `07_devblog_style_guide.md` | Plantillas + tono + formato bitácora | Baja-Media |

### 19.4 Changelog del documento

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 (parte 1) | 2026-04-XX | Founder + Cascade | Redacción inicial: §0-§11 (filosofía, meta-brand, identidad Granja/Molino/Tablet). |
| 1.0 (parte 2) | 2026-04-XX | Founder + Cascade | Continuación §11 final + tokens motion. |
| 1.0 (parte 3) | 2026-04-30 | Founder + Cascade | §12 Design system NUI Tablet completo · §13 Partículas y FX · §14 Lighting + post-FX + atmósfera. |
| 1.0 (parte 4) | 2026-05-01 | Founder + Cascade | §15 Materiales en mundo (split 3D/Code) · §16 Escenografía MLOs · §17 Marketing visual exhaustivo · §18 Plan assets + governance · §19 Roadmap + changelog. **Documento completo, firmable.** |

---

## 20. Manifesto de cierre

> *"En un mar de scripts genéricos, no construimos un script. Construimos una flota.*
> *No vendemos features. Enrolamos capitanes.*
> *No publicamos changelogs. Escribimos bitácora.*
> *No mostramos UI. Mostramos un puerto.*
>
> *Cada partícula que vuela en una parcela, cada haz de polvo en el molino, cada sello de cera en un contrato, cada campana del Tablet — todo lleva el mismo sello.*
>
> *El sello de la Almirantazgo.*
>
> *Ízate la enseña. Bienvenido a Admirals."*

---

**FIN DEL DOCUMENTO `01_art_direction.md` v1.0**

*Próximos documentos hermanos: `02_shader_contracts.md` · `03_sound_bible.md` · `04_storybook_guide.md`.*
