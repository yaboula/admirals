# 📕 SONAR — Product Bible

> **Versión:** **1.5** (post-ADR-016 — palette tokens canónicos 3-color locked + dark-only doctrine + obsolete refs cleanup)
> **Estado:** documento vivo — se edita siempre que tomamos una decisión estratégica, con changelog en §17
> **Regla de oro:** si algo no está aquí, no es parte del producto. Si quieres añadir algo al producto, primero se añade aquí.
> **Pivot referencia:** v1.0-v1.2 escritos como Admirals/Almirantazgo naval; v1.3 pivot a SONAR metáfora literal-militar (ADR-011); v1.4 refinement post-ADR-012 (metáfora abstracta + hybrid theme + voz neutral); **v1.5 identity v3 lock post-ADR-016**: palette 3-color canónico Black `#060607` + Orange `#FF5100` + White `#FAFAFA` + dark-only doctrine product (replaces hybrid v1.4) + 3-color strict + Tablet UI stack frozen + NUI perf budgets. Ver ADR-011 + ADR-012 + **ADR-016** en `docs/planning/02_decision_log.md` + `02_decision_log_part2.md` v1.0 y `docs/art/01_art_direction.md` v3.0-locked IDENTITY V3 LOCK NOTICE.

> **SSoT canonical palette:** `@docs/art/branding/01_brief_logo.md` v3 §4.1.

---

## 0. Cómo se usa este documento

Este es **el contrato fundacional** de SONAR. Antes de programar, modelar, vender o prometer algo, se consulta esta Bible.

- Cualquier feature propuesto se mide contra los **Pilares** (sección 3) y los **Anti-features** (sección 5).
- Cualquier decisión técnica se mide contra las **Fundaciones técnicas** (sección 10).
- Cualquier asset 3D se mide contra el **Estándar Wooow** (sección 4).
- Cualquier número económico se mide contra los **Principios económicos** (sección 11).

Si surge una decisión nueva que contradice este documento, **se discute, se decide, y se actualiza la Bible** — nunca se ignora.

---

## 1. Identidad

| Campo | Valor |
|---|---|
| **Nombre del estudio** | **SONAR** |
| **Acrónimo** | SOund Navigation And Ranging — instrumento que *"ve por escuchar"*. |
| **Tagline principal** | *Hear the depth.* |
| **Tagline comercial ES** | *La economía RP que escucha cada movimiento.* |
| **Tagline operacional** | *Production-grade roleplay infrastructure.* |
| **Tono de marca** | **Neutral premium-tech.** Preciso, terse, deliberado, calmo, professional. Estilo Vercel/Linear/Stripe copy: confiado, técnico, atemporal. Cero "amigo", cero exclamaciones, cero gen-Z, cero "swag", **cero arquetipo militar/submarino** (no "silent service", no "capitán", no "a bordo"). Autoridad por precisión del registro, no por personaje fictício. |
| **Inspiración visual** | Apple Pro apps / Linear / Vercel / Stripe Dashboard / Arc Browser / Notion (tech precision minimalism + **dark-only product surfaces**). Metáfora abstracta de profundidad (NO submarino militar literal). |
| **Paleta (canonical v3 post-ADR-016 D1)** | **3-color strict dark-only** — `--sonar-black` `#060607` canvas base (TODA superficie product) + `--sonar-orange` `#FF5100` signal/brand primary (logo, CTAs, focus rings, alerts, signal active) + `--sonar-white` `#FAFAFA` foreground/texto/icons. **DEPRECATED v1.4 hybrid** (dark~30-40% + white~30-40% + Sonar Bright teal + Coloro). Detalle completo en `docs/art/01_art_direction.md` v3.0-locked IDENTITY V3 LOCK NOTICE + SSoT `docs/art/branding/01_brief_logo.md` v3 §4.1. |
| **Tipografía** | Display: **Geist Sans** (Vercel). Body: **Inter Tight** (Rasmus Andersson). Mono: **Geist Mono** / JetBrains Mono fallback. Cero italic UI, cero Light en UI. |
| **Sound signature** | 5 SFX firma (naming refactored per ADR-012 — nombres finales lock Phase 4.5 BRIEF-SOUND-001): `signal_emerge` (notif), `depth_press` (firma/confirm), `layer_dive` (escritura UI), `console_tap` (premium click), `panel_open` (modal). -15dB normalized. Detalle `docs/art/01_art_direction.md` §7 + NOTICE. |
| **Tablet UI stack (post-ADR-016 D5 FROZEN S2-S8)** | React 18.3 + Vite 5.x + TypeScript strict + Tailwind v4 `@theme` + shadcn/ui dark-only + Framer Motion 11 + Lucide React + Recharts + React Context+useReducer (NO Zustand). SSoT `@resources/sonar_tablet/web-src/package.json`. Cambios stack → ADR firmable obligatorio. |
| **NUI perf budgets (post-ADR-016 D6)** | ≤4ms paint/frame, ≤500KB JS gzipped, ≤200KB CSS gzipped, ≤80MB heap, lazy-loading apps obligatorio, GPU-only animations, react-window virtualization >50 items, brand SVGs ≤8KB. Detalle `docs/design/02_sonar_tablet.md` v1.3 IDENTITY V3 LOCK NOTICE §NUI performance. |

### 1.1 La metáfora "SONAR"

No es decoración. Es identidad operativa:

