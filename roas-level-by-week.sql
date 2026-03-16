WITH CleanData AS (
    SELECT 
        "ID položky",
        -- Týždeň ako ISO string napr. "2024-W01"
        STRFTIME(DATE_TRUNC('week', TRY_CAST("Den" AS DATE)), '%Y-W%W') AS Tyzden,
        TRY_CAST(REPLACE("Cena", ',', '.') AS DOUBLE) AS Cena_Num,
        TRY_CAST(REPLACE("Hodnota konverze", ',', '.') AS DOUBLE) AS Hodnota_Num,
        TRY_CAST(REPLACE("Konverze", ',', '.') AS DOUBLE) AS Konv_Num
    FROM database.table_name
),
ProductPerWeek AS (
    SELECT 
        "ID položky",
        Tyzden,
        SUM(COALESCE(Cena_Num, 0))    AS Celkova_Cena,
        SUM(COALESCE(Hodnota_Num, 0)) AS Celkova_Hodnota,
        SUM(COALESCE(Konv_Num, 0))    AS Celkove_Konverzie
    FROM CleanData
    GROUP BY "ID položky", Tyzden
),
ProductROAS AS (
    SELECT 
        *,
        CASE 
            WHEN Celkova_Cena > 0 THEN Celkova_Hodnota / Celkova_Cena
            ELSE 0 
        END AS ROAS
    FROM ProductPerWeek
),
Hladiny AS (
    SELECT 
        Tyzden,
        CASE 
            WHEN Celkova_Cena = 0 AND Celkove_Konverzie = 0 THEN '0 - Bez konverzii a cost'
            WHEN Celkova_Hodnota = 0                        THEN '0 - Bez konverzii'
            WHEN ROAS <= 1 THEN '0.01% až 100%'
            WHEN ROAS <= 2 THEN '101% až 200%'
            WHEN ROAS <= 3 THEN '201% až 300%'
            WHEN ROAS <= 4 THEN '301% až 400%'
            WHEN ROAS <= 5 THEN '401% až 500%'
            ELSE '501% a viac'
        END AS Hladina_ROAS,
        "ID položky",
        Celkova_Cena,
        Celkova_Hodnota
    FROM ProductROAS
)
-- Finálny výstup v prehľadnom riadkovom formáte
SELECT
    Tyzden AS "Rok-Tyzden",
    Hladina_ROAS AS "ROAS Hladina",
    COUNT(DISTINCT "ID položky")      AS "Pocet Produktov",
    ROUND(SUM(Celkova_Cena), 2)       AS "Naklady",
    ROUND(SUM(Celkova_Hodnota), 2)    AS "Trzby",
    ROUND(SUM(Celkova_Hodnota) / NULLIF(SUM(Celkova_Cena), 0), 2) AS "ROAS Celkovy"
FROM Hladiny
GROUP BY Tyzden, Hladina_ROAS
ORDER BY Tyzden DESC, Hladina_ROAS ASC;
