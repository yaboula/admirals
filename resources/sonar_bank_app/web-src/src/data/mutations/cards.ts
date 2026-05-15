import { useMutation, useQueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import type { BankCardMock, BootstrapSnapshot, CardStatus } from '@/data/contracts'
import { BankError } from '@/lib/bankError'
import { createBankOperationIds } from '@/lib/bankIdempotency'
import { bankMutation, useBankMutation } from '@/lib/bankQuery'

const MAX_LIMIT_MINOR = 100_000_000 // 1,000,000.00

/* ---------------------------------------------------------------------------
   BANK-FE.4.3 — Card mutations (Phase A · MOCK).

   Three optimistic mutations that patch the cards array inside the bootstrap
   snapshot via `queryClient.setQueryData`. Phase A simulates server latency
   (120-320 ms) and never fails — when BE delivers the real contracts (likely
   C012/C013/C014) we swap the mock body for `nuiMutate(...)` calls without
   touching consumers, and add error rollback in onError.

   Optimistic update strategy:
     onMutate    → snapshot previous bootstrap, write the patched version
     onError     → restore snapshot
     onSettled   → invalidate cards key (no-op for now since data lives inside
                   bootstrap, but it keeps consumers ready for the eventual
                   dedicated cards endpoint)

   Decision deviation logged: real BE freeze flow likely needs an additional
   `freeze_reason` enum (lost / stolen / precaution). For Phase A we keep the
   minimal { card_id, freeze: bool } payload to unblock the FE; the contract
   will grow later under M1 doc-first review.
   --------------------------------------------------------------------------- */

interface MutationContext {
  previous: BootstrapSnapshot | undefined
}

function patchCardInBootstrap(
  snap: BootstrapSnapshot,
  cardId: string,
  patch: Partial<BankCardMock>,
): BootstrapSnapshot {
  return {
    ...snap,
    cards: snap.cards.map((c) => (c.card_id === cardId ? { ...c, ...patch } : c)),
  }
}

function removeCardFromBootstrap(
  snap: BootstrapSnapshot,
  cardId: string,
): BootstrapSnapshot {
  return {
    ...snap,
    cards: snap.cards.filter((c) => c.card_id !== cardId),
  }
}

/* ============================================================================
   useFreezeCard — toggle a card's status between 'active' and 'locked'.
   ============================================================================ */

export interface FreezeCardArgs extends Record<string, unknown> {
  cardId: string
  freeze: boolean
}

export interface CardStatusResponse {
  card_id: string
  status: CardStatus
}

export function useFreezeCard() {
  const qc = useQueryClient()

  return useMutation<CardStatusResponse, BankError, FreezeCardArgs, MutationContext>({
    mutationFn: async ({ cardId, freeze }) => {
      const eventName = freeze ? 'sonar:bank:card:freeze' : 'sonar:bank:card:unfreeze'
      const response = await bankMutation<{ card_id: string }, { card_id: string; status: string }>(
        eventName,
        { card_id: cardId },
        { idempotency: createBankOperationIds },
      )
      const newStatus: CardStatus = freeze ? 'locked' : 'active'
      return { card_id: response.card_id, status: newStatus }
    },
    onMutate: async ({ cardId, freeze }) => {
      await qc.cancelQueries({ queryKey: queryKeys.bootstrap() })
      const previous = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
      if (previous) {
        const newStatus: CardStatus = freeze ? 'locked' : 'active'
        qc.setQueryData<BootstrapSnapshot>(
          queryKeys.bootstrap(),
          patchCardInBootstrap(previous, cardId, { status: newStatus }),
        )
      }
      return { previous }
    },
    onError: (_err, _vars, context) => {
      if (context?.previous) {
        qc.setQueryData(queryKeys.bootstrap(), context.previous)
      }
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
    },
    onSettled: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.cards.all() })
    },
  })
}

export interface ChangeCardPinArgs extends Record<string, unknown> {
  card_id: string
  old_pin: string
  new_pin: string
}

export interface ChangeCardPinResponse {
  card_id: string
  pin_changed_ms: number
}

