CREATE DATABASE coffeeshopdb

USE coffeeshopdb

SELECT * FROM sales
SELECT * FROM [customers ]
SELECT * FROM city
SELECT * FROM products

--1.Coffee Consumers Count
--How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
city_name, FORMAT(Population * 0.25/1000000,'N2') AS CONSUMERs, 
city_rank
FROM city
ORDER BY consumers DESC

--2.	Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
c.city_name, 
SUM(ss.total) AS sales
FROM sales AS ss
 JOIN [customers ] cs
 ON ss.customer_id = cs.customer_id
 JOIN city c 
 ON c.city_id=cs.city_id
	WHERE 
	DATEPART(YEAR,ss.sale_date)  = 2023
	AND
	DATEPART(QUARTER, ss.sale_date) = 4
GROUP BY c.city_name
ORDER BY sales DESC;
				--OR
WITH salesrevenue AS(
	SELECT c.city_name,
		DATEPART(YEAR,s.sale_date) AS years,
		DATEPART(QUARTER, s.sale_date) AS quarter,
		SUM(s.total) AS revenue 
	FROM sales s
			JOIN [customers ] cs
				ON s.customer_id = cs.customer_id
			JOIN city c 
				ON c.city_id=cs.city_id
	GROUP BY
		c.city_name,
		DATEPART(YEAR,s.sale_date),
		DATEPART(QUARTER,s.sale_date)
	)
SELECT * FROM salesrevenue 
WHERE years = 2023 AND quarter = 4
ORDER BY revenue DESC


--3.	Sales Count for Each Product
--How many units of each coffee product have been sold?
SELECT p.product_name,
COUNT(DISTINCT s.sale_id) AS product_sold
FROM products p 
LEFT JOIN sales s
ON p.product_id= s.product_id
GROUP BY 
	 p.product_name
ORDER BY 
	product_sold DESC;
							--OR--
WITH prdct AS (
	SELECT 
		product_id,
		COUNT(DISTINCT sale_id) AS product_sold
	FROM sales 
	GROUP BY 
		product_id
	)
	SELECT p.product_name,
		pt.product_sold
	FROM prdct pt
		JOIN products p
			ON p.product_id = pt.product_id
	ORDER BY 
	product_sold DESC


	
	
--4.Average Sales Amount per City
--What is the average sales amount per customer in each city
SELECT  c.city_name,COUNT(DISTINCT s.customer_id) AS total_customer,
	SUM(s.total) AS total_revenue,
	ROUND(SUM(s.total)/	COUNT(DISTINCT s.customer_id),2) as avg_sale_pr_cx
FROM sales s 
	JOIN [customers ] cs
	ON cs.customer_id=s.customer_id
	JOIN city c 
	ON c.city_id=cs.city_id
GROUP BY  
		c.city_name
ORDER BY 
	avg_sale_pr_cx DESC

					

--5.City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.

SELECT c.city_name,c.population, 
COUNT(DISTINCT cs.customer_id) AS consumers_count,
FORMAT(Population * 0.25/1000000,'N2') AS estimated_coffee_consumers 
FROM sales s 
	JOIN [customers ] cs
	ON cs.customer_id=s.customer_id
	JOIN city c 
	ON c.city_id=cs.city_id
GROUP BY  c.city_name,
		c.population
ORDER BY 
	estimated_coffee_consumers DESC
				--OR--
WITH estim_population as 
(
	SELECT 
		city_name,
		FORMAT(CONVERT(DECIMAL(10,2),(population * 0.25))/1000000, 'N2') as coffee_consumers
	FROM city
),
customers_table AS(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
		JOIN [customers ] as c
			ON c.customer_id = s.customer_id
		JOIN city as ci
			ON ci.city_id = c.city_id
	GROUP BY ci.city_name
)
SELECT 
	ct.city_name,
	ct.unique_cx,
	coffee_consumers
FROM estim_population ep
JOIN customers_table ct
ON ep.city_name = ct.city_name


--6.Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?
WITH volume AS (
	SELECT 
		s.product_id,c.city_id,
		SUM(s.total) AS sales_volume,
		DENSE_RANK() OVER (PARTITION BY c.city_id ORDER BY SUM(s.total) DESC) AS ranked
	FROM sales s 
			JOIN [customers ] cs
				ON cs.customer_id=s.customer_id
			JOIN city c 
				ON c.city_id=cs.city_id
	GROUP BY s.product_id,
			c.city_id)
			--SELECT * FROM volume
		SELECT v.product_id,c.city_name,p.product_name,
				v.sales_volume,v.ranked
			ranked FROM volume v

				JOIN city c 
					ON c.city_id=v.city_id
				JOIN products p 
					ON p.product_id = v.product_id

		WHERE v.ranked <=3

	
--7.Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?
SELECT c.city_name,
COUNT(DISTINCT cs.customer_id) AS unique_customers
FROM sales s 
	JOIN [customers ] cs
		ON cs.customer_id=s.customer_id
	JOIN city c 
		ON c.city_id=cs.city_id
GROUP BY  c.city_name
ORDER BY  unique_customers DESC

--8.Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer
	
WITH avg_ AS(
	
	SELECT c.city_name, COUNT(DISTINCT cs.customer_id) Ttl_customer,
		CONVERT(DECIMAL(10,2),SUM(total))AS Avg_sals,
				COUNT(DISTINCT  cs.customer_id) AS consumers
	FROM sales s 
		JOIN [customers ] cs
			ON cs.customer_id=s.customer_id
		JOIN city c 
			ON c.city_id=cs.city_id
	GROUP BY 		
			c.city_name)

		SELECT a.city_name, Ttl_customer,
		FORMAT(CONVERT(DECIMAL(10,2) ,(a.avg_sals/a.consumers)) , 'N2') AS ave_sale_per_customer,
		FORMAT(CONVERT(DECIMAL(10,2) ,(c.estimated_rent/a.consumers)), 'N2') AS ave_rent_per_customer
		FROM avg_ a
		JOIN city c
		ON c.city_name = a.city_name;
		
							--OR