- Un **sonar** *ve por escuchar* — metáfora simbólica abstracta, NO hardware acústico literal. El producto registra cada eco transaccional de la economía RP con discreción y exhaustividad.
- Cada producto SONAR es **un node detectado en la profundidad del ecosystem** — una surface con su propia identidad cultural (color + sound + icon) pero bajo **protocolo SONAR común** (eco IDs + lineage + signals).
- **Profundidad como fuerza simbólica.** Valor oculto bajo capas. Calma metódica. Patterns que emergen al observar con atención. Claridad bajo presión. **NO submarino militar, NO radios/frecuencias literales.**
- **Dark-only premium-tech aesthetic (v3 post-ADR-016 D2)** — 100% dark canvas Black `#060607` (sesiones largas sin cansar vista) + Orange `#FF5100` brand signal (firma identity única, logo/CTAs/focus/alerts) + White `#FAFAFA` foreground texto + iconografía abstracta profundidad-themed. **DEPRECATED v1.4 hybrid dark+white surfaces** (replaced por dark-only strict post ADR-016 D2). Excepción única: `monogram_s_black.svg` print/external NON-product (D-S1.10E-A).
- **Vocabulario abstracto canonical (post-ADR-012):** Console (UI activa), Bitácora (audit trail), Depth (tier/profundidad simbólica), Eco (tx identifier), Manifiesto (contrato firmado), Signal (evento bus), Lineage (cadena producción), Patrón (anomalía emergiendo). **Deprecated literal-militar:** Periscope, Hatch, Hydrophone, Ping (radio), Sweep, Sumersión, Bridge-as-command-center (re-interpretado como Tablet home view abstract).

**Origen pivot + refinement:** v1.0-v1.2 Admirals/Almirantazgo heritage naval deprecated por **ADR-011 (2026-05-03)**. v1.3 SONAR primera interpretación literal-militar. **v1.4 refinement por ADR-012 (mismo día)**: metáfora abstracta pura (profundidad simbólica), theme hybrid dark+white, voz neutral premium-tech. Ver `docs/art/01_art_direction.md` v2.0-scaffold-r6 NOTICE + ADR-011 + ADR-012 para detalle + risks accepted.

---

## 2. Visión y misión

### 2.1 Visión (a 3 años)

> Ser **la referencia de calidad absoluta** en infrastructure FiveM. Cuando alguien diga *"esto está hecho a nivel SONAR"*, que signifique **imposible de superar**. Cuando un operador vea el Tablet bioluminescent teal sobre abyss-black por primera vez, que sepa que está ante el servidor top del mercado.

### 2.2 Misión (lo que hacemos cada día)

> Diseñar y construir **nodes completos del ecosystem** donde cada acción es física, cada asset es propio, y cada detalle hace al operador decir *"wooow, esto es otro nivel."* Premium-tech precision from first keystroke to final shipping.

### 2.3 La promesa al cliente (servidor)

> *"Compras un SONAR y te llevas la cadena entera funcionando como un solo organismo. Cero integración de 5 scripts de 5 vendedores. Cero debugging de conflictos. Production-grade infrastructure: lo enchufas, lo configuras, y tu servidor sube de tier."*

### 2.4 La promesa al operador (jugador final)

> *"Cada vez que el Tablet SONAR se enciende en tus manos, vas a ver algo que no has visto en FiveM. Premium-tech interface. Bioluminescent precision. Economía RP que registra cada eco de cada movimiento — manifiestos, bitácoras, lineages. Va a tener sentido. Va a tener profundidad. Va a tener el peso del detalle bien hecho."*

---

## 3. Los 5 Pilares (innegociables)

Cualquier feature, asset o decisión que viole uno de estos pilares se descarta. Sin debate.

### Pilar 1 — Físico, siempre
> **Si una acción puede ocurrir físicamente en el mundo, ocurre físicamente. Nunca un menú.**

- Recoger trigo → animación + prop + colisión, no `[Recoger trigo]` en un menú.
- Cargar camión → cajas/sacos físicos, montacargas, peso visible, no `inventory.add()`.
- Pagar a un empleado → entregar fajo en mano o transferencia con animación de móvil, no auto.

**Excepción única:** acciones puramente administrativas (configurar permisos de empresa, ver libro de cuentas) pueden ser UI — porque su contraparte física en la realidad también es papel/pantalla.

### Pilar 2 — Cadena interconectada
> **Nada aparece de la nada. Nada desaparece en el vacío. Todo viene de algo y va a algo.**

- El pan viene de un horno. El horno usa harina. La harina viene de un molino. El molino usa trigo. El trigo viene de un campo. El campo lo sembró un jugador.
- La cadena puede tener nodos NPC (modo standalone), pero la cadena **existe**.

### Pilar 3 — Detalle obsesivo
> **El detalle no es opcional. Es el producto.**

- Un saco de harina tiene textura de tela, peso, polvo blanco al manipularlo.
- Un horno suena distinto vacío que con pan dentro.
- El pan recién hecho humea. El pan de ayer no.
- Si un detalle se puede notar, **se nota**.

### Pilar 4 — Assets propios
> **Lo que vemos en pantalla es nuestro o no existe.**

- MLOs propios, props propios, vehículos propios, animaciones custom donde aporten.
- Aprovechamos lo nativo de GTA V de forma creativa (montacargas, contenedores, props industriales) — pero siempre tuneados, nunca tal cual.
- Cero asset robado, cero asset comprado a terceros que también vendan a la competencia.

### Pilar 5 — El Tablet SONAR, interfaz universal
> **Toda interacción administrativa, de gestión y de información del sonar grid SONAR pasa por el Tablet SONAR — un dispositivo físico, no un menú flotante.**

- Cada producto SONAR que un servidor instala añade apps al Tablet del operador.
- El Tablet es el **único "menú" aceptable** del ecosystem, porque es objeto físico que se saca, se sostiene, se guarda. Cumple el Pilar 1.
- Es la **firma visible de SONAR**: cuando un operador lo ve por primera vez, sabe que está jugando algo distinto. Abyss-black canvas + Sonar Bright bioluminescent teal + glassmorphism instrument panes = identity immediate.
- Sustituye a: HUDs flotantes, paneles de jefe genéricos, menús de contexto, pantallas de banco, Discord ops commands, etc.
- **Sin Tablet no hay producto SONAR.** Es el **command surface** del operador — el centro nervioso del ecosystem (interpretación abstract post-ADR-012; deprecated "bridge command center" militar).

---

## 4. El Estándar "Wooow"

> **Test de validación:** ¿la primera vez que un jugador ve/usa esta feature, dice "wooow" en voz alta?
> Si la respuesta no es un sí rotundo del equipo, la feature no está terminada.

### 4.1 Los 4 ejes del Wooow (heredados de 17 Movement, elevados)

