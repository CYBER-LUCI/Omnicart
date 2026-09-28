package com.omnicart.service.impl;

import com.omnicart.dto.response.ProductResponse;
import com.omnicart.entity.Product;
import com.omnicart.entity.ProductEmbeddings;
import com.omnicart.mapper.ProductMapper;
import com.omnicart.repository.ProductEmbeddingsRepository;
import com.omnicart.service.PriceService;
import com.omnicart.service.VisualSearchService;
import com.omnicart.util.VectorSimilarityUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class VisualSearchServiceImpl implements VisualSearchService {

    private static final Logger log = LoggerFactory.getLogger(VisualSearchServiceImpl.class);

    private final ProductEmbeddingsRepository embeddingRepository;
    private final PriceService priceService;

    public VisualSearchServiceImpl(ProductEmbeddingsRepository embeddingRepository, PriceService priceService) {
        this.embeddingRepository = embeddingRepository;
        this.priceService = priceService;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProductResponse> searchByVector(String vectorJson, int limit, double minSimilarity) {
        double[] queryVector = VectorSimilarityUtil.parseJsonVector(vectorJson);
        if (queryVector.length == 0) {
            return Collections.emptyList();
        }

        List<ProductEmbeddings> allEmbeddings = embeddingRepository.findAll();
        List<Map.Entry<Product, Double>> matches = new ArrayList<>();

        for (ProductEmbeddings emb : allEmbeddings) {
            double[] targetVector = VectorSimilarityUtil.parseJsonVector(emb.getFeatureVector());
            double score = VectorSimilarityUtil.cosineSimilarity(queryVector, targetVector);

            if (score >= minSimilarity) {
                matches.add(new AbstractMap.SimpleEntry<>(emb.getProduct(), score));
            }
        }

        // Sort descending by score
        matches.sort((a, b) -> Double.compare(b.getValue(), a.getValue()));

        return matches.stream()
                .limit(limit)
                .map(entry -> ProductMapper.toResponse(entry.getKey(), priceService.getCurrentPrice(entry.getKey().getId())))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProductResponse> searchByImage(MultipartFile file, int limit) {
        // Pluggable embedding generator abstraction:
        // In real-world deployment, this forwards the image byte[] to an ONNX/PyTorch/TensorFlow CLIP model.
        // For demonstration, we create a deterministic pseudo-feature vector from file hash/size.
        log.info("Processing visual search for uploaded image: {}, size: {} bytes", file.getOriginalFilename(), file.getSize());

        int seed = file.getOriginalFilename() != null ? file.getOriginalFilename().hashCode() : 42;
        Random rng = new Random(seed);
        double[] pseudoVector = new double[8];
        for (int i = 0; i < 8; i++) {
            pseudoVector[i] = rng.nextDouble() * 2 - 1.0;
        }

        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < 8; i++) {
            sb.append(String.format(Locale.US, "%.4f", pseudoVector[i]));
            if (i < 7) sb.append(", ");
        }
        sb.append("]");

        return searchByVector(sb.toString(), limit, 0.0);
    }
}
