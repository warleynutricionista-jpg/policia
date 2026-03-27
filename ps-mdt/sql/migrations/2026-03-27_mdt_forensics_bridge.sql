-- Forensics bridge fields for aggressive integration

ALTER TABLE mdt_evidence_items
    ADD COLUMN IF NOT EXISTS forensic_evidence_id INT(10) UNSIGNED DEFAULT NULL AFTER report_id,
    ADD COLUMN IF NOT EXISTS forensic_case_id INT(10) UNSIGNED DEFAULT NULL AFTER forensic_evidence_id,
    ADD COLUMN IF NOT EXISTS forensic_scene_id INT(10) UNSIGNED DEFAULT NULL AFTER forensic_case_id,
    ADD COLUMN IF NOT EXISTS incident_id INT(10) UNSIGNED DEFAULT NULL AFTER forensic_scene_id,
    ADD COLUMN IF NOT EXISTS evidence_status ENUM('registered','pending_analysis','in_analysis','processed','stored','released') NOT NULL DEFAULT 'registered' AFTER stored,
    ADD INDEX IF NOT EXISTS idx_mdt_evidence_forensic_evidence (forensic_evidence_id),
    ADD INDEX IF NOT EXISTS idx_mdt_evidence_incident (incident_id, created_at),
    ADD INDEX IF NOT EXISTS idx_mdt_evidence_status (evidence_status, created_at);

ALTER TABLE mdt_weapons
    ADD INDEX IF NOT EXISTS idx_mdt_weapons_owner_model (owner, weaponModel);
