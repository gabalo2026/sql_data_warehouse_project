/*
===============================================================================
DDL Script: Create Gold Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'gold' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'gold' Tables
===============================================================================
*/

USE DataWarehouse;
GO

DROP TABLE IF EXISTS gold.dim_customers
GO

CREATE TABLE gold.dim_customers (
	customer_key INT,
	customer_id INT,
	customer_number NVARCHAR(50),
	first_name NVARCHAR(50),
	last_name NVARCHAR(50),
	country NVARCHAR(50),
	marital_status NVARCHAR(50),
	gender NVARCHAR(50),
	birthdate DATE,
	create_date DATE
);
GO

DROP TABLE IF EXISTS gold.dim_products
GO

CREATE TABLE gold.dim_products (
	product_key INT,
	product_id INT,
	product_number NVARCHAR(50),
	product_name NVARCHAR(50),
	category_id NVARCHAR(50),
	category NVARCHAR(50),
	subcategory NVARCHAR(50),
	maintenance NVARCHAR(50),
	cost INT,
	product_line NVARCHAR(50),
	start_date DATE
);
GO

DROP TABLE IF EXISTS gold.dim_date
GO

CREATE TABLE gold.dim_date (
	date_key INT PRIMARY KEY,
	date_value DATE NOT NULL UNIQUE,
	year INT,
	quarter VARCHAR(8),      -- 2024-Q01
	month VARCHAR(8),        -- 2024-M01
	week VARCHAR(8)          -- 2024-W01
);
GO

DROP TABLE IF EXISTS gold.fact_sales
GO

CREATE TABLE gold.fact_sales (
	order_number NVARCHAR(50),
	product_key INT,
	customer_key INT,
	order_date_key INT,
	shipping_date_key INT,
	due_date_key INT,
	sales_amount INT,
	quantity INT,
	price INT
);
GO
