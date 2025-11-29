
-- Tạo database (nếu chưa có)
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'BookStoreManagement')
BEGIN
    CREATE DATABASE BookStoreManagement;
END
GO

USE BookStoreManagement;
GO

-- Bảng Sách
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Books' AND xtype='U')
BEGIN
    CREATE TABLE Books (
        book_id INT IDENTITY(1,1) PRIMARY KEY,
        book_code NVARCHAR(50) UNIQUE NOT NULL,
        title NVARCHAR(255) NOT NULL,
        author NVARCHAR(255) NOT NULL,
        publisher NVARCHAR(255) NOT NULL,
        publish_year INT,
        quantity_in_stock INT DEFAULT 0,
        price DECIMAL(18,2) DEFAULT 0
    );
END
GO

-- Bảng Khách hàng
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Customers' AND xtype='U')
BEGIN
    CREATE TABLE Customers (
        customer_id INT IDENTITY(1,1) PRIMARY KEY,
        customer_code NVARCHAR(50) UNIQUE NOT NULL,
        full_name NVARCHAR(255) NOT NULL,
        address NVARCHAR(500),
        phone_number NVARCHAR(20)
    );
END
GO

-- Bảng Đơn hàng
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Orders' AND xtype='U')
BEGIN
    CREATE TABLE Orders (
        order_id INT IDENTITY(1,1) PRIMARY KEY,
        order_code NVARCHAR(50) UNIQUE NOT NULL,
        customer_id INT NOT NULL,
        order_date DATETIME DEFAULT GETDATE(),
        total_amount DECIMAL(18,2) DEFAULT 0,
        status NVARCHAR(20) DEFAULT 'Pending',
        FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
    );
END
GO

-- Bảng Chi tiết đơn hàng
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='OrderDetails' AND xtype='U')
BEGIN
    CREATE TABLE OrderDetails (
        order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
        order_id INT NOT NULL,
        book_id INT NOT NULL,
        quantity INT NOT NULL,
        unit_price DECIMAL(18,2) NOT NULL,
        subtotal DECIMAL(18,2) NOT NULL,
        FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
        FOREIGN KEY (book_id) REFERENCES Books(book_id)
    );
END
GO

-- Bảng Phiếu nhập sách
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ImportBooks' AND xtype='U')
BEGIN
    CREATE TABLE ImportBooks (
        import_id INT IDENTITY(1,1) PRIMARY KEY,
        import_code NVARCHAR(50) UNIQUE NOT NULL,
        import_date DATETIME DEFAULT GETDATE(),
        supplier NVARCHAR(255),
        total_amount DECIMAL(18,2) DEFAULT 0
    );
END
GO

-- Bảng Chi tiết phiếu nhập
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ImportDetails' AND xtype='U')
BEGIN
    CREATE TABLE ImportDetails (
        import_detail_id INT IDENTITY(1,1) PRIMARY KEY,
        import_id INT NOT NULL,
        book_id INT NOT NULL,
        quantity INT NOT NULL,
        unit_price DECIMAL(18,2) NOT NULL,
        subtotal DECIMAL(18,2) NOT NULL,
        FOREIGN KEY (import_id) REFERENCES ImportBooks(import_id) ON DELETE CASCADE,
        FOREIGN KEY (book_id) REFERENCES Books(book_id)
    );
END
GO

-- Thêm dữ liệu mẫu
IF NOT EXISTS (SELECT 1 FROM Books)
BEGIN
    INSERT INTO Books (book_code, title, author, publisher, publish_year, quantity_in_stock, price) VALUES
    ('B001', N'Nhà Giả Kim', N'Paulo Coelho', N'NXB Văn Học', 2018, 50, 85000),
    ('B002', N'Đắc Nhân Tâm', N'Dale Carnegie', N'NXB Tổng Hợp', 2020, 30, 120000),
    ('B003', N'Tư Duy Phản Biện', N'Zoe McKey', N'NXB Lao Động', 2021, 25, 95000),
    ('B004', N'Clean Code', N'Robert C. Martin', N'NXB Trẻ', 2019, 20, 150000),
    ('B005', N'Python Cơ Bản', N'Nguyễn Văn A', N'NXB Khoa Học', 2022, 40, 110000);
END
GO

IF NOT EXISTS (SELECT 1 FROM Customers)
BEGIN
    INSERT INTO Customers (customer_code, full_name, address, phone_number) VALUES
    ('KH001', N'Nguyễn Văn An', N'123 Đường Lê Lợi, Q.1, TP.HCM', '0909123456'),
    ('KH002', N'Trần Thị Bình', N'456 Đường Nguyễn Huệ, Q.1, TP.HCM', '0909876543'),
    ('KH003', N'Lê Văn Cường', N'789 Đường Pasteur, Q.3, TP.HCM', '0918123456');
END
GO

-- Tạo index để tối ưu hiệu suất
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Books_Code')
    CREATE INDEX IX_Books_Code ON Books(book_code);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customers_Code')
    CREATE INDEX IX_Customers_Code ON Customers(customer_code);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_Code')
    CREATE INDEX IX_Orders_Code ON Orders(order_code);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ImportBooks_Code')
    CREATE INDEX IX_ImportBooks_Code ON ImportBooks(import_code);
GO
