package com.omnicart.mapper;

import com.omnicart.dto.response.CategoryResponse;
import com.omnicart.dto.response.CategoryTreeResponse;
import com.omnicart.entity.Category;

import java.util.stream.Collectors;

public class CategoryMapper {
    public static CategoryResponse toResponse(Category category) {
        if (category == null) return null;
        CategoryResponse res = new CategoryResponse();
        res.setId(category.getId());
        res.setCategoryName(category.getCategoryName());
        res.setLevel(category.getLevel());
        res.setCategoryDescription(category.getCategoryDescription());
        if (category.getParentCategory() != null) {
            res.setParentCategoryId(category.getParentCategory().getId());
            res.setParentCategoryName(category.getParentCategory().getCategoryName());
        }
        return res;
    }

    public static CategoryTreeResponse toTreeResponse(Category category) {
        if (category == null) return null;
        CategoryTreeResponse res = new CategoryTreeResponse();
        res.setId(category.getId());
        res.setCategoryName(category.getCategoryName());
        res.setLevel(category.getLevel());
        res.setCategoryDescription(category.getCategoryDescription());
        if (category.getSubCategories() != null) {
            res.setSubCategories(category.getSubCategories().stream()
                    .map(CategoryMapper::toTreeResponse)
                    .collect(Collectors.toList()));
        }
        return res;
    }
}
