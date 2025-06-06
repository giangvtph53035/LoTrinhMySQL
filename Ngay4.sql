CREATE DATABASE OnlineLearning
    DEFAULT CHARACTER SET = 'utf8mb4';

USE OnlineLearning;

DROP DATABASE OnlineLearning;

CREATE TABLE Students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    join_date DATE DEFAULT (CURRENT_DATE)
);

INSERT INTO Students (full_name, email) VALUES
('Nguyễn Văn An', 'an.nguyen@example.com'),
('Trần Thị Bình', 'binh.tran@example.com'),
('Lê Minh Châu', 'chau.le@example.com'),
('Phạm Quốc Đạt', 'dat.pham@example.com'),
('Hoàng Thuý Hằng', 'hang.hoang@example.com');

CREATE TABLE Courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    price INT CHECK (price >= 0)
);

INSERT INTO Courses (title, description, price) VALUES
('Lập trình Python cơ bản', 'Khoá học giới thiệu về lập trình Python', 1500000),
('Thiết kế Web với HTML/CSS', 'Học cách xây dựng giao diện web', 1200000),
('Cơ sở dữ liệu SQL', 'Khoá học về quản lý cơ sở dữ liệu', 1800000),
('Machine Learning cơ bản', 'Giới thiệu về học máy', 2500000),
('Lập trình Java nâng cao', 'Khoá học chuyên sâu về Java', 2000000);

CREATE TABLE Enrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    course_id INT,
    enroll_date  DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);

INSERT INTO Enrollments (student_id, course_id, enroll_date, status) VALUES
(1, 1, '2025-01-20', 'active'),
(1, 3, '2025-02-15', 'active'),
(2, 2, '2025-02-05', 'active'),
(2, 4, '2025-03-01', 'completed'),
(3, 1, '2025-03-15', 'active'),
(3, 5, '2025-04-01', 'active'),
(4, 3, '2025-04-25', 'active'),
(4, 2, '2025-05-05', 'active'),
(5, 4, '2025-05-10', 'active'),
(5, 1, '2025-05-15', 'active');

-- Câu 4:
ALTER TABLE Enrollments
ADD status VARCHAR(20) DEFAULT 'active';

-- Câu 5:
DROP TABLE Enrollments;

-- Câu 6:
CREATE VIEW StudentCourseView AS
SELECT 
    s.student_id,
    s.full_name,
    s.email,
    c.course_id,
    c.title AS course_title
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
JOIN Courses c ON e.course_id = c.course_id;


SELECT * FROM StudentCourseView;
-- Câu 7:
CREATE INDEX idx_course_title ON Courses(title);

