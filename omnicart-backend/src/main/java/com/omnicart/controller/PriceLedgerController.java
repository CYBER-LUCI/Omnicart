package com.omnicart.controller;

import com.omnicart.dto.request.PriceLedgerRequest;
import com.omnicart.dto.response.ApiResponse;
import com.omnicart.dto.response.PageResponse;
import com.omnicart.dto.response.PriceLedgerResponse;
import com.omnicart.service.PriceService;
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
@RequestMapping("/api/products/{productId}")
@Tag(name = "Dynamic Pricing & Ledger", description = "Append-only price ledger history and current price resolution")
public class PriceLedgerController {

    private final PriceService priceService;

    public PriceLedgerController(PriceService priceService) {
        this.priceService = priceService;
    }

    @PostMapping("/prices")
    @Operation(summary = "Append new price to PriceLedger (never updates/deletes old records)")
    public ResponseEntity<ApiResponse<PriceLedgerResponse>> addPrice(
            @PathVariable Long productId,
            @Valid @RequestBody PriceLedgerRequest request) {
        PriceLedgerResponse res = priceService.addPriceEntry(productId, request);
        return new ResponseEntity<>(ApiResponse.success("Price updated in ledger", res), HttpStatus.CREATED);
    }

    @GetMapping("/prices")
    @Operation(summary = "Get complete historical price timeline for product")
    public ResponseEntity<ApiResponse<List<PriceLedgerResponse>>> getPriceHistory(@PathVariable Long productId) {
        return ResponseEntity.ok(ApiResponse.success(priceService.getPriceHistory(productId)));
    }

    @GetMapping("/prices/paged")
    @Operation(summary = "Get paged historical price timeline")
    public ResponseEntity<ApiResponse<PageResponse<PriceLedgerResponse>>> getPriceHistoryPaged(
            @PathVariable Long productId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        Page<PriceLedgerResponse> paged = priceService.getPriceHistoryPaged(productId, PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.success(new PageResponse<>(paged)));
    }

    @GetMapping("/current-price")
    @Operation(summary = "Get the latest valid effective price from PriceLedger")
    public ResponseEntity<ApiResponse<BigDecimal>> getCurrentPrice(@PathVariable Long productId) {
        return ResponseEntity.ok(ApiResponse.success(priceService.getCurrentPrice(productId)));
    }
}
