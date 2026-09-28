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
