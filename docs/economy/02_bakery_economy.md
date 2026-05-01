# 🥖 Admirals — Bakery Economy (detalle)

> **Versión:** 1.0 (firmado — completo, 8 secciones).
> **Documento padre:** `economy/01_economic_model.md` v1.0 (master económico). **Toda regla del master aplica aquí salvo override explícito.**
> **Documento hermano:** `economy/03_retail_economy.md` (próximo).
> **Documentos referenciados:** `design/04_node_bakery.md` v1.0, Bible §6, `technical/03_db_schema.md` v1.0.
> **Estado:** firmado.

> **Lectura previa obligatoria:** `economy/01_economic_model.md` completo (especialmente §6.3 pricing, §7.3 margen Bakery), `design/04_node_bakery.md` §3-§7 (mecánicas Bakery).

---

## 0. Resumen ejecutivo

Este documento es **el detalle económico del nodo Bakery** — heredando todo del master y profundizando en lo específico:

- **B2B vs B2C** economics detallados (channel split, customer behavior).
- **Recetas con cost breakdown** ingrediente-a-ingrediente, todas las qualities.
- **Daily schedule economics** — hora pico horneado pre-dawn, hora pico venta morning/evening.
- **Capacity planning** — oven utilization, batch sizing, throughput.
- **Waste management** economics — unsold expiry, cost de mermas.
- **Subscriptions B2B** — clientes Retail recurrentes con commitment discount.
- **ROI por SKU** — qué pan rinde más profit absoluto vs % margin.
- **Margins finos** por categoría (pan estándar vs especialidades vs pastry premium).
- **Edge cases** específicos Bakery.

> **Por qué este documento existe:** el master define las reglas globales. El Bakery tiene **mecánicas únicas** (fermentación, doble-channel B2B+B2C, expiry rápido) que merecen tratamiento explícito para que el founder Bakery sepa exactamente cómo funcionará su negocio.

---

## 1. Channel split — B2B vs B2C

### 1.1 Estructura típica de revenue Bakery

> **Bakery healthy en steady-state opera split aproximado:**

| Channel | % revenue typical | % volume typical | Margin neto |
|---|---|---|---|
| **B2C mostrador** (clientes PED + players directo) | 55-65% | 70% | 47% |
| **B2B contratos** (Retail subscribers) | 35-45% | 30% | 29% |

**Insight clave:**
- B2C tiene **margen más alto** pero requiere **shop-front activo** + cajero presente.
- B2B tiene **volumen predecible** + sin staff atendiendo, pero **margen más bajo**.
- **Bakery óptimo** combina ambos — B2B asegura runway base, B2C maximiza margin.

### 1.2 B2B economics

#### 1.2.1 Tipos de cliente B2B

| Cliente | Volumen típico/semana | Pricing |
|---|---|---|
| **Retail supermercado pequeño** | 200-500 unidades | Canónico B2B |
| **Retail supermercado mid** | 500-1500 unidades | Canónico - 5% (volumen) |
| **Retail supermercado grande** | 1500-4000 unidades | Canónico - 10% (volumen) |
| **Restaurante / Hotel / Catering** | 100-300 unidades | Canónico + 5% (premium custom) |
| **Cafetería / Bar** | 50-150 unidades | Canónico (small order) |

#### 1.2.2 B2B contract typical structure

> **Ejemplo contrato típico:**

- **Cliente:** Supermercado Vespucci.
- **Duration:** 30 días.
- **Items:** 200 baguettes/día + 80 panes blancos/día.
- **Quality target:** A-grade.
- **Lineage:** completo trazado.
- **Delivery:** daily 6:00am, vía logistics player.
- **Pricing:** 0.85 €/baguette × 200 + 1.20 €/loaf × 80 = 266 €/día.
- **Total contract:** 266 € × 30 = **7.980 €**.
- **Escrow:** 7.980 € locked.
- **Escrow fee:** 79.80 € (1%).

#### 1.2.3 B2B subscription discounts

> **Para clientes B2B con commitment > 30 días:**

