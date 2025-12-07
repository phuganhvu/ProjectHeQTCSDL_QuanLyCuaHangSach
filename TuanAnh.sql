-- TUẤN ANH (ĐƠN HÀNG) - 5 CÂU
-- ======================================================

-- 11. Tạo đơn hàng mới (dùng mã duy nhất)
INSERT INTO Orders (order_code, customer_id, order_date, status)
VALUES ('DH' + FORMAT(GETDATE(), 'yyyyMMddHHmmss'), 1, GETDATE(), 'Pending');

-- 12. Thêm sản phẩm vào đơn hàng
INSERT INTO OrderDetails (order_id, book_id, quantity, unit_price, subtotal)
VALUES (1, 1, 2, 150000, 300000);

-- 13. Lấy chi tiết đơn hàng
SELECT 
    o.order_code,
    o.order_date,
    c.full_name as khach_hang,
    b.title as ten_sach,
    od.quantity as so_luong,
    od.unit_price as don_gia,
    od.subtotal as thanh_tien,
    o.total_amount as tong_tien,
    o.status as trang_thai
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN OrderDetails od ON o.order_id = od.order_id
JOIN Books b ON od.book_id = b.book_id
WHERE o.order_id = 1;

-- 14. Cập nhật trạng thái đơn hàng
UPDATE Orders SET status = 'Completed' WHERE order_id = 1;

-- 15. Hủy đơn hàng (sửa lỗi nesting level)
DECLARE @order_id_to_cancel INT = 1;

-- Kiểm tra đơn hàng tồn tại
IF EXISTS(SELECT 1 FROM Orders WHERE order_id = @order_id_to_cancel)
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Hoàn trả tồn kho
        UPDATE b
        SET b.quantity_in_stock = b.quantity_in_stock + od.quantity
        FROM Books b
        JOIN OrderDetails od ON b.book_id = od.book_id
        WHERE od.order_id = @order_id_to_cancel;
        
        -- Cập nhật trạng thái đơn hàng
        UPDATE Orders 
        SET status = 'Cancelled'
        WHERE order_id = @order_id_to_cancel;
        
        COMMIT TRANSACTION;
        PRINT 'Đã hủy đơn hàng và hoàn trả tồn kho';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Lỗi khi hủy đơn hàng: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT 'Đơn hàng không tồn tại';
END

-- TRIGGER: Cập nhật tồn kho khi tạo đơn (ĐƠN GIẢN)
GO
CREATE OR ALTER TRIGGER trg_UpdateStockWhenOrderCreated
ON OrderDetails
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE b
    SET quantity_in_stock = quantity_in_stock - i.quantity
    FROM Books b
    INNER JOIN inserted i ON b.book_id = i.book_id
    INNER JOIN Orders o ON i.order_id = o.order_id
    WHERE o.status != 'Cancelled';
END;
GO

-- VIEW: Đơn hàng đang chờ xử lý
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

-- PROCEDURE: Tạo đơn hàng đơn giản
CREATE OR ALTER PROCEDURE sp_CreateSimpleOrder
    @customer_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        DECLARE @order_code VARCHAR(20);
        DECLARE @order_id INT;
        
        SET @order_code = 'DH' + FORMAT(GETDATE(), 'yyyyMMddHHmmss');
        
        INSERT INTO Orders (order_code, customer_id, order_date, status)
        VALUES (@order_code, @customer_id, GETDATE(), 'Pending');
        
        SET @order_id = SCOPE_IDENTITY();
        
        SELECT 'SUCCESS' as status, @order_id as order_id, @order_code as order_code;
    END TRY
    BEGIN CATCH
        SELECT 'ERROR' as status, ERROR_MESSAGE() as message;
    END CATCH
END;
GO