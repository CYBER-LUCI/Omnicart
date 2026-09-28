package com.omnicart.service;

import com.omnicart.dto.request.PriceLedgerRequest;
import com.omnicart.dto.response.PriceLedgerResponse;
import com.omnicart.entity.PriceLedger;
import com.omnicart.entity.PriceLedgerSource;
import com.omnicart.entity.Product;
import com.omnicart.repository.PriceLedgerRepository;
import com.omnicart.repository.PriceLedgerSourceRepository;
import com.omnicart.repository.ProductRepository;
import com.omnicart.service.impl.PriceServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class PriceServiceTest {

    @Mock
    private PriceLedgerRepository priceLedgerRepository;

    @Mock
    private PriceLedgerSourceRepository priceLedgerSourceRepository;

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private PriceServiceImpl priceService;

    private Product mockProduct;
    private PriceLedgerSource mockSource;

    @BeforeEach
    void setUp() {
        mockProduct = new Product();
        mockProduct.setId(201L);
        mockProduct.setName("HP Pavilion Laptop");

        mockSource = new PriceLedgerSource(2, "Automated Discount");
    }

    @Test
    @DisplayName("Should append new price to ledger with correct fluctuation calculation")
    void testAddPriceEntry_AppendOnly() {
        PriceLedger currentPrice = new PriceLedger(mockProduct, mockSource, new BigDecimal("55000.00"), BigDecimal.ZERO);
        when(productRepository.findById(201L)).thenReturn(Optional.of(mockProduct));
        when(priceLedgerSourceRepository.findById(2)).thenReturn(Optional.of(mockSource));
        when(priceLedgerRepository.findLatestByProductId(201L)).thenReturn(Optional.of(currentPrice));

        PriceLedgerRequest request = new PriceLedgerRequest();
        request.setPrice(new BigDecimal("52000.00"));
        request.setSourceId(2);

        PriceLedger savedLedger = new PriceLedger(mockProduct, mockSource, new BigDecimal("52000.00"), new BigDecimal("-3000.00"));
        savedLedger.setId(701L);
        when(priceLedgerRepository.save(any(PriceLedger.class))).thenReturn(savedLedger);

        PriceLedgerResponse response = priceService.addPriceEntry(201L, request);

        assertNotNull(response);
        assertEquals(new BigDecimal("52000.00"), response.getPrice());
        assertEquals(new BigDecimal("-3000.00"), response.getPriceFluctuation());

        verify(priceLedgerRepository, times(1)).save(any(PriceLedger.class));
        verify(priceLedgerRepository, never()).delete(any());
    }
}
