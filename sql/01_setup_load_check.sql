-- Phần 1: Tạo database

IF DB_ID('PizzaPlace') IS NULL CREATE DATABASE PizzaPlace;
GO
USE PizzaPlace;
GO

-- Phần 2: Tạo bảng staging ( xóa trước để chạy lại không bị trùng dữ liệu)

DROP TABLE IF EXISTS stg_orders;
DROP TABLE IF EXISTS dbo.stg_order_details;
DROP TABLE IF EXISTS dbo.stg_pizzas
DROP TABLE IF EXISTS dbo.stg_pizza_types
GO

CREATE TABLE stg_orders (
	order_id NVARCHAR(50),
	[date] NVARCHAR(50),
	[time] NVARCHAR(50)
);

CREATE TABLE stg_order_details (
	order_details_id NVARCHAR(50),
	order_id NVARCHAR(50),
	pizza_id NVARCHAR(100),
	quantity NVARCHAR(50)
);


CREATE TABLE stg_pizzas (
	pizza_id NVARCHAR(100),
	pizza_type_id NVARCHAR(100),
	[size] NVARCHAR(20),
	price NVARCHAR(50)
);


CREATE TABLE stg_pizza_types (
	pizza_type_id NVARCHAR(100),
	[name] NVARCHAR(200),
	category NVARCHAR(100),
	ingredients NVARCHAR(1000)
);
GO

--Phần 3: Nạp dữ liệu từ file CSV
BULK INSERT stg_orders 
FROM 'D:\dataset\Pizza+Place+Sales\pizza_sales\orders.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2 , CODEPAGE = '65001');

BULK INSERT stg_order_details 
FROM 'D:\dataset\Pizza+Place+Sales\pizza_sales\order_details.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2 , CODEPAGE = '65001');

BULK INSERT stg_pizzas
FROM 'D:\dataset\Pizza+Place+Sales\pizza_sales\pizzas.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2 , CODEPAGE = '65001');

BULK INSERT stg_pizza_types 
FROM 'D:\dataset\Pizza+Place+Sales\pizza_sales\pizza_types.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2 , CODEPAGE = '65001'); 
GO 

-- Phần 4: Kiểm tra số dòng sau khi nạp
SELECT 'orders' AS tbl, COUNT(*) AS n FROM stg_orders
UNION ALL SELECT 'order_details', COUNT(*) FROM stg_order_details
UNION ALL SELECT 'pizzas',        COUNT(*) FROM stg_pizzas
UNION ALL SELECT 'pizza_types',   COUNT(*) FROM stg_pizza_types;

SELECT TOP 10 * FROM stg_orders;
SELECT TOP 10 * FROM stg_pizza_types;


-- Phần 5: Kiểm tra chất lượng của dữ liệu (chỉ dùng SELECT)

--5.1 Trùng khóa
SELECT order_id, COUNT(*) AS n
FROM dbo.stg_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT order_details_id, COUNT(*) AS n
FROM dbo.stg_order_details
GROUP BY order_details_id
HAVING COUNT(*) > 1;

SELECT pizza_id, COUNT(*) AS n
FROM dbo.stg_pizzas
GROUP BY pizza_id
HAVING COUNT(*) > 1;

SELECT pizza_type_id, COUNT(*) AS n
FROM dbo.stg_pizza_types
GROUP BY pizza_type_id
HAVING COUNT(*) > 1;

--5.2 Chuyển đổi kiểu dữ liệu
-- Mục đích: ghép date + time thành 1 ngày giờ hợp lệ.
SELECT order_id, [date], [time]
FROM dbo.stg_orders
WHERE TRY_CONVERT(datetime2, [date] + ' ' + [time]) IS NULL;

-- Mục đích: quantity phải là số nguyên.
SELECT order_details_id, quantity
FROM dbo.stg_order_details
WHERE TRY_CONVERT(int,quantity) IS NULL;

-- Mục đích: price phải là số thập phân.
SELECT pizza_id, price
FROM dbo.stg_pizzas
WHERE TRY_CONVERT(decimal(10,2), price) IS NULL;

SELECT * FROM dbo.stg_order_details WHERE TRY_CONVERT(INT, quantity) <= 0;
SELECT * FROM dbo.stg_pizzas        WHERE TRY_CONVERT(DECIMAL(10,2), price) <= 0;


--5.3 Dòng mồ côi
SELECT d.order_details_id, d.order_id
FROM dbo.stg_order_details d
LEFT JOIN dbo.stg_orders o ON o.order_id = d.order_id
WHERE o.order_id IS NULL;

SELECT d.order_details_id, d.pizza_id
FROM dbo.stg_order_details d
LEFT JOIN dbo.stg_pizzas p ON p.pizza_id = d.pizza_id
WHERE p.pizza_id IS NULL;

SELECT p.pizza_id,p.pizza_type_id
FROM dbo.stg_pizzas p
LEFT JOIN dbo.stg_pizza_types t ON t.pizza_type_id = p.pizza_type_id
WHERE t.pizza_type_id IS NULL;

-- 5.4. Mã hóa các ký tự
SELECT pizza_type_id, [name], ingredients
FROM dbo.stg_pizza_types
WHERE ingredients LIKE '%[^ -~]%' COLLATE Latin1_General_BIN
   OR [name]      LIKE '%[^ -~]%' COLLATE Latin1_General_BIN;
