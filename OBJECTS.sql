-- Authors: Alexandra Pacalajová, Jozef Sládeček
-- Date: 27.4.2025
-- Description: This script creates the database schema for a library management system.

-- Dropping tables if they exist
DROP TABLE USER_TABLE CASCADE CONSTRAINTS;
DROP TABLE WORKER CASCADE CONSTRAINTS;
DROP TABLE READER CASCADE CONSTRAINTS;
DROP TABLE BOOK CASCADE CONSTRAINTS;
DROP TABLE TITLE CASCADE CONSTRAINTS;
DROP TABLE MAGAZINE CASCADE CONSTRAINTS;
DROP TABLE AUTHOR CASCADE CONSTRAINTS;
DROP TABLE BOOK_AUTHOR CASCADE CONSTRAINTS;
DROP TABLE GENRE CASCADE CONSTRAINTS;
DROP TABLE TITLE_GENRE CASCADE CONSTRAINTS;
DROP TABLE COPY_TABLE CASCADE CONSTRAINTS;
DROP TABLE RESERVATION CASCADE CONSTRAINTS;
DROP TABLE LOAN CASCADE CONSTRAINTS;

-- Generalization of user types using inheritance (1 superclass with 2 subclasses)
-- The USER_TABLE serves as the supertype, containing common attributes (ID, name, surname, phone number, etc.) for both WORKER and READER.
-- WORKER and READER tables are subtypes, where each references the USER_TABLE for shared user attributes, using their respective ID as a foreign key.

