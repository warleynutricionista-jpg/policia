-- ============================================================
-- PS-FORENSICS - Drogas e testes residuais (workflow + compat)
-- Data: 2026-03-25
-- ============================================================

ALTER TABLE forensic_drug_analysis
    ADD COLUMN IF NOT EXISTS case_id INT(10) UNSIGNED DEFAULT NULL AFTER scene_id,
    ADD COLUMN IF NOT EXISTS report_id INT(10) UNSIGNED DEFAULT NULL AFTER case_id;

ALTER TABLE forensic_drug_analysis
    MODIFY COLUMN test_result ENUM('suspeita','presumido','inconclusivo','compativel','confirmado','negativo')
    NOT NULL DEFAULT 'suspeita';

ALTER TABLE forensic_drug_analysis
    ADD INDEX IF NOT EXISTS idx_drug_case_created (case_id, created_at),
    ADD INDEX IF NOT EXISTS idx_drug_report_created (report_id, created_at);
