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

-- ======================================================
-- PHẦN 2: LINH (SÁCH) - 25 CÂU
-- ======================================================

-- *** 15 CÂU CƠ BẢN ***

-- 26. Tìm sách theo tiêu đề
SELECT * FROM Books WHERE title LIKE N'%Python%';
GO

-- 27. Tìm sách theo tác giả
SELECT * FROM Books WHERE author LIKE N'%Nguyễn Văn A%';
GO

-- 28. Thêm sách mới
INSERT INTO Books (book_code, title, author, publisher, publish_year, quantity_in_stock, price)
VALUES ('B001', N'Lập trình Python', N'Nguyễn Văn A', N'NXB Giáo dục', 2023, 50, 150000);
GO

-- 29. Cập nhật giá sách
UPDATE Books SET price = 180000 WHERE book_code = 'B001';
GO

-- 30. Cập nhật số lượng tồn kho
UPDATE Books SET quantity_in_stock = quantity_in_stock - 5 WHERE book_id = 1;
GO

-- 31. Xóa sách
DELETE FROM Books WHERE book_id = 1;
GO

-- 32. Lấy tất cả sách
SELECT * FROM Books ORDER BY title;
GO

-- 33. Sách sắp hết hàng (tồn < 10)
SELECT * FROM Books WHERE quantity_in_stock < 10 ORDER BY quantity_in_stock ASC;
GO

-- 34. Sách theo nhà xuất bản
SELECT * FROM Books WHERE publisher = N'NXB Giáo dục';
GO

-- 35. Sách xuất bản năm 2023
SELECT * FROM Books WHERE publish_year = 2023;
GO

-- 36. Sắp xếp sách theo giá giảm dần
SELECT * FROM Books ORDER BY price DESC;
GO

-- 37. Sách có giá từ 100k-200k
SELECT * FROM Books WHERE price BETWEEN 100000 AND 200000;
GO

-- 38. Tìm sách theo mã
SELECT * FROM Books WHERE book_code = 'B001';
GO

-- 39. Đếm tổng số sách
SELECT COUNT(*) as total_books FROM Books;
GO

-- 40. Phân trang sách
SELECT * FROM Books 
ORDER BY book_id 
OFFSET 20 ROWS 
FETCH NEXT 10 ROWS ONLY;
GO


-- *** 10 CÂU NÂNG CAO ***

-- 41. VIEW: Sách bán chạy
GO
CREATE VIEW vw_BestSellingBooks AS
SELECT b.*, ISNULL(SUM(od.quantity), 0) as total_sold
FROM Books b
LEFT JOIN OrderDetails od ON b.book_id = od.book_id
LEFT JOIN Orders o ON od.order_id = o.order_id AND o.status = 'Completed'
GROUP BY b.book_id, b.book_code, b.title, b.author, b.publisher, 
         b.publish_year, b.quantity_in_stock, b.price, b.created_date, b.updated_date;
GO

-- 42. PROCEDURE: Tìm kiếm sách nâng cao
GO
CREATE PROCEDURE sp_AdvancedBookSearch
    @title NVARCHAR(255) = NULL,
    @author NVARCHAR(100) = NULL,
    @publisher NVARCHAR(100) = NULL,
    @min_price DECIMAL(10,2) = NULL,
    @max_price DECIMAL(10,2) = NULL
AS
BEGIN
    SELECT * FROM Books 
    WHERE (@title IS NULL OR title LIKE '%' + @title + '%')
      AND (@author IS NULL OR author LIKE '%' + @author + '%')
      AND (@publisher IS NULL OR publisher LIKE '%' + @publisher + '%')
      AND (@min_price IS NULL OR price >= @min_price)
      AND (@max_price IS NULL OR price <= @max_price);
END;
GO

-- 43. TRIGGER: Tự động cập nhật ngày sửa
GO
CREATE TRIGGER trg_AutoUpdateBookTimestamp
ON Books
AFTER UPDATE
AS
BEGIN
    UPDATE Books
    SET updated_date = GETDATE()
    WHERE book_id IN (SELECT book_id FROM inserted);
END;
GO

-- 44. INDEX: Tối ưu tìm kiếm sách
GO
CREATE INDEX idx_Books_Title ON Books(title);
GO
CREATE INDEX idx_Books_Author ON Books(author);
GO
CREATE INDEX idx_Books_Price ON Books(price);
GO

-- 45. PROCEDURE: Nhập sách vào kho
GO
CREATE PROCEDURE sp_ImportBooksToStock
    @book_id_param INT,
    @quantity_param INT,
    @unit_price_param DECIMAL(10,2)
AS
BEGIN
    DECLARE @import_code VARCHAR(20) = 'PN' + FORMAT(GETDATE(), 'yyyyMMddHHmmss');
    DECLARE @import_id INT;
    
    INSERT INTO ImportBooks (import_code, import_date, supplier)
    VALUES (@import_code, GETDATE(), 'Hệ thống');
    
    SET @import_id = SCOPE_IDENTITY();
    
    INSERT INTO ImportDetails (import_id, book_id, quantity, unit_price, subtotal)
    VALUES (@import_id, @book_id_param, @quantity_param, @unit_price_param, @quantity_param * @unit_price_param);
    
    UPDATE Books 
    SET quantity_in_stock = quantity_in_stock + @quantity_param
    WHERE book_id = @book_id_param;
END;
GO

-- 46. VIEW: Thống kê sách theo NXB
GO
CREATE VIEW vw_BooksByPublisher AS
SELECT 
    publisher,
    COUNT(*) as book_count,
    SUM(quantity_in_stock) as total_stock,
    AVG(price) as avg_price,
    SUM(quantity_in_stock * price) as total_value
FROM Books
GROUP BY publisher;
GO

-- 47. TRIGGER: Không cho xóa sách đã có đơn hàng
GO
CREATE TRIGGER trg_PreventDeleteBookWithOrders
ON Books
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS(SELECT 1 FROM deleted d 
              JOIN OrderDetails od ON d.book_id = od.book_id)
    BEGIN
        RAISERROR('Không thể xóa sách đã có đơn hàng!', 16, 1);
        RETURN;
    END
    
    DELETE FROM Books WHERE book_id IN (SELECT book_id FROM deleted);
