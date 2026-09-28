package com.omnicart.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class OrderPaymentResponse {
    private Long id;
    private String paymentMethod;
    private BigDecimal paidAmount;
    private LocalDateTime paidAt;

    public OrderPaymentResponse() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public BigDecimal getPaidAmount() { return paidAmount; }
    public void setPaidAmount(BigDecimal paidAmount) { this.paidAmount = paidAmount; }

    public LocalDateTime getPaidAt() { return paidAt; }
    public void setPaidAt(LocalDateTime paidAt) { this.paidAt = paidAt; }
}
