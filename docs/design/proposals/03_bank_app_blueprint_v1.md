# 🏦 SONAR Bank — App Blueprint v1 (PROPOSAL — pre-ADR)

> **Tipo:** PROPOSAL strategic blueprint. **NO es SSoT firmable** hasta ADR-017+ (palette amendment) + ADR-018+ (Bank surface model + sub-resources scope) + ADR-019+ (Phases roadmap). Founder review obligatorio antes de implementación.
> **Versión:** 1.0 (draft strategic — Cascade Sonnet 4.6 reasoning+research session 2026-05-05).
> **Audiencia:** Founder yaboula + AI agents próximas sesiones Phase A→E.
> **Estado:** 🟡 DRAFT review-pendiente.
> **Output este doc:** strategic blueprint, **0 código**, **0 commits**, **0 modificaciones SSoT existing**.
> **Mandato execution:** **app COMPLETA COMPLETA** ship única. Work troceado en **5 Phases horizontales técnicas A→E** con sub-tags `bank-phase-{a..e}-complete` per Phase + single-tag final `sonar-bank-v1` Phase E. **NO MVP iterativo.** **Tier 4 IN-SCOPE.**

> **Lectura previa obligatoria:**
> - `@docs/agents/00_BOOTSTRAP.md` v1.6 §1.3.1 + §5.5.
> - `@docs/design/00_PRODUCT_BIBLE.md` v1.5 §1 + §3 + §11 + §13.3.
> - `@docs/design/02_sonar_tablet.md` v1.3 §11 + IDENTITY V3 LOCK NOTICE.
> - `@docs/technical/04_api_contracts.md` v1.2 §3.1 (C001-C005 shipped, C003 DEFERRED S3).
> - `@docs/technical/03_db_schema.md` §4 (`sonar_bank_accounts` + `sonar_bank_movements` partitioned).
> - `@docs/technical/05_state_machines.md` §4.1 (FSM `escrow_lifecycle` 6 estados).
> - `@docs/economy/01_economic_model.md` §2.5 + §4.1 + §10.4 + §10.5.
> - `@docs/art/branding/01_brief_logo.md` v3 §4.1.
> - `@docs/planning/02_decision_log.md` ADR-011/012/013/014/015 + ADR-016 (part2).
> - `@progress/SPRINT_PLAN_S2.md` §1.3 + §2.1.
> - **Refs visuales founder:** `@d:/theBigProject/resources/sonar_bank/simple-ref-bank-ui/` (3 imágenes Fintrixity).

> **Quotes founder mandato (literal, sesión 2026-05-05):**
> - *"que va a superar NeedForScript Banking Script, y RX Scripts – Advanced Banking. y esta vez no quiero limites de rendimiento etc quiero superarlos en funciones y ui design"*
> - *"si llegamos a tener todos los funcionalidades que tienen estos dos grandes empresas mas el sistema que queremos aplicar de empresas y economia real de governement gestiona todas las empresas y los dueños gestionan sus empresas de aqui es nuestro punto de fuerza."*
> - *"el mejor UI posible algo de woooow, grafos, cartas, effectos visuales, animacion, algo que va a vivir en competencia 5 años mas."*
> - *"crearemos una app completa para banco el tablet sonar solo va a usar nuestra app de bank completamente o parcialmente."*
> - *"no hay strict color, tienes libertad completa, el 3 colores solo forman el color de theme."*
> - *"el upgrade no solo de UI pero también de backend y base de datos para poder llegar al nivel requerido."*
> - *"evita usar el full screen completo, interface grande pero no llega a full screen."*
> - *"no vamos a montar la mvp, nunca nunca, montamos la app completa completa, solo lo que podemos hacer es en partes."*
> - *"Vamos con todo."* (Tier 4 IN-SCOPE confirmation)

---

## 0. Resumen ejecutivo

### 0.1 Tres frases del blueprint

1. **SONAR Bank deja de ser "una app del Tablet"** y pasa a ser **producto financial-grade autónomo** (`sonar_bank_app` resource standalone — recommendation §7 Q4) responsive multi-viewport (window **1440×900 centered con backdrop dim + glassmorphism** + Tablet embed 1280×800 + lb-phone bridge 390×844), embebido por Tablet parcial o totalmente vía wrapper.
2. **El moat real vs NeedForScript / RX / ak47 / okokBanking NO es feature parity** (que también alcanzamos): es **el tejido Government NPC ↔ Empresas player-driven ↔ Players** integrado en una infrastructure financial única — Government entity con treasury-as-economy-orchestrator + dueños empresa self-serve multi-cuenta + B2B contracts/escrow/invoices + audit ledger regulatory-grade. **Ningún competidor FiveM tiene esto integrated. Eso es lo que vive 5 años.**
3. **Identity SONAR core preserved 100%** (dark canvas + Orange `#FF5100` brand + voz neutral premium-tech + sound canonical 5 SFX + Lucide bridge), pero **§8 propone ADR-017 amendment**: extended palette layer Bank-app-specific (data viz multi-series + semantic functional success/warn/error/info + brand gradients Orange→Pink/Amber + category color-coding) — necesario para Fintrixity-class wooow.

### 0.2 Roadmap proposal — Phases técnicas horizontales

| Phase | Foco | Sub-tag | Sesiones | Output |
|---|---|---|---|---|
| **A — Backend Foundation Complete** | DB extends + callbacks C001-C0XX (~30+) + FSMs (8+) + Bridges T2 + sub-resources skeleton (`sonar_companies`/`sonar_govt`/`sonar_loans`/`sonar_invest`) + audit module + state bags + events catalog v1.3 + rate limits | `bank-phase-a-complete` | 4-6 | Backend ALL functional, smoke backend ✅ |
| **B — Frontend Foundation + Design System** | Resource `sonar_bank_app` (Q4) + extended palette tokens (ADR-017) + component library (~25) + Recharts theme + Framer Motion presets + window shell 1440×900 + Tablet embed wrapper + lb-phone bridge slim + routing | `bank-phase-b-complete` | 2-3 | Design system shippable, 0 vistas |
| **C — Frontend Views Implementation** | TODAS vistas 16+: Dashboard / Cuentas / Movimientos / Wizard transfer / Receipt / Escrow hub / Insights / Beneficiaries / Recurring / Subscriptions / Loans / Cards / Limits / Multi-currency / **Govt console** / **Business dashboard** / Audit explorer / Notifications / Settings / Stocks T4 / Crypto T4 / ATM T4 | `bank-phase-c-complete` | 6-10 | App visualmente completa |
| **D — Polish + Integration** | Motion choreography full + sound triggers full + empty/error states personality + a11y AAA + perf p99 <16ms + integration `sonar_tablet` embed + lb-phone bridge | `bank-phase-d-complete` | 2-3 | App polished, smoke pre-ship |
| **E — Smoke + Regression + Ship** | Full smoke cumulative + Bank suite ~80+ steps + tag `sonar-bank-v1` + marketing brief | `sonar-bank-v1` (jugador-visible) | 1-2 | Ship-ready |

**Total estimado:** ~15-25 sesiones, ~60-100h. Phases secuenciales A→E, parallelizable INTRA-Phase entre AI agents.

### 0.3 Open questions count

**16 open questions** flagged 🔴 (sumario §7). Todas requieren green-light founder antes de promover blueprint a SSoT firmable + arrancar Phase A.

### 0.4 Decisiones top-3 inmediatas

1. 🔴 **Q1 Government entity:** ¿NPC system-managed (default recommended) o player-elected periódica? — Rec: NPC + flag `Config.Govt.Mode` para futuro player-elected.
2. 🔴 **Q4 Resource architecture:** ¿`sonar_bank_app` separado o sub-mount Tablet? — Rec: **separado** (autonomy + Tablet/lb-phone consumers vía bridge cross-resource + version independent).
3. 🔴 **Q12 Tier 4 confirmation:** confirmado "vamos con todo" — locked IN-SCOPE.

---

## 1. North Star

### 1.1 Tagline producto

> **SONAR Bank**
>
> EN: *"Production-grade financial infrastructure for roleplay servers."*
> ES: *"Cada eco financiero de tu servidor — registrado, trazable, gobernable."*
> Operacional: *"Where every transaction has lineage."*

**Voz canonical post-ADR-012 D3** (Vercel / Linear / Stripe Dashboard / Apple Pro):

| Atributo | Aplicación Bank |
|---|---|
| **Preciso** | "Saldo: 12.850,00 €" no "Tienes muchísimo dinero". |
| **Terse** | Confirmaciones máx 8 palabras: "Transferencia completada. Recibo guardado." |
| **Calmo** | Sin exclamations marketing. Sin emoji-exclamation. Tooltip neutro. |
| **Professional** | Spanish formal voseo neutro. English fallback Tebex marketing. |
| **Anti** | ❌ Cero arquetipo militar/submarino literal. ❌ Cero gen-Z. ❌ Cero comparaciones explícitas competitors en marketing. |

### 1.2 Posicionamiento estratégico

| Dimensión | NeedForScript / RX / ak47 / okokBanking | SONAR Bank |
|---|---|---|
| **Arquetipo** | Banking-as-a-feature (script Tebex aislado) | **Banking-as-infrastructure** (sub-system del ecosistema económico SONAR) |
| **Tier económico** | Player-centric | **Tri-layer:** Player ↔ Empresa player-driven ↔ Government NPC entity |
| **Moat features** | Feature-completeness | **Tejido empresas-government** + lineage trazable + audit explorer + B2B contracts FSM + subsidies G2C |
| **UI ambition** | Modern UI vendor-class | **Fintrixity / Stripe-Dashboard-class** + identity SONAR distinctive |
| **Integration** | Standalone bank script | Sub-resource integrado con `sonar_companies` + `sonar_invest` + `sonar_loans` + `sonar_govt` |
| **Lifecycle** | Compra → instalar → ship | Compra → ship → **economía vive 5 años con compliance audit + tax brackets + Govt oversight** |
| **Persistence** | Discord webhook logs | **Audit ledger regulatory-grade** in-DB partitioned + explorable player-side limited + admin full + immutable |
| **Multi-framework** | ESX/QBCore/QBox via bl_bridge / ak47_lib / native | **QBox T1** + **ESX/QBCore via Bridges Adapters T2 SONAR-own** (no third-party lib dep) |

### 1.3 Moat statement

> **El diferenciador SONAR Bank no es feature parity. El diferenciador es la integración nativa con un layer Government NPC + Empresas player-driven que ningún competidor FiveM tiene shipped.**

Cuando un servidor SONAR está running, **3 actores económicos simultáneos** transactan vía Bank:

1. **Players (B2C):** transfers entre players, recurring (alquiler/suscripciones), saldo personal, cards, ATM withdrawals, loans personales.
2. **Empresas player-driven (B2B + B2C):** multi-cuenta empresarial (operating + savings + escrow), payroll a employees, escrow contracts B2B, invoices, business credit lines, cash flow forecast, audit trail por empresa.
3. **Government NPC entity (B2G + G2C):** tax brackets auto-collect (sales / income / wealth / inheritance), subsidies G2C (unemployment / grants / pensions), fines (police / parking), public works treasury, audit oversight cross-empresa, sanctions (freeze account).

**Los 3 actores transactan en el mismo `sonar_bank_movements` partitioned table** con `category` ENUM extendido + `actor_role` discriminator nuevo (`player` / `empresa` / `govt`) + `regulatory_flags` BITMAP nuevo. Audit ledger captura TODO immutable.

**ak47 banking** tiene "wealth tax + admin city treasury panel" — pero es panel admin glorificado, no un Government entity transactional con FSM compliance + tax brackets evolutivos + subsidies G2C bidireccional. **RX Advanced** tiene "society accounts + business mgmt" — solo cash flows player↔society, sin Government layer. **NeedForScript / okokBanking / Wert** no tienen nada de esto.

**SONAR Bank vivirá 5 años porque cada server admin obtiene un sistema económico orgánico evolutivo, no un script estático.**

### 1.4 Principios non-negotiable del blueprint

| ID | Principio | Significado |
|---|---|---|
| **N1** | Identity SONAR core preserved | Dark canvas dominante + Orange `#FF5100` + White `#FAFAFA` + voz neutral + sound canonical + Lucide bridge. ADR-016 D1+D2+D4+D5+D6 mantained. |
| **N2** | Extended palette permitido (ADR-017 proposal) | Data viz multi-series + semantic functional + brand gradients + category colors allowed Bank-app-specific. **NO extiende otras apps Tablet** sin nuevo ADR. |
| **N3** | Backend-first + DB-as-truth | Toda transacción atómica via `sonar_bank_movements` + audit log + State Bags ephemeral solo UI sync (NO source of truth). |
| **N4** | FSMs formales para todo lifecycle | Cada entidad con status (loan/card/invoice/subscription/recurring/compliance) tiene FSM whitelisted transitions per `@docs/technical/05_state_machines.md`. |
| **N5** | Bridges Layer obligatorio T2 | Cero `exports['qb-*']` o `ESX.*` directo fuera `resources/sonar_bridges/adapters/*`. Money/items/identity/phone via `Bridges.Bank.*`. ADR-007 vinculante. |
| **N6** | Audit trail regulatory-grade | Cada money op + ownership change + permission grant + compliance flag escribe `sonar_audit_log` con actor_citizen_id + target + amount + concept + ts + correlation_id. |
| **N7** | Idempotencia + nonce por escritura | Toda callback escritura acepta `request_id` UUIDv4. Duplicates devuelven resultado original. Anti-replay via UNIQUE index. |
| **N8** | Rate limits por categoría | Read 30/10s + Write 10/60s + Heavy 1/24h + Govt-admin unlim. Per-citizen-id buckets. |
| **N9** | No PvP combat, no XP, no pay-to-win | Cards Black tier no son "premium paid" — son level orgánico ganado por wealth + tx_volume. |
| **N10** | NUI never-trusted | Cliente puede mentir. Validación crítica server-side. NUI envía intent, server resuelve estado. ADR-014. |

---

## 2. Competitive Analysis

### 2.1 Matrix — 50 features × 8 competidores

> **Leyenda:** ✅ shipped / ⚠️ partial / ❌ missing / 🔵 SONAR-only / 🟡 propose Phase A-E.
>
> **Competidores analizados:** NeedForScript (NFS) Banking + RX Advanced Banking + ak47 Banking + okokBanking + LB-Phone Wert Bank + Fleecanow (Venmo-class) + qb-management (society passthrough) + esx_society.
>
> **Sources research 2026-05-05:**
> - NFS: `https://needforscript.gitbook.io/needforscripts/our-scripts/banking-script` + `https://forum.cfx.re/t/needforscript-banking-script-with-loans-savings-cards-more/5268794`.
> - RX Advanced: `https://fivem.rxscripts.xyz/scripts/advanced-banking`.
> - ak47: `https://forum.cfx.re/t/advanced-banking-script-fivem-ak47-banking-esx-qb-qbx/5397367`.
> - okok: `https://forum.cfx.re/t/okokbanking-qbcore-esx-paid/4751646`.
> - Wert: `https://forum.cfx.re/t/wert-lb-phone-bank-application/5352327`.
> - Flee: `https://forum.cfx.re/t/fleecanow-lb-phone-banking-addon-app/5352337`.

#### 2.1.1 Account Management (10 features)

| # | Feature | NFS | RX | ak47 | okok | Wert | Flee | qb-mgr | esx_soc | **SONAR shipped** | **SONAR proposed** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F01 | Personal account auto-create on first join | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ❌ | ❌ | ✅ S1.1 starter 2.500€ | ✅ kept |
| F02 | Multiple personal accounts | ❌ | ✅ | ✅ | ❌ | ⚠️ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `type='personal_secondary'` |
| F03 | Society/Empresa accounts | ⚠️ | ✅ | ✅ | ✅ via qb-mgmt | ⚠️ | ❌ | ✅ | ✅ | ⚠️ DDL ready (`type='company'`) | 🟡 Phase A activación + governance roles |
| F04 | Shared accounts (multi-owner permissions) | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `sonar_bank_account_members` |
| F05 | Cooperative accounts (multi-empresa pool) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ⚠️ DDL ready | 🟡 Phase A activación (T4 in-scope) |
| F06 | Custom IBAN format | ❌ | ✅ | ⚠️ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ S1.1 `AD-XXXX-XXXX-XXXX` checksum | ✅ kept + IBAN copy/QR/share UI |
| F07 | Account closure (FSM lifecycle) | ❌ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | ⚠️ DDL `closed_at INT` | 🟡 Phase A FSM `account_lifecycle` |
| F08 | Account freeze (admin/police flag) | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A FSM state `frozen` + Govt trigger |
| F09 | Account interest (savings APY) | ❌ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `interest_rate_apy` + cron monthly |
| F10 | Account governance roles (owner/co-founder/manager/employee) | ❌ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `account_members.role ENUM` + ACL |

#### 2.1.2 Money Operations (8 features)

| # | Feature | NFS | RX | ak47 | okok | Wert | Flee | qb-mgr | esx_soc | **SONAR shipped** | **SONAR proposed** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F11 | Deposit (cash → account) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ⚠️ no UI flow | 🟡 Phase A C006 + ATM trigger |
| F12 | Withdraw (account → cash) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ⚠️ no UI flow | 🟡 Phase A C007 + ATM trigger |
| F13 | Transfer player→player online | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ S1.2 C002 | ✅ wizard ceremonial UI Phase C |
| F14 | Transfer player→offline | ⚠️ | ✅ | ✅ | ✅ via IBAN | ⚠️ | ✅ | ❌ | ❌ | ✅ S1.2 IBAN-targeted | ✅ kept |
| F15 | Transfer with concept/note | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ❌ | ❌ | ✅ S1.2 `concept` field | ✅ kept + emoji palette curated 12 |
| F16 | Saved beneficiaries (frequent recipients) | ✅ | ✅ | ⚠️ | ❌ | ⚠️ | ✅ | ❌ | ❌ | ❌ | 🟡 Phase A `sonar_bank_beneficiaries` + C008 CRUD |
| F17 | Quick amounts presets (10/50/100/500€) | ✅ | ✅ | ⚠️ | ⚠️ | ✅ | ✅ | ❌ | ❌ | ⚠️ partial UI | 🟡 Phase C wizard hero presets |
| F18 | Multi-currency transfers (FX) | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `sonar_bank_currencies` (T4 in-scope) |

#### 2.1.3 Card Management (7 features)

| # | Feature | NFS | RX | ak47 | okok | Wert | Flee | qb-mgr | esx_soc | **SONAR shipped** | **SONAR proposed** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F19 | Virtual card creation | ✅ | ✅ | ✅ | ❌ | ⚠️ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `sonar_bank_cards` + C015-C018 |
| F20 | Multiple cards per account | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A multi-card per IBAN |
| F21 | Card tiers (Basic/Gold/Platinum/Black) | ❌ | ⚠️ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A organic tiers via wealth+tx_volume (NO pay-to-win N9) |
| F22 | PIN code (custom + change) | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `pin_hash` SHA-256 + change flow |
| F23 | Card freeze (anti-theft) | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A FSM `card_lifecycle` state `frozen` |
| F24 | Physical card item (inventory) | ⚠️ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A integrated `sonar_inventory` `bank_card` (T4) |
| F25 | Card robbery / theft mechanic | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A integrated police+robbery (T4) |

#### 2.1.4 Loans + Savings (8 features)

| # | Feature | NFS | RX | ak47 | okok | Wert | Flee | qb-mgr | esx_soc | **SONAR shipped** | **SONAR proposed** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F26 | Personal loan instant (presets) | ✅ | ✅ | ✅ | ❌ | ⚠️ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `sonar_bank_loan_templates` + C019 |
| F27 | Personal loan custom request | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `loan_applications` + Govt underwrite C020 |
| F28 | Business loans (empresa credit lines) | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `sonar_loans` resource separate |
| F29 | Loan auto-repayment (cron schedule) | ✅ | ✅ | ✅ | ❌ | ⚠️ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A FSM `loan_lifecycle` + cron |
| F30 | Credit score (dynamic) | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `sonar_bank_credit_scores` + factors |
| F31 | Savings interest (compound APY) | ✅ | ✅ | ⚠️ | ❌ | ⚠️ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A cron monthly |
| F32 | Investment dashboard (stocks/crypto unified) | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `sonar_invest` resource (T4) |
| F33 | Subsidies G2C (govt → player grants) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔵 Phase A `sonar_govt_subsidies` |

#### 2.1.5 Empresa / Business (5 features) — **SONAR moat**

| # | Feature | NFS | RX | ak47 | okok | Wert | Flee | qb-mgr | esx_soc | **SONAR shipped** | **SONAR proposed** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F34 | Empresa multi-account (operating/savings/escrow) | ❌ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ⚠️ | ⚠️ | ❌ | 🟡 Phase A multi-account governance |
| F35 | Payroll (salary disbursement) | ❌ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ⚠️ boss menu | ⚠️ boss menu | ❌ | 🟡 Phase A C014 (already proposed §3.2 api_contracts) |
| F36 | B2B contracts with escrow lifecycle | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ⚠️ DDL escrow + FSM ready S1.3 | 🔵 Phase A UI escrow hub + invoice gen |
| F37 | Invoices generation (B2B + B2C) | ❌ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `sonar_bank_invoices` + PDF-class receipt |
| F38 | Treasury cash flow forecast | ❌ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔵 Phase A Insights view per empresa |

#### 2.1.6 Government / Compliance (8 features) — **SONAR moat puro**

| # | Feature | NFS | RX | ak47 | okok | Wert | Flee | qb-mgr | esx_soc | **SONAR shipped** | **SONAR proposed** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F39 | Tax brackets auto-collect (sales/income/wealth/inheritance) | ❌ | ⚠️ flat | ✅ wealth+income | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔵 Phase A `sonar_govt_tax_brackets` config + cron |
| F40 | Subsidies G2C disbursement (unemployment/grants/pensions) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔵 Phase A `sonar_govt_subsidies` + eligibility rules |
| F41 | Fines collected (police/parking/jail) | ⚠️ | ⚠️ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔵 Phase A integrated `sonar_police` event hooks |
| F42 | Government console (admin oversight) | ❌ | ⚠️ | ✅ admin city treasury | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔵 Phase A view `Govt Console` ACE-gated |
| F43 | Audit ledger explorer (player limited / admin full) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ⚠️ `sonar_audit_log` populated | 🔵 Phase A view `Audit Explorer` |
| F44 | Compliance flags / sanctions per account | ❌ | ❌ | ⚠️ police flag | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔵 Phase A `compliance_flags` + FSM |
| F45 | Regulatory reports auto (monthly tax summary) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔵 Phase A view `Regulatory Reports` empresa |
| F46 | Player-elected government (votación) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🔵 **Q1 — Phase A flag `Config.Govt.Mode`** |

#### 2.1.7 ATM / Physical (4 features)

| # | Feature | NFS | RX | ak47 | okok | Wert | Flee | qb-mgr | esx_soc | **SONAR shipped** | **SONAR proposed** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F47 | ATM physical (target prop) | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A integrated `ox_target` ATM (T4) |
| F48 | ATM minigame (PIN + camera + animations) | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A custom minigame React canvas opt (T4) |
| F49 | ATM card-swallow on wrong PIN (3 strikes) | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A FSM state `swallowed` (T4) |
| F50 | ATM withdrawal limits (session/daily) | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🟡 Phase A `sonar_bank_limits` enforce |

### 2.2 Cross-vertical inspiration (real banking apps 2026)

Cuando los competitors FiveM no llegan al "wooow" founder demanda, miramos al mundo real banking premium 2026:

| App | Feature inspiration → SONAR application |
|---|---|
| **Revolut** | Categorización auto transactions (Food/Transport/Salary/Tax) con icon+color → `sonar_bank_movements.category_visual` extends. Spending insights MoM cards. Subscription tracker auto-detect recurring. Vault sub-accounts (savings goals named). Card freeze toggle hero. |
| **N26** | Spaces (named savings sub-accounts goal-driven) → SONAR `sonar_bank_account_spaces` (saving goals nominados con progress bar). MoneyBeam (instant peer transfer) → wizard ceremonial. Insights forecasting. |
| **Monzo** | Pots (savings buckets within main, drag-drop UX) → integration con SONAR Spaces. Bills pots (separate money for bills + auto-pay) → recurring + reservations. Round-ups (round transactions) → opcional Phase A T4. |
| **Wise (TransferWise)** | Multi-currency wallet con conversion FX visible breakdown → `sonar_bank_currencies` T4 in-scope. Receipt formal class PDF download → `Receipt` view Phase C. |
| **Stripe Dashboard** | Payouts schedule + balance breakdown (available/pending) → empresa cash flow view. Customer ledger explorable. Reports CSV/PDF export → audit ledger explorer. Fraud Radar warnings → SONAR compliance_flags. |
| **Mercury** (B2B USA) | Treasury management forecast + AI categorization + auto-reconciliation → business dashboard `Treasury` tab. |
| **Cash App** | Hero amount input keypad iOS-class, ceremonial confirm → wizard transfer Phase C. |
| **Apple Card** | Color-spectrum spending visualization (categories rainbow donut con % weights) → Insights view donut Phase C, **EXTENDED PALETTE per ADR-017 D2 amendment.** |
| **Linear / Notion / Vercel Dashboard** | Window-class chrome (centered backdrop dim + glassmorphism + shadow), command palette (⌘K) → window shell Phase B + command palette opcional. |