END;
GO

-- 48. PROCEDURE: Báo cáo tồn kho
GO
CREATE PROCEDURE sp_InventoryReport
AS
BEGIN
    SELECT 
        book_code as 'Mã sách',
        title as 'Tên sách',
        author as 'Tác giả',
        publisher as 'NXB',
        quantity_in_stock as 'Số lượng tồn',
        price as 'Đơn giá',
        (quantity_in_stock * price) as 'Giá trị tồn kho'
    FROM Books
    ORDER BY (quantity_in_stock * price) DESC;
END;
GO

-- 49. FUNCTION: Tính giá trị tồn kho của sách
GO
CREATE FUNCTION fn_CalculateInventoryValue(@book_id_param INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @value DECIMAL(12,2);
    
    SELECT @value = quantity_in_stock * price 
    FROM Books 
    WHERE book_id = @book_id_param;
    
    RETURN ISNULL(@value, 0);
END;
GO

-- 50. PROCEDURE: Cập nhật giá sách theo phần trăm
GO
CREATE PROCEDURE sp_UpdatePriceByPercentage
    @book_id_param INT,
    @percentage_param DECIMAL(5,2)
AS
BEGIN
    UPDATE Books
    SET price = price * (1 + @percentage_param / 100),
        updated_date = GETDATE()
    WHERE book_id = @book_id_param;
END;
GO

-- ======================================================
-- PHẦN 3: TUẤN ANH (ĐƠN HÀNG) - 25 CÂU
-- ======================================================

-- *** 15 CÂU CƠ BẢN ***

-- 51. Tạo đơn hàng mới
INSERT INTO Orders (order_code, customer_id, order_date, status)
VALUES ('DH001', 1, GETDATE(), 'Pending');
GO

-- 52. Thêm sản phẩm vào đơn hàng
INSERT INTO OrderDetails (order_id, book_id, quantity, unit_price, subtotal)
VALUES (1, 1, 2, 150000, 300000);
GO

-- 53. Lấy tất cả đơn hàng
SELECT * FROM Orders ORDER BY order_date DESC;
GO

-- 54. Lấy đơn hàng theo mã
SELECT * FROM Orders WHERE order_code = 'DH001';
GO

-- 55. Lấy chi tiết đơn hàng
SELECT od.*, b.title, b.book_code 
FROM OrderDetails od
JOIN Books b ON od.book_id = b.book_id
WHERE od.order_id = 1;
GO

-- 56. Cập nhật trạng thái đơn hàng
UPDATE Orders SET status = 'Completed' WHERE order_id = 1;
GO

-- 57. Xóa đơn hàng
DELETE FROM Orders WHERE order_id = 1;
GO

-- 58. Xóa sản phẩm khỏi đơn hàng
DELETE FROM OrderDetails WHERE order_detail_id = 1;
GO

-- 59. Đơn hàng trong ngày
SELECT * FROM Orders WHERE CONVERT(DATE, order_date) = CONVERT(DATE, GETDATE());
GO

-- 60. Đơn hàng theo trạng thái
SELECT * FROM Orders WHERE status = 'Pending';
GO

-- 61. Đơn hàng theo khách hàng
SELECT * FROM Orders WHERE customer_id = 1;
GO

-- 62. Đếm số đơn hàng
SELECT COUNT(*) as total_orders FROM Orders;
GO

-- 63. Cập nhật số lượng sản phẩm
UPDATE OrderDetails 
SET quantity = 3, subtotal = 3 * unit_price 
WHERE order_detail_id = 1;
GO

-- 64. Đơn hàng chưa thanh toán
SELECT * FROM Orders 
WHERE status IN ('Pending', 'Processing');
GO

-- 65. Tìm đơn hàng theo sách
SELECT o.* 
FROM Orders o
JOIN OrderDetails od ON o.order_id = od.order_id
WHERE od.book_id = 1;
GO


-- *** 10 CÂU NÂNG CAO ***

-- 66. VIEW: Đơn hàng chi tiết
GO
CREATE VIEW vw_OrderDetailsFull AS
SELECT 
    o.order_id,
    o.order_code,
    o.order_date,
    c.full_name as customer_name,
    c.phone_number as customer_phone,
    b.book_code,
    b.title as book_title,
    od.quantity,
    od.unit_price,
    od.subtotal,
    o.total_amount,
    o.status
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN OrderDetails od ON o.order_id = od.order_id
JOIN Books b ON od.book_id = b.book_id;
GO

-- 67. PROCEDURE: Tạo đơn hàng đầy đủ
GO
-- Trước tiên tạo TYPE nếu chưa có
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'OrderItemType')
CREATE TYPE OrderItemType AS TABLE (
    book_id INT,
    quantity INT
);
GO

CREATE PROCEDURE sp_CreateFullOrder
    @customer_id_param INT,
    @order_items AS OrderItemType READONLY
AS
BEGIN
    DECLARE @order_code VARCHAR(20);
    DECLARE @order_id_var INT;
    DECLARE @current_price DECIMAL(10,2);
    
    SET @order_code = 'DH' + FORMAT(GETDATE(), 'yyyyMMddHHmmss');
    
    INSERT INTO Orders (order_code, customer_id, order_date)
    VALUES (@order_code, @customer_id_param, GETDATE());
    
    SET @order_id_var = SCOPE_IDENTITY();
    
    -- Thêm từng sản phẩm vào đơn hàng
    DECLARE item_cursor CURSOR FOR
    SELECT book_id, quantity FROM @order_items;
    
    DECLARE @book_id_var INT, @quantity_var INT;
    
    OPEN item_cursor;
    FETCH NEXT FROM item_cursor INTO @book_id_var, @quantity_var;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Lấy giá hiện tại của sách
        SELECT @current_price = price FROM Books WHERE book_id = @book_id_var;
        
        INSERT INTO OrderDetails (order_id, book_id, quantity, unit_price, subtotal)
        VALUES (@order_id_var, @book_id_var, @quantity_var, @current_price, @quantity_var * @current_price);
        
        FETCH NEXT FROM item_cursor INTO @book_id_var, @quantity_var;
    END
    
    CLOSE item_cursor;
    DEALLOCATE item_cursor;
    
    -- Tính tổng tiền
    DECLARE @total_amount_var DECIMAL(12,2);
    SELECT @total_amount_var = SUM(subtotal) FROM OrderDetails WHERE order_id = @order_id_var;
    
    UPDATE Orders
    SET total_amount = ISNULL(@total_amount_var, 0)
    WHERE order_id = @order_id_var;
    
    SELECT @order_id_var as order_id, @order_code as order_code;
