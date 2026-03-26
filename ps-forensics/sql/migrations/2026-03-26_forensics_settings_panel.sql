-- ============================================================
-- Migration: Settings Panel Tables
-- Criado: 2026-03-26
-- Descrição: Tabelas para configuração dinâmica do painel de perícia
-- ============================================================

CREATE TABLE IF NOT EXISTS `forensic_panel_settings` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tab_id` VARCHAR(50) NOT NULL,
    `min_level` TINYINT NOT NULL DEFAULT 1,
    `allowed_jobs` JSON NULL,
    `is_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `updated_by` VARCHAR(50) NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_tab_id` (`tab_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `forensic_permission_roles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `job` VARCHAR(50) NOT NULL,
    `grade` INT NOT NULL DEFAULT 0,
    `permissions` JSON NOT NULL,
    `updated_by` VARCHAR(50) NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_job_grade` (`job`, `grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
