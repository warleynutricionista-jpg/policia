-- ============================================================
-- PS-FORENSICS - Inteligência Forense v2 (score, revisão, alerta)
-- ============================================================

CREATE TABLE IF NOT EXISTS forensic_citizen_profiles (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    citizenid VARCHAR(50) NOT NULL,
    citizen_name VARCHAR(120) DEFAULT NULL,
    job_name VARCHAR(80) DEFAULT NULL,
    identification_status ENUM('confirmado_identificado','vestigio_desconhecido','parcial') NOT NULL DEFAULT 'confirmado_identificado',
    dna_profile_id INT UNSIGNED DEFAULT NULL,
    fingerprint_profile_id INT UNSIGNED DEFAULT NULL,
    suspicion_level ENUM('sem_suspeicao','pessoa_interesse','suspeito_tecnico','suspeito_prioritario','procurado_automatico') NOT NULL DEFAULT 'sem_suspeicao',
    suspicion_score INT NOT NULL DEFAULT 0,
    risk_level ENUM('baixo','medio','alto','critico') NOT NULL DEFAULT 'baixo',
    notes TEXT DEFAULT NULL,
    last_match_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(50) DEFAULT NULL,
    updated_by VARCHAR(50) DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_forensic_profile_citizen (citizenid),
    KEY idx_forensic_profile_level (suspicion_level, suspicion_score),
    CONSTRAINT fk_forensic_profile_dna FOREIGN KEY (dna_profile_id) REFERENCES forensic_dna_profiles(id) ON DELETE SET NULL,
    CONSTRAINT fk_forensic_profile_fp FOREIGN KEY (fingerprint_profile_id) REFERENCES forensic_fingerprint_profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS forensic_suspicion_rules (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    rule_key VARCHAR(100) NOT NULL,
    match_kind VARCHAR(40) NOT NULL DEFAULT 'all',
    association_level VARCHAR(40) NOT NULL DEFAULT 'all',
    base_weight DECIMAL(8,2) NOT NULL DEFAULT 10,
    confidence_multiplier DECIMAL(6,3) NOT NULL DEFAULT 1,
    reliability_multiplier DECIMAL(6,3) NOT NULL DEFAULT 1,
    requires_manual_review TINYINT(1) NOT NULL DEFAULT 0,
    can_auto_wanted TINYINT(1) NOT NULL DEFAULT 0,
    priority INT NOT NULL DEFAULT 10,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    description VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(50) DEFAULT 'system',
    PRIMARY KEY (id),
    UNIQUE KEY uk_suspicion_rule_key (rule_key),
    KEY idx_suspicion_rule_lookup (enabled, match_kind, association_level, priority)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS forensic_suspicion_settings (
    setting_key VARCHAR(80) NOT NULL,
    value_number DECIMAL(10,2) DEFAULT NULL,
    value_text VARCHAR(255) DEFAULT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by VARCHAR(50) DEFAULT 'system',
    PRIMARY KEY (setting_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS forensic_suspicion_snapshots (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    profile_id INT UNSIGNED DEFAULT NULL,
    citizenid VARCHAR(50) NOT NULL,
    case_id INT UNSIGNED DEFAULT NULL,
    report_id INT UNSIGNED DEFAULT NULL,
    scene_id INT UNSIGNED DEFAULT NULL,
    source_type VARCHAR(50) DEFAULT NULL,
    source_id INT UNSIGNED DEFAULT NULL,
    suspicion_level ENUM('sem_suspeicao','pessoa_interesse','suspeito_tecnico','suspeito_prioritario','procurado_automatico') NOT NULL,
    score_total INT NOT NULL,
    score_breakdown LONGTEXT DEFAULT NULL,
    triggered_rule VARCHAR(100) DEFAULT NULL,
    auto_wanted_candidate TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_suspicion_snapshot_citizen (citizenid, created_at),
    KEY idx_suspicion_snapshot_case (case_id, created_at),
    KEY idx_suspicion_snapshot_report (report_id, created_at),
    CONSTRAINT fk_suspicion_snapshot_profile FOREIGN KEY (profile_id) REFERENCES forensic_citizen_profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS forensic_evidence_person_links (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    evidence_id INT UNSIGNED NOT NULL,
    citizenid VARCHAR(50) NOT NULL,
    profile_id INT UNSIGNED DEFAULT NULL,
    possession_type ENUM('direta','indireta','ambiente','veiculo','corpo_roupa') NOT NULL DEFAULT 'ambiente',
    link_origin ENUM('apreensao','prisao','match_forense','manual') NOT NULL DEFAULT 'apreensao',
    confidence_score DECIMAL(5,2) NOT NULL DEFAULT 0,
    linked_by VARCHAR(50) DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_evidence_person_unique (evidence_id, citizenid, possession_type, link_origin),
    KEY idx_evidence_person_citizen (citizenid, created_at),
    KEY idx_evidence_person_evidence (evidence_id),
    CONSTRAINT fk_evidence_person_evidence FOREIGN KEY (evidence_id) REFERENCES forensic_evidence(id) ON DELETE CASCADE,
    CONSTRAINT fk_evidence_person_profile FOREIGN KEY (profile_id) REFERENCES forensic_citizen_profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS forensic_intelligence_alerts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    citizenid VARCHAR(50) DEFAULT NULL,
    case_id INT UNSIGNED DEFAULT NULL,
    report_id INT UNSIGNED DEFAULT NULL,
    severity ENUM('baixo','medio','alto','critico') NOT NULL DEFAULT 'medio',
    title VARCHAR(120) NOT NULL,
    message TEXT NOT NULL,
    status ENUM('novo','lido','em_analise','concluido') NOT NULL DEFAULT 'novo',
    assignee_citizenid VARCHAR(50) DEFAULT NULL,
    metadata LONGTEXT DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_alert_status (status, severity, created_at),
    KEY idx_alert_citizen (citizenid, created_at),
    KEY idx_alert_case (case_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS forensic_intelligence_reviews (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    intelligence_link_id INT UNSIGNED NOT NULL,
    citizenid VARCHAR(50) NOT NULL,
    decision ENUM('confirmado','rebaixado','invalidado','reexame') NOT NULL,
    previous_association_level VARCHAR(40) DEFAULT NULL,
    new_association_level VARCHAR(40) DEFAULT NULL,
    previous_confidence DECIMAL(5,2) DEFAULT NULL,
    new_confidence DECIMAL(5,2) DEFAULT NULL,
    reviewed_by VARCHAR(50) NOT NULL,
    reviewed_by_name VARCHAR(120) DEFAULT NULL,
    justification TEXT DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_review_link (intelligence_link_id, created_at),
    KEY idx_review_citizen (citizenid, created_at),
    CONSTRAINT fk_intelligence_review_link FOREIGN KEY (intelligence_link_id) REFERENCES forensic_intelligence_links(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


ALTER TABLE forensic_intelligence_links
    MODIFY COLUMN association_level ENUM('vestigio_relacionado','presumido','inconclusivo','compatibilidade_parcial','compatibilidade_forte','confirmacao') NOT NULL DEFAULT 'compatibilidade_parcial';

ALTER TABLE forensic_watchlist_events
    MODIFY COLUMN association_level ENUM('vestigio_relacionado','presumido','inconclusivo','compatibilidade_parcial','compatibilidade_forte','confirmacao') DEFAULT NULL;

ALTER TABLE forensic_intelligence_links
    ADD COLUMN IF NOT EXISTS review_status ENUM('pendente','confirmado','rebaixado','invalidado','reexame') NOT NULL DEFAULT 'pendente',
    ADD COLUMN IF NOT EXISTS reviewed_by VARCHAR(50) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS review_notes TEXT DEFAULT NULL;

ALTER TABLE forensic_watchlist_events
    MODIFY COLUMN event_type ENUM('suspect_linked','auto_wanted_added','auto_wanted_removed','profile_seeded','review_override') NOT NULL;

INSERT INTO forensic_suspicion_settings (setting_key, value_number, value_text, updated_by)
VALUES
    ('auto_wanted_threshold', 100, NULL, 'migration'),
    ('auto_wanted_min_factors', 3, NULL, 'migration')
ON DUPLICATE KEY UPDATE value_number = VALUES(value_number), updated_by = VALUES(updated_by);

INSERT INTO forensic_suspicion_rules
(rule_key, match_kind, association_level, base_weight, confidence_multiplier, reliability_multiplier, requires_manual_review, can_auto_wanted, priority, enabled, description, created_by)
VALUES
    ('dna_confirmacao', 'dna', 'confirmacao', 50, 1.25, 1.05, 0, 1, 100, 1, 'DNA confirmado com peso crítico', 'migration'),
    ('digital_forte', 'digital', 'compatibilidade_forte', 32, 1.10, 1.00, 0, 0, 90, 1, 'Digital forte', 'migration'),
    ('balistica_confirmada', 'arma', 'confirmacao', 45, 1.20, 1.00, 0, 1, 95, 1, 'Arma + balística confirmada', 'migration'),
    ('gsr_presumido', 'residuo_polvora', 'presumido', 18, 1.00, 0.90, 0, 0, 70, 1, 'GSR presumido', 'migration'),
    ('biologico_parcial', 'material_biologico', 'compatibilidade_parcial', 24, 1.00, 1.00, 0, 0, 70, 1, 'Vestígio biológico parcial', 'migration'),
    ('veiculo_relacionado', 'veiculo', 'vestigio_relacionado', 20, 1.00, 0.95, 0, 0, 60, 1, 'Veículo vinculado à cena', 'migration')
ON DUPLICATE KEY UPDATE
    base_weight = VALUES(base_weight),
    confidence_multiplier = VALUES(confidence_multiplier),
    reliability_multiplier = VALUES(reliability_multiplier),
    requires_manual_review = VALUES(requires_manual_review),
    can_auto_wanted = VALUES(can_auto_wanted),
    priority = VALUES(priority),
    enabled = VALUES(enabled),
    description = VALUES(description),
    created_by = VALUES(created_by);

INSERT INTO forensic_citizen_profiles (citizenid, citizen_name, created_by, updated_by)
SELECT fp.citizenid, COALESCE(fp.citizen_name, dp.citizen_name, 'Desconhecido'), 'migration', 'migration'
FROM forensic_fingerprint_profiles fp
LEFT JOIN forensic_dna_profiles dp ON dp.citizenid = fp.citizenid
ON DUPLICATE KEY UPDATE citizen_name = VALUES(citizen_name), updated_by = VALUES(updated_by);

UPDATE forensic_citizen_profiles cp
LEFT JOIN forensic_dna_profiles dp ON dp.citizenid = cp.citizenid
LEFT JOIN forensic_fingerprint_profiles fp ON fp.citizenid = cp.citizenid
SET cp.dna_profile_id = dp.id,
    cp.fingerprint_profile_id = fp.id,
    cp.updated_by = 'migration';
