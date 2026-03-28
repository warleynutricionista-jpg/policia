-- ============================================================
-- PS-FORENSICS - Índices de performance para integração com MDT
-- Idempotente: seguro para rodar múltiplas vezes
-- ============================================================

ALTER TABLE `forensic_crime_scenes`
    ADD INDEX IF NOT EXISTS `idx_scene_status_created` (`status`, `created_at`),
    ADD INDEX IF NOT EXISTS `idx_scene_case_created` (`case_id`, `created_at`),
    ADD INDEX IF NOT EXISTS `idx_scene_report_created` (`report_id`, `created_at`);

ALTER TABLE `forensic_lab_tests`
    ADD INDEX IF NOT EXISTS `idx_lab_status_created` (`status`, `created_at`);

ALTER TABLE `forensic_reports`
    ADD INDEX IF NOT EXISTS `idx_forensic_reports_created` (`created_at`);

ALTER TABLE `forensic_fingerprints_collected`
    ADD INDEX IF NOT EXISTS `idx_fp_match_status_created` (`match_status`, `created_at`);

ALTER TABLE `forensic_dna_samples`
    ADD INDEX IF NOT EXISTS `idx_dna_match_status_created` (`match_status`, `created_at`);

ALTER TABLE `forensic_evidence`
    ADD INDEX IF NOT EXISTS `idx_evidence_linked_citizen_created` (`linked_citizenid`, `created_at`),
    ADD INDEX IF NOT EXISTS `idx_evidence_linked_vehicle_created` (`linked_vehicle_plate`, `created_at`),
    ADD INDEX IF NOT EXISTS `idx_evidence_linked_weapon_created` (`linked_weapon_serial`, `created_at`);
