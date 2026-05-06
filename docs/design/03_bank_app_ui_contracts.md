# C-FE-01 — UI Contracts SONAR Bank Phase A v0.1 DRAFT

> **Owner:** Frontend & UX Premium Lead.
> **Status:** 🟡 v0.1 DRAFT BANK-FE.0 2026-05-06.
> **Sibling:** C-FE-02 + C-FE-03.
> **Upstream LOCKED:** C-BE-01..05 v1.0.1 R1 + C-SEC-01/02/03 v0.2 PASS + ADR-016 ✅ + ADR-017 🟡.

---

## 1. Filosofía + scope

### 1.1 Principles inquebrantables (P1-P8)

- **P1 — Tactile UI doctrine.** Multi-layer box-shadow ladder ADR-017 D2. Flat **prohibido**.
- **P2 — Privacy boundary M004 zero-tolerance.** Empleadores NUNCA balance personal empleados.
- **P3 — Reactividad disciplinada.** Snapshot-first → attach NetEvent/StateBag → watchdog 30s. NO polling.
- **P4 — Single source truth contracts upstream LOCKED.** Gap → `FE_BACKEND_REQUESTS.md`.
- **P5 — Dark-only + reduced-motion + WCAG 2.2 AA.** ADR-016 D3 + ADR-017 D7/D8.
- **P6 — i18n 4 locales.** ES + EN + FR + DE. `react-i18next` lazy. Fallback es → en.
- **P7 — ACE gating canonical.** 12 perms P01-P12 (C-SEC-02) → conditional rendering.
- **P8 — Tier B perf observability** (no enforcement Phase A per ADR-017 D6).

### 1.2 Scope IN/OUT

**IN:** 10 vistas + 32 components + reactivity + ACE gating + privacy + i18n 4 locales + a11y + onboarding 3-step + Transfer Wizard 4-step + Express 2-step.

**OUT:** light mode, mobile portrait, Discord webhooks (Phase D), Statement PDF mensual + Tax export (Phase B), bootstrap consolidado (REQ-FE-001 R2), recent recipients (REQ-FE-002 R2), compliance ack (REQ-FE-003 Phase B).

---

## 2. Component library (32 components)

### 2.1 Tier 1 — Primitives (10)

| ID | Componente | SFX | Motion | Tactile class | A11y |
|---|---|---|---|---|---|
| **P-01** | `<Button variant size loading? disabled? icon?>` | `console_tap` / `depth_press` (primary) | press translateY 1px + bevel invert | `tactile-button-*` | `aria-busy`, `aria-disabled` |
| **P-02** | `<IconButton icon size variant>` | `console_tap` | hover lift 1.04 + shadow rise | bevel inset subtle | `aria-label` mandatory |
| **P-03** | `<Input type label hint error icons>` | none | focus ring expand 200ms | bevel inset (pressed-in) | `aria-invalid`, `aria-describedby` |
| **P-04** | `<Card variant="baseline"\|"elevated"\|"glass" hero?>` | none | hover elevate (interactive) | `tactile-card[-elevated]` / `tactile-glass-card` | `role="region"` |
| **P-05** | `<Badge tone variant>` | none | none | bevel subtle inset | `aria-label` if icon-only |
| **P-06** | `<Avatar src alt size badge?>` | none | none | inset bevel + outer ring | alt mandatory |
| **P-07** | `<Skeleton variant shimmer>` | none | shimmer gradient 200% 1.6s linear | none | `aria-busy`, `aria-label="Cargando"` |
| **P-08** | `<Toast tone severity title desc action duration>` | `signal_emerge` (success) | enter slide+fade 320ms out_expo | glass surface | `role="status"`/`alert` |
| **P-09** | `<Tooltip content delay side>` | none | fade+scale 200ms | glass-subtle blur 12px | `role="tooltip"` |
| **P-10** | `<Spinner size variant>` | none | rotate 360° linear 1s | none | `role="status"`, `aria-label` |

### 2.2 Tier 2 — Composites (12)

