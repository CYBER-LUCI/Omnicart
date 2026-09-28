package com.omnicart.repository;

import com.omnicart.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {
    List<Category> findByParentCategoryIsNull();
    List<Category> findByParentCategoryId(Long parentId);
    boolean existsByCategoryNameIgnoreCaseAndParentCategory(String name, Category parentCategory);
}
