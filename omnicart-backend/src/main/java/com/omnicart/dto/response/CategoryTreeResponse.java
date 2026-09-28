package com.omnicart.dto.response;

import java.util.ArrayList;
import java.util.List;

public class CategoryTreeResponse {
    private Long id;
    private String categoryName;
    private Integer level;
    private String categoryDescription;
    private List<CategoryTreeResponse> subCategories = new ArrayList<>();

    public CategoryTreeResponse() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public Integer getLevel() { return level; }
    public void setLevel(Integer level) { this.level = level; }

    public String getCategoryDescription() { return categoryDescription; }
    public void setCategoryDescription(String categoryDescription) { this.categoryDescription = categoryDescription; }

    public List<CategoryTreeResponse> getSubCategories() { return subCategories; }
    public void setSubCategories(List<CategoryTreeResponse> subCategories) { this.subCategories = subCategories; }
}
