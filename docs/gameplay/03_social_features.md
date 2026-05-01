# 👥 Admirals — Social Features

> **Versión:** 1.0 (firmado — completo, 15 secciones).
> **Documento padre:** `gameplay/01_gameplay_loops.md` v1.0 (gameplay master).
> **Documento hermano:** `gameplay/02_progression_systems.md` v1.0 (firmado).
> **Documentos referenciados:** Bible §4 + §10, `economy/01_economic_model.md` v1.0 §9 (empresa), `technical/02_events_catalog.md` v1.0 (eventos `comm:*`, `empresa:*`).
> **Estado:** firmado.

> **Lectura previa obligatoria:** `gameplay/01_gameplay_loops.md` (especialmente §10 multiplayer dynamics), `economy/01_economic_model.md` §9 (sistema empresa).

---

## 0. Resumen ejecutivo

Este documento define **cómo los players interactúan socialmente** en Admirals. Cubre toda forma de comunicación, colaboración, y gobernanza entre players.

> **Filosofía social Admirals:** **economía es social, no individual.** Cada empresa requiere coordinación. Cada lineage chain requiere trust. Cada disputa requiere governance. Las features sociales son **infraestructura crítica**, no add-on.

Define:

- **Filosofía social** — los 5 principios de interacción Admirals.
- **Empresa membership** — founders, co-founders, employees, voting, dividends.
- **Chat + Comm system** — channels, DMs, broadcasts.
- **Friends list + public reputation**.
- **Market interactions** — job postings, contract negotiations, market browser.
- **Mentor system** (oleada 2+).
- **Reviews/ratings** (oleada 2+).
- **Server-wide events + community**.
- **Disputes resolution governance**.
- **Leaderboards servidor**.
- **Anti-patterns sociales** (griefing prevention, harassment).
- **Privacy + security** consideraciones.
- **KPIs sociales** + monitoring.
- **Roadmap**.

> **Por qué este doc importa:** un MMO con economía rica pero social pobre **muere a los 3 meses**. Los players quedan, vuelven, y recomiendan Admirals porque **forman relaciones reales** allí. Este documento define cómo Admirals facilita esas relaciones.

---

## 1. Filosofía social

### 1.1 Los 5 principios

#### Principio 1 — Comunicación contextual primero
> **Comunicación happens en context de trabajo.** No standalone chat rooms.

- Cajero atiende cliente PED → no chat irrelevante.
- Manager comunica employees DURANTE turno (not via guild chat).
- B2B negotiation happens en Mercado app (con context).

**Por qué:** chat puro = noise. Context-bound = signal.

#### Principio 2 — Cooperación recompensada, competencia respetada
> **Default state cooperative.** Pero competencia honesta también celebrada.

- Lineage chains (cooperative) → premium pricing × 1.20.
- Local competition (2 bakeries) → reputation differentiation.
- Both viable paths.

#### Principio 3 — Reputación pública, comportamiento privado
> **Track record visible.** Pero individual transacciones privadas.

- Profile shows reputation tier + summary metrics.
- Specific contracts/clients NOT visible to competitors.

#### Principio 4 — Governance over violence
> **Disputas se resuelven via mecanismos formales**, no PvP combat.

- Contract dispute → arbitration system.
- Reputation attack → moderator review.
- No tools to "punish" otros players unilaterally.

#### Principio 5 — Toxicity zero tolerance
> **Harassment, dox, griefing → server-level bans.**

- Reporting tools accessible.
- Moderator response < 24h target.
- Repeat offenders → permanent.

### 1.2 Anti-principios sociales

- ❌ **Always-on chat overlay** distrayendo del trabajo.
- ❌ **Forced socialization** (events que requieren invitar amigos).
- ❌ **Public shaming mechanics** (visible bans, downvote piles).
- ❌ **Stalking enabled** (geo-tracking otros players sin consent).
- ❌ **Revenue from toxicity** (no premium features que aprovechen drama).

---

## 2. Empresa membership

> **La empresa es la unidad social principal.** Todos los players activos eventualmente forman parte de una.

### 2.1 Roles dentro de empresa

#### 2.1.1 Founder
- Único role con poder absoluto inicial.
- Acciones: hire/fire, set salaries, sign contracts, withdraw profits.
- Puede transfer ownership (sell empresa).
- Puede declarar bankruptcy.

