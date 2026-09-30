package com.omnicart.controller;

import com.omnicart.dto.request.AddressRequest;
import com.omnicart.dto.response.AddressResponse;
import com.omnicart.dto.response.ApiResponse;
import com.omnicart.service.AddressService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Address Management", description = "APIs for customer delivery addresses")
public class AddressController {

    private final AddressService addressService;

    public AddressController(AddressService addressService) {
        this.addressService = addressService;
    }

    private void validateCustomerAccess(Long targetCustomerId) {
        org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof com.omnicart.security.UserPrincipal principal) {
            if (principal.getRole() == com.omnicart.security.Role.ADMIN) {
                return;
            }
            if (principal.getRole() == com.omnicart.security.Role.CUSTOMER && !principal.getId().equals(targetCustomerId)) {
                throw new org.springframework.security.access.AccessDeniedException("Access denied: You cannot view or modify another customer's addresses.");
            }
        }
    }

    @PostMapping("/api/customers/{customerId}/addresses")
    @Operation(summary = "Add delivery address for customer")
    public ResponseEntity<ApiResponse<AddressResponse>> addAddress(
            @PathVariable Long customerId,
            @Valid @RequestBody AddressRequest request) {
        validateCustomerAccess(customerId);
        AddressResponse res = addressService.addAddress(customerId, request);
        return new ResponseEntity<>(ApiResponse.success("Address added", res), HttpStatus.CREATED);
    }

    @GetMapping("/api/customers/{customerId}/addresses")
    @Operation(summary = "List all addresses for customer")
    public ResponseEntity<ApiResponse<List<AddressResponse>>> getCustomerAddresses(@PathVariable Long customerId) {
        validateCustomerAccess(customerId);
        return ResponseEntity.ok(ApiResponse.success(addressService.getCustomerAddresses(customerId)));
    }

    @GetMapping("/api/addresses/{addressId}")
    @Operation(summary = "Get address by ID")
    public ResponseEntity<ApiResponse<AddressResponse>> getAddressById(@PathVariable Long addressId) {
        AddressResponse addr = addressService.getAddressById(addressId);
        validateCustomerAccess(addr.getCustomerId());
        return ResponseEntity.ok(ApiResponse.success(addr));
    }

    @PutMapping("/api/addresses/{addressId}")
    @Operation(summary = "Update address")
    public ResponseEntity<ApiResponse<AddressResponse>> updateAddress(
            @PathVariable Long addressId,
            @Valid @RequestBody AddressRequest request) {
        AddressResponse addr = addressService.getAddressById(addressId);
        validateCustomerAccess(addr.getCustomerId());
        return ResponseEntity.ok(ApiResponse.success("Address updated", addressService.updateAddress(addressId, request)));
    }

    @DeleteMapping("/api/addresses/{addressId}")
    @Operation(summary = "Delete address")
    public ResponseEntity<ApiResponse<Void>> deleteAddress(@PathVariable Long addressId) {
        AddressResponse addr = addressService.getAddressById(addressId);
        validateCustomerAccess(addr.getCustomerId());
        addressService.deleteAddress(addressId);
        return ResponseEntity.ok(ApiResponse.success("Address deleted", null));
    }
}
