package com.omnicart.exception;

public class DuplicateGSTINException extends RuntimeException {
    public DuplicateGSTINException(String gstin) {
        super("GSTIN already registered: " + gstin);
    }
}
