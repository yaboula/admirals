# 🛒 Admirals — Retail Economy (detalle)

> **Versión:** 1.0 (firmado — completo, 10 secciones).
> **Documento padre:** `economy/01_economic_model.md` v1.0 (master económico). **Toda regla del master aplica aquí salvo override explícito.**
> **Documento hermano:** `economy/02_bakery_economy.md` v1.0 (firmado).
> **Documentos referenciados:** `design/05_node_retail.md` v1.0, Bible §7, `technical/03_db_schema.md` v1.0, `economy/01_economic_model.md` §12 (dynamic pricing), §13 (promos).
> **Estado:** firmado.

> **Lectura previa obligatoria:** `economy/01_economic_model.md` completo (especialmente §6.4 markups Retail, §7.4 margen Retail, §12 dynamic pricing, §13 promos), `design/05_node_retail.md` §3-§9 (mecánicas Retail).

---

## 0. Resumen ejecutivo

Este documento es **el detalle económico del nodo Retail** — heredando todo del master y profundizando en lo específico:

- **Markups detallados por categoría** (panadería, lácteos, carnicería, frutas/verduras, bebidas, conservas, congelados).
- **Dynamic pricing** en profundidad — fórmulas + caps + casos.
- **Stock turnover economics** — perecederos vs no-perecederos.
- **PED conversion** factors + reputation impact + foot traffic.
- **Promociones ROI** detallado por tipo.
- **Multi-supplier strategy** — cómo balancear suppliers para reducir riesgo.
- **Retail layouts** y su impacto económico (small / mid / large / hipermercado).
- **Edge cases** específicos Retail.
- **KPIs específicos** Retail Manager Panel.

> **Por qué este documento existe:** el master define markups y dynamic pricing globalmente. Retail tiene **mecánicas únicas** — multi-categoría simultáneo, perecederos rapid expiry, PED foot traffic dependence, competitive zones — que merecen tratamiento explícito para que el founder Retail entienda cómo va a operar realmente.

---

## 1. Markups detallados por categoría

### 1.1 Markup standard table (recap master + detail)

> **Markup = precio venta cliente / precio compra B2B del proveedor.**

| Categoría | Markup standard | Markup quality A | Markup lineage_complete | Margin neto target |
|---|---|---|---|---|
| **Panadería** | × 1.55 | × 1.65 | × 1.78 | 24% |
| **Lácteos** | × 1.45 | × 1.55 | × 1.65 | 20% |
| **Carnicería** | × 1.50 | × 1.62 | × 1.75 | 22% |
| **Pescadería** | × 1.55 | × 1.68 | × 1.80 | 23% |
| **Frutas/verduras** | × 1.40 | × 1.50 | × 1.60 | 18% |
| **Bebidas** | × 1.35 | × 1.42 | × 1.50 | 16% |
| **Conservas** | × 1.45 | × 1.52 | × 1.60 | 21% |
| **Congelados** | × 1.50 | × 1.58 | × 1.66 | 22% |
| **Limpieza/Hogar** | × 1.40 | × 1.45 | – | 19% |
| **Snacks/Confitería** | × 1.55 | × 1.62 | × 1.70 | 25% |

### 1.2 Por qué cada markup es ese

#### 1.2.1 Panadería (× 1.55) — flagship category
- High turnover diario (mermas medias).
- Peak hours predecibles → easy planning.
- **Lineage premium fuerte** (× 1.78) — clientes valoran trazabilidad pan.
- **Margen neto 24%** es el mejor pan-Retail combo.

#### 1.2.2 Lácteos (× 1.45)
- Refrigerated → coste energy higher.
- Mermas moderadas (5-7%).
- Volume estable, demand predictable.
- Markup más bajo compensa coste freezer.

#### 1.2.3 Carnicería (× 1.50)
- High value per unit (€8.50/kg+).
- Refrigerated obligatorio.
- Mermas críticas si freezer falla.
- Cold chain requirement justifica markup.

