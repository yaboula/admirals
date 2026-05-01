# 💰 Admirals — Economic Model (Master)

> **Versión:** 1.0 (firmado — completo, 21 secciones, 3 partes publicadas).
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.2 (§11 Calidad y economía).
> **Documentos hermanos:** `economy/02_bakery_economy.md` (próximo, hijo de este), `economy/03_retail_economy.md` (próximo, hijo de este).
> **Documentos referenciados:** todos los nodos `design/01-05`, `technical/03_db_schema.md` v1.0 (tablas `admirals_bank_*`), `technical/02_events_catalog.md` v1.0 (eventos `bank:*`, `market:*`, `logistics:*`).
> **Estado:** firmado.

> **Lectura previa obligatoria:** Bible §11 (Calidad y economía), Architecture §10 (Item Físico), DB Schema §6-§7 (banking schema).

---

## 0. Resumen ejecutivo

Este documento es **el modelo económico maestro del ecosistema Admirals**. Es el **single source of truth** para toda decisión numérica del producto.

Define:

- **Filosofía económica** — 7 pilares que rigen todas las decisiones de balance.
- **Currency model** — EUR canónico, no tokens, no fantasía.
- **Money supply** — sources (de dónde sale el dinero) vs sinks (a dónde se va), garantizando inflation control.
- **Conditions iniciales** — capital de partida por player, capital seed del servidor.
- **Salarios canónicos** por rol y nodo.
- **Pricing canónico** de cada ítem físico de la cadena del pan.
- **Margins por nodo** — qué margen B2B y B2C debe tener cada node owner.
- **Quality + lineage premium** — fórmula exacta de cómo la calidad y trazabilidad multiplican el precio.
- **Sistema empresa** económico — founding cost, member salaries, dividends.
- **Banca** — tipos de cuenta, escrow, interest (si aplica).
- **Reputation impact** en precios y conversion.
- **Dynamic pricing** del Retail — cómo cambian los precios en hora pico.
- **Promociones** — impacto económico, límites, ROI esperado.
- **Logística** — costes de transporte por categoría.
- **NPC Bridge prices** — modo standalone, precios de NPC vendors.
- **Tax + server fees** — gobernanza económica del servidor.
- **Sinks específicos** — mantenimiento, depreciación, sales tax, market fees.
- **KPIs económicos** — métricas de salud económica del servidor.
- **Edge cases + anti-patterns** — qué NO hacer.
- **Tooling balance** — herramientas de simulación + dashboard server admin.

> **Si este documento está mal, el producto entero está mal.** El balance económico es lo que separa un script "que funciona" de un ecosistema "que vive".

---

## 1. Filosofía económica

### 1.1 Los 7 pilares del modelo económico Admirals

#### Pilar 1 — Cadena propaga valor (Bible Pilar 2)
> **Cada nodo añade valor por trabajo.** No por magia.

- Un saco de trigo bruto vale X.
- Molido a harina vale **X × 1.6**.
- Convertido a pan vale **X × 4.5**.
- Vendido al cliente final vale **X × 7-8**.

#### Pilar 2 — Calidad propaga (Bible §11.2)
> **Mal grano → mal pan.** No hay magia que convierta C en A.

- Calidad input limita calidad output.
- Quality compounding fórmula explícita en §8.
- Premium quality justifica precio premium.

#### Pilar 3 — Lineage como producto (USP del ecosistema)
> **Trazabilidad jugable es premium.** El cliente Retail paga MÁS por un pan trazado.

- Pan con `lineage_complete=true` (granja → molino → bakery → retail trazada) tiene markup +12-18%.
- Es **el competitive advantage** vs cualquier resource genérico.

#### Pilar 4 — Sinks > Sources (anti-inflation)
> **Más dinero sale del sistema que entra.** Mantenimiento + sales tax + market fees + depreciación + losses absorben dinero.

- Si en hora pico el servidor produce más dinero del que sumerge → inflation → balance roto.
- Target: **sinks ≥ sources × 1.05** en steady-state.

#### Pilar 5 — Trabajo activo recompensado, AFK penalizado
> **El player que JUEGA gana más que el que tiene NPCs trabajando solos.**

- Player-operated: 100% margen.
- NPC-operated (modo standalone o player-AFK): 60-75% margen (NPC eficiencia subóptima).
- Incentivo claro a la presencia.

#### Pilar 6 — Cada empresa puede quebrar
> **Las cuentas en rojo tienen consecuencias.** No hay magic refill.

- Mantenimiento mensual obligatorio.
- Si saldo < deuda → equipo embargado, lock empresa, recovery process explícito.
- Es **realismo económico** que da peso a cada decisión.

#### Pilar 7 — Servidor es admin, no banco
> **El servidor cobra fees pequeños y consistentes**, no inyecta liquidez infinita.

- Server NO refilla cuentas player.
- Server SÍ cobra fees (market, escrow, transferencia entre IBANs externos, sales tax).
- Los fees son **fuente legítima de servidor income** (justifica subscriptions premium).

### 1.2 Anti-patrones económicos

> **Cosas que rompen la economía Admirals.**

- ❌ **Money cheats** (admin spawning grandes cantidades sin justificación).
- ❌ **Infinite stockpiling** sin coste (almacenar 10000 sacos sin pagar warehouse).
- ❌ **Quality A garantizada** (calidad debe variar según condiciones).
- ❌ **Markup arbitrario** sin trabajo físico que lo justifique.
- ❌ **Salaries fijos altos** que rompen el balance — todos los salarios son base + performance.
- ❌ **Free escrow** — el escrow tiene un fee pequeño (justifica server income).
- ❌ **Refunds automáticos** — disputas resuelven manual + governance.
- ❌ **Subsidios infinitos** — cada player es responsable de su empresa.
- ❌ **Pricing dinámico hostil** (precios x10 en hora pico) — caps fijos.

---

## 2. Currency model

### 2.1 Moneda canónica: EUR (€)

> **Decisión:** una sola moneda, **EUR**, con dos decimales máximo.

- Todos los precios, salarios, balances en €.
- DECIMAL(12,2) en MySQL (max 9.999.999.999,99 € — overkill garantizado).
- **NO** tokens, **NO** múltiples currencies, **NO** crypto, **NO** experience points monetizables.
- **Razón:** simplicidad operacional + percepción premium + alineado con setting "naval admiralty".

### 2.2 Display canónico

| Contexto | Formato |
|---|---|
| **UI Tablet** | `1.234,56 €` (locale es-ES) o `€1,234.56` (locale en-US) |
| **Tickets/recibos** | `EUR 1.234,56` |
| **Logs/database** | `1234.56` (raw decimal) |
| **Eventos bus** | `{"amount": "1234.56"}` (string para evitar float drift) |

### 2.3 Float drift — política

> **NO usar `number` para money en JS/TS.** Siempre Decimal.js o BigNumber para cálculos.

- DB: DECIMAL(12,2) hard.
- Server Lua: numero stored as integer cents (multiply by 100), divide cuando display.
- NUI/TS: Decimal.js para arithmetic, format al final.
- **Razón:** evitar `0.1 + 0.2 = 0.30000000000000004`.

### 2.4 Cash vs Bank

| Forma | Uso | Limit por player |
|---|---|---|
| **Cash physical** (efectivo) | Pequeñas transacciones B2C, robos posibles | Soft cap 5.000 € (warning above) |
| **Bank account** (IBAN) | Salarios, contracts B2B, escrow, transferencias | No cap — depende del player |

**Decisión:** **80% del flujo económico va por bank** (digitalización modern). Cash existe para realismo + B2C feel + scenarios robos/atracos (oleada 2+).

