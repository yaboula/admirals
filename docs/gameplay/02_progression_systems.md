# 📈 Admirals — Progression Systems

> **Versión:** 1.0 (firmado — completo, 11 secciones).
> **Documento padre:** `gameplay/01_gameplay_loops.md` v1.0 (gameplay master).
> **Documento hermano:** `gameplay/03_social_features.md` (próximo).
> **Documentos referenciados:** Bible §4 + §10, `economy/01_economic_model.md` v1.0, `design/0X_node_*.md` v1.0.
> **Estado:** firmado.

> **Lectura previa obligatoria:** `gameplay/01_gameplay_loops.md` (especialmente §5 difficulty curves, §6 mastery curves, §13 retention hooks).

---

## 0. Resumen ejecutivo

Este documento define **cómo progresa el player** en Admirals. Cubre toda forma de avance permanente — desde skill mastery hasta empresa milestones.

> **Filosofía de progresión Admirals:** **NO XP genérico, NO leveling abstracto.** La progresión es **métrica real medible** — Quality A rate, transactions count, revenue total, reputation score. El player progresa porque sus números reales mejoran.

Define:

- **Filosofía progresión** Admirals (anti-XP, pro-metric).
- **Skill mastery por rol** — qué se desbloquea con experience real:
  - Granjero (Junior → Operador → Especialista → Maestro).
  - Molinero.
  - Panadero (Aprendiz → Oficial → Maestro → Maestro Artesano).
  - Cajero / Reponedor / Manager Retail.
  - Driver / Logista.
- **Achievements catalog** completo (oleada 1).
- **Milestones empresa** — niveles de empresa por revenue/employees/lineage.
- **Reputation tiers detalled** — perks específicos por tier.
- **Equipment unlocks** — qué herramienta mejor desbloquea con qué métrica.
- **Title/badge system** (oleada 2+).
- **Long-term goals** que duran meses.
- **Metrics canónicas** que rigen progresión.
- **Anti-patterns progresión**.

> **Por qué este doc importa:** sin progresión, el gameplay es plano — el player hace lo mismo siempre. Con progresión real (no fake XP), el player **sabe que está creciendo** porque sus números crecen.

---

## 1. Filosofía progresión

### 1.1 Los 5 principios

#### Principio 1 — Métrica real, no XP genérico
> **Nunca XP abstracto** ("level up by doing stuff"). Siempre métrica concreta.

- ❌ "+50 XP for baking" → ¿XP de qué?
- ✅ "Quality A rate: 87%" → claro, medible, accionable.

#### Principio 2 — Múltiples ejes de progresión simultáneos
> **El player no progresa en UN eje.** Progresa simultáneamente en:

- **Personal skill** (player como individuo).
- **Empresa metrics** (negocio).
- **Reputation** (track record).
- **Wealth** (IBAN balance).
- **Social standing** (empresa rank, leaderboards).

Cada eje da satisfacción diferente.

#### Principio 3 — Progreso visible siempre
> **El player ve sus números cambiar.** Tablet expone todos los progress trackers.

- Profile page muestra todos los KPIs personales.
- Empresa Manager Panel muestra todos los KPIs empresa.
- Comparative views (vs server avg, vs personal week ago).

#### Principio 4 — Sin pay-to-win
> **No microtransactions** que aceleren progresión. Progresión es **honest grind + skill**.

- Cosmetic skins OK (oleada 2+).
- Premium subscription para perks (oleada 2+) — pero NO progresión accelerator.

#### Principio 5 — Cap superior generoso, no infinito
> **Mastery levels tope alcanzable** en realistic timeframe (100-300h play).

- No infinite leveling treadmill.
- Player Master tier alcanza techo → sigue motivado por innovación + mentoring + nuevas verticales.

### 1.2 Anti-patterns (lo que Admirals evita)

- ❌ **XP grinding** — "do task 100 times for level up".
- ❌ **Hidden progression** — "what does this number mean?".
- ❌ **Pay-to-skip** — "skip 20h grind for 10€".
- ❌ **Reset progression** — "every season everyone starts at 0".
- ❌ **Linear-only** — un solo path que todos siguen.
- ❌ **Gating arbitrario** — "you can't do X until level 30".

