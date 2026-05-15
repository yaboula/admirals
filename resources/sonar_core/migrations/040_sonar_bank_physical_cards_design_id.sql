-- ============================================================================
-- Migration: 040_sonar_bank_physical_cards_design_id.sql
-- Author: AI Full Stack (BANK-FLOW.AUDIT.F12) + yaboula
-- Date: 2026-05-15
-- Description:
--   Adds `design_id` column to sonar_bank_physical_cards so the visual style
--   chosen by the cardholder persists across sessions. Previously the card
--   list query returned the literal 'sonar_signature' for every row, and the
--   FE picker only mutated client-side state — closing the app reverted the
--   design.
--
-- Decisions:
--   D1. VARCHAR(64) — the FE registry uses snake_case ids ('noir',
--       'sonar_signature', etc.); 64 chars is comfortable headroom for future
--       limited-edition designs.
--   D2. NOT NULL DEFAULT 'sonar_signature' — every existing card receives
--       the flagship signature design automatically (no NULL ambiguity in
--       the FE which already falls back to sonar_signature).
--   D3. No FK because the canonical design catalogue lives in the FE
--       registry (`cardDesigns.ts`) — the service layer whitelists known ids
--       so invalid values cannot be persisted.
-- ============================================================================

ALTER TABLE sonar_bank_physical_cards
  ADD COLUMN IF NOT EXISTS design_id VARCHAR(64) NOT NULL DEFAULT 'sonar_signature' AFTER card_kind;