END;
GO

-- 68. TRIGGER: Tự động cập nhật tồn kho khi tạo đơn
GO
CREATE TRIGGER trg_UpdateStockOnOrder
ON OrderDetails
AFTER INSERT
AS
BEGIN
    UPDATE b
    SET b.quantity_in_stock = b.quantity_in_stock - i.quantity
    FROM Books b
    JOIN inserted i ON b.book_id = i.book_id;
END;
GO

-- 69. TRIGGER: Hoàn trả tồn kho khi hủy đơn
GO
CREATE TRIGGER trg_RestoreStockOnCancel
ON Orders
AFTER UPDATE
AS
BEGIN
    IF UPDATE(status)
    BEGIN
        IF EXISTS(SELECT 1 FROM inserted WHERE status = 'Cancelled')
        BEGIN
            UPDATE b
            SET b.quantity_in_stock = b.quantity_in_stock + od.quantity
            FROM Books b
            JOIN OrderDetails od ON b.book_id = od.book_id
            JOIN inserted i ON od.order_id = i.order_id
            WHERE i.status = 'Cancelled';
        END
    END
END;
GO

-- 70. PROCEDURE: Tính toán tổng tiền đơn hàng
GO
CREATE PROCEDURE sp_CalculateOrderTotal
    @order_id_param INT
AS
BEGIN
    DECLARE @total_var DECIMAL(12,2);
    
    SELECT @total_var = SUM(subtotal)
    FROM OrderDetails
    WHERE order_id = @order_id_param;
    
    UPDATE Orders
    SET total_amount = ISNULL(@total_var, 0)
    WHERE order_id = @order_id_param;
    
    SELECT @total_var as total_amount;
END;
GO

-- 71. VIEW: Đơn hàng cần xử lý
GO
CREATE VIEW vw_PendingOrders AS
SELECT 
    o.order_id,
    o.order_code,
    o.order_date,
    c.full_name,
    c.phone_number,
    o.total_amount,
    COUNT(od.order_detail_id) as item_count
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
LEFT JOIN OrderDetails od ON o.order_id = od.order_id
WHERE o.status = 'Pending'
GROUP BY o.order_id, o.order_code, o.order_date, 
         c.full_name, c.phone_number, o.total_amount;
GO

-- 72. PROCEDURE: Thống kê đơn hàng theo tháng
GO
CREATE PROCEDURE sp_OrderStatsByMonth
    @year_param INT = NULL,
    @month_param INT = NULL
AS
BEGIN
    DECLARE @year_var INT, @month_var INT;
    
    SET @year_var = ISNULL(@year_param, YEAR(GETDATE()));
    SET @month_var = ISNULL(@month_param, MONTH(GETDATE()));
    
    SELECT 
        COUNT(*) as total_orders,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value,
        MIN(total_amount) as min_order_value,
        MAX(total_amount) as max_order_value
    FROM Orders
    WHERE YEAR(order_date) = @year_var 
      AND MONTH(order_date) = @month_var
      AND status = 'Completed';
END;
GO

-- 73. INDEX: Tối ưu tìm kiếm đơn hàng
GO
CREATE INDEX idx_Orders_CustomerId ON Orders(customer_id);
GO
CREATE INDEX idx_Orders_OrderDate ON Orders(order_date);
GO
CREATE INDEX idx_Orders_Status ON Orders(status);
GO
CREATE INDEX idx_OrderDetails_OrderId ON OrderDetails(order_id);
GO
CREATE INDEX idx_OrderDetails_BookId ON OrderDetails(book_id);
GO

-- 74. FUNCTION: Kiểm tra tồn kho trước khi đặt
GO
CREATE FUNCTION fn_CheckStockBeforeOrder(@book_id_param INT, @quantity_param INT)
RETURNS BIT
AS
BEGIN
    DECLARE @available INT;
    DECLARE @result BIT;
    
    SELECT @available = quantity_in_stock 
    FROM Books 
    WHERE book_id = @book_id_param;
    
    IF @available >= @quantity_param
        SET @result = 1;
    ELSE
        SET @result = 0;
    
    RETURN @result;
END;
GO

-- 75. PROCEDURE: Xử lý thanh toán đơn hàng
GO
CREATE PROCEDURE sp_ProcessOrderPayment
    @order_id_param INT,
    @payment_method NVARCHAR(50),
    @payment_amount_param DECIMAL(12,2)
AS
BEGIN
    DECLARE @order_total DECIMAL(12,2);
    DECLARE @customer_id_var INT;
    
    SELECT @order_total = total_amount, @customer_id_var = customer_id
    FROM Orders
    WHERE order_id = @order_id_param AND status = 'Pending';
    
    IF @order_total IS NULL
    BEGIN
        RAISERROR('Đơn hàng không tồn tại hoặc đã xử lý', 16, 1);
        RETURN;
    END
    
    IF @payment_amount_param < @order_total
    BEGIN
        RAISERROR('Số tiền thanh toán không đủ', 16, 1);
        RETURN;
    END
    
    UPDATE Orders
    SET status = 'Completed'
    WHERE order_id = @order_id_param;
    
    UPDATE Customers
    SET total_orders = total_orders + 1,
        total_spent = total_spent + @order_total
    WHERE customer_id = @customer_id_var;
    
    SELECT 'Success' as result, @order_id_param as order_id;
END;
GO

-- ======================================================
-- PHẦN 4: THI (NHẬP SÁCH) - 25 CÂU
-- ======================================================

