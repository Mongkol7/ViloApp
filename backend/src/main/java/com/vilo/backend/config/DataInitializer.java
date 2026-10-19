package com.vilo.backend.config;

import com.vilo.backend.entity.Category;
import com.vilo.backend.entity.Product;
import com.vilo.backend.entity.Role;
import com.vilo.backend.entity.User;
import com.vilo.backend.repository.CategoryRepository;
import com.vilo.backend.repository.ProductRepository;
import com.vilo.backend.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;

@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);

    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final ProductRepository productRepository;
    private final PasswordEncoder passwordEncoder;

    public DataInitializer(UserRepository userRepository,
                           CategoryRepository categoryRepository,
                           ProductRepository productRepository,
                           PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.categoryRepository = categoryRepository;
        this.productRepository = productRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        seedUsers();
        seedEcommerceCatalog();
    }

    private void seedUsers() {
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

            User rithysak = User.builder()
                    .username("rithysak")
                    .email("rithysak@vilo.app")
                    .password(passwordEncoder.encode("password123"))
                    .displayName("Sok Rithysak")
                    .bio("E-Commerce & Orders Architect | Vilo Team")
                    .avatarUrl("https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&auto=format&fit=crop&q=80")
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

            userRepository.saveAll(List.of(mongkol, bunheng, rithysak, admin));
            log.info("Default seed users created: mongkol, bunheng, rithysak, admin");
        }
    }

    private void seedEcommerceCatalog() {
        if (categoryRepository.count() == 0) {
            log.info("Seeding E-Commerce Categories and Products for Sok Rithysak's module...");

            User seller = userRepository.findByUsername("rithysak")
                    .or(() -> userRepository.findByUsername("mongkol"))
                    .orElse(null);

            Category sneakers = Category.builder()
                    .name("Sneakers")
                    .slug("sneakers")
                    .iconUrl("https://images.unsplash.com/photo-1552346154-21d32810aba3?w=200")
                    .build();

            Category tech = Category.builder()
                    .name("Tech & Gadgets")
                    .slug("tech-gadgets")
                    .iconUrl("https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=200")
                    .build();

            Category fashion = Category.builder()
                    .name("Fashion & Apparel")
                    .slug("fashion")
                    .iconUrl("https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=200")
                    .build();

            Category gaming = Category.builder()
                    .name("Gaming & Setup")
                    .slug("gaming")
                    .iconUrl("https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=200")
                    .build();

            Category beauty = Category.builder()
                    .name("Beauty & Care")
                    .slug("beauty")
                    .iconUrl("https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=200")
                    .build();

            Category accessories = Category.builder()
                    .name("Accessories")
                    .slug("accessories")
                    .iconUrl("https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=200")
                    .build();

            categoryRepository.saveAll(List.of(sneakers, tech, fashion, gaming, beauty, accessories));

            // Products
            Product p1 = Product.builder()
                    .title("Nike Air Force 1 '07 Pro Edition")
                    .description("The radiance lives on with the Nike Air Force 1 '07. Premium leather, stitched overlays, and legendary Nike Air cushioning.")
                    .price(new BigDecimal("129.99"))
                    .originalPrice(new BigDecimal("189.99"))
                    .stock(150)
                    .rating(4.9)
                    .reviewCount(340)
                    .salesCount(1200)
                    .category(sneakers)
                    .seller(seller)
                    .images(List.of(
                            "https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800&auto=format&fit=crop&q=80",
                            "https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?w=800&auto=format&fit=crop&q=80"
                    ))
                    .videoIds(Set.of(1L, 2L))
                    .build();

            Product p2 = Product.builder()
                    .title("Apple AirPods Max - Space Gray")
                    .description("High-fidelity audio with Active Noise Cancellation, Transparency mode, and personalized spatial audio with dynamic head tracking.")
                    .price(new BigDecimal("549.00"))
                    .originalPrice(new BigDecimal("599.00"))
                    .stock(45)
                    .rating(4.8)
                    .reviewCount(180)
                    .salesCount(420)
                    .category(tech)
                    .seller(seller)
                    .images(List.of(
                            "https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=800&auto=format&fit=crop&q=80",
                            "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&auto=format&fit=crop&q=80"
                    ))
                    .videoIds(Set.of(1L, 3L))
                    .build();

            Product p3 = Product.builder()
                    .title("Cyberpunk RGB Mechanical Keyboard")
                    .description("Custom hot-swappable mechanical switches, PBT keycaps, gasket mount design, and vibrant per-key RGB backlighting.")
                    .price(new BigDecimal("149.50"))
                    .originalPrice(new BigDecimal("219.00"))
                    .stock(80)
                    .rating(4.9)
                    .reviewCount(512)
                    .salesCount(850)
                    .category(gaming)
                    .seller(seller)
                    .images(List.of(
                            "https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800&auto=format&fit=crop&q=80",
                            "https://images.unsplash.com/photo-1618384887929-16ec33fab9ef?w=800&auto=format&fit=crop&q=80"
                    ))
                    .videoIds(Set.of(2L))
                    .build();

            Product p4 = Product.builder()
                    .title("Vilo Oversized Heavyweight Streetwear Hoodie")
                    .description("450 GSM French Terry cotton hoodie with custom dropshoulder fit and embroidered minimalist typography on front and hood.")
                    .price(new BigDecimal("78.00"))
                    .originalPrice(new BigDecimal("110.00"))
                    .stock(200)
                    .rating(4.7)
                    .reviewCount(290)
                    .salesCount(640)
                    .category(fashion)
                    .seller(seller)
                    .images(List.of(
                            "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=800&auto=format&fit=crop&q=80",
                            "https://images.unsplash.com/photo-1509967419530-da38b4704bc6?w=800&auto=format&fit=crop&q=80"
                    ))
                    .videoIds(Set.of(3L, 4L))
                    .build();

            Product p5 = Product.builder()
                    .title("Minimalist Titanium Chronograph Watch")
                    .description("Sapphire crystal glass, Japanese quartz movement, 50m water resistance, and an interchangeable genuine Italian leather strap.")
                    .price(new BigDecimal("195.00"))
                    .originalPrice(new BigDecimal("280.00"))
                    .stock(60)
                    .rating(4.8)
                    .reviewCount(145)
                    .salesCount(310)
                    .category(accessories)
                    .seller(seller)
                    .images(List.of(
                            "https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=800&auto=format&fit=crop&q=80",
                            "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800&auto=format&fit=crop&q=80"
                    ))
                    .videoIds(Set.of(1L))
                    .build();

            Product p6 = Product.builder()
                    .title("Sony Alpha 7 IV Full-Frame Hybrid Camera")
                    .description("33MP full-frame Exmor R CMOS sensor, 4K 60p 10-bit recording, and next-generation real-time eye autofocus.")
                    .price(new BigDecimal("2399.00"))
                    .originalPrice(new BigDecimal("2699.00"))
                    .stock(20)
                    .rating(5.0)
                    .reviewCount(89)
                    .salesCount(115)
                    .category(tech)
                    .seller(seller)
                    .images(List.of(
                            "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80"
                    ))
                    .videoIds(Set.of(4L))
                    .build();

            Product p7 = Product.builder()
                    .title("Yeezy Boost 350 V2 'Onyx'")
                    .description("Re-engineered Primeknit upper, translucent monofilament side stripe, and responsive BOOST midsole cushioning.")
                    .price(new BigDecimal("230.00"))
                    .originalPrice(new BigDecimal("320.00"))
                    .stock(95)
                    .rating(4.9)
                    .reviewCount(620)
                    .salesCount(1540)
                    .category(sneakers)
                    .seller(seller)
                    .images(List.of(
                            "https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=800&auto=format&fit=crop&q=80"
                    ))
                    .videoIds(Set.of(2L, 4L))
                    .build();

            Product p8 = Product.builder()
                    .title("Wireless Noise-Cancelling Gaming Headset")
                    .description("Ultra-low latency 2.4GHz wireless connection, 50mm neodymium drivers, detachable broadcast-grade microphone, and 40h battery.")
                    .price(new BigDecimal("89.99"))
                    .originalPrice(new BigDecimal("139.99"))
                    .stock(110)
                    .rating(4.6)
                    .reviewCount(210)
                    .salesCount(580)
                    .category(gaming)
                    .seller(seller)
                    .images(List.of(
                            "https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=800&auto=format&fit=crop&q=80"
                    ))
                    .videoIds(Set.of(1L))
                    .build();

            productRepository.saveAll(List.of(p1, p2, p3, p4, p5, p6, p7, p8));
            log.info("E-Commerce seed catalog created with 6 categories and 8 premium products!");
        }
    }
}
