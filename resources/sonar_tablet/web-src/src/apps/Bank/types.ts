/**
 * SONAR Tablet — Bank app canonical types (S2.4).
 *
 * Shapes matchean:
 *   - C001 response per `docs/technical/04_api_contracts.md` §3.1 +
 *     `resources/sonar_bank/server/callbacks.lua:177-187`.
 *   - C002 response per SSoT §3.2 +
 *     `resources/sonar_bank/server/callbacks.lua:309-330` + Transfer.Execute.
 *   - Bridge ad-hoc §2.2.3 per
 *     `resources/sonar_tablet/server/bank_history.lua` getHistoryDirect response.
 *
 * Error codes: union estrecho de los códigos devueltos por C001/C002/bridge +
 * `CALLBACK_FAILED`/`UNKNOWN` añadidos por client-side forwarder
 * (`resources/sonar_tablet/client/main.lua:_forwardCallback`).
 */

/** Tier canonical — mapping DB enum (personal/company/cooperative/escrow) → 2 valores. */
export type BankTier = 'personal' | 'empresa'

/** C001 data payload (balance canonical shape). */
export interface BankBalance {
  iban: string
  balance: number
  currency: 'EUR'
  tier: BankTier
  /** UNIX ms (NOT seconds). Server retorna occurred_at × 1000. */
  last_updated: number
}

/** Bridge ad-hoc §2.2.3 movement row (historial). */
export interface BankMovement {
  id: number
  /** Signed: positive=ingreso, negative=salida. */
  amount: number
  balance_after: number
  category: BankMovementCategory
  counterpart_iban: string | null
  concept: string | null
  /** UNIX ms (server normaliza occurred_at × 1000). */
  created_at: number
}

/** ENUM canónico `sonar_bank_movements.category` (DB schema §4.2 + migration 003). */
export type BankMovementCategory =
  | 'salary'
  | 'b2b_payment'
  | 'transfer'
  | 'tax'
  | 'refund'
  | 'b2c_sale'
  | 'expense'
  | 'deposit'
  | 'withdrawal'
  | 'escrow_lock'
  | 'escrow_release'
  | 'adjustment'
  | 'starter_seed'

/** C002 request shape. */
export interface TransferRequest {
  from_iban: string
  to_iban: string
  amount: number
  concept: string
  /** UUID v4 client-generated. Idempotency key per SSoT §3.2. */
  request_id: string
}

/** C002 success data shape. */
export interface TransferResponseData {
  transaction_id: string
  /** UNIX seconds (per SSoT C002 response). */
  timestamp: number
  new_balance_from: number
  fee_retained?: number
}

/** C002 response envelope. */
export type TransferResponse =
  | { success: true; data: TransferResponseData }
  | { success: false; error_code: BankErrorCode; message: string }

/** Historial response shape (bridge ad-hoc §2.2.3). */
export interface BankHistoryData {
  movements: BankMovement[]
  total: number
  account_id: string
  iban: string
}

/**
 * Union de error codes que Bank app puede recibir (C001 + C002 + bridge ad-hoc
 * + forwarder). Mantener sincronizado con `error_map` Spanish mapper en
 * `bankApi.ts` + UI copy en `BankTransfer.tsx`.
 */
export type BankErrorCode =
  // Autenticación/autorización
  | 'NOT_AUTHENTICATED'
  | 'NOT_AUTHORIZED'
  // Validación
  | 'IBAN_REQUIRED'
  | 'INVALID_IBAN'
  | 'MISSING_FIELD'
  | 'AMOUNT_OUT_OF_RANGE'
  | 'SELF_TRANSFER'
  // Account state
  | 'NO_ACCOUNT'
  | 'ACCOUNT_FROZEN'
  | 'INSUFFICIENT_FUNDS'
  // Transient / infra
  | 'RATE_LIMITED'
  | 'RACE_DETECTED'
  | 'TX_CRASH'
  | 'TX_ROLLBACK'
  | 'CALLBACK_FAILED'
  | 'UNKNOWN'
  | 'FAILED'

/**
 * Typed error thrown por `bankApi.*`. Preserva `error_code` canónico para que
 * UI decida copy via `translateError()` en `bankApi.ts`.
 */
export class BankApiError extends Error {
  readonly error_code: BankErrorCode
  constructor(error_code: BankErrorCode, message: string) {
    super(message)
    this.name = 'BankApiError'
    this.error_code = error_code
  }
}
