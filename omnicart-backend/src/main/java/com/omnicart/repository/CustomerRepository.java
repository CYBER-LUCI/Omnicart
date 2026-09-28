package com.omnicart.repository;

import com.omnicart.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, Long> {
    
    @Query("SELECT c FROM Customer c JOIN c.emails e WHERE LOWER(e.emailAddress) = LOWER(:email)")
    Optional<Customer> findByEmail(@Param("email") String email);

    @Query("SELECT CASE WHEN COUNT(e) > 0 THEN true ELSE false END FROM CustomerEmail e WHERE LOWER(e.emailAddress) = LOWER(:email)")
    boolean existsByEmailAddress(@Param("email") String email);
}
