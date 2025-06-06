CREATE DATABASE Ngay1SQL
    DEFAULT CHARACTER SET = 'utf8mb4';

USE Ngay1SQL;

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(50),
    email VARCHAR(100)
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount INT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100),
    price INT
);

INSERT INTO Customers (customer_id, name, city, email) VALUES
(1, 'Nguyen An', 'Hanoi', 'an.nguyen@email.com'),
(2, 'Tran Binh', 'Ho Chi Minh', NULL),
(3, 'Le Cuong', 'Da Nang', 'cuong.le@email.com'),
(4, 'Hoang Duong', 'Hanoi', 'duong.hoang@email.com');

INSERT INTO Orders (order_id, customer_id, order_date, total_amount) VALUES
(101, 1, '2023-01-15', 500000),
(102, 3, '2023-02-10', 800000),
(103, 2, '2023-03-05', 300000),
(104, 1, '2023-04-01', 450000);

INSERT INTO Products (product_id, name, price) VALUES
(1, 'Laptop Dell', 15000000),
(2, 'Mouse Logitech', 300000),
(3, 'Keyboard Razer', 1200000),
(4, 'Laptop HP', 14000000);
-- Câu 1:
SELECT * FROM Customers
WHERE city = 'Hanoi';

-- Câu 2:
SELECT * FROM Orders
WHERE total_amount > 400000 AND order_date > '2023-01-31';

-- Câu 3:
SELECT * FROM Customers
WHERE email IS NULL;
-- Câu 4:
SELECT * FROM Orders
ORDER BY total_amount DESC;

-- Câu 5:
INSERT INTO Customers (customer_id, name, city, email)
VALUES (5, 'Pham Thanh', 'Can Tho', NULL);

-- Câu 6:
UPDATE Customers
SET email = 'binh.tran@email.com'
WHERE customer_id = 2;

-- Câu 7:
DELETE FROM Orders
WHERE order_id = 103;

-- Câu 8:
SELECT * FROM Customers
LIMIT 2;

-- Câu 9:
SELECT 
    MAX(total_amount) AS MaxOrder,
    MIN(total_amount) AS MinOrder
FROM Orders;
    
-- Câu 10:
SELECT 
    COUNT(*) AS TotalOrders,
    SUM(total_amount) AS TotalRevenue,
    AVG(total_amount) AS AverageOrderValue
FROM Orders;

-- Câu 11:
SELECT * FROM Products
WHERE name LIKE 'Laptop%';
