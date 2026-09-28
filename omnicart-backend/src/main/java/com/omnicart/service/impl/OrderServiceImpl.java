package com.omnicart.service.impl;

import com.omnicart.dto.request.OrderCreateRequest;
import com.omnicart.dto.request.OrderItemRequest;
import com.omnicart.dto.request.ShippingStatusUpdateRequest;
import com.omnicart.dto.response.OrderResponse;
import com.omnicart.entity.*;
import com.omnicart.exception.*;
import com.omnicart.mapper.OrderMapper;
import com.omnicart.repository.*;
import com.omnicart.service.OrderService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
public class OrderServiceImpl implements OrderService {

    private static final Logger log = LoggerFactory.getLogger(OrderServiceImpl.class);

    private final OrderRepository orderRepository;
    private final OrderDetailsRepository orderDetailsRepository;
    private final OrderPaymentRepository orderPaymentRepository;
    private final CustomerRepository customerRepository;
    private final ProductRepository productRepository;
    private final PriceLedgerRepository priceLedgerRepository;
    private final PriceLedgerSourceRepository priceLedgerSourceRepository;
    private final ShippingStatusRepository shippingStatusRepository;
    private final PaymentMethodRepository paymentMethodRepository;

    public OrderServiceImpl(OrderRepository orderRepository,
                            OrderDetailsRepository orderDetailsRepository,
                            OrderPaymentRepository orderPaymentRepository,
                            CustomerRepository customerRepository,
                            ProductRepository productRepository,
                            PriceLedgerRepository priceLedgerRepository,
                            PriceLedgerSourceRepository priceLedgerSourceRepository,
                            ShippingStatusRepository shippingStatusRepository,
                            PaymentMethodRepository paymentMethodRepository) {
        this.orderRepository = orderRepository;
        this.orderDetailsRepository = orderDetailsRepository;
        this.orderPaymentRepository = orderPaymentRepository;
        this.customerRepository = customerRepository;
        this.productRepository = productRepository;
        this.priceLedgerRepository = priceLedgerRepository;
        this.priceLedgerSourceRepository = priceLedgerSourceRepository;
        this.shippingStatusRepository = shippingStatusRepository;
        this.paymentMethodRepository = paymentMethodRepository;
    }

    /**
     * TRANSACTIONAL ORDER PLACEMENT ENGINE
     * 1. Pessimistic write locking on Product rows (prevents race conditions)
     * 2. Stock verification (prevents negative stock)
     * 3. Price lookup from PriceLedger (locks exact historical price)
     * 4. Stock decrement
     * 5. Order & OrderDetails insertion
     * 6. OrderPayment creation
     */
    @Override
    @Transactional(isolation = Isolation.READ_COMMITTED)
    public OrderResponse placeOrder(OrderCreateRequest request) {
        log.info("Initiating checkout transaction for customer ID: {}", request.getCustomerId());

        // 1. Validate Customer
        Customer customer = customerRepository.findById(request.getCustomerId())
                .orElseThrow(() -> new CustomerNotFoundException(request.getCustomerId()));

        // 2. Validate Payment Method
        PaymentMethod paymentMethod = paymentMethodRepository.findById(request.getPaymentMethodId())
                .orElseThrow(() -> new ResourceNotFoundException("Invalid PaymentMethod ID: " + request.getPaymentMethodId()));

        // 3. Validate Items
        if (request.getItems() == null || request.getItems().isEmpty()) {
            throw new InvalidOrderException("Order must contain at least one item.");
        }

        // 4. Create Order Header (Default status: Pending, ID = 1)
        ShippingStatus pendingStatus = shippingStatusRepository.findById(1)
                .orElseGet(() -> shippingStatusRepository.save(new ShippingStatus(1, "Pending")));

        Order order = new Order(customer, pendingStatus);
        Order savedOrder = orderRepository.save(order);

        BigDecimal calculatedTotal = BigDecimal.ZERO;
        List<OrderDetails> detailsList = new ArrayList<>();

        // 5. Process each order item with PESSIMISTIC WRITE LOCK
        for (OrderItemRequest item : request.getItems()) {
            if (item.getQuantity() <= 0) {
                throw new InvalidOrderException("Quantity must be greater than zero for product ID: " + item.getProductId());
            }

            // Lock the product row: SELECT ... FOR UPDATE
            Product product = productRepository.findByIdWithPessimisticLock(item.getProductId())
                    .orElseThrow(() -> new ProductNotFoundException(item.getProductId()));

            // Stock Check
            if (product.getStockQuantity() < item.getQuantity()) {
                log.warn("Stock underflow: Product {} has {} units, requested {}",
                        product.getId(), product.getStockQuantity(), item.getQuantity());
                throw new InsufficientStockException(product.getId(), product.getStockQuantity(), item.getQuantity());
            }

            // Retrieve latest valid price from PriceLedger (with baseline fallback)
            PriceLedger latestPrice = priceLedgerRepository.findLatestByProductId(product.getId())
                    .orElseGet(() -> {
                        PriceLedgerSource source = priceLedgerSourceRepository.findById(1)
                                .orElseGet(() -> priceLedgerSourceRepository.save(new PriceLedgerSource(1, "System Baseline")));
                        PriceLedger fallback = new PriceLedger(product, source, BigDecimal.valueOf(999), BigDecimal.ZERO);
                        return priceLedgerRepository.save(fallback);
                    });

            // Atomically decrement stock
            product.setStockQuantity(product.getStockQuantity() - item.getQuantity());
            productRepository.save(product);

            // Create OrderDetails snapshotting the exact ledger price and ledger ID
            OrderDetails orderDetails = new OrderDetails(
                    savedOrder,
                    product,
                    item.getQuantity(),
                    latestPrice.getPrice(),
                    latestPrice
            );
            detailsList.add(orderDetails);

            BigDecimal lineTotal = latestPrice.getPrice().multiply(BigDecimal.valueOf(item.getQuantity()));
            calculatedTotal = calculatedTotal.add(lineTotal);
        }

        // Save order line items
        orderDetailsRepository.saveAll(detailsList);
        savedOrder.setOrderDetails(detailsList);

        // 6. Record Payment
        OrderPayment payment = new OrderPayment(savedOrder, paymentMethod, calculatedTotal);
        orderPaymentRepository.save(payment);
        savedOrder.setPayment(payment);

        log.info("Order successfully created! Order ID: {}, Total Amount: {}", savedOrder.getId(), calculatedTotal);
        return OrderMapper.toResponse(savedOrder);
    }