| ID | Componente | SFX | Motion |
|---|---|---|---|
| **C-01** | `<BalanceCard accountType>` (hero glass + amount + delta% + lastUpdate + spinner stale) | none | count-up 640ms premium spring on update |
| **C-02** | `<TransactionRow direction>` (Avatar + label/iban + Badge category + amount semantic + ts) | `console_tap` click | hover lift moderate |
| **C-03** | `<ApprovalCard kind>` (Card elevated + status + summary + Approve/Reject) | `depth_press` confirm | enter slide moderate |
| **C-04** | `<StatusBadge state>` reactive `bank.bridges.status` | none | color transition 200ms |
| **C-05** | `<TransferWizardStep step>` form + footer | `layer_dive` next | slide+fade moderate |
| **C-06** | `<VistaShell title eyebrow actions heroLight>` | `signal_emerge` mount | fade-up 480ms |
| **C-07** | `<DataTable columns rows pagination filters>` virtualized | `console_tap` row | rows enter staggered 40ms |
| **C-08** | `<ChartSparkline data height tone>` (Recharts AreaChart gradient fill) | none | path stroke draw 640ms ease-out |
| **C-09** | `<ChartBars data labels tone>` (Recharts BarChart rounded) | `console_tap` hover | bars rise staggered |
| **C-10** | `<ConfirmDialog title desc cta>` | `panel_open` open | scale-fade enter moderate |
| **C-11** | `<ToastQueue position>` (consumes `useToastQueue` Zustand) | per Toast | per Toast |
| **C-12** | `<EmptyState icon title desc action>` | none | fade-in moderate |

### 2.3 Tier 3 — Vista Shells (10)

`<OverviewVista>` / `<AccountsListVista>` / `<TransferWizardVista>` / `<AuditExplorerVista>` / `<ComplianceConsoleVista>` / `<EmpresasDashboardVista>` / `<GovernmentConsoleVista>` / `<PayrollBatchVista>` / `<RecurringVista>` / `<OnboardingVista>` — specs §3.

---

## 3. 10 vistas — specs detallados

### 3.1 V1 — Overview

**Layout:** sidebar 80px + grid 12col. R1 hero `<BalanceCard main>` (1-8) + `<BalanceCard savings>` (9-12). R2 `<ChartSparkline>` 6mo (1-8) + Recurring teaser (9-12). R3 5 `<TransactionRow>`. R4 4 quick-actions.

**Bindings:** `useBootstrapSnapshot()` mock (REQ-FE-001) + `useBankNetEvent('balance:update'|'savings:update')` reactive + `useBankCallback('bank.transactions.list',{limit:5})` + `useBankCallback('bank.recurring.nextPayment')`.

**Reactivity:** mount snapshot → attach NetEvent → watchdog 30s defensive.

**Interactions:** click BalanceCard → V2 filtered. Click row → modal detail. Quick-action navigate.

**ACE:** P01 baseline. **Privacy:** OWN data only.

**States:** loading (skeletons hero + chart + rows). Empty (`<EmptyState>` + Transfer CTA). Error BANK_DISABLED (AlertTriangle + reason kvp).

### 3.2 V2 — Accounts List

**Layout:** split — left (1-4) `<DataTable>` accounts compact + right (5-12) detail `<EntityWorkspace mode="account">` + transactions paginated + actions.

**Bindings:** `bank.account.list` (C005) + `bank.transactions.list` cursor + `bank.business_treasury.<id>` StateBag.

**Filters:** chips class + IBAN search.

**ACE:** P01. Business visible per `business_memberships`.

**Privacy M004:** business detail = treasury aggregate + own movements (`tx.citizen_id===self`) ONLY. NO employee balance.

### 3.3 V3 — Transfer Wizard

**4-step:**
| Step | Inputs | Validation | Footer |
|---|---|---|---|
| 1 amount | amount + EUR + memo | >0 ∧ ≤available ∧ ≤daily_remaining | Cancel/Next |
| 2 recipient | IBAN OR alias + recent chips (REQ-FE-002 mock) | IBAN format + ban list | Back/Next |
| 3 review | summary readonly + correlation_id | none | Back/Confirm (200ms hold) |
| 4 confirm | spinner + status + result | none | view receipt / new / done |

