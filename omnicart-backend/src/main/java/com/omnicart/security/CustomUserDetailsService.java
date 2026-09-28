package com.omnicart.security;

import com.omnicart.entity.Customer;
import com.omnicart.entity.Seller;
import com.omnicart.repository.CustomerRepository;
import com.omnicart.repository.SellerRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final CustomerRepository customerRepository;
    private final SellerRepository sellerRepository;
    private final PasswordEncoder passwordEncoder;

    public CustomUserDetailsService(CustomerRepository customerRepository, SellerRepository sellerRepository, PasswordEncoder passwordEncoder) {
        this.customerRepository = customerRepository;
        this.sellerRepository = sellerRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        // Check for customer
        Optional<Customer> customerOpt = customerRepository.findByEmail(email);
        if (customerOpt.isPresent()) {
            Customer c = customerOpt.get();
            // Default demo password hash: 'password'
            return new UserPrincipal(c.getId(), email, passwordEncoder.encode("password"), Role.CUSTOMER);
        }

        // Check for seller
        Optional<Seller> sellerOpt = sellerRepository.findByContactEmailIgnoreCase(email);
        if (sellerOpt.isPresent()) {
            Seller s = sellerOpt.get();
            return new UserPrincipal(s.getId(), email, passwordEncoder.encode("password"), Role.SELLER);
        }

        // Check for built-in admin
        if ("admin@omnicart.com".equalsIgnoreCase(email)) {
            return new UserPrincipal(0L, email, passwordEncoder.encode("admin123"), Role.ADMIN);
        }

        throw new UsernameNotFoundException("User not found with email: " + email);
    }
}
