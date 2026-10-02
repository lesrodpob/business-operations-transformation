-- ============================================================
-- DISTRIBUIDORA EL PALMAR
-- Business Operations Transformation
-- Sales Equivalent Demand
-- ============================================================
-- Purpose:
-- Calculate product demand including sales made through
-- product kits, converted into equivalent units of the
-- underlying product.
--
-- Direct sales are kept as recorded in the ERP.
-- Kit sales are converted using the quantity defined in
-- siproductokit.
--
-- This view preserves the transaction date so it can be
-- analyzed dynamically by period in Power BI.
--
-- Important:
-- Some inconsistent kit relationships were identified in
-- the ERP and require business validation before being used
-- for final demand-equivalent calculations.
-- ============================================================

CREATE OR REPLACE VIEW vw_sales_equivalent_detail AS

-- Direct sales
SELECT
    g.VeDocumentoGeneralFecEmision AS Fecha,
    d.idSiProducto AS ProductoID,
    p.SiProductoDenominacion AS Producto,
    d.VeDocumentoDetalleCantidad AS UnidadesDirectas,
    0 AS UnidadesViaKit,
    d.VeDocumentoDetalleCantidad AS DemandaEquivalente
FROM vedocumentogeneral g
INNER JOIN vedocumentodetalle d
    ON g.idVeDocumentoGeneral = d.idVeDocumentoGeneral
INNER JOIN siproducto p
    ON d.idSiProducto = p.idSiProducto
WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)
  AND g.VeDocumentoGeneralFecEmision <= CURDATE()
  AND d.idSiProducto NOT IN (
      SELECT DISTINCT idSiProducto
      FROM siproductokit
  )

UNION ALL

-- Sales through product kits
SELECT
    g.VeDocumentoGeneralFecEmision AS Fecha,
    k.idSiProductoInsumo AS ProductoID,
    p.SiProductoDenominacion AS Producto,
    0 AS UnidadesDirectas,
    d.VeDocumentoDetalleCantidad * k.SiProductoKitCantidad
        AS UnidadesViaKit,
    d.VeDocumentoDetalleCantidad * k.SiProductoKitCantidad
        AS DemandaEquivalente
FROM vedocumentogeneral g
INNER JOIN vedocumentodetalle d
    ON g.idVeDocumentoGeneral = d.idVeDocumentoGeneral
INNER JOIN siproductokit k
    ON d.idSiProducto = k.idSiProducto
INNER JOIN siproducto p
    ON k.idSiProductoInsumo = p.idSiProducto
WHERE g.SiDocumentoCodigoSII IN (33, 35, 39)
  AND g.VeDocumentoGeneralFecEmision <= CURDATE();
