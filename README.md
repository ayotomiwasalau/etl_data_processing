## Client Sales & Product Data Pipeline

### Project Goal

The goal of this project is to build a simple, reproducible data pipeline that:
- **Ingests raw sales orders and product data** into PostgreSQL
- **Cleans and structures the data** into store-level tables with correct data types and keys
- **Creates published/analysis-ready tables** that combine sales and product attributes
- **Answers key business questions** about revenue and operational performance using SQL analysis queries

The final outputs are:
- A **`publish_product`** table with a clean product master and standardized categories
- A **`publish_orders`** table with enriched order lines and business metrics (e.g., lead time, extended price)
- SQL queries that compute:
  - The **top color by revenue per year**
  - The **average lead time per product category**

---

### Data Preparation & Transformation Steps

#### 1. Create Raw Tables (Landing Layer)
**File:** `data_loading.sql`

The first step is to define raw tables that mirror the structure of the source data (e.g., CSV files).

- **`raw_sales_order_header`**
  - Contains header-level fields for each sales order, including:
    - `salesorderid`, `orderdate`, `shipdate`, `onlineorderflag`, `accountnumber`, `customerid`, `salespersonid`, `freight`
  - Dates are initially stored as **text**.

- **`raw_products`**
  - Contains product master data:
    - Core identity and description fields: `productid`, `productdesc`, `productnumber`, `makeflag`, `color`
    - Inventory and pricing: `safetystocklevel`, `reorderpoint`, `standardcost`, `listprice`
    - Size/weight attributes and units: `"Size"`, `sizeunitmeasurecode`, `weight`, `weightunitmeasurecode`
    - Hierarchy: `productcategoryname`, `productsubcategoryname`

- **`raw_sales_order_detail`**
  - Contains line-level order data:
    - `salesorderid`, `salesorderdetailid`, `orderqty`, `productid`, `unitprice`, `unitpricediscount`

> At this stage, the raw tables are a direct, minimally processed landing of the source data.

---

#### 2. Create Store Tables (Structured Layer)
**File:** `data_review_and_storage.sql`

The second step is to create **store** tables from the raw layer, converting data types and adding keys:

- **`store_sales_order_header`**
  - Created **from `raw_sales_order_header`**.
  - Converts `orderdate` and `shipdate` from text to proper `DATE` type using `TO_DATE(orderdate, 'YYYY-MM-DD')`.
  - Keeps the other business fields unchanged.
  - Adds a **primary key** on `salesorderid`.

- **`store_sales_order_detail`**
  - Created **from `raw_sales_order_detail`**, copying all columns.
  - Adds a **primary key** on `salesorderdetailid`.
  - Adds a **foreign key** referencing `store_sales_order_header(salesorderid)`.

- **`store_products`**
  - Created **from `raw_product` / `raw_products`**, copying all columns for further transformation.

This layer ensures:
- Cleaned and typed dates
- Proper referential integrity between header and detail
- A stable base for downstream transformations

---

#### 3. Build the Product Master (Publish Layer)
**File:** `product_master_transformation.sql`

Next, we create a curated product master table with standardized product categories:

- **`publish_product`**
  - Source: `store_products`
  - Columns:
    - Keeps key fields such as `productid`, `productdesc`, `productnumber`, `makeflag`, `productsubcategoryname`, size/weight/pricing fields, etc.
    - **Cleans `color`**:
      - `COALESCE(NULLIF(color, ''), 'N/A') AS color` ensures missing or empty colors become `'N/A'`.
    - **Standardizes `productcategoryname`** with a CASE expression:
      - Uses `productcategoryname` if present.
      - Maps certain subcategories to standard roll-up categories:
        - `('Gloves','Shorts','Socks','Tights','Vests')` → `'Clothing'`
        - `('Locks','Lights','Headsets','Helmets','Pedals','Pumps')` → `'Accessories'`
        - Subcategories containing `'Frames'` or in `('Wheels','Saddles')` → `'Components'`
      - Everything else falls back to `'N/A'`.

