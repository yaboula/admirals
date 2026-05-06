import { registerMockHandler } from '@/lib/nui'
import {
  buildMockBootstrap,
  buildMockClientConfig,
  buildMockRecentRecipientsResponse,
  simulateLatency,
} from './seed'
import type { BootstrapSnapshot, ClientConfigSnapshot, RecentRecipientsResponse } from '@/data/contracts'

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

  console.info('[mock] handlers installed (3 endpoints) — VITE_MOCK_MODE=true')
}