**Express 2-step (Q5 APPROVED):** when recipient ∈ recentRecipients ∧ count_30d≥2 → step 1 merged (recipient chip pre-selected top 3 + amount) + step 2 (review + confirm).

**Bindings:** `bank.transfer:execute` (C001) idempotency_key via `crypto.randomUUID()` + `useRecentRecipients()` mock + `balance:update` post-confirm (3s wait → manual refetch fallback).

**Idempotency client:** UUIDv4 per wizard mount stable nav back/forward → cleared success/cancel.

**Validation:** Zod `transferRequestSchema` shared client/server. UI traduce error.code ENUM → toast localized.

**SFX:** transitions `layer_dive`. Confirm `depth_press`. Success `coin_clink` + `vault_close` 200ms after. Error silent + visual.

**Motion:** transitions 320ms moderate out_expo + spring premium (k=220 d=18). Confirm bevel invert + scale 0.98. Success: balance count-up 640ms + receipt scale-bounce.

**ACE:** P01. AR-P01 large_transfer (default 10k EUR convar) → step 3 informational `<Badge warning>` tooltip — NOT blocking.

**Receipt PDF:** lazy `@react-pdf/renderer` chunk on click. Template: logo + amount + iban_masked + memo + correlation_id + ts + watermark. Filename `sonar-bank-recibo-<correlation_id_short>.pdf`.

### 3.4 V4 — Audit Explorer

**Layout:** R1 scope tabs (Mis cuentas / Mis empresas / Todas govt) + filter (date + event_type + amount + search). R2 `<DataTable>` virtualized 12 cols (timestamp + event_type + actor_cid_masked + amount + currency + correlation_id_short + counterparty_masked + status + ACE_perm + reason + scope_tag + receipt_link). R3 cursor pagination.

**Bindings:** `bank.audit.query` (C035) cursor.

**ACE matrix:**
| Tab | Perm | Visible | Si missing |
|---|---|---|---|
| Mis cuentas | P02 auto ALL | Always | - |
| Mis empresas | P03 dynamic | empleados/owners | Hidden |
| Todas govt | P04 govt | govt only | Hidden |

**Privacy M004:** scope server-enforced. NO bypass client.

**Receipt sub-modal:** click row → `<Modal>` payload JSON + correlation_id + chain related events + redacted fields if scope=govt_full.

### 3.5 V5 — Compliance Console

**Layout:** R1 tabs (Self / Admin oculto si non-admin) + filter (status/severity/age). R2 `<ApprovalCard>` × N active (type + severity + raised_at + reason + autoraise_rule + actions). R3 history collapsed.

**Bindings:** `bank.compliance.listFlags` (C036/C036admin) + `compliance:flagRaised` NetEvent + `bank.compliance.<cid>.public` StateBag (CP1-A reduced) badge counter.

**Resolve flow (P10):** click "Resolve" → `<ConfirmDialog>` + note mandatory + severity reduction → `bank.compliance.resolve` (C038) → toast + Motion exit slide-fade.

**ACE matrix:** Self P01. Admin tab + actions P10. Manual raise P10+P11.

**Privacy M004:** Self own. Admin all reduced shape — full reason + actor visible per ACE.

**Workaround ack (REQ-FE-003 path-C):** click "Marcar leído" → `localStorage` flag → hide badge + opacity card. Phase B replaces backend.

### 3.6 V6 — Empresas Dashboard

**Layout:** R1 hero `<BalanceCard business>` (1-7) reactive + delta + sparkline 4w + actions (8-12: Pay payroll / Withdraw / Audit). R2 employee aggregate stats card (count + tenure days + total payroll month — **NO individual balances**) (1-6) + recent business movements (7-12). R3 pending approvals `<ApprovalCard>` × N owner-only.

**Bindings:** `bank.business.treasuryGet` (C039) + `bank.business_treasury.<id>` StateBag + `bank.business.employees.aggregate` (counts + total payroll, NO individuals) + `bank.business.movements.list` + `bank.business.pendingApprovals` owner only + `business:treasuryUpdated` NetEvent.

