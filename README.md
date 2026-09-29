<p align="center">
  <img src="images/banner-elpalmar.png" width="90%" height="300">
</p>

# Business Operations Transformation — Distribuidora El Palmar

## 📌 Project Overview

Business operations and data transformation project for Distribuidora El Palmar, focused on improving inventory management, operational processes, ERP data utilization, business reporting, and analytical decision support.

The project started with an operational analysis of inventory and warehouse processes and evolved into a broader Business Intelligence and digital transformation initiative integrating ERP data, SQL, Excel, Power BI, and web technologies.

The objective is to transform operational data into actionable information that can support sales growth, inventory optimization, profitability analysis, purchasing decisions, and operational efficiency.

---

## 🌐 Digital Product Catalog

A web-based digital product catalog was developed as part of the project's digital transformation initiatives.

The catalog provides customers with a structured way to browse available products and submit orders, while using product information generated from the ERP system.

👉 **[View Live Digital Catalog](https://distribuidora-el-palmar-limache.vercel.app/)**

### Key Features

- Product categorization and filtering.
- Product search.
- Stock-based product visibility.
- Shopping cart.
- WhatsApp order integration.
- Responsive web design.
- ERP-generated JSON product data.

### Technology

**React · JavaScript · JSON · Vercel**

---

## 🎯 Business Objectives

- Improve inventory accuracy and visibility.
- Standardize product and inventory information.
- Improve warehouse organization and stock control.
- Increase the use of ERP-generated information.
- Analyze sales and product profitability.
- Identify stockouts, slow-moving products, and high-rotation products.
- Support purchasing decisions using historical sales and inventory data.
- Identify opportunities to increase sales and improve margins.
- Reduce manual reporting and data consolidation.
- Build an interactive Business Intelligence solution for management and decision support.
- Digitize customer-facing processes through web-based tools.

---

## 🔎 Business Analysis

### Key Areas Analyzed

- Inventory management
- Warehouse organization
- Sales performance
- Product classification
- Product profitability
- Purchasing processes
- Customer activity
- ERP utilization
- Operational reporting
- Data accessibility
- Digital ordering processes

### Key Challenges Identified

- Inconsistent product naming and classification.
- Limited visibility into real-time inventory information.
- Manual stock verification and reconciliation.
- Fragmented operational information.
- Underutilization of ERP data.
- Difficulty identifying slow-moving and critical-stock products.
- Limited analytical support for purchasing decisions.
- Manual reporting and data consolidation.
- Limited digital tools for customer product discovery and ordering.

---

## 🏭 Inventory & Operations Transformation

A significant part of the project focused on improving inventory organization and operational control.

Key activities included:

- Product categorization and standardization.
- Warehouse zoning and organization.
- Inventory counting and reconciliation.
- Identification of critical stock.
- Analysis of inventory discrepancies.
- Review of ERP inventory capabilities.
- Evaluation of stock rotation and product availability.

These activities established a more structured foundation for the subsequent data analytics, Business Intelligence, and digital transformation work.

---

## 🗄️ Data & ERP Integration

The project evolved from manually managed inventory information toward structured analysis using ERP data.

The existing ERP system, MrCloud, provides access to operational and transactional information through a MySQL database.

The database contains information related to:

- Products
- Product categories and families
- Inventory by warehouse
- Sales documents
- Sales details
- Purchases
- Suppliers
- Customers
- Prices
- Units of measure
- Inventory movements
- Returns
- Cash operations

SQL is being used to transform the ERP data into analytical datasets and reusable views before connecting the information to Power BI.

Structured ERP-generated data is also used to support the digital product catalog, creating a connection between operational data and customer-facing digital tools.

### Data Architecture

```text
MrCloud ERP
     ↓
MySQL Database
     ↓
SQL Queries / Views
     ↓
 ┌───────────────────────┐
 ↓                       ↓
Power BI              JSON Data
 ↓                       ↓
Business Intelligence   Digital Product
Dashboard               Catalog
 ↓                       ↓
Decision Support      Customer Ordering