---

## 2. Skill mastery por rol

> **Cada rol tiene 4 tiers** definidos por **métricas reales acumuladas**, no XP.

### 2.1 Granjero — niveles

#### 2.1.1 Granjero Junior (Tier 1)
**Criterios para alcanzar:**
- Tasks plant + harvest completados: 0+.
- (Default starting tier).

**Capabilities:**
- Operar tractor básico.
- Plant + harvest crops básicos (trigo, otros).
- Apply water + fertilizer.

**Salary baseline:** 1.700 €/quincena.

**Limitations:**
- No puede operar cosechadora industrial.
- Quality output cap: B-grade.
- Single-parcela operations only.

#### 2.1.2 Granjero Operador (Tier 2)
**Criterios:**
- Tasks plant+harvest: 50+.
- Cosechas exitosas (>70% quality B+): 25+.
- Hours operativos en granja: 20+.

**Capabilities unlock:**
- ✅ Operar cosechadora industrial.
- ✅ Multi-parcela coordination.
- ✅ Quality output cap: A-grade possible (80%+ rate).
- ✅ Inspect crop quality avanzado.

**Salary jump:** 2.300 €/quincena (+35%).

**Tablet badge:** "Granjero Operador" badge visible profile.

#### 2.1.3 Granjero Especialista (Tier 3)
**Criterios:**
- Tasks plant+harvest: 200+.
- Quality A rate cosechas: >80% rolling 30d.
- Hours operativos: 80+.
- Reputation >50.

**Capabilities unlock:**
- ✅ Lineage-tracked outputs (initiates lineage chain).
- ✅ Premium pricing Quality A+.
- ✅ Mentor Junior granjeros (oleada 2+).
- ✅ Manage NPC employees (auto-mode con eficiencia × 0.85).

**Salary jump:** 3.500 €/quincena (+52%).

**Tablet badge:** "Especialista Agrícola".

#### 2.1.4 Granjero Maestro (Tier 4)
**Criterios:**
- Tasks plant+harvest: 1.000+.
- Quality A rate: >95% rolling 90d.
- Hours operativos: 300+.
- Reputation >85.
- Founder de empresa Granja con MRR > 30.000 €/mes.

**Capabilities unlock:**
- ✅ Premium pricing × 1.20 sobre canónico.
- ✅ Pioneer experimental crops (oleada 2+).
- ✅ Mentor program oficial.
- ✅ Empresa Granja certified premium tier.

**Salary jump:** 5.500 €/quincena (+57%) — pero típicamente Maestros son founders.

**Tablet badge:** "Maestro Granjero" gold.

### 2.2 Molinero — niveles

#### 2.2.1 Molinero Aprendiz (Tier 1)
**Criterios:**
- Default starting.

**Capabilities:**
- Operar molino básico.
- Quality output cap: B-grade.

**Salary:** 1.900 €/quincena.

#### 2.2.2 Molinero Operador (Tier 2)
**Criterios:**
- Sacos procesados: 100+.
- Conversion ratio promedio: >65%.
- Hours operativos: 25+.

**Capabilities unlock:**
- ✅ Quality A possible (75%+ rate).
- ✅ Adjust mill settings finos.
- ✅ Multi-batch parallel.

**Salary:** 2.500 €/quincena.

#### 2.2.3 Molinero Maestro Operador (Tier 3)
**Criterios:**
- Sacos procesados: 500+.
- Quality A rate: >85% rolling 30d.
- Conversion ratio: >70%.
- Hours: 100+.

**Capabilities unlock:**
- ✅ Specialty grinds (centeno, multicereales).
- ✅ Lineage-tracked outputs.
- ✅ Premium pricing.

**Salary:** 3.800 €/quincena.

#### 2.2.4 Molinero Maestro (Tier 4)
**Criterios:**
- Sacos: 3.000+.
- Quality A rate: >92% rolling 90d.
- Hours: 300+.
- Empresa Molino MRR > 50.000 €/mes (típicamente founder).

**Capabilities unlock:**
- ✅ Innovation new grinds (oleada 2+).
- ✅ Premium tier certification.

