package com.vilo.backend.dto;

import java.time.Instant;

public class StoryResponse {

    private Long id;
    private Long userId;
    private String username;
    private String displayName;
    private String avatarUrl;
    private Boolean isVerified;
    private String message;
    private String musicTrackId;
    private String musicTitle;
    private String musicArtist;
    private String musicAlbumArt;
    private String musicPreviewUrl;
    private Integer musicDuration;
    private String backgroundGradient;
    private Integer viewCount;
    private Instant expiresAt;
    private Instant createdAt;
    private Boolean isViewedByMe;
    private Boolean isMyStory;

    public StoryResponse() {
    }

    public StoryResponse(Long id, Long userId, String username, String displayName, String avatarUrl,
                         Boolean isVerified, String message, String musicTrackId, String musicTitle,
                         String musicArtist, String musicAlbumArt, String musicPreviewUrl,
                         Integer musicDuration, String backgroundGradient, Integer viewCount,
                         Instant expiresAt, Instant createdAt, Boolean isViewedByMe, Boolean isMyStory) {
        this.id = id;
        this.userId = userId;
        this.username = username;
        this.displayName = displayName;
        this.avatarUrl = avatarUrl;
        this.isVerified = isVerified;
        this.message = message;
        this.musicTrackId = musicTrackId;
        this.musicTitle = musicTitle;
        this.musicArtist = musicArtist;
        this.musicAlbumArt = musicAlbumArt;
        this.musicPreviewUrl = musicPreviewUrl;
        this.musicDuration = musicDuration;
        this.backgroundGradient = backgroundGradient;
        this.viewCount = viewCount;
        this.expiresAt = expiresAt;
        this.createdAt = createdAt;
        this.isViewedByMe = isViewedByMe;
        this.isMyStory = isMyStory;
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

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public Boolean getIsVerified() {
        return isVerified;
    }

    public void setIsVerified(Boolean isVerified) {
        this.isVerified = isVerified;
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

    public Boolean getIsViewedByMe() {
        return isViewedByMe;
    }

    public void setIsViewedByMe(Boolean isViewedByMe) {
        this.isViewedByMe = isViewedByMe;
    }

    public Boolean getIsMyStory() {
        return isMyStory;
    }

    public void setIsMyStory(Boolean isMyStory) {
        this.isMyStory = isMyStory;
    }

    public static class Builder {
        private Long id;
        private Long userId;
        private String username;
        private String displayName;
        private String avatarUrl;
        private Boolean isVerified;
        private String message;
        private String musicTrackId;
        private String musicTitle;
        private String musicArtist;
        private String musicAlbumArt;
        private String musicPreviewUrl;
        private Integer musicDuration;
        private String backgroundGradient;
        private Integer viewCount;
        private Instant expiresAt;
        private Instant createdAt;
        private Boolean isViewedByMe;
        private Boolean isMyStory;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder userId(Long userId) {
            this.userId = userId;
            return this;
        }

        public Builder username(String username) {
            this.username = username;
            return this;
        }

        public Builder displayName(String displayName) {
            this.displayName = displayName;
            return this;
        }

        public Builder avatarUrl(String avatarUrl) {
            this.avatarUrl = avatarUrl;
            return this;
        }

        public Builder isVerified(Boolean isVerified) {
            this.isVerified = isVerified;
            return this;
        }

        public Builder message(String message) {
            this.message = message;
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

        public Builder isViewedByMe(Boolean isViewedByMe) {
            this.isViewedByMe = isViewedByMe;
            return this;
        }

        public Builder isMyStory(Boolean isMyStory) {
            this.isMyStory = isMyStory;
            return this;
        }

        public StoryResponse build() {
            return new StoryResponse(id, userId, username, displayName, avatarUrl, isVerified, message,
                    musicTrackId, musicTitle, musicArtist, musicAlbumArt, musicPreviewUrl, musicDuration,
                    backgroundGradient, viewCount, expiresAt, createdAt, isViewedByMe, isMyStory);
        }
    }
}
