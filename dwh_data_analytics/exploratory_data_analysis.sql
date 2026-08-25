--======================================================================
-- Database exploration
--======================================================================

-- Explore all objects in the database
SELECT * 
FROM INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- Explore all columns in the database
SELECT * 
FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_NAME = 'dim_customers' -- Query a specific table
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;

--======================================================================
-- Dimension exploration
--======================================================================

-- Explore all countries our customers come from
SELECT DISTINCT country 
FROM gold.dim_customers
ORDER BY country;

-- Explore all categories "The major divisions"
SELECT DISTINCT category
FROM gold.dim_products
ORDER BY category;

-- Get more details: include subcategory
SELECT DISTINCT category, subcategory
FROM gold.dim_products
ORDER BY category, subcategory;

-- Full picture: include product_name
SELECT DISTINCT category, subcategory, product_name
FROM gold.dim_products
ORDER BY category, subcategory, product_name;

--======================================================================
-- Date exploration
--======================================================================

SELECT 
	-- Find the date of the first and last order
	MIN(do.date_value) AS first_order_date,
	MAX(do.date_value) AS last_order_date,
	-- How many years of sales are available
	DATEDIFF(YEAR, MIN(do.date_value), MAX(do.date_value)) AS order_range_years,
	-- How many months of sales are available
	DATEDIFF(MONTH, MIN(do.date_value), MAX(do.date_value)) AS order_range_months
	--MIN(ds.date_value) AS min_shipping_date,
	--MAX(ds.date_value) AS max_shipping_date,
	--MIN(dd.date_value) AS min_due_date,
	--MAX(dd.date_value) AS max_due_date
FROM gold.fact_sales f
LEFT JOIN gold.dim_date do
	ON f.order_date_key = do.date_key
LEFT JOIN gold.dim_date ds
	ON f.shipping_date_key = ds.date_key
LEFT JOIN gold.dim_date dd
	ON f.due_date_key = dd.date_key

-- Find the youngest and the oldest customer
SELECT 
	MIN(birthdate) AS oldest_birthdate,
	DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_age,
	MAX(birthdate) AS youngest_birthdate,
	DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers;

--======================================================================
-- Measures exploration
--======================================================================

SELECT 
	-- Find the total sales
	SUM(sales_amount) AS total_sales,
	-- Find how many items are sold
	SUM(quantity) AS total_quantity,
	-- Find the average selling price
	AVG(price) AS avg_price,
	-- Find the total number of orders
	COUNT(order_number) AS total_orders,
	COUNT(DISTINCT order_number) AS total_distinct_orders
FROM gold.fact_sales

-- Find the total number of products
SELECT 
	COUNT(product_key) AS total_products,
	COUNT(DISTINCT product_key) AS total_distinct_products
FROM gold.dim_products

-- Find the total number of customers
SELECT 
	COUNT(customer_key) AS total_customers,
	COUNT(DISTINCT customer_key) AS total_distinct_customers
FROM gold.dim_customers

-- Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_key) AS total_customers
FROM gold.fact_sales

-- Generate a report that shows all key metrics of the business

SELECT 
	'Total sales' as measure_name,
	SUM(sales_amount) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 
	'Total quantity' as measure_name,
	SUM(quantity) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 
	'Average price' as measure_name,
	AVG(price) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 
	'Total nr. orders' as measure_name,
	COUNT(DISTINCT order_number) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 
	'Total nr. products' as measure_name,
	COUNT(product_key) AS measure_value
FROM gold.dim_products
UNION ALL
SELECT 
	'Total nr. customers' as measure_name,
	COUNT(customer_key) AS measure_value
FROM gold.dim_customers
UNION ALL
SELECT 
	'Total nr. customers with orders' as measure_name,
	COUNT(DISTINCT customer_key) AS measure_value
FROM gold.fact_sales

--======================================================================
-- Magnitude
--======================================================================

-- Find total customers by country
SELECT country, COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Find total customers by gender
SELECT gender, COUNT(customer_key) total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Find total products by category
SELECT category, COUNT(product_key) total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- What is the average costs in each category?
SELECT category, AVG(cost) AS avg_costs
FROM gold.dim_products
GROUP BY category
ORDER BY avg_costs DESC;

-- What is the total revenue generated for each category?
SELECT p.category, SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Find total revenue is generated by each customer
SELECT 
	c.customer_key, 
	c.first_name,
	c.last_name, 
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY 
	c.customer_key, 
	c.first_name,
	c.last_name
ORDER BY total_revenue DESC, c.first_name, c.last_name;

-- What is the distribution of sold items across countries?
SELECT c.country, SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;

--======================================================================
-- Ranking Analysis
--======================================================================

-- Which 5 products generate the highest revenue?
SELECT TOP 5
	p.product_name,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- Using Windows Functions
;WITH cte AS (
	SELECT 
		p.product_name,
		SUM(f.sales_amount) AS total_revenue,
		ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON p.product_key = f.product_key
	GROUP BY p.product_name
)
SELECT 
	product_name,
	total_revenue
FROM cte
WHERE rank_products < 6

-- What are the 5 worst-performing products in terms of sales?
SELECT TOP 5
	p.product_name,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue;

-- Find the top 10 customers who have generated the highest revenue
SELECT TOP 10
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
	c.customer_key,
	c.first_name,
	c.last_name
ORDER BY total_revenue DESC;

-- Find the 3 customers with the fewest orders placed
SELECT TOP 3
	c.customer_key,
	c.first_name,
	c.last_name,
	COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
	c.customer_key,
	c.first_name,
	c.last_name
ORDER BY total_orders;
