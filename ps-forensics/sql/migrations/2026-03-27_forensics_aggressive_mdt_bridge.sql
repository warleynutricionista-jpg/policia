-- Aggressive MDT <-> Forensics bridge
-- Adds referential fields for incident/report/evidence syncing and pending lab workflow.

ALTER TABLE forensic_evidence
    ADD COLUMN IF NOT EXISTS incident_id INT(10) UNSIGNED DEFAULT NULL AFTER report_id,
    ADD COLUMN IF NOT EXISTS mdt_evidence_id INT(10) UNSIGNED DEFAULT NULL AFTER incident_id,
    ADD COLUMN IF NOT EXISTS pending_lab_analysis TINYINT(1) NOT NULL DEFAULT 0 AFTER status,
    ADD COLUMN IF NOT EXISTS pending_lab_reason VARCHAR(120) DEFAULT NULL AFTER pending_lab_analysis,
    ADD INDEX IF NOT EXISTS idx_evidence_incident_created (incident_id, created_at),
    ADD INDEX IF NOT EXISTS idx_evidence_pending_lab (pending_lab_analysis, created_at),
    ADD INDEX IF NOT EXISTS idx_evidence_mdt_evidence (mdt_evidence_id);

CREATE TABLE IF NOT EXISTS forensic_pending_evidence_queue (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    evidence_id INT(10) UNSIGNED NOT NULL,
    case_id INT(10) UNSIGNED DEFAULT NULL,
    report_id INT(10) UNSIGNED DEFAULT NULL,
    incident_id INT(10) UNSIGNED DEFAULT NULL,
    mdt_evidence_id INT(10) UNSIGNED DEFAULT NULL,
    status ENUM('pendente', 'em_analise', 'concluida', 'cancelada') NOT NULL DEFAULT 'pendente',
    queue_reason VARCHAR(120) DEFAULT NULL,
    queued_by VARCHAR(50) DEFAULT NULL,
    queued_by_name VARCHAR(120) DEFAULT NULL,
    consumed_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uniq_pending_queue_evidence (evidence_id),
    KEY idx_pending_queue_case (case_id, created_at),
    KEY idx_pending_queue_report (report_id, created_at),
    KEY idx_pending_queue_incident (incident_id, created_at),
    KEY idx_pending_queue_status (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
