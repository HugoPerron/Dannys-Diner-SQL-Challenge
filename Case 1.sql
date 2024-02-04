/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT sales.customer_id, SUM(menu.price) AS total_spend
FROM sales
JOIN menu 
ON sales.product_id = menu.product_id 
GROUP BY sales.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT sales.customer_id, COUNT(DISTINCT sales.order_date) AS days_visited
FROM sales
GROUP BY sales.customer_id;
-- 3. What was the first item from the menu purchased by each customer?
WITH CTE AS (
	SELECT customer_id, order_date, product_name,
			RANK() OVER(PARTITION BY customer_id
						ORDER BY order_date) AS rank
	FROM sales 
	JOIN menu 
	ON sales.product_id = menu.product_id 
	)

SELECT customer_id, product_name
FROM CTE
WHERE rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name, COUNT(product_name) AS amount_purchased
FROM sales
JOIN menu 
ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY 2 DESC 
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH CTE AS (	
SELECT customer_id, product_name, COUNT(product_name) AS amount_purchased,
		RANK() OVER(PARTITION BY customer_id
					ORDER BY COUNT(product_name) DESC) AS rank
FROM sales
JOIN menu 
ON sales.product_id = menu.product_id
GROUP BY customer_id, product_name
ORDER BY customer_id
)

SELECT customer_id, product_name
FROM CTE
WHERE rank = 1
ORDER BY customer_id;

-- 6. Which item was purchased first by the customer after they became a member?

WITH CTE AS (
	SELECT sales.customer_id, order_date, product_name, join_date,
			RANK() OVER(PARTITION BY sales.customer_id
						ORDER BY order_date) AS rank
	FROM sales 
	JOIN menu ON sales.product_id = menu.product_id 
	JOIN members ON members.customer_id = sales.customer_id 
	WHERE order_date >= join_date
	)

SELECT customer_id, product_name
FROM CTE
WHERE CTE.rank = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH CTE AS (
	SELECT sales.customer_id, order_date, product_name, join_date,
			RANK() OVER(PARTITION BY sales.customer_id
						ORDER BY order_date DESC) AS rank
	FROM sales 
	JOIN menu ON sales.product_id = menu.product_id 
	JOIN members ON members.customer_id = sales.customer_id 
	WHERE order_date < join_date
)
SELECT customer_id, product_name
FROM CTE
WHERE rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

	SELECT sales.customer_id, COUNT(product_name) AS total_items_before_member, SUM(menu.price) AS total_spend_before_member
	FROM sales 
	JOIN menu ON sales.product_id = menu.product_id 
	JOIN members ON members.customer_id = sales.customer_id 
	WHERE order_date < join_date
	GROUP BY sales.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id, 
		SUM(CASE WHEN product_name = 'sushi' THEN 2*10*price
			 ELSE 10*price END) AS points
FROM sales 
JOIN menu ON sales.product_id = menu.product_id 
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT sales.customer_id, 
		SUM(CASE 
            WHEN product_name = 'sushi' THEN 2*10*price
		    WHEN order_date BETWEEN join_date AND DATE(join_date, '+6 days') THEN 2*10*price
		    ELSE 10*price 
        END) AS points
FROM sales 
JOIN menu ON sales.product_id = menu.product_id 
JOIN members ON members.customer_id = sales.customer_id 
WHERE order_date <= '2021-01-31'
GROUP BY sales.customer_id;

-- BONUS QUESTIONS -- 
WITH CTE AS (
	SELECT sales.customer_id, order_date, menu.product_name, price,
			CASE WHEN order_date >= join_date THEN 'Y'
				 ELSE 'N' END AS member
	FROM sales 
	INNER JOIN menu ON sales.product_id = menu.product_id 
	LEFT JOIN members ON members.customer_id = sales.customer_id 
	ORDER BY sales.customer_id, member,  price DESC
)

SELECT customer_id, order_date, product_name, price, member,
	   CASE WHEN member = 'Y' THEN RANK() OVER(PARTITION BY customer_id, member
		    												   ORDER BY order_date)
				 ELSE NULL END AS ranking
FROM CTE
ORDER BY customer_id, order_date,  price DESC

