# Round 1: Silent Transfer Failure - Debug Summary

**Fecha**: 2026-05-11
**Objetivo**: Debug y fix de fallo silencioso en transferencias (UI success, DB no persistía)
**Resultado**: ÉXITO ROTUNDO - Core financiero Sonar Bank operativo en producción

---

## Bugs Identificados y Soluciones

### BUG 1: Database Collation Mismatch
**Síntoma**: Balance incorrecto en dashboard debido a collation mismatch en join condition
**Causa**: `sonar_accounts.char_id` era `utf8mb4_uca1400_ai_ci` vs QBCore `citizenid` `utf8mb4_unicode_ci`
**Solución**:
- Created migration `034_fix_sonar_accounts_collation.sql` para cambiar collation a `utf8mb4_unicode_ci`
- Added migration to `sonar_core/config.lua` migrations list
**Archivos**: `resources/sonar_core/migrations/034_fix_sonar_accounts_collation.sql`, `resources/sonar_core/config.lua`

### BUG 2: IBAN Validation Rejected SONAR Format
**Síntoma**: Frontend rechazaba IBANs SONAR formato `AD-XXXX-XXXX-XXXX`
**Causa**: Regex validaba formato español en lugar de SONAR
**Solución**:
- Updated regex from `SPANISH_IBAN_RE` to `SONAR_IBAN_RE` (`/^AD-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/`)
- Updated `formatIban()` para preservar formato con dashes
- Renamed `isValidSpanishIban` to `isValidSonarIban`
**Archivos**: `resources/sonar_bank_app/web-src/src/data/mutations/transfers.ts`, `resources/sonar_bank_app/web-src/src/data/mutations/index.ts`, `resources/sonar_bank_app/web-src/src/routes/Transfer.tsx`

### BUG 3: ox_lib Missing from Server-Side
**Síntoma**: Server callbacks usaban fallback event bus (no ox_lib)
**Causa**: ox_lib no estaba en fxmanifest dependencies
**Solución**:
- Added `ox_lib` to fxmanifest.lua dependencies
- Added `ensure ox_lib` to server.cfg
**Archivos**: `resources/sonar_bank_app/fxmanifest.lua`, `d:\FiveM_Server\Sonar\server.cfg`

### BUG 4: Frontend Mock-Only Transfer
**Síntoma**: Transferencias solo hacían optimistic updates, no llamaban servidor
**Causa**: Mutation era mock-only, sin llamada real a backend
**Solución**:
- Replaced mock implementation con `useBankMutation` para llamada real a servidor
**Archivos**: `resources/sonar_bank_app/web-src/src/data/mutations/transfers.ts`

### BUG 5: ox_lib Missing from Client-Side
**Síntoma**: Client NUI bridge usaba fallback (404 en fetch)
**Causa**: ox_lib no estaba en client_scripts
**Solución**:
- Added `@ox_lib/init.lua` to client_scripts en fxmanifest.lua
**Archivos**: `resources/sonar_bank_app/fxmanifest.lua`

### BUG 6: ox_lib Not Loaded in Server Context
**Síntoma**: Server registration fallaba a event bus (ox_lib no detectado)
**Causa**: ox_lib no estaba en server_scripts (solo dependencies)
**Solución**:
- Added `@ox_lib/init.lua` to server_scripts (primer en load order)
**Archivos**: `resources/sonar_bank_app/fxmanifest.lua`

### BUG 7: Transfer Used fetch() Instead of NUI Bridge
**Síntoma**: Transfer mutation usaba `fetch()` directo → 404 Not Found
**Causa**: Implementación incorrecta usaba HTTP fetch en lugar de NUI bridge
**Solución**:
- Replaced `fetch()` con `useBankMutation` que usa `nuiMutate` (NUI bridge)
- Removed unused imports and functions
- Fixed TypeScript errors
**Archivos**: `resources/sonar_bank_app/web-src/src/data/mutations/transfers.ts`

---

## Debug Logs Agregados

### Server Callback C006 (transfer.lua)
```lua
print(('[%s][C006] INVOKED src=%s citizen_id=%s from_iban=%s to_iban=%s amount_minor=%s'):format(
  BankApp.Config.Logging.PREFIX, tostring(src), tostring(citizen_id),
  tostring(payload.from_iban), tostring(payload.to_iban), tostring(payload.amount_minor)))
local result = TransferService.Execute({...})
print(('[%s][C006] RESULT ok=%s'):format(BankApp.Config.Logging.PREFIX, tostring(result.ok)))
```

