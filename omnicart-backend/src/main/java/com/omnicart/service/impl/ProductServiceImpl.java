package com.omnicart.service.impl;

import com.omnicart.dto.request.ProductCreateRequest;
import com.omnicart.dto.request.ProductUpdateRequest;
import com.omnicart.dto.response.ProductResponse;
import com.omnicart.entity.*;
import com.omnicart.exception.*;
import com.omnicart.mapper.ProductMapper;
import com.omnicart.repository.*;
import com.omnicart.service.PriceService;
import com.omnicart.service.ProductService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductServiceImpl implements ProductService {

    private static final Logger log = LoggerFactory.getLogger(ProductServiceImpl.class);

    private final ProductRepository productRepository;
    private final SellerRepository sellerRepository;
    private final CategoryRepository categoryRepository;
    private final PriceLedgerRepository priceLedgerRepository;
    private final PriceLedgerSourceRepository priceLedgerSourceRepository;
    private final PriceService priceService;

    public ProductServiceImpl(ProductRepository productRepository,
                              SellerRepository sellerRepository,
                              CategoryRepository categoryRepository,
                              PriceLedgerRepository priceLedgerRepository,
                              PriceLedgerSourceRepository priceLedgerSourceRepository,
                              PriceService priceService) {
        this.productRepository = productRepository;
        this.sellerRepository = sellerRepository;
        this.categoryRepository = categoryRepository;
        this.priceLedgerRepository = priceLedgerRepository;
        this.priceLedgerSourceRepository = priceLedgerSourceRepository;
        this.priceService = priceService;
    }

    @Override
    @Transactional
    public ProductResponse createProduct(ProductCreateRequest request) {
        Seller seller = sellerRepository.findById(request.getSellerId())
                .orElseThrow(() -> new SellerNotFoundException(request.getSellerId()));

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new CategoryNotFoundException(request.getCategoryId()));

        Product product = new Product();
        product.setName(request.getName());
        product.setDescription(request.getDescription());
        product.setStockQuantity(request.getStockQuantity());
        product.setSeller(seller);
        product.setCategory(category);

        Product savedProduct = productRepository.save(product);

        // Create initial price ledger entry (Source 1: Initial Listing / Seller Update)
        PriceLedgerSource source = priceLedgerSourceRepository.findById(1)
                .orElseGet(() -> priceLedgerSourceRepository.save(new PriceLedgerSource(1, "Initial Listing")));

        PriceLedger initialPrice = new PriceLedger(savedProduct, source, request.getInitialPrice(), BigDecimal.ZERO);
        priceLedgerRepository.save(initialPrice);

        log.info("Created product ID: {} with initial price: {}", savedProduct.getId(), request.getInitialPrice());
        return ProductMapper.toResponse(savedProduct, request.getInitialPrice());
    }

    @Override
    @Transactional(readOnly = true)
    public ProductResponse getProductById(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException(id));
        BigDecimal currentPrice = priceService.getCurrentPrice(id);
        return ProductMapper.toResponse(product, currentPrice);
    }

    @Override
    @Transactional
    public ProductResponse updateProduct(Long id, ProductUpdateRequest request) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException(id));

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new CategoryNotFoundException(request.getCategoryId()));

        product.setName(request.getName());
        product.setDescription(request.getDescription());
        product.setCategory(category);

        Product updated = productRepository.save(product);
        BigDecimal currentPrice = priceService.getCurrentPrice(id);
        return ProductMapper.toResponse(updated, currentPrice);
    }

    @Override
    @Transactional
    public void deleteProduct(Long id) {
        if (!productRepository.existsById(id)) {
            throw new ProductNotFoundException(id);
        }
        productRepository.deleteById(id);
        log.info("Deleted product ID: {}", id);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ProductResponse> getAllProducts(Pageable pageable, Long categoryId, Long sellerId, BigDecimal minPrice, BigDecimal maxPrice) {
        Page<Product> products;
        if (categoryId != null) {
            products = productRepository.findByCategoryId(categoryId, pageable);
        } else if (sellerId != null) {
            products = productRepository.findBySellerId(sellerId, pageable);
        } else {
            products = productRepository.findAll(pageable);
        }

        return products.map(p -> ProductMapper.toResponse(p, priceService.getCurrentPrice(p.getId())));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ProductResponse> searchProducts(String keyword, Pageable pageable) {
        return productRepository.searchByKeyword(keyword, pageable)
                .map(p -> ProductMapper.toResponse(p, priceService.getCurrentPrice(p.getId())));
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProductResponse> getLowStockProducts() {
        return productRepository.findLowStockProducts(10).stream()
                .map(p -> ProductMapper.toResponse(p, priceService.getCurrentPrice(p.getId())))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ProductResponse> getProductsByCategoryId(Long categoryId, Pageable pageable) {
        return productRepository.findByCategoryId(categoryId, pageable)
                .map(p -> ProductMapper.toResponse(p, priceService.getCurrentPrice(p.getId())));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ProductResponse> getProductsBySellerId(Long sellerId, Pageable pageable) {
        return productRepository.findBySellerId(sellerId, pageable)
                .map(p -> ProductMapper.toResponse(p, priceService.getCurrentPrice(p.getId())));
    }
}
