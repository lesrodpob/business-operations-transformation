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
-- - Physical stock movements come from the ERP stock history.
-- - Quotations, pre-sales and concessions are commercial events.
-- - Commercial events do NOT modify physical stock.
-- - Concessions are identified from the note field in
--   mrpreventas.
-- - Customer information is excluded because it is not reliably
--   populated for these transactions.
-- - CAJA and DISPLAY products are analyzed through
--   siproductokit and converted to their base product.
-- - StockAlMomento from the commercial JSON is intentionally
--   excluded because it represents commercial stock context
--   and must not affect physical inventory analysis.
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
-- CAJA / DISPLAY:
--   The commercial document may contain the kit product.
--   The analysis is performed at the base product level.
--
-- Example:
--
--   DISPLAY COCA 3 LT X 6
--          ↓
--   Producto base: COCA COLA PET 3 LT.
--   Formato: Display
--   CantidadFormato: 1
--   UnidadesEquivalentes: 6
--
-- Important:
-- Commercial movements are NOT physical stock movements.
-- ============================================================


CREATE OR REPLACE VIEW vw_commercial_movements AS


-- ============================================================
-- COTIZACIONES
-- ============================================================

SELECT
    p.id AS DocumentoID,

    'Cotizacion' AS TipoMovimiento,

    p.document_code AS Documento,

    p.created_at AS FechaHora,

    p.note AS Nota,

    CASE
        WHEN kit.idSiProducto IS NOT NULL
            THEN kit.idSiProductoInsumo
        ELSE j.ProductoID
    END AS ProductoID,

    CASE
        WHEN kit.idSiProducto IS NOT NULL
            THEN base.SiProductoDenominacion
        ELSE j.Producto
    END AS Producto,

    CASE
        WHEN kit.idSiProducto IS NOT NULL
            THEN
                CASE
                    WHEN UPPER(TRIM(kit_producto.SiProductoDenominacion)) LIKE 'CAJA%'
                        THEN 'Caja'

                    WHEN UPPER(TRIM(kit_producto.SiProductoDenominacion)) LIKE 'DISPLAY%'
                        THEN 'Display'

                    ELSE 'Unitario'
                END

        ELSE 'Unitario'
    END AS Formato,

    j.Cantidad AS CantidadFormato,

    CASE
        WHEN kit.idSiProducto IS NOT NULL
            THEN j.Cantidad * kit.SiProductoKitCantidad
        ELSE j.Cantidad
    END AS UnidadesEquivalentes

FROM mrcotizaciones p

CROSS JOIN JSON_TABLE(
    p.items_json,
    '$[*]' COLUMNS (
        ProductoID INT PATH '$.id',
        Producto VARCHAR(250) PATH '$.name',
        Cantidad DECIMAL(12,3) PATH '$.quantity'
    )
) j

LEFT JOIN siproductokit kit
    ON j.ProductoID = kit.idSiProducto
    AND kit.SiProductoKitCantidad > 0

LEFT JOIN siproducto kit_producto
    ON kit.idSiProducto = kit_producto.idSiProducto

LEFT JOIN siproducto base
    ON kit.idSiProductoInsumo = base.idSiProducto

WHERE
    kit.idSiProducto IS NULL

    OR (
        UPPER(TRIM(kit_producto.SiProductoDenominacion)) LIKE 'CAJA%'
        OR UPPER(TRIM(kit_producto.SiProductoDenominacion)) LIKE 'DISPLAY%'
    )


UNION ALL


-- ============================================================
-- PREVENTAS / CONCESIONES
-- ============================================================

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

    CASE
        WHEN kit.idSiProducto IS NOT NULL
            THEN kit.idSiProductoInsumo
        ELSE j.ProductoID
    END AS ProductoID,

    CASE
        WHEN kit.idSiProducto IS NOT NULL
            THEN base.SiProductoDenominacion
        ELSE j.Producto
    END AS Producto,

    CASE
        WHEN kit.idSiProducto IS NOT NULL
            THEN
                CASE
                    WHEN UPPER(TRIM(kit_producto.SiProductoDenominacion)) LIKE 'CAJA%'
                        THEN 'Caja'

                    WHEN UPPER(TRIM(kit_producto.SiProductoDenominacion)) LIKE 'DISPLAY%'
                        THEN 'Display'

                    ELSE 'Unitario'
                END

        ELSE 'Unitario'
    END AS Formato,

    j.Cantidad AS CantidadFormato,

    CASE
        WHEN kit.idSiProducto IS NOT NULL
            THEN j.Cantidad * kit.SiProductoKitCantidad
        ELSE j.Cantidad
    END AS UnidadesEquivalentes

