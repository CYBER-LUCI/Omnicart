package com.omnicart.controller;

import com.omnicart.dto.response.ApiResponse;
import com.omnicart.dto.response.ProductResponse;
import com.omnicart.service.VisualSearchService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/search/visual")
@Tag(name = "AI Visual Search", description = "Visual similarity matching using high-dimensional embeddings")
public class VisualSearchController {

    private final VisualSearchService visualSearchService;

    public VisualSearchController(VisualSearchService visualSearchService) {
        this.visualSearchService = visualSearchService;
    }

    @PostMapping(consumes = "multipart/form-data")
    @Operation(summary = "Visual search by uploading an image")
    public ResponseEntity<ApiResponse<List<ProductResponse>>> searchByImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam(defaultValue = "10") int limit) {
        List<ProductResponse> matches = visualSearchService.searchByImage(file, limit);
        return ResponseEntity.ok(ApiResponse.success("Visual search results", matches));
    }

    @PostMapping("/vector")
    @Operation(summary = "Visual search by passing raw JSON vector")
    public ResponseEntity<ApiResponse<List<ProductResponse>>> searchByVector(
            @RequestBody String vectorJson,
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(defaultValue = "0.5") double minSimilarity) {
        List<ProductResponse> matches = visualSearchService.searchByVector(vectorJson, limit, minSimilarity);
        return ResponseEntity.ok(ApiResponse.success("Vector search results", matches));
    }
}
