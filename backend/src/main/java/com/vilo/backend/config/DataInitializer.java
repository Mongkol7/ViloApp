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

        log.info("Checking and seeding creator videos for all real platform accounts...");
        seedVideoIfMissing("mongkol", "assets/videos/vid1.mp4", "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600",
                "Building modern reactive Flutter UI with Spring Boot #coding #flutterdev", "Seven7 Team Anthem - Seven7 Beats", 1250000L, 45200L, 120000L);
        seedVideoIfMissing("mongkol", "assets/videos/vid2.mp4", "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600",
                "Late night debug session with neon synthwave 🌃 #vilo #developer", "Neon Midnight Beats", 420000L, 15300L, 34000L);

        seedVideoIfMissing("bunheng", "assets/videos/vid2.mp4", "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600",
                "Night walk through the neon streets #citylife #neon #cyberpunk", "Cyberpunk Beats - Synthwave", 890000L, 12100L, 85000L);
        seedVideoIfMissing("bunheng", "assets/videos/vid3.mp4", "https://images.unsplash.com/photo-1518770660439-4636190af475?w=600",
                "60fps video engine rendering benchmarks 🚀 #tech #videoengine", "High FPS Pulse - Seven7", 310000L, 5400L, 21000L);

        seedVideoIfMissing("rithysak", "assets/videos/vid4.mp4", "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600",
                "Designing smooth micro-animations in Flutter 🎨 #ui #flutter #orders", "Smooth Motion Beats", 480000L, 9300L, 42000L);
        seedVideoIfMissing("rithysak", "assets/videos/vid1.mp4", "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600",
                "Weekend mountain ride on gravel trails 🚴 #nature #adventure", "Open Road Acoustic", 220000L, 3100L, 14000L);

        seedVideoIfMissing("kimliza", "assets/videos/vid3.mp4", "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600",
                "Coffee shop aesthetics & acoustic tunes ☕ #coffee #vibes #story", "Rainy Day Acoustic - LoFi", 640000L, 18200L, 53000L);
        seedVideoIfMissing("kimliza", "assets/videos/vid2.mp4", "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=600",
                "City lights after rainfall 🌧️ #aesthetic #mood #vilo", "After The Rain - Chillhop", 350000L, 7400L, 29000L);

        seedVideoIfMissing("mono_t", "assets/videos/vid1.mp4", "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600",
                "New sound wave drops this Friday! Stay tuned 🎧 #beats #producer #sounds", "Mono Wave Vol 1", 720000L, 19500L, 68000L);
        seedVideoIfMissing("mono_t", "assets/videos/vid4.mp4", "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600",
                "Analog modular synth jam session in the lab 🎛️ #synth #modular", "Analog Pulse - Mono T", 410000L, 8800L, 31000L);

        seedVideoIfMissing("admin", "assets/videos/vid2.mp4", "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=600",
                "Welcome to Vilo! Discover creators, sounds and trends worldwide ✨ #vilo #community", "Vilo Official Sound", 1500000L, 32000L, 180000L);

        seedVideoIfMissing("sophia_art", "assets/videos/vid1.mp4", "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600",
                "The view from the top is breathtaking ⛰️ #mountains #visuals #sunset", "Epic Mountain Theme - Hans Zimmer", 2100000L, 110000L, 400000L);
        seedVideoIfMissing("sophia_art", "assets/videos/vid3.mp4", "https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600",
                "Speed painting digital landscape on iPad Pro 🖌️ #art #illustration", "Cosmic Dreams - LoFi Art", 590000L, 14200L, 61000L);

        seedVideoIfMissing("alex_dancer", "assets/videos/vid4.mp4", "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=600",
                "New choreography routine rehearsal 🕺 #dance #freestyle #moves", "Urban Funk Remix - Alex R", 830000L, 21000L, 74000L);
        seedVideoIfMissing("alex_dancer", "assets/videos/vid2.mp4", "https://images.unsplash.com/photo-1547153760-18fc86324498?w=600",
                "Stage lighting & motion rehearsal in the studio 💡 #dancer #performer", "Stage Lights Beat", 380000L, 6900L, 28000L);

        seedVideoIfMissing("linda_travel", "assets/videos/vid2.mp4", "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=600",
                "Peaceful morning on the lake 🛶 #lake #peace #travel", "Morning Coffee Acoustic - Indie Band", 420000L, 5100L, 18000L);
        seedVideoIfMissing("linda_travel", "assets/videos/vid1.mp4", "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=600",
                "Secret beach sunset in Southeast Asia 🌅 #traveldiary #wanderlust", "Island Breeze - Chill", 910000L, 27500L, 95000L);

        seedVideoIfMissing("davi_beats", "assets/videos/vid3.mp4", "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600",
                "Found this hidden waterfall today! 🌿💧 #hiking #nature #beats", "Nature Sounds - Waterfall", 340000L, 3200L, 20000L);
        seedVideoIfMissing("davi_beats", "assets/videos/vid4.mp4", "https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=600",
                "Chopping vintage vinyl samples for the new EP 🎶 #lofi #boombap", "Vinyl Dust - Davi Beats", 520000L, 11400L, 46000L);

        seedVideoIfMissing("sarah_fit", "assets/videos/vid4.mp4", "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600",
                "Morning workout done! 💪 High intensity training #fitness #gym", "Workout Mix 2026 - DJ Flex", 550000L, 8400L, 15000L);
        seedVideoIfMissing("sarah_fit", "assets/videos/vid1.mp4", "https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600",
                "Outdoor trail sprint & stretch routine 🏃‍♀️ #wellness #health #cardio", "Endurance Boost - Pulse", 290000L, 4600L, 19000L);

        seedVideoIfMissing("michael_vlogs", "assets/videos/vid2.mp4", "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=600",
                "Exploring downtown neon alleys at 2 AM 🌆 #vlog #cinematic", "Midnight City Pulse", 440000L, 8900L, 37000L);
        seedVideoIfMissing("michael_vlogs", "assets/videos/vid3.mp4", "https://images.unsplash.com/photo-1485846234645-a62644f84728?w=600",
                "Behind the scenes shooting with anamorphic lens 🎥 #filmmaking #cinematography", "Cinema Tone - Ambient", 310000L, 5700L, 26000L);

        seedVideoIfMissing("emily_chef", "assets/videos/vid1.mp4", "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=600",
                "Fresh sourdough loaf straight from the oven 🥖 #baking #sourdough #crust", "Acoustic Bakery Morning", 670000L, 14300L, 58000L);
        seedVideoIfMissing("emily_chef", "assets/videos/vid3.mp4", "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600",
                "Matcha crepe cake assembly in 60 seconds 🍰 #pastry #dessert #foodie", "Sweet Kitchen Vibes", 480000L, 9800L, 41000L);

        seedVideoIfMissing("johnny_skate", "assets/videos/vid4.mp4", "https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=600",
                "Landing the switch heel after 40 attempts! 🛹 #skate #skateboarding #skatelife", "Punk Rock Skate Jam", 750000L, 16200L, 62000L);
        seedVideoIfMissing("johnny_skate", "assets/videos/vid2.mp4", "https://images.unsplash.com/photo-1520045892732-304bc3ac5d8e?w=600",
                "Evening skate session at Venice Beach park 🌴 #streetstyle #skater", "Sunset Coast Beats", 390000L, 7200L, 33000L);

        seedVideoIfMissing("cloe_design", "assets/videos/vid1.mp4", "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600",
                "3D procedural motion graphic rendered in Blender 💎 #cgi #3danimation #design", "Futuristic Synthetics", 530000L, 10800L, 47000L);
        seedVideoIfMissing("cloe_design", "assets/videos/vid3.mp4", "https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=600",
                "Minimalist packaging unboxing & tactile review 📦 #design #industrialdesign", "Clean Aesthetics - LoFi", 280000L, 4300L, 22000L);

        seedVideoIfMissing("kevin_tech", "assets/videos/vid3.mp4", "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=600",
                "Next-gen desk setup tour 🖥️ Minimal futuristic design #tech #desk", "Midnight City Pulse - Neon Dreams", 310000L, 4200L, 31000L);
        seedVideoIfMissing("kevin_tech", "assets/videos/vid4.mp4", "https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=600",
                "Mechanical keyboard build: linear switches + brass plate ⌨️ #keebs #satisfying", "ASMR Keeb Sound", 620000L, 13700L, 59000L);

        seedVideoIfMissing("anna_photo", "assets/videos/vid2.mp4", "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=600",
                "Developing 35mm film in darkroom under red light 🎞️ #analog #35mm #film", "Darkroom Ambient - Tape", 490000L, 8600L, 43000L);
        seedVideoIfMissing("anna_photo", "assets/videos/vid1.mp4", "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=600",
                "Golden hour portrait lighting tutorial with reflector 📸 #photography #tutorial", "Golden Hour Glow", 360000L, 6100L, 27000L);

        seedVideoIfMissing("lucas_gaming", "assets/videos/vid4.mp4", "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600",
                "Insane clutch round 1v4 in overtime! 🎮 #gaming #esports #clutch", "Hyperdrive Energy - Gaming EDM", 920000L, 29400L, 88000L);
        seedVideoIfMissing("lucas_gaming", "assets/videos/vid2.mp4", "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600",
                "Custom water-cooled PC rig reveal with RGB sync ⚡ #pcmasterrace #setup", "Cyber Rig Rave", 430000L, 7800L, 34000L);

        seedVideoIfMissing("maya_music", "assets/videos/vid1.mp4", "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600",
                "Acoustic fingerstyle cover of Midnight City 🎸 #acoustic #cover #guitar", "Midnight City - Maya Lin Acoustic", 580000L, 12600L, 51000L);
        seedVideoIfMissing("maya_music", "assets/videos/vid3.mp4", "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600",
                "Writing new lyrics by the riverbank ✍️ #songwriting #indiemusic", "River Whispers - Indie Folk", 330000L, 5200L, 24000L);

        seedVideoIfMissing("ryan_explores", "assets/videos/vid3.mp4", "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600",
                "Wild camping above the clouds in the misty mountains ⛺ #camping #wilderness", "Mountain Peak Solitude", 460000L, 7700L, 39000L);
        seedVideoIfMissing("ryan_explores", "assets/videos/vid1.mp4", "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600",
                "Drone tracking shot over pine canopy at sunrise 🌲 #drone #fpv #nature", "Sunrise Canopy - Cinematic", 680000L, 15100L, 57000L);

        log.info("Platform creator videos verified and seeded successfully!");
    }

    @SuppressWarnings("unused")
    private void seedVideoIfMissing(String username, String videoUrl, String thumbnailUrl,
                                     String caption, String musicTitle,
                                     Long likes, Long comments, Long saves) {
        userRepository.findByUsername(username).ifPresent(creator -> {
            List<Video> existing = videoRepository.findByCreatorOrderByCreatedAtDesc(creator);
            boolean alreadyHasThisVideo = existing.stream().anyMatch(v -> v.getVideoUrl().equals(videoUrl));
            if (!alreadyHasThisVideo) {
                videoRepository.save(new Video(
                        creator, videoUrl, thumbnailUrl, caption, musicTitle, 0L, 0L, 0L
                ));
            }
        });
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
