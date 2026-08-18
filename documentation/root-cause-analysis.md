# Root Cause Analysis

## Analysis Approach

The root cause analysis was conducted by comparing the operational issues identified during the process analysis with the underlying business practices, system usage, and data structures supporting those processes.

The analysis focused on determining whether the identified problems were primarily caused by the ERP system itself or by inconsistencies in processes, data management, and system adoption.

---

## Key Findings

The analysis revealed that the main operational challenges were not caused by a lack of ERP functionality, but by inconsistent business processes, incomplete system adoption, and the absence of standardized inventory management practices.

These underlying causes affected inventory accuracy, product information consistency, data reliability, and operational visibility.

The main findings were:

- Inventory discrepancies resulting from inconsistent inventory recording practices.
- Inconsistent product master data and classification.
- Incomplete product and pricing information.
- Negative inventory balances across warehouse records.
- Orphan inventory records without a corresponding product master record.
- Limited reliability of ERP inventory information for operational control.
- Continued reliance on manual records and employee knowledge for certain processes.
- Underutilization of available ERP functionality.

---

## Root Causes

| Finding | Root Cause |
|---|---|
| **Inventory discrepancies** | Inventory movements were not consistently recorded using the appropriate ERP workflows. Product receipts and stock changes were sometimes handled through manual inventory adjustments rather than standardized purchasing and inventory processes. |
| **Inconsistent product records** | No standardized product master data structure existed. Product names, categories, families, and descriptions were created and maintained inconsistently over time. |
| **Incomplete product and pricing information** | Product master data was not consistently maintained, resulting in missing or incomplete barcodes, sales prices, costs, categories, and other product attributes. |
| **Negative inventory balances** | Historical inventory movements and manual stock adjustments were not consistently reconciled, resulting in inventory balances that did not always reflect physical stock conditions. |
| **Orphan inventory records** | Historical inventory records existed for product IDs that no longer had corresponding product master records, indicating inconsistencies between inventory and product master data. |
| **Limited inventory visibility** | Operational information was distributed across ERP records, spreadsheets, manual counts, and employee knowledge, making it difficult to obtain a consistent view of inventory. |
| **Manual operational practices** | Several processes relied on manual counts, paper records, spreadsheets, and employee knowledge instead of standardized system workflows. |
| **Underutilized ERP functionality** | Existing ERP capabilities were not consistently integrated into daily operational processes, limiting the value of available purchasing, inventory, and reporting functionality. |

---

## Data Quality Evidence

The SQL analysis of the ERP database provided evidence that the process and master data issues identified during the business analysis were also reflected in the underlying data.

Initial data quality checks identified:

- **615 active products without a barcode.**
- **110 products without a sales price.**
- **365 products without a recorded cost.**
- **10 orphan inventory product IDs** without a corresponding product master record.
- Approximately **14.5K units associated with orphan physical stock records.**
- **349 product/inventory records identified during the reconciliation analysis** requiring further investigation.

These findings demonstrate that the operational issues were not limited to process documentation or employee practices. They were also reflected in the structure and consistency of the ERP data.

---

## Relationship Between Process and Data Issues

The analysis identified a direct relationship between operational practices and data quality.

For example:

**Manual inventory adjustments**  
→ inconsistent inventory movements  
→ negative or unreliable stock balances

**Inconsistent product creation practices**  
→ incomplete or duplicated product information  
→ unreliable product master data

**Fragmented operational records**  
→ manual consolidation  
→ limited visibility into inventory and business performance

**Underutilized ERP workflows**  
→ information stored outside the appropriate system processes  
→ reduced traceability and data reliability

This relationship indicates that improving data quality required more than correcting individual records. The underlying processes and system usage also needed to be standardized.

---
