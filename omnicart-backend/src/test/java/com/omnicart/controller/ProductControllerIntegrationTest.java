package com.omnicart.controller;

import com.omnicart.dto.response.ProductResponse;
import com.omnicart.service.ProductService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.Collections;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(ProductController.class)
@AutoConfigureMockMvc(addFilters = false)
public class ProductControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ProductService productService;

    @MockBean
    private com.omnicart.security.JwtAuthenticationFilter jwtAuthenticationFilter;

    @MockBean
    private com.omnicart.security.JwtTokenProvider jwtTokenProvider;

    @MockBean
    private com.omnicart.security.CustomUserDetailsService customUserDetailsService;

    @Test
    @DisplayName("GET /api/products - Should return paginated products")
    void testGetAllProducts() throws Exception {
        ProductResponse response = new ProductResponse();
        response.setId(1L);
        response.setName("Test Product");
        response.setCurrentPrice(new BigDecimal("999.00"));
        response.setStockQuantity(50);
        response.setStockStatus("AVAILABLE");

        when(productService.getAllProducts(any(), any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(Collections.singletonList(response)));

        mockMvc.perform(get("/api/products")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].name").value("Test Product"))
                .andExpect(jsonPath("$.data.content[0].currentPrice").value(999.00));
    }
}
