# SONAR Bank — Shared Brief v1.0

> **Brief común heredado por los 5 Tech Leads.** Contiene la visión consolidada, los mandatos founder, las decisiones Q1-Q16 firmadas, las referencias ADR vigentes, las reglas de identidad SONAR, los hard constraints técnicos y el glosario canonical.
>
> **Audiencia:** los 5 Tech Leads + futuros agentes que se sumen al pipeline SONAR Bank.
>
> **Fecha:** 2026-05-06.
> **Status:** 🟢 Locked post Q16 founder green-light.
> **Lectura:** obligatoria pre-arranque, después del manifest, antes del slice propio.

---

## 1. Visión SONAR Bank — declaración founder

### 1.1 Ambición

Construir la **infraestructura financiera más sólida del ecosistema FiveM**, con benchmark técnico aspirando a Stripe / Revolut / Wise y **superando ampliamente** los competidores actuales:

| Competidor | Posicionamiento | SONAR Bank diferencial |
|---|---|---|
| NeedForScript Banking | UI bonita, backend simple | Backend regulatory-grade + audit ledger inmutable + compliance flags autoraise |
| RX Advanced Banking | Features amplias pero sin moat | Government Console + Empresas Dashboard + Audit Explorer + Treasury cash flow forecast |
| Renewed-Banking | Compatible ESX/QBCore base | Lite Mode hybrid 3-layer + correlation-id mutex + StateBags global + chaos tested |
| Codesign-bank | Premium UI dark | Identity SONAR canonical + ADR-017 paleta extendida + 12 motion presets + sound canonical |
| QB-banking core | Solo QBCore | QBox + QBCore + ESX 1.10+ multi-framework via Bridges Layer |

### 1.2 Filosofía no-negociable

> **No es un MVP. Es la app completa.**
>
> Phases A-E son slices técnicos de troceado de trabajo, no releases incrementales. El shipping milestone real es el tag final único `sonar-bank-v1` en Phase E.

### 1.3 Comparable comercial target

- **Producto comercial:** premium tier FiveM resource market.
- **Cliente target:** servidores roleplay serios 64-200 players con economía profunda.
- **Pricing tier estimado:** premium (€80-150 una sola compra o €15-25/mes subscription).
- **Soporte:** ESX 1.10+ / QBCore / QBox. **Cut oficial ESX <1.10** (pre-2019, ~5% mercado obsoleto).

---

## 2. Mandatos founder — innegociables todos los Tech Leads

### 2.1 Los 4 mandatos canonical

#### M1 — Documentación (SSoT) antes que Código

> Bajo ninguna circunstancia escribirás una sola línea de código funcional sin antes haber estructurado, debatido y cerrado la documentación técnica de tu área.
>
> La planificación aislada es tu primera entrega.

**Aplicación práctica:** cada Tech Lead entrega SSoT v1.0 LOCKED + sign-off founder ANTES de tocar ningún archivo en `resources/sonar_bank/`, `resources/sonar_bank_app/`, `resources/sonar_bridges/` o equivalente.

#### M2 — Autonomía y Libertad Profesional (NO eres un loro)

> Recibirás un Blueprint general heredado del Product Manager. Se te exige que lo cuestiones.
>
> Tienes total libertad profesional y técnica para:
> - Buscar mejores soluciones.
> - Detectar vulnerabilidades de seguridad.
> - Optimizar el rendimiento.
> - Proponer refactorizaciones antes de documentar.
>
> Si el documento original propone un patrón anticuado, es tu deber profesional **rechazarlo** y proponer la alternativa moderna (ej. usando nuevas primitivas de Cfx.re).

**Aplicación práctica:** cada Lead lee su slice + cuestiona explícitamente cualquier diseño dudoso + investiga primitivas modernas FiveM (StateBags global, routing buckets, infinity sync, experimentalStateBagsHandler, ResourceKvp, etc.) + propone amendments al blueprint con razones técnicas argumentadas.

#### M3 — Visión Crítica

> Razona tus decisiones. Si cambias algo del Blueprint original en tu área, explica por qué tu solución es más segura, rápida o escalable.

**Aplicación práctica:** cualquier deviation del blueprint queda documented con bloque `### 🟡 Deviation from blueprint` en el SSoT del Lead, con:
- Sección blueprint afectada (con cita `@docs/design/proposals/03_bank_app_blueprint_v1.md:LINE`).
- Diseño original.
- Diseño propuesto.
- Razones técnicas (seguridad / perf / escalabilidad / mantenibilidad / legibilidad / future-proof).
- Impact downstream (qué Leads se ven afectados + cómo se notifica).

