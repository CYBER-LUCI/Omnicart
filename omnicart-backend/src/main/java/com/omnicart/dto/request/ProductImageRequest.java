package com.omnicart.dto.request;

import jakarta.validation.constraints.NotBlank;

public class ProductImageRequest {
    @NotBlank(message = "Image URL is required")
    private String imageUrl;

    private Integer displayOrder = 1;
    private Boolean isPrimary = false;

    public ProductImageRequest() {}

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public Integer getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(Integer displayOrder) { this.displayOrder = displayOrder; }

    public Boolean getIsPrimary() { return isPrimary; }
    public void setIsPrimary(Boolean isPrimary) { this.isPrimary = isPrimary; }
}