| Commitment | Discount sobre canónico |
|---|---|
| **30-90 días** | -3% |
| **90-180 días** | -5% |
| **180+ días** | -8% |

**Trade-off:** menor margen unitario, pero **runway garantizado** + escrow large = capital fluyendo.

### 1.3 B2C economics

#### 1.3.1 PED clients (NPC) flow

> **Bakery con shop-front activo recibe PEDs durante horario:**

- **Spawn rate:** depende de Foot Traffic del MLO + reputation Bakery.
- **Conversion:** cliente PED entra → consulta vitrina → compra (60-85% conversion).
- **Average ticket:** 3-12 € por compra PED (1-3 items).
- **Tip:** PED clients pagan precio canónico B2C (canónico × 1.45).

#### 1.3.2 Player clients (B2C directo)

> **Players que compran Bakery para consumo:**

- **Items food para survival/RP** (oleada 2+ con hunger system).
- **Items decorativos** (regalos, eventos servidor).
- **Pricing:** mismo canónico B2C × 1.45 (no discount players).

#### 1.3.3 B2C peak hours

| Hora server | Demand level |
|---|---|
| **05:00-07:00** | Pre-opening (no shop) |
| **07:00-10:00** | ⭐⭐⭐ peak desayunos |
| **10:00-12:00** | mid demand |
| **12:00-14:30** | ⭐⭐ peak comidas |
| **14:30-17:00** | low demand (siesta) |
| **17:00-20:00** | ⭐ secondary peak meriendas |
| **20:00-22:00** | low demand |
| **22:00-05:00** | closed |

> **Decisión:** un Bakery cerrado durante peaks pierde ~70% potential revenue. Forces presence o NPC cajero (con eficiencia × 0.85).

---

## 2. Recetas con cost breakdown

### 2.1 Pan baguette estándar (quality A)

> **Receta canónica para 100 unidades:**

| Ingrediente | Cantidad | Cost unitario | Total |
|---|---|---|---|
| Harina trigo blanca quality A | 18 kg (0.72 sacos) | 75 €/saco | **54 €** |
| Sal | 0.36 kg | 1 €/kg | 0.36 € |
| Levadura fresca | 0.45 kg | 8 €/kg | 3.60 € |
| Agua | 12 L | – (utility) | 0 € |
| **Total ingredientes** | | | **~58 €** |
| Energía horno (gas + electric) | 100 baguettes | – | 8 € |
| Salaries (panadero + cajero hora-prorrata) | 100 baguettes | – | 5 € |
| Mantenimiento prorrata | 100 baguettes | – | 4 € |
| **TOTAL COST 100 baguettes** | | | **~75 €** |
| Revenue B2B 100 baguettes A | | 0.85 €/und | **85 €** |
| Revenue B2C 100 baguettes A | | 1.23 €/und | **123 €** |
| **Margin B2B** | | | **10 € (12%)** |
| **Margin B2C** | | | **48 € (39%)** |

> **Nota:** estos números son **per-receta directa**. El margin neto del nodo §7.3 master (29% B2B, 47% B2C) incluye además depreciación + mermas + tax — el delta entre receta y nodo es esos overheads adicionales.

### 2.2 Pan blanco loaf (quality A)

> **Receta para 50 unidades (bigger product):**

| Ingrediente | Cantidad | Cost | Total |
|---|---|---|---|
| Harina trigo blanca A | 22 kg | 75 €/saco | 66 € |
| Sal | 0.5 kg | 1 €/kg | 0.50 € |
| Levadura | 0.6 kg | 8 €/kg | 4.80 € |
| Aceite | 0.5 L | 4 €/L | 2 € |
| Agua | 14 L | – | 0 € |
| **Total ingredientes** | | | **~73 €** |
| Energía + salaries + maint | | | 11 € |
| **TOTAL** | | | **84 €** |
| Revenue B2B 50 loaves A | 1.20 €/und | | 60 € |
| Revenue B2C 50 loaves A | 1.74 €/und | | 87 € |
| **Margin B2B** | | | **-24 € (LOSS)** ⚠️ |
| **Margin B2C** | | | **3 € (3%)** |

