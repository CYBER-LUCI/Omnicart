package com.omnicart.exception;

public class AddressNotFoundException extends ResourceNotFoundException {
    public AddressNotFoundException(Long id) {
        super("Address not found with ID: " + id);
    }
}
