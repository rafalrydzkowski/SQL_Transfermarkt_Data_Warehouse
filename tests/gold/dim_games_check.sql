/*
===============================================================================
PURPOSE:      Gold Layer Data Quality Test - Table: gold.dim_games
USAGE:        Run after Gold Layer refresh to ensure data integrity.
DESCRIPTION:  Validates match fixture PK uniqueness, domestic league scope, 
              and denormalized name consistency between games and clubs.
===============================================================================
*/

/* 
    CHECK 01: Uniqueness & Primary Key Integrity
    Expectation: No results 
    Findings: No results 
*/

WITH id_validation AS (
    SELECT 
        game_id,
        ROW_NUMBER() OVER(PARTITION BY game_id ORDER BY date) as row_num
    FROM gold.dim_games
)
SELECT game_id, row_num
FROM id_validation
WHERE row_num > 1 OR game_id IS NULL;

/* 
    CHECK 02: Dimensional Referential Integrity
    Expectation: No results 
    Findings: No results 
*/

SELECT 
    'Missing Competition' AS issue_type, 
    competition_id, 
    game_id 
FROM gold.dim_games AS g
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_competitions AS c WHERE c.competition_id = g.competition_id)
UNION ALL
SELECT 
    'Missing Home Club' AS issue_type, 
    home_club_id::VARCHAR, 
    game_id 
FROM gold.dim_games AS g
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_clubs AS c WHERE c.club_id = g.home_club_id)
UNION ALL
SELECT 
    'Missing Away Club' AS issue_type, 
    away_club_id::VARCHAR, 
    game_id 
FROM gold.dim_games AS g
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_clubs AS c WHERE c.club_id = g.away_club_id);

/* 
    CHECK 03: Boundary Constraints & Scope Enforcement
    Expectation: No results 
    Findings: No results 
*/

SELECT
    game_id,
    season,
    round,
    date,
    home_club_name,
    away_club_name,
    attendance,
    url
FROM gold.dim_games
WHERE
    season IS NULL OR
    round IS NULL OR
    date NOT BETWEEN '2012-01-01' AND CURRENT_DATE OR
    home_club_name IS NULL OR
    away_club_name IS NULL OR
    attendance NOT BETWEEN 0 AND 120000
    OR url NOT LIKE '%transfermarkt%';

/* 
    CHECK 04: Football Business Logic (Self-Play Prevention)
    Expectation: No results 
    Findings: No results 
*/

SELECT
    game_id,
    home_club_id,
    away_club_id
FROM gold.dim_games
WHERE home_club_id = away_club_id;

/* 
    CHECK 05: Club's Name Integrity
    Expectation: No results 
    Findings: No results 
*/

SELECT
    g.game_id,
    g.home_club_id,
    g.away_club_id,
    g.home_club_name,
    c1.name,
    g.away_club_name,
    c2.name
FROM gold.dim_games AS g
LEFT JOIN gold.dim_clubs AS c1
ON g.home_club_id = c1.club_id
LEFT JOIN gold.dim_clubs AS c2
ON g.away_club_id = c2.club_id
WHERE
    g.home_club_name <> c1.name OR
    g.away_club_name <> c2.name;