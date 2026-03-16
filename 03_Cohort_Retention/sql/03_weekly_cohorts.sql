-- SQL version: MySQL 8.0

/* ============================================================================
F.4 — WEEKLY COHORT RETENTION

Metric:
- Weekly cohorts (by signup week)
- Retention measured weeks 1–8
- Retention = active users / cohort size

Cohort week start = Monday
============================================================================ */

----------------------------------------------------------
-- F.4.1 Recreate cohort retention table
----------------------------------------------------------

DROP TABLE IF EXISTS cohort_weekly_retention;

CREATE TABLE cohort_weekly_retention
(
cohort_week VARCHAR(16) PRIMARY KEY,
cohort_start_date DATE,
cohort_size INT,

week_0_active INT,
week_1_active INT,
week_2_active INT,
week_3_active INT,
week_4_active INT,
week_5_active INT,
week_6_active INT,
week_7_active INT,
week_8_active INT,

week_1_retention_pct DECIMAL(6,2),
week_2_retention_pct DECIMAL(6,2),
week_3_retention_pct DECIMAL(6,2),
week_4_retention_pct DECIMAL(6,2),
week_5_retention_pct DECIMAL(6,2),
week_6_retention_pct DECIMAL(6,2),
week_7_retention_pct DECIMAL(6,2),
week_8_retention_pct DECIMAL(6,2)
);


----------------------------------------------------------
-- F.4.2 Insert cohort retention metrics
----------------------------------------------------------

INSERT INTO cohort_weekly_retention
(
cohort_week,
cohort_start_date,
cohort_size,

week_0_active,
week_1_active,
week_2_active,
week_3_active,
week_4_active,
week_5_active,
week_6_active,
week_7_active,
week_8_active,

week_1_retention_pct,
week_2_retention_pct,
week_3_retention_pct,
week_4_retention_pct,
week_5_retention_pct,
week_6_retention_pct,
week_7_retention_pct,
week_8_retention_pct
)

SELECT
uc.cohort_week,
uc.cohort_start_date,
uc.cohort_size,

uc.cohort_size AS week_0_active,

COALESCE(MAX(CASE WHEN a.week_index=1 THEN a.users_active END),0),
COALESCE(MAX(CASE WHEN a.week_index=2 THEN a.users_active END),0),
COALESCE(MAX(CASE WHEN a.week_index=3 THEN a.users_active END),0),
COALESCE(MAX(CASE WHEN a.week_index=4 THEN a.users_active END),0),
COALESCE(MAX(CASE WHEN a.week_index=5 THEN a.users_active END),0),
COALESCE(MAX(CASE WHEN a.week_index=6 THEN a.users_active END),0),
COALESCE(MAX(CASE WHEN a.week_index=7 THEN a.users_active END),0),
COALESCE(MAX(CASE WHEN a.week_index=8 THEN a.users_active END),0),

ROUND(100*COALESCE(MAX(CASE WHEN a.week_index=1 THEN a.users_active END),0)/uc.cohort_size,2),
ROUND(100*COALESCE(MAX(CASE WHEN a.week_index=2 THEN a.users_active END),0)/uc.cohort_size,2),
ROUND(100*COALESCE(MAX(CASE WHEN a.week_index=3 THEN a.users_active END),0)/uc.cohort_size,2),
ROUND(100*COALESCE(MAX(CASE WHEN a.week_index=4 THEN a.users_active END),0)/uc.cohort_size,2),
ROUND(100*COALESCE(MAX(CASE WHEN a.week_index=5 THEN a.users_active END),0)/uc.cohort_size,2),
ROUND(100*COALESCE(MAX(CASE WHEN a.week_index=6 THEN a.users_active END),0)/uc.cohort_size,2),
ROUND(100*COALESCE(MAX(CASE WHEN a.week_index=7 THEN a.users_active END),0)/uc.cohort_size,2),
ROUND(100*COALESCE(MAX(CASE WHEN a.week_index=8 THEN a.users_active END),0)/uc.cohort_size,2)

FROM

(
SELECT
cohort_week,
cohort_start_date,
COUNT(*) cohort_size

FROM
(
SELECT
u.user_id,

DATE_SUB(
DATE(COALESCE(u.signup_datetime,u.signup_date)),
INTERVAL WEEKDAY(DATE(COALESCE(u.signup_datetime,u.signup_date))) DAY
) cohort_start_date,

CONCAT(
YEAR(
DATE_SUB(
DATE(COALESCE(u.signup_datetime,u.signup_date)),
INTERVAL WEEKDAY(DATE(COALESCE(u.signup_datetime,u.signup_date))) DAY
)
),
'-W',
LPAD(
WEEK(
DATE_SUB(
DATE(COALESCE(u.signup_datetime,u.signup_date)),
INTERVAL WEEKDAY(DATE(COALESCE(u.signup_datetime,u.signup_date))) DAY
)
),
2,
'0'
)
) cohort_week

FROM users u
) x

GROUP BY cohort_week, cohort_start_date

) uc


LEFT JOIN

(
SELECT
ac.cohort_week,
ac.cohort_start_date,
ac.week_index,
COUNT(DISTINCT ac.user_id) users_active

FROM
(
SELECT

u.user_id,

DATE_SUB(
DATE(COALESCE(u.signup_datetime,u.signup_date)),
INTERVAL WEEKDAY(DATE(COALESCE(u.signup_datetime,u.signup_date))) DAY
) cohort_start_date,

CONCAT(
YEAR(
DATE_SUB(
DATE(COALESCE(u.signup_datetime,u.signup_date)),
INTERVAL WEEKDAY(DATE(COALESCE(u.signup_datetime,u.signup_date))) DAY
)
),
'-W',
LPAD(
WEEK(
DATE_SUB(
DATE(COALESCE(u.signup_datetime,u.signup_date)),
INTERVAL WEEKDAY(DATE(COALESCE(u.signup_datetime,u.signup_date))) DAY
)
),
2,
'0'
)
) cohort_week,

FLOOR(
DATEDIFF(
DATE(e.event_datetime),

DATE_SUB(
DATE(COALESCE(u.signup_datetime,u.signup_date)),
INTERVAL WEEKDAY(DATE(COALESCE(u.signup_datetime,u.signup_date))) DAY
)
)/7
) week_index

FROM users u
JOIN events e
ON e.user_id=u.user_id

) ac

WHERE ac.week_index BETWEEN 1 AND 8

GROUP BY
ac.cohort_week,
ac.cohort_start_date,
ac.week_index

) a

ON a.cohort_week=uc.cohort_week
AND a.cohort_start_date=uc.cohort_start_date

GROUP BY
uc.cohort_week,
uc.cohort_start_date,
uc.cohort_size;



----------------------------------------------------------
-- F.4.3 Verification queries
----------------------------------------------------------

SELECT COUNT(*) AS cohort_rows
FROM cohort_weekly_retention;


SELECT *
FROM cohort_weekly_retention
ORDER BY cohort_start_date DESC
LIMIT 50;