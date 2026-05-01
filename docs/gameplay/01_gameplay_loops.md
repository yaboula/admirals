# 🎮 Admirals — Gameplay Loops (Master)

> **Versión:** 1.0 (firmado — completo, 15 secciones, 2 partes publicadas).
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.2 (§4 Pilares + §10 Mecánica core).
> **Documentos hermanos:** `gameplay/02_progression_systems.md` (próximo), `gameplay/03_social_features.md` (próximo).
> **Documentos referenciados:** todos los `design/01-05` (mecánicas por nodo), `art/03_sound_bible.md` v1.0 (feedback auditivo), `art/04_storybook_guide.md` v1.0 (motion + a11y).
> **Estado:** firmado.

> **Lectura previa obligatoria:** Bible §4 (Pilares), Bible §10 (Mecánica core), todos los `design/0X_node_*.md` (mecánicas específicas).

---

## 0. Resumen ejecutivo

Este documento es **el master gameplay** de Admirals. Define **qué siente y hace el player** en cada timeframe — segundo, minuto, sesión, semana, mes.

> **Filosofía clave:** Admirals NO es un script de roleplay narrativo. Es **trabajo real que rinde resultados visibles**. El player no "interpreta un panadero" — el player **ES un panadero** porque amasa, hornea, vende, y ve los números subir.

Define:

- **Filosofía gameplay** — los 6 principios del feel Admirals.
- **Loops temporales** detallados:
  - Loop 30 segundos (micro action).
  - Loop 5 minutos (task completion).
  - Loop 30 minutos (mini-objective).
  - Loop 2 horas (session arc).
  - Loop sesión completa (3-5h ideal).
  - Loop semanal (commitments + subscriptions).
  - Loop mensual (empresa milestones).
- **Onboarding flow** crítico (primeros 5min / 1h / día 1 / semana 1).
- **Decision space mapping** — qué decisiones toma el player y con qué frecuencia.
- **Difficulty curves** por nodo.
- **Mastery curves** novice → expert.
- **Feedback loops** micro/meso/macro.
- **Failure states** + recovery paths.
- **Multiplayer dynamics** — cómo otros players afectan el tuyo.
- **Pacing** — tension/release patterns.
- **Anti-boredom** mechanisms.
- **Retention hooks** — daily / weekly / monthly.
- **KPIs gameplay** — métricas para medir si el gameplay funciona.
- **Edge cases** + anti-patterns.

> **Por qué este doc es crítico:** un producto puede tener perfecta arquitectura técnica, perfecta economía, perfecto arte — y aún así **fallar si el gameplay no engancha**. Este documento define el **feel** que separa Admirals de un script genérico.

---

## 1. Filosofía gameplay

### 1.1 Los 6 principios del feel Admirals

#### Principio 1 — Trabajo real, no skill check
> **Las acciones son trabajo físico simulado.** No QTEs, no minijuegos abstractos.

- Amasar → drag mouse en círculos durante 8s → masa state visible cambia.
- Cargar saco → walk to spot, F to pick, walk to truck, F to drop.
- Vender pan → click producto, click cliente, intercambio físico animado.

**Por qué:** los QTEs y minijuegos abstractos rompen inmersión. El player que mueve sacos físicamente **sabe que ha trabajado**.

#### Principio 2 — Resultados visibles inmediatos
> **Cada acción tiene feedback inmediato visual + auditivo + numérico.**

- Hornear → forno glow + crackling sound + timer + finalmente bread emerge.
- Vender → POS chime + numbers sube en Tablet.
- Quality check → color-coded indicator (A=verde, D=rojo).

**Por qué:** sin feedback, el player no sabe si está haciendo bien. Admirals **bombardea de feedback** sin saturar.

#### Principio 3 — Decisiones consecuentes
> **Las decisiones tienen consecuencias reales y duraderas.**

- Comprar trigo barato C-grade → harina C → pan C → reputación baja → menos clientes.
- No mantener freezer → carne se echa a perder → 5.000 € pérdida.
- Aceptar contrato grande → commitment 30 días → no puedes faltar.

**Por qué:** decisiones triviales matan engagement. Cada decisión Admirals **afecta el balance neto del player**.

#### Principio 4 — Progreso medible siempre
> **El player siempre tiene un número subiendo.**

- IBAN balance.
- Reputation score.
- Empresa profit YTD.
- Subscription MRR.
- Quality A rate.
- Days streak active.

**Por qué:** progreso visible = motivación intrínseca. La Tablet **expone todos los números** en dashboards.

#### Principio 5 — Sesión auto-contenida con arc
> **Cada sesión tiene un arco narrativo:** opening (pre-bake) → tension (peak hours) → resolution (close + count till).

- 5min onboarding session: morning prep → 1 contract delivery → close.
- 3h session: shift completo desde apertura hasta cierre.
- Player siente "he completado algo" cada sesión, no "estoy farmeando indefinidamente".

**Por qué:** sin arc, el player se pregunta "cuándo paro?" Admirals **propone closures naturales**.

#### Principio 6 — Multiplayer es economía, no PvP
> **Otros players son competidores económicos + socios comerciales, no enemigos.**

- Bakery competidora abre cerca → tu reputación y pricing matter más.
- Player Granja firma contract con tu Molino → win-win.
- Disputas resueltas vía governance, no combat.

**Por qué:** PvP combat trivializa el setting "naval admiralty workplace serious". Admirals es **economy game profundo**, no shooter.

### 1.2 Anti-principios (lo que Admirals NUNCA es)

- ❌ **Roleplay teatral obligatorio** — el player puede silently work, no forced acting.
- ❌ **Grind sin propósito** — todo grind tiene reward visible.
- ❌ **Skill required twitchy** — no precision shooter, no rhythm games.
- ❌ **PvP combat** — disputes economic, no shooting.
- ❌ **Pay-to-win** — no microtransactions que afecten balance económico.
- ❌ **Idle game** — presence required, AFK penalizado.
- ❌ **Random rewards puros** — todo reward tiene componente skill/decision.

---

## 2. Loops temporales

> **El gameplay Admirals opera en 7 escalas de tiempo simultáneas.** Cada una con su propio feedback ciclo.