-- *** 15 CÂU CƠ BẢN ***

-- 76. Tạo phiếu nhập
INSERT INTO ImportBooks (import_code, import_date, supplier)
VALUES ('PN001', GETDATE(), N'Nhà sách ABC');
GO

-- 77. Thêm sách vào phiếu nhập
INSERT INTO ImportDetails (import_id, book_id, quantity, unit_price, subtotal)
VALUES (1, 1, 50, 100000, 5000000);
GO

-- 78. Lấy tất cả phiếu nhập
SELECT * FROM ImportBooks ORDER BY import_date DESC;
GO

-- 79. Lấy chi tiết phiếu nhập
SELECT ib.*, b.title, b.book_code, id.quantity, id.unit_price, id.subtotal
FROM ImportBooks ib
JOIN ImportDetails id ON ib.import_id = id.import_id
JOIN Books b ON id.book_id = b.book_id
WHERE ib.import_id = 1;
GO

-- 80. Cập nhật thông tin nhà cung cấp
UPDATE ImportBooks SET supplier = N'NXB Giáo dục' WHERE import_id = 1;
GO

-- 81. Xóa phiếu nhập
DELETE FROM ImportBooks WHERE import_id = 1;
GO

-- 82. Xóa sách khỏi phiếu nhập
DELETE FROM ImportDetails WHERE import_detail_id = 1;
GO

-- 83. Nhập sách trong tháng
SELECT * FROM ImportBooks 
WHERE MONTH(import_date) = MONTH(GETDATE()) 
AND YEAR(import_date) = YEAR(GETDATE());
GO

-- 84. Nhập sách theo nhà cung cấp
SELECT * FROM ImportBooks WHERE supplier LIKE N'%NXB%';
GO

-- 85. Cập nhật số lượng nhập
UPDATE ImportDetails 
SET quantity = 100, subtotal = 100 * unit_price 
WHERE import_detail_id = 1;
GO

-- 86. Đếm số phiếu nhập
SELECT COUNT(*) as total_imports FROM ImportBooks;
GO

-- 87. Tổng giá trị nhập kho
SELECT SUM(total_amount) as total_import_value FROM ImportBooks;
GO

-- 88. Phiếu nhập có giá trị cao nhất
SELECT TOP 1 * FROM ImportBooks ORDER BY total_amount DESC;
GO

-- 89. Nhập sách theo sách
SELECT ib.* 
FROM ImportBooks ib
JOIN ImportDetails id ON ib.import_id = id.import_id
WHERE id.book_id = 1;
GO

-- 90. Phân trang phiếu nhập
SELECT * FROM ImportBooks 
ORDER BY import_id DESC 
OFFSET 0 ROWS 
FETCH NEXT 20 ROWS ONLY;
GO


-- *** 10 CÂU NÂNG CAO ***

-- 91. VIEW: Chi tiết phiếu nhập đầy đủ
GO
CREATE VIEW vw_FullImportDetails AS
SELECT 
    ib.import_id,
    ib.import_code,
    ib.import_date,
    ib.supplier,
    b.book_code,
    b.title,
    b.author,
    id.quantity,
    id.unit_price,
    id.subtotal,
    ib.total_amount
FROM ImportBooks ib
JOIN ImportDetails id ON ib.import_id = id.import_id
JOIN Books b ON id.book_id = b.book_id;
GO

-- 92. PROCEDURE: Tạo phiếu nhập đầy đủ
GO
-- Tạo TYPE nếu chưa có
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'ImportItemType')
CREATE TYPE ImportItemType AS TABLE (
    book_id INT,
    quantity INT,
    unit_price DECIMAL(10,2)
);
GO

CREATE PROCEDURE sp_CreateFullImport
    @supplier_param NVARCHAR(100),
    @import_items AS ImportItemType READONLY
AS
BEGIN
    DECLARE @import_code VARCHAR(20);
    DECLARE @import_id_var INT;
    DECLARE @total_amount_var DECIMAL(12,2);
    
    SET @import_code = 'PN' + FORMAT(GETDATE(), 'yyyyMMddHHmmss');
    SET @total_amount_var = 0;
    
    INSERT INTO ImportBooks (import_code, import_date, supplier)
    VALUES (@import_code, GETDATE(), @supplier_param);
    
    SET @import_id_var = SCOPE_IDENTITY();
    
    -- Thêm chi tiết nhập
    INSERT INTO ImportDetails (import_id, book_id, quantity, unit_price, subtotal)
    SELECT @import_id_var, book_id, quantity, unit_price, quantity * unit_price
    FROM @import_items;
    
    -- Tính tổng tiền
    SELECT @total_amount_var = SUM(quantity * unit_price)
    FROM @import_items;
    
    -- Cập nhật tổng tiền phiếu nhập
    UPDATE ImportBooks
    SET total_amount = @total_amount_var
    WHERE import_id = @import_id_var;
    
    -- Cập nhật tồn kho sách
    UPDATE b
    SET b.quantity_in_stock = b.quantity_in_stock + ii.quantity,
        b.updated_date = GETDATE()
    FROM Books b
    JOIN @import_items ii ON b.book_id = ii.book_id;
    
    SELECT @import_id_var as import_id, @import_code as import_code, @total_amount_var as total_amount;
END;
GO

-- 93. TRIGGER: Tự động cập nhật tổng tiền phiếu nhập
GO
CREATE TRIGGER trg_AutoUpdateImportTotal
ON ImportDetails
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @import_id_var INT;
    
    -- Lấy import_id từ inserted hoặc deleted
    SELECT TOP 1 @import_id_var = import_id FROM inserted;
    IF @import_id_var IS NULL
        SELECT TOP 1 @import_id_var = import_id FROM deleted;
    
    -- Cập nhật tổng tiền
    UPDATE ImportBooks
    SET total_amount = (
        SELECT ISNULL(SUM(subtotal), 0)
        FROM ImportDetails
        WHERE import_id = @import_id_var
    )
    WHERE import_id = @import_id_var;
END;
GO

