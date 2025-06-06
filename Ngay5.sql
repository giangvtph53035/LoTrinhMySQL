CREATE DATABASE HotelBooking
    DEFAULT CHARACTER SET = 'utf8mb4';
USE HotelBooking;

DROP DATABASE IF EXISTS HotelBooking;


CREATE TABLE Rooms (
    room_id INT PRIMARY KEY AUTO_INCREMENT,
    room_number VARCHAR(10) UNIQUE,
    type VARCHAR(20),
    status VARCHAR(20),
    price INT CHECK (price >= 0)
);

INSERT INTO Rooms (room_number, type, status, price) VALUES
('101', 'Single', 'Available', 1000),
('102', 'Double', 'Available', 1500),
('103', 'Suite', 'Occupied', 3000),
('104', 'Single', 'Available', 1200),
('105', 'Double', 'Occupied', 1800);

CREATE TABLE Guests (
    guest_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100),
    phone VARCHAR(20)
);

INSERT INTO Guests (full_name, phone) VALUES
('Nguyen Van A', '0912345678'),
('Tran Thi B', '0987654321'),
('Le Van C', '0935123456'),
('Pham Thi D', '0908765432'),
('Hoang Van E', '0923456789');


CREATE TABLE Bookings (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    guest_id INT,
    room_id INT,
    check_in DATE,
    check_out DATE,
    status VARCHAR(20),
    FOREIGN KEY (guest_id) REFERENCES Guests(guest_id),
    FOREIGN KEY (room_id) REFERENCES Rooms(room_id)
);

INSERT INTO Bookings (guest_id, room_id, check_in, check_out, status) VALUES
(1, 1, '2025-06-01', '2025-06-03', 'Confirmed'),
(2, 3, '2025-06-02', '2025-06-05', 'Checked-in'),
(3, 2, '2025-06-10', '2025-06-12', 'Pending'),
(4, 4, '2025-06-15', '2025-06-20', 'Confirmed'),
(5, 1, '2025-06-25', '2025-06-27', 'Cancelled');

CREATE TABLE Invoices (
    invoice_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT,
    total_amount INT,
    generated_date DATE,
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id)
);

INSERT INTO Invoices (booking_id, total_amount, generated_date) VALUES
(1, 100, '2025-06-03'),
(2, 450, '2025-06-05'),
(3, 160, '2025-06-12'),
(4, 300, '2025-06-20');


DELIMITER ::
CREATE PROCEDURE MakeBooking(
    IN p_guest_id INT,
    IN p_room_id INT,
    IN p_check_in DATE,
    IN p_check_out DATE
)
BEGIN
    -- Kiểm tra phòng có sẵn không
    IF (SELECT status FROM Rooms WHERE room_id = p_room_id) != 'Available' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is not available!';
    END IF;

    -- Kiểm tra trùng lịch đặt phòng
    IF EXISTS (
        SELECT 1 FROM Bookings
        WHERE room_id = p_room_id
          AND status = 'Confirmed'
          AND (
                (p_check_in < check_out AND p_check_out > check_in)
              )
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is already booked for the selected dates!';
    END IF;

    -- Nếu hợp lệ, tạo booking và cập nhật phòng
    INSERT INTO Bookings (guest_id, room_id, check_in, check_out, status)
    VALUES (p_guest_id, p_room_id, p_check_in, p_check_out, 'Confirmed');

    UPDATE Rooms SET status = 'Occupied' WHERE room_id = p_room_id;
END ::
DELIMITER ;

CALL MakeBooking(p_guest_id, p_room_id, p_check_in, p_check_out);

CALL MakeBooking(3, 2, '2025-07-01', '2025-07-03');

-- Trigger: after_booking_cancel
DELIMITER ::
CREATE TRIGGER after_booking_cancel
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
    IF OLD.status <> 'Cancelled' AND NEW.status = 'Cancelled' THEN
        -- Kiểm tra còn booking nào khác cho phòng này trong tương lai không
        IF NOT EXISTS (
            SELECT 1 FROM Bookings
            WHERE room_id = NEW.room_id
              AND status = 'Confirmed'
              AND check_in > CURDATE()
        ) THEN
            UPDATE Rooms SET status = 'Available' WHERE room_id = NEW.room_id;
        END IF;
    END IF;
END ::
DELIMITER ;

SHOW TRIGGERS FROM HotelBooking WHERE `Trigger` = 'after_booking_cancel';

UPDATE Bookings SET status = 'Cancelled' WHERE booking_id = 1;

SELECT * FROM Bookings WHERE booking_id = 1;
SELECT * FROM Rooms WHERE room_id = 1;


-- Bonus: Stored Procedure GenerateInvoice
DELIMITER ::
CREATE PROCEDURE GenerateInvoice(IN p_booking_id INT)
BEGIN
    DECLARE v_check_in DATE;
    DECLARE v_check_out DATE;
    DECLARE v_room_id INT;
    DECLARE v_price INT;
    DECLARE v_nights INT;
    DECLARE v_total INT;

    SELECT check_in, check_out, room_id INTO v_check_in, v_check_out, v_room_id
    FROM Bookings WHERE booking_id = p_booking_id;

    SELECT price INTO v_price FROM Rooms WHERE room_id = v_room_id;

    SET v_nights = DATEDIFF(v_check_out, v_check_in);
    SET v_total = v_nights * v_price;

    INSERT INTO Invoices (booking_id, total_amount, generated_date)
    VALUES (p_booking_id, v_total, CURDATE());
END ::
DELIMITER ;

CALL GenerateInvoice(p_booking_id);

CALL GenerateInvoice(1);

DELETE FROM Invoices WHERE booking_id = 1;