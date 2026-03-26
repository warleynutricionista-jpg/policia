-- ============================================================
-- PS-FORENSICS - Migration: Deduplication & Integrity Constraints
-- Data: 2026-03-26
-- Objetivo: Garantir fonte unica de dados, prevenir duplicidade,
--           adicionar indices para integridade referencial
-- ============================================================

-- ============================================================
-- 1. UNIQUE CONSTRAINTS - Prevenir duplicidade de perfis
-- ============================================================

-- DNA: apenas um perfil por cidadao
ALTER TABLE `forensic_dna_profiles`
  ADD UNIQUE KEY `uk_dna_profile_citizenid` (`citizenid`);

-- Fingerprints: apenas um perfil por cidadao
ALTER TABLE `forensic_fingerprint_profiles`
  ADD UNIQUE KEY `uk_fp_profile_citizenid` (`citizenid`);

-- Weapon registry: apenas um registro por serial
ALTER TABLE `forensic_weapon_registry`
  ADD UNIQUE KEY `uk_weapon_serial` (`serial`);

-- ============================================================
-- 2. INDEXES para consultas frequentes de integracao MDT
-- ============================================================

-- Evidencias: indice para busca por mdt_evidence_id
ALTER TABLE `forensic_evidence`
  ADD KEY `idx_evidence_mdt_id` (`mdt_evidence_id`);

-- Evidencias: indice para busca por linked_citizenid
ALTER TABLE `forensic_evidence`
  ADD KEY `idx_evidence_linked_citizen` (`linked_citizenid`);

-- Evidencias: indice para busca por linked_weapon_serial
ALTER TABLE `forensic_evidence`
  ADD KEY `idx_evidence_linked_weapon` (`linked_weapon_serial`);

-- Evidencias: indice para busca por linked_vehicle_plate
ALTER TABLE `forensic_evidence`
  ADD KEY `idx_evidence_linked_vehicle` (`linked_vehicle_plate`);

-- Balistica: indice por weapon_serial e matched_weapon_serial
ALTER TABLE `forensic_ballistics`
  ADD KEY `idx_ballistics_weapon_serial` (`weapon_serial`);

ALTER TABLE `forensic_ballistics`
  ADD KEY `idx_ballistics_matched_serial` (`matched_weapon_serial`);

-- Cross references: indice composto para evitar duplicatas
ALTER TABLE `forensic_cross_references`
  ADD KEY `idx_crossref_source` (`source_type`, `source_id`);

ALTER TABLE `forensic_cross_references`
  ADD KEY `idx_crossref_target` (`target_type`, `target_id`);

-- DNA samples: indice por matched_citizenid
ALTER TABLE `forensic_dna_samples`
  ADD KEY `idx_dna_matched_citizen` (`matched_citizenid`);

-- Fingerprints collected: indice por matched_citizenid
ALTER TABLE `forensic_fingerprints_collected`
  ADD KEY `idx_fp_matched_citizen` (`matched_citizenid`);

-- Lab tests: indice por test_type e status
ALTER TABLE `forensic_lab_tests`
  ADD KEY `idx_labtests_type_status` (`test_type`, `status`);

-- ============================================================
-- 3. PREVENCAO DE DUPLICIDADE em cross_references
-- ============================================================

-- Indice unico para evitar referencias cruzadas duplicadas
-- (mesma fonte + mesmo alvo + mesmo relacionamento)
ALTER TABLE `forensic_cross_references`
  ADD UNIQUE KEY `uk_crossref_unique` (`source_type`, `source_id`, `target_type`, `target_id`, `relationship`);

-- ============================================================
-- 4. PREVENCAO DE DUPLICIDADE em investigative subjects
-- ============================================================

ALTER TABLE `forensic_investigative_subjects`
  ADD UNIQUE KEY `uk_investigative_citizenid` (`citizenid`);

-- ============================================================
-- 5. AUDIT LOG - indice para consultas por ator
-- ============================================================

ALTER TABLE `forensic_audit_log`
  ADD KEY `idx_audit_actor` (`actor_citizenid`);

ALTER TABLE `forensic_audit_log`
  ADD KEY `idx_audit_entity` (`entity_type`, `entity_id`);
