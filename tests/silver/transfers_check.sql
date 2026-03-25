--------------------------------------------------------------------------------
-- PURPOSE:  Data Quality Audit for Silver Layer - Table: transfers
-- DESCRIPTION: Validates transfer records, financial outliers, and complex 
--              referential integrity between players and clubs.
--------------------------------------------------------------------------------

/* CHECK 01: Grain Integrity (Composite Key Validation)
  Description: Validates that there are no duplicate transfer records.
  Logic: The unique grain is defined by player_id, transfer_date, and participating clubs.
*/

WITH id_validation AS (
    SELECT 
        player_id,
        transfer_date,
        from_club_id,
        to_club_id,
        ROW_NUMBER() OVER(PARTITION BY player_id, transfer_date, from_club_id, to_club_id ORDER BY transfer_date DESC) as row_num
    FROM silver.transfers
)
SELECT player_id, transfer_date, from_club_id, to_club_id, row_num
FROM id_validation
WHERE row_num > 1 OR player_id IS NULL;

/* CHECK 02: Referential Integrity (Orphan Records)
  Description: Identifies records pointing to non-existent players or clubs.
  Note: Missing club_ids are expected when a Top 14 team trades with a club 
        outside the scouted dataset (lower leagues/other regions).
*/

-- Orphan Players: Critical error. Every transfer must link to a master player record.

SELECT 
    t.player_id, 
    t.player_name,
    t.transfer_date
FROM silver.transfers AS t
WHERE NOT EXISTS (
    SELECT 1 FROM silver.players AS p WHERE p.player_id = t.player_id
);

-- Orphan Clubs: Validates that at least one side of the transaction is known.
-- Logic: We audit both to understand the coverage gap.

SELECT 
    t.player_id, 
    t.player_name,
    t.from_club_id,
    t.to_club_id,
    t.transfer_date
FROM silver.transfers AS t
WHERE NOT EXISTS (
    SELECT 1 FROM silver.clubs AS c WHERE c.club_id = t.from_club_id
) 
OR NOT EXISTS (
    SELECT 1 FROM silver.clubs AS c WHERE c.club_id = t.to_club_id
)
LIMIT 100;

/* CHECK 03: Football Business Logic (Financial Outliers)
  Description: Validates transfer fees and market values against physical world limits.
  Note: 300M EUR is set as a threshold based on historical records (Neymar Jr. ~222M).
*/

SELECT 
    player_id, 
    transfer_date,
    transfer_fee,
    market_value_in_eur
FROM silver.transfers
WHERE
    transfer_fee < 0 OR
    market_value_in_eur < 0 OR
    transfer_fee > 300000000 OR
    market_value_in_eur > 300000000;

/* CHECK 04: Data Standardization & String Integrity
  Description: Identifies fields with whitespace issues requiring TRIM().
  Findings: ~1137 records identified with leading/trailing whitespaces.
  Fix: Apply TRIM() to all categorical and ID fields.
*/

SELECT 
    player_id,
    transfer_date,
    CASE 
        WHEN from_club_name != TRIM(from_club_name) THEN 'from_club_name_whitespace'
        WHEN to_club_name != TRIM(to_club_name) THEN 'to_club_name_whitespace'
        WHEN player_name != TRIM(player_name) THEN 'player_name_whitespace'
    END AS error_type
FROM silver.transfers
WHERE 
    from_club_name != TRIM(from_club_name) OR
    to_club_name != TRIM(to_club_name) OR
    player_name != TRIM(player_name);

/* CHECK 05: Categorical Consistency
  Description: Verifies distinct values for seasonal alignment.
*/

SELECT DISTINCT transfer_season FROM silver.transfers ORDER BY 1;


-- Do przeanalizowania jakie podejscie wybrac!!!!

WITH id_validation AS (
    SELECT 
        player_id,
        transfer_date,
        from_club_id,
        ROW_NUMBER() OVER(PARTITION BY player_id, transfer_date, from_club_id ORDER BY transfer_date DESC) as row_num
    FROM silver.transfers
)
SELECT player_id, transfer_date, from_club_id, row_num
FROM id_validation
WHERE row_num > 1 OR player_id IS NULL;

SELECT *
FROM silver.transfers
WHERE transfer_date = '2024-07-01' AND player_id = 832896

SELECT *
FROM silver.player_valuations
WHERE market_value_in_eur IS NULL OR market_value_in_eur = 0; 