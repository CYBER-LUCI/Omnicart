-- ========================================================================
-- Project: OmniCart Marketplace Database
-- Author: Database Architect
-- Date: 2026-09-27
-- Description: This script documents and verifies all constraints used in the 
--              OmniCartDB schema. Since all Primary Keys, Foreign Keys, 
--              Unique constraints, and Check constraints have been implemented 
--              inline within the CREATE TABLE statements in 02_tables.sql, 
--              this file serves as documentation and validation.
-- ========================================================================

USE OmniCartDB;

/*
===========================================================================
CONSTRAINT DOCUMENTATION SUMMARY
===========================================================================

TABLE: CustomerPhone
- FK: fk_custphone_customer (CustomerID references Customer.CustomerID)

TABLE: CustomerEmail
- UQ: uq_customer_email (EmailAddress)
- FK: fk_custemail_customer (CustomerID references Customer.CustomerID)

TABLE: Address
- FK: fk_addr_customer (CustomerID references Customer.CustomerID)
- FK: fk_addr_type (AddressTypeID references AddressType.AddressTypeID)
- CHK: chk_pincode (PINCode REGEXP '^[0-9]{6}$')

TABLE: Seller
- UQ: uq_seller_gstin (GSTIN)
- CHK: chk_gstin_format (GSTIN REGEXP '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')

TABLE: Category
- FK: fk_category_parent (ParentCategoryID references Category.CategoryID)
- CHK: chk_category_no_self_ref (ParentCategoryID <> CategoryID)

TABLE: Product
- FK: fk_product_seller (SellerID references Seller.SellerID)
- FK: fk_product_category (CategoryID references Category.CategoryID)

TABLE: ProductImage
- FK: fk_prodimg_product (ProductID references Product.ProductID)

TABLE: ProductEmbeddings
- UQ: uq_prodembedding_product (ProductID)
- FK: fk_prodembed_product (ProductID references Product.ProductID)

TABLE: PriceLedger
- FK: fk_ledger_product (ProductID references Product.ProductID)
- FK: fk_ledger_source (SourceID references PriceLedgerSource.SourceID)
- CHK: chk_price_nonneg (Price >= 0)

TABLE: Orders
- FK: fk_order_customer (CustomerID references Customer.CustomerID)
- FK: fk_order_status (ShippingStatusID references ShippingStatus.StatusID)

TABLE: OrderPayment
- UQ: uq_orderpayment_order (OrderID)
- FK: fk_payment_order (OrderID references Orders.OrderID)
- FK: fk_payment_method (MethodID references PaymentMethod.MethodID)
- CHK: chk_paid_amount (PaidAmount >= 0)

TABLE: OrderDetails
- FK: fk_od_order (OrderID references Orders.OrderID)
- FK: fk_od_product (ProductID references Product.ProductID)
- FK: fk_od_ledger (LedgerID references PriceLedger.LedgerID)
- CHK: chk_od_quantity (Quantity > 0)
- CHK: chk_od_price (ExactLedgerPrice >= 0)
*/

-- ========================================================================
-- VERIFICATION QUERY
-- Run this query to verify that all constraints have been created successfully.
-- ========================================================================
SELECT 
    TABLE_NAME, 
    CONSTRAINT_NAME, 
    CONSTRAINT_TYPE 
FROM 
    information_schema.TABLE_CONSTRAINTS 
WHERE 
    TABLE_SCHEMA = 'OmniCartDB' 
ORDER BY 
    TABLE_NAME, 
    CONSTRAINT_TYPE;