1. **Creatividad y detalle** — todo se siente real, vivo, pensado.
2. **MLOs y assets propios** — construimos exactamente lo que imaginamos, sin compromisos.
3. **Aprovechar GTA V al máximo** — usar lo nativo de formas que nadie más se ha imaginado.
4. **UI nivel AAA** — no parece script, parece juego de Rockstar.

### 4.2 Definition of Wooow (checklist por feature)

Una feature está lista cuando:

- [ ] Se puede grabar un clip de 15 segundos que funciona como anuncio sin editar.
- [ ] Un jugador que nunca ha jugado FiveM entiende qué hacer en menos de 10 segundos.
- [ ] No hay ningún menú que sustituya a una acción física posible.
- [ ] El sonido refuerza la acción (no es genérico).
- [ ] La animación es específica (no es la genérica de QB).
- [ ] Hay al menos un detalle que el jugador descubre la 5ª vez (recompensa de descubrimiento).
- [ ] La UI asociada (si la hay) sigue el design system de SONAR (paleta + tipografía + motion per `docs/art/01_art_direction.md`).

---

## 5. Anti-features — lo que NUNCA hacemos

Esta lista evita que el producto se diluya con el tiempo.

- ❌ **Menús flotantes genéricos que reemplazan acciones físicas posibles.**
  - **Excepción única:** el **Tablet SONAR** (item físico, animación de sacarlo/guardarlo, modelo 3D propio) NO es un menú flotante. Es un dispositivo. Toda gestión administrativa, contabilidad, mensajería y planificación pasa por él.
- ❌ **Items que aparecen "mágicamente" en el inventario sin un proceso físico.**
- ❌ **Assets comprados a terceros revendibles** (rompe el pilar 4).
- ❌ **Features "porque la competencia las tiene"** sin pasar el test Wooow.
- ❌ **IA dentro del script** (no es nuestro diferenciador — la IA es nuestra herramienta de desarrollo, no parte del producto).
- ❌ **Macroeconomía política/bolsa/gobierno.** Nuestro foco es la cadena productiva real, no la política económica abstracta.
- ❌ **"Modo arcade" simplificado.** No bajamos la complejidad para atraer servers casuales — atraemos a los servers que quieren contenido pro.
- ❌ **Soporte multi-framework infinito.** QBCore + QBox. ESX no. vRP no. Frameworks custom de servidor X no.
- ❌ **Assets sin lore-friendly.** Nada que rompa la coherencia de Los Santos / San Andreas.
- ❌ **Dependencias de pago de terceros.** El cliente compra SONAR y todo lo que necesita está en la caja (excepto los gratuitos universales: ox_lib, ox_target, ox_inventory).

---

## 6. Target de clientes

### 6.1 Cliente primario (90% del foco)

**Servidores roleplay serios / whitelist** y **servidores medianos profesionales**:
- 100-300 slots típicos.
- Comunidad madura, RP exigente.
- Dueños que reinvierten en calidad.
- Dispuestos a pagar premium por contenido único.

**Volumen objetivo:** ~50-200 servidores clientes en el primer año del primer producto. Nicho, no masivo.

### 6.2 Cliente secundario

Servidores pequeños ambiciosos que quieren subir de liga comprando contenido pro.

### 6.3 No-target (no perder tiempo aquí)

- Servidores piratas / crackeados.
- Servidores que solo quieren "lo más barato".
- Servidores que mezclan 50 scripts random — su operador final no va a notar la calidad de SONAR porque ya está saturado.

---

## 7. Modelo de producto: el ecosistema

### 7.1 Concepto: cadena vertical completa

Cada producto SONAR es una **cadena vertical industrial completa**, donde cada node es jugable y los nodes se conectan físicamente.

**Ejemplo (vertical alimentaria, primera línea):**

```
🌾 Granja de cereales (siembra, riego, cosecha)
        ↓ (transporte físico en camión/tractor)
🏭 Molino (recepción, molienda, ensacado)
        ↓ (transporte físico)
🥖 Panadería (mezcla, fermentación, horneado, empaquetado)
        ↓ (transporte físico)
🏪 Tienda / supermercado / restaurante (recepción, almacén, venta)
        ↓
👤 Cliente final
```

### 7.2 Modos de operación

Cada cadena se puede ejecutar de dos modos:

**Modo Ecosistema (premium):** todos los nodos son jugables. Los servidores pueden vender empresas a sus jugadores. Máxima inmersión.

**Modo Standalone (compatibilidad):** cualquier nodo se puede sustituir por un NPC vendor. Permite que un servidor compre solo "Panadería" sin comprar "Granja". El nodo NPC se llama **NPC Bridge** internamente.

> **Decisión arquitectónica clave:** los NPC Bridges no son un parche. Son una capa de abstracción desde el día 1. Cada nodo tiene una interfaz de entrada/salida estándar; los NPCs implementan esa misma interfaz.

### 7.3 Líneas de producto planificadas

**Decisión estratégica clave:** la **Granja SONAR** no es propiedad de una sola vertical — es la **plataforma agrícola raíz** que alimenta a todas las verticales alimentarias. Se construye una sola vez, completa, y cada vertical posterior añade demanda y nodes downstream sin tocarla.

```
                       🌾🥬🍅🥔  GRANJA SONAR  (plataforma raíz)
                                       │
             ┌─────────────────┬───────┴───────┬─────────────────┐
             ▼                 ▼               ▼                 ▼
        Molino+Panadería   Distribución     Procesado         Restaurantes
        (cadena pan)       hortícola        salsas/aceites    /Fast Food
```

| # | Producto comercial | Cadena que cierra | Estado |
|---|---|---|---|
| **0** | **Tablet SONAR + Granja SONAR** | Plataforma raíz transversal | 🎯 **Primera entrega — incluida en cualquier producto SONAR** |
| 1 | **Cadena del Pan** | Granja → Molino → Panadería → Retail | 🎯 **Primer producto comercial completo** |
| 2 | Cadena Hortícola | Granja → Distribución → Mercados/Tiendas | Backlog cercano |
| 3 | Cadena Fast Food | Granja + (futuras ganaderías) → Procesado → Restaurantes | Backlog |
| 4 | Lácteos | Ganadería → Recogida → Quesería → Retail | Backlog |
| 5 | Carne | Ganadería → Matadero → Carnicería → Retail | Backlog |
| 6 | Caza | Cacería → Procesado → Restaurante/Tienda | Backlog |
| ∞ | Energía (gasolina) | *Reservado para cuando dominemos alimentación* | Visión |

