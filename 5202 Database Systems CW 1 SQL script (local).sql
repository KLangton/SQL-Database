DROP TABLE IF EXISTS loan;
DROP TABLE IF EXISTS copy;
DROP TABLE IF EXISTS book;
DROP TABLE IF EXISTS student;
DROP TABLE IF EXISTS audit_table;
DROP VIEW IF EXISTS cmp_students;
DROP PROCEDURE IF EXISTS loan_new;

SET FOREIGN_KEY_CHECKS=0;
-- Creation of the tables

CREATE TABLE book (
	isbn CHAR(17) NOT NULL, 
	title VARCHAR(45) NOT NULL,
	author VARCHAR(45) NOT NULL,
    CONSTRAINT isbn_pk PRIMARY KEY (isbn));
    
CREATE TABLE copy (
	`code` INT NOT NULL, 
	isbn CHAR(17) NOT NULL, 
	duration INT NOT NULL,
    CONSTRAINT code_pk PRIMARY KEY (`code`));

CREATE TABLE student (
	`no` INT NOT NULL,
	`name` VARCHAR(45) NOT NULL,
	school CHAR(3) NOT NULL,
	embargo BIT DEFAULT FALSE,
    CONSTRAINT student_pk PRIMARY KEY(`no`));
    
    CREATE TABLE loan (
	`code` INT NOT NULL,
	`no` INT NOT NULL,
	taken DATE NOT NULL,
	due DATE NOT NULL,
	`return` DATE NULL,
    CONSTRAINT loan_pk PRIMARY KEY (taken, `no`, `code`),
	CONSTRAINT loan_fk1 FOREIGN KEY (`no`) 
		REFERENCES STUDENT(`no`),
    CONSTRAINT loan_fk2 FOREIGN KEY (`code`) 
		REFERENCES COPY(`code`) );

CREATE TABLE audit_table(
audit_code INT NOT NULL AUTO_INCREMENT,
`code` INT NOT NULL, 
`no` INT NOT NULL, 
taken DATE NOT NULL, 
due DATE NOT NULL, 
`return` DATE NULL,
CONSTRAINT audit_pk PRIMARY KEY (audit_code));

-- Insertion of table values

INSERT INTO book (isbn, title, author) 
	VALUES ('111-2-33-444444-5', 'Pro JavaFX', 'Dave Smith'),
	('222-3-44-555555-6', 'Oracle Systems', 'Kate Roberts'),
	('333-4-55-666666-7', 'Expert jQuery', 'Mike Smith');
    
INSERT INTO copy (`code`, isbn, duration) 
	VALUES (1011, '111-2-33-444444-5', 21),
	(1012, '111-2-33-444444-5', 14),
	(1013, '111-2-33-444444-5', 7),
	(2011, '222-3-44-555555-6', 21),
	(3011, '333-4-55-666666-7', 7),
	(3012, '333-4-55-666666-7', 14);

INSERT INTO student (`no`, `name`, school, embargo) 
	VALUES (2001, 'Mike', 'CMP', 0),
	(2002, 'Andy', 'CMP', 1),
	(2003, 'Sarah', 'ENG', 0),
	(2004, 'Karen', 'ENG', 1),
	(2005, 'Lucy', 'BUE', 0);

INSERT INTO loan (`code`, `no`, taken, due, `return`) 
	VALUES (1011, 2002, '2022-01-10', '2022-01-31', '2022-01-31'),
	(1011, 2002, '2022-02-05', '2022-02-26', '2022-02-23'),
	(1011, 2003, '2022-04-10', '2022-05-31', null),
	(1013, 2003, '2021-03-02', '2021-03-16', '2021-03-10'),
	(1013, 2002, '2021-08-02', '2021-08-16', '2021-08-16'),
	(2011, 2004, '2020-02-1', '2020-02-22', '2020-02-20'),
	(3011, 2002, '2002-07-03', '2022-07-10', null),
	(3011, 2005, '2021-10-10', '2021-10-17', '2021-10-20');

-- create view
CREATE VIEW cmp_students
	AS SELECT `no`, `name`, school, embargo
    FROM student
    WHERE school = 'CMP'
    WITH CHECK OPTION;
