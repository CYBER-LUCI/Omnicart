package com.omnicart.controller;

import com.omnicart.dto.request.EmbeddingRequest;
import com.omnicart.dto.response.ApiResponse;
import com.omnicart.dto.response.ProductEmbeddingResponse;
import com.omnicart.service.ProductEmbeddingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/products/{productId}/embedding")
@Tag(name = "Product Embeddings", description = "AI visual feature vectors for 1:1 similarity search")
public class ProductEmbeddingController {

    private final ProductEmbeddingService embeddingService;

    public ProductEmbeddingController(ProductEmbeddingService embeddingService) {
        this.embeddingService = embeddingService;
    }

    @RequestMapping(method = {RequestMethod.POST, RequestMethod.PUT})
    @Operation(summary = "Upsert product embedding vector")
    public ResponseEntity<ApiResponse<ProductEmbeddingResponse>> upsertEmbedding(
            @PathVariable Long productId,
            @Valid @RequestBody EmbeddingRequest request) {
        ProductEmbeddingResponse res = embeddingService.upsertEmbedding(productId, request);
        return ResponseEntity.ok(ApiResponse.success("Embedding stored", res));
    }

    @GetMapping
    @Operation(summary = "Retrieve embedding for a product")
    public ResponseEntity<ApiResponse<ProductEmbeddingResponse>> getEmbedding(@PathVariable Long productId) {
        return ResponseEntity.ok(ApiResponse.success(embeddingService.getEmbedding(productId)));
    }

    @DeleteMapping
    @Operation(summary = "Delete embedding for a product")
    public ResponseEntity<ApiResponse<Void>> deleteEmbedding(@PathVariable Long productId) {
        embeddingService.deleteEmbedding(productId);
        return ResponseEntity.ok(ApiResponse.success("Embedding deleted", null));
    }
}