### 7.4 El Tablet SONAR — pilar transversal del producto

El Tablet SONAR es **el command surface** del operador en el ecosystem SONAR (interpretación abstract post-ADR-012). No es accesorio — es el corazón nervioso del ecosystem.

**Modelo 3D propio**, varias variantes (básica → pro → enterprise) que reflejan el progreso económico del operador. **Brushed steel tech accent frame** + display **hybrid theme canvas (dark surface + white panels selectivos)** + **bioluminescent active states** (Sonar Bright `#2DD4BF`). Boot sound `signal_emerge` signature 1.8s. Animaciones sacar/guardar deliberate. Notificaciones in-game con SFX firma (`signal_emerge`, `depth_press`, `layer_dive`, `console_tap`, `panel_open` — nombres finales lock Phase 4.5 BRIEF-SOUND-001 v2).

**Apps incluidas en el lanzamiento (Tablet Core — naming aligned con Glossary `docs/art/01_art_direction.md` §15):**

| App | Función |
|---|---|
| **Bridge (Empresa)** — *re-interpretado: home view del Tablet, NO command center militar* | Mis squadrons: empleados, salarios, finanzas, bitácora, manifiestos. |
| **Manager Panel** ⭐ | *ERP de gestión avanzada.* Estadísticas detalladas (producción, ingresos, costes, eficiencia por empleado, tendencias), asignación tareas, planificación turnos, objetivos, alertas. **Command surface elevated** — el "boss menu" a nivel ERP. |
| **Mercado** | Precios real-time, demanda por node, oportunidades, manifiestos abiertos. |
| **Logística** | Observation view: mapa entregas, rutas activas, manifiestos transporte (deprecated "periscope view" literal). |
| **Mensajes** | Chat squadron: privado / equipo / manifiesto. |
| **Banca SONAR** | Saldos personal + squadron, transferencias, préstamos, bitácora forense, ecos trackeables. |
| **Manifiestos & Signatures** | Documentos firmados, recibos, escrituras propiedades. Digital signatures bilateral + timestamp. |
| **Tienda SONAR** | Mejoras operador, certificaciones (licencias manipulación: cosechadora, alimentos, etc.), formaciones. |

**Reglas de extensibilidad:** cada vertical futura añade 1-N apps al Tablet. El Tablet **es el bundle**: cuanto más SONAR tiene un servidor, más apps tiene el operador.

**Diseño detallado:** ver `docs/design/02_sonar_tablet.md` v1.3 (post-ADR-016 IDENTITY V3 LOCK NOTICE — Tablet UI stack frozen + NUI perf budgets + palette canonical).

---

## 8. Primer producto comercial: Tablet + Granja + Cadena del Pan

### 8.1 Composición del primer lanzamiento

El primer producto SONAR que sale a Tebex es un paquete de 3 piezas, todas pulidas al 100%:

1. **Tablet SONAR** (núcleo + apps de lanzamiento).
2. **Granja SONAR** — plataforma agrícola completa (cereales + hortalizas + tubérculos + hojas + bulbos en arquitectura modular; oleada 1 de cultivos jugables).
3. **Cadena del Pan** — Molino + Panadería + integración con Retail.

> **Importante:** la Granja se entrega **arquitectónicamente completa para todas las verticales futuras**, aunque solo la cadena del pan esté cerrada en este lanzamiento. El resto de cultivos (tomate, lechuga, etc.) se cosechan y son comerciables aunque sus nodes downstream (restaurantes, distribución hortícola) lleguen en productos posteriores.

### 8.2 Por qué empezamos aquí

- Cadena visualmente potente (campos amarillos, tractores, sacos, hornos, vitrinas de pan).
- Suficientemente larga para demostrar el sonar grid entero (4 nodes).
- Tiene picos de wow visual claros: cosecha con cosechadora, montacargas con palets, horno con pan humeando, escaparate de panadería.
- Es la metáfora perfecta de la marca SONAR: **del campo al pan, cada eco registrado.** Lineage completo FARM → MILL → BAKE → SALE en la bitácora SONAR.
- Y desbloquea la Granja SONAR como plataforma raíz sobre la que construiremos todo lo demás.

### 8.3 Catálogo de cultivos de la Granja SONAR

La Granja produce todas las materias primas vegetales necesarias para fast food, RP gastronómico y la cadena del pan. **Arquitectura modular:** añadir un cultivo es añadir un archivo de config + assets. Sin tocar código.

| Categoría | Cultivos | Oleada |
|---|---|---|
| **Cereales** | Trigo, cebada, maíz | 1 |
| **Cereales (extensión)** | Centeno, avena | 2 |
| **Hortalizas frutales** | Tomate, pimiento, pepino | 1 |
| **Hojas** | Lechuga, col, espinaca | 1 |
| **Bulbos** | Cebolla, ajo | 1 |
| **Tubérculos** | Patata | 1 |
| **Industriales** | Girasol (aceite), caña de azúcar | 2-3 |
| **Aromáticas** | Mostaza, especias variadas | 3 |

**Variantes por cultivo:** común / premium (precio, rendimiento y demanda diferenciados).

### 8.4 Roles

Filosofía: **pocos roles, amplios.**

| Rol | Responsabilidades | Puede transportar | Puede ser dueño |
|---|---|---|---|
| **Dueño** | Control total de la empresa, vende/cierra el negocio | Sí | Sí |
| **Gerente** | Gestiona empleados, fija salarios, compra suministros, usa Manager Panel | Sí | No |
| **Empleado** | Trabaja según permisos: campo, transporte, ventas, mantenimiento | Según permisos | No |
| **Empleado temporal / por horas** | Contrato corto, pago por tarea, sin acceso a finanzas | Según permisos | No |