> ⚠️ **Pan blanco loaf NO es rentable solo por B2B.** Requiere mix B2C significativo. Es **producto de surtido** — el cliente PED espera encontrarlo, pero el bakery no debería sobre-producirlo.

### 2.3 Pan integral whole loaf (quality A)

> **Receta para 50 unidades:**

| Ingrediente | Cantidad | Cost | Total |
|---|---|---|---|
| Harina trigo integral A | 22 kg | 82 €/saco | 72 € |
| Sal + semillas + miel | – | – | 5 € |
| Levadura | 0.6 kg | 8 €/kg | 4.80 € |
| Agua | 14 L | – | 0 € |
| **Total ingredientes** | | | **~82 €** |
| Otros costs | | | 11 € |
| **TOTAL** | | | **93 €** |
| Revenue B2B 50 A | 1.50 €/und | | 75 € |
| Revenue B2C 50 A | 2.18 €/und | | 109 € |
| **Margin B2B** | | | **-18 € (LOSS)** ⚠️ |
| **Margin B2C** | | | **16 € (15%)** |

> **Mismo pattern que loaf blanco** — integral panado solo B2B no es rentable. Funciona si se mixa con B2C. **El integral suele ser premium B2C** y no se vende mucho a Retail.

### 2.4 Pan rústico / artesano (quality A)

> **Receta para 30 unidades (lower volume, premium product):**

| Ingrediente | Cantidad | Cost | Total |
|---|---|---|---|
| Harina trigo whole A | 14 kg | 82 €/saco | 46 € |
| Masa madre (pre-ferment) | 2 kg | – | 4 € |
| Sal + semillas | – | – | 3 € |
| Levadura | 0.3 kg | 8 €/kg | 2.40 € |
| Agua | 9 L | – | 0 € |
| **Total ingredientes** | | | **~55 €** |
| Energía + salaries (más tiempo fermentación) | | | 12 € |
| Maint | | | 3 € |
| **TOTAL** | | | **70 €** |
| Revenue B2B 30 A | 1.80 €/und | | 54 € |
| Revenue B2C 30 A | 2.61 €/und | | 78 € |
| **Margin B2B** | | | **-16 € (LOSS)** ⚠️ |
| **Margin B2C** | | | **8 € (11%)** |

> **El rústico es premium B2C only.** No se vende a Retail con margen. Es **diferenciador artesano** + **lineage premium target** — quality A + lineage completo añade × 1.20 = revenue 3.13 €/und = margen 24 €/30 units (34%).

### 2.5 Especialidades (centeno, multicereales, etc.)

> **Receta para 25 unidades (premium, low volume):**

| Ingrediente | Cantidad | Cost | Total |
|---|---|---|---|
| Harina especialidad A | 10 kg | 110 €/saco | 44 € |
| Semillas + frutos secos | – | – | 8 € |
| Masa madre | 1.5 kg | – | 3 € |
| Sal + levadura | – | – | 4 € |
| Agua | 6 L | – | 0 € |
| **Total ingredientes** | | | **~59 €** |
| Otros costs | | | 11 € |
| **TOTAL** | | | **70 €** |
| Revenue B2B 25 A | 2.20 €/und | | 55 € |
| Revenue B2C 25 A | 3.19 €/und | | 80 € |
| **Margin B2B** | | | **-15 € (LOSS)** |
| **Margin B2C** | | | **10 € (14%)** |
| **Margin B2C + lineage premium** | × 1.20 = 3.83 €/und | | **26 € (37%)** ⭐ |

> **Especialidades con lineage** son top performers margen — único que justifica producirlas. Sin lineage no rentables.

### 2.6 Pastry — croissant (quality A)

> **Receta para 60 unidades:**

