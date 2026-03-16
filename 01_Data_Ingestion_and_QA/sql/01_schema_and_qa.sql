-- SQL version: MySQL 8.0

/* =========================================================
PROJECT 1 — DATABASE & DATA QUALITY SETUP
Purpose:
1) Create the core schema (users, restaurants, events, orders).
2) Load CSV data into each table.
3) Run basic data-quality checks:
   - Row counts
   - NULLs in mandatory columns
   - Duplicate primary keys
   - Orphan foreign keys
   - Session ID quality
========================================================= */

----------------------------------------------------------
-- A. DATABASE CREATION
----------------------------------------------------------

CREATE DATABASE IF NOT EXISTS project1
CHARACTER SET utf8mb4
COLLATE utf8mb4_general_ci;

USE project1;


----------------------------------------------------------
-- B. CORE TABLE DEFINITIONS
----------------------------------------------------------

-- 1) Users table
CREATE TABLE IF NOT EXISTS users
(
    user_id INT NOT NULL,
    signup_date DATE NOT NULL,
    signup_time TIME NOT NULL,
    device VARCHAR(20) NOT NULL,
    acquisition_channel VARCHAR(50) NOT NULL,
    age INT NOT NULL,
    gender VARCHAR(10) NOT NULL,
    city VARCHAR(100) NOT NULL,
    churn_7d TINYINT(1) NOT NULL,
    first_order_date DATE NULL,
    first_order_time TIME NULL,
    PRIMARY KEY (user_id)
);

-- 2) Restaurants table
CREATE TABLE IF NOT EXISTS restaurants
(
    restaurant_id INT NOT NULL,
    restaurant_name VARCHAR(100) NOT NULL,
    restaurant_category VARCHAR(100) NOT NULL,
    restaurant_rating DECIMAL(2,1) NOT NULL,
    avg_delivery_min INT NOT NULL,
    PRIMARY KEY (restaurant_id)
);

-- 3) Events table
CREATE TABLE IF NOT EXISTS events
(
    event_id CHAR(36) NOT NULL,
    user_id INT NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_date DATE NOT NULL,
    event_time TIME NOT NULL,
    session_id VARCHAR(50) NOT NULL,
    restaurant_id INT NULL,
    product_price DECIMAL(10,2),
    quantity INT,
    PRIMARY KEY (event_id)
);

-- 4) Orders table
CREATE TABLE IF NOT EXISTS orders
(
    order_id INT NOT NULL,
    user_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    restaurant_id INT NOT NULL,
    order_value DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    items_count INT NOT NULL,
    delivery_time_min INT NOT NULL,
    success TINYINT(1) NOT NULL,
    PRIMARY KEY (order_id)
);


----------------------------------------------------------
-- C. FOREIGN KEY CONSTRAINTS
----------------------------------------------------------

ALTER TABLE events
ADD CONSTRAINT fk_events_user
FOREIGN KEY (user_id)
REFERENCES users (user_id)
ON DELETE CASCADE,
ADD CONSTRAINT fk_events_restaurant
FOREIGN KEY (restaurant_id)
REFERENCES restaurants (restaurant_id)
ON DELETE SET NULL;

ALTER TABLE orders
MODIFY restaurant_id INT NULL;

ALTER TABLE orders
ADD CONSTRAINT fk_orders_user
FOREIGN KEY (user_id)
REFERENCES users (user_id)
ON DELETE CASCADE;

ALTER TABLE orders
ADD CONSTRAINT fk_orders_restaurant
FOREIGN KEY (restaurant_id)
REFERENCES restaurants (restaurant_id)
ON DELETE SET NULL;


----------------------------------------------------------
-- D. DATA LOAD FROM CSV FILES
----------------------------------------------------------

LOAD DATA LOCAL INFILE 'D:/downloads/my project 1 for product for CSV - Copy/restaurants.csv'
INTO TABLE restaurants
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
restaurant_id,
restaurant_name,
restaurant_category,
restaurant_rating,
avg_delivery_min
);

LOAD DATA LOCAL INFILE 'D:/downloads/my project 1 for product for CSV - Copy/users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
user_id,
signup_date,
signup_time,
device,
acquisition_channel,
age,
gender,
city,
churn_7d,
first_order_date,
first_order_time
);

LOAD DATA LOCAL INFILE 'D:/downloads/my project 1 for product for CSV - Copy/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
order_id,
user_id,
order_date,
order_time,
restaurant_id,
order_value,
payment_method,
items_count,
delivery_time_min,
success
);

LOAD DATA LOCAL INFILE 'D:/downloads/my project 1 for product for CSV - Copy/events.csv'
INTO TABLE events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
event_id,
user_id,
event_type,
event_date,
event_time,
session_id,
restaurant_id,
product_price,
quantity
);


----------------------------------------------------------
-- E. QUICK RELATIONSHIP CHECKS
----------------------------------------------------------

SELECT o.order_id, o.restaurant_id
FROM orders o
LEFT JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
WHERE r.restaurant_id IS NULL;