**Salary:** 5.800 €/quincena.

### 2.3 Panadero — niveles

#### 2.3.1 Panadero Aprendiz (Tier 1)
**Default starting.**

**Capabilities:**
- Recetas básicas (baguette, loaf blanco).
- Quality cap: B-grade.

**Salary:** 1.800 €/quincena.

#### 2.3.2 Panadero Oficial (Tier 2)
**Criterios:**
- Items horneados: 500+.
- Quality A rate: >70%.
- Hours: 30+.

**Capabilities unlock:**
- ✅ Recetas intermedias (pan integral, croissant).
- ✅ Quality A possible (75%+ rate).
- ✅ Manage fermentation timing avanzado.

**Salary:** 2.300 €/quincena.

#### 2.3.3 Panadero Maestro (Tier 3)
**Criterios:**
- Items horneados: 3.000+.
- Quality A rate: >85% rolling 30d.
- Hours: 100+.
- Reputation >55.

**Capabilities unlock:**
- ✅ Recetas premium (rústico, especialidades).
- ✅ Pastry básica (croissant especial, danish).
- ✅ Lineage-tracked outputs.
- ✅ Premium pricing.
- ✅ Mentor Aprendices.

**Salary:** 3.800 €/quincena.

#### 2.3.4 Panadero Maestro Artesano (Tier 4)
**Criterios:**
- Items horneados: 10.000+.
- Quality A rate: >93% rolling 90d.
- Hours: 300+.
- Reputation >85.
- Empresa Bakery MRR > 60.000 €/mes (típicamente founder).

**Capabilities unlock:**
- ✅ Pastry premium (eclairs, tartas custom oleada 2+).
- ✅ Recetas firma propia (signature breads).
- ✅ Pricing override × 1.20-1.30.
- ✅ Empresa Bakery certified Master Artisan tier.

**Salary:** 6.000 €/quincena.

**Badge:** "Maestro Artesano" gold con motif pan.

### 2.4 Cajero / Reponedor Retail — niveles

#### 2.4.1 Cajero Junior (Tier 1)
**Default.**

**Capabilities:**
- Operar POS básico.
- Atender PEDs.

**Salary:** 1.600 €/quincena.

#### 2.4.2 Cajero Profesional (Tier 2)
**Criterios:**
- Transactions atendidas: 1.000+.
- Conversion rate: >70%.
- Hours: 30+.

**Capabilities unlock:**
- ✅ Cross-sell técnicas (suggest items checkout).
- ✅ Manage promos en POS.
- ✅ Restock supervisión.

**Salary:** 2.000 €/quincena.

#### 2.4.3 Encargado Retail (Tier 3)
**Criterios:**
- Transactions: 5.000+.
- Hours: 80+.
- Conversion: >75%.

**Capabilities unlock:**
- ✅ Manage cajeros junior.
- ✅ Pricing adjustments dentro caps.
- ✅ Layout reorganize.

**Salary:** 3.000 €/quincena.

#### 2.4.4 Manager Retail Experto (Tier 4)
**Criterios:**
- Transactions: 20.000+.
- Hours: 200+.
- Conversion: >80%.
- Reputation >75.

**Capabilities unlock:**
- ✅ Multi-cajero coordination.
- ✅ Strategic pricing decisions.
- ✅ Promo planning long-term.
- ✅ Supplier relationship management.

**Salary:** 4.500 €/quincena.

### 2.5 Driver / Logista — niveles

#### 2.5.1 Driver Junior
**Default.**

**Capabilities:**
- Vespertino van básica.
- Local deliveries (<5km).

**Salary:** 1.700 €/quincena.

#### 2.5.2 Driver Profesional
**Criterios:**
- Deliveries completed: 100+.
- On-time rate: >85%.

**Capabilities unlock:**
- ✅ Camión light + heavy.
- ✅ Mid + long deliveries (5-50km).
- ✅ Refrigerated cargo.

**Salary:** 2.500 €/quincena.

#### 2.5.3 Driver Maestro
**Criterios:**
- Deliveries: 500+.
- On-time: >92%.
- Hours: 80+.

**Capabilities unlock:**
- ✅ Inter-zone logistics (50+km).
- ✅ Multi-stop optimized routes.
- ✅ Founder logistics company.

