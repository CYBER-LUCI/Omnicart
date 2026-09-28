package com.omnicart.repository;

import com.omnicart.entity.CustomerPhone;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CustomerPhoneRepository extends JpaRepository<CustomerPhone, Long> {
    List<CustomerPhone> findByCustomerId(Long customerId);
    List<CustomerPhone> findByPhoneNumber(String phoneNumber);
}
