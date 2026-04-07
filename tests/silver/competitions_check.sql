--------------------------------------------------------------------------------
-- PURPOSE:  Data Quality Audit for Silver Layer - Table: competitions
-- DESCRIPTION: Validates tournament metadata, regional hierarchies, and 
--              major league status flags.
--------------------------------------------------------------------------------

/* CHECK 01: Uniqueness & Primary Key Integrity
  Description: Validates that competition_id is unique and non-null.
*/

WITH id_validation AS (
    SELECT 
        competition_id,
        ROW_NUMBER() OVER(PARTITION BY competition_id) as row_num
    FROM silver.competitions
)
SELECT competition_id, row_num
FROM id_validation
WHERE row_num > 1 OR competition_id IS NULL;

/* CHECK 02: Business Logic - Major League Integrity
  Description: Validates the business rule that each country should only have 
               ONE primary (major) national league.
*/

WITH major_league_validation AS (
    SELECT 
        country_name,
        COUNT(*) as row_num
    FROM silver.competitions
    WHERE is_major_national_league = 'true'
    GROUP BY country_name
)
SELECT country_name, row_num
FROM major_league_validation
WHERE row_num > 1 OR country_name IS NULL;

/* CHECK 03: Data Standardization & String Integrity
  Description: Identifies fields with whitespace issues requiring TRIM().
*/

SELECT 
    competition_id,
    CASE 
        WHEN competition_id != TRIM(competition_id) THEN 'competition_id_whitespace'
        WHEN competition_code != TRIM(competition_code) THEN 'competition_code_whitespace'
        WHEN name != TRIM(name) THEN 'name_whitespace'
        WHEN sub_type != TRIM(sub_type) THEN 'sub_type_whitespace'
        WHEN type != TRIM(type) THEN 'type_whitespace'
        WHEN country_name != TRIM(country_name) THEN 'country_name_whitespace'
        WHEN domestic_league_code != TRIM(domestic_league_code) THEN 'domestic_league_code_whitespace'
        WHEN confederation != TRIM(confederation) THEN 'confederation_whitespace'
        WHEN url != TRIM(url) THEN 'url_whitespace'
    END AS error_type
FROM silver.competitions
WHERE 
    competition_id != TRIM(competition_id) OR
    competition_code != TRIM(competition_code) OR
    name != TRIM(name) OR
    sub_type != TRIM(sub_type) OR
    type != TRIM(type) OR
    country_name != TRIM(country_name) OR
    domestic_league_code != TRIM(domestic_league_code) OR
    confederation != TRIM(confederation) OR
    url != TRIM(url);

/* CHECK 04: Categorical Consistency & Data Type Planning
  Description: Verifies distinct values to check data consistency
*/

-- Flag Validation
SELECT DISTINCT is_major_national_league FROM silver.competitions ORDER BY 1;

-- Regional & Type Analysis
SELECT DISTINCT confederation FROM silver.competitions ORDER BY 1;
SELECT DISTINCT country_name FROM silver.competitions ORDER BY 1;
SELECT DISTINCT type FROM silver.competitions ORDER BY 1;
SELECT DISTINCT sub_type FROM silver.competitions ORDER BY 1;

-- Check for unexpected domestic league codes
SELECT DISTINCT domestic_league_code 
FROM silver.competitions 
WHERE domestic_league_code IS NOT NULL 
ORDER BY 1;