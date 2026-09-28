package com.omnicart.service.impl;

import com.omnicart.dto.request.PriceLedgerRequest;
import com.omnicart.dto.response.PriceLedgerResponse;
import com.omnicart.entity.PriceLedger;
import com.omnicart.entity.PriceLedgerSource;
import com.omnicart.entity.Product;
import com.omnicart.exception.InvalidPriceException;
import com.omnicart.exception.PriceNotFoundException;
import com.omnicart.exception.ProductNotFoundException;
import com.omnicart.exception.ResourceNotFoundException;
import com.omnicart.mapper.PriceLedgerMapper;
import com.omnicart.repository.PriceLedgerRepository;
import com.omnicart.repository.PriceLedgerSourceRepository;
import com.omnicart.repository.ProductRepository;
import com.omnicart.service.PriceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class PriceServiceImpl implements PriceService {

    private static final Logger log = LoggerFactory.getLogger(PriceServiceImpl.class);

    private final PriceLedgerRepository priceLedgerRepository;
    private final PriceLedgerSourceRepository priceLedgerSourceRepository;
    private final ProductRepository productRepository;

    public PriceServiceImpl(PriceLedgerRepository priceLedgerRepository,
                            PriceLedgerSourceRepository priceLedgerSourceRepository,
                            ProductRepository productRepository) {
        this.priceLedgerRepository = priceLedgerRepository;
        this.priceLedgerSourceRepository = priceLedgerSourceRepository;
        this.productRepository = productRepository;
    }

    @Override
    @Transactional
    public PriceLedgerResponse addPriceEntry(Long productId, PriceLedgerRequest request) {
        if (request.getPrice() == null || request.getPrice().compareTo(BigDecimal.ZERO) < 0) {
            throw new InvalidPriceException("Price cannot be null or negative");
        }

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ProductNotFoundException(productId));

        PriceLedgerSource source = priceLedgerSourceRepository.findById(request.getSourceId())
                .orElseThrow(() -> new ResourceNotFoundException("PriceLedgerSource not found with ID: " + request.getSourceId()));

        // Calculate fluctuation against current price
        BigDecimal currentPrice = getCurrentPrice(productId);
        BigDecimal fluctuation = request.getPrice().subtract(currentPrice);

        // Append-only: always insert a new row
        PriceLedger newEntry = new PriceLedger(product, source, request.getPrice(), fluctuation);
        PriceLedger saved = priceLedgerRepository.save(newEntry);
        log.info("Recorded price change for product {}: {} -> {} (Fluctuation: {}) via source {}",
                productId, currentPrice, request.getPrice(), fluctuation, source.getSourceName());

        return PriceLedgerMapper.toResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public BigDecimal getCurrentPrice(Long productId) {
        Optional<PriceLedger> latest = priceLedgerRepository.findLatestByProductId(productId);
        return latest.map(PriceLedger::getPrice).orElse(BigDecimal.ZERO);
    }

    @Override
    @Transactional(readOnly = true)
    public List<PriceLedgerResponse> getPriceHistory(Long productId) {
        if (!productRepository.existsById(productId)) {
            throw new ProductNotFoundException(productId);
        }
        return priceLedgerRepository.findAllByProductIdOrderByRecordedAtDesc(productId).stream()
                .map(PriceLedgerMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PriceLedgerResponse> getPriceHistoryPaged(Long productId, Pageable pageable) {
        if (!productRepository.existsById(productId)) {
            throw new ProductNotFoundException(productId);
        }
        return priceLedgerRepository.findByProductIdOrderByRecordedAtDesc(productId, pageable)
                .map(PriceLedgerMapper::toResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public BigDecimal getPriceAtTimestamp(Long productId, LocalDateTime timestamp) {
        return priceLedgerRepository.findPriceAtTimestamp(productId, timestamp)
                .map(PriceLedger::getPrice)
                .orElseThrow(() -> new PriceNotFoundException(productId));
    }
}
