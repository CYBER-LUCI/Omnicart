package com.omnicart.mapper;

import com.omnicart.dto.response.CustomerResponse;
import com.omnicart.entity.Customer;
import com.omnicart.entity.CustomerEmail;
import com.omnicart.entity.CustomerPhone;

import java.util.stream.Collectors;

public class CustomerMapper {
    public static CustomerResponse toResponse(Customer customer) {
        if (customer == null) return null;
        CustomerResponse res = new CustomerResponse();
        res.setId(customer.getId());
        res.setFirstName(customer.getFirstName());
        res.setLastName(customer.getLastName());
        res.setCreatedAt(customer.getCreatedAt());
        if (customer.getEmails() != null) {
            res.setEmails(customer.getEmails().stream().map(CustomerEmail::getEmailAddress).collect(Collectors.toList()));
        }
        if (customer.getPhones() != null) {
            res.setPhones(customer.getPhones().stream().map(CustomerPhone::getPhoneNumber).collect(Collectors.toList()));
        }
        return res;
    }
}
