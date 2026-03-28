/*
===============================================================================
PURPOSE:      Gold Layer Data Quality Test - Table: gold.fact_player_valuations
USAGE:        Run after Gold Layer refresh to ensure data integrity.
DESCRIPTION:  Advanced integrity checks including time-series delta validation,
              multi-dimensional FK integrity, and chronological consistency.
===============================================================================
*/

/* 
    CHECK 01: Uniqueness & Primary Key Integrity
    Expectation: No results 
    Findings: No results 
*/

WITH id_validation AS (
    SELECT 
        valuation_id,
        ROW_NUMBER() OVER(PARTITION BY valuation_id ORDER BY date_of_valuation) AS row_num
    FROM gold.fact_player_valuations
)
SELECT valuation_id, row_num
FROM id_validation
WHERE row_num > 1 OR valuation_id IS NULL;

/* 
    CHECK 02: Dimensional Referential Integrity
    Expectation: No results 
    Findings: No results 
*/

SELECT 
    'Missing Player' AS issue_type, 
    valuation_id
FROM gold.fact_player_valuations AS pv
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_players p WHERE p.player_id = pv.player_id)
UNION ALL
SELECT 
    'Missing Club' AS issue_type, 
    valuation_id
FROM gold.fact_player_valuations AS pv
WHERE 
    NOT EXISTS (SELECT 1 FROM gold.dim_clubs c WHERE c.club_id = pv.club_id_at_valuation)
    AND pv.club_id_at_valuation IS NOT NULL
UNION ALL
SELECT 
    'Missing Competition' AS issue_type, 
    valuation_id
FROM gold.fact_player_valuations AS pv
WHERE 
    NOT EXISTS (SELECT 1 FROM gold.dim_competitions c WHERE c.competition_id = pv.competition_id_at_valuation)
    AND pv.competition_id_at_valuation IS NOT NULL;

/* 
    CHECK 03: Boundary Constraints & Football Business Logic
    Expectation: No results 
    Findings: No results 
*/

SELECT
    valuation_id,
    player_id,
    valuation_age,
    market_value_in_eur
FROM gold.fact_player_valuations
WHERE 
    market_value_in_eur <= 0;

/* 
    CHECK 04: Flag Consistency (is_highest_ever & is_current)
    Expectation: No results 
    Findings: No results 
*/

-- is_current:
SELECT
    player_id,
    COUNT(player_id) AS flag_count
FROM gold.fact_player_valuations
WHERE is_current = TRUE
GROUP BY player_id
HAVING COUNT(player_id) > 1;

-- is_highest_ever:
WITH cte_valuation AS
(SELECT
    valuation_id,
    player_id,
    date_of_valuation,
    market_value_in_eur,
    market_value_in_eur = MAX(market_value_in_eur) OVER(PARTITION BY player_id) AS flag_check
FROM gold.fact_player_valuations
WHERE is_highest_ever = TRUE)

SELECT *
FROM cte_valuation
WHERE flag_check = FALSE;

/* 
    CHECK 05: Time-Series Consistency
    Expectation: No results 
    Findings: No results 
*/

WITH cte_valuation AS
(SELECT
    valuation_id,
    player_id,
    date_of_valuation,
    valuation_change_prev = (market_value_in_eur - LAG(market_value_in_eur) OVER(PARTITION BY player_id ORDER BY date_of_valuation)) AS time_series_check
FROM gold.fact_player_valuations)

SELECT *
FROM cte_valuation
WHERE time_series_check = FALSE;