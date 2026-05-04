# 🧪 Admirals — Testing Protocol

> **Versión:** 1.0 (firmado — completo, 16 secciones).
> **Tipo:** QA/Implementation. Protocolo completo de testing **FiveM-native** (no E2E automation per ADR-006) — smoke tests, manual test matrix, integration scenarios, stress testing, regression, playtest, bug tracking, release gates.
> **Documento padre:** `agents/02_working_conventions.md` v1.0 (firmado).
> **Documento hermano:** `technical/06_fivem_standards.md` v1.0 (firmado) — performance + security standards validados por tests.
> **Documento hermano:** `technical/05_state_machines.md` v1.0 (firmado) — FSMs testadas transition-by-transition.
> **Documento hermano:** `technical/04_api_contracts.md` v1.0 (firmado) — callbacks testados per contract.
> **Estado:** firmado.

> **Lectura previa obligatoria:** `technical/04_api_contracts.md`, `technical/05_state_machines.md`, `technical/06_fivem_standards.md`, `planning/02_decision_log.md` (ADR-006).

---

## 0. Resumen ejecutivo

Este documento define el **protocolo de testing de Admirals** — qué se testea, cómo, cuándo, por quién, y cómo se reporta. Dada la realidad FiveM (no hay framework E2E auto estándar, cada cambio requiere playtest humano real), este doc es **pragmático, manual-first, con automatizaciones donde aportan valor real**.

> **Filosofía:** **sin testing disciplinado → bugs en prod = pérdida de confianza cliente = negocio muerto.** Con testing disciplinado → ship stable, iterate con confidence, reputation premium.

Define:

- **Test pyramid Admirals** adaptado a FiveM (unit baja, integration media, playtest alta).
- **Smoke test checklist** pre-push / pre-release.
- **Manual test matrix** per callback + FSM + flujo UI.
- **Integration scenarios** concretos (happy + edge cases).
- **Stress / load testing** con bot simulation.
- **Regression checklist** pre-release Oleada.
- **Playtest protocol** solo + team sesiones.
- **Economy validation tests** — integrity ledger + lineage.
- **Bug reporting format** + priority matrix.
- **Release gates** — qué pasa antes de shippear.
- **Roles** QA (solo founder inicialmente, team luego).

> **Por qué este doc importa:** sin protocolo claro, testing se vuelve "ad-hoc, hope for the best". Resultado: bugs embarazosos en prod, clientes unhappy, brand damaged. Con este doc, cada release pasa gates concretos.

---

## 1. Filosofía QA Admirals

### 1.1 Realities FiveM

- ❌ No hay framework E2E estándar (no Cypress/Playwright equivalent server-side).
- ❌ Mocks de FiveM natives no existen maduros.
- ✅ Sí: unit tests de Lua puro (sin natives), JS/TS tests NUI (React).
- ✅ Sí: integration tests server booted con script testing.
- ✅ Sí: playtest manual con test characters.

### 1.2 Los 7 principios

| # | Principio | Significado |
|---|---|---|
| **Q1** | **Manual-first pragmatic** | No over-engineer auto tests si playtest es más rápido. |
| **Q2** | **Cada PR requiere smoke test** | Pre-merge. |
| **Q3** | **FSMs testean every transition** | Happy + guards + invalid + idempotency. |
| **Q4** | **Economy integrity = non-negotiable** | Ledger checks cron + on-demand. |
| **Q5** | **Playtest con team regular** | Weekly minimum, post-release mandatory. |
| **Q6** | **Bugs priorizados** | P0 blocks release, P1 fix fast, P2 backlog, P3 cosmetic. |
| **Q7** | **Regression always checks critical paths** | Login, tablet, bank, empresa basic. |

### 1.3 Anti-principios

- ❌ "Ship si funciona en mi máquina."
- ❌ "Tests los hacemos al final."
- ❌ "No hace falta playtest si passed smoke."
- ❌ "Bug P3 puede esperar siempre" (accumulation rot).

---

## 2. Test pyramid Admirals

```
         /\
        /  \       Playtest (highest value, slowest)
       /----\
      /      \    Integration tests (middle, moderate speed)
     /--------\
    /          \  Unit tests (lowest value standalone, fastest)
   /------------\
```