#### 1.2.4 Frutas/verduras (× 1.40)
- **Markup más bajo** — perecederos rapid (3-7 días vida útil).
- Mermas altas si over-stock.
- Volume game — depende de turnover rapid.
- Estrategia: pricing competitive + promos clearance.

#### 1.2.5 Bebidas (× 1.35)
- **Markup mínimo** — productos commodity (Coca-Cola, agua, etc.).
- Brand-driven, customers comparan precios.
- Volumen game pure.
- Frío opcional (drinks-on-shelf vs refrigerated).

#### 1.2.6 Conservas (× 1.45)
- Long shelf life (12-36 meses).
- Mermas casi cero.
- Stock turnover lento → cost capital tied.
- Markup compensa rotación lenta.

#### 1.2.7 Snacks/Confitería (× 1.55)
- Impulse buy → high margin.
- Mermas mid (chocolate puede expirar).
- Cross-sell efectivo en checkout.

### 1.3 Markup adjustments contextuales

> **Estos no son fixed — manager Retail puede ajustar dentro de caps:**

| Adjustment | Trigger | Effect |
|---|---|---|
| **Premium positioning** | Tienda en zona alta-renta | × 1.05-1.10 sobre standard |
| **Discount positioning** | Tienda en zona baja-renta | × 0.95-0.98 sobre standard |
| **Anchor pricing** | Producto promocional | -10% del standard |
| **Loss leader** | Producto para attract foot traffic | -20% (limitado a 1-2 SKUs) |

---

## 2. Dynamic pricing en profundidad

### 2.1 Recap fórmula master

```
price_retail = price_b2b_supplier
             × markup_category
             × quality_multiplier
             × lineage_multiplier
             × reputation_multiplier
             × dynamic_pricing_multiplier
```

Cada componente cap dentro de bounds (master §12.1).

### 2.2 Dynamic pricing scenarios detallados

#### 2.2.1 Hora pico (peak hours)

| Hora server | Demand level | Dynamic multiplier |
|---|---|---|
| **08:00-10:00** | Pre-work shopping mid | × 1.02 |
| **12:00-14:30** | ⭐ Lunch peak high | **× 1.08** |
| **17:00-20:00** | ⭐⭐ After-work peak max | **× 1.10** |
| **20:00-22:00** | Post-dinner low | × 1.00 |
| **22:00-08:00** | Night/morning empty | × 0.98 |
| **05:00-08:00** | Pre-opening (closed) | – |

> **Caps:** ningún markup × dynamic_multiplier puede exceder × 1.15 sobre canónico (master §12.1).

#### 2.2.2 Stock-driven dynamic

| Stock state | Trigger | Multiplier |
|---|---|---|
| **Critical low** (<15% lineal capacity) | Escarcity signal | × 1.08 |
| **Healthy** (40-80%) | Default | × 1.00 |
| **Saturated near expire** (>90% + <2 días vida) | Clearance | **× 0.85** |
| **Saturated normal** (>90%) | Slow rotation | × 0.95 |

#### 2.2.3 Competitor-driven dynamic

> **Si Retail hermano cercano (mismo zone) tiene precio diferente:**

- **Competitor más barato 5-15%:** matching parcial × 0.96 (no full match, preserve margin).
- **Competitor más barato >15%:** flag dump warning, NO matching forced.
- **Competitor más caro:** ignore (no upward dynamic from competition).

#### 2.2.4 Special events (oleada 2+)

| Event | Multiplier |
|---|---|
| Festividad servidor (Halloween, Navidad) | × 1.05 (premium festivo) |
| Promoción server-wide | × según promo |
| Crisis evento (escarcity narrative) | × 1.10 |

### 2.3 Update cadence (recap master §12.3)

- **Recalc cada 5min** baseline.
- **Excepción:** si event mid-day cambia condiciones (hora pico start), trigger immediate recalc.
- **Smooth transitions:** max delta 3% per 5min recalc — evita "shock pricing".

