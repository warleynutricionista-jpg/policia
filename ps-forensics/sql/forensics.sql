-- ============================================================
-- PS-FORENSICS - Sistema Forense Completo
-- Banco de Dados - Tabelas Forenses
-- Compatível com ps-mdt (QBox/QBX)
-- ============================================================

-- ============================================================
-- 1. CENAS DE CRIME
-- ============================================================
CREATE TABLE IF NOT EXISTS `forensic_crime_scenes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `scene_number` varchar(30) NOT NULL,
  `case_id` int(10) unsigned DEFAULT NULL,
  `report_id` int(10) unsigned DEFAULT NULL,
  `classification` enum(
    'homicidio','tentativa_homicidio','latrocinio',
    'roubo','furto','trafico','confronto','acidente',
    'sequestro','violencia_domestica','ocultacao_cadaver',
    'incendio_criminoso','explosao','envenenamento',
    'estupro','outros'
  ) NOT NULL DEFAULT 'outros',
  `status` enum('aberta','isolada','em_processamento','finalizada','reaberta') NOT NULL DEFAULT 'aberta',
  `location_name` varchar(200) DEFAULT NULL,
  `location_x` float DEFAULT NULL,
  `location_y` float DEFAULT NULL,
  `location_z` float DEFAULT NULL,
  `perimeter_radius` float DEFAULT 50.0,
  `description` text DEFAULT NULL,
  `weather_conditions` varchar(100) DEFAULT NULL,
  `lighting_conditions` varchar(100) DEFAULT NULL,
  `arrival_time` timestamp NULL DEFAULT NULL,
  `processing_start` timestamp NULL DEFAULT NULL,
  `processing_end` timestamp NULL DEFAULT NULL,
  `created_by` varchar(50) NOT NULL,
  `created_by_name` varchar(100) DEFAULT NULL,
  `department` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `scene_number` (`scene_number`),
  KEY `case_id` (`case_id`),
  KEY `report_id` (`report_id`),
  KEY `status` (`status`),
  KEY `classification` (`classification`),
  KEY `department` (`department`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Equipe atuando na cena
CREATE TABLE IF NOT EXISTS `forensic_scene_personnel` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `scene_id` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `role` enum('primeiro_respondente','investigador','perito','legista','fotografo','comandante') NOT NULL DEFAULT 'investigador',
  `arrival_time` timestamp NULL DEFAULT NULL,
  `departure_time` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `scene_id` (`scene_id`),
  KEY `citizenid` (`citizenid`),
  CONSTRAINT `FK_scene_personnel_scene` FOREIGN KEY (`scene_id`) REFERENCES `forensic_crime_scenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Fotos da cena
CREATE TABLE IF NOT EXISTS `forensic_scene_photos` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `scene_id` int(10) unsigned NOT NULL,
  `url` varchar(255) NOT NULL,
  `label` varchar(150) DEFAULT NULL,
  `taken_by` varchar(50) DEFAULT NULL,
  `taken_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `scene_id` (`scene_id`),
  CONSTRAINT `FK_scene_photos_scene` FOREIGN KEY (`scene_id`) REFERENCES `forensic_crime_scenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 2. EVIDÊNCIAS FORENSES (estende mdt_evidence_items)
