CREATE TABLE publish_orders AS
SELECT
    d.*,

    h.orderdate,
    h.shipdate,
    h.onlineorderflag,
    h.accountnumber,
    h.customerid,
    h.salespersonid,
    h.freight AS totalorderfreight,
    (
        SELECT COUNT(*)
        FROM generate_series(h.orderdate, h.shipdate, interval '1 day') AS g(day)
        WHERE EXTRACT(DOW FROM g.day) NOT IN (0,6)
    ) AS leadtimeinbusinessdays,

    d.orderqty * (d.unitprice - d.unitpricediscount)
        AS totallineextendedprice

FROM store_sales_order_detail d
JOIN store_sales_order_header h
ON d.salesorderid = h.salesorderid;