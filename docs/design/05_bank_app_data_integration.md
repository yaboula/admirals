# C-FE-03 — Data Integration + Mock Layer SONAR Bank Phase A v0.1 DRAFT

> **Owner:** Frontend & UX Premium Lead.
> **Status:** 🟡 v0.1 DRAFT BANK-FE.0 2026-05-06.
> **Path canonical:** `docs/design/05_bank_app_data_integration.md` v0.1.
> **Sibling:** C-FE-01 + C-FE-02.
> **Upstream LOCKED:** C-BE-01..05 v1.0.1 R1 + C-SEC-01/02/03 v0.2 PASS.

---

## 1. Filosofía + scope

### 1.1 Mandate

Define la **capa de integración de datos** Bank app — TanStack Query v5 wrappers para 40+1 callbacks C-BE-02 + Zustand stores canonical + NetEvent/StateBag subscription managers + Mock Data Layer fixture-based + reactividad disciplinada + error handling canonical + idempotency strategy client-side.

### 1.2 Principles

- **I1 — Snapshot-first.** Mount = callback snapshot autoritativo DB. NO trust client cache stale.
- **I2 — Reactive update via NetEvent/StateBag.** UI updates cache via NetEvent — never polling.
- **I3 — Watchdog defensive 30s.** Re-snapshot if no NetEvent received (cache divergence safety).
- **I4 — Idempotency client-side mandatory.** UUIDv4 per mutation per wizard mount. Replay-safe.
- **I5 — Mock Data Layer 1:1 contract shapes.** Switch mock↔real = single Vite env var. ZERO contract drift.
- **I6 — Privacy boundary M004 enforcement client-side.** UI logic NEVER manually filter — server filters all destinations.
- **I7 — Error handling canonical 20 ENUM codes.** Toast/UX response per code mapped (C-FE-01 §7.1).

### 1.3 Scope IN/OUT

**IN:** TanStack Query wrappers 40+1 callbacks + Zustand stores (5 canonical) + NetEvent/StateBag managers + Mock Data Layer fixtures + idempotency client + error mapping + watchdog hook + Bootstrap snapshot composite hook.

**OUT:** Server-Sent Events (SSE) — NO use case Phase A. Real-time chat — NO scope Bank. Background sync (offline-first) — NO scope FiveM client always-online. Service Worker cache — Phase B candidate.

---

## 2. Stack canonical (Data layer)

| Layer | Package | Versión | Razón |
|---|---|---|---|
| Server state | `@tanstack/react-query` | v5.x | Suspense + use() + React 19 concurrent-safe |
| Server state devtools | `@tanstack/react-query-devtools` | v5.x | Dev-only |
| Client state | `zustand` | v5.x | 1KB + concurrent-safe |
| Validation | `zod` | v4.x | Shared client/server schemas |
| Forms | `react-hook-form` | v7.x | Uncontrolled + Zod resolver |
| Idempotency | Web Crypto API `crypto.randomUUID()` | native | UUIDv4 |
| HTTP/Fetch (mock mode) | `fetch` native + `msw` (Mock Service Worker) optional | v2.x | Mock layer toggle |

---

## 3. Wrappers TanStack Query v5

### 3.1 Pattern canonical `useBankCallback`

```typescript
// src/lib/bank-query.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

const callback = async <TReq, TRes>(eventName: string, payload?: TReq): Promise<TRes> => {
  if (import.meta.env.VITE_MOCK_MODE === 'true') {
    return mockCallback<TReq, TRes>(eventName, payload)
  }
  // FiveM NUI bridge — wraps `fetch` to GetParentResourceName()
  const response = await fetch(`https://${GetParentResourceName()}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload ?? {}),
  })
  if (!response.ok) {
    const errorBody = await response.json().catch(() => ({ error: { code: 'INTERNAL_SERVER_ERROR', message: response.statusText } }))
    throw new BankError(errorBody.error)
  }
  const json = await response.json()
  if (json.status === 'error') throw new BankError(json.error)
  return json.data
}

// Read hook
export function useBankCallback<TRes>(eventName: string, payload?: any, options?: any) {
  return useQuery({
    queryKey: [eventName, payload],
    queryFn: () => callback<any, TRes>(eventName, payload),
    staleTime: 30000,  // default 30s freshness
    ...options,
  })
}

