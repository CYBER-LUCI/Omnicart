package com.omnicart.service.impl;

import com.omnicart.dto.request.AddressRequest;
import com.omnicart.dto.response.AddressResponse;
import com.omnicart.entity.Address;
import com.omnicart.entity.AddressType;
import com.omnicart.entity.Customer;
import com.omnicart.exception.AddressNotFoundException;
import com.omnicart.exception.CustomerNotFoundException;
import com.omnicart.exception.ResourceNotFoundException;
import com.omnicart.mapper.AddressMapper;
import com.omnicart.repository.AddressRepository;
import com.omnicart.repository.AddressTypeRepository;
import com.omnicart.repository.CustomerRepository;
import com.omnicart.service.AddressService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AddressServiceImpl implements AddressService {

    private final AddressRepository addressRepository;
    private final AddressTypeRepository addressTypeRepository;
    private final CustomerRepository customerRepository;

    public AddressServiceImpl(AddressRepository addressRepository,
                              AddressTypeRepository addressTypeRepository,
                              CustomerRepository customerRepository) {
        this.addressRepository = addressRepository;
        this.addressTypeRepository = addressTypeRepository;
        this.customerRepository = customerRepository;
    }

    @Override
    @Transactional
    public AddressResponse addAddress(Long customerId, AddressRequest request) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new CustomerNotFoundException(customerId));

        int typeId = (request.getAddressTypeId() != null && request.getAddressTypeId() > 0) ? request.getAddressTypeId() : 1;
        AddressType addressType = addressTypeRepository.findById(typeId)
                .orElseGet(() -> addressTypeRepository.save(new AddressType(1, "Home")));

        Address address = new Address();
        address.setCustomer(customer);
        address.setAddressType(addressType);
        address.setHouseNumber(request.getHouseNumber());
        address.setStreet(request.getStreet());
        address.setCity(request.getCity());
        address.setPinCode(request.getPinCode());

        Address saved = addressRepository.save(address);
        return AddressMapper.toResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public List<AddressResponse> getCustomerAddresses(Long customerId) {
        if (!customerRepository.existsById(customerId)) {
            throw new CustomerNotFoundException(customerId);
        }
        return addressRepository.findByCustomerId(customerId).stream()
                .map(AddressMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public AddressResponse getAddressById(Long addressId) {
        Address address = addressRepository.findById(addressId)
                .orElseThrow(() -> new AddressNotFoundException(addressId));
        return AddressMapper.toResponse(address);
    }

    @Override
    @Transactional
    public AddressResponse updateAddress(Long addressId, AddressRequest request) {
        Address address = addressRepository.findById(addressId)
                .orElseThrow(() -> new AddressNotFoundException(addressId));

        AddressType addressType = addressTypeRepository.findById(request.getAddressTypeId())
                .orElseThrow(() -> new ResourceNotFoundException("Invalid AddressType ID: " + request.getAddressTypeId()));

        address.setAddressType(addressType);
        address.setHouseNumber(request.getHouseNumber());
        address.setStreet(request.getStreet());
        address.setCity(request.getCity());
        address.setPinCode(request.getPinCode());

        Address updated = addressRepository.save(address);
        return AddressMapper.toResponse(updated);
    }

    @Override
    @Transactional
    public void deleteAddress(Long addressId) {
        if (!addressRepository.existsById(addressId)) {
            throw new AddressNotFoundException(addressId);
        }
        addressRepository.deleteById(addressId);
    }
}
