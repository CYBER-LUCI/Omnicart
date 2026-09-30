package com.omnicart.service;

import com.omnicart.dto.request.CustomerCreateRequest;
import com.omnicart.dto.request.CustomerUpdateRequest;
import com.omnicart.dto.request.EmailRequest;
import com.omnicart.dto.request.PhoneRequest;
import com.omnicart.dto.response.CustomerDashboardResponse;
import com.omnicart.dto.response.CustomerResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface CustomerService {
    CustomerResponse createCustomer(CustomerCreateRequest request);
    CustomerResponse getCustomerById(Long id);
    CustomerResponse updateCustomer(Long id, CustomerUpdateRequest request);
    void deleteCustomer(Long id);
    Page<CustomerResponse> getAllCustomers(Pageable pageable);
    CustomerResponse addEmail(Long customerId, EmailRequest request);
    java.util.List<com.omnicart.dto.response.CustomerEmailResponse> getCustomerEmails(Long customerId);
    void removeEmail(Long customerId, Long emailId);
    CustomerResponse addPhone(Long customerId, PhoneRequest request);
    java.util.List<com.omnicart.dto.response.CustomerPhoneResponse> getCustomerPhones(Long customerId);
    void removePhone(Long customerId, Long phoneId);
    CustomerDashboardResponse getCustomerDashboard(Long customerId);
}
