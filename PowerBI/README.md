# Power BI Dashboard

## File
`Warehouse_Dashboard.pbix` — built in Power BI Desktop (June 2024+).

## Setup
1. Open the `.pbix` file in Power BI Desktop.
2. Go to **Home → Transform Data → Data Source Settings**.
3. Update the path to point to your local `../Dataset/` folder.
4. Click **Refresh** to load the data.

## Dashboard Pages

### Page 1 — Executive Summary
- KPI cards: Total Orders, Revenue, On-Time Delivery %, Avg Processing Time, Return Rate
- Monthly revenue trend line chart
- Revenue by region map visual
- Order status donut chart

### Page 2 — Delivery & Fulfillment
- On-time delivery % by region (bar chart with target line)
- On-time delivery % by sales channel
- Processing time distribution histogram
- Delay days scatter plot

### Page 3 — Inventory Management
- Inventory status breakdown by warehouse (stacked bar)
- Stock level heatmap (warehouse × category)
- Top 20 products below reorder level (table)
- Inventory turnover rate by category

### Page 4 — Employee Productivity
- Orders handled per employee (bar chart)
- Performance score distribution (histogram)
- Error rate vs. performance scatter
- Shift comparison (morning / afternoon / night)

### Page 5 — Returns Analysis
- Return rate by category (bar chart)
- Return reasons breakdown (pie chart)
- Monthly return trend vs. order volume
- Refund amount by return condition (table)

## DAX Measures Used
```dax
On-Time Delivery % = 
    DIVIDE(
        COUNTROWS(FILTER(orders, orders[on_time_delivery] = 1)),
        COUNTROWS(orders)
    ) * 100

Return Rate % = 
    DIVIDE(COUNTROWS(returns), COUNTROWS(orders)) * 100

Avg Processing Time = 
    AVERAGE(orders[processing_time_hours])

Gross Profit = 
    SUMX(orders, orders[revenue] - (RELATED(products[unit_cost]) * orders[quantity]))

Inventory Turnover = 
    DIVIDE(
        SUM(orders[quantity]),
        AVERAGE(inventory[stock_quantity])
    )
```
