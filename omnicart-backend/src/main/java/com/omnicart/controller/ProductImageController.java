package com.omnicart.controller;

import com.omnicart.dto.request.ProductImageRequest;
import com.omnicart.dto.response.ApiResponse;
import com.omnicart.dto.response.ProductImageResponse;
import com.omnicart.service.ProductImageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@Tag(name = "Product Images", description = "APIs for product media gallery and file uploads")
public class ProductImageController {

    private final ProductImageService productImageService;

    public ProductImageController(ProductImageService productImageService) {
        this.productImageService = productImageService;
    }

    @PostMapping("/api/products/{productId}/images")
    @Operation(summary = "Add image URL to product")
    public ResponseEntity<ApiResponse<ProductImageResponse>> addImage(
            @PathVariable Long productId,
            @Valid @RequestBody ProductImageRequest request) {
        ProductImageResponse res = productImageService.addImage(productId, request);
        return new ResponseEntity<>(ApiResponse.success("Image added", res), HttpStatus.CREATED);
    }

    @PostMapping(value = "/api/products/{productId}/images/upload", consumes = "multipart/form-data")
    @Operation(summary = "Upload image file for product")
    public ResponseEntity<ApiResponse<ProductImageResponse>> uploadImage(
            @PathVariable Long productId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "isPrimary", required = false, defaultValue = "false") Boolean isPrimary) {
        ProductImageResponse res = productImageService.uploadImage(productId, file, isPrimary);
        return new ResponseEntity<>(ApiResponse.success("Image uploaded", res), HttpStatus.CREATED);
    }

    @GetMapping("/api/products/{productId}/images")
    @Operation(summary = "Get all images for a product")
    public ResponseEntity<ApiResponse<List<ProductImageResponse>>> getProductImages(@PathVariable Long productId) {
        return ResponseEntity.ok(ApiResponse.success(productImageService.getProductImages(productId)));
    }

    @DeleteMapping("/api/product-images/{imageId}")
    @Operation(summary = "Delete product image")
    public ResponseEntity<ApiResponse<Void>> deleteImage(@PathVariable Long imageId) {
        productImageService.deleteImage(imageId);
        return ResponseEntity.ok(ApiResponse.success("Image deleted", null));
    }
}
