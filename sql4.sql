-- 1. Create a procedure that adds a late fee to any customer who returned their rental after 7 days.
--	  Use the payment and rental tables.
ALTER TABLE rental
DROP COLUMN rental_duration;

DROP PROCEDURE lateFee;

ALTER TABLE rental
ADD COLUMN rental_duration INTERVAL;

SELECT *
FROM payment
WHERE rental_id = 14098;

SELECT *
FROM rental
ORDER BY rental_duration DESC;

ALTER TABLE payment
ALTER COLUMN amount TYPE DECIMAL;

DROP FUNCTION lateFeeCalc;

CREATE OR REPLACE FUNCTION lateFeeCalc(_rental_duration INTERVAL, feeAmount DECIMAL)
RETURNS DECIMAL
AS $$
	BEGIN
		RETURN feeAmount * (EXTRACT(EPOCH FROM _rental_duration) / EXTRACT(EPOCH FROM INTERVAL '7 days'));
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE lateFee(feeAmount DECIMAL, rightNow TIMESTAMP WITHOUT TIME ZONE)
LANGUAGE plpgsql
AS $$
BEGIN
	-- populate rental_duration column with an interval
	UPDATE rental
	SET rental_duration = return_date - rental_date;

	UPDATE rental
	SET rental_duration = rightNow - rental_date
	WHERE return_date is NULL;

	UPDATE payment
	SET amount = amount + lateFeeCalc(rental.rental_duration, feeAmount)
	FROM rental
	WHERE payment.rental_id = rental.rental_id AND rental_duration > '7 days';
	
	COMMIT;
END;
$$

CALL lateFee(5, LOCALTIMESTAMP);

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