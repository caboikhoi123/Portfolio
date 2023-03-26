USE salesdataset
SELECT * FROM dbo.customers_dataset
SELECT * FROM dbo.orders_dataset
SELECT * FROM dbo.order_payments_dataset
SELECT * FROM dbo.order_items_dataset
SELECT * FROM dbo.order_reviews_dataset
SELECT * FROM dbo.products_dataset
SELECT * FROM dbo.product_category_name_translation

-- Total Sales and Orders
-- Total Sales and Orders by Time
-- Total Sales by City
-- Total Order value by Number of Order
-- Total Order value by Number of Items per Order
-- Average spending per Order
-- Average spending per Order by Number of Order 
-- Item price by sales/orders
-- Best sellers

/* 1. BUSINESS OVERVIEW*/ 

-- Total orders
SELECT DISTINCT COUNT(order_id) AS total_orders
FROM dbo.orders_dataset

-- Total sales
SELECT SUM(payment_value) AS total_value 
FROM dbo.order_payments_dataset

-- Total sales by order-id
SELECT order_id, SUM(payment_value) AS total_value 
FROM dbo.order_payments_dataset
GROUP BY order_id
ORDER BY SUM(payment_value) DESC

-- Total order by Period
SELECT MONTH(order_delivered_customer_date) month_2017, 
        COUNT(a.order_id) total_month_orders
FROM orders_dataset a 
RIGHT join order_payments_dataset b 
ON a.order_id = b.order_id 
WHERE a.order_id NOT IN 
    (SELECT order_id FROM orders_dataset WHERE order_delivered_customer_date IS NULL)
group by MONTH(order_delivered_customer_date)

-- Total orders & value by Month 2017
SELECT MONTH(order_delivered_customer_date) month_2017, 
        COUNT(a.order_id) total_month_orders,
        SUM(payment_value) total_month_revenue
FROM orders_dataset a 
RIGHT join order_payments_dataset b 
ON a.order_id = b.order_id 
WHERE a.order_id NOT IN 
    (SELECT order_id FROM orders_dataset WHERE order_delivered_customer_date IS NULL)
group by MONTH(order_delivered_customer_date)

-- Total orders & value by Year
SELECT YEAR(order_delivered_customer_date) year, 
        COUNT(a.order_id) total_orders,
        SUM(payment_value) total_revenue
FROM orders_dataset a 
RIGHT join order_payments_dataset b 
ON a.order_id = b.order_id 
WHERE a.order_id NOT IN 
    (SELECT order_id FROM orders_dataset WHERE order_delivered_customer_date IS NULL)
group by YEAR(order_delivered_customer_date)

-- Average amount spent 

SELECT AVG(payment_value) FROM order_payments_dataset

-- Sales by City
SELECT c.customer_city, SUM(a. payment_value) AS revenue, COUNT(b.order_id) AS quantity
FROM dbo.order_payments_dataset a 
LEFT JOIN dbo.orders_dataset b
    ON a.order_id = b.order_id
LEFT JOIN dbo.customers_dataset c
    ON b.customer_id = c.customer_id
GROUP BY customer_city
ORDER BY SUM(a. payment_value) DESC

-- Order count per customer (How many orders has a customers ordered) 
SELECT b.customer_unique_id, COUNT(a.order_id) AS order_count
FROM dbo.orders_dataset a
RIGHT JOIN dbo.customers_dataset b
    ON a.customer_id = b.customer_id
GROUP BY b.customer_unique_id
--HAVING COUNT(a.order_id) > 3
ORDER BY COUNT(a.order_id) DESC

-- Items count per order
SELECT order_id, COUNT(order_item_id) AS item_count
FROM dbo.order_items_dataset
GROUP BY order_id
ORDER BY COUNT(order_item_id) DESC

-- Order count per customer (How many orders has a customers ordered)
WITH order_count AS (
    SELECT b.customer_unique_id, 
            COUNT(a.order_id) AS order_count
    FROM dbo.orders_dataset a
    RIGHT JOIN dbo.customers_dataset b
        ON a.customer_id = b.customer_id
    GROUP BY b.customer_unique_id
    --ORDER BY COUNT(a.order_id) DESC 
),
average_spending AS (
    SELECT c.customer_unique_id,
            AVG(p.payment_value) AS average_value
    FROM order_payments_dataset p
    LEFT JOIN orders_dataset d 
        ON p.order_id = d.order_id
    LEFT JOIN customers_dataset c 
        ON d.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
    --ORDER BY AVG(p.payment_value) DESC
)
SELECT o_c.customer_unique_id, o_c.order_count, a_s.average_value
FROM order_count o_c
LEFT JOIN average_spending a_s
    ON o_c.customer_unique_id = a_s.customer_unique_id