### 2.3 Anti-patterns identified (lo que SONAR EVITA)

| Anti-pattern | Competidor(es) | Por qué malo | Solución SONAR |
|---|---|---|---|
| **Verde/rojo flat** sin context (`+$25 verde` / `-$5 rojo`) | NFS / RX / ak47 / Fintrixity refs | Daltónicos exclu. UI envejece (todos los banks 2010s). Sin info adicional. | Lucide icons `<ArrowUpRight Orange/>` `<ArrowDownLeft White/>` + amount weight + extended palette OPT-IN per category. ADR-017 §3. |
| **Modal stack abuso** (settings dentro modal dentro modal) | okokBanking, Wert | Navegación frágil, ESC ambiguo, hierarchy poco clara. | Side panels deslizables (Linear/Stripe pattern) + breadcrumb visible siempre. |
| **Discord webhook como única fuente audit** | NFS / RX / ak47 / okok | No queryable, no immutable, no regulatory-grade, depends Discord uptime. | `sonar_audit_log` partitioned in-DB + Discord webhook **ADICIONAL** opcional. |
| **Callback config UI in-game (admin panel monkey-patch)** | ak47 admin city treasury | Player con ACE admin puede romper economía con un click. No FSM enforce. | Config via `config.lua` + ACE-gated read-only views in-app. Cambios requieren server restart. |
| **"Open society dropdown" UI** (esx_society / qb-management classic) | esx_soc / qb-mgr | Society = un select element. Sin governance, sin multi-account, sin FSM. | Multi-account governance roles ENUM + ACL hooks + audit per role action. |
| **Hard-coded EUR currency** | NFS / okok / esx_soc | Imposible servidores no-EUR roleplay. Sin FX. | `sonar_bank_currencies` table + FX config + per-server primary currency convar (T4 in-scope). |
| **Cards = solo cosmético / sin item físico** | NFS partial | Roleplay shallow — card es solo icon UI sin consecuencias mundo. | Card item físico `sonar_inventory.bank_card` + theft + ATM swallow + freeze (T4 in-scope). |
| **Loans = single template fixed amount** | esx_soc / qb-mgr / NFS partial | Roleplay rígido — todos los loans son iguales. | Templates Govt-config (5+) + custom application form Govt-underwrite + credit_score affecting interest_rate. |
| **Marketing-first UI ("Trusted by Thousands! Join Us Today!")** | Fintrixity refs founder | Refs founder son DASHBOARDS de banco fintech, NO UI in-game roleplay. | Voz neutral premium-tech (N1) + zero promo cards in-app + zero comparaciones competitors. |
| **Light-theme support (toggle moon/sun)** | Fintrixity refs founder, NFS preview | Identity SONAR D1 dark-only. Light theme rompe gravitas + glow + glassmorphism. | **Dark-only forever.** Toggle moon/sun NO in-app. ADR-016 D1 mantained. |

### 2.4 Synthesis — qué hace ganar a SONAR

**Tabla resumen post-matrix:**

| Categoría | Feature parity (SONAR vs best competitor) | SONAR-only moat |
|---|---|---|
| **Account Management** | Match RX (10/10 features) | Cooperative pool empresa (T4) + governance roles + freeze via Govt-actor |
| **Money Operations** | Match RX (8/8) | Wizard ceremonial Phase C + emoji-palette concept |
| **Card Management** | Match ak47 (7/7) | Organic tier escalation (no pay-to-win) + integration `sonar_inventory` lineage |
| **Loans + Savings** | Match ak47 (8/8 + Tier-4 stocks/crypto) | **Subsidies G2C (F33 SONAR-only)** + business credit lines |
| **Empresa / Business** | Match RX partial (5/5) | **B2B contracts FSM + invoices + treasury forecast (3 SONAR-only)** |
| **Government / Compliance** | None match | **8/8 SONAR-only moat** — la categoría entera es diferenciador |
| **ATM / Physical** | Match ak47 (4/4 T4) | Integration `sonar_inventory` + audit trail |

**Total feature count proposed Phase A-E: 50 features. SONAR-only moat: 11 features.** 22% del producto es diferenciador puro vs todos los competidores.

---

## 3. Feature Taxonomy

> **Importante:** las 4 categorías abajo son **taxonomy conceptual** para descripción + priority debugging. **NO son tiers de roadmap incrementality.** Founder mandato 2026-05-05: *"no vamos a montar la mvp, nunca nunca, montamos la app completa completa"*. **TODAS las features ship juntas en Phase E.** Si scope cut posterior, esta taxonomy guía cuál cortar primero (T4 antes que T3 antes que T2 antes que T1).

### 3.1 Tier 1 — Foundation Premium (refacto + extends shipped MVP)

> Lo que un Bank financial-grade DEBE tener para no parecer un script de 50€. Match parity competitors basics + UX premium.

| ID | Feature | Origen | Phase ownership |
|---|---|---|---|
| T1.1 | **Dashboard Overview rebuilt** | Refacto BankOverview shipped S2.4 | Phase C |
| T1.2 | **Hero balance card** con sparkline 30d + delta % MoM + currency badge | Inspired Fintrixity ref + Revolut | Phase C |
| T1.3 | **Quick actions hero** (Transferir / Depositar / Retirar / Solicitar cobro) | Cash App pattern | Phase C |
| T1.4 | **Recent transactions list** (top 5) con avatares contraparte + drill-down | Stripe Dashboard | Phase C |
| T1.5 | **Wizard transfer ceremonial** 4 steps (Origen → Destino → Importe+Concepto → Confirmar) con animations + sound | SSoT §11.4 + Cash App + Apple Pay | Phase C |
| T1.6 | **Receipt PDF-class view** post-transfer (download / share IBAN+amount+timestamp+sello digital SONAR) | Wise + Stripe | Phase C |
| T1.7 | **History view C003 unlock** + filter pills (categoría, fecha, contraparte) + search + sort + virtual list 1000+ rows | SSoT §11 (deferred S3) | Phase C — **requires C003 unlock decisión Q3** |
| T1.8 | **Empty states personality** (no transactions yet / no beneficiaries / no escrows) | Linear / Notion | Phase D |
| T1.9 | **Error states personality** (insufficient funds + suggestion / IBAN invalid + format hint / rate limited + retry timer) | Stripe error UX | Phase D |
| T1.10 | **IBAN copy + QR + share** (clipboard + canvas QR + tooltip "Copied" + sound `console_tap`) | Wise + Revolut | Phase C |
| T1.11 | **Beneficiaries book** (saved frequent recipients + alias + favorite) | NFS + RX | Phase C |
| T1.12 | **Quick amounts presets** wizard step 3 (10/50/100/500/1000€ buttons + custom keypad) | Cash App | Phase C |
| T1.13 | **Concept emoji palette** curated 12 emojis (💰 salario, 🍕 food, 🚗 transporte, 🏠 alquiler, 🎁 regalo, ⚡ urgente, 📦 envío, 🎫 multa, 💼 trabajo, 🏥 médico, 🎉 ocio, ➕ otro) — opt-in | Revolut + Apple Cash | Phase C |

**Total Tier 1: 13 features.**

### 3.2 Tier 2 — Beyond Competitors (parity + extends)

> Features que competidores top tienen, SONAR las hace mejor. Match RX/ak47 + extends UX.

| ID | Feature | Origen | Phase ownership |
|---|---|---|---|
| T2.1 | **Multi-account scaffold** (cuenta personal + secundaria + savings + escrow + empresa) selector header | RX Advanced | Phase C |
| T2.2 | **Recurring transfers** (alquiler mensual, salario semanal, suscripciones) con cron schedule + FSM `recurring_lifecycle` | Monzo Bills + Wise scheduled | Phase C |
| T2.3 | **Standing orders** (one-time scheduled transfers, e.g., pagar el 15 del mes) | N26 + Wise | Phase C |
| T2.4 | **Direct debits** (autorización a empresa cobrar desde mi cuenta — alquiler / utilities) | Real banks SEPA | Phase C |
| T2.5 | **Categorización auto transactions** (icon+color por categoría detectada — salary/food/transport/rent/etc.) | Revolut + Apple Card | Phase A backend + C UI |
| T2.6 | **Subscription tracker** (auto-detect recurring patterns, alert on duplicate, cancel button hero) | Revolut + Monzo | Phase C |
| T2.7 | **Savings spaces / pots** (named goals con progress bar, drag-drop UX para mover dinero entre spaces) | N26 Spaces + Monzo Pots | Phase C |
| T2.8 | **Cards (virtual + tier escalation)** organic per wealth+tx_volume thresholds Basic→Gold→Platinum→Black + benefits per tier (limits + cashback + insurance opcional) | ak47 tiers | Phase A backend + C UI |
| T2.9 | **Cards physical item** integrated `sonar_inventory.bank_card` con theft+ATM swallow+freeze (T4 in-scope) | ak47 + RX | Phase A + C |
| T2.10 | **Limits config** (daily withdrawal / daily transfer / per-recipient / per-category) | RX + Real banks | Phase C |
| T2.11 | **Notifications cross-app** (transfer received / loan due / subscription renewed / Govt subsidy disbursed / compliance flag) integrated `sonar_tablet` notification panel + lb-phone slim | Real banks push | Phase D |
| T2.12 | **Multi-currency wallet** (T4 in-scope) — primary EUR + secundaria USD/GBP/AUD per server config + FX rates + conversion breakdown visible | Wise + Revolut | Phase A + C |
| T2.13 | **Pending transactions** (e.g., 24h SEPA-class delay opcional) + cancel during window | Real banks SEPA | Phase A + C |
| T2.14 | **Transaction dispute flow** (raise dispute on tx → Govt actor reviews → resolve refund/keep) | Stripe Disputes pattern | Phase A + C |

**Total Tier 2: 14 features.**

### 3.3 Tier 3 — SONAR Signature (moat puro)

> **Lo que SOLO SONAR tiene.** El layer Government NPC ↔ Empresas player-driven que ningún competidor FiveM tiene. **Eje del 5-year-survival**.

| ID | Feature | SONAR-only? | Phase ownership |
|---|---|---|---|
| T3.1 | **Government console** (admin-side ACE-gated panel oversight) — vista Govt actor sobre todas empresas + flags + treasury balance + tax collected MoM + subsidies disbursed MoM | 🔵 SONAR-only | Phase C |
| T3.2 | **Government NPC entity** transactional (treasury seed `AD-SYS0-0000-0001` + tax brackets cron + subsidies cron + audit trail tagged `actor_role='govt'`) | 🔵 SONAR-only | Phase A |
| T3.3 | **Tax brackets evolutivos** Govt-config (sales tax % / income tax brackets / wealth tax threshold / inheritance tax + collect cron) | 🔵 SONAR-only | Phase A |
| T3.4 | **Subsidies G2C** (unemployment grant / new-citizen welcome / business grant / pension elderly NPCs) Govt-config eligibility rules | 🔵 SONAR-only | Phase A |
| T3.5 | **Fines collected** integration `sonar_police` (speeding / parking / jail bail) → Govt treasury + audit trail | 🔵 SONAR-only | Phase A |
| T3.6 | **Audit ledger explorer view** (player limited a sus propias transacciones + relacionadas; admin full lateral cross-empresa) | 🔵 SONAR-only | Phase C |
| T3.7 | **Compliance flags + sanctions** (account flagged for anomaly → Govt review FSM `compliance_check_lifecycle` → freeze/unfreeze/sanction with fine) | 🔵 SONAR-only | Phase A + C |
| T3.8 | **Business owner dashboard** (multi-account empresa + payroll button + invoice generation + escrow contracts list FSM viz + treasury cash flow forecast 90d) | 🔵 SONAR-only | Phase C |
| T3.9 | **B2B invoices generation** (empresa → empresa or empresa → player) con due_date + auto-fee on overdue + PDF-class | ⚠️ partial RX, SONAR extends FSM | Phase A + C |
| T3.10 | **Escrow hub** (list active + create new + FSM viz + dispute trigger + release trigger) — UI sobre backend ya shipped S1.3 | 🔵 SONAR-only (UI new) | Phase C |
| T3.11 | **Treasury cash flow forecast** empresa-side (recurring + escrow pending + manual entries → 30/60/90d projection chart) | 🔵 SONAR-only | Phase C |
| T3.12 | **Regulatory reports auto** (monthly tax summary per empresa + audit log digest + downloadable) | 🔵 SONAR-only | Phase A + C |
| T3.13 | **Patterns / anomaly surfacing** (large unusual transfer + unusual destination IBAN + structuring detection → compliance flag autoraise) | 🔵 SONAR-only | Phase A |
| T3.14 | **Player-elected government opcional** (votación periódica 3-6 meses RP cycle, top voted player asume ACE `sonar.govt`, treasury powers transferred) — flag `Config.Govt.Mode='player_elected'` | 🔵 SONAR-only | Phase A flag day-1 + Phase C UI **Q1** |

**Total Tier 3: 14 features. 13 SONAR-only puro + 1 partial extends.** **Esto es el moat 5-year-survival.**

### 3.4 Tier 4 — Defer-evaluable IN-SCOPE (per founder "vamos con todo")

> Founder confirmó 2026-05-05 *"Vamos con todo"*. Tier-4 históricamente "evaluate-later" pero se promueve **IN-SCOPE Phase A-E**. Si scope cut tardío necesario, cortar T4 antes que T3.

| ID | Feature | Origen | Phase ownership |
|---|---|---|---|
| T4.1 | **Stocks dynamic market** (Fleeca / Maze / LSC / Ammu / Tequi-La) con volatility + bull/bear regimes + FOMO pumps + whale resistance + crashes + restructuring | ak47 | Phase A `sonar_invest` resource |
| T4.2 | **Crypto QubitCoin-class** dynamic market + wallet integrated + transfer between players | ak47 | Phase A `sonar_invest` |
| T4.3 | **ATM minigame** (PIN entry + camera angle + hand animations + card swallow on 3 strikes) | ak47 | Phase A custom Three.js? Phase C wiring |
| T4.4 | **Card robbery mechanic** (NPC pickpocket / player robbery / police chase) integrated `sonar_inventory.bank_card` item | NFS + RX + ak47 | Phase A + C |
| T4.5 | **Physical card item** `sonar_inventory.bank_card` con type ENUM + linked_iban + tier_at_issue | RX + ak47 | Phase A |
| T4.6 | **Cooperative shared accounts** (multi-empresa pool con governance vote majority required) | none competitor | Phase A `account_lifecycle.type='cooperative'` |
| T4.7 | **Round-ups** (round transactions to nearest €/5€/10€, save spare change to Space) | Monzo | Phase A + C |
| T4.8 | **Salary auto-deposit** (empresa payroll → employee accounts cron via FSM `payroll_lifecycle`) | RX partial | Phase A |
| T4.9 | **Crypto staking yield** (lock crypto X days for APY) opcional | none | Phase A `sonar_invest` |
| T4.10 | **Bank loyalty rewards** (cashback %, MAX cashback per month, tier-gated) opcional org | Apple Card | Phase A + C |

**Total Tier 4: 10 features. ALL IN-SCOPE per founder mandato.**

### 3.5 Total feature count

**Tier 1 (13) + Tier 2 (14) + Tier 3 (14) + Tier 4 (10) = 51 features.**

Ship target: **51 features integradas, 1 producto único, Phase E single-tag `sonar-bank-v1`.** No incremental MVP shipping.

---

## 3.5 App Surface Model

> **Constraint founder 2026-05-05:** *"crearemos una app completa para banco el tablet sonar solo va a usar nuestra app de bank completamente o parcialmente"* + *"evita usar el full screen completo, interface grande pero no llega a full screen"*.

### 3.5.1 Tres surfaces consumer

SONAR Bank tiene **un único build de NUI** que se renderiza en 3 surfaces distintas, cada una con shell específico:

#### Surface A — Standalone (canónico, default)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  Backdrop dim rgba(6,6,7,0.78) + backdrop-filter blur(8px) — 1920×1080 cover │
│                                                                              │
│             ┌──────────────────────────────────────────────────┐             │
│             │   Window 1440×900 centered                       │             │
│             │   border: 1px solid rgba(255,255,255,0.08)       │             │
│             │   border-radius: 16px                            │             │
│             │   box-shadow: 0 32px 80px rgba(0,0,0,0.6)        │             │
│             │   backdrop-filter glassmorphism blur(20px)       │             │
│             │                                                  │             │
│             │   ┌──────┬─────────────────────────────────────┐ │             │
│             │   │ Side │ Main content area                   │ │             │
│             │   │ 240  │ 1200×844 inner                       │ │             │
│             │   │ px   │                                     │ │             │
│             │   │ nav  │                                     │ │             │
│             │   │      │                                     │ │             │
│             │   └──────┴─────────────────────────────────────┘ │             │
│             │                                                  │             │
│             └──────────────────────────────────────────────────┘             │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                            ESC → close (animated fade-out)
```

- **Trigger:** keybind dedicated (default `M` for "Money" — configurable via convar `sonar_bank_keybind`) o command `/bank` o NUI message cross-resource desde Tablet "Open Bank App".
- **Dimensiones:** window 1440×900 centered en viewport, **NO full-bleed**.
- **Backdrop:** dim oscuro semi-transparente con blur subtle (game world visible behind, dimmed).
- **Glassmorphism subtle:** border + shadow + backdrop blur interior. Identity SONAR canon.
- **ESC handler:** fade-out window + lift backdrop + return cursor control to game.
- **Pause game?** No — game continues running (player puede ver world detrás dimmed). Per ADR-014 NUI never blocks input world unless explicit modal.
- **Mouse lock:** released (cursor visible interactuable).

#### Surface B — Tablet embed (parcial dentro Tablet shell)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│   Tablet device shell (1280×800 inner per ADR-016 + 02_sonar_tablet.md §1)   │
│                                                                              │
│   ┌──────┬───────────────────────────────────────────────────────────────┐   │
│   │ Side │ Active app: BankAppEmbedded                                   │   │
│   │ 80px │   bridge consumer NUI message → loads same Bank bundle       │   │
│   │ rail │   con surface='tablet' prop                                   │   │
│   │ apps │                                                               │   │
│   │      │   Layout responsive — sidebar Bank colapsada 60px (icons),    │   │
│   │      │   content area 1140×800 inner.                                │   │
│   │      │   Wizard steps mantienen ratio (3-step compact en lugar 4).   │   │
│   └──────┴───────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────┘
                Tablet wrapper handles ESC → BACK_TO_HOME (existing S2.3)
```

- **Trigger:** Tablet usuario selecciona Bank app icon en Bridge home.
- **Dimensiones:** ratio interior Tablet 1280×800 (constrained por device shell).
- **Sidebar:** 80→60px collapsed icons-only (Tablet ya tiene sidebar own).
- **Layout adaptation:** Bank app autodetecta `surface='tablet'` prop → sidebar collapsed + wizard 3-step compact + dashboard cards 2-column en lugar 3-column.
- **Identity:** mismo bundle JS/CSS, mismo design system, mismo identity. SOLO layout responsive cambia.

#### Surface C — lb-phone bridge slim (mobile portrait)

```
┌────────────────┐
│  lb-phone     │
│  shell 390px  │
│  ┌──────────┐ │
│  │ Status   │ │
│  │ bar      │ │
│  ├──────────┤ │
│  │ Bank     │ │
│  │ app      │ │
│  │ slim     │ │
│  │ portrait │ │
│  │ 358×704  │ │
│  │ inner    │ │
│  │          │ │
│  │ Bottom   │ │
│  │ tab nav  │ │
│  │ (no      │ │
│  │ sidebar) │ │
│  └──────────┘ │
└────────────────┘
```

- **Trigger:** lb-phone home → Bank app icon (registered via lb-phone API per their docs).
- **Dimensiones:** 358×704 inner (390×844 lb-phone shell).
- **Layout adaptation:** Bank app autodetecta `surface='phone'` prop → sidebar→bottom tab nav 5 tabs (Home/Cuentas/Wizard/Insights/Más) + dashboard 1-column stack + wizard 3-step + receipt full-bleed inside phone shell.
- **Feature subset:** mobile-class subset — Dashboard, Cuentas (read), Wizard transfer, History (read), Notifications, Cards (freeze toggle). No Govt console + no Business dashboard + no Audit explorer (mobile UX no apto + ACE-gating likely false).

### 3.5.2 Bridge mechanism cross-resource

```
┌─────────────────────┐                       ┌──────────────────────────┐
│  sonar_tablet       │                       │  sonar_bank_app          │
│  (existing)         │ ─── NUI msg ────────► │  (NEW resource — Q4)     │
│                     │   'bank:open' +       │                          │
│  Bridge home App    │   surface='tablet'    │  React app build single, │
│  → Bank icon click  │   citizen_id          │  consumes                │
└─────────────────────┘                       │  surface prop, renders   │
                                              │  shell adaptation        │
                                              └──────────────────────────┘

┌─────────────────────┐                       ┌──────────────────────────┐
│  lb-phone           │                       │  sonar_bank_app          │
│  (third-party)      │ ─── NUI msg ────────► │                          │
│  registered Bank    │   'bank:open' +       │  same bundle, surface=   │
│  app icon           │   surface='phone'     │  'phone' prop, mobile    │
└─────────────────────┘                       │  shell adaptation        │
                                              └──────────────────────────┘

┌─────────────────────┐
│  keybind 'M' or     │
│  /bank command     │ ──► RegisterCommand → SetNuiFocus(true,true) → 
│  (standalone)       │     SendNUIMessage('bank:open', surface='standalone')
└─────────────────────┘
```

**Implementation note Phase A:** `sonar_bank_app` resource registra **3 trigger paths** que apuntan al mismo bundle, diferenciado solo por payload `surface` prop. **Single bundle, 3 chrome shells.** Bundle size target: **<1.2MB gzip** (sin hard cap pero p99 esperado).

### 3.5.3 Identity surface-agnostic

| Aspecto | Standalone | Tablet embed | lb-phone bridge |
|---|---|---|---|
| **Theme tokens** | Same (canonical 3 + extended ADR-017) | Same | Same |
| **Voz copy** | Same (Spanish neutral premium-tech) | Same | Same |
| **Sound canonical** | All 5 SFX | All 5 SFX | Subset 3 (`console_tap` + `layer_dive` + `panel_open`) — phone speaker quality |
| **Motion** | Full Framer Motion choreography | Full | Reduced (battery + mobile fps) |
| **Lucide icons** | Lucide bridge S2-S3 → 8 abstract custom S3+ | Same | Same |
| **Glassmorphism** | Subtle window borders | None (Tablet shell own) | None (lb-phone shell own) |
| **Backdrop dim** | Yes (1920×1080 cover) | No (Tablet handles) | No (lb-phone handles) |

### 3.5.4 Dimensiones rationale

| Surface | Width × Height | Rationale |
|---|---|---|
| Standalone window | 1440×900 (16:10) | Linear/Stripe-Dashboard-class. Centered con margins ~240+240px en 1920px viewport. NOT full-bleed (founder constraint). |
| Tablet inner | 1140×800 (effective post-sidebar Tablet) | Constrained Tablet device shell 1280×800 menos sidebar 80→60px Tablet rail + 80px Bank sidebar collapsed = ~1140 inner. |
| lb-phone inner | 358×704 portrait | Constrained lb-phone shell 390×844 menos status bar + bottom safe area. |

---

## 4. UI/UX Design Proposal

> Esta sección define **10 vistas wireframes ASCII** + voice copy 30+ samples + motion choreography + sound triggers per state + glassmorphism/glow rules. **Inspiration refs Fintrixity** (`@d:/theBigProject/resources/sonar_bank/simple-ref-bank-ui/`) + Linear/Stripe Dashboard/Vercel + Revolut/N26/Apple Card.

### 4.1 Information Architecture (IA)

#### 4.1.1 Sidebar canonical 240px (standalone) / 60px collapsed (Tablet/phone)

```
SONAR Bank — Sidebar Standalone 240px

┌───────────────────────────────┐
│ [LOGO 32x32] SONAR Bank       │  Header brand
│             v1.0              │  Version subtle
├───────────────────────────────┤
│                               │
│ ▼ Personal                    │  Section title
│   🏠  Resumen                ←│  Active state Orange underline
│   📊  Movimientos             │  Lucide bridge → custom S3+
│   ↗   Transferir              │
│   💳  Mis tarjetas            │
│   ⏰  Recurrentes              │
│   👥  Beneficiarios           │
│   💰  Spaces & Ahorros        │
│   📈  Insights                │
│                               │
│ ▼ Empresarial                 │  Conditional — solo si player es founder/manager empresa
│   🏢  Mi empresa              │
│   📃  Facturas                │
│   🔒  Escrows                 │
│   👷  Nóminas                 │
│   💼  Treasury                │
│                               │
│ ▼ Inversiones (T4)            │
│   📊  Stocks                  │
│   ₿   Crypto                  │
│   💎  Loans                   │
│                               │
│ ▼ Government (ACE-gated)      │  Solo si ACE `sonar.govt`
│   🏛   Govt Console           │
│   📋  Audit Explorer          │
│   📜  Reports                 │
│   ⚖   Compliance              │
│                               │
├───────────────────────────────┤
│ 👤 Marcos Admiral             │  Footer profile
│    AD-1A2B-3C4D-5E6F          │  IBAN compact + copy on click
│ ⚙   Ajustes                   │
│ 🚪 Cerrar                     │
└───────────────────────────────┘
```

