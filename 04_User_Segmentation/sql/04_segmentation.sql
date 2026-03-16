-- SQL version: MySQL 8.0

/******************************************************************************
SEGMENTATION PERFORMANCE TABLES

Purpose
- Build funnel metrics, retention metrics, and revenue metrics
  segmented by:
    device
    acquisition_channel
    gender
    city
    age_group

Source tables
- users
- events
- orders
- user_first_stages

Derived tables created
- user_segments
- segment_funnel_summary
- segment_retention_summary
- segment_revenue_summary
******************************************************************************/

----------------------------------------------------------
-- 0 Cleanup (idempotent)
----------------------------------------------------------

DROP TABLE IF EXISTS segment_funnel_summary;
DROP TABLE IF EXISTS segment_retention_summary;
DROP TABLE IF EXISTS segment_revenue_summary;
DROP TABLE IF EXISTS user_segments;


----------------------------------------------------------
-- 1 USER SEGMENTS TABLE
----------------------------------------------------------

CREATE TABLE user_segments AS

SELECT

u.user_id,

COALESCE(ufs.t_signup, u.signup_datetime, u.signup_date)
AS signup_datetime,

COALESCE(ufs.t_first_payment_canonical,
u.first_order_datetime)
AS t_first_payment_canonical,

ufs.t_browse,
ufs.t_view,
ufs.t_addcart,
ufs.t_checkout,
ufs.t_payment,

COALESCE(u.device,'UNKNOWN') device,
COALESCE(u.acquisition_channel,'UNKNOWN') acquisition_channel,
COALESCE(u.gender,'unknown') gender,
COALESCE(u.city,'unknown') city,

CASE
WHEN u.age BETWEEN 18 AND 24 THEN '18-24'
WHEN u.age BETWEEN 25 AND 34 THEN '25-34'
WHEN u.age BETWEEN 35 AND 44 THEN '35-44'
WHEN u.age >=45 THEN '45+'
ELSE 'unknown'
END AS age_group

FROM users u

LEFT JOIN user_first_stages ufs
ON u.user_id = ufs.user_id;


----------------------------------------------------------
-- Add indexes
----------------------------------------------------------

ALTER TABLE user_segments ADD INDEX idx_us_user (user_id);
ALTER TABLE user_segments ADD INDEX idx_us_device (device);
ALTER TABLE user_segments ADD INDEX idx_us_channel (acquisition_channel);
ALTER TABLE user_segments ADD INDEX idx_us_city (city);
ALTER TABLE user_segments ADD INDEX idx_us_age (age_group);
ALTER TABLE user_segments ADD INDEX idx_us_gender (gender);


----------------------------------------------------------
-- 2 SEGMENT FUNNEL SUMMARY
----------------------------------------------------------

CREATE TABLE segment_funnel_summary
(
segment_type VARCHAR(32),
segment_value VARCHAR(128),

n_users INT,
n_browsed INT,
n_viewed INT,
n_addcart INT,
n_checkout INT,
n_payment INT,

pct_signup_to_browse DECIMAL(6,2),
pct_browse_to_view DECIMAL(6,2),
pct_view_to_addcart DECIMAL(6,2),
pct_addcart_to_checkout DECIMAL(6,2),
pct_checkout_to_payment DECIMAL(6,2),

PRIMARY KEY (segment_type, segment_value)
);


INSERT INTO segment_funnel_summary

SELECT
'device',
device,

COUNT(*),
SUM(t_browse IS NOT NULL),
SUM(t_view IS NOT NULL),
SUM(t_addcart IS NOT NULL),
SUM(t_checkout IS NOT NULL),
SUM(t_first_payment_canonical IS NOT NULL),

ROUND(100*SUM(t_browse IS NOT NULL)/COUNT(*),2),
ROUND(100*SUM(t_view IS NOT NULL)/NULLIF(SUM(t_browse IS NOT NULL),0),2),
ROUND(100*SUM(t_addcart IS NOT NULL)/NULLIF(SUM(t_view IS NOT NULL),0),2),
ROUND(100*SUM(t_checkout IS NOT NULL)/NULLIF(SUM(t_addcart IS NOT NULL),0),2),
ROUND(100*SUM(t_first_payment_canonical IS NOT NULL)/NULLIF(SUM(t_checkout IS NOT NULL),0),2)

FROM user_segments
GROUP BY device;


----------------------------------------------------------
-- Acquisition channel
----------------------------------------------------------

INSERT INTO segment_funnel_summary

SELECT
'acquisition_channel',
acquisition_channel,

COUNT(*),
SUM(t_browse IS NOT NULL),
SUM(t_view IS NOT NULL),
SUM(t_addcart IS NOT NULL),
SUM(t_checkout IS NOT NULL),
SUM(t_first_payment_canonical IS NOT NULL),