**Salary:** 3.500 €/quincena.

### 2.6 Manager / Director (rol cross-node)

#### 2.6.1 Manager Junior
**Criterios:**
- Empleados managed: 1+.
- Empresa employed: 1+.

**Capabilities:**
- View Manager Panel basics.
- Manage 1 empresa as employee.

**Salary:** 2.500 €/quincena (+ profit share if founder).

#### 2.6.2 Manager Senior
**Criterios:**
- Empleados managed: 5+.
- Empresa MRR: 30.000+ €/mes operated.
- Hours managing: 60+.

**Capabilities unlock:**
- ✅ Full Manager Panel access.
- ✅ Cross-empresa analytics (oleada 2+ if multi-empresa).
- ✅ Strategic decisions empresa.

**Salary:** 4.000 €/quincena.

#### 2.6.3 Director
**Criterios:**
- Empresa MRR: 100.000+ €/mes operated.
- Hours: 200+.
- Reputation >80.

**Capabilities unlock:**
- ✅ Multi-empresa CEO mode.
- ✅ Strategic vertical integration.
- ✅ Top tier admin Tablet apps.

**Salary:** 7.000 €/quincena typical (mostly founders, profit-share dominates).

---

## 3. Achievements catalog

> **Achievements son hitos celebrados con reward + badge.** Oleada 1 incluye los achievements core. Oleada 2+ expansion.

### 3.1 Achievements primer día

| Achievement | Criterio | Reward |
|---|---|---|
| **First Steps** | Spawn primero servidor | +50 € |
| **First Loaf** | Hornear primer producto cualquiera | +50 € + badge |
| **First Sale** | Realizar primera venta | +25 € + badge |
| **Honest Day's Work** | Completar primer shift | +75 € + badge |
| **Tablet Master** | Abrir las 12 apps Tablet | +50 € + badge |
| **First Friend** | Add 1 player to friends list | +25 € + badge |

### 3.2 Achievements primera semana

| Achievement | Criterio | Reward |
|---|---|---|
| **Hundred Club** | Earn 100 € total | +50 € + badge |
| **Working Class** | Complete 10 shifts | +200 € + badge |
| **Quality Conscious** | Achieve quality A 5 times in row | +150 € + badge |
| **Networking** | Have 5 friends in list | +75 € + badge |
| **Reputation Rising** | Reach reputation 30 | +100 € + badge |
| **First Promotion** | Reach Tier 2 in any role | +250 € + badge |

### 3.3 Achievements primer mes

| Achievement | Criterio | Reward |
|---|---|---|
| **Five Thousand** | Earn 5.000 € total | +500 € + badge |
| **Decent Job** | Reach Tier 2 in 2 different roles | +400 € + badge |
| **Trusted** | Reach reputation 50 | +300 € + badge |
| **Empresa Curious** | Save 10.000 € (founding capital target) | +500 € + badge |
| **Streak Master** | Login 14 days consecutive | +300 € + badge |
| **Quality Streak** | Quality A 20 times in row | +500 € + badge gold |

### 3.4 Achievements long-term

| Achievement | Criterio | Reward |
|---|---|---|
| **Founder** | Found your first empresa | +1.000 € + badge gold |
| **First Contract** | Sign first B2B contract as supplier | +500 € + badge |
| **First Subscription** | Sign first subscription B2B | +750 € + badge |
| **Premium Tier** | Reach reputation 80 | +2.000 € + badge premium |
| **Master Craftsman** | Reach Tier 4 in any role | +5.000 € + badge legendary |
| **Lineage Pioneer** | Initiate first complete lineage chain (4 nodes player-trazado) | +3.000 € + badge legendary |
| **Six Figures** | Personal IBAN > 100.000 € | +5.000 € + badge legendary |
| **Empresa Powerhouse** | Empresa MRR > 100.000 €/mes | +10.000 € + badge legendary |
| **Veteran** | Play 100h total | +2.500 € + badge |
| **Master** | Play 500h total | +10.000 € + badge legendary |

### 3.5 Achievements colaborativos