// Mutation hook
export function useBankMutation<TReq, TRes>(eventName: string, options?: any) {
  return useMutation({
    mutationFn: (payload: TReq) => callback<TReq, TRes>(eventName, payload),
    ...options,
  })
}
```

### 3.2 Map 40+1 callbacks C-BE-02 → hooks canonical

**Account & balance domain:**
| Callback ID | Event name | Wrapper hook | Auth | Idempotent |
|---|---|---|---|---|
| C001b | `sonar:bank:balance:snapshot` | `useBankBalanceSnapshot()` | OWNER | NO (read) |
| C002 | `sonar:bank:savings:get` | `useBankSavings()` | OWNER | NO |
| C003 | `sonar:bank:account:create` | `useBankCreateAccount()` mutation | OWNER + ACE | YES |
| C004 | `sonar:bank:account:close` | `useBankCloseAccount()` mutation | OWNER | YES |
| C005 | `sonar:bank:account:list` | `useBankAccountList()` | OWNER | NO |
| C006 | `sonar:bank:account:detail` | `useBankAccountDetail({ id })` | OWNER | NO |

**Transfer domain:**
| C-BE-02 | Hook | Auth | Idempotent |
|---|---|---|---|
| C001 | `useBankTransferExecute()` mutation | OWNER | YES |
| C007 | `useBankTransferRecent()` (REQ-FE-002 mock) | OWNER | NO |
| C008 | `useBankTransactions({ account_id, cursor, limit })` | OWNER | NO |
| C009 | `useBankTransactionDetail({ id })` | OWNER | NO |

**Escrow domain:**
| C-BE-02 | Hook | Auth | Idempotent |
|---|---|---|---|
| C010 | `useBankEscrowCreate()` mutation | OWNER | YES |
| C011 | `useBankEscrowList()` | OWNER | NO |
| C012 | `useBankEscrowDetail({ id })` | OWNER | NO |
| C013 | `useBankEscrowApprove({ id })` mutation | OWNER + participant | YES |
| C014 | `useBankEscrowCancel({ id })` mutation | OWNER | YES |
| C015 | `useBankEscrowDispute({ id, reason })` mutation | OWNER | YES |

**Loan domain:**
| C-BE-02 | Hook | Auth | Idempotent |
|---|---|---|---|
| C016 | `useBankLoanApply()` mutation | OWNER | YES |
| C017 | `useBankLoanList()` | OWNER | NO |
| C018 | `useBankLoanDetail({ id })` | OWNER | NO |
| C019 | `useBankLoanInstallments({ loan_id })` | OWNER | NO |
| C020 | `useBankLoanPayInstallment({ loan_id, installment_id })` mutation | OWNER | YES |
| C021 | `useBankLoanWriteOff({ loan_id })` mutation | ACE P07 | YES |

**Stocks domain (Phase A read-only Q16):**
| C-BE-02 | Hook | Auth |
|---|---|---|
| C022 | `useBankStocksList()` | OWNER |
| C023 | `useBankStockDetail({ ticker })` | OWNER |
| C024 | `useBankStockHistory({ ticker, range })` | OWNER |
| C025 | `useBankPortfolio()` | OWNER |
| C026 | `useBankPortfolioPerformance()` | OWNER |

**Recurring domain:**
| C-BE-02 | Hook | Auth | Idempotent |
|---|---|---|---|
| C027 | `useBankRecurringList({ state })` | OWNER | NO |
| C028 | `useBankRecurringCreate()` mutation | OWNER | YES |
| C029 | `useBankRecurringPause({ id })` mutation | OWNER | YES |
| C030 | `useBankRecurringResume({ id })` mutation | OWNER | YES |
| C031 | `useBankRecurringDelete({ id })` mutation | OWNER | YES |
| C032 | `useBankRecurringDetail({ id })` | OWNER | NO |

**Subsidies + tax + audit + compliance:**
| C-BE-02 | Hook | Auth | Idempotent |
|---|---|---|---|
| C033 | `useBankSubsidyList()` | OWNER (own) / ACE P04 (all govt) | NO |
| C034 | `useBankSubsidyGrant()` mutation | ACE P04 | YES |
| C035 | `useBankAuditQuery({ scope, filters, cursor, limit })` | scope-dependent (P02/P03/P04) | NO |
| C036 | `useBankComplianceListFlags({ scope })` | OWNER (self) / ACE P10 (admin) | NO |
| C037 | `useBankComplianceRaiseFlag()` mutation | ACE P10+P11 | YES |
| C038 | `useBankComplianceResolveFlag()` mutation | ACE P10 | YES |

**Business domain:**
| C-BE-02 | Hook | Auth | Idempotent |
|---|---|---|---|
| C039 | `useBankBusinessTreasury({ company_id })` | role membership | NO |
| C040 | `useBankPayrollExecute()` mutation | ACE P05 | YES |
| C040.preview | `useBankPayrollPreview({ company_id })` | role | NO |

### 3.3 Composite hooks (multi-callback)

```typescript
// useBootstrapSnapshot — REQ-FE-001 mock placeholder (real Round 2 amendment target)
export function useBootstrapSnapshot() {
  return useQueries({
    queries: [
      { queryKey: ['balance.snapshot'], queryFn: () => callback('sonar:bank:balance:snapshot') },
      { queryKey: ['account.list'], queryFn: () => callback('sonar:bank:account:list') },
      { queryKey: ['stocks.portfolio'], queryFn: () => callback('sonar:bank:stocks:portfolio') },
      { queryKey: ['loan.list'], queryFn: () => callback('sonar:bank:loan:list') },
      { queryKey: ['recurring.list'], queryFn: () => callback('sonar:bank:recurring:list') },
      { queryKey: ['business.memberships'], queryFn: () => callback('sonar:bank:business:memberships') },
      { queryKey: ['compliance.flags.self'], queryFn: () => callback('sonar:bank:compliance:listFlags', { scope: 'self' }) },
    ],
    combine: (results) => ({
      data: {
        balance: results[0].data,
        accounts: results[1].data,
        portfolio: results[2].data,
        loans: results[3].data,
        recurring: results[4].data,
        memberships: results[5].data,
        compliance: results[6].data,
      },
      isLoading: results.some((r) => r.isLoading),
      isError: results.some((r) => r.isError),
    }),
  })
}
```

Real callback `sonar:bank:bootstrap:snapshot` (REQ-FE-001) replaces this in Round 2 amendment — single round-trip < 80ms p99 vs 7 parallel.

---

## 4. Zustand stores canonical (5)

### 4.1 `useBankSession`

```typescript
import { create } from 'zustand'

