# 📖 Data Catalog: Gold Layer (Star Schema)

This document provides a detailed description of the tables in the **Gold Layer**, which follows a Star Schema design optimized for football analytics and business intelligence.

---

## 🏗️ Dimension Tables

### 1. `gold.dim_competitions`
* **Purpose:** Stores master records for football competitions and leagues, providing metadata for tournament classification.
> **NOTE:** In the Gold Layer, the scope is strictly limited to **domestic league matches** from the **Top 14 leagues**. Domestic cups and European competitions (e.g., Champions League, Europa League) are excluded to ensure statistical consistency and focus on league performance.

* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **competition_id** | VARCHAR(20) | **Primary Key**. Unique identifier for the competition (e.g., 'L1', 'GB1'). |
| **name** | VARCHAR(100) | Official name of the league or tournament. |
| **type** | VARCHAR(50) | Competition category (e.g., 'domestic_league'). |
| **country_name** | VARCHAR(100) | The name of the country associated with the competition. |
| **url** | VARCHAR(255) | Direct source link to the competition profile on Transfermarkt. |

---

### 2. `gold.dim_clubs`
* **Purpose:** Stores comprehensive metadata for football clubs, including infrastructure details and competition affiliation.
> **NOTE:** In the Gold Layer, the scope is strictly limited to **domestic league matches** from the **Top 14 leagues** for the period from **2012 to the present**. The `last_season` column indicates the most recent year the club participated in a Top 14 league (e.g., a club that was relegated in 2019 and has not returned to the top league since will show 2019 as its `last_season`).

* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **club_id** | INT | **Primary Key**. Unique numerical identifier for each football club. |
| **club_code** | VARCHAR(100) | Alphanumeric short code representing the club. |
| **name** | VARCHAR(100) | Official name of the football club. |
| **competition_id** | VARCHAR(20) | **Foreign Key**. Unique ID of the domestic league (links to `gold.dim_competitions`). |
| **stadium_name** | VARCHAR(100) | Name of the club's home stadium. |
| **stadium_seats** | INT | Total spectator capacity of the stadium. |
| **last_season** | INT | The last season the club competed in a Top 14 domestic league (Range: 2012–Present). |
| **url** | VARCHAR(255) | Direct source link to the club profile on Transfermarkt. |

---

### 3. `gold.dim_games`
* **Purpose:** Provides detailed context for individual match fixtures, including technical setups and match-day metadata.
> **NOTE:** In the Gold Layer, the scope is strictly limited to **domestic league matches** from the **Top 14 leagues**. Domestic cups and European competitions (e.g., Champions League, Europa League) are excluded to ensure statistical consistency and focus on league performance.

* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **game_id** | INT | **Primary Key**. Unique identifier for the match fixture. |
| **competition_id** | VARCHAR(20) | **Foreign Key**. Unique ID of the competition (links to `gold.dim_competitions`). |
| **competition_type** | VARCHAR(50) | Type of competition (e.g., 'domestic_league'). |
| **season** | INT | Calendar year the season started (e.g., 2023). |
| **round** | VARCHAR(50) | Standardized matchday or round name (e.g., 'Matchday 05'). |
| **date** | DATE | The date the match was played. |
| **home_club_id** | INT | Unique identifier for the home team. |
| **home_club_name** | VARCHAR(100) | Official name of the home club. |
| **away_club_id** | INT | Unique identifier for the away team. |
| **away_club_name** | VARCHAR(100) | Official name of the away club. |
| **aggregate** | VARCHAR(20) | Aggregate score (used primarily in specific league formats). |
| **home_club_manager_name** | VARCHAR(50) | Name of the home team manager. |
| **away_club_manager_name** | VARCHAR(50) | Name of the away team manager. |
| **home_club_formation** | VARCHAR(50) | Tactical lineup used by the home team (e.g., '4-3-3'). |
| **away_club_formation** | VARCHAR(50) | Tactical lineup used by the away team. |
| **stadium** | VARCHAR(150) | Name of the stadium where the match took place. |
| **attendance** | INT | Total number of spectators present. |
| **referee** | VARCHAR(100) | Full name of the match official. |
| **url** | VARCHAR(255) | Direct source link to the match report on Transfermarkt. |

---

### 4. `gold.dim_players`
* **Purpose:** Comprehensive master data for football players, enriched with demographic attributes and technical profiles.
> **NOTE:** In the Gold Layer, the scope is strictly limited to **domestic league matches** from the **Top 14 leagues** for the period from **2012 to the present**. The `last_season` column indicates the most recent year the player was active in a Top 14 league.

* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **player_id** | INT | **Primary Key**. Unique identifier assigned to each player. |
| **first_name** | VARCHAR(100) | Player's given name. |
| **last_name** | VARCHAR(100) | Player's family name. |
| **name** | VARCHAR(255) | Full display name (Combined first and last name). |
| **last_season** | INT | The last season the player was registered in a Top 14 league. |
| **current_club_id** | INT | **Foreign Key**. Links to `gold.dim_clubs` (Current or last club from TOP14 Leagues). |
| **current_club_name** | VARCHAR(100) | Denormalized name of the player's current/last club for easier querying. |
| **current_club_domestic_competition_id** | VARCHAR(20) | ID of the domestic league where the player's club competes. |
| **country_of_birth** | VARCHAR(100) | Standardized name of the country where the player was born. |
| **city_of_birth** | VARCHAR(100) | City of birth. |
| **country_of_citizenship** | VARCHAR(100) | Primary nationality of the player. |
| **date_of_birth** | DATE | Player's birthday (YYYY-MM-DD). |
| **sub_position** | VARCHAR(50) | Specific tactical position (e.g., 'Centre-Forward', 'Left-Back'). |
| **position** | VARCHAR(50) | General field position (e.g., 'Attack', 'Defender'). |
| **foot** | VARCHAR(20) | Preferred kicking foot (Left, Right, Both). |
| **height_in_cm** | INT | Player's height measured in centimeters. |
| **market_value_in_eur** | NUMERIC(15,2) | Most recent estimated market value in Euros. |
| **highest_market_value_in_eur** | NUMERIC(15,2) | The peak market value achieved during the player's career. |
| **contract_expiration_date** | DATE | Expiry date of the current professional contract. |
| **agent_name** | VARCHAR(150) | Name of the agency or agent representing the player. |
| **image_url** | VARCHAR(255) | Link to the player's profile picture. |
| **url** | VARCHAR(255) | Direct source link to the player profile on Transfermarkt. |

---