ROUND(100*SUM(t_browse IS NOT NULL)/COUNT(*),2),
ROUND(100*SUM(t_view IS NOT NULL)/NULLIF(SUM(t_browse IS NOT NULL),0),2),
ROUND(100*SUM(t_addcart IS NOT NULL)/NULLIF(SUM(t_view IS NOT NULL),0),2),
ROUND(100*SUM(t_checkout IS NOT NULL)/NULLIF(SUM(t_addcart IS NOT NULL),0),2),
ROUND(100*SUM(t_first_payment_canonical IS NOT NULL)/NULLIF(SUM(t_checkout IS NOT NULL),0),2)

FROM user_segments
GROUP BY acquisition_channel;


----------------------------------------------------------
-- Gender
----------------------------------------------------------

INSERT INTO segment_funnel_summary

SELECT
'gender',
gender,

COUNT(*),
SUM(t_browse IS NOT NULL),
SUM(t_view IS NOT NULL),
SUM(t_addcart IS NOT NULL),
SUM(t_checkout IS NOT NULL),
SUM(t_first_payment_canonical IS NOT NULL),

ROUND(100*SUM(t_browse IS NOT NULL)/COUNT(*),2),
ROUND(100*SUM(t_view IS NOT NULL)/NULLIF(SUM(t_browse IS NOT NULL),0),2),
ROUND(100*SUM(t_addcart IS NOT NULL)/NULLIF(SUM(t_view IS NOT NULL),0),2),
ROUND(100*SUM(t_checkout IS NOT NULL)/NULLIF(SUM(t_addcart IS NOT NULL),0),2),
ROUND(100*SUM(t_first_payment_canonical IS NOT NULL)/NULLIF(SUM(t_checkout IS NOT NULL),0),2)

FROM user_segments
GROUP BY gender;


----------------------------------------------------------
-- City
----------------------------------------------------------

INSERT INTO segment_funnel_summary

SELECT
'city',
city,

COUNT(*),
SUM(t_browse IS NOT NULL),
SUM(t_view IS NOT NULL),
SUM(t_addcart IS NOT NULL),
SUM(t_checkout IS NOT NULL),
SUM(t_first_payment_canonical IS NOT NULL),

ROUND(100*SUM(t_browse IS NOT NULL)/COUNT(*),2),
ROUND(100*SUM(t_view IS NOT NULL)/NULLIF(SUM(t_browse IS NOT NULL),0),2),
ROUND(100*SUM(t_addcart IS NOT NULL)/NULLIF(SUM(t_view IS NOT NULL),0),2),
ROUND(100*SUM(t_checkout IS NOT NULL)/NULLIF(SUM(t_addcart IS NOT NULL),0),2),
ROUND(100*SUM(t_first_payment_canonical IS NOT NULL)/NULLIF(SUM(t_checkout IS NOT NULL),0),2)

FROM user_segments
GROUP BY city;


----------------------------------------------------------
-- Age group
----------------------------------------------------------

INSERT INTO segment_funnel_summary

SELECT
'age_group',
age_group,

COUNT(*),
SUM(t_browse IS NOT NULL),
SUM(t_view IS NOT NULL),
SUM(t_addcart IS NOT NULL),
SUM(t_checkout IS NOT NULL),
SUM(t_first_payment_canonical IS NOT NULL),

ROUND(100*SUM(t_browse IS NOT NULL)/COUNT(*),2),
ROUND(100*SUM(t_view IS NOT NULL)/NULLIF(SUM(t_browse IS NOT NULL),0),2),
ROUND(100*SUM(t_addcart IS NOT NULL)/NULLIF(SUM(t_view IS NOT NULL),0),2),
ROUND(100*SUM(t_checkout IS NOT NULL)/NULLIF(SUM(t_addcart IS NOT NULL),0),2),
ROUND(100*SUM(t_first_payment_canonical IS NOT NULL)/NULLIF(SUM(t_checkout IS NOT NULL),0),2)

FROM user_segments
GROUP BY age_group;


----------------------------------------------------------
-- 3 SEGMENT REVENUE SUMMARY
----------------------------------------------------------

CREATE TABLE segment_revenue_summary AS

SELECT

'us.device' segment_type,
us.device segment_value,

COUNT(o.order_id) orders,
SUM(o.order_value) revenue,
AVG(o.order_value) avg_order_value

FROM user_segments us
JOIN orders o
ON o.user_id = us.user_id

WHERE o.success = 1

GROUP BY us.device;


----------------------------------------------------------
-- 4 SEGMENT DAILY METRICS
----------------------------------------------------------

CREATE TABLE segment_daily_metrics AS

SELECT

DATE(o.order_datetime) order_date,

us.device,

COUNT(DISTINCT o.order_id) orders,
SUM(o.order_value) revenue,
COUNT(DISTINCT o.user_id) active_users

FROM orders o
JOIN user_segments us
ON us.user_id = o.user_id

WHERE o.success = 1

GROUP BY DATE(o.order_datetime), us.device;


----------------------------------------------------------
-- Verification
----------------------------------------------------------

SELECT * FROM segment_funnel_summary LIMIT 20;
SELECT * FROM segment_revenue_summary LIMIT 20;
SELECT * FROM segment_daily_metrics LIMIT 20;