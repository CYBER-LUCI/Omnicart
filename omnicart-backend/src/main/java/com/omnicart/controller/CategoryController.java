package com.omnicart.controller;

import com.omnicart.dto.request.CategoryRequest;
import com.omnicart.dto.response.ApiResponse;
import com.omnicart.dto.response.CategoryResponse;
import com.omnicart.dto.response.CategoryTreeResponse;
import com.omnicart.dto.response.PageResponse;
import com.omnicart.dto.response.ProductResponse;
import com.omnicart.service.CategoryService;
import com.omnicart.service.ProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@Tag(name = "Category Management", description = "Hierarchical category tree and product categorization")
public class CategoryController {

    private final CategoryService categoryService;
    private final ProductService productService;

    public CategoryController(CategoryService categoryService, ProductService productService) {
        this.categoryService = categoryService;
        this.productService = productService;
    }

    @PostMapping
    @Operation(summary = "Create category")
    public ResponseEntity<ApiResponse<CategoryResponse>> createCategory(@Valid @RequestBody CategoryRequest request) {
        CategoryResponse res = categoryService.createCategory(request);
        return new ResponseEntity<>(ApiResponse.success("Category created", res), HttpStatus.CREATED);
    }

    @GetMapping
    @Operation(summary = "List all flat categories")
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> getAllCategories() {
        return ResponseEntity.ok(ApiResponse.success(categoryService.getAllCategories()));
    }

    @GetMapping("/tree")
    @Operation(summary = "Get complete hierarchical category taxonomy tree")
    public ResponseEntity<ApiResponse<List<CategoryTreeResponse>>> getCategoryTree() {
        return ResponseEntity.ok(ApiResponse.success(categoryService.getCategoryTree()));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get category details by ID")
    public ResponseEntity<ApiResponse<CategoryResponse>> getCategoryById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(categoryService.getCategoryById(id)));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update category")
    public ResponseEntity<ApiResponse<CategoryResponse>> updateCategory(
            @PathVariable Long id,
            @Valid @RequestBody CategoryRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Category updated", categoryService.updateCategory(id, request)));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete category (fails if products exist)")
    public ResponseEntity<ApiResponse<Void>> deleteCategory(@PathVariable Long id) {
        categoryService.deleteCategory(id);
        return ResponseEntity.ok(ApiResponse.success("Category deleted", null));
    }

    @GetMapping("/{id}/children")
    @Operation(summary = "Get immediate child sub-categories")
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> getSubCategories(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(categoryService.getSubCategories(id)));
    }

    @GetMapping("/{id}/products")
    @Operation(summary = "Get products belonging to this category")
    public ResponseEntity<ApiResponse<PageResponse<ProductResponse>>> getCategoryProducts(
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<ProductResponse> products = productService.getProductsByCategoryId(id, PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.success(new PageResponse<>(products)));
    }
}
