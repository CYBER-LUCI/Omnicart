package com.omnicart.service;

import com.omnicart.dto.request.OrderCreateRequest;
import com.omnicart.dto.request.OrderItemRequest;
import com.omnicart.dto.response.OrderResponse;
import com.omnicart.entity.*;
import com.omnicart.exception.InsufficientStockException;
import com.omnicart.repository.*;
import com.omnicart.service.impl.OrderServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private OrderDetailsRepository orderDetailsRepository;

    @Mock
    private OrderPaymentRepository orderPaymentRepository;

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private ProductRepository productRepository;

    @Mock
    private PriceLedgerRepository priceLedgerRepository;

    @Mock
    private ShippingStatusRepository shippingStatusRepository;

    @Mock
    private PaymentMethodRepository paymentMethodRepository;

    @InjectMocks
    private OrderServiceImpl orderService;

    private Customer mockCustomer;
    private Product mockProduct;
    private PriceLedger mockPriceLedger;
    private PaymentMethod mockPaymentMethod;
    private ShippingStatus mockStatus;

    @BeforeEach
    void setUp() {
        mockCustomer = new Customer("Aarav", "Sharma");
        mockCustomer.setId(1L);

        mockProduct = new Product();
        mockProduct.setId(101L);
        mockProduct.setName("Samsung Galaxy S24");
        mockProduct.setStockQuantity(10);

        mockPriceLedger = new PriceLedger();
        mockPriceLedger.setId(500L);
        mockPriceLedger.setProduct(mockProduct);
        mockPriceLedger.setPrice(new BigDecimal("79999.00"));

        mockPaymentMethod = new PaymentMethod(3, "UPI");
        mockStatus = new ShippingStatus(1, "Pending");
    }

    @Test
    @DisplayName("Should successfully place order, deduct stock, and lock exact ledger price")
    void testPlaceOrder_Success() {
        OrderCreateRequest request = new OrderCreateRequest();
        request.setCustomerId(1L);
        request.setPaymentMethodId(3);
        request.setItems(Collections.singletonList(new OrderItemRequest(101L, 2)));

        when(customerRepository.findById(1L)).thenReturn(Optional.of(mockCustomer));
        when(paymentMethodRepository.findById(3)).thenReturn(Optional.of(mockPaymentMethod));
        when(shippingStatusRepository.findById(1)).thenReturn(Optional.of(mockStatus));
        when(productRepository.findByIdWithPessimisticLock(101L)).thenReturn(Optional.of(mockProduct));
        when(priceLedgerRepository.findLatestByProductId(101L)).thenReturn(Optional.of(mockPriceLedger));

        Order savedOrder = new Order(mockCustomer, mockStatus);
        savedOrder.setId(1001L);
        when(orderRepository.save(any(Order.class))).thenReturn(savedOrder);

        OrderResponse response = orderService.placeOrder(request);

        assertNotNull(response);
        assertEquals(1001L, response.getId());
        assertEquals(8, mockProduct.getStockQuantity()); // 10 - 2 = 8
        assertEquals(new BigDecimal("159998.00"), response.getTotalAmount());

        verify(productRepository, times(1)).save(mockProduct);
        verify(orderDetailsRepository, times(1)).saveAll(any());
        verify(orderPaymentRepository, times(1)).save(any());
    }

    @Test
    @DisplayName("Should throw InsufficientStockException and rollback when stock is insufficient")
    void testPlaceOrder_InsufficientStock_ThrowsException() {
        mockProduct.setStockQuantity(1);

        OrderCreateRequest request = new OrderCreateRequest();
        request.setCustomerId(1L);
        request.setPaymentMethodId(3);
        request.setItems(Collections.singletonList(new OrderItemRequest(101L, 2)));

        when(customerRepository.findById(1L)).thenReturn(Optional.of(mockCustomer));
        when(paymentMethodRepository.findById(3)).thenReturn(Optional.of(mockPaymentMethod));
        when(shippingStatusRepository.findById(1)).thenReturn(Optional.of(mockStatus));
        when(productRepository.findByIdWithPessimisticLock(101L)).thenReturn(Optional.of(mockProduct));

        Order savedOrder = new Order(mockCustomer, mockStatus);
        savedOrder.setId(1001L);
        when(orderRepository.save(any(Order.class))).thenReturn(savedOrder);

        assertThrows(InsufficientStockException.class, () -> orderService.placeOrder(request));
        assertEquals(1, mockProduct.getStockQuantity()); // Stock remains untouched
        verify(orderPaymentRepository, never()).save(any());
    }
}
