# 🥉 Bronze Layer: Raw Data Ingestion

## 🎯 Overview
The Bronze Layer (also known as the "Landing" or "Raw" Layer) serves as the entry point for all Transfermarkt data into the warehouse. 
The primary objective is to replicate source flat files into the PostgreSQL environment with **zero transformations**, ensuring an immutable record of the raw data.

## 🏗️ Architecture Principles
- **Immutability:** Data is loaded exactly as it appears in the source CSV files.
- **Full Refresh:** Every ingestion cycle performs a `TRUNCATE-and-INSERT` to ensure the landing zone reflects the latest available data export.

## ⚙️ Ingestion Orchestration (`sp_load_bronze`)

The ingestion process is managed by a centralized PL/pgSQL stored procedure that automates the data flow from the filesystem to the database.

### **Core Actions Performed**
* **Automated Cleanup:** Iteratively truncates target tables to prevent data duplication and maintain a clean state.
* **Bulk Copy Operations:** Utilizes the high-performance PostgreSQL `COPY` command for rapid data ingestion from CSV files.
* **Performance Instrumentation:** Captures and logs the start/end times for each table load to monitor performance.
* **Record Auditing:** Uses `GET DIAGNOSTICS` to track the exact number of rows processed per batch for audit trails.
* **Robust Error Handling:** A dedicated `EXCEPTION` block captures `SQLSTATE` and `SQLERRM`, ensuring that ingestion failures are logged with technical precision.

### **Ingestion Configuration**
- **Source Format:** CSV (Comma Separated Values)
- **Encoding:** UTF-8
- **Data Source Path:** `/Users/Shared/postgres_data/transfermarkt/`
- **Volume:** Handles datasets ranging from small lookup tables (Competitions) to high-volume fact logs (2.6M+ Appearance records).

## 🚦 How to run
To trigger the ingestion of raw data into the Bronze schema, execute the following command:

```sql
CALL bronze.sp_load_bronze();