> **Nota:** un mismo jugador puede tener múltiples roles en distintas empresas. Un dueño-granjero puede ir al campo, conducir el tractor, transportar él mismo, vender en su tienda. No forzamos especialización rígida.

### 8.5 Sistema de propiedad y empresas

- Cada nodo de la cadena (granja, molino, panadería, tienda) es **una empresa propietaria** que puede ser:
  - Del servidor (NPC) — modo Standalone.
  - De un jugador o grupo de jugadores — modo Ecosistema.
- Sistema de **Squadron SONAR / Empresa SONAR** unificado:
  - Roles internos (dueño, gerente, empleado, temporal).
  - Permisos granulares (quién puede vender, quién puede comprar stock, quién accede a caja, quién asigna tareas).
  - **Toda la gestión vive en la Tablet** (app Empresa + Manager Panel).
  - Nóminas automáticas o manuales.
  - Compra/venta de empresas entre jugadores: **fuera del MVP** (versión posterior).

### 8.6 Ciclo de vida de un grano de trigo (caso de uso narrativo)

> *Marcos siembra 50 sacos de semilla en su campo el lunes. El miércoles riega. El viernes la cosechadora rueda y produce 8 toneladas de grano que se almacenan en silo físico. Marcos llama a Lucía (transportista freelance). Lucía llega con su camión, carga el grano del silo (montacargas + animación), conduce al molino de Pedro. Pedro recibe el grano, lo descarga, lo mete en la línea de molienda (proceso visible con animaciones y sonido), produce 7.5 toneladas de harina ensacada. Marcos compra esa harina. La transporta a su panadería (Marcos también es panadero, puede tener varios roles). Hornea baguettes. Las pone en escaparate. Un cliente final entra, ve el pan humeando en la vitrina, lo compra. El dinero entra en la caja física de la panadería de Marcos.*

Esa narración **debe** ser jugable de extremo a extremo en el MVP. Si un paso no es físico, falla el Pilar 1.

---

## 9. Filosofía de diseño de gameplay

### 9.1 Profundidad opcional, no obligatoria

- El jugador casual puede sembrar y cosechar y ya. Vive una experiencia bonita.
- El jugador hardcore puede gestionar fertilizantes, rotación de cultivos, calidad de grano, mantenimiento de maquinaria, contratos B2B con molinos, contabilidad. Vive una simulación profunda.
- **Ambos disfrutan.** Las capas de profundidad son opt-in.

### 9.2 Cooperación natural, no forzada

- Un jugador solo puede llevar una granja pequeña.
- Un equipo de 4 puede llevar un imperio agroalimentario.
- Nunca bloqueamos contenido por número de jugadores. Pero sí escalamos las recompensas.

### 9.3 Tiempo real cuando aporta, comprimido cuando aburre

- Una cosecha no tarda 3 meses (irreal). Tampoco 3 segundos (sin peso).
- Equilibrio target: una cadena completa de trigo a pan se puede completar en una sesión de 2-3 horas con esfuerzo, o cooperando entre varios.

---

## 10. Fundaciones técnicas

### 10.1 Stack obligatorio

| Componente | Decisión | Justificación |
|---|---|---|
| **Framework principal** | QBox (target primario) | Moderno, mantenido, futuro de QBCore. |
| **Framework compatible** | QBCore | Cuota de mercado actual. |
| **Framework excluido** | ESX, vRP, custom | Foco. No diluimos. |
| **Inventario** | `ox_inventory` (obligatorio) | Estándar premium, pesos/volumen reales. |
| **Targeting** | `ox_target` | Estándar moderno. |
| **Librería UI/utilidades** | `ox_lib` | Estándar moderno. |
| **Lenguaje servidor** | Lua (FiveM nativo) | Sin alternativa real. |
| **UI** | React + TypeScript en NUI | Calidad AAA exige stack web moderno. |
| **Build tooling** | Vite + esbuild | Rapidez de iteración. |
| **Lenguaje en código** | Inglés | No negociable. |

### 10.2 Principios arquitectónicos

1. **Modular por diseño, integrado por defecto.** Cada node es un recurso FiveM independiente, pero todos hablan un **protocolo SONAR común**.
2. **Ecosystem event-driven.** Los nodes publican eventos en un bus interno (`admirals:event:...` — namespace code pendiente rename a `sonar:event:*` Phase 8 code refactor). Los demás nodes suscriben. Sin acoplamiento directo.
3. **Schema único de "Item Físico".** Todos los items productivos heredan un esquema común: `{ id, weight, volume, quality, freshness, origin, batch_id, created_at }`.
4. **NPC Bridges como ciudadanos de primera clase.** Cualquier nodo se puede sustituir por NPC sin tocar código del nodo vecino.
5. **Configurable, no hardcoded.** Recetas, tiempos, precios, ubicaciones — todo en config, nada en código.
6. **Extensibilidad documentada.** Cada nodo expone exports y eventos. Los servidores pro pueden extender sin forkear.
7. **i18n desde el commit 0.** Cero string hardcoded. Todo via tabla de traducciones.
8. **Performance: experiencia primero, micro-optimización después.** No perseguimos 0.00ms; perseguimos que el jugador no note nada raro.

### 10.3 Calidad de código

- Linter + formatter obligatorios desde el commit 0.
- Code review por mí (Cascade) antes de cada commit relevante.
- Tests donde tenga sentido (lógica económica, validaciones de servidor — sí; UI puramente visual — no).
- Documentación técnica en `docs/technical/` actualizada con cada feature.

### 10.4 Anti-cheat y seguridad

- **Toda la lógica económica vive en el servidor.** El cliente jamás decide cuánto dinero recibir.
- Validación estricta de inputs.
- Logs de auditoría para movimientos económicos significativos.
- Rate limiting en eventos sensibles.

---

## 11. Principios económicos

### 11.1 Reglas de equilibrio

