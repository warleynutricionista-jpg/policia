-- ============================================================
-- PS-FORENSICS - Backup pré-mudanças destrutivas
-- Uso manual recomendado ANTES de qualquer DROP/ALTER destrutivo.
-- Script idempotente: cria tabelas _backup e copia dados uma única vez.
-- ============================================================

CREATE TABLE IF NOT EXISTS forensic_crime_scenes_backup LIKE forensic_crime_scenes;
INSERT INTO forensic_crime_scenes_backup SELECT * FROM forensic_crime_scenes
WHERE NOT EXISTS (SELECT 1 FROM forensic_crime_scenes_backup LIMIT 1);

CREATE TABLE IF NOT EXISTS forensic_evidence_backup LIKE forensic_evidence;
INSERT INTO forensic_evidence_backup SELECT * FROM forensic_evidence
WHERE NOT EXISTS (SELECT 1 FROM forensic_evidence_backup LIMIT 1);

CREATE TABLE IF NOT EXISTS forensic_chain_of_custody_backup LIKE forensic_chain_of_custody;
INSERT INTO forensic_chain_of_custody_backup SELECT * FROM forensic_chain_of_custody
WHERE NOT EXISTS (SELECT 1 FROM forensic_chain_of_custody_backup LIMIT 1);

CREATE TABLE IF NOT EXISTS forensic_fingerprints_collected_backup LIKE forensic_fingerprints_collected;
INSERT INTO forensic_fingerprints_collected_backup SELECT * FROM forensic_fingerprints_collected
WHERE NOT EXISTS (SELECT 1 FROM forensic_fingerprints_collected_backup LIMIT 1);

CREATE TABLE IF NOT EXISTS forensic_dna_samples_backup LIKE forensic_dna_samples;
INSERT INTO forensic_dna_samples_backup SELECT * FROM forensic_dna_samples
WHERE NOT EXISTS (SELECT 1 FROM forensic_dna_samples_backup LIMIT 1);

CREATE TABLE IF NOT EXISTS forensic_ballistics_backup LIKE forensic_ballistics;
INSERT INTO forensic_ballistics_backup SELECT * FROM forensic_ballistics
WHERE NOT EXISTS (SELECT 1 FROM forensic_ballistics_backup LIMIT 1);

CREATE TABLE IF NOT EXISTS forensic_lab_tests_backup LIKE forensic_lab_tests;
INSERT INTO forensic_lab_tests_backup SELECT * FROM forensic_lab_tests
WHERE NOT EXISTS (SELECT 1 FROM forensic_lab_tests_backup LIMIT 1);

CREATE TABLE IF NOT EXISTS forensic_drug_analysis_backup LIKE forensic_drug_analysis;
INSERT INTO forensic_drug_analysis_backup SELECT * FROM forensic_drug_analysis
WHERE NOT EXISTS (SELECT 1 FROM forensic_drug_analysis_backup LIMIT 1);

CREATE TABLE IF NOT EXISTS forensic_autopsy_backup LIKE forensic_autopsy;
INSERT INTO forensic_autopsy_backup SELECT * FROM forensic_autopsy
WHERE NOT EXISTS (SELECT 1 FROM forensic_autopsy_backup LIMIT 1);

CREATE TABLE IF NOT EXISTS forensic_reports_backup LIKE forensic_reports;
INSERT INTO forensic_reports_backup SELECT * FROM forensic_reports
WHERE NOT EXISTS (SELECT 1 FROM forensic_reports_backup LIMIT 1);

CREATE TABLE IF NOT EXISTS forensic_cross_references_backup LIKE forensic_cross_references;
INSERT INTO forensic_cross_references_backup SELECT * FROM forensic_cross_references
WHERE NOT EXISTS (SELECT 1 FROM forensic_cross_references_backup LIMIT 1);

CREATE TABLE IF NOT EXISTS forensic_audit_log_backup LIKE forensic_audit_log;
INSERT INTO forensic_audit_log_backup SELECT * FROM forensic_audit_log
WHERE NOT EXISTS (SELECT 1 FROM forensic_audit_log_backup LIMIT 1);
