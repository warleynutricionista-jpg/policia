ALTER TABLE `mdt_reports`
    ADD COLUMN IF NOT EXISTS `report_status` ENUM('draft','pending_review','approved','archived') NOT NULL DEFAULT 'draft' AFTER `type`,
    ADD COLUMN IF NOT EXISTS `requires_approval` TINYINT(1) NOT NULL DEFAULT 1 AFTER `report_status`,
    ADD COLUMN IF NOT EXISTS `signed_by` VARCHAR(64) NULL AFTER `authorplaintext`,
    ADD COLUMN IF NOT EXISTS `signed_at` TIMESTAMP NULL DEFAULT NULL AFTER `signed_by`,
    ADD COLUMN IF NOT EXISTS `signature_hash` VARCHAR(96) NULL AFTER `signed_at`,
    ADD COLUMN IF NOT EXISTS `approved_by` VARCHAR(64) NULL AFTER `signature_hash`,
    ADD COLUMN IF NOT EXISTS `approved_at` TIMESTAMP NULL DEFAULT NULL AFTER `approved_by`,
    ADD COLUMN IF NOT EXISTS `archived_by` VARCHAR(64) NULL AFTER `approved_at`,
    ADD COLUMN IF NOT EXISTS `archived_at` TIMESTAMP NULL DEFAULT NULL AFTER `archived_by`,
    ADD COLUMN IF NOT EXISTS `unarchived_by` VARCHAR(64) NULL AFTER `archived_at`,
    ADD COLUMN IF NOT EXISTS `unarchived_at` TIMESTAMP NULL DEFAULT NULL AFTER `unarchived_by`,
    ADD INDEX IF NOT EXISTS `idx_mdt_reports_status` (`report_status`);

UPDATE `mdt_reports`
SET `report_status` = CASE
        WHEN `report_status` IN ('draft','pending_review','approved','archived') THEN `report_status`
        ELSE 'draft'
    END,
    `requires_approval` = CASE
        WHEN `requires_approval` IS NULL THEN 1
        WHEN `requires_approval` IN (0, 1) THEN `requires_approval`
        ELSE 1
    END;