### 2.4 Anti-gaming caso real

#### 2.4.1 Scenario: PED storm
- 50 PEDs entran en 2min al Retail (event spike).
- ❌ **Naive pricing** subiría × 1.20 instantáneo.
- ✅ **Smooth pricing** sube gradualmente max × 1.15 cap, en pasos 3% per recalc → estabiliza en 5-10min.

#### 2.4.2 Scenario: Long-term player gaming
- Player descubre que cierra/abre precios para gaming → flagged.
- Admin alert si manager hace > 50 manual price overrides/día.

---

## 3. Stock turnover economics

### 3.1 Filosofía stock turnover

> **Cada producto en lineal "consume" capital.** Stock alto = capital tied. Stock bajo = lost sales.

**Sweet spot:** turnover rate alto + stockout rate bajo.

### 3.2 Tabla turnover por categoría

| Categoría | Turnover days target | Mermas % típico | Capital efficiency |
|---|---|---|---|
| **Panadería** | 1-2 días | 8-12% | Alta (rotación rápida) |
| **Lácteos** | 5-10 días | 5-8% | Mid |
| **Carnicería** | 3-7 días | 4-6% | Mid |
| **Frutas/verduras** | 3-5 días | 8-15% | Low (mermas altas) |
| **Bebidas** | 14-30 días | 1-2% | Mid |
| **Conservas** | 60-90 días | 0-1% | Low (capital tied long) |
| **Congelados** | 30-60 días | 1-3% | Mid |
| **Snacks/Confitería** | 15-30 días | 2-4% | Mid |

### 3.3 Stock optimization formulae

#### 3.3.1 Reorder point

```
reorder_point_units = (avg_daily_sales × lead_time_days) + safety_stock
```

Donde:
- `avg_daily_sales`: rolling 7-day promedio.
- `lead_time_days`: tiempo desde orden a recepción (B2B contract).
- `safety_stock`: 20-30% del consumo en lead_time.

#### 3.3.2 Economic Order Quantity (EOQ)

```
EOQ = sqrt((2 × annual_demand × order_cost) / holding_cost_per_unit)
```

> **Manager Panel** calcula esto automáticamente y sugiere orden optima.

### 3.4 Capital tied analysis

**Bakery medium Retail (mid-size):**
- Stock total promedio en tienda: ~25.000-40.000 € capital.
- Turnover overall: ~12 días.
- ROI capital: revenue 3.000 €/día → ~75.000 €/mes → 22% margen → 16.500 €/mes profit.
- Capital efficiency: 16.500 / 32.500 = **51% mensual return** sobre capital tied.

> **Insight:** Retail eficiente rinde 50%+ mensual sobre capital — uno de los ROI más altos del producto.

---

## 4. PED conversion + reputation + foot traffic

### 4.1 Foot traffic factors

> **Cuántos PEDs entran al Retail/hora depende:**

| Factor | Impact |
|---|---|
| **MLO location score** (zona alta-renta vs marginal) | × 0.7 a × 1.5 |
| **Hora del día** | × 0.5 (low) a × 2.0 (peak) |
| **Reputation Retail** | × 0.7 (untrusted) a × 1.25 (premium) |
| **Promo activa** | × 1.15-1.30 |
| **Competition cercana** | × 0.80-1.20 |
| **Server population** | × 0.5 (low pop) a × 1.5 (high pop) |
| **Day of week** (oleada 2+) | × 0.8 (lunes) a × 1.3 (viernes-sábado) |

**Baseline:** Retail mid en zona standard, hora media, reputation 60 → ~50-80 PEDs/hora foot traffic.

### 4.2 Conversion rate factors

> **De los PEDs que entran, qué % compran:**