FROM mrpreventas p

CROSS JOIN JSON_TABLE(
    p.items_json,
    '$[*]' COLUMNS (
        ProductoID INT PATH '$.id',
        Producto VARCHAR(250) PATH '$.name',
        Cantidad DECIMAL(12,3) PATH '$.quantity'
    )
) j

LEFT JOIN siproductokit kit
    ON j.ProductoID = kit.idSiProducto
    AND kit.SiProductoKitCantidad > 0

LEFT JOIN siproducto kit_producto
    ON kit.idSiProducto = kit_producto.idSiProducto

LEFT JOIN siproducto base
    ON kit.idSiProductoInsumo = base.idSiProducto

WHERE
    kit.idSiProducto IS NULL

    OR (
        UPPER(TRIM(kit_producto.SiProductoDenominacion)) LIKE 'CAJA%'
        OR UPPER(TRIM(kit_producto.SiProductoDenominacion)) LIKE 'DISPLAY%'
    );


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
-- Origen:
--   Fisico
--   Comercial
--
-- Physical movements retain stock calculations.
-- Commercial movements do not affect physical stock.
-- ============================================================


CREATE OR REPLACE VIEW vw_product_movements AS

-- ------------------------------------------------------------
-- MOVIMIENTOS FISICOS
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
    NULL AS Nota,

    NULL AS Formato,
    NULL AS UnidadesEquivalentes

FROM vw_product_stock_history h


UNION ALL


-- ------------------------------------------------------------
-- MOVIMIENTOS COMERCIALES
-- ------------------------------------------------------------

SELECT
    c.ProductoID,
    c.Producto,

    NULL AS BodegaID,
    NULL AS Bodega,

    NULL AS StockAntes,

    c.CantidadFormato AS CantidadRegistrada,

    NULL AS StockAhora,

    NULL AS MovimientoNeto,

    'No aplica' AS TipoMovimientoStock,

    c.TipoMovimiento AS TipoMovimientoNegocio,

    c.FechaHora,

    NULL AS TipoMovimientoERP,

    c.Documento AS Referencia,

    'Comercial' AS Origen,

    c.DocumentoID,
    c.Documento,
    c.Nota,

    c.Formato,
    c.UnidadesEquivalentes

FROM vw_commercial_movements c;


-- ============================================================
-- 3. VALIDATION
-- ============================================================


-- Validate commercial movement types

SELECT
    TipoMovimientoNegocio,
    Origen,
    COUNT(*) AS Registros,
    SUM(CantidadRegistrada) AS CantidadFormatos,
    SUM(UnidadesEquivalentes) AS UnidadesEquivalentes
FROM vw_product_movements
WHERE Origen = 'Comercial'
GROUP BY
    TipoMovimientoNegocio,
    Origen
ORDER BY
    TipoMovimientoNegocio;


-- Validate commercial formats

SELECT
    TipoMovimientoNegocio,
    Formato,
    COUNT(*) AS Registros,
    SUM(CantidadRegistrada) AS CantidadFormatos,
    SUM(UnidadesEquivalentes) AS UnidadesEquivalentes
FROM vw_product_movements
WHERE Origen = 'Comercial'
GROUP BY
    TipoMovimientoNegocio,
    Formato
ORDER BY
    TipoMovimientoNegocio,
    Formato;


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
-- Current commercial movement types:
--   Concesion
--   Cotizacion
--   Preventa
--
-- Commercial events do NOT modify physical stock.
--
-- StockAlMomento from mrcotizaciones / mrpreventas is
-- intentionally excluded from the analytical model because
-- it represents the stock context captured by the commercial
-- application and should not be interpreted as physical
-- inventory.
--
-- CAJA and DISPLAY products are converted to their base
-- product using siproductokit.
--
-- The original commercial format is preserved through:
--   Formato
--   CantidadFormato
--   UnidadesEquivalentes
--
-- Example:
--   1 DISPLAY COCA 3 LT X 6
--   -> Product: COCA COLA PET 3 LT.
--   -> Formato: Display
--   -> CantidadFormato: 1
--   -> UnidadesEquivalentes: 6
--
-- Future improvement:
-- Add a status to concessions indicating whether the
-- concession was later converted into an actual sale.
--
-- This will allow analysis of:
--   - Concessions pending
--   - Concessions converted to sales
--   - Concession conversion rate
-- ============================================================
