# 🏪 Admirals — Nodo 4: El Retail Admirals

> **Versión:** 1.0 (firmado — completo, 15 secciones, 3 partes publicadas).
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.2
> **Documentos hermanos:** `01_node_farm.md` v1.1 · `02_sonar_tablet.md` v1.0 · `03_node_mill.md` v1.0 · `04_node_bakery.md` v1.0 · `art/01_art_direction.md` v1.0.
> **Estado:** firmado.

> **Lectura previa obligatoria:** Bible §3 (5 Pilares), §13.4 (3D vs Código), Bakery §0-§8 (especialmente §8.3 PED customer system + §8.4 dual-channel pattern), Tablet §7 (Manager Panel modular), Art Direction §15-§17.

---

## 0. Resumen ejecutivo

El **Retail Admirals** es el **cuarto y último nodo de la Cadena del Pan** y **el primer nodo agregador del ecosistema** — recibe producto de múltiples cadenas verticales upstream (Panadería, futura Lácteos, futura Hortícola, etc.) y los **revende al consumidor final**.

Es el **cierre comercial** de la promesa Admirals: del campo a la mesa. Cuando un cliente walk-in entra a un supermercado Admirals, **el pan que compra tiene lineage real** hasta la parcela del granjero — visible en el ticket vía Tablet.

Es a la vez:

- **Un comercio físico jugable** con MLO propio en **3 tiers** (tienda de barrio · supermercado mediano · hipermercado), con zona venta + zona backroom.
- **Un agregador de múltiples cadenas verticales** — gestiona 50-500 SKUs simultáneamente, recibe palets de N proveedores, balancea stock por categoría.
- **Un puesto profesional** (Retailer / Encargado de Tienda) con su rol RP — abre tienda 7am, gestiona reposiciones, balancea pricing, atiende equipo.
- **Un nodo del ecosistema** — recibe contratos B2B de upstream (Bakery, suppliers), vende B2C walk-in masivo, factura por Banca, gestiona inventario en Tablet.
- **El primer caso del patrón "B2C como canal principal"** — donde Bakery tenía B2C complementario (30% ventas), Retail tiene B2C dominante (90%+ ventas).

> **El Retail es donde el ecosistema Admirals se vuelve mainstream.** Cualquier player del servidor — incluso uno que no tenga interés en producir nada — entra al supermercado Admirals a comprar productos que SABE que tienen origen real. **Es la cara consumidor del ecosistema.**

---

## 1. Filosofía y posicionamiento

### 1.1 Volumen + organización + velocidad — la decisión estética

El Retail Admirals **NO es boutique premium** (eso es Bakery). El Retail Admirals es **volumen + organización + velocidad**. La inspiración no es Whole Foods — es **Mercadona / Lidl / Carrefour express bien hechos**, con lineales ordenados, neveras visibles, carteles claros, y eficiencia operativa visible.

- **Volumen** — 50-500 SKUs simultáneos en lineales, neveras llenas, palets en backroom. **El supermercado se VE lleno.**
- **Organización** — secciones claras (panadería / lácteos / frescos / despensa / bebidas), señalización brass Admirals, lineales ordenados con frente de venta perfecto.
- **Velocidad** — clientes entran, cogen, pagan, salen. La caja es eficiente. Las colas se mueven. El reponedor trabaja sin parar.

**Inspiración visual:**
- Supermercados europeos premium ordenados: Mercadona Premium / La Vie Claire (Francia) / SPAR Gourmet.
- Tonos: **blanco luminoso de lineales + brass Admirals en signage + acentos de color por sección** (verde = frescos, azul = lácteos, marrón = panadería, naranja = bebidas).
- Iluminación: **brillante uniforme** (vs cálida de Bakery) — lineales bien iluminados, sin sombras, comercial. **Wow atmosférico de código:** PEDs walk-in en flujo realista + carritos moviéndose + lineales que se vacían y reponen visualmente.

### 1.2 ¿Por qué un nodo dedicado al Retail?

> **¿No podría cada productor (Panadero, Granjero futuro, etc.) vender directo al consumidor sin intermediario?**

No. Por 6 razones:

1. **Pilar 1 — Físico.** El consumidor real va a UN sitio a comprar TODO. No va a 5 productores diferentes. El supermercado **agrega**.
2. **Pilar 2 — Cadena.** Sin Retail, la cadena queda "abierta" en el último eslabón. Retail cierra el ciclo del campo a la mesa.
3. **Pilar 3 — Detalle.** El supermercado es **el lugar más sensorial-cotidiano** del ecosistema — neveras zumbando, carritos rodando, escaneo de cajas, cola de clientes. Vida real.
4. **Comercial.** Permite vender Retail como **producto independiente**: un servidor que solo quiere "supermercado realista" lo compra + bridges NPCs upstream. Modularidad.
5. **B2C masivo.** Es **el primer nodo donde el B2C es 90%+ del negocio** — desbloquea pattern arquitectónico de "comercio de alta rotación" que reusaremos en futuras verticales (gasolineras, restaurantes, fast food).
6. **Lineage trace público.** El cliente final escanea su ticket y **VE el origen** — la baguette de la Panadería La Almirantazgo, hecha con harina del Molino San Juan, hecha con trigo de la Granja del Río parcela P03. **Es el wow narrativo más amplio del ecosistema** — alcanza a TODOS los players del servidor.

### 1.3 Los 3 tiers de Retail — modularidad comercial

| Tier | Footprint | SKUs | Cajas | Empleados típicos | Target servidor |
|---|---|---|---|---|---|
| **Tienda de barrio** | 8×6m | 50-100 | 1 caja | Encargado + 1 reponedor | RP indie, vecindario, conveniencia |
| **Supermercado (canónico)** | 25×20m | 200-300 | 2-3 cajas | Encargado + 2-3 empleados + 1 cajero | Servidores medios — **default oleada 1** |
| **Hipermercado** | 50×40m | 500+ | 4-6 cajas + autoservicio | Encargado + 5-8 empleados + 3 cajeros | Servidores grandes, RP urbano denso |

> **Implementación oleada 1:** entregamos **Supermercado canónico** + flag config para "small_mode" (Tienda barrio). **Hipermercado llega oleada 2.**

### 1.4 Anti-patrones específicos del Retail

- ❌ **Lineales estáticos sin lógica de stock.** Cuando un cliente compra, **el lineal visiblemente baja**. Cuando reponedor repone, sube.
- ❌ **Productos sin lineage.** Cada SKU del lineal lleva su lineage trace.
- ❌ **Caja como menú abstracto.** Cada caja es **POS físico** con anim del cajero pasando productos por escáner + sound `retail_pos_beep` + tique impreso.
- ❌ **Cliente walk-in sin carrito.** Los PEDs llevan **cesta o carrito visible** según volumen de compra.
- ❌ **Pricing fijo eterno.** Markup configurable por SKU, promociones temporales, descuentos por proximidad de caducidad.
- ❌ **Sin colas en hora pico.** Es realista que haya cola — gameplay del cajero (hora pico) es real.
- ❌ **Stock infinito.** Si el lineal se vacía, no hay producto. Si backroom se vacía, hay que pedir al proveedor.
- ❌ **Categoría única indiferenciada.** Mínimo 5-7 secciones visualmente distintas.
- ❌ **Carteles genéricos sin marca.** Cada lineal tiene **signage Admirals brass** + carteles de sección + carteles de oferta.
- ❌ **Producto idéntico al de Bakery.** El producto en Retail es **el mismo ítem físico** que salió de Bakery — mismo modelo 3D, mismo lineage. NO duplicar SKUs.

### 1.5 La promesa wooow específica del Retail

**Los 3 wow primarios:**

1. **El lineal lleno y vivo.** Lineal de panadería con cestas de mimbre, baguettes apiladas, carteles de precio brass. Cuando un cliente coge una, el lineal baja visiblemente. **Vida.**
2. **El paso por caja con tique con lineage.** Cliente llega a caja con cesta → cajero pasa productos uno a uno con anim escáner + sound beep → tique impreso con TODOS los lineage traces. Player escanea QR del tique en su Tablet → **ve granja, parcela, fecha, panadero, todo**.
3. **La hora pico viva.** 7-9pm: 8 PEDs simultáneos, carritos cruzándose, 2 cajas con cola, reponedor metiendo lineales, encargado supervisando. **Vida real comercial.**

---

## 2. Topología del nodo — el MLO del Retail

### 2.1 Visión general (Supermercado canónico)

> **MLO único, urbano.** Ubicación canónica recomendada: **Vespucci / Mirror Park / Vinewood Boulevard**. Acceso para camiones por trasera.

**Tamaño:** **25m × 20m de planta + zona backroom + parking exterior + dock de carga trasero.**

**Concepto:** **doble flujo separado** — frente público con escaparate + parking + entrada peatonal + trasera con dock para camiones. **NO se cruzan** — clientes no ven recepción de mercancía.

### 2.2 Zonas funcionales

| # | Zona | Función | Visible desde fuera |
|---|---|---|---|
| Z1 | **Entrada / Vestíbulo** | Carritos disponibles + cestas + ofertas semana | Sí — fachada |
| Z2 | **Sección Panadería** | Lineales de pan + neveras bollería | No |
| Z3 | **Sección Lácteos / Frío** | Neveras de leche, yogures, queso, mantequilla | No |
| Z4 | **Sección Frescos / Hortalizas** | Lineales abiertos + balanza self-service | No |
| Z5 | **Sección Despensa / Seca** | Pasillos largos productos no perecederos | No |
| Z6 | **Sección Bebidas** | Estanterías altas + neveras bebidas frías | No |
| Z7 | **Sección No-alimentación** | Higiene, limpieza, papel, snacks | No |
| Z8 | **Cajas / POS** | 2-3 cajas registradoras con cinta + escáner | Sí (parcial) |
| Z9 | **Salida / Bagging area** | Empaquetado bolsa cliente | Sí (parcial) |
| Z10 | **Backroom — Almacén general** | Palets de stock por categoría | No |
| Z11 | **Backroom — Cámara fría grande** | Stock perecederos | No |
| Z12 | **Backroom — Recepción mercancía** | Dock + báscula + zona albaranes | Sí — trasera |
| Z13 | **Despacho del encargado** | Oficina con dock Tablet + cámaras + caja fuerte | No |
| Z14 | **Vestuario empleados** | Cambio uniforme + taquillas | No |
| Z15 | **Aseos clientes (opcional)** | Baño público | No |
| Z16 | **Parking exterior** | 10-15 plazas | Sí — frente |
| Z17 | **Dock trasero** | Acceso camiones proveedores | Sí — trasera |