**ACE matrix:**
| Action | Perm | Hidden si |
|---|---|---|
| View dashboard | membership any | no membership |
| Withdraw | role==='owner' | non-owner |
| Pay payroll | P05 | missing |
| Approve loan/recurring | P06+owner | missing |
| Audit empresa | P03 | missing |

**Privacy M004 (Q4 MAX-PRIVACY):**
- Aggregate: count + total_payroll_month + average_tenure_days ONLY.
- Payroll V8: alias + last_paid + next_amount input — **NO balance column**.
- P03 audit scope: business movements + payroll batches — counterparty masked/alias only.

### 3.7 V7 — Government Console

**Layout:** R1 emblem + role badge + `<StatusBadge>`. R2 4 tabs (Subsidies / Tax / Audit Full / Admin Actions).

**Subsidies:** `<DataTable>` active + "Grant new" `<Modal>` form + "Revoke" `<ConfirmDialog>` reason.
**Tax:** `<DataTable>` brackets edit-in-place. Save → `bank.tax.updateBrackets` mutation idempotent.
**Audit Full:** Audit Explorer scope=todas_govt elevated UI.
**Admin Actions:** Escrow refund (P09) / Compliance manual raise (P10) / Elections phase (P08) / Loan write-off (P07) / Card freeze (P12).

**ACE matrix:** strict per perm — tabs/CTAs hidden missing.

**Privacy M004:** ALL admin actions emit AR-P05 admin_force_action → flag self-raised visible Compliance Self.

### 3.8 V8 — Payroll Batch

**Layout:** R1 company selector. R2 `<DataTable>` employees `[alias, role, last_paid_amount, last_paid_date, NEXT_amount input, include_checkbox]`. R3 summary `[total_to_pay, treasury_remaining, count_selected]` + execute CTA. R4 history past batches + receipt link.

**Bindings:** `bank.business.payroll.preview` (C040) + `bank.business.payroll.execute` (C040) single mutation + `bank.business.payroll.history` cursor.

**Privacy M004 strict:**
- Cols: alias (NOT cid raw) + role + last_paid (historical) + next_amount input.
- **NO column "current balance".** DOM-stripped — never present.
- Aria-label tooltip: "Saldos personales del empleado no son visibles para el empleador."
- Server reject batch with cid not in roster.

**Idempotency:** UUIDv4 per batch — Zustand `usePayrollBatch` — replay-safe.

**SFX:** confirm → `depth_press` + `coin_clink` × employees_count (cap 5 simultaneous) + `vault_close`.

**Audit:** 1 hook per employee paid + 1 batch summary (`business.payroll.executed`).

### 3.9 V9 — Recurring/Subscriptions

**Layout:** tabs Active/Paused/History + `<DataTable>` rules (alias + amount + freq + next_payment + state + actions). "Create rule" → `<Modal>` 3-step inline (recipient → amount+freq → review+confirm).

**Bindings:** `bank.recurring.{list,create,pause,resume,delete}` (C027) + `recurring:executed` NetEvent → toast.

**FSM mirror:** card visual mirrors C-BE-03 (`pending` → `active` → `paused` / `failed_3x` → `terminated`).

**ACE:** P01. Owner only edit/delete.

### 3.10 V10 — Onboarding 3-step skippable (Q9 LOCKED — Q8 RECHAZADO)

**Trigger:** first connect post-create-account → `account:created` NetEvent + `is_first_session: true`.

**Layout:** full-screen `<VistaShell heroLight>` overlay z-splash.

**Steps:**
| # | Title | Visual | CTA | Skip |
|---|---|---|---|---|
| 1 | "Bienvenido a SONAR Bank" | hero radial + emblem rotation gentle | "Empezar" | "Saltar todo" footer |
| 2 | "Tu IBAN" | IBAN_masked spaced + "Cópiame" | "Continuar" | "Saltar este paso" |
| 3 | "Las 3 cosas que puedes hacer" | grid 3 mini cards (Transfer/Track/Save) cascade | "Comenzar" → Overview | "Saltar este paso" |

