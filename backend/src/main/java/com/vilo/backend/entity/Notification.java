package com.vilo.backend.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(
        name = "notifications",
        indexes = {
                @Index(name = "idx_notifications_recipient_created", columnList = "recipient_id, created_at"),
                @Index(name = "idx_notifications_recipient_unread", columnList = "recipient_id, is_read")
        }
)
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "actor_id")
    private User actor;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private NotificationType type;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, length = 500)
    private String body;

    @Column(name = "entity_id", length = 100)
    private String entityId;

    @Column(name = "entity_type", length = 50)
    private String entityType;

    @Column(name = "is_read", nullable = false)
    private Boolean isRead = false;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    public Notification() {
    }

    public Notification(Long id, User recipient, User actor, NotificationType type, String title,
                        String body, String entityId, String entityType, Boolean isRead, Instant createdAt) {
        this.id = id;
        this.recipient = recipient;
        this.actor = actor;
        this.type = type;
        this.title = title;
        this.body = body;
        this.entityId = entityId;
        this.entityType = entityType;
        this.isRead = isRead != null ? isRead : false;
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

    public User getRecipient() {
        return recipient;
    }

    public void setRecipient(User recipient) {
        this.recipient = recipient;
    }

    public User getActor() {
        return actor;
    }

    public void setActor(User actor) {
        this.actor = actor;
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

    public static class Builder {
        private Long id;
        private User recipient;
        private User actor;
        private NotificationType type;
        private String title;
        private String body;
        private String entityId;
        private String entityType;
        private Boolean isRead = false;
        private Instant createdAt;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder recipient(User recipient) {
            this.recipient = recipient;
            return this;
        }

        public Builder actor(User actor) {
            this.actor = actor;
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

        public Notification build() {
            return new Notification(id, recipient, actor, type, title, body, entityId, entityType, isRead, createdAt);
        }
    }
}
