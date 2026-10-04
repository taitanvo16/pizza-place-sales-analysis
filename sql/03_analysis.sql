USE PizzaPlace;


-- Câu 1: Doanh thu và số đơn theo tháng

SELECT MONTH(o.order_datetime) AS Month,
		COUNT(DISTINCT o.order_id )	AS Total_Order,
		SUM(p.price * d.quantity) AS Total_revenue
FROM dbo.order_details_clean d
JOIN dbo.orders_clean o ON o.order_id = d.order_id
JOIN dbo.pizzas_clean p ON p.pizza_id = d.pizza_id
GROUP BY MONTH(o.order_datetime)
ORDER BY Month;

/*Nhận xét: 
- Số liệu: Tháng 7 cao nhất vê cả đơn hàng (1935) và doanh thu (72557.90);
tháng 5 đứng sau (1853 đơn và 71402.75). Tháng 10 thấp nhất với (1646 đơn, 64027.60).
- Chênh lệch: tháng 7 hơn tháng 10 khoảng 13% về doanh thu và khoảng 18% về đơn hàng.
Tháng 10 có ít đơn hơn nhưng giá trị về mỗi đơn hàng lại cao hơn một chút ( khoảng 38,90 so với 37,50).
-  Kết luận: doanh thu khá ổn định quanh năm, không có mùa vụ mạnh.
*/


-- Câu 2: Khung giờ nào đông khách nhất
SELECT  DATEPART(HOUR, o.order_datetime) AS [Hour],
		COUNT(*) AS Orders
FROM dbo.orders_clean o
GROUP BY DATEPART(HOUR, o.order_datetime)
ORDER BY Orders DESC
/*Nhận xét:
- Số liệu: Đông nhất là khung 12 giờ với 2520 đơn và khung 13 giờ với 2455 đơn. Tiếp theo là
     18 giờ (2399) và 17 giờ (2336). Hai khung 12-13 giờ và 17-19 giờ chiếm
     khoảng 55% tổng 21.350 đơn.

*/

-- Câu 3 Thứ nào trong tuần bán chạy nhất
SELECT DATENAME(WEEKDAY, o.order_datetime) AS WeekDay,
		COUNT(*) AS Orders
FROM dbo.orders_clean o
GROUP BY DATENAME(WEEKDAY, o.order_datetime), DATEPART(WEEKDAY, o.order_datetime)
ORDER BY DATEPART(WEEKDAY, o.order_datetime);
/*Nhận xét:
  - Số liệu: Thứ 6 đông nhất với 3538 đơn (16,57% tổng 21.350 đơn); chủ nhật
     ít nhất với 2624 đơn (12,29%). Thứ 6 đông hơn chủ nhật khoảng 35%.
   - Xu hướng: số đơn tăng dần từ đầu tuần (thứ 2: 2794) đến đỉnh thứ 6, sau đó
     thứ 7 giảm còn 3158 và chủ nhật thấp nhất. Ba ngày thứ 5, 6, 7 gộp lại
     chiếm khoảng 46,5% tổng số đơn.
   - Giải thích có thể: thứ 6 là ngày cuối tuần làm việc nên người ta hay ăn
     ngoài hoặc đặt đồ ăn để thư giãn; chủ nhật có thể ở nhà nấu ăn cùng gia đình.
   - Kết luận: số đơn biến động theo thứ trong tuần rõ hơn theo tháng.
*/

-- Câu 4: Pizza nào bán chạy nhất (TOP 5)
SELECT TOP 5 t.name , SUM(d.quantity) AS Quantity_Sold
FROM dbo.order_details_clean d
JOIN dbo.pizzas_clean p ON p.pizza_id = d.pizza_id
JOIN dbo.pizza_types_clean t ON t.pizza_type_id = p.pizza_type_id
GROUP BY t.name
ORDER BY Quantity_Sold DESC;

