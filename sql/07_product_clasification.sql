-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- Product Classification Analysis
-- ============================================================
-- Purpose:
-- Analyze the product classification structure used by the ERP,
-- including categories, families and units of measure.
-- Database: Poseasy / MrCloud
-- Engine: MySQL
--
-- Important data-quality context:
-- The ERP contains active and inactive categories/families,
-- historical or duplicated classifications, and some products
-- without an assigned family. This analysis preserves the ERP
-- structure and does not apply classification corrections.


-- 1. CATEGORY STRUCTURE

DESCRIBE sicategoria;

SELECT
    idSiCategoria,
    SiCategoriaDenominacion,
    SiCategoriaActivo
FROM sicategoria
ORDER BY idSiCategoria;


-- 2. FAMILY STRUCTURE

DESCRIBE sifamilia;

SELECT
    f.idSiFamilia,
    f.SiFamiliaDenominacion,
    f.idSiCategoria,
    c.SiCategoriaDenominacion,
    f.SiFamiliaActivo
FROM sifamilia f
LEFT JOIN sicategoria c
    ON f.idSiCategoria = c.idSiCategoria
ORDER BY
    c.SiCategoriaDenominacion,
    f.SiFamiliaDenominacion;


-- 3. UNIT OF MEASURE STRUCTURE

DESCRIBE simedida;

SELECT
    idSiMedida,
    SiMedidaDenominacion,
    SiMedidaActivo
FROM simedida
ORDER BY idSiMedida;


-- 4. PRODUCT CLASSIFICATION VALIDATION

SELECT
    p.idSiProducto AS ProductoID,
    p.SiProductoDenominacion AS Producto,

    p.idSiCategoria AS CategoriaID,
    c.SiCategoriaDenominacion AS Categoria,

    p.idSiFamilia AS FamiliaID,
    f.SiFamiliaDenominacion AS Familia,

    p.idSiMedida AS MedidaID,
    m.SiMedidaDenominacion AS Medida

FROM siproducto p

LEFT JOIN sicategoria c
    ON p.idSiCategoria = c.idSiCategoria

LEFT JOIN sifamilia f
    ON p.idSiFamilia = f.idSiFamilia

LEFT JOIN simedida m
    ON p.idSiMedida = m.idSiMedida

LIMIT 30;


-- 5. CREATE PRODUCT CLASSIFICATION VIEW

CREATE OR REPLACE VIEW vw_product_classification AS
SELECT
    p.idSiProducto AS ProductoID,
    p.SiProductoDenominacion AS Producto,

    p.idSiCategoria AS CategoriaID,
    c.SiCategoriaDenominacion AS Categoria,
    c.SiCategoriaActivo AS CategoriaActiva,

    p.idSiFamilia AS FamiliaID,
    f.SiFamiliaDenominacion AS Familia,
    f.SiFamiliaActivo AS FamiliaActiva,

    p.idSiMedida AS MedidaID,
    m.SiMedidaDenominacion AS Medida,
    m.SiMedidaActivo AS MedidaActiva

FROM siproducto p

LEFT JOIN sicategoria c
    ON p.idSiCategoria = c.idSiCategoria

LEFT JOIN sifamilia f
    ON p.idSiFamilia = f.idSiFamilia

LEFT JOIN simedida m
    ON p.idSiMedida = m.idSiMedida;


-- 6. VALIDATE PRODUCT CLASSIFICATION VIEW

SELECT *
FROM vw_product_classification
LIMIT 30;


-- 7. PRODUCTS WITHOUT A FAMILY

SELECT
    ProductoID,
    Producto,
    CategoriaID,
    Categoria,
    FamiliaID,
    Familia,
    MedidaID,
    Medida
FROM vw_product_classification
WHERE FamiliaID = 0
   OR FamiliaID IS NULL
ORDER BY ProductoID;


-- 8. PRODUCTS BY UNIT OF MEASURE

SELECT
    MedidaID,
    Medida,
    COUNT(*) AS Productos
FROM vw_product_classification
GROUP BY
    MedidaID,
    Medida
ORDER BY MedidaID;


-- 9. PRODUCTS USING INACTIVE CATEGORIES

SELECT
    ProductoID,
    Producto,
    CategoriaID,
    Categoria,
    CategoriaActiva,
    FamiliaID,
    Familia,
    FamiliaActiva,
    MedidaID,
    Medida
FROM vw_product_classification
WHERE CategoriaActiva = 0
ORDER BY ProductoID;


-- 10. PRODUCTS USING INACTIVE FAMILIES

SELECT
    ProductoID,
    Producto,
    CategoriaID,
    Categoria,
    FamiliaID,
    Familia,
    FamiliaActiva,
    MedidaID,
    Medida
FROM vw_product_classification
WHERE FamiliaActiva = 0
ORDER BY ProductoID;


-- NOTES
-- 1. The product classification hierarchy is:
--    Product -> Category -> Family -> Unit of Measure.
-- 2. Active units of measure currently identified are:
--    UNIDAD, KG and DISPLAY.
-- 3. The ERP contains active and inactive categories and families.
-- 4. Some categories and families have duplicated or historical names.
-- 5. Some products have FamiliaID = 0 and therefore no assigned family.
-- 6. Inactive classifications are preserved for historical traceability.
-- 7. No classification corrections are applied in SQL.
-- 8. DISPLAY-to-UNIT conversion logic is not assumed here.
--    The ERP configuration must be confirmed before using unit
--    conversion calculations in purchasing or inventory analysis.