### 2.1 Loop 30 segundos — micro action

> **Lo que hace el player CADA 30 SEGUNDOS aproximadamente:**

#### Granja
- Drive tractor a parcela → click `F` para empezar plowing → ver bar progress 25s → done.
- Inspect crop quality → click crop → leer color indicator → decide harvest now or later.
- Cargar saco al van → walk + `F` pick + walk + `F` drop.

#### Molino
- Insert saco harina al silo → drag-drop animation 8s.
- Operar molino → mantener `Hold E` 12s mientras grain procesa.
- Quality check output → click sample → leer 0-100 score → grade asignada.

#### Bakery
- Amasar masa → mouse circular drag 8-15s → masa state visible.
- Shape baguette → mouse swipe gesture → shape appears.
- Hornear → click oven → set temp → close door → timer comienza.

#### Retail
- Reponer lineal → carry caja from storage → place items en shelf 6s/item.
- Cobrar cliente PED → click items → POS → payment → ticket print.
- Adjust pricing → slider en Tablet → confirm → save.

**Feedback común a TODOS estos:**
- ✅ Visual: animation completa.
- ✅ Audio: sound efectivo (knife chop, mixer hum, POS chime).
- ✅ Number: counter updates en HUD/Tablet.
- ✅ Particles/glow: confirmación visual subtle.

> **Crítico:** **cada 30s el player recibe ≥ 1 feedback positivo.** Si no, el design está mal — investiga.

### 2.2 Loop 5 minutos — task completion

> **Una "task" completa que el player puede start-and-finish en 5min.**

#### Ejemplos

**Granja — Plant a parcela:**
1. Drive a parcela vacía (45s).
2. Plow soil (30s).
3. Plant seeds (30s).
4. Apply water + fertilizer (45s).
5. Confirm planting in Tablet (15s).
6. Schedule harvest reminder (15s).

**Molino — Process saco trigo:**
1. Walk a storage, pick saco trigo (20s).
2. Carry to mill input (30s).
3. Configure mill settings (15s).
4. Run mill (90s espera + supervise).
5. Collect output saco harina (30s).
6. Quality test → grade asignada (20s).
7. Store in output silo (15s).

**Bakery — Bake batch baguettes:**
1. Mix dough en mixer (45s).
2. Knead (60s).
3. First rise (set timer, do other while wait) (5min con multitasking).
4. Shape baguettes (45s para batch 30).
5. Second rise (15min, hace otras cosas).
6. Bake (25min, hace otras cosas).
7. Cool (10min).
8. Total active time: ~5min para batch 30.

**Retail — Restock una sección:**
1. Check stock dashboard Tablet (15s).
2. Walk a storage room (30s).
3. Load cart with low-stock items (60s).
4. Walk to lineal (30s).
5. Restock items en shelves (90s).
6. Adjust pricing si needed (30s).
7. Update Tablet inventory (15s).

**Feedback al completar task:**
- ✅ Notification Tablet: "Task complete: +X €" o "+X reputation".
- ✅ Sound: success chime.
- ✅ Visual: HUD subtle confirmation.
- ✅ Number: progress bar mini-objective avanza.

### 2.3 Loop 30 minutos — mini-objective

> **Un objetivo interno de la sesión que llena ~30 min.**

#### Ejemplos

**Granja — Cosecha completa de 1 parcela:**
- Plant (5min) → wait crops mature (real-time scaled, 20-25min) → harvest (5min) → store (3min).
- 30min total (wait time hace otras tareas paralelas).
- Reward: ~8-15 sacos quality A/B → ~300-700 € value.

**Bakery — Producción mañana completa:**
- Mix 4 batches diferentes (10min active).
- Bake during fermentation overlap (15min monitoring).
- Cool + display setup (5min).
- Output: ~200 productos para venta del día.
- Reward: ~150-250 € waste-prevented + 800-1200 € revenue potential.

**Retail — Atender peak hours:**
- 18:00-18:30 peak after-work.
- 35-50 PED clients atendidos.
- ~700-1100 € revenue en 30min.
- Reward: numbers sube visiblemente Tablet.

**Molino — Procesar lote 20 sacos trigo:**
- 90s × 20 sacos = 30min batch processing.
- Output: 14 sacos harina + 6 sacos bran (con pérdidas).
- Revenue: ~1.000 € value created.

**Feedback al completar mini-objective:**
- ✅ Tablet notif: "Mini-objective complete!" + summary metrics.
- ✅ Sound: longer success chime + brass swell.
- ✅ Stat update visible en dashboard empresa.
- ✅ Achievement check (oleada 2+).

### 2.4 Loop 2 horas — session arc

> **Una sesión típica de 2-3h tiene un arc narrativo.**

#### Ejemplo Bakery (sesión 3h)

**Phase 1: Opening (0-30min) — Setup & Preparation**
- Login → check Tablet dashboard (5min).
- Review night's auto-NPC operation report (5min).
- Plan day's production: ¿qué hornear y cuánto? (10min).
- Pull ingredients from storage (10min).

**Phase 2: Morning rush (30min-1.5h) — Tension high**
- 7am-9am peak desayunos (60min real time).
- Cajero atender PEDs.
- Panadero re-bake complementary batches.
- Manager monitorea Tablet stress.
- ⭐ **Tension peak:** PED queue grows si cajero slow.

**Phase 3: Midday lull (1.5h-2h) — Release**
- 9am-12am quieter.
- Replenish, clean, count.
- Manage B2B contracts pending.
- Plan afternoon.

**Phase 4: Lunch peak + closure (2h-3h) — Tension + resolution**
- 12-14:30 lunch peak (30min).
- 14:30 closing rush (30min): clearance day-old.
- 14:30 close → count till → save → logout.

**Total session: 3h with clear arc, satisfying closure.**

> **Insight crítico:** una sesión Admirals **NO debe ser indefinida**. Hay momento natural de "stop here, save, come back tomorrow".

### 2.5 Loop sesión completa — closure

> **Una sesión completa termina con ritual de closure:**

1. **Cierre operativo** — close shop, count till, finalize batches.
2. **Resumen Tablet** — Tablet muestra "Session summary":
   - Revenue session.
   - Tasks completados.
   - Quality avg outputs.
   - Reputation change.
   - Achievements unlocked (oleada 2+).
