package com.omnicart.dto.response;

import java.time.LocalDateTime;

public class CustomerPhoneResponse {
    private Long id;
    private Long customerId;
    private String phoneNumber;
    private Boolean isPrimary;
    private LocalDateTime createdAt;

    public CustomerPhoneResponse() {}

    public CustomerPhoneResponse(Long id, Long customerId, String phoneNumber, Boolean isPrimary, LocalDateTime createdAt) {
        this.id = id;
        this.customerId = customerId;
        this.phoneNumber = phoneNumber;
        this.isPrimary = isPrimary;
        this.createdAt = createdAt;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getCustomerId() { return customerId; }
    public void setCustomerId(Long customerId) { this.customerId = customerId; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public Boolean getIsPrimary() { return isPrimary; }
    public void setIsPrimary(Boolean isPrimary) { this.isPrimary = isPrimary; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
