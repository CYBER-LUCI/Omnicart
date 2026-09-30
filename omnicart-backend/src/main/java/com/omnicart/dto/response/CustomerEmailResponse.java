package com.omnicart.dto.response;

import java.time.LocalDateTime;

public class CustomerEmailResponse {
    private Long id;
    private Long customerId;
    private String emailAddress;
    private Boolean isPrimary;
    private LocalDateTime createdAt;

    public CustomerEmailResponse() {}

    public CustomerEmailResponse(Long id, Long customerId, String emailAddress, Boolean isPrimary, LocalDateTime createdAt) {
        this.id = id;
        this.customerId = customerId;
        this.emailAddress = emailAddress;
        this.isPrimary = isPrimary;
        this.createdAt = createdAt;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getCustomerId() { return customerId; }
    public void setCustomerId(Long customerId) { this.customerId = customerId; }

    public String getEmailAddress() { return emailAddress; }
    public void setEmailAddress(String emailAddress) { this.emailAddress = emailAddress; }

    public Boolean getIsPrimary() { return isPrimary; }
    public void setIsPrimary(Boolean isPrimary) { this.isPrimary = isPrimary; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
