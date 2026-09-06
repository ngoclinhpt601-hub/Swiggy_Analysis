SELECT * FROM Swiggy_Data
-- Data cleaning and validation
-- Null Check 
-- Check null count --
 DECLARE @SQL NVARCHAR(MAX) = '';

 SELECT @SQL = STRING_AGG(
	'SELECT ''' + COLUMN_NAME + ''' AS ColumnName,
	COUNT(*) AS NullCount
	FROM ' + QUOTENAME(TABLE_SCHEMA) + '.Swiggy_Data
	WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
	' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Swiggy_Data';

-- Execute the dynamic SQL -- 
EXEC sp_executesql @SQL

-- Blank or empty strings
SELECT *
FROM Swiggy_Data
WHERE State ='' 
	OR City ='' 
	OR Restaurant_Name =''
	OR Location ='' 
	OR Category =''
	OR Dish_Name =''

-- Duplicate detection
SELECT State, City, Restaurant_Name, Location,
Category, Dish_Name, Price_INR, Rating, Rating_Count,
COUNT (*)
FROM Swiggy_Data
GROUP BY State, City, Restaurant_Name, Location,
Category, Dish_Name, Price_INR, Rating, Rating_Count
HAVING COUNT(*) > 1

-- Delete duplication 
WITH CTE AS (
	SELECT *,
		ROW_NUMBER() OVER (
		PARTITION BY state, city, restaurant_name, location,
		category, dish_name, price_INR, rating, rating_count 
		ORDER BY (SELECT NULL) 
		) AS Row_Num
		FROM Swiggy_data)
DELETE FROM CTE WHERE Row_Num >1

-- Creating Schema
-- Dimennsion Tables
-- Data Table
-- dim_date
CREATE TABLE dim_date (
	date_id INT IDENTITY(1,1) PRIMARY KEY,
	full_date DATE,
	year INT,
	month INT,
	month_name varchar(20),
	quarter INT,
	day INT,
	week INT 
	)
SELECT * FROM dim_date;

-- dim_location
CREATE TABLE dim_location (
	location_id INT IDENTITY(1,1) PRIMARY KEY,
	state VARCHAR(100),
	location VARCHAR(200),
	city  VARCHAR(100),
	)
SELECT * FROM dim_location;

-- dim_restaurant
CREATE TABLE dim_restaurant (
	restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
	restaurant_name VARCHAR(200)
	)
SELECT * FROM dim_restaurant;

-- dim_category 
CREATE TABLE dim_category (
	category_id INT IDENTITY(1,1) PRIMARY KEY,
	category VARCHAR(200)
	)
SELECT * FROM dim_category;

-- dim_dish
CREATE TABLE dim_dish (
	dish_id INT IDENTITY(1,1) PRIMARY KEY,
	dish_name VARCHAR(200)
	)
SELECT * FROM dim_dish

SELECT * FROM Swiggy_Data

-- Fact Table
CREATE TABLE fact_swiggy_orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    date_id INT,
    price_INR DECIMAL(10,2),
    rating DECIMAL(4,2),
    rating_Count INT,
    location_id INT,
    restaurant_id INT,
    category_id INT,
    dish_id INT,

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
    FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
    FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
);
SELECT * FROM fact_swiggy_orders

-- INSERT DATA 
-- dim_date
INSERT INTO dim_date (full_date, year, month, month_name, 
	quarter, day, week)
SELECT DISTINCT 
	order_date,
	YEAR(order_date),
	MONTH(order_date),
	DATENAME(MONTH, order_date),
	DATEPART(QUARTER, order_date),
	DAY(order_date),
	DATEPART(WEEK, order_date)
FROM Swiggy_Data
WHERE order_date IS NOT NULL;
SELECT * FROM dim_date

-- dim_location
INSERT INTO dim_location (state, city, location)
SELECT DISTINCT 
	State,
	CIty,
	Location
FROM Swiggy_Data;
SELECT * FROM dim_location

-- dim_restaurant
INSERT INTO dim_restaurant (restaurant_name)
SELECT DISTINCT 
	Restaurant_Name
FROM Swiggy_Data;
SELECT * FROM dim_restaurant

-- dim_category
INSERT INTO dim_category (category)
SELECT DISTINCT 
	Category
FROM Swiggy_Data;
SELECT * FROM dim_category

-- dim_dish
INSERT INTO dim_dish (dish_name)
SELECT DISTINCT 
	Dish_Name
FROM Swiggy_Data;
SELECT * FROM dim_dish

-- Insert into Fact Table --
INSERT INTO fact_swiggy_orders (
	date_id, price_INR, rating, rating_Count,
	location_id, restaurant_id, category_id, dish_id
	)
SELECT 
	dd.date_id, s.price_INR, s.rating, s.rating_Count,
	dl.location_id, dr.restaurant_id, dc.category_id, dsh.dish_id
FROM Swiggy_Data s
JOIN dim_date dd
	ON dd.full_date = s.Order_Date
JOIN dim_location dl
	ON dl.state = s.State
	AND dl.city = s.City
	AND DL.location = s.Location
JOIN dim_restaurant dr
	ON dr.restaurant_name = s.Restaurant_Name
JOIN dim_category dc
	ON dc.category = s.Category
JOIN dim_dish dsh
	ON dsh.dish_name = s.Dish_Name;
SELECT * FROM fact_swiggy_orders

-- See all data table 
SELECT * FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
JOIN dim_category c ON f.category_id = c.category_id
JOIN dim_dish di ON f.dish_id = di.dish_id;


-- Basic KPIs 
-- Total Orders 
SELECT COUNT(*) AS total_orders
FROM fact_swiggy_orders

-- Total Revenue
SELECT FORMAT(SUM(CONVERT(FLOAT,price_INR))/1000000, 'N2') + 'INR Million'
	AS total_revenue
FROM fact_swiggy_orders

-- Average dish price
SELECT FORMAT(AVG(CONVERT(FLOAT,price_INR)), 'N2') + 'INR Million'
	AS average_value
FROM fact_swiggy_orders

-- Average rating 
SELECT AVG(rating) AS avg_rating
FROM fact_swiggy_orders

-- BUSINESS ANALYST  
-- Monthly Order Trends
SELECT d.year, d.month, d.month_name,
	COUNT (*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY COUNT(*) DESC

-- Monthly Revenue Trends
SELECT d.year, d.month, d.month_name,
	SUM (price_INR) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY SUM (price_INR) DESC

-- Quarterly Trend
SELECT d.year, d.quarter,
	COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.quarter
ORDER BY COUNT(*) DESC

-- Yearly Trend 
SELECT d.year,
	COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year
ORDER BY COUNT(*) DESC

-- Orders by Day of Week 
SELECT
	DATENAME(WEEKDAY, d.full_date) AS day_name,
	COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY DATENAME(WEEKDAY, d.full_date), DATEPART(WEEKDAY, d.full_date)
ORDER BY DATENAME(WEEKDAY, d.full_date)

-- Top 10 cities by order volume
SELECT TOP 10 
	l.city,
	COUNT (*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.city
ORDER BY COUNT (*) DESC

-- Top 10 cities by revenue 
SELECT TOP 10 
	l.city,
	SUM (price_INR) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.city
ORDER BY SUM (price_INR) DESC

-- Revenue contribution by states
SELECT
	l.state,
	SUM (price_INR) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.state
ORDER BY SUM (price_INR) DESC

-- Top 10 restaurant by revenue
SELECT TOP 10
	r.restaurant_name,
	SUM (price_INR) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_restaurant r ON f.location_id = r.restaurant_id
GROUP BY r.restaurant_name
ORDER BY SUM (price_INR) DESC

-- Top category by order volume
SELECT
	c.category,
	COUNT (*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_category c ON f.location_id = c.category_id
GROUP BY c.category
ORDER BY COUNT (*) DESC

-- Most ordered dishes
SELECT 
	dsh.dish_name,
	COUNT(*) AS order_count
FROM fact_swiggy_orders f
JOIN dim_dish dsh ON f.dish_id = dsh.dish_id
GROUP BY dsh.dish_name
ORDER BY COUNT(*) DESC 

-- Total revenue by State 
SELECT 
	l.state,
	SUM(price_INR) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.state
ORDER BY total_revenue DESC

-- Cuisine performance 
SELECT 
	c.category,
	COUNT(*) AS total_orders,
	AVG(CONVERT(FLOAT, f.rating)) AS avg_rating
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.category
ORDER BY total_orders DESC

-- Total Orders by Price Range
SELECT 
	CASE 
		WHEN CONVERT(FLOAT, price_INR) < 100 THEN 'Under 100'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN  100 AND 199 THEN '100 - 199'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN  200 AND 299 THEN '200 - 299'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN  300 AND 499 THEN '300 - 499'
	ELSE '500+'
END AS price_name,
COUNT (*) AS total_orders
FROM fact_swiggy_orders 
GROUP BY 
	CASE 
		WHEN CONVERT(FLOAT, price_INR) < 100 THEN 'Under 100'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN  100 AND 199 THEN '100 - 199'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN  200 AND 299 THEN '200 - 299'
		WHEN CONVERT(FLOAT, price_INR) BETWEEN  300 AND 499 THEN '300 - 499'
	ELSE '500+'
END
ORDER BY total_orders DESC 

-- Rating count distribution (1-5)
SELECT 
	rating,
	COUNT (*) AS rating_count
FROM fact_swiggy_orders
GROUP BY rating
ORDER BY rating_count DESC 