**Skip:** "Saltar todo" → dismiss → Overview. All skips fire `onboarding.skipped` audit hook (analytics — no judgment).

**State:** Zustand `useOnboarding` + server `bank_onboarding_completed_at` via `bank.onboarding.complete` callback.

**Motion:** transitions slide vertical 480ms slow + premium spring + cards cascade 40ms stagger.

**SFX:** `signal_emerge` mount + `layer_dive` transitions + `panel_open` cards reveal + `depth_press` final.

**ACE:** P01.

---

## 4. Reactividad contract canonical (P3 mandatory)

### 4.1 Lifecycle pattern

```typescript
function FinancialWidget() {
  // (1) Snapshot first via callback (autoritativo DB)
  const { data, refetch } = useQuery({
    queryKey: ['bank.balance.snapshot'],
    queryFn: () => callback('sonar:bank:balance:snapshot'),
    suspense: true,  // React 19 use() integration
    staleTime: 30000,
  })

  // (2) Attach NetEvent listener
  useBankNetEvent('balance:update', (payload) => {
    queryClient.setQueryData(['bank.balance.snapshot'], (prev) => ({
      ...prev, main: payload.main_balance, lastUpdate: payload.occurred_at,
    }))
  })

  // (3) Watchdog 30s defensive
  useWatchdog(30000, refetch, [data?.lastUpdate])

  // (4) Cleanup automatic
  return <BalanceCard balance={data.main} lastUpdate={data.lastUpdate} />
}
```

### 4.2 Map NetEvents → UI handlers

| NetEvent (C-BE-01 §3) | UI surface | TanStack Query invalidate |
|---|---|---|
| `balance:update` | Overview + Accounts | `[balance.snapshot]`, `[account.list]` |
| `savings:update` | savings BalanceCard | `[savings]` |
| `transaction:committed` | Overview rows + Audit | `[transactions.list]` |
| `escrow:stateChanged` | Compliance/Empresas approvals | `[escrow.list]`, `[account.list]` |
| `loan:{approved,rejected,disbursed,installmentDue,writtenOff}` | Loans sub-vista | `[loan.list]`, `[balance.snapshot]` |
| `recurring:executed` | Toast + Recurring V9 | `[recurring.list]`, `[balance.snapshot]` |
| `recurring:failed` | toast warning + status | mismo |
| `subsidy:{granted,revoked,executed}` | Govt Subsidies + Toast | `[subsidy.list]`, `[balance.snapshot]` |
| `tax:bracketsUpdated` | Govt Tax | `[tax.brackets]` |
| `compliance:{flagRaised,flagResolved}` | Compliance Console + counter | `[compliance.flags]` |
| `business:treasuryUpdated` | Empresas BalanceCard | `[business.treasury]` |
| `business:approvalRequested` | toast + Empresas pending | `[business.pendingApprovals]` |
| `elections:phaseChanged` | Govt Elections + toast | `[elections.state]` |
| `cron:tick` (admin) | DevOps obs — NO UI player | n/a |
| `status:transition` (admin) | DevOps tooltip enriquecido (Phase B) | n/a |

### 4.3 Map StateBags → UI hooks (CP1-A 7 keys)

| Key | Hook | Surface | Privacy |
|---|---|---|---|
| `bank.bridges.status` | `useBankStateBag(...)` | `<StatusBadge>` footer | público |
| `bank.business_treasury.<id>` | `useBankStateBag(...)` | `<BalanceCard business>` | aggregate público |
| `bank.compliance.<cid>.public` | `useBankStateBag(...)` | badge counter footer | reduced shape (count + has_active) |
| `bank.tax.brackets` | `useBankStateBag(...)` | Govt Tax + Transfer hints | público |
| `bank.elections.state` | `useBankStateBag(...)` | Govt Elections | público |
| `bank.subsidy.public.<cid>` | `useBankStateBag(...)` | Overview teaser + Govt | own via cid filter |
| `bank.global.health` | `useBankStateBag(...)` | DevOps tooltip Phase B | admin enriquecido |

### 4.4 M004 NetEvent CP1-B owner-only domains

