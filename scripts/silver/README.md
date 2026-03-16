# 🥈 Silver Layer: Cleaning, Transformation & Standardization

## 🎯 Overview
The Silver Layer (also known as the "Cleansing Layer") is responsible for transforming raw data from the **Bronze** schema into a clean, consistent, and relational format. 

The primary goal is to ensure that all data is "analytics-ready" before it reaches the Gold Layer for final business logic application.

## 🏗️ Architecture Principles
- **Immutability:** Data is loaded from bronze layer tables.
- **Data Transformation:** Cleaning, standardization, normalization, data enrichment, derived columns.

## ⚙️ Ingestion & ETL Orchestration (`sp_load_silver`)

#### **Execution Control**
* **Full Refresh Strategy:** Employs a `TRUNCATE-and-INSERT` workflow to maintain a "Clean Slate" architecture for every batch.
* **Performance Monitoring:** Logs sub-second execution times (`v_job_duration`) and total batch duration using `clock_timestamp()`.
* **Audit Logging:** Automated row-count tracking and reporting per table via `GET DIAGNOSTICS`.
* **Fault Tolerance:** Implemented a robust `EXCEPTION` block to capture `SQLSTATE` and `SQLERRM`, ensuring error visibility without database cluster interruption.

#### **Data Cleansing & Transformation**
* **String Normalization:** Global enforcement of naming conventions using `TRIM`, `UPPER`, `LOWER`, and `INITCAP`.
* **Advanced Regex Parsing:** Utilizes `regexp_replace` to unify competition rounds (e.g., standardizing qualification phases) and strip redundant prefixes from tactical formations.
* **Financial Scaling:** Logic-based `CASE` statements to convert human-readable market values (e.g., '10m', '500k') into standardized `NUMERIC` types for precise aggregation.
* **Geo-Data Alignment:** Maps legacy, non-English, or inconsistent country names (e.g., "Türkiye" → "Turkey", "Zaire" → "DR Congo") to modern ISO-standard English equivalents.
* **Temporal Standardization:** Parses inconsistent season strings (e.g., "23/24") into 4-digit Gregorian years to enable chronological time-series analysis.

#### **Data Quality & Referential Integrity**
* **Outlier Mitigation:** Enforces physical business rules (e.g., nullifying heights < 120cm or jersey numbers > 99).
* **Match-Clock Validation:** Hard-caps match minutes at 120m to eliminate common data-entry errors (e.g., 999 min entries).
* **Null Handling:** Converts logical `0` values in financial and squad metrics to `NULL`, preventing skewed statistical averages in the Gold Layer.
* **Logical Consistency Checks:** Validates match events to ensure internal integrity (e.g., preventing a player from assisting their own goal or substituting themselves).

## 🛠️ Key Transformations Examples
- **Market Values:** Cleaned and scaled from human-readable strings (e.g., "€10.0m") to exact numeric values.
- **Competition Rounds:** Standardized over 50+ variations of round names into 10 consistent categories.
- **Geopolitics:** Normalized country names to handle historical and linguistic variations in source data.

## 🚦 How to run
To refresh the Silver Layer, execute the following command in your PostgreSQL environment:
```sql
CALL silver.sp_load_silver();
