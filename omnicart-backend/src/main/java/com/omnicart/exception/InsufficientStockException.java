package com.omnicart.exception;

public class InsufficientStockException extends RuntimeException {
    public InsufficientStockException(Long productId, int available, int requested) {
        super(String.format("Insufficient stock for product ID: %d. Available: %d, Requested: %d", productId, available, requested));
    }
    public InsufficientStockException(String message) {
        super(message);
    }
}
