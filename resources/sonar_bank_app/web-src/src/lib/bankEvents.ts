import { useEffect, useRef } from 'react'
import { onNuiMessage } from '@/lib/nui'
import type { NuiInboundMessage, NuiNetEventName } from '@/data/contracts'

export type BankNetEventHandler<T = unknown> = (payload: T) => void

const eventBus = new Map<NuiNetEventName, Set<BankNetEventHandler>>()
let bridgeInstalled = false

function installBankNetEventBridge(): void {
  if (bridgeInstalled || typeof window === 'undefined') return
  bridgeInstalled = true

  onNuiMessage((data: unknown) => {
    const msg = data as NuiInboundMessage
    if (!msg || typeof msg !== 'object' || !('type' in msg)) return
    if (msg.type !== 'NET_EVENT') return

    const handlers = eventBus.get(msg.event)
    if (!handlers) return

    for (const handler of handlers) {
      try {
        handler(msg.payload)
      } catch (err) {
        console.error('[bank-events] handler raised', err)
      }
    }
  })
}

export function useBankNetEvent<T = unknown>(eventName: NuiNetEventName, handler: BankNetEventHandler<T>): void {
  const handlerRef = useRef(handler)

  useEffect(() => {
    handlerRef.current = handler
  }, [handler])

  useEffect(() => {
    installBankNetEventBridge()
    const stableHandler: BankNetEventHandler = (payload) => handlerRef.current(payload as T)
    const handlers = eventBus.get(eventName) ?? new Set<BankNetEventHandler>()
    handlers.add(stableHandler)
    eventBus.set(eventName, handlers)

    return () => {
      handlers.delete(stableHandler)
      if (handlers.size === 0) eventBus.delete(eventName)
    }
  }, [eventName])
}

export function dispatchMockBankNetEvent<T = unknown>(eventName: NuiNetEventName, payload: T): void {
  if (typeof window === 'undefined') return
  window.dispatchEvent(new MessageEvent('message', {
    data: { type: 'NET_EVENT', event: eventName, payload },
  }))
}
