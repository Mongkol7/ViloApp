package com.vilo.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import com.vilo.backend.entity.VideoTag;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class VideoResponse {

    private Long id;
    private Long creatorId;
    private String username;
    private String displayName;
    private String avatarUrl;
    private Boolean isVerified;
    private String title;
    private String description;
    private String caption;
    private String videoUrl;
    private String thumbnailUrl;
    private List<String> mediaUrls = new ArrayList<>();
    private List<String> imageUrls = new ArrayList<>();
    private Long soundId;
    private String musicTitle;
    private String musicArtist;
    private String audioUrl;
    private Long viewCount = 0L;
    private Long likeCount = 0L;
    private Long commentCount = 0L;
    private Long saveCount = 0L;
    private String formattedLikes;
    private String formattedComments;
    private String formattedSaves;
    private Boolean isFollowing = false;
    private Boolean isMe = false;
    private boolean isLiked = false;
    private boolean isSaved = false;
    private List<String> tags = new ArrayList<>();
    private LocalDateTime createdAt;

    public VideoResponse() {
    }

    public VideoResponse(Long id, Long creatorId, String username, String displayName, String avatarUrl,
                         String title, String description, String caption, String videoUrl, String thumbnailUrl,
                         Long viewCount, Long likeCount, Long commentCount, Long saveCount,
                         boolean isLiked, boolean isSaved, List<String> tags, LocalDateTime createdAt) {
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
        this.formattedLikes = formatCount(this.likeCount);
        this.formattedComments = formatCount(this.commentCount);
        this.formattedSaves = formatCount(this.saveCount);
        this.isLiked = isLiked;
        this.isSaved = isSaved;
        this.tags = tags != null ? tags : new ArrayList<>();
        this.createdAt = createdAt;
    }

    public static VideoResponse fromEntity(Video video, User currentUser) {
        if (video == null) return null;
        VideoResponse resp = new VideoResponse();
        resp.setId(video.getId());
        resp.setCreatorId(video.getCreatorId());

        User creator = video.getCreator();
        if (creator != null) {
            String rawUsername = creator.getUsername();
            resp.setUsername(rawUsername != null && rawUsername.startsWith("@") ? rawUsername : "@" + rawUsername);
            resp.setDisplayName(creator.getDisplayName() != null ? creator.getDisplayName() : creator.getUsername());
            resp.setAvatarUrl(creator.getAvatarUrl());
            resp.setIsVerified(creator.getIsVerified());

            if (currentUser != null && currentUser.getId() != null) {
                resp.setIsMe(currentUser.getId().equals(creator.getId()));
                boolean following = currentUser.getFollowing() != null &&
                        currentUser.getFollowing().stream().anyMatch(f -> f.getId().equals(creator.getId()));
                resp.setIsFollowing(following);
            } else {
                resp.setIsMe(false);
                resp.setIsFollowing(false);
            }
        } else {
            resp.setUsername("@vilo_creator");
            resp.setDisplayName("Vilo Creator");
            resp.setIsFollowing(false);
            resp.setIsMe(false);
            resp.setIsVerified(false);
        }

        resp.setTitle(video.getTitle());
        resp.setDescription(video.getDescription());
        resp.setCaption(video.getCaption());
        resp.setVideoUrl(video.getVideoUrl());
        resp.setThumbnailUrl(video.getThumbnailUrl());
        resp.setSoundId(video.getSoundId());
        List<String> images = new ArrayList<>();
        if (video.getImageUrls() != null && !video.getImageUrls().isBlank()) {
            String[] parts = video.getImageUrls().split(",");
            for (String p : parts) {
                if (p != null && !p.trim().isEmpty() && isImageFile(p.trim())) {
                    images.add(p.trim());
                }
            }
        } else if (video.getVideoUrl() != null && !video.getVideoUrl().isBlank()) {
            if (isImageFile(video.getVideoUrl())) {
                String[] parts = video.getVideoUrl().split(",");
                for (String p : parts) {
                    if (p != null && !p.trim().isEmpty() && isImageFile(p.trim())) {
                        images.add(p.trim());
                    }
                }
            }
        }
        resp.setImageUrls(images);
        resp.setMediaUrls(images);
        resp.setMusicTitle(video.getMusicTitle() != null ? video.getMusicTitle() : "Original Sound - " + resp.getDisplayName());
        resp.setMusicArtist(video.getMusicArtist() != null ? video.getMusicArtist() : resp.getDisplayName());
        resp.setAudioUrl(video.getAudioUrl());
        
        long likes = video.getLikeCount() != null ? video.getLikeCount() : 0L;
        long comments = video.getCommentCount() != null ? video.getCommentCount() : 0L;
        long saves = video.getSaveCount() != null ? video.getSaveCount() : 0L;
        long views = video.getViewCount() != null ? video.getViewCount() : 0L;
        
        resp.setLikeCount(likes);
        resp.setCommentCount(comments);
        resp.setSaveCount(saves);
        resp.setViewCount(views);
        resp.setFormattedLikes(formatCount(likes));
        resp.setFormattedComments(formatCount(comments));
        resp.setFormattedSaves(formatCount(saves));
        resp.setCreatedAt(video.getCreatedAt());

        if (video.getTags() != null) {
            List<String> tagNames = new ArrayList<>();
            for (VideoTag tag : video.getTags()) {
                tagNames.add(tag.getTagName());
            }
            resp.setTags(tagNames);
        }

        return resp;
    }

    public static String formatCount(Long count) {
        if (count == null || count <= 0) return "0";
        if (count >= 1_000_000) {
            double m = count / 1_000_000.0;
            return String.format(Locale.US, "%.1fM", m).replace(".0M", "M");
        } else if (count >= 1_000) {
            double k = count / 1_000.0;
            return String.format(Locale.US, "%.1fK", k).replace(".0K", "K");
        }
        return String.valueOf(count);
    }

    public static boolean isImageFile(String path) {
        if (path == null) return false;
        String lower = path.toLowerCase().trim();
        return lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".png")
                || lower.endsWith(".webp") || lower.endsWith(".gif") || lower.endsWith(".bmp")
                || lower.contains("/uploads/photos/");
    }

    public static Builder builder() {
        return new Builder();
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getCreatorId() { return creatorId; }
    public void setCreatorId(Long creatorId) { this.creatorId = creatorId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }

    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

    @JsonProperty("isVerified")
    public Boolean getIsVerified() { return isVerified; }
    public void setIsVerified(Boolean verified) { isVerified = verified; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getCaption() { return caption; }
    public void setCaption(String caption) { this.caption = caption; }

    public String getVideoUrl() { return videoUrl; }
    public void setVideoUrl(String videoUrl) { this.videoUrl = videoUrl; }

    public String getThumbnailUrl() { return thumbnailUrl; }
    public void setThumbnailUrl(String thumbnailUrl) { this.thumbnailUrl = thumbnailUrl; }

    public List<String> getMediaUrls() { return mediaUrls; }
    public void setMediaUrls(List<String> mediaUrls) { this.mediaUrls = mediaUrls != null ? mediaUrls : new ArrayList<>(); }

    public List<String> getImageUrls() { return imageUrls; }
    public void setImageUrls(List<String> imageUrls) { this.imageUrls = imageUrls != null ? imageUrls : new ArrayList<>(); }

    public Long getSoundId() { return soundId; }
    public void setSoundId(Long soundId) { this.soundId = soundId; }

    public String getMusicTitle() { return musicTitle; }
    public void setMusicTitle(String musicTitle) { this.musicTitle = musicTitle; }

    @JsonProperty("musicName")
    public String getMusicName() { return musicTitle; }
    public void setMusicName(String musicName) { this.musicTitle = musicName; }

    public String getMusicArtist() { return musicArtist; }
    public void setMusicArtist(String musicArtist) { this.musicArtist = musicArtist; }

    public String getAudioUrl() { return audioUrl; }
    public void setAudioUrl(String audioUrl) { this.audioUrl = audioUrl; }

    public Long getViewCount() { return viewCount; }
    public void setViewCount(Long viewCount) { this.viewCount = viewCount; }

    public Long getViewsCount() { return viewCount; }
    public void setViewsCount(Long viewsCount) { this.viewCount = viewsCount; }

    public Long getLikeCount() { return likeCount; }
    public void setLikeCount(Long likeCount) { 
        this.likeCount = likeCount; 
        this.formattedLikes = formatCount(likeCount);
    }

    public Long getLikesCount() { return likeCount; }
    public void setLikesCount(Long likesCount) { setLikeCount(likesCount); }

    public Long getCommentCount() { return commentCount; }
    public void setCommentCount(Long commentCount) { 
        this.commentCount = commentCount; 
        this.formattedComments = formatCount(commentCount);
    }

    public Long getCommentsCount() { return commentCount; }
    public void setCommentsCount(Long commentsCount) { setCommentCount(commentsCount); }

    public Long getSaveCount() { return saveCount; }
    public void setSaveCount(Long saveCount) { 
        this.saveCount = saveCount; 
        this.formattedSaves = formatCount(saveCount);
    }

    public Long getSavesCount() { return saveCount; }
    public void setSavesCount(Long savesCount) { setSaveCount(savesCount); }

    public String getFormattedLikes() { return formattedLikes; }
    public void setFormattedLikes(String formattedLikes) { this.formattedLikes = formattedLikes; }

    public String getFormattedComments() { return formattedComments; }
    public void setFormattedComments(String formattedComments) { this.formattedComments = formattedComments; }

    public String getFormattedSaves() { return formattedSaves; }
    public void setFormattedSaves(String formattedSaves) { this.formattedSaves = formattedSaves; }

    @JsonProperty("isFollowing")
    public Boolean getIsFollowing() { return isFollowing; }
    public void setIsFollowing(Boolean following) { isFollowing = following; }

    @JsonProperty("isMe")
    public Boolean getIsMe() { return isMe; }
    public void setIsMe(Boolean me) { isMe = me; }

    @JsonProperty("isLiked")
    public boolean isLiked() { return isLiked; }
    public void setLiked(boolean liked) { isLiked = liked; }

    @JsonProperty("isSaved")
    public boolean isSaved() { return isSaved; }
    public void setSaved(boolean saved) { isSaved = saved; }

    public List<String> getTags() { return tags; }
    public void setTags(List<String> tags) { this.tags = tags; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public static class Builder {
        private Long id;
        private Long creatorId;
        private String username;
        private String displayName;
        private String avatarUrl;
        private Boolean isVerified = false;
        private String title;
        private String description;
        private String caption;
        private String videoUrl;
        private String thumbnailUrl;
        private String musicTitle;
        private String musicArtist;
        private String audioUrl;
        private Long viewCount = 0L;
        private Long likeCount = 0L;
        private Long commentCount = 0L;
        private Long saveCount = 0L;
        private boolean isLiked = false;
        private boolean isSaved = false;
        private Boolean isFollowing = false;
        private Boolean isMe = false;
        private List<String> tags = new ArrayList<>();
        private List<String> imageUrls = new ArrayList<>();
        private Long soundId;
        private LocalDateTime createdAt;

        public Builder id(Long id) { this.id = id; return this; }
        public Builder creatorId(Long creatorId) { this.creatorId = creatorId; return this; }
        public Builder username(String username) { this.username = username; return this; }
        public Builder displayName(String displayName) { this.displayName = displayName; return this; }
        public Builder avatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; return this; }
        public Builder isVerified(Boolean isVerified) { this.isVerified = isVerified; return this; }
        public Builder title(String title) { this.title = title; return this; }
        public Builder description(String description) { this.description = description; return this; }
        public Builder caption(String caption) { this.caption = caption; return this; }
        public Builder videoUrl(String videoUrl) { this.videoUrl = videoUrl; return this; }
        public Builder thumbnailUrl(String thumbnailUrl) { this.thumbnailUrl = thumbnailUrl; return this; }
        public Builder imageUrls(List<String> imageUrls) { this.imageUrls = imageUrls != null ? imageUrls : new ArrayList<>(); return this; }
        public Builder soundId(Long soundId) { this.soundId = soundId; return this; }
        public Builder musicTitle(String musicTitle) { this.musicTitle = musicTitle; return this; }
        public Builder musicName(String musicName) { this.musicTitle = musicName; return this; }
        public Builder musicArtist(String musicArtist) { this.musicArtist = musicArtist; return this; }
        public Builder audioUrl(String audioUrl) { this.audioUrl = audioUrl; return this; }
        public Builder viewCount(Long viewCount) { this.viewCount = viewCount; return this; }
        public Builder likeCount(Long likeCount) { this.likeCount = likeCount; return this; }
        public Builder commentCount(Long commentCount) { this.commentCount = commentCount; return this; }
        public Builder saveCount(Long saveCount) { this.saveCount = saveCount; return this; }
        public Builder isLiked(boolean isLiked) { this.isLiked = isLiked; return this; }
        public Builder isSaved(boolean isSaved) { this.isSaved = isSaved; return this; }
        public Builder isFollowing(Boolean isFollowing) { this.isFollowing = isFollowing; return this; }
        public Builder isMe(Boolean isMe) { this.isMe = isMe; return this; }
        public Builder tags(List<String> tags) { this.tags = tags; return this; }
        public Builder createdAt(LocalDateTime createdAt) { this.createdAt = createdAt; return this; }

        public VideoResponse build() {
            String resolvedCaption = caption != null ? caption : (description != null ? description : title);
            VideoResponse resp = new VideoResponse(id, creatorId, username, displayName, avatarUrl,
                    title, description, resolvedCaption,
                    videoUrl, thumbnailUrl, viewCount, likeCount, commentCount, saveCount,
                    isLiked, isSaved, tags, createdAt);
            resp.setIsVerified(isVerified);
            resp.setIsFollowing(isFollowing);
            resp.setIsMe(isMe);
            resp.setImageUrls(imageUrls);
            resp.setMediaUrls(imageUrls);
            resp.setSoundId(soundId);
            resp.setMusicTitle(musicTitle != null ? musicTitle : "Original Sound - " + (displayName != null ? displayName : username));
            resp.setMusicArtist(musicArtist != null ? musicArtist : (displayName != null ? displayName : username));
            resp.setAudioUrl(audioUrl);
            return resp;
        }
    }
}
