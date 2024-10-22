CREATE TABLE sales (
customer_id VARCHAR(1),
order_date  DATE,
product_id INTEGER
);
INSERT INTO sales
(customer_id, order_date, product_id)
VALUES
('A', '2021-01-01', '1'),
('A', '2021-01-01', '2'),
('A', '2021-01-07', '2'),
('A', '2021-01-10', '3'),
('A', '2021-01-11', '3'),
('A', '2021-01-11', '3'),
('B', '2021-01-01', '2'),
('B', '2021-01-02', '2'),
('B', '2021-01-04', '1'),
('B', '2021-01-11', '1'),
('B', '2021-01-16', '3'),
('B', '2021-02-01', '3'),
('C', '2021-01-01', '3'),
('C', '2021-01-01', '3'),
('C', '2021-01-07', '3');

CREATE TABLE menu ( 
product_id INTEGER, 
product_name VARCHAR(5), 
price INTEGER 
); 
INSERT INTO menu 
(product_id, product_name, price) 
VALUES 
('1', 'sushi', '10'), 
('2', 'curry', '15'), 
('3', 'ramen', '12'); 
CREATE TABLE members ( 
customer_id VARCHAR(1), 
join_date DATE 
); 
INSERT INTO members 
(customer_id, join_date) 
VALUES 
('A', '2021-01-07'), 
('B', '2021-01-09');

select * from sales;
select * from menu;
select * from members;

-- ********** Case Study Questions ******** --
-- Q1Customer Expenditure: What is the total amount spent by each customer at Gourmet Gastronomy Hub?
select s.customer_id,sum(price) as total_expenditure
from sales s
join menu m on s.product_id = m.product_id
group by s.customer_id; 

-- Q2. Visitation Frequency: How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) as customer_visited
from sales
group by customer_id
order by customer_id;

-- Q3.First Menu Interaction:What was the initial menu item purchased by each customer?
-- Method 1
with first_purchase as (
select customer_id,min(order_date) as first_order_date
from sales
group by customer_id
)
select fp.customer_id,m.product_name,m.price
from first_purchase fp
join sales s on fp.first_order_date = s.order_date and fp.customer_id = s.customer_id
join menu m on s.product_id = m.product_id;

-- Method 2
SELECT customer_id , product_name, order_date
FROM sales
LEFT JOIN menu 
  ON sales.product_id = menu.product_id
WHERE order_date = '2021-01-01' 
GROUP BY customer_id;

-- Q4 Top Purchased Item: Which menu item is the most frequently purchased, and 
#how many times has it been ordered by all customers? 

select m.product_name,count(s.product_id) as order_count
from sales s
join menu m on s.product_id = m.product_id
group by product_name
order by order_count desc
limit 1;


-- Q5 Individual Favorites: Which menu item is considered the favorite for each customer?
select s.customer_id,m.product_name,count(s.product_id) as order_count
from sales s
join menu m on s.product_id = m.product_id
group by s.customer_id,m.product_name
having order_count = (select max(order_count) 
					from (select count(product_id) as order_count from sales where customer_id = s.customer_id
                    group by product_id) as counts);
				
-- EXPLANATION

-- 1. JOIN : combines the sales and menu table to get products
-- 2: Group by : group results by customer and product.
-- 3. count: count how many times each product was ordered by each customer.
-- 4. Having : filters to return only the products with the  maximum order count for each customer.
-- Method 2

with customerfavourites as (
		select s.customer_id,s.product_id, count(*) as order_count
        from sales s
        group by s.customer_id,s.product_id
        ),
        maxfavourites as (
        select customer_id,max(order_count) as max_count from customerfavourites
		group by customer_id)
        select cf.customer_id,m.product_name,cf.order_count
        from customerfavourites cf
        join maxfavourites mf on cf.customer_id = mf.customer_id and cf.order_count = mf.max_count
		join menu m on cf.product_id = m.product_id
        order by cf.customer_id;
						
-- EXPLANATION 

