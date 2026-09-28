package com.omnicart.repository;

import com.omnicart.entity.AddressType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AddressTypeRepository extends JpaRepository<AddressType, Integer> {
    Optional<AddressType> findByTypeNameIgnoreCase(String typeName);
}