**Rules sidebar:**
- Section titles `text-[10px] uppercase tracking-widest text-sonar-white/40` (idéntico tablet pattern existing).
- Active item: `text-sonar-orange` + Orange underline 2px bottom + glow subtle.
- Hover: `text-sonar-white` (de `text-sonar-white/60`).
- Icons Lucide bridge S2-S3 → custom 8 abstract S3+ replacement.
- Conditional sections (Empresarial / Govt) solo render si player tiene role/ACE — invisible if not.
- Bottom profile: avatar 24x24 (Lucide `User` placeholder hasta avatar system Oleada-2) + nombre + IBAN compact + ⚙ Ajustes + 🚪 Cerrar (window standalone) o 🚪 Volver (Tablet/phone embed → BACK_TO_HOME existing).

#### 4.1.2 Routing tree

```
/dashboard                                — Default landing (Surface A/B/C)
/cuentas
  /cuentas/:iban                          — Drill multi-account
  /cuentas/:iban/spaces                   — Spaces sub-page
  /cuentas/:iban/spaces/:space_id         — Space drill
/movimientos                              — History C003-powered
  /movimientos/:movement_id               — Drill modal o full-page
/transferir                               — Wizard 4-step
  /transferir/wizard                      — same component
  /transferir/recibo/:movement_id         — Receipt post-transfer
/tarjetas
  /tarjetas/:card_id                      — Card detail + freeze toggle + PIN change
/recurrentes
  /recurrentes/nueva                      — Wizard recurring
  /recurrentes/:recurring_id              — Edit
/beneficiarios
  /beneficiarios/nuevo
/spaces                                    — All Spaces cross-account
  /spaces/:space_id
/insights
/empresa/:company_id                      — Conditional founder/manager
  /empresa/:id/cuentas
  /empresa/:id/facturas
  /empresa/:id/facturas/nueva
  /empresa/:id/escrows
  /empresa/:id/escrows/:escrow_id
  /empresa/:id/nominas
  /empresa/:id/treasury
/invest                                   — T4
  /invest/stocks
  /invest/stocks/:ticker
  /invest/crypto
  /invest/loans
/govt                                     — ACE-gated
  /govt/console
  /govt/audit
  /govt/audit/:movement_id
  /govt/reports
  /govt/compliance
  /govt/compliance/:flag_id
/ajustes
  /ajustes/limites
  /ajustes/notificaciones
  /ajustes/seguridad
```

### 4.2 Voice copy samples (30+)

#### 4.2.1 Confirmaciones operacionales (Spanish neutral premium-tech)

| Estado | Copy ES | Copy EN fallback |
|---|---|---|
| Transferencia confirmada | "Transferencia completada. Recibo guardado." | "Transfer completed. Receipt saved." |
| Beneficiario añadido | "Beneficiario guardado." | "Recipient saved." |
| Card congelada | "Tarjeta congelada. Bloqueada para uso." | "Card frozen. Blocked from use." |
| Card reactivada | "Tarjeta reactivada." | "Card unfrozen." |
| Recurrente programada | "Pago recurrente programado para el día {date}." | "Recurring payment scheduled for {date}." |
| Loan aprobada | "Préstamo aprobado. {amount}€ ingresados en tu cuenta." | "Loan approved. {amount}€ deposited." |
| Loan denegada | "Préstamo denegado por gobierno. Motivo: {reason}." | "Loan denied by government. Reason: {reason}." |
| Subsidy disbursed | "Subvención recibida del gobierno: {amount}€ ({reason})." | "Government grant received: {amount}€ ({reason})." |
| Escrow creado | "Escrow bloqueado. Fondos retenidos hasta liberación." | "Escrow locked. Funds held pending release." |
| Compliance flag raised | "Tu cuenta está bajo revisión gubernamental." | "Your account is under government review." |

#### 4.2.2 Errors (con suggestion, NO regaño)

| Error | Copy ES | Copy EN |
|---|---|---|
| Insufficient funds | "Saldo insuficiente. Necesitas {missing}€ adicionales." | "Insufficient funds. {missing}€ short." |
| IBAN invalid | "IBAN no reconocido. Formato: AD-XXXX-XXXX-XXXX." | "IBAN unrecognized. Format: AD-XXXX-XXXX-XXXX." |
| Self-transfer attempted | "No puedes transferir a tu propia cuenta. Usa Spaces." | "Cannot transfer to your own account. Use Spaces." |
| Rate limited | "Demasiadas operaciones. Reintenta en {seconds}s." | "Too many operations. Retry in {seconds}s." |
| Card frozen attempted use | "Tarjeta congelada. Reactivar desde Mis Tarjetas." | "Card frozen. Unfreeze from My Cards." |
| Network timeout | "Sin respuesta del servidor. Reintenta." | "Server unresponsive. Retry." |
| Govt sanction freeze | "Cuenta bloqueada por gobierno. Consulta Compliance." | "Account frozen by government. See Compliance." |

#### 4.2.3 Empty states (con personalidad calmada, NO marketing)

| Vista | Copy ES |
|---|---|
| No transactions yet | "Tu primer movimiento aparecerá aquí." |
| No beneficiaries yet | "Aún no tienes contactos guardados. Añade uno desde Transferir." |
| No escrows yet | "Sin escrows activos. Los contratos B2B firmados aparecen aquí." |
| No subsidies eligible | "No cumples requisitos para subvenciones actuales." |
| No notifications | "Todo al día." |
| No cards yet | "Solicita tu primera tarjeta desde Cuentas." |
| No spaces yet | "Crea un Space para separar tus ahorros con un objetivo." |
| Insights — no data 30d | "Insights aparecerán cuando tengas 30 días de movimientos." |

#### 4.2.4 Onboarding first-time

| Step | Copy ES |
|---|---|
| Welcome | "Bienvenido a SONAR Bank, {nombre}." |
| Starter balance explain | "Te abonamos 2.500€ de saldo inicial para empezar." |
| First IBAN reveal | "Tu IBAN: {iban}. Cópialo o escanéalo desde QR." |
| Tour suggestion | "Visita la pestaña Insights cuando hayas hecho tus primeros movimientos." |

#### 4.2.5 Government / regulatory (terse + neutro)

| Tooltip / context | Copy ES |
|---|---|
| Tax bracket explain | "Income tax {rate}% sobre {threshold}€+. Recolectado mensualmente." |
| Subsidy eligibility | "Eligible para subvención por desempleo: {amount}€ mensuales." |
| Audit log entry | "Acción registrada: {action} por {actor} el {ts}." |
| Compliance flag tooltip | "Esta cuenta tiene una revisión gubernamental en curso." |

### 4.3 Wireframe 1 — Dashboard standalone (1440×900)

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  ╔══════════════════════════════════════════════════════════════════════════════════════════════╗    │
│  ║ SONAR Bank — Window 1440×900 — backdrop dim+blur+border+shadow                               ║    │
│  ╚══════════════════════════════════════════════════════════════════════════════════════════════╝    │
│  ┌──────────────┬───────────────────────────────────────────────────────────────────────────────┐    │
│  │ SIDEBAR 240  │ HEADER 64px — Resumen / Buscar (⌘K) / Notif (3) / Profile                    │    │
│  │              ├───────────────────────────────────────────────────────────────────────────────┤    │
│  │ Personal     │                                                                               │    │
│  │ ▶ Resumen ◀  │   ┌────────────────────────────────────────────────┐  ┌───────────────────┐  │    │
│  │   Movimien.. │   │ HERO BALANCE CARD (560×220) gradient subtle    │  │ QUICK ACTIONS     │  │    │
│  │   Transferir │   │                                                │  │ (380×220)         │  │    │
│  │   Tarjetas   │   │ Saldo total                                    │  │                   │  │    │
│  │   Recurren.. │   │ €12.850,00          ↗ 2.92% MoM ▲              │  │ [↗ Transferir]    │  │    │
│  │   Benefic..  │   │ ▁▂▃▅▆▇█▇▆▅▃▂▁ ▂▃▅▇█  (sparkline 30d)          │  │ [⬇ Depositar]     │  │    │
│  │   Spaces     │   │ AD-1A2B-3C4D-5E6F  📋 [QR]                    │  │ [⬆ Retirar]       │  │    │
│  │   Insights   │   │                                                │  │ [📩 Solicitar]    │  │    │
│  │              │   │  Cuenta personal · EUR · activa                │  │                   │  │    │
│  │ Empresarial  │   └────────────────────────────────────────────────┘  └───────────────────┘  │    │
│  │   Mi empresa │                                                                               │    │
│  │   Facturas   │   ┌─────────────────────────────────────────────────────────────────────┐   │    │
│  │   Escrows    │   │ INSIGHTS STRIP (960×120)                                            │   │    │
│  │   Nóminas    │   │ ┌────────────┬────────────┬────────────┬────────────┐              │   │    │
│  │   Treasury   │   │ │ Ingresos   │ Gastos     │ Ahorros    │ Forecast   │              │   │    │
│  │              │   │ │ 4.520€     │ 1.670€     │ +12.5%     │ 14.3K€ 30d │              │   │    │
│  │ Inversiones  │   │ │ ↗ +8% MoM  │ ↘ -3% MoM  │ Goal 65%   │ proyección │              │   │    │
│  │   Stocks     │   │ └────────────┴────────────┴────────────┴────────────┘              │   │    │
│  │   Crypto     │   └─────────────────────────────────────────────────────────────────────┘   │    │
│  │   Loans      │                                                                               │    │
│  │              │   ┌──────────────────────────────────────────┐  ┌──────────────────────┐    │    │
│  │ Govt (ACE)   │   │ RECENT TRANSACTIONS (560×360)            │  │ BENEFICIARIES (380x  │    │    │
│  │   Console    │   │ Hoy                                       │  │ 360) Top 4 favs +    │    │    │
│  │   Audit      │   │ 🍕 Pizza Place LS    -€18,50  📍cat: Food │  │ "Ver todos"          │    │    │
│  │   Reports    │   │ Ayer                                      │  │ 👤 Lucas Bennett ⭐  │    │    │
│  │   Complian.. │   │ 💼 ACME Corp Salary +€2.400  📍 Salary    │  │ 👤 Google Drive      │    │    │
│  │              │   │ 📅 Hace 3 días                            │  │ 👤 Nike Store        │    │    │
│  ├──────────────┤   │ 🎫 Multa LSPD       -€150    📍 Tax       │  │ 👤 Granja Valle      │    │    │
│  │ 👤 Marcos    │   │ 📦 Amazon ENVIO     -€45,00  📍 Shopping  │  │ + Añadir beneficiar  │    │    │
│  │ AD-1A2B...📋 │   │ ────────────────────────────────────────── │  │                      │    │    │
│  │ ⚙ Ajustes    │   │ Ver todo el historial →                   │  │                      │    │    │
│  │ 🚪 Cerrar    │   └──────────────────────────────────────────┘  └──────────────────────┘    │    │
│  └──────────────┴───────────────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Notes wireframe 1:**
- Hero balance card: gradient subtle Orange→Black bottom (extended palette ADR-017 D2). Sparkline Recharts area chart 30d. MoM delta con `<TrendingUp Orange/>` icon (NO verde flat).
- Quick actions: 4 vertical-stack buttons, primary "Transferir" Orange bg, others outline white/10.
- Insights strip: 4 mini stat cards 240×120 cada uno, KPIs MoM con icons + trend.
- Recent transactions: agrupadas por día (Hoy / Ayer / Hace 3 días / etc.), categoría con emoji + label small + amount weight bold + icon `<ArrowUpRight Orange/>` o `<ArrowDownLeft white/>` según signed.
- Beneficiaries: top 4 favoritos con avatar + name + alias. ⭐ favorite indicator. CTA "+ Añadir beneficiario" outline ghost.

### 4.4 Wireframe 2 — Wizard transfer 4-step ceremonial

```
STEP 1 — Origen (auto-skip si solo 1 cuenta)
┌──────────────────────────────────────────────────────────────────────────────┐
│ ←  Transferir                                          Paso 1 de 4 ●○○○      │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ¿Desde qué cuenta?                                                         │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │ ⦿ Cuenta personal Marcos                                             │  │
│   │   AD-1A2B-3C4D-5E6F · €12.850,00 · activa                            │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │ ○ Cuenta empresa Granja del Valle                                    │  │
│   │   AD-7G8H-9I0J-1K2L · €45.230,00 · empresa (manager)                 │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │ ○ Space "Coche nuevo"                                                │  │
│   │   AD-3M4N-5O6P-7Q8R · €5.200,00 · savings goal 65%                   │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│                                                              [Continuar →]   │
└──────────────────────────────────────────────────────────────────────────────┘

STEP 2 — Destino
┌──────────────────────────────────────────────────────────────────────────────┐
│ ←  Transferir                                          Paso 2 de 4 ●●○○      │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ¿A quién?                                                                  │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │ 🔍  Buscar nombre, IBAN o alias...                                   │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│   Tus contactos                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │ ⭐ Lucas Bennett             AD-2A4B-6C8D-0E2F · "Lucas alquiler"     │  │
│   │    Pagas a Lucas frecuentemente · última: hace 2 días                │  │
│   ├──────────────────────────────────────────────────────────────────────┤  │
│   │    Granja del Valle (empresa) AD-7G8H-9I0J-1K2L · "Compras semilla"  │  │
│   │    Última transferencia: hace 1 semana                               │  │
│   ├──────────────────────────────────────────────────────────────────────┤  │
│   │    + Pagar a IBAN nuevo                                              │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│                                                  [← Atrás]    [Continuar →]  │
└──────────────────────────────────────────────────────────────────────────────┘

STEP 3 — Importe + Concepto
┌──────────────────────────────────────────────────────────────────────────────┐
│ ←  Transferir                                          Paso 3 de 4 ●●●○      │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ¿Cuánto?                                                                   │
│                                                                              │
│                                                                              │
│                          ┌──────────────────┐                                │
│                          │    €  150,00     │  hero amount input             │
│                          └──────────────────┘                                │
│                          tipografía 64px geométrica                          │
│                                                                              │
│   Presets    [10€]  [50€]  [100€]  [500€]  [1000€]                          │
│                                                                              │
│   Saldo disponible tras: €12.700,00                                          │
│                                                                              │
│   Concepto (opcional)                                                        │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │ Pago alquiler octubre                                          🍕💼🏠 │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│   Emoji palette: 💰🍕🚗🏠🎁⚡📦🎫💼🏥🎉➕                                     │
│                                                                              │
│                                                  [← Atrás]    [Continuar →]  │
└──────────────────────────────────────────────────────────────────────────────┘

STEP 4 — Confirmar (ceremonial)
┌──────────────────────────────────────────────────────────────────────────────┐
│ ←  Transferir                                          Paso 4 de 4 ●●●●      │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Revisa y confirma                                                          │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │ ↗ Transferencia                                                       │  │
│   │                                                                      │  │
│   │   De      Cuenta personal Marcos     AD-1A2B-3C4D-5E6F               │  │
│   │   A       Lucas Bennett ⭐           AD-2A4B-6C8D-0E2F               │  │
│   │   Importe                                              €  150,00     │  │
│   │   Comisión (transfer interno)                          €    0,00     │  │
│   │   ─────────────────────────────────────────────────────────────────  │  │
│   │   TOTAL                                                €  150,00     │  │
│   │                                                                      │  │
│   │   Concepto      Pago alquiler octubre 🏠                             │  │
│   │   Programada    Inmediatamente                                       │  │
│   │                                                                      │  │
│   │   Saldo origen tras transferencia       €12.700,00                   │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│   Botón hold-to-confirm (1.2s ceremonial press):                             │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │              ▶▶▶ Mantén pulsado para confirmar ▶▶▶                  │  │
│   │              ▰▰▰▰▰▰▰▰▱▱▱▱▱▱▱▱▱▱  56%  (durante hold)                │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│                                                                [← Atrás]    │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Motion + Sound triggers wizard:**
- Step transition (Continuar →): `layer_dive` SFX + slide-x +400ms ease-out + opacity fade.
- Step back (← Atrás): same reversed.
- Hero amount input: keypad press → `console_tap` SFX per digit. Number tween animation Framer counter.
- Confirm hold release on full: `depth_press` SFX (Apple Touch ID success class) + Bright pulse glow Orange + transition to Receipt view.
- Confirm hold release pre-full (cancel): `panel_open` reversed soft.
- Insufficient funds detected step 3: shake horizontal subtle ±4px + Orange border glow temporary 800ms.

### 4.5 Wireframe 3 — Receipt PDF-class post-transfer

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ←  Volver al resumen                                                         │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                                                                              │
│       ┌──────────────────────────────────────────────────────────┐          │
│       │                                                          │          │
│       │   ╭──────────────────────────────────────────────╮        │          │
│       │   │  ✓  Transferencia completada                │        │          │
│       │   ╰──────────────────────────────────────────────╯        │          │
│       │                                                          │          │
│       │   €  150,00                                              │          │
│       │   tipografía 56px hero                                   │          │
│       │                                                          │          │
│       │   A    Lucas Bennett                                     │          │
│       │        AD-2A4B-6C8D-0E2F                                 │          │
│       │                                                          │          │
│       │   ────────────────────────────────────────────           │          │
│       │   Concepto      Pago alquiler octubre 🏠                 │          │
│       │   Fecha         05 May 2026 · 20:48 UTC+02               │          │
│       │   Reference     SBNK-AB12-CD34-EF56-7890                 │          │
│       │   Categoría     🏠 Vivienda                              │          │
│       │   ────────────────────────────────────────────           │          │
│       │                                                          │          │
│       │   Sello digital SONAR ✦                                  │          │
│       │   Hash SHA-256: a3f2c1...e4b9 (truncated)                │          │
│       │   Verificable en Audit Explorer                          │          │
│       │                                                          │          │
│       │   ┌─────────────────┬──────────────────┐                 │          │
│       │   │  📋 Copiar IBAN │  📥 Descargar PDF │                 │          │
│       │   ├─────────────────┼──────────────────┤                 │          │
│       │   │  📤 Compartir   │  ⏪ Otra transfer │                 │          │
│       │   └─────────────────┴──────────────────┘                 │          │
│       │                                                          │          │
│       └──────────────────────────────────────────────────────────┘          │
│                                                                              │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Notes Receipt:**
- Layout: card 480×640 centered con generous margins (NO sidebar visible — focus mode).
- Sello digital SONAR ✦ — element visual decorativo (checkmark + glow Orange + "verifiable") — elemento marca SONAR único.
- Hash SHA-256 truncated visible — referencia auditable. Click → copy full hash to clipboard.
- 4 actions grid 2×2: Copiar IBAN destino / Descargar PDF (jspdf client-side) / Compartir (web share API NUI fallback) / Otra transfer (back to wizard step 1).
- Motion: aparece con scale 0.95→1 + opacity 0→1 + Bright pulse glow centered 400ms (`signal_emerge` SFX en mount).
- Persistence: el receipt se guarda en `/movimientos/:id` y siempre se puede revisitar.

### 4.6 Wireframe 4 — Escrow hub (B2B contracts FSM viz)

```
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│  ←  Escrows                                                       [+ Nuevo escrow]           │
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                              │
│   Filter: [Todos ▾] [Activos] [Disputed] [Released] [Refunded]   Sort: [Recientes ▾]        │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ ESC-AB12 · Compra trigo Granja del Valle ←→ Bakery LS                  €5.000,00     │  │
│   │ Created 3 May · Locked 3 May · Vence en 27 días                                       │  │
│   │                                                                                       │  │
│   │  ●─────────●─────────○─────────○─────────○                                            │  │
│   │  Created   Locked    Released  Refunded  Disputed                                     │  │
│   │  ✓        ✓ ←current                                                                  │  │
│   │                                                                                       │  │
│   │  Buyer: Bakery LS (manager Marcos)        Seller: Granja del Valle (founder Lucas)    │  │
│   │  Concepto: Pedido 50kg trigo blanco semana 19                                         │  │
│   │                                                                                       │  │
│   │  [🔍 Ver detalle]   [⚖ Disputar]   [✓ Liberar al vendedor]   [↩ Reembolsar]          │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ ESC-CD34 · Servicio logística                                          €1.200,00     │  │
│   │ Created 1 May · DISPUTED · Govt arbitración pendiente                                 │  │
│   │                                                                                       │  │
│   │  ●─────────●─────────○─────────○─────────●                                            │  │
│   │  Created   Locked    Released  Refunded  ⚠ Disputed ←current                          │  │
│   │                                                                                       │  │
│   │  Buyer: ACME Corp                          Seller: Mountain Logistics                 │  │
│   │  Razón disputa: Entrega tardía 5 días                                                 │  │
│   │                                                                                       │  │
│   │  [🔍 Ver detalle]   [📜 Ver historia disputa]                                         │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ ESC-EF56 · Compra coche                                                €15.000,00    │  │
│   │ Created 28 Apr · RELEASED · Funds transferred to seller                               │  │
│   │                                                                                       │  │
│   │  ●─────────●─────────●─────────○─────────○                                            │  │
│   │  Created   Locked    Released ✓ ←final                                                │  │
│   │                                                                                       │  │
│   │  Buyer: Marcos Admiral             Seller: PDM Cars LS                                │  │
│   │  Resultado: vehículo entregado, escrow liberado 30 Apr 14:23                          │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Notes Escrow hub:**
- Cada escrow card muestra **FSM viz horizontal** con dots + connecting lines. Estado actual highlighted Orange. Estado-final greyed. Disputed → red glow (extended palette semantic ADR-017 D2).
- Actions condicionales según FSM state + role buyer/seller/govt.
- Disputed cards tienen prominent ⚠ icon + amber/red border (extended palette).
- "+ Nuevo escrow" → wizard escrow creation (similar 4-step transferir but con seller selection + concept multilínea + duration picker).

### 4.7 Wireframe 5 — Insights view (Apple-Card-class spending)

