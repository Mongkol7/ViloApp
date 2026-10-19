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
import java.util.List;
import java.util.Set;

@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);

    private final UserRepository userRepository;
    private final SoundRepository soundRepository;
    private final HashtagRepository hashtagRepository;
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
        User mongkol = null;
        User bunheng = null;
        User rithysak = null;
        User kimliza = null;
        User mono = null;
        User sophia = null;
        User davi = null;

        if (userRepository.count() < 20) {
            log.info("Database has fewer than 20 users. Seeding 20 real platform users...");

            mongkol = getOrCreateUser("mongkol", "mongkol@vilo.app", "password123",
                    "Thoeung Sereymongkol", "Flutter & Spring Boot Engineer | Vilo Core Team",
                    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            bunheng = getOrCreateUser("bunheng", "bunheng@vilo.app", "password123",
                    "Lim Bunheng", "Video Engine & Feed Specialist | Vilo Team",
                    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            rithysak = getOrCreateUser("rithysak", "rithysak@vilo.app", "password123",
                    "Chhuon Rithysak", "Mobile UI/UX Developer & Orders Lead",
                    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            kimliza = getOrCreateUser("kimliza", "kimliza@vilo.app", "password123",
                    "Set Kimliza", "Social Stories & Real-Time Chat Specialist",
                    "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            mono = getOrCreateUser("mono_t", "mono@vilo.app", "password123",
                    "Mono T", "Search, Sounds & Discovery Specialist",
                    "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_CREATOR));

            getOrCreateUser("admin", "admin@vilo.app", "admin123",
                    "Vilo System Admin", "System Administrator",
                    "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500&auto=format&fit=crop&q=80",
                    true, Set.of(Role.ROLE_USER, Role.ROLE_ADMIN));

            sophia = getOrCreateUser("sophia_art", "sophia@vilo.app", "password123",
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

            davi = getOrCreateUser("davi_beats", "davi@vilo.app", "password123",
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

            // Set up initial follow relationships:
            ensureFollow(bunheng, mongkol);
            ensureFollow(rithysak, mongkol);
            ensureFollow(kimliza, mongkol);
            ensureFollow(sophia, mongkol);

            ensureFollow(mongkol, bunheng);
            ensureFollow(mongkol, sophia);
            ensureFollow(mongkol, davi);

            ensureFollow(kimliza, mongkol);
            ensureFollow(kimliza, bunheng);
            ensureFollow(mongkol, kimliza);

            log.info("20 Platform users seeded successfully with verified initial follow graphs!");
        } else {
            mongkol = userRepository.findByUsername("mongkol").orElse(null);
            bunheng = userRepository.findByUsername("bunheng").orElse(null);
            kimliza = userRepository.findByUsername("kimliza").orElse(null);
        }

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
