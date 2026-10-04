# readme_vi_md

# Phân Tích Doanh Số Nhà Hàng Pizza (Pizza Place Sales Analysis)

Một dự án phân tích dữ liệu toàn diện (End-to-End): bắt đầu từ các tệp CSV thô, nạp và làm sạch dữ liệu trong **SQL Server**, phân tích bằng **T-SQL**, và trình bày trên báo cáo **Power BI**.

Dashboard

![Dashboard](image/dashboard.png)

## Các câu hỏi kinh doanh (Business Questions)

1. Doanh thu và số lượng đơn hàng biến động như thế nào qua từng tháng?
2. Những khung giờ nào trong ngày bận rộn nhất?
3. Những ngày nào trong tuần có doanh số mạnh nhất và yếu nhất?
4. Những loại pizza nào bán chạy nhất và chậm nhất?
5. Kích thước (size) và danh mục (category) nào mang lại doanh thu cao nhất?
6. Quy mô trung bình của một đơn hàng là bao nhiêu (số lượng pizza và số tiền)?
7. Những loại pizza nào dẫn đầu trong mỗi danh mục?

## Dữ liệu (Data)

- **Nguồn:** [Pizza Place Sales](https://mavenanalytics.io/data-playground/pizza-place-sales) từ Maven Analytics (dữ liệu giả lập của một nhà hàng pizza trong năm 2015). Vui lòng kiểm tra giấy phép của bộ dữ liệu trước khi tái sử dụng.
- **Các tệp:** `orders` (21,350 dòng), `order_details` (48,620 dòng), `pizzas` (96 dòng), `pizza_types` (32 dòng).
- Các tệp CSV thô không đi kèm trong kho lưu trữ (repository) này. Bạn có thể tải xuống từ liên kết ở trên.

## Công cụ sử dụng (Tools)

SQL Server (T-SQL), SQL Server Management Studio, Power BI Desktop (DAX).

## Quy trình thực hiện (Workflow)

| Bước | Tệp | Chức năng |
| --- | --- | --- |
| 1 | `sql/01_setup_load_check.sql` | Tạo cơ sở dữ liệu và các bảng tạm/staging (tất cả là cột văn bản), nạp các tệp CSV bằng `BULK INSERT`, và kiểm tra chất lượng dữ liệu |
| 2 | `sql/02_clean.sql` | Xây dựng các bảng sạch `*_clean` có định dạng dữ liệu và ràng buộc chuẩn từ các bảng tạm |
| 3 | `sql/03_analysis.sql` | Trả lời các câu hỏi kinh doanh, đi kèm giải thích ngắn dưới mỗi câu truy vấn |
| 4 | `sql/04_views.sql` | Tạo 1 View thực thể (Fact) và 2 View chiều (Dimension) cho Power BI (mô hình Star Schema) |
| 5 | `PizzaPlace_Dashboard.pbix` | Báo cáo Power BI được xây dựng trên các View |

## Ghi chú về chất lượng dữ liệu (Data Quality Notes)

- Sau khi nạp, số lượng dòng khớp hoàn toàn với tệp nguồn: 21,350 / 48,620 / 96 / 32.
- Phát hiện 1 lỗi mã hóa (encoding) trong cột `pizza_types.ingredients`: xuất hiện ký tự bị lỗi trước chuỗi `Nduja Salami`. Lỗi này ảnh hưởng đến 1 dòng và đã được sửa trong `02_clean.sql` (phục hồi thành `'Nduja Salami`).
- Ngày (`date`) và giờ (`time`) ban đầu là hai cột riêng biệt, đã được gộp lại thành cột `order_datetime`.
- Các bảng sạch sử dụng khóa chính (Primary Key), khóa ngoại (Foreign Key), các ràng buộc `NOT NULL` và `CHECK` (`price > 0`, `quantity > 0`). Tất cả các dòng đều được nạp thành công mà không vi phạm ràng buộc, số lượng dòng giữa bảng tạm và bảng sạch là hoàn toàn trùng khớp.
- Tổng doanh thu đã được đối soát đồng nhất giữa các tầng: **$817,860.05** trên các bảng sạch SQL, trên các View và trên báo cáo Power BI.

## Phát hiện chính (Key Findings)

Tất cả số liệu đều từ dữ liệu năm 2015.

1. **Tổng quan:** 21,350 đơn hàng, 49,574 chiếc pizza, doanh thu $817,860.05. Trung bình mỗi đơn hàng gồm 2.32 chiếc pizza và có giá trị $38.31.
2. **Theo tháng:** Doanh thu khá ổn định, dao động từ $64,027.60 (tháng 10) đến $72,557.90 (tháng 7), chênh lệch khoảng 13%. Mức tăng mạnh nhất là tháng 11 (+9.95%) và giảm mạnh nhất là tháng 12 (-8.09%). Vì chỉ có dữ liệu của một năm nên chưa thể khẳng định tính mùa vụ.
3. **Theo giờ:** Có hai đỉnh điểm rõ rệt vào lúc 12-13h (2,520 và 2,455 đơn) và 17-19h (2,336, 2,399 và 2,009 đơn). Hai khoảng thời gian này chiếm khoảng 55% tổng số đơn hàng. Số lượng đơn giảm xuống vào khoảng 14-15h (khoảng 1,470 đơn, giảm khoảng 42% so với đỉnh điểm buổi trưa). Các khung giờ 9h, 10h và 23h tổng cộng chỉ có 37 đơn hàng.
4. **Theo thứ trong tuần:** Thứ Sáu là ngày mạnh nhất (3,538 đơn hàng, chiếm 16.6% tổng số) và Chủ Nhật là ngày yếu nhất (2,624 đơn, chiếm 12.3%). Thứ Sáu có số đơn hàng nhiều hơn khoảng 35% so với Chủ Nhật, cho thấy sự biến động theo thứ rõ rệt hơn theo tháng.
5. **Theo size và danh mục:** Size L mang lại khoảng 46% doanh thu, Size M khoảng 31%, Size S khoảng 22%, trong khi XL và XXL gộp lại chưa tới 2%. Bốn danh mục có tỷ lệ khá sát nhau: Classic 26.9%, Supreme 25.5%, Chicken 24.0%, Veggie 23.7%.
6. **Mặt hàng bán chạy nhất:** Xét theo số lượng, *The Classic Deluxe Pizza* dẫn đầu (2,453 chiếc) và *The Brie Carre Pizza* thấp nhất (490 chiếc). Xét theo doanh thu, ba loại pizza gà chiếm 3 vị trí dẫn đầu (*Thai Chicken* $43,434; *BBQ Chicken* $42,768; *California Chicken* $41,410). *Thai Chicken* chỉ đứng thứ 5 về số lượng nhưng đứng đầu về doanh thu vì giá bán trung bình mỗi chiếc cao hơn.
7. **Quy mô đơn hàng:** Trung bình mỗi đơn hàng có 2.32 chiếc pizza và đạt doanh thu $38.31.

## Báo cáo (Dashboard)

Gồm một trang với 5 thẻ KPI (Total Revenue, Total Orders, Total Pizzas, Avg Order Value, Pizzas per Order), 4 biểu đồ (Doanh thu theo tháng, Đơn hàng theo giờ, Đơn hàng theo thứ, Top 5 pizza theo doanh thu), cùng các bộ lọc (slicers) theo danh mục và kích thước.

Các chỉ số DAX chính (Main DAX measures):

```
Total Revenue    = SUM ( FactSales[line_revenue] )
Total Orders     = DISTINCTCOUNT ( FactSales[order_id] )
Total Pizzas     = SUM ( FactSales[quantity] )
Avg Order Value  = DIVIDE ( [Total Revenue], [Total Orders] )
Pizzas per Order = DIVIDE ( [Total Pizzas], [Total Orders] )
```

## Cấu trúc kho lưu trữ (Repository Structure)

```
pizza-place-sales-analysis/
├── sql/
│   ├── 01_setup_load_check.sql
│   ├── 02_clean.sql
│   ├── 03_analysis.sql
│   └── 04_views.sql
├── images/
│   └── dashboard.png
├── PizzaPlace_Dashboard.pbix
└── README.md
```

## Hướng dẫn tái hiện dự án (How to Reproduce)

1. Cài đặt SQL Server (bản Developer hoặc Express) và SQL Server Management Studio.
2. Tải 4 tệp CSV từ liên kết nguồn và lưu vào một thư mục, ví dụ: `C:\Data\Pizza\`.
3. Trong tệp `01_setup_load_check.sql`, cập nhật đường dẫn tệp trong các câu lệnh `BULK INSERT`.
4. Chạy các tệp script SQL theo thứ tự: `01`, `02`, `03`, `04`. Mỗi script đều có thể chạy lại an toàn.
5. Kiểm tra tổng doanh thu đảm bảo bằng **$817,860.05**.
6. Mở tệp `PizzaPlace_Dashboard.pbix` trong Power BI Desktop và cập nhật nguồn dữ liệu thành tên server của bạn (*Transform data > Data source settings*).

## Hạn chế của dự án (Limitations)

- Dữ liệu chỉ có trong một năm nên chưa thể kết luận chắc chắn về các quy luật theo mùa.
- Dữ liệu chỉ có doanh thu, không có chi phí nên không thể đưa ra kết luận về lợi nhuận.
- Không có định danh khách hàng nên không thể phân tích tần suất mua hàng lặp lại.
- Các giải thích trong phần ghi chú SQL mang tính chất giả thuyết. Dữ liệu cho biết điều gì xảy ra, chứ không cho biết tại sao.

## Tác giả (Author)

Võ Tấn Tài - taitanvo16@gmail.com
