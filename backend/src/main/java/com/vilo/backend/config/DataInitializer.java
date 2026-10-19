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
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);

    private final UserRepository userRepository;
    private final com.vilo.backend.repository.SoundRepository soundRepository;
    private final com.vilo.backend.repository.HashtagRepository hashtagRepository;
    private final com.vilo.backend.repository.SearchHistoryRepository searchHistoryRepository;
    private final VideoRepository videoRepository;
    private final PasswordEncoder passwordEncoder;

    public DataInitializer(UserRepository userRepository,
                           com.vilo.backend.repository.SoundRepository soundRepository,
                           com.vilo.backend.repository.HashtagRepository hashtagRepository,
                           com.vilo.backend.repository.SearchHistoryRepository searchHistoryRepository,
                           VideoRepository videoRepository,
                           PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.soundRepository = soundRepository;
        this.hashtagRepository = hashtagRepository;
        this.searchHistoryRepository = searchHistoryRepository;
        this.videoRepository = videoRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        if (userRepository.count() < 20) {
            log.info("Database has fewer than 20 users. Seeding 20 real platform users...");

            User mongkol = getOrCreateUser("mongkol", "mongkol@vilo.app", "password123",
                    "Thoeung Sereymongkol", "Flutter & Spring Boot Engineer | Vilo Core Team",
                    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            User bunheng = getOrCreateUser("bunheng", "bunheng@vilo.app", "password123",
                    "Lim Bunheng", "Video Engine & Feed Specialist | Vilo Team",
                    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            User rithysak = getOrCreateUser("rithysak", "rithysak@vilo.app", "password123",
                    "Chhuon Rithysak", "Mobile UI/UX Developer & Orders Lead",
                    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            User kimliza = getOrCreateUser("kimliza", "kimliza@vilo.app", "password123",
                    "Kim Liza", "Social Stories & Real-Time Chat Specialist",
                    "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            getOrCreateUser("mono_t", "mono@vilo.app", "password123",
                    "Mono T", "Search, Sounds & Discovery Specialist",
                    "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            getOrCreateUser("admin", "admin@vilo.app", "admin123",
                    "Vilo System Admin", "System Administrator",
                    "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_ADMIN));

            User sophia = getOrCreateUser("sophia_art", "sophia@vilo.app", "password123",
                    "Sophia Vance", "Digital Artist & Visual Storyteller",
                    "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            getOrCreateUser("alex_dancer", "alex@vilo.app", "password123",
                    "Alex Rivers", "Choreographer & Movement Director",
                    "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=500&auto=format&fit=crop&q=80",
                    false, Set.of(Role.ROLE_USER));

            getOrCreateUser("linda_travel", "linda@vilo.app", "password123",
                    "Linda Chen", "Wanderlust | Visiting 40+ countries",
                    "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            User davi = getOrCreateUser("davi_beats", "davi@vilo.app", "password123",
                    "David Miller", "Lo-fi producer & sound designer",
                    "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            getOrCreateUser("sarah_fit", "sarah@vilo.app", "password123",
                    "Sarah Connor", "Daily HIIT & Mindful Wellness",
                    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80",
                    false, Set.of(Role.ROLE_USER));

            getOrCreateUser("michael_vlogs", "michael@vilo.app", "password123",
                    "Michael Scott", "Urban life & cinematic mini-docs",
                    "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=500&auto=format&fit=crop&q=80",
                    false, Set.of(Role.ROLE_USER));

            getOrCreateUser("emily_chef", "emily@vilo.app", "password123",
                    "Emily Watson", "Pastry arts & sourdough adventures",
                    "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            getOrCreateUser("johnny_skate", "johnny@vilo.app", "password123",
                    "Johnny Blaze", "Street skate clips & skatepark tours",
                    "https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=500&auto=format&fit=crop&q=80",
                    false, Set.of(Role.ROLE_USER));

            getOrCreateUser("cloe_design", "cloe@vilo.app", "password123",
                    "Chloe Martin", "Product Designer & 3D Blender enthusiast",
                    "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            getOrCreateUser("kevin_tech", "kevin@vilo.app", "password123",
                    "Kevin Zhang", "Next-gen tech breakdown & desk setups",
                    "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            getOrCreateUser("anna_photo", "anna@vilo.app", "password123",
                    "Anna Petrova", "Film portraits & street photography",
                    "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=500&auto=format&fit=crop&q=80",
                    false, Set.of(Role.ROLE_USER));

            getOrCreateUser("lucas_gaming", "lucas@vilo.app", "password123",
                    "Lucas Silva", "Speedrunner & competitive gamer",
                    "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=500&auto=format&fit=crop&q=80",
                    false, Set.of(Role.ROLE_USER));

            getOrCreateUser("maya_music", "maya@vilo.app", "password123",
                    "Maya Lin", "Acoustic guitar & indie songwriting",
                    "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            getOrCreateUser("ryan_explores", "ryan@vilo.app", "password123",
                    "Ryan Walker", "Wild camping & drone aerial shots",
                    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80",
                    false, Set.of(Role.ROLE_USER));

            // Set up initial follow relationships for mongkol:
            // 4 followers: bunheng, rithysak, kimliza, sophia
            ensureFollow(bunheng, mongkol);
            ensureFollow(rithysak, mongkol);
            ensureFollow(kimliza, mongkol);
            ensureFollow(sophia, mongkol);

            // 3 following: bunheng, sophia, davi
            ensureFollow(mongkol, bunheng);
            ensureFollow(mongkol, sophia);
            ensureFollow(mongkol, davi);

            log.info("20 Platform users seeded successfully with verified initial follow graphs!");
        }

        if (soundRepository.count() == 0) {
            log.info("Seeding popular audio tracks & sounds...");
            soundRepository.save(new com.vilo.backend.entity.Sound(
                    "Midnight City Pulse", "Neon Dreams",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
                    "https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&auto=format&fit=crop&q=80",
                    45, 1840000L, true));
            soundRepository.save(new com.vilo.backend.entity.Sound(
                    "Cyber Tokyo Bass Drop", "Akira Sound Lab",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
                    "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=500&auto=format&fit=crop&q=80",
                    30, 952000L, true));
            soundRepository.save(new com.vilo.backend.entity.Sound(
                    "Seven7 Team Anthem", "Seven7 Beats",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
                    "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80",
                    60, 820000L, true));
            soundRepository.save(new com.vilo.backend.entity.Sound(
                    "Phnom Penh Sunset Lo-Fi", "Khmer Lo-Fi Crew",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
                    "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=500&auto=format&fit=crop&q=80",
                    35, 542000L, true));
            soundRepository.save(new com.vilo.backend.entity.Sound(
                    "Liquid Glass Motion", "Design Beats",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3",
                    "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&auto=format&fit=crop&q=80",
                    25, 310000L, true));
            soundRepository.save(new com.vilo.backend.entity.Sound(
                    "Deep Focus Coding", "DevPulse",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3",
                    "https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=500&auto=format&fit=crop&q=80",
                    50, 295000L, false));
            soundRepository.save(new com.vilo.backend.entity.Sound(
                    "Retro 80s Synth Groove", "Vaporwave Boy",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3",
                    "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=80",
                    40, 180000L, false));
            soundRepository.save(new com.vilo.backend.entity.Sound(
                    "Angkor Sunrise Ambient", "Heritage Audio",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3",
                    "https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=500&auto=format&fit=crop&q=80",
                    55, 125000L, false));
            log.info("Sounds seeded successfully!");
        }

        if (hashtagRepository.count() == 0) {
            log.info("Seeding trending hashtags...");
            hashtagRepository.save(new com.vilo.backend.entity.Hashtag("viloapp", 3200000L, true));
            hashtagRepository.save(new com.vilo.backend.entity.Hashtag("flutterdev", 2100000L, true));
            hashtagRepository.save(new com.vilo.backend.entity.Hashtag("tokyocoding", 1500000L, true));
            hashtagRepository.save(new com.vilo.backend.entity.Hashtag("springsecurity", 980000L, true));
            hashtagRepository.save(new com.vilo.backend.entity.Hashtag("cambodiavibes", 850000L, true));
            hashtagRepository.save(new com.vilo.backend.entity.Hashtag("uiuxdesign", 620000L, false));
            hashtagRepository.save(new com.vilo.backend.entity.Hashtag("shortvideo", 450000L, false));
            log.info("Hashtags seeded successfully!");
        }

        if (searchHistoryRepository.count() == 0) {
            userRepository.findByUsername("mongkol").ifPresent(user -> {
                log.info("Seeding initial search history for user mongkol...");
                searchHistoryRepository.save(new com.vilo.backend.entity.SearchHistory(user, "seven7", "ALL"));
                searchHistoryRepository.save(new com.vilo.backend.entity.SearchHistory(user, "flutter ui", "ALL"));
                searchHistoryRepository.save(new com.vilo.backend.entity.SearchHistory(user, "tokyo cyberpunk", "ALL"));
                searchHistoryRepository.save(new com.vilo.backend.entity.SearchHistory(user, "neon aesthetic", "ALL"));
                log.info("Initial search history seeded!");
            });
        }

        // Clean up any legacy mock videos with inflated fake like counts (> 100)
        List<Video> legacyMockVideos = videoRepository.findAll().stream()
                .filter(v -> v.getLikeCount() != null && v.getLikeCount() > 100)
                .collect(Collectors.toList());
        if (!legacyMockVideos.isEmpty()) {
            log.info("Removing {} legacy mock videos with inflated like counts...", legacyMockVideos.size());
            videoRepository.deleteAll(legacyMockVideos);
            log.info("Legacy mock videos removed cleanly!");
        }
    }

    private User getOrCreateUser(String username, String email, String password,
                                 String displayName, String bio, String avatarUrl,
                                 boolean isVerified, Set<Role> roles) {
        return userRepository.findByUsername(username).orElseGet(() -> {
            User u = User.builder()
                    .username(username)
                    .email(email)
                    .password(passwordEncoder.encode(password))
                    .displayName(displayName)
                    .bio(bio)
                    .avatarUrl(avatarUrl)
                    .isVerified(isVerified)
                    .roles(roles)
                    .build();
            return userRepository.save(u);
        });
    }

    private void ensureFollow(User follower, User target) {
        if (follower == null || target == null || follower.getId().equals(target.getId())) {
            return;
        }
        User reloadedFollower = userRepository.findById(follower.getId()).orElse(follower);
        User reloadedTarget = userRepository.findById(target.getId()).orElse(target);

        boolean alreadyFollowed = reloadedTarget.getFollowers().stream()
                .anyMatch(f -> f.getId().equals(reloadedFollower.getId()));

        if (!alreadyFollowed) {
            reloadedTarget.getFollowers().add(reloadedFollower);
            reloadedFollower.getFollowing().add(reloadedTarget);
            userRepository.save(reloadedTarget);
            userRepository.save(reloadedFollower);
        }
    }
}
