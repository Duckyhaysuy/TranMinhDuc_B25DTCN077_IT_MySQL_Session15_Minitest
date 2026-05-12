CREATE DATABASE StudentManagement;
USE StudentManagement;

CREATE TABLE students (
    student_id VARCHAR(5) PRIMARY KEY,
    full_name VARCHAR(50) NOT NULL,
    total_debt DECIMAL(10,2) DEFAULT 0
);

CREATE TABLE subjects (
    subject_id VARCHAR(5) PRIMARY KEY,
    subject_name VARCHAR(50) NOT NULL,
    credits INT CHECK (credits > 0)
);

CREATE TABLE grades (
    student_id VARCHAR(5),
    subject_id VARCHAR(5),
    score DECIMAL(4,2) CHECK (score BETWEEN 0 AND 10),
    PRIMARY KEY (student_id, subject_id),
    CONSTRAINT fk_grades_student
	FOREIGN KEY (student_id) REFERENCES students(student_id)
	ON DELETE CASCADE
	ON UPDATE CASCADE,

    CONSTRAINT fk_grades_subject
	FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

CREATE TABLE grade_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(5),
    subject_id VARCHAR(5),
    old_score DECIMAL(4,2),
    new_score DECIMAL(4,2),
    change_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO students (student_id, full_name, total_debt) VALUES
('SV01', 'Nguyen Van An', 7000000),
('SV02', 'Ha Bich Ngoc', 5000000),
('SV03', 'Tran Minh Khoa', 2500000),
('SV04', 'Le Thu Trang', 0),
('SV05', 'Pham Quang Huy', 3500000);

INSERT INTO subjects (subject_id, subject_name, credits) VALUES
('MH01', 'Co so du lieu', 3),
('MH02', 'Lap trinh Python', 4),
('MH03', 'Toan roi rac', 3),
('MH04', 'He quan tri CSDL', 4),
('MH05', 'Mang may tinh', 3);

INSERT INTO grades (student_id, subject_id, score) VALUES
('SV01', 'MH01', 8.5),
('SV01', 'MH02', 7.8),
('SV01', 'MH03', 3.5),
('SV02', 'MH01', 9.0),
('SV02', 'MH04', 6.8),
('SV02', 'MH05', 10),
('SV03', 'MH02', 0),
('SV03', 'MH03', 5.5),
('SV04', 'MH01', 4.0),
('SV04', 'MH05', 2.8),
('SV05', 'MH04', 7.2),
('SV05', 'MH03', 8.9);

DELIMITER //
CREATE TRIGGER tg_check_score
BEFORE INSERT ON grades
FOR EACH ROW
BEGIN
    IF NEW.score < 0 THEN
        SET NEW.score = 0;
    ELSEIF NEW.score > 10 THEN
        SET NEW.score = 10;
    END IF;
END //

DELIMITER ;

START TRANSACTION;

INSERT INTO students (student_id, full_name)
VALUES ('SV06', 'Do Khanh Linh');

UPDATE students
SET total_debt = 5000000
WHERE student_id = 'SV06';

COMMIT;

DELIMITER //
CREATE TRIGGER tg_log_grade_update
AFTER UPDATE ON grades
FOR EACH ROW
BEGIN
    IF OLD.score <> NEW.score THEN
	INSERT INTO grade_log (student_id, subject_id, old_score, new_score, change_date)
	VALUES( OLD.student_id, OLD.subject_id, OLD.score, NEW.score, NOW());
    END IF;
END //

DELIMITER ;


DELIMITER //
CREATE PROCEDURE sp_pay_tuition()
BEGIN
    DECLARE v_debt DECIMAL(10,2);
    START TRANSACTION;

    UPDATE students
    SET total_debt = total_debt - 2000000
    WHERE student_id = 'SV01';

    SELECT total_debt
    INTO v_debt
    FROM students
    WHERE student_id = 'SV01';

    IF v_debt < 0 THEN
        ROLLBACK;
    ELSE
        COMMIT;
    END IF;
END //
DELIMITER ;

CALL sp_pay_tuition();


DELIMITER //
CREATE TRIGGER tg_prevent_pass_update
BEFORE UPDATE ON grades
FOR EACH ROW
BEGIN
    IF OLD.score >= 4.0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Khong the sua diem: Sinh vien da qua mon';
    END IF;
END //
DELIMITER ;
