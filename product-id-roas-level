WITH CleanData AS (
    SELECT 
        "ID položky", 
        TRY_CAST(REPLACE("Cena", ',', '.') AS DOUBLE) AS Cena_Num,
        TRY_CAST(REPLACE("Hodnota konverze", ',', '.') AS DOUBLE) AS Hodnota_Num,
        TRY_CAST(REPLACE("Konverze", ',', '.') AS DOUBLE) AS Konv_Num
    FROM database.table_name
    --WHERE "Kampaň" = 'Campaign-name'
),
ProductPerformance AS (
    SELECT 
        "ID položky", 
        SUM(COALESCE(Cena_Num, 0)) AS Celkova_Cena,
        SUM(COALESCE(Hodnota_Num, 0)) AS Celkova_Hodnota,
        SUM(COALESCE(Konv_Num, 0)) AS Celkove_Konverzie
    FROM CleanData
    GROUP BY "ID položky"
),
ProductROAS AS (
    SELECT 
        *,
        CASE 
            WHEN Celkova_Cena > 0 THEN (Celkova_Hodnota / Celkova_Cena) 
            ELSE 0 
        END AS ROAS
    FROM ProductPerformance
)
-- Finálny výber: Stĺpec 1 sú ID, Stĺpec 2 je Hladina
SELECT 
    "ID položky",
    CASE 
        WHEN Celkova_Cena = 0 AND Celkove_Konverzie = 0 THEN '0 - Bez konverzii a cost'
        WHEN Celkova_Hodnota = 0 THEN '0 - Bez konverzii'
        WHEN ROAS <= 1.00 THEN '0.01% až 100%'
        WHEN ROAS <= 2.00 THEN '101% až 200%'
        WHEN ROAS <= 3.00 THEN '201% až 300%'
        WHEN ROAS <= 4.00 THEN '301% až 400%'
        WHEN ROAS <= 5.00 THEN '401% až 500%'
        ELSE '501% a viac'
    END AS Hladina_ROAS,
    ROUND(ROAS * 100, 2) AS Presny_ROAS_Percenta, -- Pridal som pre kontrolu
    "Celkove_Konverzie"
FROM ProductROAS
-- Ak chcete vrátiť len jednu konkrétnu hladinu, odkomentujte riadok nižšie:
-- WHERE Hladina_ROAS = '0.01% až 100%'
ORDER BY ROAS DESC;
