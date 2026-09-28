-- ==============================================================================
-- OmniCart Marketplace Database - Stored Procedures
-- ==============================================================================
-- This file contains all the stored procedures for the OmniCartDB.
-- Ensure that tables and functions are created before executing this file.
-- ==============================================================================

USE OmniCartDB;

-- ------------------------------------------------------------------------------
-- 1. sp_create_customer
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_create_customer(
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_email VARCHAR(255),
    IN p_phone VARCHAR(20),
    IN p_password_hash VARCHAR(255),
    OUT p_customer_id BIGINT UNSIGNED
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    INSERT INTO Customer (FirstName, LastName, PasswordHash)
    VALUES (p_first_name, p_last_name, p_password_hash);
    
    SET p_customer_id = LAST_INSERT_ID();
    
    INSERT INTO CustomerEmail (CustomerID, EmailAddress, IsPrimary) 
    VALUES (p_customer_id, p_email, 1);
    
    INSERT INTO CustomerPhone (CustomerID, PhoneNumber, IsPrimary) 
    VALUES (p_customer_id, p_phone, 1);
    
    COMMIT;
END $$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 2. sp_add_customer_address
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_add_customer_address(
    IN p_customer_id BIGINT UNSIGNED,
    IN p_house_number VARCHAR(50),
    IN p_street VARCHAR(255),
    IN p_city VARCHAR(100),
    IN p_pin_code VARCHAR(10),
    IN p_address_type VARCHAR(50),
    OUT p_address_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_address_type_id TINYINT UNSIGNED;
    
    -- Validate customer exists
    IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer not found';
    END IF;
    
    -- Look up AddressTypeID
    SELECT AddressTypeID INTO v_address_type_id
    FROM AddressType 
    WHERE TypeName = p_address_type;
    
    IF v_address_type_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid address type';
    END IF;
    
    INSERT INTO Address (CustomerID, AddressTypeID, HouseNumber, Street, City, PINCode)
    VALUES (p_customer_id, v_address_type_id, p_house_number, p_street, p_city, p_pin_code);
    
    SET p_address_id = LAST_INSERT_ID();
END $$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 3. sp_create_seller
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_create_seller(
    IN p_company_name VARCHAR(255),
    IN p_gstin VARCHAR(15),
    IN p_email VARCHAR(255),
    IN p_phone VARCHAR(20),
    IN p_password_hash VARCHAR(255),
    OUT p_seller_id BIGINT UNSIGNED
)
BEGIN
    INSERT INTO Seller (CompanyName, GSTIN, ContactEmail, ContactPhone, PasswordHash)
    VALUES (p_company_name, p_gstin, p_email, p_phone, p_password_hash);
    
    SET p_seller_id = LAST_INSERT_ID();
END $$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 4. sp_create_category
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_create_category(
    IN p_name VARCHAR(100),
    IN p_description TEXT,
    IN p_parent_id BIGINT UNSIGNED,
    OUT p_category_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_parent_level TINYINT UNSIGNED DEFAULT 0;
    
    IF p_parent_id IS NOT NULL THEN
        -- Validate parent exists and get Level
        SELECT Level INTO v_parent_level
        FROM Category
        WHERE CategoryID = p_parent_id;
        
        IF v_parent_level IS NULL AND NOT EXISTS (SELECT 1 FROM Category WHERE CategoryID = p_parent_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parent category not found';
        END IF;
        
        SET v_parent_level = v_parent_level + 1;
    END IF;
    
    INSERT INTO Category (CategoryName, CategoryDescription, ParentCategoryID, Level)
    VALUES (p_name, p_description, p_parent_id, v_parent_level);
    
    SET p_category_id = LAST_INSERT_ID();
END $$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 5. sp_create_product
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_create_product(
    IN p_name VARCHAR(255),
    IN p_description TEXT,
    IN p_stock INT UNSIGNED,
    IN p_seller_id BIGINT UNSIGNED,
    IN p_category_id BIGINT UNSIGNED,
    IN p_initial_price DECIMAL(12,2),
    OUT p_product_id BIGINT UNSIGNED
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    IF NOT EXISTS (SELECT 1 FROM Seller WHERE SellerID = p_seller_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Seller not found';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM Category WHERE CategoryID = p_category_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Category not found';
    END IF;
    
    IF p_initial_price < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Initial price must be >= 0';
    END IF;
    
    INSERT INTO Product (Name, Description, StockQuantity, SellerID, CategoryID)
    VALUES (p_name, p_description, p_stock, p_seller_id, p_category_id);
    
    SET p_product_id = LAST_INSERT_ID();
    
    -- SourceID 1 = 'Initial Listing'
    INSERT INTO PriceLedger (ProductID, SourceID, Price, PriceFluctuation) 
    VALUES (p_product_id, 1, p_initial_price, 0.00);
    
    COMMIT;
END $$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 6. sp_add_product_image
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_add_product_image(
    IN p_product_id BIGINT UNSIGNED,
    IN p_image_url VARCHAR(500),
    IN p_display_order SMALLINT UNSIGNED,
    IN p_is_primary TINYINT(1),
    OUT p_image_id BIGINT UNSIGNED
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Product WHERE ProductID = p_product_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
    END IF;
    
    IF p_is_primary = 1 THEN
        UPDATE ProductImage SET IsPrimary = 0 WHERE ProductID = p_product_id;
    END IF;
    
    INSERT INTO ProductImage (ProductID, ImageURL, DisplayOrder, IsPrimary)
    VALUES (p_product_id, p_image_url, p_display_order, p_is_primary);
    
    SET p_image_id = LAST_INSERT_ID();
END $$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 7. sp_add_product_embedding
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_add_product_embedding(
    IN p_product_id BIGINT UNSIGNED,
    IN p_feature_vector JSON,
    IN p_model_version VARCHAR(50),
    OUT p_embedding_id BIGINT UNSIGNED
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Product WHERE ProductID = p_product_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
    END IF;
    
    INSERT INTO ProductEmbeddings (ProductID, FeatureVector, ModelVersion)
    VALUES (p_product_id, p_feature_vector, p_model_version)
    ON DUPLICATE KEY UPDATE 
        FeatureVector = VALUES(FeatureVector), 
        ModelVersion = VALUES(ModelVersion);
        
    SELECT EmbeddingID INTO p_embedding_id 
    FROM ProductEmbeddings 
    WHERE ProductID = p_product_id;
END $$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 8. sp_add_price_ledger_entry
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_add_price_ledger_entry(
    IN p_product_id BIGINT UNSIGNED,
    IN p_price DECIMAL(12,2),
    IN p_source_id TINYINT UNSIGNED,
    OUT p_ledger_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_previous_price DECIMAL(12,2);
    DECLARE v_fluctuation DECIMAL(12,2) DEFAULT 0.00;
    
    IF NOT EXISTS (SELECT 1 FROM Product WHERE ProductID = p_product_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
    END IF;
    
    IF p_price < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Price must be >= 0';
    END IF;
    
    SET v_previous_price = fn_get_current_product_price(p_product_id);
    
    IF v_previous_price IS NOT NULL THEN
        SET v_fluctuation = p_price - v_previous_price;
    END IF;
    
    INSERT INTO PriceLedger (ProductID, SourceID, Price, PriceFluctuation)
    VALUES (p_product_id, p_source_id, p_price, v_fluctuation);
    
    SET p_ledger_id = LAST_INSERT_ID();
END $$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 9. sp_update_product_stock
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_update_product_stock(
    IN p_product_id BIGINT UNSIGNED,
    IN p_new_stock INT UNSIGNED
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Product WHERE ProductID = p_product_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
    END IF;
    
    UPDATE Product 
    SET StockQuantity = p_new_stock 
    WHERE ProductID = p_product_id;
END $$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 10. sp_place_order
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_place_order(
    IN p_customer_id BIGINT UNSIGNED,
    IN p_product_ids JSON,
    IN p_quantities JSON,
    IN p_payment_method_id TINYINT UNSIGNED,
    OUT p_order_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_item_count INT;
    DECLARE v_idx INT;
    DECLARE v_total_amount DECIMAL(12,2);
    DECLARE v_product_id BIGINT UNSIGNED;
    DECLARE v_quantity INT UNSIGNED;
    DECLARE v_current_stock INT UNSIGNED;
    DECLARE v_ledger_id BIGINT UNSIGNED;
    DECLARE v_price DECIMAL(12,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validate customer exists
    IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer not found';
    END IF;

    -- Validate arrays have same length
    SET v_item_count = JSON_LENGTH(p_product_ids);
    IF v_item_count <> JSON_LENGTH(p_quantities) OR v_item_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product IDs and quantities arrays must have equal non-zero length';
    END IF;

    -- Validate payment method
    IF NOT EXISTS (SELECT 1 FROM PaymentMethod WHERE MethodID = p_payment_method_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid payment method';
    END IF;

    -- Create the order
    INSERT INTO Orders (CustomerID, ShippingStatusID) VALUES (p_customer_id, 1);
    SET p_order_id = LAST_INSERT_ID();

    -- Loop through each item
    SET v_idx = 0;
    SET v_total_amount = 0.00;

    WHILE v_idx < v_item_count DO
        SET v_product_id = JSON_EXTRACT(p_product_ids, CONCAT('$[', v_idx, ']'));
        SET v_quantity = JSON_EXTRACT(p_quantities, CONCAT('$[', v_idx, ']'));

        -- Validate quantity > 0
        IF v_quantity <= 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be greater than zero';
        END IF;

        -- Lock the product row and validate stock
        SELECT StockQuantity INTO v_current_stock
        FROM Product 
        WHERE ProductID = v_product_id 
        FOR UPDATE;

        IF v_current_stock IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
        END IF;

        IF v_current_stock < v_quantity THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
        END IF;

        -- Get current price and ledger ID
        SELECT LedgerID, Price INTO v_ledger_id, v_price
        FROM PriceLedger
        WHERE ProductID = v_product_id
        ORDER BY RecordedAt DESC, LedgerID DESC
        LIMIT 1;

        IF v_ledger_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No price found for product';
        END IF;

        -- Insert order detail with locked price
        INSERT INTO OrderDetails (OrderID, ProductID, Quantity, ExactLedgerPrice, LedgerID)
        VALUES (p_order_id, v_product_id, v_quantity, v_price, v_ledger_id);

        -- Reduce stock
        UPDATE Product 
        SET StockQuantity = StockQuantity - v_quantity
        WHERE ProductID = v_product_id;

        -- Accumulate total
        SET v_total_amount = v_total_amount + (v_quantity * v_price);

        SET v_idx = v_idx + 1;
    END WHILE;

    -- Create payment record
    INSERT INTO OrderPayment (OrderID, MethodID, PaidAmount)
    VALUES (p_order_id, p_payment_method_id, v_total_amount);

    COMMIT;
END $$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 11. sp_update_shipping_status
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_update_shipping_status(
    IN p_order_id BIGINT UNSIGNED,
    IN p_status_id TINYINT UNSIGNED
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderID = p_order_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM ShippingStatus WHERE StatusID = p_status_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid shipping status';
    END IF;
    
    UPDATE Orders 
    SET ShippingStatusID = p_status_id 
    WHERE OrderID = p_order_id;
END $$
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 12. sp_cancel_order
-- ------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_cancel_order(
    IN p_order_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_status_id TINYINT UNSIGNED;
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_product_id BIGINT UNSIGNED;
    DECLARE v_quantity INT UNSIGNED;
    
    -- Cursor for restoring stock
    DECLARE cur_items CURSOR FOR 
        SELECT ProductID, Quantity FROM OrderDetails WHERE OrderID = p_order_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    SELECT ShippingStatusID INTO v_status_id
    FROM Orders
    WHERE OrderID = p_order_id FOR UPDATE;
    
    IF v_status_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    END IF;
    
    -- If already Cancelled (6) or Delivered (5), signal error
    IF v_status_id = 5 OR v_status_id = 6 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order cannot be cancelled from its current status';
    END IF;
    
    -- Restore stock
    OPEN cur_items;
    read_loop: LOOP
        FETCH cur_items INTO v_product_id, v_quantity;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        UPDATE Product 
        SET StockQuantity = StockQuantity + v_quantity
        WHERE ProductID = v_product_id;
    END LOOP;
    CLOSE cur_items;
    
    -- Update order status to Cancelled (6)
    UPDATE Orders 
    SET ShippingStatusID = 6 
    WHERE OrderID = p_order_id;
    
    COMMIT;
END $$
DELIMITER ;
