--------------------------------------------------------------------------------
-- PURPOSE:  Data Quality Audit for Silver Layer - Table: players
-- DESCRIPTION: Audits player bio-data, market values, and geographic 
--              consistency to prepare for Silver Layer normalization.
--------------------------------------------------------------------------------

/* CHECK 01: Uniqueness & Primary Key Integrity
  Description: Validates player_id as a unique identifier.
  Logic: Even if a player appears in multiple seasons, the 'players' table 
         should maintain a single master record per ID.
*/

WITH pk_audit AS (
    SELECT 
        player_id,
        ROW_NUMBER() OVER(PARTITION BY player_id ORDER BY last_season DESC) AS row_num
    FROM silver.players
)
SELECT 
    player_id, 
    row_num
FROM pk_audit
WHERE row_num > 1 
   OR player_id IS NULL;

/* CHECK 02: Referential Integrity (Orphan Records)
  Identifies records referencing IDs missing from parent dimension tables.
*/

-- Clubs:

SELECT p.player_id, p.name, p.current_club_id
FROM silver.players AS p
WHERE NOT EXISTS (
    SELECT 1 FROM silver.clubs AS c WHERE c.club_id = p.current_club_id
)
LIMIT 100;

/* CHECK 03: Football Business Logic & Temporal Integrity
  Validates data against physical world rules and tournament regulations.
*/

SELECT
    player_id,
    market_value_in_eur,
    highest_market_value_in_eur
FROM silver.players
WHERE 
    market_value_in_eur < 0 OR 
    highest_market_value_in_eur < 0;

-- Rule: Physical Height Validation.
-- Findings: Identified records where height_in_cm = 18 (Likely typo for 180+ or 1.8m).
-- Fix: Values below 120cm will be coerced to NULL as they are physically improbable.

SELECT 
    player_id, 
    name, 
    height_in_cm
FROM silver.players
WHERE height_in_cm < 120 OR height_in_cm > 230;

/* CHECK 04: Data Standardization & String Integrity
  Description: Detects leading/trailing whitespaces and casing inconsistencies.
  Findings: unwanted leading/trailing whitespaces founded
  Fix: All identified fields will be wrapped in TRIM() during transformation.
*/

SELECT 
    player_id,
    name,
    CASE 
        WHEN first_name != TRIM(first_name) THEN 'first_name_whitespace'
        WHEN last_name != TRIM(last_name) THEN 'last_name_whitespace'
        WHEN name != TRIM(name) THEN 'name_whitespace'
        WHEN player_code != TRIM(player_code) THEN 'player_code_whitespace'
        WHEN country_of_birth != TRIM(country_of_birth) THEN 'country_of_birth_whitespace'
        WHEN city_of_birth != TRIM(city_of_birth) THEN 'city_of_birth_whitespace'
        WHEN country_of_citizenship != TRIM(country_of_citizenship) THEN 'city_of_citizenship_whitespace'
        WHEN sub_position != TRIM(sub_position) THEN 'sub_position_whitespace'
        WHEN position != TRIM(position) THEN 'position_whitespace'
        WHEN foot != TRIM(foot) THEN 'foot_whitespace'
        WHEN agent_name != TRIM(agent_name) THEN 'agent_name_whitespace'
        WHEN image_url != TRIM(image_url) THEN 'image_url_whitespace'
        WHEN url != TRIM(url) THEN 'url_whitespace'
        WHEN current_club_domestic_competition_id != TRIM(current_club_domestic_competition_id) THEN 'competition_id_whitespace'
        WHEN current_club_name != TRIM(current_club_name) THEN 'current_club_whitespace'
    END AS error_type
FROM silver.players
WHERE 
    first_name != TRIM(first_name) OR 
    last_name != TRIM(last_name) OR
    name != TRIM(name) OR
    player_code != TRIM(player_code) OR
    country_of_birth != TRIM(country_of_birth) OR
    city_of_birth != TRIM(city_of_birth) OR
    country_of_citizenship != TRIM(country_of_citizenship) OR
    sub_position != TRIM(sub_position) OR
    position != TRIM(position) OR
    foot != TRIM(foot) OR
    agent_name != TRIM(agent_name) OR
    image_url != TRIM(image_url) OR
    url != TRIM(url) OR
    current_club_domestic_competition_id != TRIM(current_club_domestic_competition_id) OR
    current_club_name != TRIM(current_club_name);

/* CHECK 05: Categorical Consistency & Historical Mapping
  Description: Identifies variations in country names and positions.
  
  Findings: 
    1. Geopolitical duplicates (e.g., 'Türkiye' vs 'Turkey', 'Czech Republic' vs 'Czechia').
    2. Historical entities (e.g., 'UdSSR', 'Yugoslavia', 'East Germany').
  
  Silver Strategy: 
    - Map historical entities to modern successors (e.g., UdSSR -> Russia) for aggregation.
    - Standardize to official international naming (UN/UEFA standards).
*/

-- Check Country naming variations

SELECT DISTINCT country_of_birth FROM silver.players ORDER BY 1;
SELECT DISTINCT country_of_citizenship FROM silver.players ORDER BY 1;

/*
Nazwa z Twoich danych; Proponowana nazwa (Ujednolicona); Powód;
Turkey,Türkiye,Oficjalna nazwa międzynarodowa (ONZ/UEFA).
Czech Republic,Czechia,Oficjalna krótka nazwa państwa.
Swaziland,Eswatini,Oficjalna zmiana nazwy państwa w 2018 r.
The Gambia,Gambia,Standaryzacja (usunięcie przedimka).
North Macedonia,North Macedonia,"(Zostawiamy – to poprawna forma po zmianie z ""Macedonia"")."
Macedonia,North Macedonia,Ujednolicenie starszych wpisów do obecnej nazwy.
Southern Sudan,South Sudan,Poprawna nazwa angielska najmłodszego państwa świata.
Brunei Darussalam,Brunei,Skrócenie do powszechnie używanej formy.
St. Kitts & Nevis,Saint Kitts and Nevis,Rozwinięcie skrótu dla spójności danych.
Zaire,DR Congo,Współczesna nazwa (Demokratyczna Republika Konga).
People's republic of the Congo,Congo,Współczesna nazwa (Republika Konga).
East Germany (GDR),Germany,Mapowanie historyczne na współczesne państwo.
UdSSR,Russia,Mapowanie historycznego sukcesora (ZSRR → Rosja).
CSSR,Czechia,Mapowanie historyczne (Czechosłowacja → Czechy*).
Yugoslavia (Republic),Serbia,Mapowanie historyczne (Jugosławia → Serbia*).
Jugoslawien (SFR),Serbia,Mapowanie historyczne.
Serbia and Montenegro,Serbia,Państwo przestało istnieć w 2006 r.
Chinese Taipei,Taiwan,Użycie nazwy geograficznej zamiast sportowej
Cote d'Ivoire, Ivory Coast, Cote d'Ivoire (to oficjalna nazwa)
Timor-Leste (jeśli się pojawi – nie używaj "East Timor")
*/

-- Check Foot preference and Position
-- Findings: Variations in casing or empty strings will be standardized to Initcap.

SELECT DISTINCT sub_position  FROM silver.players ORDER BY 1;
SELECT DISTINCT position FROM silver.players ORDER BY 1;
SELECT DISTINCT  foot FROM silver.players ORDER BY 1;


