-- SQL version: MySQL 8.0

/* ============================================================================
STEP E.2 — SESSION RECONSTRUCTION (30-MINUTE INACTIVITY RULE)

Purpose:
- Rebuild session identifiers using event_datetime.

Rule:
- First event for a user starts a new session.
- Any gap > 30 minutes from the previous event starts a new session.

Output:
events.session_id_generated = userId_sessionNumber
Example: 100000_1, 100000_2

NOTE:
Original session_id column is NOT modified.
============================================================================ */

----------------------------------------------------------
-- E.2.1 Add column for generated session IDs
----------------------------------------------------------

ALTER TABLE events
ADD COLUMN session_id_generated VARCHAR(64) NULL;


----------------------------------------------------------
-- E.2.2 Safety cleanup
----------------------------------------------------------

DROP TEMPORARY TABLE IF EXISTS tmp_event_sessions;


----------------------------------------------------------
-- E.2.3 Session reconstruction logic
----------------------------------------------------------

CREATE TEMPORARY TABLE tmp_event_sessions AS
SELECT
event_id,
user_id,
event_datetime,
prev_event_dt,

CASE
WHEN prev_event_dt IS NULL THEN 1
WHEN TIMESTAMPDIFF(MINUTE, prev_event_dt, event_datetime) > 30 THEN 1
ELSE 0
END AS is_new_session,

