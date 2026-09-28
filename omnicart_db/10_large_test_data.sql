-- =========================================================================
-- FILE 1: 10_large_test_data.sql
-- DESCRIPTION: Generates large test datasets for OmniCartDB.
-- =========================================================================

USE OmniCartDB;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_generate_test_data$$

CREATE PROCEDURE sp_generate_test_data(IN p_scale INT)
BEGIN
    -- Declare variables for loops and constraints
    DECLARE i INT DEFAULT 1;
    DECLARE v_root_count INT DEFAULT 10;
    DECLARE v_sub_count INT DEFAULT 5 * p_scale;
    DECLARE v_seller_count INT DEFAULT 5 * p_scale;
    DECLARE v_customer_count INT DEFAULT 10 * p_scale;
    DECLARE v_product_count INT DEFAULT 20 * p_scale;
    DECLARE v_order_count INT DEFAULT 15 * p_scale;
    
    DECLARE v_start_time DATETIME;
    DECLARE v_end_time DATETIME;

    -- Disable foreign key checks for faster bulk inserts
    SET FOREIGN_KEY_CHECKS = 0;

    SET v_start_time = NOW();
    SELECT CONCAT('Generation started at: ', v_start_time) AS StatusMsg;

    -- 1. Generate Categories (10 root + 5 * p_scale sub-categories)
    -- Root Categories
    SET i = 1;
    WHILE i <= v_root_count DO
        INSERT INTO Category (CategoryName, Level, ParentCategoryID, CategoryDescription, created_at, updated_at)
        VALUES (CONCAT('Root Category ', i), 1, NULL, CONCAT('Description for Root Category ', i), NOW(), NOW());
        SET i = i + 1;
    END WHILE;

    -- Sub Categories
    SET i = 1;
    WHILE i <= v_sub_count DO
        INSERT INTO Category (CategoryName, Level, ParentCategoryID, CategoryDescription, created_at, updated_at)
        VALUES (
            CONCAT('Sub Category ', i), 
            2, 
            FLOOR(1 + RAND() * v_root_count), 
            CONCAT('Description for Sub Category ', i), 
            NOW(), 
            NOW()
        );
        SET i = i + 1;
    END WHILE;

    -- 2. Generate Sellers
    SET i = 1;
    WHILE i <= v_seller_count DO
        INSERT INTO Seller (CompanyName, GSTIN, ContactEmail, ContactPhone, PasswordHash, created_at, updated_at)
        VALUES (
            CONCAT('Seller Company ', i),
            CONCAT(LPAD(FLOOR(RAND()*28)+1, 2, '0'), 'AABCT', LPAD(i, 4, '0'), 'F1Z', CHAR(65 + FLOOR(RAND()*26))),
            CONCAT('seller', i, '@marketplace.com'),
            CONCAT('+91-9', LPAD(FLOOR(RAND()*999999999), 9, '0')),
            '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG',
            NOW(),
            NOW()
        );
        SET i = i + 1;
    END WHILE;

    -- 3. Generate Customers
    SET i = 1;
    WHILE i <= v_customer_count DO
        INSERT INTO Customer (FirstName, LastName, PasswordHash, created_at, updated_at)
        VALUES (
            CONCAT('FirstName', i),
            CONCAT('LastName', i),
            '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG',
            NOW(),
            NOW()
        );
        SET i = i + 1;
    END WHILE;

    -- 4. Generate Addresses
    -- Generating 1 to 3 addresses per customer
    SET i = 1;
    WHILE i <= v_customer_count DO
        INSERT INTO Address (CustomerID, AddressTypeID, HouseNumber, Street, City, PINCode, created_at, updated_at)
        VALUES (
            i,
            FLOOR(1 + RAND() * 3), -- Assuming AddressTypeID 1,2,3 exist
            CONCAT(FLOOR(RAND()*999)),
            CONCAT('Street ', FLOOR(RAND()*100)),
            'Test City',
            CONCAT(LPAD(FLOOR(RAND()*999999), 6, '0')),
            NOW(),
            NOW()
        );
        -- Insert a second address randomly (30% chance)
        IF RAND() < 0.3 THEN
             INSERT INTO Address (CustomerID, AddressTypeID, HouseNumber, Street, City, PINCode, created_at, updated_at)
             VALUES (i, FLOOR(1 + RAND() * 3), CONCAT(FLOOR(RAND()*999)), CONCAT('Street ', FLOOR(RAND()*100)), 'Test City', CONCAT(LPAD(FLOOR(RAND()*999999), 6, '0')), NOW(), NOW());
        END IF;
        SET i = i + 1;
    END WHILE;

    -- 5. Generate Customer Phones
    SET i = 1;
    WHILE i <= v_customer_count DO
        INSERT INTO CustomerPhone (CustomerID, PhoneNumber, IsPrimary, created_at)
        VALUES (i, CONCAT('+91-', LPAD(FLOOR(RAND()*9999999999), 10, '0')), 1, NOW());
        
        IF RAND() < 0.2 THEN
            INSERT INTO CustomerPhone (CustomerID, PhoneNumber, IsPrimary, created_at)
            VALUES (i, CONCAT('+91-', LPAD(FLOOR(RAND()*9999999999), 10, '0')), 0, NOW());
        END IF;
        SET i = i + 1;
    END WHILE;

    -- 6. Generate Customer Emails
    SET i = 1;
    WHILE i <= v_customer_count DO
        INSERT INTO CustomerEmail (CustomerID, EmailAddress, IsPrimary, created_at)
        VALUES (i, CONCAT('user', i, '_', FLOOR(RAND()*10000), '@testmail.com'), 1, NOW());
        SET i = i + 1;
    END WHILE;

    -- 7. Generate Products
    SET i = 1;
    WHILE i <= v_product_count DO
        INSERT INTO Product (Name, Description, StockQuantity, SellerID, CategoryID, created_at, updated_at)
        VALUES (
            CONCAT('Product ', i),
            CONCAT('This is the description for Product ', i),
            FLOOR(10 + RAND() * 990),
            FLOOR(1 + RAND() * v_seller_count),
            v_root_count + FLOOR(1 + RAND() * (v_sub_count - 1)),
            NOW(),
            NOW()
        );
        SET i = i + 1;
    END WHILE;

    -- 8. Generate Product Images
    SET i = 1;
    WHILE i <= v_product_count DO
        INSERT INTO ProductImage (ProductID, ImageURL, DisplayOrder, IsPrimary, created_at)
        VALUES (i, CONCAT('/images/product_', i, '_main.jpg'), 1, 1, NOW());
        
        IF RAND() < 0.5 THEN
            INSERT INTO ProductImage (ProductID, ImageURL, DisplayOrder, IsPrimary, created_at)
            VALUES (i, CONCAT('/images/product_', i, '_alt.jpg'), 2, 0, NOW());
        END IF;
        SET i = i + 1;
    END WHILE;

    -- 9. Generate Embeddings (for ~70% of products)
    SET i = 1;
    WHILE i <= (v_product_count * 0.7) DO
        INSERT IGNORE INTO ProductEmbeddings (ProductID, FeatureVector, ModelVersion, created_at, updated_at)
        VALUES (
            i, 
            CONCAT('[', RAND(), ',', RAND(), ',', RAND(), ',', RAND(), ',', RAND(), ',', RAND(), ',', RAND(), ',', RAND(), ']'), 
            'v1.0', 
            NOW(), 
            NOW()
        );
        SET i = i + 1;
    END WHILE;

    -- 10. Generate Price Ledger
    SET i = 1;
    WHILE i <= v_product_count DO
        -- Initial Listing
        INSERT INTO PriceLedger (ProductID, SourceID, RecordedAt, Price, PriceFluctuation)
        VALUES (i, 1, DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 100) DAY), ROUND(10 + RAND() * 1000, 2), 0.00);
        
        -- Occasional Price Update
        IF RAND() < 0.5 THEN
            INSERT INTO PriceLedger (ProductID, SourceID, RecordedAt, Price, PriceFluctuation)
            VALUES (i, FLOOR(2 + RAND() * 4), DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 50) DAY), ROUND(10 + RAND() * 1000, 2), ROUND(-50 + RAND() * 100, 2));
        END IF;
        SET i = i + 1;
    END WHILE;

    -- 11 & 12 & 13. Generate Orders, Order Details, Payments
    SET i = 1;
    WHILE i <= v_order_count DO
        -- Insert Order
        INSERT INTO Orders (CustomerID, OrderDate, ShippingStatusID, created_at, updated_at)
        VALUES (
            FLOOR(1 + RAND() * (v_customer_count - 1)),
            DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY),
            FLOOR(1 + RAND() * 7),
            NOW(),
            NOW()
        );
        
        -- Insert Order Details
        -- Each order has 1 to 4 items
        SET @num_items = FLOOR(1 + RAND() * 4);
        SET @j = 1;
        WHILE @j <= @num_items DO
            SET @rand_product = FLOOR(1 + RAND() * (v_product_count - 1));
            
            -- Find the latest ledger ID for this product
            SELECT LedgerID, Price INTO @ledger_id, @ledger_price 
            FROM PriceLedger 
            WHERE ProductID = @rand_product 
            ORDER BY RecordedAt DESC LIMIT 1;
            
            IF @ledger_id IS NOT NULL THEN
                INSERT IGNORE INTO OrderDetails (OrderID, ProductID, Quantity, ExactLedgerPrice, LedgerID)
                VALUES (i, @rand_product, FLOOR(1 + RAND() * 5), @ledger_price, @ledger_id);
            END IF;
            
            SET @j = @j + 1;
        END WHILE;
        
        -- Insert Payment
        SELECT SUM(Quantity * ExactLedgerPrice) INTO @order_total FROM OrderDetails WHERE OrderID = i;
        IF @order_total IS NOT NULL THEN
            INSERT INTO OrderPayment (OrderID, MethodID, PaidAmount, PaidAt)
            VALUES (i, FLOOR(1 + RAND() * 6), @order_total, NOW());
        END IF;

        SET i = i + 1;
    END WHILE;

    -- Re-enable foreign key checks
    SET FOREIGN_KEY_CHECKS = 1;

    SET v_end_time = NOW();
    SELECT CONCAT('Generation completed at: ', v_end_time, ' Total time taken: ', TIMEDIFF(v_end_time, v_start_time)) AS StatusMsg;

END$$

DELIMITER ;
