-- Store Tables, Created from Raw Tables, convert the date columns to the correct data type
CREATE TABLE store_sales_order_header
AS
SELECT salesorderid, TO_DATE(orderdate, 'YYYY-MM-DD') AS orderdate, TO_DATE(shipdate, 'YYYY-MM-DD') AS shipdate, onlineorderflag, accountnumber, customerid, salespersonid, freight
FROM raw_sales_order_header;

CREATE TABLE store_sales_order_detail
AS
SELECT *
FROM raw_sales_order_detail;

CREATE TABLE store_products
AS
SELECT *
FROM raw_products;

-- Primary Keys and Foreign Keys
ALTER TABLE store_sales_order_header
ADD PRIMARY KEY (salesorderid);

ALTER TABLE store_sales_order_detail
ADD PRIMARY KEY (salesorderdetailid);

ALTER TABLE store_sales_order_detail
ADD FOREIGN KEY (salesorderid)
REFERENCES store_sales_order_header(salesorderid);
