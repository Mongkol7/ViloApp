package com.vilo.backend.dto;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class CommentResponse {

    private Long id;
    private Long videoId;
    private Long userId;
    private String username;
    private String displayName;
    private String avatarUrl;
    private Long parentId;
    private String content;
    private LocalDateTime createdAt;
    private List<CommentResponse> replies = new ArrayList<>();

    public CommentResponse() {
    }

    public CommentResponse(Long id, Long videoId, Long userId, String username, String displayName,
                           String avatarUrl, Long parentId, String content, LocalDateTime createdAt,
                           List<CommentResponse> replies) {
        this.id = id;
        this.videoId = videoId;
        this.userId = userId;
        this.username = username;
        this.displayName = displayName;
        this.avatarUrl = avatarUrl;
        this.parentId = parentId;
        this.content = content;
        this.createdAt = createdAt;
        this.replies = replies != null ? replies : new ArrayList<>();
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

    public Long getVideoId() {
        return videoId;
    }

    public void setVideoId(Long videoId) {
        this.videoId = videoId;
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

    public Long getParentId() {
        return parentId;
    }

    public void setParentId(Long parentId) {
        this.parentId = parentId;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public List<CommentResponse> getReplies() {
        return replies;
    }

    public void setReplies(List<CommentResponse> replies) {
        this.replies = replies;
    }

    public static class Builder {
        private Long id;
        private Long videoId;
        private Long userId;
        private String username;
        private String displayName;
        private String avatarUrl;
        private Long parentId;
        private String content;
        private LocalDateTime createdAt;
        private List<CommentResponse> replies = new ArrayList<>();

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder videoId(Long videoId) {
            this.videoId = videoId;
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

        public Builder parentId(Long parentId) {
            this.parentId = parentId;
            return this;
        }

        public Builder content(String content) {
            this.content = content;
            return this;
        }

        public Builder createdAt(LocalDateTime createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public Builder replies(List<CommentResponse> replies) {
            this.replies = replies;
            return this;
        }

        public CommentResponse build() {
            return new CommentResponse(id, videoId, userId, username, displayName, avatarUrl, parentId, content, createdAt, replies);
        }
    }
}
