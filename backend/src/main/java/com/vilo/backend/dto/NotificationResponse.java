package com.vilo.backend.dto;

import com.vilo.backend.entity.Notification;
import com.vilo.backend.entity.User;

import java.time.Instant;

public class NotificationResponse {
    private Long id;
    private String type;
    private Long actorId;
    private String actorUsername;
    private String actorDisplayName;
    private String actorAvatarUrl;
    private Long videoId;
    private Long commentId;
    private Long targetUserId;
    private String commentExcerpt;
    private boolean read;
    private Instant createdAt;

    public static NotificationResponse fromEntity(Notification notification, User actor) {
        NotificationResponse response = new NotificationResponse();
        response.id = notification.getId();
        response.type = notification.getType();
        response.actorId = notification.getActorId();
        response.actorUsername = actor != null ? actor.getUsername() : null;
        response.actorDisplayName = actor != null ? actor.getDisplayName() : null;
        response.actorAvatarUrl = actor != null ? actor.getAvatarUrl() : null;
        response.videoId = notification.getVideoId();
        response.commentId = notification.getCommentId();
        response.targetUserId = notification.getTargetUserId();
        response.commentExcerpt = notification.getCommentExcerpt();
        response.read = notification.getReadAt() != null;
        response.createdAt = notification.getCreatedAt();
        return response;
    }

    public Long getId() { return id; }
    public String getType() { return type; }
    public Long getActorId() { return actorId; }
    public String getActorUsername() { return actorUsername; }
    public String getActorDisplayName() { return actorDisplayName; }
    public String getActorAvatarUrl() { return actorAvatarUrl; }
    public Long getVideoId() { return videoId; }
    public Long getCommentId() { return commentId; }
    public Long getTargetUserId() { return targetUserId; }
    public String getCommentExcerpt() { return commentExcerpt; }
    public boolean isRead() { return read; }
    public Instant getCreatedAt() { return createdAt; }
}
