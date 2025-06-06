-- 1. Tạo bảng Accounts (InnoDB), Transactions (InnoDB), TxnAuditLogs (MyISAM)
CREATE DATABASE IF NOT EXISTS DigitalBanking;
USE DigitalBanking;

DROP DATABASE IF EXISTS DigitalBanking;

DROP TABLE IF EXISTS TxnAuditLogs, Transactions, Accounts, Referrals;

CREATE TABLE Accounts (
    account_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Active', 'Frozen', 'Closed')),
    CONSTRAINT chk_balance CHECK (balance >= 0)
) ENGINE=InnoDB;

-- Bảng Transactions (InnoDB)
CREATE TABLE Transactions (
    txn_id INT PRIMARY KEY AUTO_INCREMENT,
    from_account INT,
    to_account INT,
    amount DECIMAL(15, 2) NOT NULL,
    txn_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Success', 'Failed', 'Pending')),
    FOREIGN KEY (from_account) REFERENCES Accounts(account_id),
    FOREIGN KEY (to_account) REFERENCES Accounts(account_id)
) ENGINE=InnoDB;

-- Bảng TxnAuditLogs (MyISAM)
CREATE TABLE TxnAuditLogs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    txn_id INT,
    action VARCHAR(50),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
) ENGINE=MyISAM;

INSERT INTO Accounts (account_id, full_name, balance, status) VALUES
(1, 'Nguyen Van An', 5000.00, 'Active'),
(2, 'Tran Thi Binh', 3000.00, 'Active'),
(3, 'Le Van Cuong', 100.00, 'Frozen'),
(4, 'Pham Thi Dung', 0.00, 'Closed'),
(5, 'Hoang Van Nam', 10000.00, 'Active');

INSERT INTO Transactions (from_account, to_account, amount, txn_date, status) VALUES
(1, 2, 1000.00, '2025-06-01 10:00:00', 'Success'),
(2, 5, 500.00, '2025-06-02 14:30:00', 'Success'),
(3, 1, 200.00, '2025-06-03 09:15:00', 'Failed'), 
(5, 2, 1500.00, '2025-06-04 16:45:00', 'Pending'),
(1, 4, 300.00, '2025-06-05 11:20:00', 'Failed'); 


INSERT INTO TxnAuditLogs (txn_id, action, log_date, details) VALUES
(1, 'Transfer', '2025-06-01 10:00:00', 'Chuyển 1000.00 từ tài khoản 1 đến tài khoản 2'),
(2, 'Transfer', '2025-06-02 14:30:00', 'Chuyển 500.00 từ tài khoản 2 đến tài khoản 5'),
(3, 'Transfer Attempt', '2025-06-03 09:15:00', 'Thử chuyển 200.00 từ tài khoản 3 đến tài khoản 1 - Thất bại: Tài khoản Frozen'),
(4, 'Transfer Pending', '2025-06-04 16:45:00', 'Chuyển 1500.00 từ tài khoản 5 đến tài khoản 2 - Đang chờ'),
(5, 'Transfer Attempt', '2025-06-05 11:20:00', 'Thử chuyển 300.00 từ tài khoản 1 đến tài khoản 4 - Thất bại: Tài khoản Closed');





-- 1. Stored Procedure chuyển tiền, chống deadlock
DELIMITER //

CREATE PROCEDURE TransferMoney(
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(15, 2),
    OUT p_status VARCHAR(100)
)
BEGIN
    DECLARE v_from_balance DECIMAL(15, 2);
    DECLARE v_from_status VARCHAR(20);
    DECLARE v_to_status VARCHAR(20);
    DECLARE v_txn_id INT;
    
    -- Xử lý lỗi tổng quát
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_status = 'Lỗi hệ thống khi thực hiện giao dịch';
        ROLLBACK;
    END;

    -- Bắt đầu transaction
    START TRANSACTION;
    
    -- Khóa tài khoản theo thứ tự account_id để tránh deadlock
    IF p_from_account < p_to_account THEN
        -- Khóa tài khoản nguồn trước
        SELECT balance, status INTO v_from_balance, v_from_status 
        FROM Accounts 
        WHERE account_id = p_from_account 
        FOR UPDATE;
        
        -- Khóa tài khoản đích
        SELECT status INTO v_to_status 
        FROM Accounts 
        WHERE account_id = p_to_account 
        FOR UPDATE;
    ELSE
        -- Khóa tài khoản đích trước nếu p_from_account > p_to_account
        SELECT status INTO v_to_status 
        FROM Accounts 
        WHERE account_id = p_to_account 
        FOR UPDATE;
        
        SELECT balance, status INTO v_from_balance, v_from_status 
        FROM Accounts 
        WHERE account_id = p_from_account 
        FOR UPDATE;
    END IF;
    
    -- Kiểm tra trạng thái tài khoản
    IF v_from_status != 'Active' THEN
        SET p_status = 'Tài khoản nguồn không Active';
        ROLLBACK;
    ELSEIF v_to_status != 'Active' THEN
        SET p_status = 'Tài khoản đích không Active';
        ROLLBACK;
    ELSEIF v_from_balance < p_amount THEN
        SET p_status = 'Số dư không đủ';
        ROLLBACK;
    ELSE
        -- Cập nhật số dư
        UPDATE Accounts 
        SET balance = balance - p_amount 
        WHERE account_id = p_from_account;
        
        UPDATE Accounts 
        SET balance = balance + p_amount 
        WHERE account_id = p_to_account;
        
        -- Ghi giao dịch
        INSERT INTO Transactions (from_account, to_account, amount, status)
        VALUES (p_from_account, p_to_account, p_amount, 'Success');
        
        SET v_txn_id = LAST_INSERT_ID();
        
        -- Ghi audit log
        INSERT INTO TxnAuditLogs (txn_id, action, details)
        VALUES (v_txn_id, 'Transfer', CONCAT('Chuyển ', p_amount, ' từ ', p_from_account, ' đến ', p_to_account));
        
        SET p_status = 'Giao dịch thành công';
        COMMIT;
    END IF;