### 2.3 Plano conceptual

```
                        PARKING (Z16)
            ┌────────────────────────────────────┐
            │  [Z1 entrada / vestíbulo]          │   ← clientes walk-in
            │  ┌──────────────────────────────┐  │
            │  │ [Z2 panadería] [Z3 lácteos]  │  │
            │  │ [Z4 frescos]   [Z5 despensa] │  │
            │  │ [Z6 bebidas]   [Z7 no-alim]  │  │
            │  │  ━━━━━━━━━━━━━━━━━━━━━━━━━   │  │ ← lineales
            │  │  [Z8 caja1] [Z8 caja2] [Z8 c3]│  │
            │  │  [Z9 salida / bagging]        │  │
            │  └──────────────────────────────┘  │
            │  ┌──────────────────────────────┐  │
            │  │  BACKROOM                     │  │
            │  │  [Z10 almacén] [Z11 cám fría]│  │
            │  │  [Z12 recepción] [Z13 desp.] │  │
            │  └──────────────────────────────┘  │
            │           [Z17 dock trasero]      │
            └────────────────────────────────────┘
                  CALLE TRASERA (camiones)
```

### 2.4 Capacidad física

| Zona | Capacidad |
|---|---|
| Z1 entrada | 4-6 carritos + 8-10 cestas + 2 estanterías ofertas |
| Z2 panadería | 3 lineales (pan + bollería refrig + bollería ambiente) |
| Z3 lácteos | 4 neveras verticales + 1 mostrador queso |
| Z4 frescos | 2 lineales abiertos + 1 balanza self-service brass |
| Z5 despensa | 3 pasillos largos (~6m) lineales doble cara |
| Z6 bebidas | 2 lineales + 1 nevera frías + zona vinos premium |
| Z7 no-alim | 2 lineales |
| Z8 cajas | 3 POS canónicos (small=1, hipermercado=4-6) |
| Z9 salida | Mesa bagging + 2-3 PEDs simultáneos |
| Z10 almacén | 20 palets en racks |
| Z11 cámara fría | 4m × 3m con estantes |
| Z12 recepción | 1 dock + transpaleta + báscula |

---

## 3. Productos vendidos — catálogo cross-vertical

### 3.1 Filosofía del catálogo Retail

> **El Retail NO crea productos.** Recibe ítems físicos de upstream (Panadería + suppliers + futuras verticales) y los revende. **El SKU del lineal es el MISMO ítem físico que salió del productor.**

**Implicación arquitectónica clave:**
- Item `bread_baguette_classic_v1` con batch `BAK-2026-04-30-A-0042` que produjo Carlos Méndez en Panadería La Almirantazgo es **el mismo ítem** que aparece en el lineal de Z2.
- Cuando el cliente lo compra, **el `lineage_trace` se preserva al 100%** — sin abstracción, sin pérdida de datos.
- El ticket impreso lleva el lineage completo escaneable.

### 3.2 Categorías oleada 1 — productos disponibles

> **Oleada 1:** mayoría de SKUs vienen de Panadería + NPC suppliers para categorías sin vertical jugable aún. Oleadas futuras desbloquean cada categoría como cadena real.

#### 3.2.1 Panadería (Z2) — vertical real oleada 1

**Origen:** Panadería Admirals (B2B contractual) o NPC bridge si servidor no tiene Panadería.

| SKU | Markup default | Vida útil retail |
|---|---|---|
| `bread_white_basic` | 0.65€ → 1.10€ (+35%) | 24h prime, 48h descontado |
| `bread_whole_country` | 1.40€ → 2.30€ (+40%) | 36h prime |
| `bread_baguette_classic` | 0.85€ → 1.40€ (+50%) | **12h prime** ⚠ |
| `bread_sourdough_rustic` | 3.50€ → 5.50€ (+45%) | 72h prime |
| `pastry_croissant_butter` | 1.20€ → 2.20€ (+60%) | 12h prime |

#### 3.2.2 Lácteos (Z3) — NPC supplier oleada 1, vertical real oleada 2

NPC supplier "Lácteos del Valle". Productos: `milk_1L`, `yogurt_pack4`, `cheese_manchego_block`, `butter_block_250g`.

#### 3.2.3 Frescos (Z4) — NPC supplier oleada 1

NPC supplier "Hortalizas del Sur". Productos: `tomato_kg`, `lettuce_unit`, `apple_kg`, `carrot_kg`.

#### 3.2.4 Despensa / seca (Z5) — NPC supplier oleada 1

NPC supplier "Distribución Generalista". Productos: `pasta_500g`, `rice_kg`, `oil_olive_1L`, `salt_1kg`, `sugar_1kg`, `flour_white_1kg` (variante consumer del saco 25kg de Molino).

#### 3.2.5 Bebidas (Z6) — NPC supplier oleada 1

NPC supplier "Bebidas Premium SL". Productos: `water_bottle_1.5L`, `soda_can_330ml`, `wine_red_750ml`, `beer_pack6`, `juice_orange_1L`.

#### 3.2.6 No-alimentación (Z7) — NPC supplier oleada 1

NPC supplier "Hogar SL". Productos: `paper_towels`, `soap_bar`, `detergent_1kg`, `toothpaste_75ml`, `cigarettes_pack`.

### 3.3 Total catálogo oleada 1

| Categoría | SKUs jugables | Origen |
|---|---|---|
| Panadería | 5 | Panadería Admirals (real) |
| Lácteos | 6 | NPC supplier |
| Frescos | 8 | NPC supplier |
| Despensa | 12 | NPC supplier |
| Bebidas | 10 | NPC supplier |
| No-alim | 8 | NPC supplier |
| **Total** | **~50 SKUs canónicos** | 5 (10%) reales + 45 (90%) NPC bridge |

> **Oleadas 2-4:** cada categoría se "activa" como vertical jugable. Target end-of-oleada-4: 80%+ SKUs con lineage real player-produced.

### 3.4 Pricing model — markup, promociones, descuentos ⭐

> **Específico Retail — el primer nodo del ecosistema con sistema de pricing dinámico real.**

#### 3.4.1 Markup base por SKU

- Cada SKU tiene `cost_b2b` (precio que pagó el Retailer al proveedor) y `price_retail` (precio venta cliente).
- Markup default por categoría:
  - Panadería: 35-60%
  - Lácteos: 25-40%
  - Frescos: 30-50%
  - Despensa: 20-35%
  - Bebidas: 40-80% (margen estrella)
  - No-alim: 50-100% (margen rey)
- **El Retailer ajusta** cada SKU desde la Tablet — Manager Panel §7.4.

#### 3.4.2 Promociones temporales

- "2x1 en croissants este sábado" — duración X horas, descuento Y%.
- Carteles **brass del lineal** con texto dinámico.
- **Boost de spawn rate B2C** durante promoción activa.

#### 3.4.3 Descuento por proximidad caducidad

- Última 25% de vida útil prime → -15% (autosignaling).
- Pasado prime → -40%.
- Cerca de merma → -60% o donación banco alimentos NPC.
- Etiqueta amarilla brass "Oferta del día" en modelo 3D.

#### 3.4.4 Pricing competitivo entre Retails (oleada 2+)

- Si servidor tiene 2+ supermercados player-owned: cliente PED **compara precios** (rate de spawn migra al más barato dentro de margen X%).
- Sistema oleada 2 — fuera de scope oleada 1.

### 3.5 Lineage trace en ticket de compra ⭐

> **El wow narrativo más amplio del ecosistema.**

Cuando cliente paga en caja, el ticket impreso lleva:

```
┌──────────────────────────────────────┐
│  SUPERMERCADO ADMIRALS — VESPUCCI    │
│  Ticket #4521 · 30/04/2026 · 19:42   │
│  Cajero: Sofia Rivera                │
├──────────────────────────────────────┤
│  PANADERÍA                           │
│  1× Baguette clásica         1.40€   │
│      [QR escan lineage] ⭐           │
│      → Panadería La Almirantazgo     │
│      → Molino San Juan               │
│      → Granja del Río P03            │
│  2× Croissant butter         4.40€   │
│  LÁCTEOS                             │
│  1× Leche 1L                 1.20€   │
│  1× Yogures pack 4           2.50€   │
│  FRESCOS                             │
│  1.2 kg Tomate              3.60€    │
│  ────────────────────────────────    │
│  TOTAL                       13.10€  │
│  Pago: tarjeta · IVA incluido        │
│  Gracias por su compra ⚓            │
└──────────────────────────────────────┘
```

**Mecánica:**
- Player escanea QR del ticket con su Tablet → app `Mi compra` muestra lineage de cada producto.
- Para PEDs: ticket simbólico, no escanean.
- **Marketing wow:** screenshots de tickets con lineage trace son **goldmine para admirals.studio + Tebex**.

---

## 4. Proceso físico — el ciclo del Retailer

### 4.1 Las 6 etapas del ciclo

```
[1. Recepción mercancía] → [2. Almacenado backroom] → [3. Reposición lineales]
                                                              ↓
                                                       [4. Atención cliente]
                                                              ↓
[6. Cierre y reportes diarios] ← [5. Venta + caja]
```

