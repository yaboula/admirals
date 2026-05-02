-- =============================================================================
-- Admirals Bank — client/smoke.lua  (S1.1 smoke test helpers, dev-only)
--
-- Comandos client-side para ejecutar el smoke test §5-§7 de
-- scripts/smoke_test_s1_1.md vía round-trip real ox_lib callback.
--
-- Gated por ACE permission `command.admirals_bank_smoke` — añadir en server.cfg:
--   add_ace identifier.<tu_identifier> command.admirals_bank_smoke allow
-- o para dev sin restricciones:
--   add_ace builtin.everyone command.admirals_bank_smoke allow
--
-- POST-SMOKE: remover este file de fxmanifest client_scripts y borrarlo.
-- Es infraestructura desechable de S1.1 — no debe sobrevivir al sprint.
--
-- Comandos (chat F8 NO funciona — usar T chat in-game):
--   /smoke_balance               → C001 sin args (default: tu IBAN personal).
--   /smoke_balance_iban <iban>   → C001 con IBAN específico (test §6 unauthorized).
--   /smoke_balance_burst         → 31 calls back-to-back (test §7 rate limit).
-- =============================================================================

local function _print(color, msg)
  -- Print al chat client + console F8.
  TriggerEvent('chat:addMessage', {
    color = color,
    multiline = true,
    args = { '[smoke]', msg },
  })
  print(string.format('[smoke] %s', msg))
end

local function _green(msg) _print({ 0, 200, 0 }, msg) end
local function _red(msg)   _print({ 220, 30, 30 }, msg) end
local function _yellow(msg) _print({ 230, 180, 0 }, msg) end

-- ----------------------------------------------------------------------------
-- /smoke_balance — happy path (paso 5).
-- ----------------------------------------------------------------------------
RegisterCommand('smoke_balance', function()
  _yellow('Calling admirals:bank:getBalance with no args...')
  local result = lib.callback.await('admirals:bank:getBalance', false, {})
  if type(result) ~= 'table' then
    _red('FAIL: callback returned non-table: ' .. tostring(result))
    return
  end
  _yellow('Response: ' .. json.encode(result))
  if result.success and result.data then
    _green(string.format('OK iban=%s balance=%s currency=%s tier=%s',
      result.data.iban, tostring(result.data.balance),
      result.data.currency, result.data.tier))
  else
    _red('FAIL error_code=' .. tostring(result.error_code))
  end
end)

-- ----------------------------------------------------------------------------
-- /smoke_balance_iban <iban> — unauthorized test (paso 6).
-- ----------------------------------------------------------------------------
RegisterCommand('smoke_balance_iban', function(_, args)
  local iban = args and args[1]
  if not iban or iban == '' then
    _red('Usage: /smoke_balance_iban AD-XXXX-XXXX-XXXX')
    return
  end
  _yellow('Calling admirals:bank:getBalance with iban=' .. iban .. '...')
  local result = lib.callback.await('admirals:bank:getBalance', false, { iban = iban })
  if type(result) ~= 'table' then
    _red('FAIL: callback returned non-table: ' .. tostring(result))
    return
  end
  _yellow('Response: ' .. json.encode(result))
  if result.success then
    _green(string.format('OK iban=%s balance=%s', result.data.iban, tostring(result.data.balance)))
  elseif result.error_code == 'NOT_AUTHORIZED' then
    _green('EXPECTED NOT_AUTHORIZED ✅ (paso §6 PASS)')
  else
    _red('UNEXPECTED error_code=' .. tostring(result.error_code))
  end
end)

-- ----------------------------------------------------------------------------
-- /smoke_balance_burst — rate limit test (paso 7).
--
-- 31 iteraciones SECUENCIALES await — bucket bank.read default 30/10s →
-- esperado: 30 OK + 1 RATE_LIMITED. await es bloqueante per call con
-- timeout 2000 ms; total ~1-2s real-time, dentro del window 10s del bucket.
-- ----------------------------------------------------------------------------
RegisterCommand('smoke_balance_burst', function()
  _yellow('Burst 31 calls back-to-back (rate limit bank.read = 30/10s)...')
  local ok_count, blocked_count, other_count = 0, 0, 0
  local started = GetGameTimer()
  for i = 1, 31 do
    local r = lib.callback.await('admirals:bank:getBalance', false, {})
    if type(r) == 'table' then
      if r.success then
        ok_count = ok_count + 1
      elseif r.error_code == 'RATE_LIMITED' then
        blocked_count = blocked_count + 1
      else
        other_count = other_count + 1
      end
    else
      other_count = other_count + 1
    end
  end
  local elapsed = GetGameTimer() - started
  local summary = string.format('OK=%d BLOCKED=%d OTHER=%d (elapsed=%dms)',
    ok_count, blocked_count, other_count, elapsed)
  if ok_count == 30 and blocked_count >= 1 then
    _green('PASS ' .. summary)
  else
    _red('FAIL ' .. summary)
  end
end)

print('^5[admirals_bank smoke client] ready — /smoke_balance, /smoke_balance_iban <iban>, /smoke_balance_burst^7')