| Achievement | Criterio | Reward |
|---|---|---|
| **Team Player** | Become member of empresa player | +200 € + badge |
| **Co-Founder** | Co-found empresa with another player | +500 € + badge |
| **Mentor** (oleada 2+) | Help 3 newbies reach Tier 2 | +1.000 € + badge |
| **Lineage Builder** | Be part of complete lineage chain × 5 weeks | +2.000 € + badge |
| **Disputes Resolver** | Win/resolve 5 contract disputes fairly | +500 € + badge |

### 3.6 Achievements rare/edge

| Achievement | Criterio | Reward |
|---|---|---|
| **Perfect Day** | All transactions quality A in 1 day | +500 € + badge |
| **Rebuilder** | Recover from bankruptcy + rebuild empresa to MRR 50k+ | +5.000 € + badge legendary |
| **Server Pioneer** | One of first 10 players on server | +1.000 € + badge unique |
| **Bread Day Hero** (oleada 2+) | Top revenue during festival | +3.000 € + badge seasonal |
| **Crisis Survivor** | Maintain empresa through inflation crisis | +2.000 € + badge |

### 3.7 Achievement display

> **Tablet Profile app muestra:**

- All earned achievements (with date earned).
- Progress on in-progress achievements (e.g., "Quality A streak: 12/20").
- Locked achievements (visible names, hidden criteria).
- Total achievement count + percentile vs server average.

---

## 4. Milestones empresa

> **Empresa misma progresa en niveles.** Define qué unlocks por size/maturity.

### 4.1 Empresa tier 1 — Startup

**Criterios:**
- Founded < 30 days ago.
- MRR < 10.000 €/mes.
- Employees < 3.

**Capabilities:**
- Basic Manager Panel.
- 1 MLO operativo.
- Standard contracts.

### 4.2 Empresa tier 2 — Established

**Criterios:**
- Operating > 30 days.
- MRR 10.000-30.000 €/mes.
- Employees 3-7.
- Reputation > 40.

**Capabilities unlock:**
- ✅ Multi-MLO support (up to 2).
- ✅ Subscription B2B contracts.
- ✅ Premium Manager Panel insights.
- ✅ Advanced KPIs dashboard.

### 4.3 Empresa tier 3 — Mature

**Criterios:**
- Operating > 90 days.
- MRR 30.000-100.000 €/mes.
- Employees 8-20.
- Reputation > 65.

**Capabilities unlock:**
- ✅ Multi-MLO unlimited.
- ✅ Cross-empresa partnerships.
- ✅ Strategic supplier deals (long-term contracts).
- ✅ Brand recognition (oleada 2+ marketing).

### 4.4 Empresa tier 4 — Premium

**Criterios:**
- Operating > 180 days.
- MRR > 100.000 €/mes.
- Employees > 20.
- Reputation > 80.

**Capabilities unlock:**
- ✅ Premium tier badge públicamente displayed.
- ✅ Pricing × 1.10-1.20 sobre canónico.
- ✅ Server-wide leaderboard visibility.
- ✅ Mentor program empresa-level.
- ✅ Vertical integration recommendations.

### 4.5 Empresa tier 5 — Legend (oleada 2+)

**Criterios:**
- MRR > 300.000 €/mes.
- Multi-empresa group.
- Reputation > 90.
- Operating > 365 days.

**Capabilities unlock:**
- ✅ Custom branding completo.
- ✅ Influence in server economic events.
- ✅ Mentor program leadership.

---

## 5. Reputation tiers detallados

> **Recap master economy §11.2 + perks específicos:**

### 5.1 Untrusted (0-30)

**Default at start (newbies hover here briefly).**

**Penalties:**
- Markup penalty: × 0.90.
- Escrow fee: × 2 (1% en lugar de 0.5%).
- B2B contracts harder to find (clientes distrust).
- PED conversion: × 0.7.

### 5.2 Neutral (31-60)

**Most newbies graduate here within 1-2 weeks.**

- No bonus, no penalty.
- Standard pricing access.
- Standard escrow fees.
- Standard PED conversion.

### 5.3 Trusted (61-80)

**Achievable in 1-2 months consistent.**