-- 1. CustomerFavourites : the CTE counts the number of times each product was ordered by each customer.
-- 2. MaxFavourites: this CTE finds the maximum orders for each customer.
-- 3. Final select : joins the two CTEs with the menu table to retrieve the product names for each customer's favourite item.


-- method 3
SELECT customer_id, product_name, COUNT(product_name) times_purchased
FROM sales
LEFT JOIN menu 
  ON sales.product_id = menu.product_id
GROUP BY customer_id, product_name
ORDER BY times_purchased DESC;


-- Q6. What item did a customer buy first after joining the loyalty program?
select m.customer_id,s.order_date,s.product_id,mn.Product_name
from members m
join sales s on m.customer_id = s.customer_id
join menu mn on s.product_id = mn.product_id
where s.order_date = (select min(order_date) from sales s
					  where s.customer_id = m.customer_id and s.order_date > m.join_date);

-- EXPLANATION
-- 1 Main Query : 
#select : retrieves customer_id,product_id and order_date from the sales table.
#join : combines sales table with the members table based on customer_id to relate purchases to the join_date.

-- 2 where clause:
#subquery : This checks for the minimum order_date for each customer that is greater than their join_date
#the subquery is correlated to the outer query, meaning it evaluates the minimum order date for the specific customer in context.
  

select customer_id,product_id,order_date
from sales s
where order_date = (select min(order_date) 
					from sales 
                    where customer_id = s.customer_id and 
                    order_date > (select join_date from members where customer_id= s.customer_id)
                                  );


select m.customer_id,mn.product_name,s.order_date,count(s.order_date) as after_join
from sales s  
join members m on m.customer_id = s.customer_id
join menu mn on s.product_id = mn.product_id
where s.order_date > (select join_date from members where customer_id= s.customer_id)
group by m.customer_id,s.order_date,mn.product_name
having after_join = 1
order by m.customer_id,s.order_date
limit 2;

                                  
select m.customer_id,s.product_id,s.order_date
from members m 
join sales s on m.customer_id = s.customer_id
where s.order_date > join_date
order by m.customer_id,s.order_date
limit 1;


       
-- 7. Pre-Membership Purchase : What item was purchased just before a customer became a member?
select s.customer_id,s.product_id,s.order_date
from sales s 
join members m on s.customer_id = m.customer_id
where s.order_date < m.join_date and s.order_date = (select max(order_date) 
													from sales
                                                    where customer_id = s.customer_id 
                                                    and
                                                    order_date < m.join_date)
                                                    order by order_date desc;
                                                    
select s.customer_id,s.product_id,s.order_date
from sales s
where s.order_date < (select m.join_date 
					  from members m
                      where m.customer_id = s.customer_id) 
                      and s.order_date = (select max(s1.order_date)
										  from sales s1
                                          where s1.customer_id = s.customer_id
                                          and
                                          s1.order_date < (select m.join_date
														   from members m
                                                           where m.customer_id = s.customer_id));
                                                           

select s.customer_id,s.order_date,s.product_id
from sales s
join members m on s.customer_id = m.customer_id
where s.order_date < m.join_date
order by s.order_date desc;


WITH PurchasesBeforeJoin AS (
SELECT s.customer_id, s.product_id, s.order_date,
ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
FROM sales s
JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
),
LastPurchaseBeforeJoin AS (SELECT PBJ.customer_id,PBJ.product_id,PBJ.order_date
FROM PurchasesBeforeJoin PBJ
WHERE pbj.rn = 1
)
SELECT LPBJ.customer_id, m.product_name,LPBJ.order_date
FROM LastPurchaseBeforeJoin LPBJ
JOIN menu m ON lpbj.product_id = m.product_id;


-- Q8. Pre-Membership Spending: What are the total items and expenditure for each member before they became a member?
Select S.customer_id,count(S.product_id ) as Items ,Sum(M.price) as total_sales
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date < Mem.join_date
Group by S.customer_id;

WITH PurchasesBeforeJoin AS (
SELECT s.customer_id,s.product_id, s.order_date, m.price
FROM sales s
JOIN members mem ON s.customer_id = mem.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date
),
  AggregatedPurchases AS (
  SELECT p.customer_id,COUNT(p.product_id) AS total_items,SUM(p.price) AS total_expenditure
  FROM PurchasesBeforeJoin p
  GROUP BY p.customer_id
  )
     SELECT a.customer_id, a.total_items, a.total_expenditure
     FROM AggregatedPurchases a;



