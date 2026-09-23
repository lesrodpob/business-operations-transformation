-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- Inventory Analysis
-- ============================================================
-- Purpose:
-- Prepare the current inventory data from the ERP for Power BI.
--
-- Business context:
-- - Matriz is the main warehouse/reference point for inventory.
-- - Other warehouses are kept to identify where products are located.
-- - Inventory values are preserved as recorded by the ERP.
-- - Negative existence values are NOT removed or corrected.
--   They may be related to the current management of units,
--   displays and boxes in the ERP.
--
-- Database: Poseasy / MrCloud
-- Engine: MySQL
-- ============================================================


-- ============================================================
-- 1. INVENTORY TABLE STRUCTURE
-- ============================================================

DESCRIBE siproductobodega;


-- ============================================================
-- 2. INVENTORY OVERVIEW
-- ============================================================
-- Initial validation performed during analysis:
-- Records: 5,413
-- Products: 3,664
-- Warehouses: 19
--
-- Negative values found:
-- Stock field (SiProductoBodegaStock): 0 negative records
-- Existence field (SiProductoBodegaExistencia): 654 negative records
--
-- Business interpretation:
-- SiProductoBodegaExistencia is the field identified as the
-- current stock/existence value used by the business.
-- Negative values are preserved because they may be related
-- to displays/boxes and should not be treated as data errors
-- without further validation.


SELECT
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT idSiProducto) AS Products,
    COUNT(DISTINCT idSiBodega) AS Warehouses,

    SUM(
        CASE
            WHEN SiProductoBodegaStock < 0
            THEN 1
            ELSE 0
        END
    ) AS NegativeStockRecords,

    SUM(
        CASE
            WHEN SiProductoBodegaExistencia < 0
            THEN 1
            ELSE 0
        END
    ) AS NegativeExistenceRecords

FROM siproductobodega;


-- ============================================================
-- 3. INVENTORY VIEW
-- ============================================================
-- StockActual represents the current existence/stock value
-- identified for the business.
--
-- StockSistema is retained for comparison and future analysis.
--
-- BodegaID is retained because warehouse-level inventory is
-- useful for identifying where products are located.
--
-- Negative StockActual values are preserved.


CREATE OR REPLACE VIEW vw_inventory AS

SELECT
    idSiProducto AS ProductoID,
    idSiBodega AS BodegaID,

    SiProductoBodegaExistencia AS StockActual,
    SiProductoBodegaStock AS StockSistema,

    SiProductoBodegaActualizado AS Actualizado,
    SiProductoBodegaCatalogo AS Catalogo

FROM siproductobodega;


-- ============================================================
-- 4. VIEW VALIDATION
-- ============================================================

SELECT *
FROM vw_inventory
LIMIT 30;


-- ============================================================
-- 5. FUTURE INVENTORY ANALYSIS
-- ============================================================
-- Future analysis can include:
--
-- - Total stock by product
-- - Stock in Matriz
-- - Stock by warehouse
-- - Products with negative stock
-- - Products with zero stock
-- - Stock coverage
-- - Inventory value
-- - Stock rotation
-- - Replenishment needs
--
-- Important:
-- Unit / display / box conversions are not implemented yet.
-- They should be incorporated after the ERP configuration and
-- product-unit relationships are confirmed.
-- ============================================================
