package com.omnicart.service;

import com.omnicart.dto.request.AddressRequest;
import com.omnicart.dto.response.AddressResponse;

import java.util.List;

public interface AddressService {
    AddressResponse addAddress(Long customerId, AddressRequest request);
    List<AddressResponse> getCustomerAddresses(Long customerId);
    AddressResponse getAddressById(Long addressId);
    AddressResponse updateAddress(Long addressId, AddressRequest request);
    void deleteAddress(Long addressId);
}
