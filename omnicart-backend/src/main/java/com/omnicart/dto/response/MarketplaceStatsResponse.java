package com.omnicart.dto.response;

import java.math.BigDecimal;

public class MarketplaceStatsResponse {
    private long totalCustomers;
    private long totalSellers;
    private long totalCategories;
    private long totalProducts;
    private long totalOrders;
    private long lowStockProducts;
    private BigDecimal platformGmv;

    public MarketplaceStatsResponse() {}

    public long getTotalCustomers() { return totalCustomers; }
    public void setTotalCustomers(long totalCustomers) { this.totalCustomers = totalCustomers; }

    public long getTotalSellers() { return totalSellers; }
    public void setTotalSellers(long totalSellers) { this.totalSellers = totalSellers; }

    public long getTotalCategories() { return totalCategories; }
    public void setTotalCategories(long totalCategories) { this.totalCategories = totalCategories; }

    public long getTotalProducts() { return totalProducts; }
    public void setTotalProducts(long totalProducts) { this.totalProducts = totalProducts; }

    public long getTotalOrders() { return totalOrders; }
    public void setTotalOrders(long totalOrders) { this.totalOrders = totalOrders; }

    public long getLowStockProducts() { return lowStockProducts; }
    public void setLowStockProducts(long lowStockProducts) { this.lowStockProducts = lowStockProducts; }

    public BigDecimal getPlatformGmv() { return platformGmv; }
    public void setPlatformGmv(BigDecimal platformGmv) { this.platformGmv = platformGmv; }
}
