/**
 * SONAR Bank App — banker/data/contractsF6.ts
 * --------------------------------------------------------------------------
 * Phase 6: missions.
 */

export type MissionType =
  | 'atm_refill'
  | 'card_production'
  | 'vault_audit'
  | 'loan_collection'
  | 'cash_transport_b2b'
  | 'document_delivery'

export type MissionState =
  | 'open'
  | 'assigned'
  | 'in_progress'
  | 'completed'
  | 'failed'
  | 'cancelled'

export interface BankerMission {
  mission_id: string
  mission_type: MissionType
  state: MissionState
  assigned_employee_id: string | null
  assigned_citizen_id: string | null
  reward_minor: number
  created_ms: number
  assigned_ms: number | null
  completed_ms: number | null
  failed_ms: number | null
  failure_reason: string | null
}

export interface BankerMissionCatalog {
  base_reward_minor: number
}

export interface BankerMissionsListResponse {
  items: BankerMission[]
  catalog: Record<MissionType, BankerMissionCatalog>
  can_dispatch: boolean
  can_accept: boolean
  role: string
  fetched_at_ms: number
}

export type BankerMissionDispatchRequest = {
  mission_type: MissionType
  reward_minor?: number
  payload?: Record<string, unknown>
} & Record<string, unknown>

export type BankerMissionMutationRequest = {
  mission_id: string
} & Record<string, unknown>

export interface BankerMissionMutationResponse {
  mission_id: string
  mission_type?: MissionType
  reward_minor?: number
  assigned_to?: string
  completed_at_ms?: number
}