#### 2.1.2 Co-Founder
- 2-5 co-founders máximo por empresa.
- Equity share (founder + co-founders sum 100%).
- Voting rights en strategic decisions (oleada 2+ formal voting).
- Cannot unilaterally hire/fire (requires founder approval).

#### 2.1.3 Manager (employed)
- Hired employee con permissions delegate.
- Can hire/fire dentro de su department.
- Can set local pricing dentro caps.
- Salary mensual.

#### 2.1.4 Specialist (employed)
- Roles especializados: Maestro Panadero, Quality Inspector, Driver Senior.
- Higher salary que junior.
- No management permissions.

#### 2.1.5 Employee Junior
- Default newcomer.
- Operativo basic tasks.
- Promotable a Specialist.

### 2.2 Equity structure

#### 2.2.1 Founder solo
- Founder owns 100% equity.
- Profits 100% to founder (or reinvested).

#### 2.2.2 Founder + co-founders
- Equity split agreed at empresa founding.
- Example: founder 60%, co-founder A 25%, co-founder B 15%.
- Profits distributed proportional to equity (after retention 8% tax).

#### 2.2.3 Equity changes
- Founder can issue new equity (dilute existing).
- Co-founders can sell equity to other players (with founder approval).
- Equity changes require written agreement (Tablet Comm app contract).

### 2.3 Voting rights (oleada 2+ formal)

> **Strategic decisions require voting si > 1 founder/co-founder:**

- Major capital expenditure (>10% empresa value).
- Merger / acquisition.
- Bankruptcy declaration.
- Founder transfer.

**Voting weight:** proportional to equity.

**Quorum:** 60% of equity present required.

### 2.4 Dividend distribution

#### 2.4.1 Auto-distribution monthly
- Default: profits month split per equity.
- Distributed to founder/co-founder personal IBANs.
- Tax 8% retained automatically.

#### 2.4.2 Reinvest mode
- Founder can opt: "Reinvest 100% this month" (no dividends).
- Boosts empresa cash for expansion.

#### 2.4.3 Custom split
- Founder can set custom temporary split (e.g., bonus to manager).

### 2.5 Empresa joining flow

#### 2.5.1 Apply for job
1. Player sees job posting Tablet Workplace app.
2. Click "Apply" → profile + reputation visible to founder.
3. Founder reviews + accepts/rejects.
4. Accepted: instant employee.

#### 2.5.2 Co-founder invitation
1. Founder generates "Co-founder invite" link/code en Tablet.
2. Sends to player.
3. Player accepts → equity terms agreed → co-founder formal.

#### 2.5.3 Empresa founding (recap economy §9.2)
- Pay founding fee 5.000-15.000 €.
- Choose name + sector + MLO.
- Optional: invite co-founders.
- Empresa created.

### 2.6 Empresa leaving flow

#### 2.6.1 Employee resign
- Notice period: 7 days (oleada 1, configurable).
- Salary continues during notice.
- Last day: Tablet logs offboarding.

#### 2.6.2 Employee fired
- Founder/Manager fires.
- Severance pay: 1 quincena salary.
- Reputation impact: -2 founder, -1 employee (mutual minor).

#### 2.6.3 Co-founder exit
- Negotiate buyback equity con founder/other co-founders.
- Or sell equity to outside player (with approval).

---

## 3. Chat + Comm system

### 3.1 Comm app structure

> **Tablet Comm app es el chat hub centralizado.**

#### 3.1.1 Tipos de canales

| Channel type | Audience | Use |
|---|---|---|
| **Direct Message (DM)** | 1-on-1 | Private conversations |
| **Empresa internal** | Empresa members | Operational coordination |
| **Empresa department** | Department members (oleada 2+) | Team coordination |
| **Friends group** | User-defined groups | Social |
| **Public market** | All server | Trade announcements |
| **Server announcement** | Server admin → all | Events, updates |

### 3.2 Message types

| Type | Description |
|---|---|
| **Text** | Standard chat message |
| **Voice note** (oleada 2+) | Audio recording up to 30s |
| **Image attachment** (oleada 2+) | Screenshot of empresa metrics, etc. |
| **Contract proposal** | Embedded contract for B2B with accept/reject buttons |
| **Job offer** | Embedded job posting |
| **Quick action** | Button "View Profile" "Send Money" |

### 3.3 Notification rules