**Distribution:**
- **~20% unit tests** (logic puro Lua + React components pure).
- **~30% integration tests** (API callbacks, DB ops, FSM transitions).
- **~50% playtest** (full flows, UX, performance in-game).

---

## 3. Smoke tests

### 3.1 Propósito

**Smoke test = 5-10 min de validación rápida** antes merge / release. Detecta regressions obvios.

### 3.2 Daily smoke (pre-push)

Checklist ~5 min:

- [ ] Server boots sin errores (check logs).
- [ ] Connect test character 1.
- [ ] Login flow completes.
- [ ] Tablet opens (TAB).
- [ ] Home app renders.
- [ ] Bank app: saldo shown.
- [ ] Messages app: list loads.
- [ ] No errors console client.
- [ ] No errors console server.
- [ ] Resmon baseline OK (<3ms total).

### 3.3 Pre-release smoke (Oleada)

Checklist ~30 min, expanded:

- [ ] All daily smoke items.
- [ ] 2 test characters simultáneos connect.
- [ ] Transfer money between 2 IBANs.
- [ ] Create empresa founder role.
- [ ] Hire test employee.
- [ ] Send chat message.
- [ ] Open every Tablet app, navigate basic flows.
- [ ] Farm plot plant → harvest cycle (accelerated dev timers).
- [ ] Mill batch create → complete.
- [ ] Bakery oven bake cycle.
- [ ] Retail transaction POS simulation.
- [ ] Logout + relogin preserves state.

### 3.4 Smoke test script

Crear `scripts/smoke_test.md` con checklist copy-pasteable.

---

## 4. Manual test matrix

### 4.1 Per callback

Cada callback documented en `technical/04_api_contracts.md` tiene test cases:

| Test case | Expected |
|---|---|
| Happy path (válido params) | success=true + data |
| Missing required param | `VALIDATION_FAILED` error code |
| Invalid type (string donde int) | `VALIDATION_FAILED` |
| Unauthorized (no role) | `NOT_AUTHORIZED` |
| Rate limit exceeded | `RATE_LIMITED` after N calls |
| Idempotency (same request_id twice) | 2nd returns cached response |
| Business rule violation (e.g., insufficient funds) | specific error code |

### 4.2 Per FSM

Cada FSM en `technical/05_state_machines.md` tiene test cases per transición:

Para transición `from → to`:

| Test case | Expected |
|---|---|
| Happy (guard passes) | state = `to` + side effects applied |
| Guard fails | `INVALID_TRANSITION` error + state unchanged |
| Invalid from_state (e.g., `completed → fulfilling`) | rejected |
| Concurrent (2 simultáneas) | 1 success, 1 error |
| Audit log row inserted | true |
| Side effects atomic (all or none) | true |

### 4.3 Per Tablet app

Cada app Tablet:

| Test case | Expected |
|---|---|
| App opens from home | renders initial state |
| Back navigation | returns home |
| Data loading state visible | spinner shown |
| Error state visible (simulate server error) | error UI + retry button |
| Empty state (no data) | empty illustration + CTA |
| Interactions (tap, type, swipe) | expected response |

### 4.4 Matrix tracking

Document cada run en `qa/runs/YYYYMMDD_smokerun.md`:

```markdown
# Smoke Run 2026-05-10

**Tester:** founder
**Build:** 0.3.0-alpha
**Duration:** 12 min

## Results
- [x] Server boot
- [x] Login
- [x] Tablet open
- [ ] Bank transfer — FAILED: saldo mismatch after refresh
  - Bug ID: #BUG-023
...

**Summary:** 9/10 pass. 1 P2 bug filed.
```

---

## 5. Integration scenarios

### 5.1 Scenario library

Escenarios e2e-ish con multiple callbacks + FSMs + UI:

#### Scenario 5.1.1 — Happy B2B Contract

**Flujo:**
1. Empresa Bakery founder `createContractDraft` con Granja empresa.
2. Both negotiate (counter-offers).
3. Both sign → escrow auto-created + locked.
4. Granja delivers first batch via logistics.
5. Logistics job completes.
6. Contract progress advances.
7. Full delivery completes.
8. Contract → `completed`, escrow → `released`.
9. Seller gets money minus fee.
10. Both reputations +.

