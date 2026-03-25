-- ============================================================
-- PS-FORENSICS - Profundidade de cadeia de custódia + processamento
-- Data: 2026-03-25
-- ============================================================

ALTER TABLE forensic_evidence
    ADD COLUMN IF NOT EXISTS forensic_report_id INT(10) UNSIGNED DEFAULT NULL AFTER report_id,
    ADD COLUMN IF NOT EXISTS current_holder_citizenid VARCHAR(50) DEFAULT NULL AFTER collected_by_name,
    ADD COLUMN IF NOT EXISTS current_holder_name VARCHAR(100) DEFAULT NULL AFTER current_holder_citizenid,
    ADD COLUMN IF NOT EXISTS sealed_at TIMESTAMP NULL DEFAULT NULL AFTER seal_number;

ALTER TABLE forensic_evidence
    ADD INDEX IF NOT EXISTS idx_evidence_forensic_report (forensic_report_id),
    ADD INDEX IF NOT EXISTS idx_evidence_current_holder (current_holder_citizenid);

ALTER TABLE forensic_chain_of_custody
    ADD COLUMN IF NOT EXISTS integrity_hash VARCHAR(64) DEFAULT NULL AFTER notes,
    ADD COLUMN IF NOT EXISTS previous_integrity_hash VARCHAR(64) DEFAULT NULL AFTER integrity_hash,
    ADD INDEX IF NOT EXISTS idx_custody_integrity (integrity_hash);

ALTER TABLE forensic_lab_tests
    ADD COLUMN IF NOT EXISTS processing_time_seconds INT(10) UNSIGNED DEFAULT 0 AFTER processing_time_minutes,
    ADD COLUMN IF NOT EXISTS processing_tier ENUM('simples','medio','complexo') NOT NULL DEFAULT 'simples' AFTER processing_time_seconds,
    ADD COLUMN IF NOT EXISTS available_at TIMESTAMP NULL DEFAULT NULL AFTER started_at,
    ADD INDEX IF NOT EXISTS idx_lab_available_at (available_at);

ALTER TABLE forensic_reports
    ADD INDEX IF NOT EXISTS idx_reports_scene_case (scene_id, case_id, created_at);
