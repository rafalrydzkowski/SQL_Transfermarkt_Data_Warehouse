--------------------------------------------------------------------------------
-- PURPOSE:  Data Quality Audit for Silver Layer - Table: clubs
-- DESCRIPTION: Audits club financial data, stadium capacities, and geographic 
--              linkages to ensure consistency in the club dimension.
--------------------------------------------------------------------------------

/* CHECK 01: Uniqueness & Primary Key Integrity
  Description: Validates that club_id is unique and non-null.
*/

WITH id_validation AS (
    SELECT 
        club_id,
        ROW_NUMBER() OVER(PARTITION BY club_id ORDER BY last_season) as row_num
    FROM silver.clubs
)
SELECT club_id, row_num
FROM id_validation
WHERE row_num > 1 OR club_id IS NULL;

/* CHECK 02: Referential Integrity (Orphan Records)
  Description: Checks for records pointing to non-existent competitions.
*/

SELECT c.club_id
FROM silver.clubs AS c
WHERE NOT EXISTS (
    SELECT 1 FROM silver.competitions AS co WHERE co.competition_id = c.competition_id
);

/* CHECK 03: Football Business Logic & Physical Constraints
  Description: Validates club metrics against realistic football boundaries.
  Findings: Identified 2 records where squad_size, average_age, and national_team_players 
            are 0. Likely due to incomplete data ingestion for obscure clubs.
  Fix: Coerce 0 values to NULL to avoid skewing averages in the Gold layer.
*/


SELECT
    club_id,
    name,
    squad_size,
    average_age,
    foreigners_number,
    foreigners_percentage,
    national_team_players,
    stadium_seats
FROM silver.clubs
WHERE
    squad_size < 0 OR
    average_age < 15 OR
    foreigners_number < 0 OR
    foreigners_percentage < 0 OR 
    foreigners_percentage > 100 OR
    national_team_players < 0 OR
    stadium_seats < 0;

-- Outlier Detection: Stadiums larger than the Rungrado 1st of May Stadium (~114k-150k)

SELECT club_id, name, stadium_seats
FROM silver.clubs
WHERE stadium_seats > 120000;

/* CHECK 04: Data Standardization & String Integrity
  Description: Identifies formatting issues like leading/trailing spaces.
  Silver Strategy: All identified fields will be wrapped in TRIM() during transformation.
*/

SELECT 
    club_id
    name,
    CASE 
        WHEN club_code != TRIM(club_code) THEN 'club_code_whitespace'
        WHEN name != TRIM(name) THEN 'name_whitespace'
        WHEN competition_id != TRIM(competition_id) THEN 'competition_id_whitespace'
        WHEN stadium_name != TRIM(stadium_name) THEN 'stadium_name_whitespace'
        WHEN coach_name != TRIM(coach_name) THEN 'coach_name_whitespace'
        WHEN filename != TRIM(filename) THEN 'filename_whitespace'
        WHEN url != TRIM(url) THEN 'url_whitespace'
    END AS error_type
FROM silver.clubs
WHERE 
    club_code != TRIM(club_code) OR
    name != TRIM(name) OR
    competition_id != TRIM(competition_id) OR
    stadium_name != TRIM(stadium_name) OR
    coach_name != TRIM(coach_name) OR
    filename != TRIM(filename) OR 
    url != TRIM(url);

/* CHECK 05: Categorical Consistency & Financial Formatting
  Description: Verifies data distribution and identifies non-standard financial strings.
  
  Findings: 'net_transfer_record' contains mixed currency symbols and suffixes 
            (e.g., '+€5.45m', '+€450k'). 
  Fix: Use REGEX to extract numeric values and normalize to NUMERIC values in EUR.
*/

SELECT DISTINCT last_season FROM silver.clubs ORDER BY 1;

SELECT DISTINCT net_transfer_record_eur FROM silver.clubs ORDER BY 1;

-- Solution:

SELECT
    club_id,
    net_transfer_record,
    CASE 
        WHEN net_transfer_record ~ 'm' 
            THEN CAST(regexp_replace(net_transfer_record, '[^0-9.-]', '', 'g') AS NUMERIC) * 1000000
        WHEN net_transfer_record ~ 'k' 
            THEN CAST(regexp_replace(net_transfer_record, '[^0-9.-]', '', 'g') AS NUMERIC) * 1000
        ELSE CAST(regexp_replace(net_transfer_record, '[^0-9.-]', '', 'g') AS NUMERIC)
    END AS net_transfer_record_eur
FROM silver.clubs;