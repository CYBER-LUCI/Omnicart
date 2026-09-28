/*
 * OmniCart Marketplace Database
 * File: 06_functions.sql
 * Description: Defines all stored functions for the database.
 * Author: OmniCart Database Architect
 */

USE OmniCartDB;

DELIMITER $$

-- =====================================================================
-- Function: fn_get_current_product_price
-- Parameters: p_product_id (BIGINT UNSIGNED)
-- Returns: DECIMAL(12,2)
-- Characteristics: DETERMINISTIC, READS SQL DATA
-- Description: Returns the latest valid price from PriceLedger for a given product.
-- Retrieves the price for the most recent RecordedAt and highest LedgerID.
-- =====================================================================
CREATE FUNCTION fn_get_current_product_price(p_product_id BIGINT UNSIGNED)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_price DECIMAL(12,2);
    
    SELECT Price INTO v_price
    FROM PriceLedger
    WHERE ProductID = p_product_id
    ORDER BY RecordedAt DESC, LedgerID DESC
    LIMIT 1;
    
    RETURN v_price;
END$$

-- =====================================================================
-- Function: fn_calculate_order_total
-- Parameters: p_order_id (BIGINT UNSIGNED)
-- Returns: DECIMAL(12,2)
-- Characteristics: DETERMINISTIC, READS SQL DATA
-- Description: Calculates total order value from OrderDetails using the 
-- locked ExactLedgerPrice (Quantity * ExactLedgerPrice).
-- =====================================================================
CREATE FUNCTION fn_calculate_order_total(p_order_id BIGINT UNSIGNED)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);
    
    SELECT COALESCE(SUM(Quantity * ExactLedgerPrice), 0.00) INTO v_total
    FROM OrderDetails
    WHERE OrderID = p_order_id;
    
    RETURN v_total;
END$$

-- =====================================================================
-- Function: fn_customer_order_count
-- Parameters: p_customer_id (BIGINT UNSIGNED)
-- Returns: INT
-- Characteristics: DETERMINISTIC, READS SQL DATA
-- Description: Returns the total number of orders placed by a specific customer.
-- =====================================================================
CREATE FUNCTION fn_customer_order_count(p_customer_id BIGINT UNSIGNED)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    
    SELECT COUNT(*) INTO v_count
    FROM Orders
    WHERE CustomerID = p_customer_id;
    
    RETURN v_count;
END$$

-- =====================================================================
-- Function: fn_customer_total_spent
-- Parameters: p_customer_id (BIGINT UNSIGNED)
-- Returns: DECIMAL(12,2)
-- Characteristics: DETERMINISTIC, READS SQL DATA
-- Description: Calculates the total amount spent by a customer across all 
-- their orders, excluding cancelled orders (ShippingStatusID = 6).
-- =====================================================================
CREATE FUNCTION fn_customer_total_spent(p_customer_id BIGINT UNSIGNED)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_spent DECIMAL(12,2);
    
    SELECT COALESCE(SUM(od.Quantity * od.ExactLedgerPrice), 0.00) INTO v_total_spent
    FROM OrderDetails od
    JOIN Orders o ON od.OrderID = o.OrderID
    WHERE o.CustomerID = p_customer_id
      AND o.ShippingStatusID <> 6;
      
    RETURN v_total_spent;
END$$

-- =====================================================================
-- Function: fn_product_stock_status
-- Parameters: p_product_id (BIGINT UNSIGNED)
-- Returns: VARCHAR(20)
-- Characteristics: DETERMINISTIC, READS SQL DATA
-- Description: Returns the stock status as a readable string:
-- 'NOT_FOUND' if product doesn't exist, 'OUT_OF_STOCK' if 0,
-- 'LOW_STOCK' if 10 or fewer, 'AVAILABLE' otherwise.
-- =====================================================================
CREATE FUNCTION fn_product_stock_status(p_product_id BIGINT UNSIGNED)
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stock INT UNSIGNED;
    
    SELECT StockQuantity INTO v_stock
    FROM Product
    WHERE ProductID = p_product_id;
    
    IF v_stock IS NULL THEN
        RETURN 'NOT_FOUND';
    ELSEIF v_stock = 0 THEN
        RETURN 'OUT_OF_STOCK';
    ELSEIF v_stock <= 10 THEN
        RETURN 'LOW_STOCK';
    ELSE
        RETURN 'AVAILABLE';
    END IF;
END$$

DELIMITER ;