SELECT o.order_id, o.user_id
FROM orders o
LEFT JOIN users u
ON o.user_id = u.user_id
WHERE u.user_id IS NULL;

SELECT e.event_id, e.restaurant_id
FROM events e
LEFT JOIN restaurants r
ON e.restaurant_id = r.restaurant_id
WHERE r.restaurant_id IS NULL;

SELECT e.event_id, e.user_id
FROM events e
LEFT JOIN users u
ON e.user_id = u.user_id
WHERE u.user_id IS NULL;


----------------------------------------------------------
-- F. ROW COUNTS
----------------------------------------------------------

SELECT 'orders' AS table_name, COUNT(*) AS row_count, COUNT(DISTINCT order_id) AS distinct_pk_count
FROM orders
UNION ALL
SELECT 'events', COUNT(*), COUNT(DISTINCT event_id) FROM events
UNION ALL
SELECT 'users', COUNT(*), COUNT(DISTINCT user_id) FROM users
UNION ALL
SELECT 'restaurants', COUNT(*), COUNT(DISTINCT restaurant_id) FROM restaurants;


----------------------------------------------------------
-- G. DIRECT NULL CHECKS
----------------------------------------------------------

SELECT * FROM users WHERE signup_date IS NULL;
SELECT * FROM orders WHERE order_date IS NULL;
SELECT * FROM events WHERE event_date IS NULL;


----------------------------------------------------------
-- H. MANDATORY COLUMN NULL CHECKS
----------------------------------------------------------

SELECT 'users_missing_mandatory', COUNT(*)
FROM users
WHERE user_id IS NULL
OR signup_date IS NULL
OR signup_time IS NULL;

SELECT 'events_missing_mandatory', COUNT(*)
FROM events
WHERE event_id IS NULL
OR user_id IS NULL
OR event_date IS NULL
OR event_time IS NULL;

SELECT 'orders_missing_mandatory', COUNT(*)
FROM orders
WHERE order_id IS NULL
OR user_id IS NULL
OR order_date IS NULL
OR order_time IS NULL;

SELECT 'restaurants_missing_mandatory', COUNT(*)
FROM restaurants
WHERE restaurant_id IS NULL;


----------------------------------------------------------
-- I. DUPLICATE PRIMARY KEY CHECKS
----------------------------------------------------------

SELECT 'users_dup_pk', COUNT(*)
FROM (
SELECT user_id
FROM users
GROUP BY user_id
HAVING COUNT(*) > 1
) duplicates;

SELECT 'events_dup_pk', COUNT(*)
FROM (
SELECT event_id
FROM events
GROUP BY event_id
HAVING COUNT(*) > 1
) duplicates;

SELECT 'orders_dup_pk', COUNT(*)
FROM (
SELECT order_id
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1
) duplicates;

SELECT 'restaurants_dup_pk', COUNT(*)
FROM (
SELECT restaurant_id
FROM restaurants
GROUP BY restaurant_id
HAVING COUNT(*) > 1
) duplicates;


----------------------------------------------------------
-- J. ORPHAN FOREIGN KEY CHECKS
----------------------------------------------------------

SELECT 'events_orphan_users', COUNT(*)
FROM events e
LEFT JOIN users u ON e.user_id = u.user_id
WHERE u.user_id IS NULL;

SELECT 'events_orphan_restaurants', COUNT(*)
FROM events e
LEFT JOIN restaurants r ON e.restaurant_id = r.restaurant_id
WHERE e.restaurant_id IS NOT NULL
AND r.restaurant_id IS NULL;

SELECT 'orders_orphan_users', COUNT(*)
FROM orders o
LEFT JOIN users u ON o.user_id = u.user_id
WHERE u.user_id IS NULL;

SELECT 'orders_orphan_restaurants', COUNT(*)
FROM orders o
LEFT JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.restaurant_id IS NOT NULL
AND r.restaurant_id IS NULL;


----------------------------------------------------------
-- STEP D — ADD DATETIME COLUMNS
----------------------------------------------------------

ALTER TABLE users
ADD COLUMN signup_datetime DATETIME NULL,
ADD COLUMN first_order_datetime DATETIME NULL;

ALTER TABLE events
ADD COLUMN event_datetime DATETIME NULL;

ALTER TABLE orders
ADD COLUMN order_datetime DATETIME NULL;


----------------------------------------------------------
-- Populate combined datetime
----------------------------------------------------------

UPDATE users
SET signup_datetime = TIMESTAMP(signup_date, signup_time),
first_order_datetime = TIMESTAMP(first_order_date, first_order_time);

UPDATE events
SET event_datetime = TIMESTAMP(event_date, event_time);

UPDATE orders
SET order_datetime = TIMESTAMP(order_date, order_time);


----------------------------------------------------------
-- STEP E.1 — INDEX FOR EVENT QUERIES
----------------------------------------------------------

CREATE INDEX idx_events_user_datetime
ON events (user_id, event_datetime);


SELECT COUNT(*) AS events_after_index
FROM events;

SHOW INDEX FROM events;