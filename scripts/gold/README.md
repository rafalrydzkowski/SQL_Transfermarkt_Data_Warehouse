# 🥇  Gold Layer: Business Logic & Star Schema

## 🎯 Overview
The Gold Layer (also known as the "Analytics Layer") represents the final stage of the data warehouse. It transforms standardized data from the **Silver** schema into a high-performance **Star Schema** optimized for BI tools (Power BI, Tableau) and advanced analytical queries.

The primary focus of this layer is the **Top 14 domestic leagues**, ensuring a noise-free environment for football business intelligence by excluding non-league match data.

## 🏗️ Architecture Principles
- **Star Schema Design:** Organized into clear Dimension (`dim_`) and Fact (`fact_`) tables for optimal join performance.
- **Granularity:** Highly granular event-level data (player appearances) and aggregated team metrics.
- **Referential Integrity:** Enforced Foreign Key constraints to ensure data consistency between descriptive dimensions and numeric facts.

## ⚙️ Ingestion & ETL Orchestration (`gold.sp_load_gold`)

#### **Hybrid Loading Strategy**
* **Dimensions (UPSERT):** Uses `ON CONFLICT DO UPDATE` to maintain persistent IDs. This ensures that existing records are updated with the latest attributes without breaking historical links.
* **Facts (TRUNCATE & LOAD):** Employs a full refresh strategy. This is critical for complex window functions (like market value changes or record-breaking flags) to ensure they are re-calculated correctly across the entire history.

#### **Advanced Business Logic & Analytics**
* **Window Functions:** Implements `LAG()`, `MAX() OVER()`, and `PARTITION BY` to derive analytical flags such as `is_current_valuation` or `is_record_breaking_for_player`.
* **Dynamic Age Calculation:** Automatically calculates `valuation_age` based on the player's date of birth at the specific moment of valuation.
* **Financial Delta Tracking:** Computes `valuation_change_prev` to track the financial trajectory of players across multiple seasons.
* **Venue Intelligence:** Derives `stadium_filling_rate` by correlating match attendance with official stadium capacities stored in the club dimension.

#### **League-Centric Filtering**
* **Scope Control:** Automatically filters out domestic cups and international competitions via `WHERE type = 'domestic_league'`.
* **Performance Metrics:** Standardizes match outcomes into a universal `points` system (3 for win, 1 for draw, 0 for loss) to enable instant league table generation.

## 🛠️ Data Model Highlights

### **Dimensions (The "Who", "Where", "What")**
- **`dim_players`:** Master record for players, including their latest season and current club affiliation.
- **`dim_clubs`:** Unified club metadata, including stadium details and competition membership.
- **`dim_competitions`:** Reference table for the tracked Top 14 leagues.
- **`dim_games`:** Chronological record of matches with tactical info (formations) and attendance.

### **Facts (The "How Much", "When")**
- **`fact_player_stats`:** Detailed match-by-match performance metrics (goals, assists, cards, minutes).
- **`fact_team_stats`:** Aggregated team performance per game, including goal differences and manager tracking.
- **`fact_player_valuations`:** Historical time-series of player market value evolution.
- **`fact_transfers`:** Comprehensive log of player movements, including fee analysis and "record-breaking" flags.

## 🚦 How to run
To refresh the Gold Layer and recalculate all business metrics, execute the following command in your PostgreSQL environment:

```sql
CALL gold.sp_load_gold();