- **DM:** Tablet vibrate + sound + badge count.
- **Empresa channel:** Badge count, sound only if mentioned.
- **Public market:** Badge count si filter match.
- **Server announcement:** Force banner top of screen.
- **Mute/Do not disturb** options per channel.

### 3.4 Spam + abuse prevention

- **Rate limit:** max 60 messages/hour per channel for non-empresa members.
- **Mute:** users can mute other users.
- **Block:** prevents DM + visibility.
- **Report:** sends to moderators with context.
- **Auto-flag:** offensive language → review.

### 3.5 Persistence

- DMs: persistent (never auto-deleted).
- Empresa channels: 30 days retention.
- Public market: 7 days retention.
- Server announcement: persistent.

### 3.6 Search

- Tablet Comm app: search history within channels.
- Filter by sender, date, message type.

---

## 4. Friends list + public reputation

### 4.1 Friends list

#### 4.1.1 Adding friends
- Player A profile → "Add as friend" button.
- Player B receives request notification.
- Accepted: bidirectional friendship.

#### 4.1.2 Friend benefits
- Easier DM access (priority notifications).
- See online status.
- See empresa affiliation.
- Quick "Send Money" / "Send Item" with friends.
- Co-founder invite priority.

#### 4.1.3 Limits
- Max friends list: 100 (soft cap).
- Mutual friend recommendations Tablet Comm.

### 4.2 Public reputation profile

> **Each player has public profile accessible by IBAN ID or in-game name.**

#### 4.2.1 Visible to all

- Player name + avatar.
- IBAN ID (last 4 chars only for safety).
- Reputation score (0-100).
- Reputation tier badge.
- Active title.
- Empresa affiliation (current).
- Achievements count.
- Hours played (rounded).
- Days active (streak).

#### 4.2.2 Visible to friends only

- Specific empresa role.
- Recent achievements detail.
- Online status.

#### 4.2.3 Visible to empresa members only

- Salary tier.
- Performance metrics.
- Recent transactions internal.

#### 4.2.4 Always private (not visible)

- Personal IBAN balance.
- Personal transactions.
- Real-life identity.
- Email/discord (unless player chooses to share).

### 4.3 Reputation transparency

- Reputation score is **public**.
- Reputation **history graph** (rolling 90 days) visible.
- Reputation **detail breakdown** (quality avg, contracts completed, disputes) visible to friends.
- Specific bad reviews visible (oleada 2+ review system).

---

## 5. Market interactions

### 5.1 Job postings

> **Tablet Workplace app es el job board.**

#### 5.1.1 Posting a job
- Founder/Manager creates posting.
- Fields: role, salary, description, requirements (Tier minimums).
- Posting fee: 50 € flat (sink).
- Active 7 days default, renovable.

#### 5.1.2 Browsing jobs
- Filter by role, salary range, empresa, location.
- Sort by salary, recency, empresa reputation.
- Apply with one click.

#### 5.1.3 Application flow
- Apply → profile shared con founder.
- Founder reviews list of applicants.
- Accept/reject/interview (oleada 2+ interview chat optional).

### 5.2 Contract negotiations

> **B2B contracts negociados via Tablet Mercado app.**

#### 5.2.1 Contract template
- Items + quantities.
- Quality required.
- Lineage required (yes/no).
- Pricing.
- Duration.
- Delivery terms.
- Penalties for default.

#### 5.2.2 Negotiation flow
1. Buyer creates draft contract.
2. Sends to seller via Comm.
3. Seller can accept / counter-offer / reject.
4. Counter-offers iterate until agreement.
5. Both sign → contract activates with escrow.

#### 5.2.3 Contract templates library
- Players can save common contract templates.
- Quick re-use for repeat partners.

### 5.3 Market browser

> **Mercado app real-time market view.**

#### 5.3.1 What's listed
- All public buy/sell offers.
- All public job postings.
- All public B2B contract opportunities.
- Auctions (oleada 2+).

#### 5.3.2 Filters
- Item type / category.
- Quality grade.
- Price range.
- Lineage status.
- Distance/zone.
- Seller reputation tier.

#### 5.3.3 Saved searches + alerts
- Player saves search criteria.
- Tablet notifies when match appears.
- Useful: "alert me when wheat A grade < 45 €/saco".

---

## 6. Mentor system (oleada 2+)

### 6.1 Mentor application

- Player Tier 3+ can apply mentor.
- Reputation > 70 required.
- Application reviewed (oleada 2+ moderator).

