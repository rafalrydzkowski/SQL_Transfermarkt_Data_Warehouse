--------------------------------------------------------------------------------
-- PURPOSE:  Data Quality Audit for Silver Layer - Table: game_events
-- DESCRIPTION: Validates referential integrity, football-specific logic, 
--              and string standardization for match event data.
--------------------------------------------------------------------------------

/* CHECK 01: Uniqueness & Primary Key Integrity
  Description: Validates that game_event_id is unique and non-null.
  Business Logic: Every match event (goal, sub, card) must have a unique identifier.
*/

WITH id_validation AS (
    SELECT 
        game_event_id,
        ROW_NUMBER() OVER(PARTITION BY game_event_id ORDER BY date) as row_num
    FROM silver.game_events
)
SELECT game_event_id, row_num
FROM id_validation
WHERE row_num > 1 OR game_event_id IS NULL;

/* CHECK 02: Referential Integrity (Orphan Records)
  Description: Checks for records pointing to non-existent games, players, or clubs.
  Note: Orphans in 'players' and 'clubs' are expected for domestic cup games 
        involving lower-league teams not covered in the TOP 14 dataset.
*/

-- Orphan Games (Critical: Every event must belong to a known game)
SELECT ge.game_event_id, ge.game_id
FROM silver.game_events ge
WHERE NOT EXISTS (
    SELECT 1 FROM silver.games g WHERE g.game_id = ge.game_id
);

-- Orphan Players (Context: Lower league players in cup games)
SELECT ge.game_event_id, ge.player_id
FROM silver.game_events AS ge
WHERE NOT EXISTS (
    SELECT 1 FROM silver.players AS p WHERE p.player_id = ge.player_id
);

-- Orphan Clubs (Context: Lower league clubs in cup games)
SELECT ge.game_event_id, ge.club_id, ge.club_name
FROM silver.game_events ge
WHERE NOT EXISTS (
    SELECT 1 FROM silver.clubs c WHERE c.club_id = ge.club_id
);

/* CHECK 03: Football Business Logic & Temporal Constraints
  Description: Validates that events follow physical and professional football rules.
*/

-- 3.1: The Substitution Paradox
-- Logic: A player cannot substitute themselves. 
-- Findings: 16 cases identified. 
-- Silver Strategy: player_in_id will be set to NULL via CASE WHEN to maintain row integrity.
SELECT game_event_id, game_id, player_id, player_in_id
FROM silver.game_events
WHERE type = 'Substitutions' AND player_id = player_in_id;

-- 3.2: Temporal Logic (Minute Validation)
-- Logic: Minutes must be between -1 and 130. 
-- Note: '-1' is a Transfermarkt convention for penalty shootouts or untimed events.
SELECT game_event_id, game_id, minute, type, description
FROM silver.game_events
WHERE minute < -1 OR minute > 130;

-- 3.3: Assist Consistency (Self-Assists)
-- Logic: Scorer cannot be the assist provider except in specific data-entry cases.
-- Findings: ~2300 cases (2246 earned penalties, 5 rebounds, others are errors).
-- Silver Strategy: Standardize by setting player_assist_id to NULL for cleaner aggregation.
SELECT game_event_id, player_id, player_assist_id, description
FROM silver.game_events
WHERE type = 'Goals' AND player_id = player_assist_id;

/* CHECK 04: Data Standardization & String Integrity
  Description: Identifies formatting issues like leading/trailing spaces.
  Silver Strategy: All identified fields will be wrapped in TRIM() during transformation.
*/

SELECT 
    game_event_id,
    type,
    CASE 
        WHEN game_event_id != TRIM(game_event_id) THEN 'id_whitespace'
        WHEN type != TRIM(type) THEN 'type_whitespace'
        WHEN club_name != TRIM(club_name) THEN 'club_name_whitespace'
        WHEN description != TRIM(description) THEN 'description_whitespace'
    END AS error_type
FROM silver.game_events
WHERE 
    game_event_id != TRIM(game_event_id) OR 
    type != TRIM(type) OR 
    club_name != TRIM(club_name) OR 
    description != TRIM(description);

/* CHECK 05: Categorical Consistency
  Description: Lists all unique event types to identify typos or undocumented categories.
*/

SELECT DISTINCT type 
FROM silver.game_events 
ORDER BY type;

/* CHECK 06: Final Score Reconciliation (Domestic Leagues)
   Description: Compares aggregated goal events against the official final score 
                recorded in the 'games' table for domestic league matches.
   Findings: Only 25 domestic league matches identified with mismatches, 
             confirming high data reliability for top-tier league play-by-play data.
*/

WITH cte_event_goals AS (
    SELECT 
        game_id, 
        COUNT(type) AS event_goal_sum
    FROM silver.game_events
    WHERE type = 'GOALS'
    GROUP BY game_id
)
SELECT
    c.game_id,
    c.event_goal_sum,
    (g.home_club_goals + g.away_club_goals) AS official_total_goals,
    g.competition_id,
    g.competition_type
FROM cte_event_goals AS c
LEFT JOIN silver.games AS g ON c.game_id = g.game_id
WHERE 
    g.competition_type = 'domestic_league' 
    AND c.event_goal_sum != (g.home_club_goals + g.away_club_goals);

/* FOOTNOTE ON DATA RECONCILIATION: game_events vs games
  1. Limited Scouting Coverage:
     - Full play-by-play event data is primarily available for Top 14 leagues. 
     - Matches involving lower-league opponents (e.g., domestic cups) may 
       show incomplete event logs despite having a finalized score in 'games'.
  2. Match Disruptions & Awarded Results:
     - In cases of abandoned or awarded matches (walkovers), 'game_events' 
       may contain partial/fragmented data recorded prior to the disruption.
     - The 'games' table remains the Single Source of Truth (SSOT) for the 
       official final score and match outcome.
  3. Own Goal (OG) Attribution:
     - Goals of type 'Own Goal' are explicitly attributed to the player 
       who committed the error, not the beneficiary team.
     - CAUTION: When calculating a player's offensive contribution (Goals), 
       ensure events of type 'Own Goal' are excluded to avoid negative 
       skewing of performance metrics.
  4. Domestic League Reliability:
     - Audit results show that 99.9% of domestic league matches have perfect 
       alignment between 'game_events' and 'games'. Mismatches are statistically 
       insignificant (approx. 25 cases) and likely due to rare administrative 
       revisions of match results.
  5. Recommendation:
     - Always join 'game_events' with 'games' to validate event totals 
       against official scores before generating high-stakes reports.
*/
