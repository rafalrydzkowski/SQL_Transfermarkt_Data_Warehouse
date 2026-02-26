```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ffffff', 'primaryTextColor': '#2c3e50', 'lineColor': '#7f8c8d', 'fontSize': '15px', 'fontFamily': 'Inter, sans-serif', 'clusterBkg': '#f8f9fa', 'clusterBorder': '#bdc3c7'}}}%%

graph TD
    %% --- EXTERNAL SOURCES ---
    subgraph SOURCES
        CSV[📄 CSV Files - Transfermarkt]
        API[🌐 External APIs]
    end

    %% --- MAIN DWH CORE ---
    subgraph DWH
        subgraph BRONZE
            B_T[Physical Tables]
            B_L[Truncate and Load]
            B_M[Raw Data]
        end

        subgraph SILVER
            S_T[Physical Tables]
            S_L[Incremental Load]
            S_P[Cleaning and Casting]
        end

        subgraph GOLD
            G_T[Fact and Dim Tables]
            G_L[Business Logic]
            G_M[Star Schema]
        end
        
        subgraph OPERATIONS
            O_P[Stored Procedures]
            O_Q[SQL Constraints]
            O_L[Audit Logging]
        end

        %% Internal Data Flow
        B_M --> S_P
        S_P --> G_L
    end

    %% --- CONSUMPTION LAYER ---
    subgraph CONSUMPTION
        BI[📊 BI and Reporting]
        SQL_C[🔍 Ad-hoc Queries]
        ML[🧠 Machine Learning]
    end

    %% --- GLOBAL CONNECTIONS ---
    SOURCES --> BRONZE
    GOLD --> CONSUMPTION

    %% --- STYLING ---
    style BRONZE fill:#E9E0D6,stroke:#8A7E72,stroke-width:2px
    style SILVER fill:#f1f2f6,stroke:#ced4da,stroke-width:2px
    style GOLD fill:#FFF9E5,stroke:#F1C40F,stroke-width:2px
    style OPERATIONS fill:#e8f4fd,stroke:#3498db,stroke-width:2px
    style DWH fill:#ffffff,stroke:#333,stroke-width:1px
