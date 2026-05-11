fx_version 'cerulean'
game      'gta5'
lua54     'yes'

author      'SONAR'
version     '0.4.0'
description 'SONAR Bank — IBAN accounts, ledger movements, escrow FSM, banking callbacks (C001 + C002 + C004 + C005). Sprint S1 closed.'

dependencies {
  'oxmysql',
  'sonar_bridges',
  'sonar_core',
}

-- =============================================================================
-- Load order rationale (S1.1 scope: solo C001 getBalance + EnsureStarterAccount):
--
--   shared:
--     1. config.lua             — starter balance, IBAN config, audit categories.
--
--   server (strict order):
--     2. @sonar_core/lib/sonar.lua         — helper API en VM sonar_bank.
--                                            Expone SONAR.{Core,DB,Bus,Rate,
--                                            Log,Metrics,Identity}.* delegando
--                                            via exports.sonar_core.
--     3. server/iban.lua        — IBAN.Generate + IBAN.Validate + checksum
--                                 (sin DB deps — pure functions).
--     4. server/accounts.lua    — Accounts.EnsureStarterAccount + GetByIban +
--                                 GetByOwnerCitizenId (DB queries via SONAR.DB).
--     5. server/callbacks.lua   — callback bus register('sonar:bank:getBalance')
--                                 + futuras C002-C005 (placeholders S1.2/S1.3).
--     6. server/movements.lua    — DB helpers sobre sonar_bank_movements (S1.2).
--     7. server/events.lua      — Bus.Publish wrappers (S1.2). Depends SONAR.Bus only.
--     8. server/transfer.lua    — Transfer.Execute. Depends Accounts + IBAN + DB + Events.
--     9. server/fsm_escrow.lua  — S1.3 escrow layer (fsm_escrow pure-logic, escrow depends FSM+Accounts+IBAN+Events):
--     10. server/escrow.lua     —
--     11. server/init.lua       — Boot orchestration (LAST):
--                                 a. Wait SONAR.Core.WaitReady (30s).
--                                 b. Register Identity.OnPlayerLoaded → EnsureStarterAccount.
--                                 c. Register rate buckets (bank.read ya default
--                                    en sonar_core/config.lua line 122-126;
--                                    no re-registramos).
--                                 d. Mark Bank._ready + emit sonar:bank:ready.
--
--   No client_scripts (callbacks server-side; client UI llega
--   S1.5+ con sonar_tablet).
-- =============================================================================

shared_scripts {
  'config.lua',
}


server_scripts {
  -- Helper lib sonar_core (cargada en VM sonar_bank):
  '@sonar_core/lib/sonar.lua',

  -- Callback bus:
  -- Domain layer (depend on SONAR.* helper).
  -- Order strict:
  --   iban       — pure functions, no deps domain (DB only).
  --   accounts   — depends on IBAN.
  --   movements  — DB helpers sobre sonar_bank_movements (S1.2).
  --   events     — Bus.Publish wrappers (S1.2). Depends SONAR.Bus only.
  --   transfer   — Transfer.Execute. Depends Accounts + IBAN + DB + Events.
  --   callbacks  — C001 (S1.1) + C002 (S1.2). Depends Transfer + Accounts.
  'server/iban.lua',
  'server/accounts.lua',
  'server/movements.lua',
  'server/events.lua',
  'server/transfer.lua',
  -- S1.3 escrow layer (fsm_escrow pure-logic, escrow depends FSM+Accounts+IBAN+Events):
  'server/fsm_escrow.lua',
  'server/escrow.lua',
  -- Callbacks (depend on Transfer + Escrow).
  'server/callbacks.lua',

  -- Boot orchestration (LAST).
  'server/init.lua',

  -- Admin / smoke harness commands (DEV ONLY — gated por convar `sonar_dev_mode 1`
  -- + ACE `sonar.admin`). Replaces deleted-per-sprint client/smoke_*.lua pattern
  -- post Phase 8 rename. Carga LAST porque depende de modules + Bank.Version().
  -- Si convar ausente, file no-op silent (return early).
  'server/admin_commands.lua',

  -- Smoke Chaos Test Harness (DEV ONLY — BANK-DO.1 regression tests ST-001 to ST-007)
  'server/smoke_chaos.lua',

  -- Smoke Chaos Matrix (DEV ONLY — BANK-DO.2 chaos tests ST-008 to ST-030)
  'server/smoke_chaos_chaos.lua',

  -- Smoke Chaos Advanced (DEV ONLY — BANK-DO.2 Fase 2 advanced chaos tests ST-018 to ST-022+)
  -- Requires smoke_chaos_chaos.lua loaded first for baseline modules (ChaosFixtures + ChaosConcurrency)
  'server/smoke_chaos_advanced.lua',
}

-- No client_scripts (callbacks server-side; client UI llega
-- S1.5+ con sonar_tablet).
