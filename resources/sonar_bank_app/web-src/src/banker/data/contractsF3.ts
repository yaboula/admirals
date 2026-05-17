/**
 * SONAR Bank App — banker/data/contractsF3.ts
 * --------------------------------------------------------------------------
 * Phase 3: rates / fees / limits editor.
 */

export interface BankerRateItem {
  key: string
  default: number
  min: number
  max: number
  step: number
  effective: number
  override_raw: number | null
  has_override: boolean
  updated_at_ms: number | null
  updated_by: string | null
  updated_by_role: string | null
}

export interface BankerRatesCatalogResponse {
  items: BankerRateItem[]
  role: string
  can_edit: boolean
  fetched_at_ms: number
}

export type BankerRateSetRequest = {
  key: string
  value: number
} & Record<string, unknown>

export type BankerRateResetRequest = {
  key: string
} & Record<string, unknown>

export interface BankerRateMutationResponse {
  key: string
  value?: number
  reset?: boolean
  no_op?: boolean
  applied_at_ms?: number
}