### 6.2 Mentee matching

- Newbies (< 10h played) can request mentor.
- Tablet matches based on role interest + availability.

### 6.3 Mentor benefits

- 100 €/quincena bonus per active mentee (max 3 mentees).
- "Mentor" badge.
- Reputation +0.2 per successful mentee graduation (mentee reaches Tier 2).

### 6.4 Mentee benefits

- Mentor available DM 24h.
- Free quality A grain/flour 1 day for tutorials.
- Insurance: 1 free recovery from major mistake (mentor coverage).

---

## 7. Reviews / ratings (oleada 2+)

### 7.1 PED reviews

- After PED purchase, 5% chance to leave review.
- Star rating 1-5.
- Optional comment.
- Affects empresa reputation rolling.

### 7.2 B2B reviews

- After contract complete, both parties rate.
- Reputation impact mutual.
- Comments visible to public.

### 7.3 Anti-fake review measures

- Players cannot review own empresa.
- Same player → same empresa review limit: 1 per 30 days.
- Auto-flag suspicious patterns (review storms, brigading).
- Moderator review for disputes.

---

## 8. Server-wide events + community

### 8.1 Tipos de eventos servidor

#### 8.1.1 Recurring events
- **Bread Day** (annual): premium pan pricing × 1.20.
- **Founder's Day** (anniversary): -50% founding fees.
- **Quality Week** (quarterly): bonus rewards quality A.

#### 8.1.2 Special events admin-triggered
- **Festival caterings** (large NPC contracts available).
- **Crisis events** (oleada 2+ — e.g., "harvest failed, prices spike").
- **Holidays** (decoraciones MLO + special items).

#### 8.1.3 Player-initiated events (oleada 2+)
- Player empresa launch parties.
- Charity drives (donate to NPC food bank).
- Industry conventions (trade fairs).

### 8.2 Community spaces

#### 8.2.1 In-game (oleada 2+)
- Public squares en cada zona.
- Bulletin boards físicos para announcements.
- Event venues rentables.

#### 8.2.2 External (oleada 1)
- Discord server official.
- Forum / wiki.
- Server admin announcements.

### 8.3 Event notification

- Tablet notif para eventos opt-in.
- Calendar Tablet app shows upcoming events.
- Server welcome screen lists current events.

---

## 9. Disputes resolution governance

### 9.1 Disputes types

| Dispute | Common trigger |
|---|---|
| **Contract default** | Seller no entrega, buyer no paga |
| **Quality mismatch** | Promised A, delivered C |
| **Late delivery** | Beyond grace period |
| **Damaged cargo** | Driver/insurance issue |
| **Empresa equity dispute** | Co-founder disagreement |
| **Reputation attack** | False accusations |

### 9.2 Resolution flow

#### Step 1: Direct negotiation (24-48h)
- Tablet notifica ambas partes "Dispute open".
- Comm channel privado abierto entre partes.
- Encourage compromise (e.g., 50% refund).

#### Step 2: Arbitration (if step 1 fails)
- Either party escalates to arbitration.
- Tablet chooses 3 arbitros random (oleada 2+ — high-reputation players + admin).
- Arbitros review evidence (Tablet logs all relevant transactions).
- Vote majority: ruling binding.

#### Step 3: Admin override (rare)
- Server admin can override if arbitration corrupted.
- Logged + audited.

### 9.3 Penalties for fraud

- False dispute: -5 reputation + 100 € fine.
- Repeated false disputes: ban dispute system 30 days.
- Confirmed fraud: server-level ban possible.

### 9.4 Evidence available

> **All transactions immutable + auditable:**

- Bank transfers logs.
- Item movement logs (with lineage).
- Comm chat history (relevant only, privacy preserved).
- Contract terms (signed digital).
- Quality test scores at delivery.
- Driver GPS path (if logistics dispute).

### 9.5 Escrow refund mechanics (recap economy)

- Disputed escrows held until resolution.
- Resolution determines split: 100/0, 75/25, 50/50, 25/75, 0/100.
- Auto-refund if no contestation in 7 days.

---

## 10. Leaderboards servidor

### 10.1 Leaderboard categories

