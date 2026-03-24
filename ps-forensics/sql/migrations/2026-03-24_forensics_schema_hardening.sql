-- ============================================================
-- PS-FORENSICS - Hardening de schema (MariaDB-safe/idempotente)
-- Data: 2026-03-24
-- ============================================================

-- 1) Colunas de compatibilidade e consistência
ALTER TABLE forensic_drug_analysis
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE forensic_cross_references
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- 2) Índices de performance para consultas reais do backend
ALTER TABLE forensic_crime_scenes
    ADD INDEX IF NOT EXISTS idx_scene_status_created (status, created_at),
    ADD INDEX IF NOT EXISTS idx_scene_classification_created (classification, created_at),
    ADD INDEX IF NOT EXISTS idx_scene_case_created (case_id, created_at),
    ADD INDEX IF NOT EXISTS idx_scene_report_created (report_id, created_at);

ALTER TABLE forensic_evidence
    ADD INDEX IF NOT EXISTS idx_evidence_scene_created (scene_id, created_at),
    ADD INDEX IF NOT EXISTS idx_evidence_case_created (case_id, created_at),
    ADD INDEX IF NOT EXISTS idx_evidence_report_created (report_id, created_at),
    ADD INDEX IF NOT EXISTS idx_evidence_status_created (status, created_at),
    ADD INDEX IF NOT EXISTS idx_evidence_category_created (category, created_at),
    ADD INDEX IF NOT EXISTS idx_evidence_linked_vehicle (linked_vehicle_plate),
    ADD INDEX IF NOT EXISTS idx_evidence_seal_number (seal_number);

ALTER TABLE forensic_chain_of_custody
    ADD INDEX IF NOT EXISTS idx_custody_evidence_created (evidence_id, created_at),
    ADD INDEX IF NOT EXISTS idx_custody_to_citizen_created (to_citizenid, created_at),
    ADD INDEX IF NOT EXISTS idx_custody_from_citizen_created (from_citizenid, created_at);

ALTER TABLE forensic_fingerprints_collected
    ADD INDEX IF NOT EXISTS idx_fingerprint_scene_created (scene_id, created_at),
    ADD INDEX IF NOT EXISTS idx_fingerprint_evidence_created (evidence_id, created_at),
    ADD INDEX IF NOT EXISTS idx_fingerprint_match_status_created (match_status, created_at),
    ADD INDEX IF NOT EXISTS idx_fingerprint_collected_by_created (collected_by, created_at);

ALTER TABLE forensic_dna_samples
    ADD INDEX IF NOT EXISTS idx_dna_scene_created (scene_id, created_at),
    ADD INDEX IF NOT EXISTS idx_dna_evidence_created (evidence_id, created_at),
    ADD INDEX IF NOT EXISTS idx_dna_match_status_created (match_status, created_at),
    ADD INDEX IF NOT EXISTS idx_dna_collected_by_created (collected_by, created_at);

ALTER TABLE forensic_ballistics
    ADD INDEX IF NOT EXISTS idx_ballistics_scene_created (scene_id, created_at),
    ADD INDEX IF NOT EXISTS idx_ballistics_evidence_created (evidence_id, created_at),
    ADD INDEX IF NOT EXISTS idx_ballistics_weapon_created (weapon_serial, created_at),
    ADD INDEX IF NOT EXISTS idx_ballistics_rifling_created (rifling_match, created_at);

ALTER TABLE forensic_lab_tests
    ADD INDEX IF NOT EXISTS idx_lab_status_created (status, created_at),
    ADD INDEX IF NOT EXISTS idx_lab_result_created (result_level, created_at),
    ADD INDEX IF NOT EXISTS idx_lab_evidence_created (evidence_id, created_at),
    ADD INDEX IF NOT EXISTS idx_lab_scene_created (scene_id, created_at),
    ADD INDEX IF NOT EXISTS idx_lab_target_citizen_created (target_citizenid, created_at),
    ADD INDEX IF NOT EXISTS idx_lab_target_weapon_created (target_weapon_serial, created_at);

ALTER TABLE forensic_drug_analysis
    ADD INDEX IF NOT EXISTS idx_drug_scene_created (scene_id, created_at),
    ADD INDEX IF NOT EXISTS idx_drug_result_created (test_result, created_at),
    ADD INDEX IF NOT EXISTS idx_drug_category_created (substance_category, created_at);

ALTER TABLE forensic_autopsy
    ADD INDEX IF NOT EXISTS idx_autopsy_status_created (status, created_at),
    ADD INDEX IF NOT EXISTS idx_autopsy_scene_created (scene_id, created_at),
    ADD INDEX IF NOT EXISTS idx_autopsy_report_created (report_id, created_at),
    ADD INDEX IF NOT EXISTS idx_autopsy_victim_created (victim_citizenid, created_at);

ALTER TABLE forensic_reports
    ADD INDEX IF NOT EXISTS idx_reports_status_created (status, created_at),
    ADD INDEX IF NOT EXISTS idx_reports_type_created (type, created_at),
    ADD INDEX IF NOT EXISTS idx_reports_scene_created (scene_id, created_at),
    ADD INDEX IF NOT EXISTS idx_reports_case_created (case_id, created_at);

ALTER TABLE forensic_cross_references
    ADD INDEX IF NOT EXISTS idx_cross_target_created (target_type, target_id, created_at),
    ADD INDEX IF NOT EXISTS idx_cross_source_created (source_type, source_id, created_at),
    ADD INDEX IF NOT EXISTS idx_cross_created_by_created (created_by, created_at);

ALTER TABLE forensic_audit_log
    ADD INDEX IF NOT EXISTS idx_audit_entity_created (entity_type, entity_id, created_at),
    ADD INDEX IF NOT EXISTS idx_audit_actor_created (actor_citizenid, created_at),
    ADD INDEX IF NOT EXISTS idx_audit_action_created (action, created_at);

-- 3) Relações adicionais locais (somente quando seguras para legado)
-- NOTA: FK de forensic_drug_analysis.scene_id -> forensic_crime_scenes.id
-- não é aplicada automaticamente para evitar falha em bases legadas com órfãos.
-- Se desejar impor integridade estrita, limpar órfãos e aplicar manualmente.
