-- 1. Trigger cập nhật tồn kho khi có đơn hàng
CREATE OR ALTER TRIGGER tr_UpdateInventoryOnOrder
ON OrderDetails
AFTER INSERT
AS
BEGIN
    UPDATE b
    SET b.QuantityInStock = b.QuantityInStock - i.Quantity
    FROM Books b
    INNER JOIN inserted i ON b.BookID = i.BookID;
END;
GO

-- 2. Trigger cập nhật thống kê khách hàng
CREATE OR ALTER TRIGGER tr_UpdateCustomerStats
ON Orders
AFTER INSERT
AS
BEGIN
    UPDATE c
    SET 
        c.TotalOrders = c.TotalOrders + 1,
        c.TotalSpent = c.TotalSpent + i.TotalAmount
    FROM Customers c
    INNER JOIN inserted i ON c.CustomerID = i.CustomerID;
END;
GO

-- 3. Trigger tự động tính SubTotal trong OrderDetails
CREATE OR ALTER TRIGGER tr_CalculateSubTotal
ON OrderDetails
AFTER INSERT, UPDATE
AS
BEGIN
    IF UPDATE(Quantity) OR UPDATE(UnitPrice)
    BEGIN
        UPDATE od
        SET od.SubTotal = od.Quantity * od.UnitPrice
        FROM OrderDetails od
        INNER JOIN inserted i ON od.OrderDetailID = i.OrderDetailID;
    END
END;
GO

-- 4. Trigger cập nhật TotalAmount trong Orders
CREATE OR ALTER TRIGGER tr_UpdateOrderTotal
ON OrderDetails
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Cập nhật cho các OrderID bị ảnh hưởng
    DECLARE @AffectedOrders TABLE (OrderID INT);
    
    INSERT INTO @AffectedOrders (OrderID)
    SELECT OrderID FROM inserted
    UNION
    SELECT OrderID FROM deleted;
    
    UPDATE o
    SET o.TotalAmount = (
        SELECT SUM(SubTotal) 
        FROM OrderDetails od 
        WHERE od.OrderID = o.OrderID
    )
    FROM Orders o
    INNER JOIN @AffectedOrders ao ON o.OrderID = ao.OrderID;
END;
GO

-- 5. Hàm tính doanh thu theo khoảng thời gian
CREATE OR ALTER FUNCTION fn_CalculateRevenue
(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Revenue DECIMAL(18,2);
    
    SELECT @Revenue = SUM(TotalAmount)
    FROM Orders
    WHERE OrderDate BETWEEN @StartDate AND @EndDate;
    
    RETURN ISNULL(@Revenue, 0);
END;
GO

-- 6. Hàm đếm số sách bán được theo khoảng thời gian
CREATE OR ALTER FUNCTION fn_CountBooksSold
(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @TotalSold INT;
    
    SELECT @TotalSold = SUM(od.Quantity)
    FROM OrderDetails od
    INNER JOIN Orders o ON od.OrderID = o.OrderID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate;
    
    RETURN ISNULL(@TotalSold, 0);
END;
GO

-- 7. Hàm tìm sách bán chạy nhất
CREATE OR ALTER FUNCTION fn_GetBestSellingBook
(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS NVARCHAR(255)
AS
BEGIN
    DECLARE @BookName NVARCHAR(255);
    
    SELECT TOP 1 @BookName = b.BookName
    FROM Books b
    INNER JOIN OrderDetails od ON b.BookID = od.BookID
    INNER JOIN Orders o ON od.OrderID = o.OrderID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY b.BookID, b.BookName
    ORDER BY SUM(od.Quantity) DESC;
    
    RETURN ISNULL(@BookName, N'Không có dữ liệu');
END;
GO