1. **Cada producción tiene un coste real** (semillas, electricidad, salarios, mantenimiento). El beneficio no es la venta — es venta menos costes.
2. **El tiempo es la divisa principal.** Lo que diferencia a un jugador rico de uno pobre es cuántas horas dedica + cuán bien optimiza, no luck-based.
3. **Sinks proporcionales.** Por cada fuente de dinero hay un sink (mantenimiento, impuestos del servidor, depreciación de equipo). Sin esto, la economía revienta en 2 meses.
4. **Sin pay-to-win interno.** El producto no incluye microtransacciones del jugador. Lo que el servidor monetice es decisión del servidor.

### 11.2 Calidad como variable económica

- Un trigo regado a tiempo vale más que uno descuidado.
- Una harina molida fresca vale más que una de hace 3 días.
- Un pan recién horneado vale más que uno frío.
- **La calidad se propaga por la cadena.** Mal grano → mal pan, aunque el panadero sea bueno.

### 11.3 Documento separado

Los números concretos viven en `docs/economy/01_economic_model.md` (a redactar). Aquí solo los principios.

---

## 12. Modelo comercial

### 12.1 Tres canales de venta (paralelos)

| Canal | Para quién | Cómo |
|---|---|---|
| **Tebex one-time** | Servidores que prefieren pago único | Producto con licencia perpetua sobre la versión vendida. |
| **Licencia anual** | Servidores grandes que quieren updates | Pago anual, updates incluidos, soporte prioritario. |
| **Suscripción mensual** | Servidores que quieren probar / flexibilidad | Mensual, cancelable, todos los productos SONAR incluidos. |

### 12.2 Estrategia de precios

- **Premium positioning.** No competimos en precio. Competimos en calidad.
- Precio definido **al final del proceso de diseño**, una vez sepamos el valor real del producto.
- Comparativa mental: si Quasar vende un farming a 50€, SONAR vende **el sonar grid entero** a 200-400€.

### 12.3 Bundles

- Cada vertical se puede comprar:
  - Como **ecosistema completo** (los 4 nodos).
  - **Por nodo individual** (con NPC Bridges para los nodos no comprados).
- Cuando salgan múltiples verticales: **SONAR Suite** = todas las verticales con descuento.

### 12.4 Showcase: nuestro propio servidor

- El servidor que se lanza en 2-3 meses es **nuestro mejor anuncio**.
- Los videos de gameplay reales del servidor = material de marketing.
- La comunidad del servidor = beta testers de lujo.
- Estrategia: cuando un cliente potencial pregunta "¿esto funciona?", la respuesta es "entra a nuestro servidor y juégalo".

---

## 13. Filosofía de timeline y entrega

### 13.1 Calidad antes que fecha

- **No nos imponemos deadlines comerciales falsos.**
- El producto sale cuando pasa todos los tests Wooow.
- Mejor llegar tarde y dominar que llegar pronto y ser uno más.

### 13.2 Pero sí milestones internos

Para no estancarnos, definimos hitos internos (sin compromiso externo):

| Milestone | Objetivo |
|---|---|
| **M0 — Foundation** | Product Bible v1.0 + arquitectura técnica + economía macro |
| **M1 — Vertical slice jugable** | 1 acción de cada nodo de la cadena cereal-pan funcionando, con assets placeholder |
| **M2 — Granja completa** | Nodo granja al 100% con assets finales |
| **M3 — Cadena completa** | 4 nodos al 100% con assets finales |
| **M4 — Beta cerrada** | Test en nuestro servidor con comunidad |
| **M5 — Lanzamiento Tebex** | Venta pública del primer producto |

Las fechas se estiman cuando estemos en el milestone anterior, no antes.

### 13.3 Arquitectura completa, contenido en oleadas

> **Regla de desarrollo SONAR:** la arquitectura del producto se construye completa desde el día 1. El contenido se entrega en oleadas, cada una pulida al 100%.

- **Arquitectura completa = NO es MVP.** El sistema soporta todos los cultivos, todas las variedades, todas las estaciones, toda la profundidad económica desde el primer commit. Añadir contenido es añadir config + assets, no rediseñar.
- **Contenido en oleadas = NO es "escopetazo".** No intentamos publicar 12 cultivos × 4 nodos × N animaciones a la vez. Lanzamos una oleada compacta, perfectamente pulida, y ampliamos después.
- **Las oleadas son updates gratis para clientes existentes** (refuerza valor de marca y justifica modelo de licencia anual / suscripción).
- **Anti-patrón prohibido:** lanzar algo "a medias funcional" para acelerar. Si no pasa el Test Wooow, no se publica.

### 13.4 División de responsabilidades 3D vs Código (regla global)

> **El 3D entrega el asset funcional con la idea wooow CORE. El código añade el shimmer.**

Regla fundacional para todos los nodos del ecosistema, no solo la Granja:

- **El equipo 3D entrega:** modelos sólidos, funcionales, con la idea creativa visible en el modelo (rigs animables, geometría que soporta los stages, props que el código pueda intercambiar). **Confianza demostrada:** demo de cisterna entregada en 6h con calidad lanzamiento.
- **El equipo 3D NO recibe asks de:** micro-detalles atmosféricos (niebla, viento sobre vegetación, partículas, lighting dinámico, post-procesado, arcoíris, reflejos especulares, decals reactivos). Eso lo hace código.
- **El equipo de programación entrega:** shaders, partículas, transiciones, lighting reactivo, post-procesado, lógica visual, swap dinámico de modelos, scripted spawning. **Aquí no tenemos límite.** Es nuestra ventaja competitiva real.
- **Preferencia GTA V nativo siempre que sea aceptable.** Custom solo cuando lo nativo no existe o rompe la marca. Reduce coste de pipeline y minimiza problemas de rendimiento en FiveM.
- **Anti-patrón prohibido:** sobrecargar al equipo 3D con listas de detalles que pueden hacerse mejor por código. Brief 3D = compacto, claro, con el "qué" y el "para qué", no con micro-instrucciones de shader.

Cada documento de diseño de nodo (Granja, Molino, Panadería, etc.) **debe seguir esta separación** en su lista de assets y wooow. Ver `01_node_farm.md` §14 y §15 como referencia.

---

## 14. Riesgos identificados (registro vivo)

