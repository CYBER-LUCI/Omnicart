package com.omnicart.service;

import com.omnicart.dto.response.ProductResponse;

public interface InventoryService {
    int getStock(Long productId);
    ProductResponse setStock(Long productId, int quantity);
    ProductResponse addStock(Long productId, int quantity);
    ProductResponse removeStock(Long productId, int quantity);
}
