-- =========================================================================
-- FILE 4: 13_security_grants.sql
-- DESCRIPTION: Database users, roles, and GRANT statements for OmniCartDB.
-- =========================================================================

-- Security Model:
-- 1. omnicart_app: Used by the application (e.g. Spring Boot) to interact with the DB. Needs read/write access to most tables but restrictive permissions on audit tables (PriceLedger). No schema alteration.
-- 2. omnicart_readonly: For reporting tools, data analysts. Only SELECT permissions.
-- 3. omnicart_admin: Full DBA rights to manage schema, permissions, backups.
-- Note: Passwords provided here are examples. In production, utilize environment variables and strong secrets.

USE OmniCartDB;

-- ==========================================
-- 1. Create Application User (omnicart_app)
-- ==========================================
CREATE USER IF NOT EXISTS 'omnicart_app'@'%' IDENTIFIED BY 'AppSecurePass2024!';

-- General data manipulation permissions
GRANT SELECT, INSERT, UPDATE ON OmniCartDB.Customer TO 'omnicart_app'@'%';
GRANT SELECT, INSERT, UPDATE ON OmniCartDB.CustomerPhone TO 'omnicart_app'@'%';
GRANT SELECT, INSERT, UPDATE ON OmniCartDB.CustomerEmail TO 'omnicart_app'@'%';
GRANT SELECT, INSERT, UPDATE ON OmniCartDB.Address TO 'omnicart_app'@'%';
GRANT SELECT, INSERT, UPDATE ON OmniCartDB.Seller TO 'omnicart_app'@'%';
GRANT SELECT, INSERT, UPDATE ON OmniCartDB.Category TO 'omnicart_app'@'%';
GRANT SELECT, INSERT, UPDATE ON OmniCartDB.Product TO 'omnicart_app'@'%';
GRANT SELECT, INSERT, UPDATE ON OmniCartDB.ProductEmbeddings TO 'omnicart_app'@'%';
GRANT SELECT, INSERT, UPDATE ON OmniCartDB.Orders TO 'omnicart_app'@'%';
GRANT SELECT, INSERT, UPDATE ON OmniCartDB.OrderPayment TO 'omnicart_app'@'%';

-- Tables needing full DML including DELETE for order/product management
GRANT SELECT, INSERT, UPDATE, DELETE ON OmniCartDB.OrderDetails TO 'omnicart_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON OmniCartDB.ProductImage TO 'omnicart_app'@'%';

-- PriceLedger is append-only for auditing/immutability
GRANT SELECT, INSERT ON OmniCartDB.PriceLedger TO 'omnicart_app'@'%';

-- Select only on reference tables
GRANT SELECT ON OmniCartDB.AddressType TO 'omnicart_app'@'%';
GRANT SELECT ON OmniCartDB.ShippingStatus TO 'omnicart_app'@'%';
GRANT SELECT ON OmniCartDB.PaymentMethod TO 'omnicart_app'@'%';
GRANT SELECT ON OmniCartDB.PriceLedgerSource TO 'omnicart_app'@'%';

-- Access to Views and Stored Routines
GRANT SELECT ON OmniCartDB.* TO 'omnicart_app'@'%'; -- Allow select on views (could restrict to specific views if desired)
GRANT EXECUTE ON OmniCartDB.* TO 'omnicart_app'@'%';


-- ==========================================
-- 2. Create Read-Only User (omnicart_readonly)
-- ==========================================
CREATE USER IF NOT EXISTS 'omnicart_readonly'@'%' IDENTIFIED BY 'ReadOnlyPass2024!';

-- Global SELECT on all tables and views
GRANT SELECT ON OmniCartDB.* TO 'omnicart_readonly'@'%';

-- Execute on specific read-only functions
GRANT EXECUTE ON FUNCTION OmniCartDB.fn_get_current_product_price TO 'omnicart_readonly'@'%';
GRANT EXECUTE ON FUNCTION OmniCartDB.fn_calculate_order_total TO 'omnicart_readonly'@'%';
GRANT EXECUTE ON FUNCTION OmniCartDB.fn_customer_order_count TO 'omnicart_readonly'@'%';
GRANT EXECUTE ON FUNCTION OmniCartDB.fn_customer_total_spent TO 'omnicart_readonly'@'%';
GRANT EXECUTE ON FUNCTION OmniCartDB.fn_product_stock_status TO 'omnicart_readonly'@'%';


-- ==========================================
-- 3. Create DBA User (omnicart_admin)
-- ==========================================
CREATE USER IF NOT EXISTS 'omnicart_admin'@'%' IDENTIFIED BY 'AdminSecurePass2024!';

-- All privileges on the specific database
GRANT ALL PRIVILEGES ON OmniCartDB.* TO 'omnicart_admin'@'%';

-- Apply privileges
FLUSH PRIVILEGES;