### 2.5 IBAN convention

- Format canónico: `ES00 ADML XXXX XXXX XXXX XXXX` (24 chars con spaces, 20 sin).
- Servidor genera IBAN único por cuenta al crear.
- Display Tablet: con spaces para legibilidad.
- DB: VARCHAR(20) sin spaces.

---

## 3. Money supply — sources vs sinks

### 3.1 Filosofía

> **El servidor es ecosistema cerrado.** El dinero circula. Los sinks deben absorber **5%+ más** de lo que sources generan, para evitar inflation.

### 3.2 Sources (de dónde aparece dinero NUEVO)

| Source | Frecuencia | Volumen típico | Justificación |
|---|---|---|---|
| **Player B2C sales a NPC clientes** | Continuo (PED system) | 50-500 €/transacción | El "dinero del público" infinito (bridge económico) |
| **NPC contractors B2B** (modo standalone) | Per contrato | 200-2000 €/contrato | Mismo bridge — NPC paga al player |
| **Server seed inicial** | Único en boot | Definido en config | Cuenta NPC system mantiene IBAN reserva |
| **Subsidios narrative-driven** | Eventos especiales raros | Variable | Eventos servidor (dia gratis, ayudas oficiales) |
| **Quest rewards / achievements** (oleada 2+) | Pequeños | 50-200 € | Onboarding + retention |

> **Regla:** **toda source debe estar trackeada** en `admirals_bank_movements` con `category` específica para auditoría.

### 3.3 Sinks (a dónde se va el dinero)

| Sink | Frecuencia | Volumen típico | Justificación |
|---|---|---|---|
| **Maintenance equipos** | Diario/semanal | 10-100 €/equipo/día | Realismo desgaste |
| **Salaries empleados** | Quincenal | 500-2500 €/empleado | Costes laborales |
| **Sales tax (servidor)** | Por transacción B2C | 4-8% | Income servidor + sink |
| **Market fees** | Por listing | 1-3% del precio | Income servidor + sink |
| **Escrow fee** | Por contrato | 0.5-1% del valor | Income servidor + sink |
| **IBAN-to-IBAN external transfers** | Por transferencia | 0.50-2 € flat | Sink + realismo banca |
| **Depreciación equipos** | Mensual | 1% del valor | Equipos pierden valor con tiempo |
| **Mantenimiento MLO** (alquiler) | Mensual | 500-3000 € | Sink importante para empresas grandes |
| **Insurance opcional** | Mensual | 50-200 € | Cobertura disputes/losses |
| **Quality losses** | Continuo | Variable | Producto que se echa a perder |
| **Logistics costs** | Por entrega | 50-300 €/entrega | Combustible + driver |
| **Penalties/fines** | Eventual | Variable | Gobernanza servidor |

### 3.4 Money flow diagram

```
SOURCES (dinero nuevo)            SINKS (dinero absorbido)
─────────────────                 ─────────────────
NPC clientes B2C ─┐               Salaries
NPC bridges B2B ──┤               Mantenimiento
Server seed ──────┤               Sales tax
Quests rare ──────┘               Market fees
       │                          Escrow fees
       ▼                          MLO rent
   PLAYERS IBAN ◄── Inter-player ──► Depreciación
                    flow              Logística
                                      Quality losses

TARGET: Σ sinks ≥ Σ sources × 1.05  (anti-inflation 5%)
```

### 3.5 Monitoring de balance económico

> **Server admin dashboard** muestra rolling 7-day:

- **Total sources injected** (sumatorio).
- **Total sinks absorbed** (sumatorio).
- **Net flow** (sources - sinks) — target ≤ 0 (sinks dominante).
- **Money supply total** (suma todos IBAN players activos).
- **Velocity** (transactions/day per IBAN promedio).
- **Top accumulators** (cuentas con saldo top 10).

**Red flag thresholds:**
- Net flow positivo 7 días seguidos → revisar balance.
- Top 1 IBAN > 30% money supply total → revisar (posible explotación).
- Velocity < 0.5 tx/day promedio → economía estancada.

---

## 4. Conditions iniciales

### 4.1 Player nuevo

> **Capital inicial al crear cuenta:**

| Item | Valor | Justificación |
|---|---|---|
| **Bank balance** (IBAN personal) | **2.500 €** | Permite onboarding sin grind extremo, pero no resuelve nada premium |
| **Cash physical** | 0 € | Cash se obtiene operando |
| **Inventory items** | Ninguno premium | Tablet entregada (asset) |

> **Decisión:** 2.500 € es **suficiente para empezar a trabajar como empleado** (no permite fundar empresa inmediatamente). Forces gameplay loop: trabajar → ahorrar → fundar empresa.

### 4.2 Server seed

> **Capital inicial del servidor en cuenta NPC system:**

| Item | Valor |
|---|---|
| **NPC system IBAN** balance | 10.000.000 € |
| **NPC supplier accounts** (granja seed, molino seed, etc.) | 500.000 € c/u |
| **Initial market inventory** (NPC sellers oleada 1) | Stock seedeado x cada vertical |

### 4.3 Founding empresa cost

> **Coste de fundar una empresa Admirals:**

| Tipo empresa | Capital mínimo | Justificación |
|---|---|---|
| **Empresa Granja** | 25.000 € | Equipo agrícola inicial necesario |
| **Empresa Molino** | 80.000 € | Maquinaria industrial alta |
| **Empresa Panadería** | 50.000 € | Hornos + equipamiento mid-tier |
| **Empresa Retail** | 35.000 € | Lineales + POS + freezer básico |

**Capital mínimo no es coste — es saldo mínimo en empresa account.** El player paga:
- **Founding fee al servidor: 5.000 €** (sink fijo, sale del bolsillo player).
- **MLO purchase/rent** (varies, ver §16).
- **Equipos iniciales** (dependiendo node).

### 4.4 Onboarding paths

| Path | Capital necesario | Tiempo |
|---|---|---|
| **Empleado inicial** | 0 € | Día 1 (player nuevo puede trabajar inmediato) |
| **Player Granja founder** | 30.000 € + MLO | ~5-8h juego |
| **Player Bakery founder** | 60.000 € + MLO | ~12-18h juego |
| **Player Retail founder** | 50.000 € + MLO | ~10-15h juego |
| **Player Molino founder** | 100.000 € + MLO | ~20-30h juego |

> **Decisión:** **el Molino es el más caro** — refleja el "industrial mid-chain" character. Pero hay menos slots de Molino en el servidor, lo que justifica el ROI.

---

## 5. Salaries canónicos

### 5.1 Filosofía salarios

> **Base + performance.** No flat fixed.

- **Base salary** garantizado (cubre vida del player en el rol).
- **Performance bonus** (porcentaje sobre quality/quantity output).
- **Quincenal payment** (cada 14 días reales = 2 sesiones server típicas).

### 5.2 Tabla canónica de salaries

> **Salaries base** quincenales por rol:

| Nodo | Rol | Base salary (quincenal) | Performance bonus max | Total potencial |
|---|---|---|---|---|
| **Granja** | Worker base | 1.200 € | +400 € | 1.600 € |
| **Granja** | Operador maquinaria | 1.500 € | +500 € | 2.000 € |
| **Granja** | Manager | 2.500 € | +800 € | 3.300 € |
| **Molino** | Operador | 1.700 € | +500 € | 2.200 € |
| **Molino** | Quality Inspector | 1.900 € | +600 € | 2.500 € |
| **Molino** | Manager | 2.800 € | +900 € | 3.700 € |
| **Bakery** | Panadero junior | 1.400 € | +400 € | 1.800 € |
| **Bakery** | Maestro panadero | 2.200 € | +700 € | 2.900 € |
| **Bakery** | Cajero | 1.300 € | +400 € | 1.700 € |
| **Bakery** | Manager | 2.500 € | +800 € | 3.300 € |
| **Retail** | Reponedor | 1.300 € | +300 € | 1.600 € |
| **Retail** | Cajero | 1.400 € | +500 € | 1.900 € |
| **Retail** | Carnicería/Pescadería | 1.700 € | +500 € | 2.200 € |
| **Retail** | Encargado sección | 2.300 € | +700 € | 3.000 € |
| **Retail** | Director tienda | 3.200 € | +1.000 € | 4.200 € |