UI receives ONLY server-targeted destinations (filter applied server-side). UI **NEVER assumes** authority — just receives + updates cache.

Domains: `balance` / `savings` / `escrow.<id>` / `loan.<id>` / `recurring.<id>` / `subsidy.<id>` / `compliance.<flag_id>` / `business_treasury.<id>` / `business_approval.<id>`.

### 4.5 Watchdog

```typescript
function useWatchdog(intervalMs, fallback, deps) {
  const lastUpdate = useRef(Date.now())
  useEffect(() => { lastUpdate.current = Date.now() }, deps)
  useEffect(() => {
    const id = setInterval(() => {
      if (Date.now() - lastUpdate.current > intervalMs) fallback()
    }, intervalMs / 2)
    return () => clearInterval(id)
  }, [intervalMs, fallback])
}
```

Cubre: resource restart sonar_bank_app + connect mid-session + cache divergence.

---

## 5. ACE gating UI matrix (12 perms)

| Perm | Descripción | UI surfaces gated |
|---|---|---|
| **P01** `sonar.bank.player` | Baseline auto ALL | Bank app launch |
| **P02** `sonar.bank.audit.self` | Own audit | Audit V4 Mis cuentas |
| **P03** `sonar.bank.empresas.<id>` | Business audit | Audit V4 Mis empresas + Empresas audit panel |
| **P04** `sonar.bank.govt.audit.full` | All audit | Audit V4 Todas govt + Govt Audit Full |
| **P05** `sonar.bank.business.payroll.<id>` | Payroll exec | Empresas Pay payroll CTA + V8 |
| **P06** `sonar.bank.business.approval.<id>` | Business approvals | Empresas pending + actions |
| **P07** `sonar.bank.govt.loan.admin` | Loan admin | Govt Admin Loan write-off |
| **P08** `sonar.bank.govt.elections.admin` | Elections | Govt Admin Elections phase |
| **P09** `sonar.bank.govt.escrow.admin` | Escrow admin | Govt Admin Escrow refund/dispute |
| **P10** `sonar.bank.govt.compliance.admin` | Compliance | Compliance Admin tab + Resolve + Manual raise |
| **P11** `sonar.bank.govt.tax.write` | Tax write | Govt Tax edit + Save |
| **P12** `sonar.bank.govt.physical_card.admin` | Cards | Govt Admin Card freeze |

**Pattern:**

```typescript
function useAcePerm(perm: string): boolean {
  const { data } = useQuery({
    queryKey: ['bank.session.acl'],
    queryFn: () => callback('sonar:bank:session:aclGet'),
    staleTime: 60000,
  })
  return data?.perms?.includes(perm) ?? false
}
```

**NUNCA** trust client-side ACE para security — server enforce always. UI optimistic = better UX (hide non-relevant CTAs).

---

## 6. Privacy boundary M004 zero-tolerance

### 6.1 Inquebrantables UI

1. Empresas + Payroll: NO column "balance personal employee" en DOM. Aggregate stats ONLY.
2. Audit scope strict (Mis cuentas / Mis empresas / Todas govt) — server-enforced + UI tab gated ACE.
3. Compliance Self vs Admin server-filtered + tab gated.
4. Government actions emit AR-P05 admin_force_action self-flag → admin sees own flags Compliance Self.
5. CP1-B NetEvent server-filtered — UI logic NEVER filter manually.

### 6.2 Display masking

- IBAN format display-ready: `'ES12 ****  ****  3245'` from server (NO client manipulation).
- Counterparty alias preference: server resolves names → UI shows `recipient_alias ?? recipient_iban_masked`.
- CID never raw display: UI shows `actor_cid_short` (last 4 chars or alias) — never full CID DOM.
- Compliance reduced shape: `bank.compliance.<cid>.public` exposes `count + has_active` ONLY.

### 6.3 Pre-LOCK self-audit checklist

- [ ] Empresas DOM tree: zero `balance` field per employee row.
- [ ] Payroll DOM tree: zero `current_balance` column.
- [ ] Audit payloads: scope filter server-side only — client cannot request mismatch.
- [ ] Compliance Self payloads: target_cid === self enforced.
- [ ] Receipt PDF: NEVER full IBAN — masked only.