-- 94. TRIGGER: Tự động cập nhật tồn kho khi nhập
GO
CREATE TRIGGER trg_AutoUpdateStockOnImport
ON ImportDetails
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Xử lý inserted (thêm/cập nhật)
    UPDATE b
    SET b.quantity_in_stock = b.quantity_in_stock + 
        (SELECT ISNULL(SUM(quantity), 0) FROM inserted i WHERE i.book_id = b.book_id) -
        (SELECT ISNULL(SUM(quantity), 0) FROM deleted d WHERE d.book_id = b.book_id)
    FROM Books b
    WHERE b.book_id IN (
        SELECT book_id FROM inserted 
        UNION 
        SELECT book_id FROM deleted
    );
END;
GO

-- 95. VIEW: Thống kê nhập sách theo nhà cung cấp
GO
CREATE VIEW vw_ImportStatsBySupplier AS
SELECT 
    supplier,
    COUNT(*) as import_count,
    SUM(total_amount) as total_value,
    AVG(total_amount) as avg_import_value,
    MIN(import_date) as first_import,
    MAX(import_date) as last_import
FROM ImportBooks
GROUP BY supplier;
GO

-- 96. PROCEDURE: Báo cáo nhập sách theo tháng
GO
CREATE PROCEDURE sp_ImportReportByMonth
    @year_param INT,
    @month_param INT
AS
BEGIN
    SELECT 
        ib.import_code,
        ib.import_date,
        ib.supplier,
        b.book_code,
        b.title,
        id.quantity,
        id.unit_price,
        id.subtotal,
        ib.total_amount
    FROM ImportBooks ib
    JOIN ImportDetails id ON ib.import_id = id.import_id
    JOIN Books b ON id.book_id = b.book_id
    WHERE YEAR(ib.import_date) = @year_param 
      AND MONTH(ib.import_date) = @month_param
    ORDER BY ib.import_date DESC;
END;
GO

-- 97. INDEX: Tối ưu tìm kiếm phiếu nhập
GO
CREATE INDEX idx_ImportBooks_Supplier ON ImportBooks(supplier);
GO
CREATE INDEX idx_ImportBooks_ImportDate ON ImportBooks(import_date);
GO
CREATE INDEX idx_ImportDetails_ImportId ON ImportDetails(import_id);
GO
CREATE INDEX idx_ImportDetails_BookId ON ImportDetails(book_id);
GO

-- 98. FUNCTION: Tính tổng nhập của sách
GO
CREATE FUNCTION fn_CalculateTotalImported(@book_id_param INT)
RETURNS INT
AS
BEGIN
    DECLARE @total_imported INT;
    
    SELECT @total_imported = SUM(quantity)
    FROM ImportDetails
    WHERE book_id = @book_id_param;
    
    RETURN ISNULL(@total_imported, 0);
END;
GO

-- 99. PROCEDURE: Xuất báo cáo nhập sách
GO
CREATE PROCEDURE sp_ExportImportReport
    @start_date_param DATE,
    @end_date_param DATE
AS
BEGIN
    SELECT 
        ib.import_code as 'Mã phiếu',
        CONVERT(VARCHAR, ib.import_date, 103) as 'Ngày nhập',
        ib.supplier as 'Nhà cung cấp',
        b.book_code as 'Mã sách',
        b.title as 'Tên sách',
        id.quantity as 'Số lượng',
        FORMAT(id.unit_price, '#,#') as 'Đơn giá',
        FORMAT(id.subtotal, '#,#') as 'Thành tiền',
        FORMAT(ib.total_amount, '#,#') as 'Tổng cộng'
    FROM ImportBooks ib
    JOIN ImportDetails id ON ib.import_id = id.import_id
    JOIN Books b ON id.book_id = b.book_id
    WHERE ib.import_date BETWEEN @start_date_param AND @end_date_param
    ORDER BY ib.import_date DESC;
END;
GO

-- 100. PROCEDURE: Tìm phiếu nhập với điều kiện
GO
CREATE PROCEDURE sp_SearchImports
    @supplier_param NVARCHAR(100) = NULL,
    @start_date_param DATE = NULL,
    @end_date_param DATE = NULL,
    @min_amount_param DECIMAL(12,2) = NULL,
    @max_amount_param DECIMAL(12,2) = NULL
AS
BEGIN
    SELECT * FROM ImportBooks 
    WHERE (@supplier_param IS NULL OR supplier LIKE '%' + @supplier_param + '%')
      AND (@start_date_param IS NULL OR import_date >= @start_date_param)
      AND (@end_date_param IS NULL OR import_date <= @end_date_param)
      AND (@min_amount_param IS NULL OR total_amount >= @min_amount_param)
      AND (@max_amount_param IS NULL OR total_amount <= @max_amount_param)
    ORDER BY import_date DESC;
END;
GO

-- ======================================================
-- PHẦN 5: HƯỚNG (BÁO CÁO & THỐNG KÊ) - 25 CÂU
-- ======================================================

-- *** 15 CÂU CƠ BẢN ***

-- 101. Doanh thu theo ngày
SELECT CONVERT(DATE, order_date) as ngay, SUM(total_amount) as doanh_thu
FROM Orders 
WHERE status = 'Completed'
GROUP BY CONVERT(DATE, order_date)
ORDER BY ngay DESC;
GO

-- 102. Số đơn hàng theo trạng thái
SELECT status, COUNT(*) as so_don
FROM Orders 
GROUP BY status;
GO

-- 103. Top 10 khách hàng mua nhiều nhất
SELECT TOP 10 c.full_name, SUM(o.total_amount) as tong_tien
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.full_name
ORDER BY tong_tien DESC;
GO

-- 104. Top 10 sách bán chạy nhất
SELECT TOP 10 b.title, SUM(od.quantity) as so_luong_ban
FROM Books b
JOIN OrderDetails od ON b.book_id = od.book_id
JOIN Orders o ON od.order_id = o.order_id AND o.status = 'Completed'
GROUP BY b.book_id, b.title
ORDER BY so_luong_ban DESC;
GO

-- 105. Doanh thu theo tháng
SELECT YEAR(order_date) as nam, MONTH(order_date) as thang, 
       SUM(total_amount) as doanh_thu
