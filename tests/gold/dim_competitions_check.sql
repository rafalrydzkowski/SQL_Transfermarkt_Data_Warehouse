/*
===============================================================================
PURPOSE:      Gold Layer Data Quality Test - Table: gold.dim_competitions
USAGE:        Run after Gold Layer refresh to ensure data integrity.
DESCRIPTION:  Validates PK uniqueness and ensures that the competition master 
              data matches the strictly defined Top 14 domestic leagues scope.
===============================================================================
*/

/* 
    CHECK 01: Uniqueness & Primary Key Integrity
    Expectation: No results 
    Findings: No results 
*/

WITH id_validation AS (
    SELECT 
        competition_id,
        ROW_NUMBER() OVER(PARTITION BY competition_id) as row_num
    FROM gold.dim_competitions
)
SELECT competition_id, row_num
FROM id_validation
WHERE row_num > 1 OR competition_id IS NULL;

/* 
    CHECK 02: Business Scope Enforcement (Domestic Leagues Only), Data Completeness & URL Sanity
    Expectation: No results 
    Findings: No results 
*/

SELECT
    competition_id,
    name,
    type,
    country_name,
    url
FROM gold.dim_competitions
WHERE 
    name IS NULL OR
    type <> 'domestic_league' OR
    country_name IS NULL OR
    url NOT LIKE '%transfermarkt%';

/* 
    CHECK 03: Gold Layer Scope Check (The Top 14 Rule)
    Expectation: No results
    Findings: No results
*/

SELECT
    'SCOPE CHECK ERROR' AS error_type,
    COUNT(*) AS competitions_count
FROM gold.dim_competitions
HAVING COUNT(*) <> 14;