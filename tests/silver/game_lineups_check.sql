--------------------------------------------------------------------------------
-- PURPOSE:  Data Quality Audit for Silver Layer - Table: game_lineups
-- DESCRIPTION: Performs comprehensive DQ checks on the game_lineups table to 
--              inform transformation logic in the Silver Layer.
--------------------------------------------------------------------------------

/* CHECK 01: Uniqueness & Primary Key Integrity
  Validates that 'game_lineups_id' is truly unique and serves as a valid PK.
*/

WITH pk_audit AS (
    SELECT 
        game_lineups_id,
        ROW_NUMBER() OVER(PARTITION BY game_lineups_id ORDER BY date) AS row_num
    FROM silver.game_lineups
)
SELECT 
    game_lineups_id, 
    row_num
FROM pk_audit
WHERE row_num > 1 
   OR game_lineups_id IS NULL;

/* CHECK 02: Referential Integrity (Orphan Records)
  Identifies records referencing IDs missing from parent dimension tables.
  Note: Orphans in 'players'/'clubs' are expected for non-Top 14 clubs.
*/

-- Orphan Games: Critical error if any record exists without a parent match.

SELECT 
    gl.game_lineups_id, 
    gl.game_id
FROM silver.game_lineups AS gl
WHERE NOT EXISTS (
    SELECT 1 FROM silver.games AS g WHERE g.game_id = gl.game_id
);

-- Orphan Players: Identified coverage gaps in Transfermarkt dataset.
SELECT 
    gl.game_lineups_id, 
    gl.player_id, 
    gl.player_name
FROM silver.game_lineups AS gl
WHERE NOT EXISTS (
    SELECT 1 FROM silver.players AS p WHERE p.player_id = gl.player_id
)
LIMIT 100;

-- Orphan Clubs (Context: Lower league clubs in cup games)
SELECT gl.game_lineups_id, gl.club_id
FROM silver.game_lineups gl
WHERE NOT EXISTS (
    SELECT 1 FROM silver.clubs c WHERE c.club_id = gl.club_id
)
LIMIT 100;

/* CHECK 03: Football Business Logic & Temporal Integrity
  Validates data against physical world rules and tournament regulations.
*/

-- Rule: Kit numbers should typically be 1-99. 
-- Findings: Records contain '-' and 3-digit values. Silver Layer must sanitize.

SELECT 
    game_lineups_id
FROM silver.game_lineups
WHERE number > 99; -- Checks for non-numeric characters

-- Temporal Alignment: Lineup date must match Game date.

SELECT
    gl.game_lineups_id,
    gl.game_id,
    gl.date AS lineup_date,
    g.date AS match_date
FROM silver.game_lineups AS gl
INNER JOIN silver.games AS g ON gl.game_id = g.game_id
WHERE gl.date != g.date;

-- Starting XI Logic: Domestic league matches must have exactly 22 starting players.
-- Observation: COVID-19 era matches and limited scouting for juniors cause minor deviations.

WITH lineup_counts AS (
    SELECT 
        game_id, 
        COUNT(*) AS starter_count
    FROM silver.game_lineups
    WHERE type = 'starting_lineup'
    GROUP BY game_id
    HAVING COUNT(*) != 22
)
SELECT 
    lc.game_id,
    lc.starter_count,
    g.competition_id,
    g.season
FROM lineup_counts AS lc
JOIN silver.games AS g ON lc.game_id = g.game_id
WHERE g.competition_type = 'domestic_league';

/* CHECK 04: Data Standardization & String Integrity
  Detects leading/trailing whitespaces and casing inconsistencies.
*/

SELECT 
    game_lineups_id,
    player_name,
    CASE 
        WHEN game_lineups_id != TRIM(game_lineups_id) THEN 'id_whitespace'
        WHEN player_name != TRIM(player_name) THEN 'player_name_whitespace'
        WHEN position != TRIM(position) THEN 'position_whitespace'
    END AS error_type
FROM silver.game_lineups
WHERE 
    game_lineups_id != TRIM(game_lineups_id) OR 
    player_name != TRIM(player_name) OR
    position != TRIM(position);

/* CHECK 05: Categorical Consistency
  Verifies that ENUM-like fields contain expected values.
*/

-- Findings: 'midfield' (lowercase) and empty strings found. 
-- Fix: Standardize to Initcap in Silver Layer.

SELECT DISTINCT is_starting_lineup FROM silver.game_lineups ORDER BY 1;
SELECT DISTINCT position FROM silver.game_lineups ORDER BY 1;
SELECT DISTINCT is_captain FROM silver.game_lineups ORDER BY 1;
SELECT DISTINCT number FROM silver.game_lineups ORDER BY 1;