| Factor | Impact en conversion |
|---|---|
| **Stock fill rate** (>80% lineales fill) | × 1.10 |
| **Stock empty (>30% empty lineales)** | × 0.65 |
| **Pricing competitive** (vs market avg) | × 1.05 if cheaper, × 0.92 if expensive |
| **Reputation Retail** | × 0.7 to × 1.25 |
| **Cajero presente** (player cashier) | × 1.08 vs NPC |
| **Lineage premium displayed** | × 1.06 |
| **Promo activa** | × 1.20-1.40 |
| **Cleanliness MLO state** (oleada 2+) | × 0.8 (sucio) a × 1.05 (impeccable) |

**Baseline conversion:** 60-75% PEDs que entran terminan comprando.

### 4.3 Average ticket factors

| Factor | Impact en avg ticket |
|---|---|
| **Cross-selling effective** (productos cerca checkout) | × 1.15 |
| **Promo bundles activas** | × 1.20 |
| **Impulse buy items checkout** | × 1.10 |
| **Premium positioning** | × 1.25 (less items pero más caros) |
| **Discount positioning** | × 0.85 (más items pero más baratos) |

**Baseline avg ticket Retail mid:** 8-15 € por transacción PED.

### 4.4 Revenue formula end-to-end

```
revenue_hourly = foot_traffic_hour
               × conversion_rate
               × avg_ticket
```

**Ejemplo Retail mid healthy hora pico 17:00-18:00:**
- Foot traffic: 80 PEDs × 1.10 (peak) × 1.05 (reputation 75) = 92 PEDs.
- Conversion: 70% × 1.10 (good stock) × 1.06 (lineage) = 81%.
- Avg ticket: 12 € × 1.15 (cross-sell) = 13.80 €.
- **Revenue/hour:** 92 × 0.81 × 13.80 = **1.029 €/hora.**

Daily projection (7h productive peak + 8h normal):
- 7h × 1.029 = 7.200 €
- 8h × 600 (avg) = 4.800 €
- **Daily total: ~12.000 €.**

> **Pero realidad típica** Retail mid healthy 80-90% del día: **~3.000-4.500 €/día revenue**, 75.000-110.000 €/mes.

### 4.5 Reputation feedback loop

> **Reputation alta → más foot traffic → más sales → más quality fulfilling contracts → reputation sube.**

- Pero también: **reputation alta → competidores notice → price war risk.**
- **Premium tier (80+) Retail** es **stable equilibrium** — pero requires sustaining quality + experience.

---

## 5. Promociones ROI detallado

### 5.1 Promo types ROI table

| Type | Discount % | Volume increase típico | Net ROI |
|---|---|---|---|
| **Discount 10%** | -10% precio | +25-35% volume | **+12-18% revenue** |
| **Discount 15%** | -15% | +35-50% volume | **+15-25% revenue** |
| **Discount 20%** | -20% | +50-70% volume | **+20-35% revenue** |
| **Discount 25%** | -25% | +60-90% volume | **+15-30% revenue** (margin tight) |
| **2x1 (50% effective)** | -50% effective | +80-120% volume | **+10-25% revenue** |
| **3x2 (33% effective)** | -33% | +50-80% volume | **+15-30% revenue** |
| **Cross-sell -15% bundle** | -15% bundle | +40-60% specific items | **+18-25% revenue** |
| **Flash sale -25% (4h limited)** | -25% | +80-120% short window | **+25-40% revenue window** |

### 5.2 Promo strategy recommendations

#### 5.2.1 Stock-driven promos
- Use cuando inventory >80% + cerca expiry → recover capital faster.
- Categoría target: perecederos (pan day-old, lácteos, frutas).
- ROI: salvage 40-60% del cost waste.

#### 5.2.2 Foot-traffic promos
- Use weekly para attract recurrent customers.
- Frecuencia: 1 promo activa baseline, max 3 simultáneas.
- ROI: builds customer loyalty long-term.

#### 5.2.3 Loss leader (anchor pricing)
- 1-2 SKUs con discount 20-30% para attract.
- Customer entra → compra otros items full price.
- ROI: +15-25% basket size promedio.

#### 5.2.4 Cross-sell bundles
- "Pan + Mantequilla -15%" — combined products.
- ROI: increases avg ticket más que promos solo.