interface BankSessionState {
  citizenId: string | null
  ibanMasked: string | null
  isFirstSession: boolean
  acePerms: string[]  // P01-P12 granted
  onboardingCompletedAt: number | null

  setSession: (s: Partial<BankSessionState>) => void
  clearSession: () => void
}

export const useBankSession = create<BankSessionState>((set) => ({
  citizenId: null,
  ibanMasked: null,
  isFirstSession: false,
  acePerms: [],
  onboardingCompletedAt: null,
  setSession: (s) => set(s),
  clearSession: () => set({
    citizenId: null, ibanMasked: null, isFirstSession: false, acePerms: [], onboardingCompletedAt: null,
  }),
}))
```

### 4.2 `useBankStatus`

```typescript
interface BankStatusState {
  bridgesStatus: 'native_full' | 'lite_mode_active' | 'compromised_load_order' | 'framework_missing'
  reasonKvp: Record<string, string>
  lastTransitionAt: number | null

  setStatus: (s: Partial<BankStatusState>) => void
}

export const useBankStatus = create<BankStatusState>((set) => ({
  bridgesStatus: 'native_full',
  reasonKvp: {},
  lastTransitionAt: null,
  setStatus: (s) => set(s),
}))
```

### 4.3 `useToastQueue`

```typescript
interface Toast {
  id: string
  tone: 'success' | 'warning' | 'danger' | 'info'
  title: string
  description?: string
  duration?: number  // ms, default 4000
  action?: { label: string; onClick: () => void }
}

interface ToastQueueState {
  toasts: Toast[]
  push: (toast: Omit<Toast, 'id'>) => void
  dismiss: (id: string) => void
  clear: () => void
}

export const useToastQueue = create<ToastQueueState>((set) => ({
  toasts: [],
  push: (toast) => set((s) => ({
    toasts: [...s.toasts, { ...toast, id: crypto.randomUUID() }],
  })),
  dismiss: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),
  clear: () => set({ toasts: [] }),
}))

// Helper canonical
export const toast = {
  success: (title: string, description?: string) => useToastQueue.getState().push({ tone: 'success', title, description }),
  warning: (title: string, description?: string) => useToastQueue.getState().push({ tone: 'warning', title, description }),
  danger: (title: string, description?: string) => useToastQueue.getState().push({ tone: 'danger', title, description }),
  info: (title: string, description?: string) => useToastQueue.getState().push({ tone: 'info', title, description }),
}
```

### 4.4 `useOnboarding`

```typescript
interface OnboardingState {
  step: 1 | 2 | 3
  completed: boolean
  skipped: boolean

  next: () => void
  skipStep: () => void
  skipAll: () => void
  reset: () => void
}

