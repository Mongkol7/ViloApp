package com.vilo.backend.config;

import com.vilo.backend.entity.*;
import com.vilo.backend.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;

@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);

    private final UserRepository userRepository;
    private final VideoRepository videoRepository;
    private final SoundRepository soundRepository;
    private final VideoLikeRepository videoLikeRepository;
    private final VideoSaveRepository videoSaveRepository;
    private final PasswordEncoder passwordEncoder;
    private final JdbcTemplate jdbcTemplate;

    public DataInitializer(UserRepository userRepository,
                           VideoRepository videoRepository,
                           SoundRepository soundRepository,
                           VideoLikeRepository videoLikeRepository,
                           VideoSaveRepository videoSaveRepository,
                           PasswordEncoder passwordEncoder,
                           JdbcTemplate jdbcTemplate) {
        this.userRepository = userRepository;
        this.videoRepository = videoRepository;
        this.soundRepository = soundRepository;
        this.videoLikeRepository = videoLikeRepository;
        this.videoSaveRepository = videoSaveRepository;
        this.passwordEncoder = passwordEncoder;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    @Transactional
    public void run(String... args) {
        log.info("==================================================================");
        log.info("STEP 1: WIPING DATABASE IN FOREIGN-KEY-SAFE ORDER FOR FRESH START");
        log.info("==================================================================");

        try {
            jdbcTemplate.execute("DELETE FROM video_likes");
            jdbcTemplate.execute("DELETE FROM video_saves");
            jdbcTemplate.execute("DELETE FROM comments");
            jdbcTemplate.execute("DELETE FROM video_tags");
            jdbcTemplate.execute("DELETE FROM search_history");
            jdbcTemplate.execute("DELETE FROM videos");
            jdbcTemplate.execute("DELETE FROM sounds");
            jdbcTemplate.execute("DELETE FROM refresh_tokens");
            jdbcTemplate.execute("DELETE FROM followers_following");
            jdbcTemplate.execute("DELETE FROM user_roles");
            jdbcTemplate.execute("DELETE FROM users");
            jdbcTemplate.execute("DELETE FROM hashtags");
            log.info("All existing tables successfully wiped clean via native SQL in FK-safe order!");
        } catch (Exception e) {
            log.warn("Database wipe notice: {}", e.getMessage());
        }

        log.info("==================================================================");
        log.info("STEP 2: SEEDING 5 CORE USERS");
        log.info("==================================================================");

        String encodedPass = passwordEncoder.encode("password123");

        User mongkol = new User.Builder()
                .username("mongkol")
                .email("mongkol@vilo.app")
                .password(encodedPass)
                .displayName("Thoeung Sereymongkol")
                .bio("Flutter & Spring Boot Engineer | Vilo Core Team 🚀 Building in public")
                .avatarUrl("https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80")
                .isVerified(true)
                .roles(Set.of(Role.ROLE_USER, Role.ROLE_CREATOR))
                .build();
        mongkol = userRepository.save(mongkol);

        User bunheng = new User.Builder()
                .username("bunheng")
                .email("bunheng@vilo.app")
                .password(encodedPass)
                .displayName("Lim Bunheng")
                .bio("Video Engine & Feed Specialist | Vilo Team ⚡ 60fps Smooth")
                .avatarUrl("https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80")
                .isVerified(true)
                .roles(Set.of(Role.ROLE_USER, Role.ROLE_CREATOR))
                .build();
        bunheng = userRepository.save(bunheng);

        User rithysak = new User.Builder()
                .username("rithysak")
                .email("rithysak@vilo.app")
                .password(encodedPass)
                .displayName("Chhuon Rithysak")
                .bio("Mobile UI/UX Developer & Orders Lead 🎨 Crafting clean experiences")
                .avatarUrl("https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80")
                .isVerified(true)
                .roles(Set.of(Role.ROLE_USER, Role.ROLE_CREATOR))
                .build();
        rithysak = userRepository.save(rithysak);

        User kimliza = new User.Builder()
                .username("kimliza")
                .email("kimliza@vilo.app")
                .password(encodedPass)
                .displayName("Kim Liza")
                .bio("Social Stories & Real-Time Chat Specialist ☕ Chill vibes & music")
                .avatarUrl("https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80")
                .isVerified(true)
                .roles(Set.of(Role.ROLE_USER, Role.ROLE_CREATOR))
                .build();
        kimliza = userRepository.save(kimliza);

        User mono = new User.Builder()
                .username("mono")
                .email("mono@vilo.app")
                .password(encodedPass)
                .displayName("Mono T")
                .bio("Search, Sounds & Discovery Specialist 🎧 Next-gen audio algorithms")
                .avatarUrl("https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80")
                .isVerified(true)
                .roles(Set.of(Role.ROLE_USER, Role.ROLE_CREATOR))
                .build();
        mono = userRepository.save(mono);

        // Setup verified follow relationships:
        // mongkol is followed by bunheng, rithysak, kimliza
        bunheng.getFollowing().add(mongkol);
        rithysak.getFollowing().add(mongkol);
        kimliza.getFollowing().add(mongkol);
        // mongkol follows bunheng, rithysak
        mongkol.getFollowing().add(bunheng);
        mongkol.getFollowing().add(rithysak);

        userRepository.saveAll(List.of(mongkol, bunheng, rithysak, kimliza, mono));

        log.info("==================================================================");
        log.info("STEP 3: SEEDING USER-OWNED MUSIC TRACKS");
        log.info("==================================================================");

        Sound sound1 = new Sound(
                "Phnom Penh Sunset Lo-Fi",
                mongkol.getId(),
                mongkol.getUsername(),
                "/uploads/music/phnom_penh_sunset.mp3",
                "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=500&auto=format&fit=crop&q=80",
                2L // used by 2 videos
        );
        sound1 = soundRepository.save(sound1);

        Sound sound2 = new Sound(
                "Seven7 Team Anthem",
                bunheng.getId(),
                bunheng.getUsername(),
                "/uploads/music/seven7_anthem.mp3",
                "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80",
                2L // used by 2 videos
        );
        sound2 = soundRepository.save(sound2);

        Sound sound3 = new Sound(
                "Obsidian Pulse Beat",
                bunheng.getId(),
                bunheng.getUsername(),
                "/uploads/music/obsidian_pulse.mp3",
                "https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&auto=format&fit=crop&q=80",
                1L // used by 1 video
        );
        sound3 = soundRepository.save(sound3);

        log.info("==================================================================");
        log.info("STEP 4: SEEDING VIDEOS / POSTS LINKED TO USERS & SOUNDS");
        log.info("==================================================================");

        // Video 1 (by mongkol) -> uses Sound 1
        Video vid1 = new Video(
                mongkol,
                "Building high-performance video engine in Flutter & Spring Boot #coding #flutterdev",
                "Complete overview of custom PageView and VideoPlayer architecture",
                "Building high-performance video engine in Flutter & Spring Boot #coding #flutterdev",
                "/uploads/videos/video1.mp4",
                "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600"
        );
        vid1.setSoundId(sound1.getId());
        vid1.setMusicTitle(sound1.getTitle());
        vid1.setMusicArtist(sound1.getArtist());
        vid1.setAudioUrl(sound1.getAudioUrl());
        vid1.getTags().add(new VideoTag(vid1, "coding"));
        vid1.getTags().add(new VideoTag(vid1, "flutterdev"));
        vid1 = videoRepository.save(vid1);

        // Video 2 (by mongkol) -> optional sound: NO music attached
        Video vid2 = new Video(
                mongkol,
                "Spider robotics simulation test run 🤖 #robotics #tech",
                "Simulating 8-legged inverse kinematics in 3D physics engine",
                "Spider robotics simulation test run 🤖 #robotics #tech",
                "/uploads/videos/spider.mp4",
                "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600"
        );
        vid2.setSoundId(null);
        vid2.setMusicTitle(null);
        vid2.setMusicArtist(null);
        vid2.setAudioUrl(null);
        vid2.getTags().add(new VideoTag(vid2, "robotics"));
        vid2.getTags().add(new VideoTag(vid2, "tech"));
        vid2 = videoRepository.save(vid2);

        // Video 3 (by bunheng) -> uses Sound 2
        Video vid3 = new Video(
                bunheng,
                "Khmer AI robot dancing to the rhythm 🚀 #khmertech #ai",
                "Motion capture robotics demo using open source neural models",
                "Khmer AI robot dancing to the rhythm 🚀 #khmertech #ai",
                "/uploads/videos/khmer_robot.mp4",
                "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600"
        );
        vid3.setSoundId(sound2.getId());
        vid3.setMusicTitle(sound2.getTitle());
        vid3.setMusicArtist(sound2.getArtist());
        vid3.setAudioUrl(sound2.getAudioUrl());
        vid3.getTags().add(new VideoTag(vid3, "khmertech"));
        vid3.getTags().add(new VideoTag(vid3, "ai"));
        vid3 = videoRepository.save(vid3);

        // Video 4 (by rithysak) -> uses Sound 1
        Video vid4 = new Video(
                rithysak,
                "Smooth micro-animations in Flutter UI #uiux #mobile",
                "Designing fluid button transitions and glassmorphic cards",
                "Smooth micro-animations in Flutter UI #uiux #mobile",
                "/uploads/videos/video1.mp4",
                "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600"
        );
        vid4.setSoundId(sound1.getId());
        vid4.setMusicTitle(sound1.getTitle());
        vid4.setMusicArtist(sound1.getArtist());
        vid4.setAudioUrl(sound1.getAudioUrl());
        vid4.getTags().add(new VideoTag(vid4, "uiux"));
        vid4.getTags().add(new VideoTag(vid4, "mobile"));
        vid4 = videoRepository.save(vid4);

        // Video 5 (by kimliza) -> uses Sound 2
        Video vid5 = new Video(
                kimliza,
                "Coffee vibes & late night code reviews ☕ #developer #chill",
                "Aesthetic workspace setup with warm lighting and lo-fi tunes",
                "Coffee vibes & late night code reviews ☕ #developer #chill",
                "/uploads/videos/spider.mp4",
                "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600"
        );
        vid5.setSoundId(sound2.getId());
        vid5.setMusicTitle(sound2.getTitle());
        vid5.setMusicArtist(sound2.getArtist());
        vid5.setAudioUrl(sound2.getAudioUrl());
        vid5.getTags().add(new VideoTag(vid5, "developer"));
        vid5.getTags().add(new VideoTag(vid5, "chill"));
        vid5 = videoRepository.save(vid5);

        // Video 6 (by mono) -> uses Sound 3
        Video vid6 = new Video(
                mono,
                "Exploring next-gen audio discovery algorithms 🎧 #music #audio",
                "Building vector embeddings for musical genre similarities",
                "Exploring next-gen audio discovery algorithms 🎧 #music #audio",
                "/uploads/videos/khmer_robot.mp4",
                "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600"
        );
        vid6.setSoundId(sound3.getId());
        vid6.setMusicTitle(sound3.getTitle());
        vid6.setMusicArtist(sound3.getArtist());
        vid6.setAudioUrl(sound3.getAudioUrl());
        vid6.getTags().add(new VideoTag(vid6, "music"));
        vid6.getTags().add(new VideoTag(vid6, "audio"));
        vid6 = videoRepository.save(vid6);

        log.info("==================================================================");
        log.info("STEP 5: SEEDING USER SAVES");
        log.info("==================================================================");

        // mongkol saves vid3, vid4
        saveVideo(mongkol.getId(), vid3.getId());
        saveVideo(mongkol.getId(), vid4.getId());

        // bunheng saves vid1, vid5
        saveVideo(bunheng.getId(), vid1.getId());
        saveVideo(bunheng.getId(), vid5.getId());

        // rithysak saves vid2, vid6
        saveVideo(rithysak.getId(), vid2.getId());
        saveVideo(rithysak.getId(), vid6.getId());

        // kimliza saves vid1, vid3
        saveVideo(kimliza.getId(), vid1.getId());
        saveVideo(kimliza.getId(), vid3.getId());

        // mono saves vid1, vid2
        saveVideo(mono.getId(), vid1.getId());
        saveVideo(mono.getId(), vid2.getId());

        log.info("==================================================================");
        log.info("STEP 6: SEEDING EXACTLY 10 LIKES ACROSS USERS AND VIDEOS");
        log.info("==================================================================");

        // 1. mongkol likes vid3
        likeVideo(mongkol.getId(), vid3.getId());
        // 2. mongkol likes vid4
        likeVideo(mongkol.getId(), vid4.getId());
        // 3. bunheng likes vid1
        likeVideo(bunheng.getId(), vid1.getId());
        // 4. bunheng likes vid5
        likeVideo(bunheng.getId(), vid5.getId());
        // 5. rithysak likes vid1
        likeVideo(rithysak.getId(), vid1.getId());
        // 6. rithysak likes vid3
        likeVideo(rithysak.getId(), vid3.getId());
        // 7. kimliza likes vid1
        likeVideo(kimliza.getId(), vid1.getId());
        // 8. kimliza likes vid2
        likeVideo(kimliza.getId(), vid2.getId());
        // 9. mono likes vid1
        likeVideo(mono.getId(), vid1.getId());
        // 10. mono likes vid6
        likeVideo(mono.getId(), vid6.getId());

        // Update video count fields to match exact database rows
        updateVideoCounts(vid1);
        updateVideoCounts(vid2);
        updateVideoCounts(vid3);
        updateVideoCounts(vid4);
        updateVideoCounts(vid5);
        updateVideoCounts(vid6);

        log.info("==================================================================");
        log.info("CLEAN DATABASE RESET & SEEDING COMPLETED SUCCESSFULLY!");
        log.info("Seeded 5 users, 3 user-owned sounds, 6 videos, 10 saves, and EXACTLY 10 likes.");
        log.info("==================================================================");
    }

    private void saveVideo(Long userId, Long videoId) {
        videoSaveRepository.save(new VideoSave(userId, videoId));
    }

    private void likeVideo(Long userId, Long videoId) {
        videoLikeRepository.save(new VideoLike(userId, videoId));
    }

    private void updateVideoCounts(Video video) {
        long likeCount = videoLikeRepository.countByVideoId(video.getId());
        long saveCount = videoSaveRepository.countByVideoId(video.getId());
        video.setLikeCount(likeCount);
        video.setLikesCount(likeCount);
        video.setSaveCount(saveCount);
        video.setSavesCount(saveCount);
        videoRepository.save(video);
    }
}
