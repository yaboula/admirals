import { useMutation, useQueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import type { BankCardMock, BootstrapSnapshot, CardStatus } from '@/data/contracts'
import { simulateLatency } from '@/data/mock/seed'
import { BankError } from '@/lib/bankError'
import { useBankMutation } from '@/lib/bankQuery'

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

/* ============================================================================
   useFreezeCard — toggle a card's status between 'active' and 'locked'.
   ============================================================================ */

export interface FreezeCardArgs {
  cardId: string
  freeze: boolean
}

export function useFreezeCard() {
  const qc = useQueryClient()

  return useMutation<BankCardMock, BankError, FreezeCardArgs, MutationContext>({
    mutationFn: async ({ cardId, freeze }) => {
      await simulateLatency(180, 360)
      const snap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
      const card = snap?.cards.find((c) => c.card_id === cardId)
      if (!card) {
        throw new BankError({
          code: 'CARD_NOT_FOUND',
          category: 'not_found',
          message: 'No se encontró la tarjeta',
          retryable: false,
        })
      }
      const newStatus: CardStatus = freeze ? 'locked' : 'active'
      return { ...card, status: newStatus }
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
    onSettled: () => {
      qc.invalidateQueries({ queryKey: queryKeys.cards.all() })
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

export function useUpdateCardLimits() {
  const qc = useQueryClient()

  return useMutation<BankCardMock, BankError, UpdateCardLimitsArgs, MutationContext>({
    mutationFn: async (args) => {
      await simulateLatency(220, 420)
      // Mock validation: monthly must be >= daily.
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
      return {
        ...card,
        daily_limit_minor: args.daily_limit_minor,
        monthly_limit_minor: args.monthly_limit_minor,
      }
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
    onSettled: () => {
      qc.invalidateQueries({ queryKey: queryKeys.cards.all() })
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
  card_type: 'debit' | 'virtual'
  spend_limit_minor?: number
}

export interface IssueCardResult {
  card_id: string
  masked_number: string
  card_type: 'debit' | 'virtual'
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
  )
}

/* ============================================================================
   useApplyCardDesign — change the visual design of an existing card.
   ============================================================================ */

export interface ApplyCardDesignArgs {
  cardId: string
  designId: string
}

export function useApplyCardDesign() {
  const qc = useQueryClient()

  return useMutation<BankCardMock, BankError, ApplyCardDesignArgs, MutationContext>({
    mutationFn: async ({ cardId, designId }) => {
      await simulateLatency(160, 340)
      const snap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
      const card = snap?.cards.find((c) => c.card_id === cardId)
      if (!card) {
        throw new BankError({
          code: 'CARD_NOT_FOUND',
          category: 'not_found',
          message: 'No se encontró la tarjeta',
          retryable: false,
        })
      }
      return { ...card, design_id: designId }
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
      qc.invalidateQueries({ queryKey: queryKeys.cards.all() })
    },
  })
}
