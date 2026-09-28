package com.omnicart.service.impl;

import com.omnicart.dto.request.CustomerCreateRequest;
import com.omnicart.dto.request.CustomerUpdateRequest;
import com.omnicart.dto.request.EmailRequest;
import com.omnicart.dto.request.PhoneRequest;
import com.omnicart.dto.response.AddressResponse;
import com.omnicart.dto.response.CustomerDashboardResponse;
import com.omnicart.dto.response.CustomerResponse;
import com.omnicart.dto.response.OrderResponse;
import com.omnicart.entity.Customer;
import com.omnicart.entity.CustomerEmail;
import com.omnicart.entity.CustomerPhone;
import com.omnicart.exception.CustomerNotFoundException;
import com.omnicart.exception.DuplicateEmailException;
import com.omnicart.exception.ResourceNotFoundException;
import com.omnicart.mapper.AddressMapper;
import com.omnicart.mapper.CustomerMapper;
import com.omnicart.mapper.OrderMapper;
import com.omnicart.repository.AddressRepository;
import com.omnicart.repository.CustomerEmailRepository;
import com.omnicart.repository.CustomerPhoneRepository;
import com.omnicart.repository.CustomerRepository;
import com.omnicart.repository.OrderRepository;
import com.omnicart.service.CustomerService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class CustomerServiceImpl implements CustomerService {

    private static final Logger log = LoggerFactory.getLogger(CustomerServiceImpl.class);

    private final CustomerRepository customerRepository;
    private final CustomerEmailRepository customerEmailRepository;
    private final CustomerPhoneRepository customerPhoneRepository;
    private final AddressRepository addressRepository;
    private final OrderRepository orderRepository;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

    public CustomerServiceImpl(CustomerRepository customerRepository,
                               CustomerEmailRepository customerEmailRepository,
                               CustomerPhoneRepository customerPhoneRepository,
                               AddressRepository addressRepository,
                               OrderRepository orderRepository,
                               org.springframework.security.crypto.password.PasswordEncoder passwordEncoder) {
        this.customerRepository = customerRepository;
        this.customerEmailRepository = customerEmailRepository;
        this.customerPhoneRepository = customerPhoneRepository;
        this.addressRepository = addressRepository;
        this.orderRepository = orderRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public CustomerResponse createCustomer(CustomerCreateRequest request) {
        if (customerEmailRepository.existsByEmailAddressIgnoreCase(request.getEmail())) {
            throw new DuplicateEmailException(request.getEmail());
        }

        Customer customer = new Customer(request.getFirstName(), request.getLastName());
        if (request.getPassword() != null && !request.getPassword().isBlank()) {
            customer.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        } else {
            customer.setPasswordHash(passwordEncoder.encode("password"));
        }
        Customer savedCustomer = customerRepository.save(customer);

        CustomerEmail email = new CustomerEmail(savedCustomer, request.getEmail(), true);
        customerEmailRepository.save(email);
        savedCustomer.addEmail(email);

        CustomerPhone phone = new CustomerPhone(savedCustomer, request.getPhone(), true);
        customerPhoneRepository.save(phone);
        savedCustomer.addPhone(phone);

        log.info("Registered customer ID: {} ({})", savedCustomer.getId(), request.getEmail());
        return CustomerMapper.toResponse(savedCustomer);
    }

    @Override
    @Transactional(readOnly = true)
    public CustomerResponse getCustomerById(Long id) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new CustomerNotFoundException(id));
        return CustomerMapper.toResponse(customer);
    }

    @Override
    @Transactional
    public CustomerResponse updateCustomer(Long id, CustomerUpdateRequest request) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new CustomerNotFoundException(id));

        customer.setFirstName(request.getFirstName());
        customer.setLastName(request.getLastName());
        Customer updated = customerRepository.save(customer);
        return CustomerMapper.toResponse(updated);
    }

    @Override
    @Transactional
    public void deleteCustomer(Long id) {
        if (!customerRepository.existsById(id)) {
            throw new CustomerNotFoundException(id);
        }
        customerRepository.deleteById(id);
        log.info("Deleted customer ID: {}", id);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<CustomerResponse> getAllCustomers(Pageable pageable) {
        return customerRepository.findAll(pageable).map(CustomerMapper::toResponse);
    }

    @Override
    @Transactional
    public CustomerResponse addEmail(Long customerId, EmailRequest request) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new CustomerNotFoundException(customerId));

        if (customerEmailRepository.existsByEmailAddressIgnoreCase(request.getEmailAddress())) {
            throw new DuplicateEmailException(request.getEmailAddress());
        }

        CustomerEmail email = new CustomerEmail(customer, request.getEmailAddress(), request.getIsPrimary());
        customerEmailRepository.save(email);
        customer.addEmail(email);
        return CustomerMapper.toResponse(customer);
    }

    @Override
    @Transactional
    public void removeEmail(Long customerId, Long emailId) {
        CustomerEmail email = customerEmailRepository.findById(emailId)
                .orElseThrow(() -> new ResourceNotFoundException("Email not found with ID: " + emailId));

        if (!email.getCustomer().getId().equals(customerId)) {
            throw new ResourceNotFoundException("Email does not belong to customer: " + customerId);
        }
        customerEmailRepository.delete(email);
    }

    @Override
    @Transactional
    public CustomerResponse addPhone(Long customerId, PhoneRequest request) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new CustomerNotFoundException(customerId));

        CustomerPhone phone = new CustomerPhone(customer, request.getPhoneNumber(), request.getIsPrimary());
        customerPhoneRepository.save(phone);
        customer.addPhone(phone);
        return CustomerMapper.toResponse(customer);
    }

    @Override
    @Transactional
    public void removePhone(Long customerId, Long phoneId) {
        CustomerPhone phone = customerPhoneRepository.findById(phoneId)
                .orElseThrow(() -> new ResourceNotFoundException("Phone not found with ID: " + phoneId));

        if (!phone.getCustomer().getId().equals(customerId)) {
            throw new ResourceNotFoundException("Phone does not belong to customer: " + customerId);
        }
        customerPhoneRepository.delete(phone);
    }

    @Override
    @Transactional(readOnly = true)
    public CustomerDashboardResponse getCustomerDashboard(Long customerId) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new CustomerNotFoundException(customerId));

        List<AddressResponse> addresses = addressRepository.findByCustomerId(customerId).stream()
                .map(AddressMapper::toResponse)
                .collect(Collectors.toList());

        long totalOrders = orderRepository.countByCustomerId(customerId);
        BigDecimal totalSpent = orderRepository.calculateCustomerTotalSpent(customerId);
        List<OrderResponse> recentOrders = orderRepository.findByCustomerIdOrderByOrderDateDesc(customerId).stream()
                .limit(5)
                .map(OrderMapper::toResponse)
                .collect(Collectors.toList());

        CustomerDashboardResponse dashboard = new CustomerDashboardResponse();
        dashboard.setCustomer(CustomerMapper.toResponse(customer));
        dashboard.setSavedAddresses(addresses);
        dashboard.setTotalOrders(totalOrders);
        dashboard.setTotalSpent(totalSpent);
        dashboard.setRecentOrders(recentOrders);
        return dashboard;
    }
}
