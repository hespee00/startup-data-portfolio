select version();

-- SCHEMA + DATA (classic SaaS startup)
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    signup_date DATE NOT NULL,
    country VARCHAR(10),
    acquisition_channel VARCHAR(20)
);

CREATE TABLE subscriptions (
    sub_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    start_date DATE,
    end_date DATE,
    plan VARCHAR(20),
    mrr_cents INT
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    sub_id INT REFERENCES subscriptions(sub_id),
    payment_date DATE,
    amount_cents INT,
    status VARCHAR(10)  -- 'success' or 'failed'
);

CREATE TABLE user_events (
    event_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    event_type VARCHAR(30),
    event_timestamp TIMESTAMP
);

-- DATA
INSERT INTO users (signup_date, country, acquisition_channel) VALUES
('2024-01-15', 'US', 'paid_google'),
('2024-01-20', 'UK', 'organic'),
('2024-02-01', 'US', 'paid_fb'),
('2024-02-10', 'CA', 'referral'),
('2024-03-01', 'US', 'paid_google'),
('2024-03-15', 'US', 'organic');

INSERT INTO subscriptions (user_id, start_date, end_date, plan, mrr_cents) VALUES
(1, '2024-01-20', '2024-07-20', 'pro', 9900),
(2, '2024-01-25', NULL, 'basic', 0),
(3, '2024-02-05', '2024-04-05', 'pro', 9900),
(4, '2024-02-15', NULL, 'enterprise', 49900),
(5, '2024-03-05', NULL, 'pro', 9900),
(6, '2024-03-20', '2024-04-20', 'basic', 0);

INSERT INTO payments (sub_id, payment_date, amount_cents, status) VALUES
(1, '2024-01-20', 9900, 'success'),
(1, '2024-02-20', 9900, 'success'),
(1, '2024-03-20', 9900, 'failed'),
(3, '2024-02-05', 9900, 'success'),
(4, '2024-02-15', 49900, 'success'),
(5, '2024-03-05', 9900, 'success'),
(5, '2024-04-05', 9900, 'success');

INSERT INTO user_events (user_id, event_type, event_timestamp) VALUES
(1, 'login', '2024-01-21 10:00:00'),
(1, 'feature_x_used', '2024-01-22 14:30:00'),
(1, 'login', '2024-02-01 09:15:00'),
(2, 'login', '2024-01-26 11:11:11'),
(3, 'upgrade_clicked', '2024-02-10 12:00:00'),
(4, 'login', '2024-02-16 08:08:08'),
(5, 'feature_x_used', '2024-03-10 15:45:00'),
(5, 'login', '2024-03-20 16:00:00');

-- 8 QUESTIONS (exact Ramp/Vercel style)
-- 1. How many users signed up in each month of 2024?
-- 2. List all users from US who signed up via paid channels.
-- 3. What is the total MRR (in dollars) from active subscriptions right now (end_date IS NULL or > today)?
-- 4. Which subscriptions have at least one failed payment?
-- 5. Show user_id, plan, and number of successful payments for each subscription.
-- 6. Find users who have NEVER logged in (no rows in user_events with event_type = 'login').
-- 7. Monthly revenue (successful payments) for 2024, including months with $0.
-- 8. INTERVIEW KILLER: For each user who has used "feature_x_used" at least once, calculate days between signup_date and their FIRST feature_x_used event.

SELECT * FROM users;

-- 1. How many users signed up in each month of 2024?
-- Two users in each month
SELECT DATE_PART('month', signup_date), COUNT(user_id)
FROM users
GROUP BY DATE_PART('month', signup_date);

--2. List all users from US who signed up via paid channels.
SELECT *
FROM users
WHERE country = 'US'
  AND SUBSTRING(acquisition_channel, 1, 4) = 'paid';

-- 3. What is the total MRR (in dollars) from active subscriptions right now (end_date IS NULL or > today)?
SELECT SUM(mrr_cents)
FROM subscriptions
WHERE end_date IS NULL

-- 4. Which subscriptions have at least one failed payment?
SELECT 
    *
FROM 
    subscriptions AS sub
INNER JOIN 
    payments AS pay
    ON sub.sub_id = pay.sub_id
WHERE
    pay.status = 'failed'

-- 5. Show user_id, plan, and number of successful payments for each subscription.
SELECT
    user_id,
    plan,
    COUNT(*)
FROM
    subscriptions AS sub
    INNER JOIN
        payments AS pay
        ON sub.sub_id = pay.sub_id
WHERE
    pay.status = 'success'
GROUP BY
    user_id, plan

-- 6. Find users who have NEVER logged in (no rows in user_events with event_type = 'login').
SELECT
    *
FROM
    users
WHERE 
    user_id NOT IN (SELECT user_id
                    FROM user_events
                    WHERE event_type = 'login')

-- 7. Monthly revenue (successful payments) for 2024, including months with $0.
SELECT
    EXTRACT (MONTH FROM payment_date),
    SUM(amount_cents)
FROM
    payments
WHERE
    status = 'success'
GROUP BY
    1

-- 8. INTERVIEW KILLER: For each user who has used "feature_x_used" at least once, calculate days between signup_date and their FIRST feature_x_used event.
WITH feature_x_used AS 
    (SELECT
        event_id, user_events.user_id, signup_date, event_timestamp
    FROM
        user_events
    INNER JOIN
        users ON user_events.user_id = users.user_id
    WHERE
        event_type = 'feature_x_used')
SELECT
    *,
    EXTRACT(DAY FROM event_timestamp - signup_date) as days_interval
FROM
    feature_x_used