3. **Plan para next session** — Tablet sugiere "Next session priorities":
   - Pendings (e.g., contract delivery tomorrow 6am).
   - Stock low alerts.
   - Maintenance scheduled.
4. **Logout con feel-good** — sound chime farewell + visual close.

> **Por qué esto importa:** sesión sin closure → player "no sabe cuándo parar" → fatigue. Sesión con closure → player satisfecho + ansioso por next.

### 2.6 Loop semanal — commitments

> **Lo que el player gestiona cada semana:**

| Activity | Frequency | Purpose |
|---|---|---|
| **Salary payments** | Quincenal (cada 2 semanas) | Pago empleados, sink mayor |
| **B2B subscriptions delivery** | Daily delivery in subscription | Revenue base predecible |
| **Maintenance equipment** | 1-2x semana | Prevent breakdowns |
| **Stock orders** | 2-4x semana | Replenish supplies |
| **Reputation review** | 1x semana | Check trend, adjust strategy |
| **Profit review** | 1x semana | Decide reinvest vs withdraw |
| **Empresa weekly meeting** (oleada 2+) | 1x semana | Coordinate co-founders/managers |

### 2.7 Loop mensual — empresa milestones

> **Cada mes el player revisa empresa-level metrics:**

| Metric | Review monthly |
|---|---|
| **GDP empresa** (revenue total mes) | Trend up or flat? |
| **Profit neto mensual** | Match plan? |
| **Cash runway** | Cómo está el saldo? |
| **MLO rent paid** | Confirmed? |
| **Depreciation accumulated** | Equipment getting old? |
| **Subscription MRR change** | Crecimiento o churn? |
| **Reputation milestone** | Crossed tier? |
| **Empresa rank servidor** | Top 10? Top 100? |
| **New competitor entered zone?** | Strategy adjust? |

### 2.8 Loop seasonal (oleada 2+)

> **Eventos servidor temporales que cambian gameplay temporalmente.**

- Festival Bread Day (1x año): premium pricing pan, demand × 2.
- Holidays: regalos PED + decoraciones MLO.
- Weather events: tormentas afectan granja outputs.
- Server-wide quests: collaborative events que dan rewards a empresas participating.

---

## 3. Onboarding flow detallado

> **El primer minuto, hora, día, semana del player nuevo.** Critical para retention.

### 3.1 Primer minuto (0-60s)

**Player joins server:**
- 0-5s: Loading screen Admirals (logo + brand sound).
- 5-15s: Spawn punto inicial (downtown / city center).
- 15-30s: **Tutorial pop-up Tablet:** "Press TAB to open Tablet."
- 30-45s: Player abre Tablet → sees Welcome screen + balance 2.500 € + IBAN ES00 ADML XXXX.
- 45-60s: **Quest #1 unlocks:** "Find your first job — Workplace app."

**Goal primer minuto:** player entiende que tiene Tablet + tiene dinero + hay sistema de jobs.

### 3.2 Primeros 5 minutos

**Quest #1: Get a job**
- Open Workplace app en Tablet.
- See list of empresas hiring (NPC + player ofreciendo).
- Select "Bakery NPC tutorial" (always available para new players).
- Apply → instant accept.
- Tablet vibrate + notification: "Welcome to Bakery!"

**Quest #2: Go to bakery + first task**
- GPS marker en mapa apunta a bakery NPC.
- Player camina/drives a bakery (~3min).
- NPC manager interacts: "Welcome! Your first task: bake 10 baguettes."

### 3.3 Primeros 30 minutos — first shift

**Tutorial guided shift Bakery NPC:**
- 0-5min: NPC instructor enseña amasado mecánica (paso a paso).
- 5-10min: Player baka su primer batch baguettes.
- 10-15min: NPC enseña horno setting + timing.
- 15-20min: First batch sale to NPC client + receive payment.
- 20-25min: Repeat para reinforce.
- 25-30min: Shift end → tutorial summary + first paycheck (~50 €).

**Achievements unlocked:**
- "First Loaf" (bake first bread).
- "First Sale" (sell first item).
- "Honest Day's Work" (complete first shift).

### 3.4 Primera hora

**Player puede:**
- Continue working tutorial bakery.
- Explore other apps Tablet (Bank, Map, Comm).
- Drive around city, find other empresas.
- Apply otros jobs.

**Tablet sugiere quests progresivos:**
- "Earn 500 €" (~3-4 shifts).
- "Try 3 different roles" (cajero, panadero, reponedor).
- "Explore the marketplace."

### 3.5 Primer día (3-6h gameplay)

**Player típico al final del día 1:**
- ~1.500-2.000 € total (incluyendo starting 2.500 + earnings).
- Has experimented 2-3 different roles.
- Knows the Tablet apps well.
- Has 1-2 friends-list contacts (other players or NPC).
- Reputation ~10-20 (just starting).

**Critical retention checkpoint:** ¿Player vuelve el día 2?

**Hooks para day 2 return:**
- Tablet notif al logout: "Tomorrow you can apply at Player Bakery — hiring 2 panaderos."
- Achievement progress visible: "Earn 5.000 € to unlock 'Worker Stage 2'."
- Daily login bonus (oleada 2): +50 € si login next day.

### 3.6 Primera semana (15-25h gameplay)

**Player típico al final semana 1:**
- 8.000-15.000 € balance (saving + earning).
- Master uno o dos roles.
- Member de 1-2 empresas player.
- Reputation 30-45.
- Has thought about: founding own empresa? Or stay employee?

**Decision point fork:**
- **Path A: Stay employee** — work permanent, comfortable, low risk.
- **Path B: Save to found empresa** — long-term goal 25-100k €.
- **Path C: Specialize** — become master panadero / quality inspector / driver.

> **Critical:** el design debe **make all paths viable**. Empleado satisfecho NO debe sentir "I'm wasting my time, I should found empresa."

### 3.7 Primer mes (50-100h gameplay)

**Player típico al final mes 1:**
- 30.000-80.000 € balance (ready to found si chose Path B).
- Master multiple roles.
- Reputation 50-65.
- Has founded empresa or seriously planning.
- Has experienced full loops weekly + monthly.
- Has either signed B2B contracts (as supplier) or hired employees.

