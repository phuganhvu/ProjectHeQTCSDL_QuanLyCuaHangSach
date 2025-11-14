-- 1. Sách bán chạy nhất theo tháng
CREATE OR ALTER PROCEDURE sp_GetBestSellingBooksByMonth
    @Month INT,
    @Year INT
AS
BEGIN
    SELECT 
        TOP 10
        b.BookCode,
        b.BookName,
        b.Author,
        b.Publisher,
        SUM(od.Quantity) as TotalSold,
        SUM(od.SubTotal) as TotalRevenue
    FROM OrderDetails od
    INNER JOIN Orders o ON od.OrderID = o.OrderID
    INNER JOIN Books b ON od.BookID = b.BookID
    WHERE MONTH(o.OrderDate) = @Month AND YEAR(o.OrderDate) = @Year
    GROUP BY b.BookCode, b.BookName, b.Author, b.Publisher
    ORDER BY TotalSold DESC;
END;
GO

-- 2. Sách tồn kho theo nhà xuất bản
CREATE OR ALTER PROCEDURE sp_GetInventoryByPublisher
    @Publisher NVARCHAR(100) = NULL
AS
BEGIN
    SELECT 
        Publisher,
        BookCode,
        BookName,
        Author,
        QuantityInStock,
        Price
    FROM Books
    WHERE (@Publisher IS NULL OR Publisher = @Publisher)
        AND QuantityInStock > 0
    ORDER BY Publisher, BookName;
END;
GO

-- 3. Tìm kiếm sách
CREATE OR ALTER PROCEDURE sp_SearchBooks
    @Author NVARCHAR(100) = NULL,
    @Publisher NVARCHAR(100) = NULL,
    @PublishYear INT = NULL
AS
BEGIN
    SELECT 
        BookCode,
        BookName,
        Author,
        Publisher,
        PublishYear,
        QuantityInStock,
        Price
    FROM Books
    WHERE (@Author IS NULL OR Author LIKE '%' + @Author + '%')
        AND (@Publisher IS NULL OR Publisher LIKE '%' + @Publisher + '%')
        AND (@PublishYear IS NULL OR PublishYear = @PublishYear)
    ORDER BY BookName;
END;
GO

-- 4. Doanh thu theo sách
CREATE OR ALTER PROCEDURE sp_GetRevenueByBook
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    IF @StartDate IS NULL SET @StartDate = DATEADD(MONTH, -1, GETDATE())
    IF @EndDate IS NULL SET @EndDate = GETDATE()
    
    SELECT 
        b.BookCode,
        b.BookName,
        b.Author,
        b.Publisher,
        COUNT(od.OrderID) as TotalOrders,
        SUM(od.Quantity) as TotalSold,
        SUM(od.SubTotal) as TotalRevenue
    FROM Books b
    LEFT JOIN OrderDetails od ON b.BookID = od.BookID
    LEFT JOIN Orders o ON od.OrderID = o.OrderID
    WHERE (o.OrderDate BETWEEN @StartDate AND @EndDate OR o.OrderDate IS NULL)
    GROUP BY b.BookCode, b.BookName, b.Author, b.Publisher
    ORDER BY TotalRevenue DESC;
END;
GO

-- 5. Khách hàng thường xuyên
CREATE OR ALTER PROCEDURE sp_GetRegularCustomers
    @MinOrders INT = 3
AS
BEGIN
    SELECT 
        c.CustomerCode,
        c.FullName,
        c.PhoneNumber,
        c.TotalOrders,
        c.TotalSpent,
        COUNT(o.OrderID) as OrdersInLast6Months,
        SUM(o.TotalAmount) as SpentInLast6Months
    FROM Customers c
    INNER JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY c.CustomerCode, c.FullName, c.PhoneNumber, c.TotalOrders, c.TotalSpent
    HAVING COUNT(o.OrderID) >= @MinOrders
    ORDER BY OrdersInLast6Months DESC;
END;
GO

-- 6. Top khách hàng
CREATE OR ALTER PROCEDURE sp_GetTopCustomers
    @TopN INT = 10,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    IF @StartDate IS NULL SET @StartDate = DATEADD(YEAR, -1, GETDATE())
    IF @EndDate IS NULL SET @EndDate = GETDATE()
    
    SELECT TOP (@TopN)
        c.CustomerCode,
        c.FullName,
        c.PhoneNumber,
        COUNT(DISTINCT o.OrderID) as TotalOrders,
        SUM(od.Quantity) as TotalBooksPurchased,
        SUM(o.TotalAmount) as TotalSpent
    FROM Customers c
    INNER JOIN Orders o ON c.CustomerID = o.CustomerID
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY c.CustomerCode, c.FullName, c.PhoneNumber
    ORDER BY TotalSpent DESC;
END;
GO

-- 7. Thống kê đơn hàng
CREATE OR ALTER PROCEDURE sp_GetOrderStatistics
    @TimeType VARCHAR(10),
    @SpecificDate DATE = NULL
AS
BEGIN
    IF @SpecificDate IS NULL SET @SpecificDate = GETDATE()
    
    IF @TimeType = 'day'
    BEGIN
        SELECT 
            CONVERT(DATE, OrderDate) as OrderDay,
            COUNT(OrderID) as TotalOrders,
            SUM(TotalAmount) as TotalRevenue
        FROM Orders
        WHERE CONVERT(DATE, OrderDate) = @SpecificDate
        GROUP BY CONVERT(DATE, OrderDate);
    END
    ELSE IF @TimeType = 'month'
    BEGIN
        SELECT 
            YEAR(OrderDate) as OrderYear,
            MONTH(OrderDate) as OrderMonth,
            COUNT(OrderID) as TotalOrders,
            SUM(TotalAmount) as TotalRevenue
        FROM Orders
        WHERE YEAR(OrderDate) = YEAR(@SpecificDate) 
            AND MONTH(OrderDate) = MONTH(@SpecificDate)
        GROUP BY YEAR(OrderDate), MONTH(OrderDate);
    END
    ELSE IF @TimeType = 'year'
    BEGIN
        SELECT 
            YEAR(OrderDate) as OrderYear,
            COUNT(OrderID) as TotalOrders,
            SUM(TotalAmount) as TotalRevenue
        FROM Orders
        WHERE YEAR(OrderDate) = YEAR(@SpecificDate)
        GROUP BY YEAR(OrderDate);
    END
END;
GO

-- 8. Nhập xuất hàng ngày
CREATE OR ALTER PROCEDURE sp_GetDailyInventoryMovement
    @Date DATE = NULL
AS
BEGIN
    IF @Date IS NULL SET @Date = GETDATE()
    
    SELECT 
        'Import' as MovementType,
        b.BookCode,
        b.BookName,
        ib.Quantity,
        ib.ImportPrice,
        ib.Supplier,
        ib.ImportDate
    FROM ImportBooks ib
    INNER JOIN Books b ON ib.BookID = b.BookID
    WHERE CONVERT(DATE, ib.ImportDate) = @Date
    
    UNION ALL
    
    SELECT 
        'Export' as MovementType,
        b.BookCode,
        b.BookName,
        od.Quantity,
        od.UnitPrice as Price,
        c.FullName as Customer,
        o.OrderDate
    FROM OrderDetails od
    INNER JOIN Books b ON od.BookID = b.BookID
    INNER JOIN Orders o ON od.OrderID = o.OrderID
    INNER JOIN Customers c ON o.CustomerID = c.CustomerID
    WHERE CONVERT(DATE, o.OrderDate) = @Date
    ORDER BY MovementType, BookName;
END;