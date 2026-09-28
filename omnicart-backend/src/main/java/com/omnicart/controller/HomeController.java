package com.omnicart.controller;

import com.omnicart.dto.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@Tag(name = "Platform Root", description = "Server health and API discovery")
public class HomeController {

    @GetMapping("/")
    @Operation(summary = "Platform health check and quick links")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getApiInfo() {
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("service", "OmniCart Marketplace REST Backend");
        info.put("status", "UP & RUNNING");
        info.put("database", "MySQL (OmniCartDB)");
        info.put("swaggerDocumentation", "http://localhost:8080/swagger-ui/index.html");
        info.put("apiCatalog", "http://localhost:8080/api/products");
        info.put("apiCategories", "http://localhost:8080/api/categories");
        info.put("frontendLocation", "Open omnicart-frontend/index.html in your browser");
        return ResponseEntity.ok(ApiResponse.success("OmniCart Backend is running successfully", info));
    }
}
