--------------------------------------------------------------------------------
-- PURPOSE:  Data Quality Audit for Silver Layer - Table: player_valuations
-- DESCRIPTION: Validates referential integrity, football-specific logic, 
--              and string standardization for match event data.
--------------------------------------------------------------------------------

/* CHECK 01: Grain Integrity (Composite Key Validation)
  Description: In this table, player_id is NOT a PK. The grain is (player_id, date).
  Logic: A player cannot have two different market valuations on the exact same day.
*/

WITH pk_audit AS (
    SELECT 
        player_id,
        date,
        ROW_NUMBER() OVER(PARTITION BY player_id, date ORDER BY market_value_in_eur) AS row_num
    FROM silver.player_valuations
)
SELECT 
    player_id,
    date, 
    row_num
FROM pk_audit
WHERE row_num > 1 
   OR player_id IS NULL;

/* CHECK 02: Referential Integrity
  Identifies records referencing IDs missing from parent dimension tables.
*/

-- Players: Critical error if any record exists without a parent player in 'players' table.

SELECT 
    pv.player_id,
    pv.date,
    pv.market_value_in_eur
FROM silver.player_valuations AS pv
WHERE NOT EXISTS (
    SELECT 1 FROM silver.players AS p WHERE p.player_id = pv.player_id
);

/* CHECK 03: Football Business Logic & Valuation Anomalies
  Description: Validates that market values follow economic reality.
  Rule: market_value_in_eur must be non-negative. 
  Note: 0 is acceptable for retired/unattached players, but negative is a data corruption.
*/

SELECT
    player_id,
    date,
    market_value_in_eur
FROM silver.player_valuations
WHERE market_value_in_eur < 0;

-- Additional Logic: Future-dated valuations
-- Rule: Valuations cannot be dated in the future.

SELECT 
    player_id, 
    date, 
    market_value_in_eur
FROM silver.player_valuations
WHERE date > CURRENT_DATE;

/* CHECK 04: Data Standardization & String Integrity
  Description: Detects leading/trailing whitespaces in categorical and ID fields.
  Findings: Leading and trailing whitespaces identified in competition IDs and club names.
  Fix: Apply TRIM() to all affected string columns during transformation in silver layer.
*/

SELECT 
    player_id,
    date,
    CASE 
        WHEN current_club_name != TRIM(current_club_name) THEN 'club_name_whitespace'
        WHEN player_club_domestic_competition_id != TRIM(player_club_domestic_competition_id) THEN 'competition_id_whitespace'
    END AS error_type
FROM silver.player_valuations
WHERE 
    current_club_name != TRIM(current_club_name) OR 
    player_club_domestic_competition_id != TRIM(player_club_domestic_competition_id);

/* CHECK 05: Distribution Check
  Description: Check for extreme outliers that might indicate ingestion errors 
  (e.g., a player valued at 1 billion EUR or 1 EUR).
*/

SELECT 
    player_id, 
    market_value_in_eur
FROM silver.player_valuations
WHERE market_value_in_eur > 250000000; -- Current world records are around 180m-200m
