package com.omnicart.repository;

import com.omnicart.entity.PriceLedger;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PriceLedgerRepository extends JpaRepository<PriceLedger, Long> {

    @Query("SELECT pl FROM PriceLedger pl WHERE pl.product.id = :productId ORDER BY pl.recordedAt DESC, pl.id DESC LIMIT 1")
    Optional<PriceLedger> findLatestByProductId(@Param("productId") Long productId);

    @Query("SELECT pl FROM PriceLedger pl WHERE pl.product.id = :productId ORDER BY pl.recordedAt DESC, pl.id DESC")
    List<PriceLedger> findAllByProductIdOrderByRecordedAtDesc(@Param("productId") Long productId);

    Page<PriceLedger> findByProductIdOrderByRecordedAtDesc(Long productId, Pageable pageable);

    @Query("SELECT pl FROM PriceLedger pl WHERE pl.product.id = :productId AND pl.recordedAt <= :timestamp ORDER BY pl.recordedAt DESC, pl.id DESC LIMIT 1")
    Optional<PriceLedger> findPriceAtTimestamp(@Param("productId") Long productId, @Param("timestamp") LocalDateTime timestamp);
}