#### M4 — Aislamiento de Dominio

> Concéntrate exclusivamente en tu área de especialidad. No resuelvas problemas que pertenecen al Frontend si eres de Backend, y viceversa.
>
> Exige contratos claros (APIs/Eventos) a tus compañeros.

**Aplicación práctica:**
- Si encuentras un problema fuera de tu dominio, **NO lo resuelvas**. Documenta como issue cross-team en `docs/agents/teams/issues/issue_<id>.md` y notifica al Lead owner.
- Si un Lead vecino te pide ayuda fuera de tu scope, redirígelo al Lead correcto.
- Exige contratos formales firmados antes de implementar dependencias en otros dominios.

### 2.2 Mandatos secundarios derivados

#### M5 — Idioma estricto

- Documentación + discusión: **Español**.
- Código + comentarios + commit messages + logs: **Inglés**.
- Mezclar idiomas dentro de un artefacto = bloqueante review.

#### M6 — Anti-paternalismo + anti-preámbulo

- Founder yaboula no acepta validaciones tipo "¡Tienes razón!", "Excelente pregunta!", "Entendido", etc.
- Jump straight to substance.
- No sugerir descansos / pausas / breaks. Founder decide cuándo parar.

#### M7 — Anti-tech-debt commitments Phase A (heredado §11.9.4 blueprint v1.2)

- ❌ NO hash-based mutex code path.
- ❌ NO ESX <1.10 fallback paths.
- ❌ NO `TriggerClientEvent` manual publishers Bank state.
- ❌ NO hot-patch sin defensive boot check.
- ✅ Solo correlation-id metadata + StateBags global + reconciliation async + watchdog + transparency UX.

---

## 3. Decisiones founder Q1-Q16 — locked references

### 3.1 Tabla compacta Q1-Q16

| Q | Tema | Decisión locked |
|---|---|---|
| **Q1** | Government entity mode | **Configurable per server** (NPC auto OR player elections). Ambos modes funcionales día 1. Implica FSM `election_lifecycle` + 3 tablas elections + 5 callbacks C058-C062. |
| **Q2** | Paleta extendida ADR-017 | **Aceptar full** — extended palette + gradients premium Bank-app-specific sobre ADR-016 base 3-color. |
| **Q3** | C003 getTransactions | **Unlock NOW Phase A** — sin tech debt history view. |
| **Q4** | Resource arquitectura | **Resource separado `sonar_bank_app`** — autónomo + ship/version independent del Tablet. |
| **Q5** | Tamaño app | **1440×900 centered** + backdrop oscuro. No fullscreen. |
| **Q6** | Triggers acceso | **Multidisparo:** keybind `M` (configurable convar) + `/bank` command + Tablet embed icon. |
| **Q7** | Visualizaciones 3D | **DOM dialog 2D** + CSS animations. Descarta Three.js. |
| **Q8** | Multidivisa | **OFF** — single currency global config server. Elimina T4.10 + tabla `sonar_bank_currencies` + columnas FX. |
| **Q9** | Onboarding | **3-step skippable** — saludo + saldo inicial + IBAN/QR reveal. |
| **Q10** | Patrones autoraise compliance | **5 canonical** — `structuring` + `large_transfer` + `late_tax` + `velocity` + `new_account_large_deposit`. Eliminado `unusual_destination_foreign_prefix` (no aplica single-currency). |
| **Q11** | StateBag events | **`transfer_complete` ACEPTAR** + `compliance_alert` RECHAZAR (visual fallback only). Pre-CP1 era TriggerClientEvent. **Post-CP1 todo migra a StateBags global native.** |
| **Q12** | Tier 4 features | **LOCKED IN-SCOPE 100%** — cripto + robo + acciones + cooperativas + staking + ATM minigame + physical card + round-ups + bank loyalty. Cero recortes. |
| **Q13** | Audit Explorer scopes | **3 scopes** — Mis cuentas / Mis empresas / Todas (ACE govt). |
| **Q14** | Defaults config tax | **Agresivos** — IVA 8% + IRPF progresivo (0/15/25/35%) + Riqueza 1.2% above €500k. Editable por admin. |
| **Q15** | UI dev tooling | **Vite Dev Page `/dev/components`**. Descarta Storybook. |
| **Q16** | Compatibility ESX/QBCore | **Hybrid 3-layer aprobado + 8 CP integrados (CP1-CP8) + cut ESX <1.10 OFICIAL.** |