-- ============================================================
CREATE TABLE IF NOT EXISTS `forensic_evidence` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_number` varchar(30) NOT NULL,
  `scene_id` int(10) unsigned DEFAULT NULL,
  `mdt_evidence_id` int(10) unsigned DEFAULT NULL,
  `case_id` int(10) unsigned DEFAULT NULL,
  `report_id` int(10) unsigned DEFAULT NULL,
  `category` enum(
    'balistica','biologica','digital_impressao','quimica',
    'documental','eletronica','vestimenta','veiculo',
    'objeto_cortante','objeto_contundente','outros'
  ) NOT NULL DEFAULT 'outros',
  `type` varchar(80) NOT NULL,
  `subtype` varchar(80) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `collection_location` varchar(200) DEFAULT NULL,
  `collection_x` float DEFAULT NULL,
  `collection_y` float DEFAULT NULL,
  `collection_z` float DEFAULT NULL,
  `collected_by` varchar(50) NOT NULL,
  `collected_by_name` varchar(100) DEFAULT NULL,
  `collection_method` varchar(100) DEFAULT NULL,
  `collection_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `seal_number` varchar(50) DEFAULT NULL,
  `status` enum('coletada','lacrada','em_analise','analisada','armazenada','descartada','devolvida','em_julgamento') NOT NULL DEFAULT 'coletada',
  `storage_location` varchar(100) DEFAULT NULL,
  `photo_url` varchar(255) DEFAULT NULL,
  `linked_citizenid` varchar(50) DEFAULT NULL,
  `linked_vehicle_plate` varchar(20) DEFAULT NULL,
  `linked_weapon_serial` varchar(50) DEFAULT NULL,
  `priority` enum('baixa','media','alta','urgente') NOT NULL DEFAULT 'media',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `evidence_number` (`evidence_number`),
  KEY `scene_id` (`scene_id`),
  KEY `mdt_evidence_id` (`mdt_evidence_id`),
  KEY `case_id` (`case_id`),
  KEY `category` (`category`),
  KEY `status` (`status`),
  KEY `linked_citizenid` (`linked_citizenid`),
  KEY `linked_weapon_serial` (`linked_weapon_serial`),
  CONSTRAINT `FK_forensic_evidence_scene` FOREIGN KEY (`scene_id`) REFERENCES `forensic_crime_scenes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 3. CADEIA DE CUSTÓDIA FORENSE
-- ============================================================
CREATE TABLE IF NOT EXISTS `forensic_chain_of_custody` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_id` int(10) unsigned NOT NULL,
  `action` enum(
    'coletada','lacrada','transportada','recebida',
    'aberta_analise','relacrada','armazenada',
    'transferida','descartada','devolvida',
    'encaminhada_julgamento','fotografada','visualizada'
  ) NOT NULL,
  `from_citizenid` varchar(50) DEFAULT NULL,
  `from_name` varchar(100) DEFAULT NULL,
  `to_citizenid` varchar(50) DEFAULT NULL,
  `to_name` varchar(100) DEFAULT NULL,
  `location` varchar(200) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `evidence_id` (`evidence_id`),
  CONSTRAINT `FK_custody_evidence` FOREIGN KEY (`evidence_id`) REFERENCES `forensic_evidence` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 4. IMPRESSÕES DIGITAIS
-- ============================================================

-- Banco de digitais cadastradas (perfil de cada cidadão)
CREATE TABLE IF NOT EXISTS `forensic_fingerprint_profiles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `citizen_name` varchar(100) DEFAULT NULL,
  `fingerprint_hash` varchar(64) NOT NULL,
  `registered_by` varchar(50) DEFAULT NULL,
  `registered_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`),
  UNIQUE KEY `fingerprint_hash` (`fingerprint_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Digitais coletadas em cenas/objetos
CREATE TABLE IF NOT EXISTS `forensic_fingerprints_collected` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_id` int(10) unsigned DEFAULT NULL,
  `scene_id` int(10) unsigned DEFAULT NULL,
  `source_description` varchar(200) NOT NULL,
  `source_type` enum('objeto','veiculo','arma','porta','vidro','superficie','corpo','outro') NOT NULL DEFAULT 'objeto',
  `fingerprint_hash` varchar(64) DEFAULT NULL,
  `quality` enum('boa','parcial','degradada','ilegivel') NOT NULL DEFAULT 'parcial',
  `match_status` enum('pendente','sem_correspondencia','parcial','positiva') NOT NULL DEFAULT 'pendente',
  `matched_citizenid` varchar(50) DEFAULT NULL,
  `matched_name` varchar(100) DEFAULT NULL,
  `match_confidence` float DEFAULT NULL,
  `collected_by` varchar(50) NOT NULL,
  `collected_by_name` varchar(100) DEFAULT NULL,
  `analyzed_by` varchar(50) DEFAULT NULL,
  `analyzed_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `evidence_id` (`evidence_id`),
  KEY `scene_id` (`scene_id`),
  KEY `match_status` (`match_status`),
  KEY `matched_citizenid` (`matched_citizenid`),
  CONSTRAINT `FK_fingerprints_evidence` FOREIGN KEY (`evidence_id`) REFERENCES `forensic_evidence` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_fingerprints_scene` FOREIGN KEY (`scene_id`) REFERENCES `forensic_crime_scenes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 5. DNA
-- ============================================================

-- Perfis genéticos cadastrados
CREATE TABLE IF NOT EXISTS `forensic_dna_profiles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `citizen_name` varchar(100) DEFAULT NULL,
  `dna_hash` varchar(64) NOT NULL,
  `blood_type` varchar(10) DEFAULT NULL,
  `registered_by` varchar(50) DEFAULT NULL,
  `registered_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`),
  UNIQUE KEY `dna_hash` (`dna_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Amostras de DNA coletadas