-- USER_TABLE is the superclass for common user information
CREATE TABLE USER_TABLE
(
    ID           INT GENERATED AS IDENTITY PRIMARY KEY,
    NAME         VARCHAR(100) NOT NULL,
    SURNAME      VARCHAR(100) NOT NULL,
    PHONE_NUMBER VARCHAR(20),
    EMAIL        VARCHAR(100),
    USER_TYPE    CHAR(1)      NOT NULL,
    CONSTRAINT check_phone CHECK (REGEXP_LIKE(PHONE_NUMBER, '^[+]?[0-9]{9,15}$')),
    CONSTRAINT check_email CHECK (REGEXP_LIKE(EMAIL, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')),
    CONSTRAINT check_user_type CHECK (USER_TYPE IN ('W', 'R'))
);

-- WORKER is a subtype of USER_TABLE
CREATE TABLE WORKER
(
    ID   INT PRIMARY KEY,
    ROLE VARCHAR(50) NOT NULL,
    CONSTRAINT fk_worker_user FOREIGN KEY (ID) REFERENCES USER_TABLE (ID) ON DELETE CASCADE
);

-- READER is another subtype of USER_TABLE
CREATE TABLE READER
(
    ID              INT PRIMARY KEY,
    STREET          VARCHAR(200) NOT NULL,
    CITY            VARCHAR(50)  NOT NULL,
    ZIP_CODE        VARCHAR(10)  NOT NULL,
    COUNTRY         VARCHAR(50) DEFAULT 'Slovakia',
    EXPIRATION_DATE DATE         NOT NULL,
    CONSTRAINT fk_reader_user FOREIGN KEY (ID) REFERENCES USER_TABLE (ID) ON DELETE CASCADE
);


-- Generalization of title types using inheritance (1 superclass with 2 subclasses)
-- The TITLE table serves as the supertype, containing common attributes (ID, name, publication year, etc.) for both BOOK and MAGAZINE.
-- BOOK and MAGAZINE tables are subtypes, where each references the TITLE table for shared title attributes, using their respective ID as a foreign key.

-- TITLE is the superclass for common title information
CREATE TABLE TITLE
(
    ID               INT GENERATED AS IDENTITY PRIMARY KEY,
    NAME             VARCHAR(200) NOT NULL,
    PUBLICATION_YEAR INTEGER CHECK (PUBLICATION_YEAR > 0),
    LANGUAGE         VARCHAR(50)  NOT NULL,
    TITLE_TYPE       CHAR(1)      NOT NULL CHECK (TITLE_TYPE IN ('B', 'M')) -- B- BOOK , M - MAGAZINE
);

-- BOOK is a subtype of TITLE
CREATE TABLE BOOK
(
    ID   INT PRIMARY KEY,
    ISBN VARCHAR(20) UNIQUE,
    CONSTRAINT chk_isbn_format CHECK (
        REGEXP_LIKE(ISBN, '^978-[0-9]-[0-9]{4}-[0-9]{4}-[0-9]$')              -- ISBN-13
            OR REGEXP_LIKE(ISBN, '^[0-9]{1,5}-[0-9]{1,7}-[0-9]{1,3}-[0-9X]$') -- ISBN-10
        ),
    CONSTRAINT fk_book_title FOREIGN KEY (ID) REFERENCES TITLE (ID) ON DELETE CASCADE
);

-- MAGAZINE is another subtype of TITLE
CREATE TABLE MAGAZINE
(
    ID           INT PRIMARY KEY,
    ISSUE_NUMBER VARCHAR(50) NOT NULL,
    PUBLISHER    VARCHAR(50) NOT NULL,
    ISSN         VARCHAR(20),
    CONSTRAINT chk_issn_format CHECK (
        REGEXP_LIKE(ISSN, '^[0-9]{4}-[0-9]{3}[0-9X]$')
            OR REGEXP_LIKE(ISSN, '[0-9]{4}-[0-9]{3}-[0-9]{3}[0-9X]$')
        ),
    CONSTRAINT fk_magazine_title FOREIGN KEY (ID) REFERENCES TITLE (ID) ON DELETE CASCADE
);

CREATE TABLE AUTHOR
(
    ID   INT GENERATED AS IDENTITY PRIMARY KEY,
    NAME VARCHAR(50) NOT NULL
);

-- Relationship table between book and author
CREATE TABLE BOOK_AUTHOR
(
    BOOK_ID   INTEGER,
    AUTHOR_ID INTEGER,
    PRIMARY KEY (BOOK_ID, AUTHOR_ID),
    CONSTRAINT fk_book FOREIGN KEY (BOOK_ID) REFERENCES BOOK (ID) ON DELETE CASCADE,
    CONSTRAINT fk_author FOREIGN KEY (AUTHOR_ID) REFERENCES AUTHOR (ID)
);

CREATE TABLE GENRE
(
    ID   INT GENERATED AS IDENTITY PRIMARY KEY,
    NAME VARCHAR(100) NOT NULL UNIQUE
);

-- Relationship table between title and genre
CREATE TABLE TITLE_GENRE
(
    TITLE_ID INTEGER,
    GENRE_ID INTEGER,
    PRIMARY KEY (TITLE_ID, GENRE_ID),
    CONSTRAINT fk_title FOREIGN KEY (TITLE_ID) REFERENCES TITLE (ID),
    CONSTRAINT fk_genre FOREIGN KEY (GENRE_ID) REFERENCES GENRE (ID)
);

-- COPY_TABLE is used to manage copies of titles in the library
CREATE TABLE COPY_TABLE
(
    ID       INT GENERATED AS IDENTITY PRIMARY KEY,
    STATUS   VARCHAR(20)  NOT NULL CHECK (STATUS IN ('available', 'borrowed', 'reserved')),
    LOCATION VARCHAR(100) NOT NULL,
    TITLE_ID INTEGER      NOT NULL,
    CONSTRAINT fk_copy_title FOREIGN KEY (TITLE_ID) REFERENCES TITLE (ID) ON DELETE CASCADE
);

CREATE TABLE RESERVATION
(
    ID        INT GENERATED AS IDENTITY PRIMARY KEY,
    DATE_     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    STATUS    VARCHAR(20) NOT NULL CHECK (STATUS IN ('canceled', 'active', 'completed')),
    READER_ID INTEGER     NOT NULL,
    TITLE_ID  INTEGER     NOT NULL,
    CONSTRAINT fk_reservation_reader FOREIGN KEY (READER_ID) REFERENCES READER (ID),
    CONSTRAINT fk_reservation_title FOREIGN KEY (TITLE_ID) REFERENCES TITLE (ID)
);

CREATE TABLE LOAN
(
    ID          INT GENERATED AS IDENTITY PRIMARY KEY,
    BORROW_DATE TIMESTAMP NOT NULL,
    DUE_DATE    TIMESTAMP NOT NULL, -- Deadline
    RETURN_DATE TIMESTAMP,          -- Real date return
    STATUS      VARCHAR(20) DEFAULT 'active' CHECK (STATUS IN ('active', 'returned', 'overdue')),
    READER_ID   INTEGER   NOT NULL,
    COPY_ID     INTEGER,
    WORKER_ID   INTEGER,
    CONSTRAINT chk_due_date CHECK (DUE_DATE > BORROW_DATE),
    CONSTRAINT fk_loan_reader FOREIGN KEY (READER_ID) REFERENCES READER (ID),
    CONSTRAINT fk_loan_copy FOREIGN KEY (COPY_ID) REFERENCES COPY_TABLE (ID) ON DELETE SET NULL,
    CONSTRAINT fk_loan_worker FOREIGN KEY (WORKER_ID) REFERENCES WORKER (ID)
);


-- Inserting sample data into the tables
-- Insert into USER_TABLE
INSERT INTO USER_TABLE (NAME, SURNAME, PHONE_NUMBER, EMAIL, USER_TYPE)
VALUES ('Jozef', 'Novak', '+421900123456', 'jozef.novak@example.com', 'W');

INSERT INTO USER_TABLE (NAME, SURNAME, PHONE_NUMBER, EMAIL, USER_TYPE)
VALUES ('Martina', 'Kovacova', '+421900987654', 'martina.kovacova@example.com', 'R');

INSERT INTO USER_TABLE (NAME, SURNAME, PHONE_NUMBER, EMAIL, USER_TYPE)
VALUES ('Peter', 'Horvath', '+421911112233', 'peter.horvath@example.com', 'R');

INSERT INTO USER_TABLE (NAME, SURNAME, PHONE_NUMBER, EMAIL, USER_TYPE)
VALUES ('Zuzana', 'Mlynarova', '+421944556677', 'zuzana.mlynarova@example.com', 'W');

-- Insert into WORKER (Using existing ID from USER_TABLE)
INSERT INTO WORKER (ID, ROLE)
VALUES (1, 'Librarian');

INSERT INTO WORKER (ID, ROLE)
VALUES (4, 'Archivist');

-- Insert into READER (Using existing ID from USER_TABLE)
INSERT INTO READER (ID, STREET, CITY, ZIP_CODE, COUNTRY, EXPIRATION_DATE)
VALUES (2, 'Hlavna 25', 'Bratislava', '12345', 'Slovakia', TO_DATE('2025-12-31', 'YYYY-MM-DD'));

INSERT INTO READER (ID, STREET, CITY, ZIP_CODE, COUNTRY, EXPIRATION_DATE)
VALUES (3, 'Mierova 12', 'Kosice', '04011', 'Slovakia', TO_DATE('2026-05-31', 'YYYY-MM-DD'));

-- Insert into TITLE
INSERT INTO TITLE (NAME, PUBLICATION_YEAR, LANGUAGE, TITLE_TYPE)
VALUES ('The Great Adventure', 2022, 'Slovak', 'B');

INSERT INTO TITLE (NAME, PUBLICATION_YEAR, LANGUAGE, TITLE_TYPE)
VALUES ('Legends of the Forest', 2020, 'Slovak', 'B');

INSERT INTO TITLE (NAME, PUBLICATION_YEAR, LANGUAGE, TITLE_TYPE)
VALUES ('Monthly Tech Digest', 2023, 'English', 'M');

INSERT INTO TITLE (NAME, PUBLICATION_YEAR, LANGUAGE, TITLE_TYPE)
VALUES ('Science Weekly', 2024, 'English', 'M');

-- Insert into BOOK (Linking with existing titles)
INSERT INTO BOOK (ID, ISBN)
VALUES (1, '978-1-2345-6789-0');

INSERT INTO BOOK (ID, ISBN)
VALUES (2, '978-0-9876-5432-1');

-- Insert into MAGAZINE
INSERT INTO MAGAZINE (ID, ISSUE_NUMBER, PUBLISHER, ISSN)
VALUES (3, '2023-01', 'Tech Media', '2049-3630');

INSERT INTO MAGAZINE (ID, ISSUE_NUMBER, PUBLISHER, ISSN)
VALUES (4, '2023-02', 'News Publishers', '0032-8472');

-- Insert into AUTHOR
INSERT INTO AUTHOR (NAME)
VALUES ('John Smith');

INSERT INTO AUTHOR (NAME)
VALUES ('Anna Johnson');

-- Insert into BOOK_AUTHOR
INSERT INTO BOOK_AUTHOR (BOOK_ID, AUTHOR_ID)
VALUES (1, 1);

INSERT INTO BOOK_AUTHOR (BOOK_ID, AUTHOR_ID)
VALUES (2, 1);

-- Insert into GENRE
INSERT INTO GENRE (NAME)
VALUES ('Fantasy');

INSERT INTO GENRE (NAME)
VALUES ('Science');

INSERT INTO GENRE (NAME)
VALUES ('Technology');

-- Insert into TITLE_GENRE
INSERT INTO TITLE_GENRE (TITLE_ID, GENRE_ID)
VALUES (1, 1);

INSERT INTO TITLE_GENRE (TITLE_ID, GENRE_ID)
VALUES (2, 1);

INSERT INTO TITLE_GENRE (TITLE_ID, GENRE_ID)
VALUES (3, 3);

INSERT INTO TITLE_GENRE (TITLE_ID, GENRE_ID)
VALUES (4, 2);

-- Insert into COPY
INSERT INTO COPY_TABLE (STATUS, LOCATION, TITLE_ID)
VALUES ('available', 'Shelf A1', 1);

INSERT INTO COPY_TABLE (STATUS, LOCATION, TITLE_ID)
VALUES ('borrowed', 'Shelf B2', 2);

INSERT INTO COPY_TABLE (STATUS, LOCATION, TITLE_ID)
VALUES ('borrowed', 'Shelf C3', 3);

INSERT INTO COPY_TABLE (STATUS, LOCATION, TITLE_ID)
VALUES ('reserved', 'Shelf C3', 3);

INSERT INTO COPY_TABLE (STATUS, LOCATION, TITLE_ID)
VALUES ('reserved', 'Shelf D1', 4);

-- Insert into RESERVATION
INSERT INTO RESERVATION (STATUS, READER_ID, TITLE_ID)
VALUES ('active', 3, 4);

INSERT INTO RESERVATION (STATUS, READER_ID, TITLE_ID)
VALUES ('active', 2, 3);

-- Insert into LOAN
INSERT INTO LOAN
(BORROW_DATE, DUE_DATE, RETURN_DATE, STATUS, READER_ID, COPY_ID, WORKER_ID)
VALUES (TO_TIMESTAMP('2025-03-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-03-15 10:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        NULL, 'active', 3, 2, 1);

INSERT INTO LOAN
(BORROW_DATE, DUE_DATE, RETURN_DATE, STATUS, READER_ID, COPY_ID, WORKER_ID)
VALUES (TO_TIMESTAMP('2025-03-05 14:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-03-20 14:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-03-18 16:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        'returned', 3, 4, 1);

INSERT INTO LOAN
(BORROW_DATE, DUE_DATE, RETURN_DATE, STATUS, READER_ID, COPY_ID, WORKER_ID)
VALUES (TO_TIMESTAMP('2025-04-01 09:30:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2025-04-15 09:30:00', 'YYYY-MM-DD HH24:MI:SS'),
        NULL, 'returned', 2, 2, 1);

-------------------------------------------------------------------------------------
-- SELECT 1: Join tables - List readers with their basic information
-------------------------------------------------------------------------------------
SELECT u.NAME, u.SURNAME, u.EMAIL, r.CITY
FROM USER_TABLE u
         JOIN READER r ON u.ID = r.ID;

-------------------------------------------------------------------------------------
-- SELECT 2: Join tables - List magazines with their ISSN
-------------------------------------------------------------------------------------
SELECT t.NAME AS MAGAZINE_TITLE, m.ISSN
FROM MAGAZINE m
         JOIN TITLE t ON m.ID = t.ID;

-------------------------------------------------------------------------------------
-- SELECT 3: Join three tables - List authors with book titles
-------------------------------------------------------------------------------------
SELECT a.NAME AS AUTHOR_NAME, t.NAME AS BOOK_TITLE
FROM AUTHOR a
         JOIN BOOK_AUTHOR ba ON a.ID = ba.AUTHOR_ID
         JOIN BOOK b ON ba.BOOK_ID = b.ID
         JOIN TITLE t ON b.ID = t.ID;

-------------------------------------------------------------------------------------
-- SELECT 4: GROUP BY + aggregation - Count loans by status (active, returned)
-------------------------------------------------------------------------------------
SELECT STATUS, COUNT(*) AS LOAN_COUNT
FROM LOAN
GROUP BY STATUS;

-------------------------------------------------------------------------------------
-- SELECT 5: GROUP BY + aggregation - Count titles by genre
-------------------------------------------------------------------------------------
SELECT g.NAME AS GENRE_NAME, COUNT(*) AS TITLE_COUNT
FROM GENRE g
         JOIN TITLE_GENRE tg ON g.ID = tg.GENRE_ID
GROUP BY g.NAME;

-------------------------------------------------------------------------------------
-- SELECT 6: EXISTS - List readers with at least one active reservation
-------------------------------------------------------------------------------------
SELECT u.NAME, u.SURNAME
FROM USER_TABLE u
WHERE USER_TYPE = 'R'
  AND EXISTS (
    SELECT 1
    FROM RESERVATION r
    WHERE r.READER_ID = u.ID
      AND r.STATUS = 'active'
);

-------------------------------------------------------------------------------------
-- SELECT 7: IN (with nested SELECT) - List books currently loaned
-------------------------------------------------------------------------------------
SELECT t.NAME AS BOOK_TITLE
FROM TITLE t
WHERE t.ID IN (
    SELECT c.TITLE_ID
    FROM COPY_TABLE c
             JOIN LOAN l ON c.ID = l.COPY_ID
    WHERE l.STATUS = 'returned'
);