### 5.3 Promo metrics tracking

> **Manager Panel muestra por cada promo activa:**

- **Volume increase ratio** (vs baseline).
- **Revenue durante promo** vs baseline mismo período.
- **Margin neto promocional**.
- **Customer count increase**.
- **Halo effect** (otros productos vendidos junto al promo item).

### 5.4 Promo limits + anti-abuse

(Recap master §13.3:)
- Max 3 promos simultáneas por tienda.
- Promo fee 1% estimated volume pre-paid.
- Cooldown 48h entre promos mismo SKU.

---

## 6. Multi-supplier strategy

### 6.1 Filosofía multi-supplier

> **Single supplier = single point of failure.** Retail healthy mantiene 2-3 suppliers per category.

### 6.2 Supplier mix strategy por categoría

| Categoría | Min suppliers | Recommended mix |
|---|---|---|
| **Panadería** | 2 | 1 player Bakery primary + 1 NPC Bakery fallback |
| **Lácteos** | 2 | 1 player + 1 NPC (oleada 1, hasta vertical Lácteos lanzada) |
| **Carnicería** | 1-2 | NPC standalone (vertical futura) |
| **Frutas/verduras** | 1-2 | NPC standalone |
| **Bebidas** | 1-3 | NPC + opcional player distributor (oleada 2) |
| **Conservas** | 1 | NPC sufficient (low risk) |

### 6.3 Supplier balance metrics

> **Manager Panel muestra:**

- **% volume per supplier** — alert si single supplier > 70% category volume.
- **Quality avg per supplier** — comparison.
- **Pricing per supplier** — comparison.
- **Reliability score** (% deliveries on-time).

### 6.4 Supplier switching cost

- **Switching cost low** dentro mismo NPC bridge.
- **Switching cost mid** entre player suppliers (reputation transferable).
- **Switching cost high** si pierde subscription discount (penalty cancel mid-period).

### 6.5 Supplier diversification ROI

> **Caso comparison:**

**Retail con 1 supplier:**
- Volume: 100% from supplier X.
- Risk: si supplier falla → 100% category empty.
- Pricing: power negotiation low.

**Retail con 3 suppliers:**
- Volume: 50/30/20 split.
- Risk: si 1 falla → 50%-80% category covered.
- Pricing: power negotiation high (competitive bidding).
- Slight overhead admin (más contracts manage).

> **Net effect:** 3 suppliers = -3% pricing efficiency + 50% risk reduction + better resilience. **Worth it para categorías core**.

---

## 7. Retail layouts y impacto económico

### 7.1 Tipos de Retail

| Type | Size MLO | Capacity | Capital inicial | Revenue target/mes |
|---|---|---|---|---|
| **Corner shop / Tienda barrio** | Small (~80m²) | 6-8 lineales, 1 cajero | 35.000-50.000 € | 30.000-50.000 € |
| **Supermercado mid** | Medium (~250m²) | 14-18 lineales, 2-3 cajeros | 80.000-130.000 € | 80.000-150.000 € |
| **Supermercado large** | Large (~500m²) | 25-35 lineales, 4-6 cajeros | 180.000-280.000 € | 180.000-350.000 € |
| **Hipermercado** (oleada 2+) | XL (~1500m²) | 60+ lineales, 10+ cajeros | 600.000+ € | 800.000+ € |

### 7.2 Layout impact en metrics

#### 7.2.1 Corner shop economics
- **Pros:** low capital, fast ROI, hyper-local foot traffic.
- **Cons:** limited categories, no economy of scale.
- **Sweet spot:** zonas residenciales con foot traffic baja-mid.
- **ROI break-even:** ~3-5 meses player-operated.

#### 7.2.2 Supermercado mid economics
- **Pros:** balance categories + scale, target zonas urbanas.
- **Cons:** capital mid, requires staff coordination.
- **Sweet spot:** zonas comerciales mid.
- **ROI break-even:** ~6-9 meses.

