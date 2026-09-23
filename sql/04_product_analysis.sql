-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- Product & Purchase Analysis
-- ============================================================
-- Purpose:
-- Product master preparation and purchase-history analysis.
--
-- Database: Poseasy / MrCloud
-- Engine: MySQL
--
-- Important findings:
-- 1. siproducto contains 3,695 products.
-- 2. SiProductoFechaCompra has no valid dates in the current
--    product master, so it is not used as a reliable last-purchase
--    field.
-- 3. Purchase history is available from cocomprobantegeneral and
--    cocomprobantedetalle.
-- 4. Current purchase records are registered as UNID.
-- 5. CoComprobanteDetalleCantidadEmp is 0 for the current
--    purchase-history records.
-- 6. CoComprobanteDetalleCosto behaves as a unit purchase cost.
--
-- Purchase history currently found:
-- First recorded purchase: 2026-06-03
-- Last recorded purchase:  2026-09-22
-- Records: 2,107
-- Products: 912
-- ============================================================


-- ============================================================
-- 1. PRODUCT MASTER EXPLORATION
-- ============================================================

DESCRIBE siproducto;


-- ============================================================
-- 2. PRODUCT MASTER
-- ============================================================

CREATE OR REPLACE VIEW vw_product_master AS

SELECT
    p.idSiProducto AS ProductoID,
    p.SiProductoDenominacion AS Producto,

    p.idSiCategoria AS CategoriaID,
    p.idSiFamilia AS FamiliaID,
    p.idSiMedida AS MedidaID,

    p.SiProductoActivo AS Activo,
    p.SiProductoValidaStock AS ValidaStock,
    p.SiProductoPesable AS Pesable,

    p.SiProductoUltimoCosto AS UltimoCosto,
    p.SiProductoFechaCompra AS FechaUltimaCompra,
    p.SiProductoCostoVenta AS CostoVenta,

    p.SiProveedorRut AS ProveedorID,

    p.SiProductoEmpaque AS Empaque,

    p.SiProductoCodigoCorto AS CodigoCorto,
    p.idSiProductoProveedor AS CodigoProveedor,

    p.SiProductoKit AS EsKit,
    p.SiProductoPrecioTamano AS TienePrecioPorTamano

FROM siproducto p;


-- ============================================================
-- 3. PRODUCT MASTER VALIDATION
-- ============================================================

SELECT *
FROM vw_product_master
LIMIT 20;


-- ============================================================
-- 4. VALIDATE PRODUCT PURCHASE-DATE FIELD
-- ============================================================
-- MySQL configuration rejects direct comparison with
-- '0000-00-00'. YEAR() is used instead.
--
-- Result found during analysis:
-- Total products: 3,695
-- Without valid purchase date: 3,695
-- With valid purchase date: 0

SELECT
    COUNT(*) AS TotalProductos,

    SUM(
        CASE
            WHEN YEAR(SiProductoFechaCompra) = 0
            THEN 1
            ELSE 0
        END
    ) AS SinFechaCompra,

    SUM(
        CASE
            WHEN YEAR(SiProductoFechaCompra) > 0
            THEN 1
            ELSE 0
        END
    ) AS ConFechaCompra

FROM siproducto;


-- ============================================================
-- 5. PURCHASE HISTORY STRUCTURE
-- ============================================================
-- Purchase header:
-- cocomprobantegeneral
--
-- Purchase detail:
-- cocomprobantedetalle
--
-- The two tables are linked through:
-- idCoComprobanteGeneral


DESCRIBE cocomprobantegeneral;

DESCRIBE cocomprobantedetalle;


-- ============================================================
-- 6. PURCHASE HISTORY VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS Registros,
    COUNT(DISTINCT d.idSiProducto) AS Productos,
    MIN(g.CoComprobanteGeneralDocFecha) AS PrimeraCompra,
    MAX(g.CoComprobanteGeneralDocFecha) AS UltimaCompra

FROM cocomprobantedetalle d

INNER JOIN cocomprobantegeneral g
    ON d.idCoComprobanteGeneral = g.idCoComprobanteGeneral;


-- ============================================================
-- 7. PURCHASE HISTORY VIEW
-- ============================================================
-- This is kept at line level.
-- Do not aggregate it yet because it preserves the complete
-- purchase history and allows later calculations such as:
-- last purchase, purchase frequency, average purchase quantity,
-- cost evolution and supplier analysis.

CREATE OR REPLACE VIEW vw_purchase_history AS

