```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ffffff', 'primaryTextColor': '#333', 'lineColor': '#cccccc', 'fontSize': '16px', 'fontFamily': 'Inter, sans-serif'}}}%%

graph LR
    %% Horizontal Sections
    subgraph SOURCES["📄 SOURCES (External)"]
        direction TB
        CSV[📄 CSV Files]
        API[🌐 REST API]
        SQL[💾 SQL DBs]
    end

    %% Data Warehouse Central Block
    subgraph DWH["🏗️ DATA WAREHOUSE (PostgreSQL)"]
        direction LR
        
        %% Bronze Layer
        subgraph BRONZE["🟫 BRONZE (RAW STAGING)"]
            direction TB
            BRONZE_T[Type: Raw Tables]
            BRONZE_L[Load: Truncate & Load / Append]
            BRONZE_TR[Process: Schema-on-read]
        end

        %% Silver Layer
        subgraph SILVER["⬜ SILVER (NORMALIZED PROCESSING)"]
            direction TB
            SILVER_T[Type: Base Tables]
            SILVER_L[Load: Incremental Appends]
            SILVER_TR[Process: Cleaning, Casting, Deduplication]
        end

        %% Gold Layer
        subgraph GOLD["🟨 GOLD (ANALYTICAL REPORTING)"]
            direction TB
            GOLD_T[Type: Fact & Dimension Tables]
            GOLD_L[Load: Business Logic / Views]
            GOLD_TR[Model: Star Schema / Data Marts]
        end
        
        %% Orchestration & Monitoring vertical
        subgraph ORCH["⚙️ ORCHESTRATION & MONITORING (e.g., dbt + Airflow)"]
            direction TB
            ORCH_P[Pipeline scheduling]
            ORCH_DQ[Data quality checks]
            ORCH_E[Error handling]
        end

        %% Define internal connections within DWH
        BRONZE --> SILVER
        SILVER --> GOLD
    end

    %% Consumption Section
    subgraph CONSUME["📊 CONSUMPTION"]
        direction TB
        BI[📊 BI & Reporting]
        SQL_C[🔍 Ad-hoc SQL Queries]
        ML[🧠 Machine Learning]
    end

    %% Define global flow connections
    SOURCES --> DWH
    DWH --> CONSUME

    %% Style definitions for the graph (to make it look minimal)
    classDef minimal fill:#fff,stroke:#fff,stroke-width:0px,color:#333;
    classDef dwhLayer fill:#f9f9f9,stroke:#ddd,stroke-width:1px,color:#333;
    classDef bronze fill:#E0D6CC,stroke:#C6B7A6,stroke-width:2px,color:#333;
    classDef silver fill:#f0f0f0,stroke:#ddd,stroke-width:2px,color:#333;
    classDef gold fill:#FFF5E1,stroke:#EEDDBB,stroke-width:2px,color:#333;
    classDef orch fill:#e6f3ff,stroke:#b3d7ff,stroke-width:2px,color:#333;

    %% Apply styles
    class CSV,API,SQL minimal;
    class BRONZE_T,BRONZE_L,BRONZE_TR,SILVER_T,SILVER_L,SILVER_TR,GOLD_T,GOLD_L,GOLD_TR minimal;
    class BI,SQL_C,ML minimal;
    class ORCH_P,ORCH_DQ,ORCH_E minimal;
    
    class BRONZE bronze;
    class SILVER silver;
    class GOLD gold;
    class ORCH orch;
