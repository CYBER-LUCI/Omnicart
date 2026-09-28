package com.omnicart.exception;

public class CategoryNotFoundException extends ResourceNotFoundException {
    public CategoryNotFoundException(Long id) {
        super("Category not found with ID: " + id);
    }
}