SELECT
    g.idCoComprobanteGeneral,
    g.CoComprobanteGeneralDocFecha AS FechaCompra,
    g.CoComprobanteGeneralDocNumero AS NumeroDocumento,

    g.idSiProveedorRut AS ProveedorID,
    g.idSiBodega AS BodegaID,

    d.idCoComprobanteDetalle,
    d.idSiProducto AS ProductoID,
    d.SiProductoDenominacion AS Producto,

    d.CoComprobanteDetalleCantidad AS CantidadComprada,
    d.CoComprobanteDetalleUnidad AS UnidadCompra,
    d.CoComprobanteDetalleCantidadEmp AS CantidadEmpaque,

    d.CoComprobanteDetallePrecio AS PrecioCompra,
    d.CoComprobanteDetalleDescto AS Descuento,
    d.CoComprobanteDetalleTotal AS TotalCompra,

    d.CoComprobanteDetalleCosto AS CostoCompra,
    d.CoComprobanteDetalleUltCosto AS UltimoCosto,

    d.CodigoProveedor

FROM cocomprobantegeneral g

INNER JOIN cocomprobantedetalle d
    ON g.idCoComprobanteGeneral = d.idCoComprobanteGeneral;


-- ============================================================
-- 8. PURCHASE HISTORY VALIDATION
-- ============================================================

SELECT *
FROM vw_purchase_history
ORDER BY FechaCompra DESC
LIMIT 20;


-- ============================================================
-- 9. PURCHASE UNIT ANALYSIS
-- ============================================================
-- Current purchase history is registered as UNID.

SELECT
    UnidadCompra,
    COUNT(*) AS Registros,
    SUM(CantidadComprada) AS Cantidad
FROM vw_purchase_history
GROUP BY UnidadCompra
ORDER BY Registros DESC;


-- ============================================================
-- 10. PURCHASE PACKAGING ANALYSIS
-- ============================================================
-- Current purchase-history records have no populated packaging
-- quantity in CoComprobanteDetalleCantidadEmp.

SELECT
    CantidadEmpaque,
    COUNT(*) AS Registros,
    SUM(CantidadComprada) AS Cantidad
FROM vw_purchase_history
GROUP BY CantidadEmpaque
ORDER BY CantidadEmpaque;


-- ============================================================
-- 11. PURCHASE COST VALIDATION
-- ============================================================
-- CoComprobanteDetalleCosto behaves as a UNIT purchase cost.
-- Example validation:
--
-- Quantity x CostoCompra ≈ TotalCompra
--
-- Therefore, for future purchase-cost calculations:
-- Total purchase cost = Quantity x CostoCompra
--
-- Do not treat CostoCompra as a line total.

SELECT
    SUM(CantidadComprada) AS UnidadesCompradas,
    SUM(PrecioCompra) AS SumaPrecios,
    SUM(CostoCompra) AS SumaCostos,
    SUM(UltimoCosto) AS SumaUltimosCostos
FROM vw_purchase_history;


-- ============================================================
-- 12. PURCHASE COST SAMPLE VALIDATION
-- ============================================================

SELECT
    FechaCompra,
    ProductoID,
    Producto,
    CantidadComprada,
    UnidadCompra,
    PrecioCompra,
    CostoCompra,
    UltimoCosto,
    TotalCompra
FROM vw_purchase_history
WHERE CantidadComprada > 1
ORDER BY FechaCompra DESC
LIMIT 20;


-- ============================================================
-- 13. SUPPLIER ANALYSIS BY PRODUCT
-- ============================================================
-- A product can have more than one supplier.
-- Therefore, the supplier should not be treated as a single
-- permanent product attribute in the purchase model.

SELECT
    ProductoID,
    Producto,
    COUNT(DISTINCT ProveedorID) AS Proveedores,
    MIN(FechaCompra) AS PrimeraCompra,
    MAX(FechaCompra) AS UltimaCompra

FROM vw_purchase_history

GROUP BY
    ProductoID,
    Producto

ORDER BY UltimaCompra DESC
LIMIT 20;


-- ============================================================
-- 14. NOTES FOR FUTURE PURCHASE DECISION CENTER
-- ============================================================
--
-- Future calculations can combine:
--
-- Sales:
--   vw_sales_detail
--
-- Product master:
--   vw_product_master
--
-- Purchase history:
--   vw_purchase_history
--
-- Inventory:
--   Future inventory view
--
-- Potential metrics:
--   - Last purchase date
--   - Days since last purchase
--   - Last purchase quantity
--   - Last purchase cost
--   - Purchase frequency
--   - Average purchase quantity
--   - Supplier history
--   - Cost evolution
--   - Stock coverage
--   - Suggested purchase quantity
--
-- Unit/display/box conversion is NOT implemented yet because
-- current purchase records are registered as UNID and
-- CoComprobanteDetalleCantidadEmp is currently 0.
-- This should be revisited after the ERP configuration is
-- improved/confirmed with the IT administrator.
-- ============================================================
