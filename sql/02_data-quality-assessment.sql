-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- SQL Data Quality Assessment
-- ============================================================
--
-- Purpose:
-- Assess the completeness, consistency and integrity of product
-- master data and inventory records in the ERP database.
--
-- Database: Poseasy / MrCloud
-- Engine: MySQL
-- ============================================================


-- ============================================================
-- 1. PRODUCT MASTER DATA
-- ============================================================


-- ------------------------------------------------------------
-- 1.1 Active products without barcode
-- ------------------------------------------------------------
--
-- A product is considered to have a valid barcode when at least
-- one active product-price record contains a non-empty barcode.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS ProductsWithoutBarcode
FROM siproducto p
WHERE p.SiProductoActivo = 1
  AND NOT EXISTS (
      SELECT 1
      FROM siproductoprecio pp
      WHERE pp.idSiProducto = p.idSiProducto
        AND NULLIF(TRIM(pp.SiProductoCodigoBarra), '') IS NOT NULL
  );


-- ------------------------------------------------------------
-- 1.2 Active products without sales price
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS ProductsWithoutSalesPrice
FROM siproducto p
WHERE p.SiProductoActivo = 1
  AND NOT EXISTS (
      SELECT 1
      FROM siproductoprecio pp
      WHERE pp.idSiProducto = p.idSiProducto
        AND pp.SiProductoPrecioVenta > 0
  );


-- ------------------------------------------------------------
-- 1.3 Active products without recorded cost
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS ProductsWithoutCost
FROM siproducto p
WHERE p.SiProductoActivo = 1
  AND NOT EXISTS (
      SELECT 1
      FROM siproductoprecio pp
      WHERE pp.idSiProducto = p.idSiProducto
        AND pp.SiProductoPrecioCosto > 0
  );


-- ------------------------------------------------------------
-- 1.4 Active products without category
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS ProductsWithoutCategory
FROM siproducto p
WHERE p.SiProductoActivo = 1
  AND (p.idSiCategoria IS NULL OR p.idSiCategoria = 0);


-- ------------------------------------------------------------
-- 1.5 Active products without family
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS ProductsWithoutFamily
FROM siproducto p
WHERE p.SiProductoActivo = 1
  AND (p.idSiFamilia IS NULL OR p.idSiFamilia = 0);


-- ============================================================
-- 2. PRICING CONSISTENCY
-- ============================================================


-- ------------------------------------------------------------
-- 2.1 Products where cost is greater than sales price
-- ------------------------------------------------------------
--
-- Products with at least one price record where cost exceeds
-- the corresponding sales price are flagged for review.
-- ------------------------------------------------------------

SELECT
    COUNT(DISTINCT pp.idSiProducto) AS ProductsCostGreaterThanSalesPrice
FROM siproductoprecio pp
WHERE pp.SiProductoPrecioCosto > pp.SiProductoPrecioVenta;


-- ============================================================
-- 3. INVENTORY DATA
-- ============================================================


-- ------------------------------------------------------------
-- 3.1 Active products with negative physical stock
-- ------------------------------------------------------------
--
-- Physical stock is represented by SiProductoBodegaExistencia.
-- Stock is aggregated across warehouse locations before evaluating
-- whether the product has a negative total balance.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS ProductsWithNegativeStock
FROM (
    SELECT
        pb.idSiProducto,
        SUM(pb.SiProductoBodegaExistencia) AS PhysicalStock
    FROM siproductobodega pb
    INNER JOIN siproducto p
        ON p.idSiProducto = pb.idSiProducto
    WHERE p.SiProductoActivo = 1
    GROUP BY pb.idSiProducto
    HAVING SUM(pb.SiProductoBodegaExistencia) < 0
) AS NegativeStock;


-- ------------------------------------------------------------
-- 3.2 Total negative physical stock
-- ------------------------------------------------------------

SELECT
    SUM(NegativeStock.PhysicalStock) AS TotalNegativePhysicalStock
