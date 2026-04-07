--------------------------------------------------------------------------------
-- PURPOSE:  Silver Layer Data Quality Audit - Table: appearances
-- DESCRIPTION: Performs referential integrity, business logic, and physical 
--              constraint validations. Identifies if any records left require extra cleaning
--              after Silver layer transformation.
--------------------------------------------------------------------------------

/* CHECK 01: Uniqueness & Primary Key Integrity
   Validates that appearance_id is unique and matches the business logic 
   composite key: (game_id + '_' + player_id).
*/

WITH id_validation AS (
    SELECT 
        appearance_id,
        game_id,
        player_id,
        ROW_NUMBER() OVER(PARTITION BY appearance_id ORDER BY date) as row_num
    FROM silver.appearances
)
SELECT appearance_id, game_id, player_id, row_num
FROM id_validation
WHERE row_num > 1 
   OR appearance_id IS NULL 
   OR appearance_id != (game_id || '_' || player_id);

/* CHECK 02: Dimensional Referential Integrity (Orphan Players & Clubs)
   Identifies players/clubs in appearances missing from the dimension tables.
   EXPECTED BEHAVIOR: 
   - Some orphans are expected because the 'players' table only contains 
     athletes from Top 14 leagues (2012-Present).
   - Cup games involving lower-league opponents will naturally produce orphans.
*/

-- Orphan Players Check
SELECT a.appearance_id, a.player_id, a.player_name
FROM silver.appearances a
WHERE NOT EXISTS (
    SELECT 1 
    FROM silver.players p 
    WHERE p.player_id = a.player_id
);

-- Orphan Clubs Check (Validating club_id at the time of the match)
SELECT a.appearance_id, a.club_id, a.player_name
FROM silver.appearances a
WHERE NOT EXISTS (
    SELECT 1 
    FROM silver.clubs c 
    WHERE c.club_id = a.club_id
);

/* CHECK 03: Fact-to-Fact Referential Integrity (Games)
   Description: Every appearance must be linked to a valid record in the 'games' table.
*/
SELECT a.appearance_id, a.game_id
FROM silver.appearances a
WHERE NOT EXISTS (
    SELECT 1 
    FROM silver.games g
    WHERE g.game_id = a.game_id
);

-- Description: Every competition_id must be linked to a valid record in the 'competitions' table.

SELECT a.appearance_id, a.club_id, a.competition_id
FROM silver.appearances a
WHERE NOT EXISTS (
    SELECT 1 
    FROM silver.competitions c 
    WHERE c.competition_id = a.competition_id
);

/* CHECK 04: Physical Constraints & Football Business Logic
    Description: Checks for statistically impossible game data.
   - yellow_cards > 2: Impossible per FIFA Laws of the Game.
   - red_cards > 1: Impossible per FIFA Laws of the Game.
   - minutes_played > 120 (for cup games) OR > 90 (for domestic league games).
    Findings: 3 players identified with minutes_played > 130 (outliers).
    Fix: Capped at maximum theoretical limit (120') in the Silver Layer.
*/

SELECT 
    appearance_id,
    game_id,
    player_id,
    player_name, 
    yellow_cards, 
    red_cards, 
    minutes_played
FROM silver.appearances
WHERE 
    yellow_cards > 2 OR              
    red_cards > 1;        

-- Minutes played check:

SELECT 
    a.appearance_id,
    a.game_id,
    a.competition_id,
    a.player_id,
    a.player_name, 
    a.minutes_played,
    c.is_major_national_league
FROM silver.appearances AS a
LEFT JOIN silver.competitions AS c
ON a.competition_id = c.competition_id
WHERE
    (c.is_major_national_league = 'false' AND a.minutes_played > 120) OR
    (c.is_major_national_league = 'true' AND a.minutes_played > 90) OR
    a.minutes_played < 0;

/* CHECK 05: Temporal and Relational Alignment
   Description: Ensures the event date aligns with the game schedule and 
   validates that the player's club was a participant in that specific game.
*/

SELECT
  a.appearance_id,
  a.game_id,
  a.date AS appearance_date,
  g.date AS game_date,
  a.club_id,
  g.home_club_id,
  g.away_club_id
FROM silver.appearances AS a
LEFT JOIN silver.games AS g ON a.game_id = g.game_id
WHERE 
  a.date != g.date OR
  (g.home_club_id != a.club_id AND g.away_club_id != a.club_id);

/* CHECK 06: Biological Constraints (Age Integrity)
   Description: Flags players appearing at an age inconsistent with pro football.
   Logic: Minimum 15 years for general leagues; minimum 14 years for 
          Turkish Süper Lig (TR1) due to specific league exceptions.
*/

SELECT 
    a.game_id,
    a.player_id,
    a.date AS game_date,
    p.date_of_birth,
    EXTRACT(YEAR FROM AGE(a.date, p.date_of_birth)) AS age_at_game
FROM silver.appearances AS a
LEFT JOIN silver.players AS p ON a.player_id = p.player_id
WHERE 
    (a.competition_id != 'TR1' AND EXTRACT(YEAR FROM AGE(a.date, p.date_of_birth)) < 15) OR
    (a.competition_id = 'TR1' AND EXTRACT(YEAR FROM AGE(a.date, p.date_of_birth)) < 14);

/* FOOTNOTE ON DATA DISCREPANCIES:
  1. Goal totals in 'appearances' will NOT match 'games' exactly.
  2. Reasons: 
     - 'appearances' excludes Own Goals (OG).
     - 'appearances' lacks data for lower-league players (outside TOP 14) in cup games.
  3. Recommendation: For club-level stats, use 'games'. For player KPIs, use 
     'appearances' but acknowledge the missing context for lower-league opponents.
*/

/* CHECK 07: Data Standardization & String Integrity
  Description: Identifies fields with whitespace issues requiring TRIM()
*/

SELECT 
    appearance_id,
    CASE 
        WHEN competition_id != TRIM(competition_id) THEN 'competition_id_whitespace'
        WHEN player_name != TRIM(player_name) THEN 'player_name_whitespace'
        WHEN appearance_id != TRIM(appearance_id) THEN 'appearance_id_whitespace'
    END AS error_type
FROM silver.appearances
WHERE 
    competition_id != TRIM(competition_id) OR
    player_name != TRIM(player_name) OR
    appearance_id != TRIM(appearance_id);

/* CHECK 08: Categorical Consistency
  Description: Verifies distinct values for normalization planning
*/

SELECT DISTINCT yellow_cards FROM silver.appearances ORDER BY 1;

SELECT DISTINCT red_cards FROM silver.appearances ORDER BY 1;

SELECT DISTINCT goals FROM silver.appearances ORDER BY 1;

SELECT DISTINCT assists FROM silver.appearances ORDER BY 1;



