package com.omnicart.dto.response;

public class ProductImageResponse {
    private Long id;
    private String imageUrl;
    private Integer displayOrder;
    private Boolean isPrimary;

    public ProductImageResponse() {}

    public ProductImageResponse(Long id, String imageUrl, Integer displayOrder, Boolean isPrimary) {
        this.id = id;
        this.imageUrl = imageUrl;
        this.displayOrder = displayOrder;
        this.isPrimary = isPrimary;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public Integer getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(Integer displayOrder) { this.displayOrder = displayOrder; }

    public Boolean getIsPrimary() { return isPrimary; }
    public void setIsPrimary(Boolean isPrimary) { this.isPrimary = isPrimary; }
}
