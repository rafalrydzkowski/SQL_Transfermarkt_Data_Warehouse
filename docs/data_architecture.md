```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ffffff', 'primaryTextColor': '#2c3e50', 'lineColor': '#7f8c8d', 'fontSize': '16px', 'fontFamily': 'Roboto, Inter, sans-serif', 'clusterBkg': '#f8f9fa', 'clusterBorder': '#bdc3c7'}}}%%

graph TD
    %% --- SEKCJA ŹRÓDEŁ ---
    subgraph SOURCES["📄 SOURCES (External)"]
        direction LR
        CSV[📄 CSV Files<br/>Transfermarkt]
        API[🌐 External<br/>APIs]
    end

    %% --- GŁÓWNY BLOK DWH ---
    subgraph DWH["🏗️ DATA WAREHOUSE (PostgreSQL)"]
        direction TD
        
        %% Warstwy Medallion
        subgraph BRONZE["🟫 BRONZE<br/>(Raw Staging)"]
            direction TB
            B_T[Physical Tables]
            B_L[Truncate & Load]
            B_M[Raw Data]
        end

        subgraph SILVER["⬜ SILVER<br/>(Normalized Processing)"]
            direction TB
            S_T[Physical Tables]
            S_L[Incremental Load]
            S_P[Cleaning & Casting]
        end

        subgraph GOLD["🟨 GOLD<br/>(Analytical Reporting)"]
            direction TB
            G_T[Fact & Dim Tables]
            G_L[Business Logic]
            G_M[Star Schema]
        end
        
        %% Warstwa Operacyjna (Orkiestracja)
        subgraph ORCH["⚙️ PIPELINE OPERATIONS"]
            direction TB
            O_P[Orchestration<br/>Stored Procedures]
            O_Q[Data Quality<br/>Constraints & Tests]
            O_L[Audit Logging<br/>dwh_ops]
        end

        %% Połączenia wewnątrz DWH
        B_M --> S_P
        S_P --> G_L
    end

    %% --- SEKCJA KONSUMPCJI ---
    subgraph CONSUME["📊 CONSUMPTION"]
        direction LR
        BI[📊 BI & Reporting]
        SQL_C[🔍 Ad-hoc<br/>Queries]
        ML[🧠 Machine<br/>Learning]
    end

    %% --- GŁÓWNY PRZEPŁYW DANYCH ---
    SOURCES --> BRONZE
    GOLD --> CONSUME

    %% --- STYLOWANIE (Minimalist & Corporate) ---
    classDef minimal fill:#fff,stroke:#fff,stroke-width:0px,color:#2c3e50;
    classDef bronze fill:#E9E0D6,stroke:#8A7E72,stroke-width:2px,color:#2c3e50;
    classDef silver fill:#f1f2f6,stroke:#ced4da,stroke-width:2px,color:#2c3e50;
    classDef gold fill:#FFF9E5,stroke:#F1C40F,stroke-width:2px,color:#2c3e50;
    classDef orch fill:#e8f4fd,stroke:#3498db,stroke-width:2px,color:#2c3e50;

    %% Aplikacja stylów
    class CSV,API,B_T,B_L,B_M,S_T,S_L,S_P,G_T,G_L,G_M,BI,SQL_C,ML,O_P,O_Q,O_L minimal;
    
    class BRONZE bronze;
    class SILVER silver;
    class GOLD gold;
    class ORCH orch;
