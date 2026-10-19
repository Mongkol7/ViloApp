package com.vilo.backend.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(
        name = "thought_stories",
        indexes = {
                @Index(name = "idx_thought_stories_user_expires", columnList = "user_id, expires_at"),
                @Index(name = "idx_thought_stories_expires_at", columnList = "expires_at")
        }
)
public class ThoughtStory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 500)
    private String message;

    @Column(name = "music_track_id", length = 100)
    private String musicTrackId;

    @Column(name = "music_title", length = 200)
    private String musicTitle;

    @Column(name = "music_artist", length = 200)
    private String musicArtist;

    @Column(name = "music_album_art", length = 500)
    private String musicAlbumArt;

    @Column(name = "music_preview_url", length = 500)
    private String musicPreviewUrl;

    @Column(name = "music_duration")
    private Integer musicDuration;

    @Column(name = "background_gradient", length = 100)
    private String backgroundGradient;

    @Column(name = "media_url", length = 1000)
    private String mediaUrl;

    @Column(name = "media_type", length = 20)
    private String mediaType = "TEXT";

    @Column(name = "privacy", length = 20)
    private String privacy = "PUBLIC";

    @Column(name = "view_count", nullable = false)
    private Integer viewCount = 0;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    public ThoughtStory() {
    }

    public ThoughtStory(Long id, User user, String message, String mediaUrl, String mediaType, String privacy,
                        String musicTrackId, String musicTitle, String musicArtist, String musicAlbumArt,
                        String musicPreviewUrl, Integer musicDuration, String backgroundGradient,
                        Integer viewCount, Instant expiresAt, Instant createdAt) {
        this.id = id;
        this.user = user;
        this.message = message != null ? message : "";
        this.mediaUrl = mediaUrl;
        this.mediaType = mediaType != null ? mediaType : "TEXT";
        this.privacy = privacy != null ? privacy : "PUBLIC";
        this.musicTrackId = musicTrackId;
        this.musicTitle = musicTitle;
        this.musicArtist = musicArtist;
        this.musicAlbumArt = musicAlbumArt;
        this.musicPreviewUrl = musicPreviewUrl;
        this.musicDuration = musicDuration;
        this.backgroundGradient = backgroundGradient;
        this.viewCount = viewCount != null ? viewCount : 0;
        this.expiresAt = expiresAt;
        this.createdAt = createdAt;
    }

    public static Builder builder() {
        return new Builder();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getMusicTrackId() {
        return musicTrackId;
    }

    public void setMusicTrackId(String musicTrackId) {
        this.musicTrackId = musicTrackId;
    }

    public String getMusicTitle() {
        return musicTitle;
    }

    public void setMusicTitle(String musicTitle) {
        this.musicTitle = musicTitle;
    }

    public String getMusicArtist() {
        return musicArtist;
    }

    public void setMusicArtist(String musicArtist) {
        this.musicArtist = musicArtist;
    }

    public String getMusicAlbumArt() {
        return musicAlbumArt;
    }

    public void setMusicAlbumArt(String musicAlbumArt) {
        this.musicAlbumArt = musicAlbumArt;
    }

    public String getMusicPreviewUrl() {
        return musicPreviewUrl;
    }

    public void setMusicPreviewUrl(String musicPreviewUrl) {
        this.musicPreviewUrl = musicPreviewUrl;
    }

    public Integer getMusicDuration() {
        return musicDuration;
    }

    public void setMusicDuration(Integer musicDuration) {
        this.musicDuration = musicDuration;
    }

    public String getBackgroundGradient() {
        return backgroundGradient;
    }

    public void setBackgroundGradient(String backgroundGradient) {
        this.backgroundGradient = backgroundGradient;
    }

    public String getMediaUrl() {
        return mediaUrl;
    }

    public void setMediaUrl(String mediaUrl) {
        this.mediaUrl = mediaUrl;
    }

    public String getMediaType() {
        return mediaType;
    }

    public void setMediaType(String mediaType) {
        this.mediaType = mediaType;
    }

    public String getPrivacy() {
        return privacy;
    }

    public void setPrivacy(String privacy) {
        this.privacy = privacy;
    }

    public Integer getViewCount() {
        return viewCount;
    }

    public void setViewCount(Integer viewCount) {
        this.viewCount = viewCount;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(Instant expiresAt) {
        this.expiresAt = expiresAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public static class Builder {
        private Long id;
        private User user;
        private String message;
        private String mediaUrl;
        private String mediaType = "TEXT";
        private String privacy = "PUBLIC";
        private String musicTrackId;
        private String musicTitle;
        private String musicArtist;
        private String musicAlbumArt;
        private String musicPreviewUrl;
        private Integer musicDuration;
        private String backgroundGradient;
        private Integer viewCount = 0;
        private Instant expiresAt;
        private Instant createdAt;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder user(User user) {
            this.user = user;
            return this;
        }

        public Builder message(String message) {
            this.message = message;
            return this;
        }

        public Builder mediaUrl(String mediaUrl) {
            this.mediaUrl = mediaUrl;
            return this;
        }

        public Builder mediaType(String mediaType) {
            this.mediaType = mediaType;
            return this;
        }

        public Builder privacy(String privacy) {
            this.privacy = privacy;
            return this;
        }

        public Builder musicTrackId(String musicTrackId) {
            this.musicTrackId = musicTrackId;
            return this;
        }

        public Builder musicTitle(String musicTitle) {
            this.musicTitle = musicTitle;
            return this;
        }

        public Builder musicArtist(String musicArtist) {
            this.musicArtist = musicArtist;
            return this;
        }

        public Builder musicAlbumArt(String musicAlbumArt) {
            this.musicAlbumArt = musicAlbumArt;
            return this;
        }

        public Builder musicPreviewUrl(String musicPreviewUrl) {
            this.musicPreviewUrl = musicPreviewUrl;
            return this;
        }

        public Builder musicDuration(Integer musicDuration) {
            this.musicDuration = musicDuration;
            return this;
        }

        public Builder backgroundGradient(String backgroundGradient) {
            this.backgroundGradient = backgroundGradient;
            return this;
        }

        public Builder viewCount(Integer viewCount) {
            this.viewCount = viewCount;
            return this;
        }

        public Builder expiresAt(Instant expiresAt) {
            this.expiresAt = expiresAt;
            return this;
        }

        public Builder createdAt(Instant createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public ThoughtStory build() {
            return new ThoughtStory(id, user, message, mediaUrl, mediaType, privacy, musicTrackId, musicTitle, musicArtist,
                    musicAlbumArt, musicPreviewUrl, musicDuration, backgroundGradient, viewCount, expiresAt, createdAt);
        }
    }
}
