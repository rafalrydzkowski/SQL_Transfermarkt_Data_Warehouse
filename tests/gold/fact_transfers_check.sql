/*
===============================================================================
PURPOSE:      Gold Layer Data Quality Test - Table: gold.fact_transfres
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
        transfer_id,
        ROW_NUMBER() OVER(PARTITION BY transfer_id ORDER BY transfer_date) AS row_num
    FROM gold.fact_transfers
)
SELECT transfer_id, row_num
FROM id_validation
WHERE row_num > 1 OR transfer_id IS NULL;

/* 
    CHECK 02: Dimensional Referential Integrity
    Expectation: No results 
    Findings: No results 
*/

SELECT 'Missing Player' AS issue, player_id::VARCHAR FROM gold.fact_transfers t
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_players p WHERE p.player_id = t.player_id)
UNION ALL
SELECT 'Missing From-Club' AS issue, from_club_id::VARCHAR FROM gold.fact_transfers t
WHERE 
    NOT EXISTS (SELECT 1 FROM gold.dim_clubs c WHERE c.club_id = t.from_club_id)
    AND t.from_club_id IS NOT NULL
UNION ALL
SELECT 'Missing To-Club' AS issue, to_club_id::VARCHAR FROM gold.fact_transfers t
WHERE 
    NOT EXISTS (SELECT 1 FROM gold.dim_clubs c WHERE c.club_id = t.to_club_id)
    AND t.to_club_id IS NOT NULL
UNION ALL
SELECT 'Missing From-Competition' AS issue, from_competition_id FROM gold.fact_transfers t
WHERE 
    NOT EXISTS (SELECT 1 FROM gold.dim_competitions c WHERE c.competition_id = t.from_competition_id)
    AND t.from_competition_id IS NOT NULL
UNION ALL
SELECT 'Missing To-Competition' AS issue, to_competition_id FROM gold.fact_transfers t
WHERE 
    NOT EXISTS (SELECT 1 FROM gold.dim_competitions c WHERE c.competition_id = t.to_competition_id)
    AND t.to_competition_id IS NOT NULL;

/* 
    CHECK 03: Boundary Constraints, Football Business Logic & Non-Cash Integrity
    Expectation: No results 
    Findings: No results 
*/

SELECT 
    transfer_id,
    transfer_fee,
    is_non_cash_transfer
FROM gold.fact_transfers
WHERE
    (transfer_fee = 0 AND is_non_cash_transfer = FALSE) OR
    (transfer_fee > 0 AND is_non_cash_transfer = TRUE) OR
    transfer_fee < 0 OR
    market_value_at_transfer < 0;

/* 
    CHECK 04: Flag Consistency (is_latest_transfer & is_record_breaking_for_player)
    Expectation: No results 
    Findings: No results 
*/

WITH cte_transfers AS
(SELECT
    transfer_id,
    player_id,
    transfer_fee,
    transfer_date,
    is_record_breaking_for_player,
    is_latest_transfer,
    MAX(transfer_fee) OVER(PARTITION BY player_id) AS actual_record,
    ROW_NUMBER() OVER(PARTITION BY player_id ORDER BY transfer_date DESC, transfer_id DESC) AS actual_latest
FROM gold.fact_transfers)

SELECT
    'RECORD-BREAKING ERROR' AS error_type,
    transfer_id
FROM cte_transfers
WHERE 
    (is_record_breaking_for_player = TRUE AND transfer_fee < actual_record) OR
    (is_record_breaking_for_player = FALSE AND transfer_fee = actual_record AND transfer_fee > 0)
UNION ALL
SELECT
    'IS-LATEST ERROR' AS error_type,
    transfer_id
FROM cte_transfers
WHERE 
    (is_latest_transfer = TRUE AND actual_latest <> 1) OR
    (is_latest_transfer = FALSE AND actual_latest = 1);

/* 
    CHECK 05: Transfers Movement Logic
    Expectation: No results 
    Findings: No results
*/

SELECT
    transfer_id,
    from_club_id,
    to_club_id
FROM gold.fact_transfers
WHERE from_club_id = to_club_id;