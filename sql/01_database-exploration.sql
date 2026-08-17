-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- SQL Database Exploration
-- ============================================================
--
-- Purpose:
-- Initial exploration of the ERP MySQL database to understand
-- available tables, relevant entities, document types and
-- potential data quality issues.
--
-- Database: Poseasy / MrCloud
-- Engine: MySQL
-- ============================================================


-- ============================================================
-- 1. DATABASE STRUCTURE
-- ============================================================

-- List all tables available in the database
SHOW TABLES;


-- ============================================================
-- 2. CORE TABLE STRUCTURE
-- ============================================================

-- Sales / commercial documents
DESCRIBE vedocumentogeneral;
DESCRIBE vedocumentodetalle;

-- Products and product master data
DESCRIBE siproducto;

-- Product inventory by warehouse
DESCRIBE siproductobodega;

-- Warehouses
DESCRIBE sibodega;

-- Product categories and families
DESCRIBE sicategoria;
DESCRIBE sifamilia;

-- Customers
DESCRIBE sicliente;

-- Document types
DESCRIBE sidocumento;


-- ============================================================
-- 3. DOCUMENT TYPES USED IN SALES ANALYSIS
-- ============================================================

SELECT
    idSiDocumento,
    SiDocumentoCodigoSII,
    SiDocumentoDenominacion
FROM sidocumento
WHERE SiDocumentoCodigoSII IN (33, 35, 39, 52, 56, 61)
ORDER BY SiDocumentoCodigoSII;


-- ============================================================
-- 4. DOCUMENT VOLUME BY TYPE
-- ============================================================

SELECT
    SiDocumentoCodigoSII AS TipoDocumento,
    COUNT(*) AS TotalDocumentos,
    MIN(VeDocumentoGeneralFecEmision) AS FechaMinima,
    MAX(VeDocumentoGeneralFecEmision) AS FechaMaxima,
    SUM(VeDocumentoGeneralMontoTotal) AS MontoTotal
FROM vedocumentogeneral
WHERE SiDocumentoCodigoSII IN (33, 35, 39, 52, 56, 61)
GROUP BY SiDocumentoCodigoSII
ORDER BY SiDocumentoCodigoSII;


-- ============================================================
-- 5. SALES DOCUMENTS
-- ============================================================
--
-- For the initial sales analysis, the following document types
-- are considered:
--
-- 33 = Factura Electrónica
-- 35 = Nota de Venta
-- 39 = Boleta Electrónica
--
-- Credit and debit notes are analyzed separately because they
-- represent adjustments to transactions rather than regular sales.
-- ============================================================

SELECT
    YEAR(VeDocumentoGeneralFecEmision) AS Año,
    COUNT(*) AS Documentos,
    SUM(VeDocumentoGeneralMontoTotal) AS Ventas
FROM vedocumentogeneral
WHERE SiDocumentoCodigoSII IN (33, 35, 39)
GROUP BY YEAR(VeDocumentoGeneralFecEmision)
ORDER BY Año;


-- ============================================================
-- 6. DATA QUALITY CHECK - INVALID FUTURE DATES
-- ============================================================
--
-- Identify sales documents whose emission date is later than
-- the current date.
--
-- This check revealed an anomalous record that must be investigated.
-- ============================================================

SELECT
    idVeDocumentoGeneral,
    SiDocumentoCodigoSII,
    VeDocumentoGeneralFolio,
    VeDocumentoGeneralFecEmision,
    VeDocumentoGeneralMontoTotal
FROM vedocumentogeneral
WHERE SiDocumentoCodigoSII IN (33, 35, 39)
  AND VeDocumentoGeneralFecEmision > CURDATE();


-- ============================================================
-- 7. COUNT INVALID FUTURE-DATED RECORDS
-- ============================================================

SELECT
    COUNT(*) AS RegistrosFechaInvalida
FROM vedocumentogeneral
WHERE SiDocumentoCodigoSII IN (33, 35, 39)
  AND VeDocumentoGeneralFecEmision > CURDATE();


-- ============================================================
-- 8. SALES BY MONTH
-- ============================================================

SELECT
    YEAR(VeDocumentoGeneralFecEmision) AS Año,
    MONTH(VeDocumentoGeneralFecEmision) AS Mes,
    COUNT(*) AS Documentos,
    SUM(VeDocumentoGeneralMontoTotal) AS Ventas
FROM vedocumentogeneral
WHERE SiDocumentoCodigoSII IN (33, 35, 39)
GROUP BY
    YEAR(VeDocumentoGeneralFecEmision),
    MONTH(VeDocumentoGeneralFecEmision)
ORDER BY
    Año,
    Mes;


-- ============================================================
-- NOTES
-- ============================================================
--
-- Initial findings:
--
-- 1. The ERP database contains multiple operational domains,
--    including sales, inventory, products, customers, warehouses,
--    payments and stock movements.
--
-- 2. Sales transactions are primarily represented through
--    vedocumentogeneral and vedocumentodetalle.
--
-- 3. Product master data is stored in siproducto and inventory
--    quantities by warehouse are stored in siproductobodega.
--
-- 4. Document types must be explicitly classified before
--    calculating sales KPIs.
--
-- 5. A data quality issue was identified in the emission date:
--    at least one sales document contains a future date
--    (3620-09-23).
--
-- 6. Data quality validation is therefore required before using
--    the ERP data as a reliable source for business reporting.
--
-- ============================================================
