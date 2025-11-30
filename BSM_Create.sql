-- Tạo database
CREATE DATABASE BookStoreManagement;
GO

USE BookStoreManagement;
GO

-- Bảng Sách
CREATE TABLE Books (
    book_id INT IDENTITY(1,1) PRIMARY KEY,
    book_code VARCHAR(20) UNIQUE NOT NULL,
    title NVARCHAR(255) NOT NULL,
    author NVARCHAR(100) NOT NULL,
    publisher NVARCHAR(100) NOT NULL,
    publish_year INT,
    quantity_in_stock INT DEFAULT 0,
    price DECIMAL(10,2) NOT NULL,
    created_date DATETIME DEFAULT GETDATE()
);

-- Bảng Khách hàng
CREATE TABLE Customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    full_name NVARCHAR(100) NOT NULL,
    address NVARCHAR(255),
    phone_number VARCHAR(15),
    created_date DATETIME DEFAULT GETDATE()
);

-- Bảng Đơn hàng
CREATE TABLE Orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    order_code VARCHAR(20) UNIQUE NOT NULL,
    customer_id INT,
    order_date DATETIME NOT NULL,
    total_amount DECIMAL(12,2) DEFAULT 0,
    status NVARCHAR(20) DEFAULT 'Pending',
    created_date DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- Bảng Chi tiết đơn hàng
CREATE TABLE OrderDetails (
    order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT,
    book_id INT,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
);

-- Bảng Nhập sách
CREATE TABLE ImportBooks (
    import_id INT IDENTITY(1,1) PRIMARY KEY,
    import_code VARCHAR(20) UNIQUE NOT NULL,
    import_date DATETIME NOT NULL,
    supplier NVARCHAR(100),
    total_amount DECIMAL(12,2) DEFAULT 0,
    created_date DATETIME DEFAULT GETDATE()
);

-- Bảng Chi tiết nhập sách
CREATE TABLE ImportDetails (
    import_detail_id INT IDENTITY(1,1) PRIMARY KEY,
    import_id INT,
    book_id INT,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (import_id) REFERENCES ImportBooks(import_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
);

