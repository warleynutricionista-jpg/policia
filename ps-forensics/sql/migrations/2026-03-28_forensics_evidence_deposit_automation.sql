-- ============================================================
-- PS-FORENSICS - Depósito automático de evidências
-- Compatível e idempotente
-- ============================================================

ALTER TABLE forensic_evidence
    ADD COLUMN IF NOT EXISTS deposit_id BIGINT(20) UNSIGNED DEFAULT NULL AFTER storage_location,
    ADD INDEX IF NOT EXISTS idx_forensic_evidence_deposit (deposit_id, status, updated_at);

CREATE TABLE IF NOT EXISTS forensic_evidence_deposits (
    id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
    deposit_code VARCHAR(32) NOT NULL,
    name VARCHAR(120) NOT NULL,
    location_label VARCHAR(160) DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_by VARCHAR(50) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_forensic_deposit_code (deposit_code),
    KEY idx_forensic_deposit_active (is_active, updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS forensic_evidence_storage_events (
    id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
    evidence_id INT(10) UNSIGNED NOT NULL,
    deposit_id BIGINT(20) UNSIGNED NOT NULL,
    action ENUM('stored','removed','transfer') NOT NULL DEFAULT 'stored',
    action_by VARCHAR(50) DEFAULT NULL,
    action_by_name VARCHAR(100) DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_storage_events_evidence (evidence_id, created_at),
    KEY idx_storage_events_deposit (deposit_id, created_at),
    CONSTRAINT fk_storage_event_evidence
        FOREIGN KEY (evidence_id) REFERENCES forensic_evidence(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_storage_event_deposit
        FOREIGN KEY (deposit_id) REFERENCES forensic_evidence_deposits(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE forensic_evidence
    ADD CONSTRAINT fk_forensic_evidence_deposit
        FOREIGN KEY (deposit_id) REFERENCES forensic_evidence_deposits(id)
        ON DELETE SET NULL ON UPDATE CASCADE;
