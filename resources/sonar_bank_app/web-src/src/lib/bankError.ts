import type { BankErrorPayload } from '@/data/contracts'

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

export const BANK_ERROR_USER_MESSAGES: Record<string, { title: string; description: string }> = {
  VALIDATION_FAILED: {
    title: 'Datos no válidos',
    description: 'Revisa los campos del formulario y vuelve a intentarlo.',
  },
  INVALID_CITIZEN_ID: {
    title: 'Sesión no reconocida',
    description: 'Tu sesión bancaria no se ha identificado. Reinicia el cliente.',
  },
  INVALID_IBAN: {
    title: 'IBAN no válido',
    description: 'El formato del IBAN introducido no es correcto.',
  },
  ACCOUNT_NOT_FOUND: {
    title: 'Cuenta no encontrada',
    description: 'No localizamos la cuenta indicada en el sistema.',
  },
  RATE_LIMITED: {
    title: 'Demasiadas operaciones',
    description: 'Has superado el límite por minuto. Espera unos segundos.',
  },
  AUTH_REQUIRED: {
    title: 'Autenticación requerida',
    description: 'Tu sesión ha caducado. Reabre la app del banco.',
  },
  FORBIDDEN: {
    title: 'Permiso insuficiente',
    description: 'No tienes el permiso ACE necesario para esta acción.',
  },
  COMPLIANCE_FROZEN: {
    title: 'Cuenta congelada',
    description: 'La cuenta está congelada por compliance. Contacta soporte.',
  },
  IDEMPOTENCY_REPLAY: {
    title: 'Operación repetida',
    description: 'Ya hemos procesado esta operación recientemente.',
  },
  TIMEOUT: {
    title: 'Tiempo agotado',
    description: 'El servidor no respondió a tiempo. Reintenta.',
  },
  NUI_FORBIDDEN_EVENT: {
    title: 'Evento no permitido',
    description: 'El cliente intentó invocar un endpoint fuera de la lista blanca.',
  },
  NUI_BRIDGE_RAISED: {
    title: 'Error de comunicación',
    description: 'La conexión con el servidor falló. Reintenta.',
  },
  INTERNAL_ERROR: {
    title: 'Error interno',
    description: 'Algo ha fallado en el servidor. Si persiste, contacta soporte.',
  },
}

export function getUserMessage(code: string): { title: string; description: string } {
  return (
    BANK_ERROR_USER_MESSAGES[code] ?? {
      title: 'Error',
      description: code,
    }
  )
}