```
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│  Insights                                                  Periodo: [Mes ▾]  [Mayo 2026 ▾]   │
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                              │
│   ┌──────────────────────────────────────────┐  ┌──────────────────────────────────────┐    │
│   │ DONUT CATEGORIES (480×400)               │  │ TOP CATEGORIES BARS (480×400)        │    │
│   │                                          │  │                                      │    │
│   │      ╭───────────╮                       │  │ 🏠 Vivienda      ████████░░ €1.200   │    │
│   │     ╱             ╲                      │  │ 🍕 Food          ██████░░░░ €890     │    │
│   │    │               │ €3.420 total       │  │ 🚗 Transporte    █████░░░░░ €620     │    │
│   │    │   65%         │ gasto este mes     │  │ 🎫 Multas        ██░░░░░░░░ €280     │    │
│   │     ╲             ╱  ↘ -8% vs Apr        │  │ 🛒 Shopping      ██░░░░░░░░ €240     │    │
│   │      ╰───────────╯                       │  │ 🎉 Ocio          █░░░░░░░░░ €130     │    │
│   │                                          │  │ ⚡ Otros         █░░░░░░░░░ €60      │    │
│   │   🏠 Vivienda  35%                       │  │                                      │    │
│   │   🍕 Food      26%                       │  │ Total spending: €3.420               │    │
│   │   🚗 Transporte 18%                      │  │                                      │    │
│   │   🎫 Multas      8%                      │  │                                      │    │
│   │   🛒 Otros      13%                      │  │                                      │    │
│   │                                          │  │                                      │    │
│   │   (extended palette per category)        │  │ extended palette per category        │    │
│   └──────────────────────────────────────────┘  └──────────────────────────────────────┘    │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ MoM TREND (960×280) — Stacked bar 6 meses + line forecast                            │  │
│   │                                                                                      │  │
│   │ 5K ┤                                                                                 │  │
│   │ 4K ┤        ▓▓                          ▓▓▓                                         │  │
│   │ 3K ┤    ▓▓▓ ▓▓ ▓▓▓     ▓▓▓     ▓▓▓ ▓▓▓ ▓▓▓                                         │  │
│   │ 2K ┤ ▓▓▓ ▓▓ ▓▓ ▓▓ ▓▓▓ ▓▓▓ ▓▓▓ ▓▓▓ ▓▓▓ ▓▓▓                                         │  │
│   │ 1K ┤ ▓▓▓ ▓▓ ▓▓ ▓▓ ▓▓▓ ▓▓▓ ▓▓▓ ▓▓▓ ▓▓▓ ▓▓▓                                         │  │
│   │  0 └─Dec─Ene─Feb─Mar─Abr─May─Jun─Jul─Ago─                                            │  │
│   │     past actual ←─→ forecast (dashed)                                                │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ SUBSCRIPTION TRACKER (auto-detected recurring)                                       │  │
│   │ ⏰ Netflix LS         €12,99/mes · próximo cobro 8 May                  [Cancelar]    │  │
│   │ ⏰ Spotify Premium    €9,99/mes  · próximo cobro 12 May                 [Cancelar]    │  │
│   │ ⏰ Granja membership  €25,00/mes · próximo cobro 15 May                 [Cancelar]    │  │
│   │                                                                                      │  │
│   │ 💡 Detectamos un duplicado: Netflix + Netflix Family. Revisar.                       │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Notes Insights:**
- Donut Recharts con extended palette per category (Apple-Card-rainbow class — opt-in user setting).
- Bars horizontales sorted descending.
- MoM trend Recharts ComposedChart (Bar past + Line forecast dashed).
- Subscription tracker auto-detected via patterns 3+ recurring transfers same destination + interval ±3d.
- Smart insights bullets ("Detectamos duplicado") via rules engine simple Phase A.

### 4.8 Wireframe 6 — Government Console (admin-side ACE-gated) — **moat puro**

```
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│  🏛  Government Console                                              Mode: NPC-managed [v1]   │
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                              │
│   ┌─────────────────────────────────┐  ┌─────────────────────────────────────────────────┐  │
│   │ TREASURY (480×220)              │  │ COLLECTED THIS MONTH (480×220)                  │  │
│   │                                 │  │                                                  │  │
│   │ Treasury balance                │  │ ┌──────────┬──────────┬──────────┬──────────┐  │  │
│   │ €2.847.520,00                   │  │ │Sales tax │Income tax│Wealth tax│ Fines    │  │  │
│   │ ↗ +€124.300 vs Apr              │  │ │€78.230   │€156.890  │€32.450   │€18.640   │  │  │
│   │                                 │  │ │↗ +12%    │↗ +8%     │↘ -3%     │↗ +24%    │  │  │
│   │ Net flow last 30d:              │  │ └──────────┴──────────┴──────────┴──────────┘  │  │
│   │   IN  +€286.210                 │  │                                                  │  │
│   │   OUT -€161.910 (subsidies)     │  │ Total tax collected: €286.210                    │  │
│   │   NET +€124.300                 │  │                                                  │  │
│   │                                 │  │                                                  │  │
│   └─────────────────────────────────┘  └─────────────────────────────────────────────────┘  │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ EMPRESAS UNDER OVERSIGHT (table, sortable)                                           │  │
│   │                                                                                      │  │
│   │ Empresa             Balance     Tax 30d   Compliance   Last audit    Actions         │  │
│   │ ─────────────────── ─────────── ───────── ──────────── ────────────  ──────────      │  │
│   │ Granja del Valle    €45.230     €4.520    ✓ Clean      3 days ago    [🔍 Drill]     │  │
│   │ Bakery LS           €18.940     €1.890    ⚠ Flag-1     yesterday     [🔍 Drill]     │  │
│   │ ACME Corp           €124.580    €12.450   ⚠ Flag-2     today 14:22   [🔍 Drill]     │  │
│   │ Mountain Logistics  €8.230      €820      ❌ Sanction   today 09:15   [🔍 Drill]     │  │
│   │ PDM Cars LS         €67.450     €6.740    ✓ Clean      5 days ago    [🔍 Drill]     │  │
│   │                                                                                      │  │
│   │ + 24 empresas más     [Ver todas →]                                                  │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ COMPLIANCE FLAGS PENDING REVIEW (urgency sorted)                                     │  │
│   │                                                                                      │  │
│   │ 🚨 ACME Corp · Structuring detection (10x €9.999 transfers in 24h)   [Review →]      │  │
│   │ ⚠ Bakery LS · Unusual destination IBAN (foreign-prefix)              [Review →]      │  │
│   │ ⚠ Mountain Logistics · Late tax payment (overdue 7 days)            [Review →]      │  │
│   │                                                                                      │  │
│   │ + 8 flags más                                                                        │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
│   ┌─────────────────────────────────┐  ┌─────────────────────────────────────────────────┐  │
│   │ SUBSIDIES DISBURSED 30d         │  │ TAX BRACKET CONFIG (read-only — config.lua)     │  │
│   │ €161.910 total                  │  │                                                  │  │
│   │ ├ Unemployment   €82.300 (45p)  │  │ Sales tax (VAT): 8%                              │  │
│   │ ├ Welcome new    €18.500 (37p)  │  │ Income tax brackets:                             │  │
│   │ ├ Business grant €45.000 (3 e.) │  │   €0-30k:  0%                                    │  │
│   │ └ Pension elder  €16.110 (8 n.) │  │   €30-80k: 15%                                   │  │
│   │                                 │  │   €80-200k: 25%                                  │  │
│   │ [Disburse manual →]             │  │   €200k+: 35%                                    │  │
│   │                                 │  │ Wealth tax: 1.2% / yr above €500k                │  │
│   │                                 │  │                                                  │  │
│   └─────────────────────────────────┘  └─────────────────────────────────────────────────┘  │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Notes Govt Console:**
- ACE-gated `sonar.govt`. Sin ACE → vista no aparece en sidebar (conditional render).
- Mode badge "NPC-managed v1" — readonly Q1. Future "player-elected" tag con elected player name + term remaining.
- Empresas table: sortable columns + "Drill" → empresa-specific Govt view (movements + tax history + audits + override actions).
- Compliance flags: priority queue. Click "Review" → modal full-page con flag detail + decision (Dismiss / Sanction / Freeze account / Custom action) + audit trail per decision.
- Subsidies disbursed: breakdown by reason. "Disburse manual" → wizard (similar transferir but actor=govt + reason ENUM).
- Tax bracket config: **read-only** display de `config.lua` Server-side — cambios requieren restart server (anti-pattern callback admin config-write per §2.3).

### 4.9 Wireframe 7 — Business Dashboard (empresa multi-account) — **moat puro**

```
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│  🏢 Granja del Valle                                Founder: Lucas · Tu rol: Manager (👁view)│
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                              │
│   ┌────────────────────┬────────────────────┬────────────────────┬────────────────────┐    │
│   │ OPERATING (320×140)│ SAVINGS (320×140)  │ ESCROW (320×140)   │ TREASURY (320×140) │    │
│   │ €45.230,00         │ €18.500,00         │ €5.000,00 locked   │ €68.730,00 total   │    │
│   │ AD-7G8H...1K2L     │ AD-9I0J...2L3M     │ ESC-AB12 active    │ Forecast 90d:      │    │
│   │ Monthly burn: -8%  │ APY 2.5%           │ 1 contract activo  │ ↗ €72.500 proyec.  │    │
│   │ Cash flow OK ✓     │ Goal: equipment    │                    │                    │    │
│   └────────────────────┴────────────────────┴────────────────────┴────────────────────┘    │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ TREASURY CASH FLOW FORECAST 90d (Recharts ComposedChart)                             │  │
│   │                                                                                      │  │
│   │ €80K ┤                                              ╭─────                           │  │
│   │ €70K ┤                              ╭───────────────╯                                │  │
│   │ €60K ┤        ╭───────────────────╯                                                  │  │
│   │ €50K ┤────────╯                                                                      │  │
│   │ €40K ┤                                                                               │  │
│   │      └─Hoy──+15d─+30d─+45d─+60d─+75d─+90d                                            │  │
│   │                                                                                      │  │
│   │  Datos:  ─── Saldo proyectado     ░░░ Recurring incoming       ▓▓▓ Outgoing fixed    │  │
│   │  Eventos: 💼 Payroll 15 Jul (-€8.200)   📃 Invoice ACME 22 Jul (+€12.000)            │  │
│   │           🏛 Tax payment 31 Jul (-€4.520)                                             │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
│   ┌──────────────────────────────────┐  ┌────────────────────────────────────────────────┐  │
│   │ EMPLOYEES & PAYROLL (480×280)    │  │ INVOICES & ESCROWS (480×280)                   │  │
│   │                                  │  │                                                │  │
│   │ Total employees: 5                │  │ Active invoices: 3                             │  │
│   │ Monthly burn: €8.200              │  │  📃 INV-001 ACME Corp     €12.000 due 22 Jul  │  │
│   │ Last payroll: 15 Jun ✓           │  │  📃 INV-002 Bakery LS     €5.500  due 18 Jul  │  │
│   │ Next payroll: 15 Jul              │  │  📃 INV-003 Mountain L.   €1.200  OVERDUE 5d  │  │
│   │                                  │  │                                                │  │
│   │ Lucas Bennett   Founder  €2.500  │  │ Active escrows: 1                              │  │
│   │ Marcos Admiral  Manager  €1.800  │  │  🔒 ESC-AB12 trigo Bakery €5.000 locked       │  │
│   │ Sara Garcia     Worker   €1.300  │  │                                                │  │
│   │ Pablo Lopez     Worker   €1.300  │  │  [+ Nueva factura]   [+ Nuevo escrow]          │  │
│   │ Ana Torres      Worker   €1.300  │  │                                                │  │
│   │                                  │  │                                                │  │
│   │ [+ Pay payroll now]               │  │                                                │  │
│   └──────────────────────────────────┘  └────────────────────────────────────────────────┘  │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ REGULATORY REPORTS (auto-generated monthly)                                          │  │
│   │ 📜 May 2026 — Tax summary + audit digest    [Download PDF]                           │  │
│   │ 📜 Apr 2026 — Tax summary                    [Download PDF]                          │  │
│   │ 📜 Mar 2026 — Tax summary                    [Download PDF]                          │  │
│   │ + 12 reports más  [Archive →]                                                        │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Notes Business Dashboard:**
- 4 account cards top: Operating / Savings / Escrow / Treasury aggregate. Each clickable → drill cuenta.
- Cash flow forecast 90d: ComposedChart con saldo line + recurring incoming dots + outgoing fixed bars. Eventos próximos labeled.
- Payroll widget: list employees + roles + amounts. CTA "Pay payroll now" → manual trigger (also auto-cron).
- Invoices + Escrows: status badges color coded (extended palette ADR-017). OVERDUE red flag.
- Regulatory reports auto-generated monthly cron + downloadable PDF.
- Tu rol badge top right: manager/founder/employee. Acciones disponibles según rol.

### 4.10 Wireframe 8 — Audit Explorer

```
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│  📋 Audit Explorer                                              Scope: [Mis cuentas ▾]       │
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                              │
│   Filters:  [Categoría ▾] [Actor ▾] [Fecha desde] [Fecha hasta] [Severity ▾]                │
│   Search:   🔍 Buscar concepto, IBAN, hash, correlation_id...                                │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ 24 entries · sorted recent first · 1.247.832 total ledger size                       │  │
│   │                                                                                      │  │
│   │ ▼ TODAY                                                                              │  │
│   │ 20:48 │ bank.transfer        │ marcos@AD-1A2B → lucas@AD-2A4B │ €150,00  │ 🔓 OK    │  │
│   │ 20:30 │ bank.escrow_locked   │ esc-AB12 buyer→escrow         │ €5.000   │ 🔓 OK    │  │
│   │ 18:22 │ bank.tax_collected   │ govt collects sales tax        │ €120,40  │ 🔓 OK    │  │
│   │ 14:23 │ govt.subsidy_disbsr  │ govt → marcos welfare          │ €450,00  │ 🔓 OK    │  │
│   │                                                                                      │  │
│   │ ▼ YESTERDAY                                                                          │  │
│   │ 23:01 │ bank.compliance.flag │ acme_corp structuring detected │ —        │ ⚠ FLAG   │  │
│   │ 19:14 │ bank.transfer        │ marcos@AD-1A2B → granja        │ €8.500   │ 🔓 OK    │  │
│   │ ...                                                                                   │  │
│   │                                                                                      │  │
│   │ + Cargar más  ↓                                                                      │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
│   Click row → Drill modal:                                                                   │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ Audit entry · 20:48 · 5 May 2026                                            ✕ Cerrar │  │
│   │                                                                                      │  │
│   │ Category        bank.transfer                                                        │  │
│   │ Actor           marcos.admiral.cit_id_42 (player)                                    │  │
│   │ Action          DEBIT marcos@AD-1A2B + CREDIT lucas@AD-2A4B                          │  │
│   │ Amount          €150,00                                                              │  │
│   │ Concept         "Pago alquiler octubre 🏠"                                           │  │
│   │ Category        rent                                                                 │  │
│   │ Reference       SBNK-AB12-CD34-EF56-7890                                             │  │
│   │ Hash SHA-256    a3f2c1bbb4e9d12e8f01... (full 64 chars)  📋 copy                    │  │
│   │ Correlation     corr-9c4d-bb12 (links related entries)                              │  │
│   │ Source resource sonar_bank                                                           │  │
│   │ Compliance flags  none                                                               │  │
│   │ Linked entries  [DEBIT marcos] ←→ [CREDIT lucas]   (atomic transaction pair)        │  │
│   │                                                                                      │  │
│   │ Verifiable: hash matches ledger record + correlation chain valid ✓                  │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Notes Audit Explorer:**
- Scope selector: "Mis cuentas" (player default) / "Mi empresa" (founder/manager) / "Todas" (ACE `sonar.govt`).
- Filters multi-axis. Search libre full-text concept + IBAN + hash + correlation_id.
- Lista virtual (1M+ entries possible), 50 per page virtual scroll.
- Severity color-coded (extended palette): OK = white/40 / FLAG = amber / SANCTION = red.
- Drill modal: full audit entry detail + verifiable hash + correlation chain links.
- Player limited a sus propias entradas + correlated. Admin full lateral.

### 4.11 Wireframe 9 — Cards (virtual + tier escalation + physical)

```
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│  💳 Mis tarjetas                                                       [+ Solicitar nueva]   │
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                              │
│   Stack visual cards (Fintrixity-class) — front card primary, back cards stacked:            │
│                                                                                              │
│   ┌─────────────────────────────────────────────────┐                                        │
│   │ ╔═════════════════════════════════════════════╗ │  ← Active card (primary)               │
│   │ ║  SONAR BLACK                                ║ │     gradient deep navy + glow Orange   │
│   │ ║                          (chip + waves NFC) ║ │                                        │
│   │ ║                                             ║ │                                        │
│   │ ║  AD-1A2B-3C4D-5E6F                          ║ │                                        │
│   │ ║                                             ║ │                                        │
│   │ ║  MARCOS ADMIRAL              EXPIRES 12/30 ║ │                                        │
│   │ ║                                             ║ │                                        │
│   │ ║  Spending limit  €5.000 / day              ║ │                                        │
│   │ ║  Cashback 1.5% all                          ║ │                                        │
│   │ ╚═════════════════════════════════════════════╝ │                                        │
│   │ ╔═════════════════════════════════════════════╗ │  ← Stacked back card (Gold)            │
│   │ ║  SONAR GOLD ························       ║ │     gradient gold→black                │
│   │ ╚═════════════════════════════════════════════╝ │                                        │
│   │ ╔═════════════════════════════════════════════╗ │  ← Stacked back card (Basic, virtual)  │
│   │ ║  SONAR BASIC ·······························║ │                                        │
│   │ ╚═════════════════════════════════════════════╝ │                                        │
│   └─────────────────────────────────────────────────┘                                        │
│                                                                                              │
│   ┌─────────────────────────────────────────────┐  ┌─────────────────────────────────────┐  │
│   │ DETAIL — SONAR BLACK (selected)             │  │ TIER PROGRESSION                    │  │
│   │                                             │  │                                     │  │
│   │ Status: ACTIVE   ❄ Freeze toggle [OFF]      │  │ Basic     ─●─────●─────●─── Black   │  │
│   │                                             │  │            ↑                        │  │
│   │ Linked IBAN  AD-1A2B-3C4D-5E6F              │  │      You are here                   │  │
│   │ Tier         Black (organic — top wealth)   │  │                                     │  │
│   │ PIN          ●●●●  [Cambiar PIN]            │  │ Next tier: 🌟 Black achieved        │  │
│   │ Issued       12 Jan 2026                    │  │                                     │  │
│   │ Expires      31 Dec 2030                    │  │ Benefits unlocked:                  │  │
│   │ Type         Virtual + Physical             │  │  • €5K/day limit                    │  │
│   │              Item bank_card #BC-AB12 in inv │  │  • 1.5% cashback                    │  │
│   │                                             │  │  • Concierge support                │  │
│   │ Recent uses (last 24h):                     │  │  • Insurance €50K                   │  │
│   │  20:48 €150 transfer Lucas                  │  │                                     │  │
│   │  18:30 €18,50 Pizza Place                   │  │ Tier criteria (organic — N9):       │  │
│   │                                             │  │  • Wealth ≥ €500k                   │  │
│   │ [📋 Copiar IBAN] [🔄 Reemitir] [🚫 Cerrar] │  │  • Tx volume ≥ 100/mo                │  │
│   │                                             │  │  • Account age ≥ 90d                │  │
│   └─────────────────────────────────────────────┘  └─────────────────────────────────────┘  │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Notes Cards:**
- Stack visual Fintrixity-class — primary card front, others stacked behind partially. Click stacked → tween swap to front.
- Card visuals diferenciadas por tier: Basic (matte black), Gold (gradient gold→black), Platinum (silver gradient), Black (deep navy + Orange glow accent).
- Tier escalation **organic** per N9 — wealth + tx_volume + account_age thresholds. NO pay-to-win.
- Freeze toggle hero — instant kill (anti-theft). Card gets `frozen` FSM state, all use blocked.
- PIN change flow modal con auth (current PIN) + new PIN entry double.
- Recent uses tail: last 24h tx via this card.
- Physical item integrated `sonar_inventory.bank_card` con type ENUM = tier name + linked_iban + tier_at_issue (T4 in-scope).

### 4.12 Wireframe 10 — Loans Hub (consumer + business + credit score)

```
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│  💎 Préstamos                                                                                │
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                              │
│   ┌─────────────────────────────────┐  ┌─────────────────────────────────────────────────┐  │
│   │ MI CREDIT SCORE (320×220)       │  │ LOAN OFFERS (preset templates Govt-managed)     │  │
│   │                                 │  │                                                  │  │
│   │       ╭───────╮                 │  │  💼 Personal €5.000      8% APR · 12 meses      │  │
│   │      ╱  725   ╲                 │  │     Pago mensual €435     [Solicitar]            │  │
│   │     │   ───   │                 │  │                                                  │  │
│   │     │  GOOD   │                 │  │  🚗 Vehículo €25.000     6% APR · 60 meses      │  │
│   │      ╲       ╱                  │  │     Pago mensual €483     [Solicitar]            │  │
│   │       ╰───────╯                 │  │                                                  │  │
│   │   Range 300-850                 │  │  🏠 Hipoteca €150.000    4.5% APR · 240 meses   │  │
│   │   ↗ +12 pts last 30d            │  │     Pago mensual €949     [Solicitar]            │  │
│   │                                 │  │                                                  │  │
│   │   Factors:                      │  │  💼 Business €50.000     7.5% APR · 36 meses   │  │
│   │   ✓ Long history (8 mo)         │  │     Pago mensual €1.557   [Solicitar — empresa] │  │
│   │   ✓ No defaults                 │  │                                                  │  │
│   │   ⚠ High utilization 78%        │  │  + Solicitud personalizada (custom amount)       │  │
│   │   ✓ On-time payments            │  │                                                  │  │
│   │                                 │  │                                                  │  │
│   └─────────────────────────────────┘  └─────────────────────────────────────────────────┘  │
│                                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
│   │ MIS PRÉSTAMOS ACTIVOS                                                                │  │
│   │                                                                                      │  │
│   │ ┌───────────────────────────────────────────────────────────────────────────────┐   │  │
│   │ │ LOAN-AB12 · Personal Loan                                  €5.000 → €3.420    │   │  │
│   │ │ Issued 2 Mar 2026 · 8% APR · 12 meses                       │   │
│   │ │                                                                               │   │  │
│   │ │ Repaid: 32% ████████░░░░░░░░░░░░░░  €1.580 / €5.000                          │   │  │
│   │ │                                                                               │   │  │
│   │ │ Next payment: 15 Jul 2026 · €435   Auto-debit ON ✓                           │   │  │
│   │ │ Remaining: 8 monthly payments                                                 │   │  │
│   │ │                                                                               │   │  │
│   │ │ [📜 Ver schedule]   [💰 Pay early]   [🔄 Refinance]                           │   │  │
│   │ └───────────────────────────────────────────────────────────────────────────────┘   │  │
│   │                                                                                      │  │
│   │ Past loans (paid off):                                                               │  │
│   │ ✓ LOAN-CD34 Personal €2.000 — paid in full Apr 2026                                 │  │
│   │ ✓ LOAN-EF56 Vehicle €15.000 — paid in full Dec 2025                                 │  │
│   └──────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Notes Loans:**
- Credit score gauge Recharts radial bar. Range 300-850. Color extended palette by tier (Excellent green / Good orange / Fair amber / Poor red — opt-in extended palette).
- Loan offers: Govt-managed templates configurable + custom application form. Click "Solicitar" → wizard application (4-step similar transferir but actor=govt + interest pre-calculated based on credit_score).
- Active loans: progress bar repayment + next payment date + auto-debit toggle + actions (Pay early / Refinance / Schedule view).
- Past loans archival.

### 4.13 Motion choreography canonical (reused + new presets)

#### 4.13.1 Reused presets (existing `lib/motion.ts` Tablet)

| Preset existing | Apply to Bank |
|---|---|
| `tabSwitch` (existing S2.4) | Tab switching dentro Bank views |
| `panelOpen` | Modal opens (drill, settings) |
| `signalEmerge` (existing) | Window mount + Receipt mount |
| `cardFlip` (post-S2.x?) | Cards stack swap |
| `chartReveal` (post-S2.5?) | Chart mount staggered series |

#### 4.13.2 New presets propose Phase B

| New preset | Description | Easing | Duration |
|---|---|---|---|
| `wizardStep` | Slide-x next/prev step + opacity fade | `easeOutCubic` | 400ms |
| `holdConfirmFill` | Progress fill 0→100% during hold | linear | 1.2s |
| `holdConfirmRelease` | Spring release on cancel | `spring stiffness 300 damping 25` | auto |
| `receiptFold` | Card unfold + glow Bright pulse 400ms | `easeOutBack` | 600ms |
| `cardStackSwap` | Z-axis swap front↔back stack tween | `easeInOutCubic` | 500ms |
| `escrowTimelineProgress` | FSM dots + lines fill animated | linear | 800ms staggered |
| `numberCounter` | Tween balance 0→target | `easeOutQuart` | 1200ms |
| `donutMount` | Pie slices arc grow staggered | `easeOutCubic` | 800ms 100ms stagger |
| `barGrow` | Bar height 0→target staggered | `easeOutCubic` | 600ms 80ms stagger |
| `glowPulse` | Box-shadow Orange opacity 0→0.6→0 | `easeInOutSine` | 1000ms loop or once |
| `errorShake` | Translate-x ±4px wobble | `easeOutElastic` | 400ms 4 cycles |
| `successBloom` | Scale 1→1.05→1 + glow | `easeOutBack` | 500ms |

### 4.14 Sound triggers map per state (canonical 5 SFX + opcional 2 nuevos)

#### 4.14.1 Canonical 5 (existing per ADR-016 D4 + sfx.ts)

| SFX | Class | Triggers Bank |
|---|---|---|
| `signal_emerge` | Apple-class soft welcome | Window mount + first time onboarding step + Receipt mount |
| `depth_press` | Apple Touch ID success | Confirm hold release full + transfer success + escrow release |
| `layer_dive` | Apple page-flip glide 1000→660Hz | Tab switch + step Continuar → + drill modal open |
| `console_tap` | Apple UIKeyClick crisp | Button click + keypad digit + IBAN copy + filter pill toggle |
| `panel_open` | Apple modal swipe | Sidebar section expand + drawer open + back step |

#### 4.14.2 Optional new propose Phase B (review founder)

| SFX | Class | Triggers |
|---|---|---|
| `transfer_complete` | success bell soft 1-tone | Optional ceremonial post-transfer (alt path to `depth_press`) — **founder review Q11** |
| `compliance_alert` | warning soft sub-bass + sine | Compliance flag raised UI surface — only visual fallback if SFX rejected by founder |

### 4.15 Glassmorphism + Glow rules + Color tokens canonical

#### 4.15.1 Glass tokens (window standalone)

```css
/* Window backdrop */
.bank-window-backdrop {
  background: rgba(6, 6, 7, 0.78);  /* sonar-black 78% */
  backdrop-filter: blur(8px);
}

/* Window chrome */
.bank-window {
  width: 1440px;
  height: 900px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 16px;
  box-shadow: 0 32px 80px rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(20px);
  background: rgba(6, 6, 7, 0.92);  /* sonar-black 92% over backdrop */
}
```

#### 4.15.2 Glow tokens (Orange canonical + extended semantic ADR-017)

```css
/* Canonical Orange glow (focus, active, brand emphasis) */
--glow-orange-subtle: 0 0 12px rgba(255, 81, 0, 0.25);
--glow-orange-strong: 0 0 24px rgba(255, 81, 0, 0.45);
--glow-orange-pulse:  0 0 32px rgba(255, 81, 0, 0.6);   /* Bright pulse */

/* Extended semantic glows (ADR-017 D2 amendment proposal) */
--glow-success-subtle: 0 0 12px rgba(95, 184, 154, 0.25);
--glow-warn-subtle:    0 0 12px rgba(251, 191, 36, 0.25);
--glow-critical-subtle: 0 0 12px rgba(232, 93, 93, 0.25);
--glow-info-subtle:    0 0 12px rgba(96, 165, 250, 0.25);
```

#### 4.15.3 Color tokens canonical (Tailwind v4 `@theme`)

