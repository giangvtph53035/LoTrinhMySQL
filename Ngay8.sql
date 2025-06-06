
-- Tạo và nhập dữ liệu cho database
CREATE DATABASE IF NOT EXISTS Ngay8SQL;
USE Ngay8SQL;

Drop database Ngay8SQL;

-- Tạo bảng Users
CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    username VARCHAR(30),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Nhập dữ liệu mẫu vào Users
INSERT INTO Users (user_id, username, created_at) VALUES
(1, 'Giang', '2025-06-01 10:00:00'),
(2, 'Hà', '2025-06-01 11:00:00'),
(3, 'Trang', '2025-06-02 12:00:00'),
(4, 'Hiền', '2025-06-03 13:00:00'),
(5, 'Thảo', '2025-06-04 14:00:00');

-- Tạo bảng Posts
CREATE TABLE Posts (
    post_id INT PRIMARY KEY,
    user_id INT,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    likes INT DEFAULT 0,
    hashtags VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Nhập dữ liệu mẫu vào Posts
INSERT INTO Posts (post_id, user_id, content, created_at, likes, hashtags) VALUES
(1, 1, 'Great workout today!', '2025-06-06 08:00:00', 50, 'fitness,health'),
(2, 2, 'Loving this new recipe', '2025-06-06 09:00:00', 30, 'food,healthy'),
(3, 3, 'Running in the park', '2025-06-05 10:00:00', 20, 'fitness,running'),
(4, 4, 'Morning yoga session', '2025-06-04 11:00:00', 15, 'yoga,fitness'),
(5, 5, 'New book review', '2025-06-03 12:00:00', 10, 'books,review');

-- Tạo bảng Follows
CREATE TABLE Follows (
    follower_id INT,
    followee_id INT,
    PRIMARY KEY (follower_id, followee_id),
    FOREIGN KEY (follower_id) REFERENCES Users(user_id),
    FOREIGN KEY (followee_id) REFERENCES Users(user_id)
);

-- Nhập dữ liệu mẫu vào Follows
INSERT INTO Follows (follower_id, followee_id) VALUES
(1, 2), (1, 3), (2, 1), (3, 4), (4, 5);

-- Tạo bảng PostViews với phân vùng
CREATE TABLE PostViews (
    view_id INT,
    post_id INT,
    viewer_id INT,
    view_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (view_id, view_time)
) PARTITION BY RANGE (UNIX_TIMESTAMP(view_time)) (
    PARTITION p202501 VALUES LESS THAN (UNIX_TIMESTAMP('2025-02-01 00:00:00')),
    PARTITION p202502 VALUES LESS THAN (UNIX_TIMESTAMP('2025-03-01 00:00:00')),
    PARTITION p202503 VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01 00:00:00')),
    PARTITION p202504 VALUES LESS THAN (UNIX_TIMESTAMP('2025-05-01 00:00:00')),
    PARTITION p202505 VALUES LESS THAN (UNIX_TIMESTAMP('2025-06-01 00:00:00')),
    PARTITION p202506 VALUES LESS THAN (UNIX_TIMESTAMP('2025-07-01 00:00:00')),
    PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

-- Nhập dữ liệu mẫu vào PostViews
INSERT INTO PostViews (view_id, post_id, viewer_id, view_time) VALUES
(1, 1, 2, '2025-06-06 08:05:00'),
(2, 1, 3, '2025-06-06 08:10:00'),
(3, 1, 4, '2025-06-06 08:15:00'),
(4, 2, 1, '2025-06-06 09:05:00'),
(5, 2, 3, '2025-06-06 09:10:00'),
(6, 3, 4, '2025-06-05 10:05:00'),
(7, 3, 5, '2025-06-05 10:10:00'),
(8, 4, 1, '2025-06-04 11:05:00'),
(9, 4, 2, '2025-06-04 11:10:00'),
(10, 5, 3, '2025-06-03 12:05:00');

-- 1. Tận dụng bộ nhớ đệm
SELECT post_id, user_id, content, likes, created_at
FROM Posts
WHERE DATE(created_at) = CURDATE()
ORDER BY likes DESC
LIMIT 10;

CREATE TABLE TopPostsCache (
    post_id INT PRIMARY KEY,
    user_id INT,
    content VARCHAR(1000),
    likes INT,
    created_at TIMESTAMP
) ENGINE=MEMORY;

INSERT INTO TopPostsCache
SELECT post_id, user_id, content, likes, created_at
FROM Posts
WHERE DATE(created_at) = CURDATE()
ORDER BY likes DESC
LIMIT 10;

select * from TopPostsCache;

-- 2. Sử dụng EXPLAIN ANALYZE
EXPLAIN ANALYZE
SELECT * FROM Posts 
WHERE hashtags LIKE '%fitness%' 
ORDER BY created_at DESC 
LIMIT 20;

CREATE FULLTEXT INDEX idx_hashtags ON Posts(hashtags);

-- 3. Phân vùng bảng PostViews và thống kê lượt xem
SELECT 
    DATE_FORMAT(view_time, '%Y-%m') AS month,
    COUNT(*) AS view_count
FROM PostViews
WHERE view_time >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY DATE_FORMAT(view_time, '%Y-%m')
ORDER BY month DESC;

-- 4. Chuẩn hóa và phi chuẩn hóa
CREATE TABLE PostHashtags (
    post_id INT,
    hashtag VARCHAR(50),
    PRIMARY KEY (post_id, hashtag),
    INDEX idx_hashtag (hashtag)
);

INSERT INTO PostHashtags (post_id, hashtag)
SELECT post_id, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(hashtags, ',', numbers.n), ',', -1)) AS hashtag
FROM Posts
CROSS JOIN (SELECT a.N + b.N * 10 + 1 AS n
            FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) a,
                 (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) b) numbers