FROM Orders 
WHERE status = 'Completed'
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY nam DESC, thang DESC;
GO

-- 106. Thống kê tồn kho
SELECT publisher, COUNT(*) as so_sach, SUM(quantity_in_stock) as tong_ton_kho,
       SUM(quantity_in_stock * price) as gia_tri_ton_kho
FROM Books
GROUP BY publisher
ORDER BY gia_tri_ton_kho DESC;
GO

-- 107. Sách sắp hết hàng
SELECT * FROM Books 
WHERE quantity_in_stock < 10
ORDER BY quantity_in_stock ASC;
GO

-- 108. Doanh thu theo khung giờ
SELECT DATEPART(HOUR, created_date) as gio, 
       COUNT(*) as so_don,
       SUM(total_amount) as doanh_thu
FROM Orders 
WHERE status = 'Completed' 
  AND CONVERT(DATE, created_date) = CONVERT(DATE, GETDATE())
GROUP BY DATEPART(HOUR, created_date)
ORDER BY gio;
GO

-- 109. Khách hàng mới theo tháng
SELECT YEAR(created_date) as nam, MONTH(created_date) as thang, 
       COUNT(*) as khach_hang_moi
FROM Customers
GROUP BY YEAR(created_date), MONTH(created_date)
ORDER BY nam DESC, thang DESC;
GO

-- 110. Tỷ lệ hoàn thành đơn hàng
DECLARE @completed INT, @total INT;
SELECT @completed = COUNT(*) FROM Orders WHERE status = 'Completed';
SELECT @total = COUNT(*) FROM Orders;

SELECT 
    CASE 
        WHEN @total > 0 THEN (@completed * 100.0 / @total)
        ELSE 0 
    END as ty_le_hoan_thanh;
GO

-- 111. Giá trị trung bình đơn hàng
SELECT AVG(total_amount) as gia_tri_trung_binh_don
FROM Orders 
WHERE status = 'Completed';
GO

-- 112. Số lượng nhập theo tháng
SELECT YEAR(import_date) as nam, MONTH(import_date) as thang,
       COUNT(*) as so_phieu_nhap,
       SUM(total_amount) as gia_tri_nhap
FROM ImportBooks
GROUP BY YEAR(import_date), MONTH(import_date)
ORDER BY nam DESC, thang DESC;
GO

-- 113. Top nhà cung cấp
SELECT supplier, COUNT(*) as so_phieu, SUM(total_amount) as tong_gia_tri
FROM ImportBooks
GROUP BY supplier
ORDER BY tong_gia_tri DESC;
GO

-- 114. Sách không bán được trong tháng
SELECT b.* 
FROM Books b
LEFT JOIN OrderDetails od ON b.book_id = od.book_id
LEFT JOIN Orders o ON od.order_id = o.order_id 
  AND o.status = 'Completed' 
  AND MONTH(o.order_date) = MONTH(GETDATE())
WHERE od.order_detail_id IS NULL;
GO

-- 115. Thống kê theo độ tuổi sách
SELECT 
    CASE 
        WHEN publish_year >= YEAR(GETDATE()) - 1 THEN 'Mới (<=1 năm)'
        WHEN publish_year >= YEAR(GETDATE()) - 3 THEN 'Trung bình (1-3 năm)'
        ELSE 'Cũ (>3 năm)'
    END as do_tuoi,
    COUNT(*) as so_sach,
    SUM(quantity_in_stock) as tong_ton
FROM Books
GROUP BY CASE 
        WHEN publish_year >= YEAR(GETDATE()) - 1 THEN 'Mới (<=1 năm)'
        WHEN publish_year >= YEAR(GETDATE()) - 3 THEN 'Trung bình (1-3 năm)'
        ELSE 'Cũ (>3 năm)'
    END;
GO


-- *** 10 CÂU NÂNG CAO ***

-- 116. VIEW: Báo cáo tổng hợp hàng tháng
GO
CREATE VIEW vw_MonthlySummaryReport AS
WITH MonthlyStats AS (
    SELECT 
        YEAR(order_date) as report_year,
        MONTH(order_date) as report_month,
        COUNT(*) as total_orders,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value
    FROM Orders 
    WHERE status = 'Completed'
    GROUP BY YEAR(order_date), MONTH(order_date)
),
CustomerStats AS (
    SELECT 
        YEAR(created_date) as report_year,
        MONTH(created_date) as report_month,
        COUNT(*) as new_customers
    FROM Customers
    GROUP BY YEAR(created_date), MONTH(created_date)
),
ImportStats AS (
    SELECT 
        YEAR(import_date) as report_year,
        MONTH(import_date) as report_month,
        SUM(total_amount) as total_import_value
    FROM ImportBooks
    GROUP BY YEAR(import_date), MONTH(import_date)
)
SELECT 
    COALESCE(m.report_year, c.report_year, i.report_year) as year,
    COALESCE(m.report_month, c.report_month, i.report_month) as month,
    ISNULL(m.total_orders, 0) as total_orders,
    ISNULL(m.total_revenue, 0) as total_revenue,
    ISNULL(m.avg_order_value, 0) as avg_order_value,
    ISNULL(c.new_customers, 0) as new_customers,
    ISNULL(i.total_import_value, 0) as total_import_value,
    ISNULL(m.total_revenue, 0) - ISNULL(i.total_import_value, 0) as profit
FROM MonthlyStats m
FULL OUTER JOIN CustomerStats c ON m.report_year = c.report_year AND m.report_month = c.report_month
FULL OUTER JOIN ImportStats i ON m.report_year = i.report_year AND m.report_month = i.report_month;
GO

-- 117. PROCEDURE: Báo cáo doanh thu theo khoảng thời gian
GO
CREATE PROCEDURE sp_RevenueReportByDateRange
    @start_date_param DATE,
    @end_date_param DATE