export const useOnboarding = create<OnboardingState>((set) => ({
  step: 1,
  completed: false,
  skipped: false,
  next: () => set((s) => ({
    step: (s.step < 3 ? (s.step + 1) : 3) as 1 | 2 | 3,
    completed: s.step === 3,
  })),
  skipStep: () => set((s) => ({ step: (s.step < 3 ? (s.step + 1) : 3) as 1 | 2 | 3 })),
  skipAll: () => set({ skipped: true, completed: true }),
  reset: () => set({ step: 1, completed: false, skipped: false }),
}))
```

### 4.5 `useTransferWizard`

```typescript
interface TransferWizardState {
  step: 'amount' | 'recipient' | 'review' | 'confirm'
  expressMode: boolean
  idempotencyKey: string | null
  amount: number | null
  memo: string
  recipientIban: string | null
  recipientAlias: string | null
  correlationId: string | null

  init: () => void
  setStep: (step: TransferWizardState['step']) => void
  setExpressMode: (v: boolean) => void
  setAmount: (amount: number, memo?: string) => void
  setRecipient: (iban: string, alias?: string) => void
  reset: () => void
}

export const useTransferWizard = create<TransferWizardState>((set) => ({
  step: 'amount',
  expressMode: false,
  idempotencyKey: null,
  amount: null,
  memo: '',
  recipientIban: null,
  recipientAlias: null,
  correlationId: null,
  init: () => set({
    step: 'amount',
    expressMode: false,
    idempotencyKey: crypto.randomUUID(),
    correlationId: crypto.randomUUID(),
    amount: null,
    memo: '',
    recipientIban: null,
    recipientAlias: null,
  }),
  setStep: (step) => set({ step }),
  setExpressMode: (v) => set({ expressMode: v }),
  setAmount: (amount, memo = '') => set({ amount, memo }),
  setRecipient: (iban, alias) => set({ recipientIban: iban, recipientAlias: alias }),
  reset: () => set({
    step: 'amount', expressMode: false, idempotencyKey: null, correlationId: null,
    amount: null, memo: '', recipientIban: null, recipientAlias: null,
  }),
}))
```

---

## 5. NetEvent subscription manager

### 5.1 Pattern `useBankNetEvent`

```typescript
// src/lib/bank-events.ts
type NetEventHandler<T = any> = (payload: T) => void
type NetEventName = string  // e.g. 'balance:update', 'transaction:committed'

const eventBus = new Map<NetEventName, Set<NetEventHandler>>()

// Bridge: FiveM NUI dispatches via window.addEventListener('message')
if (typeof window !== 'undefined' && import.meta.env.VITE_MOCK_MODE !== 'true') {
  window.addEventListener('message', (event) => {
    const { type, payload } = event.data ?? {}
    if (typeof type !== 'string' || !type.startsWith('sonar:bank:')) return
    const eventName = type.replace('sonar:bank:', '')  // 'balance:update'
    const handlers = eventBus.get(eventName)
    if (handlers) handlers.forEach((h) => h(payload))
  })
}

export function useBankNetEvent<T = any>(eventName: NetEventName, handler: NetEventHandler<T>) {
  useEffect(() => {
    if (!eventBus.has(eventName)) eventBus.set(eventName, new Set())
    const handlers = eventBus.get(eventName)!
    handlers.add(handler as NetEventHandler)
    return () => {
      handlers.delete(handler as NetEventHandler)
      if (handlers.size === 0) eventBus.delete(eventName)
    }
  }, [eventName, handler])
}
```

### 5.2 Mock mode bus injection

```typescript
// src/lib/mock-bus.ts (DEV only)
if (import.meta.env.VITE_MOCK_MODE === 'true') {
  // Expose dispatcher window to dev tools
  ;(window as any).__mockBankEvent = (eventName: string, payload: any) => {
    window.dispatchEvent(new MessageEvent('message', {
      data: { type: `sonar:bank:${eventName}`, payload },
    }))
  }
}

// Usage from dev console:
// __mockBankEvent('balance:update', { main_balance: 1234.56, occurred_at: Date.now() })
```

---

## 6. StateBag subscription manager

### 6.1 Pattern `useBankStateBag`

```typescript
// src/lib/bank-statebags.ts
type StateBagKey = string  // 'bank.bridges.status', 'bank.business_treasury.<id>'
type StateBagListener<T = any> = (value: T) => void

const stateBagCache = new Map<StateBagKey, any>()
const stateBagListeners = new Map<StateBagKey, Set<StateBagListener>>()

