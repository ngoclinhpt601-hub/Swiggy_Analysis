# SQL Project: Swiggy Food Delivery Analysis

## 🎯 Project Objective
This project analyzes food delivery transactions from Swiggy to evaluate restaurant performance, customer demand, and revenue trends. The goal was to design a robust SQL data pipeline, clean and structure the dataset, and generate actionable insights for business decision-making.

## ⚙️ Process
1. **Data Cleaning & Validation**
   - Checked for nulls and empty strings using dynamic SQL.
   - Detected and removed duplicates with CTE + `ROW_NUMBER()`.
   - Standardized categorical values (state, city, restaurant, category, dish).

2. **Schema Design (Star Schema)**
   - Built dimension tables: `dim_date`, `dim_location`, `dim_restaurant`, `dim_category`, `dim_dish`.
   - Created fact table `fact_swiggy_orders` with foreign keys linking to dimensions.
   - Inserted cleaned data into dimensions and fact table for efficient querying.

3. **SQL Techniques Applied**
   - `JOIN`, `CTE`, `Window Functions`, `CASE WHEN`, `STRING_AGG`, and dynamic queries.
   - Aggregations for KPIs: total orders, revenue, average price, average rating.
   - Segmentation by time, location, restaurant, category, dish, and price range.

## 📊 Key Results
- **Overall KPIs**: Total orders, total revenue (in INR millions), average dish price, and average rating.
- **Time Trends**: Monthly, quarterly, and yearly order/revenue trends; weekday order distribution.
- **Geographic Insights**: Top 10 cities by orders and revenue; state-level revenue contribution.
- **Restaurant & Cuisine Performance**: Top 10 restaurants by revenue; category performance with average ratings.
- **Customer Behavior**: Most ordered dishes, preferred price ranges, and rating distribution.

## 📈 Business Insights
- **Seasonality**: Clear monthly and quarterly peaks → supports inventory and staffing planning.
- **Geographic Focus**: Certain cities and states dominate revenue → prioritize marketing in high-performing regions.
- **Restaurant Strategy**: Top restaurants drive significant revenue → strengthen partnerships and promotions.
- **Cuisine Preferences**: Categories with high orders and strong ratings → expand offerings in popular cuisines.
- **Customer Segmentation**: Price range and rating analysis → tailor promotions to budget segments and improve quality where ratings lag.

## 🛠️ Tools & Technologies
- SQL Server 2022  
- Swiggy food delivery dataset (CSV)  
- GitHub for version control and documentation  