### 5.3 Performance bonus formula

```
performance_bonus = base_max_bonus × (
  0.4 × productivity_score / 100 +
  0.3 × quality_score / 100 +
  0.2 × attendance_score / 100 +
  0.1 × team_score / 100
)
```

Donde:
- `productivity_score`: outputs del worker / target (0-100, capped).
- `quality_score`: avg quality outputs (0-100).
- `attendance_score`: hours on-shift / hours scheduled (0-100).
- `team_score`: empresa overall performance (0-100).

### 5.4 Reglas canónicas

- ✅ **Salary se paga** quincenalmente desde IBAN empresa al IBAN empleado.
- ✅ **Si empresa no tiene saldo** → salary queda en deuda, evento `bank:salary_unpaid`, empleado puede salir sin penalización.
- ✅ **Salary editable** por manager dentro de rangos +20%/-10% del canónico.
- ✅ **Override salary > +50% del canónico** requiere doble firma (manager + founder empresa).
- ✅ **Salary < 80% del canónico** → empleados se desmoralizan + score performance baja.

### 5.5 Self-employed (player owner sin staff)

> **Player que opera solo su propia empresa NO recibe salary** — recibe **profit**.

- Profit = revenue - costs (incluye depreciación + tax).
- Profit transferido a IBAN player (no IBAN empresa) cada cierre de turno o manual withdraw.
- Player decide cuánto reinvertir vs cuánto extraer.

---

## 6. Pricing canónico de items físicos

> **Single source of truth** para el precio de cada ítem físico de la cadena del pan.

### 6.1 Granja outputs (raw materials)

| Item | Unit | Quality A | Quality B | Quality C | Quality D |
|---|---|---|---|---|---|
| `wheat_grain` | saco 25kg | 45 € | 38 € | 30 € | 22 € |
| `oats_grain` | saco 25kg | 50 € | 42 € | 33 € | 24 € |
| `barley_grain` | saco 25kg | 42 € | 35 € | 28 € | 20 € |
| `rye_grain` | saco 25kg | 55 € | 46 € | 36 € | 27 € |

### 6.2 Molino outputs (intermediates)

| Item | Unit | Quality A | Quality B | Quality C | Quality D |
|---|---|---|---|---|---|
| `wheat_flour_white` | saco 25kg | 75 € | 64 € | 52 € | 39 € |
| `wheat_flour_whole` | saco 25kg | 82 € | 70 € | 56 € | 42 € |
| `bran` (subproducto) | saco 25kg | 18 € | 15 € | 12 € | 8 € |
| `oats_flour` | saco 25kg | 88 € | 75 € | 60 € | 45 € |
| `rye_flour` | saco 25kg | 95 € | 81 € | 65 € | 49 € |
| `flour_specialty` (mezclas) | saco 25kg | 110 € | 93 € | 75 € | 56 € |

### 6.3 Bakery outputs (productos terminados)

#### 6.3.1 Pan estándar (B2B price unitario)

| Item | Unit | Quality A | Quality B | Quality C | Quality D |
|---|---|---|---|---|---|
| `bread_baguette` | unidad | 0.85 € | 0.72 € | 0.58 € | 0.43 € |
| `bread_white_loaf` | unidad | 1.20 € | 1.02 € | 0.82 € | 0.61 € |
| `bread_whole_loaf` | unidad | 1.50 € | 1.28 € | 1.02 € | 0.77 € |
| `bread_rustic` | unidad | 1.80 € | 1.53 € | 1.22 € | 0.92 € |
| `bread_specialty` (centeno, cereales) | unidad | 2.20 € | 1.87 € | 1.50 € | 1.12 € |
| `pastry_croissant` | unidad | 1.10 € | 0.94 € | 0.75 € | 0.56 € |
| `pastry_pain_chocolat` | unidad | 1.30 € | 1.10 € | 0.88 € | 0.66 € |
| `pastry_premium` (artesana) | unidad | 2.50 € | 2.13 € | 1.70 € | 1.27 € |

#### 6.3.2 B2C markup (Bakery a cliente PED en mostrador)

> **B2C price = B2B price × 1.45** (markup standard panadero).

Ejemplo: baguette quality A → B2B 0.85 € → B2C 1.23 € (precio cliente PED en mostrador).

### 6.4 Retail outputs (B2C precio final cliente)

> **Retail markup sobre B2B price del proveedor:**

| Categoría | Markup standard | Markup quality A | Markup lineage_complete |
|---|---|---|---|
| Pan / panadería | × 1.55 | × 1.65 | × 1.78 |
| Lácteos | × 1.45 | × 1.55 | × 1.65 |
| Carnicería | × 1.50 | × 1.62 | × 1.75 |
| Frutas/verduras | × 1.40 | × 1.50 | × 1.60 |
| Bebidas | × 1.35 | × 1.42 | × 1.50 |
| Conservas | × 1.45 | × 1.52 | × 1.60 |

**Ejemplo end-to-end:**
- Trigo quality A: 45 € (saco 25kg) en granja.
- Harina quality A: 75 € (saco 25kg) en molino.
- Pan baguette quality A: 0.85 € (B2B price) en bakery.
- Vendido en Retail al cliente: 0.85 × 1.55 = **1.32 €** (cliente PED paga).
- Si lineage completo trazado: 0.85 × 1.78 = **1.51 €** (premium 14%).

### 6.5 Reglas canónicas de precios

- ✅ **B2B contracts** entre players pueden negociar **±15% del canónico** libremente.
- ✅ **Precios > +25% del canónico** son flagged como "premium suspicious" — review opcional admin.
- ✅ **Precios < -20%** son flagged como "dumping" — admin alerta.
- ✅ **NPC bridges** usan **precio canónico exacto** (sin negociación).
- ✅ **Retail dynamic pricing** opera dentro de rango ±15% del markup standard (ver §12).

---

## 7. Margins por nodo

> **Margin target** que cada node owner debe esperar en operación normal.

### 7.1 Margen Granja

| Tipo cliente | Revenue / saco quality A | Cost / saco | Margin gross | Margin neto |
|---|---|---|---|---|
| **B2B player** | 45 € (canónico) | ~14 € | 31 € (69%) | ~22 € (49%) |
| **B2B NPC bridge** | 45 € | ~14 € | 31 € (69%) | ~22 € (49%) |

**Cost breakdown (saco 25kg trigo quality A):**
- Semilla: 4 €
- Fertilizante + agua: 3 €
- Combustible maquinaria: 2 €
- Salaries (hora-prorrata): 3 €
- Mantenimiento + depreciación: 2 €
- **Total: ~14 €**

### 7.2 Margen Molino

| Tipo cliente | Revenue / saco harina quality A | Cost / saco | Margin gross | Margin neto |
|---|---|---|---|---|
| **B2B player** | 75 € | ~52 € | 23 € (31%) | ~17 € (23%) |
| **B2B NPC bridge** | 75 € | ~52 € | 23 € (31%) | ~17 € (23%) |