---

## 7. Error states + empty states + loading

### 7.1 Error codes ENUM mapping (C-BE-02 §3.1 → toast/UX)

| Code | UX response | Tone | Retry |
|---|---|---|---|
| `BANK_DISABLED` | Replace vista `<EmptyState>` AlertTriangle + reason kvp | n/a | NO |
| `AUTH_REQUIRED` | Redirect Tablet home + toast | warning | reconnect |
| `AUTH_FORBIDDEN` | Toast "No tienes permisos" | danger | NO |
| `AUTH_ACE_DENIED` | Toast "Permiso denegado: <perm>" | danger | NO |
| `RATE_LIMIT_EXCEEDED` | Toast retry + button disabled `retry_after_ms` | warning | YES auto |
| `IDEMPOTENCY_INFLIGHT` | Inline spinner + toast | info | YES 1s |
| `VALIDATION_FAIL` | Inline form error + toast | danger | NO (fix) |
| `INSUFFICIENT_FUNDS` | Inline amount error + show available | warning | YES (post fund) |
| `INSUFFICIENT_QUORUM` | Modal info "Faltan firmantes" | info | YES |
| `INVALID_TRANSITION` | Toast "Operación no permitida" | danger | NO |
| `INVALID_ACCOUNT_CLASS` | Toast | danger | NO |
| `RESOURCE_NOT_FOUND` | Toast + invalidate cache | warning | reload |
| `RESOURCE_LOCKED` | Toast retry breve | info | YES 1s |
| `LIMIT_EXCEEDED_DAILY` | Toast + show next reset | warning | YES |
| `LIMIT_EXCEEDED_MONTHLY` | mismo | warning | YES |
| `COMPLIANCE_FLAG_BLOCK` | Modal warning + link Compliance Self | danger | NO |
| `EXTERNAL_DEPENDENCY_FAIL` | Toast retry | warning | YES auto 2x |
| `INTERNAL_SERVER_ERROR` | Toast retry | danger | YES manual |
| `UNSUPPORTED_PHASE_A` | Button disabled + tooltip | n/a | NO |

### 7.2 Empty states

| Vista | EmptyState |
|---|---|
| Overview | `icon=Wallet title="Aún sin movimientos" desc="Tu primera transferencia aparecerá aquí." action={Transferir}` |
| Accounts | `icon=Wallet title="Sin cuentas"` |
| Audit | `icon=Search title="Sin resultados" desc="Ajusta filtros."` |
| Compliance Self | `icon=ShieldCheck title="Sin flags activos" desc="Tu cuenta opera con normalidad."` |
| Empresas | `icon=Building2 title="Sin empresas" desc="Únete o crea una empresa."` |
| Payroll history | `icon=Receipt title="Aún sin pagos"` |
| Recurring | `icon=Calendar title="Sin suscripciones activas" action={Crear regla}` |

### 7.3 Loading skeletons canonical

- Overview: 2 hero rect 120px + sparkline rect 200px + 5 row skeletons.
- Accounts: table 8 rows + detail panel hero rect.
- Audit: table 50 row skeletons cursor-paginated.
- Empresas: hero + 4 metric cards + 3 approvals.

Shimmer `--gradient-orange-shimmer` background-position 200% animated 1.6s linear infinite.

---

## 8. i18n strategy 4 locales

### 8.1 Library + structure

- `react-i18next` v15.x + `i18next-browser-languagedetector`.
- JSON per locale: `web-src/src/i18n/<locale>/<namespace>.json` lazy-loaded.
- Namespaces: `common` + `errors` + `vista_*` (10) + `actions` + `time` + `compliance_severity` + `audit_event_types`.
- Fallback: target → es → en. Default ES.
- Detection: `localStorage.sonar_lang` > `navigator.language` > `'es'`.

### 8.2 Locales

| Locale | ISO | Owner |
|---|---|---|
| Spanish | es-ES (`es`) default | Frontend Lead |
| English | en-US (`en`) | Frontend Lead |
| French | fr-FR (`fr`) | Frontend Lead — community Phase B refinement |
| German | de-DE (`de`) | mismo |

