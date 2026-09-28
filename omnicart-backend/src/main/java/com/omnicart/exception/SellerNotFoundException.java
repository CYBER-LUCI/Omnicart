package com.omnicart.exception;

public class SellerNotFoundException extends ResourceNotFoundException {
    public SellerNotFoundException(Long id) {
        super("Seller not found with ID: " + id);
    }
}