SUM(
CASE
WHEN prev_event_dt IS NULL THEN 1
WHEN TIMESTAMPDIFF(MINUTE, prev_event_dt, event_datetime) > 30 THEN 1
ELSE 0
END
) OVER (
PARTITION BY user_id
ORDER BY event_datetime, event_id
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS session_no

FROM (

SELECT
event_id,
user_id,
event_datetime,

LAG(event_datetime) OVER (
PARTITION BY user_id
ORDER BY event_datetime, event_id
) AS prev_event_dt

FROM events

) sub;


----------------------------------------------------------
-- E.2.4 Index temp table
----------------------------------------------------------

ALTER TABLE tmp_event_sessions
ADD INDEX idx_tmp_event_sessions_event_id (event_id);


----------------------------------------------------------
-- E.2.5 Preview sample session results
----------------------------------------------------------

SELECT
event_id,
user_id,
event_datetime,
prev_event_dt,
is_new_session,
session_no
FROM tmp_event_sessions
ORDER BY user_id, event_datetime, event_id
LIMIT 20;


----------------------------------------------------------
-- E.2.6 Write generated session IDs back to events
----------------------------------------------------------

UPDATE events e
JOIN tmp_event_sessions t
USING (event_id)

SET e.session_id_generated =
CONCAT(t.user_id, '_', t.session_no);


----------------------------------------------------------
-- E.2.7 Verification checks
----------------------------------------------------------

SELECT 'events_total' AS check_name,
COUNT(*) AS value
FROM events;

SELECT 'events_session_id_null_count' AS check_name,
COUNT(*) AS value
FROM events
WHERE session_id_generated IS NULL
OR session_id_generated = '';

SELECT 'distinct_generated_sessions' AS check_name,
COUNT(DISTINCT session_id_generated) AS value
FROM events;


----------------------------------------------------------
-- E.2.8 Events per session statistics
----------------------------------------------------------

WITH events_per_session AS (
SELECT
session_id_generated,
COUNT(*) AS events_per_session
FROM events
GROUP BY session_id_generated
)

SELECT 'events_per_session_avg' AS metric,
AVG(events_per_session) AS value
FROM events_per_session

UNION ALL

SELECT 'events_per_session_max',
MAX(events_per_session)
FROM events_per_session;


----------------------------------------------------------
-- Median events per session
----------------------------------------------------------

SELECT 'events_per_session_median' AS metric,
AVG(events_per_session) AS value
FROM (

SELECT
events_per_session,
ROW_NUMBER() OVER (ORDER BY events_per_session) rn,
COUNT(*) OVER () total_rows

FROM (
SELECT COUNT(*) events_per_session
FROM events
GROUP BY session_id_generated
) x

) y

WHERE rn IN (
FLOOR((total_rows + 1) / 2),
CEIL((total_rows + 1) / 2)
);


----------------------------------------------------------
-- E.2.9 Sample user session timeline
----------------------------------------------------------

SET @sample_user_id := (
SELECT user_id
FROM events
LIMIT 1
);

SELECT
event_id,
user_id,
event_datetime,
event_type,
session_id_generated
FROM events
WHERE user_id = @sample_user_id
ORDER BY event_datetime, event_id
LIMIT 200;


----------------------------------------------------------
-- E.2.10 Users with most sessions
----------------------------------------------------------

SELECT
CAST(SUBSTRING_INDEX(session_id_generated, '_', 1) AS UNSIGNED) user_id,
COUNT(DISTINCT session_id_generated) sessions_count
FROM events
GROUP BY user_id
ORDER BY sessions_count DESC
LIMIT 20;


----------------------------------------------------------
-- E.2.11 Cleanup temp table
----------------------------------------------------------

DROP TEMPORARY TABLE IF EXISTS tmp_event_sessions;



/* ============================================================================
STEP F — SESSION & FUNNEL FOUNDATION
============================================================================ */

----------------------------------------------------------
-- F.1 Context check
----------------------------------------------------------

SELECT
(SELECT COUNT(*) FROM events) AS total_events,

(SELECT COUNT(DISTINCT session_id_generated)
FROM events) AS total_sessions,

(SELECT COUNT(*) FROM events) /
NULLIF((SELECT COUNT(DISTINCT session_id_generated)
FROM events),0) AS avg_events_per_session_check;



/* ============================================================================
F.2 USER FIRST STAGES
============================================================================ */

CREATE TABLE IF NOT EXISTS user_first_stages
(
user_id INT PRIMARY KEY,

t_signup DATETIME,
t_browse DATETIME,
t_view DATETIME,
t_addcart DATETIME,
t_checkout DATETIME,
t_payment DATETIME,

first_order_time_from_orders DATETIME,

t_first_payment_canonical DATETIME,

INDEX idx_ufs_signup (t_signup),
INDEX idx_ufs_payment (t_first_payment_canonical)
);


INSERT INTO user_first_stages
(
user_id,
t_signup,
t_browse,
t_view,
t_addcart,
t_checkout,
t_payment,
first_order_time_from_orders,
t_first_payment_canonical
)

SELECT
u.user_id,

u.signup_datetime,

e.t_browse,
e.t_view,
e.t_addcart,
e.t_checkout,
e.t_payment,

o.first_order_time_from_orders,

COALESCE(e.t_payment, o.first_order_time_from_orders)

FROM users u

LEFT JOIN (

SELECT
user_id,

MIN(CASE WHEN event_type='browse_restaurant'
THEN event_datetime END) t_browse,

MIN(CASE WHEN event_type='view_menu'
THEN event_datetime END) t_view,

MIN(CASE WHEN event_type='add_to_cart'
THEN event_datetime END) t_addcart,

MIN(CASE WHEN event_type='start_checkout'
THEN event_datetime END) t_checkout,

MIN(CASE
WHEN event_type IN ('payment_success','order_complete')
THEN event_datetime END) t_payment

FROM events
GROUP BY user_id

) e

ON u.user_id = e.user_id


LEFT JOIN (

SELECT
user_id,
MIN(order_datetime) first_order_time_from_orders

FROM orders
WHERE success = 1
GROUP BY user_id

) o

ON u.user_id = o.user_id


ON DUPLICATE KEY UPDATE

t_signup = VALUES(t_signup),
t_browse = VALUES(t_browse),
t_view = VALUES(t_view),
t_addcart = VALUES(t_addcart),
t_checkout = VALUES(t_checkout),
t_payment = VALUES(t_payment),
first_order_time_from_orders = VALUES(first_order_time_from_orders),
t_first_payment_canonical = VALUES(t_first_payment_canonical);



----------------------------------------------------------
-- F.2 Verification
----------------------------------------------------------

SELECT 'ufs_row_count', COUNT(*) FROM user_first_stages;

SELECT
COUNT(*) total_users,
SUM(t_browse IS NOT NULL) n_browsed,
SUM(t_view IS NOT NULL) n_viewed,
SUM(t_addcart IS NOT NULL) n_addcart,
SUM(t_checkout IS NOT NULL) n_checkout,
SUM((t_payment IS NOT NULL) OR
(first_order_time_from_orders IS NOT NULL))
n_payment_or_order
FROM user_first_stages;



/* ============================================================================
F.3 FUNNEL SUMMARY
============================================================================ */

DROP TABLE IF EXISTS funnel_summary;

CREATE TABLE funnel_summary
(
snapshot_date DATE PRIMARY KEY,

total_users INT,
n_signed_up INT,
n_browsed INT,
n_viewed INT,
n_addcart INT,
n_checkout INT,
n_payment INT,

pct_signup_to_browse DECIMAL(5,2),
pct_browse_to_view DECIMAL(5,2),
pct_view_to_addcart DECIMAL(5,2),
pct_addcart_to_checkout DECIMAL(5,2),
pct_checkout_to_payment DECIMAL(5,2)
);


INSERT INTO funnel_summary

SELECT

CURRENT_DATE(),

COUNT(*),

SUM(t_signup IS NOT NULL),
SUM(t_browse IS NOT NULL),
SUM(t_view IS NOT NULL),
SUM(t_addcart IS NOT NULL),
SUM(t_checkout IS NOT NULL),
SUM(t_first_payment_canonical IS NOT NULL),

ROUND(100*SUM(t_browse IS NOT NULL)/NULLIF(COUNT(*),0),2),

ROUND(100*SUM(t_view IS NOT NULL)/
NULLIF(SUM(t_browse IS NOT NULL),0),2),

ROUND(100*SUM(t_addcart IS NOT NULL)/
NULLIF(SUM(t_view IS NOT NULL),0),2),

ROUND(100*SUM(t_checkout IS NOT NULL)/
NULLIF(SUM(t_addcart IS NOT NULL),0),2),

ROUND(100*SUM(t_first_payment_canonical IS NOT NULL)/
NULLIF(SUM(t_checkout IS NOT NULL),0),2)

FROM user_first_stages;


----------------------------------------------------------
-- Funnel validation
----------------------------------------------------------

SELECT * FROM funnel_summary;