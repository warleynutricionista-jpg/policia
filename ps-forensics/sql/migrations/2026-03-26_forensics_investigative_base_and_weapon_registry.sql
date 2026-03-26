-- ============================================================
-- PS-FORENSICS - Base investigativa + rastreabilidade de armas
-- ============================================================

ALTER TABLE forensic_fingerprint_profiles
    ADD COLUMN IF NOT EXISTS fingerprint_code VARCHAR(20) DEFAULT NULL AFTER citizen_name,
    ADD UNIQUE INDEX IF NOT EXISTS uk_forensic_fingerprint_code (fingerprint_code);

ALTER TABLE forensic_dna_profiles
    ADD COLUMN IF NOT EXISTS dna_code VARCHAR(20) DEFAULT NULL AFTER citizen_name,
    ADD UNIQUE INDEX IF NOT EXISTS uk_forensic_dna_code (dna_code);

UPDATE forensic_fingerprint_profiles
SET fingerprint_code = CONCAT('DIG-', LPAD(id, 8, '0'))
WHERE (fingerprint_code IS NULL OR fingerprint_code = '');

UPDATE forensic_dna_profiles
SET dna_code = CONCAT('DNA-', LPAD(id, 8, '0'))
WHERE (dna_code IS NULL OR dna_code = '');

CREATE TABLE IF NOT EXISTS forensic_investigative_subjects (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    citizenid VARCHAR(50) NOT NULL,
    reason VARCHAR(255) DEFAULT NULL,
    source_type VARCHAR(50) DEFAULT NULL,
    source_id VARCHAR(64) DEFAULT NULL,
    status ENUM('active','inactive') NOT NULL DEFAULT 'active',
    added_by VARCHAR(50) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_forensic_investigative_citizen (citizenid),
    KEY idx_forensic_investigative_status (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS forensic_weapon_registry (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    serial VARCHAR(50) NOT NULL,
    weapon_model VARCHAR(80) DEFAULT NULL,
    caliber VARCHAR(30) DEFAULT NULL,
    origin_type ENUM('mdt_legal','ilegal','apreendida','policial_carga') NOT NULL DEFAULT 'ilegal',
    current_holder_citizenid VARCHAR(50) DEFAULT NULL,
    ballistic_signature VARCHAR(32) NOT NULL,
    status ENUM('active','returned','lost','seized','destroyed') NOT NULL DEFAULT 'active',
    created_by VARCHAR(50) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_forensic_weapon_serial (serial),
    KEY idx_forensic_weapon_holder (current_holder_citizenid, status),
    KEY idx_forensic_weapon_signature (ballistic_signature)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO forensic_investigative_subjects (citizenid, reason, source_type, source_id, status, added_by)
SELECT DISTINCT citizenid, 'Backfill: perfil digital existente', 'forensic_fingerprint_profile', CAST(id AS CHAR), 'active', 'migration'
FROM forensic_fingerprint_profiles
WHERE citizenid IS NOT NULL AND citizenid <> ''
ON DUPLICATE KEY UPDATE
    status = 'active',
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO forensic_investigative_subjects (citizenid, reason, source_type, source_id, status, added_by)
SELECT DISTINCT citizenid, 'Backfill: perfil DNA existente', 'forensic_dna_profile', CAST(id AS CHAR), 'active', 'migration'
FROM forensic_dna_profiles
WHERE citizenid IS NOT NULL AND citizenid <> ''
ON DUPLICATE KEY UPDATE
    status = 'active',
    updated_at = CURRENT_TIMESTAMP;
