-- 14_catalog_seed.sql
-- Seeds default verified merchant, products, prices, images, and embeddings into OmniCartDB
USE OmniCartDB;

-- 1. Insert Verified Merchant Seller
INSERT INTO Seller (SellerID, CompanyName, GSTIN, ContactEmail, ContactPhone, created_at, updated_at)
VALUES (1, 'Apex Tech Store', '29ABCDE1234F1Z5', 'merchant@omnicart.com', '9876543210', NOW(), NOW())
ON DUPLICATE KEY UPDATE CompanyName = VALUES(CompanyName);

-- 2. Insert Products
INSERT INTO Product (ProductID, Name, Description, StockQuantity, SellerID, CategoryID, created_at, updated_at)
VALUES 
(1, 'Apex Chrono Cyber Watch v3', 'Next-gen titanium cybernetic smartwatch with biometric sensors, AMOLED retina display, and 14-day battery life.', 25, 1, 1, NOW(), NOW()),
(2, 'Falcon-X 4K Gimbal Drone', 'Ultra-stable quadcopter drone featuring 3-axis mechanical gimbal, 4K HDR 60fps video, and 8km transmission range.', 12, 1, 1, NOW(), NOW()),
(3, 'Pro Mechanical RGB Keyboard', 'Hot-swappable tactile switches, per-key RGB backlighting, sound-dampening foam, and aircraft-grade aluminum frame.', 40, 1, 1, NOW(), NOW()),
(4, 'AcousticStudio ANC Wireless Headphones', 'Studio-grade over-ear wireless headphones with hybrid active noise cancellation, spatial audio, and 40-hour playback.', 18, 1, 1, NOW(), NOW()),
(5, 'CyberGlow Neural Desk Mat RGB', 'Extended microfiber speed-surface gaming desk mat with customizable 360-degree dual-zone RGB edges and non-slip rubber base.', 35, 1, 1, NOW(), NOW()),
(6, 'Quantum ANC Wireless Earbuds Pro', 'True wireless stereo earbuds with transparency mode, wireless charging case, low-latency gaming mode, and IPX7 water resistance.', 50, 1, 1, NOW(), NOW()),
(7, 'Digital Air Fryer Pro 6.5 Litre', 'Rapid 360-degree air circulation cooker with 12 preset digital cooking modes and dishwasher-safe non-stick basket.', 15, 1, 9, NOW(), NOW()),
(8, 'Smart Ambient Gradient Light Bar', 'Voice-controlled RGBIC desktop ambient bar with screen sync and sound reactivity for modern workstation setups.', 30, 1, 1, NOW(), NOW()),
(9, 'GaN 100W Fast Charger 4-Port', 'Gallium Nitride high-efficiency compact multi-port fast power brick for laptops, smartphones, and mobile accessories.', 45, 1, 1, NOW(), NOW()),
(10, 'Sonic Dental Care Power Wand', '40,000 VPM ultrasonic power electric toothbrush with 5 intelligent cleaning modes, smart timer, and wireless charging dock.', 22, 1, 3, NOW(), NOW()),
(11, 'Braided Type-C 240W Cable 2M', 'Heavy-duty nylon braided Power Delivery 3.1 ultra-fast charging and data cable with aluminum alloy connectors.', 80, 1, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE 
    Name = VALUES(Name), 
    Description = VALUES(Description), 
    StockQuantity = VALUES(StockQuantity),
    CategoryID = VALUES(CategoryID);

-- 3. Insert Initial Prices into PriceLedger (only if not already recorded)
INSERT INTO PriceLedger (ProductID, SourceID, RecordedAt, Price, PriceFluctuation)
SELECT 1, 1, NOW(), 4999.00, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM PriceLedger WHERE ProductID = 1)
UNION ALL SELECT 2, 1, NOW(), 38999.00, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM PriceLedger WHERE ProductID = 2)
UNION ALL SELECT 3, 1, NOW(), 6499.00, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM PriceLedger WHERE ProductID = 3)
UNION ALL SELECT 4, 1, NOW(), 12999.00, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM PriceLedger WHERE ProductID = 4)
UNION ALL SELECT 5, 1, NOW(), 1899.00, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM PriceLedger WHERE ProductID = 5)
UNION ALL SELECT 6, 1, NOW(), 4499.00, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM PriceLedger WHERE ProductID = 6)
UNION ALL SELECT 7, 1, NOW(), 7999.00, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM PriceLedger WHERE ProductID = 7)
UNION ALL SELECT 8, 1, NOW(), 2499.00, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM PriceLedger WHERE ProductID = 8)
UNION ALL SELECT 9, 1, NOW(), 2999.00, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM PriceLedger WHERE ProductID = 9)
UNION ALL SELECT 10, 1, NOW(), 1999.00, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM PriceLedger WHERE ProductID = 10)
UNION ALL SELECT 11, 1, NOW(), 799.00, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM PriceLedger WHERE ProductID = 11);

-- 4. Insert Primary Images
DELETE FROM ProductImage WHERE ProductID BETWEEN 1 AND 11;
INSERT INTO ProductImage (ProductID, ImageURL, DisplayOrder, IsPrimary, created_at)
VALUES 
(1, 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?auto=format&fit=crop&w=500&q=80', 1, 1, NOW()),
(2, 'https://images.unsplash.com/photo-1527977966376-1c8408f9f108?auto=format&fit=crop&w=500&q=80', 1, 1, NOW()),
(3, 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=500&q=80', 1, 1, NOW()),
(4, 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=500&q=80', 1, 1, NOW()),
(5, 'https://images.unsplash.com/photo-1616440347437-b1c73416efc2?auto=format&fit=crop&w=500&q=80', 1, 1, NOW()),
(6, 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=500&q=80', 1, 1, NOW()),
(7, 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=500&q=80', 1, 1, NOW()),
(8, 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=500&q=80', 1, 1, NOW()),
(9, 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?auto=format&fit=crop&w=500&q=80', 1, 1, NOW()),
(10, 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?auto=format&fit=crop&w=500&q=80', 1, 1, NOW()),
(11, 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=500&q=80', 1, 1, NOW());
