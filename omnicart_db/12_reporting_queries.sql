-- =========================================================================
-- FILE 3: 12_reporting_queries.sql
-- DESCRIPTION: Analytical and reporting queries for OmniCartDB.
-- =========================================================================

USE OmniCartDB;

-- 1. Total sales revenue (sum of all order details where order not cancelled)
SELECT 
    SUM(od.Quantity * od.ExactLedgerPrice) AS TotalSalesRevenue
FROM OrderDetails od
JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.ShippingStatusID != 6; -- 6 is Cancelled

-- 2. Sales by customer (customer name, total orders, total spent)
SELECT 
    c.CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    SUM(od.Quantity * od.ExactLedgerPrice) AS TotalSpent
FROM Customer c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE o.ShippingStatusID != 6
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;

-- 3. Sales by seller (seller name, total products sold, total revenue)
SELECT 
    s.SellerID,
    s.CompanyName AS SellerName,
    SUM(od.Quantity) AS TotalProductsSold,
    SUM(od.Quantity * od.ExactLedgerPrice) AS TotalRevenue
FROM Seller s
JOIN Product p ON s.SellerID = p.SellerID
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.ShippingStatusID != 6
GROUP BY s.SellerID, s.CompanyName
ORDER BY TotalRevenue DESC;

-- 4. Sales by category
SELECT 
    cat.CategoryID,
    cat.CategoryName,
    SUM(od.Quantity) AS UnitsSold,
    SUM(od.Quantity * od.ExactLedgerPrice) AS Revenue
FROM Category cat
JOIN Product p ON cat.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.ShippingStatusID != 6
GROUP BY cat.CategoryID, cat.CategoryName
ORDER BY Revenue DESC;

-- 5. Best-selling products (by quantity sold)
SELECT 
    p.ProductID,
    p.Name,
    SUM(od.Quantity) AS TotalQuantitySold
FROM Product p
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.ShippingStatusID != 6
GROUP BY p.ProductID, p.Name
ORDER BY TotalQuantitySold DESC
LIMIT 10;

-- 6. Low stock products (stock <= 10)
SELECT 
    ProductID,
    Name,
    StockQuantity
FROM Product
WHERE StockQuantity <= 10
ORDER BY StockQuantity ASC;

-- 7. Order count by customer
SELECT 
    c.CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM Customer c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY OrderCount DESC;

-- 8. Revenue by month
SELECT 
    YEAR(o.OrderDate) AS OrderYear,
    MONTH(o.OrderDate) AS OrderMonth,
    SUM(od.Quantity * od.ExactLedgerPrice) AS MonthlyRevenue
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE o.ShippingStatusID != 6
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY OrderYear DESC, OrderMonth DESC;

-- 9. Latest price of each product (using view)
SELECT * FROM vw_current_product_price;

-- 10. Price history of a specific product (Replace 1 with desired ProductID)
SELECT * FROM vw_product_price_history WHERE ProductID = 1 ORDER BY RecordedAt DESC;

-- 11. Products with no images
SELECT 
    p.ProductID,
    p.Name
FROM Product p
LEFT JOIN ProductImage pi ON p.ProductID = pi.ProductID
WHERE pi.ImageID IS NULL;

-- 12. Products with no embeddings
SELECT 
    p.ProductID,
    p.Name
FROM Product p
LEFT JOIN ProductEmbeddings pe ON p.ProductID = pe.ProductID
WHERE pe.EmbeddingID IS NULL;

-- 13. Customers with no orders
SELECT 
    c.CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName
FROM Customer c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;

-- 14. Sellers with no products
SELECT 
    s.SellerID,
    s.CompanyName
FROM Seller s
LEFT JOIN Product p ON s.SellerID = p.SellerID
WHERE p.ProductID IS NULL;

-- 15. Average order value
SELECT 
    AVG(OrderTotal) AS AverageOrderValue
FROM (
    SELECT o.OrderID, SUM(od.Quantity * od.ExactLedgerPrice) AS OrderTotal
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.ShippingStatusID != 6
    GROUP BY o.OrderID
) AS OrderTotals;

-- 16. Payment method distribution
SELECT 
    pm.MethodName,
    COUNT(op.PaymentID) AS PaymentCount,
    SUM(op.PaidAmount) AS TotalVolume
FROM PaymentMethod pm
JOIN OrderPayment op ON pm.MethodID = op.MethodID
GROUP BY pm.MethodName
ORDER BY PaymentCount DESC;

-- 17. Top spending customers
SELECT 
    c.CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    SUM(op.PaidAmount) AS TotalPaid
FROM Customer c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderPayment op ON o.OrderID = op.OrderID
WHERE o.ShippingStatusID != 6
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalPaid DESC
LIMIT 10;

-- 18. Category hierarchy with product counts
SELECT * FROM vw_category_product_count;