CREATE TABLE IF NOT EXISTS `forensic_dna_samples` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_id` int(10) unsigned DEFAULT NULL,
  `scene_id` int(10) unsigned DEFAULT NULL,
  `source_type` enum('sangue','cabelo','saliva','tecido','suor','roupa','arma','veiculo','corpo_vitima','corpo_suspeito','outro') NOT NULL,
  `source_description` varchar(200) DEFAULT NULL,
  `dna_hash` varchar(64) DEFAULT NULL,
  `match_status` enum('pendente','sem_correspondencia','parcialmente_compativel','compativel','incompativel') NOT NULL DEFAULT 'pendente',
  `matched_citizenid` varchar(50) DEFAULT NULL,
  `matched_name` varchar(100) DEFAULT NULL,
  `match_confidence` float DEFAULT NULL,
  `collected_by` varchar(50) NOT NULL,
  `collected_by_name` varchar(100) DEFAULT NULL,
  `analyzed_by` varchar(50) DEFAULT NULL,
  `analyzed_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `evidence_id` (`evidence_id`),
  KEY `scene_id` (`scene_id`),
  KEY `match_status` (`match_status`),
  KEY `matched_citizenid` (`matched_citizenid`),
  CONSTRAINT `FK_dna_evidence` FOREIGN KEY (`evidence_id`) REFERENCES `forensic_evidence` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_dna_scene` FOREIGN KEY (`scene_id`) REFERENCES `forensic_crime_scenes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 6. BALÍSTICA
-- ============================================================
CREATE TABLE IF NOT EXISTS `forensic_ballistics` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_id` int(10) unsigned DEFAULT NULL,
  `scene_id` int(10) unsigned DEFAULT NULL,
  `item_type` enum('capsula','projetil','arma','municao') NOT NULL,
  `caliber` varchar(30) DEFAULT NULL,
  `weapon_serial` varchar(50) DEFAULT NULL,
  `weapon_model` varchar(80) DEFAULT NULL,
  `weapon_scratched` tinyint(1) DEFAULT 0,
  `rifling_match` enum('pendente','sem_correspondencia','compativel','confirmado') NOT NULL DEFAULT 'pendente',
  `matched_weapon_serial` varchar(50) DEFAULT NULL,
  `linked_scenes` text DEFAULT NULL COMMENT 'JSON array of scene IDs where same weapon was used',
  `collected_by` varchar(50) NOT NULL,
  `analyzed_by` varchar(50) DEFAULT NULL,
  `analyzed_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `evidence_id` (`evidence_id`),
  KEY `scene_id` (`scene_id`),
  KEY `weapon_serial` (`weapon_serial`),
  KEY `caliber` (`caliber`),
  CONSTRAINT `FK_ballistics_evidence` FOREIGN KEY (`evidence_id`) REFERENCES `forensic_evidence` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_ballistics_scene` FOREIGN KEY (`scene_id`) REFERENCES `forensic_crime_scenes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 7. EXAMES LABORATORIAIS / TESTES
-- ============================================================
CREATE TABLE IF NOT EXISTS `forensic_lab_tests` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_id` int(10) unsigned DEFAULT NULL,
  `scene_id` int(10) unsigned DEFAULT NULL,
  `test_type` enum(
    'residuo_polvora_maos','residuo_polvora_roupa','residuo_polvora_arma','residuo_polvora_veiculo',
    'teste_droga_presuntivo','analise_substancia','analise_pureza',
    'teste_sangue_presuntivo','analise_fluido_biologico',
    'coleta_dna','comparacao_dna',
    'coleta_digital','revelacao_digital','comparacao_digital',
    'confronto_balistico','analise_municao','analise_capsula','analise_projetil',
    'analise_vestimenta','analise_objeto_cortante','analise_objeto_contundente',
    'analise_eletronico','analise_quimico',
    'exame_cadaverico','necropsia','identificacao_cadaver',
    'toxicologico','alcoolemia',
    'outro'
  ) NOT NULL,
  `test_name` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `target_citizenid` varchar(50) DEFAULT NULL,
  `target_name` varchar(100) DEFAULT NULL,
  `target_vehicle` varchar(20) DEFAULT NULL,
  `target_weapon_serial` varchar(50) DEFAULT NULL,
  `result_level` enum('pendente','presumido','inconclusivo','compativel','confirmado','negativo') NOT NULL DEFAULT 'pendente',
  `result_details` text DEFAULT NULL,
  `processing_time_minutes` int(10) unsigned DEFAULT 0,
  `requested_by` varchar(50) NOT NULL,
  `requested_by_name` varchar(100) DEFAULT NULL,
  `performed_by` varchar(50) DEFAULT NULL,
  `performed_by_name` varchar(100) DEFAULT NULL,
  `started_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `status` enum('solicitado','em_andamento','concluido','cancelado') NOT NULL DEFAULT 'solicitado',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `evidence_id` (`evidence_id`),
  KEY `scene_id` (`scene_id`),
  KEY `test_type` (`test_type`),
  KEY `status` (`status`),
  KEY `target_citizenid` (`target_citizenid`),
  CONSTRAINT `FK_lab_tests_evidence` FOREIGN KEY (`evidence_id`) REFERENCES `forensic_evidence` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_lab_tests_scene` FOREIGN KEY (`scene_id`) REFERENCES `forensic_crime_scenes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 8. DROGAS E SUBSTÂNCIAS
