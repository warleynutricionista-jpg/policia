-- ============================================================
-- PS-FORENSICS Migration: 2026-03-27_forensics_world_evidence
-- Adiciona suporte ao sistema de coleta automática de campo.
--
-- MUDANÇAS:
--   • forensic_evidence: coluna collection_source
--     'manual' = registrado manualmente pela NUI
--     'campo'  = coletado de vestígio gerado por evento de jogo
--
--   • forensic_evidence: coluna world_evidence_id
--     ID do vestígio de mundo que originou esta evidência (rastreabilidade)
--
-- SEGURANÇA: Todas as alterações usam IF NOT EXISTS / IGNORE para
-- serem idempotentes (podem ser executadas múltiplas vezes sem erro).
-- ============================================================

-- Adicionar coluna collection_source (origem da coleta)
ALTER TABLE `forensic_evidence`
    ADD COLUMN IF NOT EXISTS `collection_source` ENUM('manual','campo') NOT NULL DEFAULT 'manual'
    COMMENT 'Origem da coleta: manual (NUI) ou campo (auto-spawn)';

-- Adicionar coluna world_evidence_id (rastreabilidade do vestígio de mundo)
ALTER TABLE `forensic_evidence`
    ADD COLUMN IF NOT EXISTS `world_evidence_id` VARCHAR(30) NULL DEFAULT NULL
    COMMENT 'ID do vestígio de mundo que originou esta evidência';

-- Índice para consultas por origem (dashboard, filtros)
CREATE INDEX IF NOT EXISTS `idx_evidence_collection_source`
    ON `forensic_evidence` (`collection_source`);

-- Índice para rastreabilidade reversa
CREATE INDEX IF NOT EXISTS `idx_evidence_world_id`
    ON `forensic_evidence` (`world_evidence_id`);
