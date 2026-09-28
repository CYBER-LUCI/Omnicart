package com.omnicart.service.impl;

import com.omnicart.dto.request.EmbeddingRequest;
import com.omnicart.dto.response.ProductEmbeddingResponse;
import com.omnicart.entity.Product;
import com.omnicart.entity.ProductEmbeddings;
import com.omnicart.exception.ProductNotFoundException;
import com.omnicart.exception.ResourceNotFoundException;
import com.omnicart.repository.ProductEmbeddingsRepository;
import com.omnicart.repository.ProductRepository;
import com.omnicart.service.ProductEmbeddingService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProductEmbeddingServiceImpl implements ProductEmbeddingService {

    private final ProductEmbeddingsRepository embeddingRepository;
    private final ProductRepository productRepository;

    public ProductEmbeddingServiceImpl(ProductEmbeddingsRepository embeddingRepository, ProductRepository productRepository) {
        this.embeddingRepository = embeddingRepository;
        this.productRepository = productRepository;
    }

    @Override
    @Transactional
    public ProductEmbeddingResponse upsertEmbedding(Long productId, EmbeddingRequest request) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ProductNotFoundException(productId));

        ProductEmbeddings embedding = embeddingRepository.findByProductId(productId)
                .orElse(new ProductEmbeddings(product, request.getFeatureVector(), request.getModelVersion()));

        embedding.setFeatureVector(request.getFeatureVector());
        embedding.setModelVersion(request.getModelVersion());

        ProductEmbeddings saved = embeddingRepository.save(embedding);

        ProductEmbeddingResponse res = new ProductEmbeddingResponse();
        res.setId(saved.getId());
        res.setProductId(productId);
        res.setFeatureVector(saved.getFeatureVector());
        res.setModelVersion(saved.getModelVersion());
        res.setCreatedAt(saved.getCreatedAt());
        return res;
    }

    @Override
    @Transactional(readOnly = true)
    public ProductEmbeddingResponse getEmbedding(Long productId) {
        ProductEmbeddings saved = embeddingRepository.findByProductId(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Embedding not found for product: " + productId));

        ProductEmbeddingResponse res = new ProductEmbeddingResponse();
        res.setId(saved.getId());
        res.setProductId(productId);
        res.setFeatureVector(saved.getFeatureVector());
        res.setModelVersion(saved.getModelVersion());
        res.setCreatedAt(saved.getCreatedAt());
        return res;
    }

    @Override
    @Transactional
    public void deleteEmbedding(Long productId) {
        ProductEmbeddings saved = embeddingRepository.findByProductId(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Embedding not found for product: " + productId));
        embeddingRepository.delete(saved);
    }
}