FROM (
    SELECT
        pb.idSiProducto,
        SUM(pb.SiProductoBodegaExistencia) AS PhysicalStock
    FROM siproductobodega pb
    INNER JOIN siproducto p
        ON p.idSiProducto = pb.idSiProducto
    WHERE p.SiProductoActivo = 1
    GROUP BY pb.idSiProducto
    HAVING SUM(pb.SiProductoBodegaExistencia) < 0
) AS NegativeStock;


-- ============================================================
-- 4. ORPHAN INVENTORY RECORDS
-- ============================================================


-- ------------------------------------------------------------
-- 4.1 Inventory records without a matching product master
-- ------------------------------------------------------------

SELECT
    COUNT(DISTINCT pb.idSiProducto) AS OrphanInventoryProducts
FROM siproductobodega pb
LEFT JOIN siproducto p
    ON p.idSiProducto = pb.idSiProducto
WHERE p.idSiProducto IS NULL;


-- ------------------------------------------------------------
-- 4.2 Physical stock associated with orphan inventory records
-- ------------------------------------------------------------

SELECT
    SUM(pb.SiProductoBodegaExistencia) AS OrphanPhysicalStock
FROM siproductobodega pb
LEFT JOIN siproducto p
    ON p.idSiProducto = pb.idSiProducto
WHERE p.idSiProducto IS NULL;


-- ------------------------------------------------------------
-- 4.3 Detail of orphan inventory records
-- ------------------------------------------------------------

SELECT
    pb.idSiProducto,
    SUM(pb.SiProductoBodegaExistencia) AS PhysicalStock
FROM siproductobodega pb
LEFT JOIN siproducto p
    ON p.idSiProducto = pb.idSiProducto
WHERE p.idSiProducto IS NULL
GROUP BY pb.idSiProducto
ORDER BY PhysicalStock ASC;


-- ============================================================
-- 5. WAREHOUSE MASTER DATA
-- ============================================================


-- ------------------------------------------------------------
-- 5.1 Active and inactive warehouses
-- ------------------------------------------------------------

SELECT
    idSiBodega AS WarehouseID,
    SiBodegaDenominacion AS WarehouseName,
    SiBodegaActivo AS IsActive
FROM sibodega
ORDER BY SiBodegaActivo DESC, SiBodegaDenominacion;


-- ------------------------------------------------------------
-- 5.2 Inventory by warehouse
-- ------------------------------------------------------------

SELECT
    b.idSiBodega AS WarehouseID,
    b.SiBodegaDenominacion AS WarehouseName,
    b.SiBodegaActivo AS IsActive,
    COUNT(pb.idSiProducto) AS ProductRecords,
    SUM(pb.SiProductoBodegaExistencia) AS PhysicalStock
FROM sibodega b
LEFT JOIN siproductobodega pb
    ON pb.idSiBodega = b.idSiBodega
GROUP BY
    b.idSiBodega,
    b.SiBodegaDenominacion,
    b.SiBodegaActivo
ORDER BY PhysicalStock DESC;


-- ============================================================
-- 6. PRODUCTS WITH STOCK BUT NO SALES
-- ============================================================
--
-- Identifies active products with positive physical stock that
-- have no associated sales documents during the analyzed period.
--
-- Regular sales documents:
-- 33 = Factura Electrónica
-- 35 = Nota de Venta
-- 39 = Boleta Electrónica
--
-- Credit and debit notes are excluded from the initial sales
-- activity check.
-- ============================================================

SELECT
    COUNT(*) AS ProductsWithStockButNoSales
FROM (
    SELECT
        p.idSiProducto
    FROM siproducto p

    INNER JOIN (
        SELECT
            pb.idSiProducto,
            SUM(pb.SiProductoBodegaExistencia) AS PhysicalStock
        FROM siproductobodega pb
        GROUP BY pb.idSiProducto
        HAVING SUM(pb.SiProductoBodegaExistencia) > 0
    ) stock
        ON stock.idSiProducto = p.idSiProducto

    LEFT JOIN (
        SELECT DISTINCT
            vd.idSiProducto
        FROM vedocumentodetalle vd
        INNER JOIN vedocumentogeneral vg
            ON vg.idVeDocumentoGeneral = vd.idVeDocumentoGeneral
        WHERE vg.SiDocumentoCodigoSII IN (33, 35, 39)
    ) sales
        ON sales.idSiProducto = p.idSiProducto

    WHERE p.SiProductoActivo = 1
      AND sales.idSiProducto IS NULL
) AS ProductsWithoutSales;


