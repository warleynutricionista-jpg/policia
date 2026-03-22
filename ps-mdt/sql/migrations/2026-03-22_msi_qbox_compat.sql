ALTER TABLE `mdt_reports`
    ADD COLUMN IF NOT EXISTS `contentplaintext` TEXT NULL,
    ADD COLUMN IF NOT EXISTS `authorplaintext` VARCHAR(100) NULL,
    ADD COLUMN IF NOT EXISTS `dateupdated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE `mdt_bolos`
    ADD COLUMN IF NOT EXISTS `subject_name` VARCHAR(100) NULL,
    ADD COLUMN IF NOT EXISTS `reportId` INT(11) UNSIGNED NULL,
    ADD COLUMN IF NOT EXISTS `notes` TEXT NULL,
    ADD COLUMN IF NOT EXISTS `status` ENUM('active','inactive','resolved') NOT NULL DEFAULT 'active';

ALTER TABLE `mdt_reports_restrictions`
    ADD COLUMN IF NOT EXISTS `type` VARCHAR(32) NULL,
    ADD COLUMN IF NOT EXISTS `identifier` VARCHAR(64) NULL;

UPDATE `mdt_reports`
SET `contentplaintext` = COALESCE(`contentplaintext`, '')
WHERE `contentplaintext` IS NULL;

UPDATE `mdt_bolos`
SET `status` = 'active'
WHERE `status` IS NULL OR `status` = '';