### 4.2 Etapa 1 — Recepción de mercancía

**Trigger:** camión proveedor llega a dock Z17.

**Acción:**
1. Notificación Tablet Encargado: "Camión Panadería La Almirantazgo en dock — pedido P-0042".
2. Empleado va a Z12 recepción.
3. Conduce transpaleta para descargar palets.
4. Tablet muestra albarán: validar contenido vs lineage esperado.
5. **Si rechazo necesario:** rechazar palet específico, anotar motivo.
6. Firmar albarán Tablet — sello digital.
7. Pago automático a proveedor vía Banca (programado por contrato B2B).

**Duración:** 5-10 min por camión.

### 4.3 Etapa 2 — Almacenado backroom

1. Empleado mueve palets de Z12 a almacén:
   - Perecederos → Z11 cámara fría.
   - No perecederos → Z10 almacén general.
2. Coloca palets en racks específicos por categoría.
3. Anim transpaleta + colocación.

**Duración:** 3-5 min por palet.

### 4.4 Etapa 3 — Reposición de lineales (la mecánica nueva ⭐)

> **Mecánica ÚNICA del nodo Retail: gestión continua de stock visible.**

**Trigger:** lineal entra "bajo stock" (umbral default 30% capacidad).

**Mecánica:**
- Tablet del Encargado muestra **mapa visual de la tienda** con código de colores:
  - 🟢 Verde: lineal lleno (>70%).
  - 🟡 Amarillo: medio (30-70%).
  - 🔴 Rojo: bajo (<30%) — **necesita reposición urgente**.
- Empleado va a backroom, coge cajas/palets del SKU necesario.
- Lleva a la sección correspondiente.
- **Anim reposición:** se acerca al lineal, abre caja, coloca productos uno a uno (3-5s/unidad).
- Lineal sube visualmente (modelo 3D dinámico — uniform `fill_count` controlado por código).

**Trade-off:**
- Reponedor lento → lineal vacío → clientes frustrados → **spawn rate B2C baja temporalmente**.
- Reponedor proactivo → lineales siempre llenos → boost reputation + spawn rate.

**Hora pico (7-9pm):** reposición debe ser constante. **Gameplay táctico real.**

### 4.5 Etapa 4 — Atención cliente walk-in

> **Reusa el patrón establecido en Bakery §8.3** con extensiones específicas Retail.

**Diferencias clave vs Bakery:**

| Aspecto | Bakery | Retail |
|---|---|---|
| Cliente entra con | Nada — va directo al mostrador | **Cesta o carrito** según volumen previsto |
| Tiempo en tienda | 1-2 min | **5-15 min** (recorrido lineales) |
| Items comprados típicos | 1-3 | **5-30** |
| Decisión compra | Pre-decidida | **Browsing — descubre productos** |
| Comportamiento | Lineal directo | **Multi-zona, recorre secciones** |

**Flow PED Retail:**

```
[Spawn fuera del MLO]
       ↓
[Walk al parking Z16 (anim coche estacionando si vehicle, o walking)]
       ↓
[Entra Z1 → coge carrito o cesta según volumen previsto]
       ↓
[Recorrido por secciones (Z2-Z7) — visita 2-5, anim mirar lineales]
       ↓
[En cada sección coge 1-N productos (anim alargar mano + decrementa lineal)]
       ↓
[Walk a cajas Z8 → elige caja con menos cola]
       ↓
[Anim espera turno con carrito]
       ↓
[Anim cajero pasa productos por escáner uno a uno]
       ↓
[Anim cliente paga (efectivo / tarjeta)]
       ↓
[Anim recibir tique + bagging Z9]
       ↓
[Walk salida Z1 → despawn fuera del MLO]
```

### 4.6 Etapa 5 — Venta y caja (POS) ⭐

> **Elaborada extensión del concepto caja registradora de Bakery.** Cada POS es prop físico complejo.

**Anatomía POS:**
- Cinta transportadora corta (60cm).
- Escáner óptico láser (beam visible al escanear — FX `retail_scanner_beam`).
- Báscula integrada para frescos (anim aguja brass).
- Pantalla cliente con total acumulado (modelo 3D LCD).
- Terminal Tablet del cajero.
- Cajón efectivo (anim apertura).
- Impresora de tickets (anim papel saliendo + sound).

**Flow caja:**
1. Cajero (player o NPC) pulsa "Iniciar venta" en Tablet.
2. Cliente coloca productos en cinta.
3. Cajero coge producto → anim escáner → sound `retail_pos_beep` → producto suma al total.
4. **Para frescos sin código:** cajero coloca en báscula → selecciona tipo → calcula precio por kg.
5. Cajero anuncia total: "Son 13.10€ por favor".
6. Cliente paga (efectivo / tarjeta).
7. Cajón abre con anim si efectivo.
8. Impresora imprime ticket con lineage QR.
9. Cliente recoge productos en bolsa (en Z9 bagging).
10. Cliente sale.

**Duración por venta:** 2-4 min según volumen.

**Hora pico:**
- 2-3 cajas operativas simultáneas.
- Colas de 3-5 PEDs por caja.
- Player cajero en gameplay intenso — escaneo rápido = más ventas/hora.

### 4.7 Etapa 6 — Cierre y reportes diarios

**Trigger:** fin de jornada — encargado decide cerrar.

**Acción:**
1. **Cierre de cada caja:** Z-report por POS (total ventas, IVA, descuadres).
2. **Recoger efectivo** → llevar a caja fuerte Z13 → anim transferencia a banco al día siguiente.
3. **Inventario diario:** Tablet muestra discrepancias (stock teórico vs físico) — opción reconcile (mermas, robos, errores).
4. **Reportes:** Tablet genera reporte day-end con KPIs.
5. **Limpieza:** anim empleado fregando suelos (5-10 min, opcional).
6. **Cerrar puertas:** anim Encargado cerrando con llave brass.

**Duración total cierre:** 15-20 min.

---

## 5. Mobiliario y equipamiento — catálogo detallado

> **Aplicando regla Bible §13.4:** 3D entrega modelos sólidos con la idea wow CORE; código añade dynamic stock visualization, sounds, FX, glow.

### 5.1 Lineal estándar — `retail_shelf_standard`

**Descripción:** estantería metálica blanca de 4 baldas, 1.5m alto × 1m ancho × 0.4m profundo. Diseño retail clásico con **frente de venta** (productos visibles desde pasillo). Detalles brass Admirals en remates verticales.

**3D entrega:** mesh con 4 baldas + estructura + remates brass laterales. Texture: blanco luminoso + brass detail. **Variantes pre-rellenadas** con productos arquetípicos (canónico, no funcional).

**Código añade:**
- **Stock dinámico visible** — uniform `fill_count` 0-N por balda controla visibility de props productos individuales.
- Cuando cliente coge ítem → fill_count decrementa → modelo refleja.
- Cuando reponedor repone → fill_count aumenta.
- Etiquetas de precio en frente — text dynamic vía code.

### 5.2 Nevera vertical — `retail_fridge_vertical`

**Descripción:** nevera comercial 2m × 1.2m × 0.7m con puerta cristal frontal full-height, iluminación LED interior, 4-5 baldas. Detalle brass en manija + signage Admirals encima.

**3D entrega:** mesh con puerta cristal + interior baldas + base motor + signage brass arriba. Texture: blanco + cristal + brass + LED interior. Anim apertura puerta. Variantes con productos.

**Código añade:**
- **Glow LED interior** (uniform `fridge_lit` 0-1).
- **Condensación cristal** (texture variant según humidity_level).
- Sound `retail_fridge_hum` ambient + `retail_fridge_door_open`.
- Stock dinámico (uniform `fill_count`).

### 5.3 Nevera horizontal abierta — `retail_fridge_open_top`

**Descripción:** nevera abierta tipo isla central, 3m × 1m × 1m alto, sin puerta. Para frescos refrigerados (yogures, queso, mantequilla). Detalle brass en remates.

**3D entrega:** mesh con cuba abierta + estructura blanca + remates brass + iluminación interior.

**Código añade:**
- Vapor frío sutil (FX `retail_fx_cold_air_subtle`).
- Sound compresor.
- Stock dinámico.

### 5.4 Caja registradora POS — `retail_pos_station` ⭐

**Descripción:** estación POS completa con cinta transportadora corta 60cm + escáner óptico arriba + báscula integrada + pantalla cliente + terminal Tablet del cajero + cajón efectivo. **Hero prop wow del nodo.** 1.5m × 0.8m × 1.2m alto.

**3D entrega:** mesh con cinta + estructura blanca + escáner brass + báscula brass + pantalla LCD + cajón frontal. Texture: blanco + brass + LCD glass. Anim cajón abriendo + cinta moviendo + báscula aguja.

**Código añade:**
- **Beam láser visible escáner** al escanear (FX `retail_scanner_beam`).
- Cinta transportadora moviéndose (uniform `belt_speed`).
- Pantalla LCD muestra total acumulado (text dynamic).
- Báscula aguja gira con peso.
- Sound layers: `retail_pos_beep`, `retail_pos_belt_motor`, `retail_pos_drawer`, `retail_pos_print`.

### 5.5 Carrito de la compra — `retail_shopping_cart`

**Descripción:** carrito metálico con 4 ruedas + asa, 80cm × 50cm × 90cm. Barra brass discreta en asa.

**3D entrega:** mesh con cesto malla metálica + ruedas + asa con detalle brass. Anim ruedas girando.

**Código añade:**
- Sound `retail_cart_rolling` posicional.
- Stock dinámico interno — uniform `fill_count` muestra productos apilados visualmente.
- Player puede coger carrito y empujarlo (adjunto al character).

### 5.6 Cesta de mano — `retail_shopping_basket`

**Descripción:** cesta plástica naranja con asas plegables, 40cm × 30cm × 25cm.

**3D entrega:** mesh sólida + asas. Variantes con/sin productos.

