# OmniCart Marketplace — Database System Architecture & Implementation Manual

**Database Engine:** MySQL 8.0+  
**Target Backend:** Java 17+ / Spring Boot 3.x (Spring Data JPA / Hibernate)  
**Schema Name:** `OmniCartDB`  
**Character Set & Collation:** `utf8mb4` / `utf8mb4_unicode_ci`  
**Architectural Standard:** 3NF / BCNF Normalized Relational Model  

---

## Table of Contents

1. [Project Purpose & Executive Overview](#1-project-purpose--executive-overview)
2. [Database Architecture & Design Philosophy](#2-database-architecture--design-philosophy)
3. [ER-to-Relational Mapping & Schema Dictionary](#3-er-to-relational-mapping--schema-dictionary)
4. [Primary Keys, Foreign Keys, & Cardinalities](#4-primary-keys-foreign-keys--cardinalities)
5. [Relational Normalization Proof (1NF through BCNF)](#5-relational-normalization-proof-1nf-through-bcnf)
6. [Indexing Strategy & Performance Analysis](#6-indexing-strategy--performance-analysis)
7. [Database Views (Reporting & Catalog Abstractions)](#7-database-views-reporting--catalog-abstractions)
8. [Deterministic Stored Functions](#8-deterministic-stored-functions)
9. [Stored Procedures & Business Transactions](#9-stored-procedures--business-transactions)
10. [Database Triggers & Invariant Enforcement](#10-database-triggers--invariant-enforcement)
11. [Transactional Integrity & Concurrency Control](#11-transactional-integrity--concurrency-control)
12. [Dynamic Pricing & The Append-Only Price Ledger](#12-dynamic-pricing--the-append-only-price-ledger)
13. [AI Visual Search & High-Dimensional Embeddings](#13-ai-visual-search--high-dimensional-embeddings)
14. [Hierarchical Category Representation](#14-hierarchical-category-representation)
15. [Role-Based Access Control (RBAC) & Security Grants](#15-role-based-access-control-rbac--security-grants)
16. [Seed Data & Sample Scenarios](#16-seed-data--sample-scenarios)
17. [High-Scale Synthetic Data Generation (100,000+ Rows)](#17-high-scale-synthetic-data-generation-100000-rows)
18. [Test Suite & Analytical Reporting Queries](#18-test-suite--analytical-reporting-queries)
19. [Script Execution Order & Deployment Guide](#19-script-execution-order--deployment-guide)
20. [Spring Boot Backend Integration Guide](#20-spring-boot-backend-integration-guide)
21. [Final Architectural Validation Checklist](#21-final-architectural-validation-checklist)

---

## 1. Project Purpose & Executive Overview

**OmniCart Marketplace** is an enterprise-grade multi-vendor e-commerce platform designed to facilitate transactions between autonomous sellers and retail consumers. The database backend must support high-concurrency order placement, multi-channel customer communications, dynamic algorithmic pricing with an immutable financial audit trail, catalog hierarchy, and AI-powered visual similarity search.

### Core Objectives:
- **Zero Financial Discrepancies:** Orders must snapshot the exact historical price agreed upon at the checkout moment. Subsequent product price changes must never retroactively alter historic orders.
- **Strict Concurrency Protection:** Race conditions (such as two buyers purchasing the last unit of stock simultaneously) must be eliminated using row-level locking (`SELECT ... FOR UPDATE`) within ACID transactions.
- **Audit Immutability:** Historical price ledgers must be physically append-only; update and delete operations are rejected at the trigger and database privilege levels.
- **Clean Normalization:** Eliminate repeating groups, multi-valued attributes, and transitive functional dependencies while providing performant denormalized views for read queries.
- **Enterprise Spring Boot Compatibility:** Built using standard surrogate keys, canonical naming, and standard JDBC types compatible with Hibernate, Flyway, and Liquibase.

---

## 2. Database Architecture & Design Philosophy

The database architecture decouples catalog data, inventory levels, media assets, vector embeddings, historical pricing, and transactional order records:

```
[Customer] --------< [CustomerPhone]
    |       --------< [CustomerEmail]
    |       --------< [Address] >-------- [AddressType]
    |
    +--------------< [Orders] >-------- [ShippingStatus]
                       |    |
                       |    +---------- [OrderPayment] >-------- [PaymentMethod]
                       |
                       +----< [OrderDetails] >-------- [Product] >-------- [Seller]
                                  |                      |    |
                                  |                      |    +--- [ProductImage]
                                  |                      |    +--- [ProductEmbeddings]
                                  |                      |    +--- [Category] (Recursive)
                                  |                      |
                                  +-----------------< [PriceLedger] >--- [PriceLedgerSource]
```

---

## 3. ER-to-Relational Mapping & Schema Dictionary

The system implements 17 relational tables organized into 7 functional modules:

### A. Lookup & Classification Tables
1. **`AddressType`**: Pre-defined address classifications (Home, Work, Other).
2. **`ShippingStatus`**: Order fulfillment states (Pending, Processing, Shipped, In Transit, Delivered, Cancelled, Returned).
3. **`PaymentMethod`**: Supported financial instruments (Credit Card, Debit Card, UPI, Net Banking, Cash on Delivery).
4. **`PriceLedgerSource`**: Catalogs the trigger behind a price change (Seller Update, Automated Discount, Platform Campaign, Bulk Upload, API Integration, Admin Adjustment).

### B. Customer Management Module
5. **`Customer`**: Core individual entity (`CustomerID`, `FirstName`, `LastName`, timestamps).
6. **`CustomerPhone`**: Resolves 1:N multi-valued phone numbers (`PhoneID`, `CustomerID`, `PhoneNumber`, `IsPrimary`).
7. **`CustomerEmail`**: Resolves 1:N multi-valued emails (`EmailID`, `CustomerID`, `EmailAddress` [UNIQUE], `IsPrimary`).
8. **`Address`**: Structured physical locations (`AddressID`, `CustomerID`, `AddressTypeID`, `HouseNumber`, `Street`, `City`, `PINCode`).

### C. Vendor & Catalog Module
9. **`Seller`**: Registered merchant records (`SellerID`, `CompanyName`, `GSTIN` [UNIQUE 15-char], `ContactEmail`, `ContactPhone`).
10. **`Category`**: Self-referencing hierarchical taxonomy (`CategoryID`, `CategoryName`, `Level`, `ParentCategoryID`, `CategoryDescription`).
11. **`Product`**: Core sellable unit (`ProductID`, `Name`, `Description`, `StockQuantity`, `SellerID`, `CategoryID`).
12. **`ProductImage`**: External media URLs (`ImageID`, `ProductID`, `ImageURL`, `DisplayOrder`, `IsPrimary`).
13. **`ProductEmbeddings`**: AI vector embeddings (`EmbeddingID`, `ProductID` [UNIQUE], `FeatureVector` [JSON], `ModelVersion`).

### D. Pricing & Dynamic Ledger Module
14. **`PriceLedger`**: Append-only price history (`LedgerID`, `ProductID`, `SourceID`, `RecordedAt`, `Price`, `PriceFluctuation`).

### E. Fulfillment & Transaction Module
15. **`Orders`**: Order header entity (`OrderID`, `CustomerID`, `OrderDate`, `ShippingStatusID`).
16. **`OrderPayment`**: Settlement record (`PaymentID`, `OrderID` [UNIQUE], `MethodID`, `PaidAmount`, `PaidAt`).
17. **`OrderDetails`**: Line item junction resolving Order <-> Product (`OrderID`, `ProductID` [Composite PK], `Quantity`, `ExactLedgerPrice`, `LedgerID`).

---

## 4. Primary Keys, Foreign Keys, & Cardinalities

| Table | Primary Key | Foreign Keys | Referenced PK | On Delete / On Update | Cardinality |
|---|---|---|---|---|---|
| `AddressType` | `AddressTypeID` (TINYINT PK) | — | — | — | — |
| `ShippingStatus` | `StatusID` (TINYINT PK) | — | — | — | — |
| `PaymentMethod` | `MethodID` (TINYINT PK) | — | — | — | — |
| `PriceLedgerSource`| `SourceID` (TINYINT PK) | — | — | — | — |
| `Customer` | `CustomerID` (BIGINT PK) | — | — | — | — |
| `CustomerPhone` | `PhoneID` (BIGINT PK) | `CustomerID` | `Customer.CustomerID` | RESTRICT / CASCADE | N:1 |
| `CustomerEmail` | `EmailID` (BIGINT PK) | `CustomerID` | `Customer.CustomerID` | RESTRICT / CASCADE | N:1 |
| `Address` | `AddressID` (BIGINT PK) | `CustomerID`<br>`AddressTypeID` | `Customer.CustomerID`<br>`AddressType.AddressTypeID` | RESTRICT / CASCADE<br>RESTRICT / CASCADE | N:1<br>N:1 |
| `Seller` | `SellerID` (BIGINT PK) | — | — | — | — |
| `Category` | `CategoryID` (BIGINT PK) | `ParentCategoryID` | `Category.CategoryID` | RESTRICT / CASCADE | N:1 (Self) |
| `Product` | `ProductID` (BIGINT PK) | `SellerID`<br>`CategoryID` | `Seller.SellerID`<br>`Category.CategoryID` | RESTRICT / CASCADE<br>RESTRICT / CASCADE | N:1<br>N:1 |
| `ProductImage` | `ImageID` (BIGINT PK) | `ProductID` | `Product.ProductID` | CASCADE / CASCADE | N:1 |
| `ProductEmbeddings`| `EmbeddingID` (BIGINT PK) | `ProductID` (UQ) | `Product.ProductID` | CASCADE / CASCADE | 1:1 |
| `PriceLedger` | `LedgerID` (BIGINT PK) | `ProductID`<br>`SourceID` | `Product.ProductID`<br>`PriceLedgerSource.SourceID` | RESTRICT / CASCADE<br>RESTRICT / CASCADE | N:1<br>N:1 |
| `Orders` | `OrderID` (BIGINT PK) | `CustomerID`<br>`ShippingStatusID` | `Customer.CustomerID`<br>`ShippingStatus.StatusID` | RESTRICT / CASCADE<br>RESTRICT / CASCADE | N:1<br>N:1 |
| `OrderPayment` | `PaymentID` (BIGINT PK) | `OrderID` (UQ)<br>`MethodID` | `Orders.OrderID`<br>`PaymentMethod.MethodID` | RESTRICT / CASCADE<br>RESTRICT / CASCADE | 1:1<br>N:1 |
| `OrderDetails` | `(OrderID, ProductID)` (Composite PK) | `OrderID`<br>`ProductID`<br>`LedgerID` | `Orders.OrderID`<br>`Product.ProductID`<br>`PriceLedger.LedgerID` | RESTRICT / CASCADE<br>RESTRICT / CASCADE<br>RESTRICT / CASCADE | N:1<br>N:1<br>N:1 |

> **Referential Integrity Guarantee:** `ON DELETE RESTRICT` is universally applied to orders, payments, customers, and price ledger items to prevent catastrophic cascading deletions of financial records.

---

## 5. Relational Normalization Proof (1NF through BCNF)

### First Normal Form (1NF)
- **Atomic Attributes:** No column contains composite values or delimiter-separated lists.
- **No Repeating Groups:** Multi-valued phones (`CustomerPhone`), emails (`CustomerEmail`), and images (`ProductImage`) are decomposed into independent child tables.
- **Primary Key:** Every relation possesses a uniquely identified primary key.

### Second Normal Form (2NF)
- A table is in 2NF if it is in 1NF and every non-prime attribute is fully functionally dependent on the primary key.
- Tables with single-attribute primary keys automatically satisfy 2NF.
- In `OrderDetails(OrderID, ProductID)`:
  - `Quantity` depends on `(OrderID, ProductID)`.
  - `ExactLedgerPrice` depends on the specific sale of that product in that order.
  - `LedgerID` identifies the exact price ledger version applied to this order line.
  - Therefore, no partial functional dependencies exist.

### Third Normal Form (3NF)
- A table is in 3NF if it is in 2NF and no transitive dependencies (X -> Y -> Z) exist among non-prime attributes.
- **Derived Totals Eliminated:** `Orders` does **not** store `TotalAmount`. Storing `TotalAmount` creates a transitive dependency on `OrderDetails (Quantity * ExactLedgerPrice)`. Instead, `TotalAmount` is calculated dynamically via `fn_calculate_order_total(OrderID)` or view queries.
- **Address Normalization:** `Address` references `AddressTypeID` via foreign key rather than storing free-text types.
- **Pricing Sources:** `PriceLedger` references `SourceID` in `PriceLedgerSource`.

### Boyce-Codd Normal Form (BCNF)
- A relation is in BCNF if for every non-trivial functional dependency X -> Y, X is a superkey.
- In every entity table in OmniCartDB, all determinants are superkeys (Candidate Keys: `CustomerID`, `EmailAddress`, `GSTIN`, `ProductID`, `OrderID`, etc.).
- Thus, OmniCartDB satisfies BCNF without update, insertion, or deletion anomalies.

---

## 6. Indexing Strategy & Performance Analysis

| Table | Index Name | Columns | Index Type | Query Accelerated & Trade-offs |
|---|---|---|---|---|
| `CustomerPhone` | `idx_custphone_phone` | `(PhoneNumber)` | B-Tree | Accelerates login and customer support lookup by phone. Minor write overhead on phone insert. |
| `CustomerPhone` | `idx_custphone_customer`| `(CustomerID)` | B-Tree | Accelerates retrieving profile phone numbers during checkout. |
| `CustomerEmail` | `idx_custemail_customer`| `(CustomerID)` | B-Tree | Accelerates listing all verified email addresses for a user profile. |
| `Address` | `idx_addr_customer` | `(CustomerID)` | B-Tree | Optimizes checkout address selection dropdowns. |
| `Address` | `idx_addr_city` | `(City)` | B-Tree | Accelerates regional delivery routing and geographical sales analytics. |
| `Address` | `idx_addr_pincode` | `(PINCode)` | B-Tree | Critical for delivery serviceability validation and shipping tier estimation. |
| `Seller` | `idx_seller_email` | `(ContactEmail)` | B-Tree | Vendor portal login and merchant communication lookup. |
| `Category` | `idx_category_parent` | `(ParentCategoryID)`| B-Tree | Accelerates hierarchical taxonomy queries (sub-category dropdowns). |
| `Category` | `idx_category_name` | `(CategoryName)` | B-Tree | Accelerates autocomplete and category search. |
| `Product` | `idx_product_seller` | `(SellerID)` | B-Tree | Accelerates merchant inventory dashboards (`WHERE SellerID = ?`). |
| `Product` | `idx_product_category`| `(CategoryID)` | B-Tree | Accelerates marketplace navigation filtering products by category. |
| `Product` | `idx_product_name` | `(Name)` | B-Tree | Prefix search on product title. |
| `Product` | `idx_product_stock` | `(StockQuantity)` | B-Tree | Powers low-stock alerts and back-office replenishment queues. |
| `Product` | `ft_product_search` | `(Name, Description)`| FULLTEXT | Natural language keyword search across catalog names and product descriptions. |
| `ProductImage` | `idx_prodimg_product` | `(ProductID)` | B-Tree | Product image gallery rendering on storefront product pages. |
| `PriceLedger` | `idx_ledger_product_time`| `(ProductID, RecordedAt DESC)`| Composite B-Tree | **Most critical index in system.** Accelerates finding latest product price in O(log N). |
| `PriceLedger` | `idx_ledger_product` | `(ProductID)` | B-Tree | Historical price graphing and volatility calculation. |
| `PriceLedger` | `idx_ledger_source` | `(SourceID)` | B-Tree | Auditing price alterations initiated by promotions vs. algorithmic adjusters. |
| `PriceLedger` | `idx_ledger_recorded` | `(RecordedAt)` | B-Tree | Period-specific inflation and price tracking reports. |
| `Orders` | `idx_order_customer_date`| `(CustomerID, OrderDate DESC)`| Composite B-Tree| Powers customer "My Orders" order history screen ordered chronologically. |
| `Orders` | `idx_order_status_date` | `(ShippingStatusID, OrderDate)`| Composite B-Tree| Logistics fulfillment queue (`WHERE ShippingStatusID = 1 ORDER BY OrderDate`). |
| `Orders` | `idx_order_date` | `(OrderDate)` | B-Tree | Monthly, quarterly, and annual sales accounting aggregations. |
| `OrderDetails` | `idx_od_product` | `(ProductID)` | B-Tree | Accelerates best-seller calculations and product return analysis. |
| `OrderDetails` | `idx_od_ledger` | `(LedgerID)` | B-Tree | Financial audit tracing Order Details back to the PriceLedger origin. |
| `OrderPayment` | `idx_payment_method` | `(MethodID)` | B-Tree | Aggregates revenue breakdown by payment gateway (UPI vs Credit Card). |
| `OrderPayment` | `idx_payment_date` | `(PaidAt)` | B-Tree | Daily cash flow reconciliation. |

---

## 7. Database Views (Reporting & Catalog Abstractions)

1. **`vw_current_product_price`**: Uses the MySQL 8.0 `ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY RecordedAt DESC, LedgerID DESC)` window function to return the single active price for every product.
2. **`vw_product_catalog`**: Joins `Product`, `Seller`, `Category`, and `vw_current_product_price` alongside `fn_product_stock_status()` to provide an end-to-end storefront catalog item representation.
3. **`vw_product_price_history`**: Chronological log of price fluctuations, percentage changes, and causal sources (`PriceLedgerSource`).
4. **`vw_order_summary`**: High-level order details with customer names, delivery status, and dynamically calculated `TotalAmount`.
5. **`vw_order_details`**: Line item breakdown computing `(Quantity * ExactLedgerPrice) AS LineTotal` with product names and shipping states.
6. **`vw_customer_order_summary`**: Customer lifetime value view aggregating completed order count and total spend.
7. **`vw_seller_product_catalog`**: Merchant-centric catalog displaying active listing counts, inventory, and current prices.
8. **`vw_category_product_count`**: Category distribution analysis calculating product densities across taxonomy nodes.
9. **`vw_low_stock_products`**: Proactive supply chain alert view filtering products where `StockQuantity <= 10`.
10. **`vw_product_embeddings_status`**: Identifies catalog gaps where machine learning embeddings have not yet been generated.

---

## 8. Deterministic Stored Functions

- **`fn_get_current_product_price(p_product_id)`**: Returns `DECIMAL(12,2)` representing the latest effective price from `PriceLedger`.
- **`fn_calculate_order_total(p_order_id)`**: Returns `DECIMAL(12,2)` computing `SUM(Quantity * ExactLedgerPrice)` strictly from immutable `OrderDetails`.
- **`fn_customer_order_count(p_customer_id)`**: Returns `INT` representing total orders placed by a customer.
- **`fn_customer_total_spent(p_customer_id)`**: Returns `DECIMAL(12,2)` calculating lifetime customer spend, excluding cancelled (`StatusID = 6`) orders.
- **`fn_product_stock_status(p_product_id)`**: Returns `VARCHAR(20)` evaluating inventory into `'OUT_OF_STOCK'`, `'LOW_STOCK'`, `'AVAILABLE'`, or `'NOT_FOUND'`.

---

## 9. Stored Procedures & Business Transactions

1. **`sp_create_customer`**: Atomic transaction creating `Customer`, initial `CustomerEmail`, and primary `CustomerPhone`.
2. **`sp_add_customer_address`**: Validates customer existence and resolves address type string into structured foreign key record.
3. **`sp_create_seller`**: Registers vendor with unique GSTIN verification.
4. **`sp_create_category`**: Inserts taxonomy nodes, calculating hierarchy `Level = parent.Level + 1`.
5. **`sp_create_product`**: Atomically creates product record and writes initial `PriceLedger` baseline entry.
6. **`sp_add_product_image`**: Adds media gallery URLs; resets existing primary images if `IsPrimary = 1`.
7. **`sp_add_product_embedding`**: Idempotent vector embedding upsert using `ON DUPLICATE KEY UPDATE`.
8. **`sp_add_price_ledger_entry`**: Append-only price recorder calculating `PriceFluctuation = (NewPrice - PreviousPrice)`.
9. **`sp_update_product_stock`**: Explicit stock level adjustment.
10. **`sp_place_order`** *(Core Transactional Engine)*:
    - Initiates transaction under serializable row-locking semantics.
    - Validates customer, products, quantities, and payment method.
    - Locks target inventory rows using `SELECT StockQuantity FROM Product WHERE ProductID = ? FOR UPDATE`.
    - Validates sufficient stock (`StockQuantity >= Quantity`).
    - Fetches latest valid `PriceLedger` record (`LedgerID`, `Price`).
    - Inserts `Orders` and writes locked `ExactLedgerPrice` into `OrderDetails`.
    - Atomically decrements `Product.StockQuantity`.
    - Records settlement record in `OrderPayment`.
    - Commits transaction; automatically triggers `ROLLBACK` on any `SQLEXCEPTION`.
11. **`sp_update_shipping_status`**: Transitions order through logistics lifecycle.
12. **`sp_cancel_order`**: Reverses inventory decrement atomically and transitions order status to `Cancelled` without modifying historical price records.

---

## 10. Database Triggers & Invariant Enforcement

1. **`trg_priceLedger_before_update`**: Intercepts any `UPDATE` statement on `PriceLedger` and throws error `45000` (`'PriceLedger is append-only. UPDATE operations are prohibited.'`).
2. **`trg_priceLedger_before_delete`**: Intercepts any `DELETE` statement on `PriceLedger` and throws error `45000` (`'PriceLedger is append-only. DELETE operations are prohibited.'`).
3. **`trg_orderDetails_before_insert`**: Validates that `Quantity > 0`, `ExactLedgerPrice >= 0`, and verifies that the referenced `LedgerID` belongs to the exact `ProductID` being purchased.
4. **`trg_orderDetails_before_update`**: Blocks post-creation modification of `OrderID`, `ProductID`, `ExactLedgerPrice`, or `LedgerID` to preserve financial auditability.
5. **`trg_orderDetails_before_delete`**: Prevents deletion of order line items if the order is already `Shipped (3)`, `In Transit (4)`, or `Delivered (5)`.

---

## 11. Transactional Integrity & Concurrency Control

### Solving the Overselling Problem:
When two concurrent users attempt to purchase the final unit of stock (`StockQuantity = 1`), an unmanaged read-modify-write cycle leads to negative inventory. 

`sp_place_order` solves this via InnoDB row-level write locks:
```sql
SELECT StockQuantity INTO v_current_stock
FROM Product 
WHERE ProductID = v_product_id 
FOR UPDATE;
```
- **Transaction 1** obtains an exclusive lock on the Product row.
- **Transaction 2** attempts to read the same Product row with `FOR UPDATE` and is blocked, entering a wait queue.
- Transaction 1 validates `StockQuantity = 1 >= 1`, decrements stock to `0`, inserts order items, and executes `COMMIT`.
- The lock is released. Transaction 2 unblocks, reads `StockQuantity = 0`, fails the check (`0 < 1`), raises a `45000` exception (`'Insufficient stock'`), and executes `ROLLBACK`.
- **Result:** Zero overselling, strict consistency.

---

## 12. Dynamic Pricing & The Append-Only Price Ledger

Price changes in modern e-commerce occur dynamically due to algorithmic repricing, promotional discounts, and seasonal campaigns. Modifying an in-place price column in the `Product` table violates financial auditing principles.

### Price Locking in Action:
When an order is created on `2026-02-15`, `sp_place_order` queries the latest price as of that date (`75999.00`, `LedgerID = 2`) and copies both values into `OrderDetails.ExactLedgerPrice` and `OrderDetails.LedgerID`. When the product price later drops to `74999.00` on `2026-03-01`, the order line item continues to read `75999.00`.

---

## 13. AI Visual Search & High-Dimensional Embeddings

Visual search in modern retail enables users to take a photo of an item and find visually similar listings. Machine learning models (e.g., CLIP, ResNet) convert product imagery into dense floating-point feature vectors (typically 512 or 768 dimensions).

### MySQL Schema Implementation:
`ProductEmbeddings` stores these vectors using the native MySQL `JSON` data type:
```sql
CREATE TABLE ProductEmbeddings (
    EmbeddingID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ProductID BIGINT UNSIGNED NOT NULL,
    FeatureVector JSON NOT NULL,
    ModelVersion VARCHAR(50) NOT NULL DEFAULT 'v1.0',
    CONSTRAINT uq_prodembedding_product UNIQUE (ProductID)
);
```

### Clarification on Indexing Limitations:
> **Important:** Standard relational B-Tree indexes **cannot** index high-dimensional feature vectors for Nearest-Neighbor (k-NN) similarity search. In OmniCart, MySQL acts as the **source of truth for feature vectors**. Vector similarity search (e.g., Cosine Similarity or Euclidean Distance) is performed either:
> 1. In the **Spring Boot application layer** (for smaller catalogs using in-memory matrix libraries), or
> 2. By synchronizing this table to a dedicated vector indexer (e.g., Milvus, Pinecone, or OpenSearch) via Change Data Capture (CDC).

---

## 14. Hierarchical Category Representation

Categories form an arbitrary-depth tree structure using an Adjacency List model with level annotations:
```sql
CREATE TABLE Category (
    CategoryID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL,
    Level TINYINT UNSIGNED NOT NULL DEFAULT 0,
    ParentCategoryID BIGINT UNSIGNED NULL DEFAULT NULL,
    CONSTRAINT fk_category_parent FOREIGN KEY (ParentCategoryID) REFERENCES Category(CategoryID),
    CONSTRAINT chk_category_no_self_ref CHECK (ParentCategoryID <> CategoryID)
);
```

### Tree Traversal via MySQL 8.0 Recursive CTE:
```sql
WITH RECURSIVE CategoryPath AS (
    SELECT CategoryID, CategoryName, ParentCategoryID, CAST(CategoryName AS CHAR(1000)) AS FullPath
    FROM Category
    WHERE ParentCategoryID IS NULL
    UNION ALL
    SELECT c.CategoryID, c.CategoryName, c.ParentCategoryID, CONCAT(cp.FullPath, ' -> ', c.CategoryName)
    FROM Category c
    INNER JOIN CategoryPath cp ON c.ParentCategoryID = cp.CategoryID
)
SELECT * FROM CategoryPath;
```

---

## 15. Role-Based Access Control (RBAC) & Security Grants

OmniCart implements the Principle of Least Privilege across three database roles/users:

1. **`omnicart_app`** (Spring Boot Application Service Account):
   - Granted `SELECT, INSERT, UPDATE` on core entities.
   - Granted **`INSERT, SELECT` ONLY** on `PriceLedger` (enforcing append-only architecture at user privilege level).
   - Granted `EXECUTE` on all stored procedures and functions.
   - Prohibited from `DROP, ALTER, CREATE, TRUNCATE`.
2. **`omnicart_readonly`** (BI / Reporting / Analytics Service Account):
   - Granted `SELECT` across all tables and views.
   - Granted `EXECUTE` on deterministic stored functions.
   - Prohibited from all data modification commands.
3. **`omnicart_admin`** (DBA / Flyway / Liquibase Migration Account):
   - Granted full administrative privileges (`ALL PRIVILEGES`) scoped to `OmniCartDB`.

---

## 16. Seed Data & Sample Scenarios

The seed dataset in `09_seed_data.sql` models a realistic Indian e-commerce marketplace:
- **5 Verified Customers:** Complete with localized phone numbers (`+91`), unique emails, and classified addresses (Home, Work) across Mumbai, Delhi, Bangalore, Hyderabad, and Chennai.
- **4 Registered Sellers:** Featuring validated 15-character GSTINs (e.g., `27AABCT1234F1ZP`).
- **10 Hierarchical Categories:** Spanning Electronics, Apparel, Home & Kitchen, and Sports.
- **15 Products:** Spanning high-end smartphones, laptops, apparel, and home goods.
- **25 Price Ledger Records:** Demonstrating initial listings, promotional markdowns, and subsequent price hikes.
- **10 Orders & Payments:** Demonstrating multiple states (`Pending`, `Processing`, `Shipped`, `In Transit`, `Delivered`, `Cancelled`).

---

## 17. High-Scale Synthetic Data Generation (100,000+ Rows)

For performance benchmarking and query optimizer testing, `10_large_test_data.sql` provides the `sp_generate_test_data(IN p_scale INT)` procedure:

```sql
CALL sp_generate_test_data(1);   -- Generates ~1,000 records (smoke benchmark)
CALL sp_generate_test_data(10);  -- Generates ~10,000 records (integration benchmark)
CALL sp_generate_test_data(100); -- Generates 100,000+ records (stress benchmark)
```

---

## 18. Test Suite & Analytical Reporting Queries

- **`11_test_queries.sql`**: Contains 30 test scenarios including:
  - Customer registration via procedure.
  - Category tree expansion.
  - Multi-item order placement under row locking.
  - Validation of stock decrement.
  - Verification that historical orders do not mutate after a price increase.
  - Trigger violation checks (append-only enforcement, negative price rejection).
  - Relational operators (`IN`, `NOT IN`, `EXISTS`, `NOT EXISTS`, `ANY`, `ALL`).
- **`12_reporting_queries.sql`**: Contains 18 enterprise BI reports including:
  - Monthly gross merchandise value (GMV).
  - Best-selling products by units and revenue.
  - Vendor sales leaderboard.
  - Customer lifetime value (CLV) ranking.
  - Dead stock analysis (products with no sales).
  - Category revenue distribution.

---

## 19. Script Execution Order & Deployment Guide

### Option 1: Unified One-Click Execution (Recommended)
Run the master consolidated script directly in your MySQL shell:
```bash
mysql -u root -p < omnicart_full_schema.sql
```

### Option 2: Modular Step-by-Step Execution
If deploying via CI/CD migration tools, execute files in this strict sequence:
```bash
mysql -u root -p < 01_database.sql
mysql -u root -p < 02_tables.sql
mysql -u root -p < 03_indexes.sql
mysql -u root -p < 04_constraints.sql
mysql -u root -p < 06_functions.sql
mysql -u root -p < 07_procedures.sql
mysql -u root -p < 05_triggers.sql
mysql -u root -p < 08_views.sql
mysql -u root -p < 09_seed_data.sql
mysql -u root -p < 10_large_test_data.sql
mysql -u root -p < 11_test_queries.sql
mysql -u root -p < 12_reporting_queries.sql
mysql -u root -p < 13_security_grants.sql
```

---

## 20. Spring Boot Backend Integration Guide

### 1. `application.yml` Configuration
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/OmniCartDB?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
    username: omnicart_app
    password: AppSecurePass2024!
    driver-class-name: com.mysql.cj.jdbc.Driver
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      idle-timeout: 300000
      connection-timeout: 20000
  jpa:
    hibernate:
      ddl-auto: validate # Database schema is managed via SQL scripts
    show-sql: true
    properties:
      hibernate:
        format_sql: true
        dialect: org.hibernate.dialect.MySQLDialect
```

### 2. JPA Entity Example (OrderDetails with Embedded Composite Key)
```java
@Embeddable
public class OrderDetailId implements Serializable {
    private Long orderId;
    private Long productId;
    // Getters, Setters, hashCode, equals
}

@Entity
@Table(name = "OrderDetails")
public class OrderDetail {
    @EmbeddedId
    private OrderDetailId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("orderId")
    @JoinColumn(name = "OrderID")
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("productId")
    @JoinColumn(name = "ProductID")
    private Product product;

    @Column(name = "Quantity", nullable = false)
    private Integer quantity;

    @Column(name = "ExactLedgerPrice", precision = 12, scale = 2, nullable = false, updatable = false)
    private BigDecimal exactLedgerPrice;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "LedgerID", nullable = false, updatable = false)
    private PriceLedger priceLedger;

    // Getters and Setters
}
```

### 3. Calling `sp_place_order` from Spring Data JPA
```java
@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    @Procedure(procedureName = "sp_place_order")
    void placeOrder(
        @Param("p_customer_id") Long customerId,
        @Param("p_product_ids") String productIdsJson,
        @Param("p_quantities") String quantitiesJson,
        @Param("p_payment_method_id") Integer paymentMethodId,
        @Param("p_order_id") Long[] orderIdOut
    );
}
```

---

## 21. Final Architectural Validation Checklist

| Architectural Checkpoint | Status | Verification Detail |
|---|---|---|
| Foreign Keys Reference Valid Keys | Passed | All child table FKs map to explicit primary or unique keys. |
| No Circular Dependencies | Passed | Table creation sequence creates parent entities before dependent tables. |
| Append-Only Price Ledger | Passed | Triggers block `UPDATE` and `DELETE`; RBAC grants only `INSERT, SELECT`. |
| Historical Price Locking | Passed | `OrderDetails.ExactLedgerPrice` snapshots ledger value; triggers reject changes. |
| Negative Stock Prevention | Passed | Managed by `INT UNSIGNED` type constraint and `sp_place_order` checks. |
| Race Condition Elimination | Passed | `SELECT ... FOR UPDATE` locks rows during checkout. |
| Derived Totals Consistency | Passed | Derived on-the-fly via `fn_calculate_order_total` and views. |
| Embedding 1:1 Relationship | Passed | Enforced via `UNIQUE (ProductID)` constraint on `ProductEmbeddings`. |
| Category Hierarchy Integrity | Passed | Self-referencing FK with `CHECK (ParentCategoryID <> CategoryID)`. |
| Normalization Standard | Passed | All relations satisfy 3NF and BCNF. |
| Spring Boot Compatibility | Passed | Standard identity patterns, PascalCase tables, clean JPA mappings. |
