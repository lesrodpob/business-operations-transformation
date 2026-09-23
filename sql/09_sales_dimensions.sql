-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- Sales Dimensions
-- ============================================================
-- Purpose:
-- Create the seller dimension used to enrich sales analysis.
-- Database: Poseasy / MrCloud
-- Engine: MySQL

-- 1. SELLER STRUCTURE
DESCRIBE sivendedor;

-- 2. SELLER OVERVIEW
SELECT
    idSiVendedor AS VendedorID,
    SiVendedorNombre AS NombreVendedor,
    SiVendedorComision AS Comision,
    SiVendedorActivo AS Activo
FROM sivendedor
ORDER BY idSiVendedor;

-- 3. ACTIVE SELLERS
SELECT
    idSiVendedor AS VendedorID,
    SiVendedorNombre AS NombreVendedor,
    SiVendedorComision AS Comision
FROM sivendedor
WHERE SiVendedorActivo = 1
ORDER BY idSiVendedor;

-- 4. SELLER DATA QUALITY
SELECT
    COUNT(*) AS TotalVendedores,
    SUM(CASE WHEN SiVendedorActivo = 1 THEN 1 ELSE 0 END) AS VendedoresActivos,
    SUM(CASE WHEN SiVendedorNombre IS NULL OR TRIM(SiVendedorNombre) = '' THEN 1 ELSE 0 END) AS NombresVacios,
    SUM(CASE WHEN SiVendedorComision IS NULL THEN 1 ELSE 0 END) AS ComisionesNulas
FROM sivendedor;

-- 5. SELLER DIMENSION VIEW
CREATE OR REPLACE VIEW vw_salesperson AS
SELECT
    idSiVendedor AS VendedorID,
    SiVendedorNombre AS NombreVendedor,
    SiVendedorComision AS Comision,
    SiVendedorActivo AS Activo
FROM sivendedor;

-- 6. VALIDATE SELLER DIMENSION
SELECT
    VendedorID,
    NombreVendedor,
    Comision,
    Activo
FROM vw_salesperson
ORDER BY VendedorID;

-- NOTES
-- Initial findings:
-- 1. The ERP contains four active sellers.
-- 2. All four sellers currently have a commission value of 0.00.
-- 3. Seller information can be linked to sales through VendedorID.
-- 4. Commission-based KPIs should not be calculated until commission
--    values are confirmed as operationally relevant.
