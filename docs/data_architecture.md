```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ffffff', 'primaryTextColor': '#2c3e50', 'lineColor': '#7f8c8d', 'fontSize': '15px', 'fontFamily': 'Inter, sans-serif', 'clusterBkg': '#f8f9fa', 'clusterBorder': '#bdc3c7'}}}%%

graph TD
    %% --- EXTERNAL SOURCES ---
    subgraph SOURCES [&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;📄 EXTERNAL SOURCES &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;]
        CSV[📄 CSV Files<br/>Transfermarkt]
        API[🌐 External<br/>APIs]
    end

    %% --- MAIN DWH CORE ---
    subgraph DWH [&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;🏗️ DATA WAREHOUSE CORE (PostgreSQL) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;]
        
        subgraph BRONZE [🟫 BRONZE LAYER]
            B_T[Physical Tables]
            B_L[Truncate & Load]
            B_M[Raw Landing]
        end

        subgraph SILVER [⬜ SILVER LAYER]
            S_T[Physical Tables]
            S_L[Incremental Load]
            S_P[Clean & Cast]
        end

        subgraph GOLD [🟨 GOLD LAYER]
            G_T[Fact & Dim Tables]
            G_L[Business Logic]
            G_M[Star Schema]
        end
        
        subgraph OPS [⚙️ PIPELINE OPS]
            O_P[Stored Procs]
            O_Q[SQL Tests]
            O_L[Audit Logs]
        end

        %% Internal Data Flow
        B_M --> S_P
        S_P --> G_L
    end

    %% --- CONSUMPTION LAYER ---
    subgraph CONSUME [&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;📊 DATA CONSUMPTION &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;]
        BI[📊 BI & Reports]
        SQL_C[🔍 Ad-hoc SQL]
        ML[🧠 ML Models]
    end

    %% --- GLOBAL CONNECTIONS ---
    SOURCES --> BRONZE
    GOLD --> CONSUME

    %% --- STYLING ---
    style BRONZE fill:#E9E0D6,stroke:#8A7E72,stroke-width:2px
    style SILVER fill:#f1f2f6,stroke:#ced4da,stroke-width:2px
    style GOLD fill:#FFF9E5,stroke:#F1C40F,stroke-width:2px
    style OPS fill:#e8f4fd,stroke:#3498db,stroke-width:2px
    style DWH fill:#ffffff,stroke:#333,stroke-width:1px