```css
@theme {
  /* SONAR canonical 3 (ADR-016 D3 immutable) */
  --color-sonar-black:  #060607;
  --color-sonar-orange: #FF5100;
  --color-sonar-white:  #FAFAFA;

  /* ADR-017 D1 — Brand gradients (Orange spectrum extends) */
  --color-sonar-orange-50:  #FFF1EB;
  --color-sonar-orange-100: #FFD5C2;
  --color-sonar-orange-300: #FF8B5A;
  --color-sonar-orange-500: #FF5100;  /* canonical alias */
  --color-sonar-orange-700: #C73A00;
  --color-sonar-orange-900: #6E2000;

  /* ADR-017 D2 — Semantic functional re-introduced Bank-specific */
  --color-sonar-success: #5FB89A;  /* incoming, balance positive — soft teal */
  --color-sonar-warn:    #FBBF24;  /* warnings, near limits — amber */
  --color-sonar-critical: #E85D5D; /* errors, fraud, sanctions — soft red */
  --color-sonar-info:    #60A5FA;  /* informational tooltips — soft blue */

  /* ADR-017 D3 — Brand gradient tones for hero/promo */
  --color-sonar-pink-500: #FF6B9D;  /* Orange→Pink hero gradient */
  --color-sonar-amber-500: #FFA94D; /* Orange→Amber alt gradient */

  /* ADR-017 D4 — Category color-coding (data viz Recharts series) — opt-in user setting */
  --color-cat-housing:    #C77DFF;  /* purple */
  --color-cat-food:       #FF7B72;  /* coral */
  --color-cat-transport:  #FBBF24;  /* amber */
  --color-cat-salary:     #5FB89A;  /* teal — match success */
  --color-cat-tax:        #E85D5D;  /* red — match critical */
  --color-cat-shopping:   #60A5FA;  /* blue */
  --color-cat-leisure:    #FF6B9D;  /* pink */
  --color-cat-other:      rgba(250,250,250,0.4); /* neutral */
}
```

**Importante N1:** dark canvas dominante + Orange brand primary + White foreground siempre. Extended palette es **tier secundario** que se aplica a chart series + semantic states + opt-in category rendering. Dominancia visual SONAR canonical no cambia.

### 4.16 Lucide bridge S2-S3 → 8 abstract custom S3+ replacement

Per ADR-016 D5 + iconography roadmap shipped: Bank app usa Lucide bridge (los iconos arriba en wireframes) hasta S3+ donde se replazan por **8 abstract custom Bank-domain-specific**:

| Lucide bridge | Custom S3+ | Concept |
|---|---|---|
| `Wallet` | `vault` | Sonar vault stylized — capas concéntricas |
| `ArrowRightLeft` | `tide_flow` | Olas bidireccionales — flow movement |
| `History` | `wave_echo` | Sonar wave radiating |
| `CreditCard` | `card_signal` | Card silhouette + signal waves |
| `Receipt` | `seal_pulse` | Sello digital ✦ + pulse |
| `BarChart3` | `depth_chart` | Vertical bars evoking sonar depth |
| `Building2` | `corp_anchor` | Building silhouette + anchor |
| `Landmark` | `civic_mark` | Govt building stylized SONAR |

**Phase B scope:** import Lucide bridge S2-S3. **Phase B+ or post-S3 sprint dedicated:** custom 8 abstract design + replace.

### 4.17 Charts (Recharts) preset specs

Phase B: Recharts theme tokens canonical + preset components Bank.

| Preset | Type | Tokens used | Use case |
|---|---|---|---|
| `<SparklineHero>` | AreaChart | `sonar-orange` fill gradient subtle | Hero balance card sparkline 30d |
| `<TrendStacked>` | ComposedChart Bar+Line | extended palette per category + `sonar-orange-300` line forecast dashed | MoM trend Insights |
| `<DonutCategories>` | PieChart | extended palette per category | Spending categories Insights |
| `<ProgressGauge>` | RadialBarChart | `sonar-orange` arc + `sonar-white/10` track | Credit score, Goals |
| `<TimelineFSM>` | Custom (no Recharts) | dots `sonar-orange` active + `sonar-white/10` future + extended palette severity | Escrow + Loan + Card lifecycle viz |
| `<CashFlowForecast>` | LineChart + ReferenceArea | `sonar-orange` past actual line + `sonar-white/30` forecast dashed + ReferenceArea tax/payroll events | Treasury empresa |

**Animation:** todas Recharts series con `isAnimationActive=true` + `animationDuration=800` + `animationEasing='ease-out'` + staggered series mount via Framer custom wrap.

---

## 5. Architecture Proposal

> Esta sección define el **backend completo** que Phase A implementa. Callbacks pseudosignatures (no Lua real). DB DDL pseudo (no SQL real). FSMs notación standard. Bridges + sub-resources scope outline. **Founder review obligatorio antes Phase A arranque.**

### 5.1 Callbacks new propose (C006-C0XX, ~25 nuevos)

> **Naming:** `sonar:bank:*` o `sonar:govt:*` o `sonar:invest:*` o `sonar:loans:*` per resource hosting. **Versioning:** A1 inmutable signatures (per `@docs/technical/04_api_contracts.md` §1).

#### 5.1.1 Bank core callbacks

| ID | Callback | Resource | Auth | Rate | Description |
|---|---|---|---|---|---|
| C006 | `sonar:bank:deposit` | sonar_bank | owner | 10/60s | Cash → account. Trigger ATM o admin. Atomic balance UPDATE + movement INSERT + audit. |
| C007 | `sonar:bank:withdraw` | sonar_bank | owner | 10/60s | Account → cash. Limits enforce + ATM minigame trigger. |
| C008 | `sonar:bank:beneficiaries:list` | sonar_bank | owner | 30/10s | List beneficiaries del player. Returns array + favorites flag. |
| C009 | `sonar:bank:beneficiaries:add` | sonar_bank | owner | 20/60s | Add IBAN to book + alias. Validates IBAN exists + not self. |
| C010 | `sonar:bank:beneficiaries:remove` | sonar_bank | owner | 20/60s | Remove from book. |
| C011 | `sonar:bank:beneficiaries:favorite` | sonar_bank | owner | 30/10s | Toggle ⭐ favorite flag. |
| C015 | `sonar:bank:cards:list` | sonar_bank | owner | 30/10s | List cards del owner + tier + status FSM. |
| C016 | `sonar:bank:cards:create` | sonar_bank | owner | 5/60s | Issue new card (virtual). Tier auto-assigned per organic criteria. PIN entry. |
| C017 | `sonar:bank:cards:freeze` | sonar_bank | owner | 10/60s | Toggle freeze. FSM transition. |
| C018 | `sonar:bank:cards:change_pin` | sonar_bank | owner+auth | 5/60s | Change PIN with current PIN auth. SHA-256 hash store. |
| C035 | `sonar:bank:limits:get` | sonar_bank | owner | 30/10s | Get player limits config. |
| C036 | `sonar:bank:limits:set` | sonar_bank | owner | 5/60s | Update limits (daily withdraw / daily transfer / per-recipient). |
| C037 | `sonar:bank:recurring:list` | sonar_bank | owner | 30/10s | List recurring + standing orders + direct debits del player. |
| C038 | `sonar:bank:recurring:create` | sonar_bank | owner | 5/60s | Create recurring transfer. Frequency ENUM + first_run + end_date opcional. |
| C039 | `sonar:bank:recurring:cancel` | sonar_bank | owner | 10/60s | Cancel recurring. FSM `recurring_lifecycle` → `cancelled`. |
| C040 | `sonar:bank:spaces:list` | sonar_bank | owner | 30/10s | List spaces (savings buckets) per IBAN. |
| C041 | `sonar:bank:spaces:create` | sonar_bank | owner | 5/60s | Create space con goal_name + target_amount. |
| C042 | `sonar:bank:spaces:transfer` | sonar_bank | owner | 20/60s | Move funds between spaces (drag-drop UI). |
| C043 | `sonar:bank:dispute:create` | sonar_bank | party | 3/24h | Raise dispute on tx. |

#### 5.1.2 Government callbacks (`sonar_govt` resource)

| ID | Callback | Auth | Rate | Description |
|---|---|---|---|---|
| C050 | `sonar:govt:treasury:get` | ACE govt | 30/10s | Get treasury balance + breakdown. |
| C051 | `sonar:govt:tax:collect_run` | ACE govt | 1/h | Manual trigger tax collection cron (also auto). |
| C052 | `sonar:govt:subsidies:list` | ACE govt | 30/10s | List subsidy programs config. |
| C053 | `sonar:govt:subsidies:disburse_manual` | ACE govt | 10/h | Disburse subsidy manual (override eligibility opcional). |
| C054 | `sonar:govt:compliance:flags:list` | ACE govt | 30/10s | List pending compliance flags. |
| C055 | `sonar:govt:compliance:flag:review` | ACE govt | 30/10s | Decide flag (Dismiss / Sanction / Freeze / Custom). FSM transition. |
| C056 | `sonar:govt:audit:query` | ACE govt | 60/10s | Query audit ledger admin scope. Pagination + filters. |
| C057 | `sonar:govt:reports:generate` | ACE govt | 5/h | Generate monthly regulatory report PDF. |

#### 5.1.3 Invest callbacks (`sonar_invest` resource — T4)

| ID | Callback | Auth | Rate | Description |
|---|---|---|---|---|
| C060 | `sonar:invest:stocks:quote` | any | 60/10s | Get current price + history per ticker. |
| C061 | `sonar:invest:stocks:buy` | owner | 20/60s | Buy shares. Atomic balance debit + portfolio update. |
| C062 | `sonar:invest:stocks:sell` | owner | 20/60s | Sell shares. |
| C063 | `sonar:invest:stocks:portfolio` | owner | 30/10s | Get portfolio holdings. |
| C064 | `sonar:invest:crypto:quote` | any | 60/10s | Crypto current price. |
| C065 | `sonar:invest:crypto:buy` | owner | 20/60s | Buy crypto. |
| C066 | `sonar:invest:crypto:sell` | owner | 20/60s | Sell crypto. |
| C067 | `sonar:invest:crypto:transfer` | owner | 10/60s | Transfer crypto between players. |
| C068 | `sonar:invest:crypto:stake` | owner | 5/60s | Lock crypto for APY (T4). |

#### 5.1.4 Loans callbacks (`sonar_loans` resource)

| ID | Callback | Auth | Rate | Description |
|---|---|---|---|---|
| C070 | `sonar:loans:templates:list` | any | 30/10s | List loan offer templates Govt-config. |
| C071 | `sonar:loans:apply_preset` | owner | 3/24h | Apply for preset loan. Auto-approval if credit_score sufficient. |
| C072 | `sonar:loans:apply_custom` | owner | 1/24h | Submit custom loan application. Govt actor reviews. |
| C073 | `sonar:loans:active` | owner | 30/10s | List active loans del player + repayment progress. |
| C074 | `sonar:loans:pay_early` | owner | 10/60s | Pay early (full or partial). Recalc remaining schedule. |
| C075 | `sonar:loans:credit_score` | owner | 30/10s | Get credit score + factors breakdown. |

#### 5.1.5 Companies callbacks (`sonar_companies` resource — extends existing partial)

| ID | Callback | Auth | Rate | Description |
|---|---|---|---|---|
| C080 | `sonar:companies:my` | any | 30/10s | List empresas where player is founder/manager/employee. |
| C081 | `sonar:companies:dashboard` | founder/manager | 30/10s | Get business dashboard data (multi-account + payroll + invoices + escrows). |
| C082 | `sonar:companies:invoices:list` | founder/manager | 30/10s | List invoices empresa. |
| C083 | `sonar:companies:invoices:create` | founder/manager | 10/60s | Create invoice. PDF gen + due_date FSM. |
| C084 | `sonar:companies:invoices:cancel` | founder/manager | 10/60s | Cancel invoice (only if `pending`). |
| C085 | `sonar:companies:treasury:forecast` | founder/manager | 10/10s | Get 90d cash flow forecast empresa. |
| C086 | `sonar:companies:reports:generate` | founder/manager | 5/h | Generate monthly regulatory report PDF empresa. |

#### 5.1.6 Total callbacks count

- **Existing shipped C001-C005 (Bank):** 5 (C001 + C002 + C004 + C005 shipped, C003 deferred S3 unlock recommended Q3).
- **New propose Phase A:** 30 callbacks (C006-C0XX above).
- **Total Phase E:** ~35 callbacks Bank-domain.

Plus existing api_contracts.md §3.2 (empresa C010-C014) + §3.3 (item C020-C022) + §3.4 (mercado C030-C031) ya en SSoT — no se tocan.

### 5.2 DB Schema extends (12+ tablas nuevas)

> **Mantienen SSoT existing:** `sonar_bank_accounts` + `sonar_bank_movements` + `sonar_companies` + `sonar_company_members` (no se tocan signatures, solo extends ENUMs cuando aplica).

#### 5.2.1 Bank extends

| Tabla nueva | Propósito | Key fields |
|---|---|---|
| `sonar_bank_account_members` | Roles per cuenta (shared/empresa governance) | `id`, `bank_account_id` FK, `account_id` FK player, `role` ENUM(`owner`,`co_founder`,`manager`,`employee`,`viewer`), `permissions` BITMAP, `granted_at`, `granted_by` |
| `sonar_bank_account_spaces` | Savings buckets within IBAN | `id`, `bank_account_id` FK, `name` VARCHAR(64), `goal_amount` DECIMAL, `current_amount` DECIMAL, `created_at` |
| `sonar_bank_beneficiaries` | Saved frequent recipients | `id`, `owner_account_id` FK, `target_iban` VARCHAR, `alias` VARCHAR(64), `is_favorite` BOOL, `last_used_at`, `tx_count` |
| `sonar_bank_cards` | Virtual + physical cards | `id`, `bank_account_id` FK, `tier` ENUM(`basic`,`gold`,`platinum`,`black`), `pin_hash` CHAR(64), `status` ENUM(`active`,`frozen`,`closed`,`swallowed`), `linked_inventory_item_id` NULL, `issued_at`, `expires_at`, `daily_limit` DECIMAL |
| `sonar_bank_recurring` | Recurring + standing orders + direct debits | `id`, `from_iban`, `to_iban`, `amount`, `concept`, `frequency` ENUM(`daily`,`weekly`,`monthly`,`yearly`,`once`), `next_run_at`, `end_date`, `status` ENUM(`active`,`paused`,`cancelled`,`exhausted`), `created_by`, `authorized_by` (for direct debits) |
| `sonar_bank_limits` | Per-player + per-card limits | `id`, `account_id` FK player, `card_id` FK NULL, `daily_withdraw` DECIMAL, `daily_transfer` DECIMAL, `per_recipient_max` DECIMAL, `per_category_max` JSON |
| `sonar_bank_compliance_flags` | Flags raised on accounts | `id`, `bank_account_id` FK, `flag_type` ENUM(`structuring`,`unusual_destination`,`large_transfer`,`late_tax`,`other`), `severity` ENUM(`info`,`warn`,`critical`), `status` ENUM(`pending`,`reviewed`,`dismissed`,`sanctioned`), `raised_at`, `raised_by`, `resolution`, `resolved_by` |
| `sonar_bank_currencies` | Multi-currency table (T4) | `code` PK CHAR(3), `name`, `symbol`, `fx_rate_to_eur` DECIMAL, `updated_at` |
| `sonar_bank_credit_scores` | Per-player score | `account_id` PK FK, `score` SMALLINT (300-850), `factors` JSON, `last_recalc_at` |

#### 5.2.2 Government extends

| Tabla nueva | Propósito | Key fields |
|---|---|---|
| `sonar_govt_tax_brackets` | Config tax brackets (read-only mostly, populated via migration seed) | `id`, `tax_type` ENUM(`sales`,`income`,`wealth`,`inheritance`), `bracket_min` DECIMAL, `bracket_max` DECIMAL NULL, `rate` DECIMAL, `effective_from` |
| `sonar_govt_tax_collections` | Audit log per collection event | `id`, `tax_type`, `account_id_taxed`, `amount`, `collected_at`, `period` (e.g., `2026-05`) |
| `sonar_govt_subsidy_programs` | Subsidy programs config | `id`, `name`, `description`, `eligibility_rules` JSON, `amount` DECIMAL, `frequency` ENUM, `active` BOOL |
| `sonar_govt_subsidy_disbursements` | Audit per subsidy paid | `id`, `program_id` FK, `recipient_account_id` FK, `amount`, `disbursed_at`, `disbursed_by` (`auto` or admin actor) |

#### 5.2.3 Loans extends (resource `sonar_loans`)

| Tabla nueva | Propósito | Key fields |
|---|---|---|
| `sonar_loan_templates` | Govt-config preset loan offers | `id`, `name`, `type` ENUM(`personal`,`vehicle`,`mortgage`,`business`), `amount` DECIMAL, `apr` DECIMAL, `term_months` SMALLINT, `min_credit_score` SMALLINT, `active` BOOL |
| `sonar_loan_applications` | Player-submitted applications | `id`, `applicant_account_id` FK, `template_id` FK NULL (custom), `requested_amount`, `requested_term_months`, `status` ENUM(`pending`,`approved`,`denied`,`withdrawn`), `reviewed_by` NULL, `reason_denial` TEXT NULL |
| `sonar_loans_active` | Active loans + schedule | `id`, `applicant_account_id` FK, `principal` DECIMAL, `apr` DECIMAL, `term_months`, `monthly_payment`, `outstanding_balance`, `next_payment_at`, `auto_debit` BOOL, `status` ENUM FSM, `issued_at` |
| `sonar_loans_payments` | Payment history per loan | `id`, `loan_id` FK, `amount`, `principal_portion`, `interest_portion`, `paid_at`, `is_late` BOOL |

#### 5.2.4 Invest extends (resource `sonar_invest` — T4)

| Tabla nueva | Propósito | Key fields |
|---|---|---|
| `sonar_invest_tickers` | Stocks + crypto config | `ticker` PK, `name`, `type` ENUM(`stock`,`crypto`), `current_price`, `volatility`, `regime` ENUM(`bull`,`bear`,`stable`,`crash`), `last_update_at` |
| `sonar_invest_holdings` | Player portfolios | `id`, `account_id` FK, `ticker` FK, `quantity`, `avg_buy_price`, `created_at` |
| `sonar_invest_transactions` | Buy/sell history | `id`, `account_id` FK, `ticker`, `action` ENUM(`buy`,`sell`,`stake`,`unstake`), `quantity`, `price`, `executed_at` |
| `sonar_invest_stakes` | Crypto staking active | `id`, `account_id` FK, `ticker`, `quantity`, `apy`, `lock_until`, `created_at` |

#### 5.2.5 Companies extends (resource `sonar_companies`)

| Tabla nueva | Propósito | Key fields |
|---|---|---|
| `sonar_company_invoices` | Invoices empresa→party | `id`, `issuer_company_id` FK, `recipient_iban`, `amount`, `concept`, `due_date`, `status` ENUM FSM, `paid_at` NULL, `pdf_hash` CHAR(64) |

#### 5.2.6 Audit extends (cross-resource)

| Existing | Extends propose |
|---|---|
| `sonar_audit_log` | Add columns `actor_role` ENUM(`player`,`empresa`,`govt`,`system`) + `correlation_id` UUID + `severity` ENUM + `regulatory_flags` BITMAP. Backfill on migration. |
| `sonar_bank_movements` | Add columns `category_visual` VARCHAR(32) NULL (detected category for UI) + `actor_role` ENUM (denormalized desde audit log) + `regulatory_flags` BITMAP. Index `idx_*_category_visual`. |

### 5.3 FSMs new (8 nuevos + extends)

> **Pattern existing per `@docs/technical/05_state_machines.md`:** estados enumerados + transitions whitelist + guards + actions + audit per transition.

#### 5.3.1 New FSMs

| FSM | Estados | Initial → Final | Triggers transition |
|---|---|---|---|
| `account_lifecycle` | `active`, `frozen`, `closing`, `closed` | `active` → `closed` | Owner request close + Govt sanction freeze + Compliance review |
| `card_lifecycle` | `active`, `frozen`, `closed`, `swallowed`, `expired` | `active` → `closed`/`expired` | Owner freeze + ATM 3 strikes wrong PIN + expiry date + manual close |
| `loan_lifecycle` | `pending`, `approved`, `active`, `delinquent`, `paid_off`, `defaulted`, `denied`, `withdrawn` | `pending` → `paid_off`/`defaulted` | Govt review + cron repayment + late >30d + applicant withdraw |
| `invoice_lifecycle` | `draft`, `sent`, `viewed`, `paid`, `overdue`, `cancelled`, `disputed` | `draft` → `paid`/`cancelled` | Send + recipient view + payment + cron overdue + cancel + dispute raise |
| `recurring_lifecycle` | `active`, `paused`, `cancelled`, `exhausted` | `active` → `cancelled`/`exhausted` | Owner pause/cancel + end_date reached + amount limit reached |
| `subscription_lifecycle` | (subset of recurring) | — | — |
| `compliance_check_lifecycle` | `raised`, `under_review`, `dismissed`, `sanctioned`, `escalated` | `raised` → `dismissed`/`sanctioned` | Govt review decision + escalate to higher tier |
| `payroll_lifecycle` (empresa cron) | `scheduled`, `executing`, `completed`, `failed`, `cancelled` | `scheduled` → `completed`/`failed` | Cron trigger + employee disbursement loop + retry on fail |

#### 5.3.2 Extends existing

- `escrow_lifecycle` (shipped S1.3): no cambios. UI viz Phase C consume estados.
- `contract_lifecycle` (shipped @ state_machines.md §4.2): integrate con invoices via FK.

### 5.4 Bridges Layer T2 wraps

> **Per N5 + ADR-007 + `@docs/technical/07_bridges_compatibility.md`:** Cero `exports['qb-*']` o `ESX.*` directo fuera adapters. Toda money/items/identity/phone via `Bridges.Bank.*`, `Bridges.Inventory.*`, `Bridges.Identity.*`, `Bridges.Phone.*`.

#### 5.4.1 Bridges.Bank new exports

```pseudo
Bridges.Bank.GetBalance(citizen_id, iban?) -> decimal
Bridges.Bank.Transfer(from_iban, to_iban, amount, concept, actor_role, request_id) -> { success, error_code? }
Bridges.Bank.GetMovements(iban, filters, limit, offset) -> [movement]
Bridges.Bank.CreateBeneficiary(owner_account_id, target_iban, alias) -> beneficiary_id
Bridges.Bank.IssueCard(account_id, tier, pin) -> card_id
Bridges.Bank.FreezeCard(card_id, by_actor) -> bool
Bridges.Bank.CreateRecurring(...) -> recurring_id
Bridges.Bank.CreateSpace(account_id, name, goal_amount) -> space_id
Bridges.Bank.RaiseComplianceFlag(account_id, flag_type, severity) -> flag_id
```

#### 5.4.2 Bridges adapters T2 (ESX/QBCore wraps)

- ESX: wrap `xPlayer.getMoney('bank')` / `xPlayer.addMoney('bank', amount)` / etc.
- QBCore: wrap `Player.PlayerData.money.bank` / `Player.Functions.AddMoney('bank', amount)` / etc.
- QBox: native (T1 primary).

**Nuevo adapter T2:** wraps deben publicar `sonar_bank_movements` + `sonar_audit_log` entries paralelo a la framework wrap, para mantener Bank ledger truth en Bridges layer. **Trade-off:** ESX/QBCore servers run Bank funcional pero NO usan `sonar_bank_accounts` como source of truth → tienen "Bank Lite mode" donde Bank app rinde las features pero balance vive en framework money.bank. Documented en `07_bridges_compatibility.md` extends Phase A.

### 5.5 Sub-resources scope outline

#### 5.5.1 `sonar_companies` (existing partial — extends Phase A)

- DDL ya partial in shipped (sonar_companies + sonar_company_members tables existing).
- Phase A scope: callbacks C080-C086 + extends DDL (`sonar_company_invoices`).
- FSMs `invoice_lifecycle` + `payroll_lifecycle`.
- Bridges hook con `sonar_bank` para multi-cuenta empresarial.
- Owner: `resources/sonar_companies/`.

#### 5.5.2 `sonar_govt` (NEW)

- DDL: `sonar_govt_tax_brackets` + `sonar_govt_tax_collections` + `sonar_govt_subsidy_programs` + `sonar_govt_subsidy_disbursements`.
- Callbacks C050-C057.
- FSM `compliance_check_lifecycle`.
- Cron jobs: tax collection monthly + subsidy disbursement monthly + compliance flag autoraise.
- ACE permission `sonar.govt` (gate Govt console + admin actions).
- Mode flag `Config.Govt.Mode` = `npc_managed` (default) | `player_elected` (Q1).
- Owner: `resources/sonar_govt/`.

#### 5.5.3 `sonar_loans` (NEW)

- DDL: `sonar_loan_templates` + `sonar_loan_applications` + `sonar_loans_active` + `sonar_loans_payments`.
- Callbacks C070-C075.
- FSM `loan_lifecycle`.
- Cron repayment monthly + delinquency check.
- Credit score recalc cron.
- Owner: `resources/sonar_loans/`.

#### 5.5.4 `sonar_invest` (NEW — T4)

- DDL: `sonar_invest_tickers` + `sonar_invest_holdings` + `sonar_invest_transactions` + `sonar_invest_stakes`.
- Callbacks C060-C068.
- Market simulation engine (volatility + regime + FOMO + crashes).
- Owner: `resources/sonar_invest/`.

