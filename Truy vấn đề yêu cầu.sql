--Sách bán chạy nhất 
SELECT TOP 1
    b.book_code, b.title, b.author, b.publisher,
    SUM(od.quantity) as total_sold,
    SUM(od.subtotal) as total_revenue
FROM OrderDetails od
JOIN Orders o ON od.order_id = o.order_id
JOIN Books b ON od.book_id = b.book_id
WHERE o.status = 'Completed'
    AND YEAR(o.order_date) = 2025
    AND MONTH(o.order_date) = 11
GROUP BY b.book_id, b.book_code, b.title, b.author, b.publisher
ORDER BY total_sold DESC


SELECT 
    publisher,
    COUNT(book_id) as book_count,
    SUM(quantity_in_stock) as total_quantity,
    SUM(quantity_in_stock * price) as total_value
FROM Books 
WHERE publisher IS NOT NULL AND publisher != ''
GROUP BY publisher 
ORDER BY total_value DESC

SELECT book_id, book_code, title, author, publisher, 
       publish_year, quantity_in_stock, price 
FROM Books WHERE 1=1
AND title LIKE '%Đắc Nhân Tâm%'
ORDER BY title

SELECT 
    b.book_code, b.title, b.author, b.publisher,
    COUNT(DISTINCT o.order_id) as order_count,
    SUM(od.quantity) as total_sold,
    SUM(od.subtotal) as total_revenue
FROM Books b
LEFT JOIN OrderDetails od ON b.book_id = od.book_id
LEFT JOIN Orders o ON od.order_id = o.order_id AND o.status = 'Completed'
WHERE od.quantity IS NOT NULL
GROUP BY b.book_id, b.book_code, b.title, b.author, b.publisher 
ORDER BY total_revenue DESC

SELECT TOP 10 
    c.customer_code, c.full_name, c.phone_number,
    ISNULL(SUM(od.quantity), 0) as total_books,
    COUNT(DISTINCT o.order_id) as total_orders,
    ISNULL(SUM(o.total_amount), 0) as total_spent
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
LEFT JOIN OrderDetails od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.customer_code, c.full_name, c.phone_number
ORDER BY total_books DESC, total_spent DESC

SELECT 
    c.customer_code, c.full_name, c.phone_number,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_code, c.full_name, c.phone_number
HAVING COUNT(o.order_id) >= 2
ORDER BY total_spent 

SELECT 
    COUNT(*) as total_orders,
    ISNULL(SUM(total_amount), 0) as total_revenue
FROM Orders 
WHERE status = 'Completed'
    AND order_date >= '2025-12-01 00:00:00' 
    AND order_date <= '2025-12-30 23:59:59'