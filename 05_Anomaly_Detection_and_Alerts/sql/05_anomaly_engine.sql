-- SQL version: MySQL 8.0

/******************************************************************************
ANOMALY DETECTION & ALERT ENGINE

Goal
Detect unusual spikes or drops in platform metrics using
7-day moving baselines.

Outputs
daily_activity_metrics
daily_baselines
daily_anomaly_flags
segment_daily_baselines
segment_anomaly_flags
insights_summary
******************************************************************************/

----------------------------------------------------------
-- 0 CLEANUP
----------------------------------------------------------

DROP TABLE IF EXISTS daily_activity_metrics;
DROP TABLE IF EXISTS daily_baselines;
DROP TABLE IF EXISTS daily_anomaly_flags;
DROP TABLE IF EXISTS segment_daily_baselines;
DROP TABLE IF EXISTS segment_anomaly_flags;
DROP TABLE IF EXISTS insights_summary;



----------------------------------------------------------
-- 1 DAILY PLATFORM METRICS
----------------------------------------------------------

CREATE TABLE daily_activity_metrics AS

SELECT

DATE(event_datetime) activity_date,

COUNT(*) total_events,
COUNT(DISTINCT user_id) active_users,
COUNT(DISTINCT session_id_generated) sessions,

SUM(event_type='browse_restaurant') browse_events,
SUM(event_type='view_menu') view_events,
SUM(event_type='add_to_cart') addcart_events,
SUM(event_type='start_checkout') checkout_events

FROM events

GROUP BY DATE(event_datetime);



----------------------------------------------------------
-- 2 DAILY BASELINES (7-DAY MOVING AVERAGE)
----------------------------------------------------------

CREATE TABLE daily_baselines AS

SELECT

activity_date,

total_events,
active_users,
sessions,

AVG(total_events)
OVER (ORDER BY activity_date
ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) baseline_events,

AVG(active_users)
OVER (ORDER BY activity_date
ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) baseline_users,

AVG(sessions)
OVER (ORDER BY activity_date
ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) baseline_sessions

FROM daily_activity_metrics;



----------------------------------------------------------
-- 3 ANOMALY FLAGS (GLOBAL METRICS)
----------------------------------------------------------

CREATE TABLE daily_anomaly_flags AS

SELECT

activity_date,

total_events,
baseline_events,

active_users,
baseline_users,

sessions,
baseline_sessions,

CASE
WHEN total_events > baseline_events*1.5
THEN 'SPIKE'

WHEN total_events < baseline_events*0.5
THEN 'DROP'

ELSE 'NORMAL'
END AS event_anomaly_flag,

CASE
WHEN active_users > baseline_users*1.5
THEN 'SPIKE'

WHEN active_users < baseline_users*0.5
THEN 'DROP'

ELSE 'NORMAL'
END AS user_anomaly_flag,

CASE
WHEN sessions > baseline_sessions*1.5
THEN 'SPIKE'

WHEN sessions < baseline_sessions*0.5
THEN 'DROP'

ELSE 'NORMAL'
END AS session_anomaly_flag

FROM daily_baselines;



----------------------------------------------------------
-- 4 SEGMENT DAILY BASELINES
----------------------------------------------------------

CREATE TABLE segment_daily_baselines AS

SELECT

order_date,
device,

orders,
revenue,
active_users,

AVG(orders)
OVER (PARTITION BY device
ORDER BY order_date
ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING)
baseline_orders,

AVG(revenue)
OVER (PARTITION BY device
ORDER BY order_date
ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING)
baseline_revenue,

AVG(active_users)
OVER (PARTITION BY device
ORDER BY order_date
ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING)
baseline_users

FROM segment_daily_metrics;



----------------------------------------------------------
-- 5 SEGMENT ANOMALY FLAGS
----------------------------------------------------------

CREATE TABLE segment_anomaly_flags AS

SELECT

order_date,
device,

orders,
baseline_orders,

revenue,
baseline_revenue,

active_users,
baseline_users,

CASE
WHEN orders > baseline_orders*1.5
THEN 'SPIKE'
WHEN orders < baseline_orders*0.5
THEN 'DROP'
ELSE 'NORMAL'
END AS orders_anomaly,

CASE
WHEN revenue > baseline_revenue*1.5
THEN 'SPIKE'
WHEN revenue < baseline_revenue*0.5
THEN 'DROP'
ELSE 'NORMAL'
END AS revenue_anomaly

FROM segment_daily_baselines;



----------------------------------------------------------
-- 6 INSIGHTS SUMMARY
----------------------------------------------------------

CREATE TABLE insights_summary AS

SELECT

activity_date,
'Platform activity anomaly' insight_type,

CONCAT(
'Events anomaly = ',event_anomaly_flag,
', Users anomaly = ',user_anomaly_flag,
', Sessions anomaly = ',session_anomaly_flag
) description

FROM daily_anomaly_flags

WHERE event_anomaly_flag <> 'NORMAL'
OR user_anomaly_flag <> 'NORMAL'
OR session_anomaly_flag <> 'NORMAL';



----------------------------------------------------------
-- VERIFICATION QUERIES
----------------------------------------------------------

SELECT * FROM daily_activity_metrics LIMIT 20;

SELECT * FROM daily_baselines LIMIT 20;

SELECT * FROM daily_anomaly_flags LIMIT 20;

SELECT * FROM segment_anomaly_flags LIMIT 20;

SELECT * FROM insights_summary LIMIT 20;