**Perks:**
- Pricing premium × 1.05 disponible.
- B2B subscription discounts -3% to -5% available.
- Featured listing en Mercado Admirals (oleada 2+).
- PED conversion × 1.10.

### 5.4 Premium (81-100)

**Achievable 3-6 months consistent excellence.**

**Perks:**
- Pricing premium × 1.10.
- Escrow fee reduced to 0.3%.
- B2B subscription discounts -8% to -10% available.
- Top featured Mercado.
- PED conversion × 1.25.
- Lineage premium qualified.
- Badge premium tier visible profile.

### 5.5 Legend (oleada 2+)

**Reputation 95+ + 1 year+ track record.**

- Server-wide recognition.
- Custom event invitations.
- Mentor program leadership.

---

## 6. Equipment unlocks

> **Better equipment = better outputs.** Pero unlocks gated by metrics.

### 6.1 Granja equipment

| Tier | Equipment | Unlock criteria | Cost | Output improvement |
|---|---|---|---|---|
| 1 | Tractor básico | Default | 8.000 € | Baseline |
| 2 | Tractor avanzado | Hours: 30+ | 18.000 € | Speed × 1.4 |
| 3 | Cosechadora industrial | Hours: 80+ + Tier 2 granjero | 45.000 € | Capacity × 2.5 |
| 4 | Tractor + cosechadora premium | Hours: 200+ + Tier 3 | 80.000 € | Quality A rate × 1.15 |

### 6.2 Molino equipment

| Tier | Equipment | Unlock | Cost | Improvement |
|---|---|---|---|---|
| 1 | Molino básico | Default | 12.000 € | Baseline |
| 2 | Stone mill grinder | Hours: 25+ | 28.000 € | Quality cap A possible |
| 3 | Industrial multi-grinder | Hours: 80+ + Tier 2 molinero | 65.000 € | Throughput × 2 |
| 4 | Premium artisan mill | Hours: 200+ + Tier 3 | 110.000 € | Quality + lineage premium support |

### 6.3 Bakery equipment

| Tier | Equipment | Unlock | Cost | Improvement |
|---|---|---|---|---|
| 1 | Mixer básico + horno standard | Default | 25.000 € | Baseline batch 30 |
| 2 | Industrial mixer + horno medium | Hours: 30+ | 50.000 € | Batch 60, faster |
| 3 | Stone deck oven + premium mixer | Hours: 100+ + Tier 3 panadero | 95.000 € | Batch 120, quality A rate × 1.10 |
| 4 | Master artisan setup completo | Hours: 300+ + Tier 4 | 180.000 € | Batch 200+, signature recipes possible |

### 6.4 Retail equipment

| Tier | Equipment | Unlock | Cost | Improvement |
|---|---|---|---|---|
| 1 | POS básico + lineales standard | Default | 15.000 € | 8 lineales |
| 2 | POS avanzado + cold storage | Empresa Tier 2 | 35.000 € | 14 lineales, refrigerated |
| 3 | Multi-POS + advanced refrigeration | Empresa Tier 3 | 75.000 € | 25 lineales, premium freezer |
| 4 | Hipermercado setup (oleada 2+) | Empresa Tier 4 | 200.000 € | 60+ lineales, full categories |

### 6.5 Logística equipment

| Tier | Vehicle | Unlock | Cost | Improvement |
|---|---|---|---|---|
| 1 | Vespertino van | Default | 8.000 € | 20 sacos cap |
| 2 | Camión light | Driver Tier 2 | 22.000 € | 50 sacos cap |
| 3 | Camión heavy | Driver Tier 3 | 55.000 € | 200 sacos cap |
| 4 | Refrigerated fleet | Driver Tier 3 + empresa Tier 3 | 120.000 € | Cold chain capable |

### 6.6 Equipment depreciation (recap master §17.1)

- 1% value loss/month base.
- × wear multiplier (1.0-2.5 según uso).
- Replacement at 0% value.

---

## 7. Title/badge system (oleada 2+)

### 7.1 Display badges

> **Player profile + Tablet Comm app shows:**

- Active title (one selected).
- Available titles (all earned).
- Empresa badge (if any).
- Reputation tier badge.

### 7.2 Title categories

