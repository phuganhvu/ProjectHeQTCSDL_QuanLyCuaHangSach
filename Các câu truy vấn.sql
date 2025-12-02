-- ======================================================
-- FILE: BOOK_STORE_QUERIES_COMPLETE.sql
-- MÔ TẢ: 125 câu truy vấn SQL cho hệ thống quản lý nhà sách
-- PHÂN BỔ: 5 thành viên x 25 câu (15 cơ bản + 10 nâng cao)
-- NGÀY TẠO: [Ngày hiện tại]
-- ======================================================

-- ======================================================
-- PHẦN 1: PHƯƠNG ANH (KHÁCH HÀNG & TRANG CHỦ) - 25 CÂU
-- ======================================================

-- *** 15 CÂU CƠ BẢN ***

-- 1. Tìm kiếm khách hàng theo tên
SELECT customer_id, customer_code, full_name, address, phone_number, email
FROM Customers 
WHERE full_name LIKE N'%Tìm kiếm%';
GO

-- 2. Tìm khách hàng theo số điện thoại
SELECT * FROM Customers WHERE phone_number LIKE '%0123%';
GO

-- 3. Thêm khách hàng mới
INSERT INTO Customers (customer_code, full_name, address, phone_number, email)
VALUES ('KH001', N'Nguyễn Văn A', N'Hà Nội', '0123456789', 'a@gmail.com');
GO

-- 4. Cập nhật thông tin khách hàng
UPDATE Customers 
SET address = N'TP.HCM', phone_number = '0987654321'
WHERE customer_code = 'KH001';
GO

-- 5. Xóa khách hàng
DELETE FROM Customers WHERE customer_code = 'KH001';
GO

-- 6. Lấy tất cả khách hàng
SELECT * FROM Customers ORDER BY created_date DESC;
GO

-- 7. Đếm tổng số khách hàng
SELECT COUNT(*) as total_customers FROM Customers;
GO

-- 8. Khách hàng có tổng chi tiêu cao nhất
SELECT TOP 10 * FROM Customers ORDER BY total_spent DESC;
GO

-- 9. Khách hàng mới trong tháng
SELECT * FROM Customers 
WHERE MONTH(created_date) = MONTH(GETDATE()) 
AND YEAR(created_date) = YEAR(GETDATE());
GO

-- 10. Tìm khách hàng không có địa chỉ
SELECT * FROM Customers WHERE address IS NULL OR address = '';
GO

-- 11. Cập nhật tổng chi tiêu khách hàng
UPDATE c
SET total_spent = (
    SELECT ISNULL(SUM(total_amount), 0) 
    FROM Orders o 
    WHERE o.customer_id = c.customer_id AND o.status = 'Completed'
)
FROM Customers c;
GO

-- 12. Sắp xếp khách hàng theo tên A-Z
SELECT * FROM Customers ORDER BY full_name ASC;
GO

-- 13. Khách hàng có số điện thoại bắt đầu bằng 09
SELECT * FROM Customers WHERE phone_number LIKE '09%';
GO

-- 14. Lấy khách hàng theo mã
SELECT * FROM Customers WHERE customer_code = 'KH001';
GO

-- 15. Phân trang khách hàng
SELECT * FROM Customers 
ORDER BY customer_id 
OFFSET 0 ROWS 
FETCH NEXT 20 ROWS ONLY;
GO


-- *** 10 CÂU NÂNG CAO ***

-- 16. VIEW: Khách hàng VIP (chi tiêu > 10 triệu)
GO
CREATE VIEW vw_VIP_Customers AS
SELECT * FROM Customers WHERE total_spent > 10000000;
GO

-- 17. PROCEDURE: Tìm khách hàng theo nhiều điều kiện
GO
CREATE PROCEDURE sp_SearchCustomers
    @name NVARCHAR(100) = NULL,
    @phone VARCHAR(15) = NULL,
    @address NVARCHAR(255) = NULL
