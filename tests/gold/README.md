# 🛡️ Data Quality Framework - Gold Layer

## 🎯 Overview
This directory contains a suite of SQL validation scripts designed to ensure the integrity, consistency, and business accuracy of the **Gold Layer** within the `SQL_Data_Warehouse_Transfermarkt` project. 

> **Goal:** To certify that all data is "Reporting-Ready" for professional analysis in SQL or BI tools like Power BI by catching anomalies before they reach the end-user. 🚀

## 🧪 Testing Methodology
Each of the 8 core tables is subjected to a multi-layered validation approach:

### 1. Technical & Structural Integrity
* **Primary Key Uniqueness:** Verified using `ROW_NUMBER()` window functions to ensure the defined grain of each table is strictly maintained.
* **Referential Integrity:** Cross-table validation using `NOT EXISTS` and `UNION ALL` to ensure every Fact record (Transfers, Stats, Valuations) has a corresponding entry in the Dimensions (Players, Clubs, Competitions).

### 2. Domain-Specific Business Logic
* **The Mirror Test:** (Applied to `fact_team_stats`) – A symmetry validation for dual-entry match records. It ensures that Team A’s "Goals Scored" exactly matches Team B’s "Goals Conceded."
* **Match Result Logic:** Validation of the points system (3 for Win, 1 for Draw, 0 for Loss) against the boolean flags (`is_win`, `is_draw`, `is_loss`).
* **Scope Enforcement:** Strict filtering validation to ensure only **Top 14 Domestic Leagues** from **2012–Present** are included, as per project requirements.

### 3. Biological & Financial Sanity Checks
* **Physical Attributes:** Range checks for player height (>120cm) and age (>15 years at debut) to eliminate data scraping anomalies.
* **Financial Consistency:** Ensuring current `market_value_in_eur` does not exceed the historical `highest_market_value_in_eur`.
* **Stadium Logistics:** Validation of stadium capacities to prevent "Division by Zero" errors during attendance rate calculations.

### 4. Denormalization & Sync Checks
* **Attribute Synchronization:** Comparing denormalized names (e.g., `current_club_name` in `dim_players`) against their source-of-truth in `dim_clubs` to prevent data drift and filtering errors in reports.

---

## 📋 Test Coverage (8 Tables)

| Category | Table | Primary Validation Focus |
| :--- | :--- | :--- |
| **Dimensions** | `gold.dim_players` | PK, Age/Height sanity, Financial peak consistency, URL formats. |
| **Dimensions** | `gold.dim_clubs` | PK, Stadium seat ranges, Competition affiliation, Last season scope. |
| **Dimensions** | `gold.dim_games` | PK, Home/Away ID conflict, Attendance logic, Date range (2012+). |
| **Dimensions** | `gold.dim_competitions` | PK, Type validation (Domestic League only), Top 14 count. |
| **Facts** | `gold.fact_team_stats` | **Mirror Symmetry**, Points logic, Clean sheet vs Opponent goals. |
| **Facts** | `gold.fact_player_stats` | PK (Game+Player), Stat caps per game, FK Integrity. |
| **Facts** | `gold.fact_transfers` | Transfer fee ranges, Date vs Season logic, Club/Player FKs. |
| **Facts** | `gold.fact_player_valuations`| Valuation trends, Date consistency, Club assignment. |

---

## 🚀 Execution Guide
Scripts are designed to return **Zero Results** upon success. 

1. **Execute** the `.sql` script
2. **Review:** Any returned records represent a **Data Quality Failure** ❌ that must be investigated and explained.
