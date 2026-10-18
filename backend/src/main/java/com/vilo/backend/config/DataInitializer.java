package com.vilo.backend.config;

import com.vilo.backend.entity.Role;
import com.vilo.backend.entity.User;
import com.vilo.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.Set;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (userRepository.count() == 0) {
            log.info("Database is empty. Seeding initial team users...");

            User mongkol = User.builder()
                    .username("mongkol")
                    .email("mongkol@vilo.app")
                    .password(passwordEncoder.encode("password123"))
                    .displayName("Thoeung Sereymongkol")
                    .bio("Flutter & Spring Boot Engineer | Vilo Core Team")
                    .avatarUrl("https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80")
                    .isVerified(true)
                    .roles(Set.of(Role.ROLE_USER, Role.ROLE_CREATOR))
                    .build();

            User bunheng = User.builder()
                    .username("bunheng")
                    .email("bunheng@vilo.app")
                    .password(passwordEncoder.encode("password123"))
                    .displayName("Lim Bunheng")
                    .bio("Video Engine & Feed Specialist | Vilo Team")
                    .avatarUrl("https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80")
                    .isVerified(true)
                    .roles(Set.of(Role.ROLE_USER, Role.ROLE_CREATOR))
                    .build();

            User admin = User.builder()
                    .username("admin")
                    .email("admin@vilo.app")
                    .password(passwordEncoder.encode("admin123"))
                    .displayName("Vilo System Admin")
                    .bio("System Administrator")
                    .avatarUrl("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500&auto=format&fit=crop&q=80")
                    .isVerified(true)
                    .roles(Set.of(Role.ROLE_USER, Role.ROLE_ADMIN))
                    .build();

            userRepository.saveAll(java.util.List.of(mongkol, bunheng, admin));
            log.info("Default seed users created successfully: 'mongkol', 'bunheng', 'admin' (passwords: 'password123' / 'admin123')");
        }
    }
}