#### 5.5.5 `sonar_bank_app` (NEW — frontend resource)

- React + Vite + TS bundle.
- 3 surface modes (standalone / tablet embed / lb-phone bridge).
- Routing tree per §4.1.2.
- Component library Phase B.
- Owner: `resources/sonar_bank_app/`.

### 5.6 State Bags extends

> Per `@docs/technical/01_architecture.md` §5: State Bags entity-attached for ephemeral UI sync (NO source of truth N3).

| State Bag key | Owner | Consumer | Purpose |
|---|---|---|---|
| `bank.balance.{iban}` | sonar_bank server | NUI Tablet/Bank | Real-time balance update on transfer |
| `bank.compliance.flagged.{citizen_id}` | sonar_govt server | NUI Bank app | Show compliance badge in header |
| `bank.subsidies.eligible.{citizen_id}` | sonar_govt server | NUI Bank app | Show subsidies available banner |
| `bank.cards.frozen.{card_id}` | sonar_bank server | NUI cards view | Show freeze status realtime |
| `bank.escrow.locked.{escrow_id}` | sonar_bank server | NUI escrow hub | FSM state realtime |

### 5.7 Events catalog v1.3 promote

> Per `@docs/technical/02_events_catalog.md` v1.1+: events fire-and-forget. Phase A promotes to v1.3.

#### 5.7.1 New events propose

```
sonar:bank:deposit_completed       payload: {citizen_id, iban, amount, request_id, ts}
sonar:bank:withdraw_completed      payload: {citizen_id, iban, amount, request_id, ts}
sonar:bank:card_frozen             payload: {card_id, by_actor, reason, ts}
sonar:bank:card_unfrozen           payload: {card_id, by_actor, ts}
sonar:bank:recurring_executed      payload: {recurring_id, from_iban, to_iban, amount, ts}
sonar:bank:dispute_raised          payload: {dispute_id, movement_id, raised_by, ts}
sonar:bank:compliance_flag_raised  payload: {flag_id, account_id, flag_type, severity, ts}
sonar:bank:compliance_flag_resolved payload: {flag_id, decision, resolved_by, ts}

sonar:govt:tax_collected           payload: {tax_type, account_id, amount, period, ts}
sonar:govt:subsidy_disbursed       payload: {program_id, recipient_account_id, amount, ts}
sonar:govt:sanction_imposed        payload: {flag_id, account_id, sanction_type, ts}
sonar:govt:treasury_balance_low    payload: {balance, threshold, ts}

sonar:loans:application_received   payload: {application_id, applicant, amount, ts}
sonar:loans:approved               payload: {loan_id, applicant, principal, ts}
sonar:loans:denied                 payload: {application_id, applicant, reason, ts}
sonar:loans:payment_processed      payload: {loan_id, amount, paid_at, principal_portion, interest_portion}
sonar:loans:delinquent             payload: {loan_id, applicant, days_late, ts}

sonar:invest:price_update          payload: {ticker, price, regime, ts} (high freq, throttled)
sonar:invest:trade_executed        payload: {account_id, ticker, action, quantity, price, ts}
sonar:invest:market_event          payload: {event_type, affected_tickers, magnitude, ts}

sonar:companies:invoice_created    payload: {invoice_id, issuer, recipient, amount, due_date, ts}
sonar:companies:invoice_paid       payload: {invoice_id, paid_at, ts}
sonar:companies:payroll_executed   payload: {company_id, total_amount, employees_count, ts}
```

### 5.8 Audit trail regulatory-grade module

> Phase A: extender `sonar_audit_log` con columns `actor_role` + `correlation_id` + `severity` + `regulatory_flags`. Crear módulo `lib/audit.lua` reutilizable cross-resource con API:

```pseudo
Audit.Log({
  category = 'bank.transfer',
  actor_citizen_id = source_citizen_id,
  actor_role = 'player',  -- new
  target_iban = to_iban,
  amount = amount,
  concept = concept,
  reference = movement_id,
  correlation_id = uuid_v4(),  -- new — links related entries
  severity = 'info',  -- new
  regulatory_flags = bitmap_zero,  -- new
  source_resource = 'sonar_bank',
  ts = unix_ts(),
})
```

**Inmutable:** UPDATE/DELETE en `sonar_audit_log` blocked via DB triggers + ACE check. Solo INSERT permitted. Compliance regulatory-grade requirement.

**Hot retention:** 24 months (per existing schema §11). Cold archival indefinido.

**Indexes:** `idx_audit_actor` + `idx_audit_target` + `idx_audit_correlation` + `idx_audit_category` + partition por `ts` mensual.

### 5.9 Rate limits canonical extends

> Per `@docs/technical/04_api_contracts.md` §8.1.

#### 5.9.1 New limits propose

| Callback category | Limit Phase A |
|---|---|
| Govt admin reads | 60 / 10s per ACE-actor (no per-citizen — admin tools) |
| Govt admin writes | 30 / 10s per ACE-actor |
| Compliance flag review | 30 / 10s per ACE-actor |
| Loan application | 1 / 24h per citizen-id |
| Loan early payment | 10 / 60s per citizen-id |
| Invest stocks/crypto trade | 20 / 60s per citizen-id |
| Invoice creation | 10 / 60s per company manager |
| Recurring create | 5 / 60s per citizen-id |
| Card issue | 5 / 60s per citizen-id |
| Beneficiary add | 20 / 60s per citizen-id |

### 5.10 Technical boot orchestration Phase A

```
Server boot order (Phase A):

1. sonar_core              (existing — DB + helpers + identity hooks + audit log base)
2. sonar_bridges           (existing — adapter registry)
3. sonar_govt              (NEW — DDL govt + tax brackets seed + cron registry)
4. sonar_companies extends (existing — DDL invoices + cron payroll)
5. sonar_bank extends      (existing — DDL cards/recurring/spaces/etc. + callbacks new C006-C0XX)
6. sonar_loans             (NEW — DDL loans + cron repayment)
7. sonar_invest            (NEW — DDL invest + market simulation cron T4)
8. sonar_tablet            (existing — adds Bank app icon to Bridge home)
9. sonar_bank_app          (NEW — NUI resource standalone + bridge consumers)
10. sonar_smoke_test       (extends — Bank suite ~80+ steps)
```

---

## 6. Roadmap — Phases A-E

> **Mandato founder:** *"montamos la app completa completa, solo lo que podemos hacer es en partes"*. Phase = horizontal technical slice. **Sub-tags `bank-phase-{a..e}-complete` per Phase = dev-ops milestones internos** ("seguro de vida"). **Single-tag final `sonar-bank-v1` Phase E = jugador-visible.**

### 6.1 Phase A — Backend Foundation Complete

**Sub-tag interno:** `bank-phase-a-complete` · **Sesiones est.:** 4-6 (~16-24h) · **Foco:** TODA backend infrastructure shippable + smoke backend-only. **CERO frontend new.**

**Entregables:**
- DDL extends 12+ tablas (§5.2) via migrations 010+.
- Resources skeleton: `sonar_govt` + `sonar_loans` + `sonar_invest` + `sonar_bank_app` (skeleton fxmanifest).
- Callbacks C006-C0XX ~30 nuevos implementados Lua per signatures §5.1.
- FSMs 8 nuevos con transition tables + guards + audit hooks per §5.3.
- Bridges Layer T2 wraps + new exports `Bridges.Bank.*` per §5.4.
- State Bags publishers + Events catalog v1.3 promoted.
- Audit module `lib/audit.lua` shared cross-resource per §5.8.
- Rate limits canonical extends per §5.9.
- Cron jobs registered: tax + subsidy + repayment + payroll + market + compliance.
- Smoke backend-only ~30 steps.

**Done criteria:**
- [ ] Server boot orchestration §5.10 ejecutado clean.
- [ ] Smoke backend 30/30 ✅.
- [ ] `@docs/technical/04_api_contracts.md` v1.3 propose con C006-C0XX.
- [ ] `@docs/technical/03_db_schema.md` v1.2 propose con tablas.
- [ ] `@docs/technical/05_state_machines.md` v1.1 promote con FSMs.
- [ ] `@docs/technical/02_events_catalog.md` v1.3 promote.
- [ ] Tag git `bank-phase-a-complete`.
- [ ] Founder green-light Phase B.

**Risks:**
- 🚩 Bridges T2 "Bank Lite mode" trade-off requires founder ADR Q16.
- 🚩 Govt mode flag (Q1) requires resolution pre-Phase-A start.

### 6.2 Phase B — Frontend Foundation + Design System

**Sub-tag interno:** `bank-phase-b-complete` · **Sesiones est.:** 2-3 (~8-12h) · **Foco:** Resource frontend skeleton + design system completo + 0 vistas.

**Entregables:**
- `sonar_bank_app` resource bootstrap (Vite + React 18.3 + TS strict).
- Tailwind v4 `@theme` con extended palette tokens (ADR-017 D1-D4).
- Component library Bank ~25 componentes:
  * `<BankWindow>` shell + `<BankTabletEmbed>` + `<BankPhoneBridge>` per §3.5.
  * `<Sidebar>` + `<HeroBalanceCard>` + `<QuickActionsGrid>` + `<TransactionRow>` + `<BeneficiaryRow>`.
  * `<WizardStepper>` + `<HeroAmountInput>` + `<EmojiPalette>` + `<HoldConfirmButton>`.
  * `<ReceiptCard>` + `<DigitalSeal>` + `<EscrowCard>` + `<TimelineFSMViz>`.
  * Charts presets `<DonutCategories>` + `<TrendStacked>` + `<ProgressGauge>` + `<SparklineHero>` + `<CashFlowForecast>` per §4.17.
  * `<CardVisual>` (tier-aware) + `<CardStack>` + `<ComplianceBadge>` + `<GovtConsoleHeader>`.
- Recharts theme tokens (extended palette + animation defaults).
- Framer Motion presets new 12 (per §4.13.2).
- Sound triggers wiring (5 + 2 opcionales Q11) per §4.14.
- Routing tree per §4.1.2.
- Bridge consumers cross-resource (NUI msg `bank:open` + surface prop).
- Vite dev page demo `/dev/components` (Q15).
- Smoke design system ~20 steps.

**Done criteria:**
- [ ] Bank app abre standalone window 1440×900 con shell vacío.
- [ ] Bank app abre Tablet embed 1280×800 (sidebar collapsed).
- [ ] Bank app abre lb-phone bridge 358×704 (bottom tab nav).
- [ ] Component library 25 componentes ✅.
- [ ] Tag `bank-phase-b-complete`.
- [ ] Founder green-light Phase C.

**Risks:**
- 🚩 Q4 resource architecture decision bloquea arranque.
- 🚩 ADR-017 (Q2) firma requerida pre tokens.

### 6.3 Phase C — Frontend Views Implementation

**Sub-tag interno:** `bank-phase-c-complete` · **Sesiones est.:** 6-10 (~24-40h, parallelizable INTRA-Phase entre AI agents) · **Foco:** TODAS las vistas funcionales + interactions + animations + sound.

**Entregables vistas (16+):**
- Dashboard (Wireframe 1).
- Cuentas multi-account + Spaces drill.
- Movimientos (History C003-powered + virtual list + filter pills + search + sort).
- Wizard transfer 4-step ceremonial (Wireframe 2).
- Receipt PDF-class (Wireframe 3).
- Escrow hub (Wireframe 4).
- Insights view (Wireframe 5).
- Beneficiaries CRUD + Recurrentes / Standing orders / Direct debits + Subscriptions tracker.
- Loans hub (Wireframe 10).
- Cards virtual + physical + tier escalation (Wireframe 9).
- Limits config + Settings + Multi-currency wallet (T4).
- **Government Console** (Wireframe 6, ACE-gated) — moat puro.
- **Business owner Dashboard** (Wireframe 7) — moat puro.
- **Audit Explorer** (Wireframe 8) — moat puro.
- Notifications panel + Stocks/Crypto views (T4) + ATM minigame (T4).

**Done criteria:**
- [ ] 16+ vistas conectadas a callbacks reales C001-C0XX.
- [ ] Wizard transfer end-to-end con animations + sound.
- [ ] Receipt PDF download via jspdf client-side.
- [ ] FSM viz Escrow + Loan + Card animadas correctly.
- [ ] Govt console renders solo si ACE check passes.
- [ ] Business dashboard renders solo si player es founder/manager.
- [ ] Smoke views ~50 steps ✅.
- [ ] Tag `bank-phase-c-complete`.

**Risks:**
- 🚩 Volume work — más grande Phase. Cuidado scope creep.
- 🚩 ATM minigame T4 puede ser cuello (DOM dialog vs Three.js — Q7).
- 🚩 Audit Explorer virtual list 1M+ entries pagination perf.

### 6.4 Phase D — Polish + Integration

**Sub-tag interno:** `bank-phase-d-complete` · **Sesiones est.:** 2-3 (~8-12h) · **Foco:** Polish total + accesibilidad + perf + integration smoke.

**Entregables:**
- Motion choreography full pass.
- Sound triggers full coverage.
- Empty states personality 8+ vistas (per §4.2.3).
- Error states personality (per §4.2.2).
- Onboarding first-time flow (per §4.2.4 / Q9).
- Accessibility AAA pass: aria-labels + keyboard nav + focus indicators + contrast.
- Perf audit:
  * Bundle <1.2MB gzip target.
  * Render p99 <16ms (60fps).
  * Audit Explorer virtual list smooth scroll 1M entries.
- Integration `sonar_tablet` Bank app icon + click → loads embed.
- Integration lb-phone Bank app registered + slim shell.
- Integration `sonar_inventory` `bank_card` item + theft + ATM swallow.
- Integration `sonar_police` fines event hook → Govt treasury.
- Cross-resource state bags consume verified.

**Done criteria:**
- [ ] Motion + sound consistency full ✅.
- [ ] Smoke integration ~20 steps ✅.
- [ ] A11y audit AAA.
- [ ] Perf audit results documented.
- [ ] Tag `bank-phase-d-complete`.
- [ ] Founder green-light Phase E.

**Risks:**
- 🚩 Perf audit bottlenecks may require refacto.

### 6.5 Phase E — Smoke + Regression + Ship

**Sub-tag interno:** `bank-phase-e-complete` + **single-tag final `sonar-bank-v1`** · **Sesiones est.:** 1-2 (~4-8h).

**Entregables:**
- Full smoke cumulative S0-current + Bank suite ~80+ steps.
- Regression test pass — existing features no rotas.
- Demo build polish (screenshots/video curated).
- Marketing brief output (Tebex copy + screenshots + feature list).
- Tag git `bank-phase-e-complete` (interno) + `sonar-bank-v1` (jugador-visible único shipping tag).
- SESSION_LOG entry + sprint retro.
- Update `@docs/planning/01_roadmap.md` con Bank app shipped milestone.

**Done criteria:**
- [ ] Smoke 80+/80+ ✅.
- [ ] Regression S0-current full pass ✅.
- [ ] Tags aplicados.
- [ ] Marketing output ready.
- [ ] Founder ✅ ship approval.

### 6.6 Dependency graph cross-Phase

```
Phase A (backend) ──► Phase B (frontend foundation) ──► Phase C (views) ──► Phase D (polish) ──► Phase E (ship)
                                                          │
                                                          ▲
                  └─ sonar_companies extends + sonar_govt + sonar_loans + sonar_invest sub-resources
                     (paralelizables INTRA-Phase A)
```

**Cross-Phase risks:**
- 🚩 Scope creep mid-Phase. Solución: docs SSoT firmable post-Phase-A frozen Phase B-E.
- 🚩 Bridges T2 Bank Lite mode trade-off (Q16). Solución: ADR firmable Phase A start.
- 🚩 Govt mode flag (Q1) unresolved. Solución: bloqueador hard pre-Phase A.
- 🚩 Identity contradictions con extended palette (Q2). Solución: ADR-017 firmable Phase A start.
- 🚩 External lib bundle bloat (jspdf, qrcode.js). Solución: dependency audit Phase B start.

---

## 7. Open Questions

> 16 preguntas decisión gating. Recommendation Cascade per Q. **Founder decisions required pre-Phase A arranque.**

### Q1 🔴 Government entity mode

¿Government NPC system-managed (default ACE-gated) o player-elected via votación periódica?

**Recommendation:** **NPC system-managed v1** + **flag `Config.Govt.Mode`** desde día 1 para futuro `player_elected` upgrade post-Oleada-1. Razones:
- Player-elected requires vote system + RP-cycle calendars + candidate registration + term limits + transition handover.
- NPC-managed evita "elections drama" y mantiene economía estable.
- Flag desde día 1 evita refacto futuro.

**Founder decision:** ☐ NPC v1 / ☐ player_elected v1 / ☐ híbrido

### Q2 🔴 ADR-017 amendment palette

¿Aceptar ADR-017 amendment proposal extended palette layer Bank-app-specific?

**Recommendation:** **Aceptar full** per §8. Sin lo cual no se llega al Fintrixity-class wooow. Identity core preserved (Black + Orange + White dominante). Extended es secondary tier.

**Founder decision:** ☐ Aceptar full / ☐ Aceptar parcial / ☐ Rechazar

### Q3 🔴 C003 `getTransactions` unlock

¿C003 unlock NOW (Phase A) o sigue DEFERRED S3 per ADR-015?

**Recommendation:** **Unlock NOW Phase A.** Bloqueador básico History view premium (filter/search/sort/sticky-tabs/virtual list 1M+). Sin C003 estamos en consumer pattern temporal — tech debt acumulando.

**Founder decision:** ☐ Unlock NOW / ☐ Sigue deferred / ☐ Pre-Phase-A

### Q4 🔴 Resource architecture

¿`sonar_bank_app` resource separado o sub-mount in `sonar_tablet/web-src/src/apps/Bank/`?

**Recommendation:** **Resource separado `sonar_bank_app`.** Razones:
- App es producto autónomo per founder pivot.
- Tablet la consume vía NUI bridge cross-resource.
- lb-phone bridge slim trivial mismo bundle.
- Ship/version independent del Tablet.
- Permite tag `sonar-bank-v1` standalone.

**Founder decision:** ☐ Separado / ☐ Sub-mount / ☐ Otro

### Q5 🔴 Window dimensions standalone

¿1440×900 confirmado o prefieres otra medida?

**Recommendation:** **1440×900 (16:10).** Linear/Stripe-Dashboard-class. Centered con margins ~240+240px en 1920px viewport. Founder constraint "no full screen" respetado. Más grande que Tablet (1280×800) por surface más complejo.

**Founder decision:** ☐ 1440×900 / ☐ 1280×800 / ☐ 1600×1000 / ☐ Otro

### Q6 🔴 Keybind standalone trigger

¿Keybind `M` (Money) o `B` (Bank) o `/bank` solo command?

**Recommendation:** **`M` keybind + `/bank` command + Tablet icon click** (3 trigger paths). Configurable via convar `sonar_bank_keybind`. Default M.

**Founder decision:** ☐ M / ☐ B / ☐ Solo command / ☐ Otro

### Q7 🔴 Tier 4 ATM minigame implementation

¿ATM minigame React Three.js canvas custom o simpler React DOM dialog flow?

**Recommendation:** **React DOM dialog flow PIN entry + CSS keyframes camera-zoom mock.** Razones:
- Three.js canvas adds significant complexity + bundle size + perf risk for marginal gain.
- DOM dialog suficientemente immersive con animation choreography.
- Faster Phase A-C delivery.

**Founder decision:** ☐ Three.js / ☐ DOM dialog / ☐ Native FiveM cam scaleform

### Q8 🔴 Multi-currency T4 scope

¿Multi-currency completo (FX dynamic + per-tx currency choice) o subset (display server-currency + FX-aware analytics)?

**Recommendation:** **Subset for MVP-of-app-complete.** Display server-currency primary + secondary balance display empresas con foreign clients + FX rates pseudo-static config-managed. Full FX dynamic = upgrade post-v1.

**Founder decision:** ☐ Subset / ☐ Completo / ☐ Defer Phase F

### Q9 🔴 Onboarding first-time flow

¿Bank app first-time launch tiene tour/onboarding ceremonial o jump-straight to Dashboard?

**Recommendation:** **Tour 3-step soft skippable.** Welcome → Starter balance explain → IBAN reveal con QR copy. Skippable forever after. Sound `signal_emerge` ceremonial. Pattern Stripe/Linear onboarding.

**Founder decision:** ☐ Tour / ☐ Jump straight / ☐ Otro

### Q10 🔴 Compliance flag autoraise patterns

¿Cuáles patterns trigger autoraise compliance flag?

**Recommendation:** **6 patterns default:** structuring (10x txs near round-amount in 24h) + unusual destination (foreign-prefix IBAN) + large transfer (>€50k single tx) + late tax (>7d overdue) + velocity (>20 txs in 1h) + new-account-large-deposit (account <7d con tx >€10k). Configurable via `Config.Govt.ComplianceFlags`.

**Founder decision:** ☐ 4 default base / ☐ 6 expanded / ☐ Custom set

### Q11 🔴 Optional new SFX

¿Aceptar 2 SFX nuevos (`transfer_complete` success bell + `compliance_alert` warning sub-bass)?

**Recommendation:** **`transfer_complete` ACEPTAR** (mejora ceremonial post-transfer alt path). **`compliance_alert` RECHAZAR** (visual fallback suficiente, audio alarm rompe vibe calmo).

**Founder decision:** ☐ Aceptar 2 / ☐ Solo transfer_complete / ☐ Solo compliance_alert / ☐ Rechazar 2

### Q12 🔴 Tier 4 confirmation

¿Re-confirmar IN-SCOPE: stocks dynamic + crypto + ATM minigame + card robbery + physical card item + cooperative shared accounts + round-ups + crypto staking + bank loyalty?

**Recommendation:** **Locked IN-SCOPE per founder explicit "vamos con todo".** Sin re-debate.

**Founder decision:** ☐ Locked IN / ☐ Cut algunos (cuáles?)

### Q13 🔴 Audit Explorer player scope limits

¿Player puede ver SOLO sus propias entries + correlated, o también las de empresas donde es founder/manager?

**Recommendation:** **3 scopes:** "Mis cuentas" (default player) + "Mis empresas" (si founder/manager) + "Todas" (si ACE govt). UI selector per §4.10.

**Founder decision:** ☐ 3 scopes / ☐ Solo personal + admin / ☐ Otro

### Q14 🔴 Tax brackets default values

¿Tax brackets default valores son los del wireframe Govt Console o conservadores?

**Recommendation:** **Defaults agresivos en `config.lua` con docs explicit** (Sales 8% / Income tier 0/15/25/35% / Wealth 1.2% above €500k). Comentarios extensivos rationale + admin override fácil. Cambios requieren restart server (no UI admin runtime per anti-pattern §2.3).

**Founder decision:** ☐ Defaults agresivos / ☐ Defaults conservadores / ☐ Custom

### Q15 🔴 Phase B Storybook canvas

¿Storybook canvas opcional para Phase B o solo Vite dev page demo?

**Recommendation:** **Vite dev page demo `/dev/components` ruta interna SOLO dev.** Storybook adds dep + complexity para uso interno único. Vite page suficiente.

**Founder decision:** ☐ Storybook / ☐ Vite dev page / ☐ Otro

### Q16 🔴 ESX/QBCore Bridges Bank Lite mode

¿En servidores ESX/QBCore (T2), Bank "Lite mode" o T1-only?

**Recommendation:** **Bank Lite mode T2 funcional.** Razones:
- Compatibility wider audience.
- Bank features all rinden (UI mismo).
- Ledger paralelo para audit trail + correlation.
- Trade-off: balance source-of-truth vive en framework, no en `sonar_bank_accounts`. Documented limitation.

**Founder decision:** ☐ Lite mode T2 / ☐ T1 only / ☐ Otro

### 7.1 Sumario Open Questions

**16 questions identified.** **15 resolved by founder 2026-05-06. Q16 in technical audit (§11).**

| Q | Status | Founder decision |
|---|---|---|
| Q1 | ✅ Resolved | **Configurable per server** (NPC auto OR player elections) — más ambicioso que Cascade rec. Ambos modes funcionales día 1. |
| Q2 | ✅ Resolved | **Aceptar ADR-017 full** — paleta extendida + gradients premium Bank-app-specific. |
| Q3 | ✅ Resolved | **C003 unlock NOW Phase A** — sin tech debt history view. |
| Q4 | ✅ Resolved | **Resource separado `sonar_bank_app`** — autónomo + ship/version independent. |
| Q5 | ✅ Resolved | **1440×900** centered + backdrop oscuro. |
| Q6 | ✅ Resolved | **Multidisparo** — keybind `M` (configurable convar) + `/bank` command + Tablet embed icon. |
| Q7 | ✅ Resolved | **DOM dialog 2D** + CSS animations — descarta Three.js. |
| Q8 | ✅ Resolved | **Multidivisa OFF** — single currency global config server. **Cambio scope:** elimina T4.10 (multi-currency wallet view). DDL `sonar_bank_currencies` se elimina. FX columns `sonar_bank_movements` se eliminan. Simplifica T4. |
| Q9 | ✅ Resolved | **Onboarding 3-step** skippable — saludo + saldo inicial + IBAN/QR reveal. |
| Q10 | ✅ Resolved | **5 patrones autoraise** (no 6) — pitufeo/structuring + transferencias masivas/large + morosidad fiscal/late tax + hiperactividad/velocity + cuentas nuevas alto capital. **Eliminado** "unusual destination foreign-prefix IBAN" porque no aplica (single-currency global + no internacional). |
| Q11 | ✅ Resolved | **`transfer_complete` ACEPTAR** + `compliance_alert` RECHAZAR (visual fallback only). |
| Q12 | ✅ Resolved | **T4 LOCKED IN-SCOPE 100%** — cripto + robo + acciones + cooperativas + staking + ATM minigame + physical card + round-ups + bank loyalty. Cero recortes. |
| Q13 | ✅ Resolved | **3 scopes Audit Explorer** — Mis cuentas / Mis empresas / Todas (ACE govt). |
| Q14 | ✅ Resolved | **Defaults agresivos** `config.lua` — IVA 8% + IRPF progresivo (0/15/25/35%) + Riqueza 1.2% above €500k. Editable por server admin. |
| Q15 | ✅ Resolved | **Vite Dev Page** `/dev/components` — descarta Storybook (no inflar deps). |
| Q16 | ✅ Resolved | **Hybrid 3-layer aprobada + 8 CP integrados + cut ESX <1.10 OFICIAL.** Ver §11.9 final decision. |

