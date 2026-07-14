-- CREATE TABLES

-- Book Table
DROP TABLE IF EXISTS Books;
CREATE TABLE Books (
    Book_ID SERIAL PRIMARY KEY,
    Title VARCHAR(100),
    Author VARCHAR(100),
    Genre VARCHAR(50),
    Published_Year INT,
    Price NUMERIC(10, 2),
    Stock INT
);

--Customers Table

DROP TABLE IF EXISTS customers;
CREATE TABLE Customers (
    Customer_ID SERIAL PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100),
    Phone VARCHAR(15),
    City VARCHAR(50),
    Country VARCHAR(150)
);

--Orders Table

DROP TABLE IF EXISTS orders;
CREATE TABLE Orders (
    Order_ID SERIAL PRIMARY KEY,
    Customer_ID INT REFERENCES Customers(Customer_ID),
    Book_ID INT REFERENCES Books(Book_ID),
    Order_Date DATE,
    Quantity INT,
    Total_Amount NUMERIC(10, 2)
);



SELECT * FROM BOOKS;
SELECT * FROM CUSTOMERS;
SELECT * FROM ORDERS;

-- BASIC QUERIES:-

-- 1) Retrieve all books in the "Fiction" genre.

SELECT * FROM BOOKS
WHERE GENRE='Fiction';

-- 2) Find books published after the year 1950.

SELECT * FROM BOOKS
WHERE PUBLISHED_YEAR>1950;

-- 3) List all customers from the Canada.

SELECT NAME FROM CUSTOMERS
WHERE COUNTRY='Canada';

-- 4) Show orders placed in November 2023.

SELECT * FROM ORDERS
WHERE ORDER_DATE BETWEEN '2023-11-01' AND '2023-11-30';

-- 5) Retrieve the total stock of books available.

SELECT SUM(STOCK) AS TOTAL_STOCK
FROM BOOKS;

-- 6) Find the details of the most expensive book.

SELECT * FROM BOOKS 
WHERE PRICE=(SELECT MAX(PRICE) FROM BOOKS);

-- 7) Show all customers who ordered more than 1 quantity of a book.

SELECT DISTINCT C.CUSTOMER_ID, C.NAME
FROM CUSTOMERS C
JOIN ORDERS O ON C.CUSTOMER_ID = O.CUSTOMER_ID
WHERE O.QUANTITY > 1;


-- 8) Retrieve all orders where the total amount exceeds $20.

SELECT * FROM ORDERS 
WHERE TOTAL_AMOUNT>20;

-- 9) List all genres available in the Books table.

SELECT DISTINCT GENRE FROM BOOKS;

-- 10) Find the book with the lowest stock.

SELECT * FROM BOOKS 
WHERE STOCK=(SELECT MIN(STOCK) FROM BOOKS);

-- 11) Calculate the total revenue generated from all orders.

SELECT SUM(TOTAL_AMOUNT) AS TOTAL_REVENUE 
FROM ORDERS;

-- 12) Find the average price of books in the "Fantasy" genre.

SELECT AVG(PRICE) AS AVERAGE_PRICE
FROM BOOKS
WHERE GENRE = 'Fantasy';

-- ADVANCE QUERIES:-

-- 1) Retrieve the total number of books sold for each genre.

SELECT B.GENRE, SUM(O.QUANTITY) AS TOTAL_BOOKS_SOLD
FROM ORDERS O
JOIN BOOKS B ON O.BOOK_ID = B.BOOK_ID
GROUP BY B.GENRE;

-- 2) List customers who have placed at least 2 orders.

SELECT O.CUSTOMER_ID, C.NAME, COUNT(O.ORDER_ID) AS ORDER_COUNT
FROM ORDERS O
JOIN CUSTOMERS C ON O.CUSTOMER_ID=C.CUSTOMER_ID
GROUP BY O.CUSTOMER_ID, C.NAME
HAVING COUNT(ORDER_ID) >=2;

-- 3) Find the most frequently ordered book.

WITH RANKED_ORDERS AS (
    SELECT B.BOOK_ID, 
           B.TITLE, 
           COUNT(O.ORDER_ID) AS ORDER_FREQUENCY,
           DENSE_RANK() OVER (ORDER BY COUNT(O.ORDER_ID) DESC) AS RNK
    FROM BOOKS B
    JOIN ORDERS O ON B.BOOK_ID = O.BOOK_ID
    GROUP BY B.BOOK_ID, B.TITLE
)
SELECT BOOK_ID, TITLE, ORDER_FREQUENCY
FROM RANKED_ORDERS
WHERE RNK = 1;

-- 4) Show the top 3 most expensive books of 'Fantasy' Genre.

SELECT BOOK_ID, TITLE, PRICE
FROM (
    SELECT BOOK_ID, TITLE, PRICE,
           DENSE_RANK() OVER (ORDER BY PRICE DESC) AS PRICE_RANK
    FROM BOOKS
    WHERE GENRE = 'Fantasy'
) RANKED_BOOKS
WHERE PRICE_RANK <= 3;