**Código añade:**
- Stock dinámico.
- Player puede llevarla en mano (anim).

### 5.7 Balanza self-service frescos — `retail_scale_selfservice`

**Descripción:** balanza brass para que cliente pese hortalizas/frutas y obtenga etiqueta. 0.5m × 0.4m × 0.4m, con plato superior + pantalla LCD + impresora etiquetas.

**3D entrega:** mesh con plato brass + display + dispenser etiqueta.

**Código añade:**
- Aguja brass + uniform `weight` igual que Bakery scale.
- LCD muestra peso + precio calculado.
- Anim impresora dispensa etiqueta adhesiva con código de barras + precio.
- Sound `retail_scale_print`.

### 5.8 Signage de sección — `retail_section_sign`

**Descripción:** cartel suspendido del techo encima de cada sección, brass-framed con texto "PANADERÍA" / "LÁCTEOS" / etc. Iluminación interior subtle.

**3D entrega:** mesh frame brass + panel texto + cadenas suspensión.

**Código añade:**
- Text dynamic vía code (cada sección configurable).
- Glow brass subtle (uniform `signage_lit`).

### 5.9 Cartel de oferta — `retail_promo_sign`

**Descripción:** cartel pequeño portable que se coloca sobre lineales en promociones. Marco brass + papel impreso con texto "2x1" / "OFERTA" / "-30%".

**3D entrega:** mesh marco brass + plano papel.

**Código añade:**
- Text + visual dinámico según promoción activa.
- Glow brass subtle.

### 5.10 Caja fuerte despacho — `retail_safe_office`

**Descripción:** caja fuerte mediana en Z13 despacho, 60cm × 50cm × 70cm. Hierro grueso + dial brass combinación + bisagras.

**3D entrega:** mesh con dial brass + puerta + bisagras. Anim apertura puerta + dial girando.

**Código añade:**
- Sound `retail_safe_dial` + `retail_safe_open`.
- Estado contenido (efectivo dentro o vacío).

### 5.11 Resumen budget mobiliario oleada 1

| Asset | Custom 3D | Aparece en |
|---|---|---|
| `retail_shelf_standard` | 1 (con states fill) | Z2-Z7 secciones |
| `retail_fridge_vertical` | 1 | Z3 lácteos + Z6 bebidas |
| `retail_fridge_open_top` | 1 | Z3 lácteos |
| `retail_pos_station` | 1 (hero prop) | Z8 cajas |
| `retail_shopping_cart` | 1 | Z1 + en uso por PEDs |
| `retail_shopping_basket` | 1 | Z1 + en uso por PEDs |
| `retail_scale_selfservice` | 1 | Z4 frescos |
| `retail_section_sign` | 1 (con text dynamic) | Suspendido en cada sección |
| `retail_promo_sign` | 1 | En lineales con promo |
| `retail_safe_office` | 1 | Z13 despacho |
| **Total mobiliario custom** | **10 (oleada 1)** | |

> Cabe en budget Bible §13.4 (≤25 assets per node). Quedan slots para escenografía + props + items en §11.

---

## 6. Sistema de empresa — adaptación al Retail

> **Reusa la arquitectura validada de Granja §11 / Molino §6 / Bakery §6.** Mismo modelo: roles + dual-pool de caja + contratos B2B vía Tablet + permisos. Los específicos del Retail son la **multiplicidad de proveedores upstream** y la **escala del equipo** en hipermercado.

### 6.1 Empresa "Retail Admirals" — definición

```yaml
business_type: "retail_admirals"
business_class: "agg_storefront"   # nuevo class — agregador con storefront masivo
required_assets:
  - mlo_retail (variante elegida: small/standard/hipermercado)
  - shelf_standard (mín 8)
  - fridge_vertical (mín 2)
  - pos_station (mín 1)
  - safe_office (mín 1)
ownership_modes: ["player_solo", "player_group", "npc_bridge"]
default_currency: "EUR"
b2c_dominant: true   # ⭐ flag específico — gameplay optimizado para alto volumen B2C
```

### 6.2 Roles de la empresa Retail

| Rol interno | Permisos | Sueldo base |
|---|---|---|
| **Encargado** (owner / CEO) | Todo. Contratos B2B con proveedores. Pricing. Contratación. Banca. | Sin sueldo (cobra dividendos). |
| **Subencargado** | Operar todo excepto firmar contratos B2B. Gestionar turnos. | 200-300€/turno. |
| **Cajero** | Operar POS. Cobrar clientes. Cerrar caja Z-report. NO toca pricing ni contratos. | 100-150€/turno. |
| **Reponedor** | Recepción mercancía + reposición lineales + limpieza. NO opera POS. | 90-130€/turno. |
| **Vigilante** (opcional) | Patrulla MLO, previene robos, RP eventos seguridad. | 110-150€/turno. |

> **Específico del Retail:** rol **Cajero** y **Reponedor** son **especializaciones del Dependiente** establecido en Bakery. El Retail tiene equipos más grandes — diseño de turnos importa más.

### 6.3 Dual-pool de caja (mismo modelo)

- **Caja Operativa** — gastos día a día (compra mercancía a proveedores, sueldos, electricidad, mantenimiento).
- **Caja de Inversión** — capital reserva (expansión MLO, comprar 2º POS, contratos pesados con proveedores premium).

**Específico Retail:** la caja se alimenta MAYORITARIAMENTE de **B2C** (90%+) — diferencia esencial con Granja/Molino/Bakery donde B2B domina.

> Tablet muestra dashboard con flujo: "Hoy hemos vendido 4.250€ B2C en 142 transacciones · Hemos pagado 1.890€ a proveedores".

### 6.4 Contratos B2B disponibles para el Retail (como cliente upstream)

> **Diferencia clave:** el Retail es **cliente B2B masivo**. Su gestión de contratos es como **comprador**, no como vendedor.

| Tipo | Quién firma con el Retail | Ejemplo |
|---|---|---|
| **Suministro Panadería diario** | Panadería player | "150 baguettes + 80 panes integrales/día, lun-vie." |
| **Suministro Lácteos semanal** | NPC supplier oleada 1 (player oleada 2) | "200 leches 1L + 100 yogures pack 4 / semana." |
| **Suministro Frescos diario** | NPC supplier (player oleada 2) | "30kg tomate + 25kg lechuga / día." |
| **Suministro Despensa quincenal** | NPC supplier "Distribución Generalista" | "Pasta + arroz + aceite + sal — pedido cada 15 días." |
| **Suministro Bebidas semanal** | NPC supplier "Bebidas Premium SL" | "Mix bebidas — pedido cada lunes." |
| **Suministro No-alim mensual** | NPC supplier "Hogar SL" | "Higiene + limpieza + papel — pedido cada mes." |

### 6.5 Pipeline de gestión de proveedores (vista del Encargado Retail)

```
[Encargado abre Tablet → app "Proveedores"]
       ↓
[Ve directorio de proveedores disponibles en servidor]
       ↓
[Filtra por categoría: Panadería / Lácteos / etc.]
       ↓
[Solicita oferta — cantidad + frecuencia + calidad mínima]
       ↓
[Negocia precio/frecuencia/penalty cláusulas en chat Tablet]
       ↓
[Firma con sello brass]
       ↓
[Contrato activo — recepciones automáticas según frecuencia]
       ↓
[Pago automático al proveedor vía Banca]
```

### 6.6 Sueldos y dinámica turnos

> **Específico Retail — turnos largos con horario comercial extenso (8h-22h típico).**

| Turno | Horario canónico | Quién |
|---|---|---|
| **Apertura / mañana** | 08:00 - 14:00 (6h) | Encargado/subencargado + 1 cajero + 1 reponedor |
| **Tarde / hora pico** | 14:00 - 22:00 (8h) | Subencargado + 2 cajeros + 1 reponedor |
| **Recepción mercancía** | 06:00 - 08:00 (2h pre-apertura) | 1 reponedor + 1 supervisor |

> Servidores con time-cycle acelerado adaptan automáticamente.

---

## 7. Manager Panel del Retailer — apps Tablet específicas

> **6 áreas, mismo lenguaje visual** que Granjero/Molinero/Panadero + 1 área NUEVA específica de Retail (multi-SKU pricing).

### 7.1 Áreas del Manager Panel del Retailer

| # | Área | Función |
|---|---|---|
| 7.1.1 | **Dashboard** | KPIs día: ventas totales, ticket medio, top SKUs, mermas, satisfacción. |
| 7.1.2 | **Stock y reposición** | Mapa visual tienda con código colores 🟢🟡🔴 + alertas reposición. |
| 7.1.3 | **Pricing y promociones** ⭐ | **Nueva área específica** — gestión markup por SKU + crear promociones. |
| 7.1.4 | **Cajas / POS** | Estado cajas operativas + Z-reports + cobros del día. |
| 7.1.5 | **Proveedores y compras** | Contratos B2B activos + pedidos del día + agenda recepciones. |
| 7.1.6 | **Empleados y turnos** | Roster + turnos + sueldos + permisos. |

### 7.2 Dashboard del Retailer — anatomía

```
┌─────────────────────────────────────────────────┐
│  SUPERMERCADO ADMIRALS — VESPUCCI       19:42   │
│  Hoy — Martes 30 abril                          │
├─────────────────────────────────────────────────┤
│  VENTAS HOY                                     │
│  · Total bruto:        4.250€  (142 tx)         │
│  · Ticket medio:        29.93€                  │
│  · Top SKU:    Baguette clásica (38 ud)         │
│  · 2ª SKU:     Leche 1L          (32 ud)        │
├─────────────────────────────────────────────────┤
│  STOCK CRÍTICO                                  │
│  🔴 Pan blanco (3 ud lineal Z2)                 │
│  🔴 Croissant (5 ud lineal Z2)                  │
│  🟡 Yogures pack 4 (12 ud nevera Z3)            │
├─────────────────────────────────────────────────┤
│  RECEPCIONES HOY                                │
│  ✅ Panadería La Almirantazgo 06:45 — entregado │
│  ⏱ Lácteos del Valle 14:00 — pendiente         │
│  ⏱ Hortalizas del Sur 17:30 — pendiente        │
├─────────────────────────────────────────────────┤
│  ALERTAS                                        │
│  ⚠ Cola en caja 1: 5 clientes esperando        │
│  ⚠ 24 baguettes caducan en 2h — promocionar?   │
└─────────────────────────────────────────────────┘
```

