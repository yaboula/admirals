/**
 * SONAR Tablet — useTabletRouter hook (S2.3).
 *
 * Thin wrapper sobre TabletRouterContext. Throw si usado fuera de
 * <TabletRouterProvider> (fail-fast strict — ayuda developer detectar missing
 * provider en tests/refactors).
 */
import { useContext } from 'react'
import { TabletRouterContext } from '@/context/TabletRouter'
import type { TabletRouterContextValue } from '@/context/TabletRouter'

export function useTabletRouter(): TabletRouterContextValue {
  const ctx = useContext(TabletRouterContext)
  if (ctx === null) {
    throw new Error(
      'useTabletRouter must be used within <TabletRouterProvider>',
    )
  }
  return ctx
}
