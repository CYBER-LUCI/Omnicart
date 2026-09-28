package com.omnicart.repository;

import com.omnicart.entity.ShippingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ShippingStatusRepository extends JpaRepository<ShippingStatus, Integer> {
    Optional<ShippingStatus> findByStatusNameIgnoreCase(String statusName);
}
