# SQL_Data_Warehouse_Transfermarkt

# 1. Project Architecture



The system follows the **Medallion Architecture** pattern, implemented within a **PostgreSQL 16+** environment. This modular approach ensures strict data lineage, high quality through validation, and optimized performance for complex analytical queries.



---



### 🏗️ Architectural Layers



#### 🥉 Bronze (Raw / Landing Zone)

* **Purpose:** Direct ingestion of raw Transfermarkt datasets (CSV)

* **Strategy:** "Load-first, transform-later." Tables use flexible schema (primarily `TEXT`) to ensure 100% ingestion success and prevent data loss during the initial load.

* **Integrity:** No Foreign Keys or complex constraints at this stage. Data is immutable.



#### 🥈 Silver (Standardized / Cleaned)

* **Purpose:** The "Single Source of Truth." Data is cleansed, typed, and normalized.

* **Key Actions:**

    * **Data Typing:** Converting strings to proper types (e.g., `NUMERIC(15,2)` for fees, `DATE` for match days).

    * **Normalization:** Implementation of (`PK`) to ensure data quality.
      
    * **Integrity:** No Foreign Keys at this stage.

    * **Deduplication:** Removal of overlapping records from incremental source files.

* **Integrity:** No Foreign Keys, only Primary Keys (for better performance). Strict enforcement of `NOT NULL`, `UNIQUE`, and `CHECK` constraints.



#### 🥇 Gold (Curated / Analytics-Ready)

* **Purpose:** High-performance reporting and Business Intelligence (BI).

* **Modeling:** Transition to a **Dimensional Model (Star Schema)**.

* **Integrity:** Primary/Foreign Keys (`PK/FK`) implemented.

* **Components:** * **Fact Tables:** Centrally located quantitative data (e.g., `fact_transfers`, `fact_player_valuation`, `fact_player_stats`, `fact_team_stats`).

    * **Dimension Tables:** Descriptive attributes (e.g., `dim_players`, `dim_clubs`, `dim_competitions`, `dim_games`).

* **Optimization:** Use of Indexing (B-Tree) for query execution.



---



### 🔄 Data Flow Process



1. **Ingestion:** Raw files → **Bronze Layer** (STG tables).

2. **Refining:** SQL scripts transform Bronze → **Silver Layer** (Base tables).

3. **Aggregating:** Business logic transforms Silver → **Gold Layer** (Analytics tables).



## 2. Data Source & Raw Dataset



The project utilizes the **Complete Transfermarkt Dataset** sourced from [Kaggle (David Cariboo)](https://www.kaggle.com/datasets/davidcariboo/player-scores). This dataset provides a comprehensive look at European football dynamics from 2012 to the present.



### 📊 Dataset Inventory

The raw data is ingested from 10 CSV files, forming the foundation of the Bronze Layer.



| File Name | Primary Entity | Key Relationships | Description |

| :--- | :--- | :--- | :--- |

| `players.csv` | **Players** | `current_club_id` | Biometrics, position, and contract details. |

| `clubs.csv` | **Clubs** | `domestic_competition_id` | Stadium info, squad size, and net transfer records. |

| `competitions.csv`| **Leagues** | `country_id` | Confederation and league tier metadata. |

| `games.csv` | **Matches** | `competition_id`, `home/away_club_id` | Match-level results, attendance, and managers. |

| `transfers.csv` | **Transfers** | `player_id`, `from/to_club_id` | Transactional data: fees, seasons, and market values. |

| `appearances.csv` | **Stats** | `game_id`, `player_id` | Individual performance (goals, assists, minutes). |

| `player_valuations.csv`| **Value** | `player_id` | Time-series data of player market value evolution. |

| `game_lineups.csv` | **Lineups** | `game_id`, `player_id` | Starting XIs, bench, and captaincy data. |

| `game_events.csv` | **Events** | `game_id`, `player_id` | Granular events: cards, subs, and assists. |

| `club_games.csv` | **Results** | `game_id`, `club_id` | Aggregated match outcomes from a club's perspective. |



> **Audit Note:** The Data may contain 'Orphan' records for Players and Clubs. This is a known architectural characteristic resulting from the upstream data extraction logic between Transfermarkt and the Kaggle dataset. More about pulling up data process from Transfermarkt Website: [Transfermarkt-Scraper](https://github.com/dcaribou/transfermarkt-scraper)

## 3. Technical Stack & Logic

### 🛠 Technology Stack
* **Database:** PostgreSQL 16+
* **Data Ingestion:** SQL `COPY` Command
* **Modeling:** Star Schema (Gold)
* **Documentation:** Markdown, DBML & PNG

### 🧩 Key SQL Concepts Implemented
To ensure production-grade quality, the following advanced SQL techniques are utilized:

* **Data Integrity:** Strict usage of `PRIMARY KEY` and `FOREIGN KEY` to prevent data corruption.
* **Complex Transformations:** Using **CTEs (Common Table Expressions)**, **Window Functions** and **CASE Statements** for player/team performance and market value trends.
* **Performance Optimization:** * **B-Tree Indexes** on join keys (IDs).
    * **Partial Indexes** for active player filtering.
* **Automation:** PL/pgSQL Stored Procedures for the ETL process between Bronze, Silver and Gold layers.

## 4. Business & Analytical Use Cases

This project is designed to answer complex sports-business questions through advanced SQL modeling. Below are the primary analytical tracks:

### ⚽ Player Market Analysis
* **Market Value vs. Performance:** Correlation between a player's valuation trends and their actual on-field output (goals, assists per 90 mins).
* **Transfer ROI:** Identifying "Value Picks" by analyzing players bought for low fees who achieved significant market value growth.

### 🏟️ Club & League Dynamics
* **Net Spend Leaderboard:** Live tracking of club transfer balances (Expenditure vs. Income) per season.
* **Squad Stability Index:** Analyzing how turnover (number of transfers) affects a team's position in the league table.

### 📈 Historical Trends
* **Inflation Tracking:** Monitoring the average transfer fee growth across major European leagues over the last decade.
* **Aging Curves:** Analyzing at what age players in specific positions (e.g., Strikers vs. Defenders) reach their peak market value.

## 🌟 About Me
I am a **Data Engineering / Data Analytics enthusiast** with a focus on building scalable, high-integrity data warehouses. I specialize in transforming raw, messy datasets into actionable business intelligence using PostgreSQL and modern architectural patterns.

* **Looking for:** Junior Data Engineer or Data Analyst roles.
* **Tech I love:** SQL (PostgreSQL), Data Modeling (3NF/Star Schema), Excel, PowerBI
* **Fun Fact:** I chose the Transfermarkt dataset because I believe sports analytics is the ultimate test for handling temporal data and complex relational integrity.

📫 **Let's connect:** www.linkedin.com/in/rafał-rydzkowski-319aa7252 | RafalRydzkowskiJ@gmail.com
