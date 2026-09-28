package com.omnicart.service;

import com.omnicart.dto.request.ProductImageRequest;
import com.omnicart.dto.response.ProductImageResponse;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface ProductImageService {
    ProductImageResponse addImage(Long productId, ProductImageRequest request);
    ProductImageResponse uploadImage(Long productId, MultipartFile file, Boolean isPrimary);
    List<ProductImageResponse> getProductImages(Long productId);
    void deleteImage(Long imageId);
}
