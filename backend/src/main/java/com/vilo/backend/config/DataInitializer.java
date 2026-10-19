package com.vilo.backend.config;

import com.vilo.backend.entity.Role;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import com.vilo.backend.repository.UserRepository;
import com.vilo.backend.repository.VideoRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;

@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final VideoRepository videoRepository;

    public DataInitializer(UserRepository userRepository,
                           PasswordEncoder passwordEncoder,
                           VideoRepository videoRepository) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.videoRepository = videoRepository;
    }

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

            userRepository.saveAll(List.of(mongkol, bunheng, admin));
            log.info("Default seed users created successfully: 'mongkol', 'bunheng', 'admin' (passwords: 'password123' / 'admin123')");
        }

        if (videoRepository.count() == 0) {
            log.info("Seeding sample feed videos...");

            Video v1 = new Video(
                1L, 
                "Exploring the stunning architecture of Phnom Penh! 🇰🇭✨ #travel #vilo", 
                "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4", 
                "https://images.unsplash.com/photo-1583491954714-a6da9249763e?w=800"
            );
            
            Video v2 = new Video(
                2L, 
                "Building a high-performance Flutter short-form video app with Spring Boot 3! #coding #flutter", 
                "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4", 
                "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800"
            );

            Video v3 = new Video(
                2L, 
                "spider glass", 
                "/uploads/videos/video1.mp4", 
                "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800"
            );

            videoRepository.save(v1);
            videoRepository.save(v2);
            videoRepository.save(v3);
            log.info("Initialized sample videos into PostgreSQL database.");
        }
    }
}