| Ingrediente | Cantidad | Cost | Total |
|---|---|---|---|
| Harina blanca A | 8 kg | 75 €/saco | 24 € |
| Mantequilla | 2.5 kg | 12 €/kg | 30 € |
| Azúcar | 0.5 kg | 2 €/kg | 1 € |
| Levadura + huevos + leche | – | – | 6 € |
| Sal | 0.1 kg | 1 €/kg | 0.10 € |
| **Total ingredientes** | | | **~61 €** |
| Energía + salaries (multi-step proceso) | | | 13 € |
| Maint | | | 3 € |
| **TOTAL** | | | **77 €** |
| Revenue B2B 60 A | 1.10 €/und | | 66 € |
| Revenue B2C 60 A | 1.60 €/und | | 96 € |
| **Margin B2B** | | | **-11 € (LOSS)** |
| **Margin B2C** | | | **19 € (24%)** |

> **Croissant es B2C-driven.** El B2B (a Retail) suele combinarse con orden de pan estándar para hacer entrega rentable conjunta (kaizen B2B).

### 2.7 Pastry premium artesana

> **Receta para 20 unidades (low volume, alto margen):**

| Ingrediente | Cantidad | Cost | Total |
|---|---|---|---|
| Harina premium | 4 kg | 110 €/saco | 18 € |
| Mantequilla premium | 1.5 kg | 18 €/kg | 27 € |
| Chocolate / frutas / fillings | – | – | 18 € |
| Otros | – | – | 6 € |
| **Total ingredientes** | | | **~69 €** |
| Energía + salaries (artesano) | | | 14 € |
| **TOTAL** | | | **83 €** |
| Revenue B2B 20 A | 2.50 €/und | | 50 € |
| Revenue B2C 20 A | 3.63 €/und | | 73 € |
| **Margin B2B** | | | **-33 € (LOSS, no producir B2B)** |
| **Margin B2C** | | | **-10 € (LOSS sin premium)** ⚠️ |
| **Margin B2C + reputation premium 80+** | × 1.10 = 4.00 €/und | | **-3 € (still LOSS)** |
| **Margin B2C + reputation 80+ + lineage** | × 1.20 = 4.36 €/und | | **4 € (5%)** |

> **Pastry premium SOLO RENTABLE** con reputation 80+ + lineage premium. Es **flagship product** — bakery con reputation top puede pricing × 1.20-1.30 sobre canónico (manager override).

### 2.8 Resumen ROI por SKU

| SKU | Margin neto B2C alone | Margin con premium full | Best channel |
|---|---|---|---|
| Baguette | 39% | 47% | **B2B + B2C dual** ⭐ |
| Pan blanco loaf | 3% | 8% | B2C primary |
| Pan integral | 15% | 22% | B2C primary |
| Pan rústico | 11% | 34% | **B2C premium** ⭐ |
| Especialidades | 14% | 37% | **B2C premium + lineage** ⭐⭐ |
| Croissant | 24% | 30% | B2C primary |
| Pastry premium | -10% baseline | 5-15% premium | **B2C premium + reputation** ⭐⭐⭐ |

**Insight final:**
- **Baguette** es el caballo de batalla — único pan rentable en B2B puro + excelente B2C.
- **Pastry y rústico** son margin makers en B2C premium con reputation alta.
- **Loaves estándar** son surtido obligatorio pero NO money makers.

---

## 3. Daily schedule economics

### 3.1 Schedule canónico de un Bakery operacional

| Hora server | Activity | Cost driver |
|---|---|---|
| **02:00-04:00** | Receta + amasado + first-rise | Salary panadero turno noche (+30%) |
| **04:00-06:00** | Shaping + second-rise + horneado peak | Energy horno peak |
| **06:00-07:00** | Cooling + display setup | Salary cajero |
| **07:00-10:00** | ⭐ B2C peak desayunos (45-55% sales día) | Salary cajero |
| **10:00-12:00** | Re-baking complementary + B2C mid | Energy + salary |
| **12:00-14:30** | ⭐ B2C peak comidas | Salary |
| **14:30-17:00** | Closed o B2B delivery dispatch | Salary driver opcional |
| **17:00-20:00** | ⭐ B2C secondary peak meriendas | Salary |
| **20:00-22:00** | Closing + clean + waste assessment | Salary |
| **22:00-02:00** | Closed | – |

