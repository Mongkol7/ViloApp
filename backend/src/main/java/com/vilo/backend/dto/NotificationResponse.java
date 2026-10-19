package com.vilo.backend.dto;

import com.vilo.backend.entity.NotificationType;

import java.time.Instant;

public class NotificationResponse {

    private Long id;
    private NotificationType type;
    private String title;
    private String body;
    private String entityId;
    private String entityType;
    private Boolean isRead;
    private Instant createdAt;

    private Long actorId;
    private String actorUsername;
    private String actorDisplayName;
    private String actorAvatarUrl;

    public NotificationResponse() {
    }

    public NotificationResponse(Long id, NotificationType type, String title, String body,
                                String entityId, String entityType, Boolean isRead, Instant createdAt,
                                Long actorId, String actorUsername, String actorDisplayName, String actorAvatarUrl) {
        this.id = id;
        this.type = type;
        this.title = title;
        this.body = body;
        this.entityId = entityId;
        this.entityType = entityType;
        this.isRead = isRead;
        this.createdAt = createdAt;
        this.actorId = actorId;
        this.actorUsername = actorUsername;
        this.actorDisplayName = actorDisplayName;
        this.actorAvatarUrl = actorAvatarUrl;
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

    public NotificationType getType() {
        return type;
    }

    public void setType(NotificationType type) {
        this.type = type;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

    public String getEntityId() {
        return entityId;
    }

    public void setEntityId(String entityId) {
        this.entityId = entityId;
    }

    public String getEntityType() {
        return entityType;
    }

    public void setEntityType(String entityType) {
        this.entityType = entityType;
    }

    public Boolean getIsRead() {
        return isRead;
    }

    public void setIsRead(Boolean isRead) {
        this.isRead = isRead;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Long getActorId() {
        return actorId;
    }

    public void setActorId(Long actorId) {
        this.actorId = actorId;
    }

    public String getActorUsername() {
        return actorUsername;
    }

    public void setActorUsername(String actorUsername) {
        this.actorUsername = actorUsername;
    }

    public String getActorDisplayName() {
        return actorDisplayName;
    }

    public void setActorDisplayName(String actorDisplayName) {
        this.actorDisplayName = actorDisplayName;
    }

    public String getActorAvatarUrl() {
        return actorAvatarUrl;
    }

    public void setActorAvatarUrl(String actorAvatarUrl) {
        this.actorAvatarUrl = actorAvatarUrl;
    }

    public static class Builder {
        private Long id;
        private NotificationType type;
        private String title;
        private String body;
        private String entityId;
        private String entityType;
        private Boolean isRead = false;
        private Instant createdAt;
        private Long actorId;
        private String actorUsername;
        private String actorDisplayName;
        private String actorAvatarUrl;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder type(NotificationType type) {
            this.type = type;
            return this;
        }

        public Builder title(String title) {
            this.title = title;
            return this;
        }

        public Builder body(String body) {
            this.body = body;
            return this;
        }

        public Builder entityId(String entityId) {
            this.entityId = entityId;
            return this;
        }

        public Builder entityType(String entityType) {
            this.entityType = entityType;
            return this;
        }

        public Builder isRead(Boolean isRead) {
            this.isRead = isRead;
            return this;
        }

        public Builder createdAt(Instant createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public Builder actorId(Long actorId) {
            this.actorId = actorId;
            return this;
        }

        public Builder actorUsername(String actorUsername) {
            this.actorUsername = actorUsername;
            return this;
        }

        public Builder actorDisplayName(String actorDisplayName) {
            this.actorDisplayName = actorDisplayName;
            return this;
        }

        public Builder actorAvatarUrl(String actorAvatarUrl) {
            this.actorAvatarUrl = actorAvatarUrl;
            return this;
        }

        public NotificationResponse build() {
            return new NotificationResponse(id, type, title, body, entityId, entityType, isRead,
                    createdAt, actorId, actorUsername, actorDisplayName, actorAvatarUrl);
        }
    }
}
