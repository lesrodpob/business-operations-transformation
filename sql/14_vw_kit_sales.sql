-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- SQL - Kit Sales Analysis
-- ============================================================
-- Purpose:
-- Identify actual sales of product kits (CAJA / DISPLAY)
-- and link them to their base product.
--
-- Business rule:
-- - Stock is managed in units of the base product.
-- - CAJA and DISPLAY are independent products in the ERP.
-- - Sales of kits are recorded as sales of the kit product.
-- - siproductokit defines the relationship between the kit
--   and the base product, including the quantity contained.
--
-- Important:
-- The product name used for classification comes from the
-- product master (siproducto), not from the historical sales
-- line description.
--
-- Database: Poseasy / MrCloud
-- Engine: MySQL
-- ============================================================


-- 1. KIT SALES DETAIL
-- ------------------------------------------------------------
-- Each record represents a sale of a CAJA or DISPLAY product.
-- The kit is linked to its base product through siproductokit.

CREATE OR REPLACE VIEW vw_kit_sales AS

SELECT
    g.idVeDocumentoGeneral AS VentaID,

    g.VeDocumentoGeneralFecEmision AS Fecha,

    g.SiDocumentoCodigoSII AS TipoDocumento,

    g.VeDocumentoGeneralFolio AS Folio,


    -- Kit sold
    d.idSiProducto AS KitID,

    kit.SiProductoDenominacion AS Kit,


    -- Base product
    k.idSiProductoInsumo AS ProductoID,

    insumo.SiProductoDenominacion AS Producto,


    -- Kit format
    CASE
        WHEN UPPER(TRIM(kit.SiProductoDenominacion)) LIKE 'CAJA%'
            THEN 'Caja'

        WHEN UPPER(TRIM(kit.SiProductoDenominacion)) LIKE 'DISPLAY%'
            THEN 'Display'

        ELSE 'Otro'
    END AS Formato,


    -- Actual number of kits sold
    d.VeDocumentoDetalleCantidad AS KitsVendidos,


    -- Sale information
    d.VeDocumentoDetallePrecio AS PrecioVenta,

    d.VeDocumentoDetalleTotal AS VentaTotal,


    -- Base units contained in each kit
    k.SiProductoKitCantidad AS UnidadesPorFormato,


    -- Equivalent base units
    d.VeDocumentoDetalleCantidad
        * k.SiProductoKitCantidad AS UnidadesEquivalentes


FROM vedocumentogeneral g


INNER JOIN vedocumentodetalle d
    ON g.idVeDocumentoGeneral = d.idVeDocumentoGeneral


INNER JOIN siproductokit k
    ON d.idSiProducto = k.idSiProducto


INNER JOIN siproducto kit
    ON k.idSiProducto = kit.idSiProducto


INNER JOIN siproducto insumo
    ON k.idSiProductoInsumo = insumo.idSiProducto


WHERE
    -- Sales documents
    g.SiDocumentoCodigoSII IN (33, 35, 39)

    -- Exclude invalid future dates
    AND g.VeDocumentoGeneralFecEmision <= CURDATE()

    -- Only products configured as kits
    AND kit.SiProductoKit > 0

    -- Only CAJA and DISPLAY formats
    AND (
        UPPER(TRIM(kit.SiProductoDenominacion)) LIKE 'CAJA%'
        OR
        UPPER(TRIM(kit.SiProductoDenominacion)) LIKE 'DISPLAY%'
    );