### 7.2 Scope changes derivados (post Q1-Q16 resolved)

**Cambios upstream que afectan §3-§6 + §11 (Q16):**

1. **Q1 → Govt mode configurable:** §5.5.2 `sonar_govt` añade `Config.Govt.Mode = 'npc_managed' | 'player_elected'` desde día 1 con FSM completo `election_lifecycle` (estados: `idle`, `nomination_open`, `voting_open`, `vote_count`, `term_active`, `term_expired`). Add tablas `sonar_govt_elections` + `sonar_govt_election_candidates` + `sonar_govt_votes` + callbacks C058-C062 nuevos (`elections:start`, `elections:nominate`, `elections:vote`, `elections:results`, `elections:end_term`).

2. **Q8 → Multidivisa OFF:**
   - Eliminar §3 T4.10 (multi-currency wallet) de feature inventory.
   - Eliminar `sonar_bank_currencies` table de §5.2.1.
   - Eliminar columnas `currency_code` / `fx_rate` propuestas en `sonar_bank_movements`.
   - Single currency display per `Config.Currency.Symbol` (default `€`, configurable `$`/`£`/`¥`/etc.).
   - Server economic model unaffected (todo amounts atomic decimals).

3. **Q10 → 5 patrones autoraise (no 6):**
   - Eliminar `unusual_destination_foreign_prefix` de `sonar_bank_compliance_flags.flag_type` ENUM.
   - 5 patterns canonical: `structuring` + `large_transfer` + `late_tax` + `velocity` + `new_account_large_deposit`.

4. **Q1 → Govt elections T4-class:** scope adicional Phase A:
   - DDL: 3 tablas elections.
   - FSM: `election_lifecycle` (6 estados).
   - Callbacks: C058-C062 (5 nuevos).
   - UI views Phase C: Government Console adquiere "Elections tab" con candidate list + vote button + results display + term countdown.

5. **Q16 → Hybrid 3-layer + 8 CP + cut ESX legacy:**
   - **Core Override** (QBox/QBCore) → monkey-patch runtime + defensive boot (CP4) + watchdog 30s.
   - **Lite Mode Triple Capa** (ESX 1.10+ ONLY) → event hooking + correlation-id mutex (CP2 only path, NO hash-fallback) + reconciliation pipeline async (CP3) + scope main_account only (CP6) + threshold auto-apply €1000 (CP5).
   - **Cut ESX <1.10 OFICIAL** → out-of-scope policy. fxmanifest dependency declarará ESX ≥1.10 mínimo. Boot defensive abort si detecta ESX legacy + console banner explanation + KVP `sonar_bank_disabled = unsupported_esx_legacy`.
   - **State Bags global refactor §5.6 (CP1)** → reemplaza `TriggerClientEvent` publishers Bank balance/account changes con `GlobalState[bank.balance.<citizen_id>] = value` + `AddStateBagChangeHandler` client-side reactive.
   - **Lite mode FSM `sonar_bank_status` (CP8)** → 4 states: `native_full` / `lite_mode_active` / `compromised_load_order` / `framework_missing`. UI badge footer Bank app sidebar always visible (transparency player).
   - **README install + convars `sv_experimental*` (CP7)** → docs entregable Phase A done criteria.
   - **Smoke chaos test Phase A** → done criteria add: lag spike injection 200ms-1s + 200 concurrent reconciliations + multi-framework matrix (QBox + QBCore + ESX 1.10+ ONLY, ESX legacy intencional FAIL boot expected).
   - **+1 FSM nuevo** (`sonar_bank_status`).
   - **+2 lib modules shared** (`lib/mutex_echo.lua` + `lib/reconciliation.lua`).
   - **+ADR-018 firma** post Phase A start: "Bank Lite mode hybrid 3-layer + correlation-id mutex + cut ESX legacy + 8 mitigation patterns".

**Total ajuste callbacks Phase A:**
- Anterior estimado: ~30 callbacks new (C006-C0XX).
- Post Q1: ~35 callbacks (5 elections nuevos).
- Total Phase E: ~40 callbacks Bank-domain.

**Total ajuste DDL Phase A:**
- Anterior estimado: 12+ tablas nuevas.
- Post Q1: 15+ tablas nuevas (-1 currencies + 3 elections).

**Total ajuste FSMs Phase A:**
- Anterior estimado: 8 FSMs (escrow/contract/dispute/loan/credit_score/election_lifecycle/etc.).
- Post Q16: 9 FSMs (+`sonar_bank_status` Lite mode).

**Total ajuste lib modules shared:**
- Post Q16: +2 (`lib/mutex_echo.lua` correlation-id store + `lib/reconciliation.lua` async worker queue).

---

## 8. Identity preserved + ADR-017 amendment proposal

### 8.1 Identity SONAR core preserved (immutable)

Per N1 + ADR-016 D1+D2+D4+D5+D6 mantained 100%:

| Aspecto | Token canonical | Status |
|---|---|---|
| Canvas | `--sonar-black` `#060607` | Immutable |
| Brand primary | `--sonar-orange` `#FF5100` | Immutable |
| Foreground | `--sonar-white` `#FAFAFA` | Immutable |
| Theme | Dark-only forever | Immutable |
| Voz | Spanish neutral premium-tech (Vercel/Linear/Stripe/Apple Pro) | Immutable |
| Sound | 5 SFX canonical | Immutable + 1 propose new (Q11) |
| Iconography | Lucide bridge S2-S3 → 8 abstract custom S3+ | Per ADR-016 D5 — bridge mantained |
| Stack | React 18.3 + Vite 5 + TS strict + Tailwind v4 + shadcn dark-only + Framer + Lucide + Recharts | Per ADR-016 D5 — frozen S2-S8 |

### 8.2 ADR-017 amendment proposal — Bank extended palette layer

**Title:** ADR-017 — Bank app extended palette layer over canonical 3-token theme.

**Status:** PROPOSAL — pre founder review.

**Decision:** introducir un **second-tier palette layer** específico Bank-app que extiende el canonical 3-token (`--sonar-black` + `--sonar-orange` + `--sonar-white`) con 4 sub-decisiones D1-D4:

#### D1 — Brand gradients (Orange spectrum extends)

Tokens nuevos `--color-sonar-orange-{50,100,300,500,700,900}` para gradient hero cards + glow halations + tier-aware backgrounds (Cards Black tier glow Orange).

**Justification:** Sin gradient Orange spectrum, hero cards quedan flat opacity solo. Fintrixity refs founder demand Orange→Black gradients. Identity Orange brand mantained — solo se le da spectrum.

#### D2 — Semantic functional re-introduced

| Token | Hex | Use |
|---|---|---|
| `--color-sonar-success` | `#5FB89A` (soft teal) | Incoming transactions, balance positive delta, loan paid_off, escrow released |
| `--color-sonar-warn` | `#FBBF24` (amber) | Near limits, approaching due_date, late tax warn, compliance flag low severity |
| `--color-sonar-critical` | `#E85D5D` (soft red) | Errors, fraud, sanctions, dispute raised, compliance flag critical, OVERDUE invoices |
| `--color-sonar-info` | `#60A5FA` (soft blue) | Informational tooltips, Govt subsidy disbursed, neutral notifications |

**Justification:** Sin semantic functional, todos los estados visuales del Bank quedan en single-color Orange — imposible distinguir "transferencia recibida" de "tarjeta congelada" de "dispute raised". Los 4 colores son **soft / desaturated** — alineados con dark canvas SONAR + non-jarring + accessible WCAG AAA.

**Anti-pattern evitado:** verde/rojo flat sin context — sustituido por Lucide icons direccionales `<ArrowUpRight Orange/>` `<ArrowDownLeft White/>` PLUS opcional opacity weight semantic. NO uso primario de verde/rojo for direction — reserved for status críticos.

#### D3 — Brand gradient tones (hero/promo cards)

| Token | Hex | Use |
|---|---|---|
| `--color-sonar-pink-500` | `#FF6B9D` | Orange→Pink gradient hero promo cards (Stripe-class) |
| `--color-sonar-amber-500` | `#FFA94D` | Orange→Amber gradient alternate (warmth) |

**Justification:** Hero balance card gradient + onboarding welcome gradient + promo upsell rewards. Fintrixity refs founder validan estos tones.

#### D4 — Category color-coding (data viz Recharts series)

8 tokens category-specific opt-in user setting. Allow Apple-Card-class spending viz. Categories: housing/food/transport/salary/tax/shopping/leisure/other.

**Justification:** Sin category palette, donut + bar charts Insights view son flat single-color — ilegible visualmente cuando hay 8+ categories simultaneous. Apple Card / Revolut / N26 todos usan category colors.

**Opt-in:** user setting `Config.User.CategoryColorsEnabled` boolean. Default `true` para new accounts. Disable → fallback Orange spectrum (Orange-300/500/700) variations.

### 8.3 ADR-017 scope limits

**Hard scope:** Bank app extended palette es **Bank-app-specific** — NO extiende a otras apps Tablet (`sonar_tablet/apps/Bridge` / `apps/Notes` / etc.) sin nuevo ADR explícito.

**Hard rule:** Identity SONAR core (Black + Orange + White dominante) **NO se desplaza** del lugar visual primary. Extended palette solo aplica a:
- Chart series (Recharts).
- Semantic functional states (4 colors).
- Brand gradients hero cards (2 tones).
- Category colors (8 tokens, opt-in).

**Dominancia visual canonical:** dark canvas + Orange brand + White foreground siempre dominantes. Extended palette es **accent secondary tier**.

### 8.4 ADR-017 firma proposal

| Field | Value |
|---|---|
| **ADR ID** | 017 |
| **Title** | Bank app extended palette layer over canonical 3-token theme |
| **Status** | PROPOSAL → Accepted (post founder green-light Q2) |
| **Date** | 2026-05-05 propose |
| **Decision-makers** | Founder yaboula + Cascade Sonnet 4.6 |
| **Supersedes** | None — extends ADR-016 D3 (3-color strict) Bank-app-specific only. |
| **Related** | ADR-016 (identity v3 lock) + ADR-012 (voz neutral premium-tech) |
| **Hard rule** | NO extender extended palette a otras apps Tablet sin nuevo ADR |
| **Review trigger** | Si feedback usuario revela problemas accesibilidad o identity drift, revisar Q4 2026 |

### 8.5 Anti-patterns refs Fintrixity flagged explícitos

> Founder refs `@d:/theBigProject/resources/sonar_bank/simple-ref-bank-ui/` son inspiration **VISUAL** (composición + cards stack + sparkline + bars) **NO de identity**. Anti-patterns explícitos rechazados:

| Fintrixity ref pattern | SONAR rechaza | Solución SONAR |
|---|---|---|
| `+$25,00` verde flat / `-$5,00` rojo flat | Sí | Lucide icon `<ArrowUpRight Orange/>` `<ArrowDownLeft White/>` + amount weight |
| Light theme toggle (moon/sun) | Sí | Dark-only forever (N1 + ADR-016 D1) |
| "Trusted by Thousands! Join Us Today!" promo card | Sí | Voz neutral premium-tech zero promo in-app (N1 + 4.2) |
| Avatar profile photo persona generic | Sí | Lucide `User` icon placeholder hasta avatar system Oleada-2 |
| "VISA / Mastercard" logos brand co-marketing | Sí | "SONAR Black/Gold/Platinum/Basic" only — own branding |
| "Earnings $84,000 average annual rate" marketing copy | Sí | Tooltip funcional only, no marketing claims |

---

## 9. Appendix

### 9.1 Glossary

- **Actor role:** discriminator transactional (`player`, `empresa`, `govt`, `system`) en `sonar_bank_movements` + `sonar_audit_log`.
- **Bank Lite mode:** mode T2 ESX/QBCore donde balance vive en framework money.bank + Bank ledger paralelo (Q16).
- **Compliance flag:** entry en `sonar_bank_compliance_flags` triggered automatic patterns + manually Govt review.
- **Correlation ID:** UUID linking related audit log entries (e.g., transfer = 2 entries — debit + credit — same correlation).
- **Escrow:** account técnico interno tipo `escrow` en `sonar_bank_accounts.type` para holding payments.
- **Extended palette:** ADR-017 amendment 4 layers tokens secondary tier Bank-app-specific.
- **Govt entity:** NPC system-managed actor con ACE `sonar.govt` + treasury seed `AD-SYS0-0000-0001`.
- **IBAN:** formato SONAR `AD-XXXX-XXXX-XXXX` checksum interno.
- **Moat:** layer Government NPC + Empresas player-driven que diferencia SONAR Bank de competitors FiveM.
- **Phase:** horizontal technical slice (A-E) per founder mandato "no MVP, app completa, work troceado en partes".
- **Sello digital SONAR ✦:** elemento visual Receipt + decorative checkmark + glow + hash SHA-256 truncated visible. Identity SONAR único.
- **State Bag:** entity-attached ephemeral data sync para UI realtime updates (NO source of truth).
- **Sub-tag:** dev-ops internal milestone tag `bank-phase-{a..e}-complete` (founder "seguro de vida"). NO jugador-visible.
- **Surface:** modo render Bank app (standalone window 1440×900 / Tablet embed 1280×800 / lb-phone bridge 358×704).
- **Tier 1-4:** taxonomy conceptual features (NO roadmap incrementality). T4 in-scope per founder.

### 9.2 FAQ pre-anticipated founder

**P1: ¿La Bank app reemplaza la Tablet Bank app shipped S2.4?**
**R:** Sí — Phase D integration step replaces existing `sonar_tablet/web-src/src/apps/Bank/` con embed wrapper que carga `sonar_bank_app` resource. Existing 3-tab MVP es deprecated. Migration path: Phase D step 1 = swap.

**P2: ¿Cuántas semanas de calendar hasta Phase E ship?**
**R:** Depende cadencia sesiones. Si 1 sesión/día = ~3-4 semanas. Si 2 sesiones/día = ~2-3 semanas. Sin límites founder mandato — quality first.

**P3: ¿Qué pasa si scope cut tardío necesario?**
**R:** Cut order: Tier 4 first (T4.1-T4.10) → Tier 3 less critical (T3.7 patterns/anomaly + T3.13 player-elected govt) → Tier 2 less critical. Tier 1 + Tier 3 core (govt console + business dashboard + audit explorer + escrow hub + treasury forecast) son bloqueadores moat — no cuttable.

**P4: ¿Cuánto bundle size esperado?**
**R:** Target <1.2MB gzip Phase B-D. Sin hard cap pero p99 esperado dado deps. Audit Phase D.

**P5: ¿Compatibilidad ESX/QBCore es full-features o limited?**
**R:** Q16 — Bank Lite mode T2 funcional con balance source-of-truth en framework money.bank + Bank ledger paralelo. UI renders todas features iguales. Trade-off documented limitation.

**P6: ¿Phase E single-tag `sonar-bank-v1` significa MVP shipping?**
**R:** **NO.** Phase E ship = **app completa completa shippable** con 51 features (T1+T2+T3+T4 all). Sub-tags `bank-phase-{a..e}-complete` son internos dev-ops milestones (founder "seguro de vida") — no jugador-visible. Single-tag final = production release.

**P7: ¿Reusable componentes para futuras apps Tablet?**
**R:** Sí — design system Phase B se hace extensible. Future Tablet apps (Notes / Empresa management standalone / Mercado / Logística) consumen los componentes via shared lib (extracción opcional post-v1 si demanda lo justifica).

**P8: ¿Marketing material output Phase E?**
**R:** Brief breve — Tebex listing copy + 6-8 screenshots curated + feature list bullets + 30-sec demo video script. Founder review final pre-publish.

### 9.3 Externos refs

- **NeedForScript:** `https://needforscript.gitbook.io/needforscripts/our-scripts/banking-script` + `https://forum.cfx.re/t/needforscript-banking-script-with-loans-savings-cards-more/5268794`.
- **RX Advanced Banking:** `https://fivem.rxscripts.xyz/scripts/advanced-banking`.
- **ak47 Banking:** `https://forum.cfx.re/t/advanced-banking-script-fivem-ak47-banking-esx-qb-qbx/5397367`.
- **okokBanking:** `https://forum.cfx.re/t/okokbanking-qbcore-esx-paid/4751646`.
- **LB-Phone Wert Bank:** `https://forum.cfx.re/t/wert-lb-phone-bank-application/5352327`.
- **Fleecanow:** `https://forum.cfx.re/t/fleecanow-lb-phone-banking-addon-app/5352337`.
- **Stripe Dashboard docs:** `https://docs.stripe.com/dashboard/basics`.
- **Revolut / N26 / Apple Card / Linear / Vercel:** training knowledge refs (UX patterns).
- **Fintrixity ref local:** `@d:/theBigProject/resources/sonar_bank/simple-ref-bank-ui/` (visual composition only — anti-patterns flagged §8.5).

### 9.4 Cross-reference index

**SSoTs canonical referenciados:**

- `@docs/00_PRODUCT_BIBLE.md` — filosofía proyecto.
- `@docs/economy/01_economic_model.md` — números económicos canónicos.
- `@docs/technical/01_architecture.md` — Bridges Layer + State Bags + EventBus.
- `@docs/technical/02_events_catalog.md` v1.1 → v1.3 promote propose.
- `@docs/technical/03_db_schema.md` v1.1 → v1.2 propose con tablas nuevas Phase A.
- `@docs/technical/04_api_contracts.md` v1.2 → v1.3 promote con C006-C0XX.
- `@docs/technical/05_state_machines.md` v1.0 → v1.1 promote con FSMs nuevos.
- `@docs/technical/06_fivem_standards.md` — performance budgets + security + sync.
- `@docs/technical/07_bridges_compatibility.md` — extends T2 Bank Lite mode (Q16).
- `@docs/planning/01_roadmap.md` — Bank app pivot milestone.
- `@docs/planning/02_decision_log.md` — ADR-016 (identity v3) + ADR-017 (extended palette propose).

**Sprints existentes consumed:**

- `@progress/SPRINT_PLAN_S0.md` — Bridges + scaffolding shipped.
- `@progress/SPRINT_PLAN_S1.md` — Bank core + escrow + audit shipped.
- `@progress/SPRINT_PLAN_S2.md` — Tablet shipped (Bank app S2.4 MVP integrado).
- `@progress/SESSION_LOG.md` — historial sesiones.

**Resources existentes consumed:**

- `resources/sonar_core/` — DB + helpers + identity hooks + audit log base.
- `resources/sonar_bridges/` — adapter registry.
- `resources/sonar_bank/` — DDL + callbacks C001-C005 shipped.
- `resources/sonar_tablet/` — UI Tablet host + Bank app S2.4 (deprecated Phase D).
- `resources/sonar_bank/simple-ref-bank-ui/` — Fintrixity visual ref (anti-patterns flagged).

**Resources nuevos Phase A:**

- `resources/sonar_govt/` (NEW).
- `resources/sonar_loans/` (NEW).
- `resources/sonar_invest/` (NEW T4).
- `resources/sonar_bank_app/` (NEW Phase B+).
- `resources/sonar_companies/` (existing partial — extends Phase A).

---

## 10. Closure

**Document length:** ~2350 líneas en 10 secciones + appendix.

**Status:** PROPOSAL v1.0 — pre founder review.

**Next steps post founder review:**

1. **Founder lee blueprint full + responde 16 Open Questions §7.**
2. **Cascade applies Q decisions** → blueprint v1.1.
3. **Promote SSoTs:**
   - `@docs/technical/04_api_contracts.md` v1.2 → v1.3 (callbacks new).
   - `@docs/technical/03_db_schema.md` v1.1 → v1.2 (tablas nuevas).
   - `@docs/technical/05_state_machines.md` v1.0 → v1.1 (FSMs nuevos).
   - `@docs/technical/02_events_catalog.md` v1.1 → v1.3 (events).
   - `@docs/technical/07_bridges_compatibility.md` extends Bank Lite mode T2.
4. **ADR-017 firma** post Q2 founder green-light.
5. **`@docs/planning/01_roadmap.md` update** con Bank app Phases A-E + sub-tags + single-tag.
6. **Sprint plan Phase A** crea `@progress/SPRINT_PLAN_BANK_PHASE_A.md` con todos los entregables §6.1.
7. **Phase A start** post all SSoTs firmados + ADR-017 accepted + Q1+Q4+Q16 resolved.

**Final note founder:**

Esta blueprint es la mapa completa de lo que vamos a construir. **App completa. Sin recortes. Sin MVP shipping engaño.** Phase A-E son slices técnicos para troceado de work, no son releases incrementales — el tag final único `sonar-bank-v1` es el shipping milestone real Phase E.

El moat (Government Console + Empresas Dashboard + Audit Explorer regulatory-grade + Escrow B2B FSM viz + Treasury cash flow forecast) está blueprinted. El polish premium-tech (wizard ceremonial 4-step + receipt PDF + glassmorphism + sound + extended palette + 12 motion presets + 6 chart presets) está blueprinted. El backend regulatory-grade (audit ledger inmutable + compliance flags autoraise + tax brackets + subsidies + credit score + loan FSM) está blueprinted.

**Falta solo: tu decisión 16-Q + green-light Phase A start.**

— Cascade Sonnet 4.6 · 2026-05-05.

---

## 11. Q16 Compatibility Audit Report — "Modo Lite" estrategia híbrida

> **Status:** ✅ **RESOLVED** — founder decisión cerrada 2026-05-06. Proceder a implementación Phase A.
>
> **Date audit:** 2026-05-06.
>
> **Date decision:** 2026-05-06 (mismo día, post audit review).
>
> **Scope:** auditar la propuesta arquitectónica founder de **Estrategia Híbrida 3-capas** para compatibilidad ESX/QBCore + investigación Cfx.re primitives recientes + identificar edge cases + contrapropuestas.
>
> **Veredicto:** propuesta **APROBADA** + **8 CP integrados (CP1-CP8 all accepted)** + **cut oficial ESX <1.10 out-of-scope** (decisión comercial founder).
>
> **Ver §11.9** para final decision compacta.

### 11.1 Resumen propuesta founder (re-statement audit-target)

**Estrategia 1 — QBox/QBCore "Core Override":** runtime monkey-patch de `Player.Functions.AddMoney` / `RemoveMoney` durante boot (resource load order priority). SONAR intercepta calls externas, redirige a `sonar_bank_accounts`. QBCore PlayerData.money.bank queda como espejo lectura (no source of truth).

**Estrategia 2 — ESX/Lite Mode "Triple Capa":**

- **Capa A — Event Hooking + Mutex semáforo:** registrar listener `esx:setAccountMoney` + cuando SONAR origina la mutación inyecta flag mutex en RAM bloqueando re-procesado del eco.
- **Capa B — Mapeo Híbrido Estricto:** dinero principal vive ESX `users.accounts` (anchor). Premium tiers (savings + escrow + empresa + treasury) viven exclusivos en `sonar_bank_accounts`.
- **Capa C — Reconciliación Activa:** check ultrarrápido saldo RAM ESX vs cache SONAR al abrir Bank app + on player connect. Descuadre → auto-ajuste + audit log entry `bank.compliance.reconciliacion_activa`.

### 11.2 Análisis edge cases críticos

#### 🔴 Edge Case #1 — Mutex desync race condition (Capa A)

**Riesgo:** lag spikes server >500ms o desync onesync extrema pueden causar que el flag mutex en RAM se libere ANTES de que llegue el eco event `esx:setAccountMoney` de la mutación SONAR-originada → eco se procesa como mutación externa → **duplicación fantasma del movimiento**.

**Análisis técnico:**
- FiveM Lua corre coroutine-based scheduler (single-threaded por design — `@docs/scripting-reference/runtimes/lua/functions/Citizen.Wait`). No hay OS threads paralelos.
- **PERO** event dispatch entre resources es **async via netbus interno** — el ack del event listener no garantiza temporalidad determinista bajo lag spike.
- Window race condition real: `bank.transfer` → `xPlayer.setAccountMoney('bank', new_amount)` → set mutex `mutex_esx_echo[citizen_id] = expires_at_ms` → ESX dispatcha event `esx:setAccountMoney` async → si lag spike entre dispatch y receive >`mutex_ttl_ms` → mutex expira → echo se procesa duplicado.
- **No es timer-based bug, es scheduling-based bug** — irreproducible en dev, latente prod.

