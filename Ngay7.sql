-- Tạo database và sử dụng
CREATE DATABASE IF NOT EXISTS ecommerce_db;
USE ecommerce_db;

DROP DATABASE IF EXISTS ecommerce_db;

-- Tạo bảng Categories
CREATE TABLE IF NOT EXISTS Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Tạo bảng Products
CREATE TABLE IF NOT EXISTS Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category_id INT,
    price DECIMAL(12,2),
    stock_quantity INT,
    created_at DATETIME,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- Tạo bảng Orders
CREATE TABLE IF NOT EXISTS Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    order_date DATETIME,
    status VARCHAR(20)
);

-- Tạo bảng OrderItems
CREATE TABLE IF NOT EXISTS OrderItems (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(12,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Thêm dữ liệu mẫu cho Categories
INSERT INTO Categories (name) VALUES 
('Electronics'), ('Books'), ('Clothing'), ('Home');

-- Thêm dữ liệu mẫu cho Products
INSERT INTO Products (name, category_id, price, stock_quantity, created_at) VALUES
('Smartphone', 1, 8000000, 10, '2025-06-01 10:00:00'),
('Laptop', 1, 15000000, 5, '2024-02-02 11:00:00'),
('Headphones', 1, 1200000, 20, '2025-06-03 12:00:00'),
('Novel', 2, 150000, 50, '2025-06-01 09:00:00'),
('T-shirt', 3, 200000, 100, '2025-06-04 13:00:00'),
('Microwave', 4, 1200000, 7, '2025-06-05 14:00:00'),
('Tablet', 1, 6000000, 8, '2024-06-06 15:00:00'),
('Camera', 1, 9000000, 3, '2025-06-07 16:00:00'),
('E-reader', 1, 2500000, 0, '2025-06-08 17:00:00'),
('Smartwatch', 1, 3000000, 12, '2025-06-09 18:00:00');

-- Thêm dữ liệu mẫu cho Orders
INSERT INTO Orders (user_id, order_date, status) VALUES
(1, '2025-06-01 10:30:00', 'Shipped'),
(2, '2024-02-02 11:30:00', 'Pending'),
(3, '2025-06-03 12:30:00', 'Shipped'),
(1, '2025-06-04 13:30:00', 'Cancelled'),
(2, '2025-06-05 14:30:00', 'Shipped'),
(3, '2025-06-06 15:30:00', 'Shipped');

-- Thêm dữ liệu mẫu cho OrderItems
INSERT INTO OrderItems (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 8000000),
(1, 3, 2, 1200000),
(2, 4, 1, 150000),
(3, 2, 1, 15000000),
(3, 5, 3, 200000),
(4, 6, 1, 1200000),
(5, 7, 2, 6000000),
(5, 8, 1, 9000000),
(6, 1, 1, 8000000),
(6, 10, 2, 3000000);

-- 1. Phân tích truy vấn bằng EXPLAIN
EXPLAIN
SELECT * FROM Orders 
JOIN OrderItems ON Orders.order_id = OrderItems.order_id
WHERE status = 'Shipped'
ORDER BY order_date DESC;

-- 2. Tạo chỉ mục cho Orders theo status, order_date
CREATE INDEX idx_orders_status_orderdate ON Orders(status, order_date);

-- 3. Tạo composite index cho OrderItems theo order_id, product_id
CREATE INDEX idx_orderitems_orderid_productid ON OrderItems(order_id, product_id);

-- 4. Sửa SELECT * thành chỉ chọn cột cần thiết
SELECT Orders.order_id, Orders.user_id, Orders.order_date, OrderItems.product_id, OrderItems.quantity
FROM Orders
JOIN OrderItems ON Orders.order_id = OrderItems.order_id
WHERE Orders.status = 'Shipped'
ORDER BY Orders.order_date DESC;

-- 5. So sánh hiệu suất JOIN vs Subquery
-- JOIN (tối ưu hơn, nên dùng)
SELECT Products.product_id, Products.name, Categories.name AS category_name
FROM Products
JOIN Categories ON Products.category_id = Categories.category_id;

-- Subquery (kém tối ưu hơn)
SELECT product_id, name,
  (SELECT name FROM Categories WHERE Categories.category_id = Products.category_id) AS category_name
FROM Products;

-- 6. Lấy 10 sản phẩm mới nhất trong danh mục “Electronics”, stock_quantity > 0
SELECT p.product_id, p.name, p.price, p.created_at
FROM Products p
JOIN Categories c ON p.category_id = c.category_id
WHERE c.name = 'Electronics' AND p.stock_quantity > 0
ORDER BY p.created_at DESC
LIMIT 10;

-- 7. Tạo Covering Index cho truy vấn thường xuyên
CREATE INDEX idx_products_covering ON Products(category_id, price, product_id, name);

-- 8. Truy vấn tính doanh thu theo tháng (tránh dùng hàm trong WHERE)
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, SUM(oi.quantity * oi.unit_price) AS revenue
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
WHERE o.order_date >= '2024-01-01' AND o.order_date < '2025-01-01'
GROUP BY month
ORDER BY month;

-- 9. Tách truy vấn lớn thành nhiều bước nhỏ
-- Bước 1: Lọc order_item có giá > 1 triệu
CREATE TEMPORARY TABLE ExpensiveOrderItems AS
SELECT order_id, product_id, quantity
FROM OrderItems
WHERE unit_price > 1000000;

-- Bước 2: Tính tổng số lượng bán ra của các sản phẩm này
SELECT product_id, SUM(quantity) AS total_quantity
FROM ExpensiveOrderItems
GROUP BY product_id
ORDER BY total_quantity DESC;

-- 10. Top 5 sản phẩm bán chạy nhất trong 30 ngày gần nhất
SELECT oi.product_id, p.name, SUM(oi.quantity) AS total_sold
FROM OrderItems oi
JOIN Orders o ON oi.order_id = o.order_id
JOIN Products p ON oi.product_id = p.product_id
WHERE o.order_date >= CURDATE() - INTERVAL 30 DAY
  AND o.status = 'Shipped'
GROUP BY oi.product_id, p.name
ORDER BY total_sold DESC
LIMIT 5;