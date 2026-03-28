/*
===============================================================================
PURPOSE:      Gold Layer Data Quality Test - Table: gold.dim_players
USAGE:        Run after Gold Layer refresh to ensure data integrity.
DESCRIPTION:  Validates player uniqueness, biological/physical constraints, 
              financial consistency, and football-specific attributes.
===============================================================================
*/

/* 
    CHECK 01: Uniqueness & Primary Key Integrity
    Expectation: No results 
    Findings: No results 
*/

WITH id_validation AS (
    SELECT 
        player_id,
        ROW_NUMBER() OVER(PARTITION BY player_id ORDER BY last_season) as row_num
    FROM gold.dim_players
)
SELECT player_id, row_num
FROM id_validation
WHERE row_num > 1 OR player_id IS NULL;

/* 
    CHECK 02: Dimensional Referential Integrity
    Expectation: No results 
    Findings: No results 
*/

SELECT 
    'Missing Competition' AS issue_type, 
    current_club_domestic_competition_id, 
    player_id
FROM gold.dim_players AS p
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_competitions AS c WHERE c.competition_id = p.current_club_domestic_competition_id)
UNION ALL
SELECT 
    'Missing Club' AS issue_type, 
    current_club_id::VARCHAR, 
    player_id 
FROM gold.dim_players AS p
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_clubs AS c WHERE c.club_id = p.current_club_id);

/* 
    CHECK 03: Crucial Data Quality
    Expectation: No results 
    Findings: No results 
*/

SELECT
    player_id,
    name,
    last_season,
    url
FROM gold.dim_players
WHERE
    name IS NULL OR
    last_season IS NULL OR
    url NOT LIKE '%transfermarkt%';

/* 
    CHECK 04: Financial Logic & Consistency
    Expectation: No results 
    Findings: No results 
*/

SELECT
    player_id,
    market_value_in_eur,
    highest_market_value_in_eur
FROM gold.dim_players
WHERE
    market_value_in_eur NOT BETWEEN 0 AND 200000000 OR
    highest_market_value_in_eur NOT BETWEEN 0 AND 200000000 OR
    market_value_in_eur > highest_market_value_in_eur;

/* 
    CHECK 05: Biological & Age Logic
    Expectation: No results 
    Findings: No results 
*/

SELECT
    player_id,
    date_of_birth,
    height_in_cm
FROM gold.dim_players
WHERE
    EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM date_of_birth) < 15 OR
    date_of_birth > CURRENT_DATE OR
    height_in_cm < 120;

/* 
    CHECK 06: Football Attribute Standardization
    Expectation: No results 
    Findings: No results 
*/

SELECT
    player_id,
    position,
    foot
FROM gold.dim_players
WHERE
    position NOT IN('ATTACK','DEFENDER','GOALKEEPER','MIDFIELD','MISSING') OR
    foot NOT IN('LEFT','RIGHT','BOTH');

/* 
    CHECK 07: Club's Name Integrity
    Expectation: No results 
    Findings: No results 
*/

SELECT
    p.player_id,
    p.current_club_id,
    p.current_club_name,
    c.name
FROM gold.dim_players AS p
LEFT JOIN gold.dim_clubs AS c
ON p.current_club_id = c.club_id
WHERE p.current_club_name <> c.name;