-- ------------------------------------------------------------
-- 6.1 Detail of products with stock but no sales
-- ------------------------------------------------------------

SELECT
    p.idSiProducto,
    p.SiProductoDenominacion,
    stock.PhysicalStock
FROM siproducto p

INNER JOIN (
    SELECT
        pb.idSiProducto,
        SUM(pb.SiProductoBodegaExistencia) AS PhysicalStock
    FROM siproductobodega pb
    GROUP BY pb.idSiProducto
    HAVING SUM(pb.SiProductoBodegaExistencia) > 0
) stock
    ON stock.idSiProducto = p.idSiProducto

LEFT JOIN (
    SELECT DISTINCT
        vd.idSiProducto
    FROM vedocumentodetalle vd
    INNER JOIN vedocumentogeneral vg
        ON vg.idVeDocumentoGeneral = vd.idVeDocumentoGeneral
    WHERE vg.SiDocumentoCodigoSII IN (33, 35, 39)
) sales
    ON sales.idSiProducto = p.idSiProducto

WHERE p.SiProductoActivo = 1
  AND sales.idSiProducto IS NULL

ORDER BY stock.PhysicalStock DESC;


-- ============================================================
-- 7. DATA QUALITY SUMMARY
-- ============================================================
--
-- The individual queries above provide the detailed checks used
-- during the assessment. The results are summarized below for
-- documentation and reporting purposes.
-- ============================================================

SELECT
    'Products without barcode' AS DataQualityMetric,
    COUNT(*) AS Result
FROM siproducto p
WHERE p.SiProductoActivo = 1
  AND NOT EXISTS (
      SELECT 1
      FROM siproductoprecio pp
      WHERE pp.idSiProducto = p.idSiProducto
        AND NULLIF(TRIM(pp.SiProductoCodigoBarra), '') IS NOT NULL
  )

UNION ALL

SELECT
    'Products without sales price',
    COUNT(*)
FROM siproducto p
WHERE p.SiProductoActivo = 1
  AND NOT EXISTS (
      SELECT 1
      FROM siproductoprecio pp
      WHERE pp.idSiProducto = p.idSiProducto
        AND pp.SiProductoPrecioVenta > 0
  )

UNION ALL

SELECT
    'Products without cost',
    COUNT(*)
FROM siproducto p
WHERE p.SiProductoActivo = 1
  AND NOT EXISTS (
      SELECT 1
      FROM siproductoprecio pp
      WHERE pp.idSiProducto = p.idSiProducto
        AND pp.SiProductoPrecioCosto > 0
  )

UNION ALL

SELECT
    'Products without category',
    COUNT(*)
FROM siproducto p
WHERE p.SiProductoActivo = 1
  AND (p.idSiCategoria IS NULL OR p.idSiCategoria = 0)

UNION ALL

SELECT
    'Products without family',
    COUNT(*)
FROM siproducto p
WHERE p.SiProductoActivo = 1
  AND (p.idSiFamilia IS NULL OR p.idSiFamilia = 0);


-- ============================================================
-- NOTES
-- ============================================================
--
-- Key findings identified during the assessment:
--
-- 1. Missing product identification and pricing information.
--
-- 2. Negative physical stock balances across active products.
--
-- 3. Orphan inventory records without a matching product master.
--
-- 4. Historical and inactive warehouse records requiring
--    consideration when analyzing current operational data.
--
-- 5. Products holding positive inventory without recorded sales
--    activity require further review.
--
-- These findings provide a baseline for future data cleansing,
-- inventory reconciliation and data quality monitoring.
--
-- ============================================================