#### 7.2.1 Achievement-based titles
- "Founder" (founded empresa).
- "Master Panadero" (Tier 4 panadero).
- "Lineage Pioneer" (first complete chain).
- "Crisis Survivor".

#### 7.2.2 Time-based titles
- "Veteran" (100h+ played).
- "Master" (500h+ played).
- "Server Pioneer" (first 10 players).

#### 7.2.3 Empresa-based titles
- "CEO" (founder).
- "Manager" (employed manager).
- "Specialist" (employed specialist).

#### 7.2.4 Seasonal titles (oleada 2+)
- "Bread Day Hero".
- "Holiday Champion".

### 7.3 Title customization

- Player chooses 1 active title to display.
- Multiple titles owned, can swap anytime.
- Some titles unlock cosmetic perks (custom Tablet theme, etc.).

---

## 8. Long-term goals

> **Goals que duran meses para mantener engagement long-term.**

### 8.1 Goal categories

#### 8.1.1 Wealth goals
- Save 100.000 € (months 2-3).
- Save 500.000 € (months 6-9).
- Save 1M € (months 12+).

#### 8.1.2 Career goals
- Reach Tier 4 in primary role (months 6-12).
- Reach Tier 2 in 3 different roles (months 3-6).
- Reach Tier 4 in 2 roles (months 9-15).

#### 8.1.3 Empresa goals
- Found first empresa (months 1-3).
- Empresa tier 3 (months 6-9).
- Empresa tier 4 / Premium (months 12-18).
- Multi-empresa group (months 12+).

#### 8.1.4 Reputation goals
- Reach Trusted tier (61) (weeks 4-8).
- Reach Premium tier (81) (months 3-6).
- Reach Legend tier (95+) (year 1+).

#### 8.1.5 Social goals
- 10+ friends.
- Mentor 5 newbies (oleada 2+).
- Lineage chain core member 6+ months.

### 8.2 Goal tracking Tablet

- Tablet Profile app dashboards each goal category.
- Progress bars + ETA estimates based on current rate.
- Tips para acelerar each goal.

---

## 9. Metrics canónicas regidoras

> **Las métricas que rigen toda progresión Admirals.** Single source of truth.

### 9.1 Per-player metrics

| Metric | Formula |
|---|---|
| **Total earnings lifetime** | Sum all income events |
| **Hours played total** | Sum session minutes / 60 |
| **Hours per role** | Sum minutes in that role |
| **Tasks completed** | Count complete events per task type |
| **Quality A rate** | Quality A outputs / total outputs (rolling 30d) |
| **Conversion rate** (cajeros) | Sales / PEDs entered (rolling 30d) |
| **On-time delivery rate** (drivers) | On-time / total deliveries (rolling 30d) |
| **Reputation score** | 0-100 calc from quality + contracts + disputes (rolling) |
| **Active streak days** | Consecutive days with login |
| **Achievements earned** | Count |

### 9.2 Per-empresa metrics

| Metric | Formula |
|---|---|
| **MRR** | Monthly recurring revenue |
| **Revenue YTD** | Year-to-date revenue |
| **Profit margin** | (Revenue - costs) / revenue |
| **Cash runway** | Saldo / avg daily costs |
| **Employees count** | Count |
| **Subscription count** | Count active subscriptions |
| **Empresa reputation** | 0-100 |
| **Lineage chains active** | Count |
| **Operating days** | Days since founded |

### 9.3 Server-wide metrics

| Metric | Use |
|---|---|
| **Player ranks** | Leaderboards |
| **Empresa ranks** | Leaderboards |
| **Top earners** | Featured in marketplace |
| **Newest founders** | Highlighted recent |

---

## 10. Anti-patterns + edge cases

### 10.1 Anti-patterns

- ❌ **Skill atrophy** — métricas históricas no decay solo. Permanecen earned.
- ❌ **Forced specialization** — players pueden master multiple roles.
- ❌ **Pay-to-skip** — no money shortcuts.
- ❌ **Reset seasonal** — progression permanent.
- ❌ **Hidden criteria** — all unlock criteria visible Tablet.

### 10.2 Edge cases

