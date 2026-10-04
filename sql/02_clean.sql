USE PizzaPlace;
GO 

-- Phần 1: KIỂM TRA TRƯỚC KHI LÀM SẠCH (Sử dụng SELECT)
-- Mục đích: biết trước dòng nào sẽ không chuyển được kiểu dữ liệu
--1.1 Ngày giờ nào không chuyển đổi được?
SELECT order_id, [date],[time]
FROM dbo.stg_orders
WHERE TRY_CONVERT(DATETIME2, [date] + ' ' + 
	  REPLACE(REPLACE([time], CHAR(13), ''), CHAR(10), '')) IS NULL;

--1.2 quantity nào không chuyển đổi được thành số nguyên?
SELECT order_details_id, quantity
FROM dbo.stg_order_details
WHERE TRY_CONVERT(INT, REPLACE(REPLACE(quantity, CHAR(13),''),CHAR(10),'')) IS NULL;

--1.3 price nào không chuyển đổi được thành số thập phân?
SELECT pizza_id, price
FROM dbo.stg_pizzas
WHERE TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(price, CHAR(13),''),CHAR(10),'')) IS NULL;

--1.4 Dòng nào có ký tự hỏng không?
SELECT pizza_type_id, [name], ingredients
FROM dbo.stg_pizza_types
WHERE ingredients LIKE '%[^ -~]%' COLLATE Latin1_General_BIN
   OR [name]      LIKE '%[^ -~]%' COLLATE Latin1_General_BIN;

GO

-- Phần 2: XÓA BẢNG
-- Mục đích: Giúp chạy lại script không bị lỗi 'đã tồn tại' và không bị trùng dữ liệu

DROP TABLE IF EXISTS dbo.order_details_clean;
DROP TABLE IF EXISTS dbo.orders_clean;
DROP TABLE IF EXISTS dbo.pizzas_clean;
DROP TABLE IF EXISTS dbo.pizza_types_clean;

-- Phần 3: Tạo bảng các bảng và chuyển đổi các dữ liệu đã làm sạch
-- table pizza_types_clean
CREATE TABLE dbo.pizza_types_clean (
	pizza_type_id NVARCHAR(100) NOT NULL PRIMARY KEY,
	name NVARCHAR(200) NOT NULL,
	category NVARCHAR(100) NOT NULL,
	 ingredients   NVARCHAR(1000) NOT NULL
);
GO

INSERT INTO dbo.pizza_types_clean (pizza_type_id, name, category, ingredients)
SELECT 
	LTRIM(RTRIM(s.pizza_type_id)),
	LTRIM(RTRIM(s.name)),
	LTRIM(RTRIM(s.category)),
	CASE WHEN p.pos > 0 THEN STUFF(c.txt, p.pos, 1, N'''') ELSE c.txt END
FROM dbo.stg_pizza_types s
CROSS APPLY (SELECT LTRIM(RTRIM(
                REPLACE(REPLACE(s.ingredients, CHAR(13), ''), CHAR(10), ''))) AS txt) c
CROSS APPLY (SELECT PATINDEX('%[^ -~]Nduja%' COLLATE Latin1_General_BIN,
                             c.txt) AS pos) p;
GO

--table pizzas_clean
-- price -> DECIMAL(10,2), Lớn hơn 0
-- Khóa ngoại trỏ đến bảng pizza_types_clean
CREATE TABLE dbo.pizzas_clean(
	pizza_id NVARCHAR(100) NOT NULL PRIMARY KEY,
	pizza_type_id NVARCHAR(100) NOT NULL REFERENCES dbo.pizza_types_clean( pizza_type_id),
	size NVARCHAR(20) NOT NULL,
	price DECIMAL(10,2) NOT NULL CHECK(price >0)
);
GO

INSERT INTO dbo.pizzas_clean(pizza_id,pizza_type_id,size,price)
SELECT 
	LTRIM(RTRIM(p.pizza_id)),
	LTRIM(RTRIM(p.pizza_type_id)),
	LTRIM(RTRIM(p.size)),
	TRY_CONVERT(DECIMAL(10,2), 
				REPLACE(
					REPLACE(p.price, CHAR(13),''), CHAR(10),''))
FROM dbo.stg_pizzas p
GO

-- table orders_clean
CREATE TABLE dbo.orders_clean (
	order_id  INT NOT NULL PRIMARY KEY,
	order_datetime DATETIME2 NOT NULL
);
GO

INSERT INTO dbo.orders_clean (order_id, order_datetime)
SELECT
    TRY_CONVERT(INT, order_id),
    TRY_CONVERT(DATETIME2(0),	
        [date] + ' ' + REPLACE(REPLACE([time], CHAR(13), ''), CHAR(10), ''))
FROM dbo.stg_orders o;
GO

-- table order_details_clean 
-- Khóa ngoại trỏ đến bảng orders_clean và bảng pizzas_clean
-- quantity --> INT, lớn hơn 0

CREATE TABLE dbo.order_details_clean(
	order_details_id INT NOT NULL PRIMARY KEY,
	order_id INT NOT NULL REFERENCES dbo.orders_clean(order_id),
	pizza_id NVARCHAR(100) NOT NULL REFERENCES dbo.pizzas_clean(pizza_id),
	quantity  INT NOT NULL CHECK (quantity > 0)
);
GO

INSERT INTO dbo.order_details_clean(order_details_id,order_id,pizza_id,quantity)
SELECT
    TRY_CONVERT(INT, order_details_id),
    TRY_CONVERT(INT, order_id),
    LTRIM(RTRIM(pizza_id)),
    TRY_CONVERT(INT, REPLACE(REPLACE(quantity, CHAR(13), ''), CHAR(10), ''))
FROM dbo.stg_order_details ;
GO

-- Phần 6: Kiểm tra sau khi làm sạch

-- 6.1 Kiểm tra số dòng của staging và clean có trùng khớp không
SELECT (SELECT COUNT(*) FROM dbo.stg_orders) AS staging_orders,
		(SELECT COUNT(*) FROM dbo.orders_clean) AS orders_clean;

SELECT (SELECT COUNT(*) FROM dbo.stg_order_details) AS staging_order_details,
		(SELECT COUNT(*) FROM dbo.order_details_clean) AS order_details_clean;

SELECT (SELECT COUNT(*) FROM dbo.stg_pizzas) AS staging_pizzas,
		(SELECT COUNT(*) FROM dbo.pizzas_clean) AS pizzas_clean;

SELECT (SELECT COUNT(*) FROM dbo.stg_pizza_types) AS staging_pizza_type,
		(SELECT COUNT(*) FROM dbo.pizza_types_clean) AS pizza_types_clean;

--6.2. Còn ký tự nào không
SELECT pizza_type_id, [name], ingredients
FROM dbo.pizza_types_clean
WHERE ingredients LIKE '%[^ -~]%' COLLATE Latin1_General_BIN
   OR [name]      LIKE '%[^ -~]%' COLLATE Latin1_General_BIN;

--6.3. Kiểm tra đã hiển thị đúng chưa
SELECT pizza_type_id, ingredients
FROM dbo.pizza_types_clean
WHERE ingredients LIKE '%Nduja%';

--6.4 Khoảng thời gian đã hợp lý chưa
SELECT MIN(order_datetime) AS first_order,
		MAX(order_datetime) AS last_order
FROM dbo.orders_clean;

--6.5 Tổng doanh thu revenue = quantity * price
SELECT SUM(quantity * price) AS total_revenue
FROM dbo.order_details_clean d
JOIN dbo.pizzas_clean p ON p.pizza_id = d.pizza_id; 
GO