-- ============================================================
CREATE TABLE IF NOT EXISTS `forensic_drug_analysis` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_id` int(10) unsigned DEFAULT NULL,
  `scene_id` int(10) unsigned DEFAULT NULL,
  `lab_test_id` int(10) unsigned DEFAULT NULL,
  `substance_category` enum(
    'cocaina','maconha','crack','metanfetamina',
    'comprimidos','substancia_desconhecida','solvente',
    'droga_liquida','drogas_sinteticas','opioides','outros'
  ) NOT NULL DEFAULT 'substancia_desconhecida',
  `preliminary_classification` varchar(100) DEFAULT NULL,
  `confirmed_substance` varchar(100) DEFAULT NULL,
  `weight_grams` float DEFAULT NULL,
  `purity_percent` float DEFAULT NULL,
  `quantity_units` int(10) unsigned DEFAULT NULL,
  `test_result` enum('suspeita','presumido','confirmado','negativo') NOT NULL DEFAULT 'suspeita',
  `analyzed_by` varchar(50) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `evidence_id` (`evidence_id`),
  KEY `lab_test_id` (`lab_test_id`),
  KEY `substance_category` (`substance_category`),
  CONSTRAINT `FK_drug_evidence` FOREIGN KEY (`evidence_id`) REFERENCES `forensic_evidence` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_drug_lab_test` FOREIGN KEY (`lab_test_id`) REFERENCES `forensic_lab_tests` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 9. MEDICINA LEGAL / NECROPSIA