This step produces a **clean, analysis-ready product dimension** with consistent category labels.

---

#### 4. Build the Orders Fact Table (Publish Layer)
**File:** `sales_order_transformations.sql`

We then create an enriched orders fact table by joining header and detail and deriving metrics:

- **`publish_orders`**
  - Source: `store_sales_order_detail` (`d`) joined to `store_sales_order_header` (`h`) on `salesorderid`.
  - Selected fields:
    - All line-level detail fields from `d.*`.
    - Header fields: `orderdate`, `shipdate`, `onlineorderflag`, `accountnumber`, `customerid`, `salespersonid`, and `freight` (renamed to `totalorderfreight`).
  - Derived metrics:
    - **`leadtimeinbusinessdays`**:
      - Computed using `generate_series(h.orderdate, h.shipdate, interval '1 day')` and counting only weekdays (`EXTRACT(DOW) NOT IN (0,6)`).
      - Represents shipping lead time in **business days**.
    - **`totallineextendedprice`**:
      - `orderqty * (unitprice - unitpricediscount)`
      - Represents line-level extended revenue after discounts.

This table is the main **fact table** used for revenue and operational performance analysis.

---

### Analysis Queries (Business Questions)
**File:** `analysis_questions.sql`

With `publish_orders` and `publish_product` in place, we can answer key business questions.

#### Question 1: Top Color by Revenue per Year

**Goal:** Identify, for each year, which product color generated the highest total revenue.

- A CTE `revenue_cte`:
  - Joins `publish_orders` (`o`) with `publish_product` (`p`) on `productid`.
  - Groups by `EXTRACT(YEAR FROM orderdate)` and `p.color`.
  - Computes `SUM(totallineextendedprice)` as `total_revenue`.
- Outer query:
  - Applies `RANK() OVER (PARTITION BY year ORDER BY total_revenue DESC)` to rank colors by revenue within each year.
  - Filters to `WHERE rnk = 1` to keep **only the top color for each year**.

#### Question 2: Average Lead Time by Product Category

**Goal:** Understand which product categories have the longest or shortest shipping lead times.

- Joins `publish_orders` (`o`) to `publish_product` (`p`) on `productid`.
- Groups by `p.productcategoryname`.
- Computes `AVG(o.leadtimeinbusinessdays)` as `avg_leadtime`.
- Orders results by `avg_leadtime DESC` to highlight categories with the longest lead times.

These queries feed into the answers documented in `analysis_answer.md`.

---

### How to Run This Project

1. **Create the raw tables**  
   Run the SQL in `data_loading.sql` to create the `raw_*` tables. Then load your CSV data (e.g., `products.csv`) into the corresponding raw tables using your preferred method (COPY, GUI, etc.).

2. **Create the store tables**  
   Run `data_review_and_storage.sql` to:
   - Create `store_sales_order_header`, `store_sales_order_detail`, and `store_products`
   - Apply primary and foreign key constraints
   - Convert date columns to proper `DATE` types

3. **Create the publish tables**  
   - Run `product_master_transformation.sql` to build `publish_product`.
   - Run `sales_order_transformations.sql` to build `publish_orders`.

4. **Run analysis queries**  
   - Execute `analysis_questions.sql` to generate the analytics outputs:
     - Top color by revenue per year
     - Average lead time by product category
   - Save or visualize the results as needed. The sample outputs are summarized in `analysis_answer.md`.

---

### Summary

This project demonstrates a small but complete analytics pipeline:
- **Raw layer** for landing data
- **Store layer** for cleaned, typed, and relationally consistent tables
- **Publish layer** for curated dimension and fact tables
- **Analysis layer** with business-focused SQL queries

You can extend this pattern by adding more transformations, additional KPIs, or connecting BI tools to the publish tables for dashboards and reports.