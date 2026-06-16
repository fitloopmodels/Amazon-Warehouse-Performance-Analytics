-- ============================================================
-- Amazon Warehouse Analytics - Schema Creation
-- Database: PostgreSQL / MySQL compatible
-- ============================================================

-- Drop tables if they exist (safe re-run)
DROP TABLE IF EXISTS returns;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS products;

-- ── 1. Products ──────────────────────────────────────────────
CREATE TABLE products (
    product_id       VARCHAR(10)    PRIMARY KEY,
    product_name     VARCHAR(100)   NOT NULL,
    category         VARCHAR(50)    NOT NULL,
    subcategory      VARCHAR(50),
    supplier_id      VARCHAR(10),
    unit_cost        DECIMAL(10,2)  NOT NULL,
    unit_price       DECIMAL(10,2)  NOT NULL,
    weight_kg        DECIMAL(6,2),
    rating           DECIMAL(3,1),
    is_active        TINYINT(1)     DEFAULT 1,
    CONSTRAINT chk_price CHECK (unit_price >= unit_cost)
);

-- ── 2. Employees ─────────────────────────────────────────────
CREATE TABLE employees (
    employee_id       VARCHAR(10)   PRIMARY KEY,
    employee_name     VARCHAR(100)  NOT NULL,
    role              VARCHAR(50)   NOT NULL,
    warehouse_id      VARCHAR(20),
    shift             VARCHAR(20),
    hire_date         DATE,
    salary            DECIMAL(10,2),
    orders_handled    INT           DEFAULT 0,
    error_rate        DECIMAL(6,4),
    attendance_rate   DECIMAL(5,4),
    performance_score DECIMAL(3,2)
);

-- ── 3. Orders ────────────────────────────────────────────────
CREATE TABLE orders (
    order_id                VARCHAR(12)   PRIMARY KEY,
    product_id              VARCHAR(10)   NOT NULL,
    customer_id             VARCHAR(12)   NOT NULL,
    employee_id             VARCHAR(10),
    order_date              DATE          NOT NULL,
    ship_date               DATE,
    delivery_date           DATE,
    promised_delivery_date  DATE,
    on_time_delivery        TINYINT(1)    DEFAULT 0,
    quantity                INT           NOT NULL,
    unit_price              DECIMAL(10,2) NOT NULL,
    revenue                 DECIMAL(12,2) NOT NULL,
    order_status            VARCHAR(20)   NOT NULL,
    region                  VARCHAR(20),
    sales_channel           VARCHAR(20),
    processing_time_hours   DECIMAL(6,2),
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- ── 4. Inventory ─────────────────────────────────────────────
CREATE TABLE inventory (
    inventory_id      VARCHAR(12)   PRIMARY KEY,
    product_id        VARCHAR(10)   NOT NULL,
    warehouse_id      VARCHAR(20)   NOT NULL,
    stock_quantity    INT           DEFAULT 0,
    reorder_level     INT           DEFAULT 100,
    max_stock_level   INT,
    last_restock_date DATE,
    days_in_stock     INT,
    stock_status      VARCHAR(20),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ── 5. Returns ───────────────────────────────────────────────
CREATE TABLE returns (
    return_id          VARCHAR(12)   PRIMARY KEY,
    order_id           VARCHAR(12)   NOT NULL,
    product_id         VARCHAR(10)   NOT NULL,
    customer_id        VARCHAR(12)   NOT NULL,
    return_date        DATE,
    return_reason      VARCHAR(100),
    refund_type        VARCHAR(30),
    refund_amount      DECIMAL(10,2),
    restocking_fee     DECIMAL(6,2)  DEFAULT 0,
    condition_on_return VARCHAR(20),
    processed_by       VARCHAR(10),
    FOREIGN KEY (order_id)    REFERENCES orders(order_id),
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    FOREIGN KEY (processed_by) REFERENCES employees(employee_id)
);

-- ── Indexes for performance ───────────────────────────────────
CREATE INDEX idx_orders_date        ON orders(order_date);
CREATE INDEX idx_orders_status      ON orders(order_status);
CREATE INDEX idx_orders_product     ON orders(product_id);
CREATE INDEX idx_orders_employee    ON orders(employee_id);
CREATE INDEX idx_orders_region      ON orders(region);
CREATE INDEX idx_inventory_product  ON inventory(product_id);
CREATE INDEX idx_inventory_wh       ON inventory(warehouse_id);
CREATE INDEX idx_returns_order      ON returns(order_id);
CREATE INDEX idx_returns_product    ON returns(product_id);
CREATE INDEX idx_returns_reason     ON returns(return_reason);
