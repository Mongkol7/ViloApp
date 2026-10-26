package com.vilo.backend.config;

import com.vilo.backend.entity.*;
import com.vilo.backend.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
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
    private final SoundRepository soundRepository;
    private final HashtagRepository hashtagRepository;
    private final SearchHistoryRepository searchHistoryRepository;
    private final VideoRepository videoRepository;
    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final ThoughtStoryRepository storyRepository;
    private final StoryViewRepository storyViewRepository;
    private final NotificationRepository notificationRepository;
    private final PasswordEncoder passwordEncoder;

    public DataInitializer(
            UserRepository userRepository,
            SoundRepository soundRepository,
            HashtagRepository hashtagRepository,
            SearchHistoryRepository searchHistoryRepository,
            VideoRepository videoRepository,
            ConversationRepository conversationRepository,
            MessageRepository messageRepository,
            ThoughtStoryRepository storyRepository,
            StoryViewRepository storyViewRepository,
            NotificationRepository notificationRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.soundRepository = soundRepository;
        this.hashtagRepository = hashtagRepository;
        this.searchHistoryRepository = searchHistoryRepository;
        this.videoRepository = videoRepository;
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
        this.storyRepository = storyRepository;
        this.storyViewRepository = storyViewRepository;
        this.notificationRepository = notificationRepository;
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

        User sak = getOrCreateUser("sak", "sak@vilo.app", "password123",
                "Sak", "Mobile UI Lead & Vilo Creator",
                "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

        User liza = getOrCreateUser("liza", "liza@vilo.app", "password123",
                "Liza", "Social Stories & Real-Time Chat Lead",
                "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80",
                true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

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
        User kimliza = setkimliza;

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

        User admin = getOrCreateUser("admin", "admin@vilo.app", "admin123",
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

        User s1 = getOrCreateUser("s1", "s1@vilo.app", "password123",
                "s1", "Vilo Creator & Peer Tester",
                "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500&auto=format&fit=crop&q=80",
                false, Set.of(Role.ROLE_USER));

        // Set up team follow graph
        ensureFollow(s1, setkimliza);
        ensureFollow(setkimliza, s1);
        ensureFollow(s1, mongkol);
        ensureFollow(mongkol, s1);
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

        ensureFollow(setkimliza, bunheng);
        ensureFollow(bunheng, setkimliza);
        ensureFollow(sak, mongkol);
        ensureFollow(mongkol, sak);
        ensureFollow(sak, setkimliza);
        ensureFollow(setkimliza, sak);
        ensureFollow(liza, mongkol);
        ensureFollow(mongkol, liza);
        ensureFollow(liza, setkimliza);
        ensureFollow(setkimliza, liza);

        ensureFollow(admin, setkimliza);
        ensureFollow(setkimliza, admin);
        ensureFollow(admin, bunheng);
        ensureFollow(bunheng, admin);
        ensureFollow(admin, sophia);
        ensureFollow(sophia, admin);
        ensureFollow(rithysak, admin);

        log.info("Platform users and creator team verified successfully!");

        if (soundRepository.count() == 0) {
            log.info("Seeding popular audio tracks & sounds...");
            soundRepository.save(new Sound(
                    "Midnight City Pulse", "Neon Dreams",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
                    "https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&auto=format&fit=crop&q=80",
                    45, 1840000L, true));
            soundRepository.save(new Sound(
                    "Cyber Tokyo Bass Drop", "Akira Sound Lab",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
                    "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=500&auto=format&fit=crop&q=80",
                    30, 952000L, true));
            soundRepository.save(new Sound(
                    "Seven7 Team Anthem", "Seven7 Beats",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
                    "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80",
                    60, 820000L, true));
            soundRepository.save(new Sound(
                    "Phnom Penh Sunset Lo-Fi", "Khmer Lo-Fi Crew",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
                    "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=500&auto=format&fit=crop&q=80",
                    35, 542000L, true));
            soundRepository.save(new Sound(
                    "Liquid Glass Motion", "Design Beats",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3",
                    "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&auto=format&fit=crop&q=80",
                    25, 310000L, true));
            soundRepository.save(new Sound(
                    "Deep Focus Coding", "DevPulse",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3",
                    "https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=500&auto=format&fit=crop&q=80",
                    50, 295000L, false));
            soundRepository.save(new Sound(
                    "Retro 80s Synth Groove", "Vaporwave Boy",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3",
                    "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=80",
                    40, 180000L, false));
            soundRepository.save(new Sound(
                    "Angkor Sunrise Ambient", "Heritage Audio",
                    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3",
                    "https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=500&auto=format&fit=crop&q=80",
                    55, 125000L, false));
            log.info("Sounds seeded successfully!");
        }

        if (hashtagRepository.count() == 0) {
            log.info("Seeding trending hashtags...");
            hashtagRepository.save(new Hashtag("viloapp", 3200000L, true));
            hashtagRepository.save(new Hashtag("flutterdev", 2100000L, true));
            hashtagRepository.save(new Hashtag("tokyocoding", 1500000L, true));
            hashtagRepository.save(new Hashtag("springsecurity", 980000L, true));
            hashtagRepository.save(new Hashtag("cambodiavibes", 850000L, true));
            hashtagRepository.save(new Hashtag("uiuxdesign", 620000L, false));
            hashtagRepository.save(new Hashtag("shortvideo", 450000L, false));
            log.info("Hashtags seeded successfully!");
        }

        if (storyRepository.count() == 0 && kimliza != null && bunheng != null && mongkol != null) {
            log.info("Seeding initial stories, chats, and notifications...");
            Instant now = Instant.now();

            // 1. Seed Active Thought Stories (24h)
            ThoughtStory storyKimliza = ThoughtStory.builder()
                    .user(kimliza)
                    .message("Building real-time WebSockets for Vilo! 🚀")
                    .musicTrackId("track-01")
                    .musicTitle("Midnight City Vibe")
                    .musicArtist("M83 Dream")
                    .musicAlbumArt("https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500&auto=format&fit=crop&q=80")
                    .musicDuration(30)
                    .backgroundGradient("sunset")
                    .viewCount(12)
                    .expiresAt(now.plus(Duration.ofHours(22)))
                    .build();

            ThoughtStory storyBunheng = ThoughtStory.builder()
                    .user(bunheng)
                    .message("Filming high FPS video feed content today 🎥")
                    .musicTrackId("track-02")
                    .musicTitle("Neon Cyberpunk Groove")
                    .musicArtist("SynthWave Echoes")
                    .musicAlbumArt("https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&auto=format&fit=crop&q=80")
                    .musicDuration(15)
                    .backgroundGradient("cyber")
                    .viewCount(28)
                    .expiresAt(now.plus(Duration.ofHours(18)))
                    .build();

            ThoughtStory storyMongkol = ThoughtStory.builder()
                    .user(mongkol)
                    .message("Spring Security 6 JWT stack is up and running 🛡️")
                    .musicTrackId("track-03")
                    .musicTitle("Lo-Fi Chill Beats")
                    .musicArtist("Coffee Studio")
                    .musicDuration(20)
                    .backgroundGradient("ocean")
                    .viewCount(45)
                    .expiresAt(now.plus(Duration.ofHours(20)))
                    .build();

            storyRepository.saveAll(List.of(storyKimliza, storyBunheng, storyMongkol));

            // Story Views
            storyViewRepository.save(StoryView.builder().story(storyKimliza).viewer(mongkol).build());
            storyViewRepository.save(StoryView.builder().story(storyKimliza).viewer(bunheng).build());
            storyViewRepository.save(StoryView.builder().story(storyBunheng).viewer(kimliza).build());

            // 2. Seed Conversations & Messages
            Conversation conv1 = Conversation.builder()
                    .participant1(mongkol.getId() < kimliza.getId() ? mongkol : kimliza)
                    .participant2(mongkol.getId() < kimliza.getId() ? kimliza : mongkol)
                    .lastMessageContent("Hey Liza! Is the STOMP endpoint ready for testing?")
                    .lastMessageSenderId(mongkol.getId())
                    .lastMessageTime(now.minusSeconds(120))
                    .build();
            conv1 = conversationRepository.save(conv1);

            Message msg1 = Message.builder()
                    .conversation(conv1)
                    .sender(kimliza)
                    .recipient(mongkol)
                    .content("Hi Mongkol, working on the real-time chat and stories right now!")
                    .isRead(true)
                    .build();

            Message msg2 = Message.builder()
                    .conversation(conv1)
                    .sender(mongkol)
                    .recipient(kimliza)
                    .content("Hey Liza! Is the STOMP endpoint ready for testing?")
                    .isRead(false)
                    .build();

            messageRepository.saveAll(List.of(msg1, msg2));

            Conversation conv2 = Conversation.builder()
                    .participant1(bunheng.getId() < kimliza.getId() ? bunheng : kimliza)
                    .participant2(bunheng.getId() < kimliza.getId() ? kimliza : bunheng)
                    .lastMessageContent("Love your new story with the background music!")
                    .lastMessageSenderId(bunheng.getId())
                    .lastMessageTime(now.minusSeconds(3600))
                    .build();
            conv2 = conversationRepository.save(conv2);

            Message msg3 = Message.builder()
                    .conversation(conv2)
                    .sender(bunheng)
                    .recipient(kimliza)
                    .content("Love your new story with the background music!")
                    .isRead(false)
                    .build();
            messageRepository.save(msg3);

            // 3. Seed Notifications
            Notification notif1 = Notification.builder()
                    .recipient(kimliza)
                    .actor(mongkol)
                    .type(NotificationType.LIKE)
                    .title("Liked your story")
                    .body("Thoeung Sereymongkol liked your 24h thought story")
                    .entityId(String.valueOf(storyKimliza.getId()))
                    .entityType("STORY")
                    .isRead(false)
                    .build();

            Notification notif2 = Notification.builder()
                    .recipient(kimliza)
                    .actor(bunheng)
                    .type(NotificationType.FOLLOW)
                    .title("New follower")
                    .body("Lim Bunheng started following you")
                    .entityId(String.valueOf(bunheng.getId()))
                    .entityType("USER")
                    .isRead(false)
                    .build();

            Notification notif3 = Notification.builder()
                    .recipient(kimliza)
                    .actor(null)
                    .type(NotificationType.SYSTEM)
                    .title("Welcome to Vilo!")
                    .body("Your real-time chat and story hub is now configured and active.")
                    .entityId("system")
                    .entityType("SYSTEM")
                    .isRead(true)
                    .build();

            Notification notif4 = Notification.builder()
                    .recipient(mongkol)
                    .actor(kimliza)
                    .type(NotificationType.COMMENT)
                    .title("New comment")
                    .body("Set Kimliza commented on your post: 'Awesome architecture!'")
                    .entityId("video-101")
                    .entityType("VIDEO")
                    .isRead(false)
                    .build();

            notificationRepository.saveAll(List.of(notif1, notif2, notif3, notif4));
            log.info("Default seed data created successfully for chat, stories, and notifications!");
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
}