#### 7.2.3 Supermercado large economics
- **Pros:** economy of scale, multi-category dominance.
- **Cons:** capital alto, payroll alto, requires manager dedicated.
- **Sweet spot:** zonas grandes + buen MLO location.
- **ROI break-even:** ~9-15 meses.

### 7.3 Layout planning interno (revenue per m²)

> **Mapping rentabilidad por sección:**

| Sección | Revenue per m² mensual típico |
|---|---|
| **Panadería** (premium category) | 350-500 €/m² |
| **Lácteos** | 280-400 €/m² |
| **Bebidas** | 250-380 €/m² |
| **Frutas/verduras** | 200-300 €/m² |
| **Carnicería** | 320-450 €/m² |
| **Conservas** | 150-220 €/m² |
| **Limpieza/Hogar** | 120-200 €/m² |
| **Snacks/Checkout impulse** | 600-900 €/m² ⭐ |

> **Insight:** **checkout impulse zone** es el ⭐ del Retail — small space, high turnover. Manager debe maximize.

### 7.4 Visual merchandising economics

> **Posición producto en lineal afecta sales:**

- **Eye-level shelf** (1.5-1.7m altura): × 1.30 sales vs floor-level.
- **Endcap** (cabeza góndola): × 1.50 sales vs aisle middle.
- **Checkout zone**: × 2.00 sales para impulse items.
- **Floor-level** (kids zone si applicable): × 0.85 sales.

**Manager Panel** permite drag-and-drop layout planning con preview impact.

---

## 8. Edge cases económicos Retail

### 8.1 Stockout cascade

- 1 SKU stockout → customers pierden trust → conversion drops × 0.85.
- **Cascade:** 3+ stockouts simultáneos → conversion drops × 0.65.
- **Recovery:** restock within 6h → conversion restores 90% in 48h.

### 8.2 Competitor opens nearby (zone war)

- New Retail abre dentro de 200m → foot traffic split.
- Mid-term: market settles, ambos pueden coexistir si differentiated.
- Short-term: revenue dip 20-35% por 2-4 semanas.
- **Mitigation:** premium positioning, lineage premium, customer loyalty.

### 8.3 Refrigeración failure

- Freezer breakdown → carne/lácteos/congelados waste accelerated.
- Insurance kick-in si activo (master §17).
- Without insurance: full loss del refrigerated stock (puede ser 5.000-15.000 €).

### 8.4 Robos / atracos (oleada 2+)

- Robos PED ocasionales (oleada 2+ mecánica security).
- Loss típico: 50-200 € cash + items.
- Mitigation: security PEDs (cost 200 €/quincena salary).
- Insurance robo coverage available.

### 8.5 Quality A flooded supplier offerings

- Si 5+ Bakeries player offering quality A baguette → market saturation.
- Retail can pricing leverage: × 0.95 negotiate.
- Suppliers compete → price war upstream.

### 8.6 Reputation collapse fast

- 3 quality D deliveries mid-week + 2 customer complaints public → reputation -10 puntos rápido.
- Recovery: 4-6 weeks consistent quality A + 0 complaints.
- During recovery: foot traffic × 0.7, conversion × 0.85.

---

## 9. KPIs específicos Retail

> **Adicionales a §18 master:**

### 9.1 Sales KPIs

- **Transactions/hora** by hour (heatmap).
- **Avg ticket trend** rolling 30d.
- **Conversion rate** real-time.
- **Foot traffic** (PEDs entered).
- **Top SKUs revenue + margin**.
- **Worst SKUs** (revisar si discontinue).

### 9.2 Stock KPIs

- **Stock fill rate** % por categoría.
- **Turnover days** por categoría.
- **Mermas % monthly**.
- **Stockout incidents** count.
- **Capital tied** total.

### 9.3 Supplier KPIs

- **Supplier reliability** % on-time.
- **Quality avg per supplier**.
- **Price comparison** suppliers same category.
- **Subscription cost** mensual.

