/*
===============================================================================
PURPOSE:      Gold Layer Data Quality Test - Table: gold.fact_player_stats
USAGE:        Run after Gold Layer refresh to ensure data integrity.
DESCRIPTION:  Validates PK uniqueness, FK constraints, and football business logic.
===============================================================================
*/

/* 
    CHECK 01: Uniqueness & Primary Key Integrity
    Expectation: No results 
    Findings: No results 
*/

WITH id_validation AS (
    SELECT 
        appearance_id,
        ROW_NUMBER() OVER(PARTITION BY appearance_id ORDER BY date) AS row_num
    FROM gold.fact_player_stats
)
SELECT appearance_id, row_num
FROM id_validation
WHERE row_num > 1 OR appearance_id IS NULL;

/* 
    CHECK 02: Dimensional Referential Integrity
    Expectation: No results 
    Findings: No results 
*/

SELECT 'Missing Player' AS issue_type, appearance_id, player_id FROM gold.fact_player_stats ps
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_players p WHERE p.player_id = ps.player_id)
UNION ALL
SELECT 'Missing Club' AS issue_type, appearance_id, club_id FROM gold.fact_player_stats ps
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_clubs c WHERE c.club_id = ps.club_id)
UNION ALL
SELECT 'Missing Opponent' AS issue_type, appearance_id, opponent_id FROM gold.fact_player_stats ps
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_clubs c WHERE c.club_id = ps.opponent_id)
UNION ALL
SELECT 'Missing Game' AS issue_type, appearance_id, game_id FROM gold.fact_player_stats ps
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_games g WHERE g.game_id = ps.game_id);

/* 
    CHECK 03: Boundary Constraints & Football Business Logic
    Expectation: No results 
    Findings: No results 
*/

SELECT 
    appearance_id,
    club_id,
    opponent_id,
    goals,
    assists,
    yellow_cards,
    red_cards,
    minutes_played
FROM gold.fact_player_stats
WHERE 
    club_id = opponent_id OR
    goals < 0 OR
    assists < 0 OR
    yellow_cards NOT IN(0,1,2) OR
    red_cards NOT IN(0,1) OR
    minutes_played NOT BETWEEN 0 AND 90;

/* 
    CHECK 04: Starting Lineup Validation
    Expectation: No results 
    Findings: No results 
*/

SELECT 
    game_id,
    club_id,
    COUNT(player_id) AS starting_player_count
FROM gold.fact_player_stats
WHERE is_starting_lineup = TRUE
GROUP BY 
    game_id, 
    club_id
HAVING COUNT(player_id) > 11;

/* 
    CHECK 05: Captaincy Uniqueness Validation
    Expectation: No results 
    Findings: 70 occurrences identified (0.07% of total records).
    Cause: Source data inconsistency from Transfermarkt upstream.
    Decision: Accepted Risk. The anomaly is statistically insignificant. 
              No manual override applied to maintain raw data lineage.
*/

SELECT
    game_id,
    club_id,
    COUNT(player_id) AS captain_count
FROM gold.fact_player_stats
WHERE is_starting_lineup = TRUE AND is_captain = TRUE
GROUP BY 
    game_id, 
    club_id
HAVING COUNT(player_id) > 1;