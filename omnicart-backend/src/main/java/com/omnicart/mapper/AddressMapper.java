package com.omnicart.mapper;

import com.omnicart.dto.response.AddressResponse;
import com.omnicart.entity.Address;

public class AddressMapper {
    public static AddressResponse toResponse(Address address) {
        if (address == null) return null;
        AddressResponse res = new AddressResponse();
        res.setId(address.getId());
        res.setCustomerId(address.getCustomer() != null ? address.getCustomer().getId() : null);
        res.setAddressType(address.getAddressType() != null ? address.getAddressType().getTypeName() : null);
        res.setHouseNumber(address.getHouseNumber());
        res.setStreet(address.getStreet());
        res.setCity(address.getCity());
        res.setPinCode(address.getPinCode());
        res.setCreatedAt(address.getCreatedAt());
        return res;
    }
}