**Assertions:**
- Ledger balance check: buyer -amount, seller +amount, escrow=0.
- Reputation +.
- Audit log chain completo.
- FSMs transiciones correctas.

#### Scenario 5.1.2 — Empresa Bankruptcy Cascade

**Flujo:**
1. Empresa with 5 employees, 2 active contracts, 3 escrows active.
2. Trigger bankruptcy (cash < 0 for 7 days).
3. FSM `empresa → bankrupt`.

**Assertions:**
- All 5 employees `status=terminated`.
- 2 contracts `status=defaulted` + escrows refunded to buyers.
- Empresa IBAN closed.
- Admirals physical assets (plots, stations) → bank collateral.
- Founder reputation -.
- Events emitted for each cascade.

#### Scenario 5.1.3 — Dispute Resolution

**Flujo:**
1. Contract signed, delivery in progress.
2. Buyer disputes (quality issue).
3. FSM `contract → disputed`, `escrow → disputed` (frozen).
4. Evidence gathering (audit logs, quality scores).
5. Arbitration ruling: split 25/75 (buyer favor).
6. FSM `dispute → resolved`.

**Assertions:**
- Escrow split correctly.
- Both parties notified.
- Reputation impacts applied.
- Audit trail complete.

#### Scenario 5.1.4 — Farm → Mill → Bakery → Retail chain

**Flujo:**
1. Farm plants wheat.
2. Harvest → wheat items produced with quality A-D.
3. Sell wheat to mill (B2B contract or direct).
4. Mill batch processes wheat → flour.
5. Bakery receives flour → mixer → oven → pan/baguette.
6. Retail buys baguettes → displays on shelf.
7. Customer (player or NPC) buys baguette.
8. Full lineage tracked.

**Assertions:**
- Lineage chain complete (wheat_batch_id in flour.lineage, flour.batch_id in baguette.lineage).
- Quality degradation / preservation logic applied.
- Each B2B transaction audited.
- Total money flow balances.

#### Scenario 5.1.5 — Offline employee salary accrual

**Flujo:**
1. Employee clocks in, works shift.
2. Player disconnects.
3. Next day, salary accrual batch runs.
4. Player reconnects.
5. Bank shows salary credited.

**Assertions:**
- Salary calculated correctly (hours × rate).
- Credit event logged.
- Employee notif on reconnect.

#### Scenario 5.1.6 — Tablet offline resilience

**Flujo:**
1. Player has Tablet open.
2. Server disconnect briefly.
3. Reconnect.
4. Tablet should restore state.

**Assertions:**
- No UI crash.
- Data refreshes.
- Pending actions retried o clearly failed.

### 5.2 Run cadence

- Pre-release: todos los scenarios (run once).
- Weekly: 1-2 random scenarios.
- Post-bug-fix: related scenario.

---

## 6. Stress / load testing

### 6.1 Propósito

Validar performance bajo carga real (50-100 players concurrent).

### 6.2 Bot simulation setup

Oleada 2+ (Oleada 1 puede ser manual).

```
scripts/load_test/
  - bot_player.lua   # simulated player
  - scenarios.lua    # list of flows
  - run.sh           # spawn N bots
```

**Bot actions:**
- Connect + auth.
- Open Tablet, navigate 3 apps.
- Transfer money random.
- Send chat messages.
- Stay connected 10 min.
- Disconnect.

### 6.3 Load test targets

| Players concurrent | Resmon total | FPS client | DB p99 |
|---|---|---|---|
| 10 | <1ms | ≥60 | <50ms |
| 30 | <3ms | ≥60 | <100ms |
| 50 | <5ms | ≥55 | <200ms |
| 80 | <8ms | ≥50 | <500ms |
| 100 | <10ms | ≥45 | <1s |

**Fail criteria:** any threshold broken sostenido > 1 min.

### 6.4 Load test scenarios

- **Steady state:** 50 bots, 30 min, normal activity.
- **Burst:** 50 bots all spawn simultáneamente.
- **Heavy transactions:** 50 bots all doing bank transfers rapid.
- **Tablet spam:** 50 bots open/close Tablet rapidly.

