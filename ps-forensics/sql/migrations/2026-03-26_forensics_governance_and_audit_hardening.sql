-- ============================================================
-- PS-FORENSICS - Governança de schema + trilha de auditoria
-- Data: 2026-03-25
-- Objetivo: padronizar created_at/updated_at/created_by, índices e auditabilidade
-- ============================================================

-- 1) Campos de governança (compatível com legado / idempotente)
ALTER TABLE forensic_scene_personnel
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER notes;

ALTER TABLE forensic_scene_photos
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER taken_by;

ALTER TABLE forensic_evidence
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER collected_by;

ALTER TABLE forensic_chain_of_custody
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER notes;

ALTER TABLE forensic_fingerprint_profiles
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER registered_by;

ALTER TABLE forensic_fingerprints_collected
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER collected_by;

ALTER TABLE forensic_dna_profiles
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER registered_by;

ALTER TABLE forensic_dna_samples
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER collected_by;

ALTER TABLE forensic_ballistics
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER collected_by;

ALTER TABLE forensic_lab_tests
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER requested_by;

ALTER TABLE forensic_drug_analysis
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER analyzed_by;

ALTER TABLE forensic_autopsy
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER examiner_citizenid;

ALTER TABLE forensic_reports
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER author_citizenid;

ALTER TABLE forensic_cross_references
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE forensic_audit_log
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER actor_citizenid,
    ADD COLUMN IF NOT EXISTS request_id VARCHAR(64) DEFAULT NULL AFTER entity_id,
    ADD COLUMN IF NOT EXISTS integrity_hash VARCHAR(64) DEFAULT NULL AFTER details,
    ADD COLUMN IF NOT EXISTS previous_integrity_hash VARCHAR(64) DEFAULT NULL AFTER integrity_hash;

ALTER TABLE forensic_intelligence_links
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER exam_generated_by;

ALTER TABLE forensic_watchlist_events
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(50) DEFAULT NULL AFTER citizenid;

-- 2) Backfill seguro para autoria e datas (somente quando vazio)
UPDATE forensic_scene_personnel
SET created_by = citizenid
WHERE created_by IS NULL AND citizenid IS NOT NULL;

UPDATE forensic_scene_photos
SET created_by = taken_by
WHERE created_by IS NULL AND taken_by IS NOT NULL;

UPDATE forensic_evidence
SET created_by = collected_by
WHERE created_by IS NULL AND collected_by IS NOT NULL;

UPDATE forensic_chain_of_custody
SET created_by = COALESCE(to_citizenid, from_citizenid)
WHERE created_by IS NULL;

UPDATE forensic_fingerprint_profiles
SET created_by = registered_by,
    created_at = COALESCE(created_at, registered_at)
WHERE created_by IS NULL OR created_at IS NULL;

UPDATE forensic_fingerprints_collected
SET created_by = collected_by
WHERE created_by IS NULL AND collected_by IS NOT NULL;

UPDATE forensic_dna_profiles
SET created_by = registered_by,
    created_at = COALESCE(created_at, registered_at)
WHERE created_by IS NULL OR created_at IS NULL;

UPDATE forensic_dna_samples
SET created_by = collected_by
WHERE created_by IS NULL AND collected_by IS NOT NULL;

UPDATE forensic_ballistics
SET created_by = collected_by
WHERE created_by IS NULL AND collected_by IS NOT NULL;

UPDATE forensic_lab_tests
SET created_by = requested_by
WHERE created_by IS NULL AND requested_by IS NOT NULL;

UPDATE forensic_drug_analysis
SET created_by = analyzed_by
WHERE created_by IS NULL AND analyzed_by IS NOT NULL;

UPDATE forensic_autopsy
SET created_by = examiner_citizenid
WHERE created_by IS NULL AND examiner_citizenid IS NOT NULL;

UPDATE forensic_reports
SET created_by = author_citizenid
WHERE created_by IS NULL AND author_citizenid IS NOT NULL;

UPDATE forensic_audit_log
SET created_by = actor_citizenid
WHERE created_by IS NULL AND actor_citizenid IS NOT NULL;

UPDATE forensic_intelligence_links
SET created_by = COALESCE(exam_performed_by, exam_generated_by)
WHERE created_by IS NULL;

UPDATE forensic_watchlist_events
SET created_at = COALESCE(created_at, occurred_at),
    created_by = COALESCE(created_by, removed_by)
WHERE created_at IS NULL OR created_by IS NULL;

-- 3) Índices para consultas principais (filters + order by created_at)
ALTER TABLE forensic_scene_personnel
    ADD INDEX IF NOT EXISTS idx_scene_personnel_scene_arrival (scene_id, arrival_time),
    ADD INDEX IF NOT EXISTS idx_scene_personnel_citizen_arrival (citizenid, arrival_time);

ALTER TABLE forensic_scene_photos
    ADD INDEX IF NOT EXISTS idx_scene_photos_scene_taken (scene_id, taken_at);

ALTER TABLE forensic_evidence
    ADD INDEX IF NOT EXISTS idx_evidence_citizen_created (linked_citizenid, created_at),
    ADD INDEX IF NOT EXISTS idx_evidence_vehicle_created (linked_vehicle_plate, created_at),
    ADD INDEX IF NOT EXISTS idx_evidence_weapon_created (linked_weapon_serial, created_at),
    ADD INDEX IF NOT EXISTS idx_evidence_forensic_report_created (forensic_report_id, created_at);

ALTER TABLE forensic_fingerprints_collected
    ADD INDEX IF NOT EXISTS idx_fingerprint_matched_created (matched_citizenid, created_at);

ALTER TABLE forensic_dna_samples
    ADD INDEX IF NOT EXISTS idx_dna_matched_created (matched_citizenid, created_at);

ALTER TABLE forensic_ballistics
    ADD INDEX IF NOT EXISTS idx_ballistics_matched_weapon_created (matched_weapon_serial, created_at);

ALTER TABLE forensic_cross_references
    ADD INDEX IF NOT EXISTS idx_cross_source_created_full (source_type, source_id, created_at),
    ADD INDEX IF NOT EXISTS idx_cross_target_created_full (target_type, target_id, created_at);

ALTER TABLE forensic_audit_log
    ADD INDEX IF NOT EXISTS idx_audit_created_at (created_at),
    ADD INDEX IF NOT EXISTS idx_audit_request_id (request_id),
    ADD INDEX IF NOT EXISTS idx_audit_hash (integrity_hash);

ALTER TABLE forensic_intelligence_links
    ADD INDEX IF NOT EXISTS idx_fi_confidence_created (confidence_score, created_at),
    ADD INDEX IF NOT EXISTS idx_fi_scene_created (scene_id, created_at);

ALTER TABLE forensic_watchlist_events
    ADD INDEX IF NOT EXISTS idx_fw_occurred_created (occurred_at, created_at),
    ADD INDEX IF NOT EXISTS idx_fw_source_created (source_type, source_id, occurred_at);

-- 4) Padronização de status (normaliza nulos em colunas críticas)
UPDATE forensic_crime_scenes SET status = 'aberta' WHERE status IS NULL;
UPDATE forensic_evidence SET status = 'coletada' WHERE status IS NULL;
UPDATE forensic_lab_tests SET status = 'solicitado' WHERE status IS NULL;
UPDATE forensic_autopsy SET status = 'pendente' WHERE status IS NULL;
UPDATE forensic_reports SET status = 'rascunho' WHERE status IS NULL;
