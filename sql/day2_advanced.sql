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

-- 2 QUESTIONS 
-- 1. Cohort retention: % of users who logged in 7 days after signup
-- 2. Revenue churn: list every subscription that ended and how much MRR was lost


-- 1. Cohort retention: % of users who logged in 7 days after signup
WITH new_table AS
        (SELECT 
            users.user_id,
            signup_date,
            signup_date + INTERVAL '7 days' AS added_days,
            event_type,
            event_timestamp
         FROM
            users
            INNER JOIN
                user_events USING (user_id))
SELECT
    (COUNT(*) / (SELECT COUNT(*) FROM users)::FLOAT) * 100 AS users_perc
FROM
    new_table
WHERE
    event_timestamp >= added_days
    AND event_type = 'login'

-- 2. Revenue churn: list every subscription that ended and how much MRR was lost
SELECT
    *,
    SUM(mrr_cents) OVER() AS total_mrr_lost
FROM
    subscriptions
WHERE
    end_date IS NOT NULL