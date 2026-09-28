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