**Retention milestone:** mes 1 churn target <40%. Industry average 60-70%.

---

## 4. Decision space mapping

> **Qué decisiones toma el player y con qué frecuencia.**

### 4.1 Decisions clasificadas por frequency

#### 4.1.1 Continuous (every few seconds)
- Movement input (drive, walk).
- Quality check during production.
- Pricing micro-adjust.

#### 4.1.2 Frequent (every few minutes)
- Which task to do next.
- Customer interaction strategy (B2C).
- Stock allocation per lineal.

#### 4.1.3 Occasional (every 30min - 2h)
- Sign B2B contract.
- Promote employee.
- Adjust salary.
- Order new stock.

#### 4.1.4 Strategic (daily - weekly)
- Plan production volume.
- Set pricing strategy.
- Hiring decisions.
- Schedule promotions.

#### 4.1.5 Long-term (weekly - monthly)
- Capital allocation (reinvest vs withdraw).
- Empresa expansion.
- Vertical integration.
- Founding new empresa.

### 4.2 Decision quality

> **Cada decisión debe tener:**

- **Stakes claros** (qué se gana / qué se pierde).
- **Information sufficient** (player tiene data para decidir).
- **Reversibility known** (can I undo? at what cost?).
- **Time pressure appropriate** (no rush forced false).

### 4.3 Anti-decision patterns

- ❌ **Decisions con info hidden** ("you don't know the price until you commit") — frustrating.
- ❌ **False choices** (todas opciones same outcome) — pointless.
- ❌ **Stakes invisible** ("what happens if I do this?") — confusing.
- ❌ **Forced reversibility** (one-way mistakes con high cost) — unfair without warning.

### 4.4 Decision quality examples

#### Good decision example: Sign B2B subscription contract
- **Stakes:** 30-day commitment, 8.000 € revenue total, escrow fee 80 €.
- **Information:** Tablet shows historical demand data + supplier reliability score + cost projection.
- **Reversibility:** can cancel mid-period with 10% penalty.
- **Time pressure:** offer expires 24h.
- ✅ Good — player has all info, knows risks, has time.

#### Bad decision example (avoided): Random gambling event
- ❌ "50% chance double money or lose all" — pure RNG.
- Admirals NO usa este pattern. Toda decisión es **informed choice**.

---

## 5. Difficulty curves por nodo

> **Qué tan complejo es cada nodo para masterear.**

### 5.1 Granja — beginner-friendly

| Skill level | Time to reach | Profit potential |
|---|---|---|
| **Novice** (basic farming) | 0-5h | 1.500-2.500 €/quincena employee |
| **Competent** (efficiency optimization) | 5-20h | 3.000-5.000 €/quincena founder |
| **Expert** (quality A consistent) | 20-50h | 8.000-12.000 €/mes profit |
| **Master** (premium lineage outputs) | 50-100h | 15.000-25.000 €/mes profit |

**Why beginner-friendly:**
- Mecánicas simples (drive, plant, harvest).
- Failure forgiving (1 bad cosecha = 5% pérdida, no catastrophic).
- Time-based (real-time waits, no precision).

### 5.2 Molino — intermediate

| Skill level | Time to reach | Profit |
|---|---|---|
| **Novice** | 0-10h | 2.000-3.000 €/quincena |
| **Competent** | 10-30h | 4.000-7.000 €/quincena founder |
| **Expert** | 30-80h | 12.000-20.000 €/mes |
| **Master** | 80-150h | 25.000-40.000 €/mes |

**Why intermediate:**
- Quality control critical (inputs vary).
- Capital alto (más stress decisional).
- Throughput matters (volume game).

### 5.3 Bakery — intermediate-advanced

| Skill level | Time to reach | Profit |
|---|---|---|
| **Novice** | 0-10h | 1.800-2.800 €/quincena |
| **Competent** | 10-40h | 5.000-9.000 €/quincena founder |
| **Expert** | 40-100h | 15.000-30.000 €/mes |
| **Master** (pastry premium + lineage) | 100-200h | 35.000-60.000 €/mes |

**Why advanced:**
- Recetas multiple, ingredient management complex.
- Schedule pre-dawn challenging.
- Dual channel (B2B + B2C) tactical.
- Waste management non-trivial.

### 5.4 Retail — advanced

| Skill level | Time to reach | Profit |
|---|---|---|
| **Novice** | 0-15h | 1.500-2.500 €/quincena |
| **Competent** | 15-50h | 6.000-12.000 €/quincena founder |
| **Expert** | 50-150h | 20.000-40.000 €/mes |
| **Master** (multi-supplier, layout optimization) | 150-300h | 50.000-100.000+ €/mes |

**Why advanced:**
- Multi-categoría simultaneous management.
- Dynamic pricing optimization.
- PED foot traffic dependent.
- Inventory turnover critical.
- Supplier management.

### 5.5 Logística (cross-node) — beginner-intermediate

| Skill level | Time to reach | Profit |
|---|---|---|
| **Novice driver** | 0-5h | 1.700-2.500 €/quincena |
| **Competent** | 5-20h | 3.500-5.000 €/quincena |
| **Expert** | 20-50h (own logistics co.) | 10.000-18.000 €/mes |

---

## 6. Mastery curves

### 6.1 Generic mastery curve

```
Profit / Hour
   ▲
   │                              ╱─── Master plateau (high)
   │                          ╱╱╱╱
   │                     ╱╱╱╱
   │                ╱╱╱╱  Expert exponential
   │           ╱╱╱╱
   │       ╱╱╱╱     Competent
   │   ╱╱╱╱
   │╱╱╱     Novice
   ├──────────────────────────────────► Hours played
   0   10   30   80   200   500
```

### 6.2 Stage characteristics

#### Novice (0-10h)
- Player learns mechanics.
- Mistakes frequent (waste, low quality).
- Profit/hour: ~5-15 €.
- Engagement: 90% (novelty + discovery).

#### Competent (10-30h)
- Player executes basic loops smoothly.
- Some efficiency gains.
- Profit/hour: ~30-60 €.
- Engagement: 75% (mastery emerging).

