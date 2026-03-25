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

* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **club_id** | INT | **Primary Key**. Unique numerical identifier for each football club. |
| **club_code** | VARCHAR(100) | Alphanumeric short code representing the club. |
| **name** | VARCHAR(100) | Official name of the football club. |
| **competition_id** | VARCHAR(20) | **Foreign Key**. Unique ID of the domestic league (links to `gold.dim_competitions`). |
| **stadium_name** | VARCHAR(100) | Name of the club's home stadium. |
| **stadium_seats** | INT | Total spectator capacity of the stadium. |
| **last_season** | INT | The most recent season in which the club was active in the filtered dataset. |
| **url** | VARCHAR(255) | Direct source link to the club profile on Transfermarkt. |
| **filename** | VARCHAR(255) | Reference to the source data file used for ingestion. |

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

