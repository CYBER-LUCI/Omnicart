package com.omnicart.service;

import com.omnicart.dto.request.CategoryRequest;
import com.omnicart.dto.response.CategoryResponse;
import com.omnicart.dto.response.CategoryTreeResponse;

import java.util.List;

public interface CategoryService {
    CategoryResponse createCategory(CategoryRequest request);
    CategoryResponse getCategoryById(Long id);
    CategoryResponse updateCategory(Long id, CategoryRequest request);
    void deleteCategory(Long id);
    List<CategoryResponse> getAllCategories();
    List<CategoryResponse> getSubCategories(Long parentId);
    List<CategoryTreeResponse> getCategoryTree();
}