**Cost breakdown (saco 25kg harina white quality A):**
- Trigo input: 45 € (saco trigo A)
- Pérdidas molienda (30% bran, 70% flour): efectiva ~38 € (con recuperación bran)
- Energía maquinaria: 5 €
- Salaries: 4 €
- Mantenimiento: 3 €
- **Total: ~52 €**

> **Margen Molino más bajo (23%)** que Granja (49%) — pero **volúmenes mayores** (un molino procesa 50+ sacos/día vs granja 8-15 sacos/día). ROI horario equivalente.

### 7.3 Margen Bakery

| Tipo cliente | Revenue / 100 baguettes A | Cost / 100 baguettes | Margin gross | Margin neto |
|---|---|---|---|---|
| **B2B (a Retail)** | 85 € | ~52 € | 33 € (39%) | ~25 € (29%) |
| **B2C (cliente PED en mostrador)** | 123 € | ~52 € | 71 € (58%) | ~58 € (47%) |

**Cost breakdown (100 baguettes quality A):**
- Harina input: ~30 € (proporcional)
- Sal + levadura + ingredientes: 5 €
- Energía horno: 8 €
- Salaries (hora-prorrata): 5 €
- Mantenimiento: 4 €
- **Total: ~52 €**

> **Bakery dual-channel** — el B2C tiene 47% margen neto, el B2B 29%. El **bakery con buen flujo PED supera al que solo vende B2B**.

### 7.4 Margen Retail

| Categoría producto | Revenue avg | Cost (B2B compra) | Margin gross | Margin neto |
|---|---|---|---|---|
| **Panadería** | 1.32 €/und | 0.85 €/und | 0.47 € (36%) | ~0.32 € (24%) |
| **Lácteos** | 2.20 €/und | 1.50 €/und | 0.70 € (32%) | ~0.45 € (20%) |
| **Carnicería** | 8.50 €/kg | 5.66 €/kg | 2.84 € (33%) | ~1.85 € (22%) |
| **Frutas/verduras** | 2.80 €/kg | 2.00 €/kg | 0.80 € (29%) | ~0.50 € (18%) |

**Cost breakdown Retail:**
- Compra B2B (60-70% del revenue).
- Salaries (~10% del revenue).
- Mantenimiento + freezer + electricidad (~6%).
- Sales tax (5-7%).
- Mermas / quality losses (~3%).
- **Total cost: ~76% del revenue**, dejando ~24% margen neto en pan (categoría flagship).

### 7.5 Resumen comparado

| Nodo | Margen neto típico | Risk profile | ROI horario player |
|---|---|---|---|
| Granja | 49% | Medio (clima + plagas) | Alto (work-intensive, gratificante) |
| Molino | 23% | Bajo | Alto (bulk volume) |
| Bakery | 29-47% | Medio (tiempos fermentación) | Muy alto (flagship) |
| Retail | 18-24% | Bajo (volume game) | Mid-high (gestión densa) |

> **Retail tiene el margen más bajo pero el volumen más alto.** Una tienda con 200 transacciones/día genera más profit absoluto que una bakery con 80 ventas/día, aunque cada transacción individual deje menos.

---

## 8. Quality + Lineage premium — fórmula maestra

### 8.1 Quality compounding (Bible §11.2)

> **La calidad propaga por la cadena, pero NUNCA mejora.**

```
quality_output = floor(min(
  quality_input,
  quality_process_actor,
  quality_machine_state
))
```

Donde:
- `quality_input`: calidad del input (e.g., trigo entrando al molino).
- `quality_process_actor`: skill del player ejecutando (proxy: experience + tasks_perfect_count).
- `quality_machine_state`: estado de la máquina (mantenimiento ratio).

**Reglas:**
- Mal grano → max harina B (no A).
- Mala harina → max pan B.
- **Quality flow sealed** — no shortcuts.

### 8.2 Quality multiplier en pricing

> **Tabla canónica multiplicador de precio según quality:**

| Quality | Multiplier |
|---|---|
| **A** (premium) | × 1.00 (precio canónico A) |
| **B** (standard) | × 0.85 |
| **C** (acceptable) | × 0.68 |
| **D** (poor) | × 0.51 |
| **F** (failed) | × 0.00 (no comercializable, descarte) |

> **Razón:** quality A es **target**, quality D es **viable pero penalizado**, quality F es **pérdida total**.

### 8.3 Lineage premium

> **El cliente Retail paga más por un producto con lineage completo trazable.**

| Lineage status | Multiplier sobre precio canónico |
|---|---|
| **Sin lineage** (NPC bridge upstream) | × 1.00 (baseline) |
| **Lineage parcial** (1-2 nodos trazados) | × 1.05 |
| **Lineage completo** (granja → molino → bakery → retail trazado) | **× 1.15** ⭐ |
| **Lineage premium** (todos players + reputation > 80) | **× 1.20** ⭐⭐ |

### 8.4 Combined formula final

```
price_final = price_canonical_A
            × quality_multiplier(quality)
            × lineage_multiplier(lineage_status)
            × reputation_multiplier(seller_reputation)
            × dynamic_pricing_multiplier(retail_state)  // solo Retail
```

**Ejemplo full chain (todo quality A, lineage completo):**
- Pan baguette canónico A: 0.85 € B2B.
- Quality A: × 1.00 = 0.85 €.
- Lineage completo: × 1.15 = 0.98 €.
- Reputation seller > 80: × 1.05 = 1.03 € (B2B).
- Retail markup standard: × 1.55 = **1.59 € precio cliente**.

vs un pan sin lineage, quality C:
- Canónico A: 0.85 €.
- Quality C: × 0.68 = 0.58 €.
- Sin lineage: × 1.00 = 0.58 €.
- Reputation neutra: × 1.00 = 0.58 €.
- Retail markup: × 1.55 = **0.90 € precio cliente**.

> **Diferencia: 76%** entre el premium trazado y el standard NPC. Esto es **el competitive moat**.

### 8.5 Lineage validation

> **Para que un producto tenga `lineage_complete=true`** debe tener:

1. ✅ Batch ID granja con player owner verificado.
2. ✅ Batch ID molino con upstream batch_id link a granja batch.
3. ✅ Batch ID bakery con upstream batch_id link a molino batch.
4. ✅ Producto en Retail con upstream lineage hasta bakery batch.
5. ✅ **Cada link timestamped + signed** vía contrato/albarán.

**Validación automática:** evento `lineage:trace_request` consulta DB recursivamente, retorna full chain o false.

---

## 9. Sistema empresa — economía interna

### 9.1 Tipos de empresa

| Tipo | Founder owners | Members max | Voting power |
|---|---|---|---|
| **Solo proprietorship** | 1 player | 1 (solo founder) | Founder 100% |
| **Partnership** | 2-4 players | 4 max | Equal por default, configurable |
| **Corporation** | 1+ players | Unlimited | Founder + members con shares |

### 9.2 Founding fees

| Tipo | Founding fee al servidor | Capital mínimo IBAN |
|---|---|---|
| **Solo proprietorship** | 5.000 € | 2x capital mínimo del nodo |
| **Partnership** | 8.000 € | 1.5x capital mínimo |
| **Corporation** | 15.000 € | 1x capital mínimo |

### 9.3 Member salaries (employee model)

> **Cuando el founder contrata members como empleados** (no co-founders):

- **Member contract** define salary + role + permissions.
- **Salary pago quincenal** desde IBAN empresa al IBAN member.
- **Permissions** granulares (ver `02_admirals_tablet.md` Manager Panel).

### 9.4 Dividends (corporation model)

> **Para corporations con shares:**

