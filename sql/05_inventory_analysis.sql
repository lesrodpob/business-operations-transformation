-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- Inventory Analysis
-- ============================================================
-- Purpose:
-- Analyze current inventory by product and warehouse,
-- identify the main warehouse (MATRIZ), and preserve
-- physical warehouse locations for inventory analysis.
-- Database: Poseasy / MrCloud
-- Engine: MySQL


-- 1. INVENTORY TABLE STRUCTURE

DESCRIBE siproductobodega;
DESCRIBE sibodega;


-- 2. INVENTORY OVERVIEW VALIDATION

SELECT
    COUNT(*) AS Registros,
    COUNT(DISTINCT idSiProducto) AS Productos,
    COUNT(DISTINCT idSiBodega) AS Bodegas
FROM siproductobodega;


-- 3. INVENTORY STOCK VALIDATION

SELECT
    COUNT(*) AS Registros,
    SUM(CASE WHEN SiProductoBodegaStock < 0 THEN 1 ELSE 0 END) AS StockSistemaNegativo,
    SUM(CASE WHEN SiProductoBodegaExistencia < 0 THEN 1 ELSE 0 END) AS ExistenciaNegativa
FROM siproductobodega;


-- 4. WAREHOUSE STRUCTURE

SELECT
    idSiBodega,
    SiBodegaDenominacion
FROM sibodega
ORDER BY idSiBodega;


-- 5. CREATE INVENTORY VIEW

CREATE OR REPLACE VIEW vw_inventory AS
SELECT
    p.idSiProducto AS ProductoID,
    p.SiProductoDenominacion AS Producto,
    pb.idSiBodega AS BodegaID,
    b.SiBodegaDenominacion AS Bodega,
    pb.SiProductoBodegaExistencia AS StockActual,
    pb.SiProductoBodegaStock AS StockSistema,
    pb.SiProductoBodegaActualizado AS Actualizado,
    pb.SiProductoBodegaCatalogo AS Catalogo,

    CASE
        WHEN pb.idSiBodega = 1 THEN 1
        ELSE 0
    END AS EsMatriz

FROM siproductobodega pb

LEFT JOIN siproducto p
    ON pb.idSiProducto = p.idSiProducto

LEFT JOIN sibodega b
    ON pb.idSiBodega = b.idSiBodega;


-- 6. VALIDATE INVENTORY VIEW

SELECT *
FROM vw_inventory
LIMIT 20;


-- 7. INVENTORY BY WAREHOUSE

SELECT
    BodegaID,
    Bodega,
    COUNT(*) AS Registros,
    COUNT(DISTINCT ProductoID) AS Productos
FROM vw_inventory
GROUP BY BodegaID, Bodega
ORDER BY BodegaID;


-- 8. INVENTORY IN MATRIZ

SELECT
    ProductoID,
    Producto,
    StockActual
FROM vw_inventory
WHERE EsMatriz = 1
ORDER BY ProductoID;


-- NOTES
-- 1. SiProductoBodegaExistencia is treated as the current physical stock.
-- 2. SiProductoBodegaStock is kept as a separate ERP stock field.
-- 3. Negative StockActual values are not automatically treated as errors,
--    because the business may use different units such as displays or boxes.
-- 4. MATRIZ (BodegaID = 1) is the main warehouse/reference point.
-- 5. Other active warehouses are retained to identify the physical
--    location of products.
-- 6. The old MERMA warehouse (BodegaID = 15) is not considered,
--    because the ERP now has a dedicated waste/merma module.
-- 7. Product unit/display/box conversion logic will be analyzed separately.
