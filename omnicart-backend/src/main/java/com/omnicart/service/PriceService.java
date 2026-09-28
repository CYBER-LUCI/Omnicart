package com.omnicart.service;

import com.omnicart.dto.request.PriceLedgerRequest;
import com.omnicart.dto.response.PriceLedgerResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public interface PriceService {
    PriceLedgerResponse addPriceEntry(Long productId, PriceLedgerRequest request);
    BigDecimal getCurrentPrice(Long productId);
    List<PriceLedgerResponse> getPriceHistory(Long productId);
    Page<PriceLedgerResponse> getPriceHistoryPaged(Long productId, Pageable pageable);
    BigDecimal getPriceAtTimestamp(Long productId, LocalDateTime timestamp);
}