ORDER BY o_c.order_count DESC

-- Revenue by payment
SELECT payment_type, COUNT(order_id) AS count, SUM(payment_value) AS total
FROM order_payments_dataset
GROUP BY payment_type
ORDER BY SUM(payment_value) DESC

-- Top selling items
SELECT product_category_name_translation.column2 AS product, COUNT(order_items_dataset.product_id) AS count_product, SUM(price) AS total_price
FROM order_items_dataset
LEFT JOIN products_dataset
    ON order_items_dataset.product_id = products_dataset.product_id
LEFT JOIN product_category_name_translation
    ON products_dataset.product_category_name = product_category_name_translation.column1
GROUP BY product_category_name_translation.column2
--ORDER BY COUNT(order_items_dataset.product_id) DESC
ORDER BY SUM(price) DESC

-- Top seller
SELECT seller_id, COUNT(seller_id) AS count, SUM(price) AS amount
FROM order_items_dataset
GROUP BY seller_id
ORDER BY COUNT(seller_id) DESC


/* 2. CUSTOMER SATISFACTION*/

-- Number of reviews
SELECT COUNT(review_score) AS count
FROM dbo.order_reviews_dataset

SELECT review_score, COUNT(review_score) AS count
FROM dbo.order_reviews_dataset
GROUP BY review_score
ORDER BY review_score

-- Average ratings
WITH a AS 
(
    SELECT review_score, COUNT(review_score) AS count, review_score*COUNT(review_score) AS weighted
    FROM dbo.order_reviews_dataset
    GROUP BY review_score
   -- ORDER BY review_score
)
SELECT SUM(weighted) / SUM(count) AS averate_rating 
FROM a

-- Which products have the highest/lowest ratigns


SELECT TOP 5 c.column2 AS product_category, 
                COUNT(r.review_score) AS count_rating, 
                ROUND(AVG(CAST(r.review_score AS FLOAT)),2) AS avg_rating
FROM dbo.order_reviews_dataset r
RIGHT JOIN dbo.order_items_dataset i
     ON r.order_id = i.order_id
RIGHT JOIN products_dataset p
    ON i.product_id = p.product_id
RIGHT JOIN dbo.product_category_name_translation c
    ON p.product_category_name = c.column1
GROUP BY c.column2
ORDER BY ROUND(AVG(CAST(r.review_score AS FLOAT)),2) DESC


SELECT TOP 6 c.column2 AS product_category, 
                COUNT(r.review_score) AS count_rating, 
                ROUND(AVG(CAST(r.review_score AS FLOAT)),2) AS avg_rating
FROM dbo.order_reviews_dataset r
RIGHT JOIN dbo.order_items_dataset i
     ON r.order_id = i.order_id
RIGHT JOIN products_dataset p
    ON i.product_id = p.product_id
RIGHT JOIN dbo.product_category_name_translation c
    ON p.product_category_name = c.column1
GROUP BY c.column2
ORDER BY ROUND(AVG(CAST(r.review_score AS FLOAT)),2)


-- Which seller have the highest/lowest ratings

SELECT i.seller_id, 
        COUNT(r.review_score) AS count_rating, 
        ROUND(AVG(CAST(r.review_score AS FLOAT)),2) AS avg_rating
FROM dbo.order_reviews_dataset r
RIGHT JOIN dbo.order_items_dataset i
     ON r.order_id = i.order_id
GROUP BY i.seller_id
ORDER BY ROUND(AVG(CAST(r.review_score AS FLOAT)),2) DESC

SELECT i.seller_id, 
        COUNT(r.review_score) AS count_rating, 
        ROUND(AVG(CAST(r.review_score AS FLOAT)),2) AS avg_rating
FROM dbo.order_reviews_dataset r
RIGHT JOIN dbo.order_items_dataset i
     ON r.order_id = i.order_id
