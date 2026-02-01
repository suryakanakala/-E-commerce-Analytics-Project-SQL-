/* E-commerce Analytics Project: 
                                  Database Design & Business Insights using SQL  */

CREATE DATABASE CASE_ECOMMERCE;
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50),
    city VARCHAR(50),
    signup_date DATE
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    order_status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_category VARCHAR(50),
    product_name VARCHAR(50),
    quantity INT,
    price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

INSERT INTO customers (customer_id, customer_name, city, signup_date) VALUES
(1, 'Amit', 'Mumbai', '2023-01-10'),
(2, 'Priya', 'Delhi', '2023-02-15'),
(3, 'Rahul', 'Bangalore', '2023-03-05'),
(4, 'Sneha', 'Mumbai', '2023-03-20'),
(5, 'Ankit', 'Pune', '2023-04-01'),
(6, 'Neha', 'Delhi', '2023-04-18');

INSERT INTO orders (order_id, customer_id, order_date, order_status) VALUES
(101, 1, '2023-04-10', 'Completed'),
(102, 2, '2023-04-12', 'Completed'),
(103, 3, '2023-04-15', 'Cancelled'),
(104, 1, '2023-04-18', 'Completed'),
(105, 4, '2023-04-20', 'Returned'),
(106, 5, '2023-04-22', 'Completed'),
(107, 6, '2023-04-25', 'Completed'),
(108, 2, '2023-04-28', 'Completed');

INSERT INTO order_items 
(order_item_id, order_id, product_category, product_name, quantity, price) 
VALUES
(1, 101, 'Electronics', 'Headphones', 1, 2000),
(2, 101, 'Accessories', 'USB Cable', 2, 300),

(3, 102, 'Electronics', 'Keyboard', 1, 2500),

(4, 103, 'Electronics', 'Mouse', 1, 800),

(5, 104, 'Electronics', 'Monitor', 1, 12000),
(6, 104, 'Accessories', 'HDMI Cable', 1, 500),

(7, 105, 'Clothing', 'Jacket', 1, 3000),

(8, 106, 'Clothing', 'T-Shirt', 3, 700),

(9, 107, 'Electronics', 'Power Bank', 1, 1500),

(10, 108, 'Accessories', 'Charger', 1, 1000);

-- LETS BEGIN

-- 🔹 LEVEL 1 – FOUNDATION QUESTIONS
-- Q1. Customer Count
-- 👉 Find the total number of unique customers.
SELECT 
    COUNT(distinct customer_id) AS total_no_of_unique_customers
FROM
    customers;

-- Q2. Orders Overview
-- 👉 Find the total number of orders placed.
SELECT 
    COUNT( distinct order_id) AS total_no_of_orders
FROM
    orders;

-- Q3. Completed Orders
-- 👉 Find how many orders were successfully completed.
SELECT 
    count(distinct order_id) as count_of_sucessful
FROM
    orders
WHERE
    order_status = 'completed';

-- Q4. Total Revenue
-- 👉 Calculate the total revenue generated from completed orders only.
-- 💡 Revenue = quantity × price
SELECT 
   sum(quantity * price) AS total_revenue
FROM
    order_items oi
        JOIN
    orders o ON o.order_id = oi.order_id
WHERE
    order_status = 'completed';

-- Q5. Category-wise Revenue
-- 👉 Find the total revenue for each product category (include only completed orders).
SELECT oi.product_category,
    sum(quantity * price) AS total_revenue
FROM order_items oi JOIN
    orders o ON o.order_id = oi.order_id
    where o.order_status = 'completed'
     group by oi.product_category;

-- Q6. Top Cities by Customers
-- 👉 Find the top 3 cities with the highest number of customers.
select city,count(*) as no_of_customers
 from customers
 group by city
 order by no_of_customers desc
 limit 3;

-- Q7. Average Order Value (AOV)
-- 👉 Calculate the average order value(only for completed orders).

select round(avg(order_total),2) as avg_order_value from (select o.order_id,
sum(oi.quantity * oi.price) as order_total
from order_items oi 
join orders o
 on o.order_id = oi.order_id
 where o.order_status = 'completed'
 group by o.order_id)t;