--UPDATE cmp_students SET school = 'BUE';


    
-- create procedure
DELIMITER $$
CREATE PROCEDURE loan_new (IN book_isbn CHAR(17), IN student_no INT)
  BEGIN
    DECLARE complete BOOLEAN DEFAULT FALSE;
    DECLARE curs_code INT;
	DECLARE curs_duration TINYINT;
    DECLARE student_embargo BIT;
    
    DECLARE curs_c CURSOR FOR
    SELECT `code`, duration 
    FROM copy WHERE isbn = book_isbn;
    DECLARE CONTINUE HANDLER FOR NOT FOUND
      SET complete = TRUE;
        
    IF (SELECT embargo
		FROM student
		WHERE `no`= student_no)THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Student failed to meet necessary embargo requirements, banned from book loans';
    END IF;
    
    OPEN curs_c;
    froot_loops : LOOP
      FETCH NEXT FROM curs_c INTO curs_code, curs_duration;
     -- when cursor runs out there is no book copy available !
      IF curs_code IS NULL THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'unable to retrieve book copy';
      END IF;
      
      IF curs_code IS NOT NULL THEN
        INSERT INTO loan
		(`code`, `no`, taken, due, `return`) VALUES
        
            -- ToDo : employ date & time functions !
            (curs_code, student_no, current_date(), adddate(current_date(),INTERVAL curs_duration DAY), NULL);
        LEAVE froot_loops;
      END IF;
    END LOOP;
    CLOSE curs_c;
    END $$
DELIMITER ;
CALL loan_new ('111-2-33-444444-5', 2001);

-- create trigger
DELIMITER $$
CREATE TRIGGER audit_trail
AFTER UPDATE ON audit_table FOR EACH ROW
    BEGIN 
    IF (NEW.`return` IS NOT NULL) THEN
    IF (NEW.`return` > NEW.due) THEN
    IF (loan.`return` > loan.due) OR (CURDATE() < loan.due) THEN
        INSERT INTO audit_table (
		`code`, `no`, taken, due, `return`) VALUES
       (NEW.`code`, NEW.`no`, NEW.taken, NEW.due, NEW.`return`);
       END IF;
		END IF;
			END IF;
    END $$
DELIMITER ;

-- 1 
SELECT isbn, title, author
	FROM  book;
    
-- 2
SELECT `no`, `name`, school
	FROM STUDENT
    ORDER BY school DESC;

-- 3
SELECT isbn, title
	FROM  book
    WHERE author LIKE '%Smith';
    
-- 4
SELECT MAX(due) AS latest_due_date
	FROM loan;
	
-- 5
SELECT `no`
	FROM loan
	WHERE due = 
		(select MAX(due) FROM loan);

-- 6
SELECT `no`, `name`
	FROM student
	WHERE `no` = (SELECT `no` 
					FROM loan
                    WHERE due = (SELECT MAX(due) 
									FROM loan));
                                    
-- 7
SELECT `code`, `no`, due
	FROM loan
    WHERE YEAR(taken) = YEAR(CURDATE())
						AND (`return` IS NULL);
                        
-- 8
SELECT DISTINCT S.`no`, S.`name`, B.isbn, B.title
	FROM copy AS C INNER JOIN loan AS L
		on C.`code` = L.`code`
				INNER JOIN student AS S 
                ON L.`no` = S.`no`
					INNER JOIN book B 
                    on C.isbn = B.isbn
						WHERE C.duration =7;

-- 9 
SELECT student.`no`, student.`name`
	FROM student INNER JOIN loan
	ON student.`no` = loan.`no`
    WHERE due = (SELECT MAX(due) 
				FROM loan);
    

-- 10
SELECT book.title, COUNT(book.title) AS FREQUENCY
	FROM book INNER JOIN copy
    ON book.isbn = copy.isbn
		INNER JOIN loan 
		on copy.`code` = loan.`code`
		GROUP BY book.title
		HAVING (COUNT(book.title));
-- 11 
SELECT book.title, COUNT(book.title) AS FREQUENCY
	FROM book INNER JOIN copy
    ON book.isbn = copy.isbn
		INNER JOIN loan 
		on copy.`code` = loan.`code`
		GROUP BY book.title
		HAVING (COUNT(book.title)) >=2;
