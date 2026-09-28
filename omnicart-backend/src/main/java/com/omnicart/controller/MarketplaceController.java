package com.omnicart.controller;

import com.omnicart.dto.response.ApiResponse;
import com.omnicart.dto.response.MarketplaceStatsResponse;
import com.omnicart.service.MarketplaceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/marketplace")
@Tag(name = "Marketplace Statistics", description = "Platform-wide administrative statistics and reporting")
public class MarketplaceController {

    private final MarketplaceService marketplaceService;

    public MarketplaceController(MarketplaceService marketplaceService) {
        this.marketplaceService = marketplaceService;
    }

    @GetMapping("/statistics")
    @Operation(summary = "Get global marketplace statistics (GMV, orders, counts)")
    public ResponseEntity<ApiResponse<MarketplaceStatsResponse>> getPlatformStatistics() {
        return ResponseEntity.ok(ApiResponse.success(marketplaceService.getPlatformStatistics()));
    }
}
