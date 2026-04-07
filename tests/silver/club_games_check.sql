--------------------------------------------------------------------------------
-- PURPOSE:  Data Quality Audit for Silver Layer - Table: club_games
-- DESCRIPTION: Validates match results, hosting consistency, and referential 
--              integrity for the club-to-game relationship.
--------------------------------------------------------------------------------

/* CHECK 01: Uniqueness & Primary Key Integrity
  Logic: Validates that key(game_id, hosting) is unique and non-null.
*/

WITH id_validation AS (
    SELECT 
        game_id,
        is_home,
        ROW_NUMBER() OVER(PARTITION BY game_id, is_home ORDER BY game_id) as row_num
    FROM silver.club_games
)
SELECT game_id, is_home, row_num
FROM id_validation
WHERE 
    row_num > 1 OR 
    game_id IS NULL
    OR is_home IS NULL;

/* CHECK 02: Referential Integrity (Orphan Records)
  Description: Identifies records referencing missing games or clubs.
  Note: Club orphans are expected for lower-league opponents in cup fixtures.
*/

-- Games: Every record in club_games must link to a valid record in games.

SELECT cg.game_id
FROM silver.club_games AS cg
WHERE NOT EXISTS (
    SELECT 1 FROM silver.games AS g WHERE g.game_id = cg.game_id
);

-- Orphan Clubs: Validates current club coverage against the clubs master table.

SELECT cg.game_id, cg.club_id
FROM silver.club_games AS cg
WHERE NOT EXISTS (
    SELECT 1 FROM silver.clubs AS c WHERE c.club_id = cg.club_id
);

/* CHECK 03: Football Business Logic (Match Result Integrity)
  Description: Ensures the 'is_win' flag aligns with 'own_goals' vs 'opponent_goals'.
  Logic: 
    - If is_win = 1, own_goals must be > opponent_goals.
    - If is_win = 0, own_goals must be <= opponent_goals.
*/

SELECT 
    game_id, 
    club_id,
    own_goals,
    opponent_id,
    opponent_goals,
    is_win
FROM silver.club_games
WHERE 
    (own_goals <= opponent_goals AND is_win = TRUE) OR -- Case A: Impossible Wins (Flagged as win but goals don't match)
    (own_goals > opponent_goals AND is_win = FALSE); -- Case B: Impossible Losses/Draws (Goals show a win but is_win = 0)

/* CHECK 04: Data Standardization & String Integrity
  Description: Identifies formatting issues like leading/trailing spaces.
*/

SELECT 
    game_id,
    club_id,
    CASE 
        WHEN own_manager_name != TRIM(own_manager_name) THEN 'own_manager_name_whitespace'
        WHEN opponent_manager_name != TRIM(opponent_manager_name) THEN 'opponent_manager_name_whitespace'
    END AS error_type
FROM silver.club_games
WHERE 
    own_manager_name != TRIM(own_manager_name) OR
    opponent_manager_name != TRIM(opponent_manager_name);

/* CHECK 05: Categorical Consistency
  Description: Validates that ENUM-like fields contain expected values.
  Expected: hosting (Home/Away), is_win (0/1).
*/

SELECT DISTINCT is_home FROM silver.club_games ORDER BY 1;
SELECT DISTINCT is_win FROM silver.club_games ORDER BY 1;

/* CHECK 06: Cross-Table Result Reconciliation
  Description: Validates that the score recorded in 'club_games' matches the 
               aggregate score in the 'games' master table.
  Logic: Sum of 'own_goals' for both participants in club_games must equal 
         the total goals (home + away) in the games table.
*/

WITH cte_goals AS (
    SELECT game_id, SUM(own_goals + opponent_goals) AS sum_goals
    FROM silver.club_games
    WHERE is_home = TRUE
    GROUP BY game_id
)
SELECT 
    c.game_id,
    c.sum_goals,
    g.home_club_goals + g.away_club_goals,
    ABS(c.sum_goals - (g.home_club_goals + g.away_club_goals)) AS goal_diff
FROM cte_goals AS c
LEFT JOIN silver.games AS g
ON c.game_id = g.game_id
WHERE c.sum_goals != g.home_club_goals + g.away_club_goals;
