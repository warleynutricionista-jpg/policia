-- ============================================================
-- PS-FORENSICS — Migration: Safety columns for MySQL compatibility
-- Ensures created_by column exists on all key tables
-- Each ALTER is separate so failures don't cascade
-- ============================================================

ALTER TABLE forensic_fingerprint_profiles ADD COLUMN created_by VARCHAR(50) DEFAULT NULL AFTER registered_by;

ALTER TABLE forensic_fingerprint_profiles ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE forensic_fingerprint_profiles ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE forensic_dna_profiles ADD COLUMN created_by VARCHAR(50) DEFAULT NULL AFTER registered_by;

ALTER TABLE forensic_dna_profiles ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE forensic_dna_profiles ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE forensic_fingerprints_collected ADD COLUMN created_by VARCHAR(50) DEFAULT NULL AFTER collected_by;

ALTER TABLE forensic_fingerprints_collected ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE forensic_dna_samples ADD COLUMN created_by VARCHAR(50) DEFAULT NULL AFTER collected_by;

ALTER TABLE forensic_dna_samples ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE forensic_scene_photos ADD COLUMN created_by VARCHAR(50) DEFAULT NULL AFTER taken_by;

ALTER TABLE forensic_chain_of_custody ADD COLUMN created_by VARCHAR(50) DEFAULT NULL AFTER notes;
