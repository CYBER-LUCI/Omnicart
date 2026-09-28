package com.omnicart.controller;

import com.omnicart.dto.request.ProductCreateRequest;
import com.omnicart.dto.request.ProductUpdateRequest;
import com.omnicart.dto.response.ApiResponse;
import com.omnicart.dto.response.PageResponse;
import com.omnicart.dto.response.ProductResponse;
import com.omnicart.service.ProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/products")
@Tag(name = "Product Catalog", description = "Core product management, search, and catalog filtering")
public class ProductController {

    private final ProductService productService;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @PostMapping
    @Operation(summary = "Create product with initial price in PriceLedger")
    public ResponseEntity<ApiResponse<ProductResponse>> createProduct(@Valid @RequestBody ProductCreateRequest request) {
        ProductResponse res = productService.createProduct(request);
        return new ResponseEntity<>(ApiResponse.success("Product created", res), HttpStatus.CREATED);
    }

    @GetMapping
    @Operation(summary = "List products with optional category/seller/price filters")
    public ResponseEntity<ApiResponse<PageResponse<ProductResponse>>> getAllProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long sellerId,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice) {
        Page<ProductResponse> products = productService.getAllProducts(PageRequest.of(page, size), categoryId, sellerId, minPrice, maxPrice);
        return ResponseEntity.ok(ApiResponse.success(new PageResponse<>(products)));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get product details by ID (including latest price and gallery)")
    public ResponseEntity<ApiResponse<ProductResponse>> getProductById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(productService.getProductById(id)));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update product details")
    public ResponseEntity<ApiResponse<ProductResponse>> updateProduct(
            @PathVariable Long id,
            @Valid @RequestBody ProductUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Product updated", productService.updateProduct(id, request)));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete product")
    public ResponseEntity<ApiResponse<Void>> deleteProduct(@PathVariable Long id) {
        productService.deleteProduct(id);
        return ResponseEntity.ok(ApiResponse.success("Product deleted", null));
    }

    @GetMapping("/search")
    @Operation(summary = "Keyword search over product name and description")
    public ResponseEntity<ApiResponse<PageResponse<ProductResponse>>> searchProducts(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<ProductResponse> results = productService.searchProducts(keyword, PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.success(new PageResponse<>(results)));
    }

    @GetMapping("/low-stock")
    @Operation(summary = "Detect low stock items (stock <= 10)")
    public ResponseEntity<ApiResponse<List<ProductResponse>>> getLowStockProducts() {
        return ResponseEntity.ok(ApiResponse.success(productService.getLowStockProducts()));
    }
}