| Category | Metric | Reset cycle |
|---|---|---|
| **Top Earners** | IBAN balance | Permanent (lifetime) |
| **Top Empresas Revenue** | Empresa MRR | Monthly |
| **Top Empresas Profit** | Profit margin (min volume threshold) | Monthly |
| **Top Reputation** | Player reputation score | Permanent |
| **Top Quality** | Quality A rate (rolling 30d) | Rolling |
| **Most Active** | Hours played | Permanent |
| **Lineage Champions** | Lineage chains formed | Permanent |
| **Achievement Hunters** | Achievements count | Permanent |

### 10.2 Visibility

- Top 50 visible to all server.
- Top 10 highlighted on landing page Tablet.
- Player can see own rank (even if not top 50).

### 10.3 Privacy options

- Player can opt-out of leaderboards (privacy mode).
- Personal rank still visible to self.

### 10.4 Rewards leaderboard top

- **Top 1 monthly** any category: 5.000 € + special badge.
- **Top 10 monthly**: 1.000 € + badge.
- **Top 50**: 200 € + recognition.

---

## 11. Anti-patterns sociales

### 11.1 Griefing prevention

- ❌ **Combat tools:** none.
- ❌ **Theft mechanics:** none oleada 1 (oleada 2+ very limited).
- ❌ **Property destruction:** none.
- ❌ **Fake job postings:** flagged + fined.
- ❌ **Salary scams:** prevented (escrow on first paycheck).
- ❌ **Spam reports:** rate limited + tracked.

### 11.2 Harassment prevention

- ❌ **Stalking:** geo-location not shared without consent.
- ❌ **Doxxing:** real-life info sharing → permanent ban.
- ❌ **Slurs:** auto-flagged + moderator review.
- ❌ **Sexual content:** zero tolerance.

### 11.3 Healthy patterns

- ✅ Players encouraged to mute/block as needed.
- ✅ Reporting functional + responsive.
- ✅ Moderators visible + accountable.
- ✅ Rules transparent (Discord pinned + Tablet Help app).

---

## 12. Privacy + security

### 12.1 What's public by default

- Player name + avatar.
- IBAN last 4.
- Reputation tier + score.
- Empresa affiliation.
- Achievements count.

### 12.2 What's private by default

- Personal IBAN balance.
- Personal transactions.
- Real identity / email.
- Specific contracts (only parties involved).

### 12.3 Player privacy controls

- Privacy mode: hide from leaderboards.
- Friends only DM mode.
- Block list functionality.
- Empresa visibility opt-out (oleada 2+).

### 12.4 Data retention

- Active player data: indefinite.
- Inactive player data: 1 year retention then anonymize.
- Banned player data: anonymize but logs preserved (legal).

### 12.5 GDPR/data rights (real-world)

- Right to export personal data.
- Right to deletion (anonymize).
- Right to know data collected.
- Process documented Tablet Help app.

---

## 13. KPIs sociales

### 13.1 Engagement KPIs

| Metric | Healthy |
|---|---|
| **% players in empresa** (week 4+) | >50% |
| **Avg empresa size** | 4-7 members |
| **Avg friends per player** | 5-10 by week 4 |
| **DMs per active player per day** | 5-15 |
| **Empresa channel messages per day** | 10-30 per empresa |

### 13.2 Health KPIs