### 7.3 App "Stock y reposición" ⭐

**Pantalla principal:**
- Vista 2D top-down de la tienda con cada lineal coloreado por estado (verde/amarillo/rojo).
- Click en lineal → ver detalle: SKU + cantidad actual + capacidad + opciones reposición.
- Botón "Repón ahora" — asigna tarea a reponedor más cercano (o player si solo).
- Filtros: ver solo críticos / ver por categoría.

**Inventario backroom:**
- Lista de palets en Z10/Z11 con SKU + cantidad + caducidad.
- Alerta si un SKU está agotado en backroom Y bajo en lineal → necesita pedido al proveedor.

### 7.4 App "Pricing y promociones" ⭐ (nueva — específica Retail)

> **Área específica que NO existe en Granja/Molino/Bakery.** Aquí gestiona el Retailer la economía de la tienda.

**Pantalla principal:**

```
┌─────────────────────────────────────────────────┐
│  PRICING & PROMOCIONES                          │
├─────────────────────────────────────────────────┤
│  POR CATEGORÍA / SKU                            │
│                                                 │
│  PANADERÍA                                      │
│  · Baguette clásica   B2B 0.85€ → 1.40€  +65%  │
│    [-] [+]      Margen unidad: 0.55€            │
│  · Pan blanco         B2B 0.65€ → 1.10€  +69%  │
│    [-] [+]      Margen unidad: 0.45€            │
│  · ...                                          │
│                                                 │
│  LÁCTEOS                                        │
│  · Leche 1L           B2B 0.85€ → 1.20€  +41%  │
│    [-] [+]      Margen unidad: 0.35€            │
│  · ...                                          │
├─────────────────────────────────────────────────┤
│  PROMOCIONES ACTIVAS                            │
│  · 2x1 Croissants (sábado 18:00 - 22:00)       │
│    Estado: [🟢 ACTIVA] · Stock vendido: 12      │
│  · -30% en Yogures (jueves todo día)           │
│    Estado: [🔴 EXPIRADA]                        │
│                                                 │
│  [+ Crear nueva promoción]                      │
└─────────────────────────────────────────────────┘
```

**Crear promoción wizard:**
1. Seleccionar SKU(s).
2. Tipo descuento (% / 2x1 / 3x2 / precio fijo).
3. Duración (horas / días).
4. Cantidad límite (opcional).
5. Confirmar → cartel **brass del lineal aparece automáticamente** + boost spawn rate.

### 7.5 App "Cajas / POS"

- Estado de cada caja: abierta/cerrada, cajero asignado, ventas acumuladas turno.
- Z-reports históricos.
- Detección anomalías (caja con discrepancia entre sistema y efectivo).
- Asignar/cambiar cajero por caja.

### 7.6 App "Proveedores y compras"

- Directorio de proveedores disponibles (incluye verticales player + NPC bridges).
- Contratos B2B activos como cliente.
- Calendario recepciones del día + próximos 7 días.
- Histórico facturación a proveedores.
- Solicitar nueva oferta a proveedor — chat negociación Tablet.

### 7.7 App "Empleados y turnos"

- Roster supermercado.
- Asignar turnos drag-and-drop semanal.
- Permisos por rol.

### 7.8 Lenguaje visual — variaciones específicas Retail

- Tonos paleta: **acentos blanco luminoso + brass + multi-color por sección** (vs cobre cálido Bakery).
- Iconografía: lineales, carritos, escáneres, neveras — versions Lucide-stylized con brass strokes.
- **Notificación signature** del nodo Retail: chime POS + visual brass scan-beam al pop notif.

---

## 8. Mercado, contratos y venta directa — el B2C masivo ⭐

> **Esta sección consolida y extiende el patrón B2C dual-channel de Bakery §8.** Retail es **el primer caso del patrón B2C dominante** — donde Bakery tenía 30% B2C, Retail tiene 90%+ B2C.

### 8.1 Los dos canales — visión Retail

```
                         RETAIL
                            │
            ┌───────────────┴──────────────┐
            ▼                              ▼
   CANAL B2B (entrante)          CANAL B2C (walk-in masivo) ⭐
            │                              │
   Contratos como CLIENTE          Cliente PED entra,
   con proveedores upstream.       coge productos en
   Recepción palets diaria.        carrito, pasa por caja.
   Pago bancario programado.       Efectivo o tarjeta.
            │                              │
   90%+ del volumen del nodo       NO es complemento — ES el negocio.
   ENTRA por B2B...                ...SALE por B2C.
```

### 8.2 Canal B2B (entrante — como cliente)

> **Diferencia clave vs Bakery:** Bakery firma contratos B2B como **vendedor**. Retail firma como **comprador**. **Mismo modelo arquitectónico, lado opuesto del flujo.**

**Tipos de contrato B2B Retail (entrantes):**
- Suministro Panadería diario (entregas mañana 6-7am).
- Suministro Lácteos semanal (entregas martes/jueves).
- Suministro Frescos diario (entregas mañana 6am).
- Suministro Despensa quincenal (entregas grandes 2 veces/mes).
- Suministro Bebidas semanal (lunes).
- Suministro No-alim mensual (1 entrega gran palet).

**Penalty cláusulas (cuando proveedor falla):**
- Entrega tardía → -10% pago al proveedor.
- Calidad bajo mínimo → opción rechazo total.
- Falta stock proveedor → derecho a buscar suplente urgente con pago premium.

### 8.3 Canal B2C (walk-in masivo) ⭐⭐

> **Mecanismo extiende lo establecido en Bakery §8.3 con escala Retail.** PEDs walk-in con spawn rate dinámico — pero AHORA con **comportamiento más complejo** (recorrido multi-zona, carrito, browsing).

#### 8.3.1 Generación de clientes PED

**Sistema:** spawn de PEDs walk-in con **rate dinámica** según hora del día y atractivo de la tienda. **Mucho mayor que Bakery** — supermercado debe sentir vivo.

**Factores que afectan spawn rate:**

| Factor | Impacto |
|---|---|
| **Hora del día** | 8-10am medio (× 2) · 10-14h alto (× 3) · 14-19h alto (× 3) · **19-22h pico (× 5)** ⭐ · 22-08h cerrado |
| **Día de la semana** | Sábado pico (× 1.4) · Domingo medio (× 0.7) si abierto |
| **Stock lineales** | Avg lineales >70% (× 1.3) · <30% (× 0.5) |
| **Pricing competitivo** | -10% vs media servidor (× 1.4) · +20% (× 0.7) |
| **Promociones activas** | +15-30% por promoción activa visible |
| **Reputation tienda** | Score 0-100 acumula con calidad consistente |
| **Tráfico zona MLO** | Vespucci alto · Paleto Bay bajo |

**Configuración:**
- Servidor admin define `retail_walkin_baseline_rate` (ej. "1 PED cada 60s baseline").
- Sistema multiplica por factores.
- Cap superior: max **8-12 PEDs simultáneos** dentro del MLO supermercado canónico.

#### 8.3.2 Comportamiento del PED customer (extendido vs Bakery)

```
[Spawn fuera del MLO]
       ↓
[Llega en coche al parking O caminando]
       ↓
[Anim PED estaciona/llega a entrada]
       ↓
[Entra Z1 → coge carrito (60% chance) o cesta (40%)]
       ↓
[Decide ruta — visita 2-5 secciones aleatoriamente]
       ↓
[En cada sección]
       ├─ Anim "browse" mirando lineal (5-10s)
       ├─ Decide coger 1-3 productos (anim alargar mano)
       ├─ Stock lineal decrementa
       └─ A veces "deja producto" (anim devolver — RP realista)
       ↓
[Walk a cajas Z8 → elige caja con menos cola]
       ↓
[Wait queue (anim idle con carrito)]
       ↓
[En su turno: coloca productos en cinta (anim)]
       ↓
[Cajero escanea uno a uno (anim)]
       ↓
[Anuncia total: "Son 13.10€ por favor"]
       ↓
[PED elige método pago (efectivo 30% / tarjeta 70%)]
       ↓
[Anim pago + recibe ticket]
       ↓
[Va a Z9 bagging — empaca en bolsa]
       ↓
[Anim sale por Z1]
       ↓
[Despawn fuera del MLO]
```

**Volumen comportamiento por PED:**
- Compra mínima: 1 producto (PED pasa rápido).
- Compra media: 5-10 productos.
- Compra grande (sábado mañana): 15-30 productos.

**Variación de modelos PED:** mínimo 15-20 modelos PED distintos para evitar repetición visible.

#### 8.3.3 Player customers

> **Players reales también compran como customers.** Mismo flow pero sin AI:
- Player walk-in entra al MLO.
- Coge carrito o cesta.
- Recorre secciones — interacciona con lineales (target prompt "Coger 1 unidad").
- Su carrito muestra ítems acumulados.
- Va a caja → cajero player (o NPC si no hay) escanea + cobra.
- Recibe ítems físicos en inventario.

> **Cierra el ciclo del Pilar 1 narrativamente:** un player entra a comprar a la tienda Admirals — la tienda en su servidor de RP normal. La compra es **real, física, con lineage**.

#### 8.3.4 POS — UX del cobro masivo

> **Extensión y especialización del concepto caja registradora de Bakery §8.3.4.**