#### Expert (30-100h)
- Player optimizes processes.
- Strategic decisions clear.
- Profit/hour: ~100-200 €.
- Engagement: 80% (sense of agency + mastery).

#### Master (100h+)
- Player innovates strategies.
- Mentors others.
- Profit/hour: ~250-500 €.
- Engagement: 70% (less novelty, but mastery satisfaction).

### 6.3 Mastery feedback signals

> **El player sabe que está progresando porque:**

- **Quality A rate** sube de 40% (novice) → 95%+ (master).
- **Waste rate** baja de 20% → 4%.
- **Conversion B2C** sube de 50% → 80%.
- **Transactions/hour** sube de 5 → 30+.
- **Reputation** sube de 0 → 90+.

---

## 7. Concrete session examples

### 7.1 Session example: New player Day 3 (Bakery employee)

**Total session: 1.5h**

```
0:00  Login server
0:01  Open Tablet, check messages: "Bakery shift starts at 7am" (notification)
0:03  Drive to Bakery NPC (8 min walk OK)
0:11  Clock in at Bakery (Tablet detects geo-fence)
0:12  NPC manager assigns: "Bake 60 baguettes"
0:14  Mix dough batch 1 (mixer mechanic, 8s mouse motion)
0:18  Knead (60s mouse motion)
0:20  First rise (8min wait → meanwhile clean station)
0:28  Shape baguettes (drag-drop 30 baguettes, ~3min)
0:31  Second rise (15min wait → meanwhile prepare batch 2)
0:46  Bake batch 1 (25min in oven → meanwhile bake batch 2 prep)
1:11  Batch 1 out, cooling
1:15  Sale to NPC clients during morning peak (4-5 transactions)
1:25  Manager confirms shift complete
1:27  Clock out, paycheck +75 € (great shift, quality A bonus)
1:28  Tablet notif: "Tomorrow contract: 100 baguettes for Player Retail XYZ"
1:30  Logout

Total earned: +75 €
Reputation: +0.3
Quality A rate: 92%
```

### 7.2 Session example: Founder week 4 (own Bakery)

**Total session: 4h**

```
0:00  Login at 5am server time (pre-dawn shift)
0:02  Tablet morning briefing: yesterday net +1.250 €, 3 contracts pending today
0:05  Pull ingredients from storage
0:15  Mix 4 batches different products (baguettes 200, loaves 80, croissants 60, specialty 30)
0:30  Schedule fermentation timing
0:35  First bakes go in oven
1:00  More bakes batch
1:15  6:30am — early B2B delivery to subscription Retail (player driver picks up)
1:30  Open shop 7am, first PEDs entering
1:45  Cajero (player employee) handles transactions, founder monitors
2:00  Mid-morning lull, restock display
2:15  Quality check on speciality batch (manual quality A confirmed)
2:30  Manager Panel review: revenue first 2.5h = 280 € (on track)
2:45  Decision: launch flash promo 17h-19h on day-old to clear stock
3:00  Schedule afternoon prep
3:15  Lunch peak begins, founder helps cajero
3:45  Lunch peak ends, count till intermediate
4:00  Logout (will resume 16h for after-work peak)

Total session profit estimate: +650 €
Reputation: stable at 78
B2B subscription on track
```

---

## 8. Feedback loops detailed

> **Feedback loop = action → reaction visible/audible/numeric.** Admirals tiene **3 capas** de feedback simultáneas.

### 8.1 Micro feedback (every action, <1s)

> **Feedback inmediato a cada input del player.**

| Action | Visual | Audio | Numeric |
|---|---|---|---|
| Click cobrar POS | Button press animation | POS chime | Counter +1 transaction |
| Pick up saco | Hands grip animation | Cloth rustle | Inventory +1 |
| Place item lineal | Item appears + glow | Place thud | Stock counter update |
| Open Tablet | Slide-up animation | UI swipe sound | – |
| Touch shader Tablet device | Glow ripple shader | Subtle haptic-like | – |
| Quality check pass | Green checkmark | Success ping | Score appears |
| Quality fail | Red X | Disapprove buzz | Score appears red |
| Type IBAN | Char appears | Keypress click | – |

**Rule:** **NO action puede ser silenciosa.** Si player hace algo y no recibe feedback inmediato, asume que falló.

### 8.2 Meso feedback (task complete, 5-30min)

> **Feedback al completar una task significativa.**

| Task complete | Visual | Audio | Numeric |
|---|---|---|---|
| Batch baked | Notification "Batch complete!" + items in display | Brass swell short | Stock +30, revenue projected |
| Cosecha harvested | Crop disappears, sacos appear | Tractor stop + bell | Inventory + sacos |
| Contract delivered | Stamp animation "DELIVERED" | Confirmation chord | Reputation +0.5, payment received |
| Day's revenue total | Tablet daily summary popup | Day's brass riff | Detailed breakdown |
| Quality A streak (5 in row) | Toast notification gold border | Achievement chime | Streak counter visible |
| Salary paid | Tablet notif "Salary received +X€" | Cash counter sound | Balance updated |

**Rule:** meso feedback debe ser **memorable** — el player recordará "ese momento" 1h después.

### 8.3 Macro feedback (session/day/week)

> **Feedback al close de session/day/week.**

| Macro event | Feedback |
|---|---|
| **Session end** | Tablet "Session Summary": revenue, tasks, achievements, quality avg. Sound: closing brass piece. |
| **Day end** | Empresa daily report: profit, top SKUs, anomalies. Notification email-style en Tablet. |
| **Week end** | Weekly report: trends, milestones, comparison vs last week. Visual charts. |
| **Month end** | Monthly empresa review: financial statement, KPIs, suggestions for improvement. |
| **Reputation tier crossed** | Big banner notification "Reputation 80 — Premium tier!" + perks unlocked listed. |
| **Achievement unlocked** (oleada 2+) | Achievement popup with brass swell + entry in profile. |

**Rule:** macro feedback debe **proyectar futuro** — "this session you did X, tomorrow you can do Y".

### 8.4 Feedback anti-patterns

