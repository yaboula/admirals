BankApp.services.risk_engine = {}
local S = BankApp.services.risk_engine

local Repo = BankApp.repos.govt
local Config = BankApp.Config

local RISK = Config.RiskScore

local function encode_json(value)
  if json and json.encode then return json.encode(value) end
  return tostring(value)
end

local function level_for_score(score)
  if score >= RISK.LEVELS.CRITICAL then return 'critical' end
  if score >= RISK.LEVELS.HIGH then return 'high' end
  if score >= RISK.LEVELS.MEDIUM then return 'medium' end
  return 'low'
end

local function compute_from_metrics(metrics)
  local max_outgoing = tonumber(metrics.max_outgoing_amount) or 0
  local outgoing_5m = tonumber(metrics.outgoing_5m_count) or 0
  local frozen_destinations = tonumber(metrics.frozen_destination_count) or 0

  local velocity_score = 0
  local compliance_score = 0
  local exposure_score = 12
  local flag_score = 0
  local dormancy_score = 0
  local rules = {}

  if max_outgoing > RISK.HIGH_SINGLE_OUTGOING_MINOR then
    exposure_score = 80
    flag_score = 70
    rules[#rules + 1] = {
      severity = 'high',
      flag_type = 'large_transfer',
      threshold_value = RISK.HIGH_SINGLE_OUTGOING_MINOR,
      observed_value = max_outgoing,
      time_window_seconds = RISK.DAILY_WINDOW_SECONDS,
      summary = ('single outgoing transfer above %d'):format(RISK.HIGH_SINGLE_OUTGOING_MINOR),
    }
  end

  if outgoing_5m >= RISK.MEDIUM_WINDOW_COUNT then
    velocity_score = math.max(velocity_score, 55)
    flag_score = math.max(flag_score, 45)
    rules[#rules + 1] = {
      severity = 'medium',
      flag_type = 'velocity',
      threshold_value = RISK.MEDIUM_WINDOW_COUNT,
      observed_value = outgoing_5m,
      time_window_seconds = RISK.MEDIUM_WINDOW_SECONDS,
      summary = 'three or more outgoing transfers inside five minutes',
    }
  end

  if frozen_destinations > 0 then
    compliance_score = math.max(compliance_score, 55)
    flag_score = math.max(flag_score, 45)
    rules[#rules + 1] = {
      severity = 'medium',
      flag_type = 'structuring',
      threshold_value = 1,
      observed_value = frozen_destinations,
      time_window_seconds = RISK.DAILY_WINDOW_SECONDS,
      summary = 'outgoing transfer to frozen or suspicious account',
    }
  end

  if #rules == 0 then
    exposure_score = 12
    rules[#rules + 1] = {
      severity = 'low',
      flag_type = nil,
      threshold_value = 0,
      observed_value = 12,
      time_window_seconds = RISK.DAILY_WINDOW_SECONDS,
      summary = 'daily-pattern anomaly placeholder fixed score',
    }
  end

  local score = math.max(velocity_score, compliance_score, exposure_score, flag_score, dormancy_score)
  return {
    score = score,
    risk_level = level_for_score(score),
    velocity_score = velocity_score,
    compliance_score = compliance_score,
    exposure_score = exposure_score,
    flag_score = flag_score,
    dormancy_score = dormancy_score,
    rules = rules,
  }
end

local function db_severity(severity)
  if severity == 'high' or severity == 'critical' then return 'critical' end
  if severity == 'medium' then return 'warning' end
  if severity == 'low' then return 'notice' end
  return 'info'
end

function S.RecomputeCitizen(cid, computed_by)
  local metrics, err = Repo.GetRiskMetrics(cid)
  if err then return nil, err end
  if not metrics or not metrics.account_uuid then return nil, nil end

  local computed = compute_from_metrics(metrics)
  local components = {
    formula = RISK.FORMULA_VERSION,
    max_outgoing_amount = tonumber(metrics.max_outgoing_amount) or 0,
    outgoing_5m_count = tonumber(metrics.outgoing_5m_count) or 0,
    frozen_destination_count = tonumber(metrics.frozen_destination_count) or 0,
    rules = computed.rules,
  }

  local _, upsert_err = Repo.UpsertRiskScore({
    account_uuid = metrics.account_uuid,
    score = computed.score,
    risk_level = computed.risk_level,
    velocity_score = computed.velocity_score,
    compliance_score = computed.compliance_score,
    exposure_score = computed.exposure_score,
    flag_score = computed.flag_score,
    dormancy_score = computed.dormancy_score,
    components_json = encode_json(components),
    computed_by = computed_by or 'system',
  })
  if upsert_err then return nil, upsert_err end

  for _, rule in ipairs(computed.rules) do
    if rule.flag_type then
      Repo.InsertFlagIfMissing({
        flag_type = rule.flag_type,
        severity = db_severity(rule.severity),
        account_uuid = metrics.account_uuid,
        bank_account_id = metrics.primary_bank_account_id,
        threshold_value = rule.threshold_value,
        observed_value = rule.observed_value,
        time_window_seconds = rule.time_window_seconds,
        evidence = encode_json({ summary = rule.summary, formula = RISK.FORMULA_VERSION }),
      })
    end
  end

  return {
    cid = cid,
    score = computed.score,
    riskLevel = computed.risk_level,
    components = components,
  }, nil
end

return S