if (typeof window !== 'undefined' && import.meta.env.VITE_MOCK_MODE !== 'true') {
  window.addEventListener('message', (event) => {
    const { type, key, value } = event.data ?? {}
    if (type !== 'sonar:bank:statebag:update') return
    stateBagCache.set(key, value)
    const listeners = stateBagListeners.get(key)
    if (listeners) listeners.forEach((l) => l(value))
  })
}

export function useBankStateBag<T = any>(key: StateBagKey): T | null {
  const [value, setValue] = useState<T | null>(stateBagCache.get(key) ?? null)
  useEffect(() => {
    if (!stateBagListeners.has(key)) stateBagListeners.set(key, new Set())
    const listeners = stateBagListeners.get(key)!
    listeners.add(setValue as StateBagListener)
    // Initial fetch via callback if not in cache
    if (!stateBagCache.has(key)) {
      callback<{ key: string }, { value: any }>('sonar:bank:statebag:get', { key })
        .then((r) => {
          stateBagCache.set(key, r.value)
          setValue(r.value)
        })
        .catch(() => { /* swallow - watchdog will retry */ })
    }
    return () => {
      listeners.delete(setValue as StateBagListener)
      if (listeners.size === 0) stateBagListeners.delete(key)
    }
  }, [key])
  return value
}
```

---

## 7. Mock Data Layer v0.1

### 7.1 Activation

- Vite env var `VITE_MOCK_MODE=true` toggles entire data layer to mock fixtures.
- Single switch — production builds default `false`.
- Mock fixtures live `src/mocks/fixtures/*.ts` deterministic seed.

### 7.2 Fixture shapes (1:1 contract)

```typescript
// src/mocks/fixtures/balance.ts
export const balanceSnapshotFixture = {
  status: 'ok',
  data: {
    main: 12_345.67,
    savings: 4_500.00,
    currency: 'EUR',
    last_update: Date.now() - 1000 * 60 * 15,
  },
  correlation_id: 'mock-balance-' + crypto.randomUUID(),
}

// src/mocks/fixtures/transactions.ts
export const transactionsListFixture = {
  status: 'ok',
  data: {
    items: [
      {
        id: 'tx-001',
        direction: 'out',
        amount: -45.50,
        currency: 'EUR',
        counterparty_alias: 'Spotify',
        counterparty_iban_masked: 'ES89 ****  ****  9876',
        category: 'subscription',
        memo: 'Monthly subscription',
        occurred_at: Date.now() - 1000 * 60 * 60 * 2,
        correlation_id: 'tx-corr-001',
        status: 'committed',
      },
      // ... 49 more
    ],
    cursor_next: null,
    has_more: false,
  },
}

// src/mocks/fixtures/recent_recipients.ts (REQ-FE-002 mock)
export const recentRecipientsFixture = {
  status: 'ok',
  data: {
    recipients: [
      { iban_masked: 'ES12 ****  ****  3245', recipient_alias: 'Carlos Vela', last_used_at: Date.now() - 1000 * 60 * 60 * 24 * 3, count_30d: 5, last_amount: 100 },
      { iban_masked: 'ES98 ****  ****  4321', recipient_alias: 'Restaurante La Paloma', last_used_at: Date.now() - 1000 * 60 * 60 * 24 * 7, count_30d: 3, last_amount: 28.50 },
      // ... 8 more
    ],
  },
}
```

### 7.3 Mock dispatcher

```typescript
// src/mocks/index.ts
import { balanceSnapshotFixture } from './fixtures/balance'
import { transactionsListFixture } from './fixtures/transactions'
// ...

const fixtureMap: Record<string, any> = {
  'sonar:bank:balance:snapshot': balanceSnapshotFixture,
  'sonar:bank:transactions:list': transactionsListFixture,
  'sonar:bank:transfer:execute': (payload: any) => ({
    status: 'ok',
    data: {
      transaction_id: 'tx-mock-' + crypto.randomUUID(),
      correlation_id: payload.correlation_id ?? crypto.randomUUID(),
      idempotency_key: payload.idempotency_key,
      committed_at: Date.now(),
    },
  }),
  // ... 38 more
}

export async function mockCallback<TReq, TRes>(eventName: string, payload?: TReq): Promise<TRes> {
  // Simulate network latency 50-150ms deterministic
  await new Promise((resolve) => setTimeout(resolve, 50 + Math.random() * 100))

  const fixture = fixtureMap[eventName]
  if (!fixture) {
    throw new BankError({ code: 'RESOURCE_NOT_FOUND', message: `Mock fixture missing: ${eventName}` })
  }

  if (typeof fixture === 'function') return fixture(payload).data
  if (fixture.status === 'error') throw new BankError(fixture.error)
  return fixture.data
}
```

### 7.4 Mock NetEvent dispatcher

```typescript
// Dispatcher dev tool exposed window.__mockBankEvent — see §5.2.
// Plus auto-dispatch on mutation success (e.g. transfer:execute → balance:update auto)
fixtureMap['sonar:bank:transfer:execute'] = (payload: any) => {
  // Simulate side effect
  setTimeout(() => {
    ;(window as any).__mockBankEvent?.('balance:update', {
      main_balance: 12_345.67 - payload.amount,
      occurred_at: Date.now(),
      correlation_id: payload.correlation_id,
    })
    ;(window as any).__mockBankEvent?.('transaction:committed', {
      transaction_id: 'tx-mock-' + crypto.randomUUID(),
      direction: 'out',
      amount: -payload.amount,
      counterparty_iban_masked: payload.recipient_iban,
      counterparty_alias: payload.recipient_alias ?? null,
      memo: payload.memo,
      occurred_at: Date.now(),
      correlation_id: payload.correlation_id,
    })
  }, 100)
  return { status: 'ok', data: { transaction_id: 'tx-mock-' + crypto.randomUUID() } }
}
```

### 7.5 Mock StateBag dispatcher

```typescript
// src/mocks/statebags.ts (DEV only)
export const initialStateBags: Record<string, any> = {
  'bank.bridges.status': 'native_full',
  'bank.business_treasury.empresa-001': { balance: 8_750.50, last_update: Date.now() },
  'bank.compliance.cid-self.public': { count: 0, has_active: false },
  'bank.tax.brackets': [
    { min_amount: 0, max_amount: 1000, percentage: 0 },
    { min_amount: 1000, max_amount: 10000, percentage: 12 },
    { min_amount: 10000, max_amount: null, percentage: 22 },
  ],
  'bank.elections.state': { phase: 'inactive', next_phase_at: null },
  'bank.subsidy.public.cid-self': { count_active: 0 },
  'bank.global.health': { all_systems_operational: true, watchdog_metrics: { samples: 1000, anomalies: 0 } },
}

// On boot in mock mode, hydrate stateBagCache + dispatch initial messages
if (import.meta.env.VITE_MOCK_MODE === 'true') {
  Object.entries(initialStateBags).forEach(([key, value]) => {
    window.dispatchEvent(new MessageEvent('message', {
      data: { type: 'sonar:bank:statebag:update', key, value },
    }))
  })
}
```

---

## 8. Idempotency strategy client-side (I4)

### 8.1 Pattern canonical

- **Generation:** `crypto.randomUUID()` (Web Crypto API — Chromium 92+ → CEF FiveM compatible).
- **Lifecycle:** generated once per wizard mount or mutation flow. Stored Zustand store.
- **Replay:** server replays cached result per C-BE-02 §5.3 if same idempotency_key received within window.
- **Cleared:** on success OR explicit cancel. New mutation flow → new key.

### 8.2 Mutation hook idempotent canonical

```typescript
export function useTransferExecute() {
  const wizard = useTransferWizard()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (payload: { amount: number; recipient_iban: string; memo?: string }) => {
      if (!wizard.idempotencyKey || !wizard.correlationId) {
        throw new Error('Wizard not initialized — call wizard.init() first')
      }
      return callback('sonar:bank:transfer:execute', {
        ...payload,
        idempotency_key: wizard.idempotencyKey,
        correlation_id: wizard.correlationId,
      })
    },
    onSuccess: (result) => {
      // Invalidate balance + transactions cache
      queryClient.invalidateQueries({ queryKey: ['sonar:bank:balance:snapshot'] })
      queryClient.invalidateQueries({ queryKey: ['sonar:bank:transactions:list'] })
      // Reset wizard idempotency for next transfer
      wizard.reset()
    },
    onError: (error: BankError) => {
      if (error.code === 'IDEMPOTENCY_INFLIGHT') {
        // Server processing — wait + retry once
        setTimeout(() => /* retry mutation */, 1000)
      }
    },
  })
}
```

---

## 9. Error handling canonical (I7)

### 9.1 BankError class

```typescript
// src/lib/bank-error.ts
export interface BankErrorPayload {
  code: ErrorCodeEnum
  message: string
  message_key?: string  // i18n optional (REQ-FE-004 future)
  retry_after_ms?: number
  retryable?: boolean
  details?: Record<string, any>
}

