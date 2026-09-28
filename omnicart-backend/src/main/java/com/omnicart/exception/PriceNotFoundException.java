package com.omnicart.exception;

public class PriceNotFoundException extends ResourceNotFoundException {
    public PriceNotFoundException(Long productId) {
        super("No valid price found for product ID: " + productId);
    }
}
