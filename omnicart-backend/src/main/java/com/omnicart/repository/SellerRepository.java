package com.omnicart.repository;

import com.omnicart.entity.Seller;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SellerRepository extends JpaRepository<Seller, Long> {
    Optional<Seller> findByGstin(String gstin);
    Optional<Seller> findByContactEmailIgnoreCase(String contactEmail);
    boolean existsByGstin(String gstin);
    boolean existsByContactEmailIgnoreCase(String contactEmail);
}
