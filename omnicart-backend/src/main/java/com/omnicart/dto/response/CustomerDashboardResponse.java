package com.omnicart.dto.response;

import java.math.BigDecimal;
import java.util.List;

public class CustomerDashboardResponse {
    private CustomerResponse customer;
    private List<AddressResponse> savedAddresses;
    private long totalOrders;
    private BigDecimal totalSpent;
    private List<OrderResponse> recentOrders;

    public CustomerDashboardResponse() {}

    public CustomerResponse getCustomer() { return customer; }
    public void setCustomer(CustomerResponse customer) { this.customer = customer; }

    public List<AddressResponse> getSavedAddresses() { return savedAddresses; }
    public void setSavedAddresses(List<AddressResponse> savedAddresses) { this.savedAddresses = savedAddresses; }

    public long getTotalOrders() { return totalOrders; }
    public void setTotalOrders(long totalOrders) { this.totalOrders = totalOrders; }

    public BigDecimal getTotalSpent() { return totalSpent; }
    public void setTotalSpent(BigDecimal totalSpent) { this.totalSpent = totalSpent; }

    public List<OrderResponse> getRecentOrders() { return recentOrders; }
    public void setRecentOrders(List<OrderResponse> recentOrders) { this.recentOrders = recentOrders; }
}
