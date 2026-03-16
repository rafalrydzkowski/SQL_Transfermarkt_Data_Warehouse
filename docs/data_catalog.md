# 📖 Data Catalog: Gold Layer (Star Schema)

This document provides a detailed description of the tables in the **Gold Layer**, which follows a Star Schema design optimized for football analytics and business intelligence.

---

## 🏗️ Dimension Tables

### 1. `gold.dim_competitions`
* **Purpose:** Stores master records for football competitions and leagues.
* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| competition_id | VARCHAR(20) | Primary Key. Unique identifier for the competition (e.g., 'L1', 'PL'). |
| name | VARCHAR(100) | Official name of the league or tournament. |
| type | VARCHAR(50) | Classification (e.g., 'domestic_league', 'international_cup'). |
| country_name | VARCHAR(100) | Name of the country hosting the competition. |
| url | VARCHAR(255) | Source link to the competition page on Transfermarkt. |

---

### 2. `gold.dim_clubs`
* **Purpose:** Contains detailed information about football clubs across various seasons.
* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| club_id | INT | Primary Key. Unique numerical identifier for each club. |
| club_code | VARCHAR(100) | Alphanumeric short code representing the club. |
| name | VARCHAR(100) | Official name of the football club. |
| competition_id | VARCHAR(20) | Foreign Key. Current domestic league the club participates in. |
| stadium_name | VARCHAR(100) | Home ground name. |
| stadium_seats | INT | Total capacity of the club's stadium. |
| last_season | INT | The most recent season the club was active in the dataset. |
| url | VARCHAR(255) | Link to the club profile on Transfermarkt. |

---

### 3. `gold.dim_players`
* **Purpose:** Comprehensive master data for players, enriched with demographic and market attributes.
* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| player_id | INT | Primary Key. Unique identifier assigned to each player. |
| first_name | VARCHAR(100) | Player's given name. |
| last_name | VARCHAR(100) | Player's family name. |
| name | VARCHAR(255) | Full display name. |
| current_club_id | INT | Foreign Key referencing the player's current club. |
| country_of_citizenship | VARCHAR(100) | Primary nationality of the player. |
| date_of_birth | DATE | Player's birthday (formatted YYYY-MM-DD). |
| position | VARCHAR(50) | Main field position (e.g., 'Attack', 'Midfield'). |
| market_value_in_eur | NUMERIC(15,2) | Most recent estimated market value. |
| highest_market_value_in_eur | NUMERIC(15,2) | Peak career market value recorded. |

---

### 4. `gold.dim_games`
* **Purpose:** Contextual data for specific match fixtures.
* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| game_id | INT | Primary Key. Unique identifier for a match fixture. |
| competition_id | VARCHAR(20) | Foreign Key. League or Cup the game belongs to. |
| season | INT | Calendar year the season started (e.g., 2023). |
| round | VARCHAR(50) | Standardized round name (e.g., 'Matchday 05', 'Final'). |
| date | DATE | Date the match was played. |
| home_club_id | INT | Foreign Key referencing the home team. |
| away_club_id | INT | Foreign Key referencing the away team. |
| attendance | INT | Total number of spectators present. |

---

## 📈 Fact Tables

### 1. `gold.fact_player_stats`
* **Purpose:** Granular data for every player appearance in a match.
* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| appearance_id | VARCHAR(50) | Primary Key. Unique ID for a player's stint in a game. |
| game_id | INT | Foreign Key. Links to `dim_games`. |
| player_id | INT | Foreign Key. Links to `dim_players`. |
| goals | INT | Number of goals scored in the match. |
| assists | INT | Number of assists provided. |
| yellow_cards | INT | Total yellow cards received (0-2). |
| minutes_played | INT | Total time on the pitch (capped at 120m). |
| is_starting_lineup | BOOLEAN | Indicates if the player started the match. |
| is_win | BOOLEAN | Flag indicating if the player's team won the match. |

---

### 2. `gold.fact_team_stats`
* **Purpose:** Aggregated performance metrics from a team's perspective for each match.
* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| game_id | INT | Composite Primary Key. Links to `dim_games`. |
| club_id | INT | Composite Primary Key. Links to `dim_clubs`. |
| own_goals | INT | Total goals scored by the team. |
| opponent_goals | INT | Total goals conceded. |
| goal_difference | INT | Calculated as `own_goals - opponent_goals`. |
| stadium_filling_rate | NUMERIC(10,2) | Percentage of stadium capacity utilized (Attendance/Seats). |
| points | INT | Calculated points (Win: 3, Draw: 1, Loss: 0). |
| is_clean_sheet | BOOLEAN | Indicates if the team conceded zero goals. |

---

### 3. `gold.fact_transfers`
* **Purpose:** Logs all professional transfers and loan moves.
* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| transfer_id | INT | Primary Key. Unique record for a transfer event. |
| player_id | INT | Foreign Key. Links to `dim_players`. |
| transfer_date | DATE | Official date of the transaction. |
| transfer_fee | NUMERIC(15,2) | Monetary value of the transfer in EUR. |
| from_club_id | INT | Foreign Key referencing the selling club. |
| to_club_id | INT | Foreign Key referencing the buying club. |
| is_latest_transfer | BOOLEAN | Flag to identify the player's most recent move. |

---

### 4. `gold.fact_player_valuations`
* **Purpose:** Historical tracking of player market value fluctuations.
* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| player_id | INT | Composite Primary Key. Links to `dim_players`. |
| date_of_valuation | DATE | Composite Primary Key. Date the valuation was updated. |
| market_value_in_eur | NUMERIC(15,2) | Estimated market value at that point in time. |
| valuation_age | INT | Player's age at the time of valuation. |
| valuation_change_prev | NUMERIC(15,2) | Difference compared to the previous valuation record. |
| is_highest_ever | BOOLEAN | Flag identifying the player's peak market value record. |
