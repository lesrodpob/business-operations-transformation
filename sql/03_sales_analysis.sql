-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- Sales Analysis
-- ============================================================
-- Purpose:
-- Sales exploration, validation and preparation of the sales
-- detail view that will later feed Power BI.
--
-- Database: Poseasy / MrCloud
-- Engine: MySQL
--
-- Important:
-- Historical cost data contains inconsistent values in some
-- periods. CostoERP is therefore kept as an informative field
-- in the final view and should not yet be used as a definitive
-- profitability measure.
-- ============================================================


-- ============================================================
-- 1. SALES DOCUMENT SUMMARY
-- ============================================================

SELECT
    g.SiDocumentoCodigoSII AS TipoDocumento,
    COUNT(*) AS TotalDocumentos,
    MIN(g.VeDocumentoGeneralFecEmision) AS FechaMinima,
    MAX(g.VeDocumentoGeneralFecEmision) AS FechaMaxima,
    SUM(g.VeDocumentoGeneralMontoTotal) AS MontoTotal
FROM vedocumentogeneral g
WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)
GROUP BY g.SiDocumentoCodigoSII
ORDER BY g.SiDocumentoCodigoSII;


-- ============================================================
-- 2. SALES BY YEAR
-- ============================================================

SELECT
    YEAR(g.VeDocumentoGeneralFecEmision) AS Año,
    COUNT(*) AS Documentos,
    SUM(g.VeDocumentoGeneralMontoTotal) AS Ventas
FROM vedocumentogeneral g
WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)
  AND g.VeDocumentoGeneralFecEmision <= CURDATE()
GROUP BY YEAR(g.VeDocumentoGeneralFecEmision)
ORDER BY Año;


-- ============================================================
-- 3. SALES BY MONTH
-- ============================================================

SELECT
    YEAR(g.VeDocumentoGeneralFecEmision) AS Año,
    MONTH(g.VeDocumentoGeneralFecEmision) AS Mes,
    COUNT(*) AS Documentos,
    SUM(g.VeDocumentoGeneralMontoTotal) AS Ventas
FROM vedocumentogeneral g
WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)
  AND g.VeDocumentoGeneralFecEmision <= CURDATE()
GROUP BY
    YEAR(g.VeDocumentoGeneralFecEmision),
    MONTH(g.VeDocumentoGeneralFecEmision)
ORDER BY
    Año,
    Mes;


-- ============================================================
-- 4. SALES BY PRODUCT
-- ============================================================
-- Initial product-level analysis.
-- Used to validate quantity, sales and ERP cost fields.

SELECT
    d.idSiProducto,
    d.VeDocumentoDetalleDenominacion,

    SUM(d.VeDocumentoDetalleCantidad) AS UnidadesVendidas,

    SUM(d.VeDocumentoDetalleTotal) AS Ventas,

    SUM(d.VeDocumentoDetalleCosto) AS Costo,

    SUM(d.VeDocumentoDetalleTotal)
        - SUM(d.VeDocumentoDetalleCosto) AS Utilidad

FROM vedocumentogeneral g

INNER JOIN vedocumentodetalle d
    ON g.idVeDocumentoGeneral = d.idVeDocumentoGeneral

WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)
  AND g.VeDocumentoGeneralFecEmision <= CURDATE()

GROUP BY
    d.idSiProducto,
    d.VeDocumentoDetalleDenominacion

ORDER BY Ventas DESC;


-- ============================================================
-- 5. COST VALIDATION
-- ============================================================
-- IMPORTANT:
-- VeDocumentoDetalleCosto appears to behave as a total line
-- cost in the validated product example. Therefore DO NOT
-- multiply it again by quantity.
--
-- Example of the corrected calculation:
--
--     Costo = SUM(VeDocumentoDetalleCosto)
--     Utilidad = SUM(VeDocumentoDetalleTotal)
--                - SUM(VeDocumentoDetalleCosto)
--
-- This replaced the previous incorrect calculation:
--
--     SUM(Cantidad * Costo)
--
-- Historical validation showed that some periods contain
-- inconsistent ERP cost values, so profitability is not yet
-- considered a definitive KPI.


SELECT
    d.idSiProducto,
    d.VeDocumentoDetalleDenominacion,

    SUM(d.VeDocumentoDetalleCantidad) AS UnidadesVendidas,

    SUM(d.VeDocumentoDetalleTotal) AS Ventas,

    SUM(d.VeDocumentoDetalleCosto) AS Costo,

    SUM(d.VeDocumentoDetalleTotal)
        - SUM(d.VeDocumentoDetalleCosto) AS Utilidad

FROM vedocumentogeneral g

INNER JOIN vedocumentodetalle d
    ON g.idVeDocumentoGeneral = d.idVeDocumentoGeneral

WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)

GROUP BY
    d.idSiProducto,
    d.VeDocumentoDetalleDenominacion

ORDER BY Ventas DESC;


-- ============================================================
-- 6. COST DISTRIBUTION FOR A PRODUCT
-- ============================================================
-- Used to investigate the cost behavior of product 1717.

SELECT
    d.VeDocumentoDetalleCosto AS Costo,
    COUNT(*) AS Registros,
    SUM(d.VeDocumentoDetalleCantidad) AS Unidades
FROM vedocumentogeneral g
INNER JOIN vedocumentodetalle d
    ON g.idVeDocumentoGeneral = d.idVeDocumentoGeneral
WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)
  AND d.idSiProducto = 1717
GROUP BY d.VeDocumentoDetalleCosto
ORDER BY d.VeDocumentoDetalleCosto;


-- ============================================================
-- 7. SALES / COST / PROFIT BY MONTH
-- ============================================================

SELECT
    YEAR(g.VeDocumentoGeneralFecEmision) AS Año,
    MONTH(g.VeDocumentoGeneralFecEmision) AS Mes,

    SUM(d.VeDocumentoDetalleCantidad) AS UnidadesVendidas,

    SUM(d.VeDocumentoDetalleTotal) AS Ventas,

    SUM(d.VeDocumentoDetalleCosto) AS Costo,

    SUM(d.VeDocumentoDetalleTotal)
        - SUM(d.VeDocumentoDetalleCosto) AS Utilidad

FROM vedocumentogeneral g

INNER JOIN vedocumentodetalle d
    ON g.idVeDocumentoGeneral = d.idVeDocumentoGeneral

WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)

GROUP BY
    YEAR(g.VeDocumentoGeneralFecEmision),
    MONTH(g.VeDocumentoGeneralFecEmision)

ORDER BY
    Año,
    Mes;


-- ============================================================
-- 8. MONTHLY COST VALIDATION
-- ============================================================
-- Excludes future-dated records from the validation.
-- Used to identify periods with implausible cost values.

SELECT
    YEAR(g.VeDocumentoGeneralFecEmision) AS Año,
    MONTH(g.VeDocumentoGeneralFecEmision) AS Mes,

    SUM(d.VeDocumentoDetalleTotal) AS Ventas,

    SUM(d.VeDocumentoDetalleCosto) AS Costo,

    COUNT(*) AS Lineas

FROM vedocumentogeneral g

INNER JOIN vedocumentodetalle d
    ON g.idVeDocumentoGeneral = d.idVeDocumentoGeneral

WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)
  AND g.VeDocumentoGeneralFecEmision <= CURDATE()

GROUP BY
    YEAR(g.VeDocumentoGeneralFecEmision),
    MONTH(g.VeDocumentoGeneralFecEmision)

ORDER BY
    Año,
    Mes;


-- ============================================================
-- 9. COST PER UNIT COMPARISON
-- ============================================================
-- Comparison used during data-quality investigation:
-- April 2024 vs September 2026.

SELECT
    YEAR(g.VeDocumentoGeneralFecEmision) AS Año,
    MONTH(g.VeDocumentoGeneralFecEmision) AS Mes,

    SUM(d.VeDocumentoDetalleCantidad) AS Unidades,

    SUM(d.VeDocumentoDetalleCosto) AS Costo,

    SUM(d.VeDocumentoDetalleCosto) /
    NULLIF(SUM(d.VeDocumentoDetalleCantidad), 0)
        AS CostoPromedioPorUnidad

FROM vedocumentogeneral g

INNER JOIN vedocumentodetalle d
    ON g.idVeDocumentoGeneral = d.idVeDocumentoGeneral

WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)
  AND (
        (
            YEAR(g.VeDocumentoGeneralFecEmision) = 2024
            AND MONTH(g.VeDocumentoGeneralFecEmision) = 4
        )
        OR
        (
            YEAR(g.VeDocumentoGeneralFecEmision) = 2026
            AND MONTH(g.VeDocumentoGeneralFecEmision) = 9
        )
      )

GROUP BY
    YEAR(g.VeDocumentoGeneralFecEmision),
    MONTH(g.VeDocumentoGeneralFecEmision);


-- ============================================================
-- 10. SALES DETAIL VIEW
-- ============================================================
-- Main SQL view to be used as a source for Power BI.
--
-- Sales documents:
-- 33 = Factura Electrónica
-- 35 = Nota de Venta
-- 39 = Boleta Electrónica
--
-- CostoERP is intentionally retained as an informative field.
-- It should not yet be used as the definitive profitability
-- measure until the historical ERP cost issue is resolved.

CREATE OR REPLACE VIEW vw_sales_detail AS

SELECT
    g.idVeDocumentoGeneral,
    g.VeDocumentoGeneralFecEmision AS Fecha,
    g.SiDocumentoCodigoSII AS TipoDocumento,
    g.VeDocumentoGeneralFolio AS Folio,

    g.idSiClienteRut AS Cliente,
    g.idSiBodega AS Bodega,
    g.idSiVendedor AS Vendedor,

    d.idSiProducto,
    d.VeDocumentoDetalleDenominacion AS Producto,

    d.VeDocumentoDetalleCantidad AS Cantidad,
    d.VeDocumentoDetallePrecio AS PrecioVenta,
    d.VeDocumentoDetalleTotal AS VentaTotal,
    d.VeDocumentoDetalleCosto AS CostoERP,

    d.VeDocumentoDetalleDescto1 AS Descuento1,
    d.VeDocumentoDetalleDescto2 AS Descuento2

FROM vedocumentogeneral g

INNER JOIN vedocumentodetalle d
    ON g.idVeDocumentoGeneral = d.idVeDocumentoGeneral

WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)
  AND g.VeDocumentoGeneralFecEmision <= CURDATE();


-- ============================================================
-- 11. VIEW VALIDATION
-- ============================================================

SELECT *
FROM vw_sales_detail
LIMIT 20;
