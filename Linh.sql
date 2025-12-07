-- Lấy tất cả sách
SELECT book_id, book_code, title, author, publisher, 
       publish_year, quantity_in_stock, price 
FROM Books 
ORDER BY book_id

-- 6. Thêm sách 
INSERT INTO Books (book_code, title, author, publisher, publish_year, quantity_in_stock, price)
VALUES ('B' + FORMAT(GETDATE(), 'yyyyMMddHHmmss'), N'Lập trình Python', N'Nguyễn Văn A', N'NXB Giáo dục', 2023, 50, 150000);

-- 7. Tìm sách 
SELECT book_id, book_code, title, author, publisher, 
       publish_year, quantity_in_stock, price 
FROM Books 
WHERE 1=1 
AND title LIKE '%Đắc Nhân Tâm%' 
ORDER BY title

-- 9. Xóa sách
DECLARE @book_id_to_delete INT = 1;
BEGIN TRANSACTION;
BEGIN TRY
    -- Xóa từ OrderDetails trước
    DELETE FROM OrderDetails WHERE book_id = @book_id_to_delete;
    
    -- Sau đó xóa từ Books
    DELETE FROM Books WHERE book_id = @book_id_to_delete;
    
    COMMIT TRANSACTION;
    PRINT 'Đã xóa sách thành công';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Lỗi khi xóa: ' + ERROR_MESSAGE();
END CATCH

-- 10. Sách sắp hết hàng
SELECT * FROM Books 
WHERE quantity_in_stock < 10
ORDER BY quantity_in_stock ASC;

-- TRIGGER: Ngăn xóa sách đã có đơn hàng CHƯA HỦY
GO
CREATE OR ALTER TRIGGER trg_PreventDeleteBookWithActiveOrders
ON Books
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS(SELECT 1 FROM deleted d 
              JOIN OrderDetails od ON d.book_id = od.book_id
              JOIN Orders o ON od.order_id = o.order_id
              WHERE o.status != 'Cancelled')
    BEGIN
        RAISERROR('Không thể xóa sách đang có trong đơn hàng chưa hủy!', 16, 1);
        RETURN;
    END
    
    -- Cho phép xóa nếu không có đơn hàng hoặc chỉ có đơn hàng đã hủy
    DELETE FROM OrderDetails 
    WHERE book_id IN (SELECT book_id FROM deleted);
    
    DELETE FROM ImportDetails 
    WHERE book_id IN (SELECT book_id FROM deleted);
    
    DELETE FROM Books 
    WHERE book_id IN (SELECT book_id FROM deleted);
END;
GO

-- TRIGGER: Cập nhật tồn kho khi nhập sách (ĐƠN GIẢN)
CREATE OR ALTER TRIGGER trg_UpdateStockWhenImportCreated
ON ImportDetails
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE b
    SET quantity_in_stock = quantity_in_stock + i.quantity,
        updated_date = GETDATE()
    FROM Books b
    INNER JOIN inserted i ON b.book_id = i.book_id;
END;
GO

-- VIEW: Sách cần nhập thêm
CREATE OR ALTER VIEW vw_BooksNeedImport AS
SELECT 
    book_code,
    title,
    author,
    publisher,
    quantity_in_stock,
    price,
    CASE 
        WHEN quantity_in_stock = 0 THEN 'HẾT HÀNG'
        WHEN quantity_in_stock < 5 THEN 'RẤT THẤP'
        WHEN quantity_in_stock < 10 THEN 'THẤP'
        ELSE 'ĐỦ'
    END as trang_thai_ton_kho
FROM Books
WHERE quantity_in_stock < 10;
GO

-- PROCEDURE: Tìm kiếm sách
CREATE OR ALTER PROCEDURE sp_SearchBooksProc
    @keyword NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        book_id,
        book_code,
        title,
        author,
        publisher,
        publish_year,
        quantity_in_stock,
        price
    FROM Books 
    WHERE @keyword IS NULL 
       OR title LIKE '%' + @keyword + '%'
       OR author LIKE '%' + @keyword + '%'
       OR publisher LIKE '%' + @keyword + '%'
    ORDER BY title;
END;
GO

EXec sp_SearchBooksProc

-- PROCEDURE: Xóa sách an toàn
CREATE OR ALTER PROCEDURE sp_SafeDeleteBookProc
    @book_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Kiểm tra sách có tồn tại
        IF NOT EXISTS(SELECT 1 FROM Books WHERE book_id = @book_id)
        BEGIN
            SELECT 'ERROR' as status, 'Sách không tồn tại!' as message;
            ROLLBACK;
            RETURN;
        END
        
        -- Kiểm tra đơn hàng chưa hủy
        IF EXISTS(
            SELECT 1 FROM OrderDetails od
            JOIN Orders o ON od.order_id = o.order_id
            WHERE od.book_id = @book_id AND o.status != 'Cancelled'
        )
        BEGIN
            SELECT 'ERROR' as status, 'Sách đang có trong đơn hàng chưa hủy!' as message;
            ROLLBACK;
            RETURN;
        END
        
        -- Xóa các bản ghi liên quan
        DELETE FROM OrderDetails WHERE book_id = @book_id;
        DELETE FROM ImportDetails WHERE book_id = @book_id;
        DELETE FROM Books WHERE book_id = @book_id;
        
        COMMIT;
        SELECT 'SUCCESS' as status, 'Đã xóa sách thành công!' as message;
    END TRY
BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SELECT 'ERROR' as status, ERROR_MESSAGE() as message;
    END CATCH
END;
GO