- ❌ **Spam micro** — feedback excesivo per second satura. Evita > 1 audio cue por segundo.
- ❌ **Skip meso** — task completed sin acknowledgment = anti-climactic.
- ❌ **Macro overwhelming** — session summary con 50 metrics confunde. Keep 5-8 key metrics.
- ❌ **Negative feedback excesivo** — too many "fail" sounds = frustration. Balance positive vs negative ratio 4:1.

---

## 9. Failure states + recovery paths

> **Cuando algo va mal en Admirals.** El design define **graceful recovery**, no death spiral.

### 9.1 Tipos de failure states

#### 9.1.1 Operational failures

| Failure | Trigger | Recovery |
|---|---|---|
| **Bad batch** (quality D outputs) | Inputs malos, equipment unmaintained | Discard batch, accept loss, improve next |
| **Stock empty** (Retail SKU 0) | Failed to reorder | Reorder from supplier, conversion drops temp |
| **Late B2B delivery** | Driver delay, traffic | Notify cliente, offer discount, fulfill ASAP |
| **Equipment breakdown** | No mantenimiento | Insurance kicks if active, repair cost, downtime |
| **PED queue too long** | Insufficient cajeros | PEDs leave, reputation -0.2 |

#### 9.1.2 Strategic failures

| Failure | Trigger | Recovery |
|---|---|---|
| **Empresa cash low** | Over-extended, slow revenue | Withdraw inventory, sell assets, reduce salaries (con caps) |
| **Reputation tank** | Multiple bad batches/late deliveries | 4-6 weeks consistent quality A to recover |
| **Subscription churn** | Bad service quality | Improve service, offer make-good discount |
| **Bankruptcy approach** | Saldo < 0 several days | Sell equipment liquidate, find investor, founder bailout |

#### 9.1.3 Catastrophic failures (rare)

| Failure | Trigger | Recovery |
|---|---|---|
| **Empresa bankruptcy** | 15 days saldo negative | Empresa locked, 30 days asset liquidation, founder restart possible |
| **Player banned** | Cheating detected | Permanent (server-level decision) |
| **MLO loss** | Failed rent 3 months | MLO repossesed, equipment moved to storage |

### 9.2 Recovery design principles

#### Principle: Always a path back
> **Ningún failure es game-over.** Player puede always recover, even bankruptcy.

#### Principle: Cost proportional
> **Recovery cost ∝ severity.** Small failure = small cost. Big failure = big cost. Never disproportionate.

#### Principle: Public failure private recovery
> **Failures visible** (reputation tank público), **recovery private** (no shame parade).

### 9.3 Help mechanisms

#### 9.3.1 Tablet warnings preventive
- "Equipment maintenance overdue" → 7 day before failure.
- "Stock low" → before stockout.
- "Cash runway 5 days" → before crisis.

#### 9.3.2 Mentor system (oleada 2+)
- Veteran players can mentor newbies.
- Mentor receives reputation + small reward.
- Mentee receives guidance + insurance against early mistakes.

#### 9.3.3 Server admin support
- Discord/forum for help.
- Admin can spawn small bailout grants in extreme cases (logged + audited).

---

## 10. Multiplayer dynamics

> **Cómo otros players afectan el gameplay.**

### 10.1 Tipos de multiplayer interaction

#### 10.1.1 Direct cooperative
- **Empresa membership** — co-founders/employees coordinate.
- **B2B contracts** — supplier-client relationship.
- **Logistics services** — driver delivers for another empresa.

#### 10.1.2 Indirect cooperative
- **Lineage chains** — granja → molino → bakery → retail (different empresas).
- **Market liquidity** — more players = more contracts available.

#### 10.1.3 Competitive
- **Same-zone competition** — 2 bakeries in 200m share foot traffic.
- **Pricing competition** — pricing wars permitted within caps.
- **Reputation competition** — better reputation = more clients.

#### 10.1.4 Adversarial (limited, no PvP combat)
- **Disputes** — contract disagreements → governance resolution.
- **Reputation attacks** (oleada 2+) — fake reviews → admin moderation.

### 10.2 Multiplayer design principles

#### Principle: Mutual benefit primary
> **Default interaction is win-win.** Predatory tactics are exception, not rule.

#### Principle: Asymmetric cooperation OK
> **Players can have different roles** — granja player + bakery player + retail player coordinate, even if their nodes have different complexity/profit profiles. Sistema de margins por nodo (Master §7) ensures all roles equally rewarded.

#### Principle: Visible reputation
> **Track record visible** — players con bad history can be filtered/avoided. Hace mercado self-correcting.

#### Principle: No griefing tools
> **No tools to deliberately harm others.** No combat, no theft (oleada 1), no sabotage. Adversarial limited to legitimate disputes.

### 10.3 Multiplayer scenarios

#### Scenario 1: Friend joins server
- Friend invites you to join their empresa.
- You become employee or co-founder (decided together).
- Coordinate roles via Tablet Comm app.
- Win-win: shared revenue.

#### Scenario 2: Two bakeries open same zone
- Foot traffic split.
- Differentiation strategy: one premium, one volume.
- Reputation becomes critical.
- Long-term: market settles.

#### Scenario 3: Lineage chain forms
- Granja A (player Alice) supplies Molino B (player Bob).
- Molino B supplies Bakery C (player Carol).
- Bakery C supplies Retail D (player Dave).
- Lineage premium × 1.20 unlocked → all 4 players benefit.
- Trust chain built over weeks of consistent quality.

#### Scenario 4: Subscription B2B fails
- Bakery promised quality A weekly.
- Quality drops to C 3 deliveries in row.
- Retail cliente exercises pause subscription.
- Bakery reputation -3.
- Recovery: 5 quality A consecutive, then resume subscription.

---

## 11. Pacing — tension/release patterns

> **Engaging gameplay alternates tension y release.**

### 11.1 Macro pacing (sesión)

```
Tension level
   ▲
high │           ╱─╲      ╱─╲
     │          ╱   ╲    ╱   ╲
mid  │     ╱──╱     ╲──╱     ╲──
     │    ╱
low  │ ──╱
     ├────────────────────────────►  Time
     0   30   60   90  120  150  180 min
       Open Morning Lull Lunch Lull Close
            peak       peak
```

**Insight:** sesión 3h tiene **2 peaks tension** + **3 release periods**. Player no se quema porque hay descansos.

