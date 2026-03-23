ALTER TABLE `mdt_reports`
    ADD COLUMN IF NOT EXISTS `contentplaintext` TEXT NULL,
    ADD COLUMN IF NOT EXISTS `authorplaintext` VARCHAR(100) NULL,
    ADD COLUMN IF NOT EXISTS `dateupdated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE `mdt_bolos`
    ADD COLUMN IF NOT EXISTS `type` ENUM('citizen','vehicle','weapon','property','other') NOT NULL DEFAULT 'citizen',
    ADD COLUMN IF NOT EXISTS `subject_id` VARCHAR(50) NULL,
    ADD COLUMN IF NOT EXISTS `subject_name` VARCHAR(100) NULL,
    ADD COLUMN IF NOT EXISTS `reportId` INT(11) UNSIGNED NULL,
    ADD COLUMN IF NOT EXISTS `notes` TEXT NULL,
    ADD COLUMN IF NOT EXISTS `status` ENUM('active','inactive','resolved') NOT NULL DEFAULT 'active';

ALTER TABLE `mdt_reports_restrictions`
    ADD COLUMN IF NOT EXISTS `type` VARCHAR(32) NULL,
    ADD COLUMN IF NOT EXISTS `identifier` VARCHAR(64) NULL;

ALTER TABLE `mdt_tags`
    ADD COLUMN IF NOT EXISTS `job_type` ENUM('leo','ems','all') NOT NULL DEFAULT 'all';

CREATE TABLE IF NOT EXISTS `mdt_report_templates` (
    `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `content` LONGTEXT NOT NULL,
    `job_type` ENUM('leo','ems','all') NOT NULL DEFAULT 'all',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_mdt_report_templates_job_type` (`job_type`),
    KEY `idx_mdt_report_templates_type_name` (`type`, `name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `mdt_report_templates`
    ADD COLUMN IF NOT EXISTS `job_type` ENUM('leo','ems','all') NOT NULL DEFAULT 'all' AFTER `content`;

ALTER TABLE `player_vehicles`
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_information` TEXT NULL,
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_points` INT(11) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_status` ENUM('valid','suspended','expired','impounded') NOT NULL DEFAULT 'valid',
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_stolen` TINYINT(1) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_boloactive` TINYINT(1) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `mdt_vehicle_image` VARCHAR(255) NULL;

ALTER TABLE `mdt_reports`
    ADD INDEX IF NOT EXISTS `idx_mdt_reports_datecreated` (`datecreated`),
    ADD INDEX IF NOT EXISTS `idx_mdt_reports_author` (`author`);

ALTER TABLE `mdt_bolos`
    ADD INDEX IF NOT EXISTS `type` (`type`),
    ADD INDEX IF NOT EXISTS `status` (`status`),
    ADD INDEX IF NOT EXISTS `reportId` (`reportId`),
    ADD INDEX IF NOT EXISTS `idx_mdt_bolos_type_status_subject` (`type`, `status`, `subject_id`);

ALTER TABLE `mdt_reports_restrictions`
    ADD INDEX IF NOT EXISTS `idx_mdt_reports_restrictions_type_identifier` (`type`, `identifier`);

ALTER TABLE `mdt_tags`
    ADD INDEX IF NOT EXISTS `idx_mdt_tags_job_type` (`job_type`);

ALTER TABLE `mdt_report_templates`
    ADD INDEX IF NOT EXISTS `idx_mdt_report_templates_job_type` (`job_type`),
    ADD INDEX IF NOT EXISTS `idx_mdt_report_templates_type_name` (`type`, `name`);

ALTER TABLE `player_vehicles`
    ADD INDEX IF NOT EXISTS `idx_player_vehicles_citizenid_plate` (`citizenid`, `plate`);

ALTER TABLE `mdt_evidence_items`
    ADD INDEX IF NOT EXISTS `idx_mdt_evidence_items_case_created` (`case_id`, `created_at`),
    ADD INDEX IF NOT EXISTS `idx_mdt_evidence_items_report_created` (`report_id`, `created_at`),
    ADD INDEX IF NOT EXISTS `idx_mdt_evidence_items_type_stored` (`type`, `stored`);

ALTER TABLE `mdt_reports_involved`
    ADD INDEX IF NOT EXISTS `idx_mdt_reports_involved_citizenid` (`citizenid`);

ALTER TABLE `mdt_reports_charges`
    ADD INDEX IF NOT EXISTS `idx_mdt_reports_charges_citizenid` (`citizenid`);

ALTER TABLE `mdt_arrests`
    ADD INDEX IF NOT EXISTS `idx_mdt_arrests_citizenid` (`citizenid`);

UPDATE `mdt_reports`
SET `contentplaintext` = COALESCE(`contentplaintext`, '')
WHERE `contentplaintext` IS NULL;

UPDATE `mdt_bolos`
SET `status` = 'active'
WHERE `status` IS NULL OR `status` = '';