- **Dividend distribution** trigger: founder o vote council.
- **Distribution event** `bank:dividend_distribute` emite a cada shareholder según shares ratio.
- **Frecuencia recomendada:** mensual o quarterly.
- **Tax dividend:** 8% retención automática al servidor (sink).

### 9.5 Empresa account types

> **Cada empresa tiene 3 IBANs separados:**

| Cuenta | Propósito | Permissions |
|---|---|---|
| **Operating account** (default) | Ingresos y gastos diarios | Manager + Founder |
| **Reserve account** (savings) | Ahorros, capex futuro | Founder only |
| **Escrow account** (auto-managed) | Holds for active contracts | Read-only para todos, server-managed |

### 9.6 Bankruptcy mechanics

> **Cuando empresa account < 0:**

| Días en negativo | Consecuencia |
|---|---|
| **1-3 días** | Warning Tablet — notif manager. |
| **4-7 días** | Salaries pendientes acumulan. Empresa flag "in_distress". |
| **8-14 días** | Equipos clave embargados (más caros first). MLO rent flag overdue. |
| **15+ días** | **Bankruptcy** — empresa locked. Founder tiene 30 días para vender assets o el servidor liquida en subasta NPC. |

> **NO automatic refund.** Servidor NO inyecta dinero. Bankruptcy es real.

### 9.7 Empresa metrics económicas

> **Manager Panel muestra dashboard económico:**

- **Revenue 7d / 30d** (rolling).
- **Costs 7d / 30d** desglosados.
- **Profit 7d / 30d** + trend.
- **Cash runway** (días que puede operar con saldo actual al ritmo current).
- **Top selling SKUs** (Bakery/Retail).
- **Quality score promedio** outputs.
- **Employee productivity** ranking.
- **Market share local** (vs competidores en mismo zone).

---

## 10. Banca — economía del sistema bancario

### 10.1 Filosofía banca

> **El banco Admirals NO da préstamos infinitos.** Es admin custodial — gestiona IBAN, escrow, y fees.

- **NO loans automáticos** del servidor.
- **SÍ peer-to-peer loans** entre players (con contracts firmable).
- **NO interest accrual** en cuentas standard (oleada 1).
- **SÍ interest opcional** en savings accounts (oleada 2+).

### 10.2 Tipos de cuenta

| Tipo | Holder | Interest | Fees |
|---|---|---|---|
| **Personal** (player) | 1 player | 0% (oleada 1) | None for normal use |
| **Empresa operating** | Empresa | 0% | Standard transaction fees |
| **Empresa reserve** | Empresa | 0% | None |
| **Escrow** (auto) | Server-managed | 0% | 0.5-1% on lock |
| **NPC system** | Servidor | – | – |
| **Savings** (oleada 2) | Player | 1.5-3% APY | None |

### 10.3 Transaction fees

| Operation | Fee |
|---|---|
| **Internal transfer** (entre IBANs Admirals) | **0 €** (free) |
| **External IBAN transfer** (futuro multi-server) | 1-2 € flat |
| **Cash deposit** | 0 € |
| **Cash withdrawal** | 0 € |
| **Currency exchange** (oleada 2+) | Si aplica, spread 0.5% |

### 10.4 Escrow mechanics

> **Escrow es el corazón del trust económico Admirals.**

#### 10.4.1 Lifecycle

1. **Lock event** — comprador deposita amount en escrow account, server emite `bank:escrow_lock`.
2. **Hold period** — fondos retenidos hasta condición fulfilled (entrega + albarán signed).
3. **Release event** — condición met, server emite `bank:escrow_release` → fondos a vendedor.
4. **Or dispute** — comprador disputa, escrow goes a admin review.

#### 10.4.2 Escrow fee

- **0.5%** del valor del contrato — pagado por el comprador en `lock`.
- **Mínimo: 2 €**, **máximo: 100 €** por contrato (caps).
- **Sink legítimo** — server income.

#### 10.4.3 Disputes

- **Dispute period:** 48h tras delivery confirmed.
- **Admin manual review** si dispute opened.
- **Outcomes:**
  - Refund full → buyer (refund escrow + seller paga penalty).
  - Release full → seller (buyer dispute rejected, no refund).
  - Partial split → admin discretion (raro).

### 10.5 Bank movements categorías

> **Toda transaction tiene category** explícita en `admirals_bank_movements`:

| Category | Direction | Use case |
|---|---|---|
| `salary` | empresa → player | Pago quincenal |
| `dividend` | empresa → shareholders | Distribución profits |
| `b2b_payment` | empresa → empresa | Contract entre players |
| `b2c_sale` | NPC → empresa | Cliente PED compra |
| `escrow_lock` | empresa → escrow | Inicio contract |
| `escrow_release` | escrow → empresa | Fin contract OK |
| `escrow_refund` | escrow → empresa | Dispute resolved |
| `market_fee` | empresa → server | Fee market listing |
| `escrow_fee` | empresa → server | Fee escrow service |
| `sales_tax` | empresa → server | Tax B2C |
| `maintenance` | empresa → server | Maint equipos |
| `mlo_rent` | empresa → server | Alquiler MLO |
| `depreciation` | empresa → null | Depreciation log (no actual money flow) |
| `loan_player` | player → player | Préstamo p2p |
| `loan_repayment` | player → player | Devolución p2p |
| `transfer_personal` | player ↔ player | Transferencia personal |
| `cash_deposit` | cash → bank | Ingreso efectivo |
| `cash_withdrawal` | bank → cash | Retirada efectivo |
| `founding_fee` | player → server | Fundar empresa |
| `penalty` | empresa/player → server | Multas |

### 10.6 Audit trail

> **Toda transaction es auditable:** timestamp + IBAN from + IBAN to + amount + category + reference (contract_id, batch_id si aplica) + signed (server signature).

**Imutability:** rows en `admirals_bank_movements` son **immutables** post-create. Reverso de transaction = nueva row con category opuesta + reference al original.

---

## 11. Reputation impact en economía

### 11.1 Reputation score

> **Cada cuenta (player + empresa) tiene reputation score 0-100.**

Basado en (DB Schema §10):
- Quality consistency outputs.
- Contract fulfillment ratio.
- Dispute lose ratio (inversa).
- Years active + transactions volume.
- Reviews recibidas (oleada 2+).

### 11.2 Reputation tiers

| Tier | Score | Beneficios |
|---|---|---|
| **Untrusted** | 0-30 | Markup penalty, escrow fee × 2 |
| **Neutral** | 31-60 | Sin bonus ni penalty |
| **Trusted** | 61-80 | Pricing premium × 1.05 disponible |
| **Premium** | 81-100 | Pricing premium × 1.10, escrow fee 0.3% |

### 11.3 Reputation × pricing multiplier

> **Reputation impact en pricing canónico:**

```
reputation_multiplier =
  0.90 if score < 30          // dumping forced
  1.00 if 30 ≤ score ≤ 60     // neutral
  1.05 if 61 ≤ score ≤ 80     // trust premium
  1.10 if score > 80          // premium tier
```

### 11.4 Conversion impact en Retail

> **PED clients prefer Retail con buen reputation:**

- **Reputation > 80** → +25% conversion rate (PEDs entran más).
- **Reputation 60-80** → conversion rate baseline.
- **Reputation < 40** → -30% conversion.

### 11.5 Reputation drift

- **Cada contrato fulfilled** → +0.5 puntos.
- **Cada dispute lost** → -3 puntos.
- **Cada quality A delivery** → +0.3 puntos.
- **Cada quality C delivery** → -1 punto.
- **Cada late payment** → -2 puntos.
- **Cap superior:** +0.5/día (no farming rapid).

---

## 12. Dynamic pricing (Retail-specific)

