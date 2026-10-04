USE PizzaPlace;
GO

-- vw_FactSales

CREATE OR ALTER VIEW dbo.vw_FactSales AS
SELECT d.order_details_id,
		d.order_id,
		d.pizza_id,
		CAST(o.order_datetime AS DATE) AS order_date,
		DATEPART(HOUR, o.order_datetime) AS order_hour,
		d.quantity,
		p.price AS unit_price,
		d.quantity * p.price AS line_revenue
FROM dbo.order_details_clean d
JOIN dbo.orders_clean o ON o.order_id = d.order_id
JOIN dbo.pizzas_clean p ON p.pizza_id = d.pizza_id
GO


--vw_DimPizza

CREATE OR ALTER VIEW dbo.vw_DimPizza AS
SELECT p.pizza_id,
		t.name AS pizza_name,
		t.category,
		p.size,
		CASE p.size WHEN 'S' THEN 1
					WHEN 'M' THEN 2
					WHEN 'L' THEN 3
					WHEN 'XL' THEN 4
					WHEN 'XXL' THEN 5 END AS size_order,
		p.price,
		t.ingredients
FROM dbo.pizzas_clean p
JOIN dbo.pizza_types_clean t ON t.pizza_type_id = p.pizza_type_id;
GO

/* ---------------------------------------------------------------------
   vw_DimDate: lich day du tu ngay dau den ngay cuoi cua du lieu
   (ke ca ngay khong co don).
   - weekday_num tinh bang DATEDIFF nen khong phu thuoc cai dat ngay dau
     tuan cua may. 1900-01-01 la thu Hai => Thu Hai = 1 ... Chu nhat = 7.
   - Dung ROW_NUMBER thay vi CTE de quy vi view khong dat duoc
     OPTION (MAXRECURSION).
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_DimDate AS
SELECT x.dt                                        AS date_key,
       YEAR(x.dt)                                  AS yr,
       MONTH(x.dt)                                 AS mth,
       DATENAME(MONTH, x.dt)                       AS month_name,
       (DATEDIFF(DAY, '19000101', x.dt) % 7) + 1   AS weekday_num,
       DATENAME(WEEKDAY, x.dt)                     AS weekday_name
FROM (
    SELECT DATEADD(DAY, n.i, r.d1) AS dt
    FROM (SELECT MIN(CAST(order_datetime AS DATE)) AS d1,
                 MAX(CAST(order_datetime AS DATE)) AS d2
          FROM dbo.orders_clean) r
    CROSS APPLY (
        SELECT TOP (DATEDIFF(DAY, r.d1, r.d2) + 1)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS i
        FROM sys.all_objects a CROSS JOIN sys.all_objects b
    ) n
) x;
GO	

-- KIEM TRA SAU KHI TAO VIEW
-- 1. Tong doanh thu: PHAI bang total_revenue (817860.05)
SELECT SUM(line_revenue) AS revenue FROM dbo.vw_FactSales;
 
-- 2. So dong Fact: 48620
SELECT COUNT(*) AS n FROM dbo.vw_FactSales;
 
-- 3. So dong DimPizza: 96
SELECT COUNT(*) AS n FROM dbo.vw_DimPizza;
 
-- 4. Bang ngay: so ngay, ngay dau, ngay cuoi (365 neu du ca nam 2015)
SELECT COUNT(*) AS n, MIN(date_key) AS first_day, MAX(date_key) AS last_day
FROM dbo.vw_DimDate;
 
-- 5. Moi ngay trong Fact deu phai co trong bang ngay. Ky vong: 0 dong
SELECT DISTINCT f.order_date
FROM dbo.vw_FactSales f
LEFT JOIN dbo.vw_DimDate d ON d.date_key = f.order_date
WHERE d.date_key IS NULL;
GO