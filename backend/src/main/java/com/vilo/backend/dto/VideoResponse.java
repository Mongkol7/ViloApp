package com.vilo.backend.dto;

import com.vilo.backend.entity.Video;
import com.vilo.backend.entity.User;

import java.time.Instant;

public class VideoResponse {

    private Long id;
    private Long creatorId;
    private String username;
    private String displayName;
    private String avatarUrl;
    private Boolean isVerified;
    private String videoUrl;
    private String thumbnailUrl;
    private String caption;
    private String musicTitle;
    private Long likesCount;
    private Long commentsCount;
    private Long savesCount;
    private Long viewsCount;
    private String formattedLikes;
    private String formattedComments;
    private String formattedSaves;
    private Boolean isFollowing;
    private Boolean isMe;
    private Instant createdAt;

    public VideoResponse() {
    }

    public static VideoResponse fromEntity(Video video, User currentUser) {
        if (video == null) return null;
        VideoResponse resp = new VideoResponse();
        resp.setId(video.getId());

        User creator = video.getCreator();
        if (creator != null) {
            resp.setCreatorId(creator.getId());
            String rawUsername = creator.getUsername();
            resp.setUsername(rawUsername != null && rawUsername.startsWith("@") ? rawUsername : "@" + rawUsername);
            resp.setDisplayName(creator.getDisplayName() != null ? creator.getDisplayName() : creator.getUsername());
            resp.setAvatarUrl(creator.getAvatarUrl());
            resp.setIsVerified(creator.getIsVerified());

            if (currentUser != null) {
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
        }

        resp.setVideoUrl(video.getVideoUrl());
        resp.setThumbnailUrl(video.getThumbnailUrl());
        resp.setCaption(video.getCaption());
        resp.setMusicTitle(video.getMusicTitle() != null ? video.getMusicTitle() : "Original Sound - " + resp.getDisplayName());
        long likes = video.getLikesCount() != null ? video.getLikesCount() : 0L;
        long comments = video.getCommentsCount() != null ? video.getCommentsCount() : 0L;
        long saves = video.getSavesCount() != null ? video.getSavesCount() : 0L;
        long views = video.getViewsCount() != null ? video.getViewsCount() : 0L;
        resp.setLikesCount(likes);
        resp.setCommentsCount(comments);
        resp.setSavesCount(saves);
        resp.setViewsCount(views);
        resp.setFormattedLikes(formatCount(likes));
        resp.setFormattedComments(formatCount(comments));
        resp.setFormattedSaves(formatCount(saves));
        resp.setCreatedAt(video.getCreatedAt());

        return resp;
    }

    public static String formatCount(Long count) {
        if (count == null || count <= 0) return "0";
        if (count >= 1_000_000) {
            double m = count / 1_000_000.0;
            return String.format(java.util.Locale.US, "%.1fM", m).replace(".0M", "M");
        } else if (count >= 1_000) {
            double k = count / 1_000.0;
            return String.format(java.util.Locale.US, "%.1fK", k).replace(".0K", "K");
        }
        return String.valueOf(count);
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

    public Boolean getIsVerified() {
        return isVerified;
    }

    public void setIsVerified(Boolean verified) {
        isVerified = verified;
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

    public String getCaption() {
        return caption;
    }

    public void setCaption(String caption) {
        this.caption = caption;
    }

    public String getMusicTitle() {
        return musicTitle;
    }

    public void setMusicTitle(String musicTitle) {
        this.musicTitle = musicTitle;
    }

    public Long getLikesCount() {
        return likesCount;
    }

    public void setLikesCount(Long likesCount) {
        this.likesCount = likesCount;
    }

    public Long getCommentsCount() {
        return commentsCount;
    }

    public void setCommentsCount(Long commentsCount) {
        this.commentsCount = commentsCount;
    }

    public Long getSavesCount() {
        return savesCount;
    }

    public void setSavesCount(Long savesCount) {
        this.savesCount = savesCount;
    }

    public Long getViewsCount() {
        return viewsCount;
    }

    public void setViewsCount(Long viewsCount) {
        this.viewsCount = viewsCount;
    }

    public String getFormattedLikes() {
        return formattedLikes;
    }

    public void setFormattedLikes(String formattedLikes) {
        this.formattedLikes = formattedLikes;
    }

    public String getFormattedComments() {
        return formattedComments;
    }

    public void setFormattedComments(String formattedComments) {
        this.formattedComments = formattedComments;
    }

    public String getFormattedSaves() {
        return formattedSaves;
    }

    public void setFormattedSaves(String formattedSaves) {
        this.formattedSaves = formattedSaves;
    }

    public Boolean getIsFollowing() {
        return isFollowing;
    }

    public void setIsFollowing(Boolean following) {
        isFollowing = following;
    }

    public Boolean getIsMe() {
        return isMe;
    }

    public void setIsMe(Boolean me) {
        isMe = me;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
