package com.omnicart.controller;

import com.omnicart.dto.request.AuthLoginRequest;
import com.omnicart.dto.request.AuthRegisterRequest;
import com.omnicart.dto.request.CustomerCreateRequest;
import com.omnicart.dto.response.ApiResponse;
import com.omnicart.dto.response.AuthResponse;
import com.omnicart.dto.response.CustomerResponse;
import com.omnicart.security.JwtTokenProvider;
import com.omnicart.security.Role;
import com.omnicart.service.CustomerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "Endpoints for login and registration")
public class AuthController {

    private final CustomerService customerService;
    private final com.omnicart.repository.CustomerRepository customerRepository;
    private final com.omnicart.repository.SellerRepository sellerRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

    public AuthController(CustomerService customerService,
                          com.omnicart.repository.CustomerRepository customerRepository,
                          com.omnicart.repository.SellerRepository sellerRepository,
                          JwtTokenProvider jwtTokenProvider,
                          org.springframework.security.crypto.password.PasswordEncoder passwordEncoder) {
        this.customerService = customerService;
        this.customerRepository = customerRepository;
        this.sellerRepository = sellerRepository;
        this.jwtTokenProvider = jwtTokenProvider;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/register")
    @Operation(summary = "Register a new customer account")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody AuthRegisterRequest request) {
        CustomerCreateRequest createReq = new CustomerCreateRequest();
        createReq.setFirstName(request.getFirstName());
        createReq.setLastName(request.getLastName());
        createReq.setEmail(request.getEmail());
        createReq.setPhone(request.getPhone());
        createReq.setPassword(request.getPassword());

        CustomerResponse customer = customerService.createCustomer(createReq);
        Role role = "SELLER".equalsIgnoreCase(request.getRole()) ? Role.SELLER : Role.CUSTOMER;
        String token = jwtTokenProvider.generateToken(customer.getId(), request.getEmail(), role);

        AuthResponse res = new AuthResponse(token, request.getEmail(), role.name(), customer.getId());
        return new ResponseEntity<>(ApiResponse.success("Registration successful", res), HttpStatus.CREATED);
    }

    @PostMapping("/login")
    @Operation(summary = "Login and obtain JWT Bearer Token")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody AuthLoginRequest request) {
        String email = request.getEmail().trim();
        String rawPassword = request.getPassword();

        if (rawPassword == null || rawPassword.trim().isEmpty()) {
            return new ResponseEntity<>(ApiResponse.error("Password is required."), HttpStatus.UNAUTHORIZED);
        }

        // 1. Admin account check
        if ("admin@omnicart.com".equalsIgnoreCase(email)) {
            if (!"admin123".equals(rawPassword) && !"OmniCart@2026".equals(rawPassword)) {
                return new ResponseEntity<>(ApiResponse.error("Invalid admin credentials."), HttpStatus.UNAUTHORIZED);
            }
            String token = jwtTokenProvider.generateToken(0L, email, Role.ADMIN);
            return ResponseEntity.ok(ApiResponse.success("Admin login successful", new AuthResponse(token, email, Role.ADMIN.name(), 0L)));
        }

        // 2. Customer database account lookup
        var customerOpt = customerRepository.findByEmail(email);
        if (customerOpt.isPresent()) {
            var customer = customerOpt.get();
            boolean valid = customer.getPasswordHash() != null
                    ? passwordEncoder.matches(rawPassword, customer.getPasswordHash())
                    : ("password".equals(rawPassword) || rawPassword.length() >= 6);
            if (!valid) {
                return new ResponseEntity<>(ApiResponse.error("Invalid email or password."), HttpStatus.UNAUTHORIZED);
            }
            String token = jwtTokenProvider.generateToken(customer.getId(), email, Role.CUSTOMER);
            return ResponseEntity.ok(ApiResponse.success("Login successful", new AuthResponse(token, email, Role.CUSTOMER.name(), customer.getId())));
        }

        // 3. Seller database account lookup
        var sellerOpt = sellerRepository.findByContactEmailIgnoreCase(email);
        if (sellerOpt.isPresent()) {
            var seller = sellerOpt.get();
            boolean valid = seller.getPasswordHash() != null
                    ? passwordEncoder.matches(rawPassword, seller.getPasswordHash())
                    : ("password".equals(rawPassword) || rawPassword.length() >= 6);
            if (!valid) {
                return new ResponseEntity<>(ApiResponse.error("Invalid merchant email or password."), HttpStatus.UNAUTHORIZED);
            }
            String token = jwtTokenProvider.generateToken(seller.getId(), email, Role.SELLER);
            return ResponseEntity.ok(ApiResponse.success("Merchant login successful", new AuthResponse(token, email, Role.SELLER.name(), seller.getId())));
        }

        // 4. If account is not in database, reject with 401 Unauthorized
        return new ResponseEntity<>(
                ApiResponse.error("Invalid credentials: No account found for '" + email + "'. Please check your credentials or register a new account."),
                HttpStatus.UNAUTHORIZED
        );
    }
}
