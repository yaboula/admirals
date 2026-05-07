import { BankError } from '@/lib/bankError'
import { generateUuidV4 } from '@/lib/utils'

export interface BankOperationIds {
  idempotencyKey: string
  correlationId: string
}

export interface BankIdempotencyPayload {
  idempotency_key: string
  correlation_id: string
}

export interface BankIdempotencyFlowState {
  idempotencyKey: string | null
  correlationId: string | null
}

export type BankIdempotencyPolicy =
  | false
  | BankOperationIds
  | (() => BankOperationIds | BankIdempotencyFlowState)

export function createBankOperationIds(): BankOperationIds {
  return {
    idempotencyKey: generateUuidV4(),
    correlationId: generateUuidV4(),
  }
}

export function requireBankOperationIds(flow: BankIdempotencyFlowState): BankOperationIds {
  if (!flow.idempotencyKey || !flow.correlationId) {
    throw new BankError({
      code: 'VALIDATION_FAILED',
      category: 'validation',
      message: 'Mutation flow is missing idempotency metadata',
      retryable: false,
    })
  }

  return {
    idempotencyKey: flow.idempotencyKey,
    correlationId: flow.correlationId,
  }
}

export function toBankIdempotencyPayload(ids: BankOperationIds): BankIdempotencyPayload {
  return {
    idempotency_key: ids.idempotencyKey,
    correlation_id: ids.correlationId,
  }
}

export function withBankIdempotency<TPayload extends Record<string, unknown>>(
  payload: TPayload,
  policy: BankIdempotencyPolicy,
): TPayload & Partial<BankIdempotencyPayload> {
  if (policy === false) return payload

  const source = typeof policy === 'function' ? policy() : policy
  const ids = requireBankOperationIds(source)

  return {
    ...payload,
    ...toBankIdempotencyPayload(ids),
  }
}