export function useChangeCardPinMutation() {
  const qc = useQueryClient()
  return useMutation<ChangeCardPinResponse, BankError, ChangeCardPinArgs>({
    mutationFn: async (args) => {
      if (!/^\d{4,8}$/.test(args.old_pin) || !/^\d{4,8}$/.test(args.new_pin)) {
        throw new BankError({
          code: 'VALIDATION_FAILED',
          category: 'validation',
          message: 'PIN must contain 4-8 digits',
          retryable: false,
        })
      }
      return bankMutation<ChangeCardPinArgs, ChangeCardPinResponse>('sonar:bank:card:changePin', args)
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      void qc.invalidateQueries({ queryKey: queryKeys.cards.all() })
    },
  })
}

export interface RevokeCardArgs extends Record<string, unknown> {
  card_id: string
  reason?: 'lost' | 'stolen' | 'damaged'
}

export interface RevokeCardResponse {
  card_id: string
  status: 'revoked'
  revoked_ms: number
}

export function useRevokeCardMutation() {
  const qc = useQueryClient()
  return useMutation<RevokeCardResponse, BankError, RevokeCardArgs, MutationContext>({
    mutationFn: async (args) => {
      return bankMutation<RevokeCardArgs, RevokeCardResponse>(
        'sonar:bank:card:revoke',
        args,
        { idempotency: createBankOperationIds },
      )
    },
    onMutate: async ({ card_id }) => {
      await qc.cancelQueries({ queryKey: queryKeys.bootstrap() })
      const previous = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
      if (previous) {
        qc.setQueryData<BootstrapSnapshot>(
          queryKeys.bootstrap(),
          removeCardFromBootstrap(previous, card_id),
        )
      }
      return { previous }
    },
    onError: (_err, _vars, context) => {
      if (context?.previous) {
        qc.setQueryData(queryKeys.bootstrap(), context.previous)
      }
    },
    onSettled: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      void qc.invalidateQueries({ queryKey: queryKeys.cards.all() })
    },
  })
}

/* ============================================================================
   useUpdateCardLimits — patch daily and monthly limit ceilings.
   ============================================================================ */

export interface UpdateCardLimitsArgs {
  cardId: string
  daily_limit_minor: number
  monthly_limit_minor: number
}

interface SetLimitsBackendPayload extends Record<string, unknown> {
  card_id: string
  daily_limit_minor: number
  monthly_limit_minor: number
}

export interface SetLimitsResponse {
  card_id: string
  daily_limit_minor: number
  monthly_limit_minor: number
  updated_ms: number
}

/**
 * useUpdateCardLimits — wires C035 sonar:bank:card:setLimits.
 *
 * Validates the same invariants as the BE (non-negative integers in minor units,
 * monthly >= daily, capped at MAX_LIMIT_MINOR) before crossing the bridge so
 * obvious mistakes never reach the server. On success the bootstrap snapshot is
 * patched optimistically and re-fetched; on failure the previous snapshot is
 * restored and a canonical BankError is surfaced.
 */
