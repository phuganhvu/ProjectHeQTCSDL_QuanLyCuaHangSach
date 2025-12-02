
-- ======================================================
-- PHƯƠNG ANH (KHÁCH HÀNG & TRANG CHỦ) - 5 CÂU
-- ======================================================

-- 1. Thêm khách hàng mới
INSERT INTO Customers (customer_code, full_name, address, phone_number)
VALUES ('KH001', N'Nguyễn Văn A', N'Hà Nội', '0123456789');
GO

-- 2. Tìm khách hàng theo tên hoặc số điện thoại
SELECT * FROM Customers 
WHERE full_name LIKE N'%Nguyễn%' OR phone_number LIKE '%0123%';
GO

-- 3. Cập nhật thông tin khách hàng
UPDATE Customers 
SET address = N'TP.HCM', phone_number = '0987654321'
WHERE customer_code = 'KH001';
GO

-- 4. Xóa khách hàng (có kiểm tra đơn hàng)
DECLARE @customer_id_to_delete INT = 1;
IF NOT EXISTS (SELECT 1 FROM Orders WHERE customer_id = @customer_id_to_delete)
BEGIN
    DELETE FROM Customers WHERE customer_id = @customer_id_to_delete;
    PRINT 'Đã xóa khách hàng thành công';
END
ELSE
BEGIN
    PRINT 'Không thể xóa khách hàng vì đã có đơn hàng';
    -- Hiển thị đơn hàng của khách hàng
    SELECT order_code, order_date, total_amount, status 
    FROM Orders WHERE customer_id = @customer_id_to_delete;
END
GO

-- 5. Thống kê khách hàng mới trong tháng (cho trang chủ)
SELECT 
    DAY(created_date) as ngay,
    COUNT(*) as so_khach_hang_moi
FROM Customers
WHERE MONTH(created_date) = MONTH(GETDATE()) 
  AND YEAR(created_date) = YEAR(GETDATE())
GROUP BY DAY(created_date)
ORDER BY ngay;
GO
-- Index cho Phương Anh (Khách hàng)
CREATE INDEX idx_Customers_NamePhone ON Customers(full_name, phone_number);
GO
-- TRIGGER cho Phương Anh (Khách hàng): Ngăn xóa khách hàng đã có đơn hàng
GO
CREATE TRIGGER trg_PreventDeleteCustomerWithOrders
ON Customers
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS(SELECT 1 FROM deleted d 
              JOIN Orders o ON d.customer_id = o.customer_id)
    BEGIN
        RAISERROR('Không thể xóa khách hàng đã có đơn hàng!', 16, 1);
        RETURN;
    END
    
    DELETE FROM Customers WHERE customer_id IN (SELECT customer_id FROM deleted);
END;
GO