| Metric | Healthy |
|---|---|
| **Reports per active player per month** | <0.5 (low toxicity) |
| **Disputes per active contract** | <5% |
| **Banned accounts per month** | <0.5% of active |
| **Mutes per active player** | <2 (most don't need to mute) |

### 13.3 Cooperation KPIs

| Metric | Healthy |
|---|---|
| **Lineage chains active** | 2-5 per server |
| **B2B contracts signed per month** | 30-100+ per server |
| **Co-founded empresas %** | >25% of empresas have co-founders |
| **Mentor program participation** (oleada 2+) | >20% of newbies have mentor |

### 13.4 Community KPIs

| Metric | Healthy |
|---|---|
| **Server event participation** | >40% active players attend |
| **Discord activity ratio** | >30% in-game players also Discord |
| **Player-initiated events** (oleada 2+) | 1-3 per month per server |

---

## 14. Edge cases sociales

### 14.1 Empresa founder leaves server

- 14 days inactive → notif co-founders.
- 30 days → co-founders can vote to take ownership.
- 60 days → server auto-transfers ownership to highest-equity co-founder.
- 90 days no co-founders → empresa abandoned (recap economy §19.1.4).

### 14.2 Co-founder dispute deadlock

- Voting tie 50/50 → arbitration mandatory.
- Repeated deadlocks → forced buyback option (founder buys out co-founder at fair value).

### 14.3 Player banned mid-empresa

- Empresa: founder banned → co-founders take over (vote).
- Empresa: employee banned → fired automatically, severance NOT paid.
- Reputations transferred to "[BANNED USER]" placeholder for ledger consistency.

### 14.4 Mass exodus (multiple co-founders leave simultaneously)

- Empresa cash drained from severances → bankruptcy risk.
- Founder warned + given recovery options (asset liquidation).

### 14.5 Cross-server federation (oleada 3+)

- Players move between servers.
- Reputation portable (with verification).
- Empresa NOT portable (server-bound).
- Ledger anonymized across federation.

---

## 15. Roadmap + estado

### 15.1 Roadmap

#### Oleada 1 (T-0 — incluido)
- ✅ Empresa membership (founders, co-founders, employees).
- ✅ Equity structure básica.
- ✅ Comm app (DMs, channels, notifications).
- ✅ Friends list + public reputation.
- ✅ Job postings + applications.
- ✅ Contract negotiations Tablet.
- ✅ Market browser.
- ✅ Disputes resolution flow.
- ✅ Leaderboards basic.
- ✅ Anti-griefing patterns.
- ✅ Privacy + security.
- ✅ KPIs sociales.

#### Oleada 2 (T+6 meses)
- 🔜 Voice notes Comm.
- 🔜 Image attachments.
- 🔜 Mentor system formal.
- 🔜 Reviews/ratings sistema completo.
- 🔜 Player-initiated events.
- 🔜 In-game public squares.
- 🔜 Bulletin boards físicos.
- 🔜 Auctions Mercado.
- 🔜 Department channels Comm.
- 🔜 Formal voting empresa.

#### Oleada 3+ (T+12 meses)
- 🔜 Cross-server federation.
- 🔜 Multi-empresa player groups (conglomerates).
- 🔜 Player governance servidor (community moderators).
- 🔜 Cross-server tournaments.

### 15.2 Estado del documento

- **Versión:** 1.0 (firmable — completo, 15 secciones).
- **Próxima revisión:** evolución oleada 2 con voice + reviews + mentor.
- **Documento padre:** `gameplay/01_gameplay_loops.md` v1.0 (firmado).
- **Documento hermano:** `gameplay/02_progression_systems.md` v1.0 (firmado).
- **Documentos relacionados:**
  - Bible §10 — mecánica core.
  - `economy/01_economic_model.md` §9 — empresa system.
  - `technical/02_events_catalog.md` — eventos `comm:*`, `empresa:*`, `dispute:*`.

### 15.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Documento completo. 15 secciones cubriendo filosofía social, empresa membership, comm, friends, market interactions, mentor, reviews, eventos servidor, disputes, leaderboards, anti-patterns, privacy, KPIs, edge cases. **Firmable.** |

---

## Resumen ejecutivo del documento (cierre)

El **Social Features** es la infraestructura humana del producto Admirals:

- **Filosofía social:** comunicación contextual, cooperación recompensada, reputación pública, governance over violence, zero tolerance toxicidad.
- **Empresa membership:** founder + co-founders + managers + specialists + employees, equity structure clara, voting rights, dividend distribution.
- **Comm system:** DMs, empresa channels, market public, server announcements, persistent + searchable.
- **Friends list + public reputation:** profile transparente, history visible, controls privacy.
- **Market interactions:** job postings, contract negotiation Tablet, market browser con filtros + alerts.
- **Mentor system** (oleada 2+) para cohort newbies.
- **Reviews/ratings** (oleada 2+) PED + B2B + anti-fake measures.
- **Server-wide events** recurring + special + player-initiated.
- **Disputes resolution** 3-step (direct → arbitration → admin override) con evidence inmutable.
- **Leaderboards** múltiples categorías + opt-out privacy.
- **Anti-patterns** documentados (no combat, no theft, no harassment).
- **Privacy + security** GDPR-compliant, data retention.

> **Si en oleada 1 con 50 players activos durante 90 días: >50% in empresa por week 4, >25% empresas con co-founders, lineage chains activos 2-5, B2B contracts signed >30/mes, reportes <0.5 per player/mes, banned <0.5% activos/mes — habrá funcionado el modelo social Admirals.**

---

*"La economía es social. Sin community, los números no tienen alma."*

**FIN DEL DOCUMENTO `gameplay/03_social_features.md` v1.0**