**Diferencias específicas Retail:**
- Multi-producto por venta (vs 1-2 en Bakery).
- Cinta transportadora física donde el cliente apila productos.
- Escáner óptico láser que lee códigos de barras (vs entry manual en Bakery).
- Báscula integrada para frescos sin código.
- Tickets más largos con secciones por categoría.
- **Escaneo más rápido** = más ventas/hora = más ingresos. **Skill cajero importa.**

**Skill cajero:**
- XP del player cajero acumula con escaneos.
- Mayor skill → menor tiempo por escaneo (de 2s → 0.8s).
- Hora pico premia skill — colas se mueven 2-3× más rápido.

#### 8.3.5 Stock lineales — sistema físico

> **El stock del lineal es STOCK FÍSICO real visible.** No abstracto.

- Cada balda de cada lineal tiene capacidad limitada (8-30 unidades según producto).
- Cuando cliente coge unidad → balda decrementa visualmente.
- Cuando reponedor repone → balda incrementa visualmente.
- **Si lineal vacío:** cliente PED cambia comportamiento ("no estaba lo que buscaba", deja review negativa, baja reputation).
- **Visual real:** un lineal con 30 baguettes se ve diferente a uno con 3.

### 8.4 Pricing dinámico — el sistema de markup Retail ⭐

> **Específico Retail — el primer nodo del ecosistema con pricing dinámico real.**

#### 8.4.1 El Retailer ajusta cada SKU

- Tablet Manager Panel §7.4 permite ajustar markup por SKU.
- Cambios efectivos inmediatos en lineales (etiquetas precio actualizadas vía code).
- Trade-off real:
  - Markup alto → más beneficio por unidad pero menos volumen (clientes compran menos).
  - Markup bajo → menos beneficio por unidad pero más volumen y reputation.

#### 8.4.2 Promociones temporales

- Wizard Tablet crea promoción.
- **Cartel brass aparece automáticamente** sobre el lineal afectado.
- **Boost spawn rate B2C +15-30%** durante duración.
- Producto rota más rápido — defrosting de stock cerca de caducidad.

#### 8.4.3 Descuento por proximidad caducidad

- Sistema automático aplica:
  - Última 25% de vida útil prime → -15%.
  - Pasado prime → -40%.
  - Cerca merma → -60% o donación banco alimentos.
- Etiqueta amarilla brass "Oferta del día" en modelo 3D.

#### 8.4.4 Pricing competitivo entre Retails (oleada 2+)

- Si servidor tiene 2+ supermercados player-owned: PEDs **comparan precios**.
- Sistema oleada 2 — fuera de scope oleada 1.

### 8.5 Reputation system de la tienda

> **Sistema más complejo que Bakery por volumen de transacciones.**

- Score 0-100 público.
- Sube con: lineales siempre llenos, calidad consistente, precios competitivos, colas cortas, satisfacción cliente.
- Baja con: lineales vacíos, productos caducados, precios abusivos, colas largas, robos no controlados.
- **Visible en directorio Tablet** — clientes B2C eligen tienda según reputation.
- **Afecta spawn rate B2C masivamente** (§8.3.1).

---

## 9. Edge cases del Retail

### 9.1 Cliente PED no encuentra producto en lineal

**Trigger:** PED busca SKU específico, lineal vacío.

**Comportamiento:**
- Anim PED visible "buscando" — mira en otros sitios, espera 5-10s.
- 60% chance se va sin comprar nada → reputation -1.
- 40% chance compra algo más (sustitución).
- Si recurrente: alerta Tablet "Lineal X agotado durante 2h hoy".

### 9.2 Cola en caja excesiva

**Trigger:** >5 clientes en cola en una caja.

**Comportamiento:**
- 40% chance algunos PEDs abandonan carrito y salen → reputation -3.
- Tablet alerta: "⚠ Cola en caja 1: 7 clientes" — sugiere abrir 2ª caja.
- Si encargado abre 2ª caja → PEDs migran automáticamente.

### 9.3 Robo (shoplifting)

**Trigger:** PED malicioso sale sin pasar por caja (raro, opt-in evento RP).

**Comportamiento:**
- Sistema detecta diferencia stock vs ventas.
- Vigilante (si está) puede interceptar — anim chase + RP.
- Si no hay vigilante: pérdida absorbida por mermas.
- Repetición de robos → reputation -2 + costes seguro.

### 9.4 Producto caducado en lineal

**Trigger:** producto supera vida útil prime + descontado.

**Comportamiento:**
- Modelo 3D visible degradación.
- PEDs no lo cogen.
- Tablet notifica: "⚠ 24 baguettes caducadas — retirar".
- Producto retirado va a:
  - Banco de alimentos NPC (donación, +reputation).
  - Mermas (waste tracking).

### 9.5 Proveedor no entrega

**Trigger:** contrato B2B con proveedor falla — no llega palet.

**Comportamiento:**
- Tablet alerta: "🚨 Panadería La Almirantazgo no entregó pedido P-0042".
- Lineales de pan vacíos progresivamente.
- Encargado opciones:
  - Aceptar penalty contractual (auto-cobrada).
  - Buscar suplente urgente (NPC supplier premium con surcharge).
  - Cancelar contrato si recurrente.

### 9.6 Caja descuadrada

**Trigger:** Z-report cierre caja → discrepancia entre sistema y efectivo.

**Comportamiento:**
- Tablet alerta: "⚠ Caja 1 descuadrada: -23€".
- Encargado investiga (cámaras Z13 si activadas, RP).
- Posibles causas: error cajero, propinas no registradas, robo interno.
- Repetición → revisar contratos cajero o sistema.

### 9.7 Hora pico con personal insuficiente

**Trigger:** sábado 19-21h, sólo 1 cajero disponible.

**Comportamiento:**
- Colas excesivas (§9.2).
- Tablet alerta: "🚨 Hora pico — abre 2ª caja (necesita cajero)".
- Encargado puede operar caja temporalmente o llamar empleado off-shift.

### 9.8 Lineal mal repuesto

**Trigger:** reponedor coloca productos mal (mezcla SKUs / pone caducados delante).

**Comportamiento (oleada 2):**
- PEDs cogen producto caducado por error → quejas → reputation -3.
- Sistema detecta misordering → alerta encargado.
- Skill reponedor reduce probabilidad.

### 9.9 Recepción mercancía con shortage

**Trigger:** camión proveedor llega pero faltan unidades vs albarán.

**Comportamiento:**
- Tablet detecta diferencia → opción "Aceptar con shortage" / "Rechazar palet".
- Si acepta: descuento auto en factura proveedor.
- Si rechaza: nueva entrega negociada.

---

## 10. Hooks a otras verticales

> **El Retail es el nodo agregador — conecta con TODAS las verticales presentes y futuras.**

### 10.1 Hooks oleada 1 (activos al launch)

- **Granja Admirals** — vía Molino → Bakery → Retail (cadena del pan completa).
- **Molino Admirals** — proveedor indirecto via Bakery.
- **Panadería Admirals** — proveedor directo principal de la sección panadería.
- **Banca Admirals** — cuenta empresa, contratos B2B con proveedores, transferencias diarias, préstamos.
- **Logística Admirals** — proveedores entregan via camión a dock Z17.

### 10.2 Hooks oleada 2 (próximos)

- **Lácteos / Granja vacas** — proveedor real de leche, yogures, queso, mantequilla (oleada 2 desbloquea como vertical jugable).
- **Hortícola — Granja vegetales** — proveedor de frescos.
- **Hipermercado** (variante) — escala superior del Retail.
- **Pastelería separada** — sección dedicada en Retail.

### 10.3 Hooks oleadas futuras

- **Pasta italiana / Cervecería / Viñedo** — proveedores nacidos de oleadas 3-4.
- **Distribución mayorista** — Retails grandes pueden ser proveedores de Retails pequeños.
- **Cadena de gasolineras** — pattern Retail + dispensador combustible (futuro nodo basado en Retail arquitectura).
- **Restaurantes / Fast food** — pattern similar (B2C dominante) reusando arquitectura Retail.
- **Mercado de barrio (semanal)** — evento RP servidor con tiendas pop-up.

### 10.4 Hooks RP no comerciales

- **Eventos servidor:** "Compra solidaria" — donar % ventas a banco alimentos.
- **Festival comercial:** todos los Retails del servidor con descuentos coordinados.
- **Inspección sanidad NPC:** evento puntual donde Retail debe pasar inspección — buena calidad → +reputation.
- **Donación banco alimentos:** producto cerca merma se dona — +reputation.

---

## 11. Assets 3D — briefing equipo 3D

> **Aplicando regla Bible §13.4**: el 3D entrega el modelo funcional con la idea wow CORE. El código añade dynamic stock + scan beams + sounds + glow.

### 11.1 Lista canónica de assets 3D oleada 1

#### MLO (1 asset estructural — 3 variantes)

| Asset | Descripción | Prioridad |
|---|---|---|
| `mlo_retail_standard` | Variante canónica 25×20m: 17 zonas (§2.2), parking + dock trasero | **P0** |
| `mlo_retail_small` | Variante pequeña 8×6m: tienda barrio, 1 caja, sin backroom amplio | P1 (toggle config) |
| `mlo_retail_hipermercado` | Variante 50×40m con multi-cajas + autoservicio + zona vinos premium | **P2 (oleada 2)** |

#### Mobiliario (10 assets — §5)

| Asset | Tipo | Hero |
|---|---|---|
| `retail_shelf_standard` | Lineal estándar | – |
| `retail_fridge_vertical` | Nevera puerta cristal | – |
| `retail_fridge_open_top` | Nevera abierta isla | – |
| `retail_pos_station` | Caja registradora POS | ⭐ |
| `retail_shopping_cart` | Carrito compra | – |
| `retail_shopping_basket` | Cesta mano | – |
| `retail_scale_selfservice` | Balanza frescos | – |
| `retail_section_sign` | Cartel sección suspendido | – |
| `retail_promo_sign` | Cartel oferta portable | – |
| `retail_safe_office` | Caja fuerte despacho | – |

