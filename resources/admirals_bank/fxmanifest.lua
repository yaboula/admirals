fx_version 'cerulean'
game      'gta5'
lua54     'yes'

author      'Admirals'
version     '0.2.0'
description 'Admirals Bank — IBAN accounts, ledger movements, banking callbacks (C001 + C002). Sprint S1.'

dependencies {
  'oxmysql',
  'admirals_bridges',
  'admirals_core',
  'ox_lib',  -- lib.callback.register para C001 getBalance
}

-- =============================================================================
-- Load order rationale (S1.1 scope: solo C001 getBalance + EnsureStarterAccount):
--
--   shared:
--     1. config.lua             — starter balance, IBAN config, audit categories.
--
--   server (strict order):
--     2. @admirals_core/lib/admirals.lua   — helper API en VM admirals_bank.
--                                            Expone Admirals.{Core,DB,Bus,Rate,
--                                            Log,Metrics,Identity}.* delegando
--                                            via exports.admirals_core.
--     3. @ox_lib/init.lua       — lib.callback global (en VM admirals_bank).
--     4. server/iban.lua        — IBAN.Generate + IBAN.Validate + checksum
--                                 (sin DB deps — pure functions).
--     5. server/accounts.lua    — Accounts.EnsureStarterAccount + GetByIban +
--                                 GetByOwnerCitizenId (DB queries via Admirals.DB).
--     6. server/callbacks.lua   — lib.callback.register('admirals:bank:getBalance')
--                                 + futuras C002-C005 (placeholders S1.2/S1.3).
--     7. server/init.lua        — Boot orchestration (LAST):
--                                 a. Wait Admirals.Core.WaitReady (30s).
--                                 b. Register Identity.OnPlayerLoaded → EnsureStarterAccount.
--                                 c. Register rate buckets (bank.read ya default
--                                    en admirals_core/config.lua line 122-126;
--                                    no re-registramos).
--                                 d. Mark Bank._ready + emit admirals:bank:ready.
--
--   client_scripts (S1.2 SMOKE TEST TEMPORAL — DELETE post sign-off):
--     - @ox_lib/init.lua    — lib.callback.await en client.
--     - client/smoke.lua    — 5 commands /smoke_transfer* para harness manual
--                             founder smoke 10 pasos. Disposable infrastructure.
--                             Se elimina en cleanup commit S1.2 final.
-- =============================================================================

shared_scripts {
  'config.lua',
}


server_scripts {
  -- oxmysql global helper — necesario porque admirals_bank usa Admirals.DB
  -- which delegates to admirals_core's MySQL helper, but ox_lib callback
  -- transactions y admirals_core's DB.Transaction expect MySQL.* available.
  -- Actually: Admirals.DB delegates 100% via exports — no MySQL.* needed here.
  -- Removed for cleanliness.

  -- Helper lib admirals_core (cargada en VM admirals_bank):
  '@admirals_core/lib/admirals.lua',

  -- ox_lib (lib.callback en server):
  '@ox_lib/init.lua',

  -- Domain layer (depend on Admirals.* helper).
  -- Order strict:
  --   iban       — pure functions, no deps domain (DB only).
  --   accounts   — depends on IBAN.
  --   movements  — DB helpers sobre admirals_bank_movements (S1.2).
  --   events     — Bus.Publish wrappers (S1.2). Depends Admirals.Bus only.
  --   transfer   — Transfer.Execute. Depends Accounts + IBAN + DB + Events.
  --   callbacks  — C001 (S1.1) + C002 (S1.2). Depends Transfer + Accounts.
  'server/iban.lua',
  'server/accounts.lua',
  'server/movements.lua',
  'server/events.lua',
  'server/transfer.lua',
  'server/callbacks.lua',

  -- Boot orchestration (LAST).
  'server/init.lua',
}

-- =============================================================================
-- S1.2 SMOKE TEST TEMPORAL — DELETE post sign-off (cleanup commit separado).
-- 5 client commands: /smoke_transfer /smoke_transfer_replay /smoke_transfer_self
-- /smoke_transfer_overdraw /smoke_transfer_burst.
-- =============================================================================
client_scripts {
  '@ox_lib/init.lua',
  'client/smoke.lua',
}