### 12.1 Filosofía dynamic pricing

> **Los precios cambian según condiciones del Retail.** PERO con caps fijos para evitar gaming.

- Cap superior: **+15% del markup canónico**.
- Cap inferior: **-15% del markup canónico**.
- Beyond caps requiere **manager approval** + flag suspicious.

### 12.2 Triggers dynamic

| Trigger | Effect |
|---|---|
| **Hora pico** (19-22h server time) | × 1.05-1.10 (subir hasta cap) |
| **Stock crítico** (<15% lineal) | × 1.08 (escasez) |
| **Stock saturado** (>90% lineal cerca expire) | × 0.85 (descontar pre-expire) |
| **Competidor cercano más barato** | × 0.95 (matching parcial) |
| **Promo activa** | × promo_multiplier (ver §13) |
| **Quality A premium** | × 1.05 |
| **Lineage trazado** | × 1.05-1.15 |

### 12.3 Update cadence

- **Pricing recalc cada 5min** (no per-second).
- **Tablet manager visualiza precio actual + razón del multiplier**.
- **PED clients ven precio actual + comparan vs expectativa** (afecta conversion).

### 12.4 Anti-gaming rules

- ❌ **NO** raise pricing >20% en respuesta a un single PED entering.
- ❌ **NO** discount > 30% sin flag promo (anti-dumping).
- ❌ **NO** pricing cycles cortos (precio cambia <5min) — confunde clientes.
- ✅ **Pricing change debe ser smooth** con max delta 3% per recalc.

---

## 13. Promociones (Retail-specific)

### 13.1 Tipos de promo

| Type | Description | Duration |
|---|---|---|
| **Discount %** | -X% en producto/categoría | 1-7 días |
| **2x1 / 3x2** | Bundles cantidad | 1-3 días |
| **Cross-sell** | Compra X y Y juntos para -Z% | 3-7 días |
| **Time-limited flash** | -X% solo X horas | 1-4h |
| **Lineage premium** | Highlight productos trazados | Permanent (always-on) |

### 13.2 Promo economics

| Type | Discount typical | ROI esperado | Limit |
|---|---|---|---|
| Discount 10-15% | 12% | +30% volume | 7 días max |
| 2x1 | -50% effective | +60% volume | 3 días max |
| Flash -25% | 25% | +80% volume short window | 4h max |

### 13.3 Promo limits (anti-abuse)

- **Max 3 promos simultáneas** por tienda.
- **Promo fee al servidor:** 1% del estimated promotional volume (pre-paid).
- **Cooldown:** 48h entre promos en mismo SKU (no spam).

### 13.4 Promo metrics (Manager Panel)

- **Revenue durante promo** vs baseline.
- **Volume increase ratio**.
- **Margin impact** (lower margin × higher volume).
- **Net effect** (positive ROI o negative).

---

## 14. Logística — costes de transporte

### 14.1 Filosofía logística

> **El transporte físico tiene coste real.** Dropshipping no existe — las mercancías se mueven con camiones, conducidos por player o NPC driver.

### 14.2 Costes por categoría

| Distancia | Cost base | Cost / km adicional |
|---|---|---|
| **Local** (<5km) | 50 € | – |
| **Mid** (5-20km) | 80 € | – |
| **Long** (20-50km) | 150 € | 5 €/km |
| **Inter-zone** (50+km) | 300 € | 6 €/km |

### 14.3 Carga + tipo vehículo

| Vehículo | Capacidad | Cost multiplier |
|---|---|---|
| **Vespertino van** | 20 sacos / 200 unidades pequeñas | × 1.0 |
| **Camión light** | 50 sacos / 500 unidades | × 1.4 |
| **Camión heavy** | 200 sacos / 2000 unidades | × 2.2 |
| **Refrigerado** | Add-on para frío | × 1.5 sobre base vehículo |

### 14.4 Driver compensation