#### 10.2.1 Skill cap reached
- Player Tier 4 in role → continues earning, but no further title progression in that role.
- Solution: encourage cross-role mastery + mentoring.

#### 10.2.2 Reputation crash
- Reputation drop below tier threshold → tier downgraded.
- Reputation recovery: 4-6 weeks consistent quality to re-tier.

#### 10.2.3 Empresa bankruptcy progression impact
- Empresa metrics reset for that empresa.
- Player personal metrics PRESERVED.
- Achievements PRESERVED (badge already earned).
- Reputation impact: -10 puntos one-time.

#### 10.2.4 Achievement reward inflation
- High-value achievement rewards (legendary 5-10k €) are sinks at server level — earned once per player only.
- Total cost server low (50 € avg per player onboarding achievements).

---

## 11. Roadmap + estado

### 11.1 Roadmap

#### Oleada 1 (T-0 — incluido)
- ✅ 5 principios filosofía progresión.
- ✅ Skill mastery 4 tiers × 6 roles.
- ✅ Achievements catalog completo (oleada 1).
- ✅ Milestones empresa (5 tiers).
- ✅ Reputation tiers detallados.
- ✅ Equipment unlocks por tier.
- ✅ Long-term goals.
- ✅ Métricas canónicas.

#### Oleada 2 (T+6 meses)
- 🔜 Title/badge system completo display.
- 🔜 Mentor program oficial.
- 🔜 Seasonal achievements + titles.
- 🔜 Tier 5 Legend empresa.
- 🔜 Cosmetic perks unlocks.
- 🔜 Custom Tablet themes per tier.

#### Oleada 3+ (T+12 meses)
- 🔜 Cross-server progression sync.
- 🔜 Hall of fame players históricos.
- 🔜 Custom title creation by players.
- 🔜 Procedural achievements AI-generated.

### 11.2 Estado del documento

- **Versión:** 1.0 (firmable — completo, 11 secciones).
- **Próxima revisión:** evolución oleada 2 con achievements expansion.
- **Documento padre:** `gameplay/01_gameplay_loops.md` v1.0 (firmado).
- **Documento hermano:** `gameplay/03_social_features.md` (próximo).
- **Documentos relacionados:**
  - Bible §10 — mecánica core.
  - `economy/01_economic_model.md` §5 (salaries) + §11 (reputation).
  - Todos `design/0X_node_*.md` — mecánicas tier-gated.

### 11.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Documento completo. 11 secciones cubriendo filosofía progresión, skill mastery 6 roles × 4 tiers, achievements catalog, milestones empresa, reputation tiers, equipment unlocks, titles, long-term goals, metrics, anti-patterns. **Firmable.** |

---

## Resumen ejecutivo del documento (cierre)

El **Progression Systems** define cómo el player avanza permanentemente en Admirals:

- **Filosofía clave:** **NO XP genérico**, métricas reales (Quality A rate, transactions count, hours operativos).
- **5 principios:** métrica real, ejes múltiples, visible siempre, no pay-to-win, cap superior generoso.
- **Skill mastery 4 tiers × 6 roles** — Granjero, Molinero, Panadero, Cajero/Retail, Driver, Manager. Cada tier unlock criteria concreto.
- **Achievements catalog** primer día → long-term → colaborativos → rare.
- **Milestones empresa** 5 tiers (Startup → Established → Mature → Premium → Legend).
- **Reputation tiers** con perks específicos (× pricing, escrow fees, PED conversion).
- **Equipment unlocks** gated by hours + tiers.
- **Title/badge system** (oleada 2+) display profile.
- **Long-term goals** wealth + career + empresa + reputation + social.
- **Anti-patterns** documentados (skill atrophy, forced specialization, pay-to-skip).

> **Si en oleada 1 con 50 players activos durante 90 días: >60% reach Tier 2 in 1 role, >30% reach Tier 3, >10% reach Tier 4 primary, >50% have 5+ achievements, >40% in empresa membership, lineage chains active 2-5 — habrá funcionado el modelo progresión Admirals.**

---

*"El player progresa porque sus números mejoran — no porque la barra de XP suba."*

**FIN DEL DOCUMENTO `gameplay/02_progression_systems.md` v1.0**
