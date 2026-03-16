# 🍔 Food Delivery App: Automated Analytics & Anomaly Detection Pipeline

![Domain](https://img.shields.io/badge/Domain-Food_Tech_%26_Delivery-FF4B4B)
![Role](https://img.shields.io/badge/Role-Product_Analyst_%2F_Data_Engineer-2E86C1)
![Tech](https://img.shields.io/badge/Tech_Stack-MySQL_8.0_%7C_Advanced_SQL-F39C12)

## 📌 The Business Problem
A food delivery platform was generating millions of rows of clickstream events and transactions, but the data was siloed. The business lacked a unified view of the user journey. They could not definitively answer:
1. Where are users dropping off before paying?
2. Which user segments are actually driving long-term revenue?
3. How quickly can we detect an app outage or a localized surge in orders?

**The Solution:** This project transforms a massive, raw data dump into a 5-stage automated SQL pipeline. It reconstructs sessions, maps conversion funnels, tracks 8-week cohorts, and deploys a statistical anomaly detection engine to flag real-time business risks.

---

## 🗂️ The Data Lineage: From Raw CSVs to Business Insights

The entire pipeline is built on a foundation of **4 Raw Input Tables** loaded directly from CSVs, which are then processed to create highly specialized **Derived Tables** for analytics.



### 1️⃣ Data Ingestion & Setup (`01_Data_Ingestion_and_QA`)
* **The Input:** 4 raw CSV files.
* **The Process:** We create the foundational database schema and load the data. To enable time-series analysis, we concatenate separate `DATE` and `TIME` columns into robust `DATETIME` columns and build composite indexes for query optimization.
* **The Output:** 4 clean, indexed base tables: `users`, `restaurants`, `events`, and `orders`.

### 2️⃣ Session & Funnel Engine (`02_Session_and_Funnel_Analysis`)
* **The Input:** Base tables (`events`, `orders`, `users`).
* **The Why:** Raw clicks are meaningless without context. We need to group clicks into logical "visits" and see exactly when a user hits a specific funnel stage (Browse → View Menu → Cart → Checkout → Pay).
* **The Process:** * Uses window functions (`LAG()`) to apply a **30-minute inactivity rule**, generating unique session IDs.
    * Uses `MIN(CASE WHEN...)` to extract the *canonical* (absolute first) timestamp a user reached each funnel stage.
* **The Output (Derived Tables):**
    * `user_first_stages`: A flattened timeline of exactly when each user hit each stage.
    * `funnel_summary`: Aggregated conversion percentages.
    * `time_to_step_stats`: The median time it takes users to move between stages.



### 3️⃣ Cohort Retention (`03_Weekly_Cohort_Retention`)
* **The Input:** `users` (signup dates) and `events` (activity dates).
* **The Why:** To measure product stickiness. Are users coming back after their first week? 
* **The Process:** Groups users by their signup week (Monday start) and uses conditional aggregation to calculate the percentage of those users who return to the app in Weeks 1 through 8.
* **The Output (Derived Table):** `cohort_weekly_retention` (The definitive 8-week loyalty matrix).



### 4️⃣ User Segmentation (`04_User_Segmentation`)
* **The Input:** Derived tables (`user_first_stages`, base `users`, `orders`).
* **The Why:** High-level averages hide the truth. We need to know if iOS users convert better than Android users, or if Instagram brings in more valuable customers than Organic Search.
* **The Process:** Joins demographic and acquisition data to the funnel and revenue logic, slicing the metrics into distinct categories.
* **The Output (Derived Tables):** * `segment_funnel_summary`
    * `segment_revenue_summary`
    * `segment_retention_summary`

### 5️⃣ Anomaly Detection Engine (`05_Anomaly_Detection_and_Alerts`)
* **The Input:** All historical event and order data.
* **The Why:** The business needs to move from reactive to proactive. If checkout conversion drops by 30% today, the product team needs to know immediately, not next week.
* **The Process:** * Calculates a dynamic **7-day trailing baseline** (`AVG() OVER(ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING)`).
    * Compares today's actuals against the baseline. Flags a `SPIKE` if deviation is > +30%, and a `DROP` if < -25%.
* **The Output (Derived Tables):**
    * `daily_activity_metrics` & `daily_baselines`.
    * `daily_anomaly_flags`: The automated alerts.
    * `insights_summary`: A human-readable feed of the most critical spikes, drops, and bottlenecks, sorted by severity.



---

## 🏆 Core Business Findings

By running this pipeline, the `insights_summary` table generated three critical, data-backed findings for the business:

1.  **The Checkout Bottleneck:** The largest friction point in the user journey is the Checkout-to-Payment stage. Over **54%** of users abandon their carts after initiating checkout (Only 45.2% complete payment).
2.  **The "Golden" Demographic:** The 25–34 age demographic is the primary economic driver, and users acquired via Instagram exhibit the highest overall Week-1 retention (44.24%). 
3.  **Automated Incident Detection:** The anomaly engine successfully flagged a localized +3,699% revenue spike in Pune, as well as a catastrophic tracking drop for the 2023-W26 cohort, proving the alerting system works.

---

## 🛠️ Technical Implementation
* **Language:** Advanced MySQL 8.0
* **Key Functions:** `LAG()`, `SUM() OVER()`, Conditional Aggregation (`SUM(CASE WHEN...)`), Composite Indexing, Rolling Window Functions, Common Table Expressions (CTEs).
* **Full Documentation:** See the `docs/` folder for comprehensive QA checks, row counts, and detailed UX recommendations.
