/*
===============================================================================
PURPOSE:      Gold Layer Data Quality Test - Table: gold.fact_team_stats
USAGE:        Run after Gold Layer refresh to ensure data integrity.
DESCRIPTION:  Validates dual-entry symmetry, match result logic, 
              and league table integrity (e.g. points).
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
        club_id,
        ROW_NUMBER() OVER(PARTITION BY game_id, club_id ORDER BY date) AS row_num
    FROM gold.fact_team_stats
)
SELECT game_id, club_id, row_num
FROM id_validation
WHERE row_num > 1 OR game_id IS NULL OR club_id IS NULL;

/* 
    CHECK 02: Dimensional Referential Integrity
    Expectation: No results 
    Findings: No results 
*/

SELECT 'Missing Club' AS issue_type, game_id, club_id 
FROM gold.fact_team_stats AS ts
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_clubs AS c WHERE c.club_id = ts.club_id)
UNION ALL
SELECT 'Missing Game' AS issue_type, game_id, club_id 
FROM gold.fact_team_stats AS ts
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_games g WHERE g.game_id = ts.game_id)
UNION ALL
SELECT 'Missing Competition' AS issue_type, game_id, club_id 
FROM gold.fact_team_stats AS ts
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_competitions AS c WHERE c.competition_id = ts.competition_id);

/* 
    CHECK 03: Boundary Constraints & Football Business Logic
    Expectation: No results 
    Findings: No results 
*/

SELECT
    game_id,
    club_id
FROM gold.fact_team_stats
WHERE
    (is_win = TRUE AND points <> 3) OR
    (is_draw = TRUE AND points <> 1) OR
    (is_loss = TRUE AND points <> 0) OR
    (opponent_goals > 0 AND is_clean_sheet = TRUE) OR
    attendance < 0 OR
    (is_win::INT + is_draw::INT + is_loss::INT) != 1;

/* 
    CHECK 04: The Mirror Test (Full Symmetry)
    Expectation: No results 
    Findings: No results 
*/

SELECT
    g1.game_id,
    g1.club_id AS team_a,
    g2.club_id AS team_b,
    g1.own_goals AS a_scored,
    g2.opponent_goals AS b_conceded
FROM gold.fact_team_stats AS g1
LEFT JOIN gold.fact_team_stats AS g2
ON g1.game_id = g2.game_id AND g1.club_id = g2.opponent_id
WHERE 
    g2.game_id IS NULL OR
    g1.own_goals != g2.opponent_goals OR
    g1.is_home = g2.is_home OR
    (g1.is_win = TRUE AND g2.is_loss = FALSE) OR
    (g1.is_draw != g2.is_draw) OR
    g1.points + g2.points NOT IN(2,3);