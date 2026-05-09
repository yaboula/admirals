START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_saved_recipients (
  id                    CHAR(36)        NOT NULL,
  owner_account_id      CHAR(36)        NOT NULL,
  counterpart_iban      VARCHAR(20)     NOT NULL,
  alias                 VARCHAR(64)     NULL,
  is_favorite           BOOLEAN         NOT NULL DEFAULT FALSE,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_saved_recipients_owner_iban (owner_account_id, counterpart_iban),
  KEY idx_sonar_bank_saved_recipients_owner_fav (owner_account_id, is_favorite, updated_at),
  KEY idx_sonar_bank_saved_recipients_iban (counterpart_iban),

  CONSTRAINT fk_sonar_bank_saved_recipients_owner
    FOREIGN KEY (owner_account_id) REFERENCES sonar_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
