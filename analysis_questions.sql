-- Question 1: What is the total revenue for each product category?
WITH revenue_cte AS (
    SELECT
        EXTRACT(YEAR FROM orderdate) AS year,
        p.color,
        SUM(totallineextendedprice) AS total_revenue
    FROM publish_orders o
    JOIN publish_product p
    ON o.productid = p.productid
    GROUP BY 1,2
)

SELECT *
FROM (
    SELECT *,
           RANK() OVER (PARTITION BY year ORDER BY total_revenue DESC) rnk
    FROM revenue_cte
) x
WHERE rnk = 1;


-- Question 2: What is the average lead time for each product category?

SELECT
    p.productcategoryname,
    AVG(o.leadtimeinbusinessdays) AS avg_leadtime
FROM publish_orders o
JOIN publish_product p
ON o.productid = p.productid
GROUP BY p.productcategoryname
ORDER BY avg_leadtime DESC;