### 3.2 Detalle Q16 — política frameworks definitiva

#### 3.2.1 Frameworks Modernos (QBCore / QBox) → "Core Override"

> Sin pedir permiso, tomamos el control.

- **Implementación:** durante arranque server, `sonar_bridges` interceptará y sobrescribirá en RAM las funciones nativas de dinero (`AddMoney`, `RemoveMoney`).
- **Resultado:** SONAR se convierte en motor nativo del dinero bancario. Rendimiento perfecto, cero lag, dominio total de la base de datos.

#### 3.2.2 Framework Clásico (ESX 1.10+ ONLY) → "Modo Lite Triple Capa"

- **Capa A — Event Hooking + Mutex Correlation-ID:** listener `esx:setAccountMoney` + correlation-id metadata-based mutex (NO TTL-based, NO hash-fallback).
- **Capa B — Mapeo Híbrido Estricto:** dinero principal vive ESX `users.accounts` (ancla). Premium tiers (savings + escrow + business_treasury + crypto_wallet) viven exclusivos en `sonar_bank_accounts`.
- **Capa C — Reconciliación Activa Async:** queue async + batch SQL multi-row + cache LRU in-memory + trust window 5min. Threshold auto-apply €1000 (sobre threshold → admin flag). Scope main_account only (excluye premium tiers).

#### 3.2.3 EL CORTE — ESX <1.10 OUT-OF-SCOPE OFICIAL

- **Justificación técnica:** ESX <1.10 no soporta metadatos en transferencias → forzaría hacks Hash-based + código espagueti.
- **Justificación negocio:** asumimos pérdida ~5% mercado abandonado pre-2019 → reducción drástica tickets soporte + cero bugs fantasma + código limpio premium.
- **Implementación:** `fxmanifest.lua` declara `dependencies` framework version. Boot defensive aborta si detecta ESX legacy + console banner explanation + KVP `sonar_bank_disabled = unsupported_esx_legacy`.

### 3.3 Counter-Proposals 8 (CP1-CP8) — todos accepted

| CP | Decisión | Owner Lead implementación |
|---|---|---|
| **CP1** State Bags global mandatory | Refactor publishers Bank balance/state. `GlobalState[bank.balance.<citizen_id>] = value` + `AddStateBagChangeHandler` reactive client. | Backend Lead |
| **CP2** Correlation-ID Mutex | ESX 1.10+ metadata reason field. Hash-fallback DESCARTADO. | Backend Lead |
| **CP3** Reconciliation pipeline async | Queue + batch SQL + cache LRU + trust window 5min. Performance target 200 concurrent <500ms p99. | Backend Lead + DB Lead jointly |
| **CP4** Defensive boot + watchdog | 3-method framework detect + watchdog 30s post-boot + KVP graceful disable + console banner crítico. | Backend Lead + DevOps Lead |
| **CP5** Reconciliation auto-apply threshold | Default €1000 + admin flag queue (anti-evaporación silent). | Backend Lead |
| **CP6** Reconciliation scope main only | Excluye savings/escrow/business_treasury/crypto del query reconciliation. | Backend Lead |
| **CP7** README install + convars | `sv_experimentalStateBagsHandler 1` + `sv_experimentalNetGameEventHandler 1` + `sv_enableNetEventReassembly 1`. | DevOps Lead |
| **CP8** Lite mode FSM + UI badge | FSM `sonar_bank_status` (4 states: native_full / lite_mode_active / compromised_load_order / framework_missing) + UI badge always visible Bank app sidebar footer. | Backend Lead (FSM) + Frontend Lead (UI badge) |

### 3.4 Sub-questions Q16.1-Q16.6 — answered

| sub-Q | Decision |
|---|---|
| Q16.1 ESX target version mínima | **ESX 1.10+ ONLY**. ESX <1.10 = out-of-scope OFICIAL. |
| Q16.2 `Config.Reconciliation.AutoApplyMaxDelta` default | **€1000** (configurable per server admin). |
| Q16.3 UI status badge visibility | **Always visible** footer mini Bank app sidebar (transparency player). |
| Q16.4 `sv_experimentalStateBagsHandler` mandatory | **Mandatory recommended** README install Phase A. |
| Q16.5 Smoke chaos test Phase A | **Yes mandatory** — lag spike injection 200ms-1s + 200 concurrent reconciliations + multi-framework matrix. |
| Q16.6 Watchdog Discord webhook | **Defer Phase D**. Phase A: KVP + console banner suficiente. |

