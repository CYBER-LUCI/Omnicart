package com.omnicart.dto.response;

import java.math.BigDecimal;
import java.util.List;

public class SellerDashboardResponse {
    private SellerResponse seller;
    private long totalProducts;
    private long lowStockCount;
    private long totalOrders;
    private BigDecimal totalRevenue;
    private List<ProductResponse> lowStockProducts;

    public SellerDashboardResponse() {}

    public SellerResponse getSeller() { return seller; }
    public void setSeller(SellerResponse seller) { this.seller = seller; }

    public long getTotalProducts() { return totalProducts; }
    public void setTotalProducts(long totalProducts) { this.totalProducts = totalProducts; }

    public long getLowStockCount() { return lowStockCount; }
    public void setLowStockCount(long lowStockCount) { this.lowStockCount = lowStockCount; }

    public long getTotalOrders() { return totalOrders; }
    public void setTotalOrders(long totalOrders) { this.totalOrders = totalOrders; }

    public BigDecimal getTotalRevenue() { return totalRevenue; }
    public void setTotalRevenue(BigDecimal totalRevenue) { this.totalRevenue = totalRevenue; }

    public List<ProductResponse> getLowStockProducts() { return lowStockProducts; }
    public void setLowStockProducts(List<ProductResponse> lowStockProducts) { this.lowStockProducts = lowStockProducts; }
}
