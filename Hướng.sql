-- HƯỚNG (BÁO CÁO & THỐNG KÊ) - 5 CÂU
-- ======================================================

-- 21. Doanh thu theo ngày
SELECT 
    CONVERT(DATE, order_date) as ngay,
    COUNT(*) as so_don_hang,
    SUM(total_amount) as doanh_thu,
    AVG(total_amount) as gia_tri_trung_binh_don
FROM Orders 
WHERE status = 'Completed'
GROUP BY CONVERT(DATE, order_date)
ORDER BY ngay DESC;

-- 22. Top 5 sách bán chạy nhất
SELECT TOP 5
    b.book_code,
    b.title,
    b.author,
    SUM(od.quantity) as so_luong_ban,
    SUM(od.subtotal) as doanh_thu
FROM Books b
JOIN OrderDetails od ON b.book_id = od.book_id
JOIN Orders o ON od.order_id = o.order_id AND o.status = 'Completed'
GROUP BY b.book_id, b.book_code, b.title, b.author
ORDER BY so_luong_ban DESC;

-- 23. Top 5 khách hàng mua nhiều nhất
SELECT TOP 5
    c.customer_code,
    c.full_name,
    c.phone_number,
    COUNT(o.order_id) as so_don_hang,
    SUM(o.total_amount) as tong_chi_tieu
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
GROUP BY c.customer_id, c.customer_code, c.full_name, c.phone_number
ORDER BY tong_chi_tieu DESC;

-- 24. Thống kê tồn kho theo nhà xuất bản
SELECT 
    publisher as nha_xuat_ban,
    COUNT(*) as so_dau_sach,
    SUM(quantity_in_stock) as tong_ton_kho,
    SUM(quantity_in_stock * price) as gia_tri_ton_kho
FROM Books
GROUP BY publisher
ORDER BY gia_tri_ton_kho DESC;

-- 25. Báo cáo tổng quan hệ thống
SELECT 
    (SELECT COUNT(*) FROM Customers) as tong_khach_hang,
    (SELECT COUNT(*) FROM Books) as tong_sach,
    (SELECT COUNT(*) FROM Orders WHERE status = 'Completed') as tong_don_hang,
    (SELECT ISNULL(SUM(total_amount), 0) FROM Orders WHERE status = 'Completed') as tong_doanh_thu,
    (SELECT COUNT(*) FROM Books WHERE quantity_in_stock < 10) as sach_sap_het_hang,
    (SELECT COUNT(*) FROM Orders WHERE status = 'Pending') as don_hang_cho_xu_ly;

-- VIEW: Doanh thu hàng tháng
GO
CREATE OR ALTER VIEW vw_MonthlyRevenueSummary AS
SELECT 
    YEAR(order_date) as nam,
    MONTH(order_date) as thang,
    COUNT(*) as so_don_hang,
    SUM(total_amount) as doanh_thu,
    AVG(total_amount) as gia_tri_tb_don
FROM Orders 
WHERE status = 'Completed'
GROUP BY YEAR(order_date), MONTH(order_date);
GO

-- VIEW: Đơn hàng đang chờ xử lý (nếu chưa có trong file TUANANH)
CREATE OR ALTER VIEW vw_PendingOrdersSummary AS
SELECT 
    o.order_id,
    o.order_code,
    o.order_date,
    c.full_name as khach_hang,
    c.phone_number,
    COUNT(od.order_detail_id) as so_mat_hang,
    o.total_amount
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
LEFT JOIN OrderDetails od ON o.order_id = od.order_id
WHERE o.status = 'Pending'
GROUP BY o.order_id, o.order_code, o.order_date, 
         c.full_name, c.phone_number, o.total_amount;
GO

-- PROCEDURE: Báo cáo doanh thu
CREATE OR ALTER PROCEDURE sp_RevenueReportProc
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Tổng doanh thu
    SELECT 
        'Tổng doanh thu' as loai_bao_cao,
        COUNT(*) as so_don_hang,
        SUM(total_amount) as doanh_thu
    FROM Orders 
    WHERE status = 'Completed'
      AND order_date BETWEEN @start_date AND @end_date;
    
    -- Doanh thu theo ngày
    SELECT 
        CONVERT(DATE, order_date) as ngay,
        COUNT(*) as so_don_hang,
        SUM(total_amount) as doanh_thu
    FROM Orders 
    WHERE status = 'Completed'
      AND order_date BETWEEN @start_date AND @end_date
    GROUP BY CONVERT(DATE, order_date)
    ORDER BY ngay DESC;
END;
GO