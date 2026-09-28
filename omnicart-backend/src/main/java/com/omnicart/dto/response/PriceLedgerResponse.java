package com.omnicart.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class PriceLedgerResponse {
    private Long id;
    private Long productId;
    private String sourceName;
    private BigDecimal price;
    private BigDecimal priceFluctuation;
    private LocalDateTime recordedAt;

    public PriceLedgerResponse() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getProductId() { return productId; }
    public void setProductId(Long productId) { this.productId = productId; }

    public String getSourceName() { return sourceName; }
    public void setSourceName(String sourceName) { this.sourceName = sourceName; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public BigDecimal getPriceFluctuation() { return priceFluctuation; }
    public void setPriceFluctuation(BigDecimal priceFluctuation) { this.priceFluctuation = priceFluctuation; }

    public LocalDateTime getRecordedAt() { return recordedAt; }
    public void setRecordedAt(LocalDateTime recordedAt) { this.recordedAt = recordedAt; }
}
