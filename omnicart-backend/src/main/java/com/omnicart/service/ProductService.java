package com.omnicart.service;

import com.omnicart.dto.request.ProductCreateRequest;
import com.omnicart.dto.request.ProductUpdateRequest;
import com.omnicart.dto.response.ProductResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.util.List;

public interface ProductService {
    ProductResponse createProduct(ProductCreateRequest request);
    ProductResponse getProductById(Long id);
    ProductResponse updateProduct(Long id, ProductUpdateRequest request);
    void deleteProduct(Long id);
    Page<ProductResponse> getAllProducts(Pageable pageable, Long categoryId, Long sellerId, BigDecimal minPrice, BigDecimal maxPrice);
    Page<ProductResponse> searchProducts(String keyword, Pageable pageable);
    List<ProductResponse> getLowStockProducts();
    Page<ProductResponse> getProductsByCategoryId(Long categoryId, Pageable pageable);
    Page<ProductResponse> getProductsBySellerId(Long sellerId, Pageable pageable);
}
