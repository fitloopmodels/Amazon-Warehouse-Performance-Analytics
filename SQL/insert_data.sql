-- ============================================================
-- Amazon Warehouse Analytics - Data Loading Instructions
-- ============================================================
-- The dataset CSVs are in the /Dataset folder.
-- Use the commands below matching your database.
-- ============================================================

-- ── MySQL / MariaDB ──────────────────────────────────────────
/*
LOAD DATA INFILE '/path/to/Dataset/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/path/to/Dataset/employees.csv'
INTO TABLE employees
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/path/to/Dataset/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/path/to/Dataset/inventory.csv'
INTO TABLE inventory
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/path/to/Dataset/returns.csv'
INTO TABLE returns
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
*/

-- ── PostgreSQL ───────────────────────────────────────────────
/*
\COPY products   FROM 'Dataset/products.csv'   CSV HEADER;
\COPY employees  FROM 'Dataset/employees.csv'  CSV HEADER;
\COPY orders     FROM 'Dataset/orders.csv'     CSV HEADER;
\COPY inventory  FROM 'Dataset/inventory.csv'  CSV HEADER;
\COPY returns    FROM 'Dataset/returns.csv'    CSV HEADER;
*/

-- ── SQLite (via Python) ──────────────────────────────────────
/*
import pandas as pd, sqlite3
conn = sqlite3.connect('warehouse.db')
for tbl in ['products','employees','orders','inventory','returns']:
    pd.read_csv(f'Dataset/{tbl}.csv').to_sql(tbl, conn, if_exists='replace', index=False)
conn.close()
*/

-- ── Quick row-count validation after loading ─────────────────
SELECT 'products'  AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'employees',                COUNT(*)              FROM employees
UNION ALL
SELECT 'orders',                   COUNT(*)              FROM orders
UNION ALL
SELECT 'inventory',                COUNT(*)              FROM inventory
UNION ALL
SELECT 'returns',                  COUNT(*)              FROM returns;
