package com.omnicart.service;

import com.omnicart.dto.request.OrderCreateRequest;
import com.omnicart.dto.request.ShippingStatusUpdateRequest;
import com.omnicart.dto.response.OrderResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;

public interface OrderService {
    OrderResponse placeOrder(OrderCreateRequest request);
    OrderResponse getOrderById(Long orderId);
    Page<OrderResponse> getAllOrders(Pageable pageable);
    Page<OrderResponse> getCustomerOrders(Long customerId, Pageable pageable);
    OrderResponse updateShippingStatus(Long orderId, ShippingStatusUpdateRequest request);
    OrderResponse cancelOrder(Long orderId);
    BigDecimal calculateOrderTotal(Long orderId);
}
