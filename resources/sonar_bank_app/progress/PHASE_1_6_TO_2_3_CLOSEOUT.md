# SONAR Bank App — Phase 1.6 to 2.3 Closeout

## Scope completed

- Phase 1.6 Compliance backend endpoint
- Phase 2.1 Recipients persistence
- Phase 2.2 Savings transfer flow
- Phase 2.3 Accounts self-management + KYC

## Implemented changes

### Phase 1.6 Compliance

- Added `sonar:bank:compliance:flags` backend callback in `server/callbacks/govt.lua`.
- Added `Repo.ListComplianceFlags` and SQL filtering in `server/repos/govt.lua`.
- Added compliance flag mapping in `server/services/govt_service.lua` for the frontend `ComplianceFlag` contract.

### Phase 2.1 Recipients

- Added real frontend recipient mutations in `web-src/src/data/mutations/recipients.ts`.
- Exported recipient hooks from `web-src/src/data/mutations/index.ts`.
- Wired save, delete, and favorite actions in `web-src/src/routes/Transfer.tsx`.
- Added saved-recipient merge behavior in `server/services/recipients_service.lua`.
- Added mock handlers for recipient mutations in `web-src/src/data/mock/register.ts`.

### Phase 2.2 Savings

- Enabled real `savings` reads/writes in `server/repos/accounts.lua`.
- Added `server/migrations/037_sonar_bank_savings.sql`.
- Added `savings` column setup to `install.sql`.
- Added frontend `useSavingsTransferMutation` in `web-src/src/data/mutations/transfers.ts`.
- Wired Guardar/Retirar controls in `web-src/src/routes/Accounts.tsx`.
- Added C007/C008 mock handlers in `web-src/src/data/mock/register.ts`.
- Preserved correlation flow in C007/C008 backend callback/service responses.

### Phase 2.3 Accounts + KYC

- Added `web-src/src/data/mutations/accounts.ts` with account open, freeze, unfreeze, close, and KYC submit hooks.
- Exported account/KYC hooks from `web-src/src/data/mutations/index.ts`.
- Wired account self-management actions in `web-src/src/routes/Accounts.tsx`.
- Added mock handlers for account lifecycle and KYC submit.
- Added account close correlation propagation in backend account callback/service.

## Validation evidence

- `npm run typecheck` passed.
- `npm run build` passed.
- `git diff --check` passed.

## Runtime notes

- The new savings DB column requires applying `server/migrations/037_sonar_bank_savings.sql` or using the updated `install.sql` on fresh install.
- Runtime FiveM resource is junctioned to this workspace, so code changes apply to runtime after resource restart.

## Remaining follow-up

- Phase 3/live runtime evidence can be collected through FXServer after applying the savings migration and restarting `sonar_bank_app`.
