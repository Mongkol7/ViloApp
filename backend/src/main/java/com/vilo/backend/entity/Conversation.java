package com.vilo.backend.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;

@Entity
@Table(
        name = "conversations",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_conversation_participants",
                        columnNames = {"participant1_id", "participant2_id"}
                )
        }
)
public class Conversation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "participant1_id", nullable = false)
    private User participant1;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "participant2_id", nullable = false)
    private User participant2;

    @Column(name = "last_message_content", length = 1000)
    private String lastMessageContent;

    @Column(name = "last_message_sender_id")
    private Long lastMessageSenderId;

    @Column(name = "last_message_time")
    private Instant lastMessageTime;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;

    public Conversation() {
    }

    public Conversation(Long id, User participant1, User participant2, String lastMessageContent,
                        Long lastMessageSenderId, Instant lastMessageTime, Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.participant1 = participant1;
        this.participant2 = participant2;
        this.lastMessageContent = lastMessageContent;
        this.lastMessageSenderId = lastMessageSenderId;
        this.lastMessageTime = lastMessageTime;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
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

    public User getParticipant1() {
        return participant1;
    }

    public void setParticipant1(User participant1) {
        this.participant1 = participant1;
    }

    public User getParticipant2() {
        return participant2;
    }

    public void setParticipant2(User participant2) {
        this.participant2 = participant2;
    }

    public String getLastMessageContent() {
        return lastMessageContent;
    }

    public void setLastMessageContent(String lastMessageContent) {
        this.lastMessageContent = lastMessageContent;
    }

    public Long getLastMessageSenderId() {
        return lastMessageSenderId;
    }

    public void setLastMessageSenderId(Long lastMessageSenderId) {
        this.lastMessageSenderId = lastMessageSenderId;
    }

    public Instant getLastMessageTime() {
        return lastMessageTime;
    }

    public void setLastMessageTime(Instant lastMessageTime) {
        this.lastMessageTime = lastMessageTime;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }

    public static class Builder {
        private Long id;
        private User participant1;
        private User participant2;
        private String lastMessageContent;
        private Long lastMessageSenderId;
        private Instant lastMessageTime;
        private Instant createdAt;
        private Instant updatedAt;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder participant1(User participant1) {
            this.participant1 = participant1;
            return this;
        }

        public Builder participant2(User participant2) {
            this.participant2 = participant2;
            return this;
        }

        public Builder lastMessageContent(String lastMessageContent) {
            this.lastMessageContent = lastMessageContent;
            return this;
        }

        public Builder lastMessageSenderId(Long lastMessageSenderId) {
            this.lastMessageSenderId = lastMessageSenderId;
            return this;
        }

        public Builder lastMessageTime(Instant lastMessageTime) {
            this.lastMessageTime = lastMessageTime;
            return this;
        }

        public Builder createdAt(Instant createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public Builder updatedAt(Instant updatedAt) {
            this.updatedAt = updatedAt;
            return this;
        }

        public Conversation build() {
            return new Conversation(id, participant1, participant2, lastMessageContent, lastMessageSenderId, lastMessageTime, createdAt, updatedAt);
        }
    }
}
