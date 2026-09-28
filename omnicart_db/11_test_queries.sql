-- =========================================================================
-- FILE 2: 11_test_queries.sql
-- DESCRIPTION: Contains numbered test queries with expected behaviors.
-- =========================================================================

USE OmniCartDB;

-- Test 1: Insert a new customer using stored procedure
CALL sp_create_customer('Test', 'User', 'test.user@example.com', '+91-9999999999', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', @new_cust_id);
SELECT @new_cust_id AS NewCustomerID;

-- Test 2: Add address for customer
CALL sp_add_customer_address(@new_cust_id, '42', 'MG Road', 'Mumbai', '400001', 'Home', @new_addr_id);
SELECT * FROM Address WHERE AddressID = @new_addr_id;

-- Test 3: Insert a new seller
CALL sp_create_seller('TestMart', '29AABCT9999F1Z9', 'test@testmart.com', '+91-8888888888', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', @new_seller_id);
SELECT @new_seller_id AS NewSellerID;

-- Test 4: Create category hierarchy
CALL sp_create_category('Test Root', 'A test root category', NULL, @root_cat_id);
CALL sp_create_category('Test Sub', 'A test sub category', @root_cat_id, @sub_cat_id);
SELECT * FROM Category WHERE CategoryID IN (@root_cat_id, @sub_cat_id);

-- Test 5: Insert product with initial price
CALL sp_create_product('Test Product', 'A test product description', 100, @new_seller_id, @sub_cat_id, 999.99, @new_prod_id);
SELECT * FROM Product WHERE ProductID = @new_prod_id;
SELECT * FROM PriceLedger WHERE ProductID = @new_prod_id;

-- Test 6: Add product image
CALL sp_add_product_image(@new_prod_id, '/images/test_product_1.jpg', 1, 1, @img_id);
SELECT * FROM ProductImage WHERE ImageID = @img_id;

-- Test 7: Add product embedding
CALL sp_add_product_embedding(@new_prod_id, '[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]', 'v2.0', @embed_id);
SELECT * FROM ProductEmbeddings WHERE EmbeddingID = @embed_id;

-- Test 8: Add a new price (price change)
CALL sp_add_price_ledger_entry(@new_prod_id, 1099.99, 2, @ledger_id);
SELECT * FROM PriceLedger WHERE ProductID = @new_prod_id ORDER BY RecordedAt DESC;

-- Test 9: Retrieve current price
SELECT fn_get_current_product_price(@new_prod_id) AS CurrentPrice;

-- Test 10: Retrieve price history via view
SELECT * FROM vw_product_price_history WHERE ProductID = @new_prod_id;

-- Test 11: Place an order (this is the key test)
CALL sp_place_order(@new_cust_id, JSON_ARRAY(@new_prod_id), JSON_ARRAY(2), 3, @order_id);
SELECT * FROM Orders WHERE OrderID = @order_id;
SELECT * FROM OrderDetails WHERE OrderID = @order_id;
SELECT * FROM OrderPayment WHERE OrderID = @order_id;

-- Test 12: Verify stock was reduced
-- Should be 100 - 2 = 98
SELECT StockQuantity FROM Product WHERE ProductID = @new_prod_id;

-- Test 13: Calculate order total
-- Should be 2 * 1099.99 = 2199.98
SELECT fn_calculate_order_total(@order_id) AS OrderTotal;

-- Test 14: Retrieve customer's orders via view
SELECT * FROM vw_order_summary WHERE CustomerID = @new_cust_id;

-- Test 15: Retrieve seller's products via view
SELECT * FROM vw_seller_product_catalog WHERE SellerID = @new_seller_id;

-- Test 16: Category products via view
SELECT * FROM vw_category_product_count;

-- Test 17: Low stock products
SELECT * FROM vw_low_stock_products;

-- Test 18: Products without embeddings
SELECT * FROM vw_product_embeddings_status WHERE EmbeddingStatus = 'NO_EMBEDDING';

-- Test 19: Full-text product search
-- Note: Requires MATCH index on Name, Description. Results depend on sample data.
SELECT * FROM Product WHERE MATCH(Name, Description) AGAINST('Samsung Galaxy' IN NATURAL LANGUAGE MODE);

-- Test 20: Test FK enforcement - insert order for non-existent customer (should fail)
-- INSERT INTO Orders (CustomerID, ShippingStatusID) VALUES (99999, 1);
-- Expected: Error - foreign key constraint fails

-- Test 21: Test unique email enforcement
-- INSERT INTO CustomerEmail (CustomerID, EmailAddress) VALUES (1, 'test.user@example.com');
-- Expected: Error - duplicate entry for unique key

-- Test 22: Test negative stock prevention via unsigned
-- UPDATE Product SET StockQuantity = StockQuantity - 9999 WHERE ProductID = @new_prod_id;
-- Expected: Error - out of range for unsigned

-- Test 23: Test append-only PriceLedger (UPDATE should fail)
-- UPDATE PriceLedger SET Price = 0 WHERE LedgerID = @ledger_id;
-- Expected: Error from trigger preventing update on PriceLedger

-- Test 24: Test price immutability - change price then verify old order unchanged
CALL sp_add_price_ledger_entry(@new_prod_id, 1299.99, 2, @new_ledger_id);
SELECT ExactLedgerPrice FROM OrderDetails WHERE OrderID = @order_id AND ProductID = @new_prod_id;
-- Should still be 1099.99, NOT 1299.99

-- Test 25: Test concurrent stock conceptually
-- Conceptual test: In sp_place_order, using SELECT StockQuantity FROM Product WHERE ProductID = X FOR UPDATE
-- locks the row, ensuring that concurrent transactions checking stock will wait, preventing race conditions (overselling).

-- Test 26: IN / NOT IN examples
SELECT * FROM Product WHERE CategoryID IN (SELECT CategoryID FROM Category WHERE Level = 1);
SELECT * FROM Customer WHERE CustomerID NOT IN (SELECT DISTINCT CustomerID FROM Orders);

-- Test 27: EXISTS / NOT EXISTS examples
SELECT * FROM Product p WHERE EXISTS (SELECT 1 FROM ProductEmbeddings pe WHERE pe.ProductID = p.ProductID);
SELECT * FROM Product p WHERE NOT EXISTS (SELECT 1 FROM ProductImage pi WHERE pi.ProductID = p.ProductID);

-- Test 28: ANY / ALL examples
SELECT * FROM Product WHERE StockQuantity > ANY (SELECT StockQuantity FROM Product WHERE CategoryID = 5);
SELECT * FROM Product WHERE StockQuantity >= ALL (SELECT StockQuantity FROM Product WHERE CategoryID = 5);

-- Test 29: Cancel order test
CALL sp_cancel_order(@order_id);
SELECT StockQuantity FROM Product WHERE ProductID = @new_prod_id;
-- Stock should be restored to 100
SELECT ss.StatusName FROM Orders o JOIN ShippingStatus ss ON o.ShippingStatusID = ss.StatusID WHERE o.OrderID = @order_id;
-- Should be 'Cancelled'

-- Test 30: Update shipping status
-- Create another order first
CALL sp_place_order(@new_cust_id, JSON_ARRAY(@new_prod_id), JSON_ARRAY(1), 1, @order_id2);
CALL sp_update_shipping_status(@order_id2, 3);
SELECT ss.StatusName FROM Orders o JOIN ShippingStatus ss ON o.ShippingStatusID = ss.StatusID WHERE o.OrderID = @order_id2;
-- Should be 'Shipped'
