-- =============================================================================
-- SONAR Bank App — callbacks/banker.lua
-- =============================================================================
-- Bank Owner Panel callbacks (F1).
--
--   Auth model:
--     - require_admin = false (we don't want server-ACE checks here; the
--       BankerAuth library performs its own employee+capability check inside
--       each handler).
--     - tier = TIER_1_READ for read endpoints, TIER_2_WRITE for mutations.
--     - cb_id prefix 'B0xx' for telemetry segmentation in perf bucket.
--
--   Endpoints (F1 Foundation set):
--     B001  sonar:bank:banker:bootstrap            (snapshot)
--     B002  sonar:bank:banker:employees:list       (read)
--     B003  sonar:bank:banker:employees:hire       (write — capability)
--     B004  sonar:bank:banker:employees:fire       (write — capability)
--     B005  sonar:bank:banker:employees:setRole    (write — capability)
--     B006  sonar:bank:banker:employees:setSalary  (write — capability)
-- =============================================================================

local Wrap   = BankApp.callbacks._wrap
local Enums  = BankApp.lib.enums

local Bootstrap  = BankApp.services.banker.bootstrap
local Employees  = BankApp.services.banker.employees
local Dashboard  = BankApp.services.banker.dashboard
local Operations = BankApp.services.banker.operations
local Customers  = BankApp.services.banker.customers
local Rates      = BankApp.services.banker.rates
local Branding   = BankApp.services.banker.branding
local Compliance = BankApp.services.banker.compliance
local Missions   = BankApp.services.banker.missions

-- -----------------------------------------------------------------------------
-- B001 — banker:bootstrap
-- -----------------------------------------------------------------------------
Wrap.Register('sonar:bank:banker:bootstrap', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'B001',
}, function(src, citizen_id, payload)
  return Bootstrap.GetSnapshot({ src = src })
end)

-- -----------------------------------------------------------------------------
-- B002 — banker:employees:list
-- -----------------------------------------------------------------------------
Wrap.Register('sonar:bank:banker:employees:list', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'B002',
}, function(src, citizen_id, payload)
  return Employees.ListEmployees({
    src           = src,
    status        = payload.status,
    include_fired = payload.include_fired == true,
    limit         = payload.limit,
  })
end)

-- -----------------------------------------------------------------------------
-- B003 — banker:employees:hire
-- -----------------------------------------------------------------------------
Wrap.Register('sonar:bank:banker:employees:hire', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B003',
}, function(src, citizen_id, payload)
  return Employees.HireEmployee({
    src                = src,
    target_citizen_id  = payload.target_citizen_id,
    role               = payload.role,
    salary_minor       = payload.salary_minor,
    notes              = payload.notes,
  })
end)

-- -----------------------------------------------------------------------------
-- B004 — banker:employees:fire
-- -----------------------------------------------------------------------------
Wrap.Register('sonar:bank:banker:employees:fire', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B004',
}, function(src, citizen_id, payload)
  return Employees.FireEmployee({
    src         = src,
    employee_id = payload.employee_id,
    reason      = payload.reason,
  })
end)

-- -----------------------------------------------------------------------------
-- B005 — banker:employees:setRole
-- -----------------------------------------------------------------------------
Wrap.Register('sonar:bank:banker:employees:setRole', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B005',
}, function(src, citizen_id, payload)
  return Employees.SetRole({
    src         = src,
    employee_id = payload.employee_id,
    new_role    = payload.new_role,
  })
end)

-- -----------------------------------------------------------------------------
-- B006 — banker:employees:setSalary
-- -----------------------------------------------------------------------------
Wrap.Register('sonar:bank:banker:employees:setSalary', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B006',
}, function(src, citizen_id, payload)
  return Employees.SetSalary({
    src          = src,
    employee_id  = payload.employee_id,
    salary_minor = payload.salary_minor,
  })
end)

-- =============================================================================
-- F2 — Dashboard + Operations + Customers
-- =============================================================================

-- B010 — banker:dashboard:snapshot
Wrap.Register('sonar:bank:banker:dashboard:snapshot', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'B010',
}, function(src, citizen_id, payload)
  return Dashboard.GetSnapshot({ src = src, window_days = payload.window_days })
end)

-- B011 — banker:operations:queues
Wrap.Register('sonar:bank:banker:operations:queues', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'B011',
}, function(src, citizen_id, payload)
  return Operations.ListQueues({ src = src, limit = payload.limit })
end)

-- B012 — banker:operations:loan:decide
Wrap.Register('sonar:bank:banker:operations:loan:decide', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B012',
}, function(src, citizen_id, payload)
  return Operations.DecideLoan({
    src          = src,
    loan_id      = payload.loan_id,
    decision     = payload.decision,
    deposit_iban = payload.deposit_iban,
    reason       = payload.reason,
  })
end)