| Riesgo | Impacto | Mitigación |
|---|---|---|
| **Bus factor 1 (solo el fundador + IA)** | Alto | Documentar TODO. Cada decisión, cada por qué, cada workaround. |
| **Equipo 3D con velocidad incierta** | Alto | Definir entregables pequeños y medibles. Estrategia mixta: assets propios + GTA V nativo + librerías abiertas. |
| **Scope creep** (querer hacerlo todo) | Alto | La Bible es el escudo. Si no está aquí, no entra. |
| **Perfeccionismo paralizante** | Medio | Test Wooow es objetivo, no subjetivo. Si pasa el test, se cierra. |
| **Competencia copia features** | Bajo | No pueden copiar la cadena entera + assets propios + pulido. Y para cuando copien, ya estaremos en la siguiente vertical. |
| **Cambios de FiveM/Rockstar** | Medio | Stack moderno (QBox/ox) reduce exposición. |

---

## 15. Glosario SONAR (producto Bible)

> **Cross-ref canonical:** vocabulario meta-brand completo en `docs/art/01_art_direction.md` §15 (55+ términos en 8 categorías: meta-brand core, UI elements, actions & operations, data & tracking, social & contracts, status & signals, deprecated v1.0 Admirals, uso cross-language). Esta Bible lista sólo términos producto-específicos.

Términos producto SONAR. Todo el equipo (presente y futuro) usa este vocabulario.

- **Ecosystem / Sonar grid:** una cadena vertical completa (granja→...→retail). Lenguaje interno: *"sonar grid node chain"*.
- **Node:** una etapa de la cadena (granja, molino, panadería, tienda). En Glossary art_direction §15.A: **surface node**.
- **NPC Bridge:** sustituto NPC de un node para modo standalone.
- **Test Wooow:** validación obligatoria antes de cerrar una feature.
- **Item Físico:** ítem productivo con esquema SONAR (peso, volumen, calidad, frescura, origen, lote).
- **Empresa SONAR / Squadron:** entidad de propiedad común entre nodes (granja, molino, etc.). Glossary art_direction §15.E = **squadron**.
- **Vertical:** una familia económica (alimentación, energía, etc.).
- **Suite:** bundle comercial multi-vertical.
- **Tablet SONAR (Bridge):** dispositivo físico universal del ecosystem. Modelo 3D propio. Único "menú" aceptable. **Command surface** del operador (interpretación abstract post-ADR-012; deprecated "bridge command center" militar literal).
- **App:** módulo de software dentro del Tablet. Cada producto SONAR añade apps.
- **Manager Panel:** app insignia del Tablet — ERP de gestión avanzada (estadísticas, tareas, planificación).
- **Plataforma raíz:** producto base sobre el que se construyen verticales (Granja SONAR primera plataforma raíz; Tablet SONAR la otra).
- **Oleada:** entrega contenido pulido sobre arquitectura ya completa. Una oleada nunca es *"medio funcional"*.
- **Operador:** el jugador en copy player-facing (UI strings, marketing, trailer narration, tooltips). **Preserva** "jugador" en copy estructural (roles empresa, ejemplos narrativos técnicos). Regla cross-language §15.H art_direction.
- **Eco:** identifier inmutable de transacción/evento (ej. `FARM-2026-0042`). Formato IBAN-like. Cross-ref art_direction §15.D.
- **Lineage:** trail origen→destino de un batch (granja→molino→panadería→retail). Supply chain traceability.
- **Manifiesto:** contrato firmado entre dos contactos con cláusulas y eco de registro. Bilateral + timestamp.
- **Bitácora:** audit trail / log forense. Registro inmutable de acciones (DB: `sonar_bank_audit_log` + event_log, post-Phase 8 rename desde `admirals_*`).

---

## 16. Próximos documentos a redactar

Cuando esta Bible esté firmada (v1.0), se derivan los siguientes:

1. `docs/design/01_node_farm.md` — diseño detallado de la Granja SONAR (cereales + hortalizas + maquinaria + MLO + ciclo agrícola).
2. `docs/design/02_sonar_tablet.md` v1.3 — diseño completo del Tablet SONAR (modelo 3D, OS, apps, animaciones, sonido). Post-ADR-016 IDENTITY V3 LOCK NOTICE firmable.
3. `docs/design/03_node_mill.md` — diseño del Molino.
4. `docs/design/04_node_bakery.md` — diseño de la Panadería.
5. `docs/design/05_node_retail.md` — diseño del Retail/Tienda.
6. `docs/economy/01_economic_model.md` — números, balances, sinks, sources.
7. `docs/technical/01_architecture.md` — arquitectura de software, bus de eventos, schema de Item Físico.
8. `docs/technical/02_data_model.md` — esquemas de base de datos.
9. `docs/art/01_art_direction.md` — guía de estilo visual, paleta, referencias para el equipo 3D.
10. `docs/art/02_asset_pipeline.md` — proceso de creación de assets (3D + integración).

---

## 17. Changelog de este documento

