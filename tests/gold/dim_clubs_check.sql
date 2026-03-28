/*
===============================================================================
PURPOSE:      Gold Layer Data Quality Test - Table: gold.dim_clubs
USAGE:        Run after Gold Layer refresh to ensure data integrity.
DESCRIPTION:  Validates PK uniqueness and ensures that the club master 
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
        club_id,
        ROW_NUMBER() OVER(PARTITION BY club_id) as row_num
    FROM gold.dim_clubs
)
SELECT club_id, row_num
FROM id_validation
WHERE row_num > 1 OR club_id IS NULL;

/* 
    CHECK 02: Dimensional Referential Integrity
    Expectation: No results 
    Findings: No results 
*/

SELECT 
    'Missing Competition' AS issue_type, 
    competition_id, 
    club_id 
FROM gold.dim_clubs AS cl
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_competitions AS c WHERE c.competition_id = cl.competition_id);

/* 
    CHECK 03: Boundary Constraints & Football Business Logic
    Expectation: No results 
    Findings: No results 
*/

SELECT 
    club_id,
    club_code,
    name,
    stadium_seats,
    last_season
FROM gold.dim_clubs
WHERE 
    club_code IS NULL OR
    name IS NULL OR
    stadium_seats NOT BETWEEN 0 AND 120000 OR
    last_season NOT BETWEEN 2012 AND 2025;