export type ErrorCodeEnum =
  | 'BANK_DISABLED' | 'AUTH_REQUIRED' | 'AUTH_FORBIDDEN' | 'AUTH_ACE_DENIED'
  | 'RATE_LIMIT_EXCEEDED' | 'IDEMPOTENCY_INFLIGHT' | 'VALIDATION_FAIL'
  | 'INSUFFICIENT_FUNDS' | 'INSUFFICIENT_QUORUM' | 'INVALID_TRANSITION' | 'INVALID_ACCOUNT_CLASS'
  | 'RESOURCE_NOT_FOUND' | 'RESOURCE_LOCKED'
  | 'LIMIT_EXCEEDED_DAILY' | 'LIMIT_EXCEEDED_MONTHLY'
  | 'COMPLIANCE_FLAG_BLOCK' | 'EXTERNAL_DEPENDENCY_FAIL' | 'INTERNAL_SERVER_ERROR' | 'UNSUPPORTED_PHASE_A'

export class BankError extends Error {
  code: ErrorCodeEnum
  retry_after_ms?: number
  retryable: boolean
  details: Record<string, any>

  constructor(payload: BankErrorPayload) {
    super(payload.message)
    this.code = payload.code
    this.retry_after_ms = payload.retry_after_ms
    this.retryable = payload.retryable ?? false
    this.details = payload.details ?? {}
  }
}
```

### 9.2 Global error handler

```typescript
// src/lib/error-handler.ts
import { toast } from '@/stores/toast'
import i18n from '@/i18n'

