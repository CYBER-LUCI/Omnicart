package com.omnicart.service;

import com.omnicart.dto.request.EmbeddingRequest;
import com.omnicart.dto.response.ProductEmbeddingResponse;

public interface ProductEmbeddingService {
    ProductEmbeddingResponse upsertEmbedding(Long productId, EmbeddingRequest request);
    ProductEmbeddingResponse getEmbedding(Long productId);
    void deleteEmbedding(Long productId);
}