### 8.3 Pluralization + currency

- `Intl.NumberFormat(locale, {style:'currency', currency:'EUR', maximumFractionDigits:2})` amounts.
- `Intl.DateTimeFormat(locale, {dateStyle:'medium', timeStyle:'short'})` timestamps.
- ICU pluralization (`{count, plural, one {1 movimiento} other {{count} movimientos}}`).

### 8.4 Translation discipline

- ZERO hard-coded strings en components canonical. Todo via `t('namespace.key')`.
- Pre-LOCK self-audit: grep regex strings literales en `.tsx`.

---

## 9. Reduced motion + a11y WCAG 2.2 AA

### 9.1 prefers-reduced-motion

```typescript
const prefersReducedMotion = useReducedMotion()  // motion v12

<motion.div
  initial={prefersReducedMotion ? {} : { opacity: 0, y: 12 }}
  animate={{ opacity: 1, y: 0 }}
  transition={prefersReducedMotion ? { duration: 0 } : { duration: 0.32, ease: [0.16, 1, 0.3, 1] }}
/>
```

Wrapper `<MotionPreset>` aplica fallback `{ duration: 0 }` automático.

### 9.2 Contrast ratios verified (ADR-017 D8)

| Combo | Ratio | WCAG |
|---|---|---|
| `--text-primary` / `--surface-card` | 15.8:1 | AAA |
| `--text-secondary` / `--surface-card` | 11.3:1 | AAA |
| `--brand-signal-orange` / `--surface-abyss` | 4.7:1 | AA ≥18px |
| `--text-tertiary` / `--surface-card` | 7.2:1 | AAA |

### 9.3 Focus visible

`:focus-visible` ring 2px brand `oklch(0.65 0.22 40 / 0.6)` + 2px gap canvas → composite outer ring 4px (`--shadow-focus-ring`).

### 9.4 Keyboard navigation

- Tab natural per layout left→right, top→bottom.
- Wizard: Enter advances, Esc cancels.
- Modal: trap focus, Esc dismiss, return focus to trigger.
- DataTable: arrow up/down navigate rows, Enter open detail.

### 9.5 Screen reader landmarks

- `<header role="banner">` + `<nav role="navigation">` + `<main role="main">` + `<aside role="complementary">` per VistaShell.
- Live regions `aria-live="polite"` for toast queue + balance updates.
- Heading hierarchy strict h1 (vista title) → h2 (section) → h3 (card title).

---

## 10. Open questions Frontend Lead

1. Component testing strategy — Vitest+RTL recomendado.
2. Vite Dev Page `/dev/components` — misma app gated `import.meta.env.DEV` recomendado.
3. Charts library — Recharts confirmado §2.2 C-08/09.
4. PDF — `@react-pdf/renderer` confirmado §3.3.
5. Receipt scope Phase A — solo Transfer (Statement + tax defer Phase B).
6. Onboarding skip policy — skip individual + skip-all confirmado §3.10.

---

## 11. Cross-references

- C-BE-01..05 v1.0.1 R1 LOCKED `@docs/technical/bank_phase_a/`.
- C-SEC-01/02/03 v0.2 PASS `@docs/technical/08_audit_hooks.md`.
- ADR-016 ✅ + ADR-017 🟡 `@docs/planning/02_decision_log_part2.md`.
- C-FE-02 (sibling) `@docs/design/04_bank_app_design_system.md`.
- C-FE-03 (sibling) `@docs/design/05_bank_app_data_integration.md`.
- Backlog `@progress/FE_BACKEND_REQUESTS.md`.
- Blueprint v1.2 `@docs/design/proposals/03_bank_app_blueprint_v1.md`.
- Identity v3 `@docs/design/IDENTITY.md`.
- SFX canonical `@resources/sonar_tablet/web-src/src/lib/sfx.ts`.

---

**FIN C-FE-01 v0.1 DRAFT** — BANK-FE.0 2026-05-06. Sign-off triple target BANK-FE.LOCK.