### 6.5 Load test cadence

- **Oleada 1:** manual 10-20 humans for 1h sesión post-release.
- **Oleada 2+:** bot suite automated weekly.

---

## 7. Regression checklist pre-release

### 7.1 Critical paths (always test)

Antes de cualquier release, verify:

- [ ] Login / character creation.
- [ ] Tablet opens + all apps navegables.
- [ ] Bank: view balance, transfer, view history.
- [ ] Messages: send, receive, mark read.
- [ ] Empresa: create, view members, hire/fire.
- [ ] Market: create offer, browse, buy.
- [ ] Inventory: view, drop, pickup.
- [ ] Performance: resmon <5ms total with 10 players.
- [ ] No errors console nothing.

### 7.2 Node-specific (per Oleada)

Oleada 1 MVP (Bakery):
- [ ] Bakery mixer + oven full cycle.
- [ ] Flour input consumed correctly.
- [ ] Baguette output correct quality.
- [ ] Ledger clean after 10 bakings.

Oleada 2 (Granja + Molino + Retail):
- [ ] Granja plot plant → harvest full.
- [ ] Mill batch end-to-end.
- [ ] Retail POS transaction + inventory decrease.
- [ ] Logistics job pickup + deliver.

### 7.3 Economic integrity

- [ ] `total money in system = initial + minted - sinks` ± 0.01%.
- [ ] No items sin lineage (except origin types).
- [ ] No orphan escrows > 30 days.
- [ ] No FSMs stuck en estado intermedio > 24h.

---

## 8. Bug reporting + tracking

### 8.1 Bug report format

```markdown
# BUG-YYY [título conciso]

**Priority:** P0 / P1 / P2 / P3
**Component:** bakery / bank / tablet / ...
**Reporter:** founder / test_player_X
**Date:** 2026-05-10
**Build:** 0.3.0-alpha

## Steps to reproduce
1. ...
2. ...
3. ...

## Expected
...

## Actual
...

## Logs / screenshots
- Server log snippet.
- Client log snippet.
- Screenshot if UI.

## Audit log relevant
- event_log entries IDs: [...]

## Impact
- User-facing / internal.
- Data corruption? Yes/No.
- Exploitable? Yes/No.
```

### 8.2 Priority matrix

| Priority | Definition | SLA |
|---|---|---|
| **P0** | Blocker: crash, data loss, security exploit, money dupe | Fix before release, immediate |
| **P1** | Critical: feature broken, significant UX | Fix this sprint |
| **P2** | Normal: feature partially broken, workaround exists | Next sprint |
| **P3** | Cosmetic: UI polish, nice-to-have | Backlog |

### 8.3 Bug storage

- **GitHub Issues** (if repo público / privado).
- Alternative: `qa/bugs/BUG-NNN.md` files.
- Tag con component + priority.

### 8.4 Bug lifecycle

```
reported → triaged → assigned → in_progress → fixed → verified → closed
                               ↘ won't_fix
                               ↘ cannot_reproduce
```

Each state tracked con timestamp + actor.

---

## 9. Playtest protocol

### 9.1 Solo playtest (founder daily)

~30 min/day:
1. Login test char.
2. Run 1-2 scenarios del library.
3. Note anomalies en log.
4. File bugs si found.

### 9.2 Team playtest (weekly, Oleada 2+)

Si team grows:
- 2-4 testers simultaneous.
- 1h sesión.
- Focus: specific feature released week.
- Rapporteur takes notes.
- End: retrospective 15min.

### 9.3 Closed beta

Oleada 1 MVP release:
- Invite 10-20 servers amigos.
- 1 week beta window.
- Feedback channel (Discord).
- Metrics monitored.

---

## 10. Economy validation tests

### 10.1 Daily integrity check (cron)

```sql
-- Money in circulation
SELECT
  (SELECT COALESCE(SUM(balance), 0) FROM sonar_bank_accounts WHERE type IN ('personal','empresa','escrow')) AS total,
  (SELECT COALESCE(SUM(amount), 0) FROM sonar_bank_movements WHERE type='mint') AS minted,
  (SELECT COALESCE(SUM(amount), 0) FROM sonar_bank_movements WHERE type='sink') AS sunken
-- Expected: total = initial + minted - sunken
```

