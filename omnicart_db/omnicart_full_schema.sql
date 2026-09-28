-- ==============================================================================
-- PROJECT: OMNICART MARKETPLACE - COMPLETE DATABASE SYSTEM
-- File: omnicart_full_schema.sql
-- Description: Unified, production-grade executable MySQL script.
--              Executes in strict dependency order:
--                1. Database Creation & Charset Configuration
--                2. Tables, PKs, FKs & Constraints (Lookup -> Core -> Dependent)
--                3. Performance Indexes & Full-Text Indexes
--                4. Deterministic Stored Functions
--                5. Transactional Stored Procedures
--                6. Integrity Triggers (Append-Only & Financial Guards)
--                7. Normalized Views
--                8. Realistic Seed Data (Indian E-Commerce Context)
--                9. Verification Smoke Test
-- Target DB: MySQL 8.0+
-- Generated: 2026-09-27
-- ==============================================================================


-- ==============================================================================
-- BEGIN MODULE: 01_database.sql
-- ==============================================================================

-- ========================================================================
-- Project: OmniCart Marketplace Database
-- Author: Database Architect
-- Date: 2026-09-27
-- Description: This script creates the OmniCartDB database, setting the 
--              appropriate character set and collation for internationalization.
-- ========================================================================

DROP DATABASE IF EXISTS OmniCartDB;
CREATE DATABASE OmniCartDB 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE OmniCartDB;


-- ==============================================================================
-- BEGIN MODULE: 02_tables.sql
-- ==============================================================================

-- ========================================================================
-- Project: OmniCart Marketplace Database
-- Author: Database Architect
-- Date: 2026-09-27
-- Description: This script creates all tables for the OmniCartDB database.
--              Includes all Primary Keys, Foreign Keys, Unique constraints, 
--              and Check constraints inline.
-- ========================================================================

USE OmniCartDB;

-- ========================================================================
-- Section 1: Lookup Tables
-- ========================================================================

