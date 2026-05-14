# Security Risk Formula Review Request — Fase 1.6

## Status

- **Requested by:** Backend/Gov closeout track
- **Target reviewer:** Security Lead
- **Scope:** Government risk score formula used by `sonar_bank_app`
- **Decision needed:** Approve current MVP formula as temporary, request amendments, or block production use

## Current implementation snapshot

- **Runtime service:** `resources/sonar_bank_app/server/services/risk_engine.lua`
- **Config thresholds:** `resources/sonar_bank_app/config.lua` (`C.RiskScore`)
- **Materialized table:** `resources/sonar_core/migrations/032_govt_risk_scores_and_treasury_movements.sql`
- **Consumers:**
  - `GovtService.ListCensus` recomputes citizen risk during listing.
  - GOVT Census detail displays `riskScore` and `riskLevel`.
  - GOVT Business detail displays materialized company risk from `sonar_bank_govt_risk_scores`.
  - GOVT Reports aggregates `riskBreakdown` from census data.

## Formula inputs currently used

Citizen recompute uses repo metrics from `Repo.GetRiskMetrics(cid)` and computes from:

- **Max outgoing amount:** `max_outgoing_amount`
- **Short-window outgoing count:** `outgoing_5m_count`
- **Frozen/suspicious destinations:** `frozen_destination_count`

## Current scoring behavior

- **High single outgoing:** sets `exposure_score = 80` and `flag_score = 70`.
- **Velocity trigger:** if outgoing count reaches configured threshold, sets `velocity_score >= 55` and `flag_score >= 45`.
- **Frozen destination trigger:** sets `compliance_score >= 55` and `flag_score >= 45`.
- **No rule matched:** assigns fixed low placeholder exposure score `12`.
- **Final score:** maximum of component scores, not weighted average.
- **Risk level:** derived from configured thresholds in `C.RiskScore.LEVELS`.

## Review concerns

1. **MVP placeholder baseline**
   - The no-rule path writes a fixed score of `12` with summary `daily-pattern anomaly placeholder fixed score`.
   - Security should decide whether this is acceptable as a temporary baseline or requires a neutral `0`/explicit `low` reason.

2. **Max-component scoring**
   - Current score is `max(component_scores)`.
   - This is simple and conservative, but may overrepresent one isolated signal.
   - Security should confirm whether max-score is intended or whether weighted scoring is required.

3. **Threshold semantics**
   - Current thresholds are config-driven:
     - `HIGH_SINGLE_OUTGOING_MINOR = 50000`
     - `MEDIUM_WINDOW_COUNT = 3`
     - `MEDIUM_WINDOW_SECONDS = 300`
   - Security should validate units and intended production values.

4. **Government-triggered recompute cadence**
   - `ListCensus` recomputes risk inline for each listed citizen.
   - This gives fresh data but may create performance/cadence issues and government read-side side effects.
   - Security/Backend should decide whether recompute should move to a scheduled job or explicit admin action.

5. **Company risk asymmetry**
   - Citizen risk has runtime recompute.
   - Company risk is read from materialized `sonar_bank_govt_risk_scores` and defaults to low if missing.
   - Security should decide whether company risk needs an equivalent recompute path.

6. **Flag side effects**
   - Recompute can insert compliance flags through `InsertFlagIfMissing`.
   - Security should confirm idempotency criteria and whether read-triggered flag creation is acceptable.

## Requested Security Lead decision

Please respond with one of:

- **APPROVE-AS-MVP:** Current formula can remain for closeout, with documented Phase B hardening.
- **APPROVE-WITH-AMENDMENTS:** List required formula/config/cadence changes before lock.
- **BLOCK:** Risk formula must not be used in production GOVT views until redesigned.

## Proposed Phase B amendments if MVP is accepted

- Move recompute to scheduled/explicit workflow instead of list-read path.
- Add formula version changelog and Security sign-off matrix.
- Add company risk recompute parity.
- Replace fixed low placeholder summary with an explicit baseline rule.
- Add live evidence report with sampled metrics, resulting score, and generated flags.