-- ============================================================
CREATE TABLE IF NOT EXISTS `forensic_autopsy` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `scene_id` int(10) unsigned DEFAULT NULL,
  `case_id` int(10) unsigned DEFAULT NULL,
  `report_id` int(10) unsigned DEFAULT NULL,
  `victim_citizenid` varchar(50) DEFAULT NULL,
  `victim_name` varchar(100) DEFAULT NULL,
  `victim_status` enum('identificado','nao_identificado','parcialmente_identificado') NOT NULL DEFAULT 'nao_identificado',
  `cause_of_death` enum(
    'arma_de_fogo','arma_branca','trauma_contundente',
    'asfixia','queimadura','overdose','envenenamento',
    'afogamento','eletrocussao','multiplos_ferimentos',
    'causa_natural','indeterminado'
  ) NOT NULL DEFAULT 'indeterminado',
  `manner_of_death` enum('homicidio','suicidio','acidente','natural','indeterminado') NOT NULL DEFAULT 'indeterminado',
  `estimated_time_of_death` timestamp NULL DEFAULT NULL,
  `body_temperature` float DEFAULT NULL,
  `rigor_mortis` enum('ausente','inicial','completo','resolvendo') DEFAULT NULL,
  `livor_mortis` varchar(100) DEFAULT NULL,
  `trauma_description` text DEFAULT NULL,
  `wounds_count` int(10) unsigned DEFAULT 0,
  `wounds_description` text DEFAULT NULL,
  `toxicology_result` text DEFAULT NULL,
  `substances_found` text DEFAULT NULL COMMENT 'JSON array',
  `dna_collected` tinyint(1) DEFAULT 0,
  `fingerprints_collected` tinyint(1) DEFAULT 0,
  `clothing_description` text DEFAULT NULL,
  `personal_effects` text DEFAULT NULL,
  `external_exam_notes` text DEFAULT NULL,
  `internal_exam_notes` text DEFAULT NULL,
  `conclusion` text DEFAULT NULL,
  `examiner_citizenid` varchar(50) NOT NULL,
  `examiner_name` varchar(100) DEFAULT NULL,
  `exam_start` timestamp NULL DEFAULT NULL,
  `exam_end` timestamp NULL DEFAULT NULL,
  `status` enum('pendente','em_andamento','concluido') NOT NULL DEFAULT 'pendente',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `scene_id` (`scene_id`),
  KEY `case_id` (`case_id`),
  KEY `victim_citizenid` (`victim_citizenid`),
  KEY `cause_of_death` (`cause_of_death`),
  KEY `examiner_citizenid` (`examiner_citizenid`),
  CONSTRAINT `FK_autopsy_scene` FOREIGN KEY (`scene_id`) REFERENCES `forensic_crime_scenes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 10. LAUDOS TÉCNICOS
-- ============================================================
CREATE TABLE IF NOT EXISTS `forensic_reports` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `report_number` varchar(30) NOT NULL,
  `scene_id` int(10) unsigned DEFAULT NULL,
  `case_id` int(10) unsigned DEFAULT NULL,
  `mdt_report_id` int(10) unsigned DEFAULT NULL,
  `type` enum(
    'laudo_pericial','laudo_balistico','laudo_toxicologico',
    'laudo_dna','laudo_digital','laudo_necropsia',
    'laudo_drogas','laudo_residuo','laudo_sangue',
    'laudo_quimico','parecer_tecnico','outro'
  ) NOT NULL,
  `title` varchar(200) NOT NULL,
  `summary` text DEFAULT NULL,
  `body` longtext DEFAULT NULL,
  `conclusion` text DEFAULT NULL,
  `evidence_ids` text DEFAULT NULL COMMENT 'JSON array of forensic_evidence IDs',
  `lab_test_ids` text DEFAULT NULL COMMENT 'JSON array of forensic_lab_tests IDs',
  `linked_citizenids` text DEFAULT NULL COMMENT 'JSON array',
  `linked_weapon_serials` text DEFAULT NULL COMMENT 'JSON array',
  `linked_vehicle_plates` text DEFAULT NULL COMMENT 'JSON array',
  `author_citizenid` varchar(50) NOT NULL,
  `author_name` varchar(100) DEFAULT NULL,
  `author_role` varchar(50) DEFAULT NULL,
  `reviewer_citizenid` varchar(50) DEFAULT NULL,
  `reviewer_name` varchar(100) DEFAULT NULL,
  `status` enum('rascunho','em_revisao','finalizado','anexado_mdt') NOT NULL DEFAULT 'rascunho',
  `finalized_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `report_number` (`report_number`),
  KEY `scene_id` (`scene_id`),
  KEY `case_id` (`case_id`),
  KEY `mdt_report_id` (`mdt_report_id`),
  KEY `type` (`type`),
  KEY `status` (`status`),
  KEY `author_citizenid` (`author_citizenid`),
  CONSTRAINT `FK_forensic_reports_scene` FOREIGN KEY (`scene_id`) REFERENCES `forensic_crime_scenes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 11. CRUZAMENTO DE DADOS INVESTIGATIVOS
-- ============================================================
CREATE TABLE IF NOT EXISTS `forensic_cross_references` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `source_type` enum('evidence','scene','fingerprint','dna','ballistic','drug','autopsy','report') NOT NULL,
  `source_id` int(10) unsigned NOT NULL,
  `target_type` enum('citizenid','vehicle','weapon','scene','case','report','evidence') NOT NULL,
  `target_id` varchar(100) NOT NULL,
  `relationship` varchar(100) DEFAULT NULL,
  `confidence` enum('baixa','media','alta','confirmada') NOT NULL DEFAULT 'media',
  `created_by` varchar(50) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `source_type_id` (`source_type`, `source_id`),
  KEY `target_type_id` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 12. LOG DE ATIVIDADES FORENSES
-- ============================================================
CREATE TABLE IF NOT EXISTS `forensic_audit_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `actor_citizenid` varchar(50) DEFAULT NULL,
  `actor_name` varchar(100) DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(50) NOT NULL,
  `entity_id` int(10) unsigned DEFAULT NULL,
  `details` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `entity_type` (`entity_type`),
  KEY `actor_citizenid` (`actor_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
