package com.omnicart.service.impl;

import com.omnicart.dto.request.SellerCreateRequest;
import com.omnicart.dto.request.SellerUpdateRequest;
import com.omnicart.dto.response.ProductResponse;
import com.omnicart.dto.response.SellerDashboardResponse;
import com.omnicart.dto.response.SellerResponse;
import com.omnicart.entity.Product;
import com.omnicart.entity.Seller;
import com.omnicart.exception.DuplicateGSTINException;
import com.omnicart.exception.SellerNotFoundException;
import com.omnicart.mapper.ProductMapper;
import com.omnicart.mapper.SellerMapper;
import com.omnicart.repository.OrderRepository;
import com.omnicart.repository.ProductRepository;
import com.omnicart.repository.SellerRepository;
import com.omnicart.service.PriceService;
import com.omnicart.service.SellerService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class SellerServiceImpl implements SellerService {

    private final SellerRepository sellerRepository;
    private final ProductRepository productRepository;
    private final OrderRepository orderRepository;
    private final PriceService priceService;

    public SellerServiceImpl(SellerRepository sellerRepository,
                             ProductRepository productRepository,
                             OrderRepository orderRepository,
                             PriceService priceService) {
        this.sellerRepository = sellerRepository;
        this.productRepository = productRepository;
        this.orderRepository = orderRepository;
        this.priceService = priceService;
    }

    @Override
    @Transactional
    public SellerResponse createSeller(SellerCreateRequest request) {
        if (sellerRepository.existsByGstin(request.getGstin())) {
            throw new DuplicateGSTINException(request.getGstin());
        }

        Seller seller = new Seller();
        seller.setCompanyName(request.getCompanyName());
        seller.setGstin(request.getGstin());
        seller.setContactEmail(request.getContactEmail());
        seller.setContactPhone(request.getContactPhone());

        Seller saved = sellerRepository.save(seller);
        return SellerMapper.toResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public SellerResponse getSellerById(Long id) {
        Seller seller = sellerRepository.findById(id)
                .orElseThrow(() -> new SellerNotFoundException(id));
        return SellerMapper.toResponse(seller);
    }

    @Override
    @Transactional
    public SellerResponse updateSeller(Long id, SellerUpdateRequest request) {
        Seller seller = sellerRepository.findById(id)
                .orElseThrow(() -> new SellerNotFoundException(id));

        seller.setCompanyName(request.getCompanyName());
        seller.setContactEmail(request.getContactEmail());
        seller.setContactPhone(request.getContactPhone());

        Seller updated = sellerRepository.save(seller);
        return SellerMapper.toResponse(updated);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<SellerResponse> getAllSellers(Pageable pageable) {
        return sellerRepository.findAll(pageable).map(SellerMapper::toResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ProductResponse> getSellerProducts(Long sellerId, Pageable pageable) {
        if (!sellerRepository.existsById(sellerId)) {
            throw new SellerNotFoundException(sellerId);
        }
        return productRepository.findBySellerId(sellerId, pageable)
                .map(p -> ProductMapper.toResponse(p, priceService.getCurrentPrice(p.getId())));
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProductResponse> getSellerInventory(Long sellerId) {
        if (!sellerRepository.existsById(sellerId)) {
            throw new SellerNotFoundException(sellerId);
        }
        return productRepository.findBySellerId(sellerId, Pageable.unpaged()).getContent().stream()
                .map(p -> ProductMapper.toResponse(p, priceService.getCurrentPrice(p.getId())))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public SellerDashboardResponse getSellerDashboard(Long sellerId) {
        Seller seller = sellerRepository.findById(sellerId)
                .orElseThrow(() -> new SellerNotFoundException(sellerId));

        long totalProducts = productRepository.countBySellerId(sellerId);
        List<Product> lowStock = productRepository.findSellerLowStockProducts(sellerId, 10);
        long totalOrders = orderRepository.countOrdersContainingSellerProducts(sellerId);
        BigDecimal totalRevenue = orderRepository.calculateSellerTotalRevenue(sellerId);

        SellerDashboardResponse dashboard = new SellerDashboardResponse();
        dashboard.setSeller(SellerMapper.toResponse(seller));
        dashboard.setTotalProducts(totalProducts);
        dashboard.setLowStockCount(lowStock.size());
        dashboard.setTotalOrders(totalOrders);
        dashboard.setTotalRevenue(totalRevenue);
        dashboard.setLowStockProducts(lowStock.stream()
                .map(p -> ProductMapper.toResponse(p, priceService.getCurrentPrice(p.getId())))
                .collect(Collectors.toList()));

        return dashboard;
    }
}
