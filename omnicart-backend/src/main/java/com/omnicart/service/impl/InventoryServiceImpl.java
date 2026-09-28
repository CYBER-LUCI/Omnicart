package com.omnicart.service.impl;

import com.omnicart.dto.response.ProductResponse;
import com.omnicart.entity.Product;
import com.omnicart.exception.InsufficientStockException;
import com.omnicart.exception.ProductNotFoundException;
import com.omnicart.mapper.ProductMapper;
import com.omnicart.repository.ProductRepository;
import com.omnicart.service.InventoryService;
import com.omnicart.service.PriceService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class InventoryServiceImpl implements InventoryService {

    private final ProductRepository productRepository;
    private final PriceService priceService;

    public InventoryServiceImpl(ProductRepository productRepository, PriceService priceService) {
        this.productRepository = productRepository;
        this.priceService = priceService;
    }

    @Override
    @Transactional(readOnly = true)
    public int getStock(Long productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ProductNotFoundException(productId));
        return product.getStockQuantity();
    }

    @Override
    @Transactional
    public ProductResponse setStock(Long productId, int quantity) {
        if (quantity < 0) {
            throw new InsufficientStockException("Stock quantity cannot be set to a negative value.");
        }
        Product product = productRepository.findByIdWithPessimisticLock(productId)
                .orElseThrow(() -> new ProductNotFoundException(productId));

        product.setStockQuantity(quantity);
        Product saved = productRepository.save(product);
        return ProductMapper.toResponse(saved, priceService.getCurrentPrice(productId));
    }

    @Override
    @Transactional
    public ProductResponse addStock(Long productId, int quantity) {
        if (quantity <= 0) {
            throw new IllegalArgumentException("Quantity to add must be positive.");
        }
        Product product = productRepository.findByIdWithPessimisticLock(productId)
                .orElseThrow(() -> new ProductNotFoundException(productId));

        product.setStockQuantity(product.getStockQuantity() + quantity);
        Product saved = productRepository.save(product);
        return ProductMapper.toResponse(saved, priceService.getCurrentPrice(productId));
    }

    @Override
    @Transactional
    public ProductResponse removeStock(Long productId, int quantity) {
        if (quantity <= 0) {
            throw new IllegalArgumentException("Quantity to remove must be positive.");
        }
        Product product = productRepository.findByIdWithPessimisticLock(productId)
                .orElseThrow(() -> new ProductNotFoundException(productId));

        if (product.getStockQuantity() < quantity) {
            throw new InsufficientStockException(productId, product.getStockQuantity(), quantity);
        }

        product.setStockQuantity(product.getStockQuantity() - quantity);
        Product saved = productRepository.save(product);
        return ProductMapper.toResponse(saved, priceService.getCurrentPrice(productId));
    }
}