Alert si diff > 0.01%.

### 10.2 Item inventory check

```sql
-- Items sin lineage
SELECT COUNT(*) FROM sonar_items
WHERE status IN ('delivered','on_display','sold','in_inventory')
  AND lineage_json IS NULL
  AND item_type NOT IN ('seed','raw_resource'); -- origin types OK
```

Expected: 0.

### 10.3 FSM stuck detection

```sql
-- Escrows locked > 30 días
SELECT id FROM sonar_escrows
WHERE status = 'locked'
  AND updated_at < UNIX_TIMESTAMP(NOW()) - 2592000;

-- Contracts fulfilling > 90 días
SELECT id FROM sonar_contracts
WHERE status = 'fulfilling'
  AND updated_at < UNIX_TIMESTAMP(NOW()) - 7776000;
```

Expected: empty or known-investigated.

### 10.4 Reputation anomalies

```sql
-- Reputation outside -100 to +100
SELECT id FROM sonar_reputation
WHERE score < -100 OR score > 100;
```

Expected: 0.

### 10.5 Audit log health

```sql
-- Audit log entries per day trend
SELECT DATE(FROM_UNIXTIME(timestamp)) AS day, COUNT(*)
FROM sonar_audit_log
GROUP BY day
ORDER BY day DESC LIMIT 7;
```

Flag anomalies (sudden drop or spike).

---

## 11. Release gates

### 11.1 Gate levels

#### Gate 1 — Dev merge
- Smoke test daily pass.
- Code review checklist (see `technical/06_fivem_standards.md` §6).
- No P0/P1 open.

#### Gate 2 — Alpha release (internal)
- Smoke pre-release pass.
- 2-3 integration scenarios pass.
- Economic integrity OK.
- Resmon budgets OK.

#### Gate 3 — Beta release (limited users)
- All integration scenarios pass.
- Regression checklist pass.
- Load test 30 concurrent pass.
- 1 week alpha stable.
- No P0/P1/P2 open > 1 week.

#### Gate 4 — Public release (Tebex)
- All beta gates.
- Load test 50 concurrent pass.
- 2 weeks beta stable.
- Documentation user-facing completa.
- Changelog prepared.
- Rollback plan documented.

### 11.2 Release checklist

Antes publish Tebex:

- [ ] All gates passed.
- [ ] Versión bumped correctamente.
- [ ] Changelog updated.
- [ ] Migration scripts tested on clean DB.
- [ ] Backup production DB.
- [ ] Docs user-facing updated.
- [ ] Discord announcement drafted.
- [ ] Rollback procedure ready.
- [ ] Support standby 24h post-release.

---

## 12. Roles QA

### 12.1 Oleada 1 (solo founder)

- Founder = QA lead + tester + bug filer.
- Weekly self-playtest.
- Daily smoke pre-push.

### 12.2 Oleada 2+ (team if hired)

- Dedicated QA person (part-time OK).
- Testers volunteers from Discord.
- Automated bot suite.

---

## 13. Tooling

### 13.1 Manual testing

- **In-game admin commands** para create test data rápido:
  - `/sonar_dev giveitem <type>`
  - `/sonar_dev setmoney <amount>`
  - `/sonar_dev spawnempresa`
  - `/sonar_dev resetplayer`

### 13.2 Logging

- Server log verbose en dev mode.
- NUI devtools accesible.
- Audit log query-able.

### 13.3 Metrics dashboard

Oleada 2+:
- Grafana o equivalent.
- Resmon history.
- Active players.
- Transaction volume.
- Bug count trending.

### 13.4 Bug tracker

- GitHub Issues (recommended).
- Tags: priority (P0-P3), component, status.

---

## 14. Anti-patterns QA

- ❌ **"Smoke test optional"** — skip one day, miss regression.
- ❌ **"P3 bugs accumulate"** — 100 P3 bugs = UX disaster.
- ❌ **"Test en prod only"** — embarrassing.
- ❌ **"Playtest de amigos, they're nice"** — biased feedback.
- ❌ **"No economy integrity checks"** — money dupes go undetected.
- ❌ **"Release gates son guidelines"** — slippery slope.
- ❌ **"Performance lo medimos después"** — opposite of `fivem_standards`.

