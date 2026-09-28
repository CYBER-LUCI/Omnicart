package com.omnicart.controller;

import com.omnicart.dto.request.SellerCreateRequest;
import com.omnicart.dto.request.SellerUpdateRequest;
import com.omnicart.dto.response.*;
import com.omnicart.service.SellerService;
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
@RequestMapping("/api/sellers")
@Tag(name = "Seller Management", description = "APIs for vendor registration, inventory, and dashboard")
public class SellerController {

    private final SellerService sellerService;

    public SellerController(SellerService sellerService) {
        this.sellerService = sellerService;
    }

    @PostMapping
    @Operation(summary = "Register seller")
    public ResponseEntity<ApiResponse<SellerResponse>> createSeller(@Valid @RequestBody SellerCreateRequest request) {
        SellerResponse res = sellerService.createSeller(request);
        return new ResponseEntity<>(ApiResponse.success("Seller registered", res), HttpStatus.CREATED);
    }

    @GetMapping
    @Operation(summary = "List all sellers")
    public ResponseEntity<ApiResponse<PageResponse<SellerResponse>>> getAllSellers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<SellerResponse> sellers = sellerService.getAllSellers(PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.success(new PageResponse<>(sellers)));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get seller profile by ID")
    public ResponseEntity<ApiResponse<SellerResponse>> getSellerById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(sellerService.getSellerById(id)));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update seller details")
    public ResponseEntity<ApiResponse<SellerResponse>> updateSeller(
            @PathVariable Long id,
            @Valid @RequestBody SellerUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Seller updated", sellerService.updateSeller(id, request)));
    }

    @GetMapping("/{id}/products")
    @Operation(summary = "List products by seller")
    public ResponseEntity<ApiResponse<PageResponse<ProductResponse>>> getSellerProducts(
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<ProductResponse> products = sellerService.getSellerProducts(id, PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.success(new PageResponse<>(products)));
    }

    @GetMapping("/{id}/inventory")
    @Operation(summary = "View seller inventory and stock quantities")
    public ResponseEntity<ApiResponse<List<ProductResponse>>> getSellerInventory(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(sellerService.getSellerInventory(id)));
    }

    @GetMapping("/{id}/dashboard")
    @Operation(summary = "Get seller dashboard metrics (revenue, orders, low stock)")
    public ResponseEntity<ApiResponse<SellerDashboardResponse>> getSellerDashboard(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(sellerService.getSellerDashboard(id)));
    }
}
