CREATE DATABASE Ngay3Sql
    DEFAULT CHARACTER SET = 'utf8mb4';

USE Ngay3Sql;

-- DROP DATABASE IF EXISTS Ngay3Sql;

CREATE TABLE Candidates (
    candidate_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    years_exp INT,
    expected_salary INT
);

INSERT INTO Candidates (candidate_id, full_name, email, phone, years_exp, expected_salary) VALUES
(1, 'Nguyen Van A', 'a@gmail.com', '0911000001', 0, 600),
(2, 'Tran Thi B', 'b@gmail.com', NULL, 2, 800),
(3, 'Le Van C', 'c@gmail.com', '0911000003', 4, 1000),
(4, 'Pham Thi D', 'd@gmail.com', '0911000004', 7, 1500),
(5, 'Do Van E', 'e@gmail.com', NULL, 3, 700);


CREATE TABLE Jobs (
    job_id INT PRIMARY KEY,
    title VARCHAR(100),
    department VARCHAR(50),
    min_salary INT,
    max_salary INT
);

INSERT INTO Jobs (job_id, title, department, min_salary, max_salary) VALUES
(101, 'Backend Developer', 'IT', 800, 1200),
(102, 'Marketing Executive', 'Marketing', 700, 1000),
(103, 'Data Analyst', 'IT', 1000, 1600),
(104, 'Sales Manager', 'Sales', 1200, 2000),
(105, 'HR Assistant', 'HR', 500, 700);


CREATE TABLE Applications (
    app_id INT PRIMARY KEY,
    candidate_id INT,
    job_id INT,
    apply_date DATE,
    status VARCHAR(20),
    FOREIGN KEY (candidate_id) REFERENCES Candidates(candidate_id),
    FOREIGN KEY (job_id) REFERENCES Jobs(job_id)
);

INSERT INTO Applications (app_id, candidate_id, job_id, apply_date, status) VALUES
(1001, 1, 101, '2024-05-01', 'Pending'),
(1002, 2, 102, '2024-05-03', 'Accepted'),
(1003, 3, 103, '2024-05-05', 'Rejected'),
(1004, 4, 101, '2024-05-06', 'Accepted'),
(1005, 5, 105, '2024-05-07', 'Pending');


CREATE TABLE ShortlistedCandidates (
    candidate_id INT,
    job_id INT,
    selection_date DATE,
    PRIMARY KEY (candidate_id, job_id),  -- Khóa chính kết hợp
    FOREIGN KEY (candidate_id) REFERENCES Candidates(candidate_id),
    FOREIGN KEY (job_id) REFERENCES Jobs(job_id)
);





-- Câu 1:
-- Bước 1: Chọn từ bảng Candidates
-- Bước 2: Dùng EXISTS để kiểm tra ứng viên đó có hồ sơ ứng tuyển vào job thuộc phòng IT không
-- Bước 3: Sắp xếp theo candidate_id
SELECT *
FROM Candidates c
WHERE EXISTS (
    SELECT 1
    FROM Applications a
    JOIN Jobs j ON a.job_id = j.job_id
    WHERE a.candidate_id = c.candidate_id
      AND j.department = 'IT'
) ORDER BY c.candidate_id;

-- Câu 2:
-- Bước 1: So sánh max_salary với bất kỳ expected_salary nào trong bảng Candidates
SELECT *
FROM Jobs
WHERE max_salary > ANY (
    SELECT expected_salary
    FROM Candidates
);

-- Câu 3:
-- Bước 1: Chỉ lấy các công việc có min_salary lớn hơn mức lương mong đợi của tất cả ứng viên
SELECT *
FROM Jobs
WHERE min_salary > ALL (
    SELECT expected_salary
    FROM Candidates
);

-- Câu 4:
-- Bước 1: Lọc những hồ sơ có trạng thái 'Accepted'
-- Bước 2: Lấy candidate_id, job_id và ngày hiện tại để chèn vào bảng ShortlistedCandidates
INSERT INTO ShortlistedCandidates (candidate_id, job_id, selection_date)
SELECT candidate_id, job_id, CURRENT_DATE()
FROM Applications
WHERE status = 'Accepted';


SELECT * FROM ShortlistedCandidates;
-- Câu 5:
-- Bước 1: Dựa vào years_exp để phân loại mức độ kinh nghiệm
SELECT 
    full_name,
    years_exp,
    CASE
        WHEN years_exp < 1 THEN 'Fresher'
        WHEN years_exp BETWEEN 1 AND 3 THEN 'Junior'
        WHEN years_exp BETWEEN 4 AND 6 THEN 'Mid-level'
        ELSE 'Senior'
    END AS experience_level
FROM Candidates;

-- Câu 6:
-- Bước 1: Dùng COALESCE để thay giá trị NULL thành 'Chưa cung cấp'
SELECT 
    full_name,
    email,
    COALESCE(phone, 'Chưa cung cấp') AS phone
FROM Candidates;

-- Câu 7:
-- Bước 1: Lọc các công việc có lương tối đa khác lương tối thiểu
-- Bước 2: Và lương tối đa phải >= 1000
SELECT *
FROM Jobs
WHERE max_salary != min_salary
  AND max_salary >= 1000;