GROUP BY i.seller_id
ORDER BY ROUND(AVG(CAST(r.review_score AS FLOAT)),2)


-- Which orders have the highest/lowest ratings

SELECT order_id, 
    COUNT(review_score) AS count_rating, 
    ROUND(AVG(CAST(review_score AS FLOAT)),2) AS avg_rating
FROM dbo.order_reviews_dataset
GROUP BY order_id
ORDER BY ROUND(AVG(CAST(review_score AS FLOAT)),2) DESC

SELECT order_id, 
    COUNT(review_score) AS count_rating, 
    ROUND(AVG(CAST(review_score AS FLOAT)),2) AS avg_rating
FROM dbo.order_reviews_dataset
GROUP BY order_id
ORDER BY ROUND(AVG(CAST(review_score AS FLOAT)),2) 

-- 

/* 3. RFM*/

DROP TABLE IF EXISTS #rfm_table;
WITH rfm AS 
(
    SELECT c.customer_unique_id, 
            COUNT(o.order_id) AS frequency,
            ROUND(SUM(payment_value),1) AS monetary,
            AVG(payment_value) AS avg_monetary,
            MAX(order_purchase_timestamp) AS lasted_order_date,
            (SELECT MAX(order_purchase_timestamp) FROM  dbo.orders_dataset) AS max_order_date,
            (DATEDIFF(DD, MAX(order_purchase_timestamp),(SELECT MAX(order_purchase_timestamp) FROM  dbo.orders_dataset))) AS recency
    FROM dbo.orders_dataset o
    LEFT JOIN dbo.customers_dataset c
        ON o.customer_id = c.customer_id
    LEFT JOIN dbo.order_payments_dataset p 
        ON o.order_id = p.order_id
    GROUP BY c.customer_unique_id
) ,
rfm_calc AS
(
    SELECT *, 
            NTILE(3) OVER (ORDER BY frequency) AS rfm_frequency,
            NTILE(3) OVER (ORDER BY monetary) AS rfm_monetary,
            NTILE(3) OVER (ORDER BY recency DESC) AS rfm_recency,
            CONCAT(NTILE(3) OVER (ORDER BY frequency), NTILE(3) OVER (ORDER BY monetary), NTILE(3) OVER (ORDER BY recency))AS rfm_rank 
    FROM rfm
)
SELECT *
INTO #rfm_table
FROM rfm_calc


SELECT customer_unique_id, rfm_recency, rfm_frequency, rfm_monetary, rfm_rank,
        CASE 
        WHEN rfm_rank IN (111,112,121,122) THEN 'Churned_customers'
        WHEN rfm_rank IN (113,123,131,132,133) THEN 'Slipping_customers'
        WHEN rfm_rank IN (222, 223, 311, 312, 313) THEN 'New_customers'
        WHEN rfm_rank IN (211, 212, 213, 221) THEN 'Potential_churn'
        WHEN rfm_rank IN (232, 233, 231) THEN 'Active'
        WHEN rfm_rank IN (321, 322, 323, 331, 332, 333) THEN 'Loyal'
        END rfm_segment
FROM #rfm_table

/* 4. COHORT*/ 

-- Select purchase week per user
-- Select first purchase week per user
DROP TABLE IF EXISTS #cohort_table; 
WITH a AS 
(
    SELECT c.customer_unique_id,
            DATEPART(WEEK, order_purchase_timestamp) AS purchase_week
    FROM orders_dataset o
    LEFT JOIN customers_dataset c
        ON o.customer_id = c.customer_id
) ,
b AS (
    SELECT c.customer_unique_id,
            MIN(datepart(week, order_purchase_timestamp)) AS first_week
    FROM orders_dataset o
    LEFT JOIN customers_dataset c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
) ,
c AS (
    SELECT a.customer_unique_id, a.purchase_week, b.first_week, (a.purchase_week - b.first_week) AS week_number
    FROM a 
    LEFT JOIN b 
    ON a.customer_unique_id = b.customer_unique_id
)
SELECT * 
INTO #cohort_table
FROM c

SELECT DISTINCT week_number
FROM #cohort_table
ORDER BY week_number

  
/* 5. RECOMMENDATION*/ 
-- Deploy 