package com.omnicart.controller;

import com.omnicart.dto.request.ProductStockUpdateRequest;
import com.omnicart.dto.response.ApiResponse;
import com.omnicart.dto.response.ProductResponse;
import com.omnicart.service.InventoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/products/{id}/stock")
@Tag(name = "Inventory Management", description = "Stock level management and adjustment")
public class InventoryController {

    private final InventoryService inventoryService;

    public InventoryController(InventoryService inventoryService) {
        this.inventoryService = inventoryService;
    }

    @GetMapping
    @Operation(summary = "Get current stock for product")
    public ResponseEntity<ApiResponse<Integer>> getStock(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(inventoryService.getStock(id)));
    }

    @PutMapping
    @Operation(summary = "Explicitly set absolute stock quantity")
    public ResponseEntity<ApiResponse<ProductResponse>> setStock(
            @PathVariable Long id,
            @Valid @RequestBody ProductStockUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Stock updated", inventoryService.setStock(id, request.getQuantity())));
    }

    @PostMapping("/add")
    @Operation(summary = "Restock inventory (add quantity)")
    public ResponseEntity<ApiResponse<ProductResponse>> addStock(
            @PathVariable Long id,
            @Valid @RequestBody ProductStockUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Stock added", inventoryService.addStock(id, request.getQuantity())));
    }

    @PostMapping("/remove")
    @Operation(summary = "Write-off stock (remove quantity)")
    public ResponseEntity<ApiResponse<ProductResponse>> removeStock(
            @PathVariable Long id,
            @Valid @RequestBody ProductStockUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Stock removed", inventoryService.removeStock(id, request.getQuantity())));
    }
}
