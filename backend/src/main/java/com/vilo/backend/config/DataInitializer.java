package com.vilo.backend.config;

import com.vilo.backend.entity.Category;
import com.vilo.backend.entity.Product;
import com.vilo.backend.entity.Role;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import com.vilo.backend.repository.CategoryRepository;
import com.vilo.backend.repository.ProductRepository;
import com.vilo.backend.repository.UserRepository;
import com.vilo.backend.repository.VideoRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);

    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final ProductRepository productRepository;
    private final com.vilo.backend.repository.SoundRepository soundRepository;
    private final com.vilo.backend.repository.HashtagRepository hashtagRepository;
    private final com.vilo.backend.repository.SearchHistoryRepository searchHistoryRepository;
    private final VideoRepository videoRepository;
    private final PasswordEncoder passwordEncoder;

    public DataInitializer(UserRepository userRepository,
                           CategoryRepository categoryRepository,
                           ProductRepository productRepository,
                           com.vilo.backend.repository.SoundRepository soundRepository,
                           com.vilo.backend.repository.HashtagRepository hashtagRepository,
                           com.vilo.backend.repository.SearchHistoryRepository searchHistoryRepository,
                           VideoRepository videoRepository,
                           PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.categoryRepository = categoryRepository;
        this.productRepository = productRepository;
        this.soundRepository = soundRepository;
        this.hashtagRepository = hashtagRepository;
        this.searchHistoryRepository = searchHistoryRepository;
        this.videoRepository = videoRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        log.info("Checking and updating platform users and team creators...");

        // Migrate legacy usernames if present
        userRepository.findByUsername("mono_t").ifPresent(oldUser -> {
            oldUser.setUsername("trenmono");
            oldUser.setDisplayName("Tren Mono");
            oldUser.setEmail("trenmono@vilo.app");
            userRepository.save(oldUser);
        });
        userRepository.findByUsername("kimliza").ifPresent(oldUser -> {
            oldUser.setUsername("setkimliza");
            oldUser.setDisplayName("Set Kimliza");
            oldUser.setEmail("setkimliza@vilo.app");
            userRepository.save(oldUser);
        });
        userRepository.findByUsername("rithysak").ifPresent(user -> {
            user.setDisplayName("Sok Rithysak");
            userRepository.save(user);
        });

        User mongkol = getOrCreateUser("mongkol", "mongkol@vilo.app", "password123",
                "Thoeung Sereymongkol", "Flutter & Spring Boot Engineer | Vilo Core Team",
                "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        User bunheng = getOrCreateUser("bunheng", "bunheng@vilo.app", "password123",
                "Lim Bunheng", "Video Engine & Feed Specialist | Vilo Team",
                "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        User rithysak = getOrCreateUser("rithysak", "rithysak@vilo.app", "password123",
                "Sok Rithysak", "Mobile UI/UX Developer & Orders Lead",
                "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        User setkimliza = getOrCreateUser("setkimliza", "setkimliza@vilo.app", "password123",
                "Set Kimliza", "Social Stories & Real-Time Chat Specialist",
                "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        User trenmono = getOrCreateUser("trenmono", "trenmono@vilo.app", "password123",
                "Tren Mono", "Search, Sounds & Discovery Specialist",
                "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        User tryphien = getOrCreateUser("tryphien", "tryphien@vilo.app", "password123",
                "Try Phien", "Creative Media & Visual Direction | Vilo Team",
                "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        User nenseanghai = getOrCreateUser("nenseanghai", "nenseanghai@vilo.app", "password123",
                "Nen Seanghai", "Full-Stack Engineer & Interactive Design",
                "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        getOrCreateUser("admin", "admin@vilo.app", "admin123",
                "Vilo System Admin", "System Administrator",
                "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_ADMIN));

        User sophia = getOrCreateUser("sophia_art", "sophia@vilo.app", "password123",
                "Sophia Vance", "Digital Artist & Visual Storyteller",
                "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        User alexDancer = getOrCreateUser("alex_dancer", "alex@vilo.app", "password123",
                "Alex Rivers", "Choreographer & Movement Director",
                "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=500&auto=format&fit=crop&q=80",
                false, Set.of(Role.ROLE_USER));

        User lindaTravel = getOrCreateUser("linda_travel", "linda@vilo.app", "password123",
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

        User emilyChef = getOrCreateUser("emily_chef", "emily@vilo.app", "password123",
                "Emily Watson", "Pastry arts & sourdough adventures",
                "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        getOrCreateUser("johnny_skate", "johnny@vilo.app", "password123",
                "Johnny Blaze", "Street skate clips & skatepark tours",
                "https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=500&auto=format&fit=crop&q=80",
                false, Set.of(Role.ROLE_USER));

        User cloeDesign = getOrCreateUser("cloe_design", "cloe@vilo.app", "password123",
                "Chloe Martin", "Product Designer & 3D Blender enthusiast",
                "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        User kevinTech = getOrCreateUser("kevin_tech", "kevin@vilo.app", "password123",
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

        User mayaMusic = getOrCreateUser("maya_music", "maya@vilo.app", "password123",
                "Maya Lin", "Acoustic guitar & indie songwriting",
                "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        getOrCreateUser("ryan_explores", "ryan@vilo.app", "password123",
                "Ryan Walker", "Wild camping & drone aerial shots",
                "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80",
                false, Set.of(Role.ROLE_USER));

        // Set up team follow graph
        ensureFollow(bunheng, mongkol);
        ensureFollow(rithysak, mongkol);
        ensureFollow(setkimliza, mongkol);
        ensureFollow(trenmono, mongkol);
        ensureFollow(tryphien, mongkol);
        ensureFollow(nenseanghai, mongkol);
        ensureFollow(sophia, mongkol);

        ensureFollow(mongkol, bunheng);
        ensureFollow(mongkol, rithysak);
        ensureFollow(mongkol, setkimliza);
        ensureFollow(mongkol, trenmono);
        ensureFollow(mongkol, tryphien);
        ensureFollow(mongkol, nenseanghai);
        ensureFollow(mongkol, sophia);
        ensureFollow(mongkol, davi);

        log.info("Platform users and creator team verified successfully!");

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

        // Seed fresh distinct videos from assets/videos/ for each of the 7 creator accounts
        log.info("Checking and seeding fresh creator videos from assets/videos/...");

        seedFreshVideo(mongkol, "assets/videos/vid1.mp4", "assets/video_thumbnails/vid1.jpg",
                "Building responsive Flutter UI with Spring Boot 🚀 #coding #flutterdev #vilo", "Original Sound - Thoeung Sereymongkol");
        seedFreshVideo(mongkol, "assets/videos/vid2.mp4", "assets/video_thumbnails/vid2.jpg",
                "Late night coding session & neon vibes 🌃 #developer #tech #viloapp", "Midnight City Pulse - Neon Dreams");

        seedFreshVideo(rithysak, "assets/videos/vid3.mp4", "assets/video_thumbnails/vid3.jpg",
                "Designing smooth micro-animations in Flutter 🎨 #ui #flutter #animation", "Smooth Motion Beats - Seven7");
        seedFreshVideo(rithysak, "assets/videos/vid4.mp4", "assets/video_thumbnails/vid4.jpg",
                "Weekend mountain trail ride 🚴 #nature #adventure #outdoor", "Open Road Acoustic");

        seedFreshVideo(setkimliza, "assets/videos/vid5.mp4", "assets/video_thumbnails/vid5.jpg",
                "Coffee shop morning aesthetics & Lo-Fi ☕ #coffee #vibes #morning", "Rainy Day Acoustic - LoFi");
        seedFreshVideo(setkimliza, "assets/videos/vid6.mp4", "assets/video_thumbnails/vid6.jpg",
                "Golden hour city stroll after rain 🌧️✨ #aesthetic #mood #vilo", "After The Rain - Chillhop");

        seedFreshVideo(trenmono, "assets/videos/vid7.mp4", "assets/video_thumbnails/vid7.jpg",
                "Analog modular synth jam session in the lab 🎛️ #synth #modular #beats", "Analog Pulse - Tren Mono");
        seedFreshVideo(trenmono, "assets/videos/vid8.mp4", "assets/video_thumbnails/vid8.jpg",
                "Minimalist architecture walk in the city 🏢 #architecture #design #minimalism", "Mono Wave Vol 1");

        seedFreshVideo(bunheng, "assets/videos/vid9.mp4", "assets/video_thumbnails/vid9.jpg",
                "60fps video engine rendering benchmarks 🚀 #tech #videoengine #performance", "High FPS Pulse - Seven7");
        seedFreshVideo(bunheng, "assets/videos/vid10.mp4", "assets/video_thumbnails/vid10.jpg",
                "Cyberpunk neon street walk at night #citylife #neon #cyberpunk", "Cyberpunk Beats - Synthwave");

        seedFreshVideo(tryphien, "assets/videos/vid11.mp4", "assets/video_thumbnails/vid11.jpg",
                "Next-gen creative setup tour 🖥️ Minimal aesthetic #creativesetup #tech", "Creative Waves - LoFi");
        seedFreshVideo(tryphien, "assets/videos/vid12.mp4", "assets/video_thumbnails/vid12.jpg",
                "Exploring neon night streets & cinematic moments 🌆 #cinematic #night #vilo", "Night Drive - Ambient");

        seedFreshVideo(nenseanghai, "assets/videos/vid13.mp4", "assets/video_thumbnails/vid13.jpg",
                "Designing clean responsive layouts & mobile interactions 📱 #flutterdev #uiux", "Motion Design Beats");
        seedFreshVideo(nenseanghai, "assets/videos/vid14.mp4", "assets/video_thumbnails/vid14.jpg",
                "Sunset vibes by the river with acoustic melodies 🌅🎸 #sunset #acoustic #chill", "Sunset Glow - Acoustic");

        // Add the remaining local videos to accounts Mongkol does not follow.
        seedFreshVideo(lindaTravel, "assets/videos/vid15.mp4", "assets/video_thumbnails/vid15.jpg",
                "Finding quiet places off the beaten path #travel #wanderlust #vilo", "Open Road Acoustic");
        seedFreshVideo(emilyChef, "assets/videos/vid16.mp4", "assets/video_thumbnails/vid16.jpg",
                "A warm pastry morning from kitchen to table #baking #foodie #morning", "Rainy Day Acoustic - LoFi");
        seedFreshVideo(cloeDesign, "assets/videos/vid17.mp4", "assets/video_thumbnails/vid17.jpg",
                "Turning a rough idea into a polished 3D concept #design #blender #creative", "Liquid Glass Motion - Design Beats");
        seedFreshVideo(kevinTech, "assets/videos/vid18.mp4", "assets/video_thumbnails/vid18.jpg",
                "Desk setup details that make deep work feel better #tech #setup #productivity", "Deep Focus Coding - DevPulse");
        seedFreshVideo(mayaMusic, "assets/videos/vid19.mp4", "assets/video_thumbnails/vid19.jpg",
                "An acoustic loop for a slow afternoon #music #acoustic #songwriting", "Seven7 Team Anthem - Seven7 Beats");
        seedFreshVideo(alexDancer, "assets/videos/vid20.mp4", "assets/video_thumbnails/vid20.jpg",
                "Movement practice under city lights #dance #movement #performance", "Retro 80s Synth Groove - Vaporwave Boy");

        log.info("Fresh creator videos verified and seeded for all local video assets!");
        ensureSeededMusicFiles();
        seedEcommerceCatalog();
    }

    private void seedFreshVideo(User creator, String videoUrl, String thumbnailUrl, String caption, String musicTitle) {
        if (creator == null) return;
        List<Video> existing = videoRepository.findByCreatorOrderByCreatedAtDesc(creator);
        for (Video existingVideo : existing) {
            if (videoUrl.equals(existingVideo.getVideoUrl())) {
                if (!thumbnailUrl.equals(existingVideo.getThumbnailUrl())) {
                    existingVideo.setThumbnailUrl(thumbnailUrl);
                    videoRepository.save(existingVideo);
                }
                return;
            }
        }

        Video video = new Video(creator, videoUrl, thumbnailUrl, caption, musicTitle, 0L, 0L, 0L);
        if (caption != null) {
            java.util.regex.Matcher matcher = java.util.regex.Pattern.compile("#([a-zA-Z0-9_]+)").matcher(caption);
            while (matcher.find()) {
                String cleanTag = matcher.group(1).toLowerCase();
                video.getTags().add(new com.vilo.backend.entity.VideoTag(video, cleanTag));
            }
        }
        videoRepository.save(video);
    }

    private User getOrCreateUser(String username, String email, String password,
                                 String displayName, String bio, String avatarUrl,
                                 boolean isVerified, Set<Role> roles) {
        return userRepository.findByUsername(username)
                .map(existing -> {
                    boolean changed = false;
                    // Only populate initial fields if currently empty. NEVER overwrite user edits!
                    if ((existing.getDisplayName() == null || existing.getDisplayName().isBlank()) && displayName != null) {
                        existing.setDisplayName(displayName);
                        changed = true;
                    }
                    if ((existing.getBio() == null || existing.getBio().isBlank()) && bio != null) {
                        existing.setBio(bio);
                        changed = true;
                    }
                    if ((existing.getAvatarUrl() == null || existing.getAvatarUrl().isBlank()) && avatarUrl != null) {
                        existing.setAvatarUrl(avatarUrl);
                        changed = true;
                    }
                    if ((existing.getEmail() == null || existing.getEmail().isBlank()) && email != null) {
                        existing.setEmail(email);
                        changed = true;
                    }
                    if (existing.getRoles() == null || existing.getRoles().isEmpty()) {
                        existing.setRoles(roles);
                        changed = true;
                    }
                    return changed ? userRepository.save(existing) : existing;
                })
                .orElseGet(() -> {
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

    private void ensureSeededMusicFiles() {
        String[] musicFiles = {"phnom_penh_sunset.mp3", "seven7_anthem.mp3", "obsidian_pulse.mp3"};
        Path[] roots = {
                Paths.get("uploads").toAbsolutePath().normalize(),
                Paths.get("backend", "uploads").toAbsolutePath().normalize()
        };

        Path sourceFile = null;
        for (Path root : roots) {
            Path candidate = root.resolve("videos").resolve("video1.mp4");
            if (Files.exists(candidate)) {
                sourceFile = candidate;
                break;
            }
        }

        if (sourceFile != null) {
            for (Path root : roots) {
                Path musicDir = root.resolve("music");
                try {
                    Files.createDirectories(musicDir);
                    for (String mf : musicFiles) {
                        Path target = musicDir.resolve(mf);
                        if (!Files.exists(target) || Files.size(target) == 0) {
                            Files.copy(sourceFile, target, StandardCopyOption.REPLACE_EXISTING);
                            log.info("Ensured playable seeded audio file at: {}", target);
                        }
                    }
                } catch (Exception e) {
                    log.warn("Notice ensuring seeded music file in {}: {}", musicDir, e.getMessage());
                }
            }
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

            // Top Sellers matching Screenshot
            Product ts1 = Product.builder()
                    .title("Electric Smart Rice Cooker & Steamer")
                    .description("Smart fuzzy logic multi-cooker with non-stick ceramic inner pot.")
                    .price(new BigDecimal("1.01"))
                    .originalPrice(new BigDecimal("101.00"))
                    .stock(50)
                    .rating(4.9)
                    .reviewCount(890)
                    .salesCount(12000)
                    .category(accessories)
                    .seller(seller)
                    .images(List.of("https://images.unsplash.com/photo-1544233726-9f1d2b27be8b?w=800&auto=format&fit=crop&q=80"))
                    .build();

            Product ts2 = Product.builder()
                    .title("Ultra Slim Aluminum Power Bank 20000mAh")
                    .description("Fast charging 65W PD portable power bank with dual USB-C ports.")
                    .price(new BigDecimal("0.01"))
                    .originalPrice(new BigDecimal("49.99"))
                    .stock(300)
                    .rating(4.8)
                    .reviewCount(540)
                    .salesCount(9500)
                    .category(tech)
                    .seller(seller)
                    .images(List.of("https://images.unsplash.com/photo-1609592424109-dd9892f1b177?w=800&auto=format&fit=crop&q=80"))
                    .build();

            Product ts3 = Product.builder()
                    .title("Mechanical Compact Keyboard White Minimalist")
                    .description("Hot-swappable linear switches, doubleshot keycaps, and RGB backlighting.")
                    .price(new BigDecimal("0.01"))
                    .originalPrice(new BigDecimal("69.99"))
                    .stock(120)
                    .rating(4.9)
                    .reviewCount(670)
                    .salesCount(7800)
                    .category(gaming)
                    .seller(seller)
                    .images(List.of("https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800&auto=format&fit=crop&q=80"))
                    .build();

            Product ts4 = Product.builder()
                    .title("Titanium Flagship Smartphone Pro Max Bundle")
                    .description("Flagship mobile device with periscope zoom lens and original retail packaging.")
                    .price(new BigDecimal("0.01"))
                    .originalPrice(new BigDecimal("999.00"))
                    .stock(40)
                    .rating(5.0)
                    .reviewCount(1120)
                    .salesCount(5400)
                    .category(tech)
                    .seller(seller)
                    .images(List.of("https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=800&auto=format&fit=crop&q=80"))
                    .build();

            // Storefront Feed Products matching Screenshot
            Product f1 = Product.builder()
                    .title("iPhone 17 Pro Max Case & Titanium Armor")
                    .description("Super Retina XDR OLED display, A18 Pro chip, and aerospace-grade titanium frame.")
                    .price(new BigDecimal("124.50"))
                    .originalPrice(new BigDecimal("299.00"))
                    .stock(75)
                    .rating(4.8)
                    .reviewCount(420)
                    .salesCount(1400)
                    .category(tech)
                    .seller(seller)
                    .images(List.of("https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=800&auto=format&fit=crop&q=80"))
                    .build();

            Product f2 = Product.builder()
                    .title("V-Watch Ultra Rugged Titanium Smartwatch")
                    .description("Dual-frequency GPS, 100m water resistance, ECG sensor, and ultra-bright 3000 nit display.")
                    .price(new BigDecimal("89.90"))
                    .originalPrice(new BigDecimal("149.00"))
                    .stock(180)
                    .rating(4.9)
                    .reviewCount(960)
                    .salesCount(4200)
                    .category(tech)
                    .seller(seller)
                    .images(List.of("https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&auto=format&fit=crop&q=80"))
                    .build();

            Product f3 = Product.builder()
                    .title("Midnight Hydration Serum with Pure Hyaluronic Acid")
                    .description("Deep multi-depth hydration barrier repair serum with botanical extracts and niacinamide.")
                    .price(new BigDecimal("42.00"))
                    .originalPrice(new BigDecimal("85.00"))
                    .stock(500)
                    .rating(4.7)
                    .reviewCount(3400)
                    .salesCount(12000)
                    .category(beauty)
                    .seller(seller)
                    .images(List.of("https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=800&auto=format&fit=crop&q=80"))
                    .build();

            Product f4 = Product.builder()
                    .title("V-Series Wireless Headphones Active Noise Cancelling")
                    .description("Flagship over-ear headphones with custom acoustic drivers, 45-hour battery, and ANC.")
                    .price(new BigDecimal("215.00"))
                    .originalPrice(new BigDecimal("369.00"))
                    .stock(90)
                    .rating(5.0)
                    .reviewCount(310)
                    .salesCount(850)
                    .category(tech)
                    .seller(seller)
                    .images(List.of("https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&auto=format&fit=crop&q=80"))
                    .build();

            productRepository.saveAll(List.of(p1, p2, p3, p4, p5, p6, p7, p8, ts1, ts2, ts3, ts4, f1, f2, f3, f4));
            log.info("E-Commerce seed catalog created with 6 categories and 16 products matching mobile storefront!");
        }
    }
}
