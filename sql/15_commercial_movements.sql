-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- SQL - Commercial & Product Movements
-- ============================================================
-- Purpose:
-- Integrate commercial events such as quotations, pre-sales
-- and concessions with the existing physical stock history.
--
-- Business rules:
-- - Physical stock movements come from the ERP stock movement
--   history.
-- - Quotations, pre-sales and concessions are commercial events.
-- - Commercial events do NOT modify physical stock.
-- - Concessions are identified from the note field in mrpreventas.
-- - Customer information is intentionally excluded because
--   the customer field is not reliably populated for these
--   transactions.
--
-- Source tables:
--   mrcotizaciones
--   mrpreventas
--   siproductobodegabitacora
--
-- Existing physical movement view:
--   vw_product_stock_history
--
-- Output views:
--   vw_commercial_movements
--   vw_product_movements
--
-- Database: Poseasy / MrCloud
-- Engine: MySQL
-- ============================================================


-- ============================================================
-- 1. COMMERCIAL MOVEMENTS
-- ============================================================
-- Extract products stored inside items_json from quotations
-- and pre-sales.
--
-- Each item becomes one row.
--
-- Commercial movement types:
--   Cotizacion
--   Preventa
--   Concesion
--
-- Important:
-- Commercial movements are NOT physical stock movements.
-- Therefore MovimientoNeto is not calculated for them.
-- StockAlMomento represents the stock recorded by the
-- commercial application when the document was created.
-- ============================================================

CREATE OR REPLACE VIEW vw_commercial_movements AS

-- ------------------------------------------------------------
-- QUOTATIONS
-- ------------------------------------------------------------

SELECT
    p.id AS DocumentoID,

    'Cotizacion' AS TipoMovimiento,

    p.document_code AS Documento,

    p.created_at AS FechaHora,

    p.note AS Nota,

    CAST(
        JSON_UNQUOTE(
            JSON_EXTRACT(item.value, '$.id')
        ) AS UNSIGNED
    ) AS ProductoID,

    JSON_UNQUOTE(
        JSON_EXTRACT(item.value, '$.name')
    ) AS Producto,

    CAST(
        JSON_UNQUOTE(
            JSON_EXTRACT(item.value, '$.quantity')
        ) AS DECIMAL(12,3)
    ) AS Cantidad,

    CAST(
        JSON_UNQUOTE(
            JSON_EXTRACT(item.value, '$.stock')
        ) AS DECIMAL(12,3)
    ) AS StockAlMomento

FROM mrcotizaciones p

CROSS JOIN JSON_TABLE(
    p.items_json,
    '$[*]' COLUMNS (
        value JSON PATH '$'
    )
) AS item


UNION ALL


-- ------------------------------------------------------------
-- PRE-SALES / CONCESSIONS
-- ------------------------------------------------------------

SELECT
    p.id AS DocumentoID,

    CASE
        WHEN UPPER(TRIM(p.note)) LIKE '%CONCES%'
            THEN 'Concesion'
        ELSE 'Preventa'
    END AS TipoMovimiento,

    p.document_code AS Documento,

    p.created_at AS FechaHora,

    p.note AS Nota,

    CAST(
        JSON_UNQUOTE(
            JSON_EXTRACT(item.value, '$.id')
        ) AS UNSIGNED
    ) AS ProductoID,

    JSON_UNQUOTE(
        JSON_EXTRACT(item.value, '$.name')
    ) AS Producto,

    CAST(
        JSON_UNQUOTE(
            JSON_EXTRACT(item.value, '$.quantity')
        ) AS DECIMAL(12,3)
    ) AS Cantidad,

    CAST(
        JSON_UNQUOTE(
            JSON_EXTRACT(item.value, '$.stock')
        ) AS DECIMAL(12,3)
    ) AS StockAlMomento

FROM mrpreventas p

CROSS JOIN JSON_TABLE(
    p.items_json,
    '$[*]' COLUMNS (
        value JSON PATH '$'
    )
) AS item;


-- ============================================================
-- 2. CONSOLIDATED PRODUCT MOVEMENTS
-- ============================================================
-- Combines:
--
--   Physical movements
--       vw_product_stock_history
--
--   Commercial movements
--       vw_commercial_movements
--
-- The Origen field distinguishes both types:
--
--   Fisico
--   Comercial
--
-- This allows Power BI to display a unified product movement
-- history without treating commercial events as physical
-- stock movements.
-- ============================================================

CREATE OR REPLACE VIEW vw_product_movements AS

-- ------------------------------------------------------------
-- PHYSICAL MOVEMENTS
-- ------------------------------------------------------------

SELECT
    h.ProductoID,
    h.Producto,

    h.BodegaID,
    h.Bodega,

    h.StockAntes,
    h.CantidadRegistrada,
    h.StockAhora,
    h.MovimientoNeto,

    h.TipoMovimientoStock,
    h.TipoMovimientoNegocio,

    h.FechaHora,
    h.TipoMovimientoERP,
    h.Referencia,

    'Fisico' AS Origen,

    NULL AS DocumentoID,
    NULL AS Documento,
    NULL AS Nota

FROM vw_product_stock_history h


UNION ALL


-- ------------------------------------------------------------
-- COMMERCIAL MOVEMENTS
-- ------------------------------------------------------------

SELECT
    c.ProductoID,
    c.Producto,

    NULL AS BodegaID,
    NULL AS Bodega,

    NULL AS StockAntes,
    c.Cantidad AS CantidadRegistrada,
    c.StockAlMomento AS StockAhora,

    NULL AS MovimientoNeto,

    'No aplica' AS TipoMovimientoStock,
    c.TipoMovimiento AS TipoMovimientoNegocio,

    c.FechaHora,
    NULL AS TipoMovimientoERP,
    c.Documento AS Referencia,

    'Comercial' AS Origen,

    c.DocumentoID,
    c.Documento,
    c.Nota

FROM vw_commercial_movements c;


-- ============================================================
-- 3. VALIDATION
-- ============================================================

-- Validate commercial movement types

SELECT
    TipoMovimientoNegocio,
    Origen,
    COUNT(*) AS Registros,
    SUM(CantidadRegistrada) AS Cantidad
FROM vw_product_movements
WHERE Origen = 'Comercial'
GROUP BY
    TipoMovimientoNegocio,
    Origen
ORDER BY
    TipoMovimientoNegocio;


-- Validate consolidated movement history

SELECT
    Origen,
    TipoMovimientoNegocio,
    COUNT(*) AS Registros
FROM vw_product_movements
GROUP BY
    Origen,
    TipoMovimientoNegocio
ORDER BY
    Origen,
    TipoMovimientoNegocio;


-- ============================================================
-- BUSINESS NOTES
-- ============================================================
--
-- Current validation:
--
-- Concesion  = 11 records / 36 units
-- Cotizacion = 26 records / 46 units
-- Preventa   = 64 records / 308 units
--
-- These values correspond to the current database state
-- at the time of validation and will change as new
-- transactions are created.
--
-- Future improvement:
-- Add a status to concessions indicating whether the
-- concession was later converted into an actual sale.
--
-- This will allow analysis of:
--   - Concessions pending
--   - Concessions converted to sales
--   - Concession conversion rate
--
-- Important:
-- Concessions, pre-sales and quotations currently do not
-- reduce physical stock.
-- ============================================================
