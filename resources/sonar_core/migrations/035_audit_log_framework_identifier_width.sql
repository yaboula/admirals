ALTER TABLE sonar_audit_log
MODIFY COLUMN actor_account_id VARCHAR(64) NULL
COMMENT 'quién ejecutó la acción (NULL si sistema; UUID/citizen/framework id)';