**Insights:**
- Pre-dawn shift (panadero noche) es **el más caro pero esencial** — sin pan a las 7am, el bakery pierde 50% revenue del día.
- Tres peaks B2C consume ~85% del día revenue.
- Off-peak times (14:30-17:00) son ideales para B2B delivery dispatch (no compite con cajero atender PEDs).

### 3.2 Capacity planning

#### 3.2.1 Oven utilization

| Tipo horno | Capacidad por batch | Tiempo batch | Throughput máx/hora |
|---|---|---|---|
| **Horno pequeño (small bakery)** | 30 baguettes / 15 loaves | 25 min | 72 baguettes/h |
| **Horno medium (default)** | 60 baguettes / 30 loaves | 25 min | 144 baguettes/h |
| **Horno grande (industrial)** | 120 baguettes / 60 loaves | 25 min | 288 baguettes/h |

**Decisión:**
- Bakery small: capacity ~500 baguettes/día.
- Bakery medium: capacity ~1.000 baguettes/día.
- Bakery large: capacity ~2.000+ baguettes/día.

**ROI hardware:**
- Horno medium upgrade: 25.000 € → +500 baguettes/día capacity → ~150-200 €/día revenue extra → ROI ~120-150 días.

#### 3.2.2 Workforce sizing

| Bakery size | Panaderos | Cajeros | Drivers | Manager |
|---|---|---|---|---|
| **Small** | 1 | 1 | 0 (pickup only) | Founder = manager |
| **Medium** | 2 (turno doble) | 2 | 1 part-time | 1 dedicated |
| **Large** | 3-4 | 3 | 2 | 1 + 1 assistant |

**Total payroll Bakery medium quincenal:**
- 2 maestros panaderos: 4.400 €
- 2 cajeros: 2.600 €
- 1 driver: 1.700 €
- 1 manager: 2.500 €
- **Total: ~11.200 €/quincena = ~22.400 €/mes**

**Revenue mensual target Bakery medium para sustainability:**
- Profit objetivo: 30% del revenue.
- Costs ~70% del revenue → revenue mensual mínimo ~75.000 €/mes.
- Daily target: ~2.500 €/día.

---

## 4. Waste management economics

### 4.1 Mermas típicas

> **Pan unsold expira rápido** (máx 24h fresco, 48h marcado day-old):

| Day | Saleable price |
|---|---|
| **Day 0** (fresh) | 100% canónico |
| **Day 1** (day-old) | 50-60% canónico (descuento clearance) |
| **Day 2+** | 0% (waste forced) |

**Waste rate típico:**

| Tipo product | Waste % típico |
|---|---|
| Baguette | 8-12% |
| Pan blanco loaf | 5-10% |
| Pan integral | 5-8% |
| Especialidades | 12-18% (high-volume risk) |
| Pastry | 10-15% (más perecedero) |

**Cost waste mensual (Bakery medium):**
- Production: ~2.000 baguettes/día × 30 = 60.000/mes.
- Waste 10%: 6.000 baguettes wasted.
- Cost: 0.75 €/baguette × 6.000 = **4.500 €/mes pérdida directa**.

### 4.2 Estrategias mitigation waste

#### 4.2.1 Day-old discount sales

- **Cierre de día (20:00-22:00):** -50% pricing en panes day-0 que sobran.
- **Apertura siguiente día:** -60% pricing en day-1.
- **Recuperación: ~20-30% del cost waste**.

#### 4.2.2 B2B excedente

- **Contracts B2B "flex"** con Retail: pueden absorber excedente diario a -15% canónico.
- Win-win: bakery reduce waste, Retail tiene producto extra.

#### 4.2.3 Donation / charity (oleada 2+)

- **Donación a NPC food bank** → tax deduction (5% del waste value reembolsado servidor).
- Reputation +0.2 puntos por donation.
- Sink legítimo + buena PR.

