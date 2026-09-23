-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- Customer Analysis
-- ============================================================
-- Purpose:
-- Analyze the customer master data available in the ERP
-- and prepare a customer dimension for sales analysis.
-- Database: Poseasy / MrCloud
-- Engine: MySQL
--
-- Important data-quality context:
-- The customer master contains generic customers, inactive
-- customers, missing fantasy names and inconsistent business
-- activity descriptions. These records are preserved as stored
-- in the ERP and are not corrected in this analysis.


-- 1. CUSTOMER TABLE STRUCTURE

DESCRIBE sicliente;


-- 2. CUSTOMER OVERVIEW

SELECT
    COUNT(*) AS TotalClientes,
    COUNT(DISTINCT idSiClienteRut) AS ClientesUnicos,
    SUM(CASE WHEN SiClienteActivo = 1 THEN 1 ELSE 0 END) AS ClientesActivos,
    SUM(CASE WHEN SiClienteActivo = 0 THEN 1 ELSE 0 END) AS ClientesInactivos
FROM sicliente;


-- 3. CUSTOMER TYPES

SELECT
    SiClienteTipo AS TipoCliente,
    COUNT(*) AS Clientes,
    SUM(CASE WHEN SiClienteActivo = 1 THEN 1 ELSE 0 END) AS ClientesActivos
FROM sicliente
GROUP BY SiClienteTipo
ORDER BY SiClienteTipo;


-- 4. CUSTOMERS BY PRICE LIST

SELECT
    idSiListaPrecio AS ListaPrecioID,
    COUNT(*) AS Clientes
FROM sicliente
GROUP BY idSiListaPrecio
ORDER BY idSiListaPrecio;


-- 5. CUSTOMER DATA QUALITY

SELECT
    SUM(
        CASE
            WHEN SiClienteRazonSocial IS NULL
                 OR TRIM(SiClienteRazonSocial) = ''
            THEN 1
            ELSE 0
        END
    ) AS SinRazonSocial,

    SUM(
        CASE
            WHEN SiClienteFantasia IS NULL
                 OR TRIM(SiClienteFantasia) = ''
            THEN 1
            ELSE 0
        END
    ) AS SinNombreFantasia,

    SUM(
        CASE
            WHEN SiClienteGiro IS NULL
                 OR TRIM(SiClienteGiro) = ''
            THEN 1
            ELSE 0
        END
    ) AS SinGiro,

    SUM(
        CASE
            WHEN idSiComuna IS NULL
                 OR idSiComuna = 0
            THEN 1
            ELSE 0
        END
    ) AS SinComuna
FROM sicliente;


-- 6. CUSTOMER CREDIT CONDITIONS

SELECT
    SiClienteTipo AS TipoCliente,
    COUNT(*) AS Clientes,
    SUM(
        CASE
            WHEN SiClienteLineaCredito IS NOT NULL
                 AND SiClienteLineaCredito > 0
            THEN 1
            ELSE 0
        END
    ) AS ConLineaCredito,
    AVG(
        CASE
            WHEN SiClienteDiasCredito > 0
            THEN SiClienteDiasCredito
            ELSE NULL
        END
    ) AS PromedioDiasCredito
FROM sicliente
GROUP BY SiClienteTipo
ORDER BY SiClienteTipo;


-- 7. CREATE CUSTOMER VIEW

CREATE OR REPLACE VIEW vw_customer AS
SELECT
    idSiClienteRut AS ClienteID,
    SiClienteDV AS DigitoVerificador,
    SiClienteRazonSocial AS RazonSocial,
    SiClienteFantasia AS NombreFantasia,
    SiClienteGiro AS Giro,
    idSiComuna AS ComunaID,
    SiClienteTipo AS TipoCliente,
    SiClienteLineaCredito AS LineaCredito,
    SiClienteDiasCredito AS DiasCredito,
    SiClienteDescuento AS Descuento,
    SiClienteActivo AS Activo,
    idSiListaPrecio AS ListaPrecioID
FROM sicliente;


-- 8. VALIDATE CUSTOMER VIEW

SELECT *
FROM vw_customer
LIMIT 30;


-- 9. ACTIVE CUSTOMERS

SELECT
    ClienteID,
    DigitoVerificador,
    RazonSocial,
    NombreFantasia,
    Giro,
    ComunaID,
    TipoCliente,
    LineaCredito,
    DiasCredito,
    Descuento,
    ListaPrecioID
FROM vw_customer
WHERE Activo = 1
ORDER BY RazonSocial
LIMIT 100;


-- NOTES
-- 1. idSiClienteRut is used as the customer identifier.
-- 2. CLIENTE BOLETA is retained as a generic ERP customer record.
-- 3. Customer types are preserved as recorded in the ERP.
-- 4. Inactive customers are preserved for historical traceability.
-- 5. Missing fantasy names, missing business activities and other
--    data-quality issues are documented but not corrected here.
-- 6. Customer contact details such as phone, email and address
--    are not included in the analytical view because they are not
--    required for the current business analysis model.
-- 7. Customer geography can be expanded later through idSiComuna.