CREATE TABLE AddressType (
    AddressTypeID TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    TypeName VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB COMMENT='Lookup table for address types (e.g., Home, Work)';

CREATE TABLE ShippingStatus (
    StatusID TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    StatusName VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB COMMENT='Lookup table for order shipping statuses';

CREATE TABLE PaymentMethod (
    MethodID TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    MethodName VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB COMMENT='Lookup table for payment methods (e.g., Credit Card, UPI)';

CREATE TABLE PriceLedgerSource (
    SourceID TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    SourceName VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB COMMENT='Lookup table for the source of price changes';

-- ========================================================================
-- Section 2: Customer Group
-- ========================================================================

CREATE TABLE Customer (
    CustomerID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Core customer information';

CREATE TABLE CustomerPhone (
    PhoneID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    CustomerID BIGINT UNSIGNED NOT NULL,
    PhoneNumber VARCHAR(20) NOT NULL,
    IsPrimary TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_custphone_customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Customer phone numbers';

CREATE TABLE CustomerEmail (
    EmailID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    CustomerID BIGINT UNSIGNED NOT NULL,
    EmailAddress VARCHAR(255) NOT NULL,
    IsPrimary TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_email UNIQUE (EmailAddress),
    CONSTRAINT fk_custemail_customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Customer email addresses';

CREATE TABLE Address (
    AddressID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    CustomerID BIGINT UNSIGNED NOT NULL,
    AddressTypeID TINYINT UNSIGNED NOT NULL,
    HouseNumber VARCHAR(50) NOT NULL,
    Street VARCHAR(255) NOT NULL,
    City VARCHAR(100) NOT NULL,
    PINCode VARCHAR(10) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_addr_customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_addr_type FOREIGN KEY (AddressTypeID) REFERENCES AddressType(AddressTypeID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_pincode CHECK (PINCode REGEXP '^[0-9]{6}$')
) ENGINE=InnoDB COMMENT='Customer physical addresses';

-- ========================================================================
-- Section 3: Seller Group
-- ========================================================================

CREATE TABLE Seller (
    SellerID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    CompanyName VARCHAR(255) NOT NULL,
    GSTIN VARCHAR(15) NOT NULL,
    ContactEmail VARCHAR(255) NOT NULL,
    ContactPhone VARCHAR(20) NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_seller_gstin UNIQUE (GSTIN),
    CONSTRAINT chk_gstin_format CHECK (GSTIN REGEXP '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
) ENGINE=InnoDB COMMENT='Seller details and legal information';

-- ========================================================================
-- Section 4: Category Group
-- ========================================================================

CREATE TABLE Category (
    CategoryID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL,
    Level TINYINT UNSIGNED NOT NULL DEFAULT 0,
    ParentCategoryID BIGINT UNSIGNED NULL DEFAULT NULL,
    CategoryDescription TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_category_parent FOREIGN KEY (ParentCategoryID) REFERENCES Category(CategoryID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_category_no_self_ref CHECK (ParentCategoryID <> CategoryID)
) ENGINE=InnoDB COMMENT='Product categories hierarchy';

-- ========================================================================
-- Section 5: Product Group
-- ========================================================================

CREATE TABLE Product (
    ProductID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    StockQuantity INT UNSIGNED NOT NULL DEFAULT 0,
    SellerID BIGINT UNSIGNED NOT NULL,
    CategoryID BIGINT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_seller FOREIGN KEY (SellerID) REFERENCES Seller(SellerID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_product_category FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Product core details and inventory';

CREATE TABLE ProductImage (
    ImageID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ProductID BIGINT UNSIGNED NOT NULL,
    ImageURL VARCHAR(500) NOT NULL,
    DisplayOrder SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    IsPrimary TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_prodimg_product FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Product images and gallery order';

CREATE TABLE ProductEmbeddings (
    EmbeddingID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ProductID BIGINT UNSIGNED NOT NULL,
    FeatureVector JSON NOT NULL,
    ModelVersion VARCHAR(50) NOT NULL DEFAULT 'v1.0',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_prodembedding_product UNIQUE (ProductID),
    CONSTRAINT fk_prodembed_product FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='AI search embeddings for products';

-- ========================================================================
-- Section 6: Price Ledger Group
-- ========================================================================

CREATE TABLE PriceLedger (
    LedgerID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ProductID BIGINT UNSIGNED NOT NULL,
    SourceID TINYINT UNSIGNED NOT NULL,
    RecordedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Price DECIMAL(12,2) NOT NULL,
    PriceFluctuation DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_ledger_product FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ledger_source FOREIGN KEY (SourceID) REFERENCES PriceLedgerSource(SourceID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_price_nonneg CHECK (Price >= 0)
) ENGINE=InnoDB COMMENT='Historical product price tracking';

-- ========================================================================
-- Section 7: Order Group
-- ========================================================================

CREATE TABLE Orders (
    OrderID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    CustomerID BIGINT UNSIGNED NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ShippingStatusID TINYINT UNSIGNED NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_order_status FOREIGN KEY (ShippingStatusID) REFERENCES ShippingStatus(StatusID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Order header details';

CREATE TABLE OrderPayment (
    PaymentID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    OrderID BIGINT UNSIGNED NOT NULL,
    MethodID TINYINT UNSIGNED NOT NULL,
    PaidAmount DECIMAL(12,2) NOT NULL,
    PaidAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_orderpayment_order UNIQUE (OrderID),
    CONSTRAINT fk_payment_order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_payment_method FOREIGN KEY (MethodID) REFERENCES PaymentMethod(MethodID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_paid_amount CHECK (PaidAmount >= 0)
) ENGINE=InnoDB COMMENT='Order payment information';

CREATE TABLE OrderDetails (
    OrderID BIGINT UNSIGNED NOT NULL,
    ProductID BIGINT UNSIGNED NOT NULL,
    Quantity INT UNSIGNED NOT NULL,
    ExactLedgerPrice DECIMAL(12,2) NOT NULL,
    LedgerID BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (OrderID, ProductID),
    CONSTRAINT fk_od_order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_od_product FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_od_ledger FOREIGN KEY (LedgerID) REFERENCES PriceLedger(LedgerID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_od_quantity CHECK (Quantity > 0),
    CONSTRAINT chk_od_price CHECK (ExactLedgerPrice >= 0)
) ENGINE=InnoDB COMMENT='Order line items associating products and exact prices';


-- ==============================================================================
-- BEGIN MODULE: 03_indexes.sql
-- ==============================================================================

-- ========================================================================
-- Project: OmniCart Marketplace Database
-- Author: Database Architect
-- Date: 2026-09-27
-- Description: This script creates all secondary indexes required for the 
--              OmniCartDB to ensure optimal query performance.
-- ========================================================================

USE OmniCartDB;

-- ========================================================================
-- Customer Phone Indexes
-- ========================================================================
-- What query it accelerates: Finding a customer by phone number
-- Why it is useful: Used during login or customer support lookup
-- Whether composite: No
-- Trade-offs: Minor write overhead during phone registration
CREATE INDEX idx_custphone_phone ON CustomerPhone(PhoneNumber);

-- What query it accelerates: Retrieving all phones for a specific customer
-- Why it is useful: Fast rendering of customer profile page
-- Whether composite: No
-- Trade-offs: Requires index maintenance on inserts/deletes
CREATE INDEX idx_custphone_customer ON CustomerPhone(CustomerID);

-- ========================================================================
-- Customer Email Indexes
-- ========================================================================
-- What query it accelerates: Listing emails associated with a customer
-- Why it is useful: Necessary for profile views, though unique email constraint handles direct lookups
-- Whether composite: No
-- Trade-offs: Takes minimal extra space
CREATE INDEX idx_custemail_customer ON CustomerEmail(CustomerID);

-- ========================================================================
-- Address Indexes
-- ========================================================================
-- What query it accelerates: Listing addresses for a specific customer
-- Why it is useful: Fast rendering of checkout address selection
-- Whether composite: No
-- Trade-offs: Small storage overhead
CREATE INDEX idx_addr_customer ON Address(CustomerID);

-- What query it accelerates: Filtering customers or deliveries by city
-- Why it is useful: Useful for geographic analytics or delivery routing
-- Whether composite: No
-- Trade-offs: Low cardinality if many addresses share a city; could be inefficient if not paired with other filters
CREATE INDEX idx_addr_city ON Address(City);

-- What query it accelerates: Filtering by PIN code (zip code)
-- Why it is useful: Crucial for calculating shipping availability and costs
-- Whether composite: No
-- Trade-offs: Adds a bit of overhead during address creation
CREATE INDEX idx_addr_pincode ON Address(PINCode);

-- ========================================================================
-- Seller Indexes
-- ========================================================================
-- What query it accelerates: Looking up a seller by their contact email
-- Why it is useful: Useful for seller portal logins and support workflows
-- Whether composite: No
-- Trade-offs: Additional write penalty on seller creation
CREATE INDEX idx_seller_email ON Seller(ContactEmail);

-- ========================================================================
-- Category Indexes
-- ========================================================================
-- What query it accelerates: Traversing the category hierarchy (finding subcategories)
-- Why it is useful: Navigation menu rendering relies on fetching child categories fast
-- Whether composite: No
-- Trade-offs: Very low overhead due to infrequent category updates
CREATE INDEX idx_category_parent ON Category(ParentCategoryID);

-- What query it accelerates: Searching for a category by name
-- Why it is useful: Text search or auto-complete on categories
-- Whether composite: No
-- Trade-offs: B-Tree index on a varchar column takes slightly more space
CREATE INDEX idx_category_name ON Category(CategoryName);

-- ========================================================================
-- Product Indexes
-- ========================================================================
-- What query it accelerates: Fetching all products for a given seller
-- Why it is useful: Seller dashboard inventory views
-- Whether composite: No
-- Trade-offs: Vital for partitioned access but requires updates when products move (rare)
CREATE INDEX idx_product_seller ON Product(SellerID);

-- What query it accelerates: Loading all products in a specific category
-- Why it is useful: Category page browsing
-- Whether composite: No
-- Trade-offs: Frequent inserts mean minor index maintenance cost
CREATE INDEX idx_product_category ON Product(CategoryID);

-- What query it accelerates: Exact or prefix matches on product name
-- Why it is useful: Basic search and filtering
-- Whether composite: No
-- Trade-offs: Indexing varchar requires space; fulltext handles more complex searches
CREATE INDEX idx_product_name ON Product(Name);

-- What query it accelerates: Identifying out-of-stock or low-stock products
-- Why it is useful: Inventory alerts and filtering out of stock items from results
-- Whether composite: No
-- Trade-offs: Frequent updates to stock quantity means this index will see heavy write activity
CREATE INDEX idx_product_stock ON Product(StockQuantity);

-- What query it accelerates: Natural language and keyword searches across product names and descriptions
-- Why it is useful: Powers the main search bar on the e-commerce site
-- Whether composite: Yes (Name, Description)
-- Trade-offs: Fulltext indexes can be resource-intensive to update and take substantial storage
CREATE FULLTEXT INDEX ft_product_search ON Product(Name, Description);

-- ========================================================================
-- ProductImage Indexes
-- ========================================================================
-- What query it accelerates: Loading images for a specific product
-- Why it is useful: Product detail page rendering
-- Whether composite: No
-- Trade-offs: Minimal overhead since product images rarely change post-creation
CREATE INDEX idx_prodimg_product ON ProductImage(ProductID);

-- ========================================================================
-- PriceLedger Indexes
-- ========================================================================
-- What query it accelerates: Fetching the most recent price for a specific product
-- Why it is useful: This is the most critical query for displaying the current price. It avoids table scans.
-- Whether composite: Yes (ProductID, RecordedAt DESC)
-- Trade-offs: High update frequency as prices change, but absolute necessity for read performance
CREATE INDEX idx_ledger_product_time ON PriceLedger(ProductID, RecordedAt DESC);

-- What query it accelerates: Retrieving the full price history of a product
-- Why it is useful: Analytics and generating price trend graphs
-- Whether composite: No
-- Trade-offs: Somewhat redundant with the composite index but may optimize different query plans
CREATE INDEX idx_ledger_product ON PriceLedger(ProductID);

-- What query it accelerates: Analyzing price changes driven by a specific source
-- Why it is useful: Determining if automated scripts vs manual overrides are changing prices
-- Whether composite: No
-- Trade-offs: Low cardinality, possibly ignored by optimizer if distribution is skewed
CREATE INDEX idx_ledger_source ON PriceLedger(SourceID);

-- What query it accelerates: Finding all price changes across the catalog in a time window
-- Why it is useful: Daily reconciliation and auditing tasks
-- Whether composite: No
-- Trade-offs: Additional index maintenance during high-volume price updates
CREATE INDEX idx_ledger_recorded ON PriceLedger(RecordedAt);

-- ========================================================================
-- Orders Indexes
-- ========================================================================
-- What query it accelerates: Retrieving a customer's order history sorted by most recent
-- Why it is useful: Populating the "My Orders" section of the user profile
-- Whether composite: Yes (CustomerID, OrderDate DESC)
-- Trade-offs: High write volume on checkout, but read performance for order history is critical
CREATE INDEX idx_order_customer_date ON Orders(CustomerID, OrderDate DESC);

-- What query it accelerates: Finding orders that need to be shipped or are delayed
-- Why it is useful: Fulfillment center dashboards and reporting
-- Whether composite: Yes (ShippingStatusID, OrderDate)
-- Trade-offs: Useful for queuing systems processing orders by status
CREATE INDEX idx_order_status_date ON Orders(ShippingStatusID, OrderDate);

-- What query it accelerates: Fetching all orders placed on a specific day or month
-- Why it is useful: Financial reporting and sales metrics
-- Whether composite: No
-- Trade-offs: Standard time-series index, necessary for business intelligence
CREATE INDEX idx_order_date ON Orders(OrderDate);

-- ========================================================================
-- OrderDetails Indexes
-- ========================================================================
-- What query it accelerates: Looking up all orders that contain a specific product
-- Why it is useful: Sales analytics per product, or finding buyers of a recalled item
-- Whether composite: No
-- Trade-offs: Order details are write-heavy, but this index is crucial for reverse lookups
CREATE INDEX idx_od_product ON OrderDetails(ProductID);

-- What query it accelerates: Tracing an exact sale back to a specific ledger price entry
-- Why it is useful: Auditing and ensuring price consistency
-- Whether composite: No
-- Trade-offs: Specialized index mostly used for auditing rather than user-facing queries
CREATE INDEX idx_od_ledger ON OrderDetails(LedgerID);

-- ========================================================================
-- OrderPayment Indexes
-- ========================================================================
-- What query it accelerates: Grouping payments by method (e.g., Credit Card vs UPI)
-- Why it is useful: Financial reconciliation and payment gateway analytics
-- Whether composite: No
-- Trade-offs: Low cardinality, but helpful for aggregations
CREATE INDEX idx_payment_method ON OrderPayment(MethodID);

-- What query it accelerates: Finding payments made within a specific timeframe
-- Why it is useful: Daily cash flow reports and ledger balancing
-- Whether composite: No
-- Trade-offs: Standard date index, mandatory for financial queries
CREATE INDEX idx_payment_date ON OrderPayment(PaidAt);


-- ==============================================================================
-- BEGIN MODULE: 06_functions.sql
-- ==============================================================================

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


-- ==============================================================================
-- BEGIN MODULE: 07_procedures.sql
-- ==============================================================================

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


-- ==============================================================================
-- BEGIN MODULE: 05_triggers.sql
-- ==============================================================================

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


-- ==============================================================================
-- BEGIN MODULE: 08_views.sql
-- ==============================================================================

-- 08_views.sql
-- ==============================================================================
-- OmniCart Marketplace Database - Views
-- Description: Creates 10 views for simplified reporting and data access.
-- ==============================================================================

USE OmniCartDB;

-- ------------------------------------------------------------------------------
-- 1. vw_current_product_price
-- Description: Retrieves the current active price for every product based on the 
-- most recent PriceLedger entry.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_current_product_price AS
SELECT ProductID, Price AS CurrentPrice, RecordedAt AS PriceAsOf, LedgerID
FROM (
  SELECT ProductID, Price, RecordedAt, LedgerID,
         ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY RecordedAt DESC, LedgerID DESC) AS rn
  FROM PriceLedger
) ranked
WHERE rn = 1;

-- ------------------------------------------------------------------------------
-- 2. vw_product_catalog
-- Description: Comprehensive product catalog view combining product details, 
-- seller info, category info, stock status, and current price.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_product_catalog AS
SELECT p.ProductID, p.Name AS ProductName, p.Description, s.CompanyName AS SellerName,
       c.CategoryName, p.StockQuantity, cpp.CurrentPrice,
       fn_product_stock_status(p.ProductID) AS StockStatus
FROM Product p
JOIN Seller s ON p.SellerID = s.SellerID
JOIN Category c ON p.CategoryID = c.CategoryID
LEFT JOIN vw_current_product_price cpp ON p.ProductID = cpp.ProductID;

-- ------------------------------------------------------------------------------
-- 3. vw_product_price_history
-- Description: Shows the complete price history for all products, including 
-- fluctuation and the source of the price change.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_product_price_history AS
SELECT pl.LedgerID, pl.ProductID, p.Name AS ProductName,
       pl.Price, pl.PriceFluctuation, pl.RecordedAt,
       pls.SourceName
FROM PriceLedger pl
JOIN Product p ON pl.ProductID = p.ProductID
JOIN PriceLedgerSource pls ON pl.SourceID = pls.SourceID
ORDER BY pl.ProductID, pl.RecordedAt DESC;

-- ------------------------------------------------------------------------------
-- 4. vw_order_summary
-- Description: High-level summary of orders, including customer name, order date, 
-- current shipping status, and total order amount.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT o.OrderID, o.CustomerID,
       CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
       o.OrderDate, ss.StatusName AS ShippingStatus,
       fn_calculate_order_total(o.OrderID) AS TotalAmount
FROM Orders o
JOIN Customer c ON o.CustomerID = c.CustomerID
JOIN ShippingStatus ss ON o.ShippingStatusID = ss.StatusID;

-- ------------------------------------------------------------------------------
-- 5. vw_order_details
-- Description: Detailed view of each order's line items, including product info, 
-- quantities, exact ledger prices charged, line totals, and order shipping status.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_order_details AS
SELECT o.OrderID, o.OrderDate, od.ProductID, p.Name AS ProductName,
       od.Quantity, od.ExactLedgerPrice,
       (od.Quantity * od.ExactLedgerPrice) AS LineTotal,
       ss.StatusName AS ShippingStatus
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Product p ON od.ProductID = p.ProductID
JOIN ShippingStatus ss ON o.ShippingStatusID = ss.StatusID;

-- ------------------------------------------------------------------------------
-- 6. vw_customer_order_summary
-- Description: Summarizes each customer's lifetime activity, showing total orders 
-- and total amount spent on the platform.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_order_summary AS
SELECT c.CustomerID,
       CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
       fn_customer_order_count(c.CustomerID) AS TotalOrders,
       fn_customer_total_spent(c.CustomerID) AS TotalSpent
FROM Customer c;

-- ------------------------------------------------------------------------------
-- 7. vw_seller_product_catalog
-- Description: Product catalog tailored for sellers, listing all their products, 
-- current stock levels, current prices, and categories.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_seller_product_catalog AS
SELECT s.SellerID, s.CompanyName, p.ProductID, p.Name AS ProductName,
       p.StockQuantity, cpp.CurrentPrice, c.CategoryName
FROM Seller s
JOIN Product p ON s.SellerID = p.SellerID
JOIN Category c ON p.CategoryID = c.CategoryID
LEFT JOIN vw_current_product_price cpp ON p.ProductID = cpp.ProductID;

-- ------------------------------------------------------------------------------
-- 8. vw_category_product_count
-- Description: Aggregates the total number of products assigned to each category.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_category_product_count AS
SELECT c.CategoryID, c.CategoryName, c.Level, c.ParentCategoryID,
       COUNT(p.ProductID) AS ProductCount
FROM Category c
LEFT JOIN Product p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName, c.Level, c.ParentCategoryID;

-- ------------------------------------------------------------------------------
-- 9. vw_low_stock_products
-- Description: Identifies products with dangerously low stock quantities 
-- (<= 10 units), including seller and category info.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_low_stock_products AS
SELECT p.ProductID, p.Name AS ProductName, p.StockQuantity,
       s.CompanyName AS SellerName, c.CategoryName,
       fn_product_stock_status(p.ProductID) AS StockStatus
FROM Product p
JOIN Seller s ON p.SellerID = s.SellerID
JOIN Category c ON p.CategoryID = c.CategoryID
WHERE p.StockQuantity <= 10;

-- ------------------------------------------------------------------------------
-- 10. vw_product_embeddings_status
-- Description: Shows whether products have had vector embeddings generated, 
-- displaying the model version and creation date.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_product_embeddings_status AS
SELECT p.ProductID, p.Name AS ProductName,
       CASE WHEN pe.EmbeddingID IS NOT NULL THEN 'HAS_EMBEDDING' ELSE 'NO_EMBEDDING' END AS EmbeddingStatus,
       pe.ModelVersion, pe.created_at AS EmbeddingCreatedAt
FROM Product p
LEFT JOIN ProductEmbeddings pe ON p.ProductID = pe.ProductID;


-- ==============================================================================
-- BEGIN MODULE: 09_seed_data.sql
-- ==============================================================================

-- 09_seed_data.sql
-- ==============================================================================
-- OmniCart Marketplace Database - Reference & Master Taxonomy Data
-- Description: Initializes essential system lookup tables and core categories.
-- Note: Default customer, seller, product, inventory, and order data have been 
--       removed. All operational data is dynamically inserted when customers and
--       sellers register, list products, update stock/prices, and place orders.
-- ==============================================================================

USE OmniCartDB;

-- 1. Lookup Tables (System reference enums required for foreign key integrity)
INSERT INTO AddressType (AddressTypeID, TypeName) VALUES
(1, 'Home'),
(2, 'Work'),
(3, 'Other')
ON DUPLICATE KEY UPDATE TypeName = VALUES(TypeName);

INSERT INTO ShippingStatus (StatusID, StatusName) VALUES 
(1, 'Pending'), 
(2, 'Processing'), 
(3, 'Shipped'), 
(4, 'In Transit'), 
(5, 'Delivered'), 
(6, 'Cancelled'), 
(7, 'Returned')
ON DUPLICATE KEY UPDATE StatusName = VALUES(StatusName);

INSERT INTO PaymentMethod (MethodID, MethodName) VALUES
(1, 'Credit Card'),
(2, 'Debit Card'),
(3, 'UPI'),
(4, 'Net Banking'),
(5, 'Cash on Delivery')
ON DUPLICATE KEY UPDATE MethodName = VALUES(MethodName);

INSERT INTO PriceLedgerSource (SourceID, SourceName) VALUES
(1, 'Seller Update'),
(2, 'Automated Discount'),
(3, 'Platform Campaign'),
(4, 'Bulk Upload'),
(5, 'API Integration'),
(6, 'Admin Adjustment')
ON DUPLICATE KEY UPDATE SourceName = VALUES(SourceName);

-- 2. Core Marketplace Categories (Base Taxonomy)
INSERT INTO Category (CategoryID, CategoryName, Level, ParentCategoryID, CategoryDescription, created_at, updated_at) VALUES
(1, 'Electronics', 0, NULL, 'Electronic devices and gadgets', NOW(), NOW()),
(2, 'Apparel', 0, NULL, 'Clothing and fashion accessories', NOW(), NOW()),
(3, 'Home & Kitchen', 0, NULL, 'Household and kitchen items', NOW(), NOW()),
(4, 'Sports', 0, NULL, 'Sports equipment and gear', NOW(), NOW()),
(5, 'Mobile Phones', 1, 1, 'Smartphones and accessories', NOW(), NOW()),
(6, 'Laptops', 1, 1, 'Laptops and notebooks', NOW(), NOW()),
(7, 'Mens Clothing', 1, 2, 'Apparel for men', NOW(), NOW()),
(8, 'Womens Clothing', 1, 2, 'Apparel for women', NOW(), NOW()),
(9, 'Kitchen Appliances', 1, 3, 'Electrical appliances for kitchen', NOW(), NOW()),
(10, 'Running Shoes', 1, 4, 'Shoes for running and athletics', NOW(), NOW())
ON DUPLICATE KEY UPDATE CategoryName = VALUES(CategoryName), CategoryDescription = VALUES(CategoryDescription);

-- ==============================================================================
-- DYNAMIC ENTITIES (Zero default dummy records)
-- The following tables start empty and are populated upon real user operations:
--   - Customer, CustomerPhone, CustomerEmail, Address: Populated on Customer registration & profile updates
--   - Seller: Populated on Merchant/Seller registration
--   - Product, ProductImage, ProductEmbeddings: Populated when Sellers list products
--   - PriceLedger: Populated on initial listing and price adjustments
--   - Orders, OrderDetails, OrderPayment: Populated upon customer checkout
-- ==============================================================================


-- ==============================================================================
-- VERIFICATION & SMOKE TEST
-- ==============================================================================
SELECT 'OmniCartDB schema initialized successfully!' AS Status;

SELECT 
    TABLE_NAME, 
    TABLE_ROWS 
FROM 
    information_schema.TABLES 
WHERE 
    TABLE_SCHEMA = 'OmniCartDB' 
ORDER BY 
    TABLE_NAME;
