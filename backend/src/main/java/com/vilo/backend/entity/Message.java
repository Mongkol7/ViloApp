package com.vilo.backend.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(
        name = "messages",
        indexes = {
                @Index(name = "idx_messages_created_at", columnList = "created_at"),
                @Index(name = "idx_messages_conversation_created", columnList = "conversation_id, created_at")
        }
)
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "conversation_id", nullable = false)
    private Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;

    @Column(nullable = false, length = 2000)
    private String content;

    @Column(name = "media_url", length = 500)
    private String mediaUrl;

    @Column(name = "is_read", nullable = false)
    private Boolean isRead = false;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    public Message() {
    }

    public Message(Long id, Conversation conversation, User sender, User recipient,
                   String content, String mediaUrl, Boolean isRead, Instant createdAt) {
        this.id = id;
        this.conversation = conversation;
        this.sender = sender;
        this.recipient = recipient;
        this.content = content;
        this.mediaUrl = mediaUrl;
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

    public Conversation getConversation() {
        return conversation;
    }

    public void setConversation(Conversation conversation) {
        this.conversation = conversation;
    }

    public User getSender() {
        return sender;
    }

    public void setSender(User sender) {
        this.sender = sender;
    }

    public User getRecipient() {
        return recipient;
    }

    public void setRecipient(User recipient) {
        this.recipient = recipient;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getMediaUrl() {
        return mediaUrl;
    }

    public void setMediaUrl(String mediaUrl) {
        this.mediaUrl = mediaUrl;
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
        private Conversation conversation;
        private User sender;
        private User recipient;
        private String content;
        private String mediaUrl;
        private Boolean isRead = false;
        private Instant createdAt;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder conversation(Conversation conversation) {
            this.conversation = conversation;
            return this;
        }

        public Builder sender(User sender) {
            this.sender = sender;
            return this;
        }

        public Builder recipient(User recipient) {
            this.recipient = recipient;
            return this;
        }

        public Builder content(String content) {
            this.content = content;
            return this;
        }

        public Builder mediaUrl(String mediaUrl) {
            this.mediaUrl = mediaUrl;
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

        public Message build() {
            return new Message(id, conversation, sender, recipient, content, mediaUrl, isRead, createdAt);
        }
    }
}
