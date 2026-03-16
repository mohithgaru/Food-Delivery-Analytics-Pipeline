# 🍔 The Delivery Engine: From Raw Clicks to Real-Time Business Insights

![Domain](https://img.shields.io/badge/Domain-Food_Tech_%26_Delivery-FF4B4B)
![Role](https://img.shields.io/badge/Role-Product_Analyst_%2F_Data_Engineer-2E86C1)
![Tech](https://img.shields.io/badge/Tech_Stack-MySQL_8.0_%7C_Advanced_SQL-F39C12)

---

## 🎬 The Prologue: Blind Spots in the Data Maze

Imagine a high-speed food delivery platform. **300,000 users** are clicking, scrolling, and ordering every day. It's millions of events. But the business had no central "command center."

* They couldn't see exactly where users were dropping off in the checkout process.
* They couldn't track long-term loyalty for a specific week's signups.
* Most dangerously, they had no automated system to flag app outages or traffic failures, causing them to lose revenue by the minute.

This project is the solution: **The modularization of a complex 4,500-line analytical engine into a five-stage automated pipeline** that turns messy clickstream events into clean, actionable, data-backed business strategy.

---

## 🗺️ Chapter 1: The New Analytical Blueprint

A monolithic, messy 4,500-line SQL script is a maintenance nightmare. A professional repository is modular. I refactored the entire project into a clean, sequential flow of 5 directories, treating each stage as a crucial component of a larger machine.

### 🗂️ The Repository Architecture



* `01_Data_Ingestion_and_QA/`
* `02_Session_and_Funnel_Analysis/`
* `03_Weekly_Cohort_Retention/`
* `04_User_Segmentation/`
* `05_Anomaly_Detection_and_Alerts/`

---

## 📖 Chapter 2: The Data Journey (Stage by Stage)

We will now follow the path of a raw event as it is processed by the five SQL engine rooms.

### ⚓ STEP A–E: Foundations & Data Quality (01_Data_Ingestion_and_QA)

Before analysis can begin, the environment must be structured and verified. This initial script constructs the database schema, loads raw CSV files, executes `DATETIME` creation, and runs crucial performance-enhancing indexing (STEP E).

* **Inputs:** Messy CSVs (`events.csv`, `orders.csv`).
* **Outputs:** 4 Structured, Quality-Verified tables (`users`, `restaurants`, `events`, `orders`).

### 🧑‍💻 STEP F: Reconstructing the User Journey (02_Session_and_Funnel_Analysis)

Raw event logs are just "scatters of clicks." In STEP F, we perform complex sessionization to build logical user sessions. This is the **most technically complex stage** of the pipeline, utilizing trailing `LAG()` functions to apply a **30-minute inactivity rule.** If a user goes silent for 30 minutes, their next action starts a new `session_id`.



* **Output 1: `user_first_stages`** - A canonical timeline that only records the *absolute first time* a unique user reached each stage of the funnel, eliminating duplicated event noise.
* **Output 2: `funnel_summary`** - The primary analytical product. A grid of the canonical conversion steps: Homepage → Browse → Add to Cart → **Checkout** → Payment → Confirmation.

We now have visibility. We can see the drops.

### 👥 STEP F.4 & G: The Economics of Loyalty (03_Weekly_Cohort_Retention)

Funnel conversion is about initial acquisition. Cohort analysis is about long-term survival. In STEP F.4 and STEP G, we use massive SQL pivot tables to group users by signup week. We track their activity for eight consecutive weeks, transforming hundreds of dates into a fixed, readable grid.



* **Outputs: `cohort_weekly_retention`** - A table showing the Week 0 to Week 8 retention for every cohort, allowing us to immediately see if new features or ad campaigns are improving loyalty over time.

### 📊 STEP G (Cont.): Slicing by Demographics (04_User_Segmentation)

The numbers we calculated in previous stages are averages, and averages can lie. The best business strategy comes from segmentation. In STEP G, we take the raw outputs from Funnel and Retention and slice them by Device, Acquisition Channel, Gender, Age Group, and City.

* **Outputs:** `segment_funnel_summary`, `segment_revenue_summary`, `segment_retention_summary`.
* **Purpose:** Prove *which* users are our economic engines, allowing the business to reallocate marketing spend intelligently.

### 🚨 STEP H: The Automated Watchdog (05_Anomaly_Detection_and_Alerts)

This final, mature script moves from description to automated monitoring. We use complex SQL window functions (`ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING`) to calculate dynamic, trailing 7-day baselines for all key metrics. If today's data deviates more than +/- 25%, it is automatically labeled a `SPIKE` or a `DROP`.



* **Outputs: `insights_summary`** - This is the "Product Feed." A human-readable alert table of real-time insights sorted by severity. A "HIGHT DROP" in events for Pune on Jan 12th might indicate a local internet failure or a serious app outage that requires immediate investigation. This table transforms reactive firefighting into proactive engineering.

---

## 🏆 The Denouement: Top Actionable Business Insights

By building and refactoring this 4,500-line pipeline, the business uncovered three massive operational blind spots:

1.  **The Checkout Dropout:** Funnel conversion drops significantly at the **Checkout → Payment** stage (**45.20% drop-off**). *Product Recommendation:* Immediate UX audit of delivery fee transparency and the payment gateway reliability to recapture lost revenue.
2.  **Acquisition Misallocation:** Users acquired via **Instagram** show the best Week 1 retention (44.24%). *Product Recommendation:* Scale ad spend for Instagram campaigns targeting 25–34-year-olds (our highest revenue segment).
3.  **App Outage Detected:** The anomaly engine flagged a catastrophic tracking failure on June 28th, resulting in **0.00% retention** for an entire daily cohort, which went completely unnoticed by the manual dashboard reports.

---

## 🛠️ Key SQL Concepts Demonstrated

* **Complex Sessionization:** Reconstructing logical sessions from raw clickstreams.
* **Trailing Window Functions:** `AVG(...) OVER(PARTITION BY... ORDER BY... ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING)` for real-time statistical baselines.
* **Canonical Funnel Mapping:** Using unique, fixed event timelines to calculate non-duplicated conversion.
* **Cohort Analysis Pivots:** Transforming date lists into fixed Week-x grids.

---

## 📄 Full Documentation

For a complete breakdown of methodology, data quality checks, row counts, and professional product recommendations, see the [Full Analytics Documentation (PDF)](./docs/Analytics_Documentation.pdf) included in this repository.

*(Note to User: Remember to save your completed Word document as a PDF and put it in the `docs/` folder!)*