    @Override
    @Transactional(readOnly = true)
    public OrderResponse getOrderById(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException(orderId));
        return OrderMapper.toResponse(order);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<OrderResponse> getAllOrders(Pageable pageable) {
        return orderRepository.findAll(pageable).map(OrderMapper::toResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<OrderResponse> getCustomerOrders(Long customerId, Pageable pageable) {
        if (!customerRepository.existsById(customerId)) {
            throw new CustomerNotFoundException(customerId);
        }
        return orderRepository.findByCustomerIdOrderByOrderDateDesc(customerId, pageable)
                .map(OrderMapper::toResponse);
    }

    @Override
    @Transactional
    public OrderResponse updateShippingStatus(Long orderId, ShippingStatusUpdateRequest request) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException(orderId));

        ShippingStatus newStatus = shippingStatusRepository.findById(request.getStatusId())
                .orElseThrow(() -> new InvalidShippingStatusException("Shipping status not found with ID: " + request.getStatusId()));

        int currentStatusId = order.getShippingStatus().getId();

        // Validate state transitions
        if (currentStatusId == 5) { // Delivered
            throw new InvalidShippingStatusException("Cannot transition from DELIVERED state.");
        }
        if (currentStatusId == 6) { // Cancelled
            throw new InvalidShippingStatusException("Cannot change status of a CANCELLED order.");
        }

        order.setShippingStatus(newStatus);
        Order updated = orderRepository.save(order);
        log.info("Updated Order {} status from {} to {}", orderId, currentStatusId, newStatus.getStatusName());
        return OrderMapper.toResponse(updated);
    }

    @Override
    @Transactional
    public OrderResponse cancelOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException(orderId));

        if (order.getShippingStatus().getId() == 5) { // Delivered
            throw new InvalidOrderException("Cannot cancel an order that has already been DELIVERED.");
        }
        if (order.getShippingStatus().getId() == 6) { // Already Cancelled
            throw new InvalidOrderException("Order is already CANCELLED.");
        }

        // Restore inventory for each item
        for (OrderDetails od : order.getOrderDetails()) {
            Product product = productRepository.findByIdWithPessimisticLock(od.getProduct().getId())
                    .orElseThrow(() -> new ProductNotFoundException(od.getProduct().getId()));

            product.setStockQuantity(product.getStockQuantity() + od.getQuantity());
            productRepository.save(product);
            log.info("Restored {} units of product {} due to order cancellation.", od.getQuantity(), product.getId());
        }

        // Update status to Cancelled (6)
        ShippingStatus cancelledStatus = shippingStatusRepository.findById(6)
                .orElseGet(() -> shippingStatusRepository.save(new ShippingStatus(6, "Cancelled")));

        order.setShippingStatus(cancelledStatus);
        Order updated = orderRepository.save(order);
        log.info("Order ID: {} cancelled successfully.", orderId);
        return OrderMapper.toResponse(updated);
    }

    @Override
    @Transactional(readOnly = true)
    public BigDecimal calculateOrderTotal(Long orderId) {
        if (!orderRepository.existsById(orderId)) {
            throw new OrderNotFoundException(orderId);
        }
        return orderDetailsRepository.calculateOrderTotal(orderId);
    }
}
