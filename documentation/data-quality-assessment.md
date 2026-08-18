# Data Quality Assessment

## Assessment Objective

A data quality assessment was conducted on the ERP MySQL database to evaluate the completeness, consistency, and integrity of product and inventory information.

The objective was to identify data issues that could affect inventory management, reporting, sales analysis, and future business analytics.

The assessment was performed using SQL queries against the ERP database, with selected findings later incorporated into Power BI.

---

## Data Quality Assessment

The analysis focused on product master data, inventory records, and relationships between products and warehouse stock.

### Product Master Data

Several active products were identified with incomplete commercial or identification information:

- 615 active products without barcode.
- 110 active products without sales price.
- 365 active products without cost.
- 0 active products without category.

The ERP brand field was not considered a data quality issue because the business did not consistently use this field as part of the product classification process.

---

### Inventory Data

Inventory balances were analyzed across warehouse records to identify abnormal stock conditions and records requiring reconciliation.

A total of 349 active products were identified with negative physical stock balances.

Negative stock balances indicate inconsistencies between recorded inventory movements and the stock maintained in the ERP. These records require reconciliation against physical inventory and historical transactions before being considered fully reliable for inventory reporting.

---

### Orphan Inventory Records

The relationship between warehouse inventory records and the product master was also analyzed.

The assessment identified:

- 10 orphan inventory product IDs.
- Approximately 14.5K units of physical stock associated with these records.

These records existed in the warehouse stock structure without a corresponding product master record.

This represents a referential integrity issue because the affected inventory cannot be reliably associated with product information such as description, category, price, or cost.

---

### Warehouse Master Data

Warehouse records were reviewed to distinguish active operational locations from historical or inactive records.

The database contained inactive warehouse locations such as:

- IMPACTO SPA
- PRUEBA
- SALA-VENTAS

Some warehouse records also contained zero or no associated inventory.

These records were not automatically treated as data errors, as inactive or historical locations may remain in the ERP for operational or historical purposes.

However, warehouse status should be considered when building analytical models and current-state reports.

---

## Key Findings

The assessment identified four main data quality areas:

1. Incomplete product master data.
2. Negative inventory balances.
3. Orphan inventory records.
4. Historical and inactive records within the ERP structure.

The most significant product master data gaps were related to missing barcodes, sales prices, and product costs.

The inventory analysis also identified negative balances and orphan records that require further reconciliation.

---

## Business Impact

The identified data quality issues can affect:

- Inventory visibility and accuracy.
- Product-level sales analysis.
- Profitability and margin analysis.
- Inventory valuation.
- Purchasing and replenishment decisions.
- Reporting reliability.
- Future analytical models.

Incomplete product information can limit the reliability of sales and profitability analysis, while negative and orphan inventory records can affect the accuracy of stock reporting.

---

## Data Quality Recommendations

The assessment provides a baseline for future data remediation.

Recommended actions include:

- Complete missing product barcodes, prices, and costs.
- Reconcile negative inventory balances against physical stock and historical movements.
- Investigate orphan inventory records and determine their correct product relationships.
- Establish rules to distinguish active operational records from historical or inactive records.
- Introduce ongoing data quality controls for product and inventory master data.

---

## Tools

- MySQL — Database exploration and data quality analysis.
- SQL — Data validation and identification of inconsistencies.
- Power BI — Data quality visualization and reporting.
- ERP / MrCloud — Source system for operational and inventory data.

---

## Assessment Outcome

The assessment confirmed that several operational issues identified during the business and process analysis were also reflected in the underlying ERP data.

The findings provide a measurable baseline for subsequent data cleansing, inventory reconciliation, reporting improvements, and ongoing data quality monitoring.