#### 4.2.4 Bread-into-breadcrumbs / croutons

> **Reciclaje creativo:**
- Pan day-2 → triturado → migas/croutons → vendible 0.30 €/100g.
- Recovery: ~10-15% del cost waste.
- Requires equipment grinder (~3.000 €).

### 4.3 Waste prediction tool

> **Manager Panel Bakery muestra:**

- Production today vs sales prediction (basado en 7-day rolling).
- Recommendation: "Producir X baguettes" para minimizar waste.
- Alert: "Stock alto 16:00 → considerar promo flash" si demand <70% prediction.

---

## 5. Subscriptions B2B

### 5.1 Modelo subscription

> **Cliente Retail repetidor firma contract recurrente.**

#### 5.1.1 Tipos

| Type | Duration | Volume commitment | Discount |
|---|---|---|---|
| **Weekly subscription** | 7 días auto-renew | Daily delivery | -3% canónico |
| **Monthly subscription** | 30 días | Daily delivery | -5% |
| **Quarterly subscription** | 90 días | Daily delivery | -8% |
| **Loyalty subscription** | 6 meses+ | Daily delivery | -10% + reputation bonus |

#### 5.1.2 Beneficios bilateral

**Cliente Retail:**
- Pricing predecible.
- Supply garantizada.
- Lineage chain estable.

**Bakery:**
- Revenue base predecible (runway).
- Inventory planning más eficiente.
- Reduces mermas (production matches commitment).

### 5.2 Subscription metrics

> **Bakery Manager Panel muestra:**

- **MRR (Monthly Recurring Revenue)** — sumatorio subscriptions activas.
- **Subscription churn rate** — % canceladas/mes.
- **Avg subscription duration** — días promedio retention.
- **Subscription upgrade rate** — % weekly → monthly o monthly → quarterly.

### 5.3 Subscription edge cases

#### 5.3.1 Cancellation
- **Grace period:** 7 días antes del renew window para cancel.
- **Penalty cancel mid-period:** 10% del remaining contract value (sink al server).

#### 5.3.2 Quality miss en subscription
- **Quality below promised** (ej. promete A, entrega C consecutivamente): cliente puede pause subscription → bakery debe restaurar quality o forfeit contract.

---

## 6. Edge cases económicos Bakery

### 6.1 Oven failure mid-production

- Equipo break → batch en horno potentially perdido.
- Insurance equipment cubre 80% del valor batch + 100% repair cost (si insurance activo).
- Without insurance: total loss + repair cost.
- **Mantenimiento preventivo §17.2 master** evita 90% de breaks.

### 6.2 Ingredient shortage (NPC bridge fallback)

- Si NPC supplier de harina queda sin stock + no player suppliers → bakery forced a NPC alternate at +15% premium.
- **Mitigation:** mantener stock buffer 5-7 días + multiple supplier contracts.

### 6.3 Demand spike unexpected (special event server)

- Server-wide event (festival, holiday) puede triplicar demand.
- Manager Panel alert pre-event si server announces.
- Override capacity temporal: bakery puede contratar **NPC overflow workers** (1.5x cost normal salary, eficiencia × 0.85).

### 6.4 Reputation damage event

- Quality C/D delivered en B2B subscription → reputation -3 puntos.
- Cliente puede leave bad review (oleada 2+).
- Recovery: 5-10 deliveries quality A consecutivos para restore.

### 6.5 Multiple bakeries en mismo zone (competition)

- Si 2+ bakeries en mismo MLO district → **demand split** + price war risk.
- Pricing diferentiation strategy: una bakery especialidades premium, otra volume estándar.
- Reputation becomes critical differentiator.

### 6.6 Founder burnout (player AFK pattern)

- Bakery requires consistent daily presence (pre-dawn baking).
- Player AFK 3+ días → quality + sales drop → revenue collapse.
- **Mitigation:** training maestro panadero player con permissions delegate.
- O **NPC overflow** (eficiencia × 0.85 para tiempo limitado).

---

