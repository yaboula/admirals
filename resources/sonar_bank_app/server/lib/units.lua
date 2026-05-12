BankApp.lib.units = {}
local M = BankApp.lib.units

local Errors = BankApp.lib.errors

local MAX_SAFE_MINOR = 9007199254740991

local function err(code, details)
  if Errors and Errors.New then return nil, Errors.New(code, details) end
  return nil, { code = code, details = details }
end

local function trim(value)
  return tostring(value):match('^%s*(.-)%s*$')
end

local function round_fraction(frac)
  frac = frac or ''
  local cents = (frac .. '00'):sub(1, 2)
  local third = tonumber((frac .. '000'):sub(3, 3)) or 0
  local value = tonumber(cents) or 0
  if third >= 5 then value = value + 1 end
  return value
end

function M.to_minor(value)
  if type(value) == 'number' then
    if value ~= value or value == math.huge or value == -math.huge then
      return err('INVALID_AMOUNT', { reason = 'not finite' })
    end
    value = string.format('%.6f', value)
  elseif type(value) ~= 'string' then
    return err('INVALID_AMOUNT', { reason = 'expected decimal string or number' })
  end

  local s = trim(value)
  local sign, whole, frac = s:match('^([+-]?)(%d+)%.?(%d*)$')
  if not whole then return err('INVALID_AMOUNT', { reason = 'invalid decimal format' }) end
  if #frac > 6 then return err('INVALID_AMOUNT', { reason = 'too many decimal places' }) end

  local major = tonumber(whole)
  if not major then return err('INVALID_AMOUNT', { reason = 'major out of range' }) end
  local minor = (major * 100) + round_fraction(frac)
  if sign == '-' then minor = -minor end
  if minor > MAX_SAFE_MINOR or minor < -MAX_SAFE_MINOR then
    return err('AMOUNT_OUT_OF_RANGE', { max_minor = MAX_SAFE_MINOR })
  end
  return math.floor(minor), nil
end

function M.from_minor(value)
  if type(value) ~= 'number' or value ~= math.floor(value) then
    return err('INVALID_AMOUNT', { reason = 'expected integer minor units' })
  end
  if value > MAX_SAFE_MINOR or value < -MAX_SAFE_MINOR then
    return err('AMOUNT_OUT_OF_RANGE', { max_minor = MAX_SAFE_MINOR })
  end
  local sign = value < 0 and '-' or ''
  local abs_value = math.abs(value)
  local major = math.floor(abs_value / 100)
  local cents = abs_value % 100
  return string.format('%s%d.%02d', sign, major, cents), nil
end

function M.normalize_minor(value)
  if type(value) ~= 'number' or value ~= math.floor(value) then
    return err('INVALID_AMOUNT', { reason = 'expected integer minor units' })
  end
  if value > MAX_SAFE_MINOR or value < -MAX_SAFE_MINOR then
    return err('AMOUNT_OUT_OF_RANGE', { max_minor = MAX_SAFE_MINOR })
  end
  return value, nil
end

function M.RunPropertyTests()
  local cases = {
    { '0', 0, '0.00' },
    { '0.01', 1, '0.01' },
    { '1', 100, '1.00' },
    { '1.2', 120, '1.20' },
    { '1.23', 123, '1.23' },
    { '1.234', 123, '1.23' },
    { '1.235', 124, '1.24' },
    { '-1.235', -124, '-1.24' },
    { '90071992547409.91', MAX_SAFE_MINOR, '90071992547409.91' },
  }
  for i, case in ipairs(cases) do
    local minor, minor_err = M.to_minor(case[1])
    if minor_err or minor ~= case[2] then
      return false, { case = i, stage = 'to_minor', expected = case[2], actual = minor, error = minor_err }
    end
    local decimal, decimal_err = M.from_minor(minor)
    if decimal_err or decimal ~= case[3] then
      return false, { case = i, stage = 'from_minor', expected = case[3], actual = decimal, error = decimal_err }
    end
  end
  for cents = -10000, 10000, 37 do
    local decimal = assert(M.from_minor(cents))
    local roundtrip = assert(M.to_minor(decimal))
    if roundtrip ~= cents then
      return false, { stage = 'roundtrip', cents = cents, decimal = decimal, roundtrip = roundtrip }
    end
  end
  return true, { cases = #cases, roundtrip_step = 37 }
end

return M
