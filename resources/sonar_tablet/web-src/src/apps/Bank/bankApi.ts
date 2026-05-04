/**
 * SONAR Tablet — Bank API (S2.4).
 *
 * Thin wrapper sobre `fetchNUI` (NUI → client Lua forwarder → server lib.callback).
 * Contratos NUI definidos en `types/nui.ts` (`sonar:tablet:bank:*` endpoints).
 *
 * Los 3 wrappers retornan promesas tipadas o lanzan `BankApiError` con
 * `error_code` canónico per SSoT §3.1/§3.2 + bridge ad-hoc §2.2.3.
 *
 * Anti-mock-drift:
 *   - Dev-mode (no FiveM): `fetchNUI` hace fetch a `https://<resourceName>/...`
 *     que fallará → caller debe manejar BankApiError('CALLBACK_FAILED').
 *   - Producción FiveM: shape canónica garantizada por
 *     `resources/sonar_bank/server/callbacks.lua` + `_forwardCallback` en
 *     `resources/sonar_tablet/client/main.lua`.
 */
import { fetchNUI } from '@/lib/nui'
import {
  BankApiError,
  type BankBalance,
  type BankErrorCode,
  type BankHistoryData,
  type BankMovement,
  type TransferRequest,
  type TransferResponse,
  type TransferResponseData,
} from './types'

/** Response envelope canónico (backend `{ success, data|error_code }`). */
type BackendEnvelope<TData> =
  | { success: true; data: TData }
  | { success: false; error_code: BankErrorCode; message?: string }

/**
 * UUID v4 client-side — RFC 4122 §4.4 compat (mismo template que
 * `sonar_bank/server/accounts.lua:52` _uuid_v4 Lua).
 *
 * Uses `crypto.randomUUID()` when available (modern Chromium; FiveM CEF ≥ 108),
 * falls back a `Math.random` impl si unsupported.
 */
export function uuidv4(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  // Fallback (less entropy, but still RFC 4122-compliant template).
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0
    const v = c === 'x' ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

/** Throw BankApiError desde response envelope si no fue success. */
function _unwrap<TData>(env: BackendEnvelope<TData>): TData {
  if (env.success) return env.data
  throw new BankApiError(env.error_code, env.message ?? env.error_code)
}

/**
 * C001 — balance real player (vía forwarder `sonar:tablet:bank:getBalance`).
 *
 * @param iban opcional — default IBAN personal del player actual.
 * @returns BankBalance canonical.
 * @throws BankApiError con `error_code` per SSoT §3.1 (INVALID_IBAN, NO_ACCOUNT,
 *         NOT_AUTHORIZED, RATE_LIMITED, NOT_AUTHENTICATED, IBAN_REQUIRED).
 */
export async function getBalance(iban?: string): Promise<BankBalance> {
  const env = await fetchNUI<{ iban?: string }, BackendEnvelope<BankBalance>>(
    'sonar:tablet:bank:getBalance',
    iban ? { iban } : {},
  )
  return _unwrap(env)
}

/**
 * C002 — transfer atomic A→B (vía forwarder `sonar:tablet:bank:transfer`).
 *
 * Cliente debe generar `request_id` (UUID v4) vía {@link uuidv4} y preservarlo
 * a través de reintentos — idempotency DB-backed garantiza mismo response en
 * replay per SSoT §3.2 + callbacks.lua:333-340.
 *
 * @throws BankApiError con códigos C002 per SSoT §3.2 +
 *         callbacks.lua:317-327 (INSUFFICIENT_FUNDS, INVALID_IBAN,
 *         SELF_TRANSFER, AMOUNT_OUT_OF_RANGE, NOT_AUTHORIZED, TX_CRASH,
 *         TX_ROLLBACK, RACE_DETECTED, ACCOUNT_FROZEN, RATE_LIMITED, etc).
 */
export async function transfer(req: TransferRequest): Promise<TransferResponseData> {
  const env = await fetchNUI<TransferRequest, TransferResponse>(
    'sonar:tablet:bank:transfer',
    req,
  )
  return _unwrap(env)
}

/**
 * Historial movements (bridge ad-hoc §2.2.3 — consumer pattern temporal
 * DEFERRED catalog promotion S3 per SPRINT_PLAN_S2 §2.2.3).
 *
 * @param limit default 50, hard cap server-side 200 (sonar_bank_movements
 *              index p99 <5ms per `03_db_schema.md` §15).
 * @returns array BankMovement ordenado DESC por fecha.
 * @throws BankApiError.
 */
export async function getHistory(limit: number = 50): Promise<BankMovement[]> {
  const env = await fetchNUI<{ limit: number }, BackendEnvelope<BankHistoryData>>(
    'sonar:tablet:bank:getHistory',
    { limit },
  )
  return _unwrap(env).movements
}

/**
 * Spanish human-readable mapping de error codes canónicos. Única fuente de
 * copy — UI consume via `translateError(err.error_code)`. Añadir código nuevo
 * = añadir aquí + en `BankErrorCode` union en `types.ts`.
 */
export function translateError(code: BankErrorCode): string {
  const map: Record<BankErrorCode, string> = {
    NOT_AUTHENTICATED:   'Sesión no iniciada.',
    NOT_AUTHORIZED:      'No estás autorizado para esta operación.',
    IBAN_REQUIRED:       'Debes indicar un IBAN.',
    INVALID_IBAN:        'IBAN no válido.',
    MISSING_FIELD:       'Faltan campos obligatorios.',
    AMOUNT_OUT_OF_RANGE: 'Importe fuera de rango (0 < amount ≤ 1.000.000 €).',
    SELF_TRANSFER:       'No puedes transferirte a ti mismo.',
    NO_ACCOUNT:          'No tienes cuenta personal todavía.',
    ACCOUNT_FROZEN:      'Cuenta congelada o cerrada.',
    INSUFFICIENT_FUNDS:  'Saldo insuficiente.',
    RATE_LIMITED:        'Demasiadas peticiones. Espera un momento.',
    RACE_DETECTED:       'Saldo agotado por concurrencia. Reintenta.',
    TX_CRASH:            'Error transitorio del sistema. Reintenta.',
    TX_ROLLBACK:         'Operación abortada por integridad. Reintenta.',
    CALLBACK_FAILED:     'El servidor no respondió. Reintenta.',
    UNKNOWN:             'Error desconocido.',
    FAILED:              'Operación fallida.',
  }
  return map[code] ?? 'Operación fallida.'
}
