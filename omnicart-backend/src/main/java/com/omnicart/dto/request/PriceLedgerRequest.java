package com.omnicart.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import java.math.BigDecimal;

public class PriceLedgerRequest {
    @NotNull(message = "New price is required")
    @PositiveOrZero(message = "Price cannot be negative")
    private BigDecimal price;

    @NotNull(message = "Source ID is required (1: Seller, 2: Auto Discount, 3: Campaign, 4: Bulk, 5: API, 6: Admin)")
    private Integer sourceId;

    public PriceLedgerRequest() {}

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public Integer getSourceId() { return sourceId; }
    public void setSourceId(Integer sourceId) { this.sourceId = sourceId; }
}