## 7. KPIs específicos Bakery

> **Adicionales a §18 master, dashboard Bakery Manager Panel muestra:**

### 7.1 Production KPIs

- **Items horneados/día** (target capacity).
- **Oven utilization %** (target 70-85%).
- **Quality A rate** (% outputs A grade).
- **Recipe success rate** (% batches sin fail).
- **Avg fermentation time variance** (consistency metric).

### 7.2 Sales KPIs

- **B2B vs B2C revenue split**.
- **Average ticket B2C** (PED clients).
- **Conversion rate B2C** (PEDs entran vs compran).
- **Subscription MRR + churn**.
- **Top SKUs revenue + margin**.

### 7.3 Waste KPIs

- **Waste rate %** (target <10% para baguettes).
- **Day-old recovery %** (cuánto del waste se vende discount).
- **Cost waste mensual** (target <8% revenue).

### 7.4 Customer KPIs

- **B2C return customers** (player customers regulares).
- **B2B subscription retention**.
- **Reputation score trend** (rolling 30d).

---

## 8. Roadmap del documento + estado

### 8.1 Roadmap

#### Oleada 1 (T-0 — incluido)
- ✅ Channel split B2B vs B2C.
- ✅ Recetas con cost breakdown todas las SKUs.
- ✅ Daily schedule economics.
- ✅ Capacity planning.
- ✅ Waste management.
- ✅ Subscriptions B2B.
- ✅ ROI por SKU.
- ✅ Edge cases.
- ✅ KPIs específicos.

#### Oleada 2 (T+6 meses)
- 🔜 Pastelería avanzada (tartas, eventos custom).
- 🔜 Catering jobs (eventos servidor).
- 🔜 Hunger system integration (B2C consumo real).
- 🔜 Reviews/ratings clientes PED.

#### Oleada 3+ (T+12 meses)
- 🔜 Multi-location bakery chains.
- 🔜 Franchise model (license bakery brand).

### 8.2 Estado del documento

- **Versión:** 1.0 (firmado — completo, 8 secciones).
- **Próxima revisión:** evolución cuando se añadan pastry avanzada o catering jobs en oleada 2.
- **Documento padre:** `economy/01_economic_model.md` v1.0 (firmado).
- **Documento hermano:** `economy/03_retail_economy.md` (próximo).
- **Documentos relacionados:**
  - `design/04_node_bakery.md` v1.0 — mecánicas Bakery.
  - Bible §6 — pilar Bakery.

### 8.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Documento completo en 1 sesión. 8 secciones cubriendo channel split, recetas detalladas, schedule, waste, subscriptions, edge cases, KPIs. **Firmable.** |

---

## Resumen ejecutivo del documento (cierre)

El **Bakery Economy** profundiza en el master con foco específico:

- **Channel split 60/40 B2C/B2B** es el sweet spot — B2C margin alto, B2B volume predecible.
- **Recetas con cost breakdown** muestran que **solo baguette** es B2B-rentable solo. Otros SKUs requieren mix B2C.
- **Pastry premium + lineage + reputation 80+** es el flagship margin (37%).
- **Schedule pre-dawn baking** es esencial — cerrado a las 7am pierde 50% revenue del día.
- **Capacity planning:** Bakery medium = 1.000 baguettes/día = ~75.000 €/mes revenue target.
- **Waste 10%** baseline = ~4.500 €/mes pérdida — mitigable a 5% con day-old discount + B2B flex.
- **Subscriptions B2B** ofrecen runway predecible con discount escalado 3-10%.
- **Edge cases** documentados: oven failure, shortage, demand spike, AFK risk.

> **Si en oleada 1 con un Bakery medium player-operated, el founder puede mantener 25-35% margen neto, waste rate <8%, B2B subscription MRR > 30.000 €/mes, reputation 70+, sin AFK > 48h consecutivas — habrá funcionado el modelo Bakery.**

---

*"El bakery sin presencia muere antes del mediodía."*

**FIN DEL DOCUMENTO `economy/02_bakery_economy.md` v1.0**