END //

DELIMITER ;

-- Kiểm tra cả hai tài khoản đều Active.

CALL TransferMoney(3, 2, 50.00, @status);
SELECT @status;

SELECT * FROM Accounts WHERE account_id IN (3, 2);
SELECT * FROM Transactions WHERE from_account = 3 AND to_account = 2;
SELECT * FROM TxnAuditLogs WHERE details LIKE '%từ 3 đến 2%';

-- Tài khoản đích không Active (Closed).
CALL TransferMoney(1, 4, 200.00, @status);
SELECT @status;

SELECT * FROM Accounts WHERE account_id IN (1, 4);
SELECT * FROM Transactions WHERE from_account = 1 AND to_account = 4;
SELECT * FROM TxnAuditLogs WHERE details LIKE '%từ 1 đến 4%';

-- 2. Đảm bảo tài khoản nguồn có đủ tiền

CALL TransferMoney(1, 2, 6000.00, @status);
SELECT @status;


SELECT * FROM Accounts WHERE account_id IN (1, 2);
SELECT * FROM Transactions WHERE from_account = 1 AND to_account = 2 AND amount = 6000.00;
SELECT * FROM TxnAuditLogs WHERE details LIKE '%6000.00%';

-- Thực hiện trừ tiền và cộng tiền trong một transaction.

CALL TransferMoney(1, 2, 1000.00, @status);
SELECT @status;

SELECT * FROM Accounts WHERE account_id IN (1, 2);
SELECT * FROM Transactions WHERE from_account = 1 AND to_account = 2 AND amount = 1000.00;
SELECT * FROM TxnAuditLogs WHERE details LIKE '%từ 1 đến 2%';

-- Ghi vào bảng Transactions.
SELECT * FROM Transactions WHERE from_account = 1 AND to_account = 2 AND amount = 1000.00;

-- Ghi vào bảng TxnAuditLogs.
SELECT * FROM TxnAuditLogs WHERE details LIKE '%từ 1 đến 2%';


-- 2. MVCC: Truy vấn số dư và mô tả hiện tượng snapshot

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
SELECT balance 
FROM Accounts 
WHERE account_id = 1;
-- Giả sử chờ một chút trước khi commit
COMMIT;

-- Session 2:
CALL TransferMoney(1, 2, 100.00, @status);

SELECT @status;



-- 4a. CTE Đệ Quy: Liệt kê tất cả cấp dưới nhiều tầng của một khách hàng
-- Tạo bảng Referrals
CREATE TABLE Referrals (
    referrer_id INT,
    referee_id INT,
    PRIMARY KEY (referrer_id, referee_id),
    FOREIGN KEY (referrer_id) REFERENCES Accounts(account_id),
    FOREIGN KEY (referee_id) REFERENCES Accounts(account_id)
) ENGINE=InnoDB;


INSERT INTO Referrals (referrer_id, referee_id) VALUES
(1, 2),
(2, 3), 
(2, 5), 
(5, 4);

-- CTE đệ quy để liệt kê tất cả cấp dưới của một khách hàng
WITH RECURSIVE ReferralTree AS (
    SELECT referrer_id, referee_id, 1 AS level
    FROM Referrals
    WHERE referrer_id = 1 -- Thay 1 bằng ID khách hàng cụ thể
    UNION ALL
    SELECT r.referrer_id, r.referee_id, rt.level + 1
    FROM Referrals r
    INNER JOIN ReferralTree rt ON r.referrer_id = rt.referee_id
)
SELECT 
    rt.referrer_id,
    rt.referee_id,
    a.full_name AS referee_name,
    rt.level
FROM ReferralTree rt
JOIN Accounts a ON rt.referee_id = a.account_id
ORDER BY rt.level, rt.referee_id;

-- 4b. CTE Đệ Quy: Tính tổng số tiền giao dịch của tất cả cấp dưới
WITH AvgTransaction AS (
    SELECT AVG(amount) AS avg_amount
    FROM Transactions
),
LabeledTransactions AS (
    SELECT 
        t.txn_id,
        t.amount,
        CASE 
            WHEN t.amount > (SELECT avg_amount FROM AvgTransaction) * 1.5 THEN 'High'
            WHEN t.amount < (SELECT avg_amount FROM AvgTransaction) * 0.5 THEN 'Low'
            ELSE 'Normal'
        END AS amount_category
    FROM Transactions t
    WHERE t.status = 'Success'
)
SELECT 
    lt.txn_id,
    lt.amount,
    lt.amount_category
FROM LabeledTransactions lt
WHERE lt.amount > (SELECT avg_amount FROM AvgTransaction)
ORDER BY lt.amount DESC;