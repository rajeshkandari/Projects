use gdb023;


/* 1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
 business in the  APAC  region. */
select distinct(market)
from dim_customer
where customer='Atliq Exclusive' and region='APAC'
order by market Asc;

/* 2.   What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
unique_products_2020 ,unique_products_2021 percentage_chg */

WITH cte AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_product_2020,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_product_2021
    FROM fact_gross_price
)
SELECT 
    unique_product_2020,
    unique_product_2021,
    CASE 
        WHEN unique_product_2020 = 0 THEN NULL 
        ELSE ((unique_product_2021 - unique_product_2020) * 100) / unique_product_2020 
    END AS percentage_change
FROM cte; 

-- 3.  Provide a report with all the unique product counts for each  segment  and 
-- sort them in descending order of product counts. The final output contains 
-- 2 fields, segment, product_count 

SELECT 
	segment, COUNT(product_code) as product_counts
FROM
	dim_product
GROUP BY segment
order by product_counts desc;

-- 4.  Follow-up: Which segment had the most increase in unique products in 
-- 2021 vs 2020? The final output contains these fields, 
-- segment product_count_2020 product_count_2021 difference

With cte as(
SELECT 
    p.segment,
    COUNT(CASE WHEN fiscal_year="2020" THEN p.product_code ELSE NULL END) AS product_count_2020,
    COUNT(CASE WHEN fiscal_year="2021" THEN p.product_code ELSE NULL END) AS product_count_2021
FROM 
	dim_product p
JOIN 
fact_gross_price GP
ON p.product_code=GP.product_code
GROUP BY p.segment)
SELECT 
	segment,
	product_count_2020,
	product_count_2021,
    (product_count_2021-product_count_2020) As difference
FROM cte 
ORDER BY difference DESC
Limit 1;

-- 5.  Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, product_code ,product ,manufacturing_cost

SELECT 
    p.product_code,
    p.product,
    mc.manufacturing_cost
FROM 
    dim_product p
JOIN 
    fact_manufacturing_cost mc
ON 
    p.product_code = mc.product_code
WHERE 
    mc.manufacturing_cost IN (
        (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost),
        (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
    );


-- 6.  Generate a report which contains the top 5 customers who received an 
-- average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
-- Indian  market. The final output contains these fields,  customer_code customer average_discount_percentage 

SELECT 
    c.customer_code,c.customer,
    AVG(pi.pre_invoice_discount_pct) AS average_discount_percentage
FROM 
    dim_customer c
JOIN
    fact_pre_invoice_deductions pi
ON 
    c.customer_code = pi.customer_code
WHERE 
    pi.fiscal_year = 2021 AND c.market = 'India'
GROUP BY 
    c.customer_code,c.customer
ORDER BY 
    average_discount_percentage DESC
LIMIT 5;


/* 7. Get the complete report of the Gross sales amount for the customer  Atliq 
Exclusive  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. The final report contains these columns: 
Month Year Gross sales Amount */

SELECT 
    MONTHNAME(sm.date) AS Month, 
    YEAR(sm.date) AS Year,
    SUM(gp.gross_price * sm.sold_quantity) AS Gross_sales_Amount
FROM
    fact_gross_price gp
JOIN 
    fact_sales_monthly sm ON sm.product_code = gp.product_code AND sm.fiscal_year = gp.fiscal_year
JOIN 
    dim_customer c ON sm.customer_code = c.customer_code
WHERE 
    c.customer = 'Atliq Exclusive'
GROUP BY 
    Month,Year
ORDER BY 
    Year, MONTHNAME(sm.date) Desc;
    
/* 8).   In which quarter of 2020, got the maximum total_sold_quantity? The final 
 output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity */

WITH cte AS (
    SELECT 
        *,
        CASE 
            WHEN MONTH(DATE) IN (9, 10, 11) THEN 'Q1'
            WHEN MONTH(DATE) IN (12, 1, 2) THEN 'Q2'
            WHEN MONTH(DATE) IN (3, 4, 5) THEN 'Q3'
            WHEN MONTH(DATE) IN (6, 7, 8) THEN 'Q4'
            ELSE NULL
        END AS Quarters
    FROM fact_sales_monthly
)
SELECT 
    Quarters,
    SUM(sold_quantity) AS Total_quantity
FROM 
    cte
WHERE 
    fiscal_year = '2020'
GROUP BY 
    Quarters
ORDER BY 
    Total_quantity DESC;


/*9.  Which channel helped to bring more gross sales in the fiscal year 2021 
 and the percentage of contribution?  The final output  contains these fields, 
 channel gross_sales_mln percentage */

WITH cte AS (
    SELECT
        c.channel,
        SUM(gp.gross_price * sm.sold_quantity) AS gross_sales
    FROM
        fact_sales_monthly sm
    JOIN 
        fact_gross_price gp ON gp.product_code = sm.product_code
    JOIN 
        dim_customer c ON c.customer_code = sm.customer_code
    WHERE 
        gp.fiscal_year = '2021'
    GROUP BY
        c.channel
)
SELECT 
    cte.channel,
    cte.gross_sales,
    (cte.gross_sales / (SELECT SUM(gross_sales) FROM cte) * 100) AS percentage
FROM 
    cte
ORDER BY 
    cte.gross_sales DESC;

/* 10) Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division 
product_code*/
WITH cte AS (
    SELECT 
        p.product_code, 
        p.division,
        SUM(sm.sold_quantity) AS total_sold_quantity,
        RANK() OVER (PARTITION BY p.division ORDER BY SUM(sm.sold_quantity) DESC) AS rnk
    FROM 
        dim_product p
    JOIN 
        fact_sales_monthly sm ON p.product_code = sm.product_code
    WHERE 
        sm.fiscal_year = '2021'
    GROUP BY 
        p.product_code, 
        p.division
)
SELECT 
    product_code, 
    division, 
    total_sold_quantity
FROM 
    cte
WHERE 
    rnk <= 3;
 



 
select * from dim_customer;
select * from dim_product;
select * from fact_gross_price;
select * from fact_manufacturing_cost;
select * from fact_pre_invoice_deductions;
select * from fact_sales_monthly;
		