### 11.2 Micro pacing (within task)

> **Even within a single task, pacing matters.**

Bake a batch:
- **Active phase** (mix, knead): 2min hands-on attention.
- **Wait phase** (fermentation): 15min low attention, multitask possible.
- **Active phase** (shape, bake setup): 3min attention.
- **Wait phase** (bake): 25min very low attention.
- **Active phase** (cool, display): 2min attention.

> **Multitask rewarded:** during wait phases, player can do other tasks. Forces planning + scheduling skill.

### 11.3 Anti-pacing patterns

- ❌ **Constant high tension** — burnout in 30min.
- ❌ **Constant low tension** — boredom.
- ❌ **No multitask possible** — wait phases idle = disengagement.
- ❌ **Forced timing** — player waits exactly X seconds, no flexibility = frustration.

---

## 12. Anti-boredom mechanisms

> **Cómo prevent que el player se aburra.**

### 12.1 Variation sources

#### 12.1.1 Procedural variation
- **Quality variability** outputs (real percent, not always A).
- **Demand variability** (peak hours predictable but exact volume varies).
- **Foot traffic variation** (PEDs spawn pattern semi-random).

#### 12.1.2 Player-driven variation
- **Recipe choice** Bakery (decide what to bake today).
- **Pricing strategy** Retail (premium vs discount day).
- **Promo timing** (when to launch).
- **Hiring/firing** (workforce decisions).
- **Capital allocation** (reinvest where).

#### 12.1.3 Server-driven variation (oleada 2+)
- **Seasonal events** (Bread Day, Holidays).
- **Weather affecting Granja** outputs.
- **Server-wide quests**.
- **Random NPC events** (large catering order, special VIP visit).

### 12.2 Surprise mechanisms

> **Healthy doses of unexpected:**

- **Unannounced quality A streak** unlocks bonus 50 €.
- **Mystery PED VIP client** (1% chance) pays 3x normal price.
- **Competitor closes shop** unexpectedly → market opens.
- **Subscription new client** approaches you proactively.

> **Rule:** surprises **all positive or neutral**, never sudden negative (no "your equipment breaks for no reason"). Negative outcomes always preceded by warnings (master §3.5 monitoring).

### 12.3 Mastery progression as anti-boredom

> **As player masters basic, deeper systems unlock:**

- Stage 1: Basic loops (novice).
- Stage 2: Optimization (competent).
- Stage 3: Strategy (expert) — pricing optimization, supplier mix.
- Stage 4: Innovation (master) — pioneering strategies, mentoring.

> **Each stage feels different**, despite same "world". Player grows with the game.

### 12.4 Social anti-boredom

- **Empresa membership** — players coordinate, communicate.
- **Mercado dynamic** — new contracts appear daily.
- **Reputation rivalries** (friendly) — top 10 leaderboard server.
- **Mentoring** (oleada 2+) — veteran helps newbie, both get rewards.

---

## 13. Retention hooks — daily / weekly / monthly

### 13.1 Daily hooks

| Hook | Trigger |
|---|---|
| **Daily login bonus** (oleada 2) | +50 € si login each day |
| **Daily contract reminders** | Tablet notif "Contract due tomorrow" |
| **Daily peak hour reminder** | "Lunch peak in 30min — be ready!" |
| **Daily quality streak** | "Quality A 4 days in row — 1 more for bonus!" |
| **Daily server event** (oleada 2+) | "Today only: -10% market fees!" |

### 13.2 Weekly hooks

| Hook | Trigger |
|---|---|
| **Weekly salary day** | Quincenal payments (every 2 weeks alternate) |
| **Weekly subscription renewals** | B2B contracts renew |
| **Weekly empresa review** | Recap report Tablet |
| **Weekly leaderboards** (oleada 2+) | Top earners, top quality, top reputation |
| **Weekly community event** (oleada 2+) | Server-wide quest |

### 13.3 Monthly hooks

| Hook | Trigger |
|---|---|
| **Monthly MLO rent** | Forces engage with finances |
| **Monthly empresa metrics** | Big-picture review |
| **Monthly tier progress** | Reputation tier change possible |
| **Monthly seasonal events** (oleada 2+) | Festival, holiday |
| **Monthly milestone rewards** (oleada 2+) | "Played 30 days streak — special perk" |

### 13.4 Long-term hooks (multi-month)

| Hook | Time |
|---|---|
| **Empresa founding milestone** | 30k-100k € savings goal |
| **First subscription B2B** | Week 4-8 typical |
| **Reputation premium tier (80+)** | Month 3-6 typical |
| **Empresa expansion** (multi-MLO oleada 2) | Month 6-12 |
| **Leaderboard top 10** (oleada 2+) | Month 6+ |

---

## 14. KPIs gameplay

> **Cómo medir si el gameplay funciona.**

### 14.1 Engagement KPIs

| Metric | Healthy | Warning | Critical |
|---|---|---|---|
| **Avg session length** | 90-180 min | 30-90 min | <30 min |
| **Sessions per week per active player** | 3-5 | 1-3 | <1 |
| **Day 1 retention** (return day 2) | >70% | 50-70% | <50% |
| **Day 7 retention** | >40% | 25-40% | <25% |
| **Day 30 retention** | >25% | 15-25% | <15% |
| **Avg time to first task complete** | <15 min | 15-30 min | >30 min |
| **Avg time to first €100 earned** | <30 min | 30-60 min | >60 min |
| **Avg time to first achievement** | <5 min | 5-15 min | >15 min |

### 14.2 Mastery progression KPIs

| Metric | Target |
|---|---|
| **% players reach Competent** (10+h) | >60% of those who pass day 1 |
| **% players reach Expert** (30+h) | >30% of competent |
| **% players reach Master** (100+h) | >10% of expert |

### 14.3 Decision quality KPIs

| Metric | Healthy |
|---|---|
| **Decision regret rate** (player undoes recently) | <15% |
| **Information sufficiency complaints** | <5% feedback |
| **Reversibility complaints** | <3% |

### 14.4 Content engagement KPIs