-- 5) Retrieve the total quantity of books sold by each author.

SELECT B.AUTHOR, SUM(O.QUANTITY) AS TOTAL_BOOKS_SOLD
FROM ORDERS O
JOIN BOOKS B ON O.BOOK_ID=B.BOOK_ID
GROUP BY B.AUTHOR
ORDER BY TOTAL_BOOKS_SOLD DESC;

-- 6) List the cities where customers spent over $30 are located.

SELECT DISTINCT C.CITY
FROM CUSTOMERS C
JOIN ORDERS O ON C.CUSTOMER_ID = O.CUSTOMER_ID
GROUP BY C.CUSTOMER_ID, C.CITY
HAVING SUM(O.TOTAL_AMOUNT) > 30
ORDER BY C.CITY;

-- 7)  Find the customer who spent the most on orders.

WITH CUSTOMER_SPENDING AS (
    SELECT C.CUSTOMER_ID, 
           C.NAME, 
           SUM(O.TOTAL_AMOUNT) AS TOTAL_SPENT,
           DENSE_RANK() OVER (ORDER BY SUM(O.TOTAL_AMOUNT) DESC) AS SPENDING_RANK
    FROM CUSTOMERS C
    JOIN ORDERS O ON C.CUSTOMER_ID = O.CUSTOMER_ID
    GROUP BY C.CUSTOMER_ID, C.NAME
)
SELECT CUSTOMER_ID, NAME, TOTAL_SPENT
FROM CUSTOMER_SPENDING
WHERE SPENDING_RANK = 1;

--8) Calculate the stock remaining after fulfilling all orders.

SELECT B.BOOK_ID, 
       B.TITLE, 
       B.STOCK AS ORIGINAL_STOCK, 
       COALESCE(SUM(O.QUANTITY), 0) AS TOTAL_SOLD, 
       (B.STOCK - COALESCE(SUM(O.QUANTITY), 0)) AS REMAINING_STOCK
FROM BOOKS B 
LEFT JOIN ORDERS O ON B.BOOK_ID = O.BOOK_ID
GROUP BY B.BOOK_ID, B.TITLE, B.STOCK
ORDER BY REMAINING_STOCK DESC;

--9) Find all customers who placed at least one order in the last 6 months of 2023,
-- and calculate their average order value.
-- Sort the results from the highest average order value to the lowest.

SELECT C.CUSTOMER_ID, C.NAME, COUNT(O.ORDER_ID), AVG(O.TOTAL_AMOUNT) AS AVG_ORDER_VALUE
FROM CUSTOMERS C 
JOIN ORDERS O ON C.CUSTOMER_ID = O.CUSTOMER_ID
WHERE O.ORDER_DATE BETWEEN '2023-07-01' AND '2023-12-31'
GROUP BY C.CUSTOMER_ID, C.NAME
HAVING COUNT(O.ORDER_ID) >= 1
ORDER BY AVG_ORDER_VALUE DESC;

--10) Find all genres where the average price of a book is greater than $25,
-- but the total number of books sold in that genre is less than 400.
-- Display the genre name, the total revenue generated by that genre,
-- and label the genre's status as 'Needs Marketing'.

SELECT B.GENRE, 
       AVG(B.PRICE) AS AVG_PRICE, 
       SUM(O.QUANTITY) AS TOTAL_BOOKS_SOLD,
       SUM(O.QUANTITY * B.PRICE) AS TOTAL_REVENUE_GENERATED, 
       'Needs Marketing' AS STATUS
FROM BOOKS B 
JOIN ORDERS O ON B.BOOK_ID = O.BOOK_ID
GROUP BY B.GENRE
HAVING AVG(B.PRICE) > 25 AND SUM(O.QUANTITY) < 400;
  
--11) Find all customers who have placed orders in at least two different months.
-- Display the customer's ID, name, and the total number of unique months they placed an order.

WITH CUSTOMER_MONTHLY_ACTIVITY AS (
    SELECT C.CUSTOMER_ID, 
           C.NAME, 
           COUNT(DISTINCT TO_CHAR(O.ORDER_DATE, 'YYYY-MM')) AS UNIQUE_MONTHS_ORDERED
    FROM CUSTOMERS C
    JOIN ORDERS O ON C.CUSTOMER_ID = O.CUSTOMER_ID
    GROUP BY C.CUSTOMER_ID, C.NAME
)
SELECT CUSTOMER_ID, 
       NAME, 
       UNIQUE_MONTHS_ORDERED
FROM CUSTOMER_MONTHLY_ACTIVITY
WHERE UNIQUE_MONTHS_ORDERED >= 2
ORDER BY UNIQUE_MONTHS_ORDERED DESC, NAME ASC;











