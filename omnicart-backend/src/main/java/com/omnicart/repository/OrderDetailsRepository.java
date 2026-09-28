package com.omnicart.repository;

import com.omnicart.entity.OrderDetails;
import com.omnicart.entity.OrderDetailsId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface OrderDetailsRepository extends JpaRepository<OrderDetails, OrderDetailsId> {

    List<OrderDetails> findByOrderId(Long orderId);

    @Query("SELECT COALESCE(SUM(od.quantity * od.exactLedgerPrice), 0.00) FROM OrderDetails od WHERE od.order.id = :orderId")
    BigDecimal calculateOrderTotal(@Param("orderId") Long orderId);
}