AS
BEGIN
    SELECT * FROM Customers 
    WHERE (@name IS NULL OR full_name LIKE '%' + @name + '%')
      AND (@phone IS NULL OR phone_number LIKE '%' + @phone + '%')
      AND (@address IS NULL OR address LIKE '%' + @address + '%');
END;
GO

-- 18. TRIGGER: Tự động tạo mã khách hàng
GO
CREATE TRIGGER trg_AutoGenerateCustomerCode
ON Customers
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @next_id INT;
    SELECT @next_id = ISNULL(MAX(customer_id), 0) + 1 FROM Customers;
    
    INSERT INTO Customers (customer_code, full_name, address, phone_number, email)
    SELECT 'KH' + RIGHT('000' + CAST(@next_id AS VARCHAR(10)), 5),
           full_name, address, phone_number, email
    FROM inserted;
END;
GO

-- 19. INDEX: Tối ưu tìm kiếm tên khách hàng
GO
CREATE INDEX idx_Customers_FullName ON Customers(full_name);
GO
CREATE INDEX idx_Customers_Phone ON Customers(phone_number);
GO

-- 20. PROCEDURE: Thống kê khách hàng theo tháng
GO
CREATE PROCEDURE sp_CustomerStatsByMonth
    @year INT,
    @month INT
AS
BEGIN
    SELECT 
        COUNT(*) as new_customers,
        SUM(total_spent) as total_revenue
    FROM Customers
    WHERE YEAR(created_date) = @year AND MONTH(created_date) = @month;
END;
GO

-- 21. VIEW: Khách hàng có đơn hàng gần đây
GO
CREATE VIEW vw_RecentActiveCustomers AS
SELECT c.*, MAX(o.order_date) as last_order_date
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_code, c.full_name, c.address, 
         c.phone_number, c.email, c.total_orders, c.total_spent, c.created_date;
GO

-- 22. TRIGGER: Cập nhật số đơn hàng khi có đơn mới
GO
CREATE TRIGGER trg_UpdateCustomerOrderCount
ON Orders
AFTER INSERT
AS
BEGIN
    UPDATE c
    SET total_orders = total_orders + 1
    FROM Customers c
    JOIN inserted i ON c.customer_id = i.customer_id;
END;
GO

-- 23. PROCEDURE: Xuất danh sách khách hàng ra file
GO
CREATE PROCEDURE sp_ExportCustomers
AS
BEGIN
    SELECT 
        customer_code as 'Mã KH',
        full_name as 'Họ tên',
        address as 'Địa chỉ',
        phone_number as 'SĐT',
        email as 'Email',
        total_orders as 'Số đơn',
        total_spent as 'Tổng chi tiêu'
    FROM Customers
    ORDER BY full_name;
END;
GO

-- 24. FUNCTION: Kiểm tra số điện thoại hợp lệ
GO
CREATE FUNCTION fn_IsValidPhone(@phone_num VARCHAR(15))
RETURNS BIT
AS
BEGIN
    DECLARE @result BIT;
    
    SET @result = CASE 
        WHEN @phone_num LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' THEN 1
        ELSE 0
    END;
    
    RETURN @result;
END;
GO

-- 25. PROCEDURE: Tạo khách hàng với kiểm tra trùng
GO
CREATE PROCEDURE sp_AddCustomerWithCheck
    @full_name NVARCHAR(100),
    @phone_num VARCHAR(15),
    @email_addr VARCHAR(100),
    @address_text NVARCHAR(255)
AS
BEGIN
    IF EXISTS(SELECT 1 FROM Customers WHERE phone_number = @phone_num)
    BEGIN
        RAISERROR('Số điện thoại đã tồn tại', 16, 1);
        RETURN;
    END
    
    DECLARE @next_code VARCHAR(20);
    DECLARE @max_id INT;
    
    SELECT @max_id = ISNULL(MAX(customer_id), 0) + 1 FROM Customers;
    SET @next_code = 'KH' + RIGHT('000' + CAST(@max_id AS VARCHAR(5)), 5);
    
    INSERT INTO Customers (customer_code, full_name, phone_number, email, address)
    VALUES (@next_code, @full_name, @phone_num, @email_addr, @address_text);
END;
GO


