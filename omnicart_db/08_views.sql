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