WHERE hashtags IS NOT NULL
AND n <= 1 + (LENGTH(hashtags) - LENGTH(REPLACE(hashtags, ',', '')));

CREATE TABLE PopularPostsDaily (
    date DATE,
    post_id INT,
    view_count BIGINT,
    like_count INT,
    PRIMARY KEY (date, post_id)
);

INSERT INTO PopularPostsDaily (date, post_id, view_count, like_count)
SELECT 
    DATE(view_time) AS date,
    post_id,
    COUNT(*) AS view_count,
    (SELECT likes FROM Posts p WHERE p.post_id = pv.post_id) AS like_count
FROM PostViews pv
WHERE DATE(view_time) = CURDATE()
GROUP BY date, post_id;

-- 5. Tối ưu kiểu dữ liệu
ALTER TABLE PostViews MODIFY view_id INT;
ALTER TABLE PostViews MODIFY viewer_id INT;
ALTER TABLE Posts MODIFY hashtags VARCHAR(100);
ALTER TABLE Users MODIFY username VARCHAR(30);
ALTER TABLE Users MODIFY created_at TIMESTAMP;
ALTER TABLE Posts MODIFY created_at TIMESTAMP;
ALTER TABLE PostViews MODIFY view_time TIMESTAMP;

-- 6. Sử dụng Window Functions để xếp hạng
SELECT 
    date,
    post_id,
    view_count,
    rank_position
FROM (
    SELECT 
        DATE(view_time) AS date,
        post_id,
        COUNT(*) AS view_count,
        RANK() OVER (PARTITION BY DATE(view_time) ORDER BY COUNT(*) DESC) AS rank_position
    FROM PostViews
    WHERE view_time >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    GROUP BY DATE(view_time), post_id
) ranked
WHERE rank_position <= 3
ORDER BY date DESC, rank_position;

-- 7. Tối ưu transaction cho lượt thích
DELIMITER //
CREATE PROCEDURE UpdatePostLike(
    IN p_post_id INT,
    IN p_user_id INT
)
BEGIN
    DECLARE already_liked INT;
    
    START TRANSACTION;
    
    SELECT COUNT(*) INTO already_liked
    FROM PostLikes
    WHERE post_id = p_post_id AND user_id = p_user_id;
    
    IF already_liked = 0 THEN
        INSERT INTO PostLikes (post_id, user_id) VALUES (p_post_id, p_user_id);
        UPDATE Posts SET likes = likes + 1 WHERE post_id = p_post_id;
    END IF;
    
    COMMIT;
END //
DELIMITER ;


CREATE TABLE PostLikes (
    post_id INT,
    user_id INT,
    like_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, user_id)
);

-- 8. Kiểm tra Slow Query Log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL slow_query_log_file = '/var/log/mysql/slow.log';
SET GLOBAL long_query_time = 1;

SELECT * FROM Posts p
JOIN PostViews pv ON p.post_id = pv.post_id
WHERE p.hashtags LIKE '%fitness%'
ORDER BY pv.view_time DESC
LIMIT 20;

CREATE INDEX idx_postviews_postid ON PostViews(post_id);
SELECT p.post_id, p.content, p.created_at, pv.view_time
FROM Posts p
JOIN PostViews pv ON p.post_id = pv.post_id
WHERE p.hashtags LIKE '%fitness%'
ORDER BY pv.view_time DESC
LIMIT 20;

-- 9. Sử dụng OPTIMIZER_TRACE để gỡ lỗi
SET SESSION optimizer_trace="enabled=on";
SELECT p.post_id, p.content, u.username
FROM Posts p
JOIN Users u ON p.user_id = u.user_id
JOIN PostViews pv ON p.post_id = pv.post_id
WHERE p.hashtags LIKE '%fitness%'
ORDER BY pv.view_time DESC
LIMIT 20;
SELECT * FROM information_schema.optimizer_trace;
SET SESSION optimizer_trace="enabled=off";