-- B013 — banker:operations:proAccount:decide
Wrap.Register('sonar:bank:banker:operations:proAccount:decide', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B013',
}, function(src, citizen_id, payload)
  return Operations.DecideProfessionalAccount({
    src         = src,
    approval_id = payload.approval_id,
    decision    = payload.decision,
    note        = payload.note,
  })
end)

-- B014 — banker:operations:kyc:decide
Wrap.Register('sonar:bank:banker:operations:kyc:decide', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B014',
}, function(src, citizen_id, payload)
  return Operations.DecideKyc({
    src               = src,
    target_citizen_id = payload.target_citizen_id,
    decision          = payload.decision,
    reason            = payload.reason,
  })
end)

-- B020 — banker:customers:search
Wrap.Register('sonar:bank:banker:customers:search', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'B020',
}, function(src, citizen_id, payload)
  return Customers.Search({
    src   = src,
    query = payload.query,
    limit = payload.limit,
  })
end)

-- B021 — banker:customers:detail
Wrap.Register('sonar:bank:banker:customers:detail', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'B021',
}, function(src, citizen_id, payload)
  return Customers.Detail({
    src        = src,
    citizen_id = payload.citizen_id,
  })
end)

-- B022 — banker:customers:freeze
Wrap.Register('sonar:bank:banker:customers:freeze', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B022',
}, function(src, citizen_id, payload)
  return Customers.Freeze({
    src    = src,
    iban   = payload.iban,
    reason = payload.reason,
  })
end)

-- B023 — banker:customers:unfreeze
Wrap.Register('sonar:bank:banker:customers:unfreeze', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B023',
}, function(src, citizen_id, payload)
  return Customers.Unfreeze({
    src    = src,
    iban   = payload.iban,
    reason = payload.reason,
  })
end)

-- =============================================================================
-- F3 — Rates / Fees / Limits editor
-- =============================================================================

-- B030 — banker:rates:catalog
Wrap.Register('sonar:bank:banker:rates:catalog', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'B030',
}, function(src, citizen_id, payload)
  return Rates.GetCatalog({ src = src })
end)

-- B031 — banker:rates:set
Wrap.Register('sonar:bank:banker:rates:set', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B031',
}, function(src, citizen_id, payload)
  return Rates.SetOverride({ src = src, key = payload.key, value = payload.value })
end)

-- B032 — banker:rates:reset
Wrap.Register('sonar:bank:banker:rates:reset', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B032',
}, function(src, citizen_id, payload)
  return Rates.ResetOverride({ src = src, key = payload.key })
end)

-- =============================================================================
-- F4 — Branding editor
-- =============================================================================

-- B040 — banker:branding:get
Wrap.Register('sonar:bank:banker:branding:get', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'B040',
}, function(src, citizen_id, payload)
  return Branding.GetSnapshot({ src = src })
end)

-- B041 — banker:branding:set
Wrap.Register('sonar:bank:banker:branding:set', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B041',
}, function(src, citizen_id, payload)
  return Branding.Set({ src = src, field = payload.field, value = payload.value })
end)

-- B042 — banker:branding:reset
Wrap.Register('sonar:bank:banker:branding:reset', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B042',
}, function(src, citizen_id, payload)
  return Branding.Reset({ src = src, field = payload.field })
end)

-- =============================================================================
-- F5 — Compliance flags review
-- =============================================================================

-- B050 — banker:compliance:list
Wrap.Register('sonar:bank:banker:compliance:list', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'B050',
}, function(src, citizen_id, payload)
  return Compliance.ListFlags({
    src      = src,
    status   = payload.status,
    severity = payload.severity,
    limit    = payload.limit,
  })
end)

-- B051 — banker:compliance:resolve
Wrap.Register('sonar:bank:banker:compliance:resolve', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B051',
}, function(src, citizen_id, payload)
  return Compliance.Resolve({
    src      = src,
    flag_id  = payload.flag_id,
    decision = payload.decision,
    note     = payload.note,
  })
end)

-- =============================================================================
-- F6 — Missions
-- =============================================================================

-- B060 — banker:missions:list
Wrap.Register('sonar:bank:banker:missions:list', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'B060',
}, function(src, citizen_id, payload)
  return Missions.ListMissions({ src = src, state = payload.state, limit = payload.limit })
end)

-- B061 — banker:missions:dispatch
Wrap.Register('sonar:bank:banker:missions:dispatch', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B061',
}, function(src, citizen_id, payload)
  return Missions.DispatchMission({
    src           = src,
    mission_type  = payload.mission_type,
    reward_minor  = payload.reward_minor,
    payload       = payload.payload,
  })
end)

-- B062 — banker:missions:assign
Wrap.Register('sonar:bank:banker:missions:assign', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B062',
}, function(src, citizen_id, payload)
  return Missions.AssignMission({ src = src, mission_id = payload.mission_id })
end)

-- B063 — banker:missions:complete
Wrap.Register('sonar:bank:banker:missions:complete', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'B063',
}, function(src, citizen_id, payload)
  return Missions.CompleteMission({ src = src, mission_id = payload.mission_id })
end)