WITH cityinfo AS (
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id),2) as avg_sale_pr_customer
	FROM sales as s
			JOIN [customers ] as c
				ON s.customer_id = c.customer_id
			JOIN city as ci
				ON ci.city_id = c.city_id
	GROUP BY ci.city_name
	
),
rentdetails AS (
	SELECT 
		city_name, 
		estimated_rent
	FROM city
)
SELECT 
	rt.city_name,
	rt.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_customer,
	ROUND(rt.estimated_rent/ct.total_cx
		, 2) as avg_rent_per_cx
FROM rentdetails as rt
	JOIN cityinfo as ct
		ON rt.city_name = ct.city_name
ORDER BY 4 DESC

--9.	Monthly Sales Growth
--Sales growth rate:
--Calculate the percentage growth (or decline) in sales over different time periods (monthly).
-- how to find % growth

WITH monthlysales AS (
    SELECT
        YEAR(sale_date) AS salesYear,
        MONTH(sale_date) AS monthNumber,
        DATENAME(MONTH, sale_date) AS salesMonths,
        SUM(total) AS cr_month_revenue
    FROM sales
    GROUP BY
        YEAR(sale_date),
        MONTH(sale_date),
        DATENAME(MONTH, sale_date)
),--SELECT * FROM monthlysales
monthlygrowth AS (
    SELECT
        salesMonths,
        salesYear,
        monthNumber,
        cr_month_revenue,
        LAG(cr_month_revenue, 1) OVER (
            ORDER BY salesYear, monthNumber
        ) AS pre_month_revenue
    FROM monthlysales
) ---SELECT * FROM monthlygrowth ;
SELECT
    salesYear,
    salesMonths,
    cr_month_revenue,
    pre_month_revenue,
    ROUND(
        (cr_month_revenue - pre_month_revenue) * 100.0
        / NULLIF(pre_month_revenue, 0),
        2
    ) AS monthly_growth_percentage
FROM monthlygrowth


--10.	Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
SELECT TOP 3
	c.city_name, c.estimated_rent,
	FORMAT(SUM(CONVERT(FLOAT, total))/1000000,'N2') + 'M' AS Ttl_sale,
		COUNT(DISTINCT s.customer_id) AS Ttl_customers,
	FORMAT(COUNT(sale_id), 'N0')AS sales_count,
	FORMAT(Population * 0.25/1000000,'N2') + 'M'AS estimated_coffee_consumers 
FROM sales s
		JOIN [customers ] cs
			ON cs.customer_id=s.customer_id
		JOIN city c 
			ON c.city_id=cs.city_id
GROUP BY 
	c.city_name,Population,c.estimated_rent
ORDER BY
	Ttl_sale DESC

									--OR

WITH salepercustomer AS (
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_customer,
		ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id),2) as sale_pr_customer
	FROM sales as s
	JOIN [customers ] as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY ci.city_name
	--ORDER BY 2 DESC
),
city_rent AS (
	SELECT 
		city_name, 
		estimated_rent,
		FORMAT(CONVERT(DECIMAL(10,2),(population * 0.25))/1000000, 'N2') + 'M' as estimated_consumer
	FROM city
)
SELECT TOP 3 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_customer,
	estimated_consumer,
	ct.sale_pr_customer,
	ROUND(
		cr.estimated_rent/ct.total_customer
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN salepercustomer as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC
	
--11.City Revenue Contribution
--Calculate each city's percentage contribution to total company revenue. Rank the cities from highest to lowest contribution.
WITH contribution AS
(
SELECT c.city_name,
	SUM(s.total) AS Total_sales,
	FORMAT(SUM(CONVERT(FLOAT , s.total))*100/
				(SELECT SUM(total) FROM sales),'N2') AS percentage_contribution
FROM sales s
		JOIN [customers ] cs
			ON cs.customer_id=s.customer_id
		JOIN city c 
			ON c.city_id=cs.city_id
GROUP BY 
	c.city_name
	)
SELECT city_name,
	percentage_contribution, 
		total_sales,
DENSE_RANK() OVER ( ORDER BY Total_sales DESC ) AS city_rank
FROM contribution

--12.Monthly sales % contibution 
SELECT 
DATENAME(MONTH,sale_date) AS Months,
SUM(Total) AS Revenue,
SUM(Total)*100/(SELECT SUM(Total) FROM sales) AS  percentage_contribution 
FROM sales 
GROUP BY												
	DATENAME(MONTH,sale_date)
ORDER BY 
	SUM(Total) DESC

--***Business Recommendations
--	Prioritize stock availability for high-demand products, particularly Cold Brew Coffee Pack (6 Bottles), which recorded the highest sales volume among the listed products.
--	Explore growth opportunities in cities with a relatively large estimated coffee consumer base as in Pune, Chennai, and Bangalore but explore growth opportunities in cities with comparatively lower sales performance through targeted promotions and local marketing.
--	Introduce loyalty programs, personalized offers, and repeat-purchase incentives to improve customer engagement and encourage frequent purchases.
--	Monitor monthly sales growth to identify periods of declining performance and investigate possible reasons behind fluctuations and plan promotional campaigns and inventory adjustments
--	Use estimated coffee consumer figures and city ranking to enhance market expansion.
