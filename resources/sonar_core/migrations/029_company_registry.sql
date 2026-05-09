-- ============================================================================
-- Migration: 029_company_registry.sql
-- Author: DB Lead (Cascade) + yaboula
-- Date: 2026-05-09 (BANK-DB.AMEND.1)
-- Description:
--   Adds the minimum company registry required by Issue #002 for GOVT and
--   Business Cockpit mock-to-real integration.
--
-- Dependencies:
--   - 002_foundation_tables.sql (sonar_accounts exists).
--   - 003_bank_schema.sql (legacy opaque company_id references exist).
--
-- Amendment scope:
--   - Resolves Issue #001 at registry-table level by creating sonar_companies.
--   - Keeps FK promotion from legacy bank tables deferred until an orphan audit
--     runs against existing opaque company_id values.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_companies (
  id                    CHAR(36)        NOT NULL,
  name                  VARCHAR(96)     NOT NULL,
  sector                ENUM('farming','milling','bakery','retail','logistics','services','finance','other') NOT NULL DEFAULT 'other',
  status                ENUM('active','frozen','liquidating','dissolved') NOT NULL DEFAULT 'active',
  founded_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  created_by_account_id CHAR(36)        NULL,

  employee_count_cached INT UNSIGNED    NOT NULL DEFAULT 0,
  director_count_cached INT UNSIGNED    NOT NULL DEFAULT 0,
  metadata              JSON            NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_companies_status_sector (status, sector),
  KEY idx_sonar_companies_name (name),
  KEY idx_sonar_companies_founded (founded_at),
  KEY idx_sonar_companies_created_by (created_by_account_id),

  CONSTRAINT fk_sonar_companies_created_by
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_companies_employee_count CHECK (employee_count_cached >= 0),
  CONSTRAINT chk_sonar_companies_director_count CHECK (director_count_cached >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sonar_company_members (
  id                    CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL,
  account_id            CHAR(36)        NOT NULL,

  role                  ENUM('founder','co-founder','director','manager','employee') NOT NULL DEFAULT 'employee',
  active                BOOLEAN         NOT NULL DEFAULT TRUE,
  joined_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  left_at               INT UNSIGNED    NULL,

  department            VARCHAR(64)     NULL,
  title                 VARCHAR(64)     NULL,
  salary_amount         DECIMAL(14,2)   NULL,
  metadata              JSON            NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_company_members_company_account_active (company_id, account_id, active),
  KEY idx_sonar_company_members_account_active (account_id, active),
  KEY idx_sonar_company_members_company_role (company_id, role, active),
  KEY idx_sonar_company_members_company_joined (company_id, joined_at DESC),

  CONSTRAINT fk_sonar_company_members_company
    FOREIGN KEY (company_id) REFERENCES sonar_companies(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_company_members_account
    FOREIGN KEY (account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_company_members_salary_nonneg CHECK (salary_amount IS NULL OR salary_amount >= 0),
  CONSTRAINT chk_sonar_company_members_left_after_join CHECK (left_at IS NULL OR joined_at <= left_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- ============================================================================
-- Backend Lead follow-up:
--   1. Create CompanyRegistry.Exists(company_id) and CompanyRegistry.List/Detail.
--   2. Maintain employee_count_cached and director_count_cached after member
--      changes, or recompute nightly before enabling large GOVT lists.
--   3. Run orphan audit before FK promotion from legacy opaque company_id columns.
-- ============================================================================
