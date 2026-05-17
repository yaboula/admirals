/**
 * SONAR Bank App — banker/data/contractsF4.ts
 * --------------------------------------------------------------------------
 * Phase 4: branding editor.
 */

export type BankerBrandingField =
  | 'bank_name'
  | 'primary_color'
  | 'accent_color'
  | 'welcome_message'
  | 'logo_url'

export interface BankerBrandingFieldState {
  effective: string
  default: string
  override_raw: string | null
  has_override: boolean
  updated_at_ms: number | null
  updated_by: string | null
  updated_by_role: string | null
}

export interface BankerBrandingSnapshotResponse {
  fields: Record<BankerBrandingField, BankerBrandingFieldState>
  can_edit: boolean
  role: string
  fetched_at_ms: number
}

export type BankerBrandingSetRequest = {
  field: BankerBrandingField
  value: string
} & Record<string, unknown>

export type BankerBrandingResetRequest = {
  field: BankerBrandingField
} & Record<string, unknown>

export interface BankerBrandingMutationResponse {
  field: BankerBrandingField
  value?: string
  reset?: boolean
  applied_at_ms?: number
}
