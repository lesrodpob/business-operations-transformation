-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- Product Movements View
-- ============================================================
-- Purpose:
-- Consolidate physical inventory movements and commercial
-- activity into a single source for the Power BI product detail.
--
-- Business rules:
-- 1. Physical movements come from vw_product_stock_history.
-- 2. Kit sales (Caja / Display) are mapped to their base product.
-- 3. Kit quantities are converted into equivalent base units.
-- 4. Stock balances are NULL for kit sales because the ERP
--    deducts stock from the kit SKU, not the base product SKU.
-- 5. Direct sales and purchases are recorded by unit.
-- 6. Commercial movements do not represent confirmed sales
--    or physical stock balances.
-- 7. Sales references use the actual document folio.
-- 8. Purchase references use the supplier document number.
-- ============================================================

CREATE OR REPLACE VIEW vw_product_movements AS

/* ============================================================
   1. PHYSICAL MOVEMENTS
   ============================================================ */

SELECT
    CASE
        WHEN venta.Formato IS NOT NULL
            THEN venta.ProductoBaseID
        ELSE h.ProductoID
    END AS ProductoID,

    CASE
        WHEN venta.Formato IS NOT NULL
            THEN venta.ProductoBase
        ELSE h.Producto
    END AS Producto,

    h.BodegaID,
    h.Bodega,

    CASE
        WHEN venta.Formato IS NOT NULL
            THEN NULL
        ELSE h.StockAntes
    END AS StockAntes,

    h.CantidadRegistrada,

    CASE
        WHEN venta.Formato IS NOT NULL
            THEN NULL
        ELSE h.StockAhora
    END AS StockAhora,

    CASE
        WHEN venta.Formato IS NOT NULL
            THEN NULL
        ELSE h.MovimientoNeto
    END AS MovimientoNeto,

    h.TipoMovimientoStock,

    CASE
        WHEN h.TipoMovimientoNegocio = 'Recepción'
            THEN 'Compra'
        ELSE h.TipoMovimientoNegocio
    END AS TipoMovimientoNegocio,

    h.FechaHora,
    h.TipoMovimientoERP,

    CASE
        WHEN h.TipoMovimientoERP LIKE 'VENTA-%'
            THEN SUBSTRING_INDEX(
                h.TipoMovimientoERP,
                '-',
                -1
            )

        WHEN h.TipoMovimientoERP LIKE
             'COMPROBANTE DE RECEPCION%'
            THEN CAST(compra.DocumentoCompra AS CHAR)

        ELSE h.Referencia
    END AS Referencia,

    'Fisico' AS Origen,

    NULL AS DocumentoID,
    NULL AS Documento,
    NULL AS Nota,

    CASE
        WHEN h.TipoMovimientoNegocio IN
             ('Venta', 'Recepción', 'Compra')
            THEN COALESCE(venta.Formato, 'Unitario')
        ELSE NULL
    END AS Formato,

    CASE
        WHEN h.TipoMovimientoNegocio = 'Venta'
             AND venta.Formato IS NOT NULL
            THEN h.CantidadRegistrada
                 * venta.UnidadesPorFormato
        ELSE h.CantidadRegistrada
    END AS UnidadesEquivalentes

FROM vw_product_stock_history h

/* Map kit sales to their base products */

LEFT JOIN (
    SELECT DISTINCT
        g.VeDocumentoGeneralFolio AS Folio,
        d.idSiProducto AS ProductoVendidoID,
        kit.idSiProductoInsumo AS ProductoBaseID,
        base.SiProductoDenominacion AS ProductoBase,

        CASE
            WHEN UPPER(
                TRIM(kit_producto.SiProductoDenominacion)
            ) LIKE 'CAJA%'
                THEN 'Caja'

            WHEN UPPER(
                TRIM(kit_producto.SiProductoDenominacion)
            ) LIKE 'DISPLAY%'
                THEN 'Display'

            ELSE NULL
        END AS Formato,

        kit.SiProductoKitCantidad AS UnidadesPorFormato

    FROM vedocumentogeneral g

    INNER JOIN vedocumentodetalle d
        ON g.idVeDocumentoGeneral =
           d.idVeDocumentoGeneral

    INNER JOIN siproductokit kit
        ON d.idSiProducto =
           kit.idSiProducto

    INNER JOIN siproducto kit_producto
        ON kit.idSiProducto =
           kit_producto.idSiProducto

    INNER JOIN siproducto base
        ON kit.idSiProductoInsumo =
           base.idSiProducto

    WHERE
        g.SiDocumentoCodigoSII IN (33, 35, 39)

        AND g.VeDocumentoGeneralFecEmision <= CURDATE()

        AND kit.SiProductoKitCantidad > 0

        AND (
            UPPER(
                TRIM(kit_producto.SiProductoDenominacion)
            ) LIKE 'CAJA%'

            OR

            UPPER(
                TRIM(kit_producto.SiProductoDenominacion)
            ) LIKE 'DISPLAY%'
        )
) venta
    ON h.TipoMovimientoERP LIKE 'VENTA-%'

    AND CAST(
        SUBSTRING_INDEX(
            h.TipoMovimientoERP,
            '-',
            -1
        ) AS UNSIGNED
    ) = venta.Folio

    AND h.ProductoID = venta.ProductoVendidoID

/* Resolve the actual supplier purchase document number */

LEFT JOIN (
    SELECT
        idCoComprobanteGeneral,
        CoComprobanteGeneralDocNumero AS DocumentoCompra
    FROM cocomprobantegeneral
) compra
    ON h.TipoMovimientoERP LIKE
       'COMPROBANTE DE RECEPCION%'

    AND compra.idCoComprobanteGeneral =
        CAST(h.Referencia AS UNSIGNED)


UNION ALL


/* ============================================================
   2. COMMERCIAL MOVEMENTS
   Quotes / Pre-sales / Concessions
   ============================================================ */

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
