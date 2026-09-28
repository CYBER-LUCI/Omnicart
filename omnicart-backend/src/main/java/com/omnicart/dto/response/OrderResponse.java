package com.omnicart.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class OrderResponse {
    private Long id;
    private Long customerId;
    private String customerName;
    private String shippingStatus;
    private BigDecimal totalAmount;
    private LocalDateTime orderDate;
    private OrderPaymentResponse payment;
    private List<OrderDetailResponse> items;

    public OrderResponse() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getCustomerId() { return customerId; }
    public void setCustomerId(Long customerId) { this.customerId = customerId; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getShippingStatus() { return shippingStatus; }
    public void setShippingStatus(String shippingStatus) { this.shippingStatus = shippingStatus; }

    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }

    public LocalDateTime getOrderDate() { return orderDate; }
    public void setOrderDate(LocalDateTime orderDate) { this.orderDate = orderDate; }

    public OrderPaymentResponse getPayment() { return payment; }
    public void setPayment(OrderPaymentResponse payment) { this.payment = payment; }

    public List<OrderDetailResponse> getItems() { return items; }
    public void setItems(List<OrderDetailResponse> items) { this.items = items; }
}