#### Hero props escenografía (4)

| Asset | Zona | Wow |
|---|---|---|
| `retail_entrance_archway` | Z1 entrada | Arco de entrada con logo Admirals brass + iluminación |
| `retail_checkout_lane` | Z8 | Estructura física del lane completo (cinta + barreras + signage) |
| `retail_loyalty_kiosk` | Z9 | Kiosko self-service tarjetas fidelización (oleada 2) |
| `retail_atm_machine` | Z1 | Cajero automático ATM Admirals brass — dispenser efectivo (Banca hook) |

#### Items físicos consumibles (~18 assets)

> **Importante:** muchos assets se reusan de Bakery (panes, croissants) y NPC suppliers. Los específicos de Retail son packaging consumer-facing.

| Asset | Detalle |
|---|---|
| `bread_*` (5 from Bakery) | Reuso directo — modelos panes Bakery |
| `milk_carton_1L` | Cartón leche con logo Lácteos del Valle (NPC supplier) |
| `yogurt_pack4_v1` | Pack 4 yogures plástico |
| `cheese_manchego_block` | Bloque queso curado envuelto |
| `butter_consumer_250g` | Mantequilla packaging consumer (variante de bakery butter_block_1kg) |
| `tomato_kg` | Cesta plástica tomates frescos |
| `lettuce_unit` | Lechuga envuelta plástico |
| `apple_kg` | Cesta manzanas |
| `pasta_500g` | Paquete pasta cartón |
| `rice_kg` | Bolsa arroz |
| `oil_olive_1L` | Botella aceite cristal |
| `flour_white_1kg` | Saco harina pequeño consumer (variante de Molino flour_sack_25kg) |
| `water_bottle_1.5L` | Botella plástica agua |
| `soda_can_330ml` | Lata refresco |
| `wine_red_750ml` | Botella vino tinto |
| `beer_pack6` | Pack 6 botellas cerveza |
| `paper_towels_roll` | Rollo papel cocina |
| `detergent_1kg` | Caja detergente |
| `retail_paper_bag` | Bolsa papel Retail con logo |
| `retail_plastic_bag` | Bolsa plástico Retail con logo |

#### Vehículos (reuso assets Bakery / Logística)

- Camiones proveedores: reuso `bakery_delivery_van` con liveries de cada proveedor.
- Camión Retail propio: futuro (oleada 2) para distribución mayorista.

#### Total budget oleada 1

| Categoría | Cantidad |
|---|---|
| MLO + variantes | 1 (P0) + 1 (P1 small mode) |
| Mobiliario | 10 (P0) |
| Hero props escenografía | 4 |
| Items físicos consumibles | ~18 (de los cuales ~5 reuso Bakery) |
| Vehículos | Reuso |
| **Total custom oleada 1** | **~30 piezas custom** ⚠ |

> **Nota:** Retail tiene MÁS assets que Bakery (~25) por la cantidad de SKUs visibles en lineales. Justificable por modularidad — Retail vende como producto comercial separable y reusa muchos assets en oleadas futuras.

### 11.2 Detalles wow específicos (qué se diferencia del nativo GTA)

| Asset | ¿Hay nativo aceptable? | Decisión |
|---|---|---|
| Lineales metálicos | Sí (varios props) | **Reusa nativo + texture custom + variantes con productos.** |
| Carrito compra | Sí (genérico) | **Reusa con variant Admirals brass detail.** |
| Cesta plástica | Sí | **Reusa nativo.** |
| Caja registradora POS | Hay genéricas, no premium con scanner + báscula | **Custom hero prop.** |
| Nevera vertical comercial | Sí (multiple) | **Reusa nativo + signage Admirals overlay.** |
| Nevera abierta isla | No (los gta son vertical) | **Custom.** |
| Balanza self-service | No (no hay con dispenser etiqueta) | **Custom.** |
| Cartel sección suspendido | No (con text dynamic + brass frame) | **Custom.** |
| Caja fuerte despacho | Sí (genéricas) | **Reusa nativo + dial brass detail.** |
| ATM Admirals | No (los GTA son banks regulares) | **Custom — pero compartido con Banca.** |
| Productos consumer (leche, yogur, etc.) | Sí pero genéricos | **Custom liveries Admirals proveedores brand.** |

### 11.3 Texture sets requeridos

| Material | Uso | Notas |
|---|---|---|
| `mat_retail_shelf_white` | Lineales | Blanco luminoso brushed metal + brass detail |
| `mat_retail_fridge_glass` | Puerta nevera | Cristal con shader humidity + condensación |
| `mat_retail_pos_white` | POS estructura | Blanco + brass detail premium |
| `mat_retail_signage_brass` | Carteles sección | Brass framed con panel iluminado interior |
| `mat_retail_floor_polished` | Suelo tienda | Mármol blanco-gris pulido brillante |
| `mat_retail_packaging_*` | Múltiples products | Cartón, plástico, vidrio según producto |
| `mat_retail_paper_receipt` | Ticket | Papel térmico blanco + texto dynamic |

### 11.4 Shader uniforms expuestos al código

> A registrar en `docs/art/02_shader_contracts.md`:

| Material | Uniforms | Range | Owner |
|---|---|---|---|
| `mat_retail_shelf_white` | `fill_count` | int 0-30 (productos visibles por balda) | `admirals_retail_visuals` |
|  | `price_text_*` | string (etiquetas precio) | id. |
|  | `promo_active` | bool (overlay cartel oferta) | id. |
| `mat_retail_fridge_glass` | `fridge_lit` | float 0-1 (LED interior) | id. |
|  | `humidity_level` | float 0-1 (condensación) | id. |
| `mat_retail_pos_white` | `belt_speed` | float 0-1 (cinta moviendo) | id. |
|  | `scanner_active` | bool (beam láser visible) | id. |
|  | `lcd_total_text` | string (display total venta) | id. |
| `mat_retail_signage_brass` | `signage_lit` | float 0-1 (iluminación interior) | id. |
|  | `signage_text` | string | id. |

---

## 12. Animaciones requeridas

### 12.1 Animaciones del personaje (empleado/encargado)

| Anim ID | Descripción | Duración | Loop |
|---|---|---|---|
| `retail_anim_pos_scan` | Pasar producto por escáner | 1.5s | Once per item |
| `retail_anim_pos_weigh` | Colocar fresco en báscula POS | 3s | Once |
| `retail_anim_pos_drawer_open` | Abrir cajón POS para efectivo | 2s | Once |
| `retail_anim_pos_print_receipt` | Recoger ticket impreso | 2s | Once |
| `retail_anim_shelf_restock` | Reponer lineal (colocar productos) | 4s | Yes |
| `retail_anim_pallet_move` | Mover palet con transpaleta | Loop | Yes |
| `retail_anim_dock_unload` | Descargar palet de camión | 6s | Yes |
| `retail_anim_clipboard_check` | Verificar albarán recepción | 5s | Once |
| `retail_anim_safe_use` | Manejar caja fuerte | 6s | Once |
| `retail_anim_floor_clean` | Fregar suelos | Loop | Yes |
| `retail_anim_shelf_label_change` | Cambiar etiqueta precio | 3s | Once |

### 12.2 Animaciones del cliente PED

| Anim ID | Descripción | Duración |
|---|---|---|
| `retail_anim_ped_grab_cart` | Coger carrito de la entrada | 3s |
| `retail_anim_ped_grab_basket` | Coger cesta | 2s |
| `retail_anim_ped_browse_shelf` | Mirar lineal ponderando | 5-10s |
| `retail_anim_ped_pick_item` | Coger producto de lineal | 2s |
| `retail_anim_ped_return_item` | Devolver producto a lineal | 2s |
| `retail_anim_ped_push_cart` | Empujar carrito caminando | Loop walking |
| `retail_anim_ped_carry_basket` | Llevar cesta caminando | Loop walking |
| `retail_anim_ped_wait_queue` | Esperar turno con carrito | Loop idle |
| `retail_anim_ped_load_belt` | Colocar productos en cinta POS | 5s |
| `retail_anim_ped_pay_cash` | Pagar efectivo | 3s |
| `retail_anim_ped_pay_card` | Pagar tarjeta | 3s |
| `retail_anim_ped_grab_bag` | Recoger bolsa post-compra | 2s |
| `retail_anim_ped_walk_away` | Salir de tienda con bolsa | Loop |

### 12.3 Animaciones de objetos/maquinaria (rigs)

| Rig | Descripción |
|---|---|
| `retail_rig_pos_belt_move` | Cinta transportadora moviendo |
| `retail_rig_pos_drawer` | Cajón POS abriendo/cerrando |
| `retail_rig_fridge_door` | Puerta nevera vertical |
| `retail_rig_safe_dial` | Dial caja fuerte girando |
| `retail_rig_safe_door` | Puerta caja fuerte abriendo |
| `retail_rig_atm_dispenser` | Dispenser ATM saliendo billetes |
| `retail_rig_shelf_fill` | Productos apareciendo/desapareciendo en baldas |

---

## 13. Sonidos requeridos

### 13.1 Sonidos del POS y caja (firma sonora del nodo)

| Sound ID | Descripción | Loop |
|---|---|---|
| `retail_pos_beep` | Beep escaneo producto ⭐ | No |
| `retail_pos_belt_motor` | Cinta transportadora moviendo | Yes |
| `retail_pos_drawer` | Cajón POS abriendo | No |
| `retail_pos_print` | Impresora ticket | No |
| `retail_pos_card_terminal` | Beep terminal tarjeta | No |
| `retail_pos_cash_count` | Contar billetes | No |

### 13.2 Sonidos del flujo cliente / atmosphere