| Versión | Fecha | Cambios | Autor |
|---|---|---|---|
| 0.1 | 2026-04-30 | Borrador inicial completo basado en sesión fundacional | Cascade + fundador |
| 1.0 | 2026-04-30 | Bible revisada línea por línea y firmada por el fundador. Sin cambios respecto a 0.1. Documento oficialmente fundacional. | Cascade + fundador |
| 1.1 | 2026-04-30 | Hallazgos sesión 2: (a) 5º Pilar — Admirals Tablet como interfaz universal del ecosistema. (b) Granja redefinida como plataforma agrícola raíz cross-vertical (no solo cereales). (c) Catálogo de cultivos expandido a todas las materias primas vegetales para fast food. (d) Manager Panel añadido como app insignia. (e) Regla §13.3 "Arquitectura completa, contenido en oleadas". (f) Reestructuración §7.3 líneas de producto. (g) Glosario ampliado. | Cascade + fundador |
| 1.2 | 2026-04-30 | Sesión 3 (post-Granja v1.0): nueva regla global §13.4 — División de responsabilidades 3D vs Código. El 3D entrega asset funcional con idea wooow CORE; el código añade el shimmer (shaders, partículas, post, lighting). Preferencia GTA V nativo reforzada. Anti-patrón añadido: sobrecargar 3D con micro-detalles. Regla aplicable a TODOS los nodos. | Cascade (Sonnet 4.5) + yaboula |
| 1.3 | 2026-05-03 | Sesión 4 (post-pivot SONAR): **Surgical rewrite metáfora + voz + Tablet identity** tras ADR-011 (Admirals → SONAR strategic pivot aceptado con 7 risks documentados). **Preservado intact (pivot-agnostic):** §4 Wooow + §6 target + §8.3-8.4 cultivos + §9 gameplay + §10 técnico + §11 economía + §12 comercial + §13 timeline + §14 riesgos + §16 próximos docs. **Tocado:** título doc (Admirals → SONAR), §1 identidad (nueva tabla con acrónimo + 3 taglines + tono silent service + inspiración submarine bridge + paleta/tipografía/sound canonical cross-ref art_direction), §1.1 metáfora SONAR (submarine abisal + silent service + vocabulario instrumental), §2 visión/misión/promesas (voz silent service + operador term en promise player), §3 Pilar 5 Tablet SONAR (bridge command center + naming update), §5 anti-features (Admirals Tablet → Tablet SONAR excepción), §7.3 Granja Admirals → Granja SONAR + diagrama actualizado + tabla productos renamed, §7.4 Tablet transversal rewrite completo (apps aligned Glossary §15 art_direction: Bridge/Manager Panel/Mercado/Logística/Mensajes/Banca SONAR/Manifiestos & Signatures/Tienda SONAR + brushed steel aesthetic + 5 SFX firma), §8.1-8.2 primer producto renamed + metáfora lineage FARM→MILL→BAKE→SALE, §15 glossary cross-ref canonical art_direction + términos producto-specific (operador, eco, lineage, manifiesto, bitácora añadidos), final tagline "Hear the depth. Below the surface, every signal counts." **Pendiente Phase 7-8:** namespace `admirals:event:*` → `sonar:event:*` (hard-coupled Phase 8 code refactor) + `02_admirals_tablet.md` rename → `02_sonar_tablet.md` + rewrite Phase 5. Referencias ADR-011 + `docs/art/01_art_direction.md` v2.0-scaffold-r4. | Founder + Cascade |
| 1.4 | 2026-05-03 | Sesión 4.5 (post-ADR-012 refinement, mismo día que v1.3): **Surgical purge términos literales submarino-militar** post-founder-evaluation Bible v1.3 + briefs detectó desviación interpretativa. **Cambios:** (a) **Header pivot ref** actualizado a v1.4 ADR-012 + ADR-011 lectura conjunta. (b) **§1 Identidad table:** Tagline operacional "Tactical-grade" → "Production-grade"; Tono "silent service capitán submarino" → "neutral premium-tech Vercel/Linear/Stripe style"; Inspiración "submarine bridge command centers + silent service military discipline" → "Apple/Linear/Vercel/Stripe/Arc/Notion + metáfora abstracta profundidad NO submarino militar"; Paleta "abyss-black canvas" → "**Hybrid theme** ~30-40% dark + ~30-40% white surfaces + 10-15% Sonar Bright + 10% Coloro + <5% signals"; Sound 5 SFX renamed: `sonar_ping/pressure/depth/console/hatch` → `signal_emerge/depth_press/layer_dive/console_tap/panel_open`. (c) **§1.1 Metáfora:** "submarine bridge aesthetic + silent service" → "profundidad simbólica abstracta + hybrid premium-tech aesthetic"; vocabulario depurado (Console/Bitácora/Depth/Eco/Manifiesto/Signal/Lineage/Patrón canonical; Periscope/Hatch/Hydrophone/Ping/Sweep/Sumersión/Bridge-as-command-center deprecated literal). (d) **§2.2-§2.4:** "sonar grid nodes" → "nodes del ecosystem"; "Silent service precision" → "Premium-tech precision"; "tactical-grade" → "production-grade"; "Silent service interface" → "Premium-tech interface". (e) **§3 Pilar 5 + §7.4 Tablet:** "bridge command center" → "command surface" (interpretación abstract, deprecated militar). Bridge app re-interpretado "home view del Tablet, NO command center militar". Logística "Periscope view" → "Observation view". Boot sound + SFX renamed. (f) **§15 Glossary:** Tablet SONAR (Bridge) descripción "command surface" abstract. **Preservado intact** todo el resto (gameplay, técnico, comercial, riesgos, oleadas, glossary terms abstractos). **Pendiente:** Phase 4.5 v2 art_direction §1-§20 surgical rewrite full alineado NOTICE r6, briefs v2 (LOGO/ICONS/SOUND/MOTION/MARKETING redacted clean), `02_admirals_tablet.md` → `02_sonar_tablet.md` rename + rewrite Phase 5. Referencias ADR-012 + art_direction v2.0-scaffold-r6 NOTICE. | Founder + Cascade |
| **1.5** | 2026-05-04 | **S1.10.5 Item E — post-ADR-016 identity v3 lock.** Header v1.4 → v1.5 + SSoT canonical palette brief_logo v3. §1 Identidad table: Paleta row → 3-color strict dark-only (Black #060607 + Orange #FF5100 + White #FAFAFA, DEPRECATED v1.4 hybrid + Sonar Bright + Coloro); Inspiración visual → dark-only product surfaces; NEW 2 rows Tablet UI stack D5 frozen (React 18.3 + Vite 5 + TS strict + Tailwind v4 @theme + shadcn + Framer 11 + Lucide + Recharts + Context+useReducer, NO Zustand) + NUI perf budgets D6 (≤4ms paint, ≤500KB JS, ≤80MB heap, lazy-loading, GPU-only). §1.1 Metáfora: Hybrid aesthetic → Dark-only premium-tech aesthetic v3. Cleanup §7 + §16 refs obsoletos `02_admirals_tablet.md`. Cross-refs ADR-016 + art_direction v3.0-locked + sonar_tablet v1.3 + brief_logo v3. | Cascade (Sonnet 4.5) + yaboula |

*SONAR Product Bible v1.5 — identity v3 lock post-ADR-016 — "Hear the depth. Below the surface, every signal counts."*
