import { useEffect, useState } from 'react'
import { nuiQuery, onNuiMessage } from '@/lib/nui'

export type BankStateBagKey =
  | 'bank.bridges.status'
  | `bank.business_treasury.${string}`
  | `bank.compliance.${string}.public`
  | 'bank.tax.brackets'
  | 'bank.elections.state'
  | `bank.subsidy.public.${string}`
  | 'bank.global.health'

export interface BankStateBagMessage<T = unknown> {
  type: 'STATE_BAG' | 'sonar:bank:statebag:update'
  key: BankStateBagKey
  value: T
}

interface StateBagSnapshot<T = unknown> {
  key: BankStateBagKey
  value: T
  fetched_at_ms?: number
}

type StateBagListener<T = unknown> = (value: T) => void

const stateBagCache = new Map<BankStateBagKey, unknown>()
const stateBagListeners = new Map<BankStateBagKey, Set<StateBagListener>>()
let bridgeInstalled = false

function isStateBagMessage(data: unknown): data is BankStateBagMessage {
  if (!data || typeof data !== 'object') return false
  const maybe = data as Partial<BankStateBagMessage>
  return (
    (maybe.type === 'STATE_BAG' || maybe.type === 'sonar:bank:statebag:update') &&
    typeof maybe.key === 'string' &&
    'value' in maybe
  )
}

function installBankStateBagBridge(): void {
  if (bridgeInstalled || typeof window === 'undefined') return
  bridgeInstalled = true

  onNuiMessage((data: unknown) => {
    if (!isStateBagMessage(data)) return
    stateBagCache.set(data.key, data.value)
    const listeners = stateBagListeners.get(data.key)
    if (!listeners) return
    for (const listener of listeners) {
      try {
        listener(data.value)
      } catch (err) {
        console.error('[bank-statebags] listener raised', err)
      }
    }
  })
}

export function useBankStateBag<T = unknown>(key: BankStateBagKey): T | null {
  const [value, setValue] = useState<T | null>(() => (stateBagCache.has(key) ? stateBagCache.get(key) as T : null))

  useEffect(() => {
    installBankStateBagBridge()

    const listeners = stateBagListeners.get(key) ?? new Set<StateBagListener>()
    const listener: StateBagListener = (next) => setValue(next as T)
    listeners.add(listener)
    stateBagListeners.set(key, listeners)

    if (stateBagCache.has(key)) {
      setValue(stateBagCache.get(key) as T)
    } else {
      void nuiQuery<StateBagSnapshot<T>>('sonar:bank:statebag:get', { key })
        .then((snapshot) => {
          stateBagCache.set(key, snapshot.value)
          setValue(snapshot.value)
        })
        .catch(() => undefined)
    }

    return () => {
      listeners.delete(listener)
      if (listeners.size === 0) stateBagListeners.delete(key)
    }
  }, [key])

  return value
}

export function hydrateBankStateBag<T = unknown>(key: BankStateBagKey, value: T): void {
  if (typeof window === 'undefined') return
  window.dispatchEvent(new MessageEvent('message', {
    data: { type: 'sonar:bank:statebag:update', key, value },
  }))
}