---

## 15. Roadmap + estado

### 15.1 Roadmap QA

#### Oleada 1 (MVP)
- ✅ Smoke test daily checklist.
- ✅ Manual test matrix per callback/FSM.
- ✅ Integration scenarios core (contract, bankruptcy, dispute, chain, offline).
- ✅ Bug reporting format.
- ✅ Release gates definidos.
- ✅ Economic integrity daily cron.
- 🔜 Admin dev commands tooling.

#### Oleada 2
- 🔜 Bot suite load testing.
- 🔜 Dashboard Grafana metrics.
- 🔜 Automated regression script (parcial).
- 🔜 Team testing cadence.

#### Oleada 3+
- 🔜 Continuous integration (if tooling improves).
- 🔜 Advanced chaos testing.
- 🔜 Public bug bounty.

### 15.2 Estado del documento

- **Versión:** 1.0 (firmable — completo, 15 secciones).
- **Próxima revisión:** primer release Alpha con aprendizajes reales.
- **Documento padre:** `agents/02_working_conventions.md`.
- **Documentos hermanos:** `technical/04_api_contracts.md`, `technical/05_state_machines.md`, `technical/06_fivem_standards.md`.

### 15.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Primera redacción. 15 secciones. Smoke daily + pre-release, manual test matrix, 6 integration scenarios, stress targets, regression checklist, bug format + priority, playtest protocol, economic integrity, release gates (4 niveles), tooling, anti-patterns, roadmap. **Firmable.** |

---

## 16. TL;DR

### Reglas absolutas QA

- 🧪 **Smoke test daily antes push** (~5 min).
- 🧪 **Smoke pre-release** (~30 min) cada Oleada.
- 🔁 **Integration scenarios** run pre-release.
- 📊 **Economic integrity cron** diario.
- 🚨 **P0/P1 bloquean release**.
- 🎮 **Playtest weekly minimum** (solo o team).
- 🏁 **Release gates** cuatro niveles cumplirse.

### Smoke test daily (5 min)

- Server boots, login, tablet open, bank view, messages load, no errors, resmon OK.

### Integration scenarios core (6)

1. Happy B2B contract.
2. Empresa bankruptcy cascade.
3. Dispute resolution split.
4. Farm→Mill→Bakery→Retail chain.
5. Offline salary accrual.
6. Tablet offline resilience.

### Priority matrix

- **P0** crash/exploit/money-dupe → fix immediate.
- **P1** critical feature broken → this sprint.
- **P2** partial broken + workaround → next sprint.
- **P3** cosmetic → backlog.

### Release gates

1. **Dev merge:** smoke + review + no P0/P1.
2. **Alpha:** + integration scenarios + integrity.
3. **Beta:** + regression + load 30 + 1w stable.
4. **Public:** + load 50 + 2w stable + docs + rollback.

---

## Resumen ejecutivo (cierre)

El **Testing Protocol Admirals** es el sistema de calidad del producto:

- **Manual-first pragmatic** adaptado a realidades FiveM (sin E2E auto estándar).
- **Smoke tests** diarios + pre-release con checklists copy-pasteables.
- **Manual test matrix** per callback + FSM + Tablet app.
- **Integration scenarios** e2e-ish cubriendo happy paths + edge cases críticos (contratos, bankruptcy, disputes, chains).
- **Stress testing** con targets por concurrencia (10/30/50/80/100 players).
- **Regression checklist** pre-release con critical paths + nodos.
- **Economic integrity** validation diaria (ledger, lineage, FSMs stuck, reputation).
- **Bug reporting** format estandarizado + priority matrix P0-P3.
- **Release gates** 4 niveles (dev → alpha → beta → public).
- **Anti-patterns** documentados.

> **Cada release Admirals pasa gates concretos.** No hay "hope it works" — hay smoke+integration+regression+integrity documentados y checkeados. Esto es **la diferencia entre un producto premium y un producto amateur**.

---

*"Un bug en prod es 100x más caro que un bug en dev. Un bug económico es 1000x más caro que un bug UX."*

**FIN DEL DOCUMENTO `qa/01_testing_protocol.md` v1.0**