export function handleBankError(error: BankError, context?: { vista?: string; action?: string }) {
  const tFn = i18n.t.bind(i18n)
  const localizedMessage = tFn(`errors.${error.code.toLowerCase()}`, error.message)

  switch (error.code) {
    case 'BANK_DISABLED':
      // Replace vista — not toast
      // Handled at vista shell level via React Error Boundary
      break
    case 'AUTH_REQUIRED':
      toast.warning(localizedMessage, tFn('errors.actions.reconnect'))
      // Trigger Tablet home redirect
      break
    case 'AUTH_FORBIDDEN':
    case 'AUTH_ACE_DENIED':
      toast.danger(localizedMessage)
      break
    case 'RATE_LIMIT_EXCEEDED':
      const retryIn = Math.ceil((error.retry_after_ms ?? 1000) / 1000)
      toast.warning(localizedMessage, tFn('errors.retry_in', { seconds: retryIn }))
      break
    case 'IDEMPOTENCY_INFLIGHT':
      toast.info(tFn('errors.processing'))
      break
    case 'VALIDATION_FAIL':
      toast.danger(localizedMessage)
      // Inline form errors handled via react-hook-form
      break
    case 'INSUFFICIENT_FUNDS':
      toast.warning(localizedMessage, tFn('errors.insufficient_funds_hint'))
      break
    case 'INSUFFICIENT_QUORUM':
      // Modal info — not toast
      break
    case 'INVALID_TRANSITION':
    case 'INVALID_ACCOUNT_CLASS':
      toast.danger(localizedMessage)
      break
    case 'RESOURCE_NOT_FOUND':
      toast.warning(localizedMessage)
      // Invalidate cache via queryClient
      break
    case 'RESOURCE_LOCKED':
      toast.info(localizedMessage)
      break
    case 'LIMIT_EXCEEDED_DAILY':
    case 'LIMIT_EXCEEDED_MONTHLY':
      toast.warning(localizedMessage, tFn('errors.next_reset_at', { date: error.details.next_reset_at }))
      break
    case 'COMPLIANCE_FLAG_BLOCK':
      // Modal warning + link to Compliance Self
      break
    case 'EXTERNAL_DEPENDENCY_FAIL':
      toast.warning(localizedMessage)
      break
    case 'INTERNAL_SERVER_ERROR':
      toast.danger(localizedMessage)
      console.error('[BankError]', error, context)
      break
    case 'UNSUPPORTED_PHASE_A':
      // Button disabled + tooltip — handled in component
      break
    default:
      toast.danger(tFn('errors.generic'))
  }
}
```

### 9.3 React Error Boundary canonical

```tsx
// src/components/error-boundary.tsx
import { Component, ReactNode } from 'react'

export class BankErrorBoundary extends Component<{ children: ReactNode }, { error: BankError | null }> {
  state = { error: null }

  static getDerivedStateFromError(error: any) {
    if (error instanceof BankError) return { error }
    return { error: new BankError({ code: 'INTERNAL_SERVER_ERROR', message: error?.message ?? 'Unknown error' }) }
  }

  componentDidCatch(error: any, info: any) {
    console.error('[BankErrorBoundary]', error, info)
  }

