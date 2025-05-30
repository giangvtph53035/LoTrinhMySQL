CREATE DATABASE Ngay2SQL
    DEFAULT CHARACTER SET = 'utf8mb4';

USE Ngay2SQL;

CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    city VARCHAR(100),
    referrer_id INT,
    created_at DATE,
    FOREIGN KEY (referrer_id) REFERENCES Users(user_id)
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price INT,
    is_active BOOLEAN
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE OrderItems (
    order_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

INSERT INTO Users (user_id, full_name, city, referrer_id, created_at) VALUES
(1, 'Nguyen Van A', 'Hanoi', NULL, '2023-01-01'),
(2, 'Tran Thi B', 'HCM', 1, '2023-01-10'),
(3, 'Le Van C', 'Hanoi', 1, '2023-01-12'),
(4, 'Do Thi D', 'Da Nang', 2, '2023-02-05'),
(5, 'Hoang E', 'Can Tho', NULL, '2023-02-10');


INSERT INTO Products (product_id, product_name, category, price, is_active) VALUES
(1, 'iPhone 13', 'Electronics', 20000000, 1),
(2, 'MacBook Air', 'Electronics', 28000000, 1),
(3, 'Coffee Beans', 'Grocery', 250000, 1),
(4, 'Book: SQL Basics', 'Books', 150000, 1),
(5, 'Xbox Controller', 'Gaming', 1200000, 0);


INSERT INTO Orders (order_id, user_id, order_date, status) VALUES
(1001, 1, '2023-02-01', 'completed'),
(1002, 2, '2023-02-10', 'cancelled'),
(1003, 3, '2023-02-12', 'completed'),
(1004, 4, '2023-02-15', 'completed'),
(1005, 1, '2023-03-01', 'pending');



INSERT INTO OrderItems (order_id, product_id, quantity) VALUES
(1001, 1, 1),
(1001, 3, 3),
(1003, 2, 1),
(1003, 4, 2),
(1004, 3, 5),
(1005, 2, 1);
-- Câu 1
SELECT 
    p.category,
    SUM(p.price * oi.quantity) AS total_revenue
FROM OrderItems oi
JOIN Orders o ON oi.order_id = o.order_id
JOIN Products p ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY p.category;


-- Câu 2
SELECT 
    u.user_id,
    u.full_name,
    r.full_name AS referrer_name
FROM Users u
LEFT JOIN Users r ON u.referrer_id = r.user_id;

-- Câu 3

SELECT DISTINCT p.product_id, p.product_name
FROM Products p
JOIN OrderItems oi ON p.product_id = oi.product_id
WHERE p.is_active = 0;

-- Câu 4
SELECT u.user_id, u.full_name
FROM Users u
LEFT JOIN Orders o ON u.user_id = o.user_id
WHERE o.order_id IS NULL;

-- Câu 5
SELECT user_id, MIN(order_id) AS first_order_id
FROM Orders
GROUP BY user_id;

-- Câu 6
SELECT 
    o.user_id,
    u.full_name,
    SUM(oi.quantity * p.price) AS total_spent
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
JOIN Users u ON o.user_id = u.user_id
WHERE o.status = 'completed'
GROUP BY o.user_id, u.full_name;

-- Câu 7
SELECT *
FROM (
    SELECT 
        o.user_id,
        u.full_name,
        SUM(oi.quantity * p.price) AS total_spent
    FROM Orders o
    JOIN OrderItems oi ON o.order_id = oi.order_id
    JOIN Products p ON oi.product_id = p.product_id
    JOIN Users u ON o.user_id = u.user_id
    WHERE o.status = 'completed'
    GROUP BY o.user_id, u.full_name
) AS user_spending
WHERE total_spent > 25000000;

-- Câu 8
SELECT 
    u.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE WHEN o.status = 'completed' THEN oi.quantity * p.price ELSE 0 END) AS total_revenue
FROM Orders o
JOIN Users u ON o.user_id = u.user_id
JOIN OrderItems oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
GROUP BY u.city;

-- Câu 9
SELECT u.user_id, u.full_name, COUNT(o.order_id) AS completed_orders
FROM Users u
JOIN Orders o ON u.user_id = o.user_id
WHERE o.status = 'completed'
GROUP BY u.user_id, u.full_name
HAVING COUNT(o.order_id) >= 2;

-- Câu 10
SELECT oi.order_id
FROM OrderItems oi
JOIN Products p ON oi.product_id = p.product_id
GROUP BY oi.order_id
HAVING COUNT(DISTINCT p.category) > 1;

-- Câu 11
SELECT DISTINCT u.user_id, u.full_name, 'placed_order' AS source
FROM Users u
JOIN Orders o ON u.user_id = o.user_id

UNION

SELECT DISTINCT u.user_id, u.full_name, 'referred' AS source
FROM Users u
WHERE u.referrer_id IS NOT NULL;

