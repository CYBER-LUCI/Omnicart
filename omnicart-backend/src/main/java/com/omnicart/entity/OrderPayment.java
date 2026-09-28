package com.omnicart.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "OrderPayment")
public class OrderPayment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "PaymentID")
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "OrderID", nullable = false, unique = true)
    private Order order;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "MethodID", nullable = false)
    private PaymentMethod paymentMethod;

    @Column(name = "PaidAmount", nullable = false, precision = 12, scale = 2)
    private BigDecimal paidAmount;

    @Column(name = "PaidAt", nullable = false)
    private LocalDateTime paidAt = LocalDateTime.now();

    public OrderPayment() {}

    public OrderPayment(Order order, PaymentMethod paymentMethod, BigDecimal paidAmount) {
        this.order = order;
        this.paymentMethod = paymentMethod;
        this.paidAmount = paidAmount;
        this.paidAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Order getOrder() { return order; }
    public void setOrder(Order order) { this.order = order; }

    public PaymentMethod getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(PaymentMethod paymentMethod) { this.paymentMethod = paymentMethod; }

    public BigDecimal getPaidAmount() { return paidAmount; }
    public void setPaidAmount(BigDecimal paidAmount) { this.paidAmount = paidAmount; }

    public LocalDateTime getPaidAt() { return paidAt; }
    public void setPaidAt(LocalDateTime paidAt) { this.paidAt = paidAt; }
}