| Metric | Target |
|---|---|
| **Apps opened per session Tablet** | 5-8 of 12 |
| **Mini-objectives completed per session** | 3-6 |
| **Tasks completed per hour** | 8-15 |
| **B2B contracts signed per month per founder** | 2-5 |

### 14.5 Social KPIs

| Metric | Target |
|---|---|
| **% players in empresa** | >50% by week 4 |
| **Avg friends list size** | 3-8 by week 4 |
| **Lineage chains formed** | 2-5 active server |

---

## 15. Edge cases gameplay + roadmap

### 15.1 Edge cases gameplay

#### 15.1.1 Player AFK mid-task
- Task pauses if player AFK >5min.
- Equipment goes idle (no waste accelerated).
- Resumed when player returns.
- If AFK > 30min: NPC employee (if hired) takes over auto.

#### 15.1.2 Server crash mid-session
- Last save state restored on reconnect.
- Pending tasks preserved.
- B2B contracts not affected (server-level state).

#### 15.1.3 Low population server
- NPC bridges activate more aggressively.
- Auto-NPC employees available cheap.
- Server admin event boosts (oleada 2+).

#### 15.1.4 New player joins late-server
- Starting balance same 2.500 €.
- Tutorial unchanged.
- But economy already mature → harder to compete with established players.
- **Mitigation:** new player tutorials emphasize employee path first.

#### 15.1.5 Veteran player feels stagnant
- Master tier reached → seek new challenges.
- Solutions: mentor mode, expand to new vertical, multi-empresa.
- Server admin can introduce special challenges.

### 15.2 Anti-patterns gameplay

- ❌ **Tutorial walls** — forcing tutorial complete before any freedom.
- ❌ **Impossible early game** — newbie must compete with veteran prices.
- ❌ **Punishing experimentation** — trying new role costs too much.
- ❌ **Hidden mechanics** — important info locked behind discovery.
- ❌ **Skill gaps unbridgeable** — newbie cant ever catch up.

### 15.3 Roadmap

#### Oleada 1 (T-0 — incluido)
- ✅ 6 principios filosofía gameplay.
- ✅ 7 loops temporales (30s → mensual).
- ✅ Onboarding flow detallado (1min → 1 mes).
- ✅ Decision space mapping.
- ✅ Difficulty + mastery curves todos nodos.
- ✅ Feedback loops 3 capas (micro/meso/macro).
- ✅ Failure states + recovery.
- ✅ Multiplayer dynamics.
- ✅ Pacing patterns.
- ✅ Anti-boredom mechanisms.
- ✅ Retention hooks daily/weekly/monthly.
- ✅ KPIs gameplay completos.
- ✅ Edge cases.

#### Oleada 2 (T+6 meses)
- 🔜 Achievements system completo.
- 🔜 Leaderboards servidor.
- 🔜 Mentor system formal.
- 🔜 Seasonal events.
- 🔜 Daily login bonuses.
- 🔜 Reviews/ratings sistema.
- 🔜 Mini-quest system PEDs especiales.
- 🔜 Hunger system (B2C consumo real).

#### Oleada 3+ (T+12 meses)
- 🔜 PvE economic challenges (NPC corporations).
- 🔜 Cross-server tournaments.
- 🔜 Procedural quests AI-generated.
- 🔜 Dynamic narrative events.

### 15.4 Estado del documento

- **Versión:** 1.0 (firmado — completo, 15 secciones, 2 partes publicadas).
- **Próxima revisión:** evolución cuando se añadan achievements + seasonal events oleada 2.
- **Documentos hijos pendientes:**
  - `gameplay/02_progression_systems.md` — skill trees, achievements, milestones.
  - `gameplay/03_social_features.md` — empresa, chat, market interactions.
- **Documentos relacionados:**
  - Bible §4 (Pilares) + §10 (Mecánica core).
  - Todos `design/0X_node_*.md` — mecánicas específicas.
  - `economy/01_economic_model.md` — números canónicos que rigen rewards.

### 15.5 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 (parte 1) | 2026-05-01 | Founder + Cascade | §0-§7 (filosofía, loops temporales, onboarding flow, decision space, difficulty curves, mastery, sessions example). |
| 1.0 (parte 2) | 2026-05-01 | Founder + Cascade | §8-§15 (feedback loops, failure states, multiplayer, pacing, anti-boredom, retention hooks, KPIs, edge cases, roadmap). **Documento completo, firmable.** |

---

## Resumen ejecutivo del documento (cierre)

El **Gameplay Loops** es el corazón experiencial del producto:

- **6 principios** filosofía: trabajo real, feedback inmediato, decisiones consecuentes, progreso medible, sesión con arc, multiplayer económico.
- **7 loops temporales** simultáneos (30s → mensual), cada uno con feedback propio.
- **Onboarding flow** detallado primer minuto / 5 minutos / 30 minutos / hora / día / semana / mes.
- **Decision space** clasificado por frequency con principles de quality.
- **Difficulty curves** por nodo: Granja beginner, Molino intermediate, Bakery int-advanced, Retail advanced.
- **Mastery curves** novice → competent → expert → master (0h → 200h+).
- **Feedback loops** 3 capas: micro (every action), meso (task complete), macro (session/day).
- **Failure states** con recovery paths siempre — no game over.
- **Multiplayer** cooperative > competitive, sin PvP combat, governance over violence.
- **Pacing** tension/release patterns, multitask rewarded.
- **Anti-boredom** via variation, surprise positive, mastery progression, social.
- **Retention hooks** daily / weekly / monthly bien definidos.
- **KPIs gameplay** medibles: session length, retention day 1/7/30, time-to-first metrics.

> **Si en oleada 1 con 50 players activos durante 30 días, el avg session length > 90 min, day 1 retention > 70%, day 30 retention > 25%, time to first task complete < 15 min, % players reaching Competent > 60%, lineage chains formed > 2-5 active — habrá funcionado el modelo gameplay Admirals.**

> El gameplay no es lo que el player VE — es lo que el player SIENTE haber hecho. Cada acción cuenta, cada decisión pesa, cada sesión cierra con sentido.

---

*"El gameplay no es lo que el player VE — es lo que el player SIENTE haber hecho."*

**FIN DEL DOCUMENTO `gameplay/01_gameplay_loops.md` v1.0**
