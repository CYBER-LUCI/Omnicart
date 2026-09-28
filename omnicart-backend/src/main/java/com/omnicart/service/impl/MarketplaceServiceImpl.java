package com.omnicart.service.impl;

import com.omnicart.dto.response.MarketplaceStatsResponse;
import com.omnicart.repository.*;
import com.omnicart.service.MarketplaceService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Service
public class MarketplaceServiceImpl implements MarketplaceService {

    private final CustomerRepository customerRepository;
    private final SellerRepository sellerRepository;
    private final CategoryRepository categoryRepository;
    private final ProductRepository productRepository;
    private final OrderRepository orderRepository;
    private final OrderDetailsRepository orderDetailsRepository;

    public MarketplaceServiceImpl(CustomerRepository customerRepository,
                                  SellerRepository sellerRepository,
                                  CategoryRepository categoryRepository,
                                  ProductRepository productRepository,
                                  OrderRepository orderRepository,
                                  OrderDetailsRepository orderDetailsRepository) {
        this.customerRepository = customerRepository;
        this.sellerRepository = sellerRepository;
        this.categoryRepository = categoryRepository;
        this.productRepository = productRepository;
        this.orderRepository = orderRepository;
        this.orderDetailsRepository = orderDetailsRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public MarketplaceStatsResponse getPlatformStatistics() {
        MarketplaceStatsResponse stats = new MarketplaceStatsResponse();
        stats.setTotalCustomers(customerRepository.count());
        stats.setTotalSellers(sellerRepository.count());
        stats.setTotalCategories(categoryRepository.count());
        stats.setTotalProducts(productRepository.count());
        stats.setTotalOrders(orderRepository.count());
        stats.setLowStockProducts(productRepository.findLowStockProducts(10).size());

        // Platform GMV = sum of all non-cancelled order items
        BigDecimal gmv = orderRepository.findAll().stream()
                .filter(o -> o.getShippingStatus().getId() != 6)
                .map(o -> orderDetailsRepository.calculateOrderTotal(o.getId()))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        stats.setPlatformGmv(gmv);
        return stats;
    }
}
