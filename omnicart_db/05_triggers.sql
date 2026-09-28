/*
 * OmniCart Marketplace Database
 * File: 05_triggers.sql
 * Description: Defines all triggers for the database.
 * Author: OmniCart Database Architect
 */

USE OmniCartDB;

DELIMITER $$

-- =====================================================================
-- Trigger: trg_priceLedger_before_update
-- Table: PriceLedger
-- Event: BEFORE UPDATE
-- Protects: The immutability of the PriceLedger table.
-- Why it's needed: The PriceLedger is an append-only historical log 
-- of price changes. Modifying past records would corrupt the audit trail.
-- Error message: 'PriceLedger is append-only. UPDATE operations are prohibited.'
-- =====================================================================
CREATE TRIGGER trg_priceLedger_before_update
BEFORE UPDATE ON PriceLedger
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'PriceLedger is append-only. UPDATE operations are prohibited.';
END$$

-- =====================================================================
-- Trigger: trg_priceLedger_before_delete
-- Table: PriceLedger
-- Event: BEFORE DELETE
-- Protects: The immutability of the PriceLedger table.
-- Why it's needed: Deleting from the price ledger destroys historical pricing data.
-- Error message: 'PriceLedger is append-only. DELETE operations are prohibited.'
-- =====================================================================
CREATE TRIGGER trg_priceLedger_before_delete
BEFORE DELETE ON PriceLedger
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'PriceLedger is append-only. DELETE operations are prohibited.';
END$$

-- =====================================================================
-- Trigger: trg_orderDetails_before_insert
-- Table: OrderDetails
-- Event: BEFORE INSERT
-- Protects: Data integrity for new order line items.
-- Why it's needed: Ensures quantities are positive, prices are non-negative, 
-- and that the recorded LedgerID actually belongs to the specified ProductID.
-- Error messages: Various based on validation failures.
-- =====================================================================
CREATE TRIGGER trg_orderDetails_before_insert
BEFORE INSERT ON OrderDetails
FOR EACH ROW
BEGIN
    DECLARE v_ledger_product_id BIGINT UNSIGNED;
    
    -- Validate Quantity
    IF NEW.Quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order quantity must be greater than zero.';
    END IF;
    
    -- Validate ExactLedgerPrice
    IF NEW.ExactLedgerPrice < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ExactLedgerPrice cannot be negative.';
    END IF;
    
    -- Verify the LedgerID belongs to the correct ProductID
    SELECT ProductID INTO v_ledger_product_id
    FROM PriceLedger
    WHERE LedgerID = NEW.LedgerID;
    
    IF v_ledger_product_id IS NULL OR v_ledger_product_id <> NEW.ProductID THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'LedgerID does not match the given ProductID in PriceLedger.';
    END IF;
END$$

-- =====================================================================
-- Trigger: trg_orderDetails_before_update
-- Table: OrderDetails
-- Event: BEFORE UPDATE
-- Protects: Immutability of critical financial and relational fields.
-- Why it's needed: Once an order is placed, the prices, products, and linked
-- ledger entries must remain fixed to prevent accounting discrepancies.
-- Error messages: Varying messages stating which field cannot be modified.
-- =====================================================================
CREATE TRIGGER trg_orderDetails_before_update
BEFORE UPDATE ON OrderDetails
FOR EACH ROW
BEGIN
    -- Prevent OrderID modification
    IF OLD.OrderID <> NEW.OrderID THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify OrderID after order creation.';
    END IF;

    -- Prevent ProductID modification
    IF OLD.ProductID <> NEW.ProductID THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify ProductID after order creation.';
    END IF;

    -- Prevent ExactLedgerPrice modification
    IF OLD.ExactLedgerPrice <> NEW.ExactLedgerPrice THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify ExactLedgerPrice after order creation.';
    END IF;
    
    -- Prevent LedgerID modification
    IF OLD.LedgerID <> NEW.LedgerID THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify LedgerID after order creation.';
    END IF;
END$$

-- =====================================================================
-- Trigger: trg_orderDetails_before_delete
-- Table: OrderDetails
-- Event: BEFORE DELETE
-- Protects: Order data consistency for shipped or completed orders.
-- Why it's needed: We cannot remove items from an order that has already 
-- been shipped (3), is in transit (4), or has been delivered (5).
-- Error message: 'Cannot delete order details for shipped or completed orders.'
-- =====================================================================
CREATE TRIGGER trg_orderDetails_before_delete
BEFORE DELETE ON OrderDetails
FOR EACH ROW
BEGIN
    DECLARE v_status_id TINYINT UNSIGNED;
    
    -- Retrieve the current shipping status of the parent order
    SELECT ShippingStatusID INTO v_status_id
    FROM Orders
    WHERE OrderID = OLD.OrderID;
    
    -- 3 = Shipped, 4 = In Transit, 5 = Delivered
    IF v_status_id IN (3, 4, 5) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete order details for shipped or completed orders.';
    END IF;
END$$

DELIMITER ;
