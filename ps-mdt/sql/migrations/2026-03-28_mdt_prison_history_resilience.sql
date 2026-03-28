-- ============================================================
-- PS-MDT - Prison history resilience & performance
-- Idempotente: seguro para rodar múltiplas vezes
-- ============================================================

CREATE TABLE IF NOT EXISTS `mdt_prison_history` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(64) NOT NULL,
    `identifier` VARCHAR(64) DEFAULT NULL,
    `action` VARCHAR(40) NOT NULL,
    `reason` TEXT NULL,
    `report_id` INT UNSIGNED NULL,
    `case_id` INT UNSIGNED NULL,
    `warrant_report_id` INT UNSIGNED NULL,
    `time_before` INT NOT NULL DEFAULT 0,
    `time_after` INT NOT NULL DEFAULT 0,
    `applied_by` VARCHAR(100) NULL,
    `released_by` VARCHAR(100) NULL,
    `changed_by` VARCHAR(100) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_mdt_prison_history_citizen_created` (`citizenid`, `created_at`),
    KEY `idx_mdt_prison_history_created` (`created_at`),
    KEY `idx_mdt_prison_history_report` (`report_id`),
    KEY `idx_mdt_prison_history_case` (`case_id`),
    KEY `idx_mdt_prison_history_warrant_report` (`warrant_report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `mdt_prison_history`
    ADD COLUMN IF NOT EXISTS `action` VARCHAR(40) NOT NULL DEFAULT 'jail' AFTER `identifier`,
    ADD COLUMN IF NOT EXISTS `reason` TEXT NULL AFTER `action`,
    ADD COLUMN IF NOT EXISTS `report_id` INT UNSIGNED NULL AFTER `reason`,
    ADD COLUMN IF NOT EXISTS `case_id` INT UNSIGNED NULL AFTER `report_id`,
    ADD COLUMN IF NOT EXISTS `warrant_report_id` INT UNSIGNED NULL AFTER `case_id`,
    ADD COLUMN IF NOT EXISTS `applied_by` VARCHAR(100) NULL AFTER `time_after`,
    ADD COLUMN IF NOT EXISTS `released_by` VARCHAR(100) NULL AFTER `applied_by`,
    ADD COLUMN IF NOT EXISTS `changed_by` VARCHAR(100) NULL AFTER `released_by`,
    ADD COLUMN IF NOT EXISTS `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER `changed_by`;

ALTER TABLE `mdt_prison_history`
    ADD INDEX IF NOT EXISTS `idx_mdt_prison_history_citizen_created` (`citizenid`, `created_at`),
    ADD INDEX IF NOT EXISTS `idx_mdt_prison_history_created` (`created_at`),
    ADD INDEX IF NOT EXISTS `idx_mdt_prison_history_report` (`report_id`),
    ADD INDEX IF NOT EXISTS `idx_mdt_prison_history_case` (`case_id`),
    ADD INDEX IF NOT EXISTS `idx_mdt_prison_history_warrant_report` (`warrant_report_id`);
