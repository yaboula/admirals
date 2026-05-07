import { registerMockHandler } from '@/lib/nui'
import {
  buildMockBootstrap,
  buildMockClientConfig,
  buildMockRecentRecipientsResponse,
  simulateLatency,
} from './seed'
import type { BootstrapSnapshot, ClientConfigSnapshot, RecentRecipientsResponse } from '@/data/contracts'
import type { BankStateBagKey } from '@/lib/bankStateBags'

let installed = false

export function installMockHandlers(): void {
  if (installed) return
  installed = true

  registerMockHandler<BootstrapSnapshot>('sonar:bank:bootstrap:snapshot', async () => {
    await simulateLatency(140, 360)
    return buildMockBootstrap()
  })

  registerMockHandler<RecentRecipientsResponse>('sonar:bank:transfer:recentRecipients', async () => {
    await simulateLatency(60, 180)
    return buildMockRecentRecipientsResponse()
  })

  registerMockHandler<ClientConfigSnapshot>('sonar:bank:nui:getConfig', async () => {
    await simulateLatency(40, 120)
    return buildMockClientConfig()
  })

  registerMockHandler<{ key: BankStateBagKey; value: unknown; fetched_at_ms: number }>('sonar:bank:statebag:get', async (payload) => {
    await simulateLatency(30, 90)
    return {
      key: payload.key as BankStateBagKey,
      value: resolveMockStateBag(payload.key as BankStateBagKey),
      fetched_at_ms: Date.now(),
    }
  })

  console.info('[mock] handlers installed (4 endpoints) — VITE_MOCK_MODE=true')
}

function resolveMockStateBag(key: BankStateBagKey): unknown {
  if (key === 'bank.bridges.status') return 'native_full'
  if (key === 'bank.tax.brackets') return []
  if (key === 'bank.elections.state') return { phase: 'inactive', next_phase_at: null }
  if (key === 'bank.global.health') return { all_systems_operational: true }
  if (key.startsWith('bank.compliance.')) return { count: 0, has_active: false }
  if (key.startsWith('bank.subsidy.public.')) return { count_active: 0 }
  if (key.startsWith('bank.business_treasury.')) return { balance_minor: 0, last_update_ms: Date.now() }
  return null
}
