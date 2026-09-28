package com.omnicart.repository;

import com.omnicart.entity.PriceLedgerSource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PriceLedgerSourceRepository extends JpaRepository<PriceLedgerSource, Integer> {
    Optional<PriceLedgerSource> findBySourceNameIgnoreCase(String sourceName);
}
