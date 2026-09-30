package com.omnicart.entity;

import org.springframework.data.domain.Persistable;
import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "OrderDetails")
public class OrderDetails implements Persistable<OrderDetailsId> {

    @EmbeddedId
    private OrderDetailsId id = new OrderDetailsId();

    @Transient
    private boolean isNew = true;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("orderId")
    @JoinColumn(name = "OrderID", nullable = false, updatable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("productId")
    @JoinColumn(name = "ProductID", nullable = false, updatable = false)
    private Product product;

    @Column(name = "Quantity", nullable = false)
    private Integer quantity;

    @Column(name = "ExactLedgerPrice", nullable = false, precision = 12, scale = 2, updatable = false)
    private BigDecimal exactLedgerPrice;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "LedgerID", nullable = false, updatable = false)
    private PriceLedger ledger;

    public OrderDetails() {}

    public OrderDetails(Order order, Product product, Integer quantity, BigDecimal exactLedgerPrice, PriceLedger ledger) {
        this.order = order;
        this.product = product;
        this.quantity = quantity;
        this.exactLedgerPrice = exactLedgerPrice;
        this.ledger = ledger;
        this.id = new OrderDetailsId(order.getId(), product.getId());
    }

    public OrderDetailsId getId() { return id; }
    public void setId(OrderDetailsId id) { this.id = id; }

    public Order getOrder() { return order; }
    public void setOrder(Order order) {
        this.order = order;
        if (order != null && this.id != null) {
            this.id.setOrderId(order.getId());
        }
    }

    public Product getProduct() { return product; }
    public void setProduct(Product product) {
        this.product = product;
        if (product != null && this.id != null) {
            this.id.setProductId(product.getId());
        }
    }

    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }

    public BigDecimal getExactLedgerPrice() { return exactLedgerPrice; }
    public void setExactLedgerPrice(BigDecimal exactLedgerPrice) { this.exactLedgerPrice = exactLedgerPrice; }

    public PriceLedger getLedger() { return ledger; }
    public void setLedger(PriceLedger ledger) { this.ledger = ledger; }

    public BigDecimal getLineTotal() {
        if (exactLedgerPrice == null || quantity == null) return BigDecimal.ZERO;
        return exactLedgerPrice.multiply(BigDecimal.valueOf(quantity));
    }

    @Override
    public boolean isNew() {
        return isNew;
    }

    @PostPersist
    @PostLoad
    public void markNotNew() {
        this.isNew = false;
    }
}