### 9.4 Customer KPIs

- **Repeat customer rate** (player customers).
- **Avg basket size**.
- **Cross-sell ratio** (items per transaction).
- **Reputation trend rolling 30d**.

### 9.5 Promo KPIs

- **Active promos count + ROI**.
- **Promo halo effect** (other items boosted).

### 9.6 Layout KPIs

- **Revenue per m²** by section.
- **Endcap rotation** (cuántos days different products).
- **Checkout impulse %** de revenue total.

---

## 10. Roadmap del documento + estado

### 10.1 Roadmap

#### Oleada 1 (T-0 — incluido)
- ✅ Markups detallados por categoría.
- ✅ Dynamic pricing scenarios.
- ✅ Stock turnover economics.
- ✅ PED conversion + foot traffic.
- ✅ Promociones ROI.
- ✅ Multi-supplier strategy.
- ✅ Retail layouts (small/mid/large).
- ✅ Edge cases.
- ✅ KPIs específicos.

#### Oleada 2 (T+6 meses)
- 🔜 Hipermercado economics.
- 🔜 Self-checkout impact.
- 🔜 Online ordering / click-and-collect.
- 🔜 Verticals nuevas (lácteos player, carnicería player).
- 🔜 Reviews/ratings sistema.
- 🔜 Loyalty programs (tarjetas cliente).

#### Oleada 3+ (T+12 meses)
- 🔜 Multi-location retail chains.
- 🔜 Franchise model.
- 🔜 Cross-server marketplace integration.

### 10.2 Estado del documento

- **Versión:** 1.0 (firmado — completo, 10 secciones).
- **Próxima revisión:** evolución cuando se añadan hipermercado economics o verticals nuevas oleada 2.
- **Documento padre:** `economy/01_economic_model.md` v1.0 (firmado).
- **Documento hermano:** `economy/02_bakery_economy.md` v1.0 (firmado).
- **Documentos relacionados:**
  - `design/05_node_retail.md` v1.0 — mecánicas Retail.
  - Bible §7 — pilar Retail.

### 10.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Documento completo en 1 sesión. 10 secciones cubriendo markups detallados, dynamic pricing, stock turnover, foot traffic + conversion, promos ROI, multi-supplier, layouts, edge cases, KPIs. **Firmable.** |

---

## Resumen ejecutivo del documento (cierre)

El **Retail Economy** profundiza el master con foco específico:

- **Markups detallados por categoría** — Panadería 1.55, Lácteos 1.45, Carnicería 1.50, Frutas 1.40, Bebidas 1.35, Conservas 1.45, etc.
- **Dynamic pricing scenarios** — peak hours × 1.08-1.10, stock low × 1.08, saturated × 0.85, smooth transitions max 3% delta.
- **Stock turnover** detallado por categoría (Panadería 1-2 días, Conservas 60-90 días).
- **Capital efficiency** Retail mid: ~50% mensual return sobre capital tied — uno de los ROI más altos.
- **Foot traffic + conversion + avg ticket** formula end-to-end.
- **Promociones ROI** typical: discount 10-15% → +25-35% volume → +12-18% net revenue.
- **Multi-supplier strategy** — 3 suppliers > 1 supplier (-3% pricing + 50% risk reduction).
- **Layouts:** Corner shop ROI 3-5 meses, Mid 6-9 meses, Large 9-15 meses.
- **Visual merchandising** — checkout impulse zone × 2.00 sales, eye-level × 1.30.
- **Edge cases** documentados (stockout cascade, competitor wars, refrigeración failure).

> **Si en oleada 1 con un Retail mid player-operated, el founder mantiene 18-25% margen neto, stockout incidents <2/semana, mermas <8%, conversion rate >65%, foot traffic stable, reputation 65+ — habrá funcionado el modelo Retail.**

---

*"El Retail no rinde mucho por transacción — rinde mucho por volumen."*

**FIN DEL DOCUMENTO `economy/03_retail_economy.md` v1.0**