-- Q8. Orders per Customer
-- 👉 Find how many orders each customer has placed.
select customer_id,count(distinct order_id) as orders_count
from orders
group by customer_id;

-- Level 2 – Business Metrics & Conditional Logic
-- Q1. Customer Activity Split
-- 👉 Find the number of active customers and inactive customers.
-- Definitions:
-- Active → Customers who placed at least 1 completed order
-- Inactive → Customers who placed no completed orders
with customer_activity as
(select
max(case when o.order_status = 'completed' then 1 else 0 end ) as 
has_completed
from customers c 
left join orders o 
on c.customer_id = o.customer_id
group by c.customer_id)
select 
case 
when has_completed = 1 then 'active'
else 'inactive'
end as customer_status,
count(*) as customer_count
from customer_activity
group by customer_status;

-- Q2. Revenue Contribution by Category (%)
-- 👉 Find each product category’s percentage contribution to total revenue 
-- (consider only completed orders).


select * from orders;

select oi.product_category,sum(oi.price * oi.quantity)
as total_revenue,
(SUM(oi.price * oi.quantity) / SUM(SUM(oi.price * oi.quantity)) OVER ()) * 100 AS revenue_percentage
from order_items oi
join orders o 
on oi.order_id = o.order_id
where order_status = 'completed'
group by product_category;

-- Q3. High-Value Customers
-- 👉 Identify customers whose total spending is above the overall average customer spending
-- (consider only completed orders).

with spending as (
select c.customer_id,c.customer_name,o.order_status,
sum(oi.price) as total_spending_percus,
round(avg(oi.price),2) as avg_customers_spending
from order_items oi
join orders o
on oi.order_id = o.order_id
join customers c
on c.customer_id = o.customer_id
where o.order_status = 'completed'
group by c.customer_id,c.customer_name,o.order_status
)
select customer_id,customer_name,total_spending_percus,avg_customers_spending
from spending 
where total_spending_percus > avg_customers_spending;
-- Q4. Repeat Customers
-- 👉 Find customers who have placed more than 1 completed order.

select * from (select c.customer_id as returned_customers ,c.customer_name,
count(distinct o.order_id) no_of_orders
from customers c
join orders o
 on o.customer_id = c.customer_id
 where o.order_status = 'completed'
 group by c.customer_id,c.customer_name
) t
where no_of_orders >1;

-- Q5. Order Status Distribution
-- 👉 Show the count and percentage of each order status
-- (e.g., completed, cancelled, returned).
with fck as (
select count(distinct order_id) as total_orders,
count(distinct case when order_status = 'completed' then order_id end ) as completed_count,
count(distinct case when order_status = 'cancelled' then order_id end ) as cancelled_count,
count(distinct case when order_status = 'returned' then order_id end ) as returned_count
from orders
)
select *, (( completed_count - total_orders  * 100.0 / total_orders)) as complete_pct,
 (( cancelled_count -  total_orders  * 100.0 / total_orders)) as cancelled_pct,
  (( returned_count -  total_orders  * 100.0 / total_orders)) as returned_pct
  from fck;


-- Q6. First Purchase Date per Customer
-- 👉 Find each customer’s first order date.
select customer_id,
min(order_date) as first_order_date
from orders 
where order_status = 'completed'
group by customer_id;

-- Q7. Category Performance Flag
-- 👉 For each product category, label it as:
-- “High Revenue” → revenue > average category revenue
-- “Low Revenue” → otherwise
-- (consider only completed orders).
select oi.product_category,
(case when sum(oi.price) > round(avg(oi.price),2) then 'high_revenue'
else 'low_revenue'
end) as Performance_flag
from order_items oi
join orders o
on oi.order_id = o.order_id
where o.order_status = 'completed'
group by oi.product_category;

-- Q8. Customer Lifetime Value (CLV – Simplified)
-- 👉 Calculate the total revenue generated by each customer
-- (consider only completed orders).
select o.customer_id,
sum(price * quantity) as customer_life_time_value
from order_items oi
join orders o
on o.order_id = oi.order_id
where order_status = 'completed'
group by customer_id

