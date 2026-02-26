```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ffffff', 'primaryTextColor': '#2c3e50', 'lineColor': '#7f8c8d', 'fontSize': '15px', 'fontFamily': 'Inter, sans-serif', 'clusterBkg': '#f8f9fa', 'clusterBorder': '#bdc3c7'}}}%%

graph TD
    %% --- EXTERNAL SOURCES ---
    subgraph SOURCES [📄 SOURCES EXTERNAL]
        direction LR
        CSV[📄 CSV Files<br/>Transfermarkt]
        API[🌐 External<br/>APIs]
    end

    %% --- MAIN DWH CORE ---
    subgraph DWH [🏗️ DATA WAREHOUSE POSTGRESQL]
        direction TD
        
        subgraph BRONZE [🟫 BRONZE - RAW STAGING]
            direction TB
            B_T[Physical Tables]
            B_L[Truncate & Load]
            B_M[Raw Data]
        end

        subgraph SILVER [⬜ SILVER - NORMALIZED]
            direction TB
            S_T[Physical Tables]
            S_L[Incremental Load]
            S_P[Cleaning & Casting]
        end

        subgraph GOLD [🟨 GOLD - ANALYTICAL]
            direction TB
            G_T[Fact & Dim Tables]
            G_L[Business Logic]
            G_M[Star Schema]
        end
        
        subgraph ORCH [⚙️ PIPELINE OPERATIONS]
            direction TB
            O_P[Orchestration<br/>Stored Procedures]
            O_Q[Data Quality<br/>SQL Constraints]
            O_L[Audit Logging<br/>dwh_ops]
        end

        %% Internal Data Flow
        B_M --> S_P
        S_P --> G_L
    end

    %% --- CONSUMPTION LAYER ---
    subgraph CONSUME [📊 CONSUMPTION]
        direction LR
        BI[📊 BI & Reporting]
        SQL_C[🔍 Ad-hoc<br/>Queries]
        ML[🧠 Machine<br/>Learning]
    end

    %% --- GLOBAL CONNECTIONS ---
    SOURCES --> BRONZE
    GOLD --> CONSUME

    %% --- STYLING ---
    classDef minimal fill:#fff,stroke:#fff,stroke-width
