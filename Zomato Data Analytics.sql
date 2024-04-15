DROP TABLE if exists goldusers_signup;
CREATE TABLE goldusers_signup(
	guserid integer Primary Key,
    gold_signup_date date
);

INSERT INTO  goldusers_signup(guserid,gold_signup_date)
VALUES
	(1,'2017-09-22'),
	(2,'2017-04-21');
    
DROP TABLE if exists users;
CREATE TABLE users(
	useruid integer,
    signup_date date
    );
    
INSERT INTO users(useruid,signup_date)
VALUES
	(1,'2014-09-02'),
    (2,'2015-01-15'),
    (3,'2014-04-11');
    
DROP TABLE if exists sales;
CREATE TABLE sales(
	userid integer,
    created_date date,
    product_id integer);
    
INSERT INTO sales(userid,created_date,product_id)
VALUES
	(1,'2017-04-19',2),
	(3,'2019-12-18',1),
	(2,'2020-07-20',3),
	(1,'2019-10-23',2),
	(1,'2018-03-19',3),
	(3,'2016-12-20',2),
	(1,'2016-11-09',1),
	(1,'2016-05-20',3),
	(2,'2017-09-24',1),
	(1,'2017-03-11',2),
	(1,'2016-03-11',1),
	(3,'2016-11-10',1),
	(3,'2017-12-07',2),
	(3,'2016-12-15',2),
	(2,'2017-11-08',2),
	(2,'2018-09-10',3);
    
DROP TABLE if exists product;
CREATE TABLE product (
	productuid integer,
    product_name text,
    price integer
    );
    
INSERT INTO product(productuid,product_name,price)
VALUES
	(1,'p1',980),
	(2,'p2',870),
	(3,'p3',330);
    
SELECT * FROM sales;
SELECT * FROM product;
SELECT * FROM goldusers_signup;
SELECT * FROM users;		

# Q1) What is the total amount each customer spent on Zomato?
SELECT useruid, product_id FROM users 
INNER JOIN sales 
ON users.useruid=sales.userid;

SELECT userid,product_id,price FROM sales 
INNER JOIN product
ON sales.product_id=product.productuid;	

#Ans1: -
SELECT useruid,SUM(price) AS tot_amt_spent FROM users
INNER JOIN product
ON users.useruid=product.productuid
GROUP BY(useruid);

# Q2) How many days has each customer visited Zomato?
SELECT useruid,COUNT(DISTINCT created_date) FROM users 
INNER JOIN sales
ON users.useruid=sales.userid
GROUP BY(useruid);

# Q3) What was the first Product purchased by each customer?
SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date ASC) rnk from sales; 
# This was data for all orders 
SELECT * FROM
	(SELECT *,RANK() OVER(PARTITION BY userid ORDER BY created_date ASC) rnk FROM sales) AS first_prod
WHERE rnk=1;

# Q4) What is the most purchased items on the menu and how many time was it purchased by all customers?

 SELECT product_id, COUNT(product_id) FROM sales
 GROUP BY(product_id)
 ORDER BY(COUNT(product_id)) DESC LIMIT 1;

# Q5) Which item was most popular for each customer ?
SELECT * FROM 
(SELECT *,RANK() OVER(PARTITION BY userid ORDER BY CNT DESC) rnk FROM 
(SELECT userid, product_id, COUNT(product_id) AS CNT FROM sales 
GROUP BY userid,product_id)  
AS most_popular_item
WHERE rnk=1);

# Q6) Which item was purchased first  by the customer after they became a member ?
	
    SELECT * FROM
    (SELECT c.*, RANK() OVER(PARTITION BY userid ORDER BY created_date ASC) rnk FROM 
    (SELECT userid, created_date, product_id, gold_signup_date FROM sales 
    INNER JOIN goldusers_signup 
    ON sales.userid=goldusers_signup.guserid AND created_date >= gold_signup_date) c)
    d WHERE rnk=1;
# Q7) Which item was first purchased just before customer became a member ?
     
     SELECT * FROM 
     (SELECT c.*,RANK() OVER(PARTITION BY userid ORDER BY created_date DESC) rnk FROM 
     (SELECT userid, created_date, product_id, gold_signup_date FROM sales
     INNER JOIN goldusers_signup
     ON sales.userid=goldusers_signup.guserid AND created_date<=gold_signup_date) c) 
     d WHERE rnk=1;
     
# Q8) What is the total orders and amount spent for each member before they became a member ?
      
SELECT 
    users.useruid,
    COUNT(sales.product_id) AS total_orders,
    SUM(product.price) AS total_amount_spent
FROM 
    sales 
JOIN 
    users ON sales.userid = users.useruid
JOIN 
    product ON sales.product_id = product.productuid
JOIN 
    goldusers_signup ON users.useruid = goldusers_signup.guserid
WHERE 
    sales.created_date <= goldusers_signup.gold_signup_date
GROUP BY 
    (users.useruid);
    
# Q9) If buying each product generate points, eg: 5Rs=2 
# Zomato Pts and each product has different pts, eg: p1=> 
# 5Rs=1 pt, p2=> 10Rs=5 pt, p3=> 5Rs=1 pt then calculate pts 
# for each customer and for which product most pts have been generated till now?

WITH product_points AS (
  SELECT productuid,
         CASE
           WHEN price <= 5 THEN 1
           WHEN price > 5 AND price <= 10 THEN 5
           ELSE FLOOR(price / 10) * 5
         END AS points_per_product
  FROM product
),
customer_points AS (
  SELECT s.userid, s.product_id, p.points_per_product, SUM(p.points_per_product) AS total_points
  FROM sales s
  JOIN product_points p ON s.product_id = p.productuid
  GROUP BY s.userid, s.product_id, p.points_per_product
)
SELECT userid, SUM(total_points) AS total_customer_points
FROM customer_points
GROUP BY userid
ORDER BY total_customer_points DESC;

SELECT product_id, SUM(total_points) AS total_product_points
FROM customer_points
GROUP BY product_id
ORDER BY total_product_points DESC
LIMIT 1;

# Q10) Rank all the transactions of the customers

SELECT *,RANK() OVER(PARTITION BY userid ORDER BY created_date) rnk FROM SALES;

# Q11) Rank all the Transactins for each member whenever they are a zomato gold member for every 
# non gold member transaction mark as NA 

WITH gold_users AS (
  SELECT u.useruid, g.gold_signup_date
  FROM users u
  JOIN goldusers_signup g ON u.useruid = g.guserid
),
user_transactions AS (
  SELECT u.useruid, s.product_id, s.created_date,
         CASE WHEN g.gold_signup_date IS NOT NULL AND s.created_date >= g.gold_signup_date
              THEN RANK() OVER (PARTITION BY u.useruid ORDER BY s.created_date)
              ELSE 'NA'
         END AS transaction_rank
  FROM users u
  LEFT JOIN gold_users g ON u.useruid = g.useruid
  JOIN sales s ON u.useruid = s.userid
)
SELECT useruid, product_id, created_date, transaction_rank
FROM user_transactions;