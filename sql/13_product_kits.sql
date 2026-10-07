-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- Product Kit / Packaging Analysis
-- ============================================================
-- Purpose:
-- Identifies the packaging formats associated with each
-- unitary product and the number of units contained in each
-- package.
--
-- Source tables:
--   siproducto
--   siproductokit
--
-- Business rule:
--   SiProductoKitCantidad represents the number of unitary
--   products contained in the kit/package.
--
-- Formats currently identified:
--   CAJA
--   DISPLAY
--
-- Important:
--   The view preserves the original ERP kit relationships.
--   It does not aggregate or select a single package when
--   multiple configurations exist.
--
-- ============================================================


-- 1. PRODUCT KIT / PACKAGING VIEW

CREATE OR REPLACE VIEW vw_product_kits AS

SELECT
    k.idSiProductoInsumo AS ProductoID,
    insumo.SiProductoDenominacion AS Producto,

    k.idSiProducto AS KitID,
    kit.SiProductoDenominacion AS Kit,

    CASE
        WHEN UPPER(TRIM(kit.SiProductoDenominacion)) LIKE 'CAJA%'
            THEN 'Caja'

        WHEN UPPER(TRIM(kit.SiProductoDenominacion)) LIKE 'DISPLAY%'
            THEN 'Display'

        ELSE 'Otro'
    END AS Formato,

    k.SiProductoKitCantidad AS UnidadesPorFormato,

    kit.SiProductoKit AS EsKit

FROM siproductokit k

INNER JOIN siproducto kit
    ON k.idSiProducto = kit.idSiProducto

INNER JOIN siproducto insumo
    ON k.idSiProductoInsumo = insumo.idSiProducto

WHERE
    kit.SiProductoKit > 0

    AND (
        UPPER(TRIM(kit.SiProductoDenominacion)) LIKE 'CAJA%'
        OR UPPER(TRIM(kit.SiProductoDenominacion)) LIKE 'DISPLAY%'
    );


-- ============================================================
-- 2. VALIDATION
-- ============================================================
-- Shows all packaging configurations associated with a product.

SELECT
    ProductoID,
    Producto,
    KitID,
    Kit,
    Formato,
    UnidadesPorFormato
FROM vw_product_kits
ORDER BY
    Producto,
    Formato,
    Kit;


-- ============================================================
-- 3. VALIDATION - MULTIPLE CONFIGURATIONS
-- ============================================================
-- Identifies products with more than one configuration
-- for the same packaging format.
--
-- This does not necessarily mean that the data is incorrect.
-- It should be reviewed in the ERP before selecting a single
-- configuration for analytical calculations.

SELECT
    ProductoID,
    Producto,
    Formato,
    COUNT(*) AS Configuraciones
FROM vw_product_kits
GROUP BY
    ProductoID,
    Producto,
    Formato
HAVING COUNT(*) > 1
ORDER BY
    Producto,
    Formato;


-- ============================================================
-- NOTES
-- ============================================================
-- 1. SiProductoKitCantidad is treated as the official ERP
--    quantity for the package equivalence.
--
-- 2. The quantity written in the product name (for example,
--    "X 6", "X 12", "X 24") is not used for calculations.
--
-- 3. Multiple kit configurations are preserved rather than
--    arbitrarily selecting one.
--
-- 4. Data-quality inconsistencies should be corrected or
--    reviewed in MrCloud before using a single configuration
--    for package-equivalent sales calculations.
--
-- 5. Package equivalents represent alternative expressions
--    of the same unitary sales volume. They must not be added
--    together with unit sales.
