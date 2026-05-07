import type { BankErrorPayload } from '@/data/contracts'
import { toast } from '@/stores/toast'

export type CanonicalBankErrorCode =
  | 'BANK_DISABLED'
  | 'AUTH_REQUIRED'
  | 'AUTH_FORBIDDEN'
  | 'AUTH_ACE_DENIED'
  | 'RATE_LIMIT_EXCEEDED'
  | 'IDEMPOTENCY_INFLIGHT'
  | 'VALIDATION_FAIL'
  | 'INSUFFICIENT_FUNDS'
  | 'INSUFFICIENT_QUORUM'
  | 'INVALID_TRANSITION'
  | 'INVALID_ACCOUNT_CLASS'
  | 'RESOURCE_NOT_FOUND'
  | 'RESOURCE_LOCKED'
  | 'LIMIT_EXCEEDED_DAILY'
  | 'LIMIT_EXCEEDED_MONTHLY'
  | 'COMPLIANCE_FLAG_BLOCK'
  | 'EXTERNAL_DEPENDENCY_FAIL'
  | 'INTERNAL_SERVER_ERROR'
  | 'UNSUPPORTED_PHASE_A'

export class BankError extends Error {
  readonly code: string
  readonly category: BankErrorPayload['category']
  readonly details?: Record<string, unknown>
  readonly retryable: boolean
  readonly correlationId?: string

  constructor(payload: BankErrorPayload, correlationId?: string) {
    super(payload.message ?? payload.code)
    this.name = 'BankError'
    this.code = payload.code
    this.category = payload.category
    this.details = payload.details
    this.retryable = payload.retryable === true
    this.correlationId = correlationId
  }

  toJSON(): BankErrorPayload & { correlationId?: string } {
    return {
      code: this.code,
      category: this.category,
      message: this.message,
      details: this.details,
      retryable: this.retryable,
      correlationId: this.correlationId,
    }
  }
}

export interface BankErrorUserMessage {
  title: string
  description: string
  tone: 'success' | 'warning' | 'danger' | 'info'
}

const BANK_ERROR_CODE_ALIASES: Record<string, CanonicalBankErrorCode> = {
  VALIDATION_FAILED: 'VALIDATION_FAIL',
  INVALID_CITIZEN_ID: 'AUTH_REQUIRED',
  INVALID_IBAN: 'VALIDATION_FAIL',
  INVALID_LIMITS: 'VALIDATION_FAIL',
  ACCOUNT_NOT_FOUND: 'RESOURCE_NOT_FOUND',
  CARD_NOT_FOUND: 'RESOURCE_NOT_FOUND',
  RATE_LIMITED: 'RATE_LIMIT_EXCEEDED',
  FORBIDDEN: 'AUTH_ACE_DENIED',
  COMPLIANCE_FROZEN: 'COMPLIANCE_FLAG_BLOCK',
  IDEMPOTENCY_REPLAY: 'IDEMPOTENCY_INFLIGHT',
  TIMEOUT: 'EXTERNAL_DEPENDENCY_FAIL',
  NUI_NETWORK_FAIL: 'EXTERNAL_DEPENDENCY_FAIL',
  NUI_HTTP_FAIL: 'EXTERNAL_DEPENDENCY_FAIL',
  NUI_BRIDGE_RAISED: 'EXTERNAL_DEPENDENCY_FAIL',
  NUI_FORBIDDEN_EVENT: 'AUTH_FORBIDDEN',
  NUI_MOCK_NOT_REGISTERED: 'RESOURCE_NOT_FOUND',
  NUI_PARSE_FAIL: 'INTERNAL_SERVER_ERROR',
  NUI_MALFORMED_ENVELOPE: 'INTERNAL_SERVER_ERROR',
  INTERNAL_ERROR: 'INTERNAL_SERVER_ERROR',
}

