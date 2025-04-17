/* A restaurant owner and his chef want to put out a new Italian special on the menu. 
They want it to be exclusive to a time slot to heighten its popularity, but
they don't know when they should offer it or how much to price it. So they came to 
me for answers */

-- Getting familiar with the data

SELECT * FROM restaurant_db.menu_items;
SELECT * FROM restaurant_db.order_details;

SELECT COUNT(*), category
FROM menu_items
GROUP BY category;

SELECT COUNT(*)
FROM order_details;

-- What are the most expensive and cheapest dishes on the menu? 

SELECT item_name, price 
FROM menu_items
ORDER BY price DESC; 
    -- Shrimp Scampi at $19.95 is the most expensive.

SELECT item_name, price 
FROM menu_items
ORDER BY price ASC;
    -- Edamame at $5.00 is the least expensive.

/* How many Italian dishes are on the menu? What are the least
and most expensive Italian dishes on the menu? */

SELECT category,
       Count(item_name) AS count_of_items 
FROM menu_items 
WHERE category = 'Italian';

-- There are 9 Italian dishes on the menu 

-- What's the percentage of Italian dishes on the menu 

SELECT
    ROUND(SUM(CASE WHEN category = 'Italian' THEN 1 ELSE 0 END)/COUNT(*) * 100,1) AS italian_percentage,
    ROUND(SUM(CASE WHEN category <> 'Italian' THEN 1 ELSE 0 END)/COUNT(*) * 100,1)  AS non_italian_percentage
FROM Menu_items;

-- 28.1% of menu items are Italian while 71.9% are not  

-- What is the impact of Italian dishes on total sales for the quarter

WITH cat_ranks AS
    (SELECT category, SUM(price)/1000 revenue_in_k
     FROM order_details od
     LEFT JOIN menu_items mi ON od.item_id = mi.menu_item_id
     GROUP BY category)

SELECT 
    category,
    ROUND(revenue_in_k,2) AS Revenue_by_thousands,
    ROUND((revenue_in_k / SUM(revenue_in_k) OVER()) * 100,2) AS percent_contribution
FROM cat_ranks
WHERE category IS NOT NULL
ORDER BY (revenue_in_k / SUM(revenue_in_k) OVER()) * 100 DESC;

-- Great! Italian dishes are the leading contributor to restaurant sales, with 31% of total sales 
-- coming from Italian dishes 

-- What time are our customers eating the most on weekdays, and what dishes do they usually order during happy hour?

SELECT order_id, order_time, order_date, item_id
FROM order_details
ORDER BY order_time ASC;

SELECT order_id, order_time, order_date, item_id
FROM order_details
ORDER BY order_time DESC;

-- With this we see when the store usually gets its first orders. The earliest is around 10:50 AM 
-- and the latest order comes in at 11:05 PM, roughly 12 hours from open to close.

SELECT order_id, order_time, order_date, item_id,
       CASE WHEN order_time BETWEEN '10:00:00' AND '15:59:59' THEN 'lunch_hours' 
            WHEN order_time BETWEEN '16:00:00' AND '18:59:59' THEN 'happy_hours'
            WHEN order_time BETWEEN '19:00:00' AND '23:59:59' THEN 'dinner_hours' 
            ELSE 'error' END AS order_hours 
FROM order_details;

-- With this we break the data up into time sections to gain more insights on when customers order

WITH time_data AS
    (SELECT order_id, order_time, order_date, item_id,
            CASE WHEN order_time BETWEEN '10:00:00' AND '15:59:59' THEN 'lunch_hours' 
                 WHEN order_time BETWEEN '16:00:00' AND '18:59:59' THEN 'happy_hours'
                 WHEN order_time BETWEEN '19:00:00' AND '23:59:59' THEN 'dinner_hours' 
                 ELSE 'error' END AS order_hours 
     FROM order_details) 

SELECT order_hours, COUNT(item_id)
FROM time_data 
GROUP BY order_hours;

-- With this we find that the lunch hour time block is the most popular in terms of items ordered. 
-- But the sum of items doesn’t equal 12,234. There are 137 entries that have NULL item IDs — this is something 
-- I would bring up to the stakeholder.

WITH time_data AS
    (SELECT order_id, order_time, order_date, item_id,
            CASE WHEN order_time BETWEEN '10:00:00' AND '15:59:59' THEN 'lunch_hours' 
                 WHEN order_time BETWEEN '16:00:00' AND '18:59:59' THEN 'happy_hours'
                 WHEN order_time BETWEEN '19:00:00' AND '23:59:59' THEN 'dinner_hours' 
                 ELSE 'error' END AS order_hours 
     FROM order_details) 

SELECT td.order_hours, mi.category, COUNT(td.item_id),
       DENSE_RANK() OVER (PARTITION BY order_hours ORDER BY COUNT(td.item_id) DESC) AS RANKING 
FROM time_data td
JOIN menu_items mi ON td.item_id = mi.menu_item_id
GROUP BY td.order_hours, mi.category
ORDER BY td.order_hours, COUNT(td.item_id) DESC, category;

-- Although Italian dishes are the leader in terms of sales, it's Asian dishes that are ordered the most
-- in every 'order hour slot', including happy hour. 
-- To introduce a new special, it would be ideal to offer it during the lunch hour. 

-- Now we want to look at item pricing to see what price the new special should be. 

SELECT category, AVG(price), MAX(price), MIN(price) 
FROM menu_items m
JOIN order_details o ON m.menu_item_id = o.item_id
GROUP BY category
ORDER BY AVG(price) DESC;

-- Our menu prices AVG, MIN, MAX by category from orders 

SELECT COUNT(price) AS times_spent, price
FROM menu_items m
JOIN order_details o ON m.menu_item_id = o.item_id
WHERE category = 'Italian'
GROUP BY Price
ORDER BY COUNT(price) DESC;

-- What price do people commonly spend on Italian dishes 

/* What we found so far: our Italian dishes are the most expensive on the menu, and they are most purchased within the lunch time block. 
Customer spending on Italian dishes is between $16 and $18 per dish. */

-- So now we can tell our chef and restaurant owner when the special should be available and what price range they should consider.
-- We can also show our stakeholders that Asian dishes are the most popular in terms of orders across all metrics and should consider 
-- testing a higher-priced Asian dish special in the near future.
