package com.vilo.backend.dto;

import java.time.Instant;

public class StoryViewerResponse {

    private Long id;
    private Long userId;
    private String username;
    private String displayName;
    private String avatarUrl;
    private Boolean isVerified;
    private Instant viewedAt;

    public StoryViewerResponse() {
    }

    public StoryViewerResponse(Long id, Long userId, String username, String displayName,
                               String avatarUrl, Boolean isVerified, Instant viewedAt) {
        this.id = id;
        this.userId = userId;
        this.username = username;
        this.displayName = displayName;
        this.avatarUrl = avatarUrl;
        this.isVerified = isVerified;
        this.viewedAt = viewedAt;
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

    public Instant getViewedAt() {
        return viewedAt;
    }

    public void setViewedAt(Instant viewedAt) {
        this.viewedAt = viewedAt;
    }

    public static class Builder {
        private Long id;
        private Long userId;
        private String username;
        private String displayName;
        private String avatarUrl;
        private Boolean isVerified;
        private Instant viewedAt;

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

        public Builder viewedAt(Instant viewedAt) {
            this.viewedAt = viewedAt;
            return this;
        }

        public StoryViewerResponse build() {
            return new StoryViewerResponse(id, userId, username, displayName, avatarUrl, isVerified, viewedAt);
        }
    }
}
