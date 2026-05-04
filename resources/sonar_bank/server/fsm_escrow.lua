-- =============================================================================
-- SONAR Bank — server/fsm_escrow.lua
--
-- Table-driven FSM para `escrow_lifecycle` per SSoT `docs/technical/
-- 05_state_machines.md` §4.1.
--
-- Estados canónicos (ENUM `sonar_escrows.status`):
--   created, locked, released, refunded, disputed.
--
-- Transitions implementadas S1.3:
--   created   → locked    (happy path C004 createEscrow — S1.3 atomic INSERT
--                          direct con status='locked' en TX, NO persiste 'created'
--                          standalone. State 'created' existe en ENUM por
--                          compat FSM SSoT + posibles paths S2+ multi-step).
--   locked    → released  (C005 direction='seller' — funds a seller).
--   locked    → refunded  (C005 direction='buyer'  — funds a buyer).
--
-- Transitions NO implementadas S1.3 (deferred):
--   locked    → disputed     — requires sonar_contracts + dispute callbacks (S2+).
--   disputed  → released     — arbitration ruling seller-favor (S2+).
--   disputed  → refunded     — arbitration ruling buyer-favor  (S2+).
--   created   → locked atomic (alt multi-step)  — S2+ multi-sig flow.
--
-- API pública:
--   FSM.CanTransition(from, to)    → boolean
--     true si (from, to) está declarada en la tabla de transitions S1.3.
--
--   FSM.AllowedFrom(from)          → { to_state, ... }
--     Array de estados destino válidos desde `from` en S1.3.
--
--   FSM.ValidState(state)          → boolean
--     true si state ∈ {created, locked, released, refunded, disputed}.
--
--   FSM.IsTerminal(state)          → boolean
--     true si state ∈ {released, refunded}.
--     S1.3 NO tratamos 'disputed' como terminal (requires arbitration outcome).
--
-- Esta capa SOLO valida transitions + logs. Los side effects (DB UPDATE,
-- audit, Bus.Publish) son responsabilidad de `server/escrow.lua`.
--
-- Patrón alineado con S1.2 transfer pattern: FSM = data (tabla literal),
-- side effects = código llamante (Escrow.Create / Escrow.Release).
--
-- Referencias SSoT:
--   docs/technical/05_state_machines.md §4.1 (escrow_lifecycle states + transitions).
--   docs/technical/02_events_catalog.md §1.4 (schema eventos resultantes).
--   docs/technical/04_api_contracts.md §3.1 C004/C005 (callbacks que disparan transitions).
-- =============================================================================

SONAR = SONAR or {}
SONAR.Bank = SONAR.Bank or {}
SONAR.Bank.FSMEscrow = SONAR.Bank.FSMEscrow or {}

local FSM = SONAR.Bank.FSMEscrow

-- =============================================================================
-- Declarative — ENUM de estados válidos (SSoT §05 §4.1).
-- =============================================================================
local _VALID_STATES = {
  created   = true,
  locked    = true,
  released  = true,
  refunded  = true,
  disputed  = true,
}

-- Terminal states S1.3 — no admiten transition outgoing dentro del scope
-- implementado. 'disputed' NO es terminal canónico (requires arbitration S2+),
-- pero en S1.3 tampoco admite transitions → equivalente operacional terminal.
local _TERMINAL_S1_3 = {
  released = true,
  refunded = true,
}

-- =============================================================================
-- Declarative — transitions table.
--
-- Shape: _TRANSITIONS[from][to] = true (declarativo, no handler — handlers
-- viven en escrow.lua).
--
-- S1.3 scope: 3 transitions. Comment explica cada una + qué callback la dispara.
-- =============================================================================
local _TRANSITIONS = {
  -- created: estado inicial lógico. En S1.3 happy path, `Escrow.Create` inserta
  -- DIRECT con status='locked' dentro de la TX atómica (fondos ya reservados).
  -- Esta entry existe para validar que si un caller testea la transition
  -- created→locked la FSM la acepta (forward-compat multi-step S2+).
  created = {
    locked = true,
  },

  -- locked: estado de holding. Admite release a seller o buyer.
  -- S1.3 NO implementa locked→disputed (requires sonar_contracts + C006
  -- disputeContract callback, scope S2+).
  locked = {
    released = true,
    refunded = true,
    -- disputed = false en S1.3 — deliberate omission.
  },

  -- released / refunded: terminal states S1.3. NO outgoing transitions.
  released = {},
  refunded = {},

  -- disputed: no implementado S1.3. Entry vacía → CanTransition siempre
  -- retorna false si alguien intenta algo desde 'disputed'. Entries
  -- {disputed→released, disputed→refunded} se añadirán en S2+ junto con
  -- arbitration FSM (`dispute_lifecycle` per SSoT §4.5 pending).
  disputed = {},
}

-- =============================================================================
-- Public — ValidState.
--
-- @param state string
-- @return boolean
-- =============================================================================
function FSM.ValidState(state)
  return type(state) == 'string' and _VALID_STATES[state] == true
end

-- =============================================================================
-- Public — IsTerminal.
--
-- @param state string
-- @return boolean
-- =============================================================================
function FSM.IsTerminal(state)
  return type(state) == 'string' and _TERMINAL_S1_3[state] == true
end

-- =============================================================================
-- Public — CanTransition.
--
-- @param from string
-- @param to   string
-- @return ok:boolean, reason:string|nil
--
-- reason codes:
--   INVALID_FROM_STATE
--   INVALID_TO_STATE
--   TRANSITION_NOT_ALLOWED
-- =============================================================================
function FSM.CanTransition(from, to)
  if not FSM.ValidState(from) then return false, 'INVALID_FROM_STATE' end
  if not FSM.ValidState(to)   then return false, 'INVALID_TO_STATE' end

  local row = _TRANSITIONS[from]
  if not row or row[to] ~= true then
    return false, 'TRANSITION_NOT_ALLOWED'
  end
  return true, nil
end

-- =============================================================================
-- Public — AllowedFrom.
--
-- @param from string
-- @return table — array de to_state strings válidos desde `from`.
--                 Empty array si from no es valid state O es terminal.
-- =============================================================================
function FSM.AllowedFrom(from)
  local out = {}
  if not FSM.ValidState(from) then return out end

  local row = _TRANSITIONS[from]
  if not row then return out end

  for to_state, allowed in pairs(row) do
    if allowed == true then out[#out + 1] = to_state end
  end
  table.sort(out)  -- determinístico para logs/debug.
  return out
end

-- =============================================================================
-- Public — LogTransition (debug helper opcional para callers).
--
-- No-op en production; útil para trace de FSM en smoke/debug.
-- @param escrow_id string
-- @param from     string
-- @param to       string
-- @param context  table? — payload opcional para log entry.
-- =============================================================================
function FSM.LogTransition(escrow_id, from, to, context)
  SONAR.Log.Debug('FSMEscrow transition: escrow=%s %s→%s context=%s',
    escrow_id, from, to, tostring(context and json and json.encode(context) or ''))
  SONAR.Metrics.Counter(('bank.escrow.transition.%s_to_%s'):format(from, to))
end

-- =============================================================================
-- Boot announce.
-- =============================================================================
SONAR.Log.Info('FSMEscrow module ready (states=5, transitions S1.3=3: created→locked, locked→released|refunded)')
