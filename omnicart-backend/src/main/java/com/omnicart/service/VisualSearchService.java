package com.omnicart.service;

import com.omnicart.dto.response.ProductResponse;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface VisualSearchService {
    List<ProductResponse> searchByVector(String vectorJson, int limit, double minSimilarity);
    List<ProductResponse> searchByImage(MultipartFile file, int limit);
}
