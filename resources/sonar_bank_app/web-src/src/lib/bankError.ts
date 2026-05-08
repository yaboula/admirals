import type { BankErrorPayload } from '@/data/contracts'
import { translate, type TranslationKey } from '@/lib/i18n'
import { useBankSession } from '@/stores/session'
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

interface BankErrorUserMessageDefinition {
  titleKey: TranslationKey
  descriptionKey: TranslationKey
  tone: BankErrorUserMessage['tone']
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

export const BANK_ERROR_USER_MESSAGE_DEFINITIONS: Record<CanonicalBankErrorCode, BankErrorUserMessageDefinition> = {
  BANK_DISABLED: {
    titleKey: 'bankError.bankDisabledTitle',
    descriptionKey: 'bankError.bankDisabledDescription',
    tone: 'danger',
  },
  AUTH_REQUIRED: {
    titleKey: 'bankError.authRequiredTitle',
    descriptionKey: 'bankError.authRequiredDescription',
    tone: 'warning',
  },
  AUTH_FORBIDDEN: {
    titleKey: 'bankError.authForbiddenTitle',
    descriptionKey: 'bankError.authForbiddenDescription',
    tone: 'danger',
  },
  AUTH_ACE_DENIED: {
    titleKey: 'bankError.authAceDeniedTitle',
    descriptionKey: 'bankError.authAceDeniedDescription',
    tone: 'danger',
  },
  RATE_LIMIT_EXCEEDED: {
    titleKey: 'bankError.rateLimitExceededTitle',
    descriptionKey: 'bankError.rateLimitExceededDescription',
    tone: 'warning',
  },
  IDEMPOTENCY_INFLIGHT: {
    titleKey: 'bankError.idempotencyInflightTitle',
    descriptionKey: 'bankError.idempotencyInflightDescription',
    tone: 'info',
  },
  VALIDATION_FAIL: {
    titleKey: 'bankError.validationFailTitle',
    descriptionKey: 'bankError.validationFailDescription',
    tone: 'danger',
  },
  INSUFFICIENT_FUNDS: {
    titleKey: 'bankError.insufficientFundsTitle',
    descriptionKey: 'bankError.insufficientFundsDescription',
    tone: 'warning',
  },
  INSUFFICIENT_QUORUM: {
    titleKey: 'bankError.insufficientQuorumTitle',
    descriptionKey: 'bankError.insufficientQuorumDescription',
    tone: 'info',
  },
  INVALID_TRANSITION: {
    titleKey: 'bankError.invalidTransitionTitle',
    descriptionKey: 'bankError.invalidTransitionDescription',
    tone: 'danger',
  },
  INVALID_ACCOUNT_CLASS: {
    titleKey: 'bankError.invalidAccountClassTitle',
    descriptionKey: 'bankError.invalidAccountClassDescription',
    tone: 'danger',
  },
  RESOURCE_NOT_FOUND: {
    titleKey: 'bankError.resourceNotFoundTitle',
    descriptionKey: 'bankError.resourceNotFoundDescription',
    tone: 'warning',
  },
  RESOURCE_LOCKED: {
    titleKey: 'bankError.resourceLockedTitle',
    descriptionKey: 'bankError.resourceLockedDescription',
    tone: 'info',
  },
  LIMIT_EXCEEDED_DAILY: {
    titleKey: 'bankError.limitExceededDailyTitle',
    descriptionKey: 'bankError.limitExceededDailyDescription',
    tone: 'warning',
  },
  LIMIT_EXCEEDED_MONTHLY: {
    titleKey: 'bankError.limitExceededMonthlyTitle',
    descriptionKey: 'bankError.limitExceededMonthlyDescription',
    tone: 'warning',
  },
  COMPLIANCE_FLAG_BLOCK: {
    titleKey: 'bankError.complianceFlagBlockTitle',
    descriptionKey: 'bankError.complianceFlagBlockDescription',
    tone: 'danger',
  },
  EXTERNAL_DEPENDENCY_FAIL: {
    titleKey: 'bankError.externalDependencyFailTitle',
    descriptionKey: 'bankError.externalDependencyFailDescription',
    tone: 'warning',
  },
  INTERNAL_SERVER_ERROR: {
    titleKey: 'bankError.internalServerErrorTitle',
    descriptionKey: 'bankError.internalServerErrorDescription',
    tone: 'danger',
  },
  UNSUPPORTED_PHASE_A: {
    titleKey: 'bankError.unsupportedFeatureTitle',
    descriptionKey: 'bankError.unsupportedFeatureDescription',
    tone: 'info',
  },
}

export function normalizeBankErrorCode(code: string | undefined): CanonicalBankErrorCode {
  if (!code) return 'INTERNAL_SERVER_ERROR'
  if (code in BANK_ERROR_USER_MESSAGE_DEFINITIONS) return code as CanonicalBankErrorCode
  return BANK_ERROR_CODE_ALIASES[code] ?? 'INTERNAL_SERVER_ERROR'
}

export function getUserMessage(code: string | undefined): BankErrorUserMessage {
  const normalized = normalizeBankErrorCode(code)
  const definition = BANK_ERROR_USER_MESSAGE_DEFINITIONS[normalized] ?? BANK_ERROR_USER_MESSAGE_DEFINITIONS.INTERNAL_SERVER_ERROR
  const locale = useBankSession.getState().locale
  return {
    title: translate(locale, definition.titleKey),
    description: translate(locale, definition.descriptionKey),
    tone: definition.tone,
  }
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