### Server Callback C001 (bootstrap.lua)
```lua
print(('[%s][C001] INVOKED src=%s citizen_id=%s'):format(
  BankApp.Config.Logging.PREFIX, tostring(src), tostring(citizen_id)))
local snapshot, err = BootstrapService.BuildSnapshot(citizen_id)
if err then
  print(('[%s][C001] ERROR code=%s message=%s'):format(
    BankApp.Config.Logging.PREFIX, tostring(err.code), tostring(err.message)))
  return { ok = false, error = err }
end
print(('[%s][C001] SUCCESS accounts=%d'):format(
  BankApp.Config.Logging.PREFIX, #snapshot.accounts))
```

### Server Wrapper (_wrap.lua)
```lua
print(('[%s][WRAP] Registering callback: %s'):format(Config.Logging.PREFIX, name))
if _G.lib and _G.lib.callback and type(_G.lib.callback.register) == 'function' then
  print(('[%s][WRAP] Using ox_lib.callback.register for: %s'):format(Config.Logging.PREFIX, name))
  _G.lib.callback.register(name, fn)
  print(('[%s][WRAP] Successfully registered with ox_lib: %s'):format(Config.Logging.PREFIX, name))
  return true
end
```

### Client NUI Bridge (nui_bridge.lua)
```lua
print(('[%s] await_server_callback: event=%s'):format(PREFIX, event_name))
if _G.lib and _G.lib.callback and type(_G.lib.callback.await) == 'function' then
  print(('[%s] Using ox_lib callback.await'):format(PREFIX))
  return _G.lib.callback.await(event_name, false, payload)
end
print(('[%s] WARNING: ox_lib not loaded, using fallback'):format(PREFIX))
```

---

## Verificación Runtime (R1.I)

### Cliente (F8)
- NUI bridge usa `ox_lib callback.await` sin warnings de fallback
- Logs: `[[sonar_bank_app][nui_bridge]] await_server_callback: event=sonar:bank:transfer:execute`
- Logs: `[[sonar_bank_app][nui_bridge]] Using ox_lib callback.await`

### Servidor (txAdmin)
- Callback C006 invocado correctamente
- Logs: `[sonar_bank_app][C006] INVOKED src=1 citizen_id=FXD56242`
- Logs: `[sonar_bank_app][C006] RESULT ok=true`

### Base de Datos (MariaDB)
- Balance persistió correctamente: $2,500.00 → $2,450.00
- Tabla `sonar_bank_accounts` actualizada atómicamente

### UI (Frontend)
- Balance actualizado en tiempo real en dashboard
- Transferencia registrada en historial
- Recibo generado instantáneamente

---

## Commit

**Hash**: `9975b30`
**Mensaje**: `fix(bank-app): resolve silent transfer failure - ox_lib integration + DB collation + NUI bridge`

**Archivos modificados** (10 files, 136 insertions, 188 deletions):
- `resources/sonar_core/config.lua`
- `resources/sonar_core/migrations/034_fix_sonar_accounts_collation.sql` (new)
- `resources/sonar_bank_app/fxmanifest.lua`
- `resources/sonar_bank_app/client/nui_bridge.lua`
- `resources/sonar_bank_app/server/callbacks/_wrap.lua`
- `resources/sonar_bank_app/server/callbacks/bootstrap.lua`
- `resources/sonar_bank_app/server/callbacks/transfer.lua`
- `resources/sonar_bank_app/web-src/src/data/mutations/index.ts`
- `resources/sonar_bank_app/web-src/src/data/mutations/transfers.ts`
- `resources/sonar_bank_app/web-src/src/routes/Transfer.tsx`

---

## Lecciones Aprendidas

1. **Arquitectura sobre parches**: No aplicar "quick fixes" que introduzcan deuda técnica. Saneamiento arquitectónico profundo es más sostenible.

2. **Protocolos estandarizados**: Forzar integración nativa de ox_lib en ambos lados (client + server) en lugar de mantener fallbacks inestables.

3. **Debug logging sistemático**: Agregar logs en todos los puntos críticos del flujo (client bridge, server wrapper, callbacks) para rastrear ejecución.

4. **Validación de datos**: Collation mismatch en DB puede causar fallos silenciosos en joins. Verificar collations cross-framework.

5. **Consistencia frontend**: Unificar flujos de React bajo wrappers seguros (`useBankMutation`) en lugar de implementaciones ad-hoc con `fetch()`.

---

## Estado Final

**Core financiero Sonar Bank**: ✅ OPERATIVO EN PRODUCCIÓN

Todos los bugs de Round 1 resueltos. Sistema listo para próximas fases con la misma disciplina de "cero parches, soluciones de ingeniería".
