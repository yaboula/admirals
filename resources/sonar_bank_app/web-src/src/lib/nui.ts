import type { NuiCallEnvelope, WrapResponse } from '@/data/contracts'
import { getNuiBaseUrl, isInsideFiveMNui, isMockMode } from '@/lib/env'
import { generateUuidV4 } from '@/lib/utils'
import { BankError } from '@/lib/bankError'

const DEFAULT_TIMEOUT_MS = 10_000
const WRITE_TIMEOUT_MS = 30_000

export interface NuiFetchOptions {
  timeoutMs?: number
  correlationId?: string
  signal?: AbortSignal
}

export type MockHandler<T> = (payload: Record<string, unknown>) => Promise<T> | T

const mockRegistry = new Map<string, MockHandler<unknown>>()

export function registerMockHandler<T>(eventName: string, handler: MockHandler<T>): void {
  mockRegistry.set(eventName, handler as MockHandler<unknown>)
}

export function clearMockHandlers(): void {
  mockRegistry.clear()
}

async function nuiFetchInternal<T>(
  eventName: string,
  payload: Record<string, unknown>,
  options: NuiFetchOptions,
): Promise<T> {
  const correlationId = options.correlationId ?? generateUuidV4()
  const envelope: NuiCallEnvelope = { event: eventName, payload: { ...payload, correlation_id: correlationId } }

  if (isMockMode() || !isInsideFiveMNui()) {
    const handler = mockRegistry.get(eventName)
    if (!handler) {
      throw new BankError(
        { code: 'NUI_MOCK_NOT_REGISTERED', category: 'internal', message: `No mock for ${eventName}` },
        correlationId,
      )
    }
    const result = await handler(envelope.payload)
    return result as T
  }

  const url = `${getNuiBaseUrl()}/cb`
  const controller = new AbortController()
  const timeoutId = window.setTimeout(() => controller.abort(), options.timeoutMs ?? DEFAULT_TIMEOUT_MS)
  if (options.signal) {
    options.signal.addEventListener('abort', () => controller.abort(), { once: true })
  }

  let response: Response
  try {
    response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(envelope),
      signal: controller.signal,
    })
  } catch (err) {
    window.clearTimeout(timeoutId)
    const isAbort = err instanceof DOMException && err.name === 'AbortError'
    throw new BankError(
      {
        code: isAbort ? 'TIMEOUT' : 'NUI_NETWORK_FAIL',
        category: 'internal',
        message: isAbort ? 'NUI fetch aborted (timeout)' : (err as Error).message,
        retryable: true,
      },
      correlationId,
    )
  }
  window.clearTimeout(timeoutId)

  if (!response.ok) {
    throw new BankError(
      { code: 'NUI_HTTP_FAIL', category: 'internal', message: `HTTP ${response.status}`, retryable: true },
      correlationId,
    )
  }

  let envelopeResp: WrapResponse<T>
  try {
    envelopeResp = (await response.json()) as WrapResponse<T>
  } catch (err) {
    throw new BankError(
      { code: 'NUI_PARSE_FAIL', category: 'internal', message: (err as Error).message },
      correlationId,
    )
  }

  if (!envelopeResp || typeof envelopeResp !== 'object' || !('ok' in envelopeResp)) {
    throw new BankError(
      { code: 'NUI_MALFORMED_ENVELOPE', category: 'internal', message: 'Server returned non-canonical envelope' },
      correlationId,
    )
  }

  if (envelopeResp.ok === false) {
    throw new BankError(envelopeResp.error, correlationId)
  }

  return envelopeResp.data
}

export function nuiQuery<T>(
  eventName: string,
  payload: Record<string, unknown> = {},
  options: NuiFetchOptions = {},
): Promise<T> {
  return nuiFetchInternal<T>(eventName, payload, {
    timeoutMs: options.timeoutMs ?? DEFAULT_TIMEOUT_MS,
    correlationId: options.correlationId,
    signal: options.signal,
  })
}

export function nuiMutate<T>(
  eventName: string,
  payload: Record<string, unknown> = {},
  options: NuiFetchOptions = {},
): Promise<T> {
  return nuiFetchInternal<T>(eventName, payload, {
    timeoutMs: options.timeoutMs ?? WRITE_TIMEOUT_MS,
    correlationId: options.correlationId,
    signal: options.signal,
  })
}

export function nuiControl(action: 'open' | 'close'): Promise<void> {
  if (!isInsideFiveMNui()) return Promise.resolve()
  const url = `${getNuiBaseUrl()}/${action}`
  return fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify({}),
  }).then(() => undefined)
}

export interface NuiInboundListener {
  (msg: MessageEvent['data']): void
}

const listeners = new Set<NuiInboundListener>()
let listenerInstalled = false

function installRootListener(): void {
  if (listenerInstalled || typeof window === 'undefined') return
  listenerInstalled = true
  window.addEventListener('message', (e: MessageEvent) => {
    for (const fn of listeners) {
      try {
        fn(e.data)
      } catch (err) {
        console.error('[nui] listener raised', err)
      }
    }
  })
}

export function onNuiMessage(fn: NuiInboundListener): () => void {
  installRootListener()
  listeners.add(fn)
  return () => listeners.delete(fn)
}
