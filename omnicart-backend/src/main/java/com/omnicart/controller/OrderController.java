package com.omnicart.controller;

import com.omnicart.dto.request.OrderCreateRequest;
import com.omnicart.dto.request.ShippingStatusUpdateRequest;
import com.omnicart.dto.response.ApiResponse;
import com.omnicart.dto.response.OrderResponse;
import com.omnicart.dto.response.PageResponse;
import com.omnicart.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

@RestController
@RequestMapping("/api/orders")
@Tag(name = "Order Management", description = "Transactional checkout engine, shipping transitions, and cancellation")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @PostMapping
    @Operation(summary = "Place order (ACID transaction with pessimistic row-locking on inventory)")
    public ResponseEntity<ApiResponse<OrderResponse>> placeOrder(@Valid @RequestBody OrderCreateRequest request) {
        OrderResponse order = orderService.placeOrder(request);
        return new ResponseEntity<>(ApiResponse.success("Order placed successfully", order), HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get order details by ID (including items and locked historical prices)")
    public ResponseEntity<ApiResponse<OrderResponse>> getOrderById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(orderService.getOrderById(id)));
    }

    @GetMapping
    @Operation(summary = "List all orders (paginated)")
    public ResponseEntity<ApiResponse<PageResponse<OrderResponse>>> getAllOrders(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<OrderResponse> orders = orderService.getAllOrders(PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.success(new PageResponse<>(orders)));
    }

    @PutMapping("/{id}/shipping-status")
    @Operation(summary = "Update order shipping status")
    public ResponseEntity<ApiResponse<OrderResponse>> updateShippingStatus(
            @PathVariable Long id,
            @Valid @RequestBody ShippingStatusUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Shipping status updated", orderService.updateShippingStatus(id, request)));
    }

    @PostMapping("/{id}/cancel")
    @Operation(summary = "Cancel order and atomically restore stock")
    public ResponseEntity<ApiResponse<OrderResponse>> cancelOrder(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("Order cancelled", orderService.cancelOrder(id)));
    }

    @GetMapping("/{id}/total")
    @Operation(summary = "Get derived order total calculation (Quantity * ExactLedgerPrice)")
    public ResponseEntity<ApiResponse<BigDecimal>> getOrderTotal(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(orderService.calculateOrderTotal(id)));
    }
}