--  Pizza nào bán kém nhất (TOP 5)
SELECT TOP 5 t.name , SUM(d.quantity) AS Quantity_Sold
FROM dbo.order_details_clean d
JOIN dbo.pizzas_clean p ON p.pizza_id = d.pizza_id
JOIN dbo.pizza_types_clean t ON t.pizza_type_id = p.pizza_type_id
GROUP BY t.name
ORDER BY Quantity_Sold ASC;
/* NHẬN XÉT 
   - Số liệu: Bán chạy nhất là The Classic Deluxe Pizza (2453), tiếp theo là
     The Barbecue Chicken (2432), Hawaiian (2422), Pepperoni (2418) và
     Thai Chicken (2371). Bán thấp nhất là The Brie Carre Pizza (490), rồi
     Mediterranean (934), Calabrese (937), Spinach Supreme (950),
     Soppressata (961).
   - So sánh: top 5 chênh nhau chỉ khoảng 3,5%; hạng 1 bán gấp khoảng 5 lần
     hạng cuối. Brie Carre thấp hơn hẳn 4 pizza còn lại của nhóm cuối.
*/

-- Câu 5: Size và Category nào đóng góp doanh thu nhiều nhất?
SELECT p.size, 
	   t.category, 
	   SUM(d.quantity*p.price) AS Revenue,
	   SUM(d.quantity * p.price)*100.0 / 
	   SUM(SUM(d.quantity*p.price)) OVER () AS Revenue_Percent

FROM dbo.order_details_clean d
JOIN dbo.pizzas_clean p ON p.pizza_id = d.pizza_id
JOIN dbo.pizza_types_clean t ON t.pizza_type_id = p.pizza_type_id
GROUP BY p.size, t.category
ORDER BY Revenue DESC;
/* NHẬN XÉT:
   - Số liệu: Về size, L dẫn đầu với 375.318,70 (khoảng 45,9% tổng 817.860,05),
     tiếp theo là M (30,5%) và S (21,8%). XL và XXL cộng lại chỉ khoảng 1,8%.
     Về danh mục, Classic cao nhất (26,9%), rồi Supreme (25,5%), Chicken (24,0%),
     Veggie (23,7%). Cặp lớn nhất là L Veggie với 104.202,70 (12,74%).
   - So sánh: 4 danh mục chênh nhau khoảng 13,6% giữa cao nhất và thấp nhất,
     khá cân bằng. Classic dẫn đầu nhờ có thêm size XL và XXL; nếu bỏ hai size này,
     Supreme sẽ đứng đầu.
   - Điểm đáng chú ý: S Classic mạnh hơn hẳn S của các danh mục khác
     (69.870,25 so với 47.463,50 của S Supreme).
   - Giải thích có thể: người mua size nhỏ ưu tiên hương vị quen thuộc.
*/

-- Câu 6: Mỗi đơn trung bình có mấy pizza và giá trị bao nhiêu ?
WITH OrderSum AS (
	SELECT o.order_id,
			SUM(d.quantity) AS Total_Pizza,
			SUM(d.quantity * p.price) AS Revenue 
	FROM dbo.orders_clean o
	JOIN dbo.order_details_clean d ON d.order_id = o.order_id
	JOIN dbo.pizzas_clean p ON p.pizza_id = d.pizza_id
	GROUP BY o.order_id
)
SELECT	COUNT(*) AS Orders,
		CAST(AVG(Total_Pizza * 1.0) AS DECIMAL(10,2)) AS Avg_Pizza_Per_Order,
        CAST(AVG(Revenue)           AS DECIMAL(10,2)) AS Avg_Revenue,
	    SUM(Revenue)                                  AS Total_Revenue
FROM OrderSum;
/* NHẬN XÉT :
   - Số liệu: Trên 21.350 đơn, mỗi đơn trung bình có 2,32 pizza và trị giá 38,31
     (tổng doanh thu 817.860,05). Trung bình mỗi pizza khoảng 16,5.
*/

