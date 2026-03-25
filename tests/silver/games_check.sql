--------------------------------------------------------------------------------
-- PURPOSE:  Data Quality Audit for Silver Layer - Table: games
-- DESCRIPTION: Validates match results, score consistency, and referential 
--              integrity for the primary games fact table.
--------------------------------------------------------------------------------

/* CHECK 01: Uniqueness & Primary Key Integrity
  Description: Validates that game_id is unique and non-null.
*/

WITH id_validation AS (
    SELECT 
        game_id,
        ROW_NUMBER() OVER(PARTITION BY game_id ORDER BY date) as row_num
    FROM silver.games
)
SELECT game_id, row_num
FROM id_validation
WHERE row_num > 1 OR game_id IS NULL;

/* CHECK 02: Referential Integrity (Orphan Records)
  Description: Checks for matches pointing to non-existent competitions.
*/

SELECT g.game_id, g.competition_id
FROM silver.games AS g
WHERE NOT EXISTS (
    SELECT 1 FROM silver.competitions AS c WHERE c.competition_id = g.competition_id
);

/* CHECK 03: Football Business Logic & Score Integrity
  Description: Validates that the 'aggregate' string matches individual goal counts
               and that goal values are physically possible.
*/

SELECT
    game_id,
    home_club_goals,
    away_club_goals,
    aggregate
FROM silver.games
WHERE aggregate != CONCAT(home_club_goals,':',away_club_goals);

-- Goal Logic: Scores cannot be negative or missing, Positions cannot be negative

SELECT
    game_id,
    home_club_id,
    away_club_id,
    home_club_goals,
    away_club_goals,
    aggregate
FROM silver.games
WHERE 
    home_club_goals < 0 OR
    away_club_goals < 0 OR
    home_club_goals IS NULL OR
    away_club_goals IS NULL OR
    home_club_position < 1 OR
    away_club_position < 1;

-- Attendance Outliers: Flagging impossible attendance (e.g., > 150k)

SELECT game_id, stadium, attendance 
FROM silver.games 
WHERE attendance > 150000;

/* CHECK 04: Data Standardization & String Integrity
  Description: Identifies fields with whitespace issues requiring TRIM().
  Findings: ~155 records identified with leading/trailing whitespaces.
  Fix: Apply TRIM() to all categorical and ID fields.
*/

SELECT 
    game_id,
    CASE 
        WHEN competition_id != TRIM(competition_id) THEN 'competition_id_whitespace'
        WHEN round != TRIM(round) THEN 'round_whitespace'
        WHEN home_club_manager_name != TRIM(home_club_manager_name) THEN 'home_club_manager_name_whitespace'
        WHEN away_club_manager_name != TRIM(away_club_manager_name) THEN 'away_club_manager_name_whitespace'
        WHEN stadium != TRIM(stadium) THEN 'stadium_whitespace'
        WHEN referee != TRIM(referee) THEN 'referee_whitespace'
        WHEN url != TRIM(url) THEN 'url_whitespace'
        WHEN home_club_formation != TRIM(home_club_formation) THEN 'home_club_formation_whitespace'
        WHEN away_club_formation != TRIM(away_club_formation) THEN 'away_club_formation_whitespace'
        WHEN home_club_name != TRIM(home_club_name) THEN 'home_club_name_whitespace'
        WHEN away_club_name != TRIM(away_club_name) THEN 'away_club_name_whitespace'
        WHEN aggregate != TRIM(aggregate) THEN 'aggregate_whitespace'
        WHEN competition_type != TRIM(competition_type) THEN 'competition_type_whitespace'
    END AS error_type
FROM silver.games
WHERE 
    competition_id != TRIM(competition_id) OR
    round != TRIM(round) OR
    home_club_manager_name != TRIM(home_club_manager_name) OR
    away_club_manager_name != TRIM(away_club_manager_name) OR
    stadium != TRIM(stadium) OR
    referee != TRIM(referee) OR
    url != TRIM(url) OR
    home_club_formation != TRIM(home_club_formation) OR
    away_club_formation != TRIM(away_club_formation) OR
    home_club_name != TRIM(home_club_name) OR
    away_club_name != TRIM(away_club_name) OR 
    aggregate != TRIM(aggregate) OR 
    competition_type != TRIM(competition_type); 

/* CHECK 05: Categorical Consistency
  Description: Verifies distinct values for normalization planning.
  Findings: 
    - 'round' contains inconsistent naming (e.g., 'Group A', '1. Round').
    - 'formations' contain variations and empty strings.
  Fix: Standardize round names and handle formation NULLs.
*/

SELECT DISTINCT season FROM silver.games ORDER BY 1;

SELECT DISTINCT round FROM silver.games ORDER BY 1;

SELECT DISTINCT home_club_formation AS formation FROM silver.games ORDER BY 1;

SELECT DISTINCT away_club_formation AS fromation FROM silver.games ORDER BY 1; 

-- Exploration of all unique formations for: home_club_formation + away_club_formation

WITH cte_formation AS
(SELECT home_club_formation AS formation
FROM silver.games
UNION ALL
SELECT away_club_formation AS formation
FROM silver.games)
SELECT DISTINCT UPPER(TRIM(formation))
FROM cte_formation
ORDER BY 1;

SELECT DISTINCT aggregate FROM silver.games ORDER BY 1;

SELECT DISTINCT competition_type FROM silver.games ORDER BY 1;






