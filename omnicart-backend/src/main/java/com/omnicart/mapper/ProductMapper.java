package com.omnicart.mapper;

import com.omnicart.dto.response.ProductImageResponse;
import com.omnicart.dto.response.ProductResponse;
import com.omnicart.entity.Product;

import java.math.BigDecimal;
import java.util.stream.Collectors;

public class ProductMapper {
    public static ProductResponse toResponse(Product product, BigDecimal currentPrice) {
        if (product == null) return null;
        ProductResponse res = new ProductResponse();
        res.setId(product.getId());
        res.setName(product.getName());
        res.setDescription(product.getDescription());
        res.setStockQuantity(product.getStockQuantity());
        
        if (product.getStockQuantity() == 0) {
            res.setStockStatus("OUT_OF_STOCK");
        } else if (product.getStockQuantity() <= 10) {
            res.setStockStatus("LOW_STOCK");
        } else {
            res.setStockStatus("AVAILABLE");
        }

        res.setCurrentPrice(currentPrice != null ? currentPrice : BigDecimal.ZERO);
        if (product.getSeller() != null) {
            res.setSellerId(product.getSeller().getId());
            res.setSellerName(product.getSeller().getCompanyName());
        }
        if (product.getCategory() != null) {
            res.setCategoryId(product.getCategory().getId());
            res.setCategoryName(product.getCategory().getCategoryName());
        }
        if (product.getImages() != null) {
            res.setImages(product.getImages().stream()
                    .map(img -> new ProductImageResponse(img.getId(), img.getImageUrl(), img.getDisplayOrder(), img.getIsPrimary()))
                    .collect(Collectors.toList()));
        }
        res.setHasEmbedding(product.getEmbedding() != null);
        res.setCreatedAt(product.getCreatedAt());
        return res;
    }
}
