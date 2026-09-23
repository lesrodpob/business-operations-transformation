-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- Purchase Analysis
-- ============================================================
-- Purpose:
-- Analyze purchase transactions recorded in the ERP,
-- including purchase dates, products, suppliers, quantities,
-- purchase costs and purchase totals.
-- Database: Poseasy / MrCloud
-- Engine: MySQL
--
-- Important data-quality context:
-- Purchase transactions in the ERP begin in June 2026.
-- Before that period, purchases were not consistently entered
-- into the ERP, so this dataset should not be interpreted as
-- a complete historical purchase record.


-- 1. PURCHASE TABLE STRUCTURE

DESCRIBE cocomprobantegeneral;
DESCRIBE cocomprobantedetalle;


-- 2. PURCHASE HISTORY OVERVIEW

SELECT
    COUNT(*) AS Registros,
    COUNT(DISTINCT d.idSiProducto) AS Productos,
    COUNT(DISTINCT g.idSiProveedorRut) AS Proveedores,
    MIN(g.CoComprobanteGeneralDocFecha) AS PrimeraCompra,
    MAX(g.CoComprobanteGeneralDocFecha) AS UltimaCompra
FROM cocomprobantedetalle d
INNER JOIN cocomprobantegeneral g
    ON d.idCoComprobanteGeneral = g.idCoComprobanteGeneral;


-- 3. PURCHASES BY MONTH

SELECT
    YEAR(g.CoComprobanteGeneralDocFecha) AS Año,
    MONTH(g.CoComprobanteGeneralDocFecha) AS Mes,
    COUNT(DISTINCT g.idCoComprobanteGeneral) AS Documentos,
    SUM(d.CoComprobanteDetalleCantidad) AS UnidadesCompradas,
    SUM(d.CoComprobanteDetalleTotal) AS TotalCompras
FROM cocomprobantegeneral g
INNER JOIN cocomprobantedetalle d
    ON g.idCoComprobanteGeneral = d.idCoComprobanteGeneral
GROUP BY
    YEAR(g.CoComprobanteGeneralDocFecha),
    MONTH(g.CoComprobanteGeneralDocFecha)
ORDER BY
    Año,
    Mes;


-- 4. PURCHASE UNIT VALIDATION

SELECT
    d.CoComprobanteDetalleUnidad AS UnidadCompra,
    COUNT(*) AS Registros,
    SUM(
        CASE
            WHEN d.CoComprobanteDetalleCantidadEmp IS NULL
                 OR d.CoComprobanteDetalleCantidadEmp = 0
            THEN 1
            ELSE 0
        END
    ) AS RegistrosSinEmpaque
FROM cocomprobantedetalle d
GROUP BY d.CoComprobanteDetalleUnidad
ORDER BY Registros DESC;


-- 5. PURCHASE COST VALIDATION
-- CoComprobanteDetalleCosto is treated as the unit purchase cost
-- based on line-level validation against quantity and total.

SELECT
    d.idSiProducto AS ProductoID,
    d.SiProductoDenominacion AS Producto,
    d.CoComprobanteDetalleCantidad AS CantidadComprada,
    d.CoComprobanteDetalleCosto AS CostoCompra,
    d.CoComprobanteDetalleTotal AS TotalCompra,
    ROUND(
        d.CoComprobanteDetalleCantidad *
        d.CoComprobanteDetalleCosto,
        2
    ) AS TotalCalculado
FROM cocomprobantedetalle d
WHERE d.CoComprobanteDetalleCantidad > 0
  AND d.CoComprobanteDetalleCosto IS NOT NULL
LIMIT 100;


-- 6. CREATE PURCHASE HISTORY VIEW

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


-- 7. VALIDATE PURCHASE HISTORY VIEW

SELECT *
FROM vw_purchase_history
ORDER BY FechaCompra DESC
LIMIT 20;


-- 8. PRODUCTS WITH MULTIPLE SUPPLIERS

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
HAVING COUNT(DISTINCT ProveedorID) > 1
ORDER BY UltimaCompra DESC;


-- 9. CREATE LAST PURCHASE VIEW
-- Keeps the most recent purchase transaction for each product.

CREATE OR REPLACE VIEW vw_last_purchase AS
SELECT
    ProductoID,
    Producto,
    FechaCompra,
    ProveedorID,
    BodegaID,
    CantidadComprada,
    UnidadCompra,
    PrecioCompra,
    CostoCompra,
    TotalCompra
FROM (
    SELECT
        h.*,
        ROW_NUMBER() OVER (
            PARTITION BY ProductoID
            ORDER BY FechaCompra DESC, idCoComprobanteDetalle DESC
        ) AS rn
    FROM vw_purchase_history h
) x
WHERE rn = 1;


-- 10. VALIDATE LAST PURCHASE VIEW

SELECT *
FROM vw_last_purchase
ORDER BY FechaCompra DESC
LIMIT 20;


-- NOTES
-- 1. Purchase history currently begins in June 2026 because
--    previous purchases were not consistently recorded in the ERP.
-- 2. Purchase records currently use UNID as the purchase unit.
-- 3. CoComprobanteDetalleCantidadEmp is currently zero in the
--    available purchase records and should not yet be used for
--    display/box conversion logic.
-- 4. CoComprobanteDetalleCosto behaves as a unit purchase cost
--    based on line-level validation.
-- 5. A product can have multiple suppliers, so supplier information
--    should be treated as transaction-dependent.
-- 6. vw_last_purchase provides the most recent purchase information
--    available for each product.
-- 7. Unit/display/box conversion logic will be analyzed separately
--    once the ERP configuration is confirmed.
