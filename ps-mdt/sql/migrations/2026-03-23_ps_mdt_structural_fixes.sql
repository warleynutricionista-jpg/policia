UPDATE `mdt_profiles`
SET `callsign` = NULL
WHERE `callsign` IS NOT NULL
  AND UPPER(TRIM(`callsign`)) IN ('SEM CALLSIGN', 'SEM INDICATIVO', 'NO CALLSIGN', 'N/A', 'NULL', 'NONE');

UPDATE `mdt_profiles`
SET `badge_number` = NULL
WHERE `badge_number` IS NOT NULL
  AND UPPER(TRIM(`badge_number`)) IN ('SEM CALLSIGN', 'SEM INDICATIVO', 'NO CALLSIGN', 'N/A', 'NULL', 'NONE');