-- Q9. Points Calculation:If each $1 spent equates to 10 points, with a 2x points multiplier for gourmet steaks, how many points would each customer have?
-- Method 1.

With Points as (
Select *, Case When product_id = 1 THEN price*20
               Else price*10
			   End as Points
From Menu
)
Select S.customer_id, Sum(P.points) as Points
From Sales S
Join Points p
On p.product_id = S.product_id
Group by S.customer_id;

-- Method 2

WITH PurchasesBeforeJoin AS (
SELECT s.customer_id,s.product_id,m.price
FROM sales s
JOIN members mem ON s.customer_id = mem.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date
),
PointsCalculation AS (SELECT p.customer_id,
					  SUM ( CASE WHEN p.product_id = 1 THEN p.price * 20 -- 10 points per $1 with 2x multiplier 
                      ELSE p.price * 10 -- 10 points per $1 for other items
                      END) AS total_points
					  FROM PurchasesBeforeJoin p
					  GROUP BY p.customer_id
					  )
						SELECT customer_id , total_points
						FROM PointsCalculation;
                        
                        
-- Q10. Points at End of January:In the first week after joining the program, with a 2x points multiplier for all items, how many points do customers A and B have at the end of January?

-- Method 1
WITH dates AS 
(
   SELECT *, 
   DATEADD(DAY, 6, join_date) AS valid_date, 
   EOMONTH('2021-01-31') AS last_date
   FROM members 
)
Select S.Customer_id, 
       SUM(
	         Case 
		       When m.product_ID = 1 THEN m.price*20
			     When S.order_date between D.join_date and D.valid_date Then m.price*20
			     Else m.price*10
			     END 
		       ) as Points
From Dates D
join Sales S
On D.customer_id = S.customer_id
Join Menu M
On M.product_id = S.product_id
Where S.order_date < d.last_date
Group by S.customer_id;


-- Method 2.
Select s.customer_id,Sum(CASE When (DATEDIFF(DAY, me.join_date, s.order_date) between 0 and 7) or (m.product_ID = 1) Then m.price * 20
			  Else m.price * 10
              END) As Points
From members as me
    Inner Join sales as s on s.customer_id = me.customer_id
    Inner Join menu as m on m.product_id = s.product_id
where s.order_date >= me.join_date and s.order_date <= CAST('2021-01-31' AS DATE)
Group by s.customer_id;

-- method 3
WITH PurchasesAfterJoin AS (
SELECT
s.customer_id,
s.product_id,
m.price,
s.order_date
FROM sales s
JOIN members mem ON s.customer_id = mem.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date > mem.join_date
AND s.order_date <= CAST('2021-01-31' AS DATE)
),
PointsCalculation AS (
SELECT
p.customer_id,
SUM(p.price * 20) AS total_points -- 2x multiplier (10 points per $1 * 2)
FROM PurchasesAfterJoin p
GROUP BY p.customer_id
)
SELECT customer_id, total_points
FROM PointsCalculation
WHERE customer_id IN ('A', 'B');

-- method 4

WITH cte_OfferValidity AS 
    (SELECT s.customer_id, m.join_date, s.order_date,
        date_add(m.join_date, interval(6) DAY) firstweek_ends, menu.product_name, menu.price
    FROM sales s
    LEFT JOIN members m
      ON s.customer_id = m.customer_id
    LEFT JOIN menu
        ON s.product_id = menu.product_id)
SELECT customer_id,
    SUM(CASE
            WHEN order_date BETWEEN join_date AND firstweek_ends THEN 20 * price 
            WHEN (order_date NOT BETWEEN join_date AND firstweek_ends) AND product_name = 'sushi' THEN 20 * price
            ELSE 10 * price
        END) points
FROM cte_OfferValidity
WHERE order_date < '2021-02-01' -- filter jan points only
GROUP BY customer_id;