---

## 4. Identidad SONAR — referencias canonical

### 4.1 ADRs vigentes (lectura obligatoria si afectan tu dominio)

| ADR | Status | Tema | Relevancia per Lead |
|---|---|---|---|
| **ADR-011** | Accepted | Rebrand Admirals → SONAR | Todos (naming) |
| **ADR-012** | Accepted (amends ADR-011) | Refinement abstract metaphor + hybrid theme + neutral voice | Frontend (UI) + DB (table prefixes) + Backend (event prefixes) |
| **ADR-013** a **ADR-015** | Accepted | (refer `docs/planning/02_decision_log.md`) | Per dominio |
| **ADR-016** | Accepted | Identity V3 lock — dark-only 3-color canonical (#060607 / #FF5100 / #FAFAFA) + 5 SFX canonical + Lucide bridge | Frontend (UI) primario |
| **ADR-017** | 🟡 Proposed (Q2 founder approved, sign pending) | Extended palette Bank-app-specific (gradients premium + accent secondary) sobre ADR-016 base | Frontend |
| **ADR-018** | 🟡 Proposed (Q16 founder approved, sign pending) | Bank Lite mode hybrid 3-layer + correlation-id mutex + cut ESX legacy + 8 mitigation patterns | Backend + DevOps + DB |

### 4.2 Identidad SONAR canonical (immutable)

| Aspecto | Token canonical | Status |
|---|---|---|
| Nombre brand | SONAR (acronym SOund Navigation And Ranging — abstract) | Locked ADR-011 |
| Voz | Premium-tech neutral (Vercel/Linear/Stripe/Apple Pro) | Locked ADR-012 |
| Metáfora | Profundidad abstracta — calma metódica + patterns emerge + claridad bajo presión | Locked ADR-012 |
| Paleta base | `#060607` (Abyss Black) + `#FF5100` (Sonar Orange) + `#FAFAFA` (Surface Light) | Locked ADR-016 |
| Paleta extendida Bank | Gradients premium + accent secondary (TBD Frontend Lead post ADR-017 sign) | 🟡 Proposed ADR-017 |
| Iconografía | Lucide React rounded — bridge canonical | Locked ADR-016 |
| Sound | 5 SFX canonical: `signal_emerge` / `depth_press` / `layer_dive` / `console_tap` / `panel_open` | Locked ADR-012 + ADR-016 |
| Typography | Display Geist Sans + Body Inter Tight + Mono Geist Mono | Locked |
| Glossary canonical | Console / Bitácora / Depth / Eco / Manifiesto / Signal / Lineage / Patrón | Locked ADR-012 |
| Glossary deprecated | ❌ Periscope, Hatch, Hydrophone, Ping (radio), Sweep, Sumersión, Bridge-as-command-center | Locked ADR-012 |

---

## 5. Stack técnico canonical SONAR (referencia compartida)

### 5.1 Backend

- **Lenguaje:** Lua 5.4 (FiveM scripts).
- **DB wrapper:** oxmysql.
- **Frameworks soportados:** QBox (T1) + QBCore (T2 native) + ESX 1.10+ (T3 Lite mode).
- **Scripts T1 obligatorios:** ox_inventory + ox_target + ox_lib + lb-phone.
- **Sync:** State Bags (entity + global) + EventBus interno + correlation-id mutex.
- **Resources canonical post-Phase-8 renaming:**
  - `sonar_bridges` (Bridges Layer + adapters per framework)
  - `sonar_core` (shared utilities + config global)
  - `sonar_bank` (existing — extends Phase A)
  - `sonar_bank_app` (NEW Phase A — separated app NUI + business logic Bank app specific)

### 5.2 Frontend / NUI

- **Framework:** React 18 + TypeScript strict.
- **Styling:** TailwindCSS + custom design tokens SONAR.
- **Components:** shadcn/ui base + custom components SONAR-themed.
- **Icons:** Lucide React (bridge canonical).
- **Motion:** framer-motion (spring physics > CSS easing).
- **Sound:** custom WebAudio engine SONAR-canonical (`@sonar_tablet/web-src/src/lib/sfx.ts`).
- **Build tool:** Vite.
- **Dev page:** `/dev/components` (Q15) — Vite-served component playground.
- **Resources:**
  - `sonar_tablet` (existing — host Tablet UI, embed Bank app via iframe or sub-route)
  - `sonar_bank_app` (NEW — hosts standalone Bank app NUI + own React tree)

### 5.3 Database

- **Engine:** MySQL 8.0+ (recomendado) o MariaDB 10.6+.
- **Wrapper:** oxmysql.
- **Charset:** utf8mb4 / utf8mb4_unicode_ci.
- **Naming:** `sonar_*` prefix obligatorio (post-Phase-9 migration applied).
- **Style:** UPPERCASE keywords + `snake_case` tables/columns.
- **Migrations:** `migrations/<NNN>_<description>.sql` numerados secuenciales.

### 5.4 Code style

- **Lua:** 2 spaces indent, `snake_case` functions/vars, `PascalCase` modules/classes, single quotes preferible.
- **JS/TS:** Prettier defaults, 2 spaces, single quotes, no semicolons consistent per file, TypeScript strict.
- **SQL:** UPPERCASE keywords, `snake_case` tables/columns, todas tablas prefijo `sonar_*`.
- **Commits:** `S{N}.{M} {imperative present}` — ej. `BANK-A.1 add bank_accounts table` o `BANK-A.2 implement core_override module`.
- **Files:** lowercase kebab-case para docs, snake_case para Lua, kebab-case para JS/TS components.

---

## 6. Hard constraints técnicos (NO NEGOCIABLES)

### 6.1 Heredados workspace

- Nunca llamar `exports['qb-*']`, `ESX.*`, `QBCore.*` directo fuera de `resources/sonar_bridges/adapters/*`.
- Nunca hardcode dinero / items fuera de Bridges API.
- Nunca push código que rompe boot del server.
- No XP genérico, no PvP combat, no pay-to-win.

### 6.2 Específicos SONAR Bank

- **No mezclar idiomas dentro mismo artefacto** (docs ES + code EN estricto).
- **CDD obligatorio** — no código sin contrato firmado.
- **No hash-based mutex paths** — solo correlation-id metadata.
- **No `TriggerClientEvent` manual publishers** Bank balance/state — todo StateBags global native.
- **No reconciliation auto-apply > €1000** sin admin flag.
- **No queries scope reconciliation a premium tiers** — solo main_account ESX-anchored.
- **No defer ADR-017 / ADR-018** — firmas requeridas pre Phase A coding.

---

## 7. Artefactos canonical existentes (referencia per Lead)

### 7.1 SSoTs vigentes (estado actual pre Phase A)

| SSoT | Path | Versión actual | Owner Lead post-promotion |
|---|---|---|---|
| Product Bible | `docs/00_PRODUCT_BIBLE.md` | v1.4 | Founder (no Lead) |
| Economic Model | `docs/economy/01_economic_model.md` | v1.0 | DB Lead reviews + Backend Lead aplica |
| Events Catalog | `docs/technical/02_events_catalog.md` | v1.2 → **v1.3 Backend Lead** | Backend Lead |
| DB Schema | `docs/technical/03_db_schema.md` | v1.1 → **v1.2 DB Lead** | DB Lead |
| API Contracts | `docs/technical/04_api_contracts.md` | v1.2 → **v1.3 Backend Lead** | Backend Lead |
| State Machines | `docs/technical/05_state_machines.md` | v1.0 → **v1.1 Backend+DB jointly** | Backend Lead + DB Lead |
| FiveM Standards | `docs/technical/06_fivem_standards.md` | v1.0 | DevOps Lead reviews |
| Bridges Compatibility | `docs/technical/07_bridges_compatibility.md` | v1.0 → **v1.1 Backend Lead** | Backend Lead |
| Audit Hooks (NEW) | `docs/technical/08_audit_hooks.md` | NEW v1.0 Security Lead | Security Lead |
| Roadmap | `docs/planning/01_roadmap.md` | extends Phase A | DevOps Lead reviews |
| Decision Log | `docs/planning/02_decision_log.md` | + ADR-017 + ADR-018 firma | Founder |
| Bank Blueprint | `docs/design/proposals/03_bank_app_blueprint_v1.md` | v1.2 (proposal) → promoted SSoT post Phase A H5 | Founder + PM (archivado post handoff DevOps) |
| Bank UI Contracts (NEW) | `docs/design/03_bank_app_ui_contracts.md` | NEW v1.0 Frontend Lead | Frontend Lead |
| Smoke Bank Phase A (NEW) | `progress/SMOKE_BANK_PHASE_A_v1.md` | NEW DevOps Lead | DevOps Lead |
| Sprint Plan Phase A (NEW) | `progress/SPRINT_PLAN_BANK_PHASE_A.md` | NEW v1.0 DevOps Lead | DevOps Lead (orchestrates) |

---

## 8. Glosario canonical SONAR Bank

| Término | Definición |
|---|---|
| **Bridges Layer** | Capa anti-corruption en `resources/sonar_bridges/` que aísla SONAR de framework directo. Todos los `Bridges.*.method()` calls. |
| **Core Override** | Estrategia QBox/QBCore — runtime monkey-patch de `Player.Functions.AddMoney/RemoveMoney`. |
| **Lite Mode** | Estrategia ESX 1.10+ — Triple Capa (Event Hooking + Correlation-ID Mutex + Reconciliation Activa). |
| **Correlation-ID Mutex** | Mecanismo anti-duplicación echo events ESX. Inyecta UUID en metadata `reason` de `setAccountMoney`. Listener drop si correlation-id matches pending echo. |
| **Reconciliation Activa** | Pipeline async que verifica saldo RAM ESX vs cache SONAR + aplica delta auto si <€1000 + admin flag si >€1000. |
| **State Bags Global** | Cfx.re primitive server-only writable + auto-replicated clients + native auth. Reemplaza `TriggerClientEvent` publishers Bank state. |
| **Defensive Boot** | Patrón check 3-method framework detect + KVP graceful disable + console banner crítico si framework missing/legacy. |
| **Watchdog** | Timer 30s post-boot verifica Core Override aplicado correctamente. Si no → broadcast admin alert + KVP `sonar_bank_compromised`. |
| **Trust Window** | Skip reconciliation check si `now - cached_ts < 5min` AND `last_known_source = 'sonar'`. |
| **IBAN** | Identifier único cuenta — formato `SONAR{4-letter-server-code}{16-digit-account}` per `@docs/economy/01_economic_model.md`. |
| **Audit Ledger Inmutable** | Tabla `sonar_bank_audit_ledger` append-only — todo evento Bank deja huella. Ningún UPDATE/DELETE permitido. |
| **Compliance Flags Autoraise** | Sistema 5 patrones automatic detection (structuring + large_transfer + late_tax + velocity + new_account_large_deposit). |
| **Government Console** | UI dedicada govt entity (NPC o player elected). Audit Explorer scope "Todas" + tax brackets editor + subsidies + treasury. |
| **Empresas Dashboard** | UI dedicada dueño empresa player-driven. Sub-cuentas tesorería + payroll + audit propio + escrow B2B. |
| **Treasury** | Cuenta tesorería empresa o gobierno. Cash flow forecast + multi-signer auth. |
| **Escrow B2B** | Cuenta intermediaria B2B con FSM 6-states (`pending_funding` / `funded` / `released_partial` / `released_full` / `disputed` / `refunded`). |
| **Audit Explorer** | UI dedicada visualización audit ledger. 3 scopes (Mis cuentas / Mis empresas / Todas ACE govt). |
| **Phase A-E** | Slices técnicos de troceado de trabajo. Phase E = shipping milestone único `sonar-bank-v1`. |
| **Sub-tag** | Release engineering internal milestone (ej. `bank-phase-a`, `bank-phase-b`). Ningún sub-tag es shipping público hasta Phase E. |

---

## 9. Próximos pasos (post-onboarding cada Lead)

1. Lectura completa onboarding 10-step (manifest §7).
2. Slice propio review → cuestionar diseños dudosos.
3. Research primitivas modernas FiveM relevantes a tu dominio.
4. Draft v0.1 SSoT(s) tu dominio.
5. Notificar founder + Leads consumer(s) → review window 24h.
6. Iterar v0.2, v0.3 según feedback.
7. Sign-off triple founder + owner + consumer(s) → v1.0 LOCKED.
8. Handoff Hx ceremony + SESSION_LOG entry.
9. Próximo Lead arranca según orden manifest §2.

---

## 10. Versioning

| Version | Fecha | Cambios |
|---|---|---|
| **v1.0** | 2026-05-06 | Initial release post Q16 RESOLVED + manifest LOCKED. |

— **Brief LOCKED** post founder green-light 2026-05-06.
