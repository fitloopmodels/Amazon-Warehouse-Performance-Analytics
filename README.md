# 📦 Amazon Warehouse Performance Analytics

![SQL](https://img.shields.io/badge/SQL-MySQL%20%7C%20PostgreSQL-blue?logo=mysql)
![Python](https://img.shields.io/badge/Python-3.10%2B-yellow?logo=python)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-orange?logo=powerbi)
![Records](https://img.shields.io/badge/Records-100%2C000%2B-green)

---

## Project Overview

End-to-end warehouse analytics project that simulates an Amazon fulfillment center's operations. The goal is to evaluate **operational efficiency**, **inventory health**, **delivery performance**, and **return patterns** across 100,000+ orders using SQL, Python, and Power BI.

---

## Business Questions Answered

| # | Question |
|---|----------|
| 1 | What is the on-time delivery rate by region and sales channel? |
| 2 | Which product categories drive the most revenue and margin? |
| 3 | Where are the inventory bottlenecks (stockouts vs. overstock)? |
| 4 | Which employees and shifts are most productive? |
| 5 | What are the top causes of returns and their financial impact? |
| 6 | How does order volume and revenue trend month over month? |
| 7 | How can we segment customers by purchasing behavior? |

---

## Dataset

| File | Rows | Description |
|------|------|-------------|
| `orders.csv` | 100,000 | Order transactions with dates, revenue, status, region |
| `products.csv` | 500 | Product catalog with category, cost, price, rating |
| `inventory.csv` | 2,500 | Stock levels per warehouse per product |
| `employees.csv` | 200 | Staff records with performance metrics |
| `returns.csv` | ~8,000 | Return records with reason and refund details |

> All data is synthetically generated with realistic distributions using NumPy/Pandas.

---

## Tools & Technologies

| Layer | Tool | Purpose |
|-------|------|---------|
| Data Generation | Python (Pandas, NumPy) | Synthetic dataset creation |
| Data Cleaning | Python (Pandas) | Null handling, type casting, derived columns |
| EDA | Python (Matplotlib, Seaborn) | Trend and distribution analysis |
| Analysis | SQL (MySQL / PostgreSQL) | Aggregations, CTEs, window functions |
| Visualization | Power BI | Interactive KPI dashboard |

---

## Project Structure

```
Amazon-Warehouse-Analytics/
│
├── Dataset/
│   ├── orders.csv              # 100K order transactions
│   ├── products.csv            # 500 product records
│   ├── inventory.csv           # Stock levels (5 warehouses × 500 SKUs)
│   ├── employees.csv           # 200 employee records
│   └── returns.csv             # ~8K return records
│
├── SQL/
│   ├── create_tables.sql       # Schema creation with indexes
│   ├── insert_data.sql         # Data loading instructions
│   └── analysis_queries.sql   # 20+ analysis queries
│
├── Python/
│   ├── data_cleaning.ipynb     # Cleaning, validation, feature engineering
│   └── eda.ipynb               # EDA with 10+ visualizations
│
├── PowerBI/
│   └── Warehouse_Dashboard.pbix  # Interactive Power BI dashboard
│
├── screenshots/                # Chart exports from EDA notebook
└── README.md
```

---

## SQL Techniques Used

- `JOIN` across 5 tables
- `GROUP BY` with multi-level aggregations
- `CTEs` (`WITH` clauses) for readable multi-step logic
- **Window functions**: `RANK()`, `LAG()`, `SUM() OVER()`, `AVG() OVER()`
- Conditional aggregation with `CASE WHEN`
- Date arithmetic for delay and processing time calculations
- Subqueries and derived tables

---

## Key SQL Analyses

| Query | Technique |
|-------|-----------|
| Monthly revenue with MoM growth | `LAG()` window function |
| Employee performance leaderboard | `RANK() OVER(PARTITION BY ...)` |
| Running revenue total + 7-day MA | `SUM/AVG OVER(ROWS BETWEEN ...)` |
| Customer RFM segmentation | CTE + `CASE WHEN` |
| Warehouse efficiency scorecard | Composite metric with CTE |
| Inventory turnover rate | Multi-table join + aggregation |
| Pareto analysis of revenue by region | Cumulative `SUM OVER()` |

---

## Python EDA Highlights

- Missing value analysis and outlier detection (IQR method)
- Date consistency validation (ship before order, delivery before ship)
- Feature engineering: `delay_days`, `margin_pct`, `tenure_years`, `utilization_pct`
- **Charts generated:**
  - Monthly revenue trend (bar + line dual-axis)
  - Revenue by product category (horizontal bar)
  - On-time delivery rate by region (color-coded vs. target)
  - Order status distribution (pie + bar)
  - Processing time distribution by sales channel (histogram + box plot)
  - Inventory heatmap (warehouse × category)
  - Return reasons (horizontal bar)
  - Employee performance scatter plot
  - Correlation matrix (lower triangle)

---

## Power BI Dashboard — KPIs

| KPI | Description |
|-----|-------------|
| Total Orders | Count of all orders |
| Total Revenue | Sum of revenue (non-cancelled) |
| On-Time Delivery % | % delivered by promised date |
| Avg Processing Time | Mean hours from order to ship |
| Inventory Turnover | Units sold / avg stock |
| Return Rate % | Returns / total orders |

**Dashboard Pages:**
1. Executive Summary
2. Delivery & Fulfillment
3. Inventory Management
4. Employee Productivity
5. Returns Analysis

---

## Key Findings

1. **On-Time Delivery** varies significantly by region — the lowest-performing region is 12pp below the 80% target.
2. **Electronics and Home & Kitchen** account for ~38% of total revenue.
3. **~9% of SKU-warehouse combinations** are out of stock, risking lost sales.
4. **"Defective Product"** is the leading return reason — signals a QC gap upstream.
5. **Night shift** processes the highest order volume per employee.
6. **Processing time outliers** (>24h) are concentrated in the B2B sales channel.

---

## How to Run

### 1. Python
```bash
pip install pandas numpy matplotlib seaborn jupyter
cd Python
jupyter notebook data_cleaning.ipynb
jupyter notebook eda.ipynb
```

### 2. SQL
```bash
# Load schema
mysql -u root -p warehouse_db < SQL/create_tables.sql

# Load data (follow instructions in insert_data.sql)
# Run analysis
mysql -u root -p warehouse_db < SQL/analysis_queries.sql
```

### 3. Power BI
Open `PowerBI/Warehouse_Dashboard.pbix` in Power BI Desktop.
Update the data source path to your local `Dataset/` folder and refresh.

---


