# 🍔 Unlocking the Delivery App: Turning Raw Clicks into Revenue

<div align="center">
  <img src="https://via.placeholder.com/800x400/1a1a1a/ff4b4b?text=+[Insert+Animated+GIF+of+Your+Dashboard+Here]+" alt="Dashboard Animation" />
</div>

<br>

<div align="center">
  <img src="https://img.shields.io/badge/SQL-Advanced%20MySQL%208.0-F39C12?style=for-the-badge&logo=mysql&logoColor=white" />
  <img src="https://img.shields.io/badge/Focus-Product%20Analytics-2E86C1?style=for-the-badge&logo=googleanalytics&logoColor=white" />
  <img src="https://img.shields.io/badge/Status-Pipeline%20Deployed-27AE60?style=for-the-badge&logo=checkmarx&logoColor=white" />
</div>

---

## 💡 Why I Built This (The "Aha!" Moment)

Imagine you run a massive food delivery app. Today, 300,000 people opened your app. Some looked at burgers, some added pizza to their cart, and some actually paid. 

The problem? **Businesses drown in this data but starve for clarity.** If the checkout page breaks, or if a specific city's orders suddenly drop by 50%, the company usually finds out *days* later when the revenue report looks bad. By then, the money is gone. 

I built this 5-stage automated SQL pipeline to solve that exact problem. I wanted to take chaotic, messy data and turn it into a **living, breathing command center** that tells the business exactly what is broken, who our best customers are, and where we are losing money.

---

## 🧱 The Raw Materials (What Went In)
Before we can cook, we need groceries. The pipeline starts with 4 massive, raw CSV files. 

| Raw Table | What's Inside? (Key Columns) | Why It Matters |
| :--- | :--- | :--- |
| 🧑‍🦱 `users` | `user_id`, `age`, `gender`, `city`, `acquisition_channel` | Tells us *who* the customer is. |
| 🏪 `restaurants` | `restaurant_id`, `city`, `category` | Tells us *what* they are buying. |
| 🖱️ `events` | `user_id`, `event_type`, `event_datetime` | The digital footprints. Every single click. |
| 💳 `orders` | `order_id`, `user_id`, `order_amount`, `order_status` | The actual money being made. |

📂 **See the Foundation:** Check out [`01_Data_Ingestion_and_QA/sql/01_schema_and_qa.sql`](./01_Data_Ingestion_and_QA/sql/01_schema_and_qa.sql) to see how I built the schema, cleaned the datetimes, and set up the structural indexes.

---

## 🗺️ Stage 2: The Funnel (Connecting the Dots)
**The Concept:** On an app, you just see a database of isolated clicks. I built a "Session Engine" that assumes if a user goes quiet for 30 minutes, they left the app. This groups their random clicks into a logical "Visit." Then, I mapped their exact journey: `Homepage ➡️ View Menu ➡️ Add to Cart ➡️ Checkout ➡️ Payment.`

* **The Impact:** I discovered that over **54% of users abandon their carts at Checkout.** Now the product team knows *exactly* which screen to fix to instantly boost revenue.

<div align="center">
  <img src="https://via.placeholder.com/600x300/f4f4f4/333333?text=+[Insert+Funnel+Drop-off+Chart+Here]+" alt="Funnel Chart" />
</div>

📂 **Dive into the Code:** See how I used complex `LAG()` window functions to build the session engine in [`02_Session_and_Funnel_Analysis/sql/02_funnel_engine.sql`](./02_Session_and_Funnel_Analysis/sql/02_funnel_engine.sql).

---

## 🤝 Stage 3: Cohort Retention (The Loyalty Test)
**The Concept:** Retention asks: *If 100 people signed up in January, how many are still ordering food in March?* I used complex SQL pivot logic to track users for 8 full weeks after their first order.

* **The Impact:** We can now see if a new marketing campaign actually brought in loyal customers, or just people who used a promo code once and never came back.

📂 **Dive into the Code:** Check out the massive pivot tables tracking Week 0 to Week 8 loyalty in [`03_Cohort_Retention/sql/03_weekly_cohorts.sql`](./03_Cohort_Retention/sql/03_weekly_cohorts.sql).

---

## 🎯 Stage 4: Segmentation (Knowing the VIPs)
**The Concept:** Averages are dangerous. I sliced the funnel and revenue data by age, device, city, and how they found the app (Instagram vs. Google). 

* **The Impact:** I found that users aged 25-34 acquired via Instagram are our absolute VIPs. The marketing team can now stop wasting ad money on generic channels and double down on Instagram.

📂 **Dive into the Code:** See how I broke down conversion rates by demographics in [`04_User_Segmentation/sql/04_segmentation.sql`](./04_User_Segmentation/sql/04_segmentation.sql).

---

## 🚨 Stage 5: Anomaly Detection (The Smoke Alarm)
**The Concept:** Anomaly detection is a digital smoke alarm. I wrote a SQL engine that calculates a "rolling 7-day average" for our app's traffic. Every single day, the engine checks: *Is today's traffic normal compared to last week?* If it drops by more than 25%, the system throws a red flag.

* **The Impact:** This transforms a data team from "historians" into "first responders." Instead of staring at charts, the CEO gets a feed that says: 🔴 **HIGH ALERT:** `Checkout events dropped by 45% in Pune on June 28th.`

<div align="center">
  <img src="https://via.placeholder.com/600x300/ffeaea/ff0000?text=+[Insert+Anomaly+Spike/Drop+Chart+Here]+" alt="Anomaly Chart" />
</div>

📂 **Dive into the Code:** See the dynamic trailing window baselines in action in [`05_Anomaly_Detection_and_Alerts/sql/05_anomaly_engine.sql`](./05_Anomaly_Detection_and_Alerts/sql/05_anomaly_engine.sql).

---

## 👨‍💻 About the Author: Mohith
This project bridges the gap between raw data and executive decision-making. With a background blending a **B.Com & MBA** with a **Data Analyst Internship**, my goal is never just to write code—it's to solve business problems. 

**Tech Stack Used:** SQL, Python, Power BI, Tableau, Excel. 
*Check out the `docs/` folder for my full PDF report on UX and Strategy recommendations based on these findings.*
