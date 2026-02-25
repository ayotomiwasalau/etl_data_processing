-- Raw Tables
CREATE TABLE raw_sales_order_header (
    salesorderid INT,
    orderdate TEXT,
    shipdate TEXT,
    onlineorderflag BOOLEAN,
    accountnumber TEXT,
    customerid INT,
    salespersonid INT,
    freight NUMERIC
);

CREATE TABLE raw_products (
    productid INT,
    productdesc TEXT,
    productnumber TEXT,
    makeflag BOOLEAN,
    color TEXT,
    safetystocklevel INT,
    reorderpoint INT,
    standardcost NUMERIC,
    listprice NUMERIC,
    Size TEXT,
    sizeunitmeasurecode TEXT,
    weight NUMERIC,
    weightunitmeasurecode TEXT,
    productcategoryname TEXT,
    productsubcategoryname TEXT
);

CREATE TABLE raw_sales_order_detail (
    salesorderid INT,
    salesorderdetailid INT,
    orderqty INT,
    productid INT,
    unitprice NUMERIC,
    unitpricediscount NUMERIC
);