  render() {
    if (this.state.error?.code === 'BANK_DISABLED') {
      return <BankDisabledFullScreen reason={this.state.error.details} />
    }
    if (this.state.error) {
      return <ErrorFullScreen error={this.state.error} onRetry={() => this.setState({ error: null })} />
    }
    return this.props.children
  }
}
```

---

## 10. Watchdog defensive (I3)

### 10.1 Hook canonical

```typescript
// src/hooks/useWatchdog.ts
export function useWatchdog(intervalMs: number, fallback: () => void, deps: any[]) {
  const lastUpdateRef = useRef(Date.now())

  useEffect(() => {
    lastUpdateRef.current = Date.now()
  }, deps)

  useEffect(() => {
    const id = setInterval(() => {
      const elapsed = Date.now() - lastUpdateRef.current
      if (elapsed > intervalMs) {
        fallback()
        lastUpdateRef.current = Date.now()
      }
    }, intervalMs / 2)
    return () => clearInterval(id)
  }, [intervalMs, fallback])
}
```

### 10.2 Use cases mandatory

- BalanceCard: `useWatchdog(30000, refetch, [data?.lastUpdate])`.
- StatusBadge bridges: `useWatchdog(60000, refetch, [bridgesStatus])`.
- TransactionsList: `useWatchdog(30000, refetch, [data?.[0]?.occurred_at])`.
- ComplianceFlagsList: `useWatchdog(60000, refetch, [data?.length])`.

---

## 11. React 19 patterns + pitfalls

### 11.1 Use cases recomendados

- **`use(promise)` Suspense:** read-only data fetch → use TanStack Query `suspense: true` option.
- **Actions API (form mutations):** prefer for forms → `useActionState()` integration.
- **`useTransition()` for non-urgent updates:** filter changes + tab switches.
- **`useDeferredValue()` for expensive renders:** DataTable virtualized rows + chart re-renders.

### 11.2 Pitfalls evitar

- ❌ **NO call `useState` setter inside render** — React 19 stricter than 18 → infinite loop crash.
- ❌ **NO synchronous fetch in component body** — always use TanStack Query / `use()`.
- ❌ **NO `useMemo` over-optimization** — React 19 compiler (RSC) auto-memoizes — manual memo often counterproductive.
- ❌ **NO unstable refs in effects deps** — use `useCallback` o stable closures.

### 11.3 Concurrent rendering safety

- All Zustand stores v5 are concurrent-safe by default.
- TanStack Query v5 + Suspense integration tested React 19 compat.
- Motion v12 supports React 19 `useTransition` for layout animations.

---

## 12. Privacy boundary M004 client enforcement

### 12.1 Inquebrantables data layer

1. **CP1-A StateBag scope público strict:** UI receives ONLY non-sensitive data — server never publishes sensitive to public StateBags.
2. **CP1-B NetEvent owner-only:** server filters destinations per `target_player_id`. UI receives = authoritative — NO client filter logic.
3. **Audit query scope server-side:** UI passes `scope` parameter, server validates against ACE perm. Bypass impossible client-side.
4. **Compliance scope server-side:** `bank.compliance.listFlags { scope: 'self'|'admin' }` — server enforces target_cid match for self / ACE P10 for admin.
5. **Business aggregate stats only:** `bank.business.employees.aggregate` returns counts + totals, NO individual balances. UI cannot request individual.

### 12.2 No-leak validation pre-LOCK

- [ ] grep `useBankCallback` calls for sensitive payload exposure.
- [ ] grep `useBankStateBag` calls for over-broad scope.
- [ ] DOM tree inspection: zero leak per Vista 6 + Vista 8 (Empresas + Payroll).
- [ ] React DevTools props inspection: balance fields scoped owner only.

---

## 13. Cross-references

- **Sibling contracts:** C-FE-01 + C-FE-02.
- **Upstream contracts:** C-BE-02 v1.0.1 R1 LOCKED `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` (40+1 callbacks).
- **Upstream events:** C-BE-01 v1.0.1 R1 LOCKED (NetEvents + StateBags).
- **Backlog:** `@progress/FE_BACKEND_REQUESTS.md` (REQ-FE-001 bootstrap + REQ-FE-002 recipients + REQ-FE-003 ack + REQ-FE-004 i18n + REQ-FE-005 status).
- **TanStack Query v5:** `https://tanstack.com/query/v5/docs/react/overview`.
- **Zustand v5:** `https://github.com/pmndrs/zustand`.
- **Zod v4:** `https://zod.dev`.
- **React Hook Form v7:** `https://react-hook-form.com`.

---

**FIN C-FE-03 v0.1 DRAFT** — BANK-FE.0 2026-05-06. Sign-off triple target BANK-FE.LOCK.
