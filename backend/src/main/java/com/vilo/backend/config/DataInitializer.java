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
    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final ThoughtStoryRepository storyRepository;
    private final StoryViewRepository storyViewRepository;
    private final NotificationRepository notificationRepository;
    private final PasswordEncoder passwordEncoder;

    public DataInitializer(
            UserRepository userRepository,
            ConversationRepository conversationRepository,
            MessageRepository messageRepository,
            ThoughtStoryRepository storyRepository,
            StoryViewRepository storyViewRepository,
            NotificationRepository notificationRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
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
        if (userRepository.count() == 0) {
            log.info("Database is empty. Seeding initial team users, stories, chats, and notifications...");

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
                    .bio("E-Commerce & Orders Lead | Vilo Team")
                    .avatarUrl("https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80")
                    .isVerified(true)
                    .roles(Set.of(Role.ROLE_USER, Role.ROLE_CREATOR))
                    .build();

            User kimliza = User.builder()
                    .username("kimliza")
                    .email("kimliza@vilo.app")
                    .password(passwordEncoder.encode("password123"))
                    .displayName("Set Kimliza")
                    .bio("Real-Time Chat & Social Stories | Vilo Team")
                    .avatarUrl("https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80")
                    .isVerified(true)
                    .roles(Set.of(Role.ROLE_USER, Role.ROLE_CREATOR))
                    .build();

            User mono = User.builder()
                    .username("mono")
                    .email("mono@vilo.app")
                    .password(passwordEncoder.encode("password123"))
                    .displayName("Tren Mono")
                    .bio("Discovery, Sounds & DevOps | Vilo Team")
                    .avatarUrl("https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=500&auto=format&fit=crop&q=80")
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

            List<User> savedUsers = userRepository.saveAll(List.of(mongkol, bunheng, rithysak, kimliza, mono, admin));
            mongkol = savedUsers.get(0);
            bunheng = savedUsers.get(1);
            rithysak = savedUsers.get(2);
            kimliza = savedUsers.get(3);
            mono = savedUsers.get(4);

            // Follow relationships
            mongkol.getFollowing().add(kimliza);
            mongkol.getFollowing().add(bunheng);
            kimliza.getFollowing().add(mongkol);
            kimliza.getFollowing().add(bunheng);
            userRepository.saveAll(List.of(mongkol, kimliza));

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

            log.info("Default seed data created successfully for all team members (mongkol, bunheng, rithysak, kimliza, mono)!");
        }
    }
}
