package com.omnicart.exception;

public class CustomerNotFoundException extends ResourceNotFoundException {
    public CustomerNotFoundException(Long id) {
        super("Customer not found with ID: " + id);
    }
    public CustomerNotFoundException(String message) {
        super(message);
    }
}