**Mitigación propuesta:**

1. **Mutex no-TTL-based, sino correlation-id-based:**
   ```pseudo
   -- En SONAR-originated transfer:
   local correlation_id = uuid_v4()
   ESX.SetAccountMoney(citizen_id, 'bank', new_amount, {
     reason = 'sonar_transfer',
     sonar_correlation = correlation_id,  -- inject metadata
   })
   register_pending_echo(correlation_id)

   -- Listener echo:
   AddEventHandler('esx:setAccountMoney', function(player, account, money, reason)
     if reason and reason.sonar_correlation and is_pending_echo(reason.sonar_correlation) then
       drop_echo(reason.sonar_correlation)  -- skip + clean
       return  -- silent drop, no double-ledger
     end
     -- Echo desde script externo → procesar como mutation
     handle_external_mutation(player, account, money, reason)
   end)
   ```

2. **Trade-off:** requiere que ESX `setAccountMoney` acepte `reason` como tabla con metadata (en ESX legacy reason es string). Verificar versión ESX target. **Si reason es string-only**, fallback a:

3. **Hash-based mutex con expected-value verification:**
   ```pseudo
   local fingerprint = hash(citizen_id, account, new_amount, ts_ms)
   pending_echoes[fingerprint] = true
   -- Listener:
   local expected = hash(player, account, money, get_ms())
   if pending_echoes[expected] then drop end
   ```
   Aún tiene window mínima pero el hash incluye amount → echo duplicado generaría hash distinto del original (porque amount post-mutation ya está aplicado), **eliminando ambiguedad**.

**Recommendation:** implementar opción **#1 (correlation-id metadata)** cuando ESX target ≥1.10+ + fallback **#3 (hash verification)** para legacy ESX.

> **🔒 FOUNDER DECISION 2026-05-06:** opción **#1 ÚNICAMENTE**. Hash-fallback **DESCARTADO** porque ESX <1.10 queda **out-of-scope oficial** (justificación negocio: ~5% mercado servidores abandonados pre-2019 vs reducción dramática tickets soporte + código limpio premium). Ver §11.9 final decision.

#### 🔴 Edge Case #2 — Performance Cron Reconciliación 200 players concurrent (Capa C)

**Riesgo:** founder pregunta directo. Escenario: server con 200 players online + restart server + todos abren Bank app simultaneously en 60s window post-spawn → 200x query `SELECT bank FROM users WHERE identifier=?` + 200x query `SELECT cached_balance FROM sonar_bank_accounts WHERE...` + 200x compare + N descuadres triggers UPDATE + audit log INSERT.

**Análisis técnico:**
- Worst case naive impl: 200 players × 2 queries × ~5ms cada = 2000ms total + serial bottleneck en oxmysql connection pool default size (typical 10-50 connections).
- Si pool size 10 → queue depth 40 batches × 5ms = 200ms p99 reasonable.
- **PERO** si descuadre rate alto (>20% players) → +N audit log INSERT + UPDATE → triplica load.
- Bigger problem: **server restart puede causar storm of reconciliations** porque `last_seen_balance_cache` SONAR estaría stale post-restart si cache vive en RAM no DB.

**Mitigación propuesta:**

1. **Reconciliación async via queue + batch processing:**
   ```pseudo
   -- En player.connect / bank.open:
   reconciliation_queue:enqueue({
     citizen_id = citizen_id,
     priority = is_bank_open and 'high' or 'normal',
     enqueued_at = get_ms(),
   })

   -- Worker thread (CreateThread loop):
   while true do
     local batch = reconciliation_queue:pop_batch(20, 100ms_timeout)
     if #batch > 0 then
       process_batch_reconciliation(batch)  -- single SQL multi-row IN(?)
     end
     Citizen.Wait(50)  -- 50ms tick
   end
   ```

2. **Single multi-row query batch:**
   ```sql
   -- Antes (200 queries):
   SELECT bank FROM users WHERE identifier=?  -- × 200
   -- Después (1 query):
   SELECT identifier, accounts FROM users WHERE identifier IN (?, ?, ...)
   -- Mismo para sonar_bank_accounts
   ```
   Reduce 400 round-trips → 2 round-trips. **~99% reducción load DB.**

3. **Cache LRU in-memory SONAR sobre `sonar_bank_accounts.balance` con invalidation on mutation:**
   - Hash table citizen_id → balance + ts_last_update.
   - Mutation SONAR-originated → update cache + DB.
   - Reconciliation lookup → cache first, DB fallback if miss.
   - Persistencia post-restart: rebuild on resource start desde DB (warm-up phase) + state ready signal.

4. **Skip reconciliation si "trust window" aplica:**
   - Si `now - cached_ts < 5 minutos` AND `last_known_source = 'sonar'` → skip check (asumir trust).
   - Solo reconciliar cold-cache, post-restart, post-disconnect-reconnect, bank.open after >5min idle.

**Recommendation:** combinar **queue async + batch SQL + cache LRU + trust window**. Performance target: 200 players concurrent reconciliation → <500ms p99 + <30% peak DB connections used.

#### 🔴 Edge Case #3 — Load Order failsafe Core Override (QBox/QBCore)

**Riesgo:** server admin instala SONAR + olvida poner `ensure sonar_bank_app` después de `ensure qbx_core` en `server.cfg` → SONAR carga ANTES de QBCore → monkey-patch fallido (función target no existe aún) → SONAR silent OK + QBCore boots normal después → **queries SONAR son no-ops, QBCore intacto, dinero player queda en duplicate-ledger desync grande**.

**Análisis técnico:**
- FiveM resource load order es secuencial per-line en `server.cfg`.
- `Player.Functions.AddMoney` se define en QBCore `qb-core/server/player.lua` durante `onResourceStart` event.
- Si SONAR `onResourceStart` corre ANTES → tabla `Player.Functions` aún no existe → patch falla.
- Si SONAR usa `dependency 'qb-core'` en `fxmanifest.lua` → FiveM garantiza qb-core started antes → fix automático.
- **PERO** si admin renombra qb-core a `qbx_core` o `qb-core-renewed` → manifiesto dependency string fail → silent failure.

**Mitigación propuesta:**

1. **Multi-fallback dependency declaration en `fxmanifest.lua`:**
   ```lua
   -- Bridges layer manifiest:
   dependencies {
     'oxmysql',
     -- Optional dependencies (any one):
   }
   -- Runtime detect framework:
   local framework_resource = detect_framework({'qbx_core', 'qb-core', 'es_extended', 'esx'})
   ```

2. **Defensive boot check on `onResourceStart` SONAR:**
   ```pseudo
   AddEventHandler('onResourceStart', function(name)
     if name ~= GetCurrentResourceName() then return end

     -- Verify framework loaded + functions monkey-patchable:
     local checks = {
       qbcore_player_functions = (QBCore and QBCore.Functions and QBCore.Functions.GetPlayer) ~= nil,
       qbox_exports = exports.qbx_core ~= nil,
       esx_object = ESX ~= nil,
     }

     local matched = false
     for k, v in pairs(checks) do
       if v then matched = true; break end
     end

     if not matched then
       print('^1[SONAR Bank] CRITICAL: framework not detected. Bridges Layer disabled.^0')
       print('^3[SONAR Bank] Install one of: qbx_core, qb-core, es_extended^0')
       print('^3[SONAR Bank] OR ensure load order: framework first, sonar_* after.^0')
       SetResourceKvp('sonar_bank_disabled', 'load_order_or_missing_framework')
       return  -- No-op resource, anti-corruption
     end

     -- Apply Core Override:
     install_core_override()
   end)
   ```

3. **Watchdog de integridad post-boot 30s después:**
   ```pseudo
   Citizen.SetTimeout(30000, function()
     local test_citizen = get_first_online_player()
     if test_citizen and not is_core_override_active(test_citizen) then
       print('^1[SONAR Bank] WATCHDOG: Core Override not active 30s post-boot.^0')
       broadcast_admin_alert('sonar_bank_compromise')
     end
   end)
   ```

**Recommendation:** **defensive boot check + ACE watchdog + console banner crítico** + KVP flag persistente para disable graceful si framework missing. Documentar en README install: "obligatorio orden `ensure qbx_core` (or framework) ANTES `ensure sonar_*`".

### 11.3 Cfx.re native primitives — research nuevas tools

**🚨 OPORTUNIDAD MAYOR DETECTADA — Global State Bags + Routing Buckets.**

#### 11.3.1 State Bags Global (server-only writable) — alternativa parcial al Event Hooking

Per **`docs.fivem.net/docs/scripting-manual/networking/state-bags`** (state bag policy verificado 2026-05-06):

> **"Global state to be able to be written by the server."**

State Bags global es una primitiva **server-only writable + auto-replicada a todos los clients + change handlers reactivos**. Esto es **superior a event hooking en 3 aspectos**:

| Capacidad | Event Hooking ESX | Global State Bags |
|---|---|---|
| Auth model | Trust event listener (cualquier resource puede dispatch) | Server-write-only forced (anti-spoof native) |
| Replication | Manual via TriggerClientEvent | Auto via FiveM netbus |
| Change handlers | Boilerplate AddEventHandler manual | `AddStateBagChangeHandler` native |
| Cross-resource read | Manual cache shared via global Lua | Native `GetStateBagValue` |
| Persistencia | RAM only (resource scoped) | RAM only (server scoped, broadcast all clients) |

**Cómo usar para Bank Lite mode:**

```pseudo
-- Server SONAR (Bridges layer) writes:
GlobalState['bank.balance.' .. citizen_id] = new_balance

-- Server ESX (legacy) reads (puede integrarse opcional):
local sonar_balance = GlobalState['bank.balance.' .. citizen_id]

-- Client NUI Bank app (auto-replicated):
AddStateBagChangeHandler('bank.balance.' .. citizen_id, 'global', function(bagName, key, value, _, replicated)
  update_ui_balance(value)
end)
```

**Beneficios concretos para SONAR Bank:**

1. **NUI realtime balance update sin manual TriggerClientEvent.** Reduce ~30% boilerplate State Bags publishers actuales (§5.6 blueprint).
2. **Cross-resource read sin Bridges shared cache** — otros resources (sonar_inventory, sonar_police) pueden leer balance directamente sin import Bridges API.
3. **Anti-spoof native** — third-party scripts no pueden escribir GlobalState (server-only) → exploit prevention.
4. **Auto-cleanup on player disconnect** — no hay leak RAM.

**LIMITACIONES State Bags global:**
- **Requiere OneSync activo** (todos los servers FiveM modernos lo tienen, pero documentar requisito).
- **No replaza event hooking ESX completamente** — porque scripts ESX legacy escriben `xPlayer.setAccountMoney` que dispara `esx:setAccountMoney` event, NO escribe State Bags (no saben de SONAR).
- **Solo broadcast read-only para clients** — write authority queda server-side estricto.
- **`experimentalStateBagsHandler` convar exists** desde July 2024 (mejorado handler perf). Verificar habilitado en `server.cfg`.

#### 11.3.2 Routing Buckets — sandbox potencial empresas/governance instances

Per **`cookbook.fivem.net/2020/11/27/routing-buckets-split-game-state/`**:

> **"Routing buckets allow split game state. Control request events can't be routed across routing buckets. Strict entity lockdown mode available."**

Use case Bank Phase A: posiblemente **out-of-scope para Lite mode core problem**, pero relevante T4:
- **Empresas múltiples isolation:** cada gran corporación player-driven en su routing bucket dedicado. Eventos no leak cross-company.
- **Government Council session room:** routing bucket para ceremonias election + voting + session admin.

**No ataca Q16** directamente pero documentar para Phase D integration steps.

#### 11.3.3 Convar `sv_experimentalStateBagsHandler` — recommended setting

```ini
# server.cfg recommended for SONAR Bank:
sv_experimentalStateBagsHandler 1
sv_experimentalNetGameEventHandler 1
sv_enableNetEventReassembly 1
```

Documentar en README install Phase A.

#### 11.3.4 Veredicto research

**State Bags global es upgrade obligatorio para §5.6 publishers.** Reescribir tabla §5.6 para usar StateBags global API canonical en lugar de TriggerClientEvent manual. Benefit: -30% boilerplate + native auth + cross-resource reads.

**Routing buckets** es deferred para Phase D integration empresas/governance instancias.

### 11.4 Edge cases secundarios identificados

#### Capa B — Mapeo Híbrido Estricto: edge case escrow drain

**Riesgo:** player tiene €5K en savings (premium SONAR-only) + €10K en main account ESX. Player se desconecta. Script externo "salary_paid" pago €1500 → ESX `addAccountMoney('bank', 1500)` → main account ahora €11500. Player se reconecta. SONAR reconciliation → detect descuadre +€1500 → audit log "external mutation". OK no problem.

**Pero:** si el script externo bug bug "drain_account" → ESX `removeAccountMoney('bank', 9999999)` (negative test) → ESX clamp a 0 silently → reconciliation detect descuadre -€10000 → SONAR auto-aplica delta a `sonar_bank_accounts` → **dinero player se evapora silently**.

**Mitigación:** reconciliation no-aplica delta automáticamente — siempre **flag** + queue admin review si delta > `Config.Reconciliation.AutoApplyMaxDelta` (default €1000). Sobre threshold → notif admin + freeze account compliance + manual review.

#### Capa C — Reconciliación: edge case cuentas premium puras

**Riesgo:** player solo tiene cuenta savings (premium SONAR-only) + ningún main account ESX-anchored. Reconciliation query `users.accounts.bank` returns null/0. Comparación con SONAR savings €18500 → false positive descuadre.

**Mitigación:** reconciliation scope **solo main_account** (anchor ESX), **excluye explicit account_type IN ('savings', 'escrow', 'business_treasury', 'crypto_wallet')**. Premium tiers son SONAR-exclusive by design — no requieren reconciliation con ESX.

### 11.5 Counter-proposals + optimizaciones

#### CP1 — Reescribir §5.6 State Bags table usando StateBags global native (mandatory)

Reemplazar publishers TriggerClientEvent → GlobalState writes. Benefit: -30% boilerplate, +auth native, +cross-resource reads.

#### CP2 — Mutex correlation-id-based (no TTL-based) — robust desync resistant

Pseudocode §11.2 Edge Case #1 mitigation #1. Trade-off: requiere ESX `reason` table support OR fallback hash-based.

#### CP3 — Reconciliation pipeline async + batch SQL + cache LRU + trust window

Pseudocode §11.2 Edge Case #2 mitigation #1+#2+#3+#4 combinados. Performance target 200 concurrent <500ms p99.

#### CP4 — Defensive boot + watchdog + KVP graceful disable

Pseudocode §11.2 Edge Case #3 mitigation #2+#3 combinados.

#### CP5 — Reconciliation auto-apply threshold + admin flag queue

Edge case secundario §11.4 escrow drain. Threshold default €1000 + admin review queue manual.

#### CP6 — Reconciliation scope main_account only

Edge case secundario §11.4 cuentas premium. Excluir savings/escrow/treasury/crypto del query.

#### CP7 — README install + convars `sv_experimental*` recommended

Phase A documentation entregable Phase A done criteria.

#### CP8 — Lite mode FSM + UI banner Bank app (transparency player)

```
sonar_bank_status FSM:
  states: native_full, lite_mode_active, compromised_load_order, framework_missing
  initial: native_full (T1 QBox/QBCore monkey-patch OK)
  transitions:
    native_full → lite_mode_active (when ESX detected + monkey-patch fail OK)
    native_full → compromised_load_order (when watchdog detect missing override post-30s)
    * → framework_missing (when no framework detected)
```

UI Bank app sidebar footer: badge mini status `🟢 Native` / `🟡 Lite` / `🔴 Compromised` / `⚫ Disabled`. Tooltip explica al player el modo activo + link docs admin.

### 11.6 Veredicto técnico Q16

**Aprobar la propuesta híbrida 3-capas con 8 contrapropuestas integradas (CP1-CP8).**

**Risk score post-mitigations:** 🟡 medium. Aceptable para production con docs install riguroso + smoke regression específico Bridges T2.

**Risk score sin mitigations:** 🔴 high. Edge cases #1+#2+#3 son bloqueadores production + #1 latente irreproducible silencioso.

**Critical adds Phase A scope:**
1. Mutex correlation-id (CP2) — Lua module shared `lib/mutex_echo.lua`.
2. Reconciliation pipeline (CP3) — Lua module `lib/reconciliation.lua` async worker.
3. Defensive boot (CP4) — extends `fxmanifest.lua` + `onResourceStart` handlers Bridges adapters.
4. State Bags global native (CP1) — refactor §5.6 + reduce TriggerClientEvent boilerplate.
5. Lite mode FSM `sonar_bank_status` (CP8) — extends FSMs §5.3 (9 nuevos en lugar de 8).
6. Threshold auto-apply (CP5) + scope main only (CP6) — config flags.
7. README install + convars recommended (CP7).

**Total ajuste Phase A:**
- +1 FSM nuevo (`sonar_bank_status`).
- +2 lib modules shared (`mutex_echo` + `reconciliation`).
- +Refactor §5.6 publishers a StateBags global.
- +Defensive boot pattern todos resources.
- +Smoke Phase A test específico: lag spike injection + load order chaos + multi-framework matrix (QBox + QBCore + ESX 1.10+ + ESX legacy).

### 11.7 Open follow-up questions Q16

| Sub-Q | Pregunta | Recommendation |
|---|---|---|
| Q16.1 | ¿ESX target version mínima soportada? | ESX 1.10+ (reason table support). ESX legacy <1.10 requiere fallback hash-mutex. |
| Q16.2 | ¿`Config.Reconciliation.AutoApplyMaxDelta` default value? | €1000 (configurable per server). |
| Q16.3 | ¿UI Bank app status badge visible siempre o solo si lite mode? | Always visible footer mini — transparency value. |
| Q16.4 | ¿State Bags global require `sv_experimentalStateBagsHandler 1` mandatory? | Recommend mandatory — documentar README. |
| Q16.5 | ¿Smoke matrix Phase A incluye chaos engineering (lag spikes injected)? | Yes — DC Phase A done criteria add "Chaos test: 200 reconciliations + injected 200ms-1s lag spike + verify zero ledger desync". |
| Q16.6 | ¿Watchdog Core Override compromise → broadcast Discord webhook admin alert? | Out of scope Phase A — defer Phase D integration. KVP + console banner suficiente Phase A. |

### 11.8 Next steps post Q16 founder green-light

1. Founder revisa §11.1-§11.7 + decide CP1-CP8 individuales (acepta todas / acepta subset / rechaza algunas).
2. Founder responde Q16.1-Q16.6 sub-questions.
3. Cascade integra decisiones → blueprint v1.2.
4. SSoTs promotion incluye §5 update con CP1-CP8 reflected (callbacks + DDL + FSMs +1 + state bags refactor).
5. Phase A scope confirmed con +1 FSM + 2 lib modules + smoke chaos test.
6. ADR-018 nuevo proposal: "Bank Lite mode hybrid 3-layer compatibility strategy + 8 mitigation patterns" — firma Phase A start.

— Cascade Sonnet 4.6 · Q16 audit · 2026-05-06.

---

### 11.9 🔒 Founder Final Decision Q16 — DECISIÓN CERRADA

**Memo founder 2026-05-06:** "Para: Product Manager / De: Founder / Estado: DECISIÓN CERRADA - Proceder a implementación en Phase A."

#### 11.9.1 Política frameworks definitiva

**1. Frameworks Modernos (QBCore / QBox) → "Core Override" (Secuestro del Núcleo)**

- **Implementación:** Durante el arranque del servidor, `sonar_bridges` interceptará y sobrescribirá en la RAM las funciones nativas de dinero (`AddMoney`, `RemoveMoney`).
- **Resultado:** SONAR se convierte en el motor nativo del dinero bancario. Rendimiento perfecto, cero lag y dominio total de la base de datos sin obligar al cliente a reescribir sus scripts.
- **Sin pedir permiso, tomamos el control.**

**2. Framework Clásico (ESX 1.10+ ONLY) → Modo Lite (Triple Capa)**

- **Implementación:** Tabla `users` ESX como ancla solo de cuenta principal. Dinero premium aislado en `sonar_bank_accounts`. Sincronización Triple Capa: Event Hooking + **Correlation-ID Mutex (CP2)** + Cron Reconciliación Activa async (CP3).
- **Resultado:** Plug & Play sin romper scripts antiguos (tiendas, robos, etc.). Compatibilidad no-invasiva.

**3. EL CORTE (NUEVA POLÍTICA): Fin del soporte a ESX pre-2019**

- **Out-of-Scope OFICIAL:** versiones ESX inferiores a 1.10 no soportadas.
- **Justificación técnica:** ESX <1.10 no soporta metadatos en transferencias → forzaría hacks Hash-based + código espagueti → ensucia Phase A + arruina mantenimiento.
- **Justificación negocio:** asumimos pérdida ~5% cuota (servidores abandonados pre-2019, sin actualizar 7 años) → reducción drástica tickets soporte + cero bugs fantasma + código limpio premium con Correlation IDs perfectos para clientes actuales.

#### 11.9.2 Estado CP1-CP8

| CP | Estado | Notas |
|---|---|---|
| **CP1** State Bags global mandatory | ✅ Accepted | Refactor §5.6 publishers obligatorio Phase A. |
| **CP2** Correlation-ID Mutex | ✅ Accepted (path #1 ONLY) | Hash-fallback **DESCARTADO** (cut ESX <1.10). Solo correlation-id ESX ≥1.10. |
| **CP3** Reconciliation pipeline async | ✅ Accepted | Queue + batch SQL + cache LRU + trust window 5min. |
| **CP4** Defensive boot + watchdog | ✅ Accepted | 3-method framework detect + watchdog 30s + KVP graceful disable + console banner. |
| **CP5** Threshold auto-apply | ✅ Accepted | Default €1000 (configurable per server admin). |
| **CP6** Reconciliation scope main only | ✅ Accepted | Excluye savings/escrow/business_treasury/crypto_wallet del query. |
| **CP7** README install + convars | ✅ Accepted | `sv_experimentalStateBagsHandler 1` + `sv_experimentalNetGameEventHandler 1` + `sv_enableNetEventReassembly 1` recommended Phase A docs. |
| **CP8** Lite mode FSM + UI badge | ✅ Accepted | FSM `sonar_bank_status` 4 states + UI badge always visible Bank app sidebar footer. |

#### 11.9.3 Estado Q16.1-Q16.6 sub-questions

| sub-Q | Decision |
|---|---|
| Q16.1 ESX target version mínima | ✅ **ESX 1.10+ ONLY**. ESX <1.10 = out-of-scope OFICIAL (memo founder). |
| Q16.2 `Config.Reconciliation.AutoApplyMaxDelta` default | ✅ **€1000** default (configurable per server admin). |
| Q16.3 UI status badge visibility | ✅ **Always visible** footer mini Bank app sidebar (transparency). |
| Q16.4 `sv_experimentalStateBagsHandler` mandatory | ✅ **Mandatory recommended** README install Phase A. |
| Q16.5 Smoke chaos test Phase A | ✅ **Yes mandatory** Phase A done criteria — lag spike injection 200ms-1s + 200 concurrent reconciliations + multi-framework matrix. |
| Q16.6 Watchdog Discord webhook | ✅ **Defer Phase D**. Phase A: KVP + console banner suficiente. |

#### 11.9.4 Anti-tech-debt commitments Phase A

- ❌ **NO Hash-based mutex code path** — descartado. Solo correlation-id metadata.
- ❌ **NO ESX <1.10 fallback paths** — anti-corruption layer aborta boot defensive si detecta ESX legacy.
- ❌ **NO TriggerClientEvent manual publishers** Bank balance/account state — todo State Bags global native.
- ❌ **NO hot-patch sin defensive boot check** — siempre 3-method framework detect + KVP graceful disable.
- ✅ **Code limpio premium** — Correlation IDs perfectos + State Bags native + reconciliation async + watchdog + transparency UX.

#### 11.9.5 Greenlight status

🟢 **Phase A green-lit pre-arranque.**

**Bloqueadores restantes pre Phase A.1 coding:**
1. Cascade integra decisiones blueprint → v1.2 (este edit ✅).
2. ADR-017 firma (Q2 paleta extendida ADR-016 amendment).
3. ADR-018 propose + firma ("Bank Lite mode hybrid 3-layer + correlation-id mutex + cut ESX legacy + 8 mitigation patterns").
4. SSoTs promotion: `04_api_contracts.md` v1.3 (callbacks C006-C0XX + C058-C062) + `03_db_schema.md` v1.2 (15+ nuevas tablas + scope changes Q8/Q10) + `05_state_machines.md` v1.1 (+9 FSMs incluido `sonar_bank_status` y `election_lifecycle`) + `02_events_catalog.md` v1.3 + `07_bridges_compatibility.md` extends (Lite mode + Core Override + cut ESX legacy + State Bags global).
5. `progress/SPRINT_PLAN_BANK_PHASE_A.md` v1.0 nuevo (Phase A breakdown + sub-tags + done criteria + smoke chaos test).

— Cascade Sonnet 4.6 · Q16 RESOLVED · 2026-05-06.







