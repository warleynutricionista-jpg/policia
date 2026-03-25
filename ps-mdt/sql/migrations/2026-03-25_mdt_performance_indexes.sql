-- MDT performance package (MSI Qbox / oxmysql)
-- Safe indexes for high-frequency lookups used by citizens, vehicles, weapons, reports and cases.

ALTER TABLE players
    ADD INDEX idx_players_citizenid (citizenid);

ALTER TABLE player_vehicles
    ADD INDEX idx_player_vehicles_citizenid (citizenid),
    ADD INDEX idx_player_vehicles_plate (plate);

ALTER TABLE mdt_profiles
    ADD INDEX idx_mdt_profiles_citizenid (citizenid),
    ADD INDEX idx_mdt_profiles_callsign (callsign);

ALTER TABLE mdt_weapons
    ADD INDEX idx_mdt_weapons_serial (serial),
    ADD INDEX idx_mdt_weapons_owner (owner),
    ADD INDEX idx_mdt_weapons_weaponmodel (weaponModel);

ALTER TABLE mdt_reports
    ADD INDEX idx_mdt_reports_datecreated (datecreated),
    ADD INDEX idx_mdt_reports_type (type);

ALTER TABLE mdt_reports_restrictions
    ADD INDEX idx_mdt_reports_restrictions_lookup (reportid, type, identifier);

ALTER TABLE mdt_report_vehicles
    ADD INDEX idx_mdt_report_vehicles_plate (plate),
    ADD INDEX idx_mdt_report_vehicles_reportid (reportid);

ALTER TABLE mdt_reports_warrants
    ADD INDEX idx_mdt_reports_warrants_citizen_expiry (citizenid, expirydate);

ALTER TABLE mdt_bolos
    ADD INDEX idx_mdt_bolos_type_status_subject (type, status, subject_id);

ALTER TABLE mdt_cases
    ADD INDEX idx_mdt_cases_status_department_updated (status, assigned_department, updated_at),
    ADD INDEX idx_mdt_cases_case_number (case_number);

ALTER TABLE mdt_case_reports
    ADD INDEX idx_mdt_case_reports_case (case_id),
    ADD INDEX idx_mdt_case_reports_report (report_id);