-- Câu 7: Doanh thu tăng giảm thế nào theo tháng
WITH monthly AS (
	SELECT MONTH(o.order_datetime) AS mth,
			SUM(d.quantity*p.price) AS revenue
	FROM dbo.order_details_clean d
	JOIN dbo.orders_clean o ON o.order_id = d.order_id
	JOIN dbo.pizzas_clean p ON p.pizza_id = d.pizza_id
	GROUP BY MONTH(o.order_datetime)
)
SELECT mth,
		revenue,
		LAG(revenue) OVER (ORDER BY mth) AS prev_month,
		revenue - LAG(revenue) OVER (ORDER BY mth) AS change_revenue,
		CAST((revenue - LAG(revenue) OVER (ORDER BY mth)) * 100.0
			/ NULLIF(LAG(revenue) OVER (ORDER BY mth),0) AS DECIMAL(6,2)) AS change_percent
FROM monthly
ORDER BY mth;
/* NHẬN XÉT:
   - Số liệu: Doanh thu dao động từ 64.027,60 (tháng 10) đến 72.557,90 (tháng 7).
     Tăng mạnh nhất là tháng 11 (+9,95%, +6.367,75), giảm mạnh nhất là tháng 12
     (-8,09%, -5.694,20).
   - Xu hướng: tháng 1-7 tăng giảm xen kẽ, không có xu hướng rõ. Từ tháng 8 đến
     tháng 10 giảm liên tiếp 3 tháng, tổng cộng từ tháng 7 xuống tháng 10 giảm
     khoảng 11,8%. Tháng 11 bật lên lại 70.395,35 rồi tháng 12 giảm xuống 64.701,15.
     Nửa năm sau thấp hơn nửa năm đầu khoảng 2,3%.
   - Giải thích có thể: tháng 2 thấp một phần do chỉ có 28 ngày; quý 4 thì số
     ngày không giải thích được (tháng 10 và 12 đều 31 ngày mà vẫn thấp).
   - Kết luận: doanh thu tương đối ổn định, biến động theo tháng khoảng
     2-10%, chưa thấy xu hướng tăng trưởng. Dữ liệu chỉ có một năm nên không đủ
     để khẳng định mùa vụ.
*/

-- Câu 8: Top 3 pizza của mỗi danh mục?
WITH sales AS (
	SELECT t.category,
		   t.name AS pizza_name,
		   SUM(p.price * d.quantity) AS revenue
	FROM dbo.order_details_clean d
	JOIN dbo.pizzas_clean p ON p.pizza_id = d.pizza_id
	JOIN dbo.pizza_types_clean t ON t.pizza_type_id = p.pizza_type_id
	GROUP BY t.category, t.name
),
ranked AS (
	SELECT category, pizza_name, revenue, 
			DENSE_RANK() OVER (PARTITION BY category
								ORDER BY revenue DESC) AS rnk
	FROM sales
)
SELECT category, rnk, pizza_name, revenue
FROM ranked
WHERE rnk <=3
ORDER BY category, rnk; 
/* NHẬN XÉT
   - Số liệu: Dẫn đầu từng danh mục: Chicken - Thai Chicken (43.434,25);
     Classic - Classic Deluxe (38.180,50); Supreme - Spicy Italian (34.831,25);
     Veggie - Four Cheese (32.265,70). Ba pizza Chicken đều cao hơn mọi pizza
     của danh mục khác.
   - So sánh: Classic Deluxe và Four Cheese nổi bật hơn hạng 2 của mình khoảng
     18% và 20%; ở Chicken và Supreme các pizza đứng đầu sát nhau (chênh khoảng 2-4%).
   - Khác với câu 4: Thai Chicken đứng thứ 5 về số lượng nhưng đứng đầu về
     doanh thu, vì giá trung bình mỗi pizza bán ra cao hơn (khoảng 18,32 so với
     khoảng 12,47 của Pepperoni).
   - Giải thích có thể: pizza Chicken có giá cao hơn nên doanh thu lớn dù số
     lượng không vượt trội.
*/