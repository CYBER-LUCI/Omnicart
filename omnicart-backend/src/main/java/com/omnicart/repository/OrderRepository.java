package com.omnicart.repository;

import com.omnicart.entity.Order;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    Page<Order> findByCustomerIdOrderByOrderDateDesc(Long customerId, Pageable pageable);

    List<Order> findByCustomerIdOrderByOrderDateDesc(Long customerId);

    @Query("SELECT COUNT(o) FROM Order o WHERE o.customer.id = :customerId")
    long countByCustomerId(@Param("customerId") Long customerId);

    @Query("SELECT COALESCE(SUM(od.quantity * od.exactLedgerPrice), 0.00) " +
           "FROM OrderDetails od JOIN od.order o " +
           "WHERE o.customer.id = :customerId AND o.shippingStatus.id <> 6")
    BigDecimal calculateCustomerTotalSpent(@Param("customerId") Long customerId);

    @Query("SELECT DISTINCT o FROM Order o JOIN o.orderDetails od WHERE od.product.seller.id = :sellerId ORDER BY o.orderDate DESC")
    Page<Order> findOrdersContainingSellerProducts(@Param("sellerId") Long sellerId, Pageable pageable);

    @Query("SELECT COUNT(DISTINCT o) FROM Order o JOIN o.orderDetails od WHERE od.product.seller.id = :sellerId")
    long countOrdersContainingSellerProducts(@Param("sellerId") Long sellerId);

    @Query("SELECT COALESCE(SUM(od.quantity * od.exactLedgerPrice), 0.00) " +
           "FROM OrderDetails od JOIN od.order o " +
           "WHERE od.product.seller.id = :sellerId AND o.shippingStatus.id <> 6")
    BigDecimal calculateSellerTotalRevenue(@Param("sellerId") Long sellerId);
}
