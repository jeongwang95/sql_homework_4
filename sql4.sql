-- 1. Create a procedure that adds a late fee to any customer who returned their rental after 7 days.
--	  Use the payment and rental tables.
ALTER TABLE rental
DROP COLUMN rental_duration;

DROP PROCEDURE lateFee;

ALTER TABLE rental
ADD COLUMN rental_duration INTERVAL;

SELECT *
FROM payment
WHERE rental_id = 1182;

SELECT *
FROM rental
WHERE rental_id = 1182;

CREATE OR REPLACE PROCEDURE lateFee(feeAmount DECIMAL)
LANGUAGE plpgsql
AS $$
BEGIN
	-- populate rental_duration column with an interval
	UPDATE rental
	SET rental_duration = return_date - rental_date;

	UPDATE payment
	SET amount = amount + feeAmount
	WHERE rental_id IN (
		SELECT rental_id
		FROM rental
		WHERE rental_duration > '7 days'
	);
	
	COMMIT;
END;
$$

CALL lateFee(.01);

-- 2. Add a new column in the customer table for Platinum Member. This can be a boolean.
-- 	  Platinum Members are any customers who have spent over $200. 
--    Create procedure that updates the Platinum Member column to True for any customer who has spent over $200 and False for any customer who has spent less than $200.
-- 	  Use the payment and customer table.

ALTER TABLE customer
ADD COLUMN plat_member BOOLEAN;

SELECT *
FROM customer;

SELECT customer_id
FROM payment;

CREATE OR REPLACE PROCEDURE updatePlat()
LANGUAGE plpgsql
AS $$
BEGIN
	UPDATE customer
	SET plat_member = true
	WHERE customer_id IN (
		SELECT customer_id
		FROM payment
		GROUP BY customer_id
		HAVING SUM(amount) > 200
	);
	
	UPDATE customer
	SET plat_member = false
	WHERE customer_id IN (
		SELECT customer_id
		FROM payment
		GROUP BY customer_id
		HAVING SUM(amount) <= 200
	);
	
	COMMIT;
END;
$$

CALL updatePlat();