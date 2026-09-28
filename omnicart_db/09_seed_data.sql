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