AS
BEGIN
    -- Tổng doanh thu
    SELECT 
        'Tổng doanh thu' as metric,
        COUNT(*) as total_orders,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value
    FROM Orders 
    WHERE status = 'Completed'
      AND order_date BETWEEN @start_date_param AND @end_date_param;
    
    -- Doanh thu theo ngày
    SELECT 
        'Doanh thu theo ngày' as metric,
        COUNT(DISTINCT CONVERT(DATE, order_date)) as total_days,
        SUM(total_amount) as total_revenue,
        0 as avg_order_value
    FROM Orders 
    WHERE status = 'Completed'
      AND order_date BETWEEN @start_date_param AND @end_date_param;
END;
GO

-- 118. PROCEDURE: Báo cáo tồn kho chi tiết
GO
CREATE PROCEDURE sp_DetailedInventoryReport
AS
BEGIN
    SELECT 
        b.book_code as 'Mã sách',
        b.title as 'Tên sách',
        b.author as 'Tác giả',
        b.publisher as 'NXB',
        b.publish_year as 'Năm XB',
        b.quantity_in_stock as 'Tồn kho',
        b.price as 'Giá bán',
        (b.quantity_in_stock * b.price) as 'Giá trị tồn kho',
        ISNULL(s.total_sold, 0) as 'Đã bán',
        ISNULL(CONVERT(VARCHAR, s.last_sale_date, 103), 'Chưa bán') as 'Ngày bán cuối'
    FROM Books b
    LEFT JOIN (
        SELECT 
            od.book_id,
            SUM(od.quantity) as total_sold,
            MAX(o.order_date) as last_sale_date
        FROM OrderDetails od
        JOIN Orders o ON od.order_id = o.order_id AND o.status = 'Completed'
        GROUP BY od.book_id
    ) s ON b.book_id = s.book_id
    ORDER BY (b.quantity_in_stock * b.price) DESC;
END;
GO

-- 119. VIEW: Biểu đồ doanh thu 12 tháng gần nhất
GO
CREATE VIEW vw_Last12MonthsRevenue AS
WITH Last12Months AS (
    SELECT 
        YEAR(order_date) as report_year,
        MONTH(order_date) as report_month,
        DATENAME(MONTH, order_date) as month_name,
        SUM(total_amount) as revenue
    FROM Orders 
    WHERE status = 'Completed'
      AND order_date >= DATEADD(MONTH, -11, GETDATE())
    GROUP BY YEAR(order_date), MONTH(order_date), DATENAME(MONTH, order_date)
)
SELECT * FROM Last12Months;
GO

-- 120. PROCEDURE: Phân tích RFM khách hàng
GO
CREATE PROCEDURE sp_RFMAnalysis
AS
BEGIN
    WITH CustomerRFM AS (
        SELECT 
            c.customer_id,
            c.full_name,
            c.customer_code,
            DATEDIFF(DAY, MAX(o.order_date), GETDATE()) as recency,
            COUNT(o.order_id) as frequency,
            SUM(o.total_amount) as monetary
        FROM Customers c
        LEFT JOIN Orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
        GROUP BY c.customer_id, c.full_name, c.customer_code
    ),
    RFM_Scores AS (
        SELECT *,
            NTILE(5) OVER (ORDER BY recency DESC) as R_Score,
            NTILE(5) OVER (ORDER BY frequency ASC) as F_Score,
            NTILE(5) OVER (ORDER BY monetary ASC) as M_Score
        FROM CustomerRFM
    )
    SELECT *,
        (R_Score + F_Score + M_Score) as RFM_Total,
        CASE 
            WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'VIP'
            WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3 THEN 'Trung thành'
            WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score <= 2 THEN 'Nguy cơ mất'
            ELSE 'Bình thường'
        END as customer_segment
    FROM RFM_Scores
    ORDER BY RFM_Total DESC;
END;
GO

-- 121. FUNCTION: Dự báo nhu cầu sách
GO
CREATE FUNCTION fn_ForecastBookDemand(@book_id_param INT)
RETURNS @forecast TABLE (
    month_num INT,
    year_num INT,
    predicted_demand INT
)
AS
BEGIN
    DECLARE @avg_monthly_sales INT;
    
    -- Tính trung bình bán hàng 3 tháng gần nhất
    SELECT @avg_monthly_sales = AVG(monthly_sales)
    FROM (
        SELECT 
            MONTH(o.order_date) as month_num,
            YEAR(o.order_date) as year_num,
            SUM(od.quantity) as monthly_sales
        FROM OrderDetails od
        JOIN Orders o ON od.order_id = o.order_id 
            AND o.status = 'Completed'
            AND o.order_date >= DATEADD(MONTH, -3, GETDATE())
        WHERE od.book_id = @book_id_param
        GROUP BY YEAR(o.order_date), MONTH(o.order_date)
    ) sales_data;
    
    -- Dự báo cho 3 tháng tới
    DECLARE @current_month INT = MONTH(GETDATE());
    DECLARE @current_year INT = YEAR(GETDATE());
    
    INSERT INTO @forecast VALUES (@current_month, @current_year, ISNULL(@avg_monthly_sales, 0));
    
    SET @current_month = @current_month + 1;
    IF @current_month > 12
    BEGIN
        SET @current_month = 1;
        SET @current_year = @current_year + 1;
    END
    INSERT INTO @forecast VALUES (@current_month, @current_year, ISNULL(@avg_monthly_sales, 0));
    
    SET @current_month = @current_month + 1;
    IF @current_month > 12
    BEGIN
        SET @current_month = 1;
        SET @current_year = @current_year + 1;
    END
    INSERT INTO @forecast VALUES (@current_month, @current_year, ISNULL(@avg_monthly_sales, 0));
    
    RETURN;
END;
GO

-- 122. PROCEDURE: Báo cáo hiệu quả nhà cung cấp
GO
CREATE PROCEDURE sp_SupplierPerformanceReport
    @start_date_param DATE,
    @end_date_param DATE
