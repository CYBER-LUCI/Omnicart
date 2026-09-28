package com.omnicart.service.impl;

import com.omnicart.dto.request.ProductImageRequest;
import com.omnicart.dto.response.ProductImageResponse;
import com.omnicart.entity.Product;
import com.omnicart.entity.ProductImage;
import com.omnicart.exception.ProductNotFoundException;
import com.omnicart.exception.ResourceNotFoundException;
import com.omnicart.repository.ProductImageRepository;
import com.omnicart.repository.ProductRepository;
import com.omnicart.service.ProductImageService;
import com.omnicart.util.FileStorageUtil;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductImageServiceImpl implements ProductImageService {

    private final ProductImageRepository productImageRepository;
    private final ProductRepository productRepository;
    private final FileStorageUtil fileStorageUtil;

    public ProductImageServiceImpl(ProductImageRepository productImageRepository,
                                   ProductRepository productRepository,
                                   FileStorageUtil fileStorageUtil) {
        this.productImageRepository = productImageRepository;
        this.productRepository = productRepository;
        this.fileStorageUtil = fileStorageUtil;
    }

    @Override
    @Transactional
    public ProductImageResponse addImage(Long productId, ProductImageRequest request) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ProductNotFoundException(productId));

        ProductImage image = new ProductImage(product, request.getImageUrl(), request.getDisplayOrder(), request.getIsPrimary());
        ProductImage saved = productImageRepository.save(image);
        return new ProductImageResponse(saved.getId(), saved.getImageUrl(), saved.getDisplayOrder(), saved.getIsPrimary());
    }

    @Override
    @Transactional
    public ProductImageResponse uploadImage(Long productId, MultipartFile file, Boolean isPrimary) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ProductNotFoundException(productId));

        try {
            String path = fileStorageUtil.storeFile(file);
            ProductImage image = new ProductImage(product, path, 1, isPrimary != null ? isPrimary : false);
            ProductImage saved = productImageRepository.save(image);
            return new ProductImageResponse(saved.getId(), saved.getImageUrl(), saved.getDisplayOrder(), saved.getIsPrimary());
        } catch (IOException e) {
            throw new RuntimeException("Failed to upload image file: " + e.getMessage());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProductImageResponse> getProductImages(Long productId) {
        return productImageRepository.findByProductIdOrderByDisplayOrderAsc(productId).stream()
                .map(img -> new ProductImageResponse(img.getId(), img.getImageUrl(), img.getDisplayOrder(), img.getIsPrimary()))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void deleteImage(Long imageId) {
        if (!productImageRepository.existsById(imageId)) {
            throw new ResourceNotFoundException("ProductImage not found with ID: " + imageId);
        }
        productImageRepository.deleteById(imageId);
    }
}
