package com.vilo.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class VideoResponse {

    private Long id;
    private Long creatorId;
    private String username;
    private String displayName;
    private String avatarUrl;
    private String title;
    private String description;
    private String caption;
    private String videoUrl;
    private String thumbnailUrl;
    private Long viewCount;
    private Long likeCount;
    private Long commentCount;
    private Long saveCount;
    private boolean isLiked;
    private boolean isSaved;
    private List<String> tags = new ArrayList<>();
    private LocalDateTime createdAt;

    public VideoResponse() {
    }

    public VideoResponse(Long id, Long creatorId, String username, String displayName, String avatarUrl,
                         String title, String description, String caption, String videoUrl, String thumbnailUrl, Long viewCount,
                         Long likeCount, Long commentCount, Long saveCount, boolean isLiked,
                         boolean isSaved, List<String> tags, LocalDateTime createdAt) {
        this.id = id;
        this.creatorId = creatorId;
        this.username = username;
        this.displayName = displayName;
        this.avatarUrl = avatarUrl;
        this.title = title;
        this.description = description;
        this.caption = caption;
        this.videoUrl = videoUrl;
        this.thumbnailUrl = thumbnailUrl;
        this.viewCount = viewCount != null ? viewCount : 0L;
        this.likeCount = likeCount != null ? likeCount : 0L;
        this.commentCount = commentCount != null ? commentCount : 0L;
        this.saveCount = saveCount != null ? saveCount : 0L;
        this.isLiked = isLiked;
        this.isSaved = isSaved;
        this.tags = tags != null ? tags : new ArrayList<>();
        this.createdAt = createdAt;
    }

    public VideoResponse(Long id, Long creatorId, String username, String displayName, String avatarUrl,
                         String caption, String videoUrl, String thumbnailUrl, Long viewCount,
                         Long likeCount, Long commentCount, Long saveCount, boolean isLiked,
                         boolean isSaved, List<String> tags, LocalDateTime createdAt) {
        this(id, creatorId, username, displayName, avatarUrl, caption, caption, caption,
                videoUrl, thumbnailUrl, viewCount, likeCount, commentCount, saveCount,
                isLiked, isSaved, tags, createdAt);
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

    public Long getCreatorId() {
        return creatorId;
    }

    public void setCreatorId(Long creatorId) {
        this.creatorId = creatorId;
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

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getCaption() {
        return caption;
    }

    public void setCaption(String caption) {
        this.caption = caption;
    }

    public String getVideoUrl() {
        return videoUrl;
    }

    public void setVideoUrl(String videoUrl) {
        this.videoUrl = videoUrl;
    }

    public String getThumbnailUrl() {
        return thumbnailUrl;
    }

    public void setThumbnailUrl(String thumbnailUrl) {
        this.thumbnailUrl = thumbnailUrl;
    }

    public Long getViewCount() {
        return viewCount;
    }

    public void setViewCount(Long viewCount) {
        this.viewCount = viewCount;
    }

    public Long getLikeCount() {
        return likeCount;
    }

    public void setLikeCount(Long likeCount) {
        this.likeCount = likeCount;
    }

    public Long getCommentCount() {
        return commentCount;
    }

    public void setCommentCount(Long commentCount) {
        this.commentCount = commentCount;
    }

    public Long getSaveCount() {
        return saveCount;
    }

    public void setSaveCount(Long saveCount) {
        this.saveCount = saveCount;
    }

    @JsonProperty("isLiked")
    public boolean isLiked() {
        return isLiked;
    }

    public void setLiked(boolean liked) {
        isLiked = liked;
    }

    @JsonProperty("isSaved")
    public boolean isSaved() {
        return isSaved;
    }

    public void setSaved(boolean saved) {
        isSaved = saved;
    }

    public List<String> getTags() {
        return tags;
    }

    public void setTags(List<String> tags) {
        this.tags = tags;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public static class Builder {
        private Long id;
        private Long creatorId;
        private String username;
        private String displayName;
        private String avatarUrl;
        private String title;
        private String description;
        private String caption;
        private String videoUrl;
        private String thumbnailUrl;
        private Long viewCount;
        private Long likeCount;
        private Long commentCount;
        private Long saveCount;
        private boolean isLiked;
        private boolean isSaved;
        private List<String> tags = new ArrayList<>();
        private LocalDateTime createdAt;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder creatorId(Long creatorId) {
            this.creatorId = creatorId;
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

        public Builder title(String title) {
            this.title = title;
            return this;
        }

        public Builder description(String description) {
            this.description = description;
            return this;
        }

        public Builder caption(String caption) {
            this.caption = caption;
            return this;
        }

        public Builder videoUrl(String videoUrl) {
            this.videoUrl = videoUrl;
            return this;
        }

        public Builder thumbnailUrl(String thumbnailUrl) {
            this.thumbnailUrl = thumbnailUrl;
            return this;
        }

        public Builder viewCount(Long viewCount) {
            this.viewCount = viewCount;
            return this;
        }

        public Builder likeCount(Long likeCount) {
            this.likeCount = likeCount;
            return this;
        }

        public Builder commentCount(Long commentCount) {
            this.commentCount = commentCount;
            return this;
        }

        public Builder saveCount(Long saveCount) {
            this.saveCount = saveCount;
            return this;
        }

        public Builder isLiked(boolean isLiked) {
            this.isLiked = isLiked;
            return this;
        }

        public Builder isSaved(boolean isSaved) {
            this.isSaved = isSaved;
            return this;
        }

        public Builder tags(List<String> tags) {
            this.tags = tags;
            return this;
        }

        public Builder createdAt(LocalDateTime createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public VideoResponse build() {
            String resolvedCaption = caption != null ? caption : (description != null ? description : title);
            return new VideoResponse(id, creatorId, username, displayName, avatarUrl,
                    title, description, resolvedCaption,
                    videoUrl, thumbnailUrl, viewCount, likeCount, commentCount, saveCount,
                    isLiked, isSaved, tags, createdAt);
        }
    }
}
