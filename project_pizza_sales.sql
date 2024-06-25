create database if not exists pizzahut;

use pizzahut; -- or you can double tap on desired db from navigator pane.

-- As data set was quite large for my machine, so I have to use below method.
-- first I moved the large csv data files at the path obtained by running below query.
-- SHOW VARIABLES LIKE 'secure_file_priv';
-- then I created table structures and inserted data into tables by running below queries.   


create table orders (
order_id int not null,
order_date date not null,
order_time time not null,
primary key (order_id)
);

create table order_details (
order_details_id int not null,
order_id int not null,
pizza_id text not null,
quantity int not null,
primary key (order_details_id)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders_cleaned.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
IGNORE 1 ROWS
(order_id, order_date, order_time);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_details.csv'
INTO TABLE order_details
FIELDS TERMINATED BY ','
IGNORE 1 ROWS
(order_details_id, order_id,pizza_id,quantity);

 -- note. To beautify the query just select the query, and press ctrl + 'b'





-- Retrieve the total number of orders placed.
select count(order_id) as total_orders from orders;





-- Calculate the total revenue generated from pizza sales.
SELECT 
    ROUND(SUM(order_details.quantity * pizzas.price),
            4) AS total_revenue
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id;




-- Identify the highest-priced pizza.
SELECT 
    pizza_types.name, (pizzas.price)
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY pizzas.price DESC
LIMIT 1;




-- Identify the most common pizza size ordered.
SELECT 
    pizzas.size,
    COUNT(order_details.order_details_id) AS no_of_pizzas_sold
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizzas.size
ORDER BY no_of_pizzas_sold DESC
LIMIT 1;




-- List the top 5 most ordered pizza types along with their quantities.
SELECT 
    pizza_types.name, SUM(order_details.quantity) AS quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY quantity DESC
LIMIT 5; 
    
    
    
    
-- Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT 
    pizza_types.category,
    SUM(order_details.quantity) AS total_quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY total_quantity DESC;

-- note- the linking table is in between





-- Determine the distribution of orders by hour of the day.
SELECT 
    HOUR(order_time) AS hour, COUNT(order_id) AS order_id
FROM
    orders
GROUP BY hour;





-- Join relevant tables to find the category-wise distribution of pizzas.
SELECT 
    category, COUNT(name) AS no_of_pizzas
FROM
    pizza_types
GROUP BY category;




-- Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT 
    ROUND(AVG(quantity), 0) AS avg_pizzas_per_day
FROM
    (SELECT 
        orders.order_date, SUM(order_details.quantity) AS quantity
    FROM
        orders
    JOIN order_details ON orders.order_id = order_details.order_id
    GROUP BY orders.order_date) AS temp;





-- Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    pizza_types.name AS name_of_pizza,
    ROUND(SUM(order_details.quantity * pizzas.price),
            2) AS revenue
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY name_of_pizza
ORDER BY revenue DESC
LIMIT 3;





-- Calculate the percentage contribution of each pizza type to total revenue.
SELECT 
    pizza_types.category,
    ROUND(SUM(order_details.quantity * pizzas.price),
            3) AS revenue,
    CONCAT(ROUND((SUM(order_details.quantity * pizzas.price) / (SELECT 
                            ROUND(SUM(order_details.quantity * pizzas.price),
                                        4)
                        FROM
                            order_details
                                JOIN
                            pizzas ON order_details.pizza_id = pizzas.pizza_id)) * 100,
                    3),
            ' %') AS revenue_percentage
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY revenue DESC;





-- Analyze the cumulative revenue generated over time.
select order_date, round(sum(revenue) over(order by order_date),3) as cumulative_sum
from
(select orders.order_date , sum(order_details.quantity*pizzas.price) as revenue
from order_details
join pizzas
on order_details.pizza_id=pizzas.pizza_id 
join orders
on order_details.order_id=orders.order_id
group by orders.order_date) as temp;





-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
select category,name,revenue, rn as ranking
from
(select category,name,revenue,
rank() over(partition by category order by revenue desc) as rn
from
(select 
	pizza_types.category ,
    pizza_types.name ,
    sum(order_details.quantity * pizzas.price) as revenue
from pizza_types 
join pizzas 
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.pizza_id=pizzas.pizza_id
group by pizza_types.category, pizza_types.name) as temp) as temp1
where rn<=3;