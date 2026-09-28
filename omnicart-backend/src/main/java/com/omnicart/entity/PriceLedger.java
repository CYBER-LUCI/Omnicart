package com.omnicart.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "PriceLedger")
public class PriceLedger {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "LedgerID")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ProductID", nullable = false, updatable = false)
    private Product product;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "SourceID", nullable = false, updatable = false)
    private PriceLedgerSource source;

    @Column(name = "RecordedAt", nullable = false, updatable = false)
    private LocalDateTime recordedAt = LocalDateTime.now();

    @Column(name = "Price", nullable = false, precision = 12, scale = 2, updatable = false)
    private BigDecimal price;

    @Column(name = "PriceFluctuation", nullable = false, precision = 12, scale = 2, updatable = false)
    private BigDecimal priceFluctuation = BigDecimal.ZERO;

    public PriceLedger() {}

    public PriceLedger(Product product, PriceLedgerSource source, BigDecimal price, BigDecimal priceFluctuation) {
        this.product = product;
        this.source = source;
        this.price = price;
        this.priceFluctuation = priceFluctuation != null ? priceFluctuation : BigDecimal.ZERO;
        this.recordedAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Product getProduct() { return product; }
    public void setProduct(Product product) { this.product = product; }

    public PriceLedgerSource getSource() { return source; }
    public void setSource(PriceLedgerSource source) { this.source = source; }

    public LocalDateTime getRecordedAt() { return recordedAt; }
    public void setRecordedAt(LocalDateTime recordedAt) { this.recordedAt = recordedAt; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public BigDecimal getPriceFluctuation() { return priceFluctuation; }
    public void setPriceFluctuation(BigDecimal priceFluctuation) { this.priceFluctuation = priceFluctuation; }
}
