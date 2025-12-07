-- THI (NHẬP SÁCH) - 5 CÂU
-- ======================================================

-- 16. Tạo phiếu nhập sách (dùng mã duy nhất)
INSERT INTO ImportBooks (import_code, import_date, supplier)
VALUES ('PN' + FORMAT(GETDATE(), 'yyyyMMddHHmmss'), GETDATE(), N'Nhà sách ABC');

-- 17. Thêm sách vào phiếu nhập
INSERT INTO ImportDetails (import_id, book_id, quantity, unit_price, subtotal)
VALUES (1, 1, 50, 100000, 5000000);

-- 18. Lấy chi tiết phiếu nhập
SELECT 
    ib.import_code,
    ib.import_date,
    ib.supplier,
    b.book_code,
    b.title,
    id.quantity,
    id.unit_price,
    id.subtotal
FROM ImportBooks ib
JOIN ImportDetails id ON ib.import_id = id.import_id
JOIN Books b ON id.book_id = b.book_id
WHERE ib.import_id = 1;

-- 19. Nhập sách trong tháng
SELECT 
    ib.import_code,
    ib.import_date,
    ib.supplier,
    ib.total_amount
FROM ImportBooks ib
WHERE MONTH(ib.import_date) = MONTH(GETDATE()) 
  AND YEAR(ib.import_date) = YEAR(GETDATE())
ORDER BY ib.import_date DESC;

-- 20. Tổng giá trị nhập kho
SELECT 
    supplier as nha_cung_cap,
    COUNT(*) as so_phieu_nhap,
    SUM(total_amount) as tong_gia_tri
FROM ImportBooks
GROUP BY supplier
ORDER BY tong_gia_tri DESC;

-- TRIGGER: Cập nhật tồn kho khi nhập sách (ĐƠN GIẢN)
GO
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

-- VIEW: Sách cần nhập thêm (nếu chưa có trong file LINH)
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