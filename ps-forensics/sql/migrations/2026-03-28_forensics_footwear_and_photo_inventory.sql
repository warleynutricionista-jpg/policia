CREATE TABLE IF NOT EXISTS forensic_footwear_profiles (
    id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    citizenid VARCHAR(50) NOT NULL,
    shoe_model INT(10) DEFAULT NULL,
    image_url LONGTEXT DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    created_by VARCHAR(50) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_footwear_citizen (citizenid, created_at),
    KEY idx_footwear_shoe_model (shoe_model, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE forensic_evidence
    ADD INDEX IF NOT EXISTS idx_forensic_evidence_type_subtype (type, subtype, created_at);