export function useUpdateCardLimits() {
  const qc = useQueryClient()

  return useMutation<SetLimitsResponse, BankError, UpdateCardLimitsArgs, MutationContext>({
    mutationFn: async (args) => {
      const isInt = (n: number) => Number.isFinite(n) && Math.floor(n) === n
      if (!isInt(args.daily_limit_minor) || args.daily_limit_minor < 0 || args.daily_limit_minor > MAX_LIMIT_MINOR) {
        throw new BankError({
          code: 'VALIDATION_FAILED',
          category: 'validation',
          message: 'Límite diario inválido',
          retryable: false,
        })
      }
      if (!isInt(args.monthly_limit_minor) || args.monthly_limit_minor < 0 || args.monthly_limit_minor > MAX_LIMIT_MINOR) {
        throw new BankError({
          code: 'VALIDATION_FAILED',
          category: 'validation',
          message: 'Límite mensual inválido',
          retryable: false,
        })
      }
      if (args.monthly_limit_minor < args.daily_limit_minor) {
        throw new BankError({
          code: 'INVALID_LIMITS',
          category: 'validation',
          message: 'El límite mensual no puede ser inferior al diario',
          retryable: false,
        })
      }
      const snap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
      const card = snap?.cards.find((c) => c.card_id === args.cardId)
      if (!card) {
        throw new BankError({
          code: 'CARD_NOT_FOUND',
          category: 'not_found',
          message: 'No se encontró la tarjeta',
          retryable: false,
        })
      }
      const payload: SetLimitsBackendPayload = {
        card_id: args.cardId,
        daily_limit_minor: args.daily_limit_minor,
        monthly_limit_minor: args.monthly_limit_minor,
      }
      return bankMutation<SetLimitsBackendPayload, SetLimitsResponse>(
        'sonar:bank:card:setLimits',
        payload,
        { idempotency: createBankOperationIds },
      )
    },
    onMutate: async (args) => {
      await qc.cancelQueries({ queryKey: queryKeys.bootstrap() })
      const previous = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
      if (previous) {
        qc.setQueryData<BootstrapSnapshot>(
          queryKeys.bootstrap(),
          patchCardInBootstrap(previous, args.cardId, {
            daily_limit_minor: args.daily_limit_minor,
            monthly_limit_minor: args.monthly_limit_minor,
          }),
        )
      }
      return { previous }
    },
    onError: (_err, _vars, context) => {
      if (context?.previous) {
        qc.setQueryData(queryKeys.bootstrap(), context.previous)
      }
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
    },
    onSettled: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.cards.all() })
    },
  })
}

/* ============================================================================
   useIssueCard — request a new physical card linked to the player's account.
   Calls C032 sonar:bank:card:issue. Requires account_iban + 4-8 digit PIN.
   On success, invalidates bootstrap so the new card appears in the carousel.
   ============================================================================ */

export interface IssueCardArgs extends Record<string, unknown> {
  account_iban: string
  pin: string
  card_type: 'classic' | 'premium'
  design_id?: string
  spend_limit_minor?: number
}

export interface IssueCardResult {
  card_id: string
  masked_number: string
  card_type: 'classic' | 'premium'
  design_id?: string
  issue_fee_minor?: number
}

export function useIssueCard() {
  const qc = useQueryClient()
  return useBankMutation<IssueCardResult, IssueCardArgs>(
    'sonar:bank:card:issue',
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
    { idempotency: createBankOperationIds },
  )
}

/* ============================================================================
   useApplyCardDesign — change the visual design of an existing card.
   ============================================================================ */

export interface ApplyCardDesignArgs {
  cardId: string
  designId: string
}

export interface ApplyCardDesignResponse {
  card_id: string
  design_id: string
  updated_ms: number
}

/**
 * useApplyCardDesign — persist the chosen visual design for a card (C036).
 *
 * Calls the real BE callback `sonar:bank:card:applyDesign` so the choice
 * survives reload / re-login. Optimistically patches the bootstrap snapshot
 * so the carousel + detail card react instantly; on error we restore the
 * previous snapshot and surface a canonical BankError to the dialog.
 */
export function useApplyCardDesign() {
  const qc = useQueryClient()

  return useMutation<ApplyCardDesignResponse, BankError, ApplyCardDesignArgs, MutationContext>({
    mutationFn: async ({ cardId, designId }) => {
      return bankMutation<{ card_id: string; design_id: string }, ApplyCardDesignResponse>(
        'sonar:bank:card:applyDesign',
        { card_id: cardId, design_id: designId },
        { idempotency: createBankOperationIds },
      )
    },
    onMutate: async ({ cardId, designId }) => {
      await qc.cancelQueries({ queryKey: queryKeys.bootstrap() })
      const previous = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
      if (previous) {
        qc.setQueryData<BootstrapSnapshot>(
          queryKeys.bootstrap(),
          patchCardInBootstrap(previous, cardId, { design_id: designId }),
        )
      }
      return { previous }
    },
    onError: (_err, _vars, context) => {
      if (context?.previous) {
        qc.setQueryData(queryKeys.bootstrap(), context.previous)
      }
    },
    onSettled: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      void qc.invalidateQueries({ queryKey: queryKeys.cards.all() })
    },
  })
}
