package com.omnicart.repository;

import com.omnicart.entity.CustomerEmail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerEmailRepository extends JpaRepository<CustomerEmail, Long> {
    Optional<CustomerEmail> findByEmailAddressIgnoreCase(String emailAddress);
    List<CustomerEmail> findByCustomerId(Long customerId);
    boolean existsByEmailAddressIgnoreCase(String emailAddress);
}