AS
BEGIN
    SELECT 
        ib.supplier as 'Nhà cung cấp',
        COUNT(DISTINCT ib.import_id) as 'Số phiếu nhập',
        SUM(id.quantity) as 'Tổng số lượng nhập',
        SUM(ib.total_amount) as 'Tổng giá trị nhập',
        AVG(ib.total_amount) as 'Giá trị TB/phiếu',
        MIN(ib.import_date) as 'Ngày nhập đầu',
        MAX(ib.import_date) as 'Ngày nhập cuối'
    FROM ImportBooks ib
    JOIN ImportDetails id ON ib.import_id = id.import_id
    WHERE ib.import_date BETWEEN @start_date_param AND @end_date_param
    GROUP BY ib.supplier
    ORDER BY SUM(ib.total_amount) DESC;
END;
GO

-- 123. VIEW: Dashboard tổng quan
GO
CREATE VIEW vw_DashboardOverview AS
WITH TodayStats AS (
    SELECT 
        COUNT(*) as today_orders,
        SUM(total_amount) as today_revenue
    FROM Orders 
    WHERE CONVERT(DATE, order_date) = CONVERT(DATE, GETDATE())
      AND status = 'Completed'
),
MonthStats AS (
    SELECT 
        COUNT(*) as month_orders,
        SUM(total_amount) as month_revenue
    FROM Orders 
    WHERE YEAR(order_date) = YEAR(GETDATE())
      AND MONTH(order_date) = MONTH(GETDATE())
      AND status = 'Completed'
),
LowStock AS (
    SELECT COUNT(*) as low_stock_count
    FROM Books 
    WHERE quantity_in_stock < 10
),
PendingOrders AS (
    SELECT COUNT(*) as pending_orders
    FROM Orders 
    WHERE status = 'Pending'
)
SELECT 
    ts.today_orders,
    ts.today_revenue,
    ms.month_orders,
    ms.month_revenue,
    ls.low_stock_count,
    po.pending_orders
FROM TodayStats ts, MonthStats ms, LowStock ls, PendingOrders po;
GO

-- 124. PROCEDURE: Phân tích lợi nhuận theo sách
GO
CREATE PROCEDURE sp_ProfitAnalysisByBook
AS
BEGIN
    WITH SalesData AS (
        SELECT 
            od.book_id,
            SUM(od.quantity) as total_sold,
            SUM(od.subtotal) as total_revenue
        FROM OrderDetails od
        JOIN Orders o ON od.order_id = o.order_id AND o.status = 'Completed'
        GROUP BY od.book_id
    ),
    ImportData AS (
        SELECT 
            id.book_id,
            SUM(id.quantity) as total_imported,
            AVG(id.unit_price) as avg_import_price,
            SUM(id.subtotal) as total_import_cost
        FROM ImportDetails id
        GROUP BY id.book_id
    )
    SELECT 
        b.book_code,
        b.title,
        b.author,
        b.publisher,
        ISNULL(sd.total_sold, 0) as total_sold,
        ISNULL(sd.total_revenue, 0) as total_revenue,
        ISNULL(id.total_imported, 0) as total_imported,
        ISNULL(id.total_import_cost, 0) as total_import_cost,
        ISNULL(sd.total_revenue, 0) - ISNULL(id.total_import_cost, 0) as profit,
        CASE 
            WHEN ISNULL(id.total_import_cost, 0) > 0 
            THEN ((ISNULL(sd.total_revenue, 0) - ISNULL(id.total_import_cost, 0)) / ISNULL(id.total_import_cost, 0)) * 100
            ELSE 0 
        END as profit_margin_percent
    FROM Books b
    LEFT JOIN SalesData sd ON b.book_id = sd.book_id
    LEFT JOIN ImportData id ON b.book_id = id.book_id
    ORDER BY profit DESC;
END;
GO

-- 125. PROCEDURE: Xuất báo cáo toàn hệ thống
GO
CREATE PROCEDURE sp_ExportSystemReport
    @report_date_param DATE = NULL
AS
BEGIN
    DECLARE @report_date_var DATE;
    SET @report_date_var = ISNULL(@report_date_param, GETDATE());
    
    -- Header
    SELECT 
        'BÁO CÁO TỔNG HỢP HỆ THỐNG' as report_title,
        FORMAT(@report_date_var, 'dd/MM/yyyy') as report_date;
    
    -- Tổng quan
    SELECT 
        'TỔNG QUAN' as section,
        (SELECT COUNT(*) FROM Customers) as total_customers,
        (SELECT COUNT(*) FROM Books) as total_books,
        (SELECT COUNT(*) FROM Orders) as total_orders,
        (SELECT ISNULL(SUM(total_amount), 0) FROM Orders WHERE status = 'Completed') as total_revenue,
        (SELECT COUNT(*) FROM Books WHERE quantity_in_stock < 10) as low_stock_books;
    
    -- Top 5 sách bán chạy
    SELECT TOP 5
        'TOP 5 SÁCH BÁN CHẠY' as section,
        ROW_NUMBER() OVER (ORDER BY SUM(od.quantity) DESC) as rank_num,
        b.title,
        b.author,
        SUM(od.quantity) as total_sold,
        SUM(od.subtotal) as total_revenue
    FROM Books b
    JOIN OrderDetails od ON b.book_id = od.book_id
    JOIN Orders o ON od.order_id = o.order_id AND o.status = 'Completed'
    GROUP BY b.book_id, b.title, b.author
    ORDER BY total_sold DESC;
    
    -- Top 5 khách hàng
    SELECT TOP 5
        'TOP 5 KHÁCH HÀNG' as section,
        ROW_NUMBER() OVER (ORDER BY SUM(o.total_amount) DESC) as rank_num,
        c.full_name,
        c.phone_number,
        COUNT(o.order_id) as total_orders,
        SUM(o.total_amount) as total_spent
    FROM Customers c
    JOIN Orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
    GROUP BY c.customer_id, c.full_name, c.phone_number
    ORDER BY total_spent DESC;
    
    -- Cảnh báo
    SELECT 
        'CẢNH BÁO' as section,
        'Sách sắp hết hàng' as warning_type,
        b.title,
        b.quantity_in_stock
    FROM Books b
    WHERE b.quantity_in_stock < 10
    ORDER BY b.quantity_in_stock ASC;
END;
GO

-- ======================================================
-- KẾT THÚC FILE
-- Tổng cộng: 125 câu truy vấn
-- ======================================================