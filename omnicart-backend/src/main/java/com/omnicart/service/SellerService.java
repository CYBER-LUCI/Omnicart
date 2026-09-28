package com.omnicart.service;

import com.omnicart.dto.request.SellerCreateRequest;
import com.omnicart.dto.request.SellerUpdateRequest;
import com.omnicart.dto.response.ProductResponse;
import com.omnicart.dto.response.SellerDashboardResponse;
import com.omnicart.dto.response.SellerResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface SellerService {
    SellerResponse createSeller(SellerCreateRequest request);
    SellerResponse getSellerById(Long id);
    SellerResponse updateSeller(Long id, SellerUpdateRequest request);
    Page<SellerResponse> getAllSellers(Pageable pageable);
    Page<ProductResponse> getSellerProducts(Long sellerId, Pageable pageable);
    List<ProductResponse> getSellerInventory(Long sellerId);
    SellerDashboardResponse getSellerDashboard(Long sellerId);
}
