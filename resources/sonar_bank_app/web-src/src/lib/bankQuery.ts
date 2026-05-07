import { useMutation, useQuery, type QueryKey, type UseMutationOptions, type UseQueryOptions } from '@tanstack/react-query'
import { BankError } from '@/lib/bankError'
import { withBankIdempotency, type BankIdempotencyPolicy } from '@/lib/bankIdempotency'
import { nuiMutate, nuiQuery, type NuiFetchOptions } from '@/lib/nui'

export function shouldRetryBankError(failureCount: number, err: BankError): boolean {
  if (err instanceof BankError && err.retryable === false) return false
  return failureCount < 2
}

export type BankCallbackOptions<TResponse, TQueryKey extends QueryKey> = Omit<
  UseQueryOptions<TResponse, BankError, TResponse, TQueryKey>,
  'queryKey' | 'queryFn'
>

export type BankMutationOptions<TResponse, TVariables, TContext = unknown> = Omit<
  UseMutationOptions<TResponse, BankError, TVariables, TContext>,
  'mutationFn'
>

export interface BankMutationNuiOptions extends NuiFetchOptions {
  idempotency?: BankIdempotencyPolicy
}

export async function bankCallback<TPayload extends Record<string, unknown>, TResponse>(
  eventName: string,
  payload?: TPayload,
  options: NuiFetchOptions = {},
): Promise<TResponse> {
  return nuiQuery<TResponse>(eventName, payload ?? {}, options)
}

export async function bankMutation<TVariables extends Record<string, unknown>, TResponse>(
  eventName: string,
  payload: TVariables,
  options: BankMutationNuiOptions = {},
): Promise<TResponse> {
  const { idempotency = false, ...nuiOptions } = options
  const nextPayload = withBankIdempotency(payload, idempotency)
  return nuiMutate<TResponse>(eventName, nextPayload, nuiOptions)
}

export function useBankCallback<
  TResponse,
  TPayload extends Record<string, unknown> = Record<string, unknown>,
  TQueryKey extends QueryKey = QueryKey,
>(
  eventName: string,
  queryKey: TQueryKey,
  payload?: TPayload,
  options: BankCallbackOptions<TResponse, TQueryKey> = {},
  nuiOptions: NuiFetchOptions = {},
) {
  return useQuery<TResponse, BankError, TResponse, TQueryKey>({
    queryKey,
    queryFn: () => bankCallback<TPayload, TResponse>(eventName, payload, nuiOptions),
    staleTime: 30_000,
    gcTime: 5 * 60_000,
    retry: shouldRetryBankError,
    refetchOnWindowFocus: false,
    ...options,
  })
}

export function useBankMutation<
  TResponse,
  TVariables extends Record<string, unknown> = Record<string, unknown>,
  TContext = unknown,
>(
  eventName: string,
  options: BankMutationOptions<TResponse, TVariables, TContext> = {},
  nuiOptions: BankMutationNuiOptions = {},
) {
  return useMutation<TResponse, BankError, TVariables, TContext>({
    mutationFn: (payload) => bankMutation<TVariables, TResponse>(eventName, payload, nuiOptions),
    retry: 0,
    ...options,
  })
}