| Sound ID | Descripción | Loop |
|---|---|---|
| `retail_door_chime` | Campanita brass al entrar cliente | No |
| `retail_cart_rolling` | Carrito rodando sobre suelo | Yes (mientras se mueve) |
| `retail_basket_pickup` | Coger cesta del stack | No |
| `retail_shelf_pickup` | Coger producto de lineal | No |
| `retail_paper_bag_rustle` | Bolsa papel moviendo | No |
| `retail_plastic_bag_rustle` | Bolsa plástico moviendo | No |

### 13.3 Sonidos de neveras / climatización

| Sound ID | Descripción | Loop |
|---|---|---|
| `retail_fridge_hum` | Compresor neveras ambient | Yes |
| `retail_fridge_door_open` | Puerta nevera abriendo | No |
| `retail_fridge_door_close` | Puerta nevera cerrando | No |
| `retail_aircon_amb` | Aire acondicionado tienda ambient | Yes |

### 13.4 Sonidos de PEDs clientes

| Sound ID | Descripción |
|---|---|
| `retail_ped_voice_browse_es_*` | "Hmm... ¿qué llevo hoy?" |
| `retail_ped_voice_complain_queue` | "¡Esta cola es eterna!" |
| `retail_ped_voice_compliment_low_price` | "¡Precios increíbles aquí!" |
| `retail_ped_voice_complain_empty_shelf` | "Otra vez sin pan..." |
| `retail_ped_voice_thank_cashier` | "Gracias, buen día" |

### 13.5 Sonidos de ambiente (atmosphere)

| Sound ID | Descripción | Zona |
|---|---|---|
| `retail_floor_amb_busy` | Ambiente comercial hora pico (PEDs hablando, carritos, beeps lejanos) | Z2-Z7 secciones |
| `retail_floor_amb_quiet` | Ambiente comercial hora valle | Z2-Z7 |
| `retail_backroom_amb` | Almacén con sutil ventilación + freezer | Z10-Z11 |
| `retail_office_amb_quiet` | Despacho silencioso | Z13 |

### 13.6 Notificaciones Tablet específicas Retail

| Sound ID | Descripción |
|---|---|
| `retail_notif_low_stock` | Lineal en estado crítico (rojo) |
| `retail_notif_long_queue` | Cola excesiva en caja |
| `retail_notif_supplier_arrived` | Camión proveedor en dock |
| `retail_notif_promo_active` | Promoción activada con éxito |
| `retail_notif_z_report_ready` | Z-report cierre caja listo |

### 13.7 Master mix — la firma sonora del nodo

> **Cuando un jugador entra al supermercado en hora pico, debería oír:**

1. **`retail_door_chime`** al cruzar entrada.
2. **`retail_aircon_amb`** ambient base toda la tienda.
3. **`retail_floor_amb_busy`** (PEDs hablando, carritos rodando — vida).
4. **`retail_pos_beep`** repetitivo desde Z8 (ventas activas) — característica más identificable.
5. **`retail_fridge_hum`** desde zona neveras.
6. **PED voices** ocasionales.

**Es el nodo MÁS animado y comercial del ecosistema oleada 1.**

---

## 14. Anti-patrones específicos del nodo + Roadmap

### 14.1 Anti-patrones (recordatorio crítico)

> **Cosas que rompen la promesa del nodo Retail:**

- ❌ **Lineales que no reflejan stock.** El stock visible es **el wow #1** del Retail.
- ❌ **POS sin scanner beam visible.** El láser brass del escáner debe verse al pasar producto.
- ❌ **Tickets sin lineage QR.** El ticket es el **artefacto narrativo más importante** del producto comercial.
- ❌ **PEDs sin carrito/cesta.** Los PEDs Retail SIEMPRE llevan algo — si no, parece arcade.
- ❌ **Cola sin migración entre cajas.** Si abres 2ª caja, los PEDs deben migrar visiblemente.
- ❌ **Stock infinito.** Si lineal vacío Y backroom vacío → no hay producto, hay que pedir al proveedor.
- ❌ **Pricing fijo sin gameplay.** Retailer DEBE poder ajustar markup + crear promociones — si no, no hay decisión real.
- ❌ **Multi-tienda idénticos.** Cada Retail player-owned debe tener su propia identidad (nombre + logo + rep score).
- ❌ **Promociones invisibles.** Si hay promo activa, el cartel brass del lineal DEBE aparecer + spawn rate boost.
- ❌ **Recepción mercancía sin rigor.** Albarán + lineage validation siempre — el flujo upstream se preserva.

### 14.2 Roadmap del nodo

#### Oleada 1 (T-0 launch — incluido en producto comercial "Cadena del Pan" + opcional "Retail standalone")
- ✅ MLO standard + variante small mode.
- ✅ 10 mobiliario custom + 4 hero props.
- ✅ ~50 SKUs canónicos en 6 categorías.
- ✅ 6 etapas proceso jugables con reposición continua.
- ✅ B2B contratos como cliente + B2C masivo walk-in.
- ✅ Manager Panel 6 áreas Tablet (incl. Pricing & Promociones nueva).
- ✅ PED customer system extendido con carrito + browsing.
- ✅ POS multi-producto con scanner + báscula + impresora ticket.
- ✅ Lineage trace en ticket de compra ⭐.
- ✅ Pricing dinámico con markup + promociones temporales.
- ✅ Reputation system básico.

#### Oleada 2 (T+6 meses)
- 🔜 **Variante Hipermercado** con 4-6 cajas + autoservicio + zona vinos premium.
- 🔜 **Pricing competitivo entre Retails** del servidor (PEDs comparan precios).
- 🔜 **Tarjeta fidelización Admirals** — clientes acumulan puntos via Tablet.
- 🔜 **Self-checkout** (cajas autoservicio).
- 🔜 **Verticales Lácteos + Frescos** activadas — productos con lineage real (no NPC).
- 🔜 **Cámaras de seguridad jugables** Z13 — vigilante real.
- 🔜 **Inspecciones sanidad NPC**.
- 🔜 **Eventos servidor compra solidaria**.

#### Oleada 3 (T+12 meses)
- 🔜 **Cadena de gasolineras** (pattern Retail + dispensador combustible).
- 🔜 **Restaurantes / Fast food** (B2C dominante similar).
- 🔜 **Distribución mayorista** (Retails grandes proveen a pequeños).
- 🔜 **Promociones cross-tienda** (alianzas entre Retails del mismo dueño).

#### Oleada 4+ (T+18-24 meses)
- 🔜 **Mercado de barrio semanal** (pop-up tiendas evento RP).
- 🔜 **Concursos servidor** "Mejor supermercado del año".
- 🔜 **App ecommerce Admirals** — pedido online entrega a domicilio (player repartidor).

### 14.3 Métricas de éxito del nodo

| KPI | Target oleada 1 |
|---|---|
| Tiempo medio del jugador en MLO Retail por sesión | ≥ 20 min |
| Player retention en rol Encargado a 30 días | ≥ 30% |
| Ratio B2C/B2B en Retails player-owned | 90/10 |
| Avg PEDs simultáneos en hora pico | ≥ 6 |
| Avg ticket con lineage trace generado/día | ≥ 100 |
| % de tickets escaneados QR por players | ≥ 15% |
| Rating Tebex específico al producto "Cadena del Pan" | ≥ 4.7/5 |
| Mentions del nodo Retail en streams / showcase | Tracking baseline → +200% mes 6 |

---

## 15. Estado del documento

- **Versión:** 1.0 (firmado — completo, 15 secciones, 3 partes publicadas).
- **Próxima revisión:** evolución cuando se desbloqueen verticales Lácteos / Hortícola (oleada 2).
- **Documentos hijos pendientes:**
  - `docs/economy/03_retail_economy.md` — números detallados (markups por categoría, costes B2B, balance económico).
  - `docs/technical/05_retail_implementation.md` — arquitectura técnica (multi-SKU stock state, POS event flow, PED behavior tree).
  - `docs/art/02_shader_contracts.md` — contratos materiales del nodo (§11.4 ya esbozados).

### 15.1 Changelog del documento

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 (parte 1) | 2026-05-01 | Founder + Cascade | §0-§5 (filosofía, MLO, productos, proceso 6 etapas, mobiliario). |
| 1.0 (parte 2) | 2026-05-01 | Founder + Cascade | §6-§10 (empresa, Manager Panel, B2C masivo ⭐, edge cases, hooks). |
| 1.0 (parte 3) | 2026-05-01 | Founder + Cascade | §11-§15 (assets 3D, animaciones, sonidos, anti-patrones + roadmap, estado). **Documento completo, firmable.** |

---

## Resumen ejecutivo del documento (cierre)

El **Retail Admirals** cierra la **Cadena del Pan** y abre la era del **B2C masivo del ecosistema**:

- **Es agregador, no productor** — recibe de múltiples cadenas verticales upstream y revende.
- **B2C dominante (90%+)** — primer nodo del ecosistema con consumidor final como negocio principal.
- **Pricing dinámico real** — primer nodo con markup configurable + promociones + descuentos automáticos.
- **POS físico complejo** — extensión y especialización de la caja registradora de Bakery, con scanner láser, báscula, ticket con lineage QR.
- **Reposición continua de lineales** — mecánica única del Retail, gameplay táctico real.
- **Cierra la promesa narrativa Bible §1** — un saco de trigo que un jugador sembró hace 4 días, hoy es el pan que otro jugador compra en su supermercado del barrio, con lineage visible en el ticket.

> **El día que un jugador en un servidor RP aleatorio entre al supermercado Admirals, compre una baguette, escanee el QR del ticket en su Tablet y vea "esta baguette se hizo a las 6:14 esta mañana en La Almirantazgo, con harina del Molino San Juan, con trigo de la parcela P03 de la Granja del Río, sembrado el 26 de abril por Carlos Méndez" — habremos construido el ecosistema más narrativo del FiveM commercial.**

---

*"Del campo a la mesa — el último eslabón."*

**FIN DEL DOCUMENTO `05_node_retail.md` v1.0**
