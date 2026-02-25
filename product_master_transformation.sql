CREATE TABLE publish_product AS
SELECT
    productid,
    productdesc,
    productnumber,
    makeflag,
    COALESCE(NULLIF(color, ''), 'N/A') AS color,

    CASE
        WHEN NULLIF(productcategoryname, '') IS NOT NULL
            THEN productcategoryname

        WHEN productsubcategoryname IN 
            ('Gloves','Shorts','Socks','Tights','Vests')
            THEN 'Clothing'

        WHEN productsubcategoryname IN 
            ('Locks','Lights','Headsets','Helmets','Pedals','Pumps')
            THEN 'Accessories'

        WHEN productsubcategoryname ILIKE '%Frames%'
            OR productsubcategoryname IN ('Wheels','Saddles')
            THEN 'Components'

        ELSE 'N/A'
    END AS productcategoryname,

    productsubcategoryname,
    safetystocklevel,
    reorderpoint,
    standardcost,
    listprice,
    "Size",
    sizeunitmeasurecode,
    weight,
    weightunitmeasurecode

FROM store_products;
