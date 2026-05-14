import { useQueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import type { RecentRecipient, RecentRecipientsResponse } from '@/data/contracts'
import { useBankMutation } from '@/lib/bankQuery'
import { normalizeIban } from './transfers'

export interface RecipientSaveArgs extends Record<string, unknown> {
  counterpart_iban: string
  alias?: string | null
  is_favorite?: boolean
}

export interface RecipientDeleteArgs extends Record<string, unknown> {
  counterpart_iban: string
}

export interface RecipientFavoriteArgs extends Record<string, unknown> {
  counterpart_iban: string
  is_favorite: boolean
}

export interface RecipientSaveResponse {
  saved: boolean
  counterpart_iban: string
}

export interface RecipientDeleteResponse {
  deleted: boolean
  counterpart_iban: string
}

export interface RecipientFavoriteResponse {
  counterpart_iban: string
  is_favorite: boolean
}

function upsertRecipient(list: RecentRecipient[], args: RecipientSaveArgs): RecentRecipient[] {
  const iban = normalizeIban(args.counterpart_iban)
  const now = Date.now()
  const existing = list.find((recipient) => normalizeIban(recipient.counterpart_iban) === iban)
  const next: RecentRecipient = {
    counterpart_iban: iban,
    alias: args.alias?.trim() || existing?.alias || null,
    is_favorite: args.is_favorite ?? existing?.is_favorite ?? false,
    last_transfer_ms: existing?.last_transfer_ms ?? now,
    transfer_count: existing?.transfer_count ?? 0,
    preset_amounts: existing?.preset_amounts ?? [],
    last_reason: existing?.last_reason ?? null,
  }
  return [next, ...list.filter((recipient) => normalizeIban(recipient.counterpart_iban) !== iban)]
}

function patchRecentRecipients(
  previous: RecentRecipientsResponse | undefined,
  patcher: (recipients: RecentRecipient[]) => RecentRecipient[],
): RecentRecipientsResponse | undefined {
  if (!previous) return previous
  return {
    ...previous,
    recipients: patcher(previous.recipients),
    cached: false,
    fetched_at_ms: Date.now(),
  }
}

export function useSaveRecipientMutation() {
  const qc = useQueryClient()
  return useBankMutation<RecipientSaveResponse, RecipientSaveArgs, { previous?: RecentRecipientsResponse }>(
    'sonar:bank:recipients:save',
    {
      onMutate: async (args) => {
        await qc.cancelQueries({ queryKey: queryKeys.recipients.recent() })
        const previous = qc.getQueryData<RecentRecipientsResponse>(queryKeys.recipients.recent())
        qc.setQueryData<RecentRecipientsResponse | undefined>(
          queryKeys.recipients.recent(),
          patchRecentRecipients(previous, (recipients) => upsertRecipient(recipients, args)),
        )
        return { previous }
      },
      onError: (_err, _args, context) => {
        if (context?.previous) qc.setQueryData(queryKeys.recipients.recent(), context.previous)
      },
      onSettled: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.recipients.recent() })
      },
    },
  )
}

export function useDeleteRecipientMutation() {
  const qc = useQueryClient()
  return useBankMutation<RecipientDeleteResponse, RecipientDeleteArgs, { previous?: RecentRecipientsResponse }>(
    'sonar:bank:recipients:delete',
    {
      onMutate: async (args) => {
        await qc.cancelQueries({ queryKey: queryKeys.recipients.recent() })
        const previous = qc.getQueryData<RecentRecipientsResponse>(queryKeys.recipients.recent())
        const iban = normalizeIban(args.counterpart_iban)
        qc.setQueryData<RecentRecipientsResponse | undefined>(
          queryKeys.recipients.recent(),
          patchRecentRecipients(previous, (recipients) => recipients.filter((recipient) => normalizeIban(recipient.counterpart_iban) !== iban)),
        )
        return { previous }
      },
      onError: (_err, _args, context) => {
        if (context?.previous) qc.setQueryData(queryKeys.recipients.recent(), context.previous)
      },
      onSettled: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.recipients.recent() })
      },
    },
  )
}

export function useToggleRecipientFavoriteMutation() {
  const qc = useQueryClient()
  return useBankMutation<RecipientFavoriteResponse, RecipientFavoriteArgs, { previous?: RecentRecipientsResponse }>(
    'sonar:bank:recipients:toggleFavorite',
    {
      onMutate: async (args) => {
        await qc.cancelQueries({ queryKey: queryKeys.recipients.recent() })
        const previous = qc.getQueryData<RecentRecipientsResponse>(queryKeys.recipients.recent())
        const iban = normalizeIban(args.counterpart_iban)
        qc.setQueryData<RecentRecipientsResponse | undefined>(
          queryKeys.recipients.recent(),
          patchRecentRecipients(previous, (recipients) => recipients.map((recipient) => (
            normalizeIban(recipient.counterpart_iban) === iban
              ? { ...recipient, is_favorite: args.is_favorite }
              : recipient
          ))),
        )
        return { previous }
      },
      onError: (_err, _args, context) => {
        if (context?.previous) qc.setQueryData(queryKeys.recipients.recent(), context.previous)
      },
      onSettled: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.recipients.recent() })
      },
    },
  )
}