| Driver type | Cost |
|---|---|
| **Player driver** (themselves) | Free (player's own time) |
| **Player employee driver** | Salary canónico applies |
| **NPC driver** (auto) | 30-80 € flat per delivery, eficiencia × 0.85 |

### 14.5 Insurance optional

> **Cada delivery puede tener seguro:**

- **No insurance** (default): si robo o accidente, pérdida total.
- **Basic insurance** (3% del valor cargo): cubre 80% en caso de pérdida.
- **Premium insurance** (6%): cubre 100% + dispute fast-track.

### 14.6 Logistics tipos de jobs

> **Recapitulación de Bible Retail/Bakery contracts:**

| Job type | Trigger |
|---|---|
| `b2b_delivery_via_logistics` | Contract B2B con `delivery=true` |
| `b2b_delivery_pickup` | Contract con `delivery=false` (pickup buyer) |
| `internal_transfer` | Mismo empresa, between MLOs |
| `marketplace_delivery` | Compra en Mercado Admirals |

### 14.7 Logistics dispute mechanics

> **Si delivery falla** (robo, accidente, late):

- **Late delivery (<6h):** -10% payment al driver, -2 reputation.
- **Late delivery (>24h):** -50% payment, -10 reputation, optional buyer cancel.
- **Cargo loss:** insurance kicks in, seguro paga, driver/empresa pay penalty.
- **Dispute path:** admin review si buyer y seller disagree.

---

## 15. NPC Bridge prices (modo standalone)

### 15.1 Filosofía NPC bridges

> **Bible Pilar §8** — NPC Bridges permiten que cualquier nodo se ejecute "solo" sin necesitar players upstream/downstream. Esto facilita que un servidor compre solo "Bakery" sin necesitar comprar "Granja+Molino".

**Precios NPC bridges** son **canónicos exactos** (sin negociación) y suelen ser **un 5-10% más caros** que el equivalente entre players para incentivar el comercio player-to-player.

### 15.2 NPC supplier prices (player buying from NPC)

| Item | Quality A NPC price | vs canónico player |
|---|---|---|
| `wheat_grain` saco 25kg | 49 € | +9% |
| `wheat_flour_white` saco 25kg | 82 € | +9% |
| `bread_baguette` (B2B Bakery → Retail) | 0.93 € | +9% |

> **Razón:** el NPC bridge cobra "premium servicio" — incentivar P2P trade entre players, donde los precios son canónicos exactos.

### 15.3 NPC buyer prices (player selling to NPC)

| Item | Quality A NPC compra | vs canónico player |
|---|---|---|
| `wheat_grain` saco 25kg | 41 € | -9% |
| `wheat_flour_white` saco 25kg | 68 € | -9% |
| `bread_baguette` (Bakery → NPC Retail) | 0.77 € | -9% |

> **Razón:** NPC paga menos que un player B2B comprador. Incentiva P2P.

### 15.4 NPC contract terms

- **Volume mínimo NPC:** sí (ejemplo: 10 sacos mínimos por compra/venta).
- **Volume máximo NPC:** caps diarios para no romper supply (ejemplo: 50 sacos/día por NPC supplier).
- **Quality NPC:** B-grade default (NPCs no entregan A-grade — eso es ventaja competitiva player).
- **Lineage NPC:** **NUNCA** lineage_complete (rompe el premium player).

### 15.5 Sliding cap NPC

> **Si demasiados players dependen del NPC en lugar de player suppliers:**

- Sistema detecta % volume vs P2P.
- Si NPC volume > 70% del total volume → NPC sliding cap reduce capacity progresivamente.
- Forces players a usar P2P upstream/downstream.
- **Restaurar capacity** automáticamente cuando P2P percentage sube.

---

## 16. Tax + server fees

### 16.1 Tax canónicos

| Tax type | Rate | Trigger |
|---|---|---|
| **Sales tax B2C** | 5% | Cada venta a cliente PED |
| **Sales tax B2B** | 0% (no double tax) | – |
| **Income tax empresa** | Not applicable oleada 1 | – |
| **Dividend retention** | 8% | Distribución dividendos |
| **Capital gains** (sell empresa) | 5% | Venta empresa a otro player |
| **Founding fee** | 5.000-15.000 € flat | Fundar empresa (§9.2) |
| **MLO transfer tax** | 2% | Cambio propietario MLO |

### 16.2 Server fees (sinks)

| Fee | Amount |
|---|---|
| **Market listing** | 1-3% del precio (depende premium) |
| **Escrow service** | 0.5-1% del valor contrato (caps 2-100€) |
| **External IBAN** transfer | 1-2 € flat |
| **Promo registration** | 1% estimated promo volume |
| **Insurance premium** | 3-6% del cargo value |
| **Job posting market** (find employees) | 50 € flat |

### 16.3 Server income breakdown (target)

> **Distribución típica de server income mensual** (sink absorbed):

| Source | % typical |
|---|---|
| Sales tax B2C | 35% |
| Maintenance fees | 22% |
| MLO rent | 18% |
| Escrow + market fees | 12% |
| Founding fees | 5% |
| Otros (penalties, insurance, etc.) | 8% |

### 16.4 Tax revenue tracking

> **Server admin dashboard muestra:**

- Total tax 7d / 30d.
- Top contributing empresas (tax payers).
- Tax categoría breakdown.
- Sink absorption ratio (target ≥ sources × 1.05).

---

## 17. Sinks específicos — equipment depreciation, MLO rent

### 17.1 Equipment depreciation

> **Cada equipo pierde valor por uso + tiempo.**

```
depreciation_monthly = original_value × 0.01  // 1% per month base
                     × wear_multiplier         // 1.0-2.5 según uso
```

| Wear level | Multiplier | Trigger |
|---|---|---|
| **Light use** (operativa <8h/día) | × 1.0 | – |
| **Normal use** (8-12h/día) | × 1.5 | – |
| **Heavy use** (12+h/día) | × 2.0 | – |
| **Overuse** (24/7 NPC operated) | × 2.5 | – |

**Equipo a 0% valor** = inservible, requiere replacement (cost full).

### 17.2 Maintenance schedules

| Equipo type | Maint cost mensual | Maint failure if skipped |
|---|---|---|
| Tractor agrícola | 80 €/mes | Eficiencia -20% si skip 1 mes |
| Cosechadora | 150 €/mes | Eficiencia -30% si skip |
| Stone mill grinder | 200 €/mes | Quality output cap a B si skip |
| Industrial mixer | 120 €/mes | Idem |
| Oven (panadería) | 100 €/mes | Quality output cap a B + waste +15% si skip |
| Cash register POS | 30 €/mes | Reliability -50% si skip |
| Refrigerator unit | 80 €/mes | Stock spoilage rate × 2 si skip |

### 17.3 MLO rent (alquiler / hipoteca)

> **MLOs son alquilados o comprados al servidor.**

| MLO size | Rent mensual | Purchase outright |
|---|---|---|
| **Small bakery / corner shop** | 800 € | 80.000 € |
| **Medium bakery / supermercado** | 1.500 € | 180.000 € |
| **Large molino industrial** | 3.000 € | 350.000 € |
| **Granja terrenos** (per parcela) | 200-500 € | 25.000-60.000 € |

**Decisión rent vs buy:**
- **Rent:** acceso fast, no capex, but ongoing sink.
- **Buy:** capex alto, no rent, can resell.
- **Hybrid:** rent first 6 meses → opt-in buy con descuento.

### 17.4 Quality losses (mermas)

> **Sink natural** del proceso productivo:

| Tipo | % loss típico | Trigger |
|---|---|---|
| **Grain spillage** Granja → Molino | 1-2% | Carga manual |
| **Flour dust loss** molienda | 0.5-1% | Proceso |
| **Bread waste** unsold expiry Bakery | 5-15% | Items no vendidos |
| **Retail mermas** vegetables/dairy | 3-8% | Productos perecederos |

**Mermas se reflejan** como inventory adjustment + log `inventory:mermas_logged` event.

---

## 18. KPIs económicos + monitoring

### 18.1 KPIs por nodo (visible al manager)

#### Granja
- Productividad (sacos/hectárea/ciclo).
- Quality avg outputs.
- Cost per saco.
- Revenue per saco.
- Margin neto %.
- Equipment usage ratio.

#### Molino
- Throughput (sacos/hora).
- Conversion ratio (kg trigo → kg harina + bran).
- Quality consistency.
- Cost / revenue per saco.
- Margin neto.

#### Bakery
- Items horneados/día.
- Waste % (unsold expiry).
- B2B vs B2C revenue split.
- Margin neto.
- Customer satisfaction (PED reviews oleada 2+).

#### Retail
- Transactions/día.
- Average ticket value.
- Conversion rate (PEDs entran vs compran).
- Stock turnover ratio.
- Margin neto.
- Top SKUs.

### 18.2 KPIs server-wide (visible admin)

- **GDP servidor** (suma revenue todas empresas activas).
- **Money supply total**.
- **Inflation rate** (precios market avg vs hace 30d).
- **Velocity** (transactions/day).
- **Top wealthy accounts** (anti-oligarchy check).
- **New empresa rate** (founding/month).
- **Bankruptcy rate** (per month).
- **Lineage trace coverage** (% productos vendidos con lineage_complete).
- **NPC vs P2P trade ratio**.
- **Tax revenue mensual**.

### 18.3 Health thresholds

| KPI | Healthy | Warning | Critical |
|---|---|---|---|
| Inflation 30d | -2% to +3% | +3% to +8% | >+8% |
| Money supply growth 30d | <5% | 5-15% | >15% |
| Velocity (avg) | >2 tx/day | 1-2 tx/day | <1 tx/day |
| Top 1 IBAN share | <20% | 20-30% | >30% |
| New empresa/month | >5 | 2-5 | <2 |
| Bankruptcy/month | <5% empresas activas | 5-10% | >10% |
| Lineage coverage | >40% | 20-40% | <20% |
| NPC dependency | <40% | 40-70% | >70% |

### 18.4 Alerts automáticas

- **Inflation > 8% sustained 7d** → admin notif red.
- **Velocity collapsing < 0.5/day** → economy stagnant.
- **Top accumulator > 35%** → review possible exploit.
- **Founding rate > bankruptcy rate × 3** → bubble warning.
- **Lineage coverage < 15%** → P2P chain not forming, NPC overuse.

---

## 19. Edge cases + anti-patterns

### 19.1 Edge cases económicos

#### 19.1.1 Player AFK con empresa activa
- Salaries siguen pagándose desde IBAN empresa.
- Si saldo se acaba → bankruptcy mechanics §9.6 aplican.
- Player no pierde empresa por AFK <14 días.

#### 19.1.2 Server downtime — escrows pendientes
- Escrows tienen timestamp de lock.
- Si server down >7 días → automatic refund a buyer (preserves trust).

#### 19.1.3 Price war entre players
- Permitido down to canónico × 0.85.
- Below × 0.85 → flag dumping, admin review.
- Múltiples players dumping mismo zona → admin intervention.

#### 19.1.4 Empresa abandonada (founder inactivo > 90 días)
- Notif primero a co-founders/managers.
- Day 90: empresa pasa a "abandoned" status.
- Day 120: server liquida en subasta NPC.
- Recovery: founder vuelve antes day 90 → no penalización.

#### 19.1.5 Quality A flooded market
- Si > 80% productos market son quality A → market detecta saturation.
- Quality A premium se reduce automatically (10% temp).
- Restaura cuando supply normalize.

#### 19.1.6 Inflation espiral (oleada 2 risk)
- Si inflation > 10% sustained 30d → emergency sink event.
- Server admin puede inyectar **mega-sink** (impuesto especial 2%) one-time.
- Goal: estabilizar pricing antes del crash.

### 19.2 Anti-patterns económicos

> **Cosas explícitamente prohibidas o flagged:**

- ❌ **Money transfer entre cuentas del mismo player** — sospechoso (laundering).
- ❌ **Empresa fundada solo para escrow farming** — admin watches multi-account.
- ❌ **Quality A consistente > 95% del output** — prácticamente imposible, flag exploit.
- ❌ **Pricing exactly at min/max caps consistently** — gaming sin diversidad.
- ❌ **Multiple short-term promos en mismo SKU** — promo abuse.
- ❌ **Self-deal contracts** entre cuentas mismo dueño — flag.

---

## 20. Tooling balance + simulation

### 20.1 Simulation tools

> **Antes de cada balance change** debe ejecutarse simulación.

#### 20.1.1 `admirals_econ_simulator` (CLI tool)

```bash
admirals-econ-sim run --duration 30d --players 50 --scenario healthy
# Outputs: GDP, inflation, bankruptcy rate, NPC vs P2P, money flows
```

**Inputs:**
- Duration (1d-365d).
- Player count (10-1000).
- Scenario (healthy / aggressive / economy / etc.).
- Custom overrides (precios, salaries, fees).

**Outputs JSON con todas KPIs §18.**

#### 20.1.2 Scenarios canónicos preset

| Scenario | Description |
|---|---|
| `healthy` | Steady-state, balanced flow |
| `boom` | Aggressive growth, many players |
| `recession` | Stagnant, low velocity |
| `inflation_attack` | Large source injection, test sinks |
| `oligarchy` | Few players accumulating |
| `npc_dominant` | High NPC dependency |

### 20.2 Admin dashboard server-side

> **Real-time dashboard** muestra:

- All KPIs §18 live.
- Money flow last 24h sankey diagram.
- Top transactions volume (daily).
- Empresa rankings (revenue + profit).
- Inflation trend last 30d.
- Alerts panel.

### 20.3 Balance change workflow

> **Para cambiar cualquier número canónico:**

1. **Propose RFC** documentando change + justification.
2. **Run simulation** con preset scenarios.
3. **Compare KPIs** old vs new.
4. **A/B test optional** (subset players, oleada 2+).
5. **Approve via founder + admin council**.
6. **Patch release con changelog**.
7. **Monitor 7d post-release**, rollback si KPIs red.

### 20.4 Override capabilities (admin only)

> **Server admin puede:**

- Override pricing canónico (config-driven).
- Disable specific sinks/sources temporal.
- Inject seed money to specific account (logged + audit).
- Force bankruptcy resolution.
- Refund disputed escrow.
- **Cannot:** delete history (immutable audit trail).

---

## 21. Roadmap del documento + estado

### 21.1 Roadmap

#### Oleada 1 (T-0 — incluido)
- ✅ 7 pilares económicos.
- ✅ Currency model + IBAN convention.
- ✅ Money supply sources/sinks.
- ✅ Conditions iniciales canónicas.
- ✅ Salaries por rol.
- ✅ Pricing canónico todos items.
- ✅ Margins por nodo.
- ✅ Quality + lineage formula.
- ✅ Sistema empresa + escrow + bankruptcy.
- ✅ Reputation impact.
- ✅ Dynamic pricing Retail.
- ✅ Promociones.
- ✅ Logística costs.
- ✅ NPC bridge prices.
- ✅ Tax + server fees.
- ✅ Sinks específicos.
- ✅ KPIs + monitoring.
- ✅ Edge cases + anti-patterns.
- ✅ Tooling balance.

#### Oleada 2 (T+6 meses)
- 🔜 Savings accounts con interest.
- 🔜 Loans player-to-player formalizados.
- 🔜 Stocks / shares trading entre empresas.
- 🔜 Currency exchange (multi-server federation).
- 🔜 Insurance products (más allá de logistics).
- 🔜 Quest rewards balanceados.
- 🔜 Subscriptions premium servidor con server bonuses tuning.
- 🔜 Numbers para verticales nuevas (Lácteos, Hortícola).

#### Oleada 3+ (T+12 meses)
- 🔜 Multi-server economic federation.
- 🔜 Marketplace global Admirals (cross-server trade).
- 🔜 Bonds / financial instruments.
- 🔜 Complex tax optimization tooling.
- 🔜 Insurance deep dive (life, property).

### 21.2 Estado del documento

- **Versión:** 1.0 (firmado — completo, 21 secciones, 3 partes publicadas).
- **Próxima revisión:** evolución cuando se añadan verticales nuevas o instruments financieros oleada 2.
- **Documentos hijos pendientes:**
  - `economy/02_bakery_economy.md` — detalle Bakery (B2B vs B2C economics).
  - `economy/03_retail_economy.md` — detalle Retail (markups por categoría + dynamic).
- **Documentos relacionados:**
  - Bible §11 (Calidad y economía) — input filosófico.
  - DB Schema §6-§7 (banking schema) — implementation backing.
  - Events Catalog `bank:*` `market:*` — eventos asociados.
  - Architecture §10 (Item Físico) — quality + lineage data structure.

### 21.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 (parte 1) | 2026-05-01 | Founder + Cascade | §0-§7 (filosofía, currency, money supply, conditions iniciales, salaries, pricing canónico, margins). |
| 1.0 (parte 2) | 2026-05-01 | Founder + Cascade | §8-§14 (quality+lineage, empresa, banca, reputation, dynamic pricing, promos, logística). |
| 1.0 (parte 3) | 2026-05-01 | Founder + Cascade | §15-§21 (NPC bridges, tax, sinks específicos, KPIs, edge cases, tooling, roadmap). **Documento completo, firmable.** |

---

## Resumen ejecutivo del documento (cierre)

El **Economic Model** es la columna vertebral numérica del producto Admirals:

- **7 pilares económicos** alineados con los 5 pilares de producto Bible.
- **EUR canónico** con DECIMAL(12,2) hard, no float drift.
- **Sources vs sinks balance** target: sinks ≥ sources × 1.05 (anti-inflation 5%).
- **Pricing canónico** completo de cada ítem físico de la cadena del pan, todas qualities.
- **Margins por nodo** verificadas: Granja 49% / Molino 23% / Bakery 29-47% / Retail 18-24%.
- **Lineage premium** ⭐ — el competitive moat: × 1.15-1.20 sobre canónico para productos trazados.
- **Reputation impact** explícito × 0.90-1.10 sobre pricing.
- **Bankruptcy real** — empresa puede quebrar, server NO refilla.
- **NPC bridges** ±9% peor que P2P para incentivar comercio entre players.
- **Server income** 35% sales tax + 22% maintenance + 18% MLO rent (estructura sostenible).
- **KPIs económicos** completos con thresholds + alerts automáticas.
- **Tooling balance** con simulator CLI + admin dashboard real-time.
- **Edge cases + anti-patterns** documentados.

> **Si en oleada 1 con 50 players activos durante 30 días, el inflation está entre -2% y +3%, la velocity > 2 tx/day, ningún top accumulator > 30% money supply, lineage coverage > 40%, y NPC dependency < 40% — habrá funcionado el modelo económico Admirals.**

Esa es la firma de salud económica.

---

*"Si este documento está mal, el producto entero está mal."*

**FIN DEL DOCUMENTO `economy/01_economic_model.md` v1.0**