export const BANK_ERROR_USER_MESSAGES: Record<CanonicalBankErrorCode, BankErrorUserMessage> = {
  BANK_DISABLED: {
    title: 'Banco no disponible',
    description: 'El servicio bancario está desactivado temporalmente.',
    tone: 'danger',
  },
  AUTH_REQUIRED: {
    title: 'Autenticación requerida',
    description: 'Tu sesión ha caducado. Reabre la app del banco.',
    tone: 'warning',
  },
  AUTH_FORBIDDEN: {
    title: 'Acceso no permitido',
    description: 'No puedes realizar esta operación con la sesión actual.',
    tone: 'danger',
  },
  AUTH_ACE_DENIED: {
    title: 'Permiso insuficiente',
    description: 'No tienes el permiso ACE necesario para esta acción.',
    tone: 'danger',
  },
  RATE_LIMIT_EXCEEDED: {
    title: 'Demasiadas operaciones',
    description: 'Has superado el límite temporal. Espera unos segundos.',
    tone: 'warning',
  },
  IDEMPOTENCY_INFLIGHT: {
    title: 'Operación en proceso',
    description: 'Ya estamos procesando esta acción. Espera la confirmación.',
    tone: 'info',
  },
  VALIDATION_FAIL: {
    title: 'Datos no válidos',
    description: 'Revisa los campos del formulario y vuelve a intentarlo.',
    tone: 'danger',
  },
  INSUFFICIENT_FUNDS: {
    title: 'Fondos insuficientes',
    description: 'No hay saldo disponible para completar esta operación.',
    tone: 'warning',
  },
  INSUFFICIENT_QUORUM: {
    title: 'Faltan firmantes',
    description: 'La operación necesita más aprobaciones antes de ejecutarse.',
    tone: 'info',
  },
  INVALID_TRANSITION: {
    title: 'Operación no permitida',
    description: 'El estado actual no permite realizar esta acción.',
    tone: 'danger',
  },
  INVALID_ACCOUNT_CLASS: {
    title: 'Cuenta incompatible',
    description: 'Esta cuenta no admite la operación seleccionada.',
    tone: 'danger',
  },
  RESOURCE_NOT_FOUND: {
    title: 'Recurso no encontrado',
    description: 'No localizamos el recurso indicado. Actualiza e inténtalo de nuevo.',
    tone: 'warning',
  },
  RESOURCE_LOCKED: {
    title: 'Recurso bloqueado',
    description: 'El recurso está ocupado temporalmente. Reintenta en unos segundos.',
    tone: 'info',
  },
  LIMIT_EXCEEDED_DAILY: {
    title: 'Límite diario superado',
    description: 'La operación supera el límite diario configurado.',
    tone: 'warning',
  },
  LIMIT_EXCEEDED_MONTHLY: {
    title: 'Límite mensual superado',
    description: 'La operación supera el límite mensual configurado.',
    tone: 'warning',
  },
  COMPLIANCE_FLAG_BLOCK: {
    title: 'Operación bloqueada',
    description: 'Compliance ha bloqueado esta acción. Revisa los avisos de tu cuenta.',
    tone: 'danger',
  },
  EXTERNAL_DEPENDENCY_FAIL: {
    title: 'Error de comunicación',
    description: 'La conexión con el servicio bancario falló. Reintenta.',
    tone: 'warning',
  },
  INTERNAL_SERVER_ERROR: {
    title: 'Error interno',
    description: 'Algo ha fallado en el servidor. Si persiste, contacta soporte.',
    tone: 'danger',
  },
  UNSUPPORTED_PHASE_A: {
    title: 'No disponible en Phase A',
    description: 'Esta función está preparada visualmente pero aún no está activa.',
    tone: 'info',
  },
}

export function normalizeBankErrorCode(code: string | undefined): CanonicalBankErrorCode {
  if (!code) return 'INTERNAL_SERVER_ERROR'
  if (code in BANK_ERROR_USER_MESSAGES) return code as CanonicalBankErrorCode
  return BANK_ERROR_CODE_ALIASES[code] ?? 'INTERNAL_SERVER_ERROR'
}

export function getUserMessage(code: string | undefined): BankErrorUserMessage {
  const normalized = normalizeBankErrorCode(code)
  return (
    BANK_ERROR_USER_MESSAGES[normalized] ?? BANK_ERROR_USER_MESSAGES.INTERNAL_SERVER_ERROR
  )
}

export function handleBankError(error: unknown): BankErrorUserMessage {
  const code = error && typeof error === 'object' && 'code' in error
    ? String(error.code)
    : undefined
  const message = getUserMessage(code)
  if (message.tone === 'warning') toast.warning(message.title, message.description)
  else if (message.tone === 'info') toast.info(message.title, message.description)
  else toast.danger(message.